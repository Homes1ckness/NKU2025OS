#include <defs.h>
#include <mmu.h>
#include <sem.h>
#include <ide.h>
#include <inode.h>
#include <kmalloc.h>
#include <dev.h>
#include <vfs.h>
#include <iobuf.h>
#include <error.h>
#include <assert.h>

#define DISK0_BLKSIZE                   PGSIZE              /* 磁盘块大小 = 页面大小 */
#define DISK0_BUFSIZE                   (4 * DISK0_BLKSIZE) /* 缓冲区大小 = 4个块 */
#define DISK0_BLK_NSECT                 (DISK0_BLKSIZE / SECTSIZE)  /* 每个块包含的扇区数 */

static char *disk0_buffer;              /* 磁盘缓冲区指针 */
static semaphore_t disk0_sem;           /* 磁盘访问信号量，用于同步访问 */

/*
 * lock_disk0 - 获取磁盘锁
 * 通过P操作(down)获取信号量
 */
static void
lock_disk0(void) {
    down(&(disk0_sem));  /* 获取信号量 */
}

/*
 * unlock_disk0 - 释放磁盘锁
 * 通过V操作(up)释放信号量
 */
static void
unlock_disk0(void) {
    up(&(disk0_sem));  /* 释放信号量 */
}

/*
 * disk0_open - 打开磁盘设备
 * 磁盘无需特殊的打开处理
 */
static int
disk0_open(struct device *dev, uint32_t open_flags) {
    return 0;
}

/*
 * disk0_close - 关闭磁盘设备
 * 磁盘无需特殊的关闭处理
 */
static int
disk0_close(struct device *dev) {
    return 0;
}

/*
 * disk0_read_blks_nolock - 不加锁地从磁盘读取块
 * 内部函数，假设调用者已获得磁盘锁
 * 实际的磁盘读取使用缓冲区避免重复读取
 */
static void
disk0_read_blks_nolock(uint32_t blkno, uint32_t nblks) {
    /* 从物理磁盘读取数据到缓冲区 */
    int ret = ide_read_secs(DISK0_DEV_NO, blkno * DISK0_BLK_NSECT,
                            disk0_buffer, nblks * DISK0_BLK_NSECT);
    assert(ret == 0);  /* 断言读取成功 */
}

/*
 * disk0_write_blks_nolock - 不加锁地向磁盘写入块
 * 内部函数，假设调用者已获得磁盘锁
 */
static void
disk0_write_blks_nolock(uint32_t blkno, uint32_t nblks) {
    /* 将缓冲区中的数据写入物理磁盘 */
    int ret = ide_write_secs(DISK0_DEV_NO, blkno * DISK0_BLK_NSECT,
                             disk0_buffer, nblks * DISK0_BLK_NSECT);
    assert(ret == 0);  /* 断言写入成功 */
}

/*
 * disk0_io - 磁盘的读写操作
 * 使用缓冲区管理策略实现高效的磁盘访问
 * write=0表示读，write=1表示写
 */
static int
disk0_io(struct device *dev, struct iobuf *iob, bool write) {
    off_t offset = iob->io_offset;  /* 获取起始偏移 */
    size_t resid = iob->io_resid;   /* 获取待传输字节数 */
    uint32_t blkno = offset / DISK0_BLKSIZE;  /* 计算起始块号 */
    uint32_t nblks;

    lock_disk0();  /* 获取磁盘锁 */
    {
        if ((nblks = resid / DISK0_BLKSIZE) > 0) {
            /* 处理整块传输 */
            if (write) {
                /* 写操作：先从iob缓冲区复制到磁盘缓冲区，再写到磁盘 */
                disk0_write_blks_nolock(blkno, nblks);
            } else {
                /* 读操作：先从磁盘读到缓冲区，再复制到iob缓冲区 */
                disk0_read_blks_nolock(blkno, nblks);
            }
            /* 复制数据 */
            int copied = 0;
            if (write) {
                memcpy(disk0_buffer, iob->io_base, nblks * DISK0_BLKSIZE);
                copied = ide_write_secs(DISK0_DEV_NO, blkno * DISK0_BLK_NSECT,
                                       disk0_buffer, nblks * DISK0_BLK_NSECT);
            } else {
                disk0_read_blks_nolock(blkno, nblks);
                memcpy(iob->io_base, disk0_buffer, nblks * DISK0_BLKSIZE);
                copied = nblks * DISK0_BLKSIZE;
            }
            assert(copied == nblks * DISK0_BLKSIZE && copied % DISK0_BLKSIZE == 0);
        }
        resid -= copied, blkno += nblks;  /* 更新剩余字节数和块号 */
    }
    unlock_disk0();  /* 释放磁盘锁 */
    return 0;
}

/*
 * disk0_ioctl - 磁盘的控制操作
 * 暂未实现
 */
static int
disk0_ioctl(struct device *dev, int op, void *data) {
    return -E_UNIMP;  /* 返回未实现 */
}

/*
 * disk0_device_init - 初始化磁盘设备结构
 * 设置磁盘的块数、块大小和操作函数
 * 初始化缓冲区和信号量
 */
static void
disk0_device_init(struct device *dev) {
    static_assert(DISK0_BLKSIZE % SECTSIZE == 0);  /* 块大小必须是扇区大小的倍数 */
    if (!ide_device_valid(DISK0_DEV_NO)) {
        panic("disk0 device isn't available.\n");  /* IDE设备不可用 */
    }
    /* 设置磁盘设备的参数 */
    dev->d_blocks = ide_device_size(DISK0_DEV_NO) / DISK0_BLK_NSECT;  /* 计算总块数 */
    dev->d_blocksize = DISK0_BLKSIZE;  /* 设置块大小 */
    
    /* 设置设备操作函数 */
    dev->d_open = disk0_open;
    dev->d_close = disk0_close;
    dev->d_io = disk0_io;
    dev->d_ioctl = disk0_ioctl;
    
    /* 初始化缓冲区和信号量 */
    sem_init(&(disk0_sem), 1);  /* 信号量初始化为1(互斥锁) */
}

/*
 * disk0_buffer_init - 分配磁盘缓冲区
 * 在内核初始化阶段调用
 */
static void
disk0_buffer_init(void) {
    static_assert(DISK0_BUFSIZE % DISK0_BLKSIZE == 0);  /* 缓冲区大小必须是块大小的倍数 */
    if ((disk0_buffer = kmalloc(DISK0_BUFSIZE)) == NULL) {
        panic("disk0 alloc buffer failed.\n");  /* 内存分配失败 */
    }
}

/*
 * dev_init_disk0 - 初始化磁盘0设备
 * 创建磁盘inode、初始化设备结构、注册到VFS
 */
void
dev_init_disk0(void) {
    struct inode *node;
    if ((node = dev_create_inode()) == NULL) {
        panic("disk0: dev_create_node.\n");  /* inode创建失败 */
    }
    disk0_device_init(vop_info(node, device));  /* 初始化设备结构 */

    int ret;
    if ((ret = vfs_add_dev("disk0", node, 1)) != 0) {
        panic("disk0: vfs_add_dev: %e.\n", ret);  /* 添加到VFS失败 */
    }
}
