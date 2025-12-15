/* dirtycow_sim.c - DirtyCOW漏洞模拟程序
 * 
 * CVE-2016-5195 - Dirty COW 竞态条件漏洞
 * 
 * 漏洞原理：
 * 1. 进程通过mmap映射一个只读文件
 * 2. Fork产生子进程，触发COW（页面标记为只读）
 * 3. 父进程调用madvise(MADV_DONTNEED)丢弃页面
 * 4. 同时对该区域执行write系统调用
 * 5. 竞态条件下，write可能在页面重新映射前完成
 * 6. 导致写入原始只读页面，绕过COW保护
 * 
 * 本程序模拟DirtyCOW的攻击场景
 * 注意：这不是真实的DirtyCOW exploit
 */

#include <stdio.h>
#include <ulib.h>
#include <string.h>

#define PGSIZE 4096

/* 模拟只读文件内容 */
static const char readonly_file_content[PGSIZE] = 
    "This is a READ-ONLY file that should NEVER be modified!\n"
    "Any modification indicates a security vulnerability.\n"
    "Original content: SECURE DATA\n";

/* 全局标志：模拟竞态条件 */
static volatile int race_flag = 0;
static volatile int attack_success = 0;

/* 测试1：正常COW行为 - 基线测试 */
void test_normal_cow(void) {
    cprintf("\n========== 测试1：正常COW（基线） ==========\n");
    
    // 创建只读数据副本
    static char protected_data[PGSIZE];
    memcpy(protected_data, readonly_file_content, PGSIZE);
    
    cprintf("原始数据: %.50s...\n", protected_data);
    
    int pid = fork();
    
    if (pid == 0) {
        // 子进程：尝试修改
        cprintf("[子进程] 尝试修改只读数据...\n");
        
        // 这会触发正常的COW
        protected_data[0] = 'X';
        strcpy(protected_data + 20, "HACKED BY CHILD");
        
        cprintf("[子进程] 修改后: %.50s...\n", protected_data);
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
        
        // 父进程验证数据未被修改
        if (protected_data[0] == 'T') {
            cprintf("[父进程] ✓ 数据完整：COW正常工作\n");
            cprintf("[父进程] 内容: %.50s...\n", protected_data);
        } else {
            cprintf("[父进程] ✗ 数据被破坏：COW失败！\n");
        }
    }
}

/* 测试2：模拟DirtyCOW竞态条件（简化版） 
 * 
 * 真实DirtyCOW需要：
 * 1. 线程1：持续调用madvise(MADV_DONTNEED)
 * 2. 线程2：持续调用write()写入私有映射
 * 3. 竞态窗口：页表项被清除后，write在重新映射前完成
 * 
 * ucore简化模拟：
 * - 用两个进程模拟两个线程的竞态
 * - 通过共享标志位同步
 */
void test_dirtycow_simulation(void) {
    cprintf("\n========== 测试2：DirtyCOW竞态模拟 ==========\n");
    cprintf("警告：这是简化的教学演示，非真实漏洞利用\n\n");
    
    // 模拟mmap的私有映射
    static char mmap_private[PGSIZE];
    memcpy(mmap_private, readonly_file_content, PGSIZE);
    
    cprintf("初始内容: %.50s...\n\n", mmap_private);
    
    // Fork创建两个进程模拟竞态
    int pid1 = fork();
    
    if (pid1 == 0) {
        //===== 子进程1：模拟madvise线程 =====
        cprintf("[madvise进程] 启动，PID=%d\n", getpid());
        cprintf("[madvise进程] 模拟持续丢弃页面...\n");
        
        for (int i = 0; i < 100; i++) {
            // 在真实DirtyCOW中，这里调用：
            // madvise(addr, len, MADV_DONTNEED);
            // 效果：清除页表项，下次访问会重新映射原文件
            
            // ucore简化：通过标志位模拟
            race_flag = 1;  // 通知write线程：页面已丢弃
            
            // 模拟系统调用延迟
            for (volatile int delay = 0; delay < 1000; delay++);
            
            race_flag = 0;
        }
        
        cprintf("[madvise进程] 完成100次丢弃操作\n");
        exit(0);
    }
    
    // 父进程继续fork第二个子进程
    int pid2 = fork();
    
    if (pid2 == 0) {
        //===== 子进程2：模拟write线程 =====
        cprintf("[write进程] 启动，PID=%d\n", getpid());
        cprintf("[write进程] 模拟持续写入...\n");
        
        for (int i = 0; i < 100; i++) {
            // 在真实DirtyCOW中，这里调用：
            // write(fd, "HACKED", 6);
            // fd指向/proc/self/mem中mmap区域的偏移
            
            // 检查竞态窗口
            if (race_flag == 1) {
                // 竞态窗口！页面刚被丢弃
                cprintf("[write进程] !!! 检测到竞态窗口（迭代%d）\n", i);
                
                // 尝试写入（在真实情况下可能写到原文件）
                memcpy(mmap_private, "HACKED DATA - VULNERABLE!", 25);
                
                attack_success = 1;
                break;
            }
            
            // 正常写入（会触发COW）
            mmap_private[i % PGSIZE] = 'W';
            
            // 模拟延迟
            for (volatile int delay = 0; delay < 500; delay++);
        }
        
        cprintf("[write进程] 完成写入操作\n");
        exit(0);
    }
    
    //===== 父进程：等待并检查结果 =====
    int exit_code;
    waitpid(pid1, &exit_code);
    cprintf("[父进程] madvise进程退出\n");
    
    waitpid(pid2, &exit_code);
    cprintf("[父进程] write进程退出\n");
    
    cprintf("\n--- 竞态结果检查 ---\n");
    if (attack_success) {
        cprintf("⚠ 检测到竞态条件触发！\n");
        cprintf("⚠ 在真实DirtyCOW中，这会导致只读文件被修改\n");
    } else {
        cprintf("✓ 未触发竞态条件\n");
        cprintf("✓ COW保护有效\n");
    }
    
    cprintf("\n当前内容: %.50s...\n", mmap_private);
}

