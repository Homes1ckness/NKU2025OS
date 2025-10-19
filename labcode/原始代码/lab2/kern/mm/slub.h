#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>
#include <list.h>

#define SLUB_MIN_SIZE 16
#define SLUB_MAX_SIZE 2048
#define SLUB_SIZE_CLASSES 7

// 大小类别：16, 32, 64, 128, 256, 512, 1024, 2048

struct slub_cache
{
    size_t object_size;
    size_t objects_per_slab;
    list_entry_t slabs_partial;
    list_entry_t slabs_full;
    unsigned int nr_slabs;
};

struct slab
{
    void *freelist;
    size_t inuse;
    size_t free_count;
    struct Page *page;
    list_entry_t slab_link;
};

void slub_init(void);
void *kmalloc(size_t size);
void kfree(void *obj);
void slub_check(void);

#endif /* __KERN_MM_SLUB_H__ */
