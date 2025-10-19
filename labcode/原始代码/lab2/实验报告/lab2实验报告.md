# Lab2 实验报告：物理内存管理

## 练习1：理解 first-fit 连续物理内存分配算法

###  一、对于原代码按顺序逐行梳理，并分析每个函数作用

#### 1. 主体代码前

`#include` 一系列库文件和头文件。

```
static free_area_t free_area;
#define ......
```

▲ 观察 `memlayout.h` 中结构体 `free_area_t` 的定义，了解到该结构体用来维护一个记录单个 pmm 管理器中未使用的 page 的 **双向链表** 结构（在实验手册中已经详细介绍双向链表的实现，准确来说是 “环状双向链表”）。下面两个宏定义分别对应结构体中定义到的两个成员变量，分别是双向链表本身和空闲页的总数，宏定义使得下面的访问更加便利。

#### 2. default_init 函数

```
list_init(&free_list);
nr_free = 0;
```

▲ 封装地调用 `list_init` 初始化空闲链表，并将空闲页数置零。

#### 3. default_init_memmap 函数

这个函数是在根据传入的内存范围（起始页和页数）建立空闲页链表。

首先断言监测输入有效性。

```
for (; p != base + n; p ++) {
    assert(PageReserved(p));
    p->flags = p->property = 0;
    set_page_ref(p, 0);
}
```

▲ 然后在循环中，依次——先检查页是否是被系统保留（Reserved）为可用状态的，然后清空引用数（ref，表示这个页正在被多少个地方访问）。

```
base->property = n;
SetPageProperty(base);
nr_free += n;
```

▲ 在接下来标记块头页（base）为空闲/可分配（property 相关的意义在指导书中已经说明，property 参量为以当前页为头的块内有多少个连续的页）。然后空闲页数加上这次被初始化的页数量。

```
if (list_empty(&free_list)) {
    list_add(&free_list, &(base->page_link));
} else {
    list_entry_t* le = &free_list;
    while ((le = list_next(le)) != &free_list) {
		......
    }
}
```

▲ 接下来一块的 `if-else` 分支语句用于将这次初始化的空闲页放入空闲双向链表中，主要逻辑是：(1) 如果双向列表现在为空，直接插入即可；(2) 如果不空，遵循地址顺序，从头遍历双向链表，直到找到正确的地址，插入。注意这里遍历时候使用到了指导书中提到的，特别设计的**抽象**的双向链表节点 `list_entry`，可以适配到任何实际的数据类型/结构。

#### 4. default_alloc_pages 函数

<big>★ 这个函数是整个算法的核心逻辑实现，按照程序给出的要求从链表中分配出合适的连续 **物理页内存**，给程序使用。</big>

首先仍然进行参数检查，以及如果可用页不足，直接返回 `NULL`.

接下来是 **“first-fit 连续物理内存分配算法”** 的核心逻辑实现：

```
struct Page *page = NULL;
list_entry_t *le = &free_list;
while ((le = list_next(le)) != &free_list) {
    struct Page *p = le2page(le, page_link);
    if (p->property >= n) {
        page = p;
        break;
    }
}
```

▲ 使用了 `list_entry` 进行双向空闲列表的遍历，并且在遍历过程中不断进行判断，找到 **第一块能够满足大小要求的空闲块**，也就是一块页内存（就是 “first-fit” 的实际含义）。

接下来对于找到合适块的情况，进行从链表中取出块的相关处理。首先将块从链表中取下（代码略）。

```
if (page->property > n) {
    struct Page *p = page + n;
    p->property = page->property - n;
    SetPageProperty(p);
    list_add(prev, &(p->page_link));
}
```

▲ 当代码块大小超过要求的大小时，拆分块，将超过要求的部分重新作为一个新的块插入到链表中，使用到了 `list_add`.

而后进行分配后一些全局状态的修改，按需减少了总空闲页数，并清空了分配出去的页的 property 标志，表示它不再空闲可用于分配。最后返回分配出来的页，注意返回的是这一块连续内存的**首地址**。

#### 5. default_free_pages 函数

用于释放一定数量的目前不再使用的连续物理页内存资源。

首先依旧检查传参正确，以及要清零的页确实都是已经分配过的。然后预先清零标志和 ref 引用数量。

```
base->property = n;
SetPageProperty(base);
nr_free += n;
```

