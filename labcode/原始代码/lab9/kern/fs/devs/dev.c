#include <defs.h>
#include <string.h>
#include <stat.h>
#include <dev.h>
#include <inode.h>
#include <unistd.h>
#include <error.h>

/*
 * dev_open - 处理打开设备的系统调用
 * 不允许创建、截断、独占或追加模式
 */
static int
dev_open(struct inode *node, uint32_t open_flags) {
    if (open_flags & (O_CREAT | O_TRUNC | O_EXCL | O_APPEND)) {
        return -E_INVAL;  /* 设备不支持这些标志 */
    }
    struct device *dev = vop_info(node, device);  /* 获取inode对应的设备结构 */
    return dop_open(dev, open_flags);  /* 调用设备的打开操作 */
}

/*
 * dev_close - 处理最后一次关闭操作
 * 直接转发给设备的关闭操作
 */
static int
dev_close(struct inode *node) {
    struct device *dev = vop_info(node, device);
    return dop_close(dev);  /* 调用设备的关闭操作 */
}

/*
 * dev_read - 处理读操作
 * 转发给设备的IO操作，write标志为0表示读取
 */
static int
dev_read(struct inode *node, struct iobuf *iob) {
    struct device *dev = vop_info(node, device);
    return dop_io(dev, iob, 0);  /* 第三个参数0表示读操作 */
}

/*
 * dev_write - 处理写操作
 * 转发给设备的IO操作，write标志为1表示写入
 */
static int
dev_write(struct inode *node, struct iobuf *iob) {
    struct device *dev = vop_info(node, device);
    return dop_io(dev, iob, 1);  /* 第三个参数1表示写操作 */
}

/*
 * dev_ioctl - 处理IO控制命令
 * 直接转发给设备的ioctl操作
 */
static int
dev_ioctl(struct inode *node, int op, void *data) {
    struct device *dev = vop_info(node, device);
    return dop_ioctl(dev, op, data);  /* 调用设备的控制操作 */
}

/*
 * dev_fstat - 处理stat()系统调用
 * 设置设备类型和大小(仅块设备)
 * 设备的链接计数总是1
 */
static int
dev_fstat(struct inode *node, struct stat *stat) {
    int ret;
    memset(stat, 0, sizeof(struct stat));  /* 清空stat结构 */
    if ((ret = vop_gettype(node, &(stat->st_mode))) != 0) {
        return ret;
    }
    struct device *dev = vop_info(node, device);
    stat->st_nlinks = 1;  /* 设备的链接数为1 */
    stat->st_blocks = dev->d_blocks;  /* 设置块数 */
    stat->st_size = stat->st_blocks * dev->d_blocksize;  /* 计算设备总大小 */
    return 0;
}

/*
 * dev_gettype - 返回设备类型
 * 块设备: 有已知长度的设备 (d_blocks > 0)
 * 字符设备: 生成数据流的设备 (d_blocks == 0)
 */
static int
dev_gettype(struct inode *node, uint32_t *type_store) {
    struct device *dev = vop_info(node, device);
    *type_store = (dev->d_blocks > 0) ? S_IFBLK : S_IFCHR;  /* 根据块数判断设备类型 */
    return 0;
}

/*
 * dev_tryseek - 尝试进行设备寻址
 * 块设备: 要求地址块对齐，且在有效范围内
 * 字符设备: 禁止进行寻址
 */
static int
dev_tryseek(struct inode *node, off_t pos) {
    struct device *dev = vop_info(node, device);
    if (dev->d_blocks > 0) {
        /* 块设备：检查块对齐和范围 */
        if ((pos % dev->d_blocksize) == 0) {
            if (pos >= 0 && pos < dev->d_blocks * dev->d_blocksize) {
                return 0;  /* 寻址有效 */
            }
        }
    }
    return -E_INVAL;  /* 字符设备或寻址无效 */
}

/*
 * dev_lookup - 处理设备名称查询
 * 一个有趣的特性是可以在设备路径上实现子路径
 * 例如: "video:800x600/24bpp" 来选择不同的工作模式
 * 不过本系统不支持此功能
 */
static int
dev_lookup(struct inode *node, char *path, struct inode **node_store) {
    if (*path != '\0') {
        return -E_NOENT;  /* 路径非空，查询失败 */
    }
    vop_ref_inc(node);  /* 增加inode的引用计数 */
    *node_store = node;
    return 0;
}

/*
 * 设备inode的虚拟操作表
 * 定义了设备inode支持的所有操作
 */
static const struct inode_ops dev_node_ops = {
    .vop_magic                      = VOP_MAGIC,  /* 操作表的魔数 */
    .vop_open                       = dev_open,   /* 打开操作 */
    .vop_close                      = dev_close,  /* 关闭操作 */
    .vop_read                       = dev_read,   /* 读操作 */
    .vop_write                      = dev_write,  /* 写操作 */
    .vop_fstat                      = dev_fstat,  /* 文件状态操作 */
    .vop_ioctl                      = dev_ioctl,  /* 控制操作 */
    .vop_gettype                    = dev_gettype,/* 获取类型操作 */
    .vop_tryseek                    = dev_tryseek,/* 寻址操作 */
    .vop_lookup                     = dev_lookup, /* 查询操作 */
};

/* 初始化设备的宏 - 自动调用设备初始化函数 */
#define init_device(x)                                  \
    do {                                                \
        extern void dev_init_##x(void);                 \
        dev_init_##x();              /* 调用dev_init_x函数 */ \
    } while (0)

/*
 * dev_init - 初始化内置的VFS级设备
 * 初始化stdin(标准输入), stdout(标准输出), disk0(磁盘)
 */
void
dev_init(void) {
   // init_device(null);  /* 暂不初始化空设备 */
    init_device(stdin);   /* 初始化标准输入设备 */
    init_device(stdout);  /* 初始化标准输出设备 */
    init_device(disk0);   /* 初始化磁盘0设备 */
}

/*
 * dev_create_inode - 为VFS级设备创建inode
 * 分配inode并初始化设备操作表
 */
struct inode *
dev_create_inode(void) {
    struct inode *node;
    if ((node = alloc_inode(device)) != NULL) {  /* 分配inode */
        vop_init(node, &dev_node_ops, NULL);  /* 初始化inode的操作表 */
    }
    return node;
}