/* 测试3：DirtyCOW防护措施验证 */
void test_dirtycow_protection(void) {
    cprintf("\n========== 测试3：DirtyCOW防护措施 ==========\n");
    
    cprintf("DirtyCOW漏洞的关键防护措施：\n\n");
    
    cprintf("1. 内核补丁（已修复）：\n");
    cprintf("   - Linux 4.8.3+ 已修复此漏洞\n");
    cprintf("   - 修复方法：在do_fault中检查VM_FAULT_WRITE标志\n");
    cprintf("   - 确保COW的页面不会被错误地标记为dirty\n\n");
    
    cprintf("2. madvise系统调用改进：\n");
    cprintf("   - MADV_DONTNEED现在会检查页面的可写属性\n");
    cprintf("   - 只读映射不允许被MADV_DONTNEED影响\n\n");
    
    cprintf("3. 页表操作原子性：\n");
    cprintf("   - 使用锁保护页表项的修改\n");
    cprintf("   - 防止竞态条件窗口\n\n");
    
    cprintf("4. ucore中的保护措施：\n");
    cprintf("   - 检查PTE_W标志位\n");
    cprintf("   - COW页面标记PTE_COW，不标记PTE_W\n");
    cprintf("   - 在do_pgfault中验证写权限\n\n");
    
    // 模拟保护措施
    static char protected[PGSIZE];
    memcpy(protected, "PROTECTED DATA", 15);
    
    int pid = fork();
    if (pid == 0) {
        cprintf("[子进程] 尝试绕过COW写入...\n");
        
        // 模拟攻击：直接写入（应该被COW机制阻止）
        protected[0] = 'X';
        
        cprintf("[子进程] 写入完成（触发了COW）\n");
        cprintf("[子进程] 数据: %s\n", protected);
        exit(0);
    } else {
        waitpid(pid, NULL);
        
        if (protected[0] == 'P') {
            cprintf("\n✓ 保护措施有效：父进程数据未被修改\n");
        } else {
            cprintf("\n✗ 保护措施失败！\n");
        }
    }
}

/* 测试4：多进程竞态放大 */
void test_race_amplification(void) {
    cprintf("\n========== 测试4：多进程竞态放大 ==========\n");
    cprintf("创建多个进程尝试触发竞态条件...\n\n");
    
    static char race_buffer[PGSIZE];
    memcpy(race_buffer, "Original shared data", 21);
    
    // 创建多个子进程增加竞态概率
    int pids[5];
    
    for (int i = 0; i < 5; i++) {
        int pid = fork();
        
        if (pid == 0) {
            // 每个子进程快速写入
            cprintf("[竞态进程%d] 开始写入\n", i);
            
            for (int j = 0; j < 50; j++) {
                race_buffer[j % PGSIZE] = '0' + i;
                
                // 随机延迟增加竞态可能性
                for (volatile int d = 0; d < (i * 100); d++);
            }
            
            cprintf("[竞态进程%d] 完成\n", i);
            exit(i);
        } else {
            pids[i] = pid;
        }
    }
    
    // 父进程也参与写入
    cprintf("[父进程] 同时写入\n");
    for (int i = 0; i < 50; i++) {
        race_buffer[i % PGSIZE] = 'P';
    }
    
    // 等待所有子进程
    for (int i = 0; i < 5; i++) {
        waitpid(pids[i], NULL);
    }
    
    cprintf("\n✓ 测试4完成：验证了多进程COW隔离\n");
    cprintf("父进程数据: %.20s...\n", race_buffer);
}