▲ 这里继续去除要清除页的被分配状态，分别把当前连续内存首个页标记为空闲块、更新空闲页的总数。

下一块 `if-else` 分支语句是把新的空闲块插入双向链表，实现原理和上一函数 `default_alloc_pages` 中的插入是一样的。

下面分别进行插入后的前后合并尝试。
前合并：

```
list_entry_t* le = list_prev(&(base->page_link));
if (le != &free_list) {
    p = le2page(le, page_link);
    if (p + p->property == base) {
        p->property += base->property;
        ClearPageProperty(base);
        list_del(&(base->page_link));
        base = p;
    }
}
```

后合并：

```
le = list_next(&(base->page_link));
if (le != &free_list) {
    p = le2page(le, page_link);
    if (base + base->property == p) {
        base->property += p->property;
        ClearPageProperty(p);
        list_del(&(p->page_link));
    }
}
```

核心的逻辑都是：

- 先取前一个或后一个 `list_entry` 元素，如果不是表头就可能可以发生合并;
- 接着判断两个待合并的两个块中物理地址较前的一个，加上 property（也就是有多少个连续的页）后，是否是下一块的首地址，这一结果成立就说明两个块是在物理内存意义上紧接着连续的，那么就可以发生合并;
- 然后将前一个块的 property 加上后一个块的 property，再调用 `list_del` 删掉后一个块，就得到了新的、合并后的、更大的块。

#### 6. default_nr_free_pages 函数

只是一个简单的封装函数，返回当前空闲页的个数。	

#### 7. 在这之后

是对于 **“first-fit 连续物理内存分配算法”** 的测试函数。

- `basic_check` 测试最基础的页分配、释放，以及 `free_list` 的功能是否正常。
- `default_check` 测试更综合更复杂，如大量页的分配 -> 块拆分、释放 -> 块合并等，拥有一个更加完整的页管理流程。
  最后还有 `pmm_manager` 的实例化，手册中介绍比较详细了不再赘述。


***

### 二、一些细节

#### 1. PageReserved -> 一系列同类宏定义函数

在 `memlayout.h` 中定义了一些列函数：

```
#define SetPageReserved(page)       ((page)->flags |= (1UL << PG_reserved))
#define ClearPageReserved(page)     ((page)->flags &= ~(1UL << PG_reserved))
#define PageReserved(page)          (((page)->flags >> PG_reserved) & 1)
#define SetPageProperty(page)       ((page)->flags |= (1UL << PG_property))
#define ClearPageProperty(page)     ((page)->flags &= ~(1UL << PG_property))
#define PageProperty(page)          (((page)->flags >> PG_property) & 1)
```

▲ 其中包含了上面代码实现中的 `PageReserved` 函数。
而在此之前，对 reserved 标志位和 property 标志位在 flag 中的位置进行了划分，分别在低位起的第0和第1位：

```
#define PG_reserved                 0       // if this bit=1: the Page is reserved for kernel, cannot be used in alloc/free_pages; otherwise, this bit=0 
#define PG_property                 1       // if this bit=1: the Page is the head page of a free memory block(contains some continuous_addrress pages), and can be used in alloc_pages; if this bit=0: if the Page is the the head page of a free memory block, then this Page and the memory block is alloced. Or this Page isn't the head page.
```

▲ 注释也说明了，`reserved = 0` 说明页处于可分配给程序使用的状态，否则不能够分配；`property = 1` 说明当前页是当前物理内存块的头页，否则有两种情况：(1) 头页代表的物理内存块已被分配；(2) 当前页不是头页。

那么上面那些宏函数的实现是如何的？
它们以定义的标志位位置为左移/右移位数，然后与页本身的 flag 或单 bit 立即数进行位运算，便可以对页 flag 进行更新或监测当前 flag 中对应的标志位是0还是1. 

```
1UL是什么？
U = Unsigned：无符号数
L = Long：长整型
——无符号长整型1
不直接写作1（默认int型），是为了防止位移导致溢出/未定义行为。
```

比如：`#define PageReserved(page)          (((page)->flags >> PG_reserved) & 1)`
这时 flag 左移0位，`&` 只会将最低位进行与运算，那么就可以运算监测 flag 的最低位，也就是 reserved 标志位是0还是1.

#### 2. set_page_ref -> 什么是 ref？

