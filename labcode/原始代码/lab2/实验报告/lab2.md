# 实验二：物理内存管理

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

#### 练习1：理解first-fit 连续物理内存分配算法（思考题）
first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合`kern/mm/default_pmm.c`中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 你的first fit算法是否有进一步的改进空间？

#### 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）
在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。
请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
- 你的 Best-Fit 算法是否有进一步的改进空间？

#### 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

 -  参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档

**设计原理和核心思想：**

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理,系统中的所有内存块（无论是空闲还是已分配）的大小都是2的幂次方个页帧（比如1, 2, 4, 8, ..., 1024个页）， 所以我们划分的每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

**伙伴关系**：两个大小相同、地址相邻且满足特定对齐条件的内存块被称为“伙伴”。合并和分裂操作都围绕伙伴关系进行。

**设计思路：**

  我们要编写的分裂过程是当需要分配一个大小为 `n` 的内存块时，系统会查找大小为 `2^k` 的最小空闲块，其中 `2^k >= n`。 如果找到了大小正好为 `2^k` 的块，则直接分配。如果找到的块大于 `2^k`（例如 `2^m`，其中 `m > k`），系统会将其**分裂**成两个大小为 `2^(m-1)` 的伙伴块。一个用于分配或继续分裂，另一个加入到对应大小的空闲链表中。这个过程会递归进行，直到得到我们所需大小的块。

  当一个内存块被释放时，我们要检查其伙伴块是否也处于空闲状态。如果伙伴块也空闲，系统会将它们**合并**成一个大小翻倍的父块。这个合并过程会递归进行，直到父块的伙伴不空闲，或者已经合并到最大的块。

> 举个例子：假设进行需要操作系统分配一个1页大小的块，但只有一块16页的空闲块。
>
> ```
> +---------------------------------------------------------------+
> |                      16 pages (Order 4)                       |
> +---------------------------------------------------------------+
>                            |
>                            V (分裂)
> +-------------------------------+-------------------------------+
> |       8 pages (Order 3)       |       8 pages (Order 3)       | <- 右边伙伴加入空闲链表
> +-------------------------------+-------------------------------+
>               |
>               V (分裂)
> +---------------+---------------+
> | 4 pages (Ord 2)| 4 pages (Ord 2)|      <- 右边伙伴加入空闲链表
> +---------------+---------------+
>       |
>       V (分裂)
> +-------+-------+
> | 2(O1) | 2(O1) |               <-右边伙伴加入空闲链表
> +-------+-------+
>    |
>    V (分裂)
> +---+---+
> | 1 | 1 |                    <- 右边伙伴加入空闲链表
> +-|-+---+
>   |
>   V (分配)
>  分配这1页
> ```

 当一个内存块被释放时，我们要检查其伙伴块是否也处于空闲状态。如果伙伴块也空闲，系统会将它们**合并**成一个大小翻倍的父块。这个合并过程会递归进行，直到父块的伙伴不空闲，或者已经合并到最大的块。

> 举个例子：假设要释放一个1页大小的块 `A`，其伙伴 `B` 也空闲。

> ```
> +---+---+-----------------------+-------------------------------+
> | A | B |       (free)          |            (free)             |
> +-|-+---+-----------------------+-------------------------------+
>   | (释放A)
>   V
>  检查B是否空闲 -> 是
> +-------+-----------------------+-------------------------------+
> | A   B |       (free)          |            (free)             | <- 合并A和B
> +-------+-----------------------+-------------------------------+
>    |
>    V
>   检查(A&B)的伙伴C是否空闲 -> 是
> +---------------+-----------------------------------------------+
> |   (ABC)       |                     (free)                    | <- 继续合并
> +---------------+-----------------------------------------------+
>    ... 直到伙伴不空闲或达到最大块
> ```

**实验代码**

**1. 数据结构设计**

为了高效地管理不同大小的空闲块，我们使用一个数组，其每个元素是一个双向链表。

```c
\#define MAX_ORDER 11  // 支持最大2^10 = 1024页
typedef struct {

  list_entry_t free_list[MAX_ORDER];  // 每个order一个链表

  unsigned int nr_free[MAX_ORDER];   // 每个order的空闲块数量

} buddy_free_area_t;

static buddy_free_area_t buddy_free_area;
```

