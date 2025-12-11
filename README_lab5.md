# Lab 5 实验报告说明

本目录包含完整的Lab 5实验报告，报告详细讲解了用户进程管理的实现。

## 报告内容概览

### 一、练习1：加载应用程序并执行

**核心内容：**
- `load_icode`函数第6步的实现代码和详细讲解
- trapframe关键寄存器（sp、epc、status）的设置原理
- 用户态进程从被调度到执行第一条指令的完整流程（14个步骤）
- 关键数据结构trapframe和context的作用说明

**代码实现：**
```c
tf->gpr.sp = USTACKTOP;                                    // 用户栈顶
tf->epc = elf->e_entry;                                    // 程序入口
tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;     // 用户态+中断使能
```

### 二、练习2：父进程复制内存空间给子进程

**核心内容：**
- `copy_range`函数的完整实现和逐步讲解
- 物理页面复制的4个关键步骤
- 与do_fork函数的配合关系
- Copy on Write（COW）机制的详细设计
  - COW状态转换图
  - 完整的COW实现代码（copy_range_cow和do_cow_page）
  - Dirty COW漏洞分析和防范措施

**代码实现：**
```c
void *src_kvaddr = page2kva(page);        // 源页面内核虚拟地址
void *dst_kvaddr = page2kva(npage);       // 目标页面内核虚拟地址
memcpy(dst_kvaddr, src_kvaddr, PGSIZE);   // 复制页面内容
ret = page_insert(to, npage, start, perm); // 建立映射
```

### 三、练习3：fork/exec/wait/exit的实现分析

**核心内容：**
- fork/exec/wait/exit四个系统调用的详细执行流程
- 每个系统调用的用户态和内核态实现
- 用户态与内核态的交互机制
- 系统调用的完整过程：ecall→异常处理→syscall→sret
- 进程状态生命周期图和6种状态转换

**关键流程：**
```
用户态：fork() → sys_fork() → syscall(SYS_fork)
       ↓ ecall指令
内核态：trap() → exception_handler() → syscall() → sys_fork()
       → do_fork() → 创建子进程
       ↓ sret指令
用户态：父进程返回子进程PID，子进程返回0
```

### 四、扩展问题：用户程序预加载机制

**核心内容：**
- 用户程序在编译时被链接到内核镜像的机制
- 与常用操作系统（Linux）的对比分析
- ucore采用这种方式的原因（教学目的、简化实现、循序渐进）

## 报告特色

1. **详细的代码讲解**：每个实现都有完整的代码和逐行注释
2. **清晰的流程图**：用文字和图示展示复杂的执行流程
3. **深入的原理分析**：不仅讲解怎么做，更解释为什么这么做
4. **实用的扩展内容**：COW机制的完整设计和安全性分析
5. **系统的知识整合**：将进程管理、内存管理、系统调用等知识点串联

## 代码位置

实验的核心代码位于：
- `labcode/原始代码/lab5/kern/process/proc.c` - 进程管理
- `labcode/原始代码/lab5/kern/mm/pmm.c` - 内存管理
- `labcode/原始代码/lab5/kern/syscall/syscall.c` - 系统调用
- `labcode/原始代码/lab5/kern/trap/trap.c` - 异常处理

## 阅读建议

1. 先阅读实验概述，了解整体框架
2. 按照练习顺序逐个学习，理解每个练习的实现
3. 重点关注用户态进程执行流程（练习1第4节）
4. 学习COW机制设计，理解内存优化思想（练习2第5节）
5. 结合状态图理解进程生命周期（练习3第6节）

## 总结

本实验通过实际编码和代码分析，深入理解了操作系统进程管理的核心机制：
- 掌握了用户程序的加载与执行过程
- 理解了进程的创建与内存复制机制
- 认识了系统调用的实现原理
- 了解了进程生命周期管理

这些知识为后续学习文件系统、同步互斥等高级主题打下了坚实的基础。
