/* cowstress.c - COW机制压力测试
 * 
 * 测试场景：
 * 1. 大量fork：创建多个子进程共享内存
 * 2. fork炸弹：测试极限情况
 * 3. 并发写入：多个进程同时触发COW
 * 4. 内存压力：大量页面的COW操作
 */

#include <stdio.h>
#include <ulib.h>
#include <string.h>

#define PGSIZE 4096
#define MAX_CHILDREN 10
#define LARGE_BUFFER_PAGES 50

// 大块共享数据
static char shared_buffer[PGSIZE * LARGE_BUFFER_PAGES];
static int test_counter = 0;

/* 压力测试1：大量fork */
void stress_test_many_forks(void) {
    cprintf("\n========== 压力测试1：大量Fork ==========\n");
    cprintf("创建%d个子进程...\n", MAX_CHILDREN);
    
    // 初始化共享数据
    for (int i = 0; i < PGSIZE * LARGE_BUFFER_PAGES; i++) {
        shared_buffer[i] = 'S';
    }
    
    int pids[MAX_CHILDREN];
    int created = 0;
    
    // 创建多个子进程
    for (int i = 0; i < MAX_CHILDREN; i++) {
        int pid = fork();
        
        if (pid < 0) {
            cprintf("Fork失败，已创建%d个子进程\n", i);
            break;
        }
        
        if (pid == 0) {
            // 子进程：读取共享数据
            cprintf("[子进程%d PID=%d] 开始读取共享数据...\n", 
                    i, getpid());
            
            // 读取所有页面
            volatile int checksum = 0;
            for (int j = 0; j < PGSIZE * LARGE_BUFFER_PAGES; j += PGSIZE) {
                checksum += shared_buffer[j];
            }
            
            cprintf("[子进程%d] 读取完成，校验和=%d\n", i, checksum);
            
            // 让一半的子进程修改数据（触发COW）
            if (i % 2 == 0) {
                cprintf("[子进程%d] 触发COW写入...\n", i);
                for (int j = i * 1000; j < (i + 1) * 1000; j++) {
                    shared_buffer[j] = 'C';
                }
                cprintf("[子进程%d] COW写入完成\n", i);
            }
            
            exit(i);
        } else {
            pids[created++] = pid;
        }
    }
    
    cprintf("\n[父进程] 成功创建%d个子进程\n", created);
    cprintf("[父进程] 等待所有子进程退出...\n");
    
    // 等待所有子进程
    for (int i = 0; i < created; i++) {
        int exit_code;
        waitpid(pids[i], &exit_code);
        cprintf("子进程%d (PID=%d) 退出，exit_code=%d\n", 
                i, pids[i], exit_code);
    }
    
    // 验证父进程数据未被修改
    int unchanged = 1;
    for (int i = 0; i < PGSIZE * LARGE_BUFFER_PAGES; i++) {
        if (shared_buffer[i] != 'S') {
            unchanged = 0;
            cprintf("检测到位置%d被修改为'%c'\n", i, shared_buffer[i]);
            break;
        }
    }
    
    if (unchanged) {
        cprintf("✓ 压力测试1通过：%d个子进程COW正常\n", created);
    } else {
        cprintf("✗ 压力测试1失败：父进程数据被修改\n");
    }
}

/* 压力测试2：fork树 */
void stress_test_fork_tree(int depth, int breadth) {
    if (depth <= 0) return;
    
    cprintf("[深度%d] PID=%d, 创建%d个子进程\n", 
            depth, getpid(), breadth);
    
    static char tree_data[PGSIZE * 2];
    tree_data[0] = 'T';
    tree_data[PGSIZE] = 'T';
    
    for (int i = 0; i < breadth; i++) {
        int pid = fork();
        
        if (pid == 0) {
            // 子进程：修改数据并递归
            tree_data[i] = 'C';
            tree_data[PGSIZE + i] = 'C';
            
            cprintf("[深度%d-子%d] PID=%d, 修改数据\n", 
                    depth, i, getpid());
            
            // 递归创建下一层
            stress_test_fork_tree(depth - 1, breadth);
            exit(0);
        }
    }
    
    // 等待所有子进程
    for (int i = 0; i < breadth; i++) {
        wait();
    }
}

void stress_test_fork_tree_wrapper(void) {
    cprintf("\n========== 压力测试2：Fork树 ==========\n");
    cprintf("深度=3, 广度=2\n");
    
    stress_test_fork_tree(3, 2);
    
    cprintf("✓ 压力测试2完成\n");
}

