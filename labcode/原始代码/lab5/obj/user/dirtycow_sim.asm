
obj/__user_dirtycow_sim.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
.text
.globl _start
_start:
    # call user-program function
    call umain
  800020:	0c8000ef          	jal	ra,8000e8 <umain>
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
  80006a:	0f6000ef          	jal	ra,800160 <vprintfmt>
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
  8000d8:	d2c50513          	addi	a0,a0,-724 # 800e00 <main+0xf6>
  8000dc:	f65ff0ef          	jal	ra,800040 <cprintf>
    while (1);
  8000e0:	a001                	j	8000e0 <exit+0x14>

00000000008000e2 <fork>:
}

int
fork(void) {
    return sys_fork();
  8000e2:	bfd1                	j	8000b6 <sys_fork>

00000000008000e4 <waitpid>:
    return sys_wait(0, NULL);
}

int
waitpid(int pid, int *store) {
    return sys_wait(pid, store);
  8000e4:	bfd9                	j	8000ba <sys_wait>

00000000008000e6 <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  8000e6:	bff1                	j	8000c2 <sys_getpid>

00000000008000e8 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000e8:	1141                	addi	sp,sp,-16
  8000ea:	e406                	sd	ra,8(sp)
    int ret = main();
  8000ec:	41f000ef          	jal	ra,800d0a <main>
    exit(ret);
  8000f0:	fddff0ef          	jal	ra,8000cc <exit>

00000000008000f4 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  8000f4:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000f8:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  8000fa:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000fe:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  800100:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  800104:	f022                	sd	s0,32(sp)
  800106:	ec26                	sd	s1,24(sp)
  800108:	e84a                	sd	s2,16(sp)
  80010a:	f406                	sd	ra,40(sp)
  80010c:	e44e                	sd	s3,8(sp)
  80010e:	84aa                	mv	s1,a0
  800110:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800112:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  800116:	2a01                	sext.w	s4,s4
    if (num >= base) {
  800118:	03067e63          	bgeu	a2,a6,800154 <printnum+0x60>
  80011c:	89be                	mv	s3,a5
        while (-- width > 0)
  80011e:	00805763          	blez	s0,80012c <printnum+0x38>
  800122:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800124:	85ca                	mv	a1,s2
  800126:	854e                	mv	a0,s3
  800128:	9482                	jalr	s1
        while (-- width > 0)
  80012a:	fc65                	bnez	s0,800122 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  80012c:	1a02                	slli	s4,s4,0x20
  80012e:	00001797          	auipc	a5,0x1
  800132:	cea78793          	addi	a5,a5,-790 # 800e18 <main+0x10e>
  800136:	020a5a13          	srli	s4,s4,0x20
  80013a:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  80013c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  80013e:	000a4503          	lbu	a0,0(s4)
}
  800142:	70a2                	ld	ra,40(sp)
  800144:	69a2                	ld	s3,8(sp)
  800146:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  800148:	85ca                	mv	a1,s2
  80014a:	87a6                	mv	a5,s1
}
  80014c:	6942                	ld	s2,16(sp)
  80014e:	64e2                	ld	s1,24(sp)
  800150:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  800152:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  800154:	03065633          	divu	a2,a2,a6
  800158:	8722                	mv	a4,s0
  80015a:	f9bff0ef          	jal	ra,8000f4 <printnum>
  80015e:	b7f9                	j	80012c <printnum+0x38>

