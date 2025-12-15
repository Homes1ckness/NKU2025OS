
obj/__user_cowtest.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
.text
.globl _start
_start:
    # call user-program function
    call umain
  800020:	0ce000ef          	jal	ra,8000ee <umain>
1:  j 1b
  800024:	a001                	j	800024 <_start+0x4>

0000000000800026 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  800026:	1141                	addi	sp,sp,-16
  800028:	e022                	sd	s0,0(sp)
  80002a:	e406                	sd	ra,8(sp)
  80002c:	842e                	mv	s0,a1
    sys_putc(c);
  80002e:	09c000ef          	jal	ra,8000ca <sys_putc>
    (*cnt) ++;
  800032:	401c                	lw	a5,0(s0)
}
  800034:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
  800036:	2785                	addiw	a5,a5,1
  800038:	c01c                	sw	a5,0(s0)
}
  80003a:	6402                	ld	s0,0(sp)
  80003c:	0141                	addi	sp,sp,16
  80003e:	8082                	ret

0000000000800040 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  800040:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  800042:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  800046:	8e2a                	mv	t3,a0
  800048:	f42e                	sd	a1,40(sp)
  80004a:	f832                	sd	a2,48(sp)
  80004c:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  80004e:	00000517          	auipc	a0,0x0
  800052:	fd850513          	addi	a0,a0,-40 # 800026 <cputch>
  800056:	004c                	addi	a1,sp,4
  800058:	869a                	mv	a3,t1
  80005a:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
  80005c:	ec06                	sd	ra,24(sp)
  80005e:	e0ba                	sd	a4,64(sp)
  800060:	e4be                	sd	a5,72(sp)
  800062:	e8c2                	sd	a6,80(sp)
  800064:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
  800066:	e41a                	sd	t1,8(sp)
    int cnt = 0;
  800068:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  80006a:	0fc000ef          	jal	ra,800166 <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  80006e:	60e2                	ld	ra,24(sp)
  800070:	4512                	lw	a0,4(sp)
  800072:	6125                	addi	sp,sp,96
  800074:	8082                	ret

0000000000800076 <syscall>:
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
  800076:	7175                	addi	sp,sp,-144
  800078:	f8ba                	sd	a4,112(sp)
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
  80007a:	e0ba                	sd	a4,64(sp)
  80007c:	0118                	addi	a4,sp,128
syscall(int64_t num, ...) {
  80007e:	e42a                	sd	a0,8(sp)
  800080:	ecae                	sd	a1,88(sp)
  800082:	f0b2                	sd	a2,96(sp)
  800084:	f4b6                	sd	a3,104(sp)
  800086:	fcbe                	sd	a5,120(sp)
  800088:	e142                	sd	a6,128(sp)
  80008a:	e546                	sd	a7,136(sp)
        a[i] = va_arg(ap, uint64_t);
  80008c:	f42e                	sd	a1,40(sp)
  80008e:	f832                	sd	a2,48(sp)
  800090:	fc36                	sd	a3,56(sp)
  800092:	f03a                	sd	a4,32(sp)
  800094:	e4be                	sd	a5,72(sp)
    }
    va_end(ap);

    asm volatile (
  800096:	6522                	ld	a0,8(sp)
  800098:	75a2                	ld	a1,40(sp)
  80009a:	7642                	ld	a2,48(sp)
  80009c:	76e2                	ld	a3,56(sp)
  80009e:	6706                	ld	a4,64(sp)
  8000a0:	67a6                	ld	a5,72(sp)
  8000a2:	00000073          	ecall
  8000a6:	00a13e23          	sd	a0,28(sp)
        "sd a0, %0"
        : "=m" (ret)
        : "m"(num), "m"(a[0]), "m"(a[1]), "m"(a[2]), "m"(a[3]), "m"(a[4])
        :"memory");
    return ret;
}
  8000aa:	4572                	lw	a0,28(sp)
  8000ac:	6149                	addi	sp,sp,144
  8000ae:	8082                	ret

00000000008000b0 <sys_exit>:

int
sys_exit(int64_t error_code) {
  8000b0:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  8000b2:	4505                	li	a0,1
  8000b4:	b7c9                	j	800076 <syscall>

00000000008000b6 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  8000b6:	4509                	li	a0,2
  8000b8:	bf7d                	j	800076 <syscall>

00000000008000ba <sys_wait>:
}

int
sys_wait(int64_t pid, int *store) {
  8000ba:	862e                	mv	a2,a1
    return syscall(SYS_wait, pid, store);
  8000bc:	85aa                	mv	a1,a0
  8000be:	450d                	li	a0,3
  8000c0:	bf5d                	j	800076 <syscall>

00000000008000c2 <sys_yield>:
}

int
sys_yield(void) {
    return syscall(SYS_yield);
  8000c2:	4529                	li	a0,10
  8000c4:	bf4d                	j	800076 <syscall>

00000000008000c6 <sys_getpid>:
    return syscall(SYS_kill, pid);
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  8000c6:	4549                	li	a0,18
  8000c8:	b77d                	j	800076 <syscall>

00000000008000ca <sys_putc>:
}

int
sys_putc(int64_t c) {
  8000ca:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  8000cc:	4579                	li	a0,30
  8000ce:	b765                	j	800076 <syscall>

00000000008000d0 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  8000d0:	1141                	addi	sp,sp,-16
  8000d2:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  8000d4:	fddff0ef          	jal	ra,8000b0 <sys_exit>
    cprintf("BUG: exit failed.\n");
  8000d8:	00001517          	auipc	a0,0x1
  8000dc:	b7050513          	addi	a0,a0,-1168 # 800c48 <main+0x84>
  8000e0:	f61ff0ef          	jal	ra,800040 <cprintf>
    while (1);
  8000e4:	a001                	j	8000e4 <exit+0x14>

00000000008000e6 <fork>:
}

int
fork(void) {
    return sys_fork();
  8000e6:	bfc1                	j	8000b6 <sys_fork>

00000000008000e8 <waitpid>:
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
  8000e8:	bfc9                	j	8000ba <sys_wait>

00000000008000ea <yield>:
}

void
yield(void) {
    sys_yield();
  8000ea:	bfe1                	j	8000c2 <sys_yield>

00000000008000ec <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  8000ec:	bfe9                	j	8000c6 <sys_getpid>

00000000008000ee <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000ee:	1141                	addi	sp,sp,-16
  8000f0:	e406                	sd	ra,8(sp)
    int ret = main();
  8000f2:	2d3000ef          	jal	ra,800bc4 <main>
    exit(ret);
  8000f6:	fdbff0ef          	jal	ra,8000d0 <exit>

00000000008000fa <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  8000fa:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000fe:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  800100:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800104:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  800106:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  80010a:	f022                	sd	s0,32(sp)
  80010c:	ec26                	sd	s1,24(sp)
  80010e:	e84a                	sd	s2,16(sp)
  800110:	f406                	sd	ra,40(sp)
  800112:	e44e                	sd	s3,8(sp)
  800114:	84aa                	mv	s1,a0
  800116:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800118:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  80011c:	2a01                	sext.w	s4,s4
    if (num >= base) {
  80011e:	03067e63          	bgeu	a2,a6,80015a <printnum+0x60>
  800122:	89be                	mv	s3,a5
        while (-- width > 0)
  800124:	00805763          	blez	s0,800132 <printnum+0x38>
  800128:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  80012a:	85ca                	mv	a1,s2
  80012c:	854e                	mv	a0,s3
  80012e:	9482                	jalr	s1
        while (-- width > 0)
  800130:	fc65                	bnez	s0,800128 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800132:	1a02                	slli	s4,s4,0x20
  800134:	00001797          	auipc	a5,0x1
  800138:	b2c78793          	addi	a5,a5,-1236 # 800c60 <main+0x9c>
  80013c:	020a5a13          	srli	s4,s4,0x20
  800140:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800142:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800144:	000a4503          	lbu	a0,0(s4)
}
  800148:	70a2                	ld	ra,40(sp)
  80014a:	69a2                	ld	s3,8(sp)
  80014c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  80014e:	85ca                	mv	a1,s2
  800150:	87a6                	mv	a5,s1
}
  800152:	6942                	ld	s2,16(sp)
  800154:	64e2                	ld	s1,24(sp)
  800156:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  800158:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  80015a:	03065633          	divu	a2,a2,a6
  80015e:	8722                	mv	a4,s0
  800160:	f9bff0ef          	jal	ra,8000fa <printnum>
  800164:	b7f9                	j	800132 <printnum+0x38>