ref 是 Page 结构体中的一个成员变量，当 `ref > 0` 时，页被 “引用/正在使用”，不能够回收释放或当作空闲页；当 `ref == 0` 时，没有任何地方正在使用，那么就可以释放作为空闲页（其它标志也允许的前提下）。

在 `pmm.h` 中可以看到，除了 `set_page_ref` 函数之外，还有配套的 `page_ref_inc` 和 `page_ref_dec` 分别用来增加和减少页面的被引用次数，这在实际多进程运行中是重要的。

常见的 “引用” 来源有<small>（询问了大模型帮助了解）</small>：

- 页表中有虚拟页映射到该物理页，一个映射对应一个引用。
- 内核数据结构（缓存、内存池等）持有该页。
- DMA/外部设备正在访问页面。
- 作为页面缓存的一部分被多个用户共享。

#### 3. le2page 转化

在上面的代码实现中，使用到了 le2page 宏定义，能够将 `list_entry` 向上一级转化到对应的 Page 结构体。实验指导书中已经有比较详细的介绍

```
#define le2page(le, member)                 \
    to_struct((le), struct Page, member)
```

```
#define to_struct(ptr, type, member)                               \
    ((type *)((char *)(ptr) - offsetof(type, member)))
```

```
#define offsetof(type, member)                                      \
    ((size_t)(&((type *)0)->member))
```

▲ 使用层级递进的宏定义：先假设地把结构体放在0地址，得到 `list_entry` 的 offset，而后将 `list_entry` 指针减去 offset 得到结构体起始地址，就可以最终将 `list_entry` 转化成 Page 结构体。

#### 4. list_init 在做什么？

很简单，创建一个新的环状双向链表记录空闲页。

```
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
}
```

实际上，环状双向链表需要一个不对应实际页内存块的节点用来表示表头（也表示表尾，因为是环状）。在遍历开始时，以及回收页面时判断能否合并等工作时都需要利用其作为切入点或进行边界判断。在上面新建链表的代码中，就是先仅仅创建出了这个并没有有效数据的节点，此时链表为空。

```
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
}
```

▲ 判断链表为空的逻辑也可以证明上面的设计推理：为空的条件是列表起始 `list_entry`（全部用 `list` 表示）的下一个 `list_entry` 还是它本身。上面初始化中 `elm->prev = elm->next = elm` 的赋值导致这个条件一定被满足，说明上面刚创建出来的就是没有数据的链表，为空。

***

### 三、整体工作流程归纳

#### 1. 内核启动到整个物理内存初始化结束，函数/结构体的调用过程：

`kern_init --> pmm_init --> page_init --> init_memmap --> pmm_manager --> init_memmap`
通过 page_init 解析可以自由使用的物理内存区间，通过 init_memmap 初始化这一整块自由物理内存区间，pmm 用来查询当前使用内存分配策略下函数的实际地址。
在 first-in 的方法下，pmm_manager 被实例化为 default_pmm_manager，init_memmap 也被相应地赋值（指针的赋值）到 default_init_memmap：

```
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};
```

#### 2. 初始化之后的具体操作

初始化完成之后就可以由程序申请页获得运行空间，这中间 `alloc_pages` 和 `free_pages` 将被频繁地交叉调用，按照 first-fit 的方式分配页，并释放回收不再使用的页。当然这里的两个函数也已经在实例化过程中被函数指针地赋值为 `default_···` 方法。此外还会发生 `nr_free_pages` 的查询。

***


### 四、原代码改进空间

#### 1. 代码复用改进

在 `default_init_memmap` 和 `default_free_pages` 出现了完全相同的两段 “插入新的空闲页到双向链表中” 的逻辑。这一块代码可以进一步 **封装为函数**，避免代码复用而造成冗余。

#### 2. 缺少锁机制

在实际的操作系统运行环境下，有多个进程来申请页面，将会导致冲突。这时候需要给分配页、向链表插入页块和从链表卸下页块等原子性操作加锁，保证线程安全。包括 ref 的更新等，也可使用 atomic 库的方法来做。

#### 3. 算法设计与策略“本质上”的改进

first-fit 本质上并不是一个效率高的算法，因为它在最坏的情况下每次都需要遍历全部链表元素，时间复杂度是 $O(n)$ 级别的。可以改进算法，使用更快的 best-fit 或者 next-fit 等，优化链表的排序方法、分配块的查找策略。

