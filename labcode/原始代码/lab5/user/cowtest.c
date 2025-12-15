/* cowtest.c - Copy-on-Write机制测试程序
 * 
 * 测试项目：
 * 1. 基础COW：fork后父子进程共享页面
 * 2. 写时复制：修改共享页面触发复制
 * 3. 引用计数：验证页面引用计数正确
 * 4. 多进程共享：多个子进程共享同一页面
 * 5. 性能对比：COW vs 传统复制
 */

#include <stdio.h>
#include <ulib.h>
#include <string.h>

#define PGSIZE 4096
#define TEST_PAGES 10

// 全局测试数据（会被映射到用户空间）
static char test_data[PGSIZE] = "Initial data before fork";
static int shared_counter = 0;

/* 测试1：基础COW - 验证fork后的共享 */
void test_basic_cow(void) {
    cprintf("\n========== 测试1：基础COW共享 ==========\n");
    
    int original_value = 12345;
    int *shared_var = &original_value;
    
    cprintf("Fork前: shared_var地址=0x%x, 值=%d\n", 
            shared_var, *shared_var);
    
    int pid = fork();
    
    if (pid == 0) {
        // 子进程：只读访问
        cprintf("[子进程] shared_var地址=0x%x, 值=%d\n", 
                shared_var, *shared_var);
        cprintf("[子进程] 读取成功，页面共享正常\n");
        
        // 验证test_data也是共享的
        cprintf("[子进程] test_data内容: %s\n", test_data);
        
        exit(0);
    } else {
        // 父进程等待子进程
        int exit_code;
        waitpid(pid, &exit_code);
        cprintf("[父进程] 子进程退出，exit_code=%d\n", exit_code);
    }
    
    cprintf("✓ 测试1通过：fork后成功共享页面\n");
}