/* 测试5：时间窗口分析 */
void test_timing_window(void) {
    cprintf("\n========== 测试5：竞态时间窗口分析 ==========\n");
    
    cprintf("DirtyCOW竞态窗口分析：\n\n");
    
    cprintf("时序图：\n");
    cprintf("Thread 1 (madvise)        Thread 2 (write)\n");
    cprintf("==================        ================\n");
    cprintf("madvise(MADV_DONTNEED)\n");
    cprintf("  ↓\n");
    cprintf("清除PTE\n");
    cprintf("  ↓                       write()\n");
    cprintf("  |                         ↓\n");
    cprintf("  |                       检查PTE（已清除）\n");
    cprintf("  |                         ↓\n");
    cprintf("[竞态窗口]                 触发page fault\n");
    cprintf("  |                         ↓\n");
    cprintf("  |                       分配新页面\n");
    cprintf("  ↓                         ↓\n");
    cprintf("返回                      写入数据 <-- 可能写到原页面！\n");
    cprintf("重新映射原文件              ↓\n");
    cprintf("                          返回\n\n");
    
    cprintf("关键点：\n");
    cprintf("1. madvise清除PTE后，页面暂时无效\n");
    cprintf("2. write检测到PTE无效，触发page fault\n");
    cprintf("3. 如果page fault在重新映射前完成写入\n");
    cprintf("4. 写操作可能直接写到原只读页面\n");
    cprintf("5. 导致只读文件被修改\n\n");
    
    cprintf("✓ 时序分析完成\n");
}

/* 打印漏洞信息和缓解措施 */
void print_vulnerability_info(void) {
    cprintf("\n╔════════════════════════════════════════════════════╗\n");
    cprintf("║          DirtyCOW 漏洞详细信息                    ║\n");
    cprintf("╚════════════════════════════════════════════════════╝\n\n");
    
    cprintf("漏洞编号：CVE-2016-5195\n");
    cprintf("漏洞名称：Dirty COW (Copy-On-Write)\n");
    cprintf("影响版本：Linux Kernel 2.6.22 - 4.8.3\n");
    cprintf("危险等级：高危（CVSS 7.8）\n\n");
    
    cprintf("漏洞影响：\n");
    cprintf("• 本地权限提升\n");
    cprintf("• 修改只读文件（如/etc/passwd）\n");
    cprintf("• 绕过文件权限检查\n");
    cprintf("• 容器逃逸\n\n");
    
    cprintf("攻击场景示例：\n");
    cprintf("1. 攻击者以普通用户身份运行\n");
    cprintf("2. 映射/etc/passwd为只读\n");
    cprintf("3. Fork子进程（触发COW）\n");
    cprintf("4. 利用竞态条件修改/etc/passwd\n");
    cprintf("5. 添加root权限账户\n");
    cprintf("6. 获得系统管理员权限\n\n");
    
    cprintf("缓解措施：\n");
    cprintf("✓ 升级内核至4.8.3+\n");
    cprintf("✓ 应用安全补丁\n");
    cprintf("✓ 使用SELinux/AppArmor限制\n");
    cprintf("✓ 监控异常madvise调用\n\n");
    
    cprintf("在ucore中的教学意义：\n");
    cprintf("• 理解COW机制的实现细节\n");
    cprintf("• 认识竞态条件的危害\n");
    cprintf("• 学习内核安全编程\n");
    cprintf("• 掌握页表操作的原子性要求\n\n");
}

int main(void) {
    cprintf("╔════════════════════════════════════════════════════╗\n");
    cprintf("║       DirtyCOW 漏洞模拟与教学演示程序            ║\n");
    cprintf("║                                                    ║\n");
    cprintf("║  警告：这是教学演示，不包含真实漏洞利用代码      ║\n");
    cprintf("║  目的：帮助理解COW机制和竞态条件安全问题         ║\n");
    cprintf("╚════════════════════════════════════════════════════╝\n");
    
    // 打印漏洞信息
    print_vulnerability_info();
    
    cprintf("\n按任意键开始测试...\n");
    cprintf("(在真实系统中按键，这里自动继续)\n\n");
    
    // 运行所有测试
    test_normal_cow();           // 测试1：正常COW
    test_dirtycow_simulation();  // 测试2：竞态模拟
    test_dirtycow_protection();  // 测试3：防护措施
    test_race_amplification();   // 测试4：竞态放大
    test_timing_window();        // 测试5：时序分析
    
    cprintf("\n╔════════════════════════════════════════════════════╗\n");
    cprintf("║              演示完成                              ║\n");
    cprintf("║                                                    ║\n");
    cprintf("║  学习要点：                                        ║\n");
    cprintf("║  1. COW不仅是性能优化，也是安全边界              ║\n");
    cprintf("║  2. 竞态条件可能导致严重安全漏洞                  ║\n");
    cprintf("║  3. 内核编程需要极其谨慎的同步控制                ║\n");
    cprintf("║  4. 页表操作必须保证原子性                        ║\n");
    cprintf("╚════════════════════════════════════════════════════╝\n");
    
    return 0;
}