0000000000800166 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  800166:	7119                	addi	sp,sp,-128
  800168:	f4a6                	sd	s1,104(sp)
  80016a:	f0ca                	sd	s2,96(sp)
  80016c:	ecce                	sd	s3,88(sp)
  80016e:	e8d2                	sd	s4,80(sp)
  800170:	e4d6                	sd	s5,72(sp)
  800172:	e0da                	sd	s6,64(sp)
  800174:	fc5e                	sd	s7,56(sp)
  800176:	f06a                	sd	s10,32(sp)
  800178:	fc86                	sd	ra,120(sp)
  80017a:	f8a2                	sd	s0,112(sp)
  80017c:	f862                	sd	s8,48(sp)
  80017e:	f466                	sd	s9,40(sp)
  800180:	ec6e                	sd	s11,24(sp)
  800182:	892a                	mv	s2,a0
  800184:	84ae                	mv	s1,a1
  800186:	8d32                	mv	s10,a2
  800188:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80018a:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  80018e:	5b7d                	li	s6,-1
  800190:	00001a97          	auipc	s5,0x1
  800194:	b04a8a93          	addi	s5,s5,-1276 # 800c94 <main+0xd0>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800198:	00001b97          	auipc	s7,0x1
  80019c:	d18b8b93          	addi	s7,s7,-744 # 800eb0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001a0:	000d4503          	lbu	a0,0(s10)
  8001a4:	001d0413          	addi	s0,s10,1
  8001a8:	01350a63          	beq	a0,s3,8001bc <vprintfmt+0x56>
            if (ch == '\0') {
  8001ac:	c121                	beqz	a0,8001ec <vprintfmt+0x86>
            putch(ch, putdat);
  8001ae:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001b0:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  8001b2:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001b4:	fff44503          	lbu	a0,-1(s0)
  8001b8:	ff351ae3          	bne	a0,s3,8001ac <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  8001bc:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  8001c0:	02000793          	li	a5,32
        lflag = altflag = 0;
  8001c4:	4c81                	li	s9,0
  8001c6:	4881                	li	a7,0
        width = precision = -1;
  8001c8:	5c7d                	li	s8,-1
  8001ca:	5dfd                	li	s11,-1
  8001cc:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  8001d0:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  8001d2:	fdd6059b          	addiw	a1,a2,-35
  8001d6:	0ff5f593          	zext.b	a1,a1
  8001da:	00140d13          	addi	s10,s0,1
  8001de:	04b56263          	bltu	a0,a1,800222 <vprintfmt+0xbc>
  8001e2:	058a                	slli	a1,a1,0x2
  8001e4:	95d6                	add	a1,a1,s5
  8001e6:	4194                	lw	a3,0(a1)
  8001e8:	96d6                	add	a3,a3,s5
  8001ea:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  8001ec:	70e6                	ld	ra,120(sp)
  8001ee:	7446                	ld	s0,112(sp)
  8001f0:	74a6                	ld	s1,104(sp)
  8001f2:	7906                	ld	s2,96(sp)
  8001f4:	69e6                	ld	s3,88(sp)
  8001f6:	6a46                	ld	s4,80(sp)
  8001f8:	6aa6                	ld	s5,72(sp)
  8001fa:	6b06                	ld	s6,64(sp)
  8001fc:	7be2                	ld	s7,56(sp)
  8001fe:	7c42                	ld	s8,48(sp)
  800200:	7ca2                	ld	s9,40(sp)
  800202:	7d02                	ld	s10,32(sp)
  800204:	6de2                	ld	s11,24(sp)
  800206:	6109                	addi	sp,sp,128
  800208:	8082                	ret
            padc = '0';
  80020a:	87b2                	mv	a5,a2
            goto reswitch;
  80020c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800210:	846a                	mv	s0,s10
  800212:	00140d13          	addi	s10,s0,1
  800216:	fdd6059b          	addiw	a1,a2,-35
  80021a:	0ff5f593          	zext.b	a1,a1
  80021e:	fcb572e3          	bgeu	a0,a1,8001e2 <vprintfmt+0x7c>
            putch('%', putdat);
  800222:	85a6                	mv	a1,s1
  800224:	02500513          	li	a0,37
  800228:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  80022a:	fff44783          	lbu	a5,-1(s0)
  80022e:	8d22                	mv	s10,s0
  800230:	f73788e3          	beq	a5,s3,8001a0 <vprintfmt+0x3a>
  800234:	ffed4783          	lbu	a5,-2(s10)
  800238:	1d7d                	addi	s10,s10,-1
  80023a:	ff379de3          	bne	a5,s3,800234 <vprintfmt+0xce>
  80023e:	b78d                	j	8001a0 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  800240:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  800244:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800248:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  80024a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  80024e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800252:	02d86463          	bltu	a6,a3,80027a <vprintfmt+0x114>
                ch = *fmt;
  800256:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  80025a:	002c169b          	slliw	a3,s8,0x2
  80025e:	0186873b          	addw	a4,a3,s8
  800262:	0017171b          	slliw	a4,a4,0x1
  800266:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  800268:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  80026c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  80026e:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  800272:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800276:	fed870e3          	bgeu	a6,a3,800256 <vprintfmt+0xf0>
            if (width < 0)
  80027a:	f40ddce3          	bgez	s11,8001d2 <vprintfmt+0x6c>
                width = precision, precision = -1;
  80027e:	8de2                	mv	s11,s8
  800280:	5c7d                	li	s8,-1
  800282:	bf81                	j	8001d2 <vprintfmt+0x6c>
            if (width < 0)
  800284:	fffdc693          	not	a3,s11
  800288:	96fd                	srai	a3,a3,0x3f
  80028a:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  80028e:	00144603          	lbu	a2,1(s0)
  800292:	2d81                	sext.w	s11,s11
  800294:	846a                	mv	s0,s10
            goto reswitch;
  800296:	bf35                	j	8001d2 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  800298:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  80029c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  8002a0:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  8002a2:	846a                	mv	s0,s10
            goto process_precision;
  8002a4:	bfd9                	j	80027a <vprintfmt+0x114>
    if (lflag >= 2) {
  8002a6:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002a8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002ac:	01174463          	blt	a4,a7,8002b4 <vprintfmt+0x14e>
    else if (lflag) {
  8002b0:	1a088e63          	beqz	a7,80046c <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  8002b4:	000a3603          	ld	a2,0(s4)
  8002b8:	46c1                	li	a3,16
  8002ba:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002bc:	2781                	sext.w	a5,a5
  8002be:	876e                	mv	a4,s11
  8002c0:	85a6                	mv	a1,s1
  8002c2:	854a                	mv	a0,s2
  8002c4:	e37ff0ef          	jal	ra,8000fa <printnum>
            break;
  8002c8:	bde1                	j	8001a0 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  8002ca:	000a2503          	lw	a0,0(s4)
  8002ce:	85a6                	mv	a1,s1
  8002d0:	0a21                	addi	s4,s4,8
  8002d2:	9902                	jalr	s2
            break;
  8002d4:	b5f1                	j	8001a0 <vprintfmt+0x3a>
    if (lflag >= 2) {
  8002d6:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002d8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002dc:	01174463          	blt	a4,a7,8002e4 <vprintfmt+0x17e>
    else if (lflag) {
  8002e0:	18088163          	beqz	a7,800462 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  8002e4:	000a3603          	ld	a2,0(s4)
  8002e8:	46a9                	li	a3,10
  8002ea:	8a2e                	mv	s4,a1
  8002ec:	bfc1                	j	8002bc <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  8002ee:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  8002f2:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  8002f4:	846a                	mv	s0,s10
            goto reswitch;
  8002f6:	bdf1                	j	8001d2 <vprintfmt+0x6c>
            putch(ch, putdat);
  8002f8:	85a6                	mv	a1,s1
  8002fa:	02500513          	li	a0,37
  8002fe:	9902                	jalr	s2
            break;
  800300:	b545                	j	8001a0 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  800302:	00144603          	lbu	a2,1(s0)
            lflag ++;
  800306:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  800308:	846a                	mv	s0,s10
            goto reswitch;
  80030a:	b5e1                	j	8001d2 <vprintfmt+0x6c>
    if (lflag >= 2) {
  80030c:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80030e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800312:	01174463          	blt	a4,a7,80031a <vprintfmt+0x1b4>
    else if (lflag) {
  800316:	14088163          	beqz	a7,800458 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  80031a:	000a3603          	ld	a2,0(s4)
  80031e:	46a1                	li	a3,8
  800320:	8a2e                	mv	s4,a1
  800322:	bf69                	j	8002bc <vprintfmt+0x156>
            putch('0', putdat);
  800324:	03000513          	li	a0,48
  800328:	85a6                	mv	a1,s1
  80032a:	e03e                	sd	a5,0(sp)
  80032c:	9902                	jalr	s2
            putch('x', putdat);
  80032e:	85a6                	mv	a1,s1
  800330:	07800513          	li	a0,120
  800334:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800336:	0a21                	addi	s4,s4,8
            goto number;
  800338:	6782                	ld	a5,0(sp)
  80033a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80033c:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  800340:	bfb5                	j	8002bc <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  800342:	000a3403          	ld	s0,0(s4)
  800346:	008a0713          	addi	a4,s4,8
  80034a:	e03a                	sd	a4,0(sp)
  80034c:	14040263          	beqz	s0,800490 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  800350:	0fb05763          	blez	s11,80043e <vprintfmt+0x2d8>
  800354:	02d00693          	li	a3,45
  800358:	0cd79163          	bne	a5,a3,80041a <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80035c:	00044783          	lbu	a5,0(s0)
  800360:	0007851b          	sext.w	a0,a5
  800364:	cf85                	beqz	a5,80039c <vprintfmt+0x236>
  800366:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  80036a:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80036e:	000c4563          	bltz	s8,800378 <vprintfmt+0x212>
  800372:	3c7d                	addiw	s8,s8,-1
  800374:	036c0263          	beq	s8,s6,800398 <vprintfmt+0x232>
                    putch('?', putdat);
  800378:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  80037a:	0e0c8e63          	beqz	s9,800476 <vprintfmt+0x310>
  80037e:	3781                	addiw	a5,a5,-32
  800380:	0ef47b63          	bgeu	s0,a5,800476 <vprintfmt+0x310>
                    putch('?', putdat);
  800384:	03f00513          	li	a0,63
  800388:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80038a:	000a4783          	lbu	a5,0(s4)
  80038e:	3dfd                	addiw	s11,s11,-1
  800390:	0a05                	addi	s4,s4,1
  800392:	0007851b          	sext.w	a0,a5
  800396:	ffe1                	bnez	a5,80036e <vprintfmt+0x208>
            for (; width > 0; width --) {
  800398:	01b05963          	blez	s11,8003aa <vprintfmt+0x244>
  80039c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  80039e:	85a6                	mv	a1,s1
  8003a0:	02000513          	li	a0,32
  8003a4:	9902                	jalr	s2
            for (; width > 0; width --) {
  8003a6:	fe0d9be3          	bnez	s11,80039c <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003aa:	6a02                	ld	s4,0(sp)
  8003ac:	bbd5                	j	8001a0 <vprintfmt+0x3a>
    if (lflag >= 2) {
  8003ae:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8003b0:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  8003b4:	01174463          	blt	a4,a7,8003bc <vprintfmt+0x256>
    else if (lflag) {
  8003b8:	08088d63          	beqz	a7,800452 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  8003bc:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  8003c0:	0a044d63          	bltz	s0,80047a <vprintfmt+0x314>
            num = getint(&ap, lflag);
  8003c4:	8622                	mv	a2,s0
  8003c6:	8a66                	mv	s4,s9
  8003c8:	46a9                	li	a3,10
  8003ca:	bdcd                	j	8002bc <vprintfmt+0x156>
            err = va_arg(ap, int);
  8003cc:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003d0:	4761                	li	a4,24
            err = va_arg(ap, int);
  8003d2:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003d4:	41f7d69b          	sraiw	a3,a5,0x1f
  8003d8:	8fb5                	xor	a5,a5,a3
  8003da:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003de:	02d74163          	blt	a4,a3,800400 <vprintfmt+0x29a>
  8003e2:	00369793          	slli	a5,a3,0x3
  8003e6:	97de                	add	a5,a5,s7
  8003e8:	639c                	ld	a5,0(a5)
  8003ea:	cb99                	beqz	a5,800400 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  8003ec:	86be                	mv	a3,a5
  8003ee:	00001617          	auipc	a2,0x1
  8003f2:	8a260613          	addi	a2,a2,-1886 # 800c90 <main+0xcc>
  8003f6:	85a6                	mv	a1,s1
  8003f8:	854a                	mv	a0,s2
  8003fa:	0ce000ef          	jal	ra,8004c8 <printfmt>
  8003fe:	b34d                	j	8001a0 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  800400:	00001617          	auipc	a2,0x1
  800404:	88060613          	addi	a2,a2,-1920 # 800c80 <main+0xbc>
  800408:	85a6                	mv	a1,s1
  80040a:	854a                	mv	a0,s2
  80040c:	0bc000ef          	jal	ra,8004c8 <printfmt>
  800410:	bb41                	j	8001a0 <vprintfmt+0x3a>
                p = "(null)";
  800412:	00001417          	auipc	s0,0x1
  800416:	86640413          	addi	s0,s0,-1946 # 800c78 <main+0xb4>
                for (width -= strnlen(p, precision); width > 0; width --) {
  80041a:	85e2                	mv	a1,s8
  80041c:	8522                	mv	a0,s0
  80041e:	e43e                	sd	a5,8(sp)
  800420:	0c8000ef          	jal	ra,8004e8 <strnlen>
  800424:	40ad8dbb          	subw	s11,s11,a0
  800428:	01b05b63          	blez	s11,80043e <vprintfmt+0x2d8>
                    putch(padc, putdat);
  80042c:	67a2                	ld	a5,8(sp)
  80042e:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800432:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  800434:	85a6                	mv	a1,s1
  800436:	8552                	mv	a0,s4
  800438:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  80043a:	fe0d9ce3          	bnez	s11,800432 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80043e:	00044783          	lbu	a5,0(s0)
  800442:	00140a13          	addi	s4,s0,1
  800446:	0007851b          	sext.w	a0,a5
  80044a:	d3a5                	beqz	a5,8003aa <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  80044c:	05e00413          	li	s0,94
  800450:	bf39                	j	80036e <vprintfmt+0x208>
        return va_arg(*ap, int);
  800452:	000a2403          	lw	s0,0(s4)
  800456:	b7ad                	j	8003c0 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  800458:	000a6603          	lwu	a2,0(s4)
  80045c:	46a1                	li	a3,8
  80045e:	8a2e                	mv	s4,a1
  800460:	bdb1                	j	8002bc <vprintfmt+0x156>
  800462:	000a6603          	lwu	a2,0(s4)
  800466:	46a9                	li	a3,10
  800468:	8a2e                	mv	s4,a1
  80046a:	bd89                	j	8002bc <vprintfmt+0x156>
  80046c:	000a6603          	lwu	a2,0(s4)
  800470:	46c1                	li	a3,16
  800472:	8a2e                	mv	s4,a1
  800474:	b5a1                	j	8002bc <vprintfmt+0x156>
                    putch(ch, putdat);
  800476:	9902                	jalr	s2
  800478:	bf09                	j	80038a <vprintfmt+0x224>
                putch('-', putdat);
  80047a:	85a6                	mv	a1,s1
  80047c:	02d00513          	li	a0,45
  800480:	e03e                	sd	a5,0(sp)
  800482:	9902                	jalr	s2
                num = -(long long)num;
  800484:	6782                	ld	a5,0(sp)
  800486:	8a66                	mv	s4,s9
  800488:	40800633          	neg	a2,s0
  80048c:	46a9                	li	a3,10
  80048e:	b53d                	j	8002bc <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  800490:	03b05163          	blez	s11,8004b2 <vprintfmt+0x34c>
  800494:	02d00693          	li	a3,45
  800498:	f6d79de3          	bne	a5,a3,800412 <vprintfmt+0x2ac>
                p = "(null)";
  80049c:	00000417          	auipc	s0,0x0
  8004a0:	7dc40413          	addi	s0,s0,2012 # 800c78 <main+0xb4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004a4:	02800793          	li	a5,40
  8004a8:	02800513          	li	a0,40
  8004ac:	00140a13          	addi	s4,s0,1
  8004b0:	bd6d                	j	80036a <vprintfmt+0x204>
  8004b2:	00000a17          	auipc	s4,0x0
  8004b6:	7c7a0a13          	addi	s4,s4,1991 # 800c79 <main+0xb5>
  8004ba:	02800513          	li	a0,40
  8004be:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  8004c2:	05e00413          	li	s0,94
  8004c6:	b565                	j	80036e <vprintfmt+0x208>

00000000008004c8 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004c8:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004ca:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004ce:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004d0:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004d2:	ec06                	sd	ra,24(sp)
  8004d4:	f83a                	sd	a4,48(sp)
  8004d6:	fc3e                	sd	a5,56(sp)
  8004d8:	e0c2                	sd	a6,64(sp)
  8004da:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004dc:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004de:	c89ff0ef          	jal	ra,800166 <vprintfmt>
}
  8004e2:	60e2                	ld	ra,24(sp)
  8004e4:	6161                	addi	sp,sp,80
  8004e6:	8082                	ret

00000000008004e8 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  8004e8:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  8004ea:	e589                	bnez	a1,8004f4 <strnlen+0xc>
  8004ec:	a811                	j	800500 <strnlen+0x18>
        cnt ++;
  8004ee:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  8004f0:	00f58863          	beq	a1,a5,800500 <strnlen+0x18>
  8004f4:	00f50733          	add	a4,a0,a5
  8004f8:	00074703          	lbu	a4,0(a4)
  8004fc:	fb6d                	bnez	a4,8004ee <strnlen+0x6>
  8004fe:	85be                	mv	a1,a5
    }
    return cnt;
}
  800500:	852e                	mv	a0,a1
  800502:	8082                	ret

0000000000800504 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
  800504:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
  800506:	0005c703          	lbu	a4,0(a1)
  80050a:	0785                	addi	a5,a5,1
  80050c:	0585                	addi	a1,a1,1
  80050e:	fee78fa3          	sb	a4,-1(a5)
  800512:	fb75                	bnez	a4,800506 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
  800514:	8082                	ret

0000000000800516 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
  800516:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
  80051a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
  80051e:	cb89                	beqz	a5,800530 <strcmp+0x1a>
        s1 ++, s2 ++;
  800520:	0505                	addi	a0,a0,1
  800522:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
  800524:	fee789e3          	beq	a5,a4,800516 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
  800528:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
  80052c:	9d19                	subw	a0,a0,a4
  80052e:	8082                	ret
  800530:	4501                	li	a0,0
  800532:	bfed                	j	80052c <strcmp+0x16>

0000000000800534 <test_basic_cow>:
// 全局测试数据（会被映射到用户空间）
static char test_data[PGSIZE] = "Initial data before fork";
static int shared_counter = 0;

/* 测试1：基础COW - 验证fork后的共享 */
void test_basic_cow(void) {
  800534:	1101                	addi	sp,sp,-32
    cprintf("\n========== 测试1：基础COW共享 ==========\n");
  800536:	00001517          	auipc	a0,0x1
  80053a:	a4250513          	addi	a0,a0,-1470 # 800f78 <error_string+0xc8>
void test_basic_cow(void) {
  80053e:	ec06                	sd	ra,24(sp)
    cprintf("\n========== 测试1：基础COW共享 ==========\n");
  800540:	b01ff0ef          	jal	ra,800040 <cprintf>
    
    int original_value = 12345;
  800544:	660d                	lui	a2,0x3
  800546:	03960613          	addi	a2,a2,57 # 3039 <_start-0x7fcfe7>
    int *shared_var = &original_value;
    
    cprintf("Fork前: shared_var地址=0x%x, 值=%d\n", 
  80054a:	002c                	addi	a1,sp,8
  80054c:	00001517          	auipc	a0,0x1
  800550:	a6450513          	addi	a0,a0,-1436 # 800fb0 <error_string+0x100>
    int original_value = 12345;
  800554:	c432                	sw	a2,8(sp)
    cprintf("Fork前: shared_var地址=0x%x, 值=%d\n", 
  800556:	aebff0ef          	jal	ra,800040 <cprintf>
            shared_var, *shared_var);
    
    int pid = fork();
  80055a:	b8dff0ef          	jal	ra,8000e6 <fork>
    
    if (pid == 0) {
  80055e:	c505                	beqz	a0,800586 <test_basic_cow+0x52>
        
        exit(0);
    } else {
        // 父进程等待子进程
        int exit_code;
        waitpid(pid, &exit_code);
  800560:	006c                	addi	a1,sp,12
  800562:	b87ff0ef          	jal	ra,8000e8 <waitpid>
        cprintf("[父进程] 子进程退出，exit_code=%d\n", exit_code);
  800566:	45b2                	lw	a1,12(sp)
  800568:	00001517          	auipc	a0,0x1
  80056c:	af850513          	addi	a0,a0,-1288 # 801060 <error_string+0x1b0>
  800570:	ad1ff0ef          	jal	ra,800040 <cprintf>
    }
    
    cprintf("✓ 测试1通过：fork后成功共享页面\n");
  800574:	00001517          	auipc	a0,0x1
  800578:	b1c50513          	addi	a0,a0,-1252 # 801090 <error_string+0x1e0>
  80057c:	ac5ff0ef          	jal	ra,800040 <cprintf>
}
  800580:	60e2                	ld	ra,24(sp)
  800582:	6105                	addi	sp,sp,32
  800584:	8082                	ret
        cprintf("[子进程] shared_var地址=0x%x, 值=%d\n", 
  800586:	4622                	lw	a2,8(sp)
  800588:	002c                	addi	a1,sp,8
  80058a:	00001517          	auipc	a0,0x1
  80058e:	a4e50513          	addi	a0,a0,-1458 # 800fd8 <error_string+0x128>
  800592:	aafff0ef          	jal	ra,800040 <cprintf>
        cprintf("[子进程] 读取成功，页面共享正常\n");
  800596:	00001517          	auipc	a0,0x1
  80059a:	a7250513          	addi	a0,a0,-1422 # 801008 <error_string+0x158>
  80059e:	aa3ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[子进程] test_data内容: %s\n", test_data);
  8005a2:	00002597          	auipc	a1,0x2
  8005a6:	b0658593          	addi	a1,a1,-1274 # 8020a8 <test_data>
  8005aa:	00001517          	auipc	a0,0x1
  8005ae:	a8e50513          	addi	a0,a0,-1394 # 801038 <error_string+0x188>
  8005b2:	a8fff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  8005b6:	4501                	li	a0,0
  8005b8:	b19ff0ef          	jal	ra,8000d0 <exit>

00000000008005bc <test_cow_write>:

/* 测试2：写时复制 - 验证修改触发复制 */
void test_cow_write(void) {
  8005bc:	1101                	addi	sp,sp,-32
    cprintf("\n========== 测试2：写时复制触发 ==========\n");
  8005be:	00001517          	auipc	a0,0x1
  8005c2:	b0250513          	addi	a0,a0,-1278 # 8010c0 <error_string+0x210>
void test_cow_write(void) {
  8005c6:	ec06                	sd	ra,24(sp)
  8005c8:	e822                	sd	s0,16(sp)
    cprintf("\n========== 测试2：写时复制触发 ==========\n");
  8005ca:	a77ff0ef          	jal	ra,800040 <cprintf>
    
    // 准备测试数据
    static int test_array[10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    
    cprintf("Fork前: test_array[0]=%d\n", test_array[0]);
  8005ce:	00002417          	auipc	s0,0x2
  8005d2:	ab240413          	addi	s0,s0,-1358 # 802080 <test_array.7>
  8005d6:	400c                	lw	a1,0(s0)
  8005d8:	00001517          	auipc	a0,0x1
  8005dc:	b2050513          	addi	a0,a0,-1248 # 8010f8 <error_string+0x248>
  8005e0:	a61ff0ef          	jal	ra,800040 <cprintf>
    
    int pid = fork();
  8005e4:	b03ff0ef          	jal	ra,8000e6 <fork>
    
    if (pid == 0) {
  8005e8:	c129                	beqz	a0,80062a <test_cow_write+0x6e>
        
        exit(0);
    } else {
        // 父进程等待
        int exit_code;
        waitpid(pid, &exit_code);
  8005ea:	006c                	addi	a1,sp,12
  8005ec:	afdff0ef          	jal	ra,8000e8 <waitpid>
        
        // 验证父进程的数据未被修改
        cprintf("[父进程] test_array[0]=%d (应该仍是0)\n", test_array[0]);
  8005f0:	400c                	lw	a1,0(s0)
  8005f2:	00001517          	auipc	a0,0x1
  8005f6:	bbe50513          	addi	a0,a0,-1090 # 8011b0 <error_string+0x300>
  8005fa:	a47ff0ef          	jal	ra,800040 <cprintf>
        
        if (test_array[0] == 0) {
  8005fe:	401c                	lw	a5,0(s0)
  800600:	cb99                	beqz	a5,800616 <test_cow_write+0x5a>
            cprintf("✓ 测试2通过：COW成功隔离父子进程数据\n");
        } else {
            cprintf("✗ 测试2失败：父进程数据被子进程修改！\n");
  800602:	00001517          	auipc	a0,0x1
  800606:	c1650513          	addi	a0,a0,-1002 # 801218 <error_string+0x368>
  80060a:	a37ff0ef          	jal	ra,800040 <cprintf>
        }
    }
}
  80060e:	60e2                	ld	ra,24(sp)
  800610:	6442                	ld	s0,16(sp)
  800612:	6105                	addi	sp,sp,32
  800614:	8082                	ret
            cprintf("✓ 测试2通过：COW成功隔离父子进程数据\n");
  800616:	00001517          	auipc	a0,0x1
  80061a:	bca50513          	addi	a0,a0,-1078 # 8011e0 <error_string+0x330>
  80061e:	a23ff0ef          	jal	ra,800040 <cprintf>
}
  800622:	60e2                	ld	ra,24(sp)
  800624:	6442                	ld	s0,16(sp)
  800626:	6105                	addi	sp,sp,32
  800628:	8082                	ret
        cprintf("[子进程] 修改前: test_array[0]=%d\n", test_array[0]);
  80062a:	400c                	lw	a1,0(s0)
  80062c:	00001517          	auipc	a0,0x1
  800630:	aec50513          	addi	a0,a0,-1300 # 801118 <error_string+0x268>
  800634:	a0dff0ef          	jal	ra,800040 <cprintf>
        test_array[0] = 999;
  800638:	3e700793          	li	a5,999
        cprintf("[子进程] 修改后: test_array[0]=%d\n", test_array[0]);
  80063c:	3e700593          	li	a1,999
  800640:	00001517          	auipc	a0,0x1
  800644:	b0850513          	addi	a0,a0,-1272 # 801148 <error_string+0x298>
        test_array[0] = 999;
  800648:	c01c                	sw	a5,0(s0)
        cprintf("[子进程] 修改后: test_array[0]=%d\n", test_array[0]);
  80064a:	9f7ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[子进程] 写时复制触发，数据已独立\n");
  80064e:	00001517          	auipc	a0,0x1
  800652:	b2a50513          	addi	a0,a0,-1238 # 801178 <error_string+0x2c8>
  800656:	9ebff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  80065a:	4501                	li	a0,0
  80065c:	a75ff0ef          	jal	ra,8000d0 <exit>

0000000000800660 <test_multiple_writes>:

/* 测试3：多次写操作 - 验证复制后的页面可正常写入 */
void test_multiple_writes(void) {
  800660:	1101                	addi	sp,sp,-32
    cprintf("\n========== 测试3：多次写操作 ==========\n");
  800662:	00001517          	auipc	a0,0x1
  800666:	bf650513          	addi	a0,a0,-1034 # 801258 <error_string+0x3a8>
void test_multiple_writes(void) {
  80066a:	ec06                	sd	ra,24(sp)
    cprintf("\n========== 测试3：多次写操作 ==========\n");
  80066c:	9d5ff0ef          	jal	ra,800040 <cprintf>
    
    static char buffer[100] = "Original text";
    
    int pid = fork();
  800670:	a77ff0ef          	jal	ra,8000e6 <fork>
    
    if (pid == 0) {
  800674:	c939                	beqz	a0,8006ca <test_multiple_writes+0x6a>
        
        cprintf("[子进程] 最终内容: %s\n", buffer);
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
  800676:	006c                	addi	a1,sp,12
  800678:	a71ff0ef          	jal	ra,8000e8 <waitpid>
        
        cprintf("[父进程] 内容: %s\n", buffer);
  80067c:	00002597          	auipc	a1,0x2
  800680:	98458593          	addi	a1,a1,-1660 # 802000 <buffer.6>
  800684:	00001517          	auipc	a0,0x1
  800688:	cd450513          	addi	a0,a0,-812 # 801358 <error_string+0x4a8>
  80068c:	9b5ff0ef          	jal	ra,800040 <cprintf>
        if (strcmp(buffer, "Original text") == 0) {
  800690:	00001597          	auipc	a1,0x1
  800694:	ce058593          	addi	a1,a1,-800 # 801370 <error_string+0x4c0>
  800698:	00002517          	auipc	a0,0x2
  80069c:	96850513          	addi	a0,a0,-1688 # 802000 <buffer.6>
  8006a0:	e77ff0ef          	jal	ra,800516 <strcmp>
  8006a4:	c911                	beqz	a0,8006b8 <test_multiple_writes+0x58>
            cprintf("✓ 测试3通过：多次写操作正常\n");
        } else {
            cprintf("✗ 测试3失败\n");
  8006a6:	00001517          	auipc	a0,0x1
  8006aa:	d0a50513          	addi	a0,a0,-758 # 8013b0 <error_string+0x500>
  8006ae:	993ff0ef          	jal	ra,800040 <cprintf>
        }
    }
}
  8006b2:	60e2                	ld	ra,24(sp)
  8006b4:	6105                	addi	sp,sp,32
  8006b6:	8082                	ret
            cprintf("✓ 测试3通过：多次写操作正常\n");
  8006b8:	00001517          	auipc	a0,0x1
  8006bc:	cc850513          	addi	a0,a0,-824 # 801380 <error_string+0x4d0>
  8006c0:	981ff0ef          	jal	ra,800040 <cprintf>
}
  8006c4:	60e2                	ld	ra,24(sp)
  8006c6:	6105                	addi	sp,sp,32
  8006c8:	8082                	ret
        cprintf("[子进程] 第1次写入...\n");
  8006ca:	00001517          	auipc	a0,0x1
  8006ce:	bc650513          	addi	a0,a0,-1082 # 801290 <error_string+0x3e0>
  8006d2:	96fff0ef          	jal	ra,800040 <cprintf>
        strcpy(buffer, "Modified by child 1");
  8006d6:	00001597          	auipc	a1,0x1
  8006da:	bda58593          	addi	a1,a1,-1062 # 8012b0 <error_string+0x400>
  8006de:	00002517          	auipc	a0,0x2
  8006e2:	92250513          	addi	a0,a0,-1758 # 802000 <buffer.6>
  8006e6:	e1fff0ef          	jal	ra,800504 <strcpy>
        cprintf("[子进程] 第2次写入...\n");
  8006ea:	00001517          	auipc	a0,0x1
  8006ee:	bde50513          	addi	a0,a0,-1058 # 8012c8 <error_string+0x418>
  8006f2:	94fff0ef          	jal	ra,800040 <cprintf>
        strcpy(buffer, "Modified by child 2");
  8006f6:	00001597          	auipc	a1,0x1
  8006fa:	bf258593          	addi	a1,a1,-1038 # 8012e8 <error_string+0x438>
  8006fe:	00002517          	auipc	a0,0x2
  800702:	90250513          	addi	a0,a0,-1790 # 802000 <buffer.6>
  800706:	dffff0ef          	jal	ra,800504 <strcpy>
        cprintf("[子进程] 第3次写入...\n");
  80070a:	00001517          	auipc	a0,0x1
  80070e:	bf650513          	addi	a0,a0,-1034 # 801300 <error_string+0x450>
  800712:	92fff0ef          	jal	ra,800040 <cprintf>
        strcpy(buffer, "Modified by child 3");
  800716:	00001597          	auipc	a1,0x1
  80071a:	c0a58593          	addi	a1,a1,-1014 # 801320 <error_string+0x470>
  80071e:	00002517          	auipc	a0,0x2
  800722:	8e250513          	addi	a0,a0,-1822 # 802000 <buffer.6>
  800726:	ddfff0ef          	jal	ra,800504 <strcpy>
        cprintf("[子进程] 最终内容: %s\n", buffer);
  80072a:	00002597          	auipc	a1,0x2
  80072e:	8d658593          	addi	a1,a1,-1834 # 802000 <buffer.6>
  800732:	00001517          	auipc	a0,0x1
  800736:	c0650513          	addi	a0,a0,-1018 # 801338 <error_string+0x488>
  80073a:	907ff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  80073e:	4501                	li	a0,0
  800740:	991ff0ef          	jal	ra,8000d0 <exit>

0000000000800744 <test_multiple_children>:

/* 测试4：多个子进程共享 */
void test_multiple_children(void) {
  800744:	7179                	addi	sp,sp,-48
    cprintf("\n========== 测试4：多个子进程共享 ==========\n");
  800746:	00001517          	auipc	a0,0x1
  80074a:	c8250513          	addi	a0,a0,-894 # 8013c8 <error_string+0x518>
void test_multiple_children(void) {
  80074e:	f406                	sd	ra,40(sp)
  800750:	f022                	sd	s0,32(sp)
  800752:	ec26                	sd	s1,24(sp)
  800754:	e84a                	sd	s2,16(sp)
    cprintf("\n========== 测试4：多个子进程共享 ==========\n");
  800756:	8ebff0ef          	jal	ra,800040 <cprintf>
    
    static int shared_data = 100;
    
    cprintf("创建3个子进程...\n");
  80075a:	00001517          	auipc	a0,0x1
  80075e:	ca650513          	addi	a0,a0,-858 # 801400 <error_string+0x550>
  800762:	8dfff0ef          	jal	ra,800040 <cprintf>
    
    int pid1 = fork();
  800766:	981ff0ef          	jal	ra,8000e6 <fork>
    if (pid1 == 0) {
  80076a:	10050563          	beqz	a0,800874 <test_multiple_children+0x130>
  80076e:	842a                	mv	s0,a0
        yield();  // 让出CPU
        cprintf("[子进程1] 再次读取 shared_data=%d\n", shared_data);
        exit(1);
    }
    
    int pid2 = fork();
  800770:	977ff0ef          	jal	ra,8000e6 <fork>
  800774:	892a                	mv	s2,a0
    if (pid2 == 0) {
  800776:	0c050863          	beqz	a0,800846 <test_multiple_children+0x102>
        yield();
        cprintf("[子进程2] 再次读取 shared_data=%d\n", shared_data);
        exit(2);
    }
    
    int pid3 = fork();
  80077a:	96dff0ef          	jal	ra,8000e6 <fork>
  80077e:	84aa                	mv	s1,a0
    if (pid3 == 0) {
  800780:	c951                	beqz	a0,800814 <test_multiple_children+0xd0>
        exit(3);
    }
    
    // 父进程：等待所有子进程
    int exit_code;
    waitpid(pid1, &exit_code);
  800782:	006c                	addi	a1,sp,12
  800784:	8522                	mv	a0,s0
  800786:	963ff0ef          	jal	ra,8000e8 <waitpid>
    cprintf("子进程1退出，exit_code=%d\n", exit_code);
  80078a:	45b2                	lw	a1,12(sp)
  80078c:	00001517          	auipc	a0,0x1
  800790:	d8c50513          	addi	a0,a0,-628 # 801518 <error_string+0x668>
    cprintf("子进程2退出，exit_code=%d\n", exit_code);
    
    waitpid(pid3, &exit_code);
    cprintf("子进程3退出，exit_code=%d\n", exit_code);
    
    cprintf("[父进程] shared_data=%d (应该仍是100)\n", shared_data);
  800794:	00003417          	auipc	s0,0x3
  800798:	91440413          	addi	s0,s0,-1772 # 8030a8 <shared_data.5>
    cprintf("子进程1退出，exit_code=%d\n", exit_code);
  80079c:	8a5ff0ef          	jal	ra,800040 <cprintf>
    waitpid(pid2, &exit_code);
  8007a0:	006c                	addi	a1,sp,12
  8007a2:	854a                	mv	a0,s2
  8007a4:	945ff0ef          	jal	ra,8000e8 <waitpid>
    cprintf("子进程2退出，exit_code=%d\n", exit_code);
  8007a8:	45b2                	lw	a1,12(sp)
  8007aa:	00001517          	auipc	a0,0x1
  8007ae:	d9650513          	addi	a0,a0,-618 # 801540 <error_string+0x690>
  8007b2:	88fff0ef          	jal	ra,800040 <cprintf>
    waitpid(pid3, &exit_code);
  8007b6:	006c                	addi	a1,sp,12
  8007b8:	8526                	mv	a0,s1
  8007ba:	92fff0ef          	jal	ra,8000e8 <waitpid>
    cprintf("子进程3退出，exit_code=%d\n", exit_code);
  8007be:	45b2                	lw	a1,12(sp)
  8007c0:	00001517          	auipc	a0,0x1
  8007c4:	da850513          	addi	a0,a0,-600 # 801568 <error_string+0x6b8>
  8007c8:	879ff0ef          	jal	ra,800040 <cprintf>
    cprintf("[父进程] shared_data=%d (应该仍是100)\n", shared_data);
  8007cc:	400c                	lw	a1,0(s0)
  8007ce:	00001517          	auipc	a0,0x1
  8007d2:	dc250513          	addi	a0,a0,-574 # 801590 <error_string+0x6e0>
  8007d6:	86bff0ef          	jal	ra,800040 <cprintf>
    
    if (shared_data == 100) {
  8007da:	4018                	lw	a4,0(s0)
  8007dc:	06400793          	li	a5,100
  8007e0:	00f70e63          	beq	a4,a5,8007fc <test_multiple_children+0xb8>
        cprintf("✓ 测试4通过：多子进程COW正常\n");
    } else {
        cprintf("✗ 测试4失败\n");
  8007e4:	00001517          	auipc	a0,0x1
  8007e8:	e0c50513          	addi	a0,a0,-500 # 8015f0 <error_string+0x740>
  8007ec:	855ff0ef          	jal	ra,800040 <cprintf>
    }
}
  8007f0:	70a2                	ld	ra,40(sp)
  8007f2:	7402                	ld	s0,32(sp)
  8007f4:	64e2                	ld	s1,24(sp)
  8007f6:	6942                	ld	s2,16(sp)
  8007f8:	6145                	addi	sp,sp,48
  8007fa:	8082                	ret
        cprintf("✓ 测试4通过：多子进程COW正常\n");
  8007fc:	00001517          	auipc	a0,0x1
  800800:	dc450513          	addi	a0,a0,-572 # 8015c0 <error_string+0x710>
  800804:	83dff0ef          	jal	ra,800040 <cprintf>
}
  800808:	70a2                	ld	ra,40(sp)
  80080a:	7402                	ld	s0,32(sp)
  80080c:	64e2                	ld	s1,24(sp)
  80080e:	6942                	ld	s2,16(sp)
  800810:	6145                	addi	sp,sp,48
  800812:	8082                	ret
        cprintf("[子进程3] 修改前 shared_data=%d\n", shared_data);
  800814:	00003417          	auipc	s0,0x3
  800818:	89440413          	addi	s0,s0,-1900 # 8030a8 <shared_data.5>
  80081c:	400c                	lw	a1,0(s0)
  80081e:	00001517          	auipc	a0,0x1
  800822:	caa50513          	addi	a0,a0,-854 # 8014c8 <error_string+0x618>
  800826:	81bff0ef          	jal	ra,800040 <cprintf>
        shared_data = 300;
  80082a:	12c00793          	li	a5,300
        cprintf("[子进程3] 修改后 shared_data=%d\n", shared_data);
  80082e:	12c00593          	li	a1,300
  800832:	00001517          	auipc	a0,0x1
  800836:	cbe50513          	addi	a0,a0,-834 # 8014f0 <error_string+0x640>
        shared_data = 300;
  80083a:	c01c                	sw	a5,0(s0)
        cprintf("[子进程3] 修改后 shared_data=%d\n", shared_data);
  80083c:	805ff0ef          	jal	ra,800040 <cprintf>
        exit(3);
  800840:	450d                	li	a0,3
  800842:	88fff0ef          	jal	ra,8000d0 <exit>
        cprintf("[子进程2] 读取 shared_data=%d\n", shared_data);
  800846:	00003417          	auipc	s0,0x3
  80084a:	86240413          	addi	s0,s0,-1950 # 8030a8 <shared_data.5>
  80084e:	400c                	lw	a1,0(s0)
  800850:	00001517          	auipc	a0,0x1
  800854:	c2050513          	addi	a0,a0,-992 # 801470 <error_string+0x5c0>
  800858:	fe8ff0ef          	jal	ra,800040 <cprintf>
        yield();
  80085c:	88fff0ef          	jal	ra,8000ea <yield>
        cprintf("[子进程2] 再次读取 shared_data=%d\n", shared_data);
  800860:	400c                	lw	a1,0(s0)
  800862:	00001517          	auipc	a0,0x1
  800866:	c3650513          	addi	a0,a0,-970 # 801498 <error_string+0x5e8>
  80086a:	fd6ff0ef          	jal	ra,800040 <cprintf>
        exit(2);
  80086e:	4509                	li	a0,2
  800870:	861ff0ef          	jal	ra,8000d0 <exit>
        cprintf("[子进程1] 读取 shared_data=%d\n", shared_data);
  800874:	00003417          	auipc	s0,0x3
  800878:	83440413          	addi	s0,s0,-1996 # 8030a8 <shared_data.5>
  80087c:	400c                	lw	a1,0(s0)
  80087e:	00001517          	auipc	a0,0x1
  800882:	b9a50513          	addi	a0,a0,-1126 # 801418 <error_string+0x568>
  800886:	fbaff0ef          	jal	ra,800040 <cprintf>
        yield();  // 让出CPU
  80088a:	861ff0ef          	jal	ra,8000ea <yield>
        cprintf("[子进程1] 再次读取 shared_data=%d\n", shared_data);
  80088e:	400c                	lw	a1,0(s0)
  800890:	00001517          	auipc	a0,0x1
  800894:	bb050513          	addi	a0,a0,-1104 # 801440 <error_string+0x590>
  800898:	fa8ff0ef          	jal	ra,800040 <cprintf>
        exit(1);
  80089c:	4505                	li	a0,1
  80089e:	833ff0ef          	jal	ra,8000d0 <exit>

00000000008008a2 <test_heavy_write>:

/* 测试5：大量写操作压力测试 */
void test_heavy_write(void) {
  8008a2:	7179                	addi	sp,sp,-48
    cprintf("\n========== 测试5：大量写操作 ==========\n");
  8008a4:	00001517          	auipc	a0,0x1
  8008a8:	d6450513          	addi	a0,a0,-668 # 801608 <error_string+0x758>
void test_heavy_write(void) {
  8008ac:	f022                	sd	s0,32(sp)
  8008ae:	ec26                	sd	s1,24(sp)
  8008b0:	f406                	sd	ra,40(sp)
  8008b2:	e84a                	sd	s2,16(sp)
  8008b4:	0000c497          	auipc	s1,0xc
  8008b8:	7fc48493          	addi	s1,s1,2044 # 80d0b0 <large_buffer.4>
    cprintf("\n========== 测试5：大量写操作 ==========\n");
  8008bc:	f84ff0ef          	jal	ra,800040 <cprintf>
    
    // 分配多个页面的数据
    static char large_buffer[PGSIZE * 4];
    
    // 初始化数据
    for (int i = 0; i < PGSIZE * 4; i++) {
  8008c0:	4401                	li	s0,0
    cprintf("\n========== 测试5：大量写操作 ==========\n");
  8008c2:	8726                	mv	a4,s1
        large_buffer[i] = 'A' + (i % 26);
  8008c4:	4669                	li	a2,26
    for (int i = 0; i < PGSIZE * 4; i++) {
  8008c6:	6691                	lui	a3,0x4
        large_buffer[i] = 'A' + (i % 26);
  8008c8:	02c467bb          	remw	a5,s0,a2
    for (int i = 0; i < PGSIZE * 4; i++) {
  8008cc:	0705                	addi	a4,a4,1
  8008ce:	2405                	addiw	s0,s0,1
        large_buffer[i] = 'A' + (i % 26);
  8008d0:	0417879b          	addiw	a5,a5,65
  8008d4:	fef70fa3          	sb	a5,-1(a4)
    for (int i = 0; i < PGSIZE * 4; i++) {
  8008d8:	fed418e3          	bne	s0,a3,8008c8 <test_heavy_write+0x26>
    }
    
    int pid = fork();
  8008dc:	80bff0ef          	jal	ra,8000e6 <fork>
  8008e0:	892a                	mv	s2,a0
    
    if (pid == 0) {
  8008e2:	c921                	beqz	a0,800932 <test_heavy_write+0x90>
        
        cprintf("[子进程] 验证：%d个位置被正确修改\n", count);
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
  8008e4:	006c                	addi	a1,sp,12
  8008e6:	803ff0ef          	jal	ra,8000e8 <waitpid>
        
        // 验证父进程数据未变
        int unchanged = 1;
        for (int i = 0; i < PGSIZE * 4; i += 128) {
  8008ea:	9426                	add	s0,s0,s1
            if (large_buffer[i] == 'X') {
  8008ec:	05800713          	li	a4,88
  8008f0:	a029                	j	8008fa <test_heavy_write+0x58>
        for (int i = 0; i < PGSIZE * 4; i += 128) {
  8008f2:	08048493          	addi	s1,s1,128
  8008f6:	02848263          	beq	s1,s0,80091a <test_heavy_write+0x78>
            if (large_buffer[i] == 'X') {
  8008fa:	0004c783          	lbu	a5,0(s1)
  8008fe:	fee79ae3          	bne	a5,a4,8008f2 <test_heavy_write+0x50>
        }
        
        if (unchanged) {
            cprintf("✓ 测试5通过：大量写操作COW正常\n");
        } else {
            cprintf("✗ 测试5失败：父进程数据被修改\n");
  800902:	00001517          	auipc	a0,0x1
  800906:	dbe50513          	addi	a0,a0,-578 # 8016c0 <error_string+0x810>
  80090a:	f36ff0ef          	jal	ra,800040 <cprintf>
        }
    }
}
  80090e:	70a2                	ld	ra,40(sp)
  800910:	7402                	ld	s0,32(sp)
  800912:	64e2                	ld	s1,24(sp)
  800914:	6942                	ld	s2,16(sp)
  800916:	6145                	addi	sp,sp,48
  800918:	8082                	ret
            cprintf("✓ 测试5通过：大量写操作COW正常\n");
  80091a:	00001517          	auipc	a0,0x1
  80091e:	dd650513          	addi	a0,a0,-554 # 8016f0 <error_string+0x840>
  800922:	f1eff0ef          	jal	ra,800040 <cprintf>
}
  800926:	70a2                	ld	ra,40(sp)
  800928:	7402                	ld	s0,32(sp)
  80092a:	64e2                	ld	s1,24(sp)
  80092c:	6942                	ld	s2,16(sp)
  80092e:	6145                	addi	sp,sp,48
  800930:	8082                	ret
        cprintf("[子进程] 开始写入%d字节...\n", PGSIZE * 4);
  800932:	6591                	lui	a1,0x4
  800934:	00001517          	auipc	a0,0x1
  800938:	d0c50513          	addi	a0,a0,-756 # 801640 <error_string+0x790>
  80093c:	f04ff0ef          	jal	ra,800040 <cprintf>
        for (int i = 0; i < PGSIZE * 4; i += 128) {
  800940:	9426                	add	s0,s0,s1
        cprintf("[子进程] 开始写入%d字节...\n", PGSIZE * 4);
  800942:	0000c797          	auipc	a5,0xc
  800946:	76e78793          	addi	a5,a5,1902 # 80d0b0 <large_buffer.4>
            large_buffer[i] = 'X';  // 每隔128字节写一次
  80094a:	05800713          	li	a4,88
  80094e:	00e78023          	sb	a4,0(a5)
        for (int i = 0; i < PGSIZE * 4; i += 128) {
  800952:	08078793          	addi	a5,a5,128
  800956:	fef41ce3          	bne	s0,a5,80094e <test_heavy_write+0xac>
        cprintf("[子进程] 写入完成\n");
  80095a:	00001517          	auipc	a0,0x1
  80095e:	d0e50513          	addi	a0,a0,-754 # 801668 <error_string+0x7b8>
  800962:	edeff0ef          	jal	ra,800040 <cprintf>
            if (large_buffer[i] == 'X') count++;
  800966:	05800793          	li	a5,88
  80096a:	0004c703          	lbu	a4,0(s1)
  80096e:	00f71363          	bne	a4,a5,800974 <test_heavy_write+0xd2>
  800972:	2905                	addiw	s2,s2,1
        for (int i = 0; i < PGSIZE * 4; i += 128) {
  800974:	08048493          	addi	s1,s1,128
  800978:	fe8499e3          	bne	s1,s0,80096a <test_heavy_write+0xc8>
        cprintf("[子进程] 验证：%d个位置被正确修改\n", count);
  80097c:	85ca                	mv	a1,s2
  80097e:	00001517          	auipc	a0,0x1
  800982:	d0a50513          	addi	a0,a0,-758 # 801688 <error_string+0x7d8>
  800986:	ebaff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  80098a:	4501                	li	a0,0
  80098c:	f44ff0ef          	jal	ra,8000d0 <exit>

0000000000800990 <test_recursive_fork>:

/* 测试6：递归fork测试 */
void test_recursive_fork(int depth) {
    if (depth <= 0) return;
  800990:	00a05363          	blez	a0,800996 <test_recursive_fork+0x6>
  800994:	a011                	j	800998 <test_recursive_fork.part.0>
        // 父进程等待
        int exit_code;
        waitpid(pid, &exit_code);
        cprintf("[深度%d父进程] counter=%d\n", depth, counter);
    }
}
  800996:	8082                	ret

0000000000800998 <test_recursive_fork.part.0>:
void test_recursive_fork(int depth) {
  800998:	7179                	addi	sp,sp,-48
  80099a:	f406                	sd	ra,40(sp)
  80099c:	f022                	sd	s0,32(sp)
  80099e:	ec26                	sd	s1,24(sp)
  8009a0:	842a                	mv	s0,a0
    cprintf("[深度%d] 当前进程PID=%d\n", depth, getpid());
  8009a2:	f4aff0ef          	jal	ra,8000ec <getpid>
  8009a6:	862a                	mv	a2,a0
  8009a8:	85a2                	mv	a1,s0
  8009aa:	00001517          	auipc	a0,0x1
  8009ae:	d7650513          	addi	a0,a0,-650 # 801720 <error_string+0x870>
    counter++;
  8009b2:	00024497          	auipc	s1,0x24
  8009b6:	6fe48493          	addi	s1,s1,1790 # 8250b0 <counter.3>
    cprintf("[深度%d] 当前进程PID=%d\n", depth, getpid());
  8009ba:	e86ff0ef          	jal	ra,800040 <cprintf>
    counter++;
  8009be:	409c                	lw	a5,0(s1)
  8009c0:	2785                	addiw	a5,a5,1
  8009c2:	c09c                	sw	a5,0(s1)
    int pid = fork();
  8009c4:	f22ff0ef          	jal	ra,8000e6 <fork>
    if (pid == 0) {
  8009c8:	c10d                	beqz	a0,8009ea <test_recursive_fork.part.0+0x52>
        waitpid(pid, &exit_code);
  8009ca:	006c                	addi	a1,sp,12
  8009cc:	f1cff0ef          	jal	ra,8000e8 <waitpid>
        cprintf("[深度%d父进程] counter=%d\n", depth, counter);
  8009d0:	4090                	lw	a2,0(s1)
  8009d2:	85a2                	mv	a1,s0
  8009d4:	00001517          	auipc	a0,0x1
  8009d8:	d8c50513          	addi	a0,a0,-628 # 801760 <error_string+0x8b0>
  8009dc:	e64ff0ef          	jal	ra,800040 <cprintf>
}
  8009e0:	70a2                	ld	ra,40(sp)
  8009e2:	7402                	ld	s0,32(sp)
  8009e4:	64e2                	ld	s1,24(sp)
  8009e6:	6145                	addi	sp,sp,48
  8009e8:	8082                	ret
        counter += 100;
  8009ea:	409c                	lw	a5,0(s1)
        cprintf("[深度%d子进程] counter=%d\n", depth, counter);
  8009ec:	85a2                	mv	a1,s0
  8009ee:	00001517          	auipc	a0,0x1
  8009f2:	d5250513          	addi	a0,a0,-686 # 801740 <error_string+0x890>
        counter += 100;
  8009f6:	0647861b          	addiw	a2,a5,100
  8009fa:	c090                	sw	a2,0(s1)
        cprintf("[深度%d子进程] counter=%d\n", depth, counter);
  8009fc:	e44ff0ef          	jal	ra,800040 <cprintf>
        test_recursive_fork(depth - 1);
  800a00:	fff4051b          	addiw	a0,s0,-1
  800a04:	f8dff0ef          	jal	ra,800990 <test_recursive_fork>
        exit(0);
  800a08:	4501                	li	a0,0
  800a0a:	ec6ff0ef          	jal	ra,8000d0 <exit>

0000000000800a0e <test_recursive_fork_wrapper>:

void test_recursive_fork_wrapper(void) {
  800a0e:	1141                	addi	sp,sp,-16
    cprintf("\n========== 测试6：递归fork ==========\n");
  800a10:	00001517          	auipc	a0,0x1
  800a14:	d7050513          	addi	a0,a0,-656 # 801780 <error_string+0x8d0>
void test_recursive_fork_wrapper(void) {
  800a18:	e406                	sd	ra,8(sp)
    cprintf("\n========== 测试6：递归fork ==========\n");
  800a1a:	e26ff0ef          	jal	ra,800040 <cprintf>
    if (depth <= 0) return;
  800a1e:	450d                	li	a0,3
  800a20:	f79ff0ef          	jal	ra,800998 <test_recursive_fork.part.0>
    test_recursive_fork(3);
    cprintf("✓ 测试6完成\n");
}
  800a24:	60a2                	ld	ra,8(sp)
    cprintf("✓ 测试6完成\n");
  800a26:	00001517          	auipc	a0,0x1
  800a2a:	d8a50513          	addi	a0,a0,-630 # 8017b0 <error_string+0x900>
}
  800a2e:	0141                	addi	sp,sp,16
    cprintf("✓ 测试6完成\n");
  800a30:	e10ff06f          	j	800040 <cprintf>

0000000000800a34 <test_memory_saving>:

/* 测试7：验证页面共享节省内存 
 * 注意：这个测试需要内核支持查询页面引用计数的系统调用
 */
void test_memory_saving(void) {
  800a34:	7179                	addi	sp,sp,-48
    cprintf("\n========== 测试7：内存节省验证 ==========\n");
  800a36:	00001517          	auipc	a0,0x1
  800a3a:	d9250513          	addi	a0,a0,-622 # 8017c8 <error_string+0x918>
void test_memory_saving(void) {
  800a3e:	f022                	sd	s0,32(sp)
  800a40:	f406                	sd	ra,40(sp)
  800a42:	00002417          	auipc	s0,0x2
  800a46:	66e40413          	addi	s0,s0,1646 # 8030b0 <big_data.2>
    cprintf("\n========== 测试7：内存节省验证 ==========\n");
  800a4a:	df6ff0ef          	jal	ra,800040 <cprintf>
  800a4e:	8722                	mv	a4,s0
    
    // 分配大块数据
    static char big_data[PGSIZE * 10];
    for (int i = 0; i < PGSIZE * 10; i++) {
  800a50:	4781                	li	a5,0
  800a52:	66a9                	lui	a3,0xa
        big_data[i] = i % 256;
  800a54:	00f70023          	sb	a5,0(a4)
    for (int i = 0; i < PGSIZE * 10; i++) {
  800a58:	2785                	addiw	a5,a5,1
  800a5a:	0705                	addi	a4,a4,1
  800a5c:	fed79ce3          	bne	a5,a3,800a54 <test_memory_saving+0x20>
    }
    
    cprintf("分配了%d字节数据\n", PGSIZE * 10);
  800a60:	65a9                	lui	a1,0xa
  800a62:	00001517          	auipc	a0,0x1
  800a66:	d9e50513          	addi	a0,a0,-610 # 801800 <error_string+0x950>
  800a6a:	dd6ff0ef          	jal	ra,800040 <cprintf>
    
    int pid = fork();
  800a6e:	e78ff0ef          	jal	ra,8000e6 <fork>
    if (pid == 0) {
  800a72:	cd19                	beqz	a0,800a90 <test_memory_saving+0x5c>
        cprintf("[子进程] 数据校验和=%d\n", sum);
        
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
  800a74:	086c                	addi	a1,sp,28
  800a76:	e72ff0ef          	jal	ra,8000e8 <waitpid>
        cprintf("✓ 测试7完成：理论上节省了%d字节内存\n", PGSIZE * 10);
  800a7a:	65a9                	lui	a1,0xa
  800a7c:	00001517          	auipc	a0,0x1
  800a80:	dec50513          	addi	a0,a0,-532 # 801868 <error_string+0x9b8>
  800a84:	dbcff0ef          	jal	ra,800040 <cprintf>
    }
}
  800a88:	70a2                	ld	ra,40(sp)
  800a8a:	7402                	ld	s0,32(sp)
  800a8c:	6145                	addi	sp,sp,48
  800a8e:	8082                	ret
  800a90:	e42a                	sd	a0,8(sp)
        cprintf("[子进程] 共享数据，不修改\n");
  800a92:	00001517          	auipc	a0,0x1
  800a96:	d8e50513          	addi	a0,a0,-626 # 801820 <error_string+0x970>
  800a9a:	da6ff0ef          	jal	ra,800040 <cprintf>
        for (int i = 0; i < 100; i++) {
  800a9e:	65a2                	ld	a1,8(sp)
  800aa0:	00002797          	auipc	a5,0x2
  800aa4:	67478793          	addi	a5,a5,1652 # 803114 <big_data.2+0x64>
            sum += big_data[i];
  800aa8:	00044703          	lbu	a4,0(s0)
        for (int i = 0; i < 100; i++) {
  800aac:	0405                	addi	s0,s0,1
            sum += big_data[i];
  800aae:	9db9                	addw	a1,a1,a4
        for (int i = 0; i < 100; i++) {
  800ab0:	fe879ce3          	bne	a5,s0,800aa8 <test_memory_saving+0x74>
        cprintf("[子进程] 数据校验和=%d\n", sum);
  800ab4:	00001517          	auipc	a0,0x1
  800ab8:	d9450513          	addi	a0,a0,-620 # 801848 <error_string+0x998>
  800abc:	d84ff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  800ac0:	4501                	li	a0,0
  800ac2:	e0eff0ef          	jal	ra,8000d0 <exit>

0000000000800ac6 <test_fork_exec>:

/* 测试8：边界条件 - fork后立即exec */
void test_fork_exec(void) {
  800ac6:	1101                	addi	sp,sp,-32
    cprintf("\n========== 测试8：Fork后Exec ==========\n");
  800ac8:	00001517          	auipc	a0,0x1
  800acc:	dd850513          	addi	a0,a0,-552 # 8018a0 <error_string+0x9f0>
void test_fork_exec(void) {
  800ad0:	ec06                	sd	ra,24(sp)
    cprintf("\n========== 测试8：Fork后Exec ==========\n");
  800ad2:	d6eff0ef          	jal	ra,800040 <cprintf>
    
    static char data[] = "Data before exec";
    
    int pid = fork();
  800ad6:	e10ff0ef          	jal	ra,8000e6 <fork>
    if (pid == 0) {
  800ada:	cd09                	beqz	a0,800af4 <test_fork_exec+0x2e>
        cprintf("[子进程] 模拟exec：COW页面未被使用即被释放\n");
        
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
  800adc:	006c                	addi	a1,sp,12
  800ade:	e0aff0ef          	jal	ra,8000e8 <waitpid>
        cprintf("✓ 测试8完成：Fork-exec场景\n");
  800ae2:	00001517          	auipc	a0,0x1
  800ae6:	e7e50513          	addi	a0,a0,-386 # 801960 <error_string+0xab0>
  800aea:	d56ff0ef          	jal	ra,800040 <cprintf>
    }
}
  800aee:	60e2                	ld	ra,24(sp)
  800af0:	6105                	addi	sp,sp,32
  800af2:	8082                	ret
        cprintf("[子进程] Fork后立即执行其他程序\n");
  800af4:	00001517          	auipc	a0,0x1
  800af8:	ddc50513          	addi	a0,a0,-548 # 8018d0 <error_string+0xa20>
  800afc:	d44ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[子进程] 原数据: %s\n", data);
  800b00:	00001597          	auipc	a1,0x1
  800b04:	56858593          	addi	a1,a1,1384 # 802068 <data.1>
  800b08:	00001517          	auipc	a0,0x1
  800b0c:	df850513          	addi	a0,a0,-520 # 801900 <error_string+0xa50>
  800b10:	d30ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[子进程] 模拟exec：COW页面未被使用即被释放\n");
  800b14:	00001517          	auipc	a0,0x1
  800b18:	e0c50513          	addi	a0,a0,-500 # 801920 <error_string+0xa70>
  800b1c:	d24ff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  800b20:	4501                	li	a0,0
  800b22:	daeff0ef          	jal	ra,8000d0 <exit>

0000000000800b26 <performance_test>:

/* 性能测试：对比COW和传统复制 */
void performance_test(void) {
  800b26:	7179                	addi	sp,sp,-48
    cprintf("\n========== 性能测试 ==========\n");
  800b28:	00001517          	auipc	a0,0x1
  800b2c:	e6050513          	addi	a0,a0,-416 # 801988 <error_string+0xad8>
void performance_test(void) {
  800b30:	f406                	sd	ra,40(sp)
  800b32:	f022                	sd	s0,32(sp)
  800b34:	ec26                	sd	s1,24(sp)
    cprintf("\n========== 性能测试 ==========\n");
  800b36:	d0aff0ef          	jal	ra,800040 <cprintf>
    cprintf("注意：此测试需要修改内核支持传统复制方式\n");
  800b3a:	00001517          	auipc	a0,0x1
  800b3e:	e7650513          	addi	a0,a0,-394 # 8019b0 <error_string+0xb00>
  800b42:	cfeff0ef          	jal	ra,800040 <cprintf>
    
    // 准备大量数据
    static char perf_data[PGSIZE * 20];
    for (int i = 0; i < PGSIZE * 20; i++) {
  800b46:	00010497          	auipc	s1,0x10
  800b4a:	56a48493          	addi	s1,s1,1386 # 8110b0 <perf_data.0>
  800b4e:	4401                	li	s0,0
    cprintf("注意：此测试需要修改内核支持传统复制方式\n");
  800b50:	87a6                	mv	a5,s1
    for (int i = 0; i < PGSIZE * 20; i++) {
  800b52:	6751                	lui	a4,0x14
        perf_data[i] = i % 256;
  800b54:	00878023          	sb	s0,0(a5)
    for (int i = 0; i < PGSIZE * 20; i++) {
  800b58:	2405                	addiw	s0,s0,1
  800b5a:	0785                	addi	a5,a5,1
  800b5c:	fee41ce3          	bne	s0,a4,800b54 <performance_test+0x2e>
    }
    
    cprintf("测试数据大小：%d字节 (%d页)\n", 
  800b60:	4651                	li	a2,20
  800b62:	65d1                	lui	a1,0x14
  800b64:	00001517          	auipc	a0,0x1
  800b68:	e8c50513          	addi	a0,a0,-372 # 8019f0 <error_string+0xb40>
  800b6c:	cd4ff0ef          	jal	ra,800040 <cprintf>
            PGSIZE * 20, 20);
    
    // COW方式
    cprintf("\n--- COW方式 ---\n");
  800b70:	00001517          	auipc	a0,0x1
  800b74:	ea850513          	addi	a0,a0,-344 # 801a18 <error_string+0xb68>
  800b78:	cc8ff0ef          	jal	ra,800040 <cprintf>
    unsigned int start_time = 0;  // 需要系统调用获取时间
    
    int pid1 = fork();
  800b7c:	d6aff0ef          	jal	ra,8000e6 <fork>
    if (pid1 == 0) {
  800b80:	c505                	beqz	a0,800ba8 <performance_test+0x82>
        for (int i = 0; i < PGSIZE * 20; i += 1024) {
            sum += perf_data[i];
        }
        exit(0);
    }
    waitpid(pid1, NULL);
  800b82:	4581                	li	a1,0
  800b84:	d64ff0ef          	jal	ra,8000e8 <waitpid>
    
    cprintf("COW fork+读取 完成\n");
  800b88:	00001517          	auipc	a0,0x1
  800b8c:	ea850513          	addi	a0,a0,-344 # 801a30 <error_string+0xb80>
  800b90:	cb0ff0ef          	jal	ra,800040 <cprintf>
    
    // 如果有传统复制方式，在这里测试
    cprintf("\n性能对比需要内核支持\n");
}
  800b94:	7402                	ld	s0,32(sp)
  800b96:	70a2                	ld	ra,40(sp)
  800b98:	64e2                	ld	s1,24(sp)
    cprintf("\n性能对比需要内核支持\n");
  800b9a:	00001517          	auipc	a0,0x1
  800b9e:	eae50513          	addi	a0,a0,-338 # 801a48 <error_string+0xb98>
}
  800ba2:	6145                	addi	sp,sp,48
    cprintf("\n性能对比需要内核支持\n");
  800ba4:	c9cff06f          	j	800040 <cprintf>
        volatile int sum = 0;
  800ba8:	c602                	sw	zero,12(sp)
        for (int i = 0; i < PGSIZE * 20; i += 1024) {
  800baa:	9426                	add	s0,s0,s1
            sum += perf_data[i];
  800bac:	47b2                	lw	a5,12(sp)
  800bae:	0004c703          	lbu	a4,0(s1)
        for (int i = 0; i < PGSIZE * 20; i += 1024) {
  800bb2:	40048493          	addi	s1,s1,1024
            sum += perf_data[i];
  800bb6:	9fb9                	addw	a5,a5,a4
  800bb8:	c63e                	sw	a5,12(sp)
        for (int i = 0; i < PGSIZE * 20; i += 1024) {
  800bba:	fe9419e3          	bne	s0,s1,800bac <performance_test+0x86>
        exit(0);
  800bbe:	4501                	li	a0,0
  800bc0:	d10ff0ef          	jal	ra,8000d0 <exit>

0000000000800bc4 <main>:

int main(void) {
  800bc4:	1141                	addi	sp,sp,-16
    cprintf("╔════════════════════════════════════════╗\n");
  800bc6:	00001517          	auipc	a0,0x1
  800bca:	eaa50513          	addi	a0,a0,-342 # 801a70 <error_string+0xbc0>
int main(void) {
  800bce:	e406                	sd	ra,8(sp)
    cprintf("╔════════════════════════════════════════╗\n");
  800bd0:	c70ff0ef          	jal	ra,800040 <cprintf>
    cprintf("║   Copy-on-Write 机制综合测试程序      ║\n");
  800bd4:	00001517          	auipc	a0,0x1
  800bd8:	f1c50513          	addi	a0,a0,-228 # 801af0 <error_string+0xc40>
  800bdc:	c64ff0ef          	jal	ra,800040 <cprintf>
    cprintf("╚════════════════════════════════════════╝\n");
  800be0:	00001517          	auipc	a0,0x1
  800be4:	f4850513          	addi	a0,a0,-184 # 801b28 <error_string+0xc78>
  800be8:	c58ff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("\n开始COW测试...\n");
  800bec:	00001517          	auipc	a0,0x1
  800bf0:	fbc50513          	addi	a0,a0,-68 # 801ba8 <error_string+0xcf8>
  800bf4:	c4cff0ef          	jal	ra,800040 <cprintf>
    
    // 运行所有测试
    test_basic_cow();           // 测试1：基础共享
  800bf8:	93dff0ef          	jal	ra,800534 <test_basic_cow>
    test_cow_write();           // 测试2：写时复制
  800bfc:	9c1ff0ef          	jal	ra,8005bc <test_cow_write>
    test_multiple_writes();     // 测试3：多次写入
  800c00:	a61ff0ef          	jal	ra,800660 <test_multiple_writes>
    test_multiple_children();   // 测试4：多子进程
  800c04:	b41ff0ef          	jal	ra,800744 <test_multiple_children>
    test_heavy_write();         // 测试5：大量写入
  800c08:	c9bff0ef          	jal	ra,8008a2 <test_heavy_write>
    test_recursive_fork_wrapper(); // 测试6：递归fork
  800c0c:	e03ff0ef          	jal	ra,800a0e <test_recursive_fork_wrapper>
    test_memory_saving();       // 测试7：内存节省
  800c10:	e25ff0ef          	jal	ra,800a34 <test_memory_saving>
    test_fork_exec();           // 测试8：fork-exec
  800c14:	eb3ff0ef          	jal	ra,800ac6 <test_fork_exec>
    performance_test();         // 性能测试
  800c18:	f0fff0ef          	jal	ra,800b26 <performance_test>
    
    cprintf("\n╔════════════════════════════════════════╗\n");
  800c1c:	00001517          	auipc	a0,0x1
  800c20:	fa450513          	addi	a0,a0,-92 # 801bc0 <error_string+0xd10>
  800c24:	c1cff0ef          	jal	ra,800040 <cprintf>
    cprintf("║          所有测试完成！                ║\n");
  800c28:	00001517          	auipc	a0,0x1
  800c2c:	02050513          	addi	a0,a0,32 # 801c48 <error_string+0xd98>
  800c30:	c10ff0ef          	jal	ra,800040 <cprintf>
    cprintf("╚════════════════════════════════════════╝\n");
  800c34:	00001517          	auipc	a0,0x1
  800c38:	ef450513          	addi	a0,a0,-268 # 801b28 <error_string+0xc78>
  800c3c:	c04ff0ef          	jal	ra,800040 <cprintf>
    
    return 0;
}
  800c40:	60a2                	ld	ra,8(sp)
  800c42:	4501                	li	a0,0
  800c44:	0141                	addi	sp,sp,16
  800c46:	8082                	ret
