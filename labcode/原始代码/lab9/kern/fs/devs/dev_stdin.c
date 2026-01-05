#include <defs.h>
#include <stdio.h>
#include <wait.h>
#include <sync.h>
#include <proc.h>
#include <sched.h>
#include <dev.h>
#include <vfs.h>
#include <iobuf.h>
#include <inode.h>
#include <unistd.h>
#include <error.h>
#include <assert.h>

#define STDIN_BUFSIZE               4096  /* 标准输入缓冲区大小 */

static char stdin_buffer[STDIN_BUFSIZE];  /* 输入缓冲区 */
static off_t p_rpos, p_wpos;              /* 读指针和写指针 */
static wait_queue_t __wait_queue, *wait_queue = &__wait_queue;  /* 等待队列，用于阻塞读取的进程 */

/*
 * dev_stdin_write - 键盘驱动调用此函数向标准输入缓冲区写入字符
 * 将字符存入缓冲区，并唤醒等待队列中的进程
 */
void
dev_stdin_write(char c) {
    bool intr_flag;
    if (c != '\0') {
        local_intr_save(intr_flag);  /* 保存中断状态并禁用中断 */
        {
            stdin_buffer[p_wpos % STDIN_BUFSIZE] = c;  /* 将字符写入循环缓冲区 */
            if (p_wpos - p_rpos < STDIN_BUFSIZE) {
                p_wpos ++;  /* 增加写指针 */
            }
            if (!wait_queue_empty(wait_queue)) {
                wakeup_queue(wait_queue, WT_KBD, 1);  /* 唤醒等待键盘输入的进程 */
            }
        }
        local_intr_restore(intr_flag);  /* 恢复中断状态 */
    }
}

/*
 * dev_stdin_read - 从标准输入缓冲区读取字符
 * 如果缓冲区中有数据就读取，否则进程进入等待队列并让出CPU
 */
static int
dev_stdin_read(char *buf, size_t len) {
    int ret = 0;
    bool intr_flag;
    local_intr_save(intr_flag);  /* 保存中断状态并禁用中断 */
    {
        for (; ret < len; ret ++, p_rpos ++) {
        try_again:
            if (p_rpos < p_wpos) {
                /* 缓冲区中有数据 */
                *buf ++ = stdin_buffer[p_rpos % STDIN_BUFSIZE];  /* 读取一个字符 */
            }
            else {
                /* 缓冲区为空，进程需要等待输入 */
                wait_t __wait, *wait = &__wait;
                wait_current_set(wait_queue, wait, WT_KBD);  /* 将当前进程加入等待队列 */
                local_intr_restore(intr_flag);  /* 恢复中断以便接收键盘输入 */

                schedule();  /* 让出CPU，等待唤醒 */

                local_intr_save(intr_flag);  /* 恢复中断禁用状态 */
                wait_current_del(wait_queue, wait);  /* 从等待队列移除 */
                if (wait->wakeup_flags == WT_KBD) {
                    goto try_again;  /* 被键盘中断唤醒，重新尝试读取 */
                }
                break;  /* 其他原因唤醒，停止读取 */
            }
        }
    }
    local_intr_restore(intr_flag);  /* 恢复中断状态 */
    return ret;  /* 返回实际读取的字符数 */
}

/*
 * stdin_open - 打开标准输入设备
 * 标准输入只能以只读模式打开
 */
static int
stdin_open(struct device *dev, uint32_t open_flags) {
    if (open_flags != O_RDONLY) {
        return -E_INVAL;  /* 只允许读打开 */
    }
    return 0;
}

/*
 * stdin_close - 关闭标准输入设备
 * 无需特殊处理
 */
static int
stdin_close(struct device *dev) {
    return 0;
}

/*
 * stdin_io - 标准输入的读写操作
 * write=0表示读操作，write=1表示写操作
 * 标准输入只支持读，不支持写
 */
static int
stdin_io(struct device *dev, struct iobuf *iob, bool write) {
    if (!write) {
        /* 读操作 */
        int ret;
        if ((ret = dev_stdin_read(iob->io_base, iob->io_resid)) > 0) {
            iob->io_resid -= ret;  /* 减少剩余待读取字节数 */
        }
        return ret;
    }
    return -E_INVAL;  /* 不支持写操作 */
}

/*
 * stdin_ioctl - 标准输入的控制操作
 * 标准输入不支持特殊的控制操作
 */
static int
stdin_ioctl(struct device *dev, int op, void *data) {
    return -E_INVAL;  /* 不实现任何ioctl操作 */
}

/*
 * stdin_device_init - 初始化标准输入设备结构
 * 设置设备的操作函数指针，初始化缓冲区指针和等待队列
 */
static void
stdin_device_init(struct device *dev) {
    dev->d_blocks = 0;              /* 字符设备，块数为0 */
    dev->d_blocksize = 1;           /* 块大小为1字节 */
    dev->d_open = stdin_open;       /* 设置打开操作 */
    dev->d_close = stdin_close;     /* 设置关闭操作 */
    dev->d_io = stdin_io;           /* 设置读写操作 */
    dev->d_ioctl = stdin_ioctl;     /* 设置控制操作 */

    p_rpos = p_wpos = 0;            /* 初始化读写指针 */
    wait_queue_init(wait_queue);    /* 初始化等待队列 */
}

/*
 * dev_init_stdin - 初始化标准输入设备
 * 创建标准输入inode并注册到VFS
 */
void
dev_init_stdin(void) {
    struct inode *node;
    if ((node = dev_create_inode()) == NULL) {
        panic("stdin: dev_create_node.\n");  /* inode创建失败 */
    }
    stdin_device_init(vop_info(node, device));  /* 初始化设备结构 */

    int ret;
    if ((ret = vfs_add_dev("stdin", node, 0)) != 0) {
        panic("stdin: vfs_add_dev: %e.\n", ret);  /* 添加到VFS失败 */
    }
}
