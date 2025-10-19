#include <slub.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>

static const size_t size_classes[] = {
    16, 32, 64, 128, 256, 512, 1024, 2048};

static struct slub_cache caches[SLUB_SIZE_CLASSES];

// 计算对象大小对应的类别索引
static int get_size_class_index(size_t size)
{
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
    {
        if (size <= size_classes[i])
        {
            return i;
        }
    }
    return -1; // 太大
}

// 地址计算所属的Page
static struct Page *addr_to_page(void *addr)
{
    uintptr_t pa = PADDR(addr);
    return pa2page(pa);
}

// 创建新的slab
static struct slab *slub_create_slab(struct slub_cache *cache)
{

    struct Page *page = alloc_page();
    if (page == NULL)
    {
        return NULL;
    }

    struct slab *slab = (struct slab *)page2kva(page); // 元数据
    slab->page = page;
    slab->inuse = 0;
    slab->free_count = cache->objects_per_slab;

    size_t slab_struct_size = ROUNDUP(sizeof(struct slab), 8);
    char *obj_start = (char *)slab + slab_struct_size;

    slab->freelist = obj_start;
    char *current = obj_start;
    for (size_t i = 0; i < cache->objects_per_slab - 1; i++)
    {
        char *next = current + cache->object_size;
        *(void **)current = next;
        current = next;
    }
    *(void **)current = NULL;

    return slab;
}

void slub_init(void)
{
    cprintf("Initializing Slabs\n");

    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
    {
        caches[i].object_size = size_classes[i];

        // 每个slab可容纳的对象数
        size_t slab_overhead = ROUNDUP(sizeof(struct slab), 8);
        size_t available = PGSIZE - slab_overhead;
        caches[i].objects_per_slab = available / size_classes[i];

        list_init(&caches[i].slabs_partial);
        list_init(&caches[i].slabs_full);
        caches[i].nr_slabs = 0;

        cprintf("  Size class %d: object_size=%d, objects_per_slab=%d\n",
                i, size_classes[i], caches[i].objects_per_slab);
    }
}

// 分配对象
void *kmalloc(size_t size)
{
    if (size == 0 || size > SLUB_MAX_SIZE)
    {
        return NULL;
    }

    // 找到合适的大小类别
    int idx = get_size_class_index(size);
    if (idx < 0)
    {
        // 太大，直接分配页面
        size_t pages = ROUNDUP(size, PGSIZE) / PGSIZE;
        struct Page *page = alloc_pages(pages);
        return page ? page2kva(page) : NULL;
    }

    struct slub_cache *cache = &caches[idx];
    struct slab *slab = NULL;

    // 从partial链表获取slab
    if (!list_empty(&cache->slabs_partial))
    {
        list_entry_t *le = list_next(&cache->slabs_partial);
        slab = to_struct(le, struct slab, slab_link);
    }
    // 创建新的slab
    else
    {
        slab = slub_create_slab(cache);
        if (slab == NULL)
        {
            return NULL;
        }
        list_add(&cache->slabs_partial, &slab->slab_link);
        cache->nr_slabs++;
    }

    // 从freelist获取对象
    void *object = slab->freelist;
    if (object == NULL)
    {
        cprintf("Error: freelist is NULL but slab is in partial list!\n");
        return NULL;
    }

    slab->freelist = *(void **)object;
    slab->inuse++;
    slab->free_count--;

    // slab已满移动到full链表
    if (slab->free_count == 0)
    {
        list_del(&slab->slab_link);
        list_add(&cache->slabs_full, &slab->slab_link);
    }

    memset(object, 0, cache->object_size);

    return object;
}

// 释放对象
void kfree(void *obj)
{
    if (obj == NULL)
    {
        return;
    }

    // 获取对象所属页面
    struct Page *page = addr_to_page(obj);
    struct slab *slab = (struct slab *)page2kva(page);

    // 找到对应cache
    struct slub_cache *cache = NULL;
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
    {
        if (caches[i].object_size >= ((char *)obj - (char *)slab))
        {

            cache = &caches[i];
            break;
        }
    }

    if (cache == NULL)
    {
        // 大对象
        free_page(page);
        return;
    }

    bool was_full = (slab->free_count == 0);

    // 将对象加入freelist
    *(void **)obj = slab->freelist;
    slab->freelist = obj;
    slab->inuse--;
    slab->free_count++;

    if (slab->free_count == cache->objects_per_slab)
    {
        // 释放slab
        list_del(&slab->slab_link);
        free_page(page);
        cache->nr_slabs--;
    }
    else if (was_full)
    {
        // 从full变为partial
        list_del(&slab->slab_link);
        list_add(&cache->slabs_partial, &slab->slab_link);
    }
}

void slub_check(void)
{
    cprintf("\nSLUB Test:\n");

    // 分配不同大小的对象

    void *obj1 = kmalloc(16);
    void *obj2 = kmalloc(32);
    void *obj3 = kmalloc(64);
    void *obj4 = kmalloc(128);

    assert(obj1 != NULL && obj2 != NULL && obj3 != NULL && obj4 != NULL);
    cprintf("  Allocated: obj1=%p, obj2=%p, obj3=%p, obj4=%p\n",
            obj1, obj2, obj3, obj4);

    // 使用对象

    strcpy((char *)obj1, "liuliu");
    *(int *)obj2 = 666666;
    cprintf("  obj1='%s', obj2=%d\n", (char *)obj1, *(int *)obj2);

    // 释放对象
    cprintf("Free objects\n");
    kfree(obj1);
    kfree(obj2);
    kfree(obj3);
    kfree(obj4);
    cprintf(" freed\n");

    // 分配和释放

#define BATCH_SIZE 20
    void *objs[BATCH_SIZE];
    for (int i = 0; i < BATCH_SIZE; i++)
    {
        objs[i] = kmalloc(64);
        assert(objs[i] != NULL);
    }
    cprintf("  Allocated %d objects\n", BATCH_SIZE);

    for (int i = 0; i < BATCH_SIZE; i++)
    {
        kfree(objs[i]);
    }
    cprintf("  Freed %d objects\n", BATCH_SIZE);

    // 碎片
    void *small[10];
    for (int i = 0; i < 10; i++)
    {
        small[i] = kmalloc(16);
    }

    // 释放一半
    for (int i = 0; i < 5; i++)
    {
        kfree(small[i * 2]);
    }

    // 再分配
    for (int i = 0; i < 5; i++)
    {
        small[i * 2] = kmalloc(16);
    }

    // 全部释放
    for (int i = 0; i < 10; i++)
    {
        kfree(small[i]);
    }
    cprintf("  Fragmentation test passed\n");

    cprintf("\nSLUB Statistics:\n");
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
    {
        if (caches[i].nr_slabs > 0)
        {
            cprintf("  Size %d: %d slabs\n",
                    size_classes[i], caches[i].nr_slabs);
        }
    }
}
