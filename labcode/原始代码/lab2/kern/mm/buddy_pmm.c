#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>

#define MAX_ORDER 11 // 最大2^10 = 1024页

typedef struct
{
    list_entry_t free_list[MAX_ORDER];
    unsigned int nr_free[MAX_ORDER];
} buddy_free_area_t;

static buddy_free_area_t buddy_area;

// n的以2为底的对数
static size_t log2(size_t n)
{
    size_t order = 0;
    size_t size = 1;
    while (size < n)
    {
        size <<= 1;
        order++;
    }
    return order;
}

// 判断是否是2的幂
static int is_power2(size_t n)
{
    return n > 0 && (n & (n - 1)) == 0;
}

// 计算伙伴块的地址
static struct Page *get_buddy(struct Page *page, size_t order)
{

    size_t page_idx = page - pages;
    size_t buddy_idx = page_idx ^ (1 << order);
    return &pages[buddy_idx];
}

static int page_is_free(struct Page *page, size_t order)
{
    list_entry_t *le = &buddy_area.free_list[order];
    while ((le = list_next(le)) != &buddy_area.free_list[order])
    {
        if (le2page(le, page_link) == page)
        {
            return 1;
        }
    }
    return 0;
}

static int is_buddy(struct Page *page1, struct Page *page2, size_t order)
{
    size_t page1_idx = page1 - pages;
    size_t page2_idx = page2 - pages;

    size_t block_size = 1 << (order + 1);
    if ((page1_idx / block_size) != (page2_idx / block_size))
    {
        return 0;
    }

    size_t diff = page1_idx > page2_idx ? page1_idx - page2_idx : page2_idx - page1_idx;
    return diff == (1UL << order);
}

static void
buddy_init(void)
{
    for (int i = 0; i < MAX_ORDER; i++)
    {
        list_init(&buddy_area.free_list[i]);
        buddy_area.nr_free[i] = 0;
    }
}

static void
buddy_init_mmp(struct Page *base, size_t n)
{
    assert(n > 0);

    // 初始化
    struct Page *p = base;
    for (; p != base + n; p++)
    {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }

    size_t remain = n;
    struct Page *cur = base;

    while (remain > 0)
    {
        // 找到最大的2的幂次
        size_t order = 0;
        size_t size = 1;
        while (size * 2 <= remain && order < MAX_ORDER - 1)
        {
            size <<= 1;
            order++;
        }

        // 设置块属性
        cur->property = order;
        SetPageProperty(cur);

        // 加入对应order链表
        list_add(&buddy_area.free_list[order], &(cur->page_link));
        buddy_area.nr_free[order]++;

        cur += size;
        remain -= size;
    }
}

static struct Page *
buddy_alloc_pages(size_t n)
{
    assert(n > 0);
    size_t order = log2(n);
    if (order >= MAX_ORDER)
    {
        return NULL;
    }

    // 查找合适的空闲块
    size_t cur_order = order;
    while (cur_order < MAX_ORDER && list_empty(&buddy_area.free_list[cur_order]))
    {
        cur_order++;
    }

    if (cur_order >= MAX_ORDER)
    {
        return NULL;
    }

    // 从链表中取出一个块
    list_entry_t *le = list_next(&buddy_area.free_list[cur_order]);
    struct Page *page = le2page(le, page_link);
    list_del(&(page->page_link));
    buddy_area.nr_free[cur_order]--;
    ClearPageProperty(page);

    // 分裂
    while (cur_order > order)
    {
        cur_order--;
        struct Page *buddy = page + (1 << cur_order);
        buddy->property = cur_order;
        SetPageProperty(buddy);
        list_add(&buddy_area.free_list[cur_order], &(buddy->page_link));
        buddy_area.nr_free[cur_order]++;
    }

    page->property = order;

    return page;
}

static void
buddy_free_pages(struct Page *base, size_t n)
{
    assert(n > 0);

    // 计算order
    size_t order = log2(n);
    if (order >= MAX_ORDER)
    {
        return;
    }

    struct Page *p = base;
    for (int i = 0; i < (1 << order); i++, p++)
    {
        assert(!PageReserved(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }

    while (order < MAX_ORDER - 1)
    {

        struct Page *buddy = get_buddy(base, order);

        // 伙伴块空闲且大小相同
        if (buddy < pages || buddy >= pages + npage)
        {
            break;
        }

        if (!PageProperty(buddy) || buddy->property != order)
        {
            break;
        }

        // 从链表中删除伙伴块
        list_del(&(buddy->page_link));
        buddy_area.nr_free[order]--;
        ClearPageProperty(buddy);

        // 地址较小的作为新块的基地址
        if (buddy < base)
        {
            base = buddy;
        }

        order++;
    }
    base->property = order;
    SetPageProperty(base);
    list_add(&buddy_area.free_list[order], &(base->page_link));
    buddy_area.nr_free[order]++;
}

static size_t
buddy_nr_free_pages(void)
{
    size_t total = 0;
    for (int i = 0; i < MAX_ORDER; i++)
    {
        total += buddy_area.nr_free[i] * (1 << i);
    }
    return total;
}

static void
buddy_check(void)
{

    // 分配和释放
    struct Page *p0, *p1, *p2;

    p0 = alloc_pages(1);
    assert(p0 != NULL);

    p1 = alloc_pages(2);
    assert(p1 != NULL);

    p2 = alloc_pages(4);
    assert(p2 != NULL);

    cprintf("Allocated: p0=%p (1 page), p1=%p (2 pages), p2=%p (4 pages)\n", p0, p1, p2);

    free_pages(p0, 1);
    free_pages(p1, 2);
    free_pages(p2, 4);

    cprintf("Freed all pages\n");

    // 测试2：合并
    p0 = alloc_pages(1);
    p1 = alloc_pages(1);

    cprintf("Allocated two 1-page blocks: p0=%p, p1=%p\n", p0, p1);

    // 检查伙伴
    if (is_buddy(p0, p1, 0))
    {
        cprintf("p0 and p1 are buddies\n");
    }

    free_pages(p0, 1);
    free_pages(p1, 1);

    // 测试3：大块分配
    p0 = alloc_pages(16);
    assert(p0 != NULL);
    cprintf("Allocated 16 pages: p0=%p\n", p0);
    free_pages(p0, 16);

    // 测试4：碎片
    struct Page *pages_array[10];
    for (int i = 0; i < 10; i++)
    {
        pages_array[i] = alloc_pages(1);
        assert(pages_array[i] != NULL);
    }
    cprintf("Allocated 10 single pages\n");

    for (int i = 0; i < 10; i++)
    {
        free_pages(pages_array[i], 1);
    }
    cprintf("Freed 10 single pages\n");

    cprintf("\nFree blocks statistics:\n");
    for (int i = 0; i < MAX_ORDER; i++)
    {
        if (buddy_area.nr_free[i] > 0)
        {
            cprintf("Order %d (2^%d=%d pages): %d blocks\n",
                    i, i, 1 << i, buddy_area.nr_free[i]);
        }
    }

    cprintf("Total free pages: %d\n", buddy_nr_free_pages());
    ;
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_mmp,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