/* 压力测试3：并发写入同一区域 */
void stress_test_concurrent_write(void) {
    cprintf("\n========== 压力测试3：并发写入 ==========\n");
    
    // 准备共享数据
    static int concurrent_data[1024];
    for (int i = 0; i < 1024; i++) {
        concurrent_data[i] = i;
    }
    
    cprintf("创建5个子进程同时写入...\n");
    
    int pids[5];
    
    for (int i = 0; i < 5; i++) {
        int pid = fork();
        
        if (pid == 0) {
            cprintf("[子进程%d] 开始写入...\n", i);
            
            // 所有子进程写入相同区域（不同值）
            for (int j = 0; j < 1024; j++) {
                concurrent_data[j] = i * 1000 + j;
            }
            
            cprintf("[子进程%d] 写入完成\n", i);
            
            // 验证写入
            int errors = 0;
            for (int j = 0; j < 1024; j++) {
                if (concurrent_data[j] != i * 1000 + j) {
                    errors++;
                }
            }
            
            if (errors == 0) {
                cprintf("[子进程%d] 数据验证通过\n", i);
            } else {
                cprintf("[子进程%d] 数据验证失败：%d个错误\n", i, errors);
            }
            
            exit(i);
        } else {
            pids[i] = pid;
        }
    }
    
    // 父进程也写入
    cprintf("[父进程] 同时写入...\n");
    for (int i = 0; i < 1024; i++) {
        concurrent_data[i] = 99999 + i;
    }
    
    // 等待所有子进程
    for (int i = 0; i < 5; i++) {
        int exit_code;
        waitpid(pids[i], &exit_code);
        cprintf("子进程%d退出\n", i);
    }
    
    // 验证父进程数据
    int errors = 0;
    for (int i = 0; i < 1024; i++) {
        if (concurrent_data[i] != 99999 + i) {
            errors++;
        }
    }
    
    if (errors == 0) {
        cprintf("✓ 压力测试3通过：并发写入正确隔离\n");
    } else {
        cprintf("✗ 压力测试3失败：%d个数据错误\n", errors);
    }
}

/* 压力测试4：随机访问模式 */
void stress_test_random_access(void) {
    cprintf("\n========== 压力测试4：随机访问 ==========\n");
    
    static char random_buffer[PGSIZE * 20];
    
    // 初始化
    for (int i = 0; i < PGSIZE * 20; i++) {
        random_buffer[i] = (i * 7 + 13) % 256;
    }
    
    int pid = fork();
    
    if (pid == 0) {
        cprintf("[子进程] 随机读写测试...\n");
        
        // 随机访问模式：先读后写
        for (int iter = 0; iter < 100; iter++) {
            // 伪随机位置
            int pos = (iter * 997 + 2333) % (PGSIZE * 20);
            
            // 读
            volatile char old_val = random_buffer[pos];
            
            // 写（第一次写会触发COW）
            random_buffer[pos] = (char)(iter % 256);
            
            if (iter % 20 == 0) {
                cprintf("[子进程] 迭代%d: pos=%d, old=%d, new=%d\n", 
                        iter, pos, old_val, random_buffer[pos]);
            }
        }
        
        cprintf("[子进程] 随机访问完成\n");
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
        
        // 验证父进程数据未变
        int unchanged = 1;
        for (int i = 0; i < PGSIZE * 20; i++) {
            char expected = (i * 7 + 13) % 256;
            if (random_buffer[i] != expected) {
                unchanged = 0;
                break;
            }
        }
        
        if (unchanged) {
            cprintf("✓ 压力测试4通过\n");
        } else {
            cprintf("✗ 压力测试4失败\n");
        }
    }
}

/* 压力测试5：内存不足场景 
 * 测试当系统内存不足时，COW是否能正确处理
 */
void stress_test_memory_pressure(void) {
    cprintf("\n========== 压力测试5：内存压力 ==========\n");
    
    // 分配大量页面
    static char huge_buffer[PGSIZE * 100];
    cprintf("分配了%d页 (%d字节)\n", 100, PGSIZE * 100);
    
    // 初始化
    for (int i = 0; i < PGSIZE * 100; i += PGSIZE) {
        huge_buffer[i] = 'H';
    }
    
    int pid = fork();
    
    if (pid < 0) {
        cprintf("Fork失败：可能内存不足\n");
        return;
    }
    
    if (pid == 0) {
        cprintf("[子进程] 尝试写入所有100页...\n");
        
        int success_count = 0;
        
        // 逐页写入，每页触发一次COW
        for (int i = 0; i < 100; i++) {
            huge_buffer[i * PGSIZE] = 'C';
            success_count++;
            
            if (i % 10 == 0) {
                cprintf("[子进程] 已复制%d页\n", success_count);
            }
        }
        
        cprintf("[子进程] 成功复制%d页\n", success_count);
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
        
        if (exit_code == 0) {
            cprintf("✓ 压力测试5通过\n");
        } else {
            cprintf("子进程异常退出：exit_code=%d\n", exit_code);
        }
    }
}