#### 4. 算法设计与策略“非本质上”的改进

和上一条同样的出发点，可以通过一些额外的数据结构来优化链表访问。比如升级为维护一个双向的 **跳表**，虽然会带来额外的空间代价，并且会在插入和卸下的时候消耗更多时间，但相对于 $O(n)$ 到 $O(log~n)$ 级别时间复杂度的优化，访问效率还是提升了。

#### 5. 宏定义可能带来的不便

```
static free_area_t free_area;
#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)
```

对于这样的宏定义，会直接暴露 `free_area` 的内部成员；而且如果对于成员名进行修改，不会有编译器类型检查，容易导致隐藏的 bug 出现。所以从上面两点考虑，更好的方法还是回到封装函数访问。



## 练习2：实现Best-Fit连续物理内存分配算法

### 设计实现过程

#### 设计思路

Best-Fit算法的核心思想是：**在所有能满足需求的空闲块中，选择大小最接近需求的那一个**。

**与First-Fit的本质区别**：

- **First-Fit**：找到第一个满足大小的块就立即停止，时间复杂度最好情况O(1)
- **Best-Fit**：必须遍历整个空闲链表，找到最小的满足块，时间复杂度O(n)

**设计目标**：
1. 减少大块的浪费，保留大块用于大请求
2. 通过精确匹配减少内存碎片
3. 保持链表按地址有序，便于合并操作

**数据结构设计**：
- 使用双向链表管理空闲块（与First-Fit相同）

- 每个空闲块的首页用property记录块大小

- 维护全局计数器nr_free记录总空闲页数

  

### 实现代码与说明

#### 1. `best_fit_init_memmap()` 实现

```c
static void best_fit_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        // 清空当前页框的标志和属性信息，并将页框的引用计数设置为0
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            // 找到第一个大于base的页，将base插入到它前面
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                // 已经到达链表结尾，将base插入到链表尾部
                list_add(le, &(base->page_link));
            }
        }
    }
}
```

**实现要点**：
- 初始化每个页面的flags、property、引用计数
- 按地址顺序插入链表，保持链表有序
- **注意**：在插入到链表末尾时必须加`break`，否则会继续无意义的循环

#### 2. `best_fit_alloc_pages()` 实现（核心）

这是Best-Fit算法的**核心部分**，体现了"最佳适配"的思想。

```c
static struct Page *best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;  // 初始化为一个不可能的大值
    
    // 遍历整个空闲链表，找到最小的满足需求的块
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        // 如果当前块满足需求且比之前找到的块更小
        if (p->property >= n && p->property < min_size) {
            page = p;
            min_size = p->property;
        }
    }

    // 分配找到的最佳块
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        
        // 如果块较大则分割
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

**关键改动与实现细节**：

1. **初始化最小值**：`min_size = nr_free + 1`
   
- 设为不可能达到的大值，确保第一个满足条件的块能被记录
  
2. **完整遍历策略**：
   ```c
   if (p->property >= n && p->property < min_size) {
       page = p;
       min_size = p->property;
   }
   ```
   - **不能**在找到第一个满足的块时就break（这是First-Fit的做法）
   - 必须遍历完整个链表，找到所有满足条件中最小的
   - 每次发现更小的满足块时更新`page`和`min_size`

3. **分割剩余块**：
   ```c
   if (page->property > n) {
       struct Page *p = page + n;
       p->property = page->property - n;
       SetPageProperty(p);
       list_add(prev, &(p->page_link));
   }
   ```
   - 如果最佳块大于需求，将剩余部分作为新块插回链表
   
   - 插入到原块的前驱位置，保持地址有序
   
     

#### 3. `best_fit_free_pages()` 实现

```c
static void best_fit_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    
    // 设置当前页块的属性
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    // 按地址顺序插入链表
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    // 尝试向前合并
    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        // 判断前面的空闲页块是否与当前页块连续
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    // 尝试向后合并
    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
```

**实现要点**：
- 重置页面状态并设置块属性

- 按地址顺序插入链表

- 向前和向后尝试合并相邻的空闲块

- **注意**：合并后要更新base指针，以便继续向后合并

  

### 物理内存分配和释放的详细流程

#### 内存分配流程（best_fit_alloc_pages）

![page_allocation_flowchart](C:\Users\xiongcy\Desktop\lab2\img\page_allocation_flowchart.png)

**关键点说明**：

- **Best-Fit的本质**：第2步必须遍历完整个链表，不能提前退出
- **分割策略**：精确分配所需页数，剩余部分返回链表，避免内部碎片
- **地址有序性**：剩余块插入到原块位置，维护链表的地址有序特性

#### 内存释放流程（best_fit_free_pages）

![memory_free_flowchart](C:\Users\xiongcy\Desktop\lab2\img\memory_free_flowchart.png)



**合并操作的关键逻辑**：

```c
// 判断物理地址连续的条件
p + p->property == base  // 前驱块的末尾 = 当前块的开头

base + base->property == p  // 当前块的末尾 = 后继块的开头
```

**合并的优势**：
- 减少外部碎片
- 维护更少的空闲块节点
- 提高后续大块分配的成功率



### 测试与验证

编译并运行测试：

```bash
make clean
make
make qemu
```

预期输出应包含：

- `check_alloc_page() succeeded!`
- `best_fit_check() succeeded!`

```bash
make grade
```

![2734c3ea241be49d0dda3e7ce21228d](C:\Users\xiongcy\Desktop\lab2\img\2734c3ea241be49d0dda3e7ce21228d.png)

这表明Best-Fit算法实现正确，通过了所有测试用例。



### 进一步改进

​		将空闲链表改为**按块大小从小到大排序**后，分配操作的效率可以显著提升。当前实现采用地址排序，每次分配时必须遍历整个链表来找到最小的满足块，时间复杂度始终为O(n)。而按大小排序后，由于链表已经有序，第一个满足条件（`property >= n`）的块就是最小的满足块，可以立即返回，无需继续遍历。特别是在完美匹配的情况下（请求大小正好等于某个空闲块），性能提升更为明显，可以直接在链表前部快速定位，避免了全链表扫描。

​		按大小排序使得Best-Fit算法的核心逻辑更加简洁和符合直觉——"找到第一个满足条件的块即为最佳匹配"，消除了当前实现中需要维护`min_size`变量并持续更新的复杂性。同时，这种排序方式还带来了额外的优势：小块集中在链表前部，提高了CPU缓存命中率，因为大多数分配请求会频繁访问链表头部区域。虽然这种改进会增加释放操作的复杂度（合并后可能需要重新调整块在链表中的位置），但考虑到操作系统中分配操作的频率通常远高于释放操作，总体性能提升仍然显著且能更精确地匹配请求大小，从而减少内存碎片。

























## 重要知识点总结

#### 1. OS原理对应的知识点

| 实验知识点 | OS原理知识点 | 关系说明 |
|-----------|-------------|---------|
| First-Fit算法 | 动态分区分配 | 实验实现了教材中的经典算法 |
| Best-Fit算法 | 动态分区分配 | 通过遍历找最优解，减少碎片 |
| 空闲链表管理 | 空闲块管理 | 用双向链表维护空闲块信息 |
| 页面合并 | 碎片整理 | 释放时的即时合并策略 |
| Page结构体 | 页表项 | 操作系统对物理页面的抽象 |

#### 2. 实验中的重要概念

- **property字段**：记录空闲块的大小（仅块首页有效）
- **PG_property标志**：标识该页是否为空闲块首页
- **页面合并**：释放时自动合并相邻空闲块，减少外部碎片
- **地址有序**：链表按物理地址排序，便于合并操作

#### 3. 实现难点与收获

**难点**：
- 理解链表操作宏（`le2page`, `list_add_before`等）
- 正确处理块分割和合并的边界情况
- Best-Fit算法需要完整遍历链表的逻辑

**收获**：
- 深入理解了物理内存管理的底层实现
- 掌握了First-Fit和Best-Fit算法的优缺点
- 学会了如何使用链表管理动态数据结构

### OS原理中重要但实验未涉及的知识点

1. **分页与分段结合**：实验仅实现了页式管理
2. **多级页表**：实验使用简单的页面管理，未涉及多级页表
3. **虚拟内存**：实验专注于物理内存，虚拟内存在后续实验
4. **页面置换算法**：LRU、Clock等算法未在本实验中体现
5. **内存保护**：权限控制、越界检查等安全机制
6. **NUMA架构**：现代多核系统的内存访问优化




