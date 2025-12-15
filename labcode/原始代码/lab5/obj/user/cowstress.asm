
obj/__user_cowstress.out:     file format elf64-littleriscv


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
  80002e:	098000ef          	jal	ra,8000c6 <sys_putc>
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

00000000008000c2 <sys_getpid>:
    return syscall(SYS_kill, pid);
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  8000c2:	4549                	li	a0,18
  8000c4:	bf4d                	j	800076 <syscall>

00000000008000c6 <sys_putc>:
}

int
sys_putc(int64_t c) {
  8000c6:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  8000c8:	4579                	li	a0,30
  8000ca:	b775                	j	800076 <syscall>

00000000008000cc <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  8000cc:	1141                	addi	sp,sp,-16
  8000ce:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  8000d0:	fe1ff0ef          	jal	ra,8000b0 <sys_exit>
    cprintf("BUG: exit failed.\n");
  8000d4:	00001517          	auipc	a0,0x1
  8000d8:	c8c50513          	addi	a0,a0,-884 # 800d60 <main+0x9e>
  8000dc:	f65ff0ef          	jal	ra,800040 <cprintf>
    while (1);
  8000e0:	a001                	j	8000e0 <exit+0x14>

00000000008000e2 <fork>:
}

int
fork(void) {
    return sys_fork();
  8000e2:	bfd1                	j	8000b6 <sys_fork>

00000000008000e4 <wait>:
}

int
wait(void) {
    return sys_wait(0, NULL);
  8000e4:	4581                	li	a1,0
  8000e6:	4501                	li	a0,0
  8000e8:	bfc9                	j	8000ba <sys_wait>

00000000008000ea <waitpid>:
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
  8000ea:	bfc1                	j	8000ba <sys_wait>

00000000008000ec <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  8000ec:	bfd9                	j	8000c2 <sys_getpid>

00000000008000ee <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000ee:	1141                	addi	sp,sp,-16
  8000f0:	e406                	sd	ra,8(sp)
    int ret = main();
  8000f2:	3d1000ef          	jal	ra,800cc2 <main>
    exit(ret);
  8000f6:	fd7ff0ef          	jal	ra,8000cc <exit>

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
  800138:	c4478793          	addi	a5,a5,-956 # 800d78 <main+0xb6>
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
  800194:	c1ca8a93          	addi	s5,s5,-996 # 800dac <main+0xea>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800198:	00001b97          	auipc	s7,0x1
  80019c:	e30b8b93          	addi	s7,s7,-464 # 800fc8 <error_string>
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
  8003f2:	9ba60613          	addi	a2,a2,-1606 # 800da8 <main+0xe6>
  8003f6:	85a6                	mv	a1,s1
  8003f8:	854a                	mv	a0,s2
  8003fa:	0ce000ef          	jal	ra,8004c8 <printfmt>
  8003fe:	b34d                	j	8001a0 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  800400:	00001617          	auipc	a2,0x1
  800404:	99860613          	addi	a2,a2,-1640 # 800d98 <main+0xd6>
  800408:	85a6                	mv	a1,s1
  80040a:	854a                	mv	a0,s2
  80040c:	0bc000ef          	jal	ra,8004c8 <printfmt>
  800410:	bb41                	j	8001a0 <vprintfmt+0x3a>
                p = "(null)";
  800412:	00001417          	auipc	s0,0x1
  800416:	97e40413          	addi	s0,s0,-1666 # 800d90 <main+0xce>
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
  80049c:	00001417          	auipc	s0,0x1
  8004a0:	8f440413          	addi	s0,s0,-1804 # 800d90 <main+0xce>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004a4:	02800793          	li	a5,40
  8004a8:	02800513          	li	a0,40
  8004ac:	00140a13          	addi	s4,s0,1
  8004b0:	bd6d                	j	80036a <vprintfmt+0x204>
  8004b2:	00001a17          	auipc	s4,0x1
  8004b6:	8dfa0a13          	addi	s4,s4,-1825 # 800d91 <main+0xcf>
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

0000000000800504 <stress_test_fork_tree.part.0>:
        cprintf("✗ 压力测试1失败：父进程数据被修改\n");
    }
}

