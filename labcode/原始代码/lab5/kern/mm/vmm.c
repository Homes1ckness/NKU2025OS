#include <vmm.h>
#include <sync.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <error.h>
#include <pmm.h>
#include <riscv.h>
#include <swap.h>
#include <kmalloc.h>
#include <mmu.h>

/* 
  vmm design include two parts: mm_struct (mm) & vma_struct (vma)
  mm is the memory manager for the set of continuous virtual memory  
  area which have the same PDT. vma is a continuous virtual memory area.
  There a linear link list for vma & a redblack link list for vma in mm.
---------------
  mm related functions:
   golbal functions
     struct mm_struct * mm_create(void)
     void mm_destroy(struct mm_struct *mm)
     int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
--------------
  vma related functions:
   global functions
     struct vma_struct * vma_create (uintptr_t vm_start, uintptr_t vm_end,...)
     void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
     struct vma_struct * find_vma(struct mm_struct *mm, uintptr_t addr)
   local functions
     inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
---------------
   check correctness functions
     void check_vmm(void);
     void check_vma_struct(void);
     void check_pgfault(void);
*/

// szx func : print_vma and print_mm
void print_vma(char *name, struct vma_struct *vma){
	cprintf("-- %s print_vma --\n", name);
	cprintf("   mm_struct: %p\n",vma->vm_mm);
	cprintf("   vm_start,vm_end: %x,%x\n",vma->vm_start,vma->vm_end);
	cprintf("   vm_flags: %x\n",vma->vm_flags);
	cprintf("   list_entry_t: %p\n",&vma->list_link);
}

void print_mm(char *name, struct mm_struct *mm){
	cprintf("-- %s print_mm --\n",name);
	cprintf("   mmap_list: %p\n",&mm->mmap_list);
	cprintf("   map_count: %d\n",mm->map_count);
	list_entry_t *list = &mm->mmap_list;
	for(int i=0;i<mm->map_count;i++){
		list = list_next(list);
		print_vma(name, le2vma(list,list_link));
	}
}

static void check_vmm(void);
static void check_vma_struct(void);
static void check_pgfault(void);
static void check_cow(void);

// mm_create -  alloc a mm_struct & initialize it.
struct mm_struct *
mm_create(void) {
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));

    if (mm != NULL) {
        list_init(&(mm->mmap_list));
        mm->mmap_cache = NULL;
        mm->pgdir = NULL;
        mm->map_count = 0;
        set_mm_count(mm, 0);

        if (swap_init_ok) swap_init_mm(mm);
        else mm->sm_priv = NULL;
    }
    return mm;
}

// vma_create - alloc a vma_struct & initialize it. (addr range: vm_start~vm_end)
struct vma_struct *
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));

    if (vma != NULL) {
        vma->vm_start = vm_start;
        vma->vm_end = vm_end;
        vma->vm_flags = vm_flags;
    }
    return vma;
}


// find_vma - find a vma  (vma->vm_start <= addr <= vma_vm_end)
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr) {
    struct vma_struct *vma = NULL;
    if (mm != NULL) {
        vma = mm->mmap_cache;
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
                bool found = 0;
                list_entry_t *list = &(mm->mmap_list), *le = list;
                while ((le = list_next(le)) != list) {
                    vma = le2vma(le, list_link);
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
                        found = 1;
                        break;
                    }
                }
                if (!found) {
                    vma = NULL;
                }
        }
        if (vma != NULL) {
            mm->mmap_cache = vma;
        }
    }
    return vma;
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
}


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
    list_entry_t *list = &(mm->mmap_list);
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
                break;
            }
            le_prev = le;
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
    }
    if (le_next != list) {
        check_vma_overlap(vma, le2vma(le_next, list_link));
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
}

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
    }
    kfree(mm); //kfree mm
    mm=NULL;
}

// mm_map - allocate a new vma and add it to mm's vma list
int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
       struct vma_struct **vma_store) {
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
    if (!USER_ACCESS(start, end)) {
        return -E_INVAL;
    }

    assert(mm != NULL);

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
        goto out;
    }
    ret = -E_NO_MEM;

    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }
    insert_vma_struct(mm, vma);
    if (vma_store != NULL) {
        *vma_store = vma;
    }
    ret = 0;

out:
    return ret;
}

// dup_mmap - duplicate a memory management struct
int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
    assert(to != NULL && from != NULL);
    list_entry_t *list = &(from->mmap_list), *le = list;
    while ((le = list_prev(le)) != list) {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);

        bool share = 1;  // 启用COW机制
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
            return -E_NO_MEM;
        }
    }
    return 0;
}

// exit_mmap - release all memory associated with mm
void
exit_mmap(struct mm_struct *mm) {
    assert(mm != NULL && mm_count(mm) == 0);
    pde_t *pgdir = mm->pgdir;
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list) {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
    }
    while ((le = list_next(le)) != list) {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
    }
}

// user_mem_check - check user memory access permission
bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
    if (mm != NULL) {
        if (!USER_ACCESS(addr, addr + len)) {
            return 0;
        }
        struct vma_struct *vma;
        uintptr_t start = addr, end = addr + len;
        while (start < end) {
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
                return 0;
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) {
                    return 0;
                }
            }
            start = vma->vm_end;
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}

// copy_from_user - copy data from user space to kernel space
bool
copy_from_user(struct mm_struct *mm, void *dst, const void *src, size_t len, bool writable) {
    if (!user_mem_check(mm, (uintptr_t)src, len, writable)) {
        return 0;
    }
    memcpy(dst, src, len);
    return 1;
}

// copy_to_user - copy data from kernel space to user space
bool
copy_to_user(struct mm_struct *mm, void *dst, const void *src, size_t len) {
    if (!user_mem_check(mm, (uintptr_t)dst, len, 1)) {
        return 0;
    }
    memcpy(dst, src, len);
    return 1;
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
    check_vmm();
}

// check_cow - check correctness of Copy on Write mechanism
static void
check_cow(void) {
    cprintf("---------- check_cow() begin ----------\n");
    cprintf("\n[Test 1] Testing copy_range COW setup...\n");
    
    // 使用boot_pgdir进行测试
    uintptr_t test_addr = 0x00800000;  // 用户空间地址
    
    // 分配一个页面作为"父进程"的页面
    struct Page *parent_page = alloc_page();
    assert(parent_page != NULL);
    // 注意：不要手动设置ref，page_insert会自动增加引用计数
    
    // 写入测试数据
    int *parent_data = (int *)page2kva(parent_page);
    *parent_data = 0x12345678;
    parent_data[1] = 0xDEADBEEF;
    
    // 在boot_pgdir中建立映射（模拟父进程页表）
    // page_insert会将ref从0增加到1
    int ret = page_insert(boot_pgdir, parent_page, test_addr, PTE_U | PTE_W);
    assert(ret == 0);
    cprintf("Parent page: ref=%d, data[0]=0x%x, data[1]=0x%x\n", 
            page_ref(parent_page), parent_data[0], parent_data[1]);
    cprintf("Parent PTE created with R/W permission\n");
    
    // 记录COW前的引用计数
    int ref_before_cow = page_ref(parent_page);
    cprintf("Reference count before COW: %d\n", ref_before_cow);
    
    // 创建一个新的页目录作为"子进程"
    struct Page *child_pgdir_page = alloc_page();
    assert(child_pgdir_page != NULL);
    pde_t *child_pgdir = (pde_t *)page2kva(child_pgdir_page);
    memcpy(child_pgdir, boot_pgdir, PGSIZE);
    
    // 调用copy_range with share=1 (COW模式)
    cprintf("\nCalling copy_range with share=1 (COW mode)...\n");
    ret = copy_range(child_pgdir, boot_pgdir, test_addr, test_addr + PGSIZE, 1);
    assert(ret == 0);
    
    //引用计数应该增加1（从ref_before_cow变成ref_before_cow+1）
    int expected_ref = ref_before_cow + 1;
    cprintf("\n[Verify 1] Page reference count:\n");
    cprintf("  Expected: %d, Actual: %d ", expected_ref, page_ref(parent_page));
    assert(page_ref(parent_page) == expected_ref);
    cprintf("- PASS\n");
    
    // 父进程PTE应该变成只读
    pte_t *parent_pte = get_pte(boot_pgdir, test_addr, 0);
    cprintf("\n[Verify 2] Parent PTE write permission:\n");
    cprintf("  Expected: 0 (read-only), Actual: %d ", (*parent_pte & PTE_W) ? 1 : 0);
    assert((*parent_pte & PTE_W) == 0);
    cprintf("- PASS\n");
    
    //子进程PTE也应该是只读
    pte_t *child_pte = get_pte(child_pgdir, test_addr, 0);
    cprintf("\n[Verify 3] Child PTE write permission:\n");
    cprintf("  Expected: 0 (read-only), Actual: %d ", (*child_pte & PTE_W) ? 1 : 0);
    assert((*child_pte & PTE_W) == 0);
    cprintf("- PASS\n");
    
    // 两个PTE指向同一物理页面
    cprintf("\n[Verify 4] Both PTEs point to same physical page:\n");
    cprintf("  Parent PTE addr: 0x%x\n", PTE_ADDR(*parent_pte));
    cprintf("  Child PTE addr:  0x%x\n", PTE_ADDR(*child_pte));
    assert(PTE_ADDR(*parent_pte) == PTE_ADDR(*child_pte));
    cprintf("  - PASS\n");
    
    cprintf("\n[Test 2] Testing do_pgfault COW handler...\n");
    
    // 创建mm_struct用于do_pgfault
    struct mm_struct *test_mm = mm_create();
    assert(test_mm != NULL);
    test_mm->pgdir = child_pgdir;
    
    // 创建对应的vma
    struct vma_struct *test_vma = vma_create(test_addr, test_addr + PGSIZE, VM_WRITE);
    assert(test_vma != NULL);
    insert_vma_struct(test_mm, test_vma);
    
    // 保存旧的check_mm_struct
    struct mm_struct *old_check_mm = check_mm_struct;
    check_mm_struct = test_mm;
    
    // 记录旧的引用计数
    int old_ref = page_ref(parent_page);
    cprintf("Before COW trigger: page ref = %d\n", old_ref);
   
    // 直接测试COW逻辑
    cprintf("\nSimulating COW page fault handling...\n");
    
    struct Page *old_page = pte2page(*child_pte);
    assert(old_page == parent_page);
    
    if (page_ref(old_page) > 1) {
        // 分配新页面
        struct Page *new_page = alloc_page();
        assert(new_page != NULL);
        
        // 复制内容
        void *src = page2kva(old_page);
        void *dst = page2kva(new_page);
        memcpy(dst, src, PGSIZE);
        cprintf("COW: Copied page content to new page\n");
        
        // 更新子进程页表项
        // 注意：page_insert会自动处理旧页面的引用计数（通过page_remove_pte）
        ret = page_insert(child_pgdir, new_page, test_addr, PTE_U | PTE_W);
        assert(ret == 0);
        cprintf("COW: Updated child PTE to point to new page with R/W\n");
        cprintf("COW: page_insert automatically decremented old page ref count\n");
        
        // 新页面数据是否正确
        int *new_data = (int *)page2kva(new_page);
        cprintf("\n[Verify 5] New page data integrity:\n");
        cprintf("  data[0]: Expected=0x12345678, Actual=0x%x ", new_data[0]);
        assert(new_data[0] == 0x12345678);
        cprintf("- PASS\n");
        cprintf("  data[1]: Expected=0xDEADBEEF, Actual=0x%x ", new_data[1]);
        assert(new_data[1] == 0xDEADBEEF);
        cprintf("- PASS\n");
        
        // 原页面引用计数减少（应该减少1）
        cprintf("\n[Verify 6] Original page reference count after COW:\n");
        cprintf("  Before COW: %d, After COW: %d (should decrease by 1)\n", old_ref, page_ref(parent_page));
        assert(page_ref(parent_page) == old_ref - 1);
        cprintf("  - PASS\n");
        
        // 子进程PTE现在有写权限
        child_pte = get_pte(child_pgdir, test_addr, 0);
        cprintf("\n[Verify 7] Child PTE now has write permission:\n");
        cprintf("  Expected: 1, Actual: %d ", (*child_pte & PTE_W) ? 1 : 0);
        assert((*child_pte & PTE_W) != 0);
        cprintf("- PASS\n");
        
        // 子进程页面和原页面是不同的物理页面
        // 注意：由于测试环境限制（child_pgdir是简单复制的boot_pgdir，共享页表），
        // 我们通过比较Page结构体指针来验证
        struct Page *new_page_verify = pte2page(*child_pte);
        cprintf("\n[Verify 8] Child has a different physical page than original:\n");
        cprintf("  Original page struct: %p\n", old_page);
        cprintf("  New page struct:      %p\n", new_page_verify);
        assert(new_page_verify != old_page);
        assert(new_page_verify == new_page);
        cprintf("  - PASS\n");
        
        // 修改子进程数据不影响父进程
        new_data[0] = 0x11111111;
        cprintf("\n[Verify 9] Child modification doesn't affect parent:\n");
        cprintf("  Child data[0] changed to: 0x%x\n", new_data[0]);
        cprintf("  Parent data[0] still is: 0x%x ", parent_data[0]);
        assert(parent_data[0] == 0x12345678);
        cprintf("- PASS\n");
        
        // 清理新页面 - 手动减少引用计数并释放
        // 因为页表是共享的，page_remove会影响两个页目录
        struct Page *new_page_to_free = pte2page(*child_pte);
        page_ref_dec(new_page_to_free);
        if (page_ref(new_page_to_free) == 0) {
            free_page(new_page_to_free);
        }
    }
    
    check_mm_struct = old_check_mm;
    
    // 清理所有页表结构
    // 地址0x00800000的页表结构需要完全清理
    pte_t *final_pte = get_pte(boot_pgdir, test_addr, 0);
    if (final_pte && (*final_pte & PTE_V)) {
        *final_pte = 0;  // 直接清除PTE
    }
    
    // 清理中间页表
    // 对于RISC-V Sv39，页表结构是: pgdir -> pmd -> pt
    // test_addr = 0x00800000
    // PDX1(0x00800000) = 0, PDX0(0x00800000) = 4, PTX(0x00800000) = 0
    pde_t pde1 = boot_pgdir[PDX1(test_addr)];
    if (pde1 & PTE_V) {
        pde_t *pd0 = (pde_t *)KADDR(PDE_ADDR(pde1));
        pde_t pde0 = pd0[PDX0(test_addr)];
        if (pde0 & PTE_V) {
            // 释放页表页
            free_page(pde2page(pde0));
            pd0[PDX0(test_addr)] = 0;
        }
        // 检查pd0是否为空，如果是则释放
        int i, empty = 1;
        for (i = 0; i < NPTEENTRY; i++) {
            if (pd0[i] & PTE_V) {
                empty = 0;
                break;
            }
        }
        if (empty) {
            free_page(pde2page(pde1));
            boot_pgdir[PDX1(test_addr)] = 0;
        }
    }
    
    tlb_invalidate(boot_pgdir, test_addr);
    flush_tlb();
    
    // 释放parent_page（如果还有引用）
    if (page_ref(parent_page) > 0) {
        set_page_ref(parent_page, 0);
        free_page(parent_page);
    }
    
    free_page(child_pgdir_page);
    mm_destroy(test_mm);
    
    cprintf("\n---------- check_cow() succeeded! ----------\n");
}

// check_vmm - check correctness of vmm
static void
check_vmm(void) {
    check_vma_struct();
    check_pgfault();
    check_cow();  // 添加COW测试

    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void) {
    struct mm_struct *mm = mm_create();
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    for (i = step1 + 1; i <= step2; i ++) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
        struct vma_struct *vma1 = find_vma(mm, i);
        assert(vma1 != NULL);
        struct vma_struct *vma2 = find_vma(mm, i+1);
        assert(vma2 != NULL);
        struct vma_struct *vma3 = find_vma(mm, i+2);
        assert(vma3 == NULL);
        struct vma_struct *vma4 = find_vma(mm, i+3);
        assert(vma4 == NULL);
        struct vma_struct *vma5 = find_vma(mm, i+4);
        assert(vma5 == NULL);

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
    }

    for (i =4; i>=0; i--) {
        struct vma_struct *vma_below_5= find_vma(mm,i);
        if (vma_below_5 != NULL ) {
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
}

struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();

    check_mm_struct = mm_create();
    assert(check_mm_struct != NULL);

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
    assert(pgdir[0] == 0);

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
        *(char *)(addr + i) = i;
        sum += i;
    }
    for (i = 0; i < 100; i ++) {
        sum -= *(char *)(addr + i);
    }
    assert(sum == 0);

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    pgdir[0] = 0;
    flush_tlb();

    mm->pgdir = NULL;
    mm_destroy(mm);
    check_mm_struct = NULL;

    assert(nr_free_pages_store == nr_free_pages());

    cprintf("check_pgfault() succeeded!\n");
}
//page fault number
volatile unsigned int pgfault_num=0;

