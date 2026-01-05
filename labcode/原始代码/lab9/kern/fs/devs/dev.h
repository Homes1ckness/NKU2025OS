#ifndef __KERN_FS_DEVS_DEV_H__
#define __KERN_FS_DEVS_DEV_H__

#include <defs.h>

struct inode;
struct iobuf;

/*
 * 文件系统命名空间可访问的设备结构
 * d_io 用于读和写操作；iobuf 会指示操作方向
 */
struct device {
    size_t d_blocks;              /* 设备中的块数 */
    size_t d_blocksize;           /* 每个块的大小(字节) */
    int (*d_open)(struct device *dev, uint32_t open_flags);      /* 打开设备操作 */
    int (*d_close)(struct device *dev);                           /* 关闭设备操作 */
    int (*d_io)(struct device *dev, struct iobuf *iob, bool write); /* 读写操作,write标志表示写入操作 */
    int (*d_ioctl)(struct device *dev, int op, void *data);      /* 控制操作 */
};

/* 设备操作宏定义 - 便捷调用设备操作函数 */
#define dop_open(dev, open_flags)           ((dev)->d_open(dev, open_flags))     /* 打开设备 */
#define dop_close(dev)                      ((dev)->d_close(dev))                 /* 关闭设备 */
#define dop_io(dev, iob, write)             ((dev)->d_io(dev, iob, write))        /* 设备读写 */
#define dop_ioctl(dev, op, data)            ((dev)->d_ioctl(dev, op, data))       /* 设备控制 */

void dev_init(void);                    /* 初始化所有设备 */
struct inode *dev_create_inode(void);   /* 为设备创建inode */

#endif /* !__KERN_FS_DEVS_DEV_H__ */