`free_list[i]`是一个双向链表的头节点，链接了所有大小为 `2^i` 页的空闲块。

\-  `Page` 结构体中的 `property` 字段被复用。当一个页是空闲块的起始页时，`property` 存储该块的 `order`（即 `k`，大小为 `2^k`）。`PageProperty` 标志位用于表示该页是否为空闲块的头部。

**2. 核心函数实现**

**2.1 初始化函数**

初始化 `buddy_area`，将所有链表设置为空，计数器清零。

```c
static void buddy_init(void) {
  for (int i = 0; i < MAX_ORDER; i++) {
     list_init(&buddy_area.free_list[i]);
     buddy_area.nr_free[i] = 0;
  }
}
```

**2.2 内存映射初始化**

这是伙伴系统的初始化，接收一块连续的物理内存， 将 `n` 页内存分解为多个大小为2的幂次方的块。在这里我们采用贪心策略：从 `base` 地址开始，每次都尝试划分出不超过剩余内存 `remaining` 的最大2的幂次方块。对于每个划分出的块，获取其起始页 `current`，设置其 `order` (`current->property = order`)，并将其加入到 `buddy_area.free_list[order]` 中。

```c
static void buddy_init_mmp(struct Page *base, size_t n) {
    assert(n > 0);
    // 初始化所有页面
    struct Page *p = base;
    for (; p != base + n; p++)
    {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }
  // 将内存块按2的幂次分解
  size_t remain = n;
  struct Page *cur = base;
  while (remain > 0) {
     // 找到最大的2的幂次
     size_t order = 0;
     size_t size = 1;
     while (size * 2 <= remain && order < MAX_ORDER - 1) {
       size <<= 1;
       order++;
     }
    // 加入对应order的链表
    cur->property = order;
    SetPageProperty(cur);
    list_add(&buddy_area.free_list[order], &(cur->page_link));
    buddy_area.nr_free[order]++;
    cur += size;
    remain -= size;
  }
}
```

例如：100页内存会被分解为：64页(order=6) + 32页(order=5) + 4页(order=2)

**2.3 分配函数**

  需要分配大小为n的内存块，我们先使用 `log2(n)` 计算满足 `n` 页所需的最小 `order`。接着从 `order` 开始，向上遍历 `free_list`，找到第一个不为空的链表 `free_list[cur_order]`。如果 `cur_order > order`，说明找到的块太大了，我们就需要分裂。这里设置一个 `while` 循环，不断将块一分为二。在每次分裂中，当前块 `page` 的大小从 `2^cur_order` 减半到 `2^(cur_order-1)`。它的伙伴块 `buddy`（地址为 `page + (1 << (cur_order-1))`）被创建出来。将这个新的伙伴块  设置好 `order`，添加到 `free_list[current_order-1]` 中。这个循环直到 `current_order` 等于所需的 `order`。

  最后我们从链表中取出大小合适的块，清除其 `PageProperty` 标志，设置其 `property` 为最终的 `order`，并返回。

```c
static struct Page *
buddy_alloc_pages(size_t n)
{
    assert(n > 0);
    // 计算需要的order
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

    // 没有找到合适的块
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

    // 如果块太大，需要分裂
    while (cur_order > order)
    {
        cur_order--;

        // 分裂成两个伙伴块，将右边的块加入链表
        struct Page *buddy = page + (1 << cur_order);
        buddy->property = cur_order;
        SetPageProperty(buddy);
        list_add(&buddy_area.free_list[cur_order], &(buddy->page_link));
        buddy_area.nr_free[cur_order]++;
    }

    // 设置分配的块
    page->property = order;

    return page;
}

```

***\*分配示例\****：

\- 请求5页 → 需要8页(order=3)

\- 如果order=3的链表为空，查找order=4(16页)

\- 分裂：16页 → 8页 + 8页，取一个8页分配，另一个8页放回链表

**2.4 释放函数（合并算法）**