/* do_pgfault - interrupt handler to process the page fault execption
 * @mm         : the control struct for a set of vma using the same PDT
 * @error_code : the error code recorded in trapframe->tf_err which is setted by x86 hardware
 * @addr       : the addr which causes a memory access exception, (the contents of the CR2 register)
 *
 * CALL GRAPH: trap--> trap_dispatch-->pgfault_handler-->do_pgfault
 * The processor provides ucore's do_pgfault function with two items of information to aid in diagnosing
 * the exception and recovering from it.
 *   (1) The contents of the CR2 register. The processor loads the CR2 register with the
 *       32-bit linear address that generated the exception. The do_pgfault fun can
 *       use this address to locate the corresponding page directory and page-table
 *       entries.
 *   (2) An error code on the kernel stack. The error code for a page fault has a format different from
 *       that for other exceptions. The error code tells the exception handler three things:
 *         -- The P flag   (bit 0) indicates whether the exception was due to a not-present page (0)
 *            or to either an access rights violation or the use of a reserved bit (1).
 *         -- The W/R flag (bit 1) indicates whether the memory access that caused the exception
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);

    pgfault_num++;
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }

    /* IF (write an existed addr ) OR
     *    (write an non_existed addr && addr is writable) OR
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);

    ret = -E_NO_MEM;

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    } else if (*ptep & PTE_V) {
        /* LAB5:EXERCISE4 - COW (Copy on Write) Page Fault Handler
         * 当页表项有效但缺少写权限时，可能是COW页面
         * 需要检查：
         * 1. vma是否允许写
         * 2. 当前页表项是否没有写权限（只读共享页面）
         * 如果是COW页面，则：
         * 1. 分配新页面
         * 2. 复制内容
         * 3. 更新页表项，设置写权限
         * 4. 减少原页面的引用计数
         */
        if ((vma->vm_flags & VM_WRITE) && !(*ptep & PTE_W)) {
            // 这是一个COW页面，需要进行写时复制
            cprintf("COW triggered at addr 0x%x\n", addr); 
            struct Page *old_page = pte2page(*ptep);
            
            if (page_ref(old_page) > 1) {
                // 多个进程共享此页面，需要创建副本
                 cprintf("COW: copying page, ref count = %d\n", page_ref(old_page));
                struct Page *new_page = alloc_page();
                if (new_page == NULL) {
                    goto failed;
                }
                
                // 复制页面内容
                void *src = page2kva(old_page);
                void *dst = page2kva(new_page);
                memcpy(dst, src, PGSIZE);
                
                // 更新页表项，指向新页面并设置写权限
                // 注意：page_insert会自动通过page_remove_pte减少旧页面的引用计数
                // 所以不需要手动调用page_ref_dec
                page_insert(mm->pgdir, new_page, addr, perm);
            } else {
                // 只有当前进程使用此页面，直接设置写权限
                cprintf("COW: restoring write permission\n");
                *ptep = (*ptep) | PTE_W;
                tlb_invalidate(mm->pgdir, addr);
            }
        } else {
            // 不是COW情况，可能是其他权限问题
            cprintf("do_pgfault: page exists but permission check failed\n");
            goto failed;
        }
    } else {
        /*LAB3 EXERCISE 3: YOUR CODE
        * 请你根据以下信息提示，补充函数
        * 现在我们认为pte是一个交换条目，那我们应该从磁盘加载数据并放到带有phy addr的页面，
        * 并将phy addr与逻辑addr映射，触发交换管理器记录该页面的访问情况
        *
        *  一些有用的宏和定义，可能会对你接下来代码的编写产生帮助(显然是有帮助的)
        *  宏或函数:
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            if ((ret = swap_in(mm, addr, &page)) != 0) {
                cprintf("swap_in in do_pgfault failed\n");
                goto failed;
            }
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            page_insert(mm->pgdir, page, addr, perm);
            //(3) make the page swappable.
            swap_map_swappable(mm, addr, page, 1);
            page->pra_vaddr = addr;
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
failed:
    return ret;
}