/* 压力测试2：fork树 */
void stress_test_fork_tree(int depth, int breadth) {
  800504:	1101                	addi	sp,sp,-32
  800506:	e426                	sd	s1,8(sp)
  800508:	e04a                	sd	s2,0(sp)
  80050a:	84ae                	mv	s1,a1
  80050c:	ec06                	sd	ra,24(sp)
  80050e:	e822                	sd	s0,16(sp)
  800510:	892a                	mv	s2,a0
    if (depth <= 0) return;
    
    cprintf("[深度%d] PID=%d, 创建%d个子进程\n", 
  800512:	bdbff0ef          	jal	ra,8000ec <getpid>
  800516:	862a                	mv	a2,a0
  800518:	86a6                	mv	a3,s1
  80051a:	85ca                	mv	a1,s2
  80051c:	00001517          	auipc	a0,0x1
  800520:	b7450513          	addi	a0,a0,-1164 # 801090 <error_string+0xc8>
  800524:	b1dff0ef          	jal	ra,800040 <cprintf>
    
    static char tree_data[PGSIZE * 2];
    tree_data[0] = 'T';
    tree_data[PGSIZE] = 'T';
    
    for (int i = 0; i < breadth; i++) {
  800528:	02905363          	blez	s1,80054e <stress_test_fork_tree.part.0+0x4a>
  80052c:	4401                	li	s0,0
  80052e:	a011                	j	800532 <stress_test_fork_tree.part.0+0x2e>
  800530:	843e                	mv	s0,a5
        int pid = fork();
  800532:	bb1ff0ef          	jal	ra,8000e2 <fork>
        
        if (pid == 0) {
  800536:	c115                	beqz	a0,80055a <stress_test_fork_tree.part.0+0x56>
    for (int i = 0; i < breadth; i++) {
  800538:	0014079b          	addiw	a5,s0,1
  80053c:	fef49ae3          	bne	s1,a5,800530 <stress_test_fork_tree.part.0+0x2c>
  800540:	4481                	li	s1,0
        }
    }
    
    // 等待所有子进程
    for (int i = 0; i < breadth; i++) {
        wait();
  800542:	ba3ff0ef          	jal	ra,8000e4 <wait>
    for (int i = 0; i < breadth; i++) {
  800546:	87a6                	mv	a5,s1
  800548:	2485                	addiw	s1,s1,1
  80054a:	fe879ce3          	bne	a5,s0,800542 <stress_test_fork_tree.part.0+0x3e>
    }
}
  80054e:	60e2                	ld	ra,24(sp)
  800550:	6442                	ld	s0,16(sp)
  800552:	64a2                	ld	s1,8(sp)
  800554:	6902                	ld	s2,0(sp)
  800556:	6105                	addi	sp,sp,32
  800558:	8082                	ret
            cprintf("[深度%d-子%d] PID=%d, 修改数据\n", 
  80055a:	b93ff0ef          	jal	ra,8000ec <getpid>
  80055e:	86aa                	mv	a3,a0
  800560:	8622                	mv	a2,s0
  800562:	85ca                	mv	a1,s2
  800564:	00001517          	auipc	a0,0x1
  800568:	b5c50513          	addi	a0,a0,-1188 # 8010c0 <error_string+0xf8>
  80056c:	ad5ff0ef          	jal	ra,800040 <cprintf>
            stress_test_fork_tree(depth - 1, breadth);
  800570:	fff9051b          	addiw	a0,s2,-1
    if (depth <= 0) return;
  800574:	c501                	beqz	a0,80057c <stress_test_fork_tree.part.0+0x78>
  800576:	85a6                	mv	a1,s1
  800578:	f8dff0ef          	jal	ra,800504 <stress_test_fork_tree.part.0>
            exit(0);
  80057c:	4501                	li	a0,0
  80057e:	b4fff0ef          	jal	ra,8000cc <exit>

0000000000800582 <stress_test_many_forks>:
void stress_test_many_forks(void) {
  800582:	7159                	addi	sp,sp,-112
    cprintf("\n========== 压力测试1：大量Fork ==========\n");
  800584:	00001517          	auipc	a0,0x1
  800588:	b6450513          	addi	a0,a0,-1180 # 8010e8 <error_string+0x120>
void stress_test_many_forks(void) {
  80058c:	f486                	sd	ra,104(sp)
  80058e:	f0a2                	sd	s0,96(sp)
  800590:	eca6                	sd	s1,88(sp)
  800592:	f85a                	sd	s6,48(sp)
  800594:	e8ca                	sd	s2,80(sp)
  800596:	e4ce                	sd	s3,72(sp)
  800598:	e0d2                	sd	s4,64(sp)
  80059a:	fc56                	sd	s5,56(sp)
    cprintf("\n========== 压力测试1：大量Fork ==========\n");
  80059c:	aa5ff0ef          	jal	ra,800040 <cprintf>
    cprintf("创建%d个子进程...\n", MAX_CHILDREN);
  8005a0:	45a9                	li	a1,10
  8005a2:	00001517          	auipc	a0,0x1
  8005a6:	b7e50513          	addi	a0,a0,-1154 # 801120 <error_string+0x158>
  8005aa:	0001c497          	auipc	s1,0x1c
  8005ae:	e5648493          	addi	s1,s1,-426 # 81c400 <shared_buffer>
  8005b2:	a8fff0ef          	jal	ra,800040 <cprintf>
    for (int i = 0; i < PGSIZE * LARGE_BUFFER_PAGES; i++) {
  8005b6:	0004e417          	auipc	s0,0x4e
  8005ba:	e4a40413          	addi	s0,s0,-438 # 84e400 <shared_buffer+0x32000>
    cprintf("创建%d个子进程...\n", MAX_CHILDREN);
  8005be:	8b26                	mv	s6,s1
  8005c0:	87a6                	mv	a5,s1
        shared_buffer[i] = 'S';
  8005c2:	05300713          	li	a4,83
  8005c6:	00e78023          	sb	a4,0(a5)
    for (int i = 0; i < PGSIZE * LARGE_BUFFER_PAGES; i++) {
  8005ca:	0785                	addi	a5,a5,1
  8005cc:	fe879de3          	bne	a5,s0,8005c6 <stress_test_many_forks+0x44>
  8005d0:	00810993          	addi	s3,sp,8
  8005d4:	8a4e                	mv	s4,s3
    int created = 0;
  8005d6:	4901                	li	s2,0
    for (int i = 0; i < MAX_CHILDREN; i++) {
  8005d8:	4aa9                	li	s5,10
        int pid = fork();
  8005da:	b09ff0ef          	jal	ra,8000e2 <fork>
        if (pid < 0) {
  8005de:	08054e63          	bltz	a0,80067a <stress_test_many_forks+0xf8>
        if (pid == 0) {
  8005e2:	0e050263          	beqz	a0,8006c6 <stress_test_many_forks+0x144>
            pids[created++] = pid;
  8005e6:	00aa2023          	sw	a0,0(s4)
  8005ea:	2905                	addiw	s2,s2,1
    for (int i = 0; i < MAX_CHILDREN; i++) {
  8005ec:	0a11                	addi	s4,s4,4
  8005ee:	ff5916e3          	bne	s2,s5,8005da <stress_test_many_forks+0x58>
    cprintf("\n[父进程] 成功创建%d个子进程\n", created);
  8005f2:	45a9                	li	a1,10
  8005f4:	00001517          	auipc	a0,0x1
  8005f8:	b7450513          	addi	a0,a0,-1164 # 801168 <error_string+0x1a0>
  8005fc:	a45ff0ef          	jal	ra,800040 <cprintf>
    cprintf("[父进程] 等待所有子进程退出...\n");
  800600:	00001517          	auipc	a0,0x1
  800604:	b9850513          	addi	a0,a0,-1128 # 801198 <error_string+0x1d0>
  800608:	a39ff0ef          	jal	ra,800040 <cprintf>
    int created = 0;
  80060c:	4401                	li	s0,0
        cprintf("子进程%d (PID=%d) 退出，exit_code=%d\n", 
  80060e:	00001a97          	auipc	s5,0x1
  800612:	c6aa8a93          	addi	s5,s5,-918 # 801278 <error_string+0x2b0>
        waitpid(pids[i], &exit_code);
  800616:	0009aa03          	lw	s4,0(s3)
  80061a:	004c                	addi	a1,sp,4
    for (int i = 0; i < created; i++) {
  80061c:	0991                	addi	s3,s3,4
        waitpid(pids[i], &exit_code);
  80061e:	8552                	mv	a0,s4
  800620:	acbff0ef          	jal	ra,8000ea <waitpid>
        cprintf("子进程%d (PID=%d) 退出，exit_code=%d\n", 
  800624:	4692                	lw	a3,4(sp)
  800626:	85a2                	mv	a1,s0
  800628:	8652                	mv	a2,s4
    for (int i = 0; i < created; i++) {
  80062a:	2405                	addiw	s0,s0,1
        cprintf("子进程%d (PID=%d) 退出，exit_code=%d\n", 
  80062c:	8556                	mv	a0,s5
  80062e:	a13ff0ef          	jal	ra,800040 <cprintf>
    for (int i = 0; i < created; i++) {
  800632:	ff2442e3          	blt	s0,s2,800616 <stress_test_many_forks+0x94>
    for (int i = 0; i < PGSIZE * LARGE_BUFFER_PAGES; i++) {
  800636:	4581                	li	a1,0
        if (shared_buffer[i] != 'S') {
  800638:	05300793          	li	a5,83
    for (int i = 0; i < PGSIZE * LARGE_BUFFER_PAGES; i++) {
  80063c:	00032737          	lui	a4,0x32
  800640:	a029                	j	80064a <stress_test_many_forks+0xc8>
  800642:	2585                	addiw	a1,a1,1
  800644:	0485                	addi	s1,s1,1
  800646:	06e58163          	beq	a1,a4,8006a8 <stress_test_many_forks+0x126>
        if (shared_buffer[i] != 'S') {
  80064a:	0004c603          	lbu	a2,0(s1)
  80064e:	fef60ae3          	beq	a2,a5,800642 <stress_test_many_forks+0xc0>
            cprintf("检测到位置%d被修改为'%c'\n", i, shared_buffer[i]);
  800652:	00001517          	auipc	a0,0x1
  800656:	c5650513          	addi	a0,a0,-938 # 8012a8 <error_string+0x2e0>
  80065a:	9e7ff0ef          	jal	ra,800040 <cprintf>
}
  80065e:	7406                	ld	s0,96(sp)
  800660:	70a6                	ld	ra,104(sp)
  800662:	64e6                	ld	s1,88(sp)
  800664:	6946                	ld	s2,80(sp)
  800666:	69a6                	ld	s3,72(sp)
  800668:	6a06                	ld	s4,64(sp)
  80066a:	7ae2                	ld	s5,56(sp)
  80066c:	7b42                	ld	s6,48(sp)
        cprintf("✗ 压力测试1失败：父进程数据被修改\n");
  80066e:	00001517          	auipc	a0,0x1
  800672:	c6250513          	addi	a0,a0,-926 # 8012d0 <error_string+0x308>
}
  800676:	6165                	addi	sp,sp,112
        cprintf("✗ 压力测试1失败：父进程数据被修改\n");
  800678:	b2e1                	j	800040 <cprintf>
            cprintf("Fork失败，已创建%d个子进程\n", i);
  80067a:	85ca                	mv	a1,s2
  80067c:	00001517          	auipc	a0,0x1
  800680:	ac450513          	addi	a0,a0,-1340 # 801140 <error_string+0x178>
  800684:	9bdff0ef          	jal	ra,800040 <cprintf>
    cprintf("\n[父进程] 成功创建%d个子进程\n", created);
  800688:	85ca                	mv	a1,s2
  80068a:	00001517          	auipc	a0,0x1
  80068e:	ade50513          	addi	a0,a0,-1314 # 801168 <error_string+0x1a0>
  800692:	9afff0ef          	jal	ra,800040 <cprintf>
    cprintf("[父进程] 等待所有子进程退出...\n");
  800696:	00001517          	auipc	a0,0x1
  80069a:	b0250513          	addi	a0,a0,-1278 # 801198 <error_string+0x1d0>
  80069e:	9a3ff0ef          	jal	ra,800040 <cprintf>
    for (int i = 0; i < created; i++) {
  8006a2:	f60915e3          	bnez	s2,80060c <stress_test_many_forks+0x8a>
  8006a6:	bf41                	j	800636 <stress_test_many_forks+0xb4>
}
  8006a8:	7406                	ld	s0,96(sp)
  8006aa:	70a6                	ld	ra,104(sp)
  8006ac:	64e6                	ld	s1,88(sp)
  8006ae:	69a6                	ld	s3,72(sp)
  8006b0:	6a06                	ld	s4,64(sp)
  8006b2:	7ae2                	ld	s5,56(sp)
  8006b4:	7b42                	ld	s6,48(sp)
        cprintf("✓ 压力测试1通过：%d个子进程COW正常\n", created);
  8006b6:	85ca                	mv	a1,s2
}
  8006b8:	6946                	ld	s2,80(sp)
        cprintf("✓ 压力测试1通过：%d个子进程COW正常\n", created);
  8006ba:	00001517          	auipc	a0,0x1
  8006be:	c4e50513          	addi	a0,a0,-946 # 801308 <error_string+0x340>
}
  8006c2:	6165                	addi	sp,sp,112
        cprintf("✓ 压力测试1通过：%d个子进程COW正常\n", created);
  8006c4:	bab5                	j	800040 <cprintf>
            cprintf("[子进程%d PID=%d] 开始读取共享数据...\n", 
  8006c6:	a27ff0ef          	jal	ra,8000ec <getpid>
  8006ca:	862a                	mv	a2,a0
  8006cc:	85ca                	mv	a1,s2
  8006ce:	00001517          	auipc	a0,0x1
  8006d2:	afa50513          	addi	a0,a0,-1286 # 8011c8 <error_string+0x200>
  8006d6:	96bff0ef          	jal	ra,800040 <cprintf>
            for (int j = 0; j < PGSIZE * LARGE_BUFFER_PAGES; j += PGSIZE) {
  8006da:	6705                	lui	a4,0x1
            volatile int checksum = 0;
  8006dc:	c202                	sw	zero,4(sp)
                checksum += shared_buffer[j];
  8006de:	4792                	lw	a5,4(sp)
  8006e0:	0004c683          	lbu	a3,0(s1)
            for (int j = 0; j < PGSIZE * LARGE_BUFFER_PAGES; j += PGSIZE) {
  8006e4:	94ba                	add	s1,s1,a4
                checksum += shared_buffer[j];
  8006e6:	9fb5                	addw	a5,a5,a3
  8006e8:	c23e                	sw	a5,4(sp)
            for (int j = 0; j < PGSIZE * LARGE_BUFFER_PAGES; j += PGSIZE) {
  8006ea:	fe849ae3          	bne	s1,s0,8006de <stress_test_many_forks+0x15c>
            cprintf("[子进程%d] 读取完成，校验和=%d\n", i, checksum);
  8006ee:	4612                	lw	a2,4(sp)
  8006f0:	85ca                	mv	a1,s2
  8006f2:	00001517          	auipc	a0,0x1
  8006f6:	b0e50513          	addi	a0,a0,-1266 # 801200 <error_string+0x238>
  8006fa:	2601                	sext.w	a2,a2
  8006fc:	945ff0ef          	jal	ra,800040 <cprintf>
            if (i % 2 == 0) {
  800700:	00197793          	andi	a5,s2,1
  800704:	c781                	beqz	a5,80070c <stress_test_many_forks+0x18a>
            exit(i);
  800706:	854a                	mv	a0,s2
  800708:	9c5ff0ef          	jal	ra,8000cc <exit>
                cprintf("[子进程%d] 触发COW写入...\n", i);
  80070c:	85ca                	mv	a1,s2
  80070e:	00001517          	auipc	a0,0x1
  800712:	b2250513          	addi	a0,a0,-1246 # 801230 <error_string+0x268>
  800716:	92bff0ef          	jal	ra,800040 <cprintf>
                for (int j = i * 1000; j < (i + 1) * 1000; j++) {
  80071a:	3e800793          	li	a5,1000
  80071e:	0327873b          	mulw	a4,a5,s2
                    shared_buffer[j] = 'C';
  800722:	04300693          	li	a3,67
                for (int j = i * 1000; j < (i + 1) * 1000; j++) {
  800726:	3e87079b          	addiw	a5,a4,1000
  80072a:	9b3a                	add	s6,s6,a4
                    shared_buffer[j] = 'C';
  80072c:	00db0023          	sb	a3,0(s6)
                for (int j = i * 1000; j < (i + 1) * 1000; j++) {
  800730:	2705                	addiw	a4,a4,1
  800732:	0b05                	addi	s6,s6,1
  800734:	fef74ce3          	blt	a4,a5,80072c <stress_test_many_forks+0x1aa>
                cprintf("[子进程%d] COW写入完成\n", i);
  800738:	85ca                	mv	a1,s2
  80073a:	00001517          	auipc	a0,0x1
  80073e:	b1e50513          	addi	a0,a0,-1250 # 801258 <error_string+0x290>
  800742:	8ffff0ef          	jal	ra,800040 <cprintf>
  800746:	b7c1                	j	800706 <stress_test_many_forks+0x184>

0000000000800748 <stress_test_fork_tree_wrapper>:

void stress_test_fork_tree_wrapper(void) {
  800748:	1141                	addi	sp,sp,-16
    cprintf("\n========== 压力测试2：Fork树 ==========\n");
  80074a:	00001517          	auipc	a0,0x1
  80074e:	bf650513          	addi	a0,a0,-1034 # 801340 <error_string+0x378>
void stress_test_fork_tree_wrapper(void) {
  800752:	e406                	sd	ra,8(sp)
    cprintf("\n========== 压力测试2：Fork树 ==========\n");
  800754:	8edff0ef          	jal	ra,800040 <cprintf>
    cprintf("深度=3, 广度=2\n");
  800758:	00001517          	auipc	a0,0x1
  80075c:	c1850513          	addi	a0,a0,-1000 # 801370 <error_string+0x3a8>
  800760:	8e1ff0ef          	jal	ra,800040 <cprintf>
    if (depth <= 0) return;
  800764:	450d                	li	a0,3
  800766:	4589                	li	a1,2
  800768:	d9dff0ef          	jal	ra,800504 <stress_test_fork_tree.part.0>
    
    stress_test_fork_tree(3, 2);
    
    cprintf("✓ 压力测试2完成\n");
}
  80076c:	60a2                	ld	ra,8(sp)
    cprintf("✓ 压力测试2完成\n");
  80076e:	00001517          	auipc	a0,0x1
  800772:	c1a50513          	addi	a0,a0,-998 # 801388 <error_string+0x3c0>
}
  800776:	0141                	addi	sp,sp,16
    cprintf("✓ 压力测试2完成\n");
  800778:	8c9ff06f          	j	800040 <cprintf>

000000000080077c <stress_test_concurrent_write>:

/* 压力测试3：并发写入同一区域 */
void stress_test_concurrent_write(void) {
  80077c:	711d                	addi	sp,sp,-96
    cprintf("\n========== 压力测试3：并发写入 ==========\n");
  80077e:	00001517          	auipc	a0,0x1
  800782:	c2a50513          	addi	a0,a0,-982 # 8013a8 <error_string+0x3e0>
void stress_test_concurrent_write(void) {
  800786:	e8a2                	sd	s0,80(sp)
  800788:	ec86                	sd	ra,88(sp)
  80078a:	e4a6                	sd	s1,72(sp)
  80078c:	e0ca                	sd	s2,64(sp)
  80078e:	fc4e                	sd	s3,56(sp)
  800790:	f852                	sd	s4,48(sp)
  800792:	f456                	sd	s5,40(sp)
  800794:	00002417          	auipc	s0,0x2
  800798:	86c40413          	addi	s0,s0,-1940 # 802000 <concurrent_data.4>
    cprintf("\n========== 压力测试3：并发写入 ==========\n");
  80079c:	8a5ff0ef          	jal	ra,800040 <cprintf>
  8007a0:	8722                	mv	a4,s0
    
    // 准备共享数据
    static int concurrent_data[1024];
    for (int i = 0; i < 1024; i++) {
  8007a2:	4781                	li	a5,0
  8007a4:	40000693          	li	a3,1024
        concurrent_data[i] = i;
  8007a8:	c31c                	sw	a5,0(a4)
    for (int i = 0; i < 1024; i++) {
  8007aa:	2785                	addiw	a5,a5,1
  8007ac:	0711                	addi	a4,a4,4
  8007ae:	fed79de3          	bne	a5,a3,8007a8 <stress_test_concurrent_write+0x2c>
    }
    
    cprintf("创建5个子进程同时写入...\n");
  8007b2:	00001517          	auipc	a0,0x1
  8007b6:	c2e50513          	addi	a0,a0,-978 # 8013e0 <error_string+0x418>
  8007ba:	00810993          	addi	s3,sp,8
  8007be:	883ff0ef          	jal	ra,800040 <cprintf>
  8007c2:	8a4e                	mv	s4,s3
    
    int pids[5];
    
    for (int i = 0; i < 5; i++) {
  8007c4:	4901                	li	s2,0
  8007c6:	4a95                	li	s5,5
        int pid = fork();
  8007c8:	91bff0ef          	jal	ra,8000e2 <fork>
  8007cc:	84aa                	mv	s1,a0
        
        if (pid == 0) {
  8007ce:	c94d                	beqz	a0,800880 <stress_test_concurrent_write+0x104>
                cprintf("[子进程%d] 数据验证失败：%d个错误\n", i, errors);
            }
            
            exit(i);
        } else {
            pids[i] = pid;
  8007d0:	00aa2023          	sw	a0,0(s4)
    for (int i = 0; i < 5; i++) {
  8007d4:	2905                	addiw	s2,s2,1
  8007d6:	0a11                	addi	s4,s4,4
  8007d8:	ff5918e3          	bne	s2,s5,8007c8 <stress_test_concurrent_write+0x4c>
        }
    }
    
    // 父进程也写入
    cprintf("[父进程] 同时写入...\n");
  8007dc:	00001517          	auipc	a0,0x1
  8007e0:	cc450513          	addi	a0,a0,-828 # 8014a0 <error_string+0x4d8>
  8007e4:	85dff0ef          	jal	ra,800040 <cprintf>
  8007e8:	6761                	lui	a4,0x18
  8007ea:	00003497          	auipc	s1,0x3
  8007ee:	81648493          	addi	s1,s1,-2026 # 803000 <loop_data.1>
  8007f2:	00002797          	auipc	a5,0x2
  8007f6:	80e78793          	addi	a5,a5,-2034 # 802000 <concurrent_data.4>
  8007fa:	69f70713          	addi	a4,a4,1695 # 1869f <_start-0x7e7981>
    for (int i = 0; i < 1024; i++) {
        concurrent_data[i] = 99999 + i;
  8007fe:	c398                	sw	a4,0(a5)
    for (int i = 0; i < 1024; i++) {
  800800:	0791                	addi	a5,a5,4
  800802:	2705                	addiw	a4,a4,1
  800804:	fe979de3          	bne	a5,s1,8007fe <stress_test_concurrent_write+0x82>
    }
    
    // 等待所有子进程
    for (int i = 0; i < 5; i++) {
  800808:	4901                	li	s2,0
        int exit_code;
        waitpid(pids[i], &exit_code);
        cprintf("子进程%d退出\n", i);
  80080a:	00001a97          	auipc	s5,0x1
  80080e:	cb6a8a93          	addi	s5,s5,-842 # 8014c0 <error_string+0x4f8>
    for (int i = 0; i < 5; i++) {
  800812:	4a15                	li	s4,5
        waitpid(pids[i], &exit_code);
  800814:	0009a503          	lw	a0,0(s3)
  800818:	004c                	addi	a1,sp,4
    for (int i = 0; i < 5; i++) {
  80081a:	0991                	addi	s3,s3,4
        waitpid(pids[i], &exit_code);
  80081c:	8cfff0ef          	jal	ra,8000ea <waitpid>
        cprintf("子进程%d退出\n", i);
  800820:	85ca                	mv	a1,s2
  800822:	8556                	mv	a0,s5
    for (int i = 0; i < 5; i++) {
  800824:	2905                	addiw	s2,s2,1
        cprintf("子进程%d退出\n", i);
  800826:	81bff0ef          	jal	ra,800040 <cprintf>
    for (int i = 0; i < 5; i++) {
  80082a:	ff4915e3          	bne	s2,s4,800814 <stress_test_concurrent_write+0x98>
  80082e:	67e1                	lui	a5,0x18
  800830:	69f78793          	addi	a5,a5,1695 # 1869f <_start-0x7e7981>
    }
    
    // 验证父进程数据
    int errors = 0;
  800834:	4581                	li	a1,0
    for (int i = 0; i < 1024; i++) {
        if (concurrent_data[i] != 99999 + i) {
  800836:	4018                	lw	a4,0(s0)
  800838:	00f70363          	beq	a4,a5,80083e <stress_test_concurrent_write+0xc2>
            errors++;
  80083c:	2585                	addiw	a1,a1,1
    for (int i = 0; i < 1024; i++) {
  80083e:	0411                	addi	s0,s0,4
  800840:	2785                	addiw	a5,a5,1
  800842:	fe941ae3          	bne	s0,s1,800836 <stress_test_concurrent_write+0xba>
        }
    }
    
    if (errors == 0) {
  800846:	ed99                	bnez	a1,800864 <stress_test_concurrent_write+0xe8>
        cprintf("✓ 压力测试3通过：并发写入正确隔离\n");
    } else {
        cprintf("✗ 压力测试3失败：%d个数据错误\n", errors);
    }
}
  800848:	6446                	ld	s0,80(sp)
  80084a:	60e6                	ld	ra,88(sp)
  80084c:	64a6                	ld	s1,72(sp)
  80084e:	6906                	ld	s2,64(sp)
  800850:	79e2                	ld	s3,56(sp)
  800852:	7a42                	ld	s4,48(sp)
  800854:	7aa2                	ld	s5,40(sp)
        cprintf("✓ 压力测试3通过：并发写入正确隔离\n");
  800856:	00001517          	auipc	a0,0x1
  80085a:	c8250513          	addi	a0,a0,-894 # 8014d8 <error_string+0x510>
}
  80085e:	6125                	addi	sp,sp,96
        cprintf("✓ 压力测试3通过：并发写入正确隔离\n");
  800860:	fe0ff06f          	j	800040 <cprintf>
}
  800864:	6446                	ld	s0,80(sp)
  800866:	60e6                	ld	ra,88(sp)
  800868:	64a6                	ld	s1,72(sp)
  80086a:	6906                	ld	s2,64(sp)
  80086c:	79e2                	ld	s3,56(sp)
  80086e:	7a42                	ld	s4,48(sp)
  800870:	7aa2                	ld	s5,40(sp)
        cprintf("✗ 压力测试3失败：%d个数据错误\n", errors);
  800872:	00001517          	auipc	a0,0x1
  800876:	c9e50513          	addi	a0,a0,-866 # 801510 <error_string+0x548>
}
  80087a:	6125                	addi	sp,sp,96
        cprintf("✗ 压力测试3失败：%d个数据错误\n", errors);
  80087c:	fc4ff06f          	j	800040 <cprintf>
                concurrent_data[j] = i * 1000 + j;
  800880:	3e800993          	li	s3,1000
  800884:	032989bb          	mulw	s3,s3,s2
            cprintf("[子进程%d] 开始写入...\n", i);
  800888:	85ca                	mv	a1,s2
  80088a:	00001517          	auipc	a0,0x1
  80088e:	b7e50513          	addi	a0,a0,-1154 # 801408 <error_string+0x440>
  800892:	faeff0ef          	jal	ra,800040 <cprintf>
            for (int j = 0; j < 1024; j++) {
  800896:	00002a17          	auipc	s4,0x2
  80089a:	76aa0a13          	addi	s4,s4,1898 # 803000 <loop_data.1>
                concurrent_data[j] = i * 1000 + j;
  80089e:	00001797          	auipc	a5,0x1
  8008a2:	76278793          	addi	a5,a5,1890 # 802000 <concurrent_data.4>
  8008a6:	874e                	mv	a4,s3
  8008a8:	c398                	sw	a4,0(a5)
            for (int j = 0; j < 1024; j++) {
  8008aa:	0791                	addi	a5,a5,4
  8008ac:	2705                	addiw	a4,a4,1
  8008ae:	fefa1de3          	bne	s4,a5,8008a8 <stress_test_concurrent_write+0x12c>
            cprintf("[子进程%d] 写入完成\n", i);
  8008b2:	85ca                	mv	a1,s2
  8008b4:	00001517          	auipc	a0,0x1
  8008b8:	b7450513          	addi	a0,a0,-1164 # 801428 <error_string+0x460>
  8008bc:	f84ff0ef          	jal	ra,800040 <cprintf>
                if (concurrent_data[j] != i * 1000 + j) {
  8008c0:	401c                	lw	a5,0(s0)
  8008c2:	01378363          	beq	a5,s3,8008c8 <stress_test_concurrent_write+0x14c>
                    errors++;
  8008c6:	2485                	addiw	s1,s1,1
            for (int j = 0; j < 1024; j++) {
  8008c8:	0411                	addi	s0,s0,4
  8008ca:	2985                	addiw	s3,s3,1
  8008cc:	fe8a1ae3          	bne	s4,s0,8008c0 <stress_test_concurrent_write+0x144>
            if (errors == 0) {
  8008d0:	e899                	bnez	s1,8008e6 <stress_test_concurrent_write+0x16a>
                cprintf("[子进程%d] 数据验证通过\n", i);
  8008d2:	85ca                	mv	a1,s2
  8008d4:	00001517          	auipc	a0,0x1
  8008d8:	b7450513          	addi	a0,a0,-1164 # 801448 <error_string+0x480>
  8008dc:	f64ff0ef          	jal	ra,800040 <cprintf>
            exit(i);
  8008e0:	854a                	mv	a0,s2
  8008e2:	feaff0ef          	jal	ra,8000cc <exit>
                cprintf("[子进程%d] 数据验证失败：%d个错误\n", i, errors);
  8008e6:	8626                	mv	a2,s1
  8008e8:	85ca                	mv	a1,s2
  8008ea:	00001517          	auipc	a0,0x1
  8008ee:	b8650513          	addi	a0,a0,-1146 # 801470 <error_string+0x4a8>
  8008f2:	f4eff0ef          	jal	ra,800040 <cprintf>
  8008f6:	b7ed                	j	8008e0 <stress_test_concurrent_write+0x164>

00000000008008f8 <stress_test_random_access>:

/* 压力测试4：随机访问模式 */
void stress_test_random_access(void) {
  8008f8:	715d                	addi	sp,sp,-80
    cprintf("\n========== 压力测试4：随机访问 ==========\n");
  8008fa:	00001517          	auipc	a0,0x1
  8008fe:	c4650513          	addi	a0,a0,-954 # 801540 <error_string+0x578>
void stress_test_random_access(void) {
  800902:	e0a2                	sd	s0,64(sp)
  800904:	fc26                	sd	s1,56(sp)
  800906:	f44e                	sd	s3,40(sp)
  800908:	00008497          	auipc	s1,0x8
  80090c:	af848493          	addi	s1,s1,-1288 # 808400 <random_buffer.3>
  800910:	e486                	sd	ra,72(sp)
  800912:	f84a                	sd	s2,48(sp)
  800914:	f052                	sd	s4,32(sp)
  800916:	ec56                	sd	s5,24(sp)
  800918:	e85a                	sd	s6,16(sp)
    cprintf("\n========== 压力测试4：随机访问 ==========\n");
  80091a:	f26ff0ef          	jal	ra,800040 <cprintf>
    
    static char random_buffer[PGSIZE * 20];
    
    // 初始化
    for (int i = 0; i < PGSIZE * 20; i++) {
  80091e:	0001c417          	auipc	s0,0x1c
  800922:	ae240413          	addi	s0,s0,-1310 # 81c400 <shared_buffer>
    cprintf("\n========== 压力测试4：随机访问 ==========\n");
  800926:	89a6                	mv	s3,s1
  800928:	8726                	mv	a4,s1
  80092a:	47b5                	li	a5,13
        random_buffer[i] = (i * 7 + 13) % 256;
  80092c:	00f70023          	sb	a5,0(a4)
    for (int i = 0; i < PGSIZE * 20; i++) {
  800930:	279d                	addiw	a5,a5,7
  800932:	0705                	addi	a4,a4,1
  800934:	0ff7f793          	zext.b	a5,a5
  800938:	fe871ae3          	bne	a4,s0,80092c <stress_test_random_access+0x34>
    }
    
    int pid = fork();
  80093c:	fa6ff0ef          	jal	ra,8000e2 <fork>
  800940:	892a                	mv	s2,a0
    
    if (pid == 0) {
  800942:	c539                	beqz	a0,800990 <stress_test_random_access+0x98>
        
        cprintf("[子进程] 随机访问完成\n");
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
  800944:	006c                	addi	a1,sp,12
  800946:	fa4ff0ef          	jal	ra,8000ea <waitpid>
  80094a:	47b5                	li	a5,13
  80094c:	a039                	j	80095a <stress_test_random_access+0x62>
        
        // 验证父进程数据未变
        int unchanged = 1;
        for (int i = 0; i < PGSIZE * 20; i++) {
  80094e:	279d                	addiw	a5,a5,7
  800950:	0485                	addi	s1,s1,1
  800952:	0ff7f793          	zext.b	a5,a5
  800956:	02848663          	beq	s1,s0,800982 <stress_test_random_access+0x8a>
            char expected = (i * 7 + 13) % 256;
            if (random_buffer[i] != expected) {
  80095a:	0004c703          	lbu	a4,0(s1)
  80095e:	fef708e3          	beq	a4,a5,80094e <stress_test_random_access+0x56>
        }
        
        if (unchanged) {
            cprintf("✓ 压力测试4通过\n");
        } else {
            cprintf("✗ 压力测试4失败\n");
  800962:	00001517          	auipc	a0,0x1
  800966:	cae50513          	addi	a0,a0,-850 # 801610 <error_string+0x648>
  80096a:	ed6ff0ef          	jal	ra,800040 <cprintf>
        }
    }
}
  80096e:	60a6                	ld	ra,72(sp)
  800970:	6406                	ld	s0,64(sp)
  800972:	74e2                	ld	s1,56(sp)
  800974:	7942                	ld	s2,48(sp)
  800976:	79a2                	ld	s3,40(sp)
  800978:	7a02                	ld	s4,32(sp)
  80097a:	6ae2                	ld	s5,24(sp)
  80097c:	6b42                	ld	s6,16(sp)
  80097e:	6161                	addi	sp,sp,80
  800980:	8082                	ret
            cprintf("✓ 压力测试4通过\n");
  800982:	00001517          	auipc	a0,0x1
  800986:	c6e50513          	addi	a0,a0,-914 # 8015f0 <error_string+0x628>
  80098a:	eb6ff0ef          	jal	ra,800040 <cprintf>
  80098e:	b7c5                	j	80096e <stress_test_random_access+0x76>
        cprintf("[子进程] 随机读写测试...\n");
  800990:	00001517          	auipc	a0,0x1
  800994:	be850513          	addi	a0,a0,-1048 # 801578 <error_string+0x5b0>
  800998:	6405                	lui	s0,0x1
  80099a:	ea6ff0ef          	jal	ra,800040 <cprintf>
  80099e:	91d40413          	addi	s0,s0,-1763 # 91d <_start-0x7ff703>
            int pos = (iter * 997 + 2333) % (PGSIZE * 20);
  8009a2:	6b51                	lui	s6,0x14
            random_buffer[pos] = (char)(iter % 256);
  8009a4:	4ad1                	li	s5,20
                cprintf("[子进程] 迭代%d: pos=%d, old=%d, new=%d\n", 
  8009a6:	00001a17          	auipc	s4,0x1
  8009aa:	bfaa0a13          	addi	s4,s4,-1030 # 8015a0 <error_string+0x5d8>
        for (int iter = 0; iter < 100; iter++) {
  8009ae:	06400493          	li	s1,100
  8009b2:	a031                	j	8009be <stress_test_random_access+0xc6>
  8009b4:	2905                	addiw	s2,s2,1
  8009b6:	3e54041b          	addiw	s0,s0,997
  8009ba:	02990963          	beq	s2,s1,8009ec <stress_test_random_access+0xf4>
            int pos = (iter * 997 + 2333) % (PGSIZE * 20);
  8009be:	0364663b          	remw	a2,s0,s6
            if (iter % 20 == 0) {
  8009c2:	035967bb          	remw	a5,s2,s5
            volatile char old_val = random_buffer[pos];
  8009c6:	00c98733          	add	a4,s3,a2
  8009ca:	00074683          	lbu	a3,0(a4)
            random_buffer[pos] = (char)(iter % 256);
  8009ce:	01270023          	sb	s2,0(a4)
            volatile char old_val = random_buffer[pos];
  8009d2:	00d10623          	sb	a3,12(sp)
            if (iter % 20 == 0) {
  8009d6:	fff9                	bnez	a5,8009b4 <stress_test_random_access+0xbc>
                cprintf("[子进程] 迭代%d: pos=%d, old=%d, new=%d\n", 
  8009d8:	00c14683          	lbu	a3,12(sp)
  8009dc:	874a                	mv	a4,s2
  8009de:	85ca                	mv	a1,s2
  8009e0:	0ff6f693          	zext.b	a3,a3
  8009e4:	8552                	mv	a0,s4
  8009e6:	e5aff0ef          	jal	ra,800040 <cprintf>
  8009ea:	b7e9                	j	8009b4 <stress_test_random_access+0xbc>
        cprintf("[子进程] 随机访问完成\n");
  8009ec:	00001517          	auipc	a0,0x1
  8009f0:	be450513          	addi	a0,a0,-1052 # 8015d0 <error_string+0x608>
  8009f4:	e4cff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  8009f8:	4501                	li	a0,0
  8009fa:	ed2ff0ef          	jal	ra,8000cc <exit>

00000000008009fe <stress_test_memory_pressure>:

/* 压力测试5：内存不足场景 
 * 测试当系统内存不足时，COW是否能正确处理
 */
void stress_test_memory_pressure(void) {
  8009fe:	7139                	addi	sp,sp,-64
    cprintf("\n========== 压力测试5：内存压力 ==========\n");
  800a00:	00001517          	auipc	a0,0x1
  800a04:	c3050513          	addi	a0,a0,-976 # 801630 <error_string+0x668>
void stress_test_memory_pressure(void) {
  800a08:	fc06                	sd	ra,56(sp)
  800a0a:	f822                	sd	s0,48(sp)
  800a0c:	f426                	sd	s1,40(sp)
  800a0e:	f04a                	sd	s2,32(sp)
  800a10:	ec4e                	sd	s3,24(sp)
    cprintf("\n========== 压力测试5：内存压力 ==========\n");
  800a12:	e2eff0ef          	jal	ra,800040 <cprintf>
    
    // 分配大量页面
    static char huge_buffer[PGSIZE * 100];
    cprintf("分配了%d页 (%d字节)\n", 100, PGSIZE * 100);
  800a16:	00064637          	lui	a2,0x64
  800a1a:	06400593          	li	a1,100
  800a1e:	00001517          	auipc	a0,0x1
  800a22:	c4a50513          	addi	a0,a0,-950 # 801668 <error_string+0x6a0>
  800a26:	e1aff0ef          	jal	ra,800040 <cprintf>
    // 初始化
    for (int i = 0; i < PGSIZE * 100; i += PGSIZE) {
        huge_buffer[i] = 'H';
    }
    
    int pid = fork();
  800a2a:	eb8ff0ef          	jal	ra,8000e2 <fork>
    
    if (pid < 0) {
  800a2e:	04054363          	bltz	a0,800a74 <stress_test_memory_pressure+0x76>
  800a32:	842a                	mv	s0,a0
        cprintf("Fork失败：可能内存不足\n");
        return;
    }
    
    if (pid == 0) {
  800a34:	cd21                	beqz	a0,800a8c <stress_test_memory_pressure+0x8e>
        
        cprintf("[子进程] 成功复制%d页\n", success_count);
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
  800a36:	006c                	addi	a1,sp,12
  800a38:	eb2ff0ef          	jal	ra,8000ea <waitpid>
        
        if (exit_code == 0) {
  800a3c:	45b2                	lw	a1,12(sp)
  800a3e:	cd91                	beqz	a1,800a5a <stress_test_memory_pressure+0x5c>
            cprintf("✓ 压力测试5通过\n");
        } else {
            cprintf("子进程异常退出：exit_code=%d\n", exit_code);
  800a40:	00001517          	auipc	a0,0x1
  800a44:	d0050513          	addi	a0,a0,-768 # 801740 <error_string+0x778>
  800a48:	df8ff0ef          	jal	ra,800040 <cprintf>
        }
    }
}
  800a4c:	70e2                	ld	ra,56(sp)
  800a4e:	7442                	ld	s0,48(sp)
  800a50:	74a2                	ld	s1,40(sp)
  800a52:	7902                	ld	s2,32(sp)
  800a54:	69e2                	ld	s3,24(sp)
  800a56:	6121                	addi	sp,sp,64
  800a58:	8082                	ret
            cprintf("✓ 压力测试5通过\n");
  800a5a:	00001517          	auipc	a0,0x1
  800a5e:	cc650513          	addi	a0,a0,-826 # 801720 <error_string+0x758>
  800a62:	ddeff0ef          	jal	ra,800040 <cprintf>
}
  800a66:	70e2                	ld	ra,56(sp)
  800a68:	7442                	ld	s0,48(sp)
  800a6a:	74a2                	ld	s1,40(sp)
  800a6c:	7902                	ld	s2,32(sp)
  800a6e:	69e2                	ld	s3,24(sp)
  800a70:	6121                	addi	sp,sp,64
  800a72:	8082                	ret
  800a74:	7442                	ld	s0,48(sp)
  800a76:	70e2                	ld	ra,56(sp)
  800a78:	74a2                	ld	s1,40(sp)
  800a7a:	7902                	ld	s2,32(sp)
  800a7c:	69e2                	ld	s3,24(sp)
        cprintf("Fork失败：可能内存不足\n");
  800a7e:	00001517          	auipc	a0,0x1
  800a82:	c0a50513          	addi	a0,a0,-1014 # 801688 <error_string+0x6c0>
}
  800a86:	6121                	addi	sp,sp,64
        cprintf("Fork失败：可能内存不足\n");
  800a88:	db8ff06f          	j	800040 <cprintf>
        cprintf("[子进程] 尝试写入所有100页...\n");
  800a8c:	00001517          	auipc	a0,0x1
  800a90:	c2450513          	addi	a0,a0,-988 # 8016b0 <error_string+0x6e8>
  800a94:	dacff0ef          	jal	ra,800040 <cprintf>
            success_count++;
  800a98:	49a9                	li	s3,10
                cprintf("[子进程] 已复制%d页\n", success_count);
  800a9a:	00001917          	auipc	s2,0x1
  800a9e:	c4690913          	addi	s2,s2,-954 # 8016e0 <error_string+0x718>
        for (int i = 0; i < 100; i++) {
  800aa2:	06400493          	li	s1,100
            if (i % 10 == 0) {
  800aa6:	033467bb          	remw	a5,s0,s3
            success_count++;
  800aaa:	2405                	addiw	s0,s0,1
            if (i % 10 == 0) {
  800aac:	cf91                	beqz	a5,800ac8 <stress_test_memory_pressure+0xca>
        for (int i = 0; i < 100; i++) {
  800aae:	fe941ce3          	bne	s0,s1,800aa6 <stress_test_memory_pressure+0xa8>
        cprintf("[子进程] 成功复制%d页\n", success_count);
  800ab2:	06400593          	li	a1,100
  800ab6:	00001517          	auipc	a0,0x1
  800aba:	c4a50513          	addi	a0,a0,-950 # 801700 <error_string+0x738>
  800abe:	d82ff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  800ac2:	4501                	li	a0,0
  800ac4:	e08ff0ef          	jal	ra,8000cc <exit>
                cprintf("[子进程] 已复制%d页\n", success_count);
  800ac8:	85a2                	mv	a1,s0
  800aca:	854a                	mv	a0,s2
  800acc:	d74ff0ef          	jal	ra,800040 <cprintf>
  800ad0:	bff9                	j	800aae <stress_test_memory_pressure+0xb0>

0000000000800ad2 <stress_test_fork_exit_loop>:

/* 压力测试6：快速fork-exit循环 */
void stress_test_fork_exit_loop(void) {
  800ad2:	7139                	addi	sp,sp,-64
    cprintf("\n========== 压力测试6：Fork-Exit循环 ==========\n");
  800ad4:	00001517          	auipc	a0,0x1
  800ad8:	c9450513          	addi	a0,a0,-876 # 801768 <error_string+0x7a0>
void stress_test_fork_exit_loop(void) {
  800adc:	e852                	sd	s4,16(sp)
  800ade:	fc06                	sd	ra,56(sp)
  800ae0:	f822                	sd	s0,48(sp)
  800ae2:	f426                	sd	s1,40(sp)
  800ae4:	f04a                	sd	s2,32(sp)
  800ae6:	ec4e                	sd	s3,24(sp)
  800ae8:	00002a17          	auipc	s4,0x2
  800aec:	518a0a13          	addi	s4,s4,1304 # 803000 <loop_data.1>
    cprintf("\n========== 压力测试6：Fork-Exit循环 ==========\n");
  800af0:	d50ff0ef          	jal	ra,800040 <cprintf>
  800af4:	8752                	mv	a4,s4
    
    static int loop_data[256];
    for (int i = 0; i < 256; i++) {
  800af6:	4781                	li	a5,0
  800af8:	10000693          	li	a3,256
        loop_data[i] = i;
  800afc:	c31c                	sw	a5,0(a4)
    for (int i = 0; i < 256; i++) {
  800afe:	2785                	addiw	a5,a5,1
  800b00:	0711                	addi	a4,a4,4
  800b02:	fed79de3          	bne	a5,a3,800afc <stress_test_fork_exit_loop+0x2a>
    }
    
    cprintf("执行100次fork-exit循环...\n");
  800b06:	00001517          	auipc	a0,0x1
  800b0a:	c9a50513          	addi	a0,a0,-870 # 8017a0 <error_string+0x7d8>
  800b0e:	d32ff0ef          	jal	ra,800040 <cprintf>
    
    for (int i = 0; i < 100; i++) {
  800b12:	4401                	li	s0,0
            exit(0);
        } else {
            // 父进程：立即等待
            waitpid(pid, NULL);
            
            if (i % 10 == 0) {
  800b14:	4929                	li	s2,10
                cprintf("完成%d次循环\n", i + 1);
  800b16:	00001997          	auipc	s3,0x1
  800b1a:	caa98993          	addi	s3,s3,-854 # 8017c0 <error_string+0x7f8>
    for (int i = 0; i < 100; i++) {
  800b1e:	06400493          	li	s1,100
        int pid = fork();
  800b22:	dc0ff0ef          	jal	ra,8000e2 <fork>
        if (pid == 0) {
  800b26:	cd15                	beqz	a0,800b62 <stress_test_fork_exit_loop+0x90>
            waitpid(pid, NULL);
  800b28:	4581                	li	a1,0
  800b2a:	dc0ff0ef          	jal	ra,8000ea <waitpid>
            if (i % 10 == 0) {
  800b2e:	032467bb          	remw	a5,s0,s2
                cprintf("完成%d次循环\n", i + 1);
  800b32:	2405                	addiw	s0,s0,1
            if (i % 10 == 0) {
  800b34:	c385                	beqz	a5,800b54 <stress_test_fork_exit_loop+0x82>
    for (int i = 0; i < 100; i++) {
  800b36:	fe9416e3          	bne	s0,s1,800b22 <stress_test_fork_exit_loop+0x50>
            }
        }
    }
    
    cprintf("✓ 压力测试6完成：100次fork-exit\n");
}
  800b3a:	7442                	ld	s0,48(sp)
  800b3c:	70e2                	ld	ra,56(sp)
  800b3e:	74a2                	ld	s1,40(sp)
  800b40:	7902                	ld	s2,32(sp)
  800b42:	69e2                	ld	s3,24(sp)
  800b44:	6a42                	ld	s4,16(sp)
    cprintf("✓ 压力测试6完成：100次fork-exit\n");
  800b46:	00001517          	auipc	a0,0x1
  800b4a:	c9250513          	addi	a0,a0,-878 # 8017d8 <error_string+0x810>
}
  800b4e:	6121                	addi	sp,sp,64
    cprintf("✓ 压力测试6完成：100次fork-exit\n");
  800b50:	cf0ff06f          	j	800040 <cprintf>
                cprintf("完成%d次循环\n", i + 1);
  800b54:	85a2                	mv	a1,s0
  800b56:	854e                	mv	a0,s3
  800b58:	ce8ff0ef          	jal	ra,800040 <cprintf>
    for (int i = 0; i < 100; i++) {
  800b5c:	fc9413e3          	bne	s0,s1,800b22 <stress_test_fork_exit_loop+0x50>
  800b60:	bfe9                	j	800b3a <stress_test_fork_exit_loop+0x68>
            volatile int sum = 0;
  800b62:	c602                	sw	zero,12(sp)
            for (int j = 0; j < 256; j++) {
  800b64:	00003697          	auipc	a3,0x3
  800b68:	89c68693          	addi	a3,a3,-1892 # 803400 <nested_data.0>
                sum += loop_data[j];
  800b6c:	47b2                	lw	a5,12(sp)
  800b6e:	000a2703          	lw	a4,0(s4)
            for (int j = 0; j < 256; j++) {
  800b72:	0a11                	addi	s4,s4,4
                sum += loop_data[j];
  800b74:	9fb9                	addw	a5,a5,a4
  800b76:	c63e                	sw	a5,12(sp)
            for (int j = 0; j < 256; j++) {
  800b78:	feda1ae3          	bne	s4,a3,800b6c <stress_test_fork_exit_loop+0x9a>
            exit(0);
  800b7c:	4501                	li	a0,0
  800b7e:	d4eff0ef          	jal	ra,8000cc <exit>

0000000000800b82 <stress_test_nested_fork>:

/* 压力测试7：嵌套fork */
void stress_test_nested_fork(void) {
  800b82:	1101                	addi	sp,sp,-32
    cprintf("\n========== 压力测试7：嵌套Fork ==========\n");
  800b84:	00001517          	auipc	a0,0x1
  800b88:	c8450513          	addi	a0,a0,-892 # 801808 <error_string+0x840>
void stress_test_nested_fork(void) {
  800b8c:	e822                	sd	s0,16(sp)
  800b8e:	e426                	sd	s1,8(sp)
  800b90:	ec06                	sd	ra,24(sp)
  800b92:	00003497          	auipc	s1,0x3
  800b96:	86e48493          	addi	s1,s1,-1938 # 803400 <nested_data.0>
    cprintf("\n========== 压力测试7：嵌套Fork ==========\n");
  800b9a:	ca6ff0ef          	jal	ra,800040 <cprintf>
    
    static char nested_data[PGSIZE * 5];
    for (int i = 0; i < PGSIZE * 5; i++) {
        nested_data[i] = 'N';
  800b9e:	04e00413          	li	s0,78
  800ba2:	87a6                	mv	a5,s1
  800ba4:	00008717          	auipc	a4,0x8
  800ba8:	85c70713          	addi	a4,a4,-1956 # 808400 <random_buffer.3>
  800bac:	00878023          	sb	s0,0(a5)
    for (int i = 0; i < PGSIZE * 5; i++) {
  800bb0:	0785                	addi	a5,a5,1
  800bb2:	fef71de3          	bne	a4,a5,800bac <stress_test_nested_fork+0x2a>
    }
    
    cprintf("执行三层嵌套fork...\n");
  800bb6:	00001517          	auipc	a0,0x1
  800bba:	c8a50513          	addi	a0,a0,-886 # 801840 <error_string+0x878>
  800bbe:	c82ff0ef          	jal	ra,800040 <cprintf>
    
    int pid1 = fork();
  800bc2:	d20ff0ef          	jal	ra,8000e2 <fork>
    if (pid1 == 0) {
  800bc6:	e159                	bnez	a0,800c4c <stress_test_nested_fork+0xca>
        // 第一层子进程
        cprintf("[L1子进程] PID=%d\n", getpid());
  800bc8:	d24ff0ef          	jal	ra,8000ec <getpid>
  800bcc:	85aa                	mv	a1,a0
  800bce:	00001517          	auipc	a0,0x1
  800bd2:	c9250513          	addi	a0,a0,-878 # 801860 <error_string+0x898>
  800bd6:	c6aff0ef          	jal	ra,800040 <cprintf>
        nested_data[0] = '1';
  800bda:	03100793          	li	a5,49
  800bde:	00f48023          	sb	a5,0(s1)
        
        int pid2 = fork();
  800be2:	d00ff0ef          	jal	ra,8000e2 <fork>
        if (pid2 == 0) {
  800be6:	e161                	bnez	a0,800ca6 <stress_test_nested_fork+0x124>
            // 第二层子进程
            cprintf("[L2子进程] PID=%d\n", getpid());
  800be8:	d04ff0ef          	jal	ra,8000ec <getpid>
  800bec:	85aa                	mv	a1,a0
  800bee:	00001517          	auipc	a0,0x1
  800bf2:	c8a50513          	addi	a0,a0,-886 # 801878 <error_string+0x8b0>
  800bf6:	c4aff0ef          	jal	ra,800040 <cprintf>
            nested_data[PGSIZE] = '2';
  800bfa:	00004417          	auipc	s0,0x4
  800bfe:	80640413          	addi	s0,s0,-2042 # 804400 <nested_data.0+0x1000>
  800c02:	03200793          	li	a5,50
  800c06:	00f40023          	sb	a5,0(s0)
            
            int pid3 = fork();
  800c0a:	cd8ff0ef          	jal	ra,8000e2 <fork>
            if (pid3 == 0) {
  800c0e:	ed25                	bnez	a0,800c86 <stress_test_nested_fork+0x104>
                // 第三层子进程
                cprintf("[L3子进程] PID=%d\n", getpid());
  800c10:	cdcff0ef          	jal	ra,8000ec <getpid>
  800c14:	85aa                	mv	a1,a0
  800c16:	00001517          	auipc	a0,0x1
  800c1a:	c7a50513          	addi	a0,a0,-902 # 801890 <error_string+0x8c8>
  800c1e:	c22ff0ef          	jal	ra,800040 <cprintf>
                nested_data[PGSIZE * 2] = '3';
                
                cprintf("[L3子进程] 数据: %c, %c, %c\n", 
  800c22:	00044603          	lbu	a2,0(s0)
  800c26:	0004c583          	lbu	a1,0(s1)
                nested_data[PGSIZE * 2] = '3';
  800c2a:	03300793          	li	a5,51
                cprintf("[L3子进程] 数据: %c, %c, %c\n", 
  800c2e:	03300693          	li	a3,51
  800c32:	00001517          	auipc	a0,0x1
  800c36:	c7650513          	addi	a0,a0,-906 # 8018a8 <error_string+0x8e0>
                nested_data[PGSIZE * 2] = '3';
  800c3a:	00004717          	auipc	a4,0x4
  800c3e:	7cf70323          	sb	a5,1990(a4) # 805400 <nested_data.0+0x2000>
                cprintf("[L3子进程] 数据: %c, %c, %c\n", 
  800c42:	bfeff0ef          	jal	ra,800040 <cprintf>
                        nested_data[0], nested_data[PGSIZE], 
                        nested_data[PGSIZE * 2]);
                exit(0);
  800c46:	4501                	li	a0,0
  800c48:	c84ff0ef          	jal	ra,8000cc <exit>
        waitpid(pid2, NULL);
        cprintf("[L1子进程] 数据: %c\n", nested_data[0]);
        exit(0);
    }
    
    waitpid(pid1, NULL);
  800c4c:	4581                	li	a1,0
  800c4e:	c9cff0ef          	jal	ra,8000ea <waitpid>
    cprintf("[父进程] 数据: %c (应该是'N')\n", nested_data[0]);
  800c52:	0004c583          	lbu	a1,0(s1)
  800c56:	00001517          	auipc	a0,0x1
  800c5a:	cba50513          	addi	a0,a0,-838 # 801910 <error_string+0x948>
  800c5e:	be2ff0ef          	jal	ra,800040 <cprintf>
    
    if (nested_data[0] == 'N') {
  800c62:	0004c783          	lbu	a5,0(s1)
        cprintf("✓ 压力测试7通过\n");
  800c66:	00001517          	auipc	a0,0x1
  800c6a:	cd250513          	addi	a0,a0,-814 # 801938 <error_string+0x970>
    if (nested_data[0] == 'N') {
  800c6e:	00878663          	beq	a5,s0,800c7a <stress_test_nested_fork+0xf8>
    } else {
        cprintf("✗ 压力测试7失败\n");
  800c72:	00001517          	auipc	a0,0x1
  800c76:	ce650513          	addi	a0,a0,-794 # 801958 <error_string+0x990>
    }
}
  800c7a:	6442                	ld	s0,16(sp)
  800c7c:	60e2                	ld	ra,24(sp)
  800c7e:	64a2                	ld	s1,8(sp)
  800c80:	6105                	addi	sp,sp,32
        cprintf("✗ 压力测试7失败\n");
  800c82:	bbeff06f          	j	800040 <cprintf>
            waitpid(pid3, NULL);
  800c86:	4581                	li	a1,0
  800c88:	c62ff0ef          	jal	ra,8000ea <waitpid>
            cprintf("[L2子进程] 数据: %c, %c\n", 
  800c8c:	00044603          	lbu	a2,0(s0)
  800c90:	0004c583          	lbu	a1,0(s1)
  800c94:	00001517          	auipc	a0,0x1
  800c98:	c3c50513          	addi	a0,a0,-964 # 8018d0 <error_string+0x908>
  800c9c:	ba4ff0ef          	jal	ra,800040 <cprintf>
            exit(0);
  800ca0:	4501                	li	a0,0
  800ca2:	c2aff0ef          	jal	ra,8000cc <exit>
        waitpid(pid2, NULL);
  800ca6:	4581                	li	a1,0
  800ca8:	c42ff0ef          	jal	ra,8000ea <waitpid>
        cprintf("[L1子进程] 数据: %c\n", nested_data[0]);
  800cac:	0004c583          	lbu	a1,0(s1)
  800cb0:	00001517          	auipc	a0,0x1
  800cb4:	c4050513          	addi	a0,a0,-960 # 8018f0 <error_string+0x928>
  800cb8:	b88ff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  800cbc:	4501                	li	a0,0
  800cbe:	c0eff0ef          	jal	ra,8000cc <exit>

0000000000800cc2 <main>:

int main(void) {
  800cc2:	1141                	addi	sp,sp,-16
    cprintf("╔════════════════════════════════════════╗\n");
  800cc4:	00001517          	auipc	a0,0x1
  800cc8:	cb450513          	addi	a0,a0,-844 # 801978 <error_string+0x9b0>
int main(void) {
  800ccc:	e406                	sd	ra,8(sp)
    cprintf("╔════════════════════════════════════════╗\n");
  800cce:	b72ff0ef          	jal	ra,800040 <cprintf>
    cprintf("║      COW机制压力测试程序              ║\n");
  800cd2:	00001517          	auipc	a0,0x1
  800cd6:	d2650513          	addi	a0,a0,-730 # 8019f8 <error_string+0xa30>
  800cda:	b66ff0ef          	jal	ra,800040 <cprintf>
    cprintf("║   警告：此测试会产生大量进程！        ║\n");
  800cde:	00001517          	auipc	a0,0x1
  800ce2:	d5250513          	addi	a0,a0,-686 # 801a30 <error_string+0xa68>
  800ce6:	b5aff0ef          	jal	ra,800040 <cprintf>
    cprintf("╚════════════════════════════════════════╝\n");
  800cea:	00001517          	auipc	a0,0x1
  800cee:	d8650513          	addi	a0,a0,-634 # 801a70 <error_string+0xaa8>
  800cf2:	b4eff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("\n准备运行压力测试...\n");
  800cf6:	00001517          	auipc	a0,0x1
  800cfa:	dfa50513          	addi	a0,a0,-518 # 801af0 <error_string+0xb28>
  800cfe:	b42ff0ef          	jal	ra,800040 <cprintf>
    cprintf("共享缓冲区大小：%d字节 (%d页)\n", 
  800d02:	03200613          	li	a2,50
  800d06:	000325b7          	lui	a1,0x32
  800d0a:	00001517          	auipc	a0,0x1
  800d0e:	e0650513          	addi	a0,a0,-506 # 801b10 <error_string+0xb48>
  800d12:	b2eff0ef          	jal	ra,800040 <cprintf>
            PGSIZE * LARGE_BUFFER_PAGES, LARGE_BUFFER_PAGES);
    
    // 运行所有压力测试
    stress_test_many_forks();         // 测试1：大量fork
  800d16:	86dff0ef          	jal	ra,800582 <stress_test_many_forks>
    stress_test_fork_tree_wrapper();  // 测试2：fork树
  800d1a:	a2fff0ef          	jal	ra,800748 <stress_test_fork_tree_wrapper>
    stress_test_concurrent_write();   // 测试3：并发写入
  800d1e:	a5fff0ef          	jal	ra,80077c <stress_test_concurrent_write>
    stress_test_random_access();      // 测试4：随机访问
  800d22:	bd7ff0ef          	jal	ra,8008f8 <stress_test_random_access>
    stress_test_memory_pressure();    // 测试5：内存压力
  800d26:	cd9ff0ef          	jal	ra,8009fe <stress_test_memory_pressure>
    stress_test_fork_exit_loop();     // 测试6：fork-exit循环
  800d2a:	da9ff0ef          	jal	ra,800ad2 <stress_test_fork_exit_loop>
    stress_test_nested_fork();        // 测试7：嵌套fork
  800d2e:	e55ff0ef          	jal	ra,800b82 <stress_test_nested_fork>
    
    cprintf("\n╔════════════════════════════════════════╗\n");
  800d32:	00001517          	auipc	a0,0x1
  800d36:	e0e50513          	addi	a0,a0,-498 # 801b40 <error_string+0xb78>
  800d3a:	b06ff0ef          	jal	ra,800040 <cprintf>
    cprintf("║       所有压力测试完成！              ║\n");
  800d3e:	00001517          	auipc	a0,0x1
  800d42:	e8a50513          	addi	a0,a0,-374 # 801bc8 <error_string+0xc00>
  800d46:	afaff0ef          	jal	ra,800040 <cprintf>
    cprintf("╚════════════════════════════════════════╝\n");
  800d4a:	00001517          	auipc	a0,0x1
  800d4e:	d2650513          	addi	a0,a0,-730 # 801a70 <error_string+0xaa8>
  800d52:	aeeff0ef          	jal	ra,800040 <cprintf>
    
    return 0;
}
  800d56:	60a2                	ld	ra,8(sp)
  800d58:	4501                	li	a0,0
  800d5a:	0141                	addi	sp,sp,16
  800d5c:	8082                	ret