0000000000800160 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  800160:	7119                	addi	sp,sp,-128
  800162:	f4a6                	sd	s1,104(sp)
  800164:	f0ca                	sd	s2,96(sp)
  800166:	ecce                	sd	s3,88(sp)
  800168:	e8d2                	sd	s4,80(sp)
  80016a:	e4d6                	sd	s5,72(sp)
  80016c:	e0da                	sd	s6,64(sp)
  80016e:	fc5e                	sd	s7,56(sp)
  800170:	f06a                	sd	s10,32(sp)
  800172:	fc86                	sd	ra,120(sp)
  800174:	f8a2                	sd	s0,112(sp)
  800176:	f862                	sd	s8,48(sp)
  800178:	f466                	sd	s9,40(sp)
  80017a:	ec6e                	sd	s11,24(sp)
  80017c:	892a                	mv	s2,a0
  80017e:	84ae                	mv	s1,a1
  800180:	8d32                	mv	s10,a2
  800182:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800184:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  800188:	5b7d                	li	s6,-1
  80018a:	00001a97          	auipc	s5,0x1
  80018e:	cc2a8a93          	addi	s5,s5,-830 # 800e4c <main+0x142>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800192:	00001b97          	auipc	s7,0x1
  800196:	ed6b8b93          	addi	s7,s7,-298 # 801068 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80019a:	000d4503          	lbu	a0,0(s10)
  80019e:	001d0413          	addi	s0,s10,1
  8001a2:	01350a63          	beq	a0,s3,8001b6 <vprintfmt+0x56>
            if (ch == '\0') {
  8001a6:	c121                	beqz	a0,8001e6 <vprintfmt+0x86>
            putch(ch, putdat);
  8001a8:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001aa:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  8001ac:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001ae:	fff44503          	lbu	a0,-1(s0)
  8001b2:	ff351ae3          	bne	a0,s3,8001a6 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  8001b6:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  8001ba:	02000793          	li	a5,32
        lflag = altflag = 0;
  8001be:	4c81                	li	s9,0
  8001c0:	4881                	li	a7,0
        width = precision = -1;
  8001c2:	5c7d                	li	s8,-1
  8001c4:	5dfd                	li	s11,-1
  8001c6:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  8001ca:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  8001cc:	fdd6059b          	addiw	a1,a2,-35
  8001d0:	0ff5f593          	zext.b	a1,a1
  8001d4:	00140d13          	addi	s10,s0,1
  8001d8:	04b56263          	bltu	a0,a1,80021c <vprintfmt+0xbc>
  8001dc:	058a                	slli	a1,a1,0x2
  8001de:	95d6                	add	a1,a1,s5
  8001e0:	4194                	lw	a3,0(a1)
  8001e2:	96d6                	add	a3,a3,s5
  8001e4:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  8001e6:	70e6                	ld	ra,120(sp)
  8001e8:	7446                	ld	s0,112(sp)
  8001ea:	74a6                	ld	s1,104(sp)
  8001ec:	7906                	ld	s2,96(sp)
  8001ee:	69e6                	ld	s3,88(sp)
  8001f0:	6a46                	ld	s4,80(sp)
  8001f2:	6aa6                	ld	s5,72(sp)
  8001f4:	6b06                	ld	s6,64(sp)
  8001f6:	7be2                	ld	s7,56(sp)
  8001f8:	7c42                	ld	s8,48(sp)
  8001fa:	7ca2                	ld	s9,40(sp)
  8001fc:	7d02                	ld	s10,32(sp)
  8001fe:	6de2                	ld	s11,24(sp)
  800200:	6109                	addi	sp,sp,128
  800202:	8082                	ret
            padc = '0';
  800204:	87b2                	mv	a5,a2
            goto reswitch;
  800206:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  80020a:	846a                	mv	s0,s10
  80020c:	00140d13          	addi	s10,s0,1
  800210:	fdd6059b          	addiw	a1,a2,-35
  800214:	0ff5f593          	zext.b	a1,a1
  800218:	fcb572e3          	bgeu	a0,a1,8001dc <vprintfmt+0x7c>
            putch('%', putdat);
  80021c:	85a6                	mv	a1,s1
  80021e:	02500513          	li	a0,37
  800222:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  800224:	fff44783          	lbu	a5,-1(s0)
  800228:	8d22                	mv	s10,s0
  80022a:	f73788e3          	beq	a5,s3,80019a <vprintfmt+0x3a>
  80022e:	ffed4783          	lbu	a5,-2(s10)
  800232:	1d7d                	addi	s10,s10,-1
  800234:	ff379de3          	bne	a5,s3,80022e <vprintfmt+0xce>
  800238:	b78d                	j	80019a <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  80023a:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  80023e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800242:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  800244:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  800248:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  80024c:	02d86463          	bltu	a6,a3,800274 <vprintfmt+0x114>
                ch = *fmt;
  800250:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  800254:	002c169b          	slliw	a3,s8,0x2
  800258:	0186873b          	addw	a4,a3,s8
  80025c:	0017171b          	slliw	a4,a4,0x1
  800260:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  800262:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  800266:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  800268:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  80026c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800270:	fed870e3          	bgeu	a6,a3,800250 <vprintfmt+0xf0>
            if (width < 0)
  800274:	f40ddce3          	bgez	s11,8001cc <vprintfmt+0x6c>
                width = precision, precision = -1;
  800278:	8de2                	mv	s11,s8
  80027a:	5c7d                	li	s8,-1
  80027c:	bf81                	j	8001cc <vprintfmt+0x6c>
            if (width < 0)
  80027e:	fffdc693          	not	a3,s11
  800282:	96fd                	srai	a3,a3,0x3f
  800284:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  800288:	00144603          	lbu	a2,1(s0)
  80028c:	2d81                	sext.w	s11,s11
  80028e:	846a                	mv	s0,s10
            goto reswitch;
  800290:	bf35                	j	8001cc <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  800292:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  800296:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  80029a:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  80029c:	846a                	mv	s0,s10
            goto process_precision;
  80029e:	bfd9                	j	800274 <vprintfmt+0x114>
    if (lflag >= 2) {
  8002a0:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002a2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002a6:	01174463          	blt	a4,a7,8002ae <vprintfmt+0x14e>
    else if (lflag) {
  8002aa:	1a088e63          	beqz	a7,800466 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  8002ae:	000a3603          	ld	a2,0(s4)
  8002b2:	46c1                	li	a3,16
  8002b4:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002b6:	2781                	sext.w	a5,a5
  8002b8:	876e                	mv	a4,s11
  8002ba:	85a6                	mv	a1,s1
  8002bc:	854a                	mv	a0,s2
  8002be:	e37ff0ef          	jal	ra,8000f4 <printnum>
            break;
  8002c2:	bde1                	j	80019a <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  8002c4:	000a2503          	lw	a0,0(s4)
  8002c8:	85a6                	mv	a1,s1
  8002ca:	0a21                	addi	s4,s4,8
  8002cc:	9902                	jalr	s2
            break;
  8002ce:	b5f1                	j	80019a <vprintfmt+0x3a>
    if (lflag >= 2) {
  8002d0:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002d2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002d6:	01174463          	blt	a4,a7,8002de <vprintfmt+0x17e>
    else if (lflag) {
  8002da:	18088163          	beqz	a7,80045c <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  8002de:	000a3603          	ld	a2,0(s4)
  8002e2:	46a9                	li	a3,10
  8002e4:	8a2e                	mv	s4,a1
  8002e6:	bfc1                	j	8002b6 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  8002e8:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  8002ec:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  8002ee:	846a                	mv	s0,s10
            goto reswitch;
  8002f0:	bdf1                	j	8001cc <vprintfmt+0x6c>
            putch(ch, putdat);
  8002f2:	85a6                	mv	a1,s1
  8002f4:	02500513          	li	a0,37
  8002f8:	9902                	jalr	s2
            break;
  8002fa:	b545                	j	80019a <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  8002fc:	00144603          	lbu	a2,1(s0)
            lflag ++;
  800300:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  800302:	846a                	mv	s0,s10
            goto reswitch;
  800304:	b5e1                	j	8001cc <vprintfmt+0x6c>
    if (lflag >= 2) {
  800306:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800308:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80030c:	01174463          	blt	a4,a7,800314 <vprintfmt+0x1b4>
    else if (lflag) {
  800310:	14088163          	beqz	a7,800452 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  800314:	000a3603          	ld	a2,0(s4)
  800318:	46a1                	li	a3,8
  80031a:	8a2e                	mv	s4,a1
  80031c:	bf69                	j	8002b6 <vprintfmt+0x156>
            putch('0', putdat);
  80031e:	03000513          	li	a0,48
  800322:	85a6                	mv	a1,s1
  800324:	e03e                	sd	a5,0(sp)
  800326:	9902                	jalr	s2
            putch('x', putdat);
  800328:	85a6                	mv	a1,s1
  80032a:	07800513          	li	a0,120
  80032e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800330:	0a21                	addi	s4,s4,8
            goto number;
  800332:	6782                	ld	a5,0(sp)
  800334:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800336:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  80033a:	bfb5                	j	8002b6 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  80033c:	000a3403          	ld	s0,0(s4)
  800340:	008a0713          	addi	a4,s4,8
  800344:	e03a                	sd	a4,0(sp)
  800346:	14040263          	beqz	s0,80048a <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  80034a:	0fb05763          	blez	s11,800438 <vprintfmt+0x2d8>
  80034e:	02d00693          	li	a3,45
  800352:	0cd79163          	bne	a5,a3,800414 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800356:	00044783          	lbu	a5,0(s0)
  80035a:	0007851b          	sext.w	a0,a5
  80035e:	cf85                	beqz	a5,800396 <vprintfmt+0x236>
  800360:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  800364:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800368:	000c4563          	bltz	s8,800372 <vprintfmt+0x212>
  80036c:	3c7d                	addiw	s8,s8,-1
  80036e:	036c0263          	beq	s8,s6,800392 <vprintfmt+0x232>
                    putch('?', putdat);
  800372:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  800374:	0e0c8e63          	beqz	s9,800470 <vprintfmt+0x310>
  800378:	3781                	addiw	a5,a5,-32
  80037a:	0ef47b63          	bgeu	s0,a5,800470 <vprintfmt+0x310>
                    putch('?', putdat);
  80037e:	03f00513          	li	a0,63
  800382:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800384:	000a4783          	lbu	a5,0(s4)
  800388:	3dfd                	addiw	s11,s11,-1
  80038a:	0a05                	addi	s4,s4,1
  80038c:	0007851b          	sext.w	a0,a5
  800390:	ffe1                	bnez	a5,800368 <vprintfmt+0x208>
            for (; width > 0; width --) {
  800392:	01b05963          	blez	s11,8003a4 <vprintfmt+0x244>
  800396:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  800398:	85a6                	mv	a1,s1
  80039a:	02000513          	li	a0,32
  80039e:	9902                	jalr	s2
            for (; width > 0; width --) {
  8003a0:	fe0d9be3          	bnez	s11,800396 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003a4:	6a02                	ld	s4,0(sp)
  8003a6:	bbd5                	j	80019a <vprintfmt+0x3a>
    if (lflag >= 2) {
  8003a8:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8003aa:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  8003ae:	01174463          	blt	a4,a7,8003b6 <vprintfmt+0x256>
    else if (lflag) {
  8003b2:	08088d63          	beqz	a7,80044c <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  8003b6:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  8003ba:	0a044d63          	bltz	s0,800474 <vprintfmt+0x314>
            num = getint(&ap, lflag);
  8003be:	8622                	mv	a2,s0
  8003c0:	8a66                	mv	s4,s9
  8003c2:	46a9                	li	a3,10
  8003c4:	bdcd                	j	8002b6 <vprintfmt+0x156>
            err = va_arg(ap, int);
  8003c6:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003ca:	4761                	li	a4,24
            err = va_arg(ap, int);
  8003cc:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003ce:	41f7d69b          	sraiw	a3,a5,0x1f
  8003d2:	8fb5                	xor	a5,a5,a3
  8003d4:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003d8:	02d74163          	blt	a4,a3,8003fa <vprintfmt+0x29a>
  8003dc:	00369793          	slli	a5,a3,0x3
  8003e0:	97de                	add	a5,a5,s7
  8003e2:	639c                	ld	a5,0(a5)
  8003e4:	cb99                	beqz	a5,8003fa <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  8003e6:	86be                	mv	a3,a5
  8003e8:	00001617          	auipc	a2,0x1
  8003ec:	a6060613          	addi	a2,a2,-1440 # 800e48 <main+0x13e>
  8003f0:	85a6                	mv	a1,s1
  8003f2:	854a                	mv	a0,s2
  8003f4:	0ce000ef          	jal	ra,8004c2 <printfmt>
  8003f8:	b34d                	j	80019a <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  8003fa:	00001617          	auipc	a2,0x1
  8003fe:	a3e60613          	addi	a2,a2,-1474 # 800e38 <main+0x12e>
  800402:	85a6                	mv	a1,s1
  800404:	854a                	mv	a0,s2
  800406:	0bc000ef          	jal	ra,8004c2 <printfmt>
  80040a:	bb41                	j	80019a <vprintfmt+0x3a>
                p = "(null)";
  80040c:	00001417          	auipc	s0,0x1
  800410:	a2440413          	addi	s0,s0,-1500 # 800e30 <main+0x126>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800414:	85e2                	mv	a1,s8
  800416:	8522                	mv	a0,s0
  800418:	e43e                	sd	a5,8(sp)
  80041a:	0c8000ef          	jal	ra,8004e2 <strnlen>
  80041e:	40ad8dbb          	subw	s11,s11,a0
  800422:	01b05b63          	blez	s11,800438 <vprintfmt+0x2d8>
                    putch(padc, putdat);
  800426:	67a2                	ld	a5,8(sp)
  800428:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  80042c:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  80042e:	85a6                	mv	a1,s1
  800430:	8552                	mv	a0,s4
  800432:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  800434:	fe0d9ce3          	bnez	s11,80042c <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800438:	00044783          	lbu	a5,0(s0)
  80043c:	00140a13          	addi	s4,s0,1
  800440:	0007851b          	sext.w	a0,a5
  800444:	d3a5                	beqz	a5,8003a4 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  800446:	05e00413          	li	s0,94
  80044a:	bf39                	j	800368 <vprintfmt+0x208>
        return va_arg(*ap, int);
  80044c:	000a2403          	lw	s0,0(s4)
  800450:	b7ad                	j	8003ba <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  800452:	000a6603          	lwu	a2,0(s4)
  800456:	46a1                	li	a3,8
  800458:	8a2e                	mv	s4,a1
  80045a:	bdb1                	j	8002b6 <vprintfmt+0x156>
  80045c:	000a6603          	lwu	a2,0(s4)
  800460:	46a9                	li	a3,10
  800462:	8a2e                	mv	s4,a1
  800464:	bd89                	j	8002b6 <vprintfmt+0x156>
  800466:	000a6603          	lwu	a2,0(s4)
  80046a:	46c1                	li	a3,16
  80046c:	8a2e                	mv	s4,a1
  80046e:	b5a1                	j	8002b6 <vprintfmt+0x156>
                    putch(ch, putdat);
  800470:	9902                	jalr	s2
  800472:	bf09                	j	800384 <vprintfmt+0x224>
                putch('-', putdat);
  800474:	85a6                	mv	a1,s1
  800476:	02d00513          	li	a0,45
  80047a:	e03e                	sd	a5,0(sp)
  80047c:	9902                	jalr	s2
                num = -(long long)num;
  80047e:	6782                	ld	a5,0(sp)
  800480:	8a66                	mv	s4,s9
  800482:	40800633          	neg	a2,s0
  800486:	46a9                	li	a3,10
  800488:	b53d                	j	8002b6 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  80048a:	03b05163          	blez	s11,8004ac <vprintfmt+0x34c>
  80048e:	02d00693          	li	a3,45
  800492:	f6d79de3          	bne	a5,a3,80040c <vprintfmt+0x2ac>
                p = "(null)";
  800496:	00001417          	auipc	s0,0x1
  80049a:	99a40413          	addi	s0,s0,-1638 # 800e30 <main+0x126>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80049e:	02800793          	li	a5,40
  8004a2:	02800513          	li	a0,40
  8004a6:	00140a13          	addi	s4,s0,1
  8004aa:	bd6d                	j	800364 <vprintfmt+0x204>
  8004ac:	00001a17          	auipc	s4,0x1
  8004b0:	985a0a13          	addi	s4,s4,-1659 # 800e31 <main+0x127>
  8004b4:	02800513          	li	a0,40
  8004b8:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  8004bc:	05e00413          	li	s0,94
  8004c0:	b565                	j	800368 <vprintfmt+0x208>

00000000008004c2 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004c2:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004c4:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004c8:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004ca:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004cc:	ec06                	sd	ra,24(sp)
  8004ce:	f83a                	sd	a4,48(sp)
  8004d0:	fc3e                	sd	a5,56(sp)
  8004d2:	e0c2                	sd	a6,64(sp)
  8004d4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004d6:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004d8:	c89ff0ef          	jal	ra,800160 <vprintfmt>
}
  8004dc:	60e2                	ld	ra,24(sp)
  8004de:	6161                	addi	sp,sp,80
  8004e0:	8082                	ret

00000000008004e2 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  8004e2:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  8004e4:	e589                	bnez	a1,8004ee <strnlen+0xc>
  8004e6:	a811                	j	8004fa <strnlen+0x18>
        cnt ++;
  8004e8:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  8004ea:	00f58863          	beq	a1,a5,8004fa <strnlen+0x18>
  8004ee:	00f50733          	add	a4,a0,a5
  8004f2:	00074703          	lbu	a4,0(a4)
  8004f6:	fb6d                	bnez	a4,8004e8 <strnlen+0x6>
  8004f8:	85be                	mv	a1,a5
    }
    return cnt;
}
  8004fa:	852e                	mv	a0,a1
  8004fc:	8082                	ret

00000000008004fe <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
  8004fe:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
  800500:	0005c703          	lbu	a4,0(a1)
  800504:	0785                	addi	a5,a5,1
  800506:	0585                	addi	a1,a1,1
  800508:	fee78fa3          	sb	a4,-1(a5)
  80050c:	fb75                	bnez	a4,800500 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
  80050e:	8082                	ret

0000000000800510 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
  800510:	ca19                	beqz	a2,800526 <memcpy+0x16>
  800512:	962e                	add	a2,a2,a1
    char *d = dst;
  800514:	87aa                	mv	a5,a0
        *d ++ = *s ++;
  800516:	0005c703          	lbu	a4,0(a1)
  80051a:	0585                	addi	a1,a1,1
  80051c:	0785                	addi	a5,a5,1
  80051e:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
  800522:	fec59ae3          	bne	a1,a2,800516 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
  800526:	8082                	ret

0000000000800528 <test_normal_cow>:
/* 全局标志：模拟竞态条件 */
static volatile int race_flag = 0;
static volatile int attack_success = 0;

/* 测试1：正常COW行为 - 基线测试 */
void test_normal_cow(void) {
  800528:	1101                	addi	sp,sp,-32
    cprintf("\n========== 测试1：正常COW（基线） ==========\n");
  80052a:	00001517          	auipc	a0,0x1
  80052e:	c0650513          	addi	a0,a0,-1018 # 801130 <error_string+0xc8>
void test_normal_cow(void) {
  800532:	ec06                	sd	ra,24(sp)
  800534:	e822                	sd	s0,16(sp)
    cprintf("\n========== 测试1：正常COW（基线） ==========\n");
  800536:	b0bff0ef          	jal	ra,800040 <cprintf>
    
    // 创建只读数据副本
    static char protected_data[PGSIZE];
    memcpy(protected_data, readonly_file_content, PGSIZE);
  80053a:	6605                	lui	a2,0x1
  80053c:	00002597          	auipc	a1,0x2
  800540:	29c58593          	addi	a1,a1,668 # 8027d8 <readonly_file_content>
  800544:	00006517          	auipc	a0,0x6
  800548:	abc50513          	addi	a0,a0,-1348 # 806000 <protected_data.3>
  80054c:	fc5ff0ef          	jal	ra,800510 <memcpy>
    
    cprintf("原始数据: %.50s...\n", protected_data);
  800550:	00006597          	auipc	a1,0x6
  800554:	ab058593          	addi	a1,a1,-1360 # 806000 <protected_data.3>
  800558:	00001517          	auipc	a0,0x1
  80055c:	c1050513          	addi	a0,a0,-1008 # 801168 <error_string+0x100>
  800560:	ae1ff0ef          	jal	ra,800040 <cprintf>
    
    int pid = fork();
  800564:	b7fff0ef          	jal	ra,8000e2 <fork>
    
    if (pid == 0) {
  800568:	c929                	beqz	a0,8005ba <test_normal_cow+0x92>
        
        cprintf("[子进程] 修改后: %.50s...\n", protected_data);
        exit(0);
    } else {
        int exit_code;
        waitpid(pid, &exit_code);
  80056a:	006c                	addi	a1,sp,12
  80056c:	b79ff0ef          	jal	ra,8000e4 <waitpid>
        
        // 父进程验证数据未被修改
        if (protected_data[0] == 'T') {
  800570:	00006417          	auipc	s0,0x6
  800574:	a9040413          	addi	s0,s0,-1392 # 806000 <protected_data.3>
  800578:	00044703          	lbu	a4,0(s0)
  80057c:	05400793          	li	a5,84
  800580:	00f70c63          	beq	a4,a5,800598 <test_normal_cow+0x70>
            cprintf("[父进程] ✓ 数据完整：COW正常工作\n");
            cprintf("[父进程] 内容: %.50s...\n", protected_data);
        } else {
            cprintf("[父进程] ✗ 数据被破坏：COW失败！\n");
  800584:	00001517          	auipc	a0,0x1
  800588:	cb450513          	addi	a0,a0,-844 # 801238 <error_string+0x1d0>
  80058c:	ab5ff0ef          	jal	ra,800040 <cprintf>
        }
    }
}
  800590:	60e2                	ld	ra,24(sp)
  800592:	6442                	ld	s0,16(sp)
  800594:	6105                	addi	sp,sp,32
  800596:	8082                	ret
            cprintf("[父进程] ✓ 数据完整：COW正常工作\n");
  800598:	00001517          	auipc	a0,0x1
  80059c:	c5050513          	addi	a0,a0,-944 # 8011e8 <error_string+0x180>
  8005a0:	aa1ff0ef          	jal	ra,800040 <cprintf>
            cprintf("[父进程] 内容: %.50s...\n", protected_data);
  8005a4:	85a2                	mv	a1,s0
  8005a6:	00001517          	auipc	a0,0x1
  8005aa:	c7250513          	addi	a0,a0,-910 # 801218 <error_string+0x1b0>
  8005ae:	a93ff0ef          	jal	ra,800040 <cprintf>
}
  8005b2:	60e2                	ld	ra,24(sp)
  8005b4:	6442                	ld	s0,16(sp)
  8005b6:	6105                	addi	sp,sp,32
  8005b8:	8082                	ret
        cprintf("[子进程] 尝试修改只读数据...\n");
  8005ba:	00001517          	auipc	a0,0x1
  8005be:	bc650513          	addi	a0,a0,-1082 # 801180 <error_string+0x118>
  8005c2:	a7fff0ef          	jal	ra,800040 <cprintf>
        protected_data[0] = 'X';
  8005c6:	05800793          	li	a5,88
  8005ca:	00006417          	auipc	s0,0x6
  8005ce:	a3640413          	addi	s0,s0,-1482 # 806000 <protected_data.3>
        strcpy(protected_data + 20, "HACKED BY CHILD");
  8005d2:	00001597          	auipc	a1,0x1
  8005d6:	bde58593          	addi	a1,a1,-1058 # 8011b0 <error_string+0x148>
  8005da:	00006517          	auipc	a0,0x6
  8005de:	a3a50513          	addi	a0,a0,-1478 # 806014 <protected_data.3+0x14>
        protected_data[0] = 'X';
  8005e2:	00f40023          	sb	a5,0(s0)
        strcpy(protected_data + 20, "HACKED BY CHILD");
  8005e6:	f19ff0ef          	jal	ra,8004fe <strcpy>
        cprintf("[子进程] 修改后: %.50s...\n", protected_data);
  8005ea:	85a2                	mv	a1,s0
  8005ec:	00001517          	auipc	a0,0x1
  8005f0:	bd450513          	addi	a0,a0,-1068 # 8011c0 <error_string+0x158>
  8005f4:	a4dff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  8005f8:	4501                	li	a0,0
  8005fa:	ad3ff0ef          	jal	ra,8000cc <exit>

00000000008005fe <test_dirtycow_simulation>:
 * 
 * ucore简化模拟：
 * - 用两个进程模拟两个线程的竞态
 * - 通过共享标志位同步
 */
void test_dirtycow_simulation(void) {
  8005fe:	7179                	addi	sp,sp,-48
    cprintf("\n========== 测试2：DirtyCOW竞态模拟 ==========\n");
  800600:	00001517          	auipc	a0,0x1
  800604:	c6850513          	addi	a0,a0,-920 # 801268 <error_string+0x200>
void test_dirtycow_simulation(void) {
  800608:	f406                	sd	ra,40(sp)
  80060a:	f022                	sd	s0,32(sp)
  80060c:	ec26                	sd	s1,24(sp)
    cprintf("\n========== 测试2：DirtyCOW竞态模拟 ==========\n");
  80060e:	a33ff0ef          	jal	ra,800040 <cprintf>
    cprintf("警告：这是简化的教学演示，非真实漏洞利用\n\n");
  800612:	00001517          	auipc	a0,0x1
  800616:	c8e50513          	addi	a0,a0,-882 # 8012a0 <error_string+0x238>
  80061a:	a27ff0ef          	jal	ra,800040 <cprintf>
    
    // 模拟mmap的私有映射
    static char mmap_private[PGSIZE];
    memcpy(mmap_private, readonly_file_content, PGSIZE);
  80061e:	6605                	lui	a2,0x1
  800620:	00002597          	auipc	a1,0x2
  800624:	1b858593          	addi	a1,a1,440 # 8027d8 <readonly_file_content>
  800628:	00004517          	auipc	a0,0x4
  80062c:	9d850513          	addi	a0,a0,-1576 # 804000 <mmap_private.2>
  800630:	ee1ff0ef          	jal	ra,800510 <memcpy>
    
    cprintf("初始内容: %.50s...\n\n", mmap_private);
  800634:	00004597          	auipc	a1,0x4
  800638:	9cc58593          	addi	a1,a1,-1588 # 804000 <mmap_private.2>
  80063c:	00001517          	auipc	a0,0x1
  800640:	ca450513          	addi	a0,a0,-860 # 8012e0 <error_string+0x278>
  800644:	9fdff0ef          	jal	ra,800040 <cprintf>
    
    // Fork创建两个进程模拟竞态
    int pid1 = fork();
  800648:	a9bff0ef          	jal	ra,8000e2 <fork>
    
    if (pid1 == 0) {
  80064c:	10050b63          	beqz	a0,800762 <test_dirtycow_simulation+0x164>
  800650:	84aa                	mv	s1,a0
        cprintf("[madvise进程] 完成100次丢弃操作\n");
        exit(0);
    }
    
    // 父进程继续fork第二个子进程
    int pid2 = fork();
  800652:	a91ff0ef          	jal	ra,8000e2 <fork>
  800656:	842a                	mv	s0,a0
    
    if (pid2 == 0) {
  800658:	c941                	beqz	a0,8006e8 <test_dirtycow_simulation+0xea>
        exit(0);
    }
    
    //===== 父进程：等待并检查结果 =====
    int exit_code;
    waitpid(pid1, &exit_code);
  80065a:	006c                	addi	a1,sp,12
  80065c:	8526                	mv	a0,s1
  80065e:	a87ff0ef          	jal	ra,8000e4 <waitpid>
    cprintf("[父进程] madvise进程退出\n");
  800662:	00001517          	auipc	a0,0x1
  800666:	dee50513          	addi	a0,a0,-530 # 801450 <error_string+0x3e8>
  80066a:	9d7ff0ef          	jal	ra,800040 <cprintf>
    
    waitpid(pid2, &exit_code);
  80066e:	006c                	addi	a1,sp,12
  800670:	8522                	mv	a0,s0
  800672:	a73ff0ef          	jal	ra,8000e4 <waitpid>
    cprintf("[父进程] write进程退出\n");
  800676:	00001517          	auipc	a0,0x1
  80067a:	e0250513          	addi	a0,a0,-510 # 801478 <error_string+0x410>
  80067e:	9c3ff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("\n--- 竞态结果检查 ---\n");
  800682:	00001517          	auipc	a0,0x1
  800686:	e1650513          	addi	a0,a0,-490 # 801498 <error_string+0x430>
  80068a:	9b7ff0ef          	jal	ra,800040 <cprintf>
    if (attack_success) {
  80068e:	00008797          	auipc	a5,0x8
  800692:	9727a783          	lw	a5,-1678(a5) # 808000 <attack_success>
  800696:	ef85                	bnez	a5,8006ce <test_dirtycow_simulation+0xd0>
        cprintf("⚠ 检测到竞态条件触发！\n");
        cprintf("⚠ 在真实DirtyCOW中，这会导致只读文件被修改\n");
    } else {
        cprintf("✓ 未触发竞态条件\n");
  800698:	00001517          	auipc	a0,0x1
  80069c:	e8850513          	addi	a0,a0,-376 # 801520 <error_string+0x4b8>
  8006a0:	9a1ff0ef          	jal	ra,800040 <cprintf>
        cprintf("✓ COW保护有效\n");
  8006a4:	00001517          	auipc	a0,0x1
  8006a8:	e9c50513          	addi	a0,a0,-356 # 801540 <error_string+0x4d8>
  8006ac:	995ff0ef          	jal	ra,800040 <cprintf>
    }
    
    cprintf("\n当前内容: %.50s...\n", mmap_private);
  8006b0:	00004597          	auipc	a1,0x4
  8006b4:	95058593          	addi	a1,a1,-1712 # 804000 <mmap_private.2>
  8006b8:	00001517          	auipc	a0,0x1
  8006bc:	ea050513          	addi	a0,a0,-352 # 801558 <error_string+0x4f0>
  8006c0:	981ff0ef          	jal	ra,800040 <cprintf>
}
  8006c4:	70a2                	ld	ra,40(sp)
  8006c6:	7402                	ld	s0,32(sp)
  8006c8:	64e2                	ld	s1,24(sp)
  8006ca:	6145                	addi	sp,sp,48
  8006cc:	8082                	ret
        cprintf("⚠ 检测到竞态条件触发！\n");
  8006ce:	00001517          	auipc	a0,0x1
  8006d2:	dea50513          	addi	a0,a0,-534 # 8014b8 <error_string+0x450>
  8006d6:	96bff0ef          	jal	ra,800040 <cprintf>
        cprintf("⚠ 在真实DirtyCOW中，这会导致只读文件被修改\n");
  8006da:	00001517          	auipc	a0,0x1
  8006de:	e0650513          	addi	a0,a0,-506 # 8014e0 <error_string+0x478>
  8006e2:	95fff0ef          	jal	ra,800040 <cprintf>
  8006e6:	b7e9                	j	8006b0 <test_dirtycow_simulation+0xb2>
        cprintf("[write进程] 启动，PID=%d\n", getpid());
  8006e8:	9ffff0ef          	jal	ra,8000e6 <getpid>
  8006ec:	85aa                	mv	a1,a0
  8006ee:	00001517          	auipc	a0,0x1
  8006f2:	c9a50513          	addi	a0,a0,-870 # 801388 <error_string+0x320>
  8006f6:	94bff0ef          	jal	ra,800040 <cprintf>
        cprintf("[write进程] 模拟持续写入...\n");
  8006fa:	00001517          	auipc	a0,0x1
  8006fe:	cae50513          	addi	a0,a0,-850 # 8013a8 <error_string+0x340>
  800702:	93fff0ef          	jal	ra,800040 <cprintf>
            if (race_flag == 1) {
  800706:	4485                	li	s1,1
  800708:	00004697          	auipc	a3,0x4
  80070c:	8f868693          	addi	a3,a3,-1800 # 804000 <mmap_private.2>
  800710:	00008617          	auipc	a2,0x8
  800714:	8f460613          	addi	a2,a2,-1804 # 808004 <race_flag>
            mmap_private[i % PGSIZE] = 'W';
  800718:	05700513          	li	a0,87
            for (volatile int delay = 0; delay < 500; delay++);
  80071c:	1f300713          	li	a4,499
        for (int i = 0; i < 100; i++) {
  800720:	06400593          	li	a1,100
            if (race_flag == 1) {
  800724:	421c                	lw	a5,0(a2)
  800726:	2781                	sext.w	a5,a5
  800728:	0a978163          	beq	a5,s1,8007ca <test_dirtycow_simulation+0x1cc>
            for (volatile int delay = 0; delay < 500; delay++);
  80072c:	c602                	sw	zero,12(sp)
  80072e:	47b2                	lw	a5,12(sp)
            mmap_private[i % PGSIZE] = 'W';
  800730:	00a68023          	sb	a0,0(a3)
            for (volatile int delay = 0; delay < 500; delay++);
  800734:	2781                	sext.w	a5,a5
  800736:	00f74963          	blt	a4,a5,800748 <test_dirtycow_simulation+0x14a>
  80073a:	47b2                	lw	a5,12(sp)
  80073c:	2785                	addiw	a5,a5,1
  80073e:	c63e                	sw	a5,12(sp)
  800740:	47b2                	lw	a5,12(sp)
  800742:	2781                	sext.w	a5,a5
  800744:	fef75be3          	bge	a4,a5,80073a <test_dirtycow_simulation+0x13c>
        for (int i = 0; i < 100; i++) {
  800748:	2405                	addiw	s0,s0,1
  80074a:	0685                	addi	a3,a3,1
  80074c:	fcb41ce3          	bne	s0,a1,800724 <test_dirtycow_simulation+0x126>
        cprintf("[write进程] 完成写入操作\n");
  800750:	00001517          	auipc	a0,0x1
  800754:	cd850513          	addi	a0,a0,-808 # 801428 <error_string+0x3c0>
  800758:	8e9ff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  80075c:	4501                	li	a0,0
  80075e:	96fff0ef          	jal	ra,8000cc <exit>
        cprintf("[madvise进程] 启动，PID=%d\n", getpid());
  800762:	985ff0ef          	jal	ra,8000e6 <getpid>
  800766:	85aa                	mv	a1,a0
  800768:	00001517          	auipc	a0,0x1
  80076c:	b9850513          	addi	a0,a0,-1128 # 801300 <error_string+0x298>
  800770:	8d1ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[madvise进程] 模拟持续丢弃页面...\n");
  800774:	00001517          	auipc	a0,0x1
  800778:	bb450513          	addi	a0,a0,-1100 # 801328 <error_string+0x2c0>
  80077c:	8c5ff0ef          	jal	ra,800040 <cprintf>
  800780:	06400693          	li	a3,100
  800784:	00008617          	auipc	a2,0x8
  800788:	88060613          	addi	a2,a2,-1920 # 808004 <race_flag>
            race_flag = 1;  // 通知write线程：页面已丢弃
  80078c:	4585                	li	a1,1
            for (volatile int delay = 0; delay < 1000; delay++);
  80078e:	3e700713          	li	a4,999
            race_flag = 1;  // 通知write线程：页面已丢弃
  800792:	c20c                	sw	a1,0(a2)
            for (volatile int delay = 0; delay < 1000; delay++);
  800794:	c602                	sw	zero,12(sp)
  800796:	47b2                	lw	a5,12(sp)
  800798:	2781                	sext.w	a5,a5
  80079a:	00f74963          	blt	a4,a5,8007ac <test_dirtycow_simulation+0x1ae>
  80079e:	47b2                	lw	a5,12(sp)
  8007a0:	2785                	addiw	a5,a5,1
  8007a2:	c63e                	sw	a5,12(sp)
  8007a4:	47b2                	lw	a5,12(sp)
  8007a6:	2781                	sext.w	a5,a5
  8007a8:	fef75be3          	bge	a4,a5,80079e <test_dirtycow_simulation+0x1a0>
            race_flag = 0;
  8007ac:	00008797          	auipc	a5,0x8
  8007b0:	8407ac23          	sw	zero,-1960(a5) # 808004 <race_flag>
        for (int i = 0; i < 100; i++) {
  8007b4:	36fd                	addiw	a3,a3,-1
  8007b6:	fef1                	bnez	a3,800792 <test_dirtycow_simulation+0x194>
        cprintf("[madvise进程] 完成100次丢弃操作\n");
  8007b8:	00001517          	auipc	a0,0x1
  8007bc:	ba050513          	addi	a0,a0,-1120 # 801358 <error_string+0x2f0>
  8007c0:	881ff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  8007c4:	4501                	li	a0,0
  8007c6:	907ff0ef          	jal	ra,8000cc <exit>
                cprintf("[write进程] !!! 检测到竞态窗口（迭代%d）\n", i);
  8007ca:	85a2                	mv	a1,s0
  8007cc:	00001517          	auipc	a0,0x1
  8007d0:	c0450513          	addi	a0,a0,-1020 # 8013d0 <error_string+0x368>
  8007d4:	86dff0ef          	jal	ra,800040 <cprintf>
                memcpy(mmap_private, "HACKED DATA - VULNERABLE!", 25);
  8007d8:	4665                	li	a2,25
  8007da:	00001597          	auipc	a1,0x1
  8007de:	c2e58593          	addi	a1,a1,-978 # 801408 <error_string+0x3a0>
  8007e2:	00004517          	auipc	a0,0x4
  8007e6:	81e50513          	addi	a0,a0,-2018 # 804000 <mmap_private.2>
  8007ea:	d27ff0ef          	jal	ra,800510 <memcpy>
                attack_success = 1;
  8007ee:	00008797          	auipc	a5,0x8
  8007f2:	8097a923          	sw	s1,-2030(a5) # 808000 <attack_success>
                break;
  8007f6:	bfa9                	j	800750 <test_dirtycow_simulation+0x152>

00000000008007f8 <test_dirtycow_protection>:

/* 测试3：DirtyCOW防护措施验证 */
void test_dirtycow_protection(void) {
  8007f8:	1141                	addi	sp,sp,-16
    cprintf("\n========== 测试3：DirtyCOW防护措施 ==========\n");
  8007fa:	00001517          	auipc	a0,0x1
  8007fe:	d7e50513          	addi	a0,a0,-642 # 801578 <error_string+0x510>
void test_dirtycow_protection(void) {
  800802:	e406                	sd	ra,8(sp)
  800804:	e022                	sd	s0,0(sp)
    cprintf("\n========== 测试3：DirtyCOW防护措施 ==========\n");
  800806:	83bff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("DirtyCOW漏洞的关键防护措施：\n\n");
  80080a:	00001517          	auipc	a0,0x1
  80080e:	da650513          	addi	a0,a0,-602 # 8015b0 <error_string+0x548>
  800812:	82fff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("1. 内核补丁（已修复）：\n");
  800816:	00001517          	auipc	a0,0x1
  80081a:	dca50513          	addi	a0,a0,-566 # 8015e0 <error_string+0x578>
  80081e:	823ff0ef          	jal	ra,800040 <cprintf>
    cprintf("   - Linux 4.8.3+ 已修复此漏洞\n");
  800822:	00001517          	auipc	a0,0x1
  800826:	de650513          	addi	a0,a0,-538 # 801608 <error_string+0x5a0>
  80082a:	817ff0ef          	jal	ra,800040 <cprintf>
    cprintf("   - 修复方法：在do_fault中检查VM_FAULT_WRITE标志\n");
  80082e:	00001517          	auipc	a0,0x1
  800832:	e0250513          	addi	a0,a0,-510 # 801630 <error_string+0x5c8>
  800836:	80bff0ef          	jal	ra,800040 <cprintf>
    cprintf("   - 确保COW的页面不会被错误地标记为dirty\n\n");
  80083a:	00001517          	auipc	a0,0x1
  80083e:	e3650513          	addi	a0,a0,-458 # 801670 <error_string+0x608>
  800842:	ffeff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("2. madvise系统调用改进：\n");
  800846:	00001517          	auipc	a0,0x1
  80084a:	e6a50513          	addi	a0,a0,-406 # 8016b0 <error_string+0x648>
  80084e:	ff2ff0ef          	jal	ra,800040 <cprintf>
    cprintf("   - MADV_DONTNEED现在会检查页面的可写属性\n");
  800852:	00001517          	auipc	a0,0x1
  800856:	e8650513          	addi	a0,a0,-378 # 8016d8 <error_string+0x670>
  80085a:	fe6ff0ef          	jal	ra,800040 <cprintf>
    cprintf("   - 只读映射不允许被MADV_DONTNEED影响\n\n");
  80085e:	00001517          	auipc	a0,0x1
  800862:	eb250513          	addi	a0,a0,-334 # 801710 <error_string+0x6a8>
  800866:	fdaff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("3. 页表操作原子性：\n");
  80086a:	00001517          	auipc	a0,0x1
  80086e:	ede50513          	addi	a0,a0,-290 # 801748 <error_string+0x6e0>
  800872:	fceff0ef          	jal	ra,800040 <cprintf>
    cprintf("   - 使用锁保护页表项的修改\n");
  800876:	00001517          	auipc	a0,0x1
  80087a:	ef250513          	addi	a0,a0,-270 # 801768 <error_string+0x700>
  80087e:	fc2ff0ef          	jal	ra,800040 <cprintf>
    cprintf("   - 防止竞态条件窗口\n\n");
  800882:	00001517          	auipc	a0,0x1
  800886:	f0e50513          	addi	a0,a0,-242 # 801790 <error_string+0x728>
  80088a:	fb6ff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("4. ucore中的保护措施：\n");
  80088e:	00001517          	auipc	a0,0x1
  800892:	f2250513          	addi	a0,a0,-222 # 8017b0 <error_string+0x748>
  800896:	faaff0ef          	jal	ra,800040 <cprintf>
    cprintf("   - 检查PTE_W标志位\n");
  80089a:	00001517          	auipc	a0,0x1
  80089e:	f3650513          	addi	a0,a0,-202 # 8017d0 <error_string+0x768>
  8008a2:	f9eff0ef          	jal	ra,800040 <cprintf>
    cprintf("   - COW页面标记PTE_COW，不标记PTE_W\n");
  8008a6:	00001517          	auipc	a0,0x1
  8008aa:	f4a50513          	addi	a0,a0,-182 # 8017f0 <error_string+0x788>
  8008ae:	f92ff0ef          	jal	ra,800040 <cprintf>
    cprintf("   - 在do_pgfault中验证写权限\n\n");
  8008b2:	00001517          	auipc	a0,0x1
  8008b6:	f6e50513          	addi	a0,a0,-146 # 801820 <error_string+0x7b8>
  8008ba:	f86ff0ef          	jal	ra,800040 <cprintf>
    
    // 模拟保护措施
    static char protected[PGSIZE];
    memcpy(protected, "PROTECTED DATA", 15);
  8008be:	463d                	li	a2,15
  8008c0:	00001597          	auipc	a1,0x1
  8008c4:	f8858593          	addi	a1,a1,-120 # 801848 <error_string+0x7e0>
  8008c8:	00004517          	auipc	a0,0x4
  8008cc:	73850513          	addi	a0,a0,1848 # 805000 <protected.1>
  8008d0:	c41ff0ef          	jal	ra,800510 <memcpy>
    
    int pid = fork();
  8008d4:	80fff0ef          	jal	ra,8000e2 <fork>
    if (pid == 0) {
  8008d8:	c90d                	beqz	a0,80090a <test_dirtycow_protection+0x112>
        
        cprintf("[子进程] 写入完成（触发了COW）\n");
        cprintf("[子进程] 数据: %s\n", protected);
        exit(0);
    } else {
        waitpid(pid, NULL);
  8008da:	4581                	li	a1,0
  8008dc:	809ff0ef          	jal	ra,8000e4 <waitpid>
        
        if (protected[0] == 'P') {
  8008e0:	00004717          	auipc	a4,0x4
  8008e4:	72074703          	lbu	a4,1824(a4) # 805000 <protected.1>
  8008e8:	05000793          	li	a5,80
            cprintf("\n✓ 保护措施有效：父进程数据未被修改\n");
  8008ec:	00001517          	auipc	a0,0x1
  8008f0:	fdc50513          	addi	a0,a0,-36 # 8018c8 <error_string+0x860>
        if (protected[0] == 'P') {
  8008f4:	00f70663          	beq	a4,a5,800900 <test_dirtycow_protection+0x108>
        } else {
            cprintf("\n✗ 保护措施失败！\n");
  8008f8:	00001517          	auipc	a0,0x1
  8008fc:	00850513          	addi	a0,a0,8 # 801900 <error_string+0x898>
        }
    }
}
  800900:	6402                	ld	s0,0(sp)
  800902:	60a2                	ld	ra,8(sp)
  800904:	0141                	addi	sp,sp,16
            cprintf("\n✗ 保护措施失败！\n");
  800906:	f3aff06f          	j	800040 <cprintf>
        cprintf("[子进程] 尝试绕过COW写入...\n");
  80090a:	00001517          	auipc	a0,0x1
  80090e:	f4e50513          	addi	a0,a0,-178 # 801858 <error_string+0x7f0>
  800912:	f2eff0ef          	jal	ra,800040 <cprintf>
        protected[0] = 'X';
  800916:	05800793          	li	a5,88
  80091a:	00004417          	auipc	s0,0x4
  80091e:	6e640413          	addi	s0,s0,1766 # 805000 <protected.1>
        cprintf("[子进程] 写入完成（触发了COW）\n");
  800922:	00001517          	auipc	a0,0x1
  800926:	f5e50513          	addi	a0,a0,-162 # 801880 <error_string+0x818>
        protected[0] = 'X';
  80092a:	00f40023          	sb	a5,0(s0)
        cprintf("[子进程] 写入完成（触发了COW）\n");
  80092e:	f12ff0ef          	jal	ra,800040 <cprintf>
        cprintf("[子进程] 数据: %s\n", protected);
  800932:	85a2                	mv	a1,s0
  800934:	00001517          	auipc	a0,0x1
  800938:	f7c50513          	addi	a0,a0,-132 # 8018b0 <error_string+0x848>
  80093c:	f04ff0ef          	jal	ra,800040 <cprintf>
        exit(0);
  800940:	4501                	li	a0,0
  800942:	f8aff0ef          	jal	ra,8000cc <exit>

0000000000800946 <test_race_amplification>:

/* 测试4：多进程竞态放大 */
void test_race_amplification(void) {
  800946:	715d                	addi	sp,sp,-80
    cprintf("\n========== 测试4：多进程竞态放大 ==========\n");
  800948:	00001517          	auipc	a0,0x1
  80094c:	fd850513          	addi	a0,a0,-40 # 801920 <error_string+0x8b8>
void test_race_amplification(void) {
  800950:	e486                	sd	ra,72(sp)
  800952:	e0a2                	sd	s0,64(sp)
  800954:	fc26                	sd	s1,56(sp)
  800956:	f84a                	sd	s2,48(sp)
  800958:	f44e                	sd	s3,40(sp)
    cprintf("\n========== 测试4：多进程竞态放大 ==========\n");
  80095a:	ee6ff0ef          	jal	ra,800040 <cprintf>
    cprintf("创建多个进程尝试触发竞态条件...\n\n");
  80095e:	00001517          	auipc	a0,0x1
  800962:	ffa50513          	addi	a0,a0,-6 # 801958 <error_string+0x8f0>
  800966:	edaff0ef          	jal	ra,800040 <cprintf>
    
    static char race_buffer[PGSIZE];
    memcpy(race_buffer, "Original shared data", 21);
  80096a:	4655                	li	a2,21
  80096c:	00001597          	auipc	a1,0x1
  800970:	01c58593          	addi	a1,a1,28 # 801988 <error_string+0x920>
  800974:	00006517          	auipc	a0,0x6
  800978:	68c50513          	addi	a0,a0,1676 # 807000 <race_buffer.0>
  80097c:	0020                	addi	s0,sp,8
  80097e:	b93ff0ef          	jal	ra,800510 <memcpy>
  800982:	8922                	mv	s2,s0
    
    // 创建多个子进程增加竞态概率
    int pids[5];
    
    for (int i = 0; i < 5; i++) {
  800984:	4481                	li	s1,0
  800986:	4995                	li	s3,5
        int pid = fork();
  800988:	f5aff0ef          	jal	ra,8000e2 <fork>
        
        if (pid == 0) {
  80098c:	c93d                	beqz	a0,800a02 <test_race_amplification+0xbc>
            }
            
            cprintf("[竞态进程%d] 完成\n", i);
            exit(i);
        } else {
            pids[i] = pid;
  80098e:	00a92023          	sw	a0,0(s2)
    for (int i = 0; i < 5; i++) {
  800992:	2485                	addiw	s1,s1,1
  800994:	0911                	addi	s2,s2,4
  800996:	ff3499e3          	bne	s1,s3,800988 <test_race_amplification+0x42>
        }
    }
    
    // 父进程也参与写入
    cprintf("[父进程] 同时写入\n");
  80099a:	00001517          	auipc	a0,0x1
  80099e:	04650513          	addi	a0,a0,70 # 8019e0 <error_string+0x978>
  8009a2:	e9eff0ef          	jal	ra,800040 <cprintf>
    for (int i = 0; i < 50; i++) {
  8009a6:	00006797          	auipc	a5,0x6
  8009aa:	65a78793          	addi	a5,a5,1626 # 807000 <race_buffer.0>
  8009ae:	00006697          	auipc	a3,0x6
  8009b2:	68468693          	addi	a3,a3,1668 # 807032 <race_buffer.0+0x32>
        race_buffer[i % PGSIZE] = 'P';
  8009b6:	05000713          	li	a4,80
  8009ba:	00e78023          	sb	a4,0(a5)
    for (int i = 0; i < 50; i++) {
  8009be:	0785                	addi	a5,a5,1
  8009c0:	fed79de3          	bne	a5,a3,8009ba <test_race_amplification+0x74>
  8009c4:	01440493          	addi	s1,s0,20
    }
    
    // 等待所有子进程
    for (int i = 0; i < 5; i++) {
        waitpid(pids[i], NULL);
  8009c8:	4008                	lw	a0,0(s0)
  8009ca:	4581                	li	a1,0
    for (int i = 0; i < 5; i++) {
  8009cc:	0411                	addi	s0,s0,4
        waitpid(pids[i], NULL);
  8009ce:	f16ff0ef          	jal	ra,8000e4 <waitpid>
    for (int i = 0; i < 5; i++) {
  8009d2:	fe941be3          	bne	s0,s1,8009c8 <test_race_amplification+0x82>
    }
    
    cprintf("\n✓ 测试4完成：验证了多进程COW隔离\n");
  8009d6:	00001517          	auipc	a0,0x1
  8009da:	02a50513          	addi	a0,a0,42 # 801a00 <error_string+0x998>
  8009de:	e62ff0ef          	jal	ra,800040 <cprintf>
    cprintf("父进程数据: %.20s...\n", race_buffer);
}
  8009e2:	6406                	ld	s0,64(sp)
  8009e4:	60a6                	ld	ra,72(sp)
  8009e6:	74e2                	ld	s1,56(sp)
  8009e8:	7942                	ld	s2,48(sp)
  8009ea:	79a2                	ld	s3,40(sp)
    cprintf("父进程数据: %.20s...\n", race_buffer);
  8009ec:	00006597          	auipc	a1,0x6
  8009f0:	61458593          	addi	a1,a1,1556 # 807000 <race_buffer.0>
  8009f4:	00001517          	auipc	a0,0x1
  8009f8:	04450513          	addi	a0,a0,68 # 801a38 <error_string+0x9d0>
}
  8009fc:	6161                	addi	sp,sp,80
    cprintf("父进程数据: %.20s...\n", race_buffer);
  8009fe:	e42ff06f          	j	800040 <cprintf>
            cprintf("[竞态进程%d] 开始写入\n", i);
  800a02:	85a6                	mv	a1,s1
  800a04:	00001517          	auipc	a0,0x1
  800a08:	f9c50513          	addi	a0,a0,-100 # 8019a0 <error_string+0x938>
  800a0c:	e34ff0ef          	jal	ra,800040 <cprintf>
                for (volatile int d = 0; d < (i * 100); d++);
  800a10:	06400713          	li	a4,100
  800a14:	0297073b          	mulw	a4,a4,s1
                race_buffer[j % PGSIZE] = '0' + i;
  800a18:	0304861b          	addiw	a2,s1,48
  800a1c:	0ff67613          	zext.b	a2,a2
  800a20:	00006697          	auipc	a3,0x6
  800a24:	5e068693          	addi	a3,a3,1504 # 807000 <race_buffer.0>
  800a28:	00006597          	auipc	a1,0x6
  800a2c:	60a58593          	addi	a1,a1,1546 # 807032 <race_buffer.0+0x32>
                for (volatile int d = 0; d < (i * 100); d++);
  800a30:	c202                	sw	zero,4(sp)
  800a32:	4792                	lw	a5,4(sp)
                race_buffer[j % PGSIZE] = '0' + i;
  800a34:	00c68023          	sb	a2,0(a3)
                for (volatile int d = 0; d < (i * 100); d++);
  800a38:	2781                	sext.w	a5,a5
  800a3a:	00e7d963          	bge	a5,a4,800a4c <test_race_amplification+0x106>
  800a3e:	4792                	lw	a5,4(sp)
  800a40:	2785                	addiw	a5,a5,1
  800a42:	c23e                	sw	a5,4(sp)
  800a44:	4792                	lw	a5,4(sp)
  800a46:	2781                	sext.w	a5,a5
  800a48:	fee7cbe3          	blt	a5,a4,800a3e <test_race_amplification+0xf8>
            for (int j = 0; j < 50; j++) {
  800a4c:	0685                	addi	a3,a3,1
  800a4e:	feb691e3          	bne	a3,a1,800a30 <test_race_amplification+0xea>
            cprintf("[竞态进程%d] 完成\n", i);
  800a52:	85a6                	mv	a1,s1
  800a54:	00001517          	auipc	a0,0x1
  800a58:	f6c50513          	addi	a0,a0,-148 # 8019c0 <error_string+0x958>
  800a5c:	de4ff0ef          	jal	ra,800040 <cprintf>
            exit(i);
  800a60:	8526                	mv	a0,s1
  800a62:	e6aff0ef          	jal	ra,8000cc <exit>

0000000000800a66 <test_timing_window>:

/* 测试5：时间窗口分析 */
void test_timing_window(void) {
  800a66:	1141                	addi	sp,sp,-16
    cprintf("\n========== 测试5：竞态时间窗口分析 ==========\n");
  800a68:	00001517          	auipc	a0,0x1
  800a6c:	ff050513          	addi	a0,a0,-16 # 801a58 <error_string+0x9f0>
void test_timing_window(void) {
  800a70:	e406                	sd	ra,8(sp)
    cprintf("\n========== 测试5：竞态时间窗口分析 ==========\n");
  800a72:	dceff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("DirtyCOW竞态窗口分析：\n\n");
  800a76:	00001517          	auipc	a0,0x1
  800a7a:	02250513          	addi	a0,a0,34 # 801a98 <error_string+0xa30>
  800a7e:	dc2ff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("时序图：\n");
  800a82:	00001517          	auipc	a0,0x1
  800a86:	03650513          	addi	a0,a0,54 # 801ab8 <error_string+0xa50>
  800a8a:	db6ff0ef          	jal	ra,800040 <cprintf>
    cprintf("Thread 1 (madvise)        Thread 2 (write)\n");
  800a8e:	00001517          	auipc	a0,0x1
  800a92:	03a50513          	addi	a0,a0,58 # 801ac8 <error_string+0xa60>
  800a96:	daaff0ef          	jal	ra,800040 <cprintf>
    cprintf("==================        ================\n");
  800a9a:	00001517          	auipc	a0,0x1
  800a9e:	05e50513          	addi	a0,a0,94 # 801af8 <error_string+0xa90>
  800aa2:	d9eff0ef          	jal	ra,800040 <cprintf>
    cprintf("madvise(MADV_DONTNEED)\n");
  800aa6:	00001517          	auipc	a0,0x1
  800aaa:	08250513          	addi	a0,a0,130 # 801b28 <error_string+0xac0>
  800aae:	d92ff0ef          	jal	ra,800040 <cprintf>
    cprintf("  ↓\n");
  800ab2:	00001517          	auipc	a0,0x1
  800ab6:	08e50513          	addi	a0,a0,142 # 801b40 <error_string+0xad8>
  800aba:	d86ff0ef          	jal	ra,800040 <cprintf>
    cprintf("清除PTE\n");
  800abe:	00001517          	auipc	a0,0x1
  800ac2:	08a50513          	addi	a0,a0,138 # 801b48 <error_string+0xae0>
  800ac6:	d7aff0ef          	jal	ra,800040 <cprintf>
    cprintf("  ↓                       write()\n");
  800aca:	00001517          	auipc	a0,0x1
  800ace:	08e50513          	addi	a0,a0,142 # 801b58 <error_string+0xaf0>
  800ad2:	d6eff0ef          	jal	ra,800040 <cprintf>
    cprintf("  |                         ↓\n");
  800ad6:	00001517          	auipc	a0,0x1
  800ada:	0aa50513          	addi	a0,a0,170 # 801b80 <error_string+0xb18>
  800ade:	d62ff0ef          	jal	ra,800040 <cprintf>
    cprintf("  |                       检查PTE（已清除）\n");
  800ae2:	00001517          	auipc	a0,0x1
  800ae6:	0c650513          	addi	a0,a0,198 # 801ba8 <error_string+0xb40>
  800aea:	d56ff0ef          	jal	ra,800040 <cprintf>
    cprintf("  |                         ↓\n");
  800aee:	00001517          	auipc	a0,0x1
  800af2:	09250513          	addi	a0,a0,146 # 801b80 <error_string+0xb18>
  800af6:	d4aff0ef          	jal	ra,800040 <cprintf>
    cprintf("[竞态窗口]                 触发page fault\n");
  800afa:	00001517          	auipc	a0,0x1
  800afe:	0e650513          	addi	a0,a0,230 # 801be0 <error_string+0xb78>
  800b02:	d3eff0ef          	jal	ra,800040 <cprintf>
    cprintf("  |                         ↓\n");
  800b06:	00001517          	auipc	a0,0x1
  800b0a:	07a50513          	addi	a0,a0,122 # 801b80 <error_string+0xb18>
  800b0e:	d32ff0ef          	jal	ra,800040 <cprintf>
    cprintf("  |                       分配新页面\n");
  800b12:	00001517          	auipc	a0,0x1
  800b16:	10650513          	addi	a0,a0,262 # 801c18 <error_string+0xbb0>
  800b1a:	d26ff0ef          	jal	ra,800040 <cprintf>
    cprintf("  ↓                         ↓\n");
  800b1e:	00001517          	auipc	a0,0x1
  800b22:	12a50513          	addi	a0,a0,298 # 801c48 <error_string+0xbe0>
  800b26:	d1aff0ef          	jal	ra,800040 <cprintf>
    cprintf("返回                      写入数据 <-- 可能写到原页面！\n");
  800b2a:	00001517          	auipc	a0,0x1
  800b2e:	14650513          	addi	a0,a0,326 # 801c70 <error_string+0xc08>
  800b32:	d0eff0ef          	jal	ra,800040 <cprintf>
    cprintf("重新映射原文件              ↓\n");
  800b36:	00001517          	auipc	a0,0x1
  800b3a:	18250513          	addi	a0,a0,386 # 801cb8 <error_string+0xc50>
  800b3e:	d02ff0ef          	jal	ra,800040 <cprintf>
    cprintf("                          返回\n\n");
  800b42:	00001517          	auipc	a0,0x1
  800b46:	19e50513          	addi	a0,a0,414 # 801ce0 <error_string+0xc78>
  800b4a:	cf6ff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("关键点：\n");
  800b4e:	00001517          	auipc	a0,0x1
  800b52:	1ba50513          	addi	a0,a0,442 # 801d08 <error_string+0xca0>
  800b56:	ceaff0ef          	jal	ra,800040 <cprintf>
    cprintf("1. madvise清除PTE后，页面暂时无效\n");
  800b5a:	00001517          	auipc	a0,0x1
  800b5e:	1be50513          	addi	a0,a0,446 # 801d18 <error_string+0xcb0>
  800b62:	cdeff0ef          	jal	ra,800040 <cprintf>
    cprintf("2. write检测到PTE无效，触发page fault\n");
  800b66:	00001517          	auipc	a0,0x1
  800b6a:	1e250513          	addi	a0,a0,482 # 801d48 <error_string+0xce0>
  800b6e:	cd2ff0ef          	jal	ra,800040 <cprintf>
    cprintf("3. 如果page fault在重新映射前完成写入\n");
  800b72:	00001517          	auipc	a0,0x1
  800b76:	20650513          	addi	a0,a0,518 # 801d78 <error_string+0xd10>
  800b7a:	cc6ff0ef          	jal	ra,800040 <cprintf>
    cprintf("4. 写操作可能直接写到原只读页面\n");
  800b7e:	00001517          	auipc	a0,0x1
  800b82:	23250513          	addi	a0,a0,562 # 801db0 <error_string+0xd48>
  800b86:	cbaff0ef          	jal	ra,800040 <cprintf>
    cprintf("5. 导致只读文件被修改\n\n");
  800b8a:	00001517          	auipc	a0,0x1
  800b8e:	25650513          	addi	a0,a0,598 # 801de0 <error_string+0xd78>
  800b92:	caeff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("✓ 时序分析完成\n");
}
  800b96:	60a2                	ld	ra,8(sp)
    cprintf("✓ 时序分析完成\n");
  800b98:	00001517          	auipc	a0,0x1
  800b9c:	27050513          	addi	a0,a0,624 # 801e08 <error_string+0xda0>
}
  800ba0:	0141                	addi	sp,sp,16
    cprintf("✓ 时序分析完成\n");
  800ba2:	c9eff06f          	j	800040 <cprintf>

0000000000800ba6 <print_vulnerability_info>:

/* 打印漏洞信息和缓解措施 */
void print_vulnerability_info(void) {
  800ba6:	1141                	addi	sp,sp,-16
    cprintf("\n╔════════════════════════════════════════════════════╗\n");
  800ba8:	00001517          	auipc	a0,0x1
  800bac:	27850513          	addi	a0,a0,632 # 801e20 <error_string+0xdb8>
void print_vulnerability_info(void) {
  800bb0:	e406                	sd	ra,8(sp)
    cprintf("\n╔════════════════════════════════════════════════════╗\n");
  800bb2:	c8eff0ef          	jal	ra,800040 <cprintf>
    cprintf("║          DirtyCOW 漏洞详细信息                    ║\n");
  800bb6:	00001517          	auipc	a0,0x1
  800bba:	31250513          	addi	a0,a0,786 # 801ec8 <error_string+0xe60>
  800bbe:	c82ff0ef          	jal	ra,800040 <cprintf>
    cprintf("╚════════════════════════════════════════════════════╝\n\n");
  800bc2:	00001517          	auipc	a0,0x1
  800bc6:	34e50513          	addi	a0,a0,846 # 801f10 <error_string+0xea8>
  800bca:	c76ff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("漏洞编号：CVE-2016-5195\n");
  800bce:	00001517          	auipc	a0,0x1
  800bd2:	3ea50513          	addi	a0,a0,1002 # 801fb8 <error_string+0xf50>
  800bd6:	c6aff0ef          	jal	ra,800040 <cprintf>
    cprintf("漏洞名称：Dirty COW (Copy-On-Write)\n");
  800bda:	00001517          	auipc	a0,0x1
  800bde:	3fe50513          	addi	a0,a0,1022 # 801fd8 <error_string+0xf70>
  800be2:	c5eff0ef          	jal	ra,800040 <cprintf>
    cprintf("影响版本：Linux Kernel 2.6.22 - 4.8.3\n");
  800be6:	00001517          	auipc	a0,0x1
  800bea:	42250513          	addi	a0,a0,1058 # 802008 <error_string+0xfa0>
  800bee:	c52ff0ef          	jal	ra,800040 <cprintf>
    cprintf("危险等级：高危（CVSS 7.8）\n\n");
  800bf2:	00001517          	auipc	a0,0x1
  800bf6:	44650513          	addi	a0,a0,1094 # 802038 <error_string+0xfd0>
  800bfa:	c46ff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("漏洞影响：\n");
  800bfe:	00001517          	auipc	a0,0x1
  800c02:	46250513          	addi	a0,a0,1122 # 802060 <error_string+0xff8>
  800c06:	c3aff0ef          	jal	ra,800040 <cprintf>
    cprintf("• 本地权限提升\n");
  800c0a:	00001517          	auipc	a0,0x1
  800c0e:	46e50513          	addi	a0,a0,1134 # 802078 <error_string+0x1010>
  800c12:	c2eff0ef          	jal	ra,800040 <cprintf>
    cprintf("• 修改只读文件（如/etc/passwd）\n");
  800c16:	00001517          	auipc	a0,0x1
  800c1a:	47a50513          	addi	a0,a0,1146 # 802090 <error_string+0x1028>
  800c1e:	c22ff0ef          	jal	ra,800040 <cprintf>
    cprintf("• 绕过文件权限检查\n");
  800c22:	00001517          	auipc	a0,0x1
  800c26:	49e50513          	addi	a0,a0,1182 # 8020c0 <error_string+0x1058>
  800c2a:	c16ff0ef          	jal	ra,800040 <cprintf>
    cprintf("• 容器逃逸\n\n");
  800c2e:	00001517          	auipc	a0,0x1
  800c32:	4b250513          	addi	a0,a0,1202 # 8020e0 <error_string+0x1078>
  800c36:	c0aff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("攻击场景示例：\n");
  800c3a:	00001517          	auipc	a0,0x1
  800c3e:	4be50513          	addi	a0,a0,1214 # 8020f8 <error_string+0x1090>
  800c42:	bfeff0ef          	jal	ra,800040 <cprintf>
    cprintf("1. 攻击者以普通用户身份运行\n");
  800c46:	00001517          	auipc	a0,0x1
  800c4a:	4ca50513          	addi	a0,a0,1226 # 802110 <error_string+0x10a8>
  800c4e:	bf2ff0ef          	jal	ra,800040 <cprintf>
    cprintf("2. 映射/etc/passwd为只读\n");
  800c52:	00001517          	auipc	a0,0x1
  800c56:	4ee50513          	addi	a0,a0,1262 # 802140 <error_string+0x10d8>
  800c5a:	be6ff0ef          	jal	ra,800040 <cprintf>
    cprintf("3. Fork子进程（触发COW）\n");
  800c5e:	00001517          	auipc	a0,0x1
  800c62:	50250513          	addi	a0,a0,1282 # 802160 <error_string+0x10f8>
  800c66:	bdaff0ef          	jal	ra,800040 <cprintf>
    cprintf("4. 利用竞态条件修改/etc/passwd\n");
  800c6a:	00001517          	auipc	a0,0x1
  800c6e:	51e50513          	addi	a0,a0,1310 # 802188 <error_string+0x1120>
  800c72:	bceff0ef          	jal	ra,800040 <cprintf>
    cprintf("5. 添加root权限账户\n");
  800c76:	00001517          	auipc	a0,0x1
  800c7a:	53a50513          	addi	a0,a0,1338 # 8021b0 <error_string+0x1148>
  800c7e:	bc2ff0ef          	jal	ra,800040 <cprintf>
    cprintf("6. 获得系统管理员权限\n\n");
  800c82:	00001517          	auipc	a0,0x1
  800c86:	54e50513          	addi	a0,a0,1358 # 8021d0 <error_string+0x1168>
  800c8a:	bb6ff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("缓解措施：\n");
  800c8e:	00001517          	auipc	a0,0x1
  800c92:	56a50513          	addi	a0,a0,1386 # 8021f8 <error_string+0x1190>
  800c96:	baaff0ef          	jal	ra,800040 <cprintf>
    cprintf("✓ 升级内核至4.8.3+\n");
  800c9a:	00001517          	auipc	a0,0x1
  800c9e:	57650513          	addi	a0,a0,1398 # 802210 <error_string+0x11a8>
  800ca2:	b9eff0ef          	jal	ra,800040 <cprintf>
    cprintf("✓ 应用安全补丁\n");
  800ca6:	00001517          	auipc	a0,0x1
  800caa:	58a50513          	addi	a0,a0,1418 # 802230 <error_string+0x11c8>
  800cae:	b92ff0ef          	jal	ra,800040 <cprintf>
    cprintf("✓ 使用SELinux/AppArmor限制\n");
  800cb2:	00001517          	auipc	a0,0x1
  800cb6:	59650513          	addi	a0,a0,1430 # 802248 <error_string+0x11e0>
  800cba:	b86ff0ef          	jal	ra,800040 <cprintf>
    cprintf("✓ 监控异常madvise调用\n\n");
  800cbe:	00001517          	auipc	a0,0x1
  800cc2:	5b250513          	addi	a0,a0,1458 # 802270 <error_string+0x1208>
  800cc6:	b7aff0ef          	jal	ra,800040 <cprintf>
    
    cprintf("在ucore中的教学意义：\n");
  800cca:	00001517          	auipc	a0,0x1
  800cce:	5c650513          	addi	a0,a0,1478 # 802290 <error_string+0x1228>
  800cd2:	b6eff0ef          	jal	ra,800040 <cprintf>
    cprintf("• 理解COW机制的实现细节\n");
  800cd6:	00001517          	auipc	a0,0x1
  800cda:	5da50513          	addi	a0,a0,1498 # 8022b0 <error_string+0x1248>
  800cde:	b62ff0ef          	jal	ra,800040 <cprintf>
    cprintf("• 认识竞态条件的危害\n");
  800ce2:	00001517          	auipc	a0,0x1
  800ce6:	5f650513          	addi	a0,a0,1526 # 8022d8 <error_string+0x1270>
  800cea:	b56ff0ef          	jal	ra,800040 <cprintf>
    cprintf("• 学习内核安全编程\n");
  800cee:	00001517          	auipc	a0,0x1
  800cf2:	61250513          	addi	a0,a0,1554 # 802300 <error_string+0x1298>
  800cf6:	b4aff0ef          	jal	ra,800040 <cprintf>
    cprintf("• 掌握页表操作的原子性要求\n\n");
}
  800cfa:	60a2                	ld	ra,8(sp)
    cprintf("• 掌握页表操作的原子性要求\n\n");
  800cfc:	00001517          	auipc	a0,0x1
  800d00:	62450513          	addi	a0,a0,1572 # 802320 <error_string+0x12b8>
}
  800d04:	0141                	addi	sp,sp,16
    cprintf("• 掌握页表操作的原子性要求\n\n");
  800d06:	b3aff06f          	j	800040 <cprintf>

0000000000800d0a <main>:

int main(void) {
  800d0a:	1141                	addi	sp,sp,-16
    cprintf("╔════════════════════════════════════════════════════╗\n");
  800d0c:	00001517          	auipc	a0,0x1
  800d10:	64450513          	addi	a0,a0,1604 # 802350 <error_string+0x12e8>
int main(void) {
  800d14:	e406                	sd	ra,8(sp)
    cprintf("╔════════════════════════════════════════════════════╗\n");
  800d16:	b2aff0ef          	jal	ra,800040 <cprintf>
    cprintf("║       DirtyCOW 漏洞模拟与教学演示程序            ║\n");
  800d1a:	00001517          	auipc	a0,0x1
  800d1e:	6de50513          	addi	a0,a0,1758 # 8023f8 <error_string+0x1390>
  800d22:	b1eff0ef          	jal	ra,800040 <cprintf>
    cprintf("║                                                    ║\n");
  800d26:	00001517          	auipc	a0,0x1
  800d2a:	71a50513          	addi	a0,a0,1818 # 802440 <error_string+0x13d8>
  800d2e:	b12ff0ef          	jal	ra,800040 <cprintf>
    cprintf("║  警告：这是教学演示，不包含真实漏洞利用代码      ║\n");
  800d32:	00001517          	auipc	a0,0x1
  800d36:	74e50513          	addi	a0,a0,1870 # 802480 <error_string+0x1418>
  800d3a:	b06ff0ef          	jal	ra,800040 <cprintf>
    cprintf("║  目的：帮助理解COW机制和竞态条件安全问题         ║\n");
  800d3e:	00001517          	auipc	a0,0x1
  800d42:	79250513          	addi	a0,a0,1938 # 8024d0 <error_string+0x1468>
  800d46:	afaff0ef          	jal	ra,800040 <cprintf>
    cprintf("╚════════════════════════════════════════════════════╝\n");
  800d4a:	00001517          	auipc	a0,0x1
  800d4e:	7d650513          	addi	a0,a0,2006 # 802520 <error_string+0x14b8>
  800d52:	aeeff0ef          	jal	ra,800040 <cprintf>
    
    // 打印漏洞信息
    print_vulnerability_info();
  800d56:	e51ff0ef          	jal	ra,800ba6 <print_vulnerability_info>
    
    cprintf("\n按任意键开始测试...\n");
  800d5a:	00002517          	auipc	a0,0x2
  800d5e:	86e50513          	addi	a0,a0,-1938 # 8025c8 <error_string+0x1560>
  800d62:	adeff0ef          	jal	ra,800040 <cprintf>
    cprintf("(在真实系统中按键，这里自动继续)\n\n");
  800d66:	00002517          	auipc	a0,0x2
  800d6a:	88250513          	addi	a0,a0,-1918 # 8025e8 <error_string+0x1580>
  800d6e:	ad2ff0ef          	jal	ra,800040 <cprintf>
    
    // 运行所有测试
    test_normal_cow();           // 测试1：正常COW
  800d72:	fb6ff0ef          	jal	ra,800528 <test_normal_cow>
    test_dirtycow_simulation();  // 测试2：竞态模拟
  800d76:	889ff0ef          	jal	ra,8005fe <test_dirtycow_simulation>
    test_dirtycow_protection();  // 测试3：防护措施
  800d7a:	a7fff0ef          	jal	ra,8007f8 <test_dirtycow_protection>
    test_race_amplification();   // 测试4：竞态放大
  800d7e:	bc9ff0ef          	jal	ra,800946 <test_race_amplification>
    test_timing_window();        // 测试5：时序分析
  800d82:	ce5ff0ef          	jal	ra,800a66 <test_timing_window>
    
    cprintf("\n╔════════════════════════════════════════════════════╗\n");
  800d86:	00001517          	auipc	a0,0x1
  800d8a:	09a50513          	addi	a0,a0,154 # 801e20 <error_string+0xdb8>
  800d8e:	ab2ff0ef          	jal	ra,800040 <cprintf>
    cprintf("║              演示完成                              ║\n");
  800d92:	00002517          	auipc	a0,0x2
  800d96:	88e50513          	addi	a0,a0,-1906 # 802620 <error_string+0x15b8>
  800d9a:	aa6ff0ef          	jal	ra,800040 <cprintf>
    cprintf("║                                                    ║\n");
  800d9e:	00001517          	auipc	a0,0x1
  800da2:	6a250513          	addi	a0,a0,1698 # 802440 <error_string+0x13d8>
  800da6:	a9aff0ef          	jal	ra,800040 <cprintf>
    cprintf("║  学习要点：                                        ║\n");
  800daa:	00002517          	auipc	a0,0x2
  800dae:	8b650513          	addi	a0,a0,-1866 # 802660 <error_string+0x15f8>
  800db2:	a8eff0ef          	jal	ra,800040 <cprintf>
    cprintf("║  1. COW不仅是性能优化，也是安全边界              ║\n");
  800db6:	00002517          	auipc	a0,0x2
  800dba:	8f250513          	addi	a0,a0,-1806 # 8026a8 <error_string+0x1640>
  800dbe:	a82ff0ef          	jal	ra,800040 <cprintf>
    cprintf("║  2. 竞态条件可能导致严重安全漏洞                  ║\n");
  800dc2:	00002517          	auipc	a0,0x2
  800dc6:	92e50513          	addi	a0,a0,-1746 # 8026f0 <error_string+0x1688>
  800dca:	a76ff0ef          	jal	ra,800040 <cprintf>
    cprintf("║  3. 内核编程需要极其谨慎的同步控制                ║\n");
  800dce:	00002517          	auipc	a0,0x2
  800dd2:	97250513          	addi	a0,a0,-1678 # 802740 <error_string+0x16d8>
  800dd6:	a6aff0ef          	jal	ra,800040 <cprintf>
    cprintf("║  4. 页表操作必须保证原子性                        ║\n");
  800dda:	00002517          	auipc	a0,0x2
  800dde:	9b650513          	addi	a0,a0,-1610 # 802790 <error_string+0x1728>
  800de2:	a5eff0ef          	jal	ra,800040 <cprintf>
    cprintf("╚════════════════════════════════════════════════════╝\n");
  800de6:	00001517          	auipc	a0,0x1
  800dea:	73a50513          	addi	a0,a0,1850 # 802520 <error_string+0x14b8>
  800dee:	a52ff0ef          	jal	ra,800040 <cprintf>
    
    return 0;
}
  800df2:	60a2                	ld	ra,8(sp)
  800df4:	4501                	li	a0,0
  800df6:	0141                	addi	sp,sp,16
  800df8:	8082                	ret
