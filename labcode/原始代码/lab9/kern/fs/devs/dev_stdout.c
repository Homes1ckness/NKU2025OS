#include <defs.h>
#include <stdio.h>
#include <dev.h>
#include <vfs.h>
#include <iobuf.h>
#include <inode.h>
#include <unistd.h>
#include <error.h>
#include <assert.h>

/*
 * stdout_open - 打开标准输出设备
 * 标准输出只能以只写模式打开
 */
static int
stdout_open(struct device *dev, uint32_t open_flags) {
    if (open_flags != O_WRONLY) {
        return -E_INVAL;  /* 只允许写打开 */
    }
    return 0;
}

/*
 * stdout_close - 关闭标准输出设备
 * 无需特殊处理
 */
static int
stdout_close(struct device *dev) {
    return 0;
}

/*
 * stdout_io - 标准输出的读写操作
 * write=0表示读操作，write=1表示写操作
 * 标准输出只支持写，不支持读
 * 通过cputchar()将字符输出到控制台
 */
static int
stdout_io(struct device *dev, struct iobuf *iob, bool write) {
    if (write) {
        /* 写操作 */
        char *data = iob->io_base;  /* 获取待写入的数据指针 */
        for (; iob->io_resid != 0; iob->io_resid --) {
            cputchar(*data ++);  /* 每次输出一个字符到控制台 */
        }
        return 0;
    }
    return -E_INVAL;  /* 不支持读操作 */
}

/*
 * stdout_ioctl - 标准输出的控制操作
 * 标准输出不支持特殊的控制操作
 */
static int
stdout_ioctl(struct device *dev, int op, void *data) {
    return -E_INVAL;  /* 不实现任何ioctl操作 */
}

/*
 * stdout_device_init - 初始化标准输出设备结构
 * 设置设备的操作函数指针
 */
static void
stdout_device_init(struct device *dev) {
    dev->d_blocks = 0;              /* 字符设备，块数为0 */
    dev->d_blocksize = 1;           /* 块大小为1字节 */
    dev->d_open = stdout_open;      /* 设置打开操作 */
    dev->d_close = stdout_close;    /* 设置关闭操作 */
    dev->d_io = stdout_io;          /* 设置读写操作 */
    dev->d_ioctl = stdout_ioctl;    /* 设置控制操作 */
}

/*
 * dev_init_stdout - 初始化标准输出设备
 * 创建标准输出inode并注册到VFS
 */
void
dev_init_stdout(void) {
    struct inode *node;
    if ((node = dev_create_inode()) == NULL) {
        panic("stdout: dev_create_node.\n");  /* inode创建失败 */
    }
    stdout_device_init(vop_info(node, device));  /* 初始化设备结构 */

    int ret;
    if ((ret = vfs_add_dev("stdout", node, 0)) != 0) {
        panic("stdout: vfs_add_dev: %e.\n", ret);  /* 添加到VFS失败 */
    }
}