如果我们要释放从 某个地址`base` 开始的 `n` 页内存。与分解同理刚开始要根据 `n` 计算出 `order`。之后不断尝试与同样大小的伙伴合并，这里我使用 `get_buddy(base, order)` 函数计算伙伴块的地址。这个函数使用位运算 `page_idx ^ (1 << order)` 来快速定位伙伴。

这时候不能急着合并伙伴块，我们先检查伙伴块是否在物理内存范围内，以及伙伴块是否是空闲块的头部 (通过`PageProperty` 标志），最后我们要保证伙伴块的 `order` 要与当前块相同。

 如果以上条件都满足，这时候我们可以合并了。先从伙伴的空闲链表中移除它，再选择两个伙伴中地址较小的一个作为新块的 `base`。然后让`order` 加一进入下一次循环，尝试与新的、更大的伙伴块合并，直到不能合并。

  别忘了将最终合并后的块 `base` 设置好 `order` 和 `PageProperty` 标志，加入到 `free_list[order]` 中。

```c
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

    // 重置页面状态
    struct Page *p = base;
    for (int i = 0; i < (1 << order); i++, p++)
    {
        assert(!PageReserved(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }

    // 合并伙伴块
    while (order < MAX_ORDER - 1)
    {
        // 计算伙伴块的地址
        struct Page *buddy = get_buddy(base, order);

        // 检查伙伴块是否空闲且大小相同
        if (buddy < pages || buddy >= pages + npage)
        {
            break; // 伙伴块超出范围
        }

        if (!PageProperty(buddy) || buddy->property != order)
        {
            break; // 伙伴块不空闲或大小不匹配
        }

        // 从链表中删除伙伴块
        list_del(&(buddy->page_link));
        buddy_area.nr_free[order]--;
        ClearPageProperty(buddy);

        // 合并：选择地址较小的作为新块的基地址
        if (buddy < base)
        {
            base = buddy;
        }

        order++;
    }

    // 将合并后的块加入链表
    base->property = order;
    SetPageProperty(base);
    list_add(&buddy_area.free_list[order], &(base->page_link));
    buddy_area.nr_free[order]++;
}
```

#### 2.5 伙伴计算：

```c
static struct Page *get_buddy(struct Page *page, size_t order) {

  size_t page_idx = page - pages;

  size_t buddy_idx = page_idx ^ (1 << order);  // 异或翻转order位

  return &pages[buddy_idx];

}
```

**为什么翻转第 `order` 位就能找到伙伴？**

伙伴系统的定义是：两个大小为 `2^k` 的块，如果它们的地址是连续的，并且共同构成一个大小为 `2^(k+1)` 的、地址对齐的块，那么它们就是伙伴。

两个大小为 `2^order` 的伙伴块，它们的起始页号 `page_idx` 在二进制表示下，只有**第 `order` 位**是不同的。因此，通过异或操作 `^ (1 << order)` 来翻转这一位，就可以精确地从一个伙伴的地址计算出另一个伙伴的地址。

**测试检测流程**

我设计了以下功能测试方案：

 1.连续分配1、2、4页的块。验证alloc_pages功能，如果返回非 `NULL` 指针说明功能无误。然后立即释放内存块，恢复环境。

2.分配两个大小为1的块 `p0` 和 `p1`。 使用 `is_buddy(p0, p1, 0)` 检查它们是否是伙伴关系。在释放后，检查 `free_list[0]` 是否为空，`free_list[1]` 中如果出现了一个新的块。说明两个1页的伙伴块已成功合并为一个2页的块。

3.分配一个16页的大块，如果`alloc_pages` 返回非 `NULL` 指针说明正确。在释放后，我们使用`buddy_nr_free_pages()` 检查总空闲页数是否恢复正常。

4.连续分配10个1页的块，让内存出现碎片， 再将这10个块全部释放。打印 `free_list` 的统计信息。理想状态是许多小的空闲块已经消失，存在几个大的、合并后的空闲块。

```c
static void buddy_test(void)
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

    // 测试合并
    p0 = alloc_pages(1);
    p1 = alloc_pages(1);

    cprintf("Allocated two 1-page blocks: p0=%p, p1=%p\n", p0, p1);

    // 检查是否是伙伴
    if (is_buddy(p0, p1, 0))
    {
        cprintf("p0 and p1 are buddies\n");
    }

    free_pages(p0, 1);
    free_pages(p1, 1);

    // 大块分配
    p0 = alloc_pages(16);
    assert(p0 != NULL);
    cprintf("Allocated 16 pages: p0=%p\n", p0);
    free_pages(p0, 16);

    // 测试碎片
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

    // 打印空闲块统计
    cprintf("\nFree blocks:\n");
    for (int i = 0; i < MAX_ORDER; i++)
    {
        if (buddy_area.nr_free[i] > 0)
        {
            cprintf("Order %d (2^%d=%d pages): %d blocks\n",
                    i, i, 1 << i, buddy_area.nr_free[i]);
        }
    }
    cprintf("Total free pages: %d\n", buddy_nr_free_pages());
   
}

```

**运行测试**

1.在 `kern/init/init.c` 的 `pmm_init` 函数中，将 `pmm_manager` 指向 `buddy_pmm_manager`。

```c
  const struct pmm_manager *pmm_manager = &buddy_pmm_manager;
```

2.在 `pmm_init` 函数的末尾，调用 `pmm_manager->check()`。

```c
  pmm_manager->init_memmap(base, n);
  pmm_manager->check();
```

3.执行以下命令重新编译并运行 uCore ：

```bash
$ make clean
$ make
$ make qemu
```

结果如图：

<img src="C:\Users\hpkjy\AppData\Roaming\Typora\typora-user-images\image-20251014200756786.png" alt="image-20251014200756786" style="zoom:67%;" />

测试结果显示我们伙伴系统成功地完成了基本内存块的**分配**和**释放**（如分配1、2、4页的块），**分裂**（为满足小请求而拆分大块）和**合并**（将释放的相邻伙伴块组合成大块）机制也工作正常。

在一系列碎片化的分配和释放10个单页块后， `Free blocks statistics` 显示系统中存在大量高阶的空闲块（如Order 10, 7, 5等），不是一堆零碎的低阶小块。说明我们的合并逻辑非常有效，减少了外部碎片。

#### 扩展练习Challenge：任意大小的内存单元slub分配算法（需要编程）

slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。

 - 参考[linux的slub分配算法/](http://www.ibm.com/developerworks/cn/linux/l-cn-slub/)，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

**实验原理和设计思路**

SLUB 分配器构建在底层的物理内存管理器（PMM，如 Buddy System）之上，形成了一个**两层内存管理架构**。

对于小于一个页面的小对象分配，如果直接使用 PMM 分配整个页面，很容易出现内部碎片。SLUB 将一个页面（ `slab`）切分成多个固定大小的小对象，按需分配。通过预先分配和缓存对象，`kmalloc` 和 `kfree` 的操作通常只是简单的指针操作，避免了昂贵的页面分配和查找过程，也提高了 CPU 缓存的命中率。

```
+------------------------------------------------+
|                 应用程序/内核代码                 |
|          kmalloc(size) | kfree(obj)            |
+-----------------------|------------------------+
                        V
+------------------------------------------------+
|                SLUB 分配器                      |
|  - 管理不同大小类别的 slub_cache                  |
|  - 在 slab 页面内分配/释放 object                 |
+-----------------------|------------------------+
                        V (当需要新页面时)
+------------------------------------------------+
|           物理内存管理器 (PMM)                    |
|   (e.g., Buddy System, Best-Fit)               |
|         alloc_pages() | free_pages()           |
+------------------------------------------------+
```

2. **数据结构设计**

SLUB 的核心是 `slub_cache` 和 `slab` 这两个结构体。

`slub_cache` 是一个特定大小对象的“管理器”。系统会为每种大小的对象（如16字节、32字节、64字节等）创建一个 `slub_cache`。

```c
struct slub_cache {

  size_t object_size;    // 此 cache 管理的对象大小

  size_t objects_per_slab; // 每个 slab 能容纳多少个对象

  list_entry_t slabs_partial; // 部分空闲的 slab 链表

  list_entry_t slabs_full;   // 完全占满的 slab 链表

  unsigned int nr_slabs;   // 此 cache 总共拥有的 slab 数量

};
```

其中 `slabs_partial`链接所有部分被使用的 slab。`kmalloc` 会优先从这个链表中寻找空间。`slabs_full `链接所有**已无空闲对象**的 slab。当 `slabs_partial` 中的一个 slab 被用完时，它会被移到这里。

`slab` 本质上就是一个物理页面，其头部包含元数据，其余空间被划分为多个固定大小的对象。

```c
struct slab {
  void *freelist;     // 指向第一个空闲对象的指针 (形成一个链表)
  size_t inuse;      // 已分配的对象数量
  size_t free_count;    // 剩余空闲对象数
  struct Page *page;    // 指向此 slab 对应的 Page 结构体
  list_entry_t slab_link; // 用于链接到 cache 的链表节点
};
```

所有空闲对象通过在对象自身存储下一个空闲对象的地址，形成一个侵入式单向链表。

我们来看一下cache和slabs的关系：

```
caches[i] (for 64-byte objects)

+------------------+

| object_size: 64  |

| slabs_partial ---|---> [Slab A] <--> [Slab C] <--> ...

| slabs_full    ---|---> [Slab B] <--> [Slab D] <--> ...

+------------------+
```



```
[Slab A] 是一个物理页面
+--------------------------------------------------------------------+
| meta: {freelist -> obj2, inuse: 2, ...} | obj1 | obj2 | obj3 | ... |
+---------------------------------------- |------|------|------|-----+
                                          |(used)|  |   |(used)|
                                                V   |  
                                              [obj4]<-+
                                                |
                                                V
                                               NULL
```

在上图中，`Slab A` 是一个部分使用的 slab。它的 `freelist` 指向 `obj2`，而 `obj2` 的内存空间里存储着下一个空闲对象 `obj4` 的地址，`obj4` 指向 `NULL`，表示空闲链表结束。

3. **代码编写步骤**

1.`slub_init()`初始化函数

```c
void slub_init(void)
{
    cprintf("Initializing Slabs\n");

    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
    {
        caches[i].object_size = size_classes[i];

        // 计算每个slab可容纳的对象数
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
```

遍历预设的 `size_classes` 数组，为每个大小类别初始化一个 `caches[i]` 结构体。用一个页面 `PGSIZE` 减去 `sizeof(struct slab)` 的元数据开销，再除以对象大小，就得到了每个 slab 能容纳的对象数量。最后初始化 `slabs_partial` 和 `slabs_full` 链表。

2.**`kmalloc(size_t size)`**

```c
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

    // 1. 尝试从partial链表获取slab
    if (!list_empty(&cache->slabs_partial))
    {
        list_entry_t *le = list_next(&cache->slabs_partial);
        slab = to_struct(le, struct slab, slab_link);
    }
    // 2. 创建新的slab
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

    // 如果slab已满，移动到full链表
    if (slab->free_count == 0)
    {
        list_del(&slab->slab_link);
        list_add(&cache->slabs_full, &slab->slab_link);
    }

    // 清零对象内存
    memset(object, 0, cache->object_size);

    return object;
}
```

我们先根据请求的 `size`，通过 `get_size_class_index` 找到最合适的 `slub_cache`。优先从 `cache->slabs_partial` 链表中取出一个 slab。 如果 `slabs_partial` 为空，则调用 `slub_create_slab` 创建一个***新的 slab**。

创建新 Slab 时先调用 `alloc_page()` 从底层 PMM 获取一个新页面。初始化 `struct slab` 元数据后遍历页面中所有对象的存储空间，将它们像串珠子一样链接起来，形成初始的空闲对象链表。将这个新创建的 slab 添加到 `slabs_partial` 链表中。

接着分配对象，从所选 slab 的 `freelist` 中“弹出”第一个空闲对象，更新 `freelist` 指向下一个空闲对象。最后更新 slab 的 `inuse` 和 `free_count` 计数。

3.**`kfree(void \*obj)`**

```c
void kfree(void *obj)
{
    if (obj == NULL)
    {
        return;
    }

    // 获取对象所属的页面
    struct Page *page = addr_to_page(obj);
    struct slab *slab = (struct slab *)page2kva(page);

    // 找到对应的cache
    struct slub_cache *cache = NULL;
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
    {
        if (caches[i].object_size >= ((char *)obj - (char *)slab))
        {
            // 简化判断：通过偏移粗略确定
            cache = &caches[i];
            break;
        }
    }

    if (cache == NULL)
    {
        // 可能是大对象，直接释放页面
        free_page(page);
        return;
    }

    // 判断slab之前的状态
    bool was_full = (slab->free_count == 0);

    // 将对象加入freelist
    *(void **)obj = slab->freelist;
    slab->freelist = obj;
    slab->inuse--;
    slab->free_count++;

    // 根据使用情况调整链表
    if (slab->free_count == cache->objects_per_slab)
    {
        // 完全空闲，释放slab
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
```

`addr_to_page(obj)` 函数可以从任意一个对象地址反向定位到它所在的物理页面，从而找到 `struct slab` 的元数据，再根据对象大小（或通过其他机制）找到对应的 `slub_cache`。

我们将被释放的对象 `obj` “压入”slab 的 `freelist` 头部，更新 slab 的 `inuse` 和 `free_count` 计数。

如果 slab 之前是满的（`was_full`），现在因为释放而有了空位，则将其从 `slabs_full` 链表移回到 `slabs_partial` 链表，以便下次分配时重用。如果 slab 在释放后完全空闲（`inuse == 0`），则直接调用 `free_page()` 将整个页面归还给底层 PMM，以回收内存。

4.**测试思路与过程**

1.测试不同大小的对象能否被正确分配和释放。我们连续为每个主要的大小类别分配一个对象，验证所有`slub_cache` 都能正常工作，并能成功创建和使用新的 slab。

```c
    void *obj1 = kmalloc(16);
    void *obj2 = kmalloc(32);
    void *obj3 = kmalloc(64);
    void *obj4 = kmalloc(128);

    assert(obj1 != NULL && obj2 != NULL && obj3 != NULL && obj4 != NULL);
    cprintf("  Allocated: obj1=%p, obj2=%p, obj3=%p, obj4=%p\n",
            obj1, obj2, obj3, obj4);
```

2.我们向之前分配的对象中写入数据 （字符串和整数),验证返回的内存地址有效且可用。

```c
    strcpy((char *)obj1, "Hello");
    *(int *)obj2 = 12345;
    cprintf("  obj1='%s', obj2=%d\n", (char *)obj1, *(int *)obj2);
```

3.释放所有对象。

```c
kfree(obj1);
kfree(obj2);
kfree(obj3);
kfree(obj4);
```

4.在一个循环中分配大量（如20个）相同大小的对象，然后全部释放。强制 slab 从 `partial` 状态转移到 `full` 状态，然后再因为释放而移回 `partial`，甚至可能因为完全空闲而被回收，测试鲁棒性。

```c
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
```

5.测试碎片。分配一组对象，然后交错地释放其中一部分，再重新分配，最后全部释放。

```c
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
cprintf("  释放完所有slabs\n");

for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
{
    if (caches[i].nr_slabs > 0)
    {
        cprintf("  Size %d: %d slabs\n",
                size_classes[i], caches[i].nr_slabs);
    }
}

```

**测试结果**

我们设计的SLUB 依赖于 PMM，我把PMM配置为 `buddy_pmm_manager`，因为 Buddy System 能高效地提供页面。

执行下列命令编译执行：

```bash
$ make clean
$ make
$ make qemu
```

输出结果如下：

<img src="C:\Users\hpkjy\AppData\Roaming\Typora\typora-user-images\image-20251015141132272.png" alt="image-20251015141132272" style="zoom:67%;" />

输出结果显示我们成功分配了四个不同大小的对象，且可以正常读写，可以正常被释放。连续分配20个64字节的对象也无误，没有出现内存泄漏现象。在内存碎片化情况下SLUB仍然能正确重用之前释放的对象空间。freelist链表管理逻辑没有问题。

#### 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）

  - 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？


> Challenges是选做，完成Challenge的同学可单独提交Challenge。完成得好的同学可获得最终考试成绩的加分。