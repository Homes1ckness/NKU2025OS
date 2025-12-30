#include <stdio.h>
#include <ulib.h>

/* RISC-V doesn't have segments, so we test invalid memory access instead */

int
main(void) {
    // 简单地访问一个未映射的地址（与faultread类似）
    // 这应该触发页错误并终止进程
    volatile int dummy = *(int *)0x00040000;
    panic("FAIL: T.T\n");
}