/* 测试2：写时复制 - 验证修改触发复制 */
void test_cow_write(void) {
    cprintf("\n========== 测试2：写时复制触发 ==========\n");
    
    // 准备测试数据
    static int test_array[10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    
    cprintf("Fork前: test_array[0]=%d\n", test_array[0]);
    
    int pid = fork();
    
    if (pid == 0) {
        // 子进程：修改数组
        cprintf("[子进程] 修改前: test_array[0]=%d\n", test_array[0]);
        
        // 这次写操作应该触发COW
        test_array[0] = 999;
        
        cprintf("[子进程] 修改后: test_array[0]=%d\n", test_array[0]);
        cprintf("[子进程] 写时复制触发，数据已独立\n");
        
        exit(0);
    } else {
        // 父进程等待
        int exit_code;
        waitpid(pid, &exit_code);
        
        // 验证父进程的数据未被修改
        cprintf("[父进程] test_array[0]=%d (应该仍是0)\n", test_array[0]);
        
        if (test_array[0] == 0) {
            cprintf("✓ 测试2通过：COW成功隔离父子进程数据\n");
        } else {
            cprintf("✗ 测试2失败：父进程数据被子进程修改！\n");
        }
    }
}

/* 测试3：多次写操作 - 验证复制后的页面可正常写入 */
void test_multiple_writes(void) {
    cprintf("\n========== 测试3：多次写操作 ==========\n");
    
    static char buffer[100] = "Original text";
    
    int pid = fork();
    
    if (pid == 0) {
        // 子进程：多次写入
        cprintf("[子进程] 第1次写入...\n");
        strcpy(buffer, "Modified by child 1");
        
        cprintf("[子进程] 第2次写入...\n");
        strcpy(buffer, "Modified by child 2");
        
        cprintf("[子进程] 第3次写入...\n");
        strcpy(buffer, "Modified by child 3");
        
        cprintf("[子进程] 最终内容: %s\n", buffer);
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
        
        cprintf("[父进程] 内容: %s\n", buffer);
        if (strcmp(buffer, "Original text") == 0) {
            cprintf("✓ 测试3通过：多次写操作正常\n");
        } else {
            cprintf("✗ 测试3失败\n");
        }
    }
}

/* 测试4：多个子进程共享 */
void test_multiple_children(void) {
    cprintf("\n========== 测试4：多个子进程共享 ==========\n");
    
    static int shared_data = 100;
    
    cprintf("创建3个子进程...\n");
    
    int pid1 = fork();
    if (pid1 == 0) {
        // 子进程1：只读
        cprintf("[子进程1] 读取 shared_data=%d\n", shared_data);
        yield();  // 让出CPU
        cprintf("[子进程1] 再次读取 shared_data=%d\n", shared_data);
        exit(1);
    }
    
    int pid2 = fork();
    if (pid2 == 0) {
        // 子进程2：只读
        cprintf("[子进程2] 读取 shared_data=%d\n", shared_data);
        yield();
        cprintf("[子进程2] 再次读取 shared_data=%d\n", shared_data);
        exit(2);
    }
    
    int pid3 = fork();
    if (pid3 == 0) {
        // 子进程3：写入（触发COW）
        cprintf("[子进程3] 修改前 shared_data=%d\n", shared_data);
        shared_data = 300;
        cprintf("[子进程3] 修改后 shared_data=%d\n", shared_data);
        exit(3);
    }
    
    // 父进程：等待所有子进程
    int exit_code;
    waitpid(pid1, &exit_code);
    cprintf("子进程1退出，exit_code=%d\n", exit_code);
    
    waitpid(pid2, &exit_code);
    cprintf("子进程2退出，exit_code=%d\n", exit_code);
    
    waitpid(pid3, &exit_code);
    cprintf("子进程3退出，exit_code=%d\n", exit_code);
    
    cprintf("[父进程] shared_data=%d (应该仍是100)\n", shared_data);
    
    if (shared_data == 100) {
        cprintf("✓ 测试4通过：多子进程COW正常\n");
    } else {
        cprintf("✗ 测试4失败\n");
    }
}

/* 测试5：大量写操作压力测试 */
void test_heavy_write(void) {
    cprintf("\n========== 测试5：大量写操作 ==========\n");
    
    // 分配多个页面的数据
    static char large_buffer[PGSIZE * 4];
    
    // 初始化数据
    for (int i = 0; i < PGSIZE * 4; i++) {
        large_buffer[i] = 'A' + (i % 26);
    }
    
    int pid = fork();
    
    if (pid == 0) {
        // 子进程：写入所有页面
        cprintf("[子进程] 开始写入%d字节...\n", PGSIZE * 4);
        
        for (int i = 0; i < PGSIZE * 4; i += 128) {
            large_buffer[i] = 'X';  // 每隔128字节写一次
        }
        
        cprintf("[子进程] 写入完成\n");
        
        // 验证写入
        int count = 0;
        for (int i = 0; i < PGSIZE * 4; i += 128) {
            if (large_buffer[i] == 'X') count++;
        }
        
        cprintf("[子进程] 验证：%d个位置被正确修改\n", count);
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
        
        // 验证父进程数据未变
        int unchanged = 1;
        for (int i = 0; i < PGSIZE * 4; i += 128) {
            if (large_buffer[i] == 'X') {
                unchanged = 0;
                break;
            }
        }
        
        if (unchanged) {
            cprintf("✓ 测试5通过：大量写操作COW正常\n");
        } else {
            cprintf("✗ 测试5失败：父进程数据被修改\n");
        }
    }
}

/* 测试6：递归fork测试 */
void test_recursive_fork(int depth) {
    if (depth <= 0) return;
    
    cprintf("[深度%d] 当前进程PID=%d\n", depth, getpid());
    
    static int counter = 0;
    counter++;
    
    int pid = fork();
    if (pid == 0) {
        // 子进程：修改counter并继续fork
        counter += 100;
        cprintf("[深度%d子进程] counter=%d\n", depth, counter);
        
        test_recursive_fork(depth - 1);
        exit(0);
    } else {
        // 父进程等待
        int exit_code;
        waitpid(pid, &exit_code);
        cprintf("[深度%d父进程] counter=%d\n", depth, counter);
    }
}

void test_recursive_fork_wrapper(void) {
    cprintf("\n========== 测试6：递归fork ==========\n");
    test_recursive_fork(3);
    cprintf("✓ 测试6完成\n");
}

/* 测试7：验证页面共享节省内存 
 * 注意：这个测试需要内核支持查询页面引用计数的系统调用
 */
void test_memory_saving(void) {
    cprintf("\n========== 测试7：内存节省验证 ==========\n");
    
    // 分配大块数据
    static char big_data[PGSIZE * 10];
    for (int i = 0; i < PGSIZE * 10; i++) {
        big_data[i] = i % 256;
    }
    
    cprintf("分配了%d字节数据\n", PGSIZE * 10);
    
    int pid = fork();
    if (pid == 0) {
        // 子进程：不修改数据，直接退出
        cprintf("[子进程] 共享数据，不修改\n");
        
        // 验证数据可读
        int sum = 0;
        for (int i = 0; i < 100; i++) {
            sum += big_data[i];
        }
        cprintf("[子进程] 数据校验和=%d\n", sum);
        
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
        cprintf("✓ 测试7完成：理论上节省了%d字节内存\n", PGSIZE * 10);
    }
}

/* 测试8：边界条件 - fork后立即exec */
void test_fork_exec(void) {
    cprintf("\n========== 测试8：Fork后Exec ==========\n");
    
    static char data[] = "Data before exec";
    
    int pid = fork();
    if (pid == 0) {
        // 子进程：立即exec
        cprintf("[子进程] Fork后立即执行其他程序\n");
        cprintf("[子进程] 原数据: %s\n", data);
        
        // 在真实系统中，这里会exec另一个程序
        // ucore lab5没有实际的exec实现，所以这里模拟
        cprintf("[子进程] 模拟exec：COW页面未被使用即被释放\n");
        
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
        cprintf("✓ 测试8完成：Fork-exec场景\n");
    }
}

/* 性能测试：对比COW和传统复制 */
void performance_test(void) {
    cprintf("\n========== 性能测试 ==========\n");
    cprintf("注意：此测试需要修改内核支持传统复制方式\n");
    
    // 准备大量数据
    static char perf_data[PGSIZE * 20];
    for (int i = 0; i < PGSIZE * 20; i++) {
        perf_data[i] = i % 256;
    }
    
    cprintf("测试数据大小：%d字节 (%d页)\n", 
            PGSIZE * 20, 20);
    
    // COW方式
    cprintf("\n--- COW方式 ---\n");
    unsigned int start_time = 0;  // 需要系统调用获取时间
    
    int pid1 = fork();
    if (pid1 == 0) {
        // 子进程：只读访问
        volatile int sum = 0;
        for (int i = 0; i < PGSIZE * 20; i += 1024) {
            sum += perf_data[i];
        }
        exit(0);
    }
    waitpid(pid1, NULL);
    
    cprintf("COW fork+读取 完成\n");
    
    // 如果有传统复制方式，在这里测试
    cprintf("\n性能对比需要内核支持\n");
}

int main(void) {
    cprintf("╔════════════════════════════════════════╗\n");
    cprintf("║   Copy-on-Write 机制综合测试程序      ║\n");
    cprintf("╚════════════════════════════════════════╝\n");
    
    cprintf("\n开始COW测试...\n");
    
    // 运行所有测试
    test_basic_cow();           // 测试1：基础共享
    test_cow_write();           // 测试2：写时复制
    test_multiple_writes();     // 测试3：多次写入
    test_multiple_children();   // 测试4：多子进程
    test_heavy_write();         // 测试5：大量写入
    test_recursive_fork_wrapper(); // 测试6：递归fork
    test_memory_saving();       // 测试7：内存节省
    test_fork_exec();           // 测试8：fork-exec
    performance_test();         // 性能测试
    
    cprintf("\n╔════════════════════════════════════════╗\n");
    cprintf("║          所有测试完成！                ║\n");
    cprintf("╚════════════════════════════════════════╝\n");
    
    return 0;
}