/* 压力测试6：快速fork-exit循环 */
void stress_test_fork_exit_loop(void) {
    cprintf("\n========== 压力测试6：Fork-Exit循环 ==========\n");
    
    static int loop_data[256];
    for (int i = 0; i < 256; i++) {
        loop_data[i] = i;
    }
    
    cprintf("执行100次fork-exit循环...\n");
    
    for (int i = 0; i < 100; i++) {
        int pid = fork();
        
        if (pid == 0) {
            // 子进程：快速退出
            volatile int sum = 0;
            for (int j = 0; j < 256; j++) {
                sum += loop_data[j];
            }
            exit(0);
        } else {
            // 父进程：立即等待
            waitpid(pid, NULL);
            
            if (i % 10 == 0) {
                cprintf("完成%d次循环\n", i + 1);
            }
        }
    }
    
    cprintf("✓ 压力测试6完成：100次fork-exit\n");
}

/* 压力测试7：嵌套fork */
void stress_test_nested_fork(void) {
    cprintf("\n========== 压力测试7：嵌套Fork ==========\n");
    
    static char nested_data[PGSIZE * 5];
    for (int i = 0; i < PGSIZE * 5; i++) {
        nested_data[i] = 'N';
    }
    
    cprintf("执行三层嵌套fork...\n");
    
    int pid1 = fork();
    if (pid1 == 0) {
        // 第一层子进程
        cprintf("[L1子进程] PID=%d\n", getpid());
        nested_data[0] = '1';
        
        int pid2 = fork();
        if (pid2 == 0) {
            // 第二层子进程
            cprintf("[L2子进程] PID=%d\n", getpid());
            nested_data[PGSIZE] = '2';
            
            int pid3 = fork();
            if (pid3 == 0) {
                // 第三层子进程
                cprintf("[L3子进程] PID=%d\n", getpid());
                nested_data[PGSIZE * 2] = '3';
                
                cprintf("[L3子进程] 数据: %c, %c, %c\n", 
                        nested_data[0], nested_data[PGSIZE], 
                        nested_data[PGSIZE * 2]);
                exit(0);
            }
            waitpid(pid3, NULL);
            cprintf("[L2子进程] 数据: %c, %c\n", 
                    nested_data[0], nested_data[PGSIZE]);
            exit(0);
        }
        waitpid(pid2, NULL);
        cprintf("[L1子进程] 数据: %c\n", nested_data[0]);
        exit(0);
    }
    
    waitpid(pid1, NULL);
    cprintf("[父进程] 数据: %c (应该是'N')\n", nested_data[0]);
    
    if (nested_data[0] == 'N') {
        cprintf("✓ 压力测试7通过\n");
    } else {
        cprintf("✗ 压力测试7失败\n");
    }
}

int main(void) {
    cprintf("╔════════════════════════════════════════╗\n");
    cprintf("║      COW机制压力测试程序              ║\n");
    cprintf("║   警告：此测试会产生大量进程！        ║\n");
    cprintf("╚════════════════════════════════════════╝\n");
    
    cprintf("\n准备运行压力测试...\n");
    cprintf("共享缓冲区大小：%d字节 (%d页)\n", 
            PGSIZE * LARGE_BUFFER_PAGES, LARGE_BUFFER_PAGES);
    
    // 运行所有压力测试
    stress_test_many_forks();         // 测试1：大量fork
    stress_test_fork_tree_wrapper();  // 测试2：fork树
    stress_test_concurrent_write();   // 测试3：并发写入
    stress_test_random_access();      // 测试4：随机访问
    stress_test_memory_pressure();    // 测试5：内存压力
    stress_test_fork_exit_loop();     // 测试6：fork-exit循环
    stress_test_nested_fork();        // 测试7：嵌套fork
    
    cprintf("\n╔════════════════════════════════════════╗\n");
    cprintf("║       所有压力测试完成！              ║\n");
    cprintf("╚════════════════════════════════════════╝\n");
    
    return 0;
}
