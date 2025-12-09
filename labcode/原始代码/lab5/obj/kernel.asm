
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000a6517          	auipc	a0,0xa6
ffffffffc020004e:	42650513          	addi	a0,a0,1062 # ffffffffc02a6470 <buf>
ffffffffc0200052:	000ab617          	auipc	a2,0xab
ffffffffc0200056:	8c260613          	addi	a2,a2,-1854 # ffffffffc02aa914 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	66c050ef          	jal	ra,ffffffffc02056ce <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	68a58593          	addi	a1,a1,1674 # ffffffffc02056f8 <etext>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	6a250513          	addi	a0,a0,1698 # ffffffffc0205718 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	6b0020ef          	jal	ra,ffffffffc0202736 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	17d030ef          	jal	ra,ffffffffc0203a0e <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	58b040ef          	jal	ra,ffffffffc0204e20 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	717040ef          	jal	ra,ffffffffc0204fb8 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00005517          	auipc	a0,0x5
ffffffffc02000c0:	66450513          	addi	a0,a0,1636 # ffffffffc0205720 <etext+0x28>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	000a6b97          	auipc	s7,0xa6
ffffffffc02000d6:	39eb8b93          	addi	s7,s7,926 # ffffffffc02a6470 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	000a6517          	auipc	a0,0xa6
ffffffffc0200132:	34250513          	addi	a0,a0,834 # ffffffffc02a6470 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	122050ef          	jal	ra,ffffffffc02052aa <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	0ec050ef          	jal	ra,ffffffffc02052aa <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	50a50513          	addi	a0,a0,1290 # ffffffffc0205728 <etext+0x30>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	51450513          	addi	a0,a0,1300 # ffffffffc0205748 <etext+0x50>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	4b858593          	addi	a1,a1,1208 # ffffffffc02056f8 <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	52050513          	addi	a0,a0,1312 # ffffffffc0205768 <etext+0x70>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	21c58593          	addi	a1,a1,540 # ffffffffc02a6470 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	52c50513          	addi	a0,a0,1324 # ffffffffc0205788 <etext+0x90>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	6ac58593          	addi	a1,a1,1708 # ffffffffc02aa914 <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	53850513          	addi	a0,a0,1336 # ffffffffc02057a8 <etext+0xb0>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000ab597          	auipc	a1,0xab
ffffffffc0200280:	a9758593          	addi	a1,a1,-1385 # ffffffffc02aad13 <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00005517          	auipc	a0,0x5
ffffffffc02002a2:	52a50513          	addi	a0,a0,1322 # ffffffffc02057c8 <etext+0xd0>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00005617          	auipc	a2,0x5
ffffffffc02002b0:	54c60613          	addi	a2,a2,1356 # ffffffffc02057f8 <etext+0x100>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	55850513          	addi	a0,a0,1368 # ffffffffc0205810 <etext+0x118>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00005617          	auipc	a2,0x5
ffffffffc02002cc:	56060613          	addi	a2,a2,1376 # ffffffffc0205828 <etext+0x130>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	57858593          	addi	a1,a1,1400 # ffffffffc0205848 <etext+0x150>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	57850513          	addi	a0,a0,1400 # ffffffffc0205850 <etext+0x158>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	57a60613          	addi	a2,a2,1402 # ffffffffc0205860 <etext+0x168>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	59a58593          	addi	a1,a1,1434 # ffffffffc0205888 <etext+0x190>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	55a50513          	addi	a0,a0,1370 # ffffffffc0205850 <etext+0x158>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	59660613          	addi	a2,a2,1430 # ffffffffc0205898 <etext+0x1a0>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	5ae58593          	addi	a1,a1,1454 # ffffffffc02058b8 <etext+0x1c0>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	53e50513          	addi	a0,a0,1342 # ffffffffc0205850 <etext+0x158>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00005517          	auipc	a0,0x5
ffffffffc0200350:	57c50513          	addi	a0,a0,1404 # ffffffffc02058c8 <etext+0x1d0>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00005517          	auipc	a0,0x5
ffffffffc0200372:	58250513          	addi	a0,a0,1410 # ffffffffc02058f0 <etext+0x1f8>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	5dcc0c13          	addi	s8,s8,1500 # ffffffffc0205960 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	58c90913          	addi	s2,s2,1420 # ffffffffc0205918 <etext+0x220>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	58c48493          	addi	s1,s1,1420 # ffffffffc0205920 <etext+0x228>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	58ab0b13          	addi	s6,s6,1418 # ffffffffc0205928 <etext+0x230>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	4a2a0a13          	addi	s4,s4,1186 # ffffffffc0205848 <etext+0x150>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00005d17          	auipc	s10,0x5
ffffffffc02003cc:	598d0d13          	addi	s10,s10,1432 # ffffffffc0205960 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	29e050ef          	jal	ra,ffffffffc0205674 <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	28a050ef          	jal	ra,ffffffffc0205674 <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	290050ef          	jal	ra,ffffffffc02056b8 <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	252050ef          	jal	ra,ffffffffc02056b8 <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00005517          	auipc	a0,0x5
ffffffffc0200484:	4c850513          	addi	a0,a0,1224 # ffffffffc0205948 <etext+0x250>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000aa317          	auipc	t1,0xaa
ffffffffc0200492:	40a30313          	addi	t1,t1,1034 # ffffffffc02aa898 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00005517          	auipc	a0,0x5
ffffffffc02004c0:	4ec50513          	addi	a0,a0,1260 # ffffffffc02059a8 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00006517          	auipc	a0,0x6
ffffffffc02004d6:	5de50513          	addi	a0,a0,1502 # ffffffffc0206ab0 <default_pmm_manager+0x578>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00005517          	auipc	a0,0x5
ffffffffc020050a:	4c250513          	addi	a0,a0,1218 # ffffffffc02059c8 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00006517          	auipc	a0,0x6
ffffffffc020052a:	58a50513          	addi	a0,a0,1418 # ffffffffc0206ab0 <default_pmm_manager+0x578>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd560>
ffffffffc0200540:	000aa717          	auipc	a4,0xaa
ffffffffc0200544:	36f73423          	sd	a5,872(a4) # ffffffffc02aa8a8 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	48850513          	addi	a0,a0,1160 # ffffffffc02059e8 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000aa797          	auipc	a5,0xaa
ffffffffc020056c:	3207bc23          	sd	zero,824(a5) # ffffffffc02aa8a0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000aa797          	auipc	a5,0xaa
ffffffffc020057a:	3327b783          	ld	a5,818(a5) # ffffffffc02aa8a8 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	40850513          	addi	a0,a0,1032 # ffffffffc0205a08 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	3ea50513          	addi	a0,a0,1002 # ffffffffc0205a18 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	3e450513          	addi	a0,a0,996 # ffffffffc0205a28 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	3ec50513          	addi	a0,a0,1004 # ffffffffc0205a40 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe355d9>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	38290913          	addi	s2,s2,898 # ffffffffc0205a90 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	36c48493          	addi	s1,s1,876 # ffffffffc0205a88 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	39850513          	addi	a0,a0,920 # ffffffffc0205b08 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	3c450513          	addi	a0,a0,964 # ffffffffc0205b40 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	2a450513          	addi	a0,a0,676 # ffffffffc0205a60 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	663040ef          	jal	ra,ffffffffc020562c <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	6bb040ef          	jal	ra,ffffffffc0205692 <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	607040ef          	jal	ra,ffffffffc0205674 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	21650513          	addi	a0,a0,534 # ffffffffc0205a98 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	16850513          	addi	a0,a0,360 # ffffffffc0205ab8 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	16e50513          	addi	a0,a0,366 # ffffffffc0205ad0 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	17c50513          	addi	a0,a0,380 # ffffffffc0205af0 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	1c050513          	addi	a0,a0,448 # ffffffffc0205b40 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000aa797          	auipc	a5,0xaa
ffffffffc020098c:	f287b423          	sd	s0,-216(a5) # ffffffffc02aa8b0 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000aa797          	auipc	a5,0xaa
ffffffffc0200994:	f367b423          	sd	s6,-216(a5) # ffffffffc02aa8b8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000aa517          	auipc	a0,0xaa
ffffffffc020099e:	f1653503          	ld	a0,-234(a0) # ffffffffc02aa8b0 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000aa517          	auipc	a0,0xaa
ffffffffc02009a8:	f1453503          	ld	a0,-236(a0) # ffffffffc02aa8b8 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	4a478793          	addi	a5,a5,1188 # ffffffffc0200e64 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	17a50513          	addi	a0,a0,378 # ffffffffc0205b58 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	18250513          	addi	a0,a0,386 # ffffffffc0205b70 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	18c50513          	addi	a0,a0,396 # ffffffffc0205b88 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	19650513          	addi	a0,a0,406 # ffffffffc0205ba0 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	1a050513          	addi	a0,a0,416 # ffffffffc0205bb8 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	1aa50513          	addi	a0,a0,426 # ffffffffc0205bd0 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	1b450513          	addi	a0,a0,436 # ffffffffc0205be8 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	1be50513          	addi	a0,a0,446 # ffffffffc0205c00 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	1c850513          	addi	a0,a0,456 # ffffffffc0205c18 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	1d250513          	addi	a0,a0,466 # ffffffffc0205c30 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	1dc50513          	addi	a0,a0,476 # ffffffffc0205c48 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	1e650513          	addi	a0,a0,486 # ffffffffc0205c60 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	1f050513          	addi	a0,a0,496 # ffffffffc0205c78 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	1fa50513          	addi	a0,a0,506 # ffffffffc0205c90 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	20450513          	addi	a0,a0,516 # ffffffffc0205ca8 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	20e50513          	addi	a0,a0,526 # ffffffffc0205cc0 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	21850513          	addi	a0,a0,536 # ffffffffc0205cd8 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	22250513          	addi	a0,a0,546 # ffffffffc0205cf0 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	22c50513          	addi	a0,a0,556 # ffffffffc0205d08 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	23650513          	addi	a0,a0,566 # ffffffffc0205d20 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	24050513          	addi	a0,a0,576 # ffffffffc0205d38 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	24a50513          	addi	a0,a0,586 # ffffffffc0205d50 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	25450513          	addi	a0,a0,596 # ffffffffc0205d68 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	25e50513          	addi	a0,a0,606 # ffffffffc0205d80 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	26850513          	addi	a0,a0,616 # ffffffffc0205d98 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	27250513          	addi	a0,a0,626 # ffffffffc0205db0 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	27c50513          	addi	a0,a0,636 # ffffffffc0205dc8 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	28650513          	addi	a0,a0,646 # ffffffffc0205de0 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	29050513          	addi	a0,a0,656 # ffffffffc0205df8 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	29a50513          	addi	a0,a0,666 # ffffffffc0205e10 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	2a450513          	addi	a0,a0,676 # ffffffffc0205e28 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	2aa50513          	addi	a0,a0,682 # ffffffffc0205e40 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	2ac50513          	addi	a0,a0,684 # ffffffffc0205e58 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	2ac50513          	addi	a0,a0,684 # ffffffffc0205e70 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	2b450513          	addi	a0,a0,692 # ffffffffc0205e88 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	2bc50513          	addi	a0,a0,700 # ffffffffc0205ea0 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	2b850513          	addi	a0,a0,696 # ffffffffc0205eb0 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c06:	11853783          	ld	a5,280(a0)
ffffffffc0200c0a:	472d                	li	a4,11
ffffffffc0200c0c:	0786                	slli	a5,a5,0x1
ffffffffc0200c0e:	8385                	srli	a5,a5,0x1
ffffffffc0200c10:	08f76463          	bltu	a4,a5,ffffffffc0200c98 <interrupt_handler+0x92>
ffffffffc0200c14:	00005717          	auipc	a4,0x5
ffffffffc0200c18:	39470713          	addi	a4,a4,916 # ffffffffc0205fa8 <commands+0x648>
ffffffffc0200c1c:	078a                	slli	a5,a5,0x2
ffffffffc0200c1e:	97ba                	add	a5,a5,a4
ffffffffc0200c20:	439c                	lw	a5,0(a5)
ffffffffc0200c22:	97ba                	add	a5,a5,a4
ffffffffc0200c24:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c26:	00005517          	auipc	a0,0x5
ffffffffc0200c2a:	30250513          	addi	a0,a0,770 # ffffffffc0205f28 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	2d650513          	addi	a0,a0,726 # ffffffffc0205f08 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	28a50513          	addi	a0,a0,650 # ffffffffc0205ec8 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	29e50513          	addi	a0,a0,670 # ffffffffc0205ee8 <commands+0x588>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c56:	1141                	addi	sp,sp,-16
ffffffffc0200c58:	e406                	sd	ra,8(sp)
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        // (1) 设置下次时钟中断
        clock_set_next_event();
ffffffffc0200c5a:	919ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        // (2) 计数器加一
        ticks++;
ffffffffc0200c5e:	000aa797          	auipc	a5,0xaa
ffffffffc0200c62:	c4278793          	addi	a5,a5,-958 # ffffffffc02aa8a0 <ticks>
ffffffffc0200c66:	6398                	ld	a4,0(a5)
ffffffffc0200c68:	0705                	addi	a4,a4,1
ffffffffc0200c6a:	e398                	sd	a4,0(a5)
        // (3) 每100次时钟中断，设置当前进程需要调度
        if (ticks % TICK_NUM == 0) {
ffffffffc0200c6c:	639c                	ld	a5,0(a5)
ffffffffc0200c6e:	06400713          	li	a4,100
ffffffffc0200c72:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200c76:	eb81                	bnez	a5,ffffffffc0200c86 <interrupt_handler+0x80>
            assert(current != NULL);
ffffffffc0200c78:	000aa797          	auipc	a5,0xaa
ffffffffc0200c7c:	c807b783          	ld	a5,-896(a5) # ffffffffc02aa8f8 <current>
ffffffffc0200c80:	cf89                	beqz	a5,ffffffffc0200c9a <interrupt_handler+0x94>
            current->need_resched = 1;
ffffffffc0200c82:	4705                	li	a4,1
ffffffffc0200c84:	ef98                	sd	a4,24(a5)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c86:	60a2                	ld	ra,8(sp)
ffffffffc0200c88:	0141                	addi	sp,sp,16
ffffffffc0200c8a:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c8c:	00005517          	auipc	a0,0x5
ffffffffc0200c90:	2fc50513          	addi	a0,a0,764 # ffffffffc0205f88 <commands+0x628>
ffffffffc0200c94:	d00ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c98:	b731                	j	ffffffffc0200ba4 <print_trapframe>
            assert(current != NULL);
ffffffffc0200c9a:	00005697          	auipc	a3,0x5
ffffffffc0200c9e:	2ae68693          	addi	a3,a3,686 # ffffffffc0205f48 <commands+0x5e8>
ffffffffc0200ca2:	00005617          	auipc	a2,0x5
ffffffffc0200ca6:	2b660613          	addi	a2,a2,694 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0200caa:	08800593          	li	a1,136
ffffffffc0200cae:	00005517          	auipc	a0,0x5
ffffffffc0200cb2:	2c250513          	addi	a0,a0,706 # ffffffffc0205f70 <commands+0x610>
ffffffffc0200cb6:	fd8ff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200cba <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200cba:	11853783          	ld	a5,280(a0)
{
ffffffffc0200cbe:	1141                	addi	sp,sp,-16
ffffffffc0200cc0:	e022                	sd	s0,0(sp)
ffffffffc0200cc2:	e406                	sd	ra,8(sp)
ffffffffc0200cc4:	473d                	li	a4,15
ffffffffc0200cc6:	842a                	mv	s0,a0
ffffffffc0200cc8:	0cf76463          	bltu	a4,a5,ffffffffc0200d90 <exception_handler+0xd6>
ffffffffc0200ccc:	00005717          	auipc	a4,0x5
ffffffffc0200cd0:	48470713          	addi	a4,a4,1156 # ffffffffc0206150 <commands+0x7f0>
ffffffffc0200cd4:	078a                	slli	a5,a5,0x2
ffffffffc0200cd6:	97ba                	add	a5,a5,a4
ffffffffc0200cd8:	439c                	lw	a5,0(a5)
ffffffffc0200cda:	97ba                	add	a5,a5,a4
ffffffffc0200cdc:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cde:	00005517          	auipc	a0,0x5
ffffffffc0200ce2:	3ca50513          	addi	a0,a0,970 # ffffffffc02060a8 <commands+0x748>
ffffffffc0200ce6:	caeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200cea:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200cee:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200cf0:	0791                	addi	a5,a5,4
ffffffffc0200cf2:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200cf6:	6402                	ld	s0,0(sp)
ffffffffc0200cf8:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200cfa:	4ae0406f          	j	ffffffffc02051a8 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cfe:	00005517          	auipc	a0,0x5
ffffffffc0200d02:	3ca50513          	addi	a0,a0,970 # ffffffffc02060c8 <commands+0x768>
}
ffffffffc0200d06:	6402                	ld	s0,0(sp)
ffffffffc0200d08:	60a2                	ld	ra,8(sp)
ffffffffc0200d0a:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d0c:	c88ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d10:	00005517          	auipc	a0,0x5
ffffffffc0200d14:	3d850513          	addi	a0,a0,984 # ffffffffc02060e8 <commands+0x788>
ffffffffc0200d18:	b7fd                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200d1a:	00005517          	auipc	a0,0x5
ffffffffc0200d1e:	3ee50513          	addi	a0,a0,1006 # ffffffffc0206108 <commands+0x7a8>
ffffffffc0200d22:	b7d5                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Load page fault\n");
ffffffffc0200d24:	00005517          	auipc	a0,0x5
ffffffffc0200d28:	3fc50513          	addi	a0,a0,1020 # ffffffffc0206120 <commands+0x7c0>
ffffffffc0200d2c:	bfe9                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Store/AMO page fault\n");
ffffffffc0200d2e:	00005517          	auipc	a0,0x5
ffffffffc0200d32:	40a50513          	addi	a0,a0,1034 # ffffffffc0206138 <commands+0x7d8>
ffffffffc0200d36:	bfc1                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d38:	00005517          	auipc	a0,0x5
ffffffffc0200d3c:	2a050513          	addi	a0,a0,672 # ffffffffc0205fd8 <commands+0x678>
ffffffffc0200d40:	b7d9                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d42:	00005517          	auipc	a0,0x5
ffffffffc0200d46:	2b650513          	addi	a0,a0,694 # ffffffffc0205ff8 <commands+0x698>
ffffffffc0200d4a:	bf75                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d4c:	00005517          	auipc	a0,0x5
ffffffffc0200d50:	2cc50513          	addi	a0,a0,716 # ffffffffc0206018 <commands+0x6b8>
ffffffffc0200d54:	bf4d                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d56:	00005517          	auipc	a0,0x5
ffffffffc0200d5a:	2da50513          	addi	a0,a0,730 # ffffffffc0206030 <commands+0x6d0>
ffffffffc0200d5e:	c36ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200d62:	6458                	ld	a4,136(s0)
ffffffffc0200d64:	47a9                	li	a5,10
ffffffffc0200d66:	04f70663          	beq	a4,a5,ffffffffc0200db2 <exception_handler+0xf8>
}
ffffffffc0200d6a:	60a2                	ld	ra,8(sp)
ffffffffc0200d6c:	6402                	ld	s0,0(sp)
ffffffffc0200d6e:	0141                	addi	sp,sp,16
ffffffffc0200d70:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200d72:	00005517          	auipc	a0,0x5
ffffffffc0200d76:	2ce50513          	addi	a0,a0,718 # ffffffffc0206040 <commands+0x6e0>
ffffffffc0200d7a:	b771                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200d7c:	00005517          	auipc	a0,0x5
ffffffffc0200d80:	2e450513          	addi	a0,a0,740 # ffffffffc0206060 <commands+0x700>
ffffffffc0200d84:	b749                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d86:	00005517          	auipc	a0,0x5
ffffffffc0200d8a:	30a50513          	addi	a0,a0,778 # ffffffffc0206090 <commands+0x730>
ffffffffc0200d8e:	bfa5                	j	ffffffffc0200d06 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200d90:	8522                	mv	a0,s0
}
ffffffffc0200d92:	6402                	ld	s0,0(sp)
ffffffffc0200d94:	60a2                	ld	ra,8(sp)
ffffffffc0200d96:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200d98:	b531                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d9a:	00005617          	auipc	a2,0x5
ffffffffc0200d9e:	2de60613          	addi	a2,a2,734 # ffffffffc0206078 <commands+0x718>
ffffffffc0200da2:	0c200593          	li	a1,194
ffffffffc0200da6:	00005517          	auipc	a0,0x5
ffffffffc0200daa:	1ca50513          	addi	a0,a0,458 # ffffffffc0205f70 <commands+0x610>
ffffffffc0200dae:	ee0ff0ef          	jal	ra,ffffffffc020048e <__panic>
            tf->epc += 4;
ffffffffc0200db2:	10843783          	ld	a5,264(s0)
ffffffffc0200db6:	0791                	addi	a5,a5,4
ffffffffc0200db8:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200dbc:	3ec040ef          	jal	ra,ffffffffc02051a8 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dc0:	000aa797          	auipc	a5,0xaa
ffffffffc0200dc4:	b387b783          	ld	a5,-1224(a5) # ffffffffc02aa8f8 <current>
ffffffffc0200dc8:	6b9c                	ld	a5,16(a5)
ffffffffc0200dca:	8522                	mv	a0,s0
}
ffffffffc0200dcc:	6402                	ld	s0,0(sp)
ffffffffc0200dce:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dd0:	6589                	lui	a1,0x2
ffffffffc0200dd2:	95be                	add	a1,a1,a5
}
ffffffffc0200dd4:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dd6:	aab1                	j	ffffffffc0200f32 <kernel_execve_ret>

ffffffffc0200dd8 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200dd8:	1101                	addi	sp,sp,-32
ffffffffc0200dda:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200ddc:	000aa417          	auipc	s0,0xaa
ffffffffc0200de0:	b1c40413          	addi	s0,s0,-1252 # ffffffffc02aa8f8 <current>
ffffffffc0200de4:	6018                	ld	a4,0(s0)
{
ffffffffc0200de6:	ec06                	sd	ra,24(sp)
ffffffffc0200de8:	e426                	sd	s1,8(sp)
ffffffffc0200dea:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dec:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200df0:	cf1d                	beqz	a4,ffffffffc0200e2e <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200df2:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200df6:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200dfa:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200dfc:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e00:	0206c463          	bltz	a3,ffffffffc0200e28 <trap+0x50>
        exception_handler(tf);
ffffffffc0200e04:	eb7ff0ef          	jal	ra,ffffffffc0200cba <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200e08:	601c                	ld	a5,0(s0)
ffffffffc0200e0a:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200e0e:	e499                	bnez	s1,ffffffffc0200e1c <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200e10:	0b07a703          	lw	a4,176(a5)
ffffffffc0200e14:	8b05                	andi	a4,a4,1
ffffffffc0200e16:	e329                	bnez	a4,ffffffffc0200e58 <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e18:	6f9c                	ld	a5,24(a5)
ffffffffc0200e1a:	eb85                	bnez	a5,ffffffffc0200e4a <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200e1c:	60e2                	ld	ra,24(sp)
ffffffffc0200e1e:	6442                	ld	s0,16(sp)
ffffffffc0200e20:	64a2                	ld	s1,8(sp)
ffffffffc0200e22:	6902                	ld	s2,0(sp)
ffffffffc0200e24:	6105                	addi	sp,sp,32
ffffffffc0200e26:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e28:	ddfff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200e2c:	bff1                	j	ffffffffc0200e08 <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e2e:	0006c863          	bltz	a3,ffffffffc0200e3e <trap+0x66>
}
ffffffffc0200e32:	6442                	ld	s0,16(sp)
ffffffffc0200e34:	60e2                	ld	ra,24(sp)
ffffffffc0200e36:	64a2                	ld	s1,8(sp)
ffffffffc0200e38:	6902                	ld	s2,0(sp)
ffffffffc0200e3a:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200e3c:	bdbd                	j	ffffffffc0200cba <exception_handler>
}
ffffffffc0200e3e:	6442                	ld	s0,16(sp)
ffffffffc0200e40:	60e2                	ld	ra,24(sp)
ffffffffc0200e42:	64a2                	ld	s1,8(sp)
ffffffffc0200e44:	6902                	ld	s2,0(sp)
ffffffffc0200e46:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e48:	bb7d                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200e4a:	6442                	ld	s0,16(sp)
ffffffffc0200e4c:	60e2                	ld	ra,24(sp)
ffffffffc0200e4e:	64a2                	ld	s1,8(sp)
ffffffffc0200e50:	6902                	ld	s2,0(sp)
ffffffffc0200e52:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e54:	2680406f          	j	ffffffffc02050bc <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e58:	555d                	li	a0,-9
ffffffffc0200e5a:	5a8030ef          	jal	ra,ffffffffc0204402 <do_exit>
            if (current->need_resched)
ffffffffc0200e5e:	601c                	ld	a5,0(s0)
ffffffffc0200e60:	bf65                	j	ffffffffc0200e18 <trap+0x40>
	...

ffffffffc0200e64 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e64:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e68:	00011463          	bnez	sp,ffffffffc0200e70 <__alltraps+0xc>
ffffffffc0200e6c:	14002173          	csrr	sp,sscratch
ffffffffc0200e70:	712d                	addi	sp,sp,-288
ffffffffc0200e72:	e002                	sd	zero,0(sp)
ffffffffc0200e74:	e406                	sd	ra,8(sp)
ffffffffc0200e76:	ec0e                	sd	gp,24(sp)
ffffffffc0200e78:	f012                	sd	tp,32(sp)
ffffffffc0200e7a:	f416                	sd	t0,40(sp)
ffffffffc0200e7c:	f81a                	sd	t1,48(sp)
ffffffffc0200e7e:	fc1e                	sd	t2,56(sp)
ffffffffc0200e80:	e0a2                	sd	s0,64(sp)
ffffffffc0200e82:	e4a6                	sd	s1,72(sp)
ffffffffc0200e84:	e8aa                	sd	a0,80(sp)
ffffffffc0200e86:	ecae                	sd	a1,88(sp)
ffffffffc0200e88:	f0b2                	sd	a2,96(sp)
ffffffffc0200e8a:	f4b6                	sd	a3,104(sp)
ffffffffc0200e8c:	f8ba                	sd	a4,112(sp)
ffffffffc0200e8e:	fcbe                	sd	a5,120(sp)
ffffffffc0200e90:	e142                	sd	a6,128(sp)
ffffffffc0200e92:	e546                	sd	a7,136(sp)
ffffffffc0200e94:	e94a                	sd	s2,144(sp)
ffffffffc0200e96:	ed4e                	sd	s3,152(sp)
ffffffffc0200e98:	f152                	sd	s4,160(sp)
ffffffffc0200e9a:	f556                	sd	s5,168(sp)
ffffffffc0200e9c:	f95a                	sd	s6,176(sp)
ffffffffc0200e9e:	fd5e                	sd	s7,184(sp)
ffffffffc0200ea0:	e1e2                	sd	s8,192(sp)
ffffffffc0200ea2:	e5e6                	sd	s9,200(sp)
ffffffffc0200ea4:	e9ea                	sd	s10,208(sp)
ffffffffc0200ea6:	edee                	sd	s11,216(sp)
ffffffffc0200ea8:	f1f2                	sd	t3,224(sp)
ffffffffc0200eaa:	f5f6                	sd	t4,232(sp)
ffffffffc0200eac:	f9fa                	sd	t5,240(sp)
ffffffffc0200eae:	fdfe                	sd	t6,248(sp)
ffffffffc0200eb0:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200eb4:	100024f3          	csrr	s1,sstatus
ffffffffc0200eb8:	14102973          	csrr	s2,sepc
ffffffffc0200ebc:	143029f3          	csrr	s3,stval
ffffffffc0200ec0:	14202a73          	csrr	s4,scause
ffffffffc0200ec4:	e822                	sd	s0,16(sp)
ffffffffc0200ec6:	e226                	sd	s1,256(sp)
ffffffffc0200ec8:	e64a                	sd	s2,264(sp)
ffffffffc0200eca:	ea4e                	sd	s3,272(sp)
ffffffffc0200ecc:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200ece:	850a                	mv	a0,sp
    jal trap
ffffffffc0200ed0:	f09ff0ef          	jal	ra,ffffffffc0200dd8 <trap>

ffffffffc0200ed4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200ed4:	6492                	ld	s1,256(sp)
ffffffffc0200ed6:	6932                	ld	s2,264(sp)
ffffffffc0200ed8:	1004f413          	andi	s0,s1,256
ffffffffc0200edc:	e401                	bnez	s0,ffffffffc0200ee4 <__trapret+0x10>
ffffffffc0200ede:	1200                	addi	s0,sp,288
ffffffffc0200ee0:	14041073          	csrw	sscratch,s0
ffffffffc0200ee4:	10049073          	csrw	sstatus,s1
ffffffffc0200ee8:	14191073          	csrw	sepc,s2
ffffffffc0200eec:	60a2                	ld	ra,8(sp)
ffffffffc0200eee:	61e2                	ld	gp,24(sp)
ffffffffc0200ef0:	7202                	ld	tp,32(sp)
ffffffffc0200ef2:	72a2                	ld	t0,40(sp)
ffffffffc0200ef4:	7342                	ld	t1,48(sp)
ffffffffc0200ef6:	73e2                	ld	t2,56(sp)
ffffffffc0200ef8:	6406                	ld	s0,64(sp)
ffffffffc0200efa:	64a6                	ld	s1,72(sp)
ffffffffc0200efc:	6546                	ld	a0,80(sp)
ffffffffc0200efe:	65e6                	ld	a1,88(sp)
ffffffffc0200f00:	7606                	ld	a2,96(sp)
ffffffffc0200f02:	76a6                	ld	a3,104(sp)
ffffffffc0200f04:	7746                	ld	a4,112(sp)
ffffffffc0200f06:	77e6                	ld	a5,120(sp)
ffffffffc0200f08:	680a                	ld	a6,128(sp)
ffffffffc0200f0a:	68aa                	ld	a7,136(sp)
ffffffffc0200f0c:	694a                	ld	s2,144(sp)
ffffffffc0200f0e:	69ea                	ld	s3,152(sp)
ffffffffc0200f10:	7a0a                	ld	s4,160(sp)
ffffffffc0200f12:	7aaa                	ld	s5,168(sp)
ffffffffc0200f14:	7b4a                	ld	s6,176(sp)
ffffffffc0200f16:	7bea                	ld	s7,184(sp)
ffffffffc0200f18:	6c0e                	ld	s8,192(sp)
ffffffffc0200f1a:	6cae                	ld	s9,200(sp)
ffffffffc0200f1c:	6d4e                	ld	s10,208(sp)
ffffffffc0200f1e:	6dee                	ld	s11,216(sp)
ffffffffc0200f20:	7e0e                	ld	t3,224(sp)
ffffffffc0200f22:	7eae                	ld	t4,232(sp)
ffffffffc0200f24:	7f4e                	ld	t5,240(sp)
ffffffffc0200f26:	7fee                	ld	t6,248(sp)
ffffffffc0200f28:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f2a:	10200073          	sret

ffffffffc0200f2e <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f2e:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200f30:	b755                	j	ffffffffc0200ed4 <__trapret>

ffffffffc0200f32 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200f32:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7ce8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200f36:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200f3a:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200f3e:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200f42:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200f46:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200f4a:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200f4e:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200f52:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200f56:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200f58:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200f5a:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200f5c:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200f5e:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200f60:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200f62:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200f64:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200f66:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200f68:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200f6a:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200f6c:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200f6e:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200f70:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200f72:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200f74:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200f76:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200f78:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200f7a:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200f7c:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200f7e:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200f80:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200f82:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200f84:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200f86:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200f88:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200f8a:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200f8c:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200f8e:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f90:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f92:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f94:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f96:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200f98:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200f9a:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200f9c:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200f9e:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200fa0:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200fa2:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200fa4:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200fa6:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200fa8:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200faa:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200fac:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200fae:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200fb0:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200fb2:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200fb4:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200fb6:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200fb8:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200fba:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200fbc:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200fbe:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200fc0:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200fc2:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200fc4:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200fc6:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200fc8:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200fca:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200fcc:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200fce:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200fd0:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200fd2:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200fd4:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200fd6:	812e                	mv	sp,a1
ffffffffc0200fd8:	bdf5                	j	ffffffffc0200ed4 <__trapret>

ffffffffc0200fda <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200fda:	000a6797          	auipc	a5,0xa6
ffffffffc0200fde:	89678793          	addi	a5,a5,-1898 # ffffffffc02a6870 <free_area>
ffffffffc0200fe2:	e79c                	sd	a5,8(a5)
ffffffffc0200fe4:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200fe6:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200fea:	8082                	ret

ffffffffc0200fec <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200fec:	000a6517          	auipc	a0,0xa6
ffffffffc0200ff0:	89456503          	lwu	a0,-1900(a0) # ffffffffc02a6880 <free_area+0x10>
ffffffffc0200ff4:	8082                	ret

ffffffffc0200ff6 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200ff6:	715d                	addi	sp,sp,-80
ffffffffc0200ff8:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200ffa:	000a6417          	auipc	s0,0xa6
ffffffffc0200ffe:	87640413          	addi	s0,s0,-1930 # ffffffffc02a6870 <free_area>
ffffffffc0201002:	641c                	ld	a5,8(s0)
ffffffffc0201004:	e486                	sd	ra,72(sp)
ffffffffc0201006:	fc26                	sd	s1,56(sp)
ffffffffc0201008:	f84a                	sd	s2,48(sp)
ffffffffc020100a:	f44e                	sd	s3,40(sp)
ffffffffc020100c:	f052                	sd	s4,32(sp)
ffffffffc020100e:	ec56                	sd	s5,24(sp)
ffffffffc0201010:	e85a                	sd	s6,16(sp)
ffffffffc0201012:	e45e                	sd	s7,8(sp)
ffffffffc0201014:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201016:	2a878d63          	beq	a5,s0,ffffffffc02012d0 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc020101a:	4481                	li	s1,0
ffffffffc020101c:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020101e:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201022:	8b09                	andi	a4,a4,2
ffffffffc0201024:	2a070a63          	beqz	a4,ffffffffc02012d8 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0201028:	ff87a703          	lw	a4,-8(a5)
ffffffffc020102c:	679c                	ld	a5,8(a5)
ffffffffc020102e:	2905                	addiw	s2,s2,1
ffffffffc0201030:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201032:	fe8796e3          	bne	a5,s0,ffffffffc020101e <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0201036:	89a6                	mv	s3,s1
ffffffffc0201038:	6df000ef          	jal	ra,ffffffffc0201f16 <nr_free_pages>
ffffffffc020103c:	6f351e63          	bne	a0,s3,ffffffffc0201738 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201040:	4505                	li	a0,1
ffffffffc0201042:	657000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc0201046:	8aaa                	mv	s5,a0
ffffffffc0201048:	42050863          	beqz	a0,ffffffffc0201478 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020104c:	4505                	li	a0,1
ffffffffc020104e:	64b000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc0201052:	89aa                	mv	s3,a0
ffffffffc0201054:	70050263          	beqz	a0,ffffffffc0201758 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201058:	4505                	li	a0,1
ffffffffc020105a:	63f000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc020105e:	8a2a                	mv	s4,a0
ffffffffc0201060:	48050c63          	beqz	a0,ffffffffc02014f8 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201064:	293a8a63          	beq	s5,s3,ffffffffc02012f8 <default_check+0x302>
ffffffffc0201068:	28aa8863          	beq	s5,a0,ffffffffc02012f8 <default_check+0x302>
ffffffffc020106c:	28a98663          	beq	s3,a0,ffffffffc02012f8 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201070:	000aa783          	lw	a5,0(s5)
ffffffffc0201074:	2a079263          	bnez	a5,ffffffffc0201318 <default_check+0x322>
ffffffffc0201078:	0009a783          	lw	a5,0(s3)
ffffffffc020107c:	28079e63          	bnez	a5,ffffffffc0201318 <default_check+0x322>
ffffffffc0201080:	411c                	lw	a5,0(a0)
ffffffffc0201082:	28079b63          	bnez	a5,ffffffffc0201318 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0201086:	000aa797          	auipc	a5,0xaa
ffffffffc020108a:	85a7b783          	ld	a5,-1958(a5) # ffffffffc02aa8e0 <pages>
ffffffffc020108e:	40fa8733          	sub	a4,s5,a5
ffffffffc0201092:	00006617          	auipc	a2,0x6
ffffffffc0201096:	7ce63603          	ld	a2,1998(a2) # ffffffffc0207860 <nbase>
ffffffffc020109a:	8719                	srai	a4,a4,0x6
ffffffffc020109c:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020109e:	000aa697          	auipc	a3,0xaa
ffffffffc02010a2:	83a6b683          	ld	a3,-1990(a3) # ffffffffc02aa8d8 <npage>
ffffffffc02010a6:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc02010a8:	0732                	slli	a4,a4,0xc
ffffffffc02010aa:	28d77763          	bgeu	a4,a3,ffffffffc0201338 <default_check+0x342>
    return page - pages + nbase;
ffffffffc02010ae:	40f98733          	sub	a4,s3,a5
ffffffffc02010b2:	8719                	srai	a4,a4,0x6
ffffffffc02010b4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010b6:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010b8:	4cd77063          	bgeu	a4,a3,ffffffffc0201578 <default_check+0x582>
    return page - pages + nbase;
ffffffffc02010bc:	40f507b3          	sub	a5,a0,a5
ffffffffc02010c0:	8799                	srai	a5,a5,0x6
ffffffffc02010c2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010c4:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010c6:	30d7f963          	bgeu	a5,a3,ffffffffc02013d8 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc02010ca:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02010cc:	00043c03          	ld	s8,0(s0)
ffffffffc02010d0:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02010d4:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02010d8:	e400                	sd	s0,8(s0)
ffffffffc02010da:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02010dc:	000a5797          	auipc	a5,0xa5
ffffffffc02010e0:	7a07a223          	sw	zero,1956(a5) # ffffffffc02a6880 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02010e4:	5b5000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc02010e8:	2c051863          	bnez	a0,ffffffffc02013b8 <default_check+0x3c2>
    free_page(p0);
ffffffffc02010ec:	4585                	li	a1,1
ffffffffc02010ee:	8556                	mv	a0,s5
ffffffffc02010f0:	5e7000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    free_page(p1);
ffffffffc02010f4:	4585                	li	a1,1
ffffffffc02010f6:	854e                	mv	a0,s3
ffffffffc02010f8:	5df000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    free_page(p2);
ffffffffc02010fc:	4585                	li	a1,1
ffffffffc02010fe:	8552                	mv	a0,s4
ffffffffc0201100:	5d7000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    assert(nr_free == 3);
ffffffffc0201104:	4818                	lw	a4,16(s0)
ffffffffc0201106:	478d                	li	a5,3
ffffffffc0201108:	28f71863          	bne	a4,a5,ffffffffc0201398 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020110c:	4505                	li	a0,1
ffffffffc020110e:	58b000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc0201112:	89aa                	mv	s3,a0
ffffffffc0201114:	26050263          	beqz	a0,ffffffffc0201378 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201118:	4505                	li	a0,1
ffffffffc020111a:	57f000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc020111e:	8aaa                	mv	s5,a0
ffffffffc0201120:	3a050c63          	beqz	a0,ffffffffc02014d8 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201124:	4505                	li	a0,1
ffffffffc0201126:	573000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc020112a:	8a2a                	mv	s4,a0
ffffffffc020112c:	38050663          	beqz	a0,ffffffffc02014b8 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201130:	4505                	li	a0,1
ffffffffc0201132:	567000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc0201136:	36051163          	bnez	a0,ffffffffc0201498 <default_check+0x4a2>
    free_page(p0);
ffffffffc020113a:	4585                	li	a1,1
ffffffffc020113c:	854e                	mv	a0,s3
ffffffffc020113e:	599000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201142:	641c                	ld	a5,8(s0)
ffffffffc0201144:	20878a63          	beq	a5,s0,ffffffffc0201358 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0201148:	4505                	li	a0,1
ffffffffc020114a:	54f000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc020114e:	30a99563          	bne	s3,a0,ffffffffc0201458 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201152:	4505                	li	a0,1
ffffffffc0201154:	545000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc0201158:	2e051063          	bnez	a0,ffffffffc0201438 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc020115c:	481c                	lw	a5,16(s0)
ffffffffc020115e:	2a079d63          	bnez	a5,ffffffffc0201418 <default_check+0x422>
    free_page(p);
ffffffffc0201162:	854e                	mv	a0,s3
ffffffffc0201164:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201166:	01843023          	sd	s8,0(s0)
ffffffffc020116a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020116e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201172:	565000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    free_page(p1);
ffffffffc0201176:	4585                	li	a1,1
ffffffffc0201178:	8556                	mv	a0,s5
ffffffffc020117a:	55d000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    free_page(p2);
ffffffffc020117e:	4585                	li	a1,1
ffffffffc0201180:	8552                	mv	a0,s4
ffffffffc0201182:	555000ef          	jal	ra,ffffffffc0201ed6 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201186:	4515                	li	a0,5
ffffffffc0201188:	511000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc020118c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020118e:	26050563          	beqz	a0,ffffffffc02013f8 <default_check+0x402>
ffffffffc0201192:	651c                	ld	a5,8(a0)
ffffffffc0201194:	8385                	srli	a5,a5,0x1
ffffffffc0201196:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201198:	54079063          	bnez	a5,ffffffffc02016d8 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020119c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020119e:	00043b03          	ld	s6,0(s0)
ffffffffc02011a2:	00843a83          	ld	s5,8(s0)
ffffffffc02011a6:	e000                	sd	s0,0(s0)
ffffffffc02011a8:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02011aa:	4ef000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc02011ae:	50051563          	bnez	a0,ffffffffc02016b8 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02011b2:	08098a13          	addi	s4,s3,128
ffffffffc02011b6:	8552                	mv	a0,s4
ffffffffc02011b8:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02011ba:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02011be:	000a5797          	auipc	a5,0xa5
ffffffffc02011c2:	6c07a123          	sw	zero,1730(a5) # ffffffffc02a6880 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02011c6:	511000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02011ca:	4511                	li	a0,4
ffffffffc02011cc:	4cd000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc02011d0:	4c051463          	bnez	a0,ffffffffc0201698 <default_check+0x6a2>
ffffffffc02011d4:	0889b783          	ld	a5,136(s3)
ffffffffc02011d8:	8385                	srli	a5,a5,0x1
ffffffffc02011da:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02011dc:	48078e63          	beqz	a5,ffffffffc0201678 <default_check+0x682>
ffffffffc02011e0:	0909a703          	lw	a4,144(s3)
ffffffffc02011e4:	478d                	li	a5,3
ffffffffc02011e6:	48f71963          	bne	a4,a5,ffffffffc0201678 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011ea:	450d                	li	a0,3
ffffffffc02011ec:	4ad000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc02011f0:	8c2a                	mv	s8,a0
ffffffffc02011f2:	46050363          	beqz	a0,ffffffffc0201658 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02011f6:	4505                	li	a0,1
ffffffffc02011f8:	4a1000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc02011fc:	42051e63          	bnez	a0,ffffffffc0201638 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201200:	418a1c63          	bne	s4,s8,ffffffffc0201618 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201204:	4585                	li	a1,1
ffffffffc0201206:	854e                	mv	a0,s3
ffffffffc0201208:	4cf000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    free_pages(p1, 3);
ffffffffc020120c:	458d                	li	a1,3
ffffffffc020120e:	8552                	mv	a0,s4
ffffffffc0201210:	4c7000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
ffffffffc0201214:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201218:	04098c13          	addi	s8,s3,64
ffffffffc020121c:	8385                	srli	a5,a5,0x1
ffffffffc020121e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201220:	3c078c63          	beqz	a5,ffffffffc02015f8 <default_check+0x602>
ffffffffc0201224:	0109a703          	lw	a4,16(s3)
ffffffffc0201228:	4785                	li	a5,1
ffffffffc020122a:	3cf71763          	bne	a4,a5,ffffffffc02015f8 <default_check+0x602>
ffffffffc020122e:	008a3783          	ld	a5,8(s4)
ffffffffc0201232:	8385                	srli	a5,a5,0x1
ffffffffc0201234:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201236:	3a078163          	beqz	a5,ffffffffc02015d8 <default_check+0x5e2>
ffffffffc020123a:	010a2703          	lw	a4,16(s4)
ffffffffc020123e:	478d                	li	a5,3
ffffffffc0201240:	38f71c63          	bne	a4,a5,ffffffffc02015d8 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201244:	4505                	li	a0,1
ffffffffc0201246:	453000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc020124a:	36a99763          	bne	s3,a0,ffffffffc02015b8 <default_check+0x5c2>
    free_page(p0);
ffffffffc020124e:	4585                	li	a1,1
ffffffffc0201250:	487000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201254:	4509                	li	a0,2
ffffffffc0201256:	443000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc020125a:	32aa1f63          	bne	s4,a0,ffffffffc0201598 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020125e:	4589                	li	a1,2
ffffffffc0201260:	477000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    free_page(p2);
ffffffffc0201264:	4585                	li	a1,1
ffffffffc0201266:	8562                	mv	a0,s8
ffffffffc0201268:	46f000ef          	jal	ra,ffffffffc0201ed6 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020126c:	4515                	li	a0,5
ffffffffc020126e:	42b000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc0201272:	89aa                	mv	s3,a0
ffffffffc0201274:	48050263          	beqz	a0,ffffffffc02016f8 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201278:	4505                	li	a0,1
ffffffffc020127a:	41f000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc020127e:	2c051d63          	bnez	a0,ffffffffc0201558 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201282:	481c                	lw	a5,16(s0)
ffffffffc0201284:	2a079a63          	bnez	a5,ffffffffc0201538 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201288:	4595                	li	a1,5
ffffffffc020128a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020128c:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201290:	01643023          	sd	s6,0(s0)
ffffffffc0201294:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201298:	43f000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    return listelm->next;
ffffffffc020129c:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020129e:	00878963          	beq	a5,s0,ffffffffc02012b0 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02012a2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02012a6:	679c                	ld	a5,8(a5)
ffffffffc02012a8:	397d                	addiw	s2,s2,-1
ffffffffc02012aa:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02012ac:	fe879be3          	bne	a5,s0,ffffffffc02012a2 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02012b0:	26091463          	bnez	s2,ffffffffc0201518 <default_check+0x522>
    assert(total == 0);
ffffffffc02012b4:	46049263          	bnez	s1,ffffffffc0201718 <default_check+0x722>
}
ffffffffc02012b8:	60a6                	ld	ra,72(sp)
ffffffffc02012ba:	6406                	ld	s0,64(sp)
ffffffffc02012bc:	74e2                	ld	s1,56(sp)
ffffffffc02012be:	7942                	ld	s2,48(sp)
ffffffffc02012c0:	79a2                	ld	s3,40(sp)
ffffffffc02012c2:	7a02                	ld	s4,32(sp)
ffffffffc02012c4:	6ae2                	ld	s5,24(sp)
ffffffffc02012c6:	6b42                	ld	s6,16(sp)
ffffffffc02012c8:	6ba2                	ld	s7,8(sp)
ffffffffc02012ca:	6c02                	ld	s8,0(sp)
ffffffffc02012cc:	6161                	addi	sp,sp,80
ffffffffc02012ce:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02012d0:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02012d2:	4481                	li	s1,0
ffffffffc02012d4:	4901                	li	s2,0
ffffffffc02012d6:	b38d                	j	ffffffffc0201038 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02012d8:	00005697          	auipc	a3,0x5
ffffffffc02012dc:	eb868693          	addi	a3,a3,-328 # ffffffffc0206190 <commands+0x830>
ffffffffc02012e0:	00005617          	auipc	a2,0x5
ffffffffc02012e4:	c7860613          	addi	a2,a2,-904 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02012e8:	11000593          	li	a1,272
ffffffffc02012ec:	00005517          	auipc	a0,0x5
ffffffffc02012f0:	eb450513          	addi	a0,a0,-332 # ffffffffc02061a0 <commands+0x840>
ffffffffc02012f4:	99aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02012f8:	00005697          	auipc	a3,0x5
ffffffffc02012fc:	f4068693          	addi	a3,a3,-192 # ffffffffc0206238 <commands+0x8d8>
ffffffffc0201300:	00005617          	auipc	a2,0x5
ffffffffc0201304:	c5860613          	addi	a2,a2,-936 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201308:	0db00593          	li	a1,219
ffffffffc020130c:	00005517          	auipc	a0,0x5
ffffffffc0201310:	e9450513          	addi	a0,a0,-364 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201314:	97aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201318:	00005697          	auipc	a3,0x5
ffffffffc020131c:	f4868693          	addi	a3,a3,-184 # ffffffffc0206260 <commands+0x900>
ffffffffc0201320:	00005617          	auipc	a2,0x5
ffffffffc0201324:	c3860613          	addi	a2,a2,-968 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201328:	0dc00593          	li	a1,220
ffffffffc020132c:	00005517          	auipc	a0,0x5
ffffffffc0201330:	e7450513          	addi	a0,a0,-396 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201334:	95aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201338:	00005697          	auipc	a3,0x5
ffffffffc020133c:	f6868693          	addi	a3,a3,-152 # ffffffffc02062a0 <commands+0x940>
ffffffffc0201340:	00005617          	auipc	a2,0x5
ffffffffc0201344:	c1860613          	addi	a2,a2,-1000 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201348:	0de00593          	li	a1,222
ffffffffc020134c:	00005517          	auipc	a0,0x5
ffffffffc0201350:	e5450513          	addi	a0,a0,-428 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201354:	93aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201358:	00005697          	auipc	a3,0x5
ffffffffc020135c:	fd068693          	addi	a3,a3,-48 # ffffffffc0206328 <commands+0x9c8>
ffffffffc0201360:	00005617          	auipc	a2,0x5
ffffffffc0201364:	bf860613          	addi	a2,a2,-1032 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201368:	0f700593          	li	a1,247
ffffffffc020136c:	00005517          	auipc	a0,0x5
ffffffffc0201370:	e3450513          	addi	a0,a0,-460 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201374:	91aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201378:	00005697          	auipc	a3,0x5
ffffffffc020137c:	e6068693          	addi	a3,a3,-416 # ffffffffc02061d8 <commands+0x878>
ffffffffc0201380:	00005617          	auipc	a2,0x5
ffffffffc0201384:	bd860613          	addi	a2,a2,-1064 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201388:	0f000593          	li	a1,240
ffffffffc020138c:	00005517          	auipc	a0,0x5
ffffffffc0201390:	e1450513          	addi	a0,a0,-492 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201394:	8faff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc0201398:	00005697          	auipc	a3,0x5
ffffffffc020139c:	f8068693          	addi	a3,a3,-128 # ffffffffc0206318 <commands+0x9b8>
ffffffffc02013a0:	00005617          	auipc	a2,0x5
ffffffffc02013a4:	bb860613          	addi	a2,a2,-1096 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02013a8:	0ee00593          	li	a1,238
ffffffffc02013ac:	00005517          	auipc	a0,0x5
ffffffffc02013b0:	df450513          	addi	a0,a0,-524 # ffffffffc02061a0 <commands+0x840>
ffffffffc02013b4:	8daff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013b8:	00005697          	auipc	a3,0x5
ffffffffc02013bc:	f4868693          	addi	a3,a3,-184 # ffffffffc0206300 <commands+0x9a0>
ffffffffc02013c0:	00005617          	auipc	a2,0x5
ffffffffc02013c4:	b9860613          	addi	a2,a2,-1128 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02013c8:	0e900593          	li	a1,233
ffffffffc02013cc:	00005517          	auipc	a0,0x5
ffffffffc02013d0:	dd450513          	addi	a0,a0,-556 # ffffffffc02061a0 <commands+0x840>
ffffffffc02013d4:	8baff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02013d8:	00005697          	auipc	a3,0x5
ffffffffc02013dc:	f0868693          	addi	a3,a3,-248 # ffffffffc02062e0 <commands+0x980>
ffffffffc02013e0:	00005617          	auipc	a2,0x5
ffffffffc02013e4:	b7860613          	addi	a2,a2,-1160 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02013e8:	0e000593          	li	a1,224
ffffffffc02013ec:	00005517          	auipc	a0,0x5
ffffffffc02013f0:	db450513          	addi	a0,a0,-588 # ffffffffc02061a0 <commands+0x840>
ffffffffc02013f4:	89aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc02013f8:	00005697          	auipc	a3,0x5
ffffffffc02013fc:	f7868693          	addi	a3,a3,-136 # ffffffffc0206370 <commands+0xa10>
ffffffffc0201400:	00005617          	auipc	a2,0x5
ffffffffc0201404:	b5860613          	addi	a2,a2,-1192 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201408:	11800593          	li	a1,280
ffffffffc020140c:	00005517          	auipc	a0,0x5
ffffffffc0201410:	d9450513          	addi	a0,a0,-620 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201414:	87aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201418:	00005697          	auipc	a3,0x5
ffffffffc020141c:	f4868693          	addi	a3,a3,-184 # ffffffffc0206360 <commands+0xa00>
ffffffffc0201420:	00005617          	auipc	a2,0x5
ffffffffc0201424:	b3860613          	addi	a2,a2,-1224 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201428:	0fd00593          	li	a1,253
ffffffffc020142c:	00005517          	auipc	a0,0x5
ffffffffc0201430:	d7450513          	addi	a0,a0,-652 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201434:	85aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201438:	00005697          	auipc	a3,0x5
ffffffffc020143c:	ec868693          	addi	a3,a3,-312 # ffffffffc0206300 <commands+0x9a0>
ffffffffc0201440:	00005617          	auipc	a2,0x5
ffffffffc0201444:	b1860613          	addi	a2,a2,-1256 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201448:	0fb00593          	li	a1,251
ffffffffc020144c:	00005517          	auipc	a0,0x5
ffffffffc0201450:	d5450513          	addi	a0,a0,-684 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201454:	83aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201458:	00005697          	auipc	a3,0x5
ffffffffc020145c:	ee868693          	addi	a3,a3,-280 # ffffffffc0206340 <commands+0x9e0>
ffffffffc0201460:	00005617          	auipc	a2,0x5
ffffffffc0201464:	af860613          	addi	a2,a2,-1288 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201468:	0fa00593          	li	a1,250
ffffffffc020146c:	00005517          	auipc	a0,0x5
ffffffffc0201470:	d3450513          	addi	a0,a0,-716 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201474:	81aff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201478:	00005697          	auipc	a3,0x5
ffffffffc020147c:	d6068693          	addi	a3,a3,-672 # ffffffffc02061d8 <commands+0x878>
ffffffffc0201480:	00005617          	auipc	a2,0x5
ffffffffc0201484:	ad860613          	addi	a2,a2,-1320 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201488:	0d700593          	li	a1,215
ffffffffc020148c:	00005517          	auipc	a0,0x5
ffffffffc0201490:	d1450513          	addi	a0,a0,-748 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201494:	ffbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201498:	00005697          	auipc	a3,0x5
ffffffffc020149c:	e6868693          	addi	a3,a3,-408 # ffffffffc0206300 <commands+0x9a0>
ffffffffc02014a0:	00005617          	auipc	a2,0x5
ffffffffc02014a4:	ab860613          	addi	a2,a2,-1352 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02014a8:	0f400593          	li	a1,244
ffffffffc02014ac:	00005517          	auipc	a0,0x5
ffffffffc02014b0:	cf450513          	addi	a0,a0,-780 # ffffffffc02061a0 <commands+0x840>
ffffffffc02014b4:	fdbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014b8:	00005697          	auipc	a3,0x5
ffffffffc02014bc:	d6068693          	addi	a3,a3,-672 # ffffffffc0206218 <commands+0x8b8>
ffffffffc02014c0:	00005617          	auipc	a2,0x5
ffffffffc02014c4:	a9860613          	addi	a2,a2,-1384 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02014c8:	0f200593          	li	a1,242
ffffffffc02014cc:	00005517          	auipc	a0,0x5
ffffffffc02014d0:	cd450513          	addi	a0,a0,-812 # ffffffffc02061a0 <commands+0x840>
ffffffffc02014d4:	fbbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014d8:	00005697          	auipc	a3,0x5
ffffffffc02014dc:	d2068693          	addi	a3,a3,-736 # ffffffffc02061f8 <commands+0x898>
ffffffffc02014e0:	00005617          	auipc	a2,0x5
ffffffffc02014e4:	a7860613          	addi	a2,a2,-1416 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02014e8:	0f100593          	li	a1,241
ffffffffc02014ec:	00005517          	auipc	a0,0x5
ffffffffc02014f0:	cb450513          	addi	a0,a0,-844 # ffffffffc02061a0 <commands+0x840>
ffffffffc02014f4:	f9bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014f8:	00005697          	auipc	a3,0x5
ffffffffc02014fc:	d2068693          	addi	a3,a3,-736 # ffffffffc0206218 <commands+0x8b8>
ffffffffc0201500:	00005617          	auipc	a2,0x5
ffffffffc0201504:	a5860613          	addi	a2,a2,-1448 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201508:	0d900593          	li	a1,217
ffffffffc020150c:	00005517          	auipc	a0,0x5
ffffffffc0201510:	c9450513          	addi	a0,a0,-876 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201514:	f7bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc0201518:	00005697          	auipc	a3,0x5
ffffffffc020151c:	fa868693          	addi	a3,a3,-88 # ffffffffc02064c0 <commands+0xb60>
ffffffffc0201520:	00005617          	auipc	a2,0x5
ffffffffc0201524:	a3860613          	addi	a2,a2,-1480 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201528:	14600593          	li	a1,326
ffffffffc020152c:	00005517          	auipc	a0,0x5
ffffffffc0201530:	c7450513          	addi	a0,a0,-908 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201534:	f5bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc0201538:	00005697          	auipc	a3,0x5
ffffffffc020153c:	e2868693          	addi	a3,a3,-472 # ffffffffc0206360 <commands+0xa00>
ffffffffc0201540:	00005617          	auipc	a2,0x5
ffffffffc0201544:	a1860613          	addi	a2,a2,-1512 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201548:	13a00593          	li	a1,314
ffffffffc020154c:	00005517          	auipc	a0,0x5
ffffffffc0201550:	c5450513          	addi	a0,a0,-940 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201554:	f3bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201558:	00005697          	auipc	a3,0x5
ffffffffc020155c:	da868693          	addi	a3,a3,-600 # ffffffffc0206300 <commands+0x9a0>
ffffffffc0201560:	00005617          	auipc	a2,0x5
ffffffffc0201564:	9f860613          	addi	a2,a2,-1544 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201568:	13800593          	li	a1,312
ffffffffc020156c:	00005517          	auipc	a0,0x5
ffffffffc0201570:	c3450513          	addi	a0,a0,-972 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201574:	f1bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201578:	00005697          	auipc	a3,0x5
ffffffffc020157c:	d4868693          	addi	a3,a3,-696 # ffffffffc02062c0 <commands+0x960>
ffffffffc0201580:	00005617          	auipc	a2,0x5
ffffffffc0201584:	9d860613          	addi	a2,a2,-1576 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201588:	0df00593          	li	a1,223
ffffffffc020158c:	00005517          	auipc	a0,0x5
ffffffffc0201590:	c1450513          	addi	a0,a0,-1004 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201594:	efbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201598:	00005697          	auipc	a3,0x5
ffffffffc020159c:	ee868693          	addi	a3,a3,-280 # ffffffffc0206480 <commands+0xb20>
ffffffffc02015a0:	00005617          	auipc	a2,0x5
ffffffffc02015a4:	9b860613          	addi	a2,a2,-1608 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02015a8:	13200593          	li	a1,306
ffffffffc02015ac:	00005517          	auipc	a0,0x5
ffffffffc02015b0:	bf450513          	addi	a0,a0,-1036 # ffffffffc02061a0 <commands+0x840>
ffffffffc02015b4:	edbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02015b8:	00005697          	auipc	a3,0x5
ffffffffc02015bc:	ea868693          	addi	a3,a3,-344 # ffffffffc0206460 <commands+0xb00>
ffffffffc02015c0:	00005617          	auipc	a2,0x5
ffffffffc02015c4:	99860613          	addi	a2,a2,-1640 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02015c8:	13000593          	li	a1,304
ffffffffc02015cc:	00005517          	auipc	a0,0x5
ffffffffc02015d0:	bd450513          	addi	a0,a0,-1068 # ffffffffc02061a0 <commands+0x840>
ffffffffc02015d4:	ebbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02015d8:	00005697          	auipc	a3,0x5
ffffffffc02015dc:	e6068693          	addi	a3,a3,-416 # ffffffffc0206438 <commands+0xad8>
ffffffffc02015e0:	00005617          	auipc	a2,0x5
ffffffffc02015e4:	97860613          	addi	a2,a2,-1672 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02015e8:	12e00593          	li	a1,302
ffffffffc02015ec:	00005517          	auipc	a0,0x5
ffffffffc02015f0:	bb450513          	addi	a0,a0,-1100 # ffffffffc02061a0 <commands+0x840>
ffffffffc02015f4:	e9bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02015f8:	00005697          	auipc	a3,0x5
ffffffffc02015fc:	e1868693          	addi	a3,a3,-488 # ffffffffc0206410 <commands+0xab0>
ffffffffc0201600:	00005617          	auipc	a2,0x5
ffffffffc0201604:	95860613          	addi	a2,a2,-1704 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201608:	12d00593          	li	a1,301
ffffffffc020160c:	00005517          	auipc	a0,0x5
ffffffffc0201610:	b9450513          	addi	a0,a0,-1132 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201614:	e7bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201618:	00005697          	auipc	a3,0x5
ffffffffc020161c:	de868693          	addi	a3,a3,-536 # ffffffffc0206400 <commands+0xaa0>
ffffffffc0201620:	00005617          	auipc	a2,0x5
ffffffffc0201624:	93860613          	addi	a2,a2,-1736 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201628:	12800593          	li	a1,296
ffffffffc020162c:	00005517          	auipc	a0,0x5
ffffffffc0201630:	b7450513          	addi	a0,a0,-1164 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201634:	e5bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201638:	00005697          	auipc	a3,0x5
ffffffffc020163c:	cc868693          	addi	a3,a3,-824 # ffffffffc0206300 <commands+0x9a0>
ffffffffc0201640:	00005617          	auipc	a2,0x5
ffffffffc0201644:	91860613          	addi	a2,a2,-1768 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201648:	12700593          	li	a1,295
ffffffffc020164c:	00005517          	auipc	a0,0x5
ffffffffc0201650:	b5450513          	addi	a0,a0,-1196 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201654:	e3bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201658:	00005697          	auipc	a3,0x5
ffffffffc020165c:	d8868693          	addi	a3,a3,-632 # ffffffffc02063e0 <commands+0xa80>
ffffffffc0201660:	00005617          	auipc	a2,0x5
ffffffffc0201664:	8f860613          	addi	a2,a2,-1800 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201668:	12600593          	li	a1,294
ffffffffc020166c:	00005517          	auipc	a0,0x5
ffffffffc0201670:	b3450513          	addi	a0,a0,-1228 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201674:	e1bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201678:	00005697          	auipc	a3,0x5
ffffffffc020167c:	d3868693          	addi	a3,a3,-712 # ffffffffc02063b0 <commands+0xa50>
ffffffffc0201680:	00005617          	auipc	a2,0x5
ffffffffc0201684:	8d860613          	addi	a2,a2,-1832 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201688:	12500593          	li	a1,293
ffffffffc020168c:	00005517          	auipc	a0,0x5
ffffffffc0201690:	b1450513          	addi	a0,a0,-1260 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201694:	dfbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201698:	00005697          	auipc	a3,0x5
ffffffffc020169c:	d0068693          	addi	a3,a3,-768 # ffffffffc0206398 <commands+0xa38>
ffffffffc02016a0:	00005617          	auipc	a2,0x5
ffffffffc02016a4:	8b860613          	addi	a2,a2,-1864 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02016a8:	12400593          	li	a1,292
ffffffffc02016ac:	00005517          	auipc	a0,0x5
ffffffffc02016b0:	af450513          	addi	a0,a0,-1292 # ffffffffc02061a0 <commands+0x840>
ffffffffc02016b4:	ddbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016b8:	00005697          	auipc	a3,0x5
ffffffffc02016bc:	c4868693          	addi	a3,a3,-952 # ffffffffc0206300 <commands+0x9a0>
ffffffffc02016c0:	00005617          	auipc	a2,0x5
ffffffffc02016c4:	89860613          	addi	a2,a2,-1896 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02016c8:	11e00593          	li	a1,286
ffffffffc02016cc:	00005517          	auipc	a0,0x5
ffffffffc02016d0:	ad450513          	addi	a0,a0,-1324 # ffffffffc02061a0 <commands+0x840>
ffffffffc02016d4:	dbbfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc02016d8:	00005697          	auipc	a3,0x5
ffffffffc02016dc:	ca868693          	addi	a3,a3,-856 # ffffffffc0206380 <commands+0xa20>
ffffffffc02016e0:	00005617          	auipc	a2,0x5
ffffffffc02016e4:	87860613          	addi	a2,a2,-1928 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02016e8:	11900593          	li	a1,281
ffffffffc02016ec:	00005517          	auipc	a0,0x5
ffffffffc02016f0:	ab450513          	addi	a0,a0,-1356 # ffffffffc02061a0 <commands+0x840>
ffffffffc02016f4:	d9bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02016f8:	00005697          	auipc	a3,0x5
ffffffffc02016fc:	da868693          	addi	a3,a3,-600 # ffffffffc02064a0 <commands+0xb40>
ffffffffc0201700:	00005617          	auipc	a2,0x5
ffffffffc0201704:	85860613          	addi	a2,a2,-1960 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201708:	13700593          	li	a1,311
ffffffffc020170c:	00005517          	auipc	a0,0x5
ffffffffc0201710:	a9450513          	addi	a0,a0,-1388 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201714:	d7bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc0201718:	00005697          	auipc	a3,0x5
ffffffffc020171c:	db868693          	addi	a3,a3,-584 # ffffffffc02064d0 <commands+0xb70>
ffffffffc0201720:	00005617          	auipc	a2,0x5
ffffffffc0201724:	83860613          	addi	a2,a2,-1992 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201728:	14700593          	li	a1,327
ffffffffc020172c:	00005517          	auipc	a0,0x5
ffffffffc0201730:	a7450513          	addi	a0,a0,-1420 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201734:	d5bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc0201738:	00005697          	auipc	a3,0x5
ffffffffc020173c:	a8068693          	addi	a3,a3,-1408 # ffffffffc02061b8 <commands+0x858>
ffffffffc0201740:	00005617          	auipc	a2,0x5
ffffffffc0201744:	81860613          	addi	a2,a2,-2024 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201748:	11300593          	li	a1,275
ffffffffc020174c:	00005517          	auipc	a0,0x5
ffffffffc0201750:	a5450513          	addi	a0,a0,-1452 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201754:	d3bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201758:	00005697          	auipc	a3,0x5
ffffffffc020175c:	aa068693          	addi	a3,a3,-1376 # ffffffffc02061f8 <commands+0x898>
ffffffffc0201760:	00004617          	auipc	a2,0x4
ffffffffc0201764:	7f860613          	addi	a2,a2,2040 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201768:	0d800593          	li	a1,216
ffffffffc020176c:	00005517          	auipc	a0,0x5
ffffffffc0201770:	a3450513          	addi	a0,a0,-1484 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201774:	d1bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201778 <default_free_pages>:
{
ffffffffc0201778:	1141                	addi	sp,sp,-16
ffffffffc020177a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020177c:	14058463          	beqz	a1,ffffffffc02018c4 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201780:	00659693          	slli	a3,a1,0x6
ffffffffc0201784:	96aa                	add	a3,a3,a0
ffffffffc0201786:	87aa                	mv	a5,a0
ffffffffc0201788:	02d50263          	beq	a0,a3,ffffffffc02017ac <default_free_pages+0x34>
ffffffffc020178c:	6798                	ld	a4,8(a5)
ffffffffc020178e:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201790:	10071a63          	bnez	a4,ffffffffc02018a4 <default_free_pages+0x12c>
ffffffffc0201794:	6798                	ld	a4,8(a5)
ffffffffc0201796:	8b09                	andi	a4,a4,2
ffffffffc0201798:	10071663          	bnez	a4,ffffffffc02018a4 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc020179c:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02017a0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02017a4:	04078793          	addi	a5,a5,64
ffffffffc02017a8:	fed792e3          	bne	a5,a3,ffffffffc020178c <default_free_pages+0x14>
    base->property = n;
ffffffffc02017ac:	2581                	sext.w	a1,a1
ffffffffc02017ae:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02017b0:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017b4:	4789                	li	a5,2
ffffffffc02017b6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02017ba:	000a5697          	auipc	a3,0xa5
ffffffffc02017be:	0b668693          	addi	a3,a3,182 # ffffffffc02a6870 <free_area>
ffffffffc02017c2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02017c4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02017c6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02017ca:	9db9                	addw	a1,a1,a4
ffffffffc02017cc:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02017ce:	0ad78463          	beq	a5,a3,ffffffffc0201876 <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc02017d2:	fe878713          	addi	a4,a5,-24
ffffffffc02017d6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02017da:	4581                	li	a1,0
            if (base < page)
ffffffffc02017dc:	00e56a63          	bltu	a0,a4,ffffffffc02017f0 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02017e0:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02017e2:	04d70c63          	beq	a4,a3,ffffffffc020183a <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc02017e6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017e8:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017ec:	fee57ae3          	bgeu	a0,a4,ffffffffc02017e0 <default_free_pages+0x68>
ffffffffc02017f0:	c199                	beqz	a1,ffffffffc02017f6 <default_free_pages+0x7e>
ffffffffc02017f2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017f6:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02017f8:	e390                	sd	a2,0(a5)
ffffffffc02017fa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02017fc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017fe:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0201800:	00d70d63          	beq	a4,a3,ffffffffc020181a <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201804:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201808:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc020180c:	02059813          	slli	a6,a1,0x20
ffffffffc0201810:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201814:	97b2                	add	a5,a5,a2
ffffffffc0201816:	02f50c63          	beq	a0,a5,ffffffffc020184e <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020181a:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc020181c:	00d78c63          	beq	a5,a3,ffffffffc0201834 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201820:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201822:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc0201826:	02061593          	slli	a1,a2,0x20
ffffffffc020182a:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020182e:	972a                	add	a4,a4,a0
ffffffffc0201830:	04e68a63          	beq	a3,a4,ffffffffc0201884 <default_free_pages+0x10c>
}
ffffffffc0201834:	60a2                	ld	ra,8(sp)
ffffffffc0201836:	0141                	addi	sp,sp,16
ffffffffc0201838:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020183a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020183c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020183e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201840:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201842:	02d70763          	beq	a4,a3,ffffffffc0201870 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0201846:	8832                	mv	a6,a2
ffffffffc0201848:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020184a:	87ba                	mv	a5,a4
ffffffffc020184c:	bf71                	j	ffffffffc02017e8 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020184e:	491c                	lw	a5,16(a0)
ffffffffc0201850:	9dbd                	addw	a1,a1,a5
ffffffffc0201852:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201856:	57f5                	li	a5,-3
ffffffffc0201858:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020185c:	01853803          	ld	a6,24(a0)
ffffffffc0201860:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201862:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201864:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201868:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020186a:	0105b023          	sd	a6,0(a1)
ffffffffc020186e:	b77d                	j	ffffffffc020181c <default_free_pages+0xa4>
ffffffffc0201870:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201872:	873e                	mv	a4,a5
ffffffffc0201874:	bf41                	j	ffffffffc0201804 <default_free_pages+0x8c>
}
ffffffffc0201876:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201878:	e390                	sd	a2,0(a5)
ffffffffc020187a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020187c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020187e:	ed1c                	sd	a5,24(a0)
ffffffffc0201880:	0141                	addi	sp,sp,16
ffffffffc0201882:	8082                	ret
            base->property += p->property;
ffffffffc0201884:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201888:	ff078693          	addi	a3,a5,-16
ffffffffc020188c:	9e39                	addw	a2,a2,a4
ffffffffc020188e:	c910                	sw	a2,16(a0)
ffffffffc0201890:	5775                	li	a4,-3
ffffffffc0201892:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201896:	6398                	ld	a4,0(a5)
ffffffffc0201898:	679c                	ld	a5,8(a5)
}
ffffffffc020189a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020189c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020189e:	e398                	sd	a4,0(a5)
ffffffffc02018a0:	0141                	addi	sp,sp,16
ffffffffc02018a2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02018a4:	00005697          	auipc	a3,0x5
ffffffffc02018a8:	c4468693          	addi	a3,a3,-956 # ffffffffc02064e8 <commands+0xb88>
ffffffffc02018ac:	00004617          	auipc	a2,0x4
ffffffffc02018b0:	6ac60613          	addi	a2,a2,1708 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02018b4:	09400593          	li	a1,148
ffffffffc02018b8:	00005517          	auipc	a0,0x5
ffffffffc02018bc:	8e850513          	addi	a0,a0,-1816 # ffffffffc02061a0 <commands+0x840>
ffffffffc02018c0:	bcffe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc02018c4:	00005697          	auipc	a3,0x5
ffffffffc02018c8:	c1c68693          	addi	a3,a3,-996 # ffffffffc02064e0 <commands+0xb80>
ffffffffc02018cc:	00004617          	auipc	a2,0x4
ffffffffc02018d0:	68c60613          	addi	a2,a2,1676 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02018d4:	09000593          	li	a1,144
ffffffffc02018d8:	00005517          	auipc	a0,0x5
ffffffffc02018dc:	8c850513          	addi	a0,a0,-1848 # ffffffffc02061a0 <commands+0x840>
ffffffffc02018e0:	baffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02018e4 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02018e4:	c941                	beqz	a0,ffffffffc0201974 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc02018e6:	000a5597          	auipc	a1,0xa5
ffffffffc02018ea:	f8a58593          	addi	a1,a1,-118 # ffffffffc02a6870 <free_area>
ffffffffc02018ee:	0105a803          	lw	a6,16(a1)
ffffffffc02018f2:	872a                	mv	a4,a0
ffffffffc02018f4:	02081793          	slli	a5,a6,0x20
ffffffffc02018f8:	9381                	srli	a5,a5,0x20
ffffffffc02018fa:	00a7ee63          	bltu	a5,a0,ffffffffc0201916 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02018fe:	87ae                	mv	a5,a1
ffffffffc0201900:	a801                	j	ffffffffc0201910 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201902:	ff87a683          	lw	a3,-8(a5)
ffffffffc0201906:	02069613          	slli	a2,a3,0x20
ffffffffc020190a:	9201                	srli	a2,a2,0x20
ffffffffc020190c:	00e67763          	bgeu	a2,a4,ffffffffc020191a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201910:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201912:	feb798e3          	bne	a5,a1,ffffffffc0201902 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201916:	4501                	li	a0,0
}
ffffffffc0201918:	8082                	ret
    return listelm->prev;
ffffffffc020191a:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020191e:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201922:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201926:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc020192a:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020192e:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201932:	02c77863          	bgeu	a4,a2,ffffffffc0201962 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0201936:	071a                	slli	a4,a4,0x6
ffffffffc0201938:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020193a:	41c686bb          	subw	a3,a3,t3
ffffffffc020193e:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201940:	00870613          	addi	a2,a4,8
ffffffffc0201944:	4689                	li	a3,2
ffffffffc0201946:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020194a:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020194e:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201952:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201956:	e290                	sd	a2,0(a3)
ffffffffc0201958:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020195c:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020195e:	01173c23          	sd	a7,24(a4)
ffffffffc0201962:	41c8083b          	subw	a6,a6,t3
ffffffffc0201966:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020196a:	5775                	li	a4,-3
ffffffffc020196c:	17c1                	addi	a5,a5,-16
ffffffffc020196e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201972:	8082                	ret
{
ffffffffc0201974:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201976:	00005697          	auipc	a3,0x5
ffffffffc020197a:	b6a68693          	addi	a3,a3,-1174 # ffffffffc02064e0 <commands+0xb80>
ffffffffc020197e:	00004617          	auipc	a2,0x4
ffffffffc0201982:	5da60613          	addi	a2,a2,1498 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201986:	06c00593          	li	a1,108
ffffffffc020198a:	00005517          	auipc	a0,0x5
ffffffffc020198e:	81650513          	addi	a0,a0,-2026 # ffffffffc02061a0 <commands+0x840>
{
ffffffffc0201992:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201994:	afbfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201998 <default_init_memmap>:
{
ffffffffc0201998:	1141                	addi	sp,sp,-16
ffffffffc020199a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020199c:	c5f1                	beqz	a1,ffffffffc0201a68 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc020199e:	00659693          	slli	a3,a1,0x6
ffffffffc02019a2:	96aa                	add	a3,a3,a0
ffffffffc02019a4:	87aa                	mv	a5,a0
ffffffffc02019a6:	00d50f63          	beq	a0,a3,ffffffffc02019c4 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02019aa:	6798                	ld	a4,8(a5)
ffffffffc02019ac:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc02019ae:	cf49                	beqz	a4,ffffffffc0201a48 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02019b0:	0007a823          	sw	zero,16(a5)
ffffffffc02019b4:	0007b423          	sd	zero,8(a5)
ffffffffc02019b8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02019bc:	04078793          	addi	a5,a5,64
ffffffffc02019c0:	fed795e3          	bne	a5,a3,ffffffffc02019aa <default_init_memmap+0x12>
    base->property = n;
ffffffffc02019c4:	2581                	sext.w	a1,a1
ffffffffc02019c6:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019c8:	4789                	li	a5,2
ffffffffc02019ca:	00850713          	addi	a4,a0,8
ffffffffc02019ce:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02019d2:	000a5697          	auipc	a3,0xa5
ffffffffc02019d6:	e9e68693          	addi	a3,a3,-354 # ffffffffc02a6870 <free_area>
ffffffffc02019da:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02019dc:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02019de:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02019e2:	9db9                	addw	a1,a1,a4
ffffffffc02019e4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02019e6:	04d78a63          	beq	a5,a3,ffffffffc0201a3a <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc02019ea:	fe878713          	addi	a4,a5,-24
ffffffffc02019ee:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02019f2:	4581                	li	a1,0
            if (base < page)
ffffffffc02019f4:	00e56a63          	bltu	a0,a4,ffffffffc0201a08 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02019f8:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019fa:	02d70263          	beq	a4,a3,ffffffffc0201a1e <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc02019fe:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201a00:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201a04:	fee57ae3          	bgeu	a0,a4,ffffffffc02019f8 <default_init_memmap+0x60>
ffffffffc0201a08:	c199                	beqz	a1,ffffffffc0201a0e <default_init_memmap+0x76>
ffffffffc0201a0a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201a0e:	6398                	ld	a4,0(a5)
}
ffffffffc0201a10:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201a12:	e390                	sd	a2,0(a5)
ffffffffc0201a14:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201a16:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a18:	ed18                	sd	a4,24(a0)
ffffffffc0201a1a:	0141                	addi	sp,sp,16
ffffffffc0201a1c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201a1e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a20:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a22:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a24:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a26:	00d70663          	beq	a4,a3,ffffffffc0201a32 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201a2a:	8832                	mv	a6,a2
ffffffffc0201a2c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201a2e:	87ba                	mv	a5,a4
ffffffffc0201a30:	bfc1                	j	ffffffffc0201a00 <default_init_memmap+0x68>
}
ffffffffc0201a32:	60a2                	ld	ra,8(sp)
ffffffffc0201a34:	e290                	sd	a2,0(a3)
ffffffffc0201a36:	0141                	addi	sp,sp,16
ffffffffc0201a38:	8082                	ret
ffffffffc0201a3a:	60a2                	ld	ra,8(sp)
ffffffffc0201a3c:	e390                	sd	a2,0(a5)
ffffffffc0201a3e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a40:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a42:	ed1c                	sd	a5,24(a0)
ffffffffc0201a44:	0141                	addi	sp,sp,16
ffffffffc0201a46:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a48:	00005697          	auipc	a3,0x5
ffffffffc0201a4c:	ac868693          	addi	a3,a3,-1336 # ffffffffc0206510 <commands+0xbb0>
ffffffffc0201a50:	00004617          	auipc	a2,0x4
ffffffffc0201a54:	50860613          	addi	a2,a2,1288 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201a58:	04b00593          	li	a1,75
ffffffffc0201a5c:	00004517          	auipc	a0,0x4
ffffffffc0201a60:	74450513          	addi	a0,a0,1860 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201a64:	a2bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201a68:	00005697          	auipc	a3,0x5
ffffffffc0201a6c:	a7868693          	addi	a3,a3,-1416 # ffffffffc02064e0 <commands+0xb80>
ffffffffc0201a70:	00004617          	auipc	a2,0x4
ffffffffc0201a74:	4e860613          	addi	a2,a2,1256 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201a78:	04700593          	li	a1,71
ffffffffc0201a7c:	00004517          	auipc	a0,0x4
ffffffffc0201a80:	72450513          	addi	a0,a0,1828 # ffffffffc02061a0 <commands+0x840>
ffffffffc0201a84:	a0bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201a88 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a88:	c94d                	beqz	a0,ffffffffc0201b3a <slob_free+0xb2>
{
ffffffffc0201a8a:	1141                	addi	sp,sp,-16
ffffffffc0201a8c:	e022                	sd	s0,0(sp)
ffffffffc0201a8e:	e406                	sd	ra,8(sp)
ffffffffc0201a90:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201a92:	e9c1                	bnez	a1,ffffffffc0201b22 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a94:	100027f3          	csrr	a5,sstatus
ffffffffc0201a98:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a9a:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a9c:	ebd9                	bnez	a5,ffffffffc0201b32 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a9e:	000a5617          	auipc	a2,0xa5
ffffffffc0201aa2:	9c260613          	addi	a2,a2,-1598 # ffffffffc02a6460 <slobfree>
ffffffffc0201aa6:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201aa8:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201aaa:	679c                	ld	a5,8(a5)
ffffffffc0201aac:	02877a63          	bgeu	a4,s0,ffffffffc0201ae0 <slob_free+0x58>
ffffffffc0201ab0:	00f46463          	bltu	s0,a5,ffffffffc0201ab8 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ab4:	fef76ae3          	bltu	a4,a5,ffffffffc0201aa8 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201ab8:	400c                	lw	a1,0(s0)
ffffffffc0201aba:	00459693          	slli	a3,a1,0x4
ffffffffc0201abe:	96a2                	add	a3,a3,s0
ffffffffc0201ac0:	02d78a63          	beq	a5,a3,ffffffffc0201af4 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201ac4:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201ac6:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201ac8:	00469793          	slli	a5,a3,0x4
ffffffffc0201acc:	97ba                	add	a5,a5,a4
ffffffffc0201ace:	02f40e63          	beq	s0,a5,ffffffffc0201b0a <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201ad2:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201ad4:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201ad6:	e129                	bnez	a0,ffffffffc0201b18 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201ad8:	60a2                	ld	ra,8(sp)
ffffffffc0201ada:	6402                	ld	s0,0(sp)
ffffffffc0201adc:	0141                	addi	sp,sp,16
ffffffffc0201ade:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ae0:	fcf764e3          	bltu	a4,a5,ffffffffc0201aa8 <slob_free+0x20>
ffffffffc0201ae4:	fcf472e3          	bgeu	s0,a5,ffffffffc0201aa8 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201ae8:	400c                	lw	a1,0(s0)
ffffffffc0201aea:	00459693          	slli	a3,a1,0x4
ffffffffc0201aee:	96a2                	add	a3,a3,s0
ffffffffc0201af0:	fcd79ae3          	bne	a5,a3,ffffffffc0201ac4 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201af4:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201af6:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201af8:	9db5                	addw	a1,a1,a3
ffffffffc0201afa:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201afc:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201afe:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b00:	00469793          	slli	a5,a3,0x4
ffffffffc0201b04:	97ba                	add	a5,a5,a4
ffffffffc0201b06:	fcf416e3          	bne	s0,a5,ffffffffc0201ad2 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201b0a:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201b0c:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201b0e:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201b10:	9ebd                	addw	a3,a3,a5
ffffffffc0201b12:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201b14:	e70c                	sd	a1,8(a4)
ffffffffc0201b16:	d169                	beqz	a0,ffffffffc0201ad8 <slob_free+0x50>
}
ffffffffc0201b18:	6402                	ld	s0,0(sp)
ffffffffc0201b1a:	60a2                	ld	ra,8(sp)
ffffffffc0201b1c:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201b1e:	e91fe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201b22:	25bd                	addiw	a1,a1,15
ffffffffc0201b24:	8191                	srli	a1,a1,0x4
ffffffffc0201b26:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b28:	100027f3          	csrr	a5,sstatus
ffffffffc0201b2c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b2e:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b30:	d7bd                	beqz	a5,ffffffffc0201a9e <slob_free+0x16>
        intr_disable();
ffffffffc0201b32:	e83fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201b36:	4505                	li	a0,1
ffffffffc0201b38:	b79d                	j	ffffffffc0201a9e <slob_free+0x16>
ffffffffc0201b3a:	8082                	ret

ffffffffc0201b3c <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b3c:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b3e:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b40:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b44:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b46:	352000ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
	if (!page)
ffffffffc0201b4a:	c91d                	beqz	a0,ffffffffc0201b80 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b4c:	000a9697          	auipc	a3,0xa9
ffffffffc0201b50:	d946b683          	ld	a3,-620(a3) # ffffffffc02aa8e0 <pages>
ffffffffc0201b54:	8d15                	sub	a0,a0,a3
ffffffffc0201b56:	8519                	srai	a0,a0,0x6
ffffffffc0201b58:	00006697          	auipc	a3,0x6
ffffffffc0201b5c:	d086b683          	ld	a3,-760(a3) # ffffffffc0207860 <nbase>
ffffffffc0201b60:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201b62:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b66:	83b1                	srli	a5,a5,0xc
ffffffffc0201b68:	000a9717          	auipc	a4,0xa9
ffffffffc0201b6c:	d7073703          	ld	a4,-656(a4) # ffffffffc02aa8d8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b70:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201b72:	00e7fa63          	bgeu	a5,a4,ffffffffc0201b86 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201b76:	000a9697          	auipc	a3,0xa9
ffffffffc0201b7a:	d7a6b683          	ld	a3,-646(a3) # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0201b7e:	9536                	add	a0,a0,a3
}
ffffffffc0201b80:	60a2                	ld	ra,8(sp)
ffffffffc0201b82:	0141                	addi	sp,sp,16
ffffffffc0201b84:	8082                	ret
ffffffffc0201b86:	86aa                	mv	a3,a0
ffffffffc0201b88:	00005617          	auipc	a2,0x5
ffffffffc0201b8c:	9e860613          	addi	a2,a2,-1560 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc0201b90:	07100593          	li	a1,113
ffffffffc0201b94:	00005517          	auipc	a0,0x5
ffffffffc0201b98:	a0450513          	addi	a0,a0,-1532 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc0201b9c:	8f3fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ba0 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201ba0:	1101                	addi	sp,sp,-32
ffffffffc0201ba2:	ec06                	sd	ra,24(sp)
ffffffffc0201ba4:	e822                	sd	s0,16(sp)
ffffffffc0201ba6:	e426                	sd	s1,8(sp)
ffffffffc0201ba8:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201baa:	01050713          	addi	a4,a0,16
ffffffffc0201bae:	6785                	lui	a5,0x1
ffffffffc0201bb0:	0cf77363          	bgeu	a4,a5,ffffffffc0201c76 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201bb4:	00f50493          	addi	s1,a0,15
ffffffffc0201bb8:	8091                	srli	s1,s1,0x4
ffffffffc0201bba:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bbc:	10002673          	csrr	a2,sstatus
ffffffffc0201bc0:	8a09                	andi	a2,a2,2
ffffffffc0201bc2:	e25d                	bnez	a2,ffffffffc0201c68 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201bc4:	000a5917          	auipc	s2,0xa5
ffffffffc0201bc8:	89c90913          	addi	s2,s2,-1892 # ffffffffc02a6460 <slobfree>
ffffffffc0201bcc:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bd0:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201bd2:	4398                	lw	a4,0(a5)
ffffffffc0201bd4:	08975e63          	bge	a4,s1,ffffffffc0201c70 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201bd8:	00f68b63          	beq	a3,a5,ffffffffc0201bee <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bdc:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201bde:	4018                	lw	a4,0(s0)
ffffffffc0201be0:	02975a63          	bge	a4,s1,ffffffffc0201c14 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201be4:	00093683          	ld	a3,0(s2)
ffffffffc0201be8:	87a2                	mv	a5,s0
ffffffffc0201bea:	fef699e3          	bne	a3,a5,ffffffffc0201bdc <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201bee:	ee31                	bnez	a2,ffffffffc0201c4a <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201bf0:	4501                	li	a0,0
ffffffffc0201bf2:	f4bff0ef          	jal	ra,ffffffffc0201b3c <__slob_get_free_pages.constprop.0>
ffffffffc0201bf6:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201bf8:	cd05                	beqz	a0,ffffffffc0201c30 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201bfa:	6585                	lui	a1,0x1
ffffffffc0201bfc:	e8dff0ef          	jal	ra,ffffffffc0201a88 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c00:	10002673          	csrr	a2,sstatus
ffffffffc0201c04:	8a09                	andi	a2,a2,2
ffffffffc0201c06:	ee05                	bnez	a2,ffffffffc0201c3e <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201c08:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c0c:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c0e:	4018                	lw	a4,0(s0)
ffffffffc0201c10:	fc974ae3          	blt	a4,s1,ffffffffc0201be4 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c14:	04e48763          	beq	s1,a4,ffffffffc0201c62 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201c18:	00449693          	slli	a3,s1,0x4
ffffffffc0201c1c:	96a2                	add	a3,a3,s0
ffffffffc0201c1e:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201c20:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201c22:	9f05                	subw	a4,a4,s1
ffffffffc0201c24:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201c26:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201c28:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201c2a:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201c2e:	e20d                	bnez	a2,ffffffffc0201c50 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201c30:	60e2                	ld	ra,24(sp)
ffffffffc0201c32:	8522                	mv	a0,s0
ffffffffc0201c34:	6442                	ld	s0,16(sp)
ffffffffc0201c36:	64a2                	ld	s1,8(sp)
ffffffffc0201c38:	6902                	ld	s2,0(sp)
ffffffffc0201c3a:	6105                	addi	sp,sp,32
ffffffffc0201c3c:	8082                	ret
        intr_disable();
ffffffffc0201c3e:	d77fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201c42:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201c46:	4605                	li	a2,1
ffffffffc0201c48:	b7d1                	j	ffffffffc0201c0c <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201c4a:	d65fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201c4e:	b74d                	j	ffffffffc0201bf0 <slob_alloc.constprop.0+0x50>
ffffffffc0201c50:	d5ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201c54:	60e2                	ld	ra,24(sp)
ffffffffc0201c56:	8522                	mv	a0,s0
ffffffffc0201c58:	6442                	ld	s0,16(sp)
ffffffffc0201c5a:	64a2                	ld	s1,8(sp)
ffffffffc0201c5c:	6902                	ld	s2,0(sp)
ffffffffc0201c5e:	6105                	addi	sp,sp,32
ffffffffc0201c60:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c62:	6418                	ld	a4,8(s0)
ffffffffc0201c64:	e798                	sd	a4,8(a5)
ffffffffc0201c66:	b7d1                	j	ffffffffc0201c2a <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201c68:	d4dfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201c6c:	4605                	li	a2,1
ffffffffc0201c6e:	bf99                	j	ffffffffc0201bc4 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201c70:	843e                	mv	s0,a5
ffffffffc0201c72:	87b6                	mv	a5,a3
ffffffffc0201c74:	b745                	j	ffffffffc0201c14 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c76:	00005697          	auipc	a3,0x5
ffffffffc0201c7a:	93268693          	addi	a3,a3,-1742 # ffffffffc02065a8 <default_pmm_manager+0x70>
ffffffffc0201c7e:	00004617          	auipc	a2,0x4
ffffffffc0201c82:	2da60613          	addi	a2,a2,730 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0201c86:	06300593          	li	a1,99
ffffffffc0201c8a:	00005517          	auipc	a0,0x5
ffffffffc0201c8e:	93e50513          	addi	a0,a0,-1730 # ffffffffc02065c8 <default_pmm_manager+0x90>
ffffffffc0201c92:	ffcfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201c96 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201c96:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201c98:	00005517          	auipc	a0,0x5
ffffffffc0201c9c:	94850513          	addi	a0,a0,-1720 # ffffffffc02065e0 <default_pmm_manager+0xa8>
{
ffffffffc0201ca0:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201ca2:	cf2fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201ca6:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ca8:	00005517          	auipc	a0,0x5
ffffffffc0201cac:	95050513          	addi	a0,a0,-1712 # ffffffffc02065f8 <default_pmm_manager+0xc0>
}
ffffffffc0201cb0:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cb2:	ce2fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201cb6 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201cb6:	4501                	li	a0,0
ffffffffc0201cb8:	8082                	ret

ffffffffc0201cba <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201cba:	1101                	addi	sp,sp,-32
ffffffffc0201cbc:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cbe:	6905                	lui	s2,0x1
{
ffffffffc0201cc0:	e822                	sd	s0,16(sp)
ffffffffc0201cc2:	ec06                	sd	ra,24(sp)
ffffffffc0201cc4:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cc6:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bd9>
{
ffffffffc0201cca:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ccc:	04a7f963          	bgeu	a5,a0,ffffffffc0201d1e <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201cd0:	4561                	li	a0,24
ffffffffc0201cd2:	ecfff0ef          	jal	ra,ffffffffc0201ba0 <slob_alloc.constprop.0>
ffffffffc0201cd6:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201cd8:	c929                	beqz	a0,ffffffffc0201d2a <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201cda:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201cde:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ce0:	00f95763          	bge	s2,a5,ffffffffc0201cee <kmalloc+0x34>
ffffffffc0201ce4:	6705                	lui	a4,0x1
ffffffffc0201ce6:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201ce8:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201cea:	fef74ee3          	blt	a4,a5,ffffffffc0201ce6 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201cee:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201cf0:	e4dff0ef          	jal	ra,ffffffffc0201b3c <__slob_get_free_pages.constprop.0>
ffffffffc0201cf4:	e488                	sd	a0,8(s1)
ffffffffc0201cf6:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201cf8:	c525                	beqz	a0,ffffffffc0201d60 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201cfa:	100027f3          	csrr	a5,sstatus
ffffffffc0201cfe:	8b89                	andi	a5,a5,2
ffffffffc0201d00:	ef8d                	bnez	a5,ffffffffc0201d3a <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201d02:	000a9797          	auipc	a5,0xa9
ffffffffc0201d06:	bbe78793          	addi	a5,a5,-1090 # ffffffffc02aa8c0 <bigblocks>
ffffffffc0201d0a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d0c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d0e:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201d10:	60e2                	ld	ra,24(sp)
ffffffffc0201d12:	8522                	mv	a0,s0
ffffffffc0201d14:	6442                	ld	s0,16(sp)
ffffffffc0201d16:	64a2                	ld	s1,8(sp)
ffffffffc0201d18:	6902                	ld	s2,0(sp)
ffffffffc0201d1a:	6105                	addi	sp,sp,32
ffffffffc0201d1c:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d1e:	0541                	addi	a0,a0,16
ffffffffc0201d20:	e81ff0ef          	jal	ra,ffffffffc0201ba0 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d24:	01050413          	addi	s0,a0,16
ffffffffc0201d28:	f565                	bnez	a0,ffffffffc0201d10 <kmalloc+0x56>
ffffffffc0201d2a:	4401                	li	s0,0
}
ffffffffc0201d2c:	60e2                	ld	ra,24(sp)
ffffffffc0201d2e:	8522                	mv	a0,s0
ffffffffc0201d30:	6442                	ld	s0,16(sp)
ffffffffc0201d32:	64a2                	ld	s1,8(sp)
ffffffffc0201d34:	6902                	ld	s2,0(sp)
ffffffffc0201d36:	6105                	addi	sp,sp,32
ffffffffc0201d38:	8082                	ret
        intr_disable();
ffffffffc0201d3a:	c7bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d3e:	000a9797          	auipc	a5,0xa9
ffffffffc0201d42:	b8278793          	addi	a5,a5,-1150 # ffffffffc02aa8c0 <bigblocks>
ffffffffc0201d46:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d48:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d4a:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201d4c:	c63fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201d50:	6480                	ld	s0,8(s1)
}
ffffffffc0201d52:	60e2                	ld	ra,24(sp)
ffffffffc0201d54:	64a2                	ld	s1,8(sp)
ffffffffc0201d56:	8522                	mv	a0,s0
ffffffffc0201d58:	6442                	ld	s0,16(sp)
ffffffffc0201d5a:	6902                	ld	s2,0(sp)
ffffffffc0201d5c:	6105                	addi	sp,sp,32
ffffffffc0201d5e:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d60:	45e1                	li	a1,24
ffffffffc0201d62:	8526                	mv	a0,s1
ffffffffc0201d64:	d25ff0ef          	jal	ra,ffffffffc0201a88 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201d68:	b765                	j	ffffffffc0201d10 <kmalloc+0x56>

ffffffffc0201d6a <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d6a:	c169                	beqz	a0,ffffffffc0201e2c <kfree+0xc2>
{
ffffffffc0201d6c:	1101                	addi	sp,sp,-32
ffffffffc0201d6e:	e822                	sd	s0,16(sp)
ffffffffc0201d70:	ec06                	sd	ra,24(sp)
ffffffffc0201d72:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201d74:	03451793          	slli	a5,a0,0x34
ffffffffc0201d78:	842a                	mv	s0,a0
ffffffffc0201d7a:	e3d9                	bnez	a5,ffffffffc0201e00 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d7c:	100027f3          	csrr	a5,sstatus
ffffffffc0201d80:	8b89                	andi	a5,a5,2
ffffffffc0201d82:	e7d9                	bnez	a5,ffffffffc0201e10 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d84:	000a9797          	auipc	a5,0xa9
ffffffffc0201d88:	b3c7b783          	ld	a5,-1220(a5) # ffffffffc02aa8c0 <bigblocks>
    return 0;
ffffffffc0201d8c:	4601                	li	a2,0
ffffffffc0201d8e:	cbad                	beqz	a5,ffffffffc0201e00 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d90:	000a9697          	auipc	a3,0xa9
ffffffffc0201d94:	b3068693          	addi	a3,a3,-1232 # ffffffffc02aa8c0 <bigblocks>
ffffffffc0201d98:	a021                	j	ffffffffc0201da0 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d9a:	01048693          	addi	a3,s1,16
ffffffffc0201d9e:	c3a5                	beqz	a5,ffffffffc0201dfe <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201da0:	6798                	ld	a4,8(a5)
ffffffffc0201da2:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201da4:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201da6:	fe871ae3          	bne	a4,s0,ffffffffc0201d9a <kfree+0x30>
				*last = bb->next;
ffffffffc0201daa:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201dac:	ee2d                	bnez	a2,ffffffffc0201e26 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201dae:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201db2:	4098                	lw	a4,0(s1)
ffffffffc0201db4:	08f46963          	bltu	s0,a5,ffffffffc0201e46 <kfree+0xdc>
ffffffffc0201db8:	000a9697          	auipc	a3,0xa9
ffffffffc0201dbc:	b386b683          	ld	a3,-1224(a3) # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0201dc0:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201dc2:	8031                	srli	s0,s0,0xc
ffffffffc0201dc4:	000a9797          	auipc	a5,0xa9
ffffffffc0201dc8:	b147b783          	ld	a5,-1260(a5) # ffffffffc02aa8d8 <npage>
ffffffffc0201dcc:	06f47163          	bgeu	s0,a5,ffffffffc0201e2e <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201dd0:	00006517          	auipc	a0,0x6
ffffffffc0201dd4:	a9053503          	ld	a0,-1392(a0) # ffffffffc0207860 <nbase>
ffffffffc0201dd8:	8c09                	sub	s0,s0,a0
ffffffffc0201dda:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201ddc:	000a9517          	auipc	a0,0xa9
ffffffffc0201de0:	b0453503          	ld	a0,-1276(a0) # ffffffffc02aa8e0 <pages>
ffffffffc0201de4:	4585                	li	a1,1
ffffffffc0201de6:	9522                	add	a0,a0,s0
ffffffffc0201de8:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201dec:	0ea000ef          	jal	ra,ffffffffc0201ed6 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201df0:	6442                	ld	s0,16(sp)
ffffffffc0201df2:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201df4:	8526                	mv	a0,s1
}
ffffffffc0201df6:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201df8:	45e1                	li	a1,24
}
ffffffffc0201dfa:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dfc:	b171                	j	ffffffffc0201a88 <slob_free>
ffffffffc0201dfe:	e20d                	bnez	a2,ffffffffc0201e20 <kfree+0xb6>
ffffffffc0201e00:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201e04:	6442                	ld	s0,16(sp)
ffffffffc0201e06:	60e2                	ld	ra,24(sp)
ffffffffc0201e08:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e0a:	4581                	li	a1,0
}
ffffffffc0201e0c:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e0e:	b9ad                	j	ffffffffc0201a88 <slob_free>
        intr_disable();
ffffffffc0201e10:	ba5fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e14:	000a9797          	auipc	a5,0xa9
ffffffffc0201e18:	aac7b783          	ld	a5,-1364(a5) # ffffffffc02aa8c0 <bigblocks>
        return 1;
ffffffffc0201e1c:	4605                	li	a2,1
ffffffffc0201e1e:	fbad                	bnez	a5,ffffffffc0201d90 <kfree+0x26>
        intr_enable();
ffffffffc0201e20:	b8ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e24:	bff1                	j	ffffffffc0201e00 <kfree+0x96>
ffffffffc0201e26:	b89fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e2a:	b751                	j	ffffffffc0201dae <kfree+0x44>
ffffffffc0201e2c:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e2e:	00005617          	auipc	a2,0x5
ffffffffc0201e32:	81260613          	addi	a2,a2,-2030 # ffffffffc0206640 <default_pmm_manager+0x108>
ffffffffc0201e36:	06900593          	li	a1,105
ffffffffc0201e3a:	00004517          	auipc	a0,0x4
ffffffffc0201e3e:	75e50513          	addi	a0,a0,1886 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc0201e42:	e4cfe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e46:	86a2                	mv	a3,s0
ffffffffc0201e48:	00004617          	auipc	a2,0x4
ffffffffc0201e4c:	7d060613          	addi	a2,a2,2000 # ffffffffc0206618 <default_pmm_manager+0xe0>
ffffffffc0201e50:	07700593          	li	a1,119
ffffffffc0201e54:	00004517          	auipc	a0,0x4
ffffffffc0201e58:	74450513          	addi	a0,a0,1860 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc0201e5c:	e32fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e60 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e60:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e62:	00004617          	auipc	a2,0x4
ffffffffc0201e66:	7de60613          	addi	a2,a2,2014 # ffffffffc0206640 <default_pmm_manager+0x108>
ffffffffc0201e6a:	06900593          	li	a1,105
ffffffffc0201e6e:	00004517          	auipc	a0,0x4
ffffffffc0201e72:	72a50513          	addi	a0,a0,1834 # ffffffffc0206598 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201e76:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e78:	e16fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e7c <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201e7c:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201e7e:	00004617          	auipc	a2,0x4
ffffffffc0201e82:	7e260613          	addi	a2,a2,2018 # ffffffffc0206660 <default_pmm_manager+0x128>
ffffffffc0201e86:	07f00593          	li	a1,127
ffffffffc0201e8a:	00004517          	auipc	a0,0x4
ffffffffc0201e8e:	70e50513          	addi	a0,a0,1806 # ffffffffc0206598 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201e92:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201e94:	dfafe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e98 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e98:	100027f3          	csrr	a5,sstatus
ffffffffc0201e9c:	8b89                	andi	a5,a5,2
ffffffffc0201e9e:	e799                	bnez	a5,ffffffffc0201eac <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ea0:	000a9797          	auipc	a5,0xa9
ffffffffc0201ea4:	a487b783          	ld	a5,-1464(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201ea8:	6f9c                	ld	a5,24(a5)
ffffffffc0201eaa:	8782                	jr	a5
{
ffffffffc0201eac:	1141                	addi	sp,sp,-16
ffffffffc0201eae:	e406                	sd	ra,8(sp)
ffffffffc0201eb0:	e022                	sd	s0,0(sp)
ffffffffc0201eb2:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201eb4:	b01fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eb8:	000a9797          	auipc	a5,0xa9
ffffffffc0201ebc:	a307b783          	ld	a5,-1488(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201ec0:	6f9c                	ld	a5,24(a5)
ffffffffc0201ec2:	8522                	mv	a0,s0
ffffffffc0201ec4:	9782                	jalr	a5
ffffffffc0201ec6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201ec8:	ae7fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201ecc:	60a2                	ld	ra,8(sp)
ffffffffc0201ece:	8522                	mv	a0,s0
ffffffffc0201ed0:	6402                	ld	s0,0(sp)
ffffffffc0201ed2:	0141                	addi	sp,sp,16
ffffffffc0201ed4:	8082                	ret

ffffffffc0201ed6 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ed6:	100027f3          	csrr	a5,sstatus
ffffffffc0201eda:	8b89                	andi	a5,a5,2
ffffffffc0201edc:	e799                	bnez	a5,ffffffffc0201eea <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ede:	000a9797          	auipc	a5,0xa9
ffffffffc0201ee2:	a0a7b783          	ld	a5,-1526(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201ee6:	739c                	ld	a5,32(a5)
ffffffffc0201ee8:	8782                	jr	a5
{
ffffffffc0201eea:	1101                	addi	sp,sp,-32
ffffffffc0201eec:	ec06                	sd	ra,24(sp)
ffffffffc0201eee:	e822                	sd	s0,16(sp)
ffffffffc0201ef0:	e426                	sd	s1,8(sp)
ffffffffc0201ef2:	842a                	mv	s0,a0
ffffffffc0201ef4:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201ef6:	abffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201efa:	000a9797          	auipc	a5,0xa9
ffffffffc0201efe:	9ee7b783          	ld	a5,-1554(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201f02:	739c                	ld	a5,32(a5)
ffffffffc0201f04:	85a6                	mv	a1,s1
ffffffffc0201f06:	8522                	mv	a0,s0
ffffffffc0201f08:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f0a:	6442                	ld	s0,16(sp)
ffffffffc0201f0c:	60e2                	ld	ra,24(sp)
ffffffffc0201f0e:	64a2                	ld	s1,8(sp)
ffffffffc0201f10:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f12:	a9dfe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201f16 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f16:	100027f3          	csrr	a5,sstatus
ffffffffc0201f1a:	8b89                	andi	a5,a5,2
ffffffffc0201f1c:	e799                	bnez	a5,ffffffffc0201f2a <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f1e:	000a9797          	auipc	a5,0xa9
ffffffffc0201f22:	9ca7b783          	ld	a5,-1590(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201f26:	779c                	ld	a5,40(a5)
ffffffffc0201f28:	8782                	jr	a5
{
ffffffffc0201f2a:	1141                	addi	sp,sp,-16
ffffffffc0201f2c:	e406                	sd	ra,8(sp)
ffffffffc0201f2e:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f30:	a85fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f34:	000a9797          	auipc	a5,0xa9
ffffffffc0201f38:	9b47b783          	ld	a5,-1612(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201f3c:	779c                	ld	a5,40(a5)
ffffffffc0201f3e:	9782                	jalr	a5
ffffffffc0201f40:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f42:	a6dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f46:	60a2                	ld	ra,8(sp)
ffffffffc0201f48:	8522                	mv	a0,s0
ffffffffc0201f4a:	6402                	ld	s0,0(sp)
ffffffffc0201f4c:	0141                	addi	sp,sp,16
ffffffffc0201f4e:	8082                	ret

ffffffffc0201f50 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f50:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f54:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201f58:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f5a:	078e                	slli	a5,a5,0x3
{
ffffffffc0201f5c:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f5e:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f62:	6094                	ld	a3,0(s1)
{
ffffffffc0201f64:	f04a                	sd	s2,32(sp)
ffffffffc0201f66:	ec4e                	sd	s3,24(sp)
ffffffffc0201f68:	e852                	sd	s4,16(sp)
ffffffffc0201f6a:	fc06                	sd	ra,56(sp)
ffffffffc0201f6c:	f822                	sd	s0,48(sp)
ffffffffc0201f6e:	e456                	sd	s5,8(sp)
ffffffffc0201f70:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f72:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f76:	892e                	mv	s2,a1
ffffffffc0201f78:	8a32                	mv	s4,a2
ffffffffc0201f7a:	000a9997          	auipc	s3,0xa9
ffffffffc0201f7e:	95e98993          	addi	s3,s3,-1698 # ffffffffc02aa8d8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f82:	efbd                	bnez	a5,ffffffffc0202000 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f84:	14060c63          	beqz	a2,ffffffffc02020dc <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f88:	100027f3          	csrr	a5,sstatus
ffffffffc0201f8c:	8b89                	andi	a5,a5,2
ffffffffc0201f8e:	14079963          	bnez	a5,ffffffffc02020e0 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f92:	000a9797          	auipc	a5,0xa9
ffffffffc0201f96:	9567b783          	ld	a5,-1706(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0201f9a:	6f9c                	ld	a5,24(a5)
ffffffffc0201f9c:	4505                	li	a0,1
ffffffffc0201f9e:	9782                	jalr	a5
ffffffffc0201fa0:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fa2:	12040d63          	beqz	s0,ffffffffc02020dc <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201fa6:	000a9b17          	auipc	s6,0xa9
ffffffffc0201faa:	93ab0b13          	addi	s6,s6,-1734 # ffffffffc02aa8e0 <pages>
ffffffffc0201fae:	000b3503          	ld	a0,0(s6)
ffffffffc0201fb2:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fb6:	000a9997          	auipc	s3,0xa9
ffffffffc0201fba:	92298993          	addi	s3,s3,-1758 # ffffffffc02aa8d8 <npage>
ffffffffc0201fbe:	40a40533          	sub	a0,s0,a0
ffffffffc0201fc2:	8519                	srai	a0,a0,0x6
ffffffffc0201fc4:	9556                	add	a0,a0,s5
ffffffffc0201fc6:	0009b703          	ld	a4,0(s3)
ffffffffc0201fca:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201fce:	4685                	li	a3,1
ffffffffc0201fd0:	c014                	sw	a3,0(s0)
ffffffffc0201fd2:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fd4:	0532                	slli	a0,a0,0xc
ffffffffc0201fd6:	16e7f763          	bgeu	a5,a4,ffffffffc0202144 <get_pte+0x1f4>
ffffffffc0201fda:	000a9797          	auipc	a5,0xa9
ffffffffc0201fde:	9167b783          	ld	a5,-1770(a5) # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0201fe2:	6605                	lui	a2,0x1
ffffffffc0201fe4:	4581                	li	a1,0
ffffffffc0201fe6:	953e                	add	a0,a0,a5
ffffffffc0201fe8:	6e6030ef          	jal	ra,ffffffffc02056ce <memset>
    return page - pages + nbase;
ffffffffc0201fec:	000b3683          	ld	a3,0(s6)
ffffffffc0201ff0:	40d406b3          	sub	a3,s0,a3
ffffffffc0201ff4:	8699                	srai	a3,a3,0x6
ffffffffc0201ff6:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ff8:	06aa                	slli	a3,a3,0xa
ffffffffc0201ffa:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ffe:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202000:	77fd                	lui	a5,0xfffff
ffffffffc0202002:	068a                	slli	a3,a3,0x2
ffffffffc0202004:	0009b703          	ld	a4,0(s3)
ffffffffc0202008:	8efd                	and	a3,a3,a5
ffffffffc020200a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020200e:	10e7ff63          	bgeu	a5,a4,ffffffffc020212c <get_pte+0x1dc>
ffffffffc0202012:	000a9a97          	auipc	s5,0xa9
ffffffffc0202016:	8dea8a93          	addi	s5,s5,-1826 # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc020201a:	000ab403          	ld	s0,0(s5)
ffffffffc020201e:	01595793          	srli	a5,s2,0x15
ffffffffc0202022:	1ff7f793          	andi	a5,a5,511
ffffffffc0202026:	96a2                	add	a3,a3,s0
ffffffffc0202028:	00379413          	slli	s0,a5,0x3
ffffffffc020202c:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc020202e:	6014                	ld	a3,0(s0)
ffffffffc0202030:	0016f793          	andi	a5,a3,1
ffffffffc0202034:	ebad                	bnez	a5,ffffffffc02020a6 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202036:	0a0a0363          	beqz	s4,ffffffffc02020dc <get_pte+0x18c>
ffffffffc020203a:	100027f3          	csrr	a5,sstatus
ffffffffc020203e:	8b89                	andi	a5,a5,2
ffffffffc0202040:	efcd                	bnez	a5,ffffffffc02020fa <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202042:	000a9797          	auipc	a5,0xa9
ffffffffc0202046:	8a67b783          	ld	a5,-1882(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc020204a:	6f9c                	ld	a5,24(a5)
ffffffffc020204c:	4505                	li	a0,1
ffffffffc020204e:	9782                	jalr	a5
ffffffffc0202050:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202052:	c4c9                	beqz	s1,ffffffffc02020dc <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202054:	000a9b17          	auipc	s6,0xa9
ffffffffc0202058:	88cb0b13          	addi	s6,s6,-1908 # ffffffffc02aa8e0 <pages>
ffffffffc020205c:	000b3503          	ld	a0,0(s6)
ffffffffc0202060:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202064:	0009b703          	ld	a4,0(s3)
ffffffffc0202068:	40a48533          	sub	a0,s1,a0
ffffffffc020206c:	8519                	srai	a0,a0,0x6
ffffffffc020206e:	9552                	add	a0,a0,s4
ffffffffc0202070:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202074:	4685                	li	a3,1
ffffffffc0202076:	c094                	sw	a3,0(s1)
ffffffffc0202078:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020207a:	0532                	slli	a0,a0,0xc
ffffffffc020207c:	0ee7f163          	bgeu	a5,a4,ffffffffc020215e <get_pte+0x20e>
ffffffffc0202080:	000ab783          	ld	a5,0(s5)
ffffffffc0202084:	6605                	lui	a2,0x1
ffffffffc0202086:	4581                	li	a1,0
ffffffffc0202088:	953e                	add	a0,a0,a5
ffffffffc020208a:	644030ef          	jal	ra,ffffffffc02056ce <memset>
    return page - pages + nbase;
ffffffffc020208e:	000b3683          	ld	a3,0(s6)
ffffffffc0202092:	40d486b3          	sub	a3,s1,a3
ffffffffc0202096:	8699                	srai	a3,a3,0x6
ffffffffc0202098:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020209a:	06aa                	slli	a3,a3,0xa
ffffffffc020209c:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02020a0:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020a2:	0009b703          	ld	a4,0(s3)
ffffffffc02020a6:	068a                	slli	a3,a3,0x2
ffffffffc02020a8:	757d                	lui	a0,0xfffff
ffffffffc02020aa:	8ee9                	and	a3,a3,a0
ffffffffc02020ac:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020b0:	06e7f263          	bgeu	a5,a4,ffffffffc0202114 <get_pte+0x1c4>
ffffffffc02020b4:	000ab503          	ld	a0,0(s5)
ffffffffc02020b8:	00c95913          	srli	s2,s2,0xc
ffffffffc02020bc:	1ff97913          	andi	s2,s2,511
ffffffffc02020c0:	96aa                	add	a3,a3,a0
ffffffffc02020c2:	00391513          	slli	a0,s2,0x3
ffffffffc02020c6:	9536                	add	a0,a0,a3
}
ffffffffc02020c8:	70e2                	ld	ra,56(sp)
ffffffffc02020ca:	7442                	ld	s0,48(sp)
ffffffffc02020cc:	74a2                	ld	s1,40(sp)
ffffffffc02020ce:	7902                	ld	s2,32(sp)
ffffffffc02020d0:	69e2                	ld	s3,24(sp)
ffffffffc02020d2:	6a42                	ld	s4,16(sp)
ffffffffc02020d4:	6aa2                	ld	s5,8(sp)
ffffffffc02020d6:	6b02                	ld	s6,0(sp)
ffffffffc02020d8:	6121                	addi	sp,sp,64
ffffffffc02020da:	8082                	ret
            return NULL;
ffffffffc02020dc:	4501                	li	a0,0
ffffffffc02020de:	b7ed                	j	ffffffffc02020c8 <get_pte+0x178>
        intr_disable();
ffffffffc02020e0:	8d5fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020e4:	000a9797          	auipc	a5,0xa9
ffffffffc02020e8:	8047b783          	ld	a5,-2044(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc02020ec:	6f9c                	ld	a5,24(a5)
ffffffffc02020ee:	4505                	li	a0,1
ffffffffc02020f0:	9782                	jalr	a5
ffffffffc02020f2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02020f4:	8bbfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02020f8:	b56d                	j	ffffffffc0201fa2 <get_pte+0x52>
        intr_disable();
ffffffffc02020fa:	8bbfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02020fe:	000a8797          	auipc	a5,0xa8
ffffffffc0202102:	7ea7b783          	ld	a5,2026(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0202106:	6f9c                	ld	a5,24(a5)
ffffffffc0202108:	4505                	li	a0,1
ffffffffc020210a:	9782                	jalr	a5
ffffffffc020210c:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc020210e:	8a1fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202112:	b781                	j	ffffffffc0202052 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202114:	00004617          	auipc	a2,0x4
ffffffffc0202118:	45c60613          	addi	a2,a2,1116 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc020211c:	0fa00593          	li	a1,250
ffffffffc0202120:	00004517          	auipc	a0,0x4
ffffffffc0202124:	56850513          	addi	a0,a0,1384 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202128:	b66fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020212c:	00004617          	auipc	a2,0x4
ffffffffc0202130:	44460613          	addi	a2,a2,1092 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc0202134:	0ed00593          	li	a1,237
ffffffffc0202138:	00004517          	auipc	a0,0x4
ffffffffc020213c:	55050513          	addi	a0,a0,1360 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202140:	b4efe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202144:	86aa                	mv	a3,a0
ffffffffc0202146:	00004617          	auipc	a2,0x4
ffffffffc020214a:	42a60613          	addi	a2,a2,1066 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc020214e:	0e900593          	li	a1,233
ffffffffc0202152:	00004517          	auipc	a0,0x4
ffffffffc0202156:	53650513          	addi	a0,a0,1334 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc020215a:	b34fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020215e:	86aa                	mv	a3,a0
ffffffffc0202160:	00004617          	auipc	a2,0x4
ffffffffc0202164:	41060613          	addi	a2,a2,1040 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc0202168:	0f700593          	li	a1,247
ffffffffc020216c:	00004517          	auipc	a0,0x4
ffffffffc0202170:	51c50513          	addi	a0,a0,1308 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202174:	b1afe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0202178 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202178:	1141                	addi	sp,sp,-16
ffffffffc020217a:	e022                	sd	s0,0(sp)
ffffffffc020217c:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020217e:	4601                	li	a2,0
{
ffffffffc0202180:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202182:	dcfff0ef          	jal	ra,ffffffffc0201f50 <get_pte>
    if (ptep_store != NULL)
ffffffffc0202186:	c011                	beqz	s0,ffffffffc020218a <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202188:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020218a:	c511                	beqz	a0,ffffffffc0202196 <get_page+0x1e>
ffffffffc020218c:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020218e:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202190:	0017f713          	andi	a4,a5,1
ffffffffc0202194:	e709                	bnez	a4,ffffffffc020219e <get_page+0x26>
}
ffffffffc0202196:	60a2                	ld	ra,8(sp)
ffffffffc0202198:	6402                	ld	s0,0(sp)
ffffffffc020219a:	0141                	addi	sp,sp,16
ffffffffc020219c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020219e:	078a                	slli	a5,a5,0x2
ffffffffc02021a0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021a2:	000a8717          	auipc	a4,0xa8
ffffffffc02021a6:	73673703          	ld	a4,1846(a4) # ffffffffc02aa8d8 <npage>
ffffffffc02021aa:	00e7ff63          	bgeu	a5,a4,ffffffffc02021c8 <get_page+0x50>
ffffffffc02021ae:	60a2                	ld	ra,8(sp)
ffffffffc02021b0:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02021b2:	fff80537          	lui	a0,0xfff80
ffffffffc02021b6:	97aa                	add	a5,a5,a0
ffffffffc02021b8:	079a                	slli	a5,a5,0x6
ffffffffc02021ba:	000a8517          	auipc	a0,0xa8
ffffffffc02021be:	72653503          	ld	a0,1830(a0) # ffffffffc02aa8e0 <pages>
ffffffffc02021c2:	953e                	add	a0,a0,a5
ffffffffc02021c4:	0141                	addi	sp,sp,16
ffffffffc02021c6:	8082                	ret
ffffffffc02021c8:	c99ff0ef          	jal	ra,ffffffffc0201e60 <pa2page.part.0>

ffffffffc02021cc <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02021cc:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021ce:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02021d2:	f486                	sd	ra,104(sp)
ffffffffc02021d4:	f0a2                	sd	s0,96(sp)
ffffffffc02021d6:	eca6                	sd	s1,88(sp)
ffffffffc02021d8:	e8ca                	sd	s2,80(sp)
ffffffffc02021da:	e4ce                	sd	s3,72(sp)
ffffffffc02021dc:	e0d2                	sd	s4,64(sp)
ffffffffc02021de:	fc56                	sd	s5,56(sp)
ffffffffc02021e0:	f85a                	sd	s6,48(sp)
ffffffffc02021e2:	f45e                	sd	s7,40(sp)
ffffffffc02021e4:	f062                	sd	s8,32(sp)
ffffffffc02021e6:	ec66                	sd	s9,24(sp)
ffffffffc02021e8:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021ea:	17d2                	slli	a5,a5,0x34
ffffffffc02021ec:	e3ed                	bnez	a5,ffffffffc02022ce <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc02021ee:	002007b7          	lui	a5,0x200
ffffffffc02021f2:	842e                	mv	s0,a1
ffffffffc02021f4:	0ef5ed63          	bltu	a1,a5,ffffffffc02022ee <unmap_range+0x122>
ffffffffc02021f8:	8932                	mv	s2,a2
ffffffffc02021fa:	0ec5fa63          	bgeu	a1,a2,ffffffffc02022ee <unmap_range+0x122>
ffffffffc02021fe:	4785                	li	a5,1
ffffffffc0202200:	07fe                	slli	a5,a5,0x1f
ffffffffc0202202:	0ec7e663          	bltu	a5,a2,ffffffffc02022ee <unmap_range+0x122>
ffffffffc0202206:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc0202208:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020220a:	000a8c97          	auipc	s9,0xa8
ffffffffc020220e:	6cec8c93          	addi	s9,s9,1742 # ffffffffc02aa8d8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202212:	000a8c17          	auipc	s8,0xa8
ffffffffc0202216:	6cec0c13          	addi	s8,s8,1742 # ffffffffc02aa8e0 <pages>
ffffffffc020221a:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc020221e:	000a8d17          	auipc	s10,0xa8
ffffffffc0202222:	6cad0d13          	addi	s10,s10,1738 # ffffffffc02aa8e8 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202226:	00200b37          	lui	s6,0x200
ffffffffc020222a:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc020222e:	4601                	li	a2,0
ffffffffc0202230:	85a2                	mv	a1,s0
ffffffffc0202232:	854e                	mv	a0,s3
ffffffffc0202234:	d1dff0ef          	jal	ra,ffffffffc0201f50 <get_pte>
ffffffffc0202238:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020223a:	cd29                	beqz	a0,ffffffffc0202294 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc020223c:	611c                	ld	a5,0(a0)
ffffffffc020223e:	e395                	bnez	a5,ffffffffc0202262 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202240:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202242:	ff2466e3          	bltu	s0,s2,ffffffffc020222e <unmap_range+0x62>
}
ffffffffc0202246:	70a6                	ld	ra,104(sp)
ffffffffc0202248:	7406                	ld	s0,96(sp)
ffffffffc020224a:	64e6                	ld	s1,88(sp)
ffffffffc020224c:	6946                	ld	s2,80(sp)
ffffffffc020224e:	69a6                	ld	s3,72(sp)
ffffffffc0202250:	6a06                	ld	s4,64(sp)
ffffffffc0202252:	7ae2                	ld	s5,56(sp)
ffffffffc0202254:	7b42                	ld	s6,48(sp)
ffffffffc0202256:	7ba2                	ld	s7,40(sp)
ffffffffc0202258:	7c02                	ld	s8,32(sp)
ffffffffc020225a:	6ce2                	ld	s9,24(sp)
ffffffffc020225c:	6d42                	ld	s10,16(sp)
ffffffffc020225e:	6165                	addi	sp,sp,112
ffffffffc0202260:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202262:	0017f713          	andi	a4,a5,1
ffffffffc0202266:	df69                	beqz	a4,ffffffffc0202240 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0202268:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020226c:	078a                	slli	a5,a5,0x2
ffffffffc020226e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202270:	08e7ff63          	bgeu	a5,a4,ffffffffc020230e <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202274:	000c3503          	ld	a0,0(s8)
ffffffffc0202278:	97de                	add	a5,a5,s7
ffffffffc020227a:	079a                	slli	a5,a5,0x6
ffffffffc020227c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020227e:	411c                	lw	a5,0(a0)
ffffffffc0202280:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202284:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202286:	cf11                	beqz	a4,ffffffffc02022a2 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc0202288:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020228c:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202290:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202292:	bf45                	j	ffffffffc0202242 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202294:	945a                	add	s0,s0,s6
ffffffffc0202296:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020229a:	d455                	beqz	s0,ffffffffc0202246 <unmap_range+0x7a>
ffffffffc020229c:	f92469e3          	bltu	s0,s2,ffffffffc020222e <unmap_range+0x62>
ffffffffc02022a0:	b75d                	j	ffffffffc0202246 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02022a2:	100027f3          	csrr	a5,sstatus
ffffffffc02022a6:	8b89                	andi	a5,a5,2
ffffffffc02022a8:	e799                	bnez	a5,ffffffffc02022b6 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc02022aa:	000d3783          	ld	a5,0(s10)
ffffffffc02022ae:	4585                	li	a1,1
ffffffffc02022b0:	739c                	ld	a5,32(a5)
ffffffffc02022b2:	9782                	jalr	a5
    if (flag)
ffffffffc02022b4:	bfd1                	j	ffffffffc0202288 <unmap_range+0xbc>
ffffffffc02022b6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02022b8:	efcfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02022bc:	000d3783          	ld	a5,0(s10)
ffffffffc02022c0:	6522                	ld	a0,8(sp)
ffffffffc02022c2:	4585                	li	a1,1
ffffffffc02022c4:	739c                	ld	a5,32(a5)
ffffffffc02022c6:	9782                	jalr	a5
        intr_enable();
ffffffffc02022c8:	ee6fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02022cc:	bf75                	j	ffffffffc0202288 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022ce:	00004697          	auipc	a3,0x4
ffffffffc02022d2:	3ca68693          	addi	a3,a3,970 # ffffffffc0206698 <default_pmm_manager+0x160>
ffffffffc02022d6:	00004617          	auipc	a2,0x4
ffffffffc02022da:	c8260613          	addi	a2,a2,-894 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02022de:	12000593          	li	a1,288
ffffffffc02022e2:	00004517          	auipc	a0,0x4
ffffffffc02022e6:	3a650513          	addi	a0,a0,934 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02022ea:	9a4fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02022ee:	00004697          	auipc	a3,0x4
ffffffffc02022f2:	3da68693          	addi	a3,a3,986 # ffffffffc02066c8 <default_pmm_manager+0x190>
ffffffffc02022f6:	00004617          	auipc	a2,0x4
ffffffffc02022fa:	c6260613          	addi	a2,a2,-926 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02022fe:	12100593          	li	a1,289
ffffffffc0202302:	00004517          	auipc	a0,0x4
ffffffffc0202306:	38650513          	addi	a0,a0,902 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc020230a:	984fe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc020230e:	b53ff0ef          	jal	ra,ffffffffc0201e60 <pa2page.part.0>

ffffffffc0202312 <exit_range>:
{
ffffffffc0202312:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202314:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202318:	fc86                	sd	ra,120(sp)
ffffffffc020231a:	f8a2                	sd	s0,112(sp)
ffffffffc020231c:	f4a6                	sd	s1,104(sp)
ffffffffc020231e:	f0ca                	sd	s2,96(sp)
ffffffffc0202320:	ecce                	sd	s3,88(sp)
ffffffffc0202322:	e8d2                	sd	s4,80(sp)
ffffffffc0202324:	e4d6                	sd	s5,72(sp)
ffffffffc0202326:	e0da                	sd	s6,64(sp)
ffffffffc0202328:	fc5e                	sd	s7,56(sp)
ffffffffc020232a:	f862                	sd	s8,48(sp)
ffffffffc020232c:	f466                	sd	s9,40(sp)
ffffffffc020232e:	f06a                	sd	s10,32(sp)
ffffffffc0202330:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202332:	17d2                	slli	a5,a5,0x34
ffffffffc0202334:	20079a63          	bnez	a5,ffffffffc0202548 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc0202338:	002007b7          	lui	a5,0x200
ffffffffc020233c:	24f5e463          	bltu	a1,a5,ffffffffc0202584 <exit_range+0x272>
ffffffffc0202340:	8ab2                	mv	s5,a2
ffffffffc0202342:	24c5f163          	bgeu	a1,a2,ffffffffc0202584 <exit_range+0x272>
ffffffffc0202346:	4785                	li	a5,1
ffffffffc0202348:	07fe                	slli	a5,a5,0x1f
ffffffffc020234a:	22c7ed63          	bltu	a5,a2,ffffffffc0202584 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc020234e:	c00009b7          	lui	s3,0xc0000
ffffffffc0202352:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202356:	ffe00937          	lui	s2,0xffe00
ffffffffc020235a:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc020235e:	5cfd                	li	s9,-1
ffffffffc0202360:	8c2a                	mv	s8,a0
ffffffffc0202362:	0125f933          	and	s2,a1,s2
ffffffffc0202366:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0202368:	000a8d17          	auipc	s10,0xa8
ffffffffc020236c:	570d0d13          	addi	s10,s10,1392 # ffffffffc02aa8d8 <npage>
    return KADDR(page2pa(page));
ffffffffc0202370:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202374:	000a8717          	auipc	a4,0xa8
ffffffffc0202378:	56c70713          	addi	a4,a4,1388 # ffffffffc02aa8e0 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc020237c:	000a8d97          	auipc	s11,0xa8
ffffffffc0202380:	56cd8d93          	addi	s11,s11,1388 # ffffffffc02aa8e8 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202384:	c0000437          	lui	s0,0xc0000
ffffffffc0202388:	944e                	add	s0,s0,s3
ffffffffc020238a:	8079                	srli	s0,s0,0x1e
ffffffffc020238c:	1ff47413          	andi	s0,s0,511
ffffffffc0202390:	040e                	slli	s0,s0,0x3
ffffffffc0202392:	9462                	add	s0,s0,s8
ffffffffc0202394:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ec0>
        if (pde1 & PTE_V)
ffffffffc0202398:	001a7793          	andi	a5,s4,1
ffffffffc020239c:	eb99                	bnez	a5,ffffffffc02023b2 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc020239e:	12098463          	beqz	s3,ffffffffc02024c6 <exit_range+0x1b4>
ffffffffc02023a2:	400007b7          	lui	a5,0x40000
ffffffffc02023a6:	97ce                	add	a5,a5,s3
ffffffffc02023a8:	894e                	mv	s2,s3
ffffffffc02023aa:	1159fe63          	bgeu	s3,s5,ffffffffc02024c6 <exit_range+0x1b4>
ffffffffc02023ae:	89be                	mv	s3,a5
ffffffffc02023b0:	bfd1                	j	ffffffffc0202384 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc02023b2:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023b6:	0a0a                	slli	s4,s4,0x2
ffffffffc02023b8:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc02023bc:	1cfa7263          	bgeu	s4,a5,ffffffffc0202580 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023c0:	fff80637          	lui	a2,0xfff80
ffffffffc02023c4:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02023c6:	000806b7          	lui	a3,0x80
ffffffffc02023ca:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02023cc:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02023d0:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023d2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023d4:	18f5fa63          	bgeu	a1,a5,ffffffffc0202568 <exit_range+0x256>
ffffffffc02023d8:	000a8817          	auipc	a6,0xa8
ffffffffc02023dc:	51880813          	addi	a6,a6,1304 # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc02023e0:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02023e4:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02023e6:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02023ea:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02023ec:	00080337          	lui	t1,0x80
ffffffffc02023f0:	6885                	lui	a7,0x1
ffffffffc02023f2:	a819                	j	ffffffffc0202408 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02023f4:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02023f6:	002007b7          	lui	a5,0x200
ffffffffc02023fa:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023fc:	08090c63          	beqz	s2,ffffffffc0202494 <exit_range+0x182>
ffffffffc0202400:	09397a63          	bgeu	s2,s3,ffffffffc0202494 <exit_range+0x182>
ffffffffc0202404:	0f597063          	bgeu	s2,s5,ffffffffc02024e4 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202408:	01595493          	srli	s1,s2,0x15
ffffffffc020240c:	1ff4f493          	andi	s1,s1,511
ffffffffc0202410:	048e                	slli	s1,s1,0x3
ffffffffc0202412:	94da                	add	s1,s1,s6
ffffffffc0202414:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc0202416:	0017f693          	andi	a3,a5,1
ffffffffc020241a:	dee9                	beqz	a3,ffffffffc02023f4 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc020241c:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202420:	078a                	slli	a5,a5,0x2
ffffffffc0202422:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202424:	14b7fe63          	bgeu	a5,a1,ffffffffc0202580 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202428:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020242a:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc020242e:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202432:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202436:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202438:	12bef863          	bgeu	t4,a1,ffffffffc0202568 <exit_range+0x256>
ffffffffc020243c:	00083783          	ld	a5,0(a6)
ffffffffc0202440:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202442:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc0202446:	629c                	ld	a5,0(a3)
ffffffffc0202448:	8b85                	andi	a5,a5,1
ffffffffc020244a:	f7d5                	bnez	a5,ffffffffc02023f6 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020244c:	06a1                	addi	a3,a3,8
ffffffffc020244e:	fed59ce3          	bne	a1,a3,ffffffffc0202446 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202452:	631c                	ld	a5,0(a4)
ffffffffc0202454:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202456:	100027f3          	csrr	a5,sstatus
ffffffffc020245a:	8b89                	andi	a5,a5,2
ffffffffc020245c:	e7d9                	bnez	a5,ffffffffc02024ea <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc020245e:	000db783          	ld	a5,0(s11)
ffffffffc0202462:	4585                	li	a1,1
ffffffffc0202464:	e032                	sd	a2,0(sp)
ffffffffc0202466:	739c                	ld	a5,32(a5)
ffffffffc0202468:	9782                	jalr	a5
    if (flag)
ffffffffc020246a:	6602                	ld	a2,0(sp)
ffffffffc020246c:	000a8817          	auipc	a6,0xa8
ffffffffc0202470:	48480813          	addi	a6,a6,1156 # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0202474:	fff80e37          	lui	t3,0xfff80
ffffffffc0202478:	00080337          	lui	t1,0x80
ffffffffc020247c:	6885                	lui	a7,0x1
ffffffffc020247e:	000a8717          	auipc	a4,0xa8
ffffffffc0202482:	46270713          	addi	a4,a4,1122 # ffffffffc02aa8e0 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202486:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc020248a:	002007b7          	lui	a5,0x200
ffffffffc020248e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202490:	f60918e3          	bnez	s2,ffffffffc0202400 <exit_range+0xee>
            if (free_pd0)
ffffffffc0202494:	f00b85e3          	beqz	s7,ffffffffc020239e <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0202498:	000d3783          	ld	a5,0(s10)
ffffffffc020249c:	0efa7263          	bgeu	s4,a5,ffffffffc0202580 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02024a0:	6308                	ld	a0,0(a4)
ffffffffc02024a2:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02024a4:	100027f3          	csrr	a5,sstatus
ffffffffc02024a8:	8b89                	andi	a5,a5,2
ffffffffc02024aa:	efad                	bnez	a5,ffffffffc0202524 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02024ac:	000db783          	ld	a5,0(s11)
ffffffffc02024b0:	4585                	li	a1,1
ffffffffc02024b2:	739c                	ld	a5,32(a5)
ffffffffc02024b4:	9782                	jalr	a5
ffffffffc02024b6:	000a8717          	auipc	a4,0xa8
ffffffffc02024ba:	42a70713          	addi	a4,a4,1066 # ffffffffc02aa8e0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02024be:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02024c2:	ee0990e3          	bnez	s3,ffffffffc02023a2 <exit_range+0x90>
}
ffffffffc02024c6:	70e6                	ld	ra,120(sp)
ffffffffc02024c8:	7446                	ld	s0,112(sp)
ffffffffc02024ca:	74a6                	ld	s1,104(sp)
ffffffffc02024cc:	7906                	ld	s2,96(sp)
ffffffffc02024ce:	69e6                	ld	s3,88(sp)
ffffffffc02024d0:	6a46                	ld	s4,80(sp)
ffffffffc02024d2:	6aa6                	ld	s5,72(sp)
ffffffffc02024d4:	6b06                	ld	s6,64(sp)
ffffffffc02024d6:	7be2                	ld	s7,56(sp)
ffffffffc02024d8:	7c42                	ld	s8,48(sp)
ffffffffc02024da:	7ca2                	ld	s9,40(sp)
ffffffffc02024dc:	7d02                	ld	s10,32(sp)
ffffffffc02024de:	6de2                	ld	s11,24(sp)
ffffffffc02024e0:	6109                	addi	sp,sp,128
ffffffffc02024e2:	8082                	ret
            if (free_pd0)
ffffffffc02024e4:	ea0b8fe3          	beqz	s7,ffffffffc02023a2 <exit_range+0x90>
ffffffffc02024e8:	bf45                	j	ffffffffc0202498 <exit_range+0x186>
ffffffffc02024ea:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc02024ec:	e42a                	sd	a0,8(sp)
ffffffffc02024ee:	cc6fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024f2:	000db783          	ld	a5,0(s11)
ffffffffc02024f6:	6522                	ld	a0,8(sp)
ffffffffc02024f8:	4585                	li	a1,1
ffffffffc02024fa:	739c                	ld	a5,32(a5)
ffffffffc02024fc:	9782                	jalr	a5
        intr_enable();
ffffffffc02024fe:	cb0fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202502:	6602                	ld	a2,0(sp)
ffffffffc0202504:	000a8717          	auipc	a4,0xa8
ffffffffc0202508:	3dc70713          	addi	a4,a4,988 # ffffffffc02aa8e0 <pages>
ffffffffc020250c:	6885                	lui	a7,0x1
ffffffffc020250e:	00080337          	lui	t1,0x80
ffffffffc0202512:	fff80e37          	lui	t3,0xfff80
ffffffffc0202516:	000a8817          	auipc	a6,0xa8
ffffffffc020251a:	3da80813          	addi	a6,a6,986 # ffffffffc02aa8f0 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc020251e:	0004b023          	sd	zero,0(s1)
ffffffffc0202522:	b7a5                	j	ffffffffc020248a <exit_range+0x178>
ffffffffc0202524:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0202526:	c8efe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020252a:	000db783          	ld	a5,0(s11)
ffffffffc020252e:	6502                	ld	a0,0(sp)
ffffffffc0202530:	4585                	li	a1,1
ffffffffc0202532:	739c                	ld	a5,32(a5)
ffffffffc0202534:	9782                	jalr	a5
        intr_enable();
ffffffffc0202536:	c78fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020253a:	000a8717          	auipc	a4,0xa8
ffffffffc020253e:	3a670713          	addi	a4,a4,934 # ffffffffc02aa8e0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202542:	00043023          	sd	zero,0(s0)
ffffffffc0202546:	bfb5                	j	ffffffffc02024c2 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202548:	00004697          	auipc	a3,0x4
ffffffffc020254c:	15068693          	addi	a3,a3,336 # ffffffffc0206698 <default_pmm_manager+0x160>
ffffffffc0202550:	00004617          	auipc	a2,0x4
ffffffffc0202554:	a0860613          	addi	a2,a2,-1528 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202558:	13500593          	li	a1,309
ffffffffc020255c:	00004517          	auipc	a0,0x4
ffffffffc0202560:	12c50513          	addi	a0,a0,300 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202564:	f2bfd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202568:	00004617          	auipc	a2,0x4
ffffffffc020256c:	00860613          	addi	a2,a2,8 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc0202570:	07100593          	li	a1,113
ffffffffc0202574:	00004517          	auipc	a0,0x4
ffffffffc0202578:	02450513          	addi	a0,a0,36 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc020257c:	f13fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202580:	8e1ff0ef          	jal	ra,ffffffffc0201e60 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202584:	00004697          	auipc	a3,0x4
ffffffffc0202588:	14468693          	addi	a3,a3,324 # ffffffffc02066c8 <default_pmm_manager+0x190>
ffffffffc020258c:	00004617          	auipc	a2,0x4
ffffffffc0202590:	9cc60613          	addi	a2,a2,-1588 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202594:	13600593          	li	a1,310
ffffffffc0202598:	00004517          	auipc	a0,0x4
ffffffffc020259c:	0f050513          	addi	a0,a0,240 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02025a0:	eeffd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02025a4 <page_remove>:
{
ffffffffc02025a4:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025a6:	4601                	li	a2,0
{
ffffffffc02025a8:	ec26                	sd	s1,24(sp)
ffffffffc02025aa:	f406                	sd	ra,40(sp)
ffffffffc02025ac:	f022                	sd	s0,32(sp)
ffffffffc02025ae:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025b0:	9a1ff0ef          	jal	ra,ffffffffc0201f50 <get_pte>
    if (ptep != NULL)
ffffffffc02025b4:	c511                	beqz	a0,ffffffffc02025c0 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02025b6:	611c                	ld	a5,0(a0)
ffffffffc02025b8:	842a                	mv	s0,a0
ffffffffc02025ba:	0017f713          	andi	a4,a5,1
ffffffffc02025be:	e711                	bnez	a4,ffffffffc02025ca <page_remove+0x26>
}
ffffffffc02025c0:	70a2                	ld	ra,40(sp)
ffffffffc02025c2:	7402                	ld	s0,32(sp)
ffffffffc02025c4:	64e2                	ld	s1,24(sp)
ffffffffc02025c6:	6145                	addi	sp,sp,48
ffffffffc02025c8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02025ca:	078a                	slli	a5,a5,0x2
ffffffffc02025cc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02025ce:	000a8717          	auipc	a4,0xa8
ffffffffc02025d2:	30a73703          	ld	a4,778(a4) # ffffffffc02aa8d8 <npage>
ffffffffc02025d6:	06e7f363          	bgeu	a5,a4,ffffffffc020263c <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02025da:	fff80537          	lui	a0,0xfff80
ffffffffc02025de:	97aa                	add	a5,a5,a0
ffffffffc02025e0:	079a                	slli	a5,a5,0x6
ffffffffc02025e2:	000a8517          	auipc	a0,0xa8
ffffffffc02025e6:	2fe53503          	ld	a0,766(a0) # ffffffffc02aa8e0 <pages>
ffffffffc02025ea:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02025ec:	411c                	lw	a5,0(a0)
ffffffffc02025ee:	fff7871b          	addiw	a4,a5,-1
ffffffffc02025f2:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02025f4:	cb11                	beqz	a4,ffffffffc0202608 <page_remove+0x64>
        *ptep = 0;
ffffffffc02025f6:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025fa:	12048073          	sfence.vma	s1
}
ffffffffc02025fe:	70a2                	ld	ra,40(sp)
ffffffffc0202600:	7402                	ld	s0,32(sp)
ffffffffc0202602:	64e2                	ld	s1,24(sp)
ffffffffc0202604:	6145                	addi	sp,sp,48
ffffffffc0202606:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202608:	100027f3          	csrr	a5,sstatus
ffffffffc020260c:	8b89                	andi	a5,a5,2
ffffffffc020260e:	eb89                	bnez	a5,ffffffffc0202620 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202610:	000a8797          	auipc	a5,0xa8
ffffffffc0202614:	2d87b783          	ld	a5,728(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0202618:	739c                	ld	a5,32(a5)
ffffffffc020261a:	4585                	li	a1,1
ffffffffc020261c:	9782                	jalr	a5
    if (flag)
ffffffffc020261e:	bfe1                	j	ffffffffc02025f6 <page_remove+0x52>
        intr_disable();
ffffffffc0202620:	e42a                	sd	a0,8(sp)
ffffffffc0202622:	b92fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202626:	000a8797          	auipc	a5,0xa8
ffffffffc020262a:	2c27b783          	ld	a5,706(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc020262e:	739c                	ld	a5,32(a5)
ffffffffc0202630:	6522                	ld	a0,8(sp)
ffffffffc0202632:	4585                	li	a1,1
ffffffffc0202634:	9782                	jalr	a5
        intr_enable();
ffffffffc0202636:	b78fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020263a:	bf75                	j	ffffffffc02025f6 <page_remove+0x52>
ffffffffc020263c:	825ff0ef          	jal	ra,ffffffffc0201e60 <pa2page.part.0>

ffffffffc0202640 <page_insert>:
{
ffffffffc0202640:	7139                	addi	sp,sp,-64
ffffffffc0202642:	e852                	sd	s4,16(sp)
ffffffffc0202644:	8a32                	mv	s4,a2
ffffffffc0202646:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202648:	4605                	li	a2,1
{
ffffffffc020264a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020264c:	85d2                	mv	a1,s4
{
ffffffffc020264e:	f426                	sd	s1,40(sp)
ffffffffc0202650:	fc06                	sd	ra,56(sp)
ffffffffc0202652:	f04a                	sd	s2,32(sp)
ffffffffc0202654:	ec4e                	sd	s3,24(sp)
ffffffffc0202656:	e456                	sd	s5,8(sp)
ffffffffc0202658:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020265a:	8f7ff0ef          	jal	ra,ffffffffc0201f50 <get_pte>
    if (ptep == NULL)
ffffffffc020265e:	c961                	beqz	a0,ffffffffc020272e <page_insert+0xee>
    page->ref += 1;
ffffffffc0202660:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202662:	611c                	ld	a5,0(a0)
ffffffffc0202664:	89aa                	mv	s3,a0
ffffffffc0202666:	0016871b          	addiw	a4,a3,1
ffffffffc020266a:	c018                	sw	a4,0(s0)
ffffffffc020266c:	0017f713          	andi	a4,a5,1
ffffffffc0202670:	ef05                	bnez	a4,ffffffffc02026a8 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202672:	000a8717          	auipc	a4,0xa8
ffffffffc0202676:	26e73703          	ld	a4,622(a4) # ffffffffc02aa8e0 <pages>
ffffffffc020267a:	8c19                	sub	s0,s0,a4
ffffffffc020267c:	000807b7          	lui	a5,0x80
ffffffffc0202680:	8419                	srai	s0,s0,0x6
ffffffffc0202682:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202684:	042a                	slli	s0,s0,0xa
ffffffffc0202686:	8cc1                	or	s1,s1,s0
ffffffffc0202688:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020268c:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ec0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202690:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202694:	4501                	li	a0,0
}
ffffffffc0202696:	70e2                	ld	ra,56(sp)
ffffffffc0202698:	7442                	ld	s0,48(sp)
ffffffffc020269a:	74a2                	ld	s1,40(sp)
ffffffffc020269c:	7902                	ld	s2,32(sp)
ffffffffc020269e:	69e2                	ld	s3,24(sp)
ffffffffc02026a0:	6a42                	ld	s4,16(sp)
ffffffffc02026a2:	6aa2                	ld	s5,8(sp)
ffffffffc02026a4:	6121                	addi	sp,sp,64
ffffffffc02026a6:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02026a8:	078a                	slli	a5,a5,0x2
ffffffffc02026aa:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026ac:	000a8717          	auipc	a4,0xa8
ffffffffc02026b0:	22c73703          	ld	a4,556(a4) # ffffffffc02aa8d8 <npage>
ffffffffc02026b4:	06e7ff63          	bgeu	a5,a4,ffffffffc0202732 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02026b8:	000a8a97          	auipc	s5,0xa8
ffffffffc02026bc:	228a8a93          	addi	s5,s5,552 # ffffffffc02aa8e0 <pages>
ffffffffc02026c0:	000ab703          	ld	a4,0(s5)
ffffffffc02026c4:	fff80937          	lui	s2,0xfff80
ffffffffc02026c8:	993e                	add	s2,s2,a5
ffffffffc02026ca:	091a                	slli	s2,s2,0x6
ffffffffc02026cc:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02026ce:	01240c63          	beq	s0,s2,ffffffffc02026e6 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02026d2:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcd56ec>
ffffffffc02026d6:	fff7869b          	addiw	a3,a5,-1
ffffffffc02026da:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc02026de:	c691                	beqz	a3,ffffffffc02026ea <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026e0:	120a0073          	sfence.vma	s4
}
ffffffffc02026e4:	bf59                	j	ffffffffc020267a <page_insert+0x3a>
ffffffffc02026e6:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02026e8:	bf49                	j	ffffffffc020267a <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026ea:	100027f3          	csrr	a5,sstatus
ffffffffc02026ee:	8b89                	andi	a5,a5,2
ffffffffc02026f0:	ef91                	bnez	a5,ffffffffc020270c <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02026f2:	000a8797          	auipc	a5,0xa8
ffffffffc02026f6:	1f67b783          	ld	a5,502(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc02026fa:	739c                	ld	a5,32(a5)
ffffffffc02026fc:	4585                	li	a1,1
ffffffffc02026fe:	854a                	mv	a0,s2
ffffffffc0202700:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202702:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202706:	120a0073          	sfence.vma	s4
ffffffffc020270a:	bf85                	j	ffffffffc020267a <page_insert+0x3a>
        intr_disable();
ffffffffc020270c:	aa8fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202710:	000a8797          	auipc	a5,0xa8
ffffffffc0202714:	1d87b783          	ld	a5,472(a5) # ffffffffc02aa8e8 <pmm_manager>
ffffffffc0202718:	739c                	ld	a5,32(a5)
ffffffffc020271a:	4585                	li	a1,1
ffffffffc020271c:	854a                	mv	a0,s2
ffffffffc020271e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202720:	a8efe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202724:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202728:	120a0073          	sfence.vma	s4
ffffffffc020272c:	b7b9                	j	ffffffffc020267a <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020272e:	5571                	li	a0,-4
ffffffffc0202730:	b79d                	j	ffffffffc0202696 <page_insert+0x56>
ffffffffc0202732:	f2eff0ef          	jal	ra,ffffffffc0201e60 <pa2page.part.0>

ffffffffc0202736 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202736:	00004797          	auipc	a5,0x4
ffffffffc020273a:	e0278793          	addi	a5,a5,-510 # ffffffffc0206538 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020273e:	638c                	ld	a1,0(a5)
{
ffffffffc0202740:	7159                	addi	sp,sp,-112
ffffffffc0202742:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202744:	00004517          	auipc	a0,0x4
ffffffffc0202748:	f9c50513          	addi	a0,a0,-100 # ffffffffc02066e0 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc020274c:	000a8b17          	auipc	s6,0xa8
ffffffffc0202750:	19cb0b13          	addi	s6,s6,412 # ffffffffc02aa8e8 <pmm_manager>
{
ffffffffc0202754:	f486                	sd	ra,104(sp)
ffffffffc0202756:	e8ca                	sd	s2,80(sp)
ffffffffc0202758:	e4ce                	sd	s3,72(sp)
ffffffffc020275a:	f0a2                	sd	s0,96(sp)
ffffffffc020275c:	eca6                	sd	s1,88(sp)
ffffffffc020275e:	e0d2                	sd	s4,64(sp)
ffffffffc0202760:	fc56                	sd	s5,56(sp)
ffffffffc0202762:	f45e                	sd	s7,40(sp)
ffffffffc0202764:	f062                	sd	s8,32(sp)
ffffffffc0202766:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202768:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020276c:	a29fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202770:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202774:	000a8997          	auipc	s3,0xa8
ffffffffc0202778:	17c98993          	addi	s3,s3,380 # ffffffffc02aa8f0 <va_pa_offset>
    pmm_manager->init();
ffffffffc020277c:	679c                	ld	a5,8(a5)
ffffffffc020277e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202780:	57f5                	li	a5,-3
ffffffffc0202782:	07fa                	slli	a5,a5,0x1e
ffffffffc0202784:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202788:	a12fe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc020278c:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020278e:	a16fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202792:	200505e3          	beqz	a0,ffffffffc020319c <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202796:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202798:	00004517          	auipc	a0,0x4
ffffffffc020279c:	f8050513          	addi	a0,a0,-128 # ffffffffc0206718 <default_pmm_manager+0x1e0>
ffffffffc02027a0:	9f5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027a4:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02027a8:	fff40693          	addi	a3,s0,-1
ffffffffc02027ac:	864a                	mv	a2,s2
ffffffffc02027ae:	85a6                	mv	a1,s1
ffffffffc02027b0:	00004517          	auipc	a0,0x4
ffffffffc02027b4:	f8050513          	addi	a0,a0,-128 # ffffffffc0206730 <default_pmm_manager+0x1f8>
ffffffffc02027b8:	9ddfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02027bc:	c8000737          	lui	a4,0xc8000
ffffffffc02027c0:	87a2                	mv	a5,s0
ffffffffc02027c2:	54876163          	bltu	a4,s0,ffffffffc0202d04 <pmm_init+0x5ce>
ffffffffc02027c6:	757d                	lui	a0,0xfffff
ffffffffc02027c8:	000a9617          	auipc	a2,0xa9
ffffffffc02027cc:	14b60613          	addi	a2,a2,331 # ffffffffc02ab913 <end+0xfff>
ffffffffc02027d0:	8e69                	and	a2,a2,a0
ffffffffc02027d2:	000a8497          	auipc	s1,0xa8
ffffffffc02027d6:	10648493          	addi	s1,s1,262 # ffffffffc02aa8d8 <npage>
ffffffffc02027da:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027de:	000a8b97          	auipc	s7,0xa8
ffffffffc02027e2:	102b8b93          	addi	s7,s7,258 # ffffffffc02aa8e0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02027e6:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027e8:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027ec:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027f0:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02027f2:	02f50863          	beq	a0,a5,ffffffffc0202822 <pmm_init+0xec>
ffffffffc02027f6:	4781                	li	a5,0
ffffffffc02027f8:	4585                	li	a1,1
ffffffffc02027fa:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02027fe:	00679513          	slli	a0,a5,0x6
ffffffffc0202802:	9532                	add	a0,a0,a2
ffffffffc0202804:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd546f4>
ffffffffc0202808:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020280c:	6088                	ld	a0,0(s1)
ffffffffc020280e:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202810:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202814:	00d50733          	add	a4,a0,a3
ffffffffc0202818:	fee7e3e3          	bltu	a5,a4,ffffffffc02027fe <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020281c:	071a                	slli	a4,a4,0x6
ffffffffc020281e:	00e606b3          	add	a3,a2,a4
ffffffffc0202822:	c02007b7          	lui	a5,0xc0200
ffffffffc0202826:	2ef6ece3          	bltu	a3,a5,ffffffffc020331e <pmm_init+0xbe8>
ffffffffc020282a:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020282e:	77fd                	lui	a5,0xfffff
ffffffffc0202830:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202832:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202834:	5086eb63          	bltu	a3,s0,ffffffffc0202d4a <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202838:	00004517          	auipc	a0,0x4
ffffffffc020283c:	f2050513          	addi	a0,a0,-224 # ffffffffc0206758 <default_pmm_manager+0x220>
ffffffffc0202840:	955fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202844:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202848:	000a8917          	auipc	s2,0xa8
ffffffffc020284c:	08890913          	addi	s2,s2,136 # ffffffffc02aa8d0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202850:	7b9c                	ld	a5,48(a5)
ffffffffc0202852:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202854:	00004517          	auipc	a0,0x4
ffffffffc0202858:	f1c50513          	addi	a0,a0,-228 # ffffffffc0206770 <default_pmm_manager+0x238>
ffffffffc020285c:	939fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202860:	00007697          	auipc	a3,0x7
ffffffffc0202864:	7a068693          	addi	a3,a3,1952 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202868:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020286c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202870:	28f6ebe3          	bltu	a3,a5,ffffffffc0203306 <pmm_init+0xbd0>
ffffffffc0202874:	0009b783          	ld	a5,0(s3)
ffffffffc0202878:	8e9d                	sub	a3,a3,a5
ffffffffc020287a:	000a8797          	auipc	a5,0xa8
ffffffffc020287e:	04d7b723          	sd	a3,78(a5) # ffffffffc02aa8c8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202882:	100027f3          	csrr	a5,sstatus
ffffffffc0202886:	8b89                	andi	a5,a5,2
ffffffffc0202888:	4a079763          	bnez	a5,ffffffffc0202d36 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc020288c:	000b3783          	ld	a5,0(s6)
ffffffffc0202890:	779c                	ld	a5,40(a5)
ffffffffc0202892:	9782                	jalr	a5
ffffffffc0202894:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202896:	6098                	ld	a4,0(s1)
ffffffffc0202898:	c80007b7          	lui	a5,0xc8000
ffffffffc020289c:	83b1                	srli	a5,a5,0xc
ffffffffc020289e:	66e7e363          	bltu	a5,a4,ffffffffc0202f04 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028a2:	00093503          	ld	a0,0(s2)
ffffffffc02028a6:	62050f63          	beqz	a0,ffffffffc0202ee4 <pmm_init+0x7ae>
ffffffffc02028aa:	03451793          	slli	a5,a0,0x34
ffffffffc02028ae:	62079b63          	bnez	a5,ffffffffc0202ee4 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028b2:	4601                	li	a2,0
ffffffffc02028b4:	4581                	li	a1,0
ffffffffc02028b6:	8c3ff0ef          	jal	ra,ffffffffc0202178 <get_page>
ffffffffc02028ba:	60051563          	bnez	a0,ffffffffc0202ec4 <pmm_init+0x78e>
ffffffffc02028be:	100027f3          	csrr	a5,sstatus
ffffffffc02028c2:	8b89                	andi	a5,a5,2
ffffffffc02028c4:	44079e63          	bnez	a5,ffffffffc0202d20 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028c8:	000b3783          	ld	a5,0(s6)
ffffffffc02028cc:	4505                	li	a0,1
ffffffffc02028ce:	6f9c                	ld	a5,24(a5)
ffffffffc02028d0:	9782                	jalr	a5
ffffffffc02028d2:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02028d4:	00093503          	ld	a0,0(s2)
ffffffffc02028d8:	4681                	li	a3,0
ffffffffc02028da:	4601                	li	a2,0
ffffffffc02028dc:	85d2                	mv	a1,s4
ffffffffc02028de:	d63ff0ef          	jal	ra,ffffffffc0202640 <page_insert>
ffffffffc02028e2:	26051ae3          	bnez	a0,ffffffffc0203356 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02028e6:	00093503          	ld	a0,0(s2)
ffffffffc02028ea:	4601                	li	a2,0
ffffffffc02028ec:	4581                	li	a1,0
ffffffffc02028ee:	e62ff0ef          	jal	ra,ffffffffc0201f50 <get_pte>
ffffffffc02028f2:	240502e3          	beqz	a0,ffffffffc0203336 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02028f6:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02028f8:	0017f713          	andi	a4,a5,1
ffffffffc02028fc:	5a070263          	beqz	a4,ffffffffc0202ea0 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202900:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202902:	078a                	slli	a5,a5,0x2
ffffffffc0202904:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202906:	58e7fb63          	bgeu	a5,a4,ffffffffc0202e9c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020290a:	000bb683          	ld	a3,0(s7)
ffffffffc020290e:	fff80637          	lui	a2,0xfff80
ffffffffc0202912:	97b2                	add	a5,a5,a2
ffffffffc0202914:	079a                	slli	a5,a5,0x6
ffffffffc0202916:	97b6                	add	a5,a5,a3
ffffffffc0202918:	14fa17e3          	bne	s4,a5,ffffffffc0203266 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc020291c:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc8>
ffffffffc0202920:	4785                	li	a5,1
ffffffffc0202922:	12f692e3          	bne	a3,a5,ffffffffc0203246 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202926:	00093503          	ld	a0,0(s2)
ffffffffc020292a:	77fd                	lui	a5,0xfffff
ffffffffc020292c:	6114                	ld	a3,0(a0)
ffffffffc020292e:	068a                	slli	a3,a3,0x2
ffffffffc0202930:	8efd                	and	a3,a3,a5
ffffffffc0202932:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202936:	0ee67ce3          	bgeu	a2,a4,ffffffffc020322e <pmm_init+0xaf8>
ffffffffc020293a:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020293e:	96e2                	add	a3,a3,s8
ffffffffc0202940:	0006ba83          	ld	s5,0(a3)
ffffffffc0202944:	0a8a                	slli	s5,s5,0x2
ffffffffc0202946:	00fafab3          	and	s5,s5,a5
ffffffffc020294a:	00cad793          	srli	a5,s5,0xc
ffffffffc020294e:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0203214 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202952:	4601                	li	a2,0
ffffffffc0202954:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202956:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202958:	df8ff0ef          	jal	ra,ffffffffc0201f50 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020295c:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020295e:	55551363          	bne	a0,s5,ffffffffc0202ea4 <pmm_init+0x76e>
ffffffffc0202962:	100027f3          	csrr	a5,sstatus
ffffffffc0202966:	8b89                	andi	a5,a5,2
ffffffffc0202968:	3a079163          	bnez	a5,ffffffffc0202d0a <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc020296c:	000b3783          	ld	a5,0(s6)
ffffffffc0202970:	4505                	li	a0,1
ffffffffc0202972:	6f9c                	ld	a5,24(a5)
ffffffffc0202974:	9782                	jalr	a5
ffffffffc0202976:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202978:	00093503          	ld	a0,0(s2)
ffffffffc020297c:	46d1                	li	a3,20
ffffffffc020297e:	6605                	lui	a2,0x1
ffffffffc0202980:	85e2                	mv	a1,s8
ffffffffc0202982:	cbfff0ef          	jal	ra,ffffffffc0202640 <page_insert>
ffffffffc0202986:	060517e3          	bnez	a0,ffffffffc02031f4 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020298a:	00093503          	ld	a0,0(s2)
ffffffffc020298e:	4601                	li	a2,0
ffffffffc0202990:	6585                	lui	a1,0x1
ffffffffc0202992:	dbeff0ef          	jal	ra,ffffffffc0201f50 <get_pte>
ffffffffc0202996:	02050fe3          	beqz	a0,ffffffffc02031d4 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc020299a:	611c                	ld	a5,0(a0)
ffffffffc020299c:	0107f713          	andi	a4,a5,16
ffffffffc02029a0:	7c070e63          	beqz	a4,ffffffffc020317c <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02029a4:	8b91                	andi	a5,a5,4
ffffffffc02029a6:	7a078b63          	beqz	a5,ffffffffc020315c <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02029aa:	00093503          	ld	a0,0(s2)
ffffffffc02029ae:	611c                	ld	a5,0(a0)
ffffffffc02029b0:	8bc1                	andi	a5,a5,16
ffffffffc02029b2:	78078563          	beqz	a5,ffffffffc020313c <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02029b6:	000c2703          	lw	a4,0(s8)
ffffffffc02029ba:	4785                	li	a5,1
ffffffffc02029bc:	76f71063          	bne	a4,a5,ffffffffc020311c <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02029c0:	4681                	li	a3,0
ffffffffc02029c2:	6605                	lui	a2,0x1
ffffffffc02029c4:	85d2                	mv	a1,s4
ffffffffc02029c6:	c7bff0ef          	jal	ra,ffffffffc0202640 <page_insert>
ffffffffc02029ca:	72051963          	bnez	a0,ffffffffc02030fc <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02029ce:	000a2703          	lw	a4,0(s4)
ffffffffc02029d2:	4789                	li	a5,2
ffffffffc02029d4:	70f71463          	bne	a4,a5,ffffffffc02030dc <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc02029d8:	000c2783          	lw	a5,0(s8)
ffffffffc02029dc:	6e079063          	bnez	a5,ffffffffc02030bc <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029e0:	00093503          	ld	a0,0(s2)
ffffffffc02029e4:	4601                	li	a2,0
ffffffffc02029e6:	6585                	lui	a1,0x1
ffffffffc02029e8:	d68ff0ef          	jal	ra,ffffffffc0201f50 <get_pte>
ffffffffc02029ec:	6a050863          	beqz	a0,ffffffffc020309c <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc02029f0:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02029f2:	00177793          	andi	a5,a4,1
ffffffffc02029f6:	4a078563          	beqz	a5,ffffffffc0202ea0 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02029fa:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02029fc:	00271793          	slli	a5,a4,0x2
ffffffffc0202a00:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a02:	48d7fd63          	bgeu	a5,a3,ffffffffc0202e9c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a06:	000bb683          	ld	a3,0(s7)
ffffffffc0202a0a:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a0e:	97d6                	add	a5,a5,s5
ffffffffc0202a10:	079a                	slli	a5,a5,0x6
ffffffffc0202a12:	97b6                	add	a5,a5,a3
ffffffffc0202a14:	66fa1463          	bne	s4,a5,ffffffffc020307c <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a18:	8b41                	andi	a4,a4,16
ffffffffc0202a1a:	64071163          	bnez	a4,ffffffffc020305c <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a1e:	00093503          	ld	a0,0(s2)
ffffffffc0202a22:	4581                	li	a1,0
ffffffffc0202a24:	b81ff0ef          	jal	ra,ffffffffc02025a4 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a28:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a2c:	4785                	li	a5,1
ffffffffc0202a2e:	60fc9763          	bne	s9,a5,ffffffffc020303c <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202a32:	000c2783          	lw	a5,0(s8)
ffffffffc0202a36:	5e079363          	bnez	a5,ffffffffc020301c <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a3a:	00093503          	ld	a0,0(s2)
ffffffffc0202a3e:	6585                	lui	a1,0x1
ffffffffc0202a40:	b65ff0ef          	jal	ra,ffffffffc02025a4 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a44:	000a2783          	lw	a5,0(s4)
ffffffffc0202a48:	52079a63          	bnez	a5,ffffffffc0202f7c <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202a4c:	000c2783          	lw	a5,0(s8)
ffffffffc0202a50:	50079663          	bnez	a5,ffffffffc0202f5c <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a54:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a58:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a5a:	000a3683          	ld	a3,0(s4)
ffffffffc0202a5e:	068a                	slli	a3,a3,0x2
ffffffffc0202a60:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a62:	42b6fd63          	bgeu	a3,a1,ffffffffc0202e9c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a66:	000bb503          	ld	a0,0(s7)
ffffffffc0202a6a:	96d6                	add	a3,a3,s5
ffffffffc0202a6c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202a6e:	00d507b3          	add	a5,a0,a3
ffffffffc0202a72:	439c                	lw	a5,0(a5)
ffffffffc0202a74:	4d979463          	bne	a5,s9,ffffffffc0202f3c <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202a78:	8699                	srai	a3,a3,0x6
ffffffffc0202a7a:	00080637          	lui	a2,0x80
ffffffffc0202a7e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202a80:	00c69713          	slli	a4,a3,0xc
ffffffffc0202a84:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a86:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a88:	48b77e63          	bgeu	a4,a1,ffffffffc0202f24 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202a8c:	0009b703          	ld	a4,0(s3)
ffffffffc0202a90:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a92:	629c                	ld	a5,0(a3)
ffffffffc0202a94:	078a                	slli	a5,a5,0x2
ffffffffc0202a96:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a98:	40b7f263          	bgeu	a5,a1,ffffffffc0202e9c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a9c:	8f91                	sub	a5,a5,a2
ffffffffc0202a9e:	079a                	slli	a5,a5,0x6
ffffffffc0202aa0:	953e                	add	a0,a0,a5
ffffffffc0202aa2:	100027f3          	csrr	a5,sstatus
ffffffffc0202aa6:	8b89                	andi	a5,a5,2
ffffffffc0202aa8:	30079963          	bnez	a5,ffffffffc0202dba <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202aac:	000b3783          	ld	a5,0(s6)
ffffffffc0202ab0:	4585                	li	a1,1
ffffffffc0202ab2:	739c                	ld	a5,32(a5)
ffffffffc0202ab4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ab6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202aba:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202abc:	078a                	slli	a5,a5,0x2
ffffffffc0202abe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ac0:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202e9c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ac4:	000bb503          	ld	a0,0(s7)
ffffffffc0202ac8:	fff80737          	lui	a4,0xfff80
ffffffffc0202acc:	97ba                	add	a5,a5,a4
ffffffffc0202ace:	079a                	slli	a5,a5,0x6
ffffffffc0202ad0:	953e                	add	a0,a0,a5
ffffffffc0202ad2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ad6:	8b89                	andi	a5,a5,2
ffffffffc0202ad8:	2c079563          	bnez	a5,ffffffffc0202da2 <pmm_init+0x66c>
ffffffffc0202adc:	000b3783          	ld	a5,0(s6)
ffffffffc0202ae0:	4585                	li	a1,1
ffffffffc0202ae2:	739c                	ld	a5,32(a5)
ffffffffc0202ae4:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202ae6:	00093783          	ld	a5,0(s2)
ffffffffc0202aea:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd546ec>
    asm volatile("sfence.vma");
ffffffffc0202aee:	12000073          	sfence.vma
ffffffffc0202af2:	100027f3          	csrr	a5,sstatus
ffffffffc0202af6:	8b89                	andi	a5,a5,2
ffffffffc0202af8:	28079b63          	bnez	a5,ffffffffc0202d8e <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202afc:	000b3783          	ld	a5,0(s6)
ffffffffc0202b00:	779c                	ld	a5,40(a5)
ffffffffc0202b02:	9782                	jalr	a5
ffffffffc0202b04:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b06:	4b441b63          	bne	s0,s4,ffffffffc0202fbc <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b0a:	00004517          	auipc	a0,0x4
ffffffffc0202b0e:	f8e50513          	addi	a0,a0,-114 # ffffffffc0206a98 <default_pmm_manager+0x560>
ffffffffc0202b12:	e82fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202b16:	100027f3          	csrr	a5,sstatus
ffffffffc0202b1a:	8b89                	andi	a5,a5,2
ffffffffc0202b1c:	24079f63          	bnez	a5,ffffffffc0202d7a <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b20:	000b3783          	ld	a5,0(s6)
ffffffffc0202b24:	779c                	ld	a5,40(a5)
ffffffffc0202b26:	9782                	jalr	a5
ffffffffc0202b28:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b2a:	6098                	ld	a4,0(s1)
ffffffffc0202b2c:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b30:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b32:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b36:	6a05                	lui	s4,0x1
ffffffffc0202b38:	02f47c63          	bgeu	s0,a5,ffffffffc0202b70 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b3c:	00c45793          	srli	a5,s0,0xc
ffffffffc0202b40:	00093503          	ld	a0,0(s2)
ffffffffc0202b44:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202e42 <pmm_init+0x70c>
ffffffffc0202b48:	0009b583          	ld	a1,0(s3)
ffffffffc0202b4c:	4601                	li	a2,0
ffffffffc0202b4e:	95a2                	add	a1,a1,s0
ffffffffc0202b50:	c00ff0ef          	jal	ra,ffffffffc0201f50 <get_pte>
ffffffffc0202b54:	32050463          	beqz	a0,ffffffffc0202e7c <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b58:	611c                	ld	a5,0(a0)
ffffffffc0202b5a:	078a                	slli	a5,a5,0x2
ffffffffc0202b5c:	0157f7b3          	and	a5,a5,s5
ffffffffc0202b60:	2e879e63          	bne	a5,s0,ffffffffc0202e5c <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b64:	6098                	ld	a4,0(s1)
ffffffffc0202b66:	9452                	add	s0,s0,s4
ffffffffc0202b68:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b6c:	fcf468e3          	bltu	s0,a5,ffffffffc0202b3c <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202b70:	00093783          	ld	a5,0(s2)
ffffffffc0202b74:	639c                	ld	a5,0(a5)
ffffffffc0202b76:	42079363          	bnez	a5,ffffffffc0202f9c <pmm_init+0x866>
ffffffffc0202b7a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b7e:	8b89                	andi	a5,a5,2
ffffffffc0202b80:	24079963          	bnez	a5,ffffffffc0202dd2 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202b84:	000b3783          	ld	a5,0(s6)
ffffffffc0202b88:	4505                	li	a0,1
ffffffffc0202b8a:	6f9c                	ld	a5,24(a5)
ffffffffc0202b8c:	9782                	jalr	a5
ffffffffc0202b8e:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202b90:	00093503          	ld	a0,0(s2)
ffffffffc0202b94:	4699                	li	a3,6
ffffffffc0202b96:	10000613          	li	a2,256
ffffffffc0202b9a:	85d2                	mv	a1,s4
ffffffffc0202b9c:	aa5ff0ef          	jal	ra,ffffffffc0202640 <page_insert>
ffffffffc0202ba0:	44051e63          	bnez	a0,ffffffffc0202ffc <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202ba4:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc8>
ffffffffc0202ba8:	4785                	li	a5,1
ffffffffc0202baa:	42f71963          	bne	a4,a5,ffffffffc0202fdc <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202bae:	00093503          	ld	a0,0(s2)
ffffffffc0202bb2:	6405                	lui	s0,0x1
ffffffffc0202bb4:	4699                	li	a3,6
ffffffffc0202bb6:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ac8>
ffffffffc0202bba:	85d2                	mv	a1,s4
ffffffffc0202bbc:	a85ff0ef          	jal	ra,ffffffffc0202640 <page_insert>
ffffffffc0202bc0:	72051363          	bnez	a0,ffffffffc02032e6 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202bc4:	000a2703          	lw	a4,0(s4)
ffffffffc0202bc8:	4789                	li	a5,2
ffffffffc0202bca:	6ef71e63          	bne	a4,a5,ffffffffc02032c6 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202bce:	00004597          	auipc	a1,0x4
ffffffffc0202bd2:	01258593          	addi	a1,a1,18 # ffffffffc0206be0 <default_pmm_manager+0x6a8>
ffffffffc0202bd6:	10000513          	li	a0,256
ffffffffc0202bda:	289020ef          	jal	ra,ffffffffc0205662 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202bde:	10040593          	addi	a1,s0,256
ffffffffc0202be2:	10000513          	li	a0,256
ffffffffc0202be6:	28f020ef          	jal	ra,ffffffffc0205674 <strcmp>
ffffffffc0202bea:	6a051e63          	bnez	a0,ffffffffc02032a6 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202bee:	000bb683          	ld	a3,0(s7)
ffffffffc0202bf2:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202bf6:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202bf8:	40da06b3          	sub	a3,s4,a3
ffffffffc0202bfc:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202bfe:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202c00:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202c02:	8031                	srli	s0,s0,0xc
ffffffffc0202c04:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c08:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c0a:	30f77d63          	bgeu	a4,a5,ffffffffc0202f24 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c0e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c12:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c16:	96be                	add	a3,a3,a5
ffffffffc0202c18:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c1c:	211020ef          	jal	ra,ffffffffc020562c <strlen>
ffffffffc0202c20:	66051363          	bnez	a0,ffffffffc0203286 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c24:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c28:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c2a:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd546ec>
ffffffffc0202c2e:	068a                	slli	a3,a3,0x2
ffffffffc0202c30:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c32:	26f6f563          	bgeu	a3,a5,ffffffffc0202e9c <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202c36:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c38:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c3a:	2ef47563          	bgeu	s0,a5,ffffffffc0202f24 <pmm_init+0x7ee>
ffffffffc0202c3e:	0009b403          	ld	s0,0(s3)
ffffffffc0202c42:	9436                	add	s0,s0,a3
ffffffffc0202c44:	100027f3          	csrr	a5,sstatus
ffffffffc0202c48:	8b89                	andi	a5,a5,2
ffffffffc0202c4a:	1e079163          	bnez	a5,ffffffffc0202e2c <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202c4e:	000b3783          	ld	a5,0(s6)
ffffffffc0202c52:	4585                	li	a1,1
ffffffffc0202c54:	8552                	mv	a0,s4
ffffffffc0202c56:	739c                	ld	a5,32(a5)
ffffffffc0202c58:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c5a:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202c5c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c5e:	078a                	slli	a5,a5,0x2
ffffffffc0202c60:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c62:	22e7fd63          	bgeu	a5,a4,ffffffffc0202e9c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c66:	000bb503          	ld	a0,0(s7)
ffffffffc0202c6a:	fff80737          	lui	a4,0xfff80
ffffffffc0202c6e:	97ba                	add	a5,a5,a4
ffffffffc0202c70:	079a                	slli	a5,a5,0x6
ffffffffc0202c72:	953e                	add	a0,a0,a5
ffffffffc0202c74:	100027f3          	csrr	a5,sstatus
ffffffffc0202c78:	8b89                	andi	a5,a5,2
ffffffffc0202c7a:	18079d63          	bnez	a5,ffffffffc0202e14 <pmm_init+0x6de>
ffffffffc0202c7e:	000b3783          	ld	a5,0(s6)
ffffffffc0202c82:	4585                	li	a1,1
ffffffffc0202c84:	739c                	ld	a5,32(a5)
ffffffffc0202c86:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c88:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202c8c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c8e:	078a                	slli	a5,a5,0x2
ffffffffc0202c90:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c92:	20e7f563          	bgeu	a5,a4,ffffffffc0202e9c <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c96:	000bb503          	ld	a0,0(s7)
ffffffffc0202c9a:	fff80737          	lui	a4,0xfff80
ffffffffc0202c9e:	97ba                	add	a5,a5,a4
ffffffffc0202ca0:	079a                	slli	a5,a5,0x6
ffffffffc0202ca2:	953e                	add	a0,a0,a5
ffffffffc0202ca4:	100027f3          	csrr	a5,sstatus
ffffffffc0202ca8:	8b89                	andi	a5,a5,2
ffffffffc0202caa:	14079963          	bnez	a5,ffffffffc0202dfc <pmm_init+0x6c6>
ffffffffc0202cae:	000b3783          	ld	a5,0(s6)
ffffffffc0202cb2:	4585                	li	a1,1
ffffffffc0202cb4:	739c                	ld	a5,32(a5)
ffffffffc0202cb6:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202cb8:	00093783          	ld	a5,0(s2)
ffffffffc0202cbc:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202cc0:	12000073          	sfence.vma
ffffffffc0202cc4:	100027f3          	csrr	a5,sstatus
ffffffffc0202cc8:	8b89                	andi	a5,a5,2
ffffffffc0202cca:	10079f63          	bnez	a5,ffffffffc0202de8 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cce:	000b3783          	ld	a5,0(s6)
ffffffffc0202cd2:	779c                	ld	a5,40(a5)
ffffffffc0202cd4:	9782                	jalr	a5
ffffffffc0202cd6:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202cd8:	4c8c1e63          	bne	s8,s0,ffffffffc02031b4 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202cdc:	00004517          	auipc	a0,0x4
ffffffffc0202ce0:	f7c50513          	addi	a0,a0,-132 # ffffffffc0206c58 <default_pmm_manager+0x720>
ffffffffc0202ce4:	cb0fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202ce8:	7406                	ld	s0,96(sp)
ffffffffc0202cea:	70a6                	ld	ra,104(sp)
ffffffffc0202cec:	64e6                	ld	s1,88(sp)
ffffffffc0202cee:	6946                	ld	s2,80(sp)
ffffffffc0202cf0:	69a6                	ld	s3,72(sp)
ffffffffc0202cf2:	6a06                	ld	s4,64(sp)
ffffffffc0202cf4:	7ae2                	ld	s5,56(sp)
ffffffffc0202cf6:	7b42                	ld	s6,48(sp)
ffffffffc0202cf8:	7ba2                	ld	s7,40(sp)
ffffffffc0202cfa:	7c02                	ld	s8,32(sp)
ffffffffc0202cfc:	6ce2                	ld	s9,24(sp)
ffffffffc0202cfe:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d00:	f97fe06f          	j	ffffffffc0201c96 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202d04:	c80007b7          	lui	a5,0xc8000
ffffffffc0202d08:	bc7d                	j	ffffffffc02027c6 <pmm_init+0x90>
        intr_disable();
ffffffffc0202d0a:	cabfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d0e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d12:	4505                	li	a0,1
ffffffffc0202d14:	6f9c                	ld	a5,24(a5)
ffffffffc0202d16:	9782                	jalr	a5
ffffffffc0202d18:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d1a:	c95fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d1e:	b9a9                	j	ffffffffc0202978 <pmm_init+0x242>
        intr_disable();
ffffffffc0202d20:	c95fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d24:	000b3783          	ld	a5,0(s6)
ffffffffc0202d28:	4505                	li	a0,1
ffffffffc0202d2a:	6f9c                	ld	a5,24(a5)
ffffffffc0202d2c:	9782                	jalr	a5
ffffffffc0202d2e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d30:	c7ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d34:	b645                	j	ffffffffc02028d4 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202d36:	c7ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d3a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d3e:	779c                	ld	a5,40(a5)
ffffffffc0202d40:	9782                	jalr	a5
ffffffffc0202d42:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d44:	c6bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d48:	b6b9                	j	ffffffffc0202896 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d4a:	6705                	lui	a4,0x1
ffffffffc0202d4c:	177d                	addi	a4,a4,-1
ffffffffc0202d4e:	96ba                	add	a3,a3,a4
ffffffffc0202d50:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d52:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d56:	14a77363          	bgeu	a4,a0,ffffffffc0202e9c <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d5a:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202d5e:	fff80537          	lui	a0,0xfff80
ffffffffc0202d62:	972a                	add	a4,a4,a0
ffffffffc0202d64:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d66:	8c1d                	sub	s0,s0,a5
ffffffffc0202d68:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202d6c:	00c45593          	srli	a1,s0,0xc
ffffffffc0202d70:	9532                	add	a0,a0,a2
ffffffffc0202d72:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202d74:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d78:	b4c1                	j	ffffffffc0202838 <pmm_init+0x102>
        intr_disable();
ffffffffc0202d7a:	c3bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d7e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d82:	779c                	ld	a5,40(a5)
ffffffffc0202d84:	9782                	jalr	a5
ffffffffc0202d86:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d88:	c27fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d8c:	bb79                	j	ffffffffc0202b2a <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202d8e:	c27fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d92:	000b3783          	ld	a5,0(s6)
ffffffffc0202d96:	779c                	ld	a5,40(a5)
ffffffffc0202d98:	9782                	jalr	a5
ffffffffc0202d9a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d9c:	c13fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202da0:	b39d                	j	ffffffffc0202b06 <pmm_init+0x3d0>
ffffffffc0202da2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202da4:	c11fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202da8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dac:	6522                	ld	a0,8(sp)
ffffffffc0202dae:	4585                	li	a1,1
ffffffffc0202db0:	739c                	ld	a5,32(a5)
ffffffffc0202db2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202db4:	bfbfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202db8:	b33d                	j	ffffffffc0202ae6 <pmm_init+0x3b0>
ffffffffc0202dba:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dbc:	bf9fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202dc0:	000b3783          	ld	a5,0(s6)
ffffffffc0202dc4:	6522                	ld	a0,8(sp)
ffffffffc0202dc6:	4585                	li	a1,1
ffffffffc0202dc8:	739c                	ld	a5,32(a5)
ffffffffc0202dca:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dcc:	be3fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dd0:	b1dd                	j	ffffffffc0202ab6 <pmm_init+0x380>
        intr_disable();
ffffffffc0202dd2:	be3fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202dd6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dda:	4505                	li	a0,1
ffffffffc0202ddc:	6f9c                	ld	a5,24(a5)
ffffffffc0202dde:	9782                	jalr	a5
ffffffffc0202de0:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202de2:	bcdfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202de6:	b36d                	j	ffffffffc0202b90 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202de8:	bcdfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dec:	000b3783          	ld	a5,0(s6)
ffffffffc0202df0:	779c                	ld	a5,40(a5)
ffffffffc0202df2:	9782                	jalr	a5
ffffffffc0202df4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202df6:	bb9fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dfa:	bdf9                	j	ffffffffc0202cd8 <pmm_init+0x5a2>
ffffffffc0202dfc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dfe:	bb7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e02:	000b3783          	ld	a5,0(s6)
ffffffffc0202e06:	6522                	ld	a0,8(sp)
ffffffffc0202e08:	4585                	li	a1,1
ffffffffc0202e0a:	739c                	ld	a5,32(a5)
ffffffffc0202e0c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e0e:	ba1fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e12:	b55d                	j	ffffffffc0202cb8 <pmm_init+0x582>
ffffffffc0202e14:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e16:	b9ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e1a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e1e:	6522                	ld	a0,8(sp)
ffffffffc0202e20:	4585                	li	a1,1
ffffffffc0202e22:	739c                	ld	a5,32(a5)
ffffffffc0202e24:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e26:	b89fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e2a:	bdb9                	j	ffffffffc0202c88 <pmm_init+0x552>
        intr_disable();
ffffffffc0202e2c:	b89fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e30:	000b3783          	ld	a5,0(s6)
ffffffffc0202e34:	4585                	li	a1,1
ffffffffc0202e36:	8552                	mv	a0,s4
ffffffffc0202e38:	739c                	ld	a5,32(a5)
ffffffffc0202e3a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e3c:	b73fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e40:	bd29                	j	ffffffffc0202c5a <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e42:	86a2                	mv	a3,s0
ffffffffc0202e44:	00003617          	auipc	a2,0x3
ffffffffc0202e48:	72c60613          	addi	a2,a2,1836 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc0202e4c:	25300593          	li	a1,595
ffffffffc0202e50:	00004517          	auipc	a0,0x4
ffffffffc0202e54:	83850513          	addi	a0,a0,-1992 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202e58:	e36fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e5c:	00004697          	auipc	a3,0x4
ffffffffc0202e60:	c9c68693          	addi	a3,a3,-868 # ffffffffc0206af8 <default_pmm_manager+0x5c0>
ffffffffc0202e64:	00003617          	auipc	a2,0x3
ffffffffc0202e68:	0f460613          	addi	a2,a2,244 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202e6c:	25400593          	li	a1,596
ffffffffc0202e70:	00004517          	auipc	a0,0x4
ffffffffc0202e74:	81850513          	addi	a0,a0,-2024 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202e78:	e16fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e7c:	00004697          	auipc	a3,0x4
ffffffffc0202e80:	c3c68693          	addi	a3,a3,-964 # ffffffffc0206ab8 <default_pmm_manager+0x580>
ffffffffc0202e84:	00003617          	auipc	a2,0x3
ffffffffc0202e88:	0d460613          	addi	a2,a2,212 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202e8c:	25300593          	li	a1,595
ffffffffc0202e90:	00003517          	auipc	a0,0x3
ffffffffc0202e94:	7f850513          	addi	a0,a0,2040 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202e98:	df6fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202e9c:	fc5fe0ef          	jal	ra,ffffffffc0201e60 <pa2page.part.0>
ffffffffc0202ea0:	fddfe0ef          	jal	ra,ffffffffc0201e7c <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202ea4:	00004697          	auipc	a3,0x4
ffffffffc0202ea8:	a0c68693          	addi	a3,a3,-1524 # ffffffffc02068b0 <default_pmm_manager+0x378>
ffffffffc0202eac:	00003617          	auipc	a2,0x3
ffffffffc0202eb0:	0ac60613          	addi	a2,a2,172 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202eb4:	22300593          	li	a1,547
ffffffffc0202eb8:	00003517          	auipc	a0,0x3
ffffffffc0202ebc:	7d050513          	addi	a0,a0,2000 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202ec0:	dcefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202ec4:	00004697          	auipc	a3,0x4
ffffffffc0202ec8:	92c68693          	addi	a3,a3,-1748 # ffffffffc02067f0 <default_pmm_manager+0x2b8>
ffffffffc0202ecc:	00003617          	auipc	a2,0x3
ffffffffc0202ed0:	08c60613          	addi	a2,a2,140 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202ed4:	21600593          	li	a1,534
ffffffffc0202ed8:	00003517          	auipc	a0,0x3
ffffffffc0202edc:	7b050513          	addi	a0,a0,1968 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202ee0:	daefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202ee4:	00004697          	auipc	a3,0x4
ffffffffc0202ee8:	8cc68693          	addi	a3,a3,-1844 # ffffffffc02067b0 <default_pmm_manager+0x278>
ffffffffc0202eec:	00003617          	auipc	a2,0x3
ffffffffc0202ef0:	06c60613          	addi	a2,a2,108 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202ef4:	21500593          	li	a1,533
ffffffffc0202ef8:	00003517          	auipc	a0,0x3
ffffffffc0202efc:	79050513          	addi	a0,a0,1936 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202f00:	d8efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f04:	00004697          	auipc	a3,0x4
ffffffffc0202f08:	88c68693          	addi	a3,a3,-1908 # ffffffffc0206790 <default_pmm_manager+0x258>
ffffffffc0202f0c:	00003617          	auipc	a2,0x3
ffffffffc0202f10:	04c60613          	addi	a2,a2,76 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202f14:	21400593          	li	a1,532
ffffffffc0202f18:	00003517          	auipc	a0,0x3
ffffffffc0202f1c:	77050513          	addi	a0,a0,1904 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202f20:	d6efd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f24:	00003617          	auipc	a2,0x3
ffffffffc0202f28:	64c60613          	addi	a2,a2,1612 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc0202f2c:	07100593          	li	a1,113
ffffffffc0202f30:	00003517          	auipc	a0,0x3
ffffffffc0202f34:	66850513          	addi	a0,a0,1640 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc0202f38:	d56fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f3c:	00004697          	auipc	a3,0x4
ffffffffc0202f40:	b0468693          	addi	a3,a3,-1276 # ffffffffc0206a40 <default_pmm_manager+0x508>
ffffffffc0202f44:	00003617          	auipc	a2,0x3
ffffffffc0202f48:	01460613          	addi	a2,a2,20 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202f4c:	23c00593          	li	a1,572
ffffffffc0202f50:	00003517          	auipc	a0,0x3
ffffffffc0202f54:	73850513          	addi	a0,a0,1848 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202f58:	d36fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f5c:	00004697          	auipc	a3,0x4
ffffffffc0202f60:	a9c68693          	addi	a3,a3,-1380 # ffffffffc02069f8 <default_pmm_manager+0x4c0>
ffffffffc0202f64:	00003617          	auipc	a2,0x3
ffffffffc0202f68:	ff460613          	addi	a2,a2,-12 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202f6c:	23a00593          	li	a1,570
ffffffffc0202f70:	00003517          	auipc	a0,0x3
ffffffffc0202f74:	71850513          	addi	a0,a0,1816 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202f78:	d16fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202f7c:	00004697          	auipc	a3,0x4
ffffffffc0202f80:	aac68693          	addi	a3,a3,-1364 # ffffffffc0206a28 <default_pmm_manager+0x4f0>
ffffffffc0202f84:	00003617          	auipc	a2,0x3
ffffffffc0202f88:	fd460613          	addi	a2,a2,-44 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202f8c:	23900593          	li	a1,569
ffffffffc0202f90:	00003517          	auipc	a0,0x3
ffffffffc0202f94:	6f850513          	addi	a0,a0,1784 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202f98:	cf6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202f9c:	00004697          	auipc	a3,0x4
ffffffffc0202fa0:	b7468693          	addi	a3,a3,-1164 # ffffffffc0206b10 <default_pmm_manager+0x5d8>
ffffffffc0202fa4:	00003617          	auipc	a2,0x3
ffffffffc0202fa8:	fb460613          	addi	a2,a2,-76 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202fac:	25700593          	li	a1,599
ffffffffc0202fb0:	00003517          	auipc	a0,0x3
ffffffffc0202fb4:	6d850513          	addi	a0,a0,1752 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202fb8:	cd6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202fbc:	00004697          	auipc	a3,0x4
ffffffffc0202fc0:	ab468693          	addi	a3,a3,-1356 # ffffffffc0206a70 <default_pmm_manager+0x538>
ffffffffc0202fc4:	00003617          	auipc	a2,0x3
ffffffffc0202fc8:	f9460613          	addi	a2,a2,-108 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202fcc:	24400593          	li	a1,580
ffffffffc0202fd0:	00003517          	auipc	a0,0x3
ffffffffc0202fd4:	6b850513          	addi	a0,a0,1720 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202fd8:	cb6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202fdc:	00004697          	auipc	a3,0x4
ffffffffc0202fe0:	b8c68693          	addi	a3,a3,-1140 # ffffffffc0206b68 <default_pmm_manager+0x630>
ffffffffc0202fe4:	00003617          	auipc	a2,0x3
ffffffffc0202fe8:	f7460613          	addi	a2,a2,-140 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0202fec:	25c00593          	li	a1,604
ffffffffc0202ff0:	00003517          	auipc	a0,0x3
ffffffffc0202ff4:	69850513          	addi	a0,a0,1688 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0202ff8:	c96fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202ffc:	00004697          	auipc	a3,0x4
ffffffffc0203000:	b2c68693          	addi	a3,a3,-1236 # ffffffffc0206b28 <default_pmm_manager+0x5f0>
ffffffffc0203004:	00003617          	auipc	a2,0x3
ffffffffc0203008:	f5460613          	addi	a2,a2,-172 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc020300c:	25b00593          	li	a1,603
ffffffffc0203010:	00003517          	auipc	a0,0x3
ffffffffc0203014:	67850513          	addi	a0,a0,1656 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203018:	c76fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020301c:	00004697          	auipc	a3,0x4
ffffffffc0203020:	9dc68693          	addi	a3,a3,-1572 # ffffffffc02069f8 <default_pmm_manager+0x4c0>
ffffffffc0203024:	00003617          	auipc	a2,0x3
ffffffffc0203028:	f3460613          	addi	a2,a2,-204 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc020302c:	23600593          	li	a1,566
ffffffffc0203030:	00003517          	auipc	a0,0x3
ffffffffc0203034:	65850513          	addi	a0,a0,1624 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203038:	c56fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020303c:	00004697          	auipc	a3,0x4
ffffffffc0203040:	85c68693          	addi	a3,a3,-1956 # ffffffffc0206898 <default_pmm_manager+0x360>
ffffffffc0203044:	00003617          	auipc	a2,0x3
ffffffffc0203048:	f1460613          	addi	a2,a2,-236 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc020304c:	23500593          	li	a1,565
ffffffffc0203050:	00003517          	auipc	a0,0x3
ffffffffc0203054:	63850513          	addi	a0,a0,1592 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203058:	c36fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020305c:	00004697          	auipc	a3,0x4
ffffffffc0203060:	9b468693          	addi	a3,a3,-1612 # ffffffffc0206a10 <default_pmm_manager+0x4d8>
ffffffffc0203064:	00003617          	auipc	a2,0x3
ffffffffc0203068:	ef460613          	addi	a2,a2,-268 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc020306c:	23200593          	li	a1,562
ffffffffc0203070:	00003517          	auipc	a0,0x3
ffffffffc0203074:	61850513          	addi	a0,a0,1560 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203078:	c16fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020307c:	00004697          	auipc	a3,0x4
ffffffffc0203080:	80468693          	addi	a3,a3,-2044 # ffffffffc0206880 <default_pmm_manager+0x348>
ffffffffc0203084:	00003617          	auipc	a2,0x3
ffffffffc0203088:	ed460613          	addi	a2,a2,-300 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc020308c:	23100593          	li	a1,561
ffffffffc0203090:	00003517          	auipc	a0,0x3
ffffffffc0203094:	5f850513          	addi	a0,a0,1528 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203098:	bf6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020309c:	00004697          	auipc	a3,0x4
ffffffffc02030a0:	88468693          	addi	a3,a3,-1916 # ffffffffc0206920 <default_pmm_manager+0x3e8>
ffffffffc02030a4:	00003617          	auipc	a2,0x3
ffffffffc02030a8:	eb460613          	addi	a2,a2,-332 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02030ac:	23000593          	li	a1,560
ffffffffc02030b0:	00003517          	auipc	a0,0x3
ffffffffc02030b4:	5d850513          	addi	a0,a0,1496 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02030b8:	bd6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030bc:	00004697          	auipc	a3,0x4
ffffffffc02030c0:	93c68693          	addi	a3,a3,-1732 # ffffffffc02069f8 <default_pmm_manager+0x4c0>
ffffffffc02030c4:	00003617          	auipc	a2,0x3
ffffffffc02030c8:	e9460613          	addi	a2,a2,-364 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02030cc:	22f00593          	li	a1,559
ffffffffc02030d0:	00003517          	auipc	a0,0x3
ffffffffc02030d4:	5b850513          	addi	a0,a0,1464 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02030d8:	bb6fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02030dc:	00004697          	auipc	a3,0x4
ffffffffc02030e0:	90468693          	addi	a3,a3,-1788 # ffffffffc02069e0 <default_pmm_manager+0x4a8>
ffffffffc02030e4:	00003617          	auipc	a2,0x3
ffffffffc02030e8:	e7460613          	addi	a2,a2,-396 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02030ec:	22e00593          	li	a1,558
ffffffffc02030f0:	00003517          	auipc	a0,0x3
ffffffffc02030f4:	59850513          	addi	a0,a0,1432 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02030f8:	b96fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02030fc:	00004697          	auipc	a3,0x4
ffffffffc0203100:	8b468693          	addi	a3,a3,-1868 # ffffffffc02069b0 <default_pmm_manager+0x478>
ffffffffc0203104:	00003617          	auipc	a2,0x3
ffffffffc0203108:	e5460613          	addi	a2,a2,-428 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc020310c:	22d00593          	li	a1,557
ffffffffc0203110:	00003517          	auipc	a0,0x3
ffffffffc0203114:	57850513          	addi	a0,a0,1400 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203118:	b76fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020311c:	00004697          	auipc	a3,0x4
ffffffffc0203120:	87c68693          	addi	a3,a3,-1924 # ffffffffc0206998 <default_pmm_manager+0x460>
ffffffffc0203124:	00003617          	auipc	a2,0x3
ffffffffc0203128:	e3460613          	addi	a2,a2,-460 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc020312c:	22b00593          	li	a1,555
ffffffffc0203130:	00003517          	auipc	a0,0x3
ffffffffc0203134:	55850513          	addi	a0,a0,1368 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203138:	b56fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020313c:	00004697          	auipc	a3,0x4
ffffffffc0203140:	83c68693          	addi	a3,a3,-1988 # ffffffffc0206978 <default_pmm_manager+0x440>
ffffffffc0203144:	00003617          	auipc	a2,0x3
ffffffffc0203148:	e1460613          	addi	a2,a2,-492 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc020314c:	22a00593          	li	a1,554
ffffffffc0203150:	00003517          	auipc	a0,0x3
ffffffffc0203154:	53850513          	addi	a0,a0,1336 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203158:	b36fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc020315c:	00004697          	auipc	a3,0x4
ffffffffc0203160:	80c68693          	addi	a3,a3,-2036 # ffffffffc0206968 <default_pmm_manager+0x430>
ffffffffc0203164:	00003617          	auipc	a2,0x3
ffffffffc0203168:	df460613          	addi	a2,a2,-524 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc020316c:	22900593          	li	a1,553
ffffffffc0203170:	00003517          	auipc	a0,0x3
ffffffffc0203174:	51850513          	addi	a0,a0,1304 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203178:	b16fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc020317c:	00003697          	auipc	a3,0x3
ffffffffc0203180:	7dc68693          	addi	a3,a3,2012 # ffffffffc0206958 <default_pmm_manager+0x420>
ffffffffc0203184:	00003617          	auipc	a2,0x3
ffffffffc0203188:	dd460613          	addi	a2,a2,-556 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc020318c:	22800593          	li	a1,552
ffffffffc0203190:	00003517          	auipc	a0,0x3
ffffffffc0203194:	4f850513          	addi	a0,a0,1272 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203198:	af6fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc020319c:	00003617          	auipc	a2,0x3
ffffffffc02031a0:	55c60613          	addi	a2,a2,1372 # ffffffffc02066f8 <default_pmm_manager+0x1c0>
ffffffffc02031a4:	06500593          	li	a1,101
ffffffffc02031a8:	00003517          	auipc	a0,0x3
ffffffffc02031ac:	4e050513          	addi	a0,a0,1248 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02031b0:	adefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02031b4:	00004697          	auipc	a3,0x4
ffffffffc02031b8:	8bc68693          	addi	a3,a3,-1860 # ffffffffc0206a70 <default_pmm_manager+0x538>
ffffffffc02031bc:	00003617          	auipc	a2,0x3
ffffffffc02031c0:	d9c60613          	addi	a2,a2,-612 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02031c4:	26e00593          	li	a1,622
ffffffffc02031c8:	00003517          	auipc	a0,0x3
ffffffffc02031cc:	4c050513          	addi	a0,a0,1216 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02031d0:	abefd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02031d4:	00003697          	auipc	a3,0x3
ffffffffc02031d8:	74c68693          	addi	a3,a3,1868 # ffffffffc0206920 <default_pmm_manager+0x3e8>
ffffffffc02031dc:	00003617          	auipc	a2,0x3
ffffffffc02031e0:	d7c60613          	addi	a2,a2,-644 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02031e4:	22700593          	li	a1,551
ffffffffc02031e8:	00003517          	auipc	a0,0x3
ffffffffc02031ec:	4a050513          	addi	a0,a0,1184 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02031f0:	a9efd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02031f4:	00003697          	auipc	a3,0x3
ffffffffc02031f8:	6ec68693          	addi	a3,a3,1772 # ffffffffc02068e0 <default_pmm_manager+0x3a8>
ffffffffc02031fc:	00003617          	auipc	a2,0x3
ffffffffc0203200:	d5c60613          	addi	a2,a2,-676 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203204:	22600593          	li	a1,550
ffffffffc0203208:	00003517          	auipc	a0,0x3
ffffffffc020320c:	48050513          	addi	a0,a0,1152 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203210:	a7efd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203214:	86d6                	mv	a3,s5
ffffffffc0203216:	00003617          	auipc	a2,0x3
ffffffffc020321a:	35a60613          	addi	a2,a2,858 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc020321e:	22200593          	li	a1,546
ffffffffc0203222:	00003517          	auipc	a0,0x3
ffffffffc0203226:	46650513          	addi	a0,a0,1126 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc020322a:	a64fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020322e:	00003617          	auipc	a2,0x3
ffffffffc0203232:	34260613          	addi	a2,a2,834 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc0203236:	22100593          	li	a1,545
ffffffffc020323a:	00003517          	auipc	a0,0x3
ffffffffc020323e:	44e50513          	addi	a0,a0,1102 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203242:	a4cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203246:	00003697          	auipc	a3,0x3
ffffffffc020324a:	65268693          	addi	a3,a3,1618 # ffffffffc0206898 <default_pmm_manager+0x360>
ffffffffc020324e:	00003617          	auipc	a2,0x3
ffffffffc0203252:	d0a60613          	addi	a2,a2,-758 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203256:	21f00593          	li	a1,543
ffffffffc020325a:	00003517          	auipc	a0,0x3
ffffffffc020325e:	42e50513          	addi	a0,a0,1070 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203262:	a2cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203266:	00003697          	auipc	a3,0x3
ffffffffc020326a:	61a68693          	addi	a3,a3,1562 # ffffffffc0206880 <default_pmm_manager+0x348>
ffffffffc020326e:	00003617          	auipc	a2,0x3
ffffffffc0203272:	cea60613          	addi	a2,a2,-790 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203276:	21e00593          	li	a1,542
ffffffffc020327a:	00003517          	auipc	a0,0x3
ffffffffc020327e:	40e50513          	addi	a0,a0,1038 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203282:	a0cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203286:	00004697          	auipc	a3,0x4
ffffffffc020328a:	9aa68693          	addi	a3,a3,-1622 # ffffffffc0206c30 <default_pmm_manager+0x6f8>
ffffffffc020328e:	00003617          	auipc	a2,0x3
ffffffffc0203292:	cca60613          	addi	a2,a2,-822 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203296:	26500593          	li	a1,613
ffffffffc020329a:	00003517          	auipc	a0,0x3
ffffffffc020329e:	3ee50513          	addi	a0,a0,1006 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02032a2:	9ecfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02032a6:	00004697          	auipc	a3,0x4
ffffffffc02032aa:	95268693          	addi	a3,a3,-1710 # ffffffffc0206bf8 <default_pmm_manager+0x6c0>
ffffffffc02032ae:	00003617          	auipc	a2,0x3
ffffffffc02032b2:	caa60613          	addi	a2,a2,-854 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02032b6:	26200593          	li	a1,610
ffffffffc02032ba:	00003517          	auipc	a0,0x3
ffffffffc02032be:	3ce50513          	addi	a0,a0,974 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02032c2:	9ccfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc02032c6:	00004697          	auipc	a3,0x4
ffffffffc02032ca:	90268693          	addi	a3,a3,-1790 # ffffffffc0206bc8 <default_pmm_manager+0x690>
ffffffffc02032ce:	00003617          	auipc	a2,0x3
ffffffffc02032d2:	c8a60613          	addi	a2,a2,-886 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02032d6:	25e00593          	li	a1,606
ffffffffc02032da:	00003517          	auipc	a0,0x3
ffffffffc02032de:	3ae50513          	addi	a0,a0,942 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02032e2:	9acfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02032e6:	00004697          	auipc	a3,0x4
ffffffffc02032ea:	89a68693          	addi	a3,a3,-1894 # ffffffffc0206b80 <default_pmm_manager+0x648>
ffffffffc02032ee:	00003617          	auipc	a2,0x3
ffffffffc02032f2:	c6a60613          	addi	a2,a2,-918 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02032f6:	25d00593          	li	a1,605
ffffffffc02032fa:	00003517          	auipc	a0,0x3
ffffffffc02032fe:	38e50513          	addi	a0,a0,910 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203302:	98cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203306:	00003617          	auipc	a2,0x3
ffffffffc020330a:	31260613          	addi	a2,a2,786 # ffffffffc0206618 <default_pmm_manager+0xe0>
ffffffffc020330e:	0c900593          	li	a1,201
ffffffffc0203312:	00003517          	auipc	a0,0x3
ffffffffc0203316:	37650513          	addi	a0,a0,886 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc020331a:	974fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020331e:	00003617          	auipc	a2,0x3
ffffffffc0203322:	2fa60613          	addi	a2,a2,762 # ffffffffc0206618 <default_pmm_manager+0xe0>
ffffffffc0203326:	08100593          	li	a1,129
ffffffffc020332a:	00003517          	auipc	a0,0x3
ffffffffc020332e:	35e50513          	addi	a0,a0,862 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203332:	95cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203336:	00003697          	auipc	a3,0x3
ffffffffc020333a:	51a68693          	addi	a3,a3,1306 # ffffffffc0206850 <default_pmm_manager+0x318>
ffffffffc020333e:	00003617          	auipc	a2,0x3
ffffffffc0203342:	c1a60613          	addi	a2,a2,-998 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203346:	21d00593          	li	a1,541
ffffffffc020334a:	00003517          	auipc	a0,0x3
ffffffffc020334e:	33e50513          	addi	a0,a0,830 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203352:	93cfd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203356:	00003697          	auipc	a3,0x3
ffffffffc020335a:	4ca68693          	addi	a3,a3,1226 # ffffffffc0206820 <default_pmm_manager+0x2e8>
ffffffffc020335e:	00003617          	auipc	a2,0x3
ffffffffc0203362:	bfa60613          	addi	a2,a2,-1030 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203366:	21a00593          	li	a1,538
ffffffffc020336a:	00003517          	auipc	a0,0x3
ffffffffc020336e:	31e50513          	addi	a0,a0,798 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203372:	91cfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203376 <copy_range>:
{
ffffffffc0203376:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203378:	00d667b3          	or	a5,a2,a3
{
ffffffffc020337c:	f486                	sd	ra,104(sp)
ffffffffc020337e:	f0a2                	sd	s0,96(sp)
ffffffffc0203380:	eca6                	sd	s1,88(sp)
ffffffffc0203382:	e8ca                	sd	s2,80(sp)
ffffffffc0203384:	e4ce                	sd	s3,72(sp)
ffffffffc0203386:	e0d2                	sd	s4,64(sp)
ffffffffc0203388:	fc56                	sd	s5,56(sp)
ffffffffc020338a:	f85a                	sd	s6,48(sp)
ffffffffc020338c:	f45e                	sd	s7,40(sp)
ffffffffc020338e:	f062                	sd	s8,32(sp)
ffffffffc0203390:	ec66                	sd	s9,24(sp)
ffffffffc0203392:	e86a                	sd	s10,16(sp)
ffffffffc0203394:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203396:	17d2                	slli	a5,a5,0x34
ffffffffc0203398:	20079f63          	bnez	a5,ffffffffc02035b6 <copy_range+0x240>
    assert(USER_ACCESS(start, end));
ffffffffc020339c:	002007b7          	lui	a5,0x200
ffffffffc02033a0:	8432                	mv	s0,a2
ffffffffc02033a2:	1af66263          	bltu	a2,a5,ffffffffc0203546 <copy_range+0x1d0>
ffffffffc02033a6:	8936                	mv	s2,a3
ffffffffc02033a8:	18d67f63          	bgeu	a2,a3,ffffffffc0203546 <copy_range+0x1d0>
ffffffffc02033ac:	4785                	li	a5,1
ffffffffc02033ae:	07fe                	slli	a5,a5,0x1f
ffffffffc02033b0:	18d7eb63          	bltu	a5,a3,ffffffffc0203546 <copy_range+0x1d0>
ffffffffc02033b4:	5b7d                	li	s6,-1
ffffffffc02033b6:	8aaa                	mv	s5,a0
ffffffffc02033b8:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc02033ba:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02033bc:	000a7c17          	auipc	s8,0xa7
ffffffffc02033c0:	51cc0c13          	addi	s8,s8,1308 # ffffffffc02aa8d8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02033c4:	000a7b97          	auipc	s7,0xa7
ffffffffc02033c8:	51cb8b93          	addi	s7,s7,1308 # ffffffffc02aa8e0 <pages>
    return KADDR(page2pa(page));
ffffffffc02033cc:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc02033d0:	000a7c97          	auipc	s9,0xa7
ffffffffc02033d4:	518c8c93          	addi	s9,s9,1304 # ffffffffc02aa8e8 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02033d8:	4601                	li	a2,0
ffffffffc02033da:	85a2                	mv	a1,s0
ffffffffc02033dc:	854e                	mv	a0,s3
ffffffffc02033de:	b73fe0ef          	jal	ra,ffffffffc0201f50 <get_pte>
ffffffffc02033e2:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02033e4:	0e050c63          	beqz	a0,ffffffffc02034dc <copy_range+0x166>
        if (*ptep & PTE_V)
ffffffffc02033e8:	611c                	ld	a5,0(a0)
ffffffffc02033ea:	8b85                	andi	a5,a5,1
ffffffffc02033ec:	e785                	bnez	a5,ffffffffc0203414 <copy_range+0x9e>
        start += PGSIZE;
ffffffffc02033ee:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02033f0:	ff2464e3          	bltu	s0,s2,ffffffffc02033d8 <copy_range+0x62>
    return 0;
ffffffffc02033f4:	4501                	li	a0,0
}
ffffffffc02033f6:	70a6                	ld	ra,104(sp)
ffffffffc02033f8:	7406                	ld	s0,96(sp)
ffffffffc02033fa:	64e6                	ld	s1,88(sp)
ffffffffc02033fc:	6946                	ld	s2,80(sp)
ffffffffc02033fe:	69a6                	ld	s3,72(sp)
ffffffffc0203400:	6a06                	ld	s4,64(sp)
ffffffffc0203402:	7ae2                	ld	s5,56(sp)
ffffffffc0203404:	7b42                	ld	s6,48(sp)
ffffffffc0203406:	7ba2                	ld	s7,40(sp)
ffffffffc0203408:	7c02                	ld	s8,32(sp)
ffffffffc020340a:	6ce2                	ld	s9,24(sp)
ffffffffc020340c:	6d42                	ld	s10,16(sp)
ffffffffc020340e:	6da2                	ld	s11,8(sp)
ffffffffc0203410:	6165                	addi	sp,sp,112
ffffffffc0203412:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203414:	4605                	li	a2,1
ffffffffc0203416:	85a2                	mv	a1,s0
ffffffffc0203418:	8556                	mv	a0,s5
ffffffffc020341a:	b37fe0ef          	jal	ra,ffffffffc0201f50 <get_pte>
ffffffffc020341e:	c56d                	beqz	a0,ffffffffc0203508 <copy_range+0x192>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203420:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203422:	0017f713          	andi	a4,a5,1
ffffffffc0203426:	01f7f493          	andi	s1,a5,31
ffffffffc020342a:	16070a63          	beqz	a4,ffffffffc020359e <copy_range+0x228>
    if (PPN(pa) >= npage)
ffffffffc020342e:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203432:	078a                	slli	a5,a5,0x2
ffffffffc0203434:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203438:	14d77763          	bgeu	a4,a3,ffffffffc0203586 <copy_range+0x210>
    return &pages[PPN(pa) - nbase];
ffffffffc020343c:	000bb783          	ld	a5,0(s7)
ffffffffc0203440:	fff806b7          	lui	a3,0xfff80
ffffffffc0203444:	9736                	add	a4,a4,a3
ffffffffc0203446:	071a                	slli	a4,a4,0x6
ffffffffc0203448:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020344c:	10002773          	csrr	a4,sstatus
ffffffffc0203450:	8b09                	andi	a4,a4,2
ffffffffc0203452:	e345                	bnez	a4,ffffffffc02034f2 <copy_range+0x17c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203454:	000cb703          	ld	a4,0(s9)
ffffffffc0203458:	4505                	li	a0,1
ffffffffc020345a:	6f18                	ld	a4,24(a4)
ffffffffc020345c:	9702                	jalr	a4
ffffffffc020345e:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc0203460:	0c0d8363          	beqz	s11,ffffffffc0203526 <copy_range+0x1b0>
            assert(npage != NULL);
ffffffffc0203464:	100d0163          	beqz	s10,ffffffffc0203566 <copy_range+0x1f0>
    return page - pages + nbase;
ffffffffc0203468:	000bb703          	ld	a4,0(s7)
ffffffffc020346c:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc0203470:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0203474:	40ed86b3          	sub	a3,s11,a4
ffffffffc0203478:	8699                	srai	a3,a3,0x6
ffffffffc020347a:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc020347c:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203480:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203482:	08c7f663          	bgeu	a5,a2,ffffffffc020350e <copy_range+0x198>
    return page - pages + nbase;
ffffffffc0203486:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc020348a:	000a7717          	auipc	a4,0xa7
ffffffffc020348e:	46670713          	addi	a4,a4,1126 # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0203492:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc0203494:	8799                	srai	a5,a5,0x6
ffffffffc0203496:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc0203498:	0167f733          	and	a4,a5,s6
ffffffffc020349c:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02034a0:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02034a2:	06c77563          	bgeu	a4,a2,ffffffffc020350c <copy_range+0x196>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02034a6:	6605                	lui	a2,0x1
ffffffffc02034a8:	953e                	add	a0,a0,a5
ffffffffc02034aa:	236020ef          	jal	ra,ffffffffc02056e0 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc02034ae:	86a6                	mv	a3,s1
ffffffffc02034b0:	8622                	mv	a2,s0
ffffffffc02034b2:	85ea                	mv	a1,s10
ffffffffc02034b4:	8556                	mv	a0,s5
ffffffffc02034b6:	98aff0ef          	jal	ra,ffffffffc0202640 <page_insert>
            assert(ret == 0);
ffffffffc02034ba:	d915                	beqz	a0,ffffffffc02033ee <copy_range+0x78>
ffffffffc02034bc:	00003697          	auipc	a3,0x3
ffffffffc02034c0:	7dc68693          	addi	a3,a3,2012 # ffffffffc0206c98 <default_pmm_manager+0x760>
ffffffffc02034c4:	00003617          	auipc	a2,0x3
ffffffffc02034c8:	a9460613          	addi	a2,a2,-1388 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02034cc:	1b200593          	li	a1,434
ffffffffc02034d0:	00003517          	auipc	a0,0x3
ffffffffc02034d4:	1b850513          	addi	a0,a0,440 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02034d8:	fb7fc0ef          	jal	ra,ffffffffc020048e <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02034dc:	00200637          	lui	a2,0x200
ffffffffc02034e0:	9432                	add	s0,s0,a2
ffffffffc02034e2:	ffe00637          	lui	a2,0xffe00
ffffffffc02034e6:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc02034e8:	f00406e3          	beqz	s0,ffffffffc02033f4 <copy_range+0x7e>
ffffffffc02034ec:	ef2466e3          	bltu	s0,s2,ffffffffc02033d8 <copy_range+0x62>
ffffffffc02034f0:	b711                	j	ffffffffc02033f4 <copy_range+0x7e>
        intr_disable();
ffffffffc02034f2:	cc2fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034f6:	000cb703          	ld	a4,0(s9)
ffffffffc02034fa:	4505                	li	a0,1
ffffffffc02034fc:	6f18                	ld	a4,24(a4)
ffffffffc02034fe:	9702                	jalr	a4
ffffffffc0203500:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc0203502:	cacfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203506:	bfa9                	j	ffffffffc0203460 <copy_range+0xea>
                return -E_NO_MEM;
ffffffffc0203508:	5571                	li	a0,-4
ffffffffc020350a:	b5f5                	j	ffffffffc02033f6 <copy_range+0x80>
ffffffffc020350c:	86be                	mv	a3,a5
ffffffffc020350e:	00003617          	auipc	a2,0x3
ffffffffc0203512:	06260613          	addi	a2,a2,98 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc0203516:	07100593          	li	a1,113
ffffffffc020351a:	00003517          	auipc	a0,0x3
ffffffffc020351e:	07e50513          	addi	a0,a0,126 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc0203522:	f6dfc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc0203526:	00003697          	auipc	a3,0x3
ffffffffc020352a:	75268693          	addi	a3,a3,1874 # ffffffffc0206c78 <default_pmm_manager+0x740>
ffffffffc020352e:	00003617          	auipc	a2,0x3
ffffffffc0203532:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203536:	19400593          	li	a1,404
ffffffffc020353a:	00003517          	auipc	a0,0x3
ffffffffc020353e:	14e50513          	addi	a0,a0,334 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203542:	f4dfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203546:	00003697          	auipc	a3,0x3
ffffffffc020354a:	18268693          	addi	a3,a3,386 # ffffffffc02066c8 <default_pmm_manager+0x190>
ffffffffc020354e:	00003617          	auipc	a2,0x3
ffffffffc0203552:	a0a60613          	addi	a2,a2,-1526 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203556:	17c00593          	li	a1,380
ffffffffc020355a:	00003517          	auipc	a0,0x3
ffffffffc020355e:	12e50513          	addi	a0,a0,302 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203562:	f2dfc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(npage != NULL);
ffffffffc0203566:	00003697          	auipc	a3,0x3
ffffffffc020356a:	72268693          	addi	a3,a3,1826 # ffffffffc0206c88 <default_pmm_manager+0x750>
ffffffffc020356e:	00003617          	auipc	a2,0x3
ffffffffc0203572:	9ea60613          	addi	a2,a2,-1558 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203576:	19500593          	li	a1,405
ffffffffc020357a:	00003517          	auipc	a0,0x3
ffffffffc020357e:	10e50513          	addi	a0,a0,270 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203582:	f0dfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203586:	00003617          	auipc	a2,0x3
ffffffffc020358a:	0ba60613          	addi	a2,a2,186 # ffffffffc0206640 <default_pmm_manager+0x108>
ffffffffc020358e:	06900593          	li	a1,105
ffffffffc0203592:	00003517          	auipc	a0,0x3
ffffffffc0203596:	00650513          	addi	a0,a0,6 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc020359a:	ef5fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020359e:	00003617          	auipc	a2,0x3
ffffffffc02035a2:	0c260613          	addi	a2,a2,194 # ffffffffc0206660 <default_pmm_manager+0x128>
ffffffffc02035a6:	07f00593          	li	a1,127
ffffffffc02035aa:	00003517          	auipc	a0,0x3
ffffffffc02035ae:	fee50513          	addi	a0,a0,-18 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc02035b2:	eddfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02035b6:	00003697          	auipc	a3,0x3
ffffffffc02035ba:	0e268693          	addi	a3,a3,226 # ffffffffc0206698 <default_pmm_manager+0x160>
ffffffffc02035be:	00003617          	auipc	a2,0x3
ffffffffc02035c2:	99a60613          	addi	a2,a2,-1638 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02035c6:	17b00593          	li	a1,379
ffffffffc02035ca:	00003517          	auipc	a0,0x3
ffffffffc02035ce:	0be50513          	addi	a0,a0,190 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc02035d2:	ebdfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02035d6 <pgdir_alloc_page>:
{
ffffffffc02035d6:	7179                	addi	sp,sp,-48
ffffffffc02035d8:	ec26                	sd	s1,24(sp)
ffffffffc02035da:	e84a                	sd	s2,16(sp)
ffffffffc02035dc:	e052                	sd	s4,0(sp)
ffffffffc02035de:	f406                	sd	ra,40(sp)
ffffffffc02035e0:	f022                	sd	s0,32(sp)
ffffffffc02035e2:	e44e                	sd	s3,8(sp)
ffffffffc02035e4:	8a2a                	mv	s4,a0
ffffffffc02035e6:	84ae                	mv	s1,a1
ffffffffc02035e8:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02035ea:	100027f3          	csrr	a5,sstatus
ffffffffc02035ee:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02035f0:	000a7997          	auipc	s3,0xa7
ffffffffc02035f4:	2f898993          	addi	s3,s3,760 # ffffffffc02aa8e8 <pmm_manager>
ffffffffc02035f8:	ef8d                	bnez	a5,ffffffffc0203632 <pgdir_alloc_page+0x5c>
ffffffffc02035fa:	0009b783          	ld	a5,0(s3)
ffffffffc02035fe:	4505                	li	a0,1
ffffffffc0203600:	6f9c                	ld	a5,24(a5)
ffffffffc0203602:	9782                	jalr	a5
ffffffffc0203604:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0203606:	cc09                	beqz	s0,ffffffffc0203620 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203608:	86ca                	mv	a3,s2
ffffffffc020360a:	8626                	mv	a2,s1
ffffffffc020360c:	85a2                	mv	a1,s0
ffffffffc020360e:	8552                	mv	a0,s4
ffffffffc0203610:	830ff0ef          	jal	ra,ffffffffc0202640 <page_insert>
ffffffffc0203614:	e915                	bnez	a0,ffffffffc0203648 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203616:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0203618:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc020361a:	4785                	li	a5,1
ffffffffc020361c:	04f71e63          	bne	a4,a5,ffffffffc0203678 <pgdir_alloc_page+0xa2>
}
ffffffffc0203620:	70a2                	ld	ra,40(sp)
ffffffffc0203622:	8522                	mv	a0,s0
ffffffffc0203624:	7402                	ld	s0,32(sp)
ffffffffc0203626:	64e2                	ld	s1,24(sp)
ffffffffc0203628:	6942                	ld	s2,16(sp)
ffffffffc020362a:	69a2                	ld	s3,8(sp)
ffffffffc020362c:	6a02                	ld	s4,0(sp)
ffffffffc020362e:	6145                	addi	sp,sp,48
ffffffffc0203630:	8082                	ret
        intr_disable();
ffffffffc0203632:	b82fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203636:	0009b783          	ld	a5,0(s3)
ffffffffc020363a:	4505                	li	a0,1
ffffffffc020363c:	6f9c                	ld	a5,24(a5)
ffffffffc020363e:	9782                	jalr	a5
ffffffffc0203640:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203642:	b6cfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203646:	b7c1                	j	ffffffffc0203606 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203648:	100027f3          	csrr	a5,sstatus
ffffffffc020364c:	8b89                	andi	a5,a5,2
ffffffffc020364e:	eb89                	bnez	a5,ffffffffc0203660 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203650:	0009b783          	ld	a5,0(s3)
ffffffffc0203654:	8522                	mv	a0,s0
ffffffffc0203656:	4585                	li	a1,1
ffffffffc0203658:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020365a:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020365c:	9782                	jalr	a5
    if (flag)
ffffffffc020365e:	b7c9                	j	ffffffffc0203620 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203660:	b54fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203664:	0009b783          	ld	a5,0(s3)
ffffffffc0203668:	8522                	mv	a0,s0
ffffffffc020366a:	4585                	li	a1,1
ffffffffc020366c:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020366e:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203670:	9782                	jalr	a5
        intr_enable();
ffffffffc0203672:	b3cfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203676:	b76d                	j	ffffffffc0203620 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203678:	00003697          	auipc	a3,0x3
ffffffffc020367c:	63068693          	addi	a3,a3,1584 # ffffffffc0206ca8 <default_pmm_manager+0x770>
ffffffffc0203680:	00003617          	auipc	a2,0x3
ffffffffc0203684:	8d860613          	addi	a2,a2,-1832 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203688:	1fb00593          	li	a1,507
ffffffffc020368c:	00003517          	auipc	a0,0x3
ffffffffc0203690:	ffc50513          	addi	a0,a0,-4 # ffffffffc0206688 <default_pmm_manager+0x150>
ffffffffc0203694:	dfbfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203698 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203698:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020369a:	00003697          	auipc	a3,0x3
ffffffffc020369e:	62668693          	addi	a3,a3,1574 # ffffffffc0206cc0 <default_pmm_manager+0x788>
ffffffffc02036a2:	00003617          	auipc	a2,0x3
ffffffffc02036a6:	8b660613          	addi	a2,a2,-1866 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02036aa:	07400593          	li	a1,116
ffffffffc02036ae:	00003517          	auipc	a0,0x3
ffffffffc02036b2:	63250513          	addi	a0,a0,1586 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036b6:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02036b8:	dd7fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02036bc <mm_create>:
{
ffffffffc02036bc:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036be:	04000513          	li	a0,64
{
ffffffffc02036c2:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036c4:	df6fe0ef          	jal	ra,ffffffffc0201cba <kmalloc>
    if (mm != NULL)
ffffffffc02036c8:	cd19                	beqz	a0,ffffffffc02036e6 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02036ca:	e508                	sd	a0,8(a0)
ffffffffc02036cc:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02036ce:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02036d2:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02036d6:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02036da:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02036de:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02036e2:	02053c23          	sd	zero,56(a0)
}
ffffffffc02036e6:	60a2                	ld	ra,8(sp)
ffffffffc02036e8:	0141                	addi	sp,sp,16
ffffffffc02036ea:	8082                	ret

ffffffffc02036ec <find_vma>:
{
ffffffffc02036ec:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02036ee:	c505                	beqz	a0,ffffffffc0203716 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02036f0:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02036f2:	c501                	beqz	a0,ffffffffc02036fa <find_vma+0xe>
ffffffffc02036f4:	651c                	ld	a5,8(a0)
ffffffffc02036f6:	02f5f263          	bgeu	a1,a5,ffffffffc020371a <find_vma+0x2e>
    return listelm->next;
ffffffffc02036fa:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02036fc:	00f68d63          	beq	a3,a5,ffffffffc0203716 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203700:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f4ea8>
ffffffffc0203704:	00e5e663          	bltu	a1,a4,ffffffffc0203710 <find_vma+0x24>
ffffffffc0203708:	ff07b703          	ld	a4,-16(a5)
ffffffffc020370c:	00e5ec63          	bltu	a1,a4,ffffffffc0203724 <find_vma+0x38>
ffffffffc0203710:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203712:	fef697e3          	bne	a3,a5,ffffffffc0203700 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203716:	4501                	li	a0,0
}
ffffffffc0203718:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020371a:	691c                	ld	a5,16(a0)
ffffffffc020371c:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02036fa <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203720:	ea88                	sd	a0,16(a3)
ffffffffc0203722:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203724:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203728:	ea88                	sd	a0,16(a3)
ffffffffc020372a:	8082                	ret

ffffffffc020372c <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc020372c:	6590                	ld	a2,8(a1)
ffffffffc020372e:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_exit_out_size+0x74ed0>
{
ffffffffc0203732:	1141                	addi	sp,sp,-16
ffffffffc0203734:	e406                	sd	ra,8(sp)
ffffffffc0203736:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203738:	01066763          	bltu	a2,a6,ffffffffc0203746 <insert_vma_struct+0x1a>
ffffffffc020373c:	a085                	j	ffffffffc020379c <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020373e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203742:	04e66863          	bltu	a2,a4,ffffffffc0203792 <insert_vma_struct+0x66>
ffffffffc0203746:	86be                	mv	a3,a5
ffffffffc0203748:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020374a:	fef51ae3          	bne	a0,a5,ffffffffc020373e <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020374e:	02a68463          	beq	a3,a0,ffffffffc0203776 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203752:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203756:	fe86b883          	ld	a7,-24(a3)
ffffffffc020375a:	08e8f163          	bgeu	a7,a4,ffffffffc02037dc <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020375e:	04e66f63          	bltu	a2,a4,ffffffffc02037bc <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203762:	00f50a63          	beq	a0,a5,ffffffffc0203776 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203766:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020376a:	05076963          	bltu	a4,a6,ffffffffc02037bc <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020376e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203772:	02c77363          	bgeu	a4,a2,ffffffffc0203798 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203776:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203778:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020377a:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020377e:	e390                	sd	a2,0(a5)
ffffffffc0203780:	e690                	sd	a2,8(a3)
}
ffffffffc0203782:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203784:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203786:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203788:	0017079b          	addiw	a5,a4,1
ffffffffc020378c:	d11c                	sw	a5,32(a0)
}
ffffffffc020378e:	0141                	addi	sp,sp,16
ffffffffc0203790:	8082                	ret
    if (le_prev != list)
ffffffffc0203792:	fca690e3          	bne	a3,a0,ffffffffc0203752 <insert_vma_struct+0x26>
ffffffffc0203796:	bfd1                	j	ffffffffc020376a <insert_vma_struct+0x3e>
ffffffffc0203798:	f01ff0ef          	jal	ra,ffffffffc0203698 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020379c:	00003697          	auipc	a3,0x3
ffffffffc02037a0:	55468693          	addi	a3,a3,1364 # ffffffffc0206cf0 <default_pmm_manager+0x7b8>
ffffffffc02037a4:	00002617          	auipc	a2,0x2
ffffffffc02037a8:	7b460613          	addi	a2,a2,1972 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02037ac:	07a00593          	li	a1,122
ffffffffc02037b0:	00003517          	auipc	a0,0x3
ffffffffc02037b4:	53050513          	addi	a0,a0,1328 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc02037b8:	cd7fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037bc:	00003697          	auipc	a3,0x3
ffffffffc02037c0:	57468693          	addi	a3,a3,1396 # ffffffffc0206d30 <default_pmm_manager+0x7f8>
ffffffffc02037c4:	00002617          	auipc	a2,0x2
ffffffffc02037c8:	79460613          	addi	a2,a2,1940 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02037cc:	07300593          	li	a1,115
ffffffffc02037d0:	00003517          	auipc	a0,0x3
ffffffffc02037d4:	51050513          	addi	a0,a0,1296 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc02037d8:	cb7fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02037dc:	00003697          	auipc	a3,0x3
ffffffffc02037e0:	53468693          	addi	a3,a3,1332 # ffffffffc0206d10 <default_pmm_manager+0x7d8>
ffffffffc02037e4:	00002617          	auipc	a2,0x2
ffffffffc02037e8:	77460613          	addi	a2,a2,1908 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02037ec:	07200593          	li	a1,114
ffffffffc02037f0:	00003517          	auipc	a0,0x3
ffffffffc02037f4:	4f050513          	addi	a0,a0,1264 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc02037f8:	c97fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02037fc <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02037fc:	591c                	lw	a5,48(a0)
{
ffffffffc02037fe:	1141                	addi	sp,sp,-16
ffffffffc0203800:	e406                	sd	ra,8(sp)
ffffffffc0203802:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203804:	e78d                	bnez	a5,ffffffffc020382e <mm_destroy+0x32>
ffffffffc0203806:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203808:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc020380a:	00a40c63          	beq	s0,a0,ffffffffc0203822 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020380e:	6118                	ld	a4,0(a0)
ffffffffc0203810:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203812:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203814:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203816:	e398                	sd	a4,0(a5)
ffffffffc0203818:	d52fe0ef          	jal	ra,ffffffffc0201d6a <kfree>
    return listelm->next;
ffffffffc020381c:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc020381e:	fea418e3          	bne	s0,a0,ffffffffc020380e <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203822:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203824:	6402                	ld	s0,0(sp)
ffffffffc0203826:	60a2                	ld	ra,8(sp)
ffffffffc0203828:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc020382a:	d40fe06f          	j	ffffffffc0201d6a <kfree>
    assert(mm_count(mm) == 0);
ffffffffc020382e:	00003697          	auipc	a3,0x3
ffffffffc0203832:	52268693          	addi	a3,a3,1314 # ffffffffc0206d50 <default_pmm_manager+0x818>
ffffffffc0203836:	00002617          	auipc	a2,0x2
ffffffffc020383a:	72260613          	addi	a2,a2,1826 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc020383e:	09e00593          	li	a1,158
ffffffffc0203842:	00003517          	auipc	a0,0x3
ffffffffc0203846:	49e50513          	addi	a0,a0,1182 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc020384a:	c45fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020384e <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc020384e:	7139                	addi	sp,sp,-64
ffffffffc0203850:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203852:	6405                	lui	s0,0x1
ffffffffc0203854:	147d                	addi	s0,s0,-1
ffffffffc0203856:	77fd                	lui	a5,0xfffff
ffffffffc0203858:	9622                	add	a2,a2,s0
ffffffffc020385a:	962e                	add	a2,a2,a1
{
ffffffffc020385c:	f426                	sd	s1,40(sp)
ffffffffc020385e:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203860:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203864:	f04a                	sd	s2,32(sp)
ffffffffc0203866:	ec4e                	sd	s3,24(sp)
ffffffffc0203868:	e852                	sd	s4,16(sp)
ffffffffc020386a:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc020386c:	002005b7          	lui	a1,0x200
ffffffffc0203870:	00f67433          	and	s0,a2,a5
ffffffffc0203874:	06b4e363          	bltu	s1,a1,ffffffffc02038da <mm_map+0x8c>
ffffffffc0203878:	0684f163          	bgeu	s1,s0,ffffffffc02038da <mm_map+0x8c>
ffffffffc020387c:	4785                	li	a5,1
ffffffffc020387e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203880:	0487ed63          	bltu	a5,s0,ffffffffc02038da <mm_map+0x8c>
ffffffffc0203884:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203886:	cd21                	beqz	a0,ffffffffc02038de <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203888:	85a6                	mv	a1,s1
ffffffffc020388a:	8ab6                	mv	s5,a3
ffffffffc020388c:	8a3a                	mv	s4,a4
ffffffffc020388e:	e5fff0ef          	jal	ra,ffffffffc02036ec <find_vma>
ffffffffc0203892:	c501                	beqz	a0,ffffffffc020389a <mm_map+0x4c>
ffffffffc0203894:	651c                	ld	a5,8(a0)
ffffffffc0203896:	0487e263          	bltu	a5,s0,ffffffffc02038da <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020389a:	03000513          	li	a0,48
ffffffffc020389e:	c1cfe0ef          	jal	ra,ffffffffc0201cba <kmalloc>
ffffffffc02038a2:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02038a4:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02038a6:	02090163          	beqz	s2,ffffffffc02038c8 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02038aa:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02038ac:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02038b0:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02038b4:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02038b8:	85ca                	mv	a1,s2
ffffffffc02038ba:	e73ff0ef          	jal	ra,ffffffffc020372c <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02038be:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02038c0:	000a0463          	beqz	s4,ffffffffc02038c8 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02038c4:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc8>

out:
    return ret;
}
ffffffffc02038c8:	70e2                	ld	ra,56(sp)
ffffffffc02038ca:	7442                	ld	s0,48(sp)
ffffffffc02038cc:	74a2                	ld	s1,40(sp)
ffffffffc02038ce:	7902                	ld	s2,32(sp)
ffffffffc02038d0:	69e2                	ld	s3,24(sp)
ffffffffc02038d2:	6a42                	ld	s4,16(sp)
ffffffffc02038d4:	6aa2                	ld	s5,8(sp)
ffffffffc02038d6:	6121                	addi	sp,sp,64
ffffffffc02038d8:	8082                	ret
        return -E_INVAL;
ffffffffc02038da:	5575                	li	a0,-3
ffffffffc02038dc:	b7f5                	j	ffffffffc02038c8 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02038de:	00003697          	auipc	a3,0x3
ffffffffc02038e2:	48a68693          	addi	a3,a3,1162 # ffffffffc0206d68 <default_pmm_manager+0x830>
ffffffffc02038e6:	00002617          	auipc	a2,0x2
ffffffffc02038ea:	67260613          	addi	a2,a2,1650 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02038ee:	0b300593          	li	a1,179
ffffffffc02038f2:	00003517          	auipc	a0,0x3
ffffffffc02038f6:	3ee50513          	addi	a0,a0,1006 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc02038fa:	b95fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038fe <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02038fe:	7139                	addi	sp,sp,-64
ffffffffc0203900:	fc06                	sd	ra,56(sp)
ffffffffc0203902:	f822                	sd	s0,48(sp)
ffffffffc0203904:	f426                	sd	s1,40(sp)
ffffffffc0203906:	f04a                	sd	s2,32(sp)
ffffffffc0203908:	ec4e                	sd	s3,24(sp)
ffffffffc020390a:	e852                	sd	s4,16(sp)
ffffffffc020390c:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc020390e:	c52d                	beqz	a0,ffffffffc0203978 <dup_mmap+0x7a>
ffffffffc0203910:	892a                	mv	s2,a0
ffffffffc0203912:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203914:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203916:	e595                	bnez	a1,ffffffffc0203942 <dup_mmap+0x44>
ffffffffc0203918:	a085                	j	ffffffffc0203978 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc020391a:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc020391c:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ec8>
        vma->vm_end = vm_end;
ffffffffc0203920:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203924:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203928:	e05ff0ef          	jal	ra,ffffffffc020372c <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc020392c:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bd8>
ffffffffc0203930:	fe843603          	ld	a2,-24(s0)
ffffffffc0203934:	6c8c                	ld	a1,24(s1)
ffffffffc0203936:	01893503          	ld	a0,24(s2)
ffffffffc020393a:	4701                	li	a4,0
ffffffffc020393c:	a3bff0ef          	jal	ra,ffffffffc0203376 <copy_range>
ffffffffc0203940:	e105                	bnez	a0,ffffffffc0203960 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203942:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203944:	02848863          	beq	s1,s0,ffffffffc0203974 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203948:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc020394c:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203950:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203954:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203958:	b62fe0ef          	jal	ra,ffffffffc0201cba <kmalloc>
ffffffffc020395c:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc020395e:	fd55                	bnez	a0,ffffffffc020391a <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203960:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203962:	70e2                	ld	ra,56(sp)
ffffffffc0203964:	7442                	ld	s0,48(sp)
ffffffffc0203966:	74a2                	ld	s1,40(sp)
ffffffffc0203968:	7902                	ld	s2,32(sp)
ffffffffc020396a:	69e2                	ld	s3,24(sp)
ffffffffc020396c:	6a42                	ld	s4,16(sp)
ffffffffc020396e:	6aa2                	ld	s5,8(sp)
ffffffffc0203970:	6121                	addi	sp,sp,64
ffffffffc0203972:	8082                	ret
    return 0;
ffffffffc0203974:	4501                	li	a0,0
ffffffffc0203976:	b7f5                	j	ffffffffc0203962 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203978:	00003697          	auipc	a3,0x3
ffffffffc020397c:	40068693          	addi	a3,a3,1024 # ffffffffc0206d78 <default_pmm_manager+0x840>
ffffffffc0203980:	00002617          	auipc	a2,0x2
ffffffffc0203984:	5d860613          	addi	a2,a2,1496 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203988:	0cf00593          	li	a1,207
ffffffffc020398c:	00003517          	auipc	a0,0x3
ffffffffc0203990:	35450513          	addi	a0,a0,852 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203994:	afbfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203998 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203998:	1101                	addi	sp,sp,-32
ffffffffc020399a:	ec06                	sd	ra,24(sp)
ffffffffc020399c:	e822                	sd	s0,16(sp)
ffffffffc020399e:	e426                	sd	s1,8(sp)
ffffffffc02039a0:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039a2:	c531                	beqz	a0,ffffffffc02039ee <exit_mmap+0x56>
ffffffffc02039a4:	591c                	lw	a5,48(a0)
ffffffffc02039a6:	84aa                	mv	s1,a0
ffffffffc02039a8:	e3b9                	bnez	a5,ffffffffc02039ee <exit_mmap+0x56>
    return listelm->next;
ffffffffc02039aa:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02039ac:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc02039b0:	02850663          	beq	a0,s0,ffffffffc02039dc <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039b4:	ff043603          	ld	a2,-16(s0)
ffffffffc02039b8:	fe843583          	ld	a1,-24(s0)
ffffffffc02039bc:	854a                	mv	a0,s2
ffffffffc02039be:	80ffe0ef          	jal	ra,ffffffffc02021cc <unmap_range>
ffffffffc02039c2:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039c4:	fe8498e3          	bne	s1,s0,ffffffffc02039b4 <exit_mmap+0x1c>
ffffffffc02039c8:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02039ca:	00848c63          	beq	s1,s0,ffffffffc02039e2 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039ce:	ff043603          	ld	a2,-16(s0)
ffffffffc02039d2:	fe843583          	ld	a1,-24(s0)
ffffffffc02039d6:	854a                	mv	a0,s2
ffffffffc02039d8:	93bfe0ef          	jal	ra,ffffffffc0202312 <exit_range>
ffffffffc02039dc:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039de:	fe8498e3          	bne	s1,s0,ffffffffc02039ce <exit_mmap+0x36>
    }
}
ffffffffc02039e2:	60e2                	ld	ra,24(sp)
ffffffffc02039e4:	6442                	ld	s0,16(sp)
ffffffffc02039e6:	64a2                	ld	s1,8(sp)
ffffffffc02039e8:	6902                	ld	s2,0(sp)
ffffffffc02039ea:	6105                	addi	sp,sp,32
ffffffffc02039ec:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039ee:	00003697          	auipc	a3,0x3
ffffffffc02039f2:	3aa68693          	addi	a3,a3,938 # ffffffffc0206d98 <default_pmm_manager+0x860>
ffffffffc02039f6:	00002617          	auipc	a2,0x2
ffffffffc02039fa:	56260613          	addi	a2,a2,1378 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02039fe:	0e800593          	li	a1,232
ffffffffc0203a02:	00003517          	auipc	a0,0x3
ffffffffc0203a06:	2de50513          	addi	a0,a0,734 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203a0a:	a85fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a0e <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203a0e:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a10:	04000513          	li	a0,64
{
ffffffffc0203a14:	fc06                	sd	ra,56(sp)
ffffffffc0203a16:	f822                	sd	s0,48(sp)
ffffffffc0203a18:	f426                	sd	s1,40(sp)
ffffffffc0203a1a:	f04a                	sd	s2,32(sp)
ffffffffc0203a1c:	ec4e                	sd	s3,24(sp)
ffffffffc0203a1e:	e852                	sd	s4,16(sp)
ffffffffc0203a20:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a22:	a98fe0ef          	jal	ra,ffffffffc0201cba <kmalloc>
    if (mm != NULL)
ffffffffc0203a26:	2e050663          	beqz	a0,ffffffffc0203d12 <vmm_init+0x304>
ffffffffc0203a2a:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203a2c:	e508                	sd	a0,8(a0)
ffffffffc0203a2e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a30:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a34:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a38:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203a3c:	02053423          	sd	zero,40(a0)
ffffffffc0203a40:	02052823          	sw	zero,48(a0)
ffffffffc0203a44:	02053c23          	sd	zero,56(a0)
ffffffffc0203a48:	03200413          	li	s0,50
ffffffffc0203a4c:	a811                	j	ffffffffc0203a60 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203a4e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a50:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a52:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203a56:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a58:	8526                	mv	a0,s1
ffffffffc0203a5a:	cd3ff0ef          	jal	ra,ffffffffc020372c <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203a5e:	c80d                	beqz	s0,ffffffffc0203a90 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a60:	03000513          	li	a0,48
ffffffffc0203a64:	a56fe0ef          	jal	ra,ffffffffc0201cba <kmalloc>
ffffffffc0203a68:	85aa                	mv	a1,a0
ffffffffc0203a6a:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203a6e:	f165                	bnez	a0,ffffffffc0203a4e <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203a70:	00003697          	auipc	a3,0x3
ffffffffc0203a74:	4c068693          	addi	a3,a3,1216 # ffffffffc0206f30 <default_pmm_manager+0x9f8>
ffffffffc0203a78:	00002617          	auipc	a2,0x2
ffffffffc0203a7c:	4e060613          	addi	a2,a2,1248 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203a80:	12c00593          	li	a1,300
ffffffffc0203a84:	00003517          	auipc	a0,0x3
ffffffffc0203a88:	25c50513          	addi	a0,a0,604 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203a8c:	a03fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203a90:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203a94:	1f900913          	li	s2,505
ffffffffc0203a98:	a819                	j	ffffffffc0203aae <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203a9a:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a9c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a9e:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203aa2:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203aa4:	8526                	mv	a0,s1
ffffffffc0203aa6:	c87ff0ef          	jal	ra,ffffffffc020372c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203aaa:	03240a63          	beq	s0,s2,ffffffffc0203ade <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203aae:	03000513          	li	a0,48
ffffffffc0203ab2:	a08fe0ef          	jal	ra,ffffffffc0201cba <kmalloc>
ffffffffc0203ab6:	85aa                	mv	a1,a0
ffffffffc0203ab8:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203abc:	fd79                	bnez	a0,ffffffffc0203a9a <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203abe:	00003697          	auipc	a3,0x3
ffffffffc0203ac2:	47268693          	addi	a3,a3,1138 # ffffffffc0206f30 <default_pmm_manager+0x9f8>
ffffffffc0203ac6:	00002617          	auipc	a2,0x2
ffffffffc0203aca:	49260613          	addi	a2,a2,1170 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203ace:	13300593          	li	a1,307
ffffffffc0203ad2:	00003517          	auipc	a0,0x3
ffffffffc0203ad6:	20e50513          	addi	a0,a0,526 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203ada:	9b5fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203ade:	649c                	ld	a5,8(s1)
ffffffffc0203ae0:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203ae2:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203ae6:	16f48663          	beq	s1,a5,ffffffffc0203c52 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203aea:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd546d4>
ffffffffc0203aee:	ffe70693          	addi	a3,a4,-2
ffffffffc0203af2:	10d61063          	bne	a2,a3,ffffffffc0203bf2 <vmm_init+0x1e4>
ffffffffc0203af6:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203afa:	0ed71c63          	bne	a4,a3,ffffffffc0203bf2 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203afe:	0715                	addi	a4,a4,5
ffffffffc0203b00:	679c                	ld	a5,8(a5)
ffffffffc0203b02:	feb712e3          	bne	a4,a1,ffffffffc0203ae6 <vmm_init+0xd8>
ffffffffc0203b06:	4a1d                	li	s4,7
ffffffffc0203b08:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b0a:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b0e:	85a2                	mv	a1,s0
ffffffffc0203b10:	8526                	mv	a0,s1
ffffffffc0203b12:	bdbff0ef          	jal	ra,ffffffffc02036ec <find_vma>
ffffffffc0203b16:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203b18:	16050d63          	beqz	a0,ffffffffc0203c92 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203b1c:	00140593          	addi	a1,s0,1
ffffffffc0203b20:	8526                	mv	a0,s1
ffffffffc0203b22:	bcbff0ef          	jal	ra,ffffffffc02036ec <find_vma>
ffffffffc0203b26:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b28:	14050563          	beqz	a0,ffffffffc0203c72 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b2c:	85d2                	mv	a1,s4
ffffffffc0203b2e:	8526                	mv	a0,s1
ffffffffc0203b30:	bbdff0ef          	jal	ra,ffffffffc02036ec <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b34:	16051f63          	bnez	a0,ffffffffc0203cb2 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b38:	00340593          	addi	a1,s0,3
ffffffffc0203b3c:	8526                	mv	a0,s1
ffffffffc0203b3e:	bafff0ef          	jal	ra,ffffffffc02036ec <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b42:	1a051863          	bnez	a0,ffffffffc0203cf2 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b46:	00440593          	addi	a1,s0,4
ffffffffc0203b4a:	8526                	mv	a0,s1
ffffffffc0203b4c:	ba1ff0ef          	jal	ra,ffffffffc02036ec <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b50:	18051163          	bnez	a0,ffffffffc0203cd2 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b54:	00893783          	ld	a5,8(s2)
ffffffffc0203b58:	0a879d63          	bne	a5,s0,ffffffffc0203c12 <vmm_init+0x204>
ffffffffc0203b5c:	01093783          	ld	a5,16(s2)
ffffffffc0203b60:	0b479963          	bne	a5,s4,ffffffffc0203c12 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b64:	0089b783          	ld	a5,8(s3)
ffffffffc0203b68:	0c879563          	bne	a5,s0,ffffffffc0203c32 <vmm_init+0x224>
ffffffffc0203b6c:	0109b783          	ld	a5,16(s3)
ffffffffc0203b70:	0d479163          	bne	a5,s4,ffffffffc0203c32 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b74:	0415                	addi	s0,s0,5
ffffffffc0203b76:	0a15                	addi	s4,s4,5
ffffffffc0203b78:	f9541be3          	bne	s0,s5,ffffffffc0203b0e <vmm_init+0x100>
ffffffffc0203b7c:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203b7e:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203b80:	85a2                	mv	a1,s0
ffffffffc0203b82:	8526                	mv	a0,s1
ffffffffc0203b84:	b69ff0ef          	jal	ra,ffffffffc02036ec <find_vma>
ffffffffc0203b88:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203b8c:	c90d                	beqz	a0,ffffffffc0203bbe <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203b8e:	6914                	ld	a3,16(a0)
ffffffffc0203b90:	6510                	ld	a2,8(a0)
ffffffffc0203b92:	00003517          	auipc	a0,0x3
ffffffffc0203b96:	32650513          	addi	a0,a0,806 # ffffffffc0206eb8 <default_pmm_manager+0x980>
ffffffffc0203b9a:	dfafc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203b9e:	00003697          	auipc	a3,0x3
ffffffffc0203ba2:	34268693          	addi	a3,a3,834 # ffffffffc0206ee0 <default_pmm_manager+0x9a8>
ffffffffc0203ba6:	00002617          	auipc	a2,0x2
ffffffffc0203baa:	3b260613          	addi	a2,a2,946 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203bae:	15900593          	li	a1,345
ffffffffc0203bb2:	00003517          	auipc	a0,0x3
ffffffffc0203bb6:	12e50513          	addi	a0,a0,302 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203bba:	8d5fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203bbe:	147d                	addi	s0,s0,-1
ffffffffc0203bc0:	fd2410e3          	bne	s0,s2,ffffffffc0203b80 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203bc4:	8526                	mv	a0,s1
ffffffffc0203bc6:	c37ff0ef          	jal	ra,ffffffffc02037fc <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203bca:	00003517          	auipc	a0,0x3
ffffffffc0203bce:	32e50513          	addi	a0,a0,814 # ffffffffc0206ef8 <default_pmm_manager+0x9c0>
ffffffffc0203bd2:	dc2fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203bd6:	7442                	ld	s0,48(sp)
ffffffffc0203bd8:	70e2                	ld	ra,56(sp)
ffffffffc0203bda:	74a2                	ld	s1,40(sp)
ffffffffc0203bdc:	7902                	ld	s2,32(sp)
ffffffffc0203bde:	69e2                	ld	s3,24(sp)
ffffffffc0203be0:	6a42                	ld	s4,16(sp)
ffffffffc0203be2:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203be4:	00003517          	auipc	a0,0x3
ffffffffc0203be8:	33450513          	addi	a0,a0,820 # ffffffffc0206f18 <default_pmm_manager+0x9e0>
}
ffffffffc0203bec:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bee:	da6fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203bf2:	00003697          	auipc	a3,0x3
ffffffffc0203bf6:	1de68693          	addi	a3,a3,478 # ffffffffc0206dd0 <default_pmm_manager+0x898>
ffffffffc0203bfa:	00002617          	auipc	a2,0x2
ffffffffc0203bfe:	35e60613          	addi	a2,a2,862 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203c02:	13d00593          	li	a1,317
ffffffffc0203c06:	00003517          	auipc	a0,0x3
ffffffffc0203c0a:	0da50513          	addi	a0,a0,218 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203c0e:	881fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203c12:	00003697          	auipc	a3,0x3
ffffffffc0203c16:	24668693          	addi	a3,a3,582 # ffffffffc0206e58 <default_pmm_manager+0x920>
ffffffffc0203c1a:	00002617          	auipc	a2,0x2
ffffffffc0203c1e:	33e60613          	addi	a2,a2,830 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203c22:	14e00593          	li	a1,334
ffffffffc0203c26:	00003517          	auipc	a0,0x3
ffffffffc0203c2a:	0ba50513          	addi	a0,a0,186 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203c2e:	861fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c32:	00003697          	auipc	a3,0x3
ffffffffc0203c36:	25668693          	addi	a3,a3,598 # ffffffffc0206e88 <default_pmm_manager+0x950>
ffffffffc0203c3a:	00002617          	auipc	a2,0x2
ffffffffc0203c3e:	31e60613          	addi	a2,a2,798 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203c42:	14f00593          	li	a1,335
ffffffffc0203c46:	00003517          	auipc	a0,0x3
ffffffffc0203c4a:	09a50513          	addi	a0,a0,154 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203c4e:	841fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203c52:	00003697          	auipc	a3,0x3
ffffffffc0203c56:	16668693          	addi	a3,a3,358 # ffffffffc0206db8 <default_pmm_manager+0x880>
ffffffffc0203c5a:	00002617          	auipc	a2,0x2
ffffffffc0203c5e:	2fe60613          	addi	a2,a2,766 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203c62:	13b00593          	li	a1,315
ffffffffc0203c66:	00003517          	auipc	a0,0x3
ffffffffc0203c6a:	07a50513          	addi	a0,a0,122 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203c6e:	821fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203c72:	00003697          	auipc	a3,0x3
ffffffffc0203c76:	1a668693          	addi	a3,a3,422 # ffffffffc0206e18 <default_pmm_manager+0x8e0>
ffffffffc0203c7a:	00002617          	auipc	a2,0x2
ffffffffc0203c7e:	2de60613          	addi	a2,a2,734 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203c82:	14600593          	li	a1,326
ffffffffc0203c86:	00003517          	auipc	a0,0x3
ffffffffc0203c8a:	05a50513          	addi	a0,a0,90 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203c8e:	801fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203c92:	00003697          	auipc	a3,0x3
ffffffffc0203c96:	17668693          	addi	a3,a3,374 # ffffffffc0206e08 <default_pmm_manager+0x8d0>
ffffffffc0203c9a:	00002617          	auipc	a2,0x2
ffffffffc0203c9e:	2be60613          	addi	a2,a2,702 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203ca2:	14400593          	li	a1,324
ffffffffc0203ca6:	00003517          	auipc	a0,0x3
ffffffffc0203caa:	03a50513          	addi	a0,a0,58 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203cae:	fe0fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203cb2:	00003697          	auipc	a3,0x3
ffffffffc0203cb6:	17668693          	addi	a3,a3,374 # ffffffffc0206e28 <default_pmm_manager+0x8f0>
ffffffffc0203cba:	00002617          	auipc	a2,0x2
ffffffffc0203cbe:	29e60613          	addi	a2,a2,670 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203cc2:	14800593          	li	a1,328
ffffffffc0203cc6:	00003517          	auipc	a0,0x3
ffffffffc0203cca:	01a50513          	addi	a0,a0,26 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203cce:	fc0fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203cd2:	00003697          	auipc	a3,0x3
ffffffffc0203cd6:	17668693          	addi	a3,a3,374 # ffffffffc0206e48 <default_pmm_manager+0x910>
ffffffffc0203cda:	00002617          	auipc	a2,0x2
ffffffffc0203cde:	27e60613          	addi	a2,a2,638 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203ce2:	14c00593          	li	a1,332
ffffffffc0203ce6:	00003517          	auipc	a0,0x3
ffffffffc0203cea:	ffa50513          	addi	a0,a0,-6 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203cee:	fa0fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203cf2:	00003697          	auipc	a3,0x3
ffffffffc0203cf6:	14668693          	addi	a3,a3,326 # ffffffffc0206e38 <default_pmm_manager+0x900>
ffffffffc0203cfa:	00002617          	auipc	a2,0x2
ffffffffc0203cfe:	25e60613          	addi	a2,a2,606 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203d02:	14a00593          	li	a1,330
ffffffffc0203d06:	00003517          	auipc	a0,0x3
ffffffffc0203d0a:	fda50513          	addi	a0,a0,-38 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203d0e:	f80fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203d12:	00003697          	auipc	a3,0x3
ffffffffc0203d16:	05668693          	addi	a3,a3,86 # ffffffffc0206d68 <default_pmm_manager+0x830>
ffffffffc0203d1a:	00002617          	auipc	a2,0x2
ffffffffc0203d1e:	23e60613          	addi	a2,a2,574 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0203d22:	12400593          	li	a1,292
ffffffffc0203d26:	00003517          	auipc	a0,0x3
ffffffffc0203d2a:	fba50513          	addi	a0,a0,-70 # ffffffffc0206ce0 <default_pmm_manager+0x7a8>
ffffffffc0203d2e:	f60fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203d32 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203d32:	7179                	addi	sp,sp,-48
ffffffffc0203d34:	f022                	sd	s0,32(sp)
ffffffffc0203d36:	f406                	sd	ra,40(sp)
ffffffffc0203d38:	ec26                	sd	s1,24(sp)
ffffffffc0203d3a:	e84a                	sd	s2,16(sp)
ffffffffc0203d3c:	e44e                	sd	s3,8(sp)
ffffffffc0203d3e:	e052                	sd	s4,0(sp)
ffffffffc0203d40:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203d42:	c135                	beqz	a0,ffffffffc0203da6 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203d44:	002007b7          	lui	a5,0x200
ffffffffc0203d48:	04f5e663          	bltu	a1,a5,ffffffffc0203d94 <user_mem_check+0x62>
ffffffffc0203d4c:	00c584b3          	add	s1,a1,a2
ffffffffc0203d50:	0495f263          	bgeu	a1,s1,ffffffffc0203d94 <user_mem_check+0x62>
ffffffffc0203d54:	4785                	li	a5,1
ffffffffc0203d56:	07fe                	slli	a5,a5,0x1f
ffffffffc0203d58:	0297ee63          	bltu	a5,s1,ffffffffc0203d94 <user_mem_check+0x62>
ffffffffc0203d5c:	892a                	mv	s2,a0
ffffffffc0203d5e:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d60:	6a05                	lui	s4,0x1
ffffffffc0203d62:	a821                	j	ffffffffc0203d7a <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d64:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d68:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203d6a:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d6c:	c685                	beqz	a3,ffffffffc0203d94 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203d6e:	c399                	beqz	a5,ffffffffc0203d74 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d70:	02e46263          	bltu	s0,a4,ffffffffc0203d94 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203d74:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203d76:	04947663          	bgeu	s0,s1,ffffffffc0203dc2 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203d7a:	85a2                	mv	a1,s0
ffffffffc0203d7c:	854a                	mv	a0,s2
ffffffffc0203d7e:	96fff0ef          	jal	ra,ffffffffc02036ec <find_vma>
ffffffffc0203d82:	c909                	beqz	a0,ffffffffc0203d94 <user_mem_check+0x62>
ffffffffc0203d84:	6518                	ld	a4,8(a0)
ffffffffc0203d86:	00e46763          	bltu	s0,a4,ffffffffc0203d94 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d8a:	4d1c                	lw	a5,24(a0)
ffffffffc0203d8c:	fc099ce3          	bnez	s3,ffffffffc0203d64 <user_mem_check+0x32>
ffffffffc0203d90:	8b85                	andi	a5,a5,1
ffffffffc0203d92:	f3ed                	bnez	a5,ffffffffc0203d74 <user_mem_check+0x42>
            return 0;
ffffffffc0203d94:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203d96:	70a2                	ld	ra,40(sp)
ffffffffc0203d98:	7402                	ld	s0,32(sp)
ffffffffc0203d9a:	64e2                	ld	s1,24(sp)
ffffffffc0203d9c:	6942                	ld	s2,16(sp)
ffffffffc0203d9e:	69a2                	ld	s3,8(sp)
ffffffffc0203da0:	6a02                	ld	s4,0(sp)
ffffffffc0203da2:	6145                	addi	sp,sp,48
ffffffffc0203da4:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203da6:	c02007b7          	lui	a5,0xc0200
ffffffffc0203daa:	4501                	li	a0,0
ffffffffc0203dac:	fef5e5e3          	bltu	a1,a5,ffffffffc0203d96 <user_mem_check+0x64>
ffffffffc0203db0:	962e                	add	a2,a2,a1
ffffffffc0203db2:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203d96 <user_mem_check+0x64>
ffffffffc0203db6:	c8000537          	lui	a0,0xc8000
ffffffffc0203dba:	0505                	addi	a0,a0,1
ffffffffc0203dbc:	00a63533          	sltu	a0,a2,a0
ffffffffc0203dc0:	bfd9                	j	ffffffffc0203d96 <user_mem_check+0x64>
        return 1;
ffffffffc0203dc2:	4505                	li	a0,1
ffffffffc0203dc4:	bfc9                	j	ffffffffc0203d96 <user_mem_check+0x64>

ffffffffc0203dc6 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203dc6:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203dc8:	9402                	jalr	s0

	jal do_exit
ffffffffc0203dca:	638000ef          	jal	ra,ffffffffc0204402 <do_exit>

ffffffffc0203dce <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203dce:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203dd0:	10800513          	li	a0,264
{
ffffffffc0203dd4:	e022                	sd	s0,0(sp)
ffffffffc0203dd6:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203dd8:	ee3fd0ef          	jal	ra,ffffffffc0201cba <kmalloc>
ffffffffc0203ddc:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203dde:	cd21                	beqz	a0,ffffffffc0203e36 <alloc_proc+0x68>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->state = PROC_UNINIT;                      // 设置进程为未初始化状态
ffffffffc0203de0:	57fd                	li	a5,-1
ffffffffc0203de2:	1782                	slli	a5,a5,0x20
ffffffffc0203de4:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                                 // 初始化运行次数为0
        proc->kstack = 0;                               // 内核栈地址初始化为0
        proc->need_resched = 0;                         // 不需要调度
        proc->parent = NULL;                            // 没有父进程
        proc->mm = NULL;                                // 未分配内存管理结构
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文
ffffffffc0203de6:	07000613          	li	a2,112
ffffffffc0203dea:	4581                	li	a1,0
        proc->runs = 0;                                 // 初始化运行次数为0
ffffffffc0203dec:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d556f4>
        proc->kstack = 0;                               // 内核栈地址初始化为0
ffffffffc0203df0:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                         // 不需要调度
ffffffffc0203df4:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;                            // 没有父进程
ffffffffc0203df8:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                                // 未分配内存管理结构
ffffffffc0203dfc:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文
ffffffffc0203e00:	03050513          	addi	a0,a0,48
ffffffffc0203e04:	0cb010ef          	jal	ra,ffffffffc02056ce <memset>
        proc->tf = NULL;                                // 中断帧指针初始化为NULL
        proc->pgdir = boot_pgdir_pa;                    // 使用内核页目录表
ffffffffc0203e08:	000a7797          	auipc	a5,0xa7
ffffffffc0203e0c:	ac07b783          	ld	a5,-1344(a5) # ffffffffc02aa8c8 <boot_pgdir_pa>
        proc->tf = NULL;                                // 中断帧指针初始化为NULL
ffffffffc0203e10:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;                    // 使用内核页目录表
ffffffffc0203e14:	f45c                	sd	a5,168(s0)
        proc->flags = 0;                                // 初始化标志位为0
ffffffffc0203e16:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);       // 初始化进程名
ffffffffc0203e1a:	4641                	li	a2,16
ffffffffc0203e1c:	4581                	li	a1,0
ffffffffc0203e1e:	0b440513          	addi	a0,s0,180
ffffffffc0203e22:	0ad010ef          	jal	ra,ffffffffc02056ce <memset>
        // LAB5 新增字段初始化
        proc->wait_state = 0;                           // 初始化等待状态
ffffffffc0203e26:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;                              // 子进程指针
ffffffffc0203e2a:	0e043823          	sd	zero,240(s0)
        proc->yptr = NULL;                              // 年幼兄弟进程指针
ffffffffc0203e2e:	0e043c23          	sd	zero,248(s0)
        proc->optr = NULL;                              // 年长兄弟进程指针
ffffffffc0203e32:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc0203e36:	60a2                	ld	ra,8(sp)
ffffffffc0203e38:	8522                	mv	a0,s0
ffffffffc0203e3a:	6402                	ld	s0,0(sp)
ffffffffc0203e3c:	0141                	addi	sp,sp,16
ffffffffc0203e3e:	8082                	ret

ffffffffc0203e40 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203e40:	000a7797          	auipc	a5,0xa7
ffffffffc0203e44:	ab87b783          	ld	a5,-1352(a5) # ffffffffc02aa8f8 <current>
ffffffffc0203e48:	73c8                	ld	a0,160(a5)
ffffffffc0203e4a:	8e4fd06f          	j	ffffffffc0200f2e <forkrets>

ffffffffc0203e4e <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e4e:	000a7797          	auipc	a5,0xa7
ffffffffc0203e52:	aaa7b783          	ld	a5,-1366(a5) # ffffffffc02aa8f8 <current>
ffffffffc0203e56:	43cc                	lw	a1,4(a5)
{
ffffffffc0203e58:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e5a:	00003617          	auipc	a2,0x3
ffffffffc0203e5e:	0e660613          	addi	a2,a2,230 # ffffffffc0206f40 <default_pmm_manager+0xa08>
ffffffffc0203e62:	00003517          	auipc	a0,0x3
ffffffffc0203e66:	0ee50513          	addi	a0,a0,238 # ffffffffc0206f50 <default_pmm_manager+0xa18>
{
ffffffffc0203e6a:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e6c:	b28fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0203e70:	3fe07797          	auipc	a5,0x3fe07
ffffffffc0203e74:	b1078793          	addi	a5,a5,-1264 # a980 <_binary_obj___user_forktest_out_size>
ffffffffc0203e78:	e43e                	sd	a5,8(sp)
ffffffffc0203e7a:	00003517          	auipc	a0,0x3
ffffffffc0203e7e:	0c650513          	addi	a0,a0,198 # ffffffffc0206f40 <default_pmm_manager+0xa08>
ffffffffc0203e82:	00046797          	auipc	a5,0x46
ffffffffc0203e86:	92e78793          	addi	a5,a5,-1746 # ffffffffc02497b0 <_binary_obj___user_forktest_out_start>
ffffffffc0203e8a:	f03e                	sd	a5,32(sp)
ffffffffc0203e8c:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203e8e:	e802                	sd	zero,16(sp)
ffffffffc0203e90:	79c010ef          	jal	ra,ffffffffc020562c <strlen>
ffffffffc0203e94:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203e96:	4511                	li	a0,4
ffffffffc0203e98:	55a2                	lw	a1,40(sp)
ffffffffc0203e9a:	4662                	lw	a2,24(sp)
ffffffffc0203e9c:	5682                	lw	a3,32(sp)
ffffffffc0203e9e:	4722                	lw	a4,8(sp)
ffffffffc0203ea0:	48a9                	li	a7,10
ffffffffc0203ea2:	9002                	ebreak
ffffffffc0203ea4:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203ea6:	65c2                	ld	a1,16(sp)
ffffffffc0203ea8:	00003517          	auipc	a0,0x3
ffffffffc0203eac:	0d050513          	addi	a0,a0,208 # ffffffffc0206f78 <default_pmm_manager+0xa40>
ffffffffc0203eb0:	ae4fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0203eb4:	00003617          	auipc	a2,0x3
ffffffffc0203eb8:	0d460613          	addi	a2,a2,212 # ffffffffc0206f88 <default_pmm_manager+0xa50>
ffffffffc0203ebc:	3cc00593          	li	a1,972
ffffffffc0203ec0:	00003517          	auipc	a0,0x3
ffffffffc0203ec4:	0e850513          	addi	a0,a0,232 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0203ec8:	dc6fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ecc <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203ecc:	6d14                	ld	a3,24(a0)
{
ffffffffc0203ece:	1141                	addi	sp,sp,-16
ffffffffc0203ed0:	e406                	sd	ra,8(sp)
ffffffffc0203ed2:	c02007b7          	lui	a5,0xc0200
ffffffffc0203ed6:	02f6ee63          	bltu	a3,a5,ffffffffc0203f12 <put_pgdir+0x46>
ffffffffc0203eda:	000a7517          	auipc	a0,0xa7
ffffffffc0203ede:	a1653503          	ld	a0,-1514(a0) # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0203ee2:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203ee4:	82b1                	srli	a3,a3,0xc
ffffffffc0203ee6:	000a7797          	auipc	a5,0xa7
ffffffffc0203eea:	9f27b783          	ld	a5,-1550(a5) # ffffffffc02aa8d8 <npage>
ffffffffc0203eee:	02f6fe63          	bgeu	a3,a5,ffffffffc0203f2a <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203ef2:	00004517          	auipc	a0,0x4
ffffffffc0203ef6:	96e53503          	ld	a0,-1682(a0) # ffffffffc0207860 <nbase>
}
ffffffffc0203efa:	60a2                	ld	ra,8(sp)
ffffffffc0203efc:	8e89                	sub	a3,a3,a0
ffffffffc0203efe:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203f00:	000a7517          	auipc	a0,0xa7
ffffffffc0203f04:	9e053503          	ld	a0,-1568(a0) # ffffffffc02aa8e0 <pages>
ffffffffc0203f08:	4585                	li	a1,1
ffffffffc0203f0a:	9536                	add	a0,a0,a3
}
ffffffffc0203f0c:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203f0e:	fc9fd06f          	j	ffffffffc0201ed6 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203f12:	00002617          	auipc	a2,0x2
ffffffffc0203f16:	70660613          	addi	a2,a2,1798 # ffffffffc0206618 <default_pmm_manager+0xe0>
ffffffffc0203f1a:	07700593          	li	a1,119
ffffffffc0203f1e:	00002517          	auipc	a0,0x2
ffffffffc0203f22:	67a50513          	addi	a0,a0,1658 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc0203f26:	d68fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203f2a:	00002617          	auipc	a2,0x2
ffffffffc0203f2e:	71660613          	addi	a2,a2,1814 # ffffffffc0206640 <default_pmm_manager+0x108>
ffffffffc0203f32:	06900593          	li	a1,105
ffffffffc0203f36:	00002517          	auipc	a0,0x2
ffffffffc0203f3a:	66250513          	addi	a0,a0,1634 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc0203f3e:	d50fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203f42 <proc_run>:
{
ffffffffc0203f42:	7179                	addi	sp,sp,-48
ffffffffc0203f44:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203f46:	000a7917          	auipc	s2,0xa7
ffffffffc0203f4a:	9b290913          	addi	s2,s2,-1614 # ffffffffc02aa8f8 <current>
{
ffffffffc0203f4e:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203f50:	00093483          	ld	s1,0(s2)
{
ffffffffc0203f54:	f406                	sd	ra,40(sp)
ffffffffc0203f56:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0203f58:	02a48863          	beq	s1,a0,ffffffffc0203f88 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f5c:	100027f3          	csrr	a5,sstatus
ffffffffc0203f60:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203f62:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f64:	ef9d                	bnez	a5,ffffffffc0203fa2 <proc_run+0x60>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203f66:	755c                	ld	a5,168(a0)
ffffffffc0203f68:	577d                	li	a4,-1
ffffffffc0203f6a:	177e                	slli	a4,a4,0x3f
ffffffffc0203f6c:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0203f6e:	00a93023          	sd	a0,0(s2)
ffffffffc0203f72:	8fd9                	or	a5,a5,a4
ffffffffc0203f74:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0203f78:	03050593          	addi	a1,a0,48
ffffffffc0203f7c:	03048513          	addi	a0,s1,48
ffffffffc0203f80:	052010ef          	jal	ra,ffffffffc0204fd2 <switch_to>
    if (flag)
ffffffffc0203f84:	00099863          	bnez	s3,ffffffffc0203f94 <proc_run+0x52>
}
ffffffffc0203f88:	70a2                	ld	ra,40(sp)
ffffffffc0203f8a:	7482                	ld	s1,32(sp)
ffffffffc0203f8c:	6962                	ld	s2,24(sp)
ffffffffc0203f8e:	69c2                	ld	s3,16(sp)
ffffffffc0203f90:	6145                	addi	sp,sp,48
ffffffffc0203f92:	8082                	ret
ffffffffc0203f94:	70a2                	ld	ra,40(sp)
ffffffffc0203f96:	7482                	ld	s1,32(sp)
ffffffffc0203f98:	6962                	ld	s2,24(sp)
ffffffffc0203f9a:	69c2                	ld	s3,16(sp)
ffffffffc0203f9c:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203f9e:	a11fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc0203fa2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203fa4:	a11fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0203fa8:	6522                	ld	a0,8(sp)
ffffffffc0203faa:	4985                	li	s3,1
ffffffffc0203fac:	bf6d                	j	ffffffffc0203f66 <proc_run+0x24>

ffffffffc0203fae <do_fork>:
{
ffffffffc0203fae:	7119                	addi	sp,sp,-128
ffffffffc0203fb0:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203fb2:	000a7917          	auipc	s2,0xa7
ffffffffc0203fb6:	95e90913          	addi	s2,s2,-1698 # ffffffffc02aa910 <nr_process>
ffffffffc0203fba:	00092703          	lw	a4,0(s2)
{
ffffffffc0203fbe:	fc86                	sd	ra,120(sp)
ffffffffc0203fc0:	f8a2                	sd	s0,112(sp)
ffffffffc0203fc2:	f4a6                	sd	s1,104(sp)
ffffffffc0203fc4:	ecce                	sd	s3,88(sp)
ffffffffc0203fc6:	e8d2                	sd	s4,80(sp)
ffffffffc0203fc8:	e4d6                	sd	s5,72(sp)
ffffffffc0203fca:	e0da                	sd	s6,64(sp)
ffffffffc0203fcc:	fc5e                	sd	s7,56(sp)
ffffffffc0203fce:	f862                	sd	s8,48(sp)
ffffffffc0203fd0:	f466                	sd	s9,40(sp)
ffffffffc0203fd2:	f06a                	sd	s10,32(sp)
ffffffffc0203fd4:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203fd6:	6785                	lui	a5,0x1
ffffffffc0203fd8:	32f75b63          	bge	a4,a5,ffffffffc020430e <do_fork+0x360>
ffffffffc0203fdc:	8a2a                	mv	s4,a0
ffffffffc0203fde:	89ae                	mv	s3,a1
ffffffffc0203fe0:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0203fe2:	dedff0ef          	jal	ra,ffffffffc0203dce <alloc_proc>
ffffffffc0203fe6:	84aa                	mv	s1,a0
ffffffffc0203fe8:	30050463          	beqz	a0,ffffffffc02042f0 <do_fork+0x342>
    proc->parent = current;
ffffffffc0203fec:	000a7c17          	auipc	s8,0xa7
ffffffffc0203ff0:	90cc0c13          	addi	s8,s8,-1780 # ffffffffc02aa8f8 <current>
ffffffffc0203ff4:	000c3783          	ld	a5,0(s8)
    assert(current->wait_state == 0);
ffffffffc0203ff8:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8adc>
    proc->parent = current;
ffffffffc0203ffc:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0203ffe:	30071d63          	bnez	a4,ffffffffc0204318 <do_fork+0x36a>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204002:	4509                	li	a0,2
ffffffffc0204004:	e95fd0ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
    if (page != NULL)
ffffffffc0204008:	2e050163          	beqz	a0,ffffffffc02042ea <do_fork+0x33c>
    return page - pages + nbase;
ffffffffc020400c:	000a7a97          	auipc	s5,0xa7
ffffffffc0204010:	8d4a8a93          	addi	s5,s5,-1836 # ffffffffc02aa8e0 <pages>
ffffffffc0204014:	000ab683          	ld	a3,0(s5)
ffffffffc0204018:	00004b17          	auipc	s6,0x4
ffffffffc020401c:	848b0b13          	addi	s6,s6,-1976 # ffffffffc0207860 <nbase>
ffffffffc0204020:	000b3783          	ld	a5,0(s6)
ffffffffc0204024:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204028:	000a7b97          	auipc	s7,0xa7
ffffffffc020402c:	8b0b8b93          	addi	s7,s7,-1872 # ffffffffc02aa8d8 <npage>
    return page - pages + nbase;
ffffffffc0204030:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204032:	5dfd                	li	s11,-1
ffffffffc0204034:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204038:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020403a:	00cddd93          	srli	s11,s11,0xc
ffffffffc020403e:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204042:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204044:	2ee67a63          	bgeu	a2,a4,ffffffffc0204338 <do_fork+0x38a>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204048:	000c3603          	ld	a2,0(s8)
ffffffffc020404c:	000a7c17          	auipc	s8,0xa7
ffffffffc0204050:	8a4c0c13          	addi	s8,s8,-1884 # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0204054:	000c3703          	ld	a4,0(s8)
ffffffffc0204058:	02863d03          	ld	s10,40(a2)
ffffffffc020405c:	e43e                	sd	a5,8(sp)
ffffffffc020405e:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204060:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0204062:	020d0863          	beqz	s10,ffffffffc0204092 <do_fork+0xe4>
    if (clone_flags & CLONE_VM)
ffffffffc0204066:	100a7a13          	andi	s4,s4,256
ffffffffc020406a:	1c0a0163          	beqz	s4,ffffffffc020422c <do_fork+0x27e>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc020406e:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204072:	018d3783          	ld	a5,24(s10)
ffffffffc0204076:	c02006b7          	lui	a3,0xc0200
ffffffffc020407a:	2705                	addiw	a4,a4,1
ffffffffc020407c:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0204080:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204084:	2ed7e263          	bltu	a5,a3,ffffffffc0204368 <do_fork+0x3ba>
ffffffffc0204088:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020408c:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020408e:	8f99                	sub	a5,a5,a4
ffffffffc0204090:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204092:	6789                	lui	a5,0x2
ffffffffc0204094:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7ce8>
ffffffffc0204098:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc020409a:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020409c:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc020409e:	87b6                	mv	a5,a3
ffffffffc02040a0:	12040893          	addi	a7,s0,288
ffffffffc02040a4:	00063803          	ld	a6,0(a2)
ffffffffc02040a8:	6608                	ld	a0,8(a2)
ffffffffc02040aa:	6a0c                	ld	a1,16(a2)
ffffffffc02040ac:	6e18                	ld	a4,24(a2)
ffffffffc02040ae:	0107b023          	sd	a6,0(a5)
ffffffffc02040b2:	e788                	sd	a0,8(a5)
ffffffffc02040b4:	eb8c                	sd	a1,16(a5)
ffffffffc02040b6:	ef98                	sd	a4,24(a5)
ffffffffc02040b8:	02060613          	addi	a2,a2,32
ffffffffc02040bc:	02078793          	addi	a5,a5,32
ffffffffc02040c0:	ff1612e3          	bne	a2,a7,ffffffffc02040a4 <do_fork+0xf6>
    proc->tf->gpr.a0 = 0;
ffffffffc02040c4:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02040c8:	12098f63          	beqz	s3,ffffffffc0204206 <do_fork+0x258>
ffffffffc02040cc:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02040d0:	00000797          	auipc	a5,0x0
ffffffffc02040d4:	d7078793          	addi	a5,a5,-656 # ffffffffc0203e40 <forkret>
ffffffffc02040d8:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02040da:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040dc:	100027f3          	csrr	a5,sstatus
ffffffffc02040e0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02040e2:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02040e4:	14079063          	bnez	a5,ffffffffc0204224 <do_fork+0x276>
    if (++last_pid >= MAX_PID)
ffffffffc02040e8:	000a2817          	auipc	a6,0xa2
ffffffffc02040ec:	38080813          	addi	a6,a6,896 # ffffffffc02a6468 <last_pid.1>
ffffffffc02040f0:	00082783          	lw	a5,0(a6)
ffffffffc02040f4:	6709                	lui	a4,0x2
ffffffffc02040f6:	0017851b          	addiw	a0,a5,1
ffffffffc02040fa:	00a82023          	sw	a0,0(a6)
ffffffffc02040fe:	08e55d63          	bge	a0,a4,ffffffffc0204198 <do_fork+0x1ea>
    if (last_pid >= next_safe)
ffffffffc0204102:	000a2317          	auipc	t1,0xa2
ffffffffc0204106:	36a30313          	addi	t1,t1,874 # ffffffffc02a646c <next_safe.0>
ffffffffc020410a:	00032783          	lw	a5,0(t1)
ffffffffc020410e:	000a6417          	auipc	s0,0xa6
ffffffffc0204112:	77a40413          	addi	s0,s0,1914 # ffffffffc02aa888 <proc_list>
ffffffffc0204116:	08f55963          	bge	a0,a5,ffffffffc02041a8 <do_fork+0x1fa>
        proc->pid = get_pid();
ffffffffc020411a:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020411c:	45a9                	li	a1,10
ffffffffc020411e:	2501                	sext.w	a0,a0
ffffffffc0204120:	108010ef          	jal	ra,ffffffffc0205228 <hash32>
ffffffffc0204124:	02051793          	slli	a5,a0,0x20
ffffffffc0204128:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020412c:	000a2797          	auipc	a5,0xa2
ffffffffc0204130:	75c78793          	addi	a5,a5,1884 # ffffffffc02a6888 <hash_list>
ffffffffc0204134:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204136:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204138:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020413a:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc020413e:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204140:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0204142:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204144:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204146:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc020414a:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc020414c:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc020414e:	e21c                	sd	a5,0(a2)
ffffffffc0204150:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0204152:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0204154:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204156:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020415a:	10e4b023          	sd	a4,256(s1)
ffffffffc020415e:	c311                	beqz	a4,ffffffffc0204162 <do_fork+0x1b4>
        proc->optr->yptr = proc;
ffffffffc0204160:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc0204162:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204166:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0204168:	2785                	addiw	a5,a5,1
ffffffffc020416a:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc020416e:	18099363          	bnez	s3,ffffffffc02042f4 <do_fork+0x346>
    wakeup_proc(proc);
ffffffffc0204172:	8526                	mv	a0,s1
ffffffffc0204174:	6c9000ef          	jal	ra,ffffffffc020503c <wakeup_proc>
    ret = proc->pid;
ffffffffc0204178:	40c8                	lw	a0,4(s1)
}
ffffffffc020417a:	70e6                	ld	ra,120(sp)
ffffffffc020417c:	7446                	ld	s0,112(sp)
ffffffffc020417e:	74a6                	ld	s1,104(sp)
ffffffffc0204180:	7906                	ld	s2,96(sp)
ffffffffc0204182:	69e6                	ld	s3,88(sp)
ffffffffc0204184:	6a46                	ld	s4,80(sp)
ffffffffc0204186:	6aa6                	ld	s5,72(sp)
ffffffffc0204188:	6b06                	ld	s6,64(sp)
ffffffffc020418a:	7be2                	ld	s7,56(sp)
ffffffffc020418c:	7c42                	ld	s8,48(sp)
ffffffffc020418e:	7ca2                	ld	s9,40(sp)
ffffffffc0204190:	7d02                	ld	s10,32(sp)
ffffffffc0204192:	6de2                	ld	s11,24(sp)
ffffffffc0204194:	6109                	addi	sp,sp,128
ffffffffc0204196:	8082                	ret
        last_pid = 1;
ffffffffc0204198:	4785                	li	a5,1
ffffffffc020419a:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020419e:	4505                	li	a0,1
ffffffffc02041a0:	000a2317          	auipc	t1,0xa2
ffffffffc02041a4:	2cc30313          	addi	t1,t1,716 # ffffffffc02a646c <next_safe.0>
    return listelm->next;
ffffffffc02041a8:	000a6417          	auipc	s0,0xa6
ffffffffc02041ac:	6e040413          	addi	s0,s0,1760 # ffffffffc02aa888 <proc_list>
ffffffffc02041b0:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc02041b4:	6789                	lui	a5,0x2
ffffffffc02041b6:	00f32023          	sw	a5,0(t1)
ffffffffc02041ba:	86aa                	mv	a3,a0
ffffffffc02041bc:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02041be:	6e89                	lui	t4,0x2
ffffffffc02041c0:	148e0263          	beq	t3,s0,ffffffffc0204304 <do_fork+0x356>
ffffffffc02041c4:	88ae                	mv	a7,a1
ffffffffc02041c6:	87f2                	mv	a5,t3
ffffffffc02041c8:	6609                	lui	a2,0x2
ffffffffc02041ca:	a811                	j	ffffffffc02041de <do_fork+0x230>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041cc:	00e6d663          	bge	a3,a4,ffffffffc02041d8 <do_fork+0x22a>
ffffffffc02041d0:	00c75463          	bge	a4,a2,ffffffffc02041d8 <do_fork+0x22a>
ffffffffc02041d4:	863a                	mv	a2,a4
ffffffffc02041d6:	4885                	li	a7,1
ffffffffc02041d8:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02041da:	00878d63          	beq	a5,s0,ffffffffc02041f4 <do_fork+0x246>
            if (proc->pid == last_pid)
ffffffffc02041de:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c8c>
ffffffffc02041e2:	fed715e3          	bne	a4,a3,ffffffffc02041cc <do_fork+0x21e>
                if (++last_pid >= next_safe)
ffffffffc02041e6:	2685                	addiw	a3,a3,1
ffffffffc02041e8:	10c6d963          	bge	a3,a2,ffffffffc02042fa <do_fork+0x34c>
ffffffffc02041ec:	679c                	ld	a5,8(a5)
ffffffffc02041ee:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02041f0:	fe8797e3          	bne	a5,s0,ffffffffc02041de <do_fork+0x230>
ffffffffc02041f4:	c581                	beqz	a1,ffffffffc02041fc <do_fork+0x24e>
ffffffffc02041f6:	00d82023          	sw	a3,0(a6)
ffffffffc02041fa:	8536                	mv	a0,a3
ffffffffc02041fc:	f0088fe3          	beqz	a7,ffffffffc020411a <do_fork+0x16c>
ffffffffc0204200:	00c32023          	sw	a2,0(t1)
ffffffffc0204204:	bf19                	j	ffffffffc020411a <do_fork+0x16c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204206:	89b6                	mv	s3,a3
ffffffffc0204208:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020420c:	00000797          	auipc	a5,0x0
ffffffffc0204210:	c3478793          	addi	a5,a5,-972 # ffffffffc0203e40 <forkret>
ffffffffc0204214:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204216:	fc94                	sd	a3,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204218:	100027f3          	csrr	a5,sstatus
ffffffffc020421c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020421e:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204220:	ec0784e3          	beqz	a5,ffffffffc02040e8 <do_fork+0x13a>
        intr_disable();
ffffffffc0204224:	f90fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204228:	4985                	li	s3,1
ffffffffc020422a:	bd7d                	j	ffffffffc02040e8 <do_fork+0x13a>
    if ((mm = mm_create()) == NULL)
ffffffffc020422c:	c90ff0ef          	jal	ra,ffffffffc02036bc <mm_create>
ffffffffc0204230:	8caa                	mv	s9,a0
ffffffffc0204232:	c541                	beqz	a0,ffffffffc02042ba <do_fork+0x30c>
    if ((page = alloc_page()) == NULL)
ffffffffc0204234:	4505                	li	a0,1
ffffffffc0204236:	c63fd0ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc020423a:	cd2d                	beqz	a0,ffffffffc02042b4 <do_fork+0x306>
    return page - pages + nbase;
ffffffffc020423c:	000ab683          	ld	a3,0(s5)
ffffffffc0204240:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc0204242:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204246:	40d506b3          	sub	a3,a0,a3
ffffffffc020424a:	8699                	srai	a3,a3,0x6
ffffffffc020424c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020424e:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204252:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204254:	0eedf263          	bgeu	s11,a4,ffffffffc0204338 <do_fork+0x38a>
ffffffffc0204258:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020425c:	6605                	lui	a2,0x1
ffffffffc020425e:	000a6597          	auipc	a1,0xa6
ffffffffc0204262:	6725b583          	ld	a1,1650(a1) # ffffffffc02aa8d0 <boot_pgdir_va>
ffffffffc0204266:	9a36                	add	s4,s4,a3
ffffffffc0204268:	8552                	mv	a0,s4
ffffffffc020426a:	476010ef          	jal	ra,ffffffffc02056e0 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc020426e:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc0204272:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204276:	4785                	li	a5,1
ffffffffc0204278:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc020427c:	8b85                	andi	a5,a5,1
ffffffffc020427e:	4a05                	li	s4,1
ffffffffc0204280:	c799                	beqz	a5,ffffffffc020428e <do_fork+0x2e0>
    {
        schedule();
ffffffffc0204282:	63b000ef          	jal	ra,ffffffffc02050bc <schedule>
ffffffffc0204286:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc020428a:	8b85                	andi	a5,a5,1
ffffffffc020428c:	fbfd                	bnez	a5,ffffffffc0204282 <do_fork+0x2d4>
        ret = dup_mmap(mm, oldmm);
ffffffffc020428e:	85ea                	mv	a1,s10
ffffffffc0204290:	8566                	mv	a0,s9
ffffffffc0204292:	e6cff0ef          	jal	ra,ffffffffc02038fe <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204296:	57f9                	li	a5,-2
ffffffffc0204298:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc020429c:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020429e:	0e078e63          	beqz	a5,ffffffffc020439a <do_fork+0x3ec>
good_mm:
ffffffffc02042a2:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc02042a4:	dc0505e3          	beqz	a0,ffffffffc020406e <do_fork+0xc0>
    exit_mmap(mm);
ffffffffc02042a8:	8566                	mv	a0,s9
ffffffffc02042aa:	eeeff0ef          	jal	ra,ffffffffc0203998 <exit_mmap>
    put_pgdir(mm);
ffffffffc02042ae:	8566                	mv	a0,s9
ffffffffc02042b0:	c1dff0ef          	jal	ra,ffffffffc0203ecc <put_pgdir>
    mm_destroy(mm);
ffffffffc02042b4:	8566                	mv	a0,s9
ffffffffc02042b6:	d46ff0ef          	jal	ra,ffffffffc02037fc <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02042ba:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc02042bc:	c02007b7          	lui	a5,0xc0200
ffffffffc02042c0:	0cf6e163          	bltu	a3,a5,ffffffffc0204382 <do_fork+0x3d4>
ffffffffc02042c4:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc02042c8:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02042cc:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02042d0:	83b1                	srli	a5,a5,0xc
ffffffffc02042d2:	06e7ff63          	bgeu	a5,a4,ffffffffc0204350 <do_fork+0x3a2>
    return &pages[PPN(pa) - nbase];
ffffffffc02042d6:	000b3703          	ld	a4,0(s6)
ffffffffc02042da:	000ab503          	ld	a0,0(s5)
ffffffffc02042de:	4589                	li	a1,2
ffffffffc02042e0:	8f99                	sub	a5,a5,a4
ffffffffc02042e2:	079a                	slli	a5,a5,0x6
ffffffffc02042e4:	953e                	add	a0,a0,a5
ffffffffc02042e6:	bf1fd0ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    kfree(proc);
ffffffffc02042ea:	8526                	mv	a0,s1
ffffffffc02042ec:	a7ffd0ef          	jal	ra,ffffffffc0201d6a <kfree>
    ret = -E_NO_MEM;
ffffffffc02042f0:	5571                	li	a0,-4
    return ret;
ffffffffc02042f2:	b561                	j	ffffffffc020417a <do_fork+0x1cc>
        intr_enable();
ffffffffc02042f4:	ebafc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02042f8:	bdad                	j	ffffffffc0204172 <do_fork+0x1c4>
                    if (last_pid >= MAX_PID)
ffffffffc02042fa:	01d6c363          	blt	a3,t4,ffffffffc0204300 <do_fork+0x352>
                        last_pid = 1;
ffffffffc02042fe:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204300:	4585                	li	a1,1
ffffffffc0204302:	bd7d                	j	ffffffffc02041c0 <do_fork+0x212>
ffffffffc0204304:	c599                	beqz	a1,ffffffffc0204312 <do_fork+0x364>
ffffffffc0204306:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc020430a:	8536                	mv	a0,a3
ffffffffc020430c:	b539                	j	ffffffffc020411a <do_fork+0x16c>
    int ret = -E_NO_FREE_PROC;
ffffffffc020430e:	556d                	li	a0,-5
ffffffffc0204310:	b5ad                	j	ffffffffc020417a <do_fork+0x1cc>
    return last_pid;
ffffffffc0204312:	00082503          	lw	a0,0(a6)
ffffffffc0204316:	b511                	j	ffffffffc020411a <do_fork+0x16c>
    assert(current->wait_state == 0);
ffffffffc0204318:	00003697          	auipc	a3,0x3
ffffffffc020431c:	ca868693          	addi	a3,a3,-856 # ffffffffc0206fc0 <default_pmm_manager+0xa88>
ffffffffc0204320:	00002617          	auipc	a2,0x2
ffffffffc0204324:	c3860613          	addi	a2,a2,-968 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0204328:	1e700593          	li	a1,487
ffffffffc020432c:	00003517          	auipc	a0,0x3
ffffffffc0204330:	c7c50513          	addi	a0,a0,-900 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204334:	95afc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204338:	00002617          	auipc	a2,0x2
ffffffffc020433c:	23860613          	addi	a2,a2,568 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc0204340:	07100593          	li	a1,113
ffffffffc0204344:	00002517          	auipc	a0,0x2
ffffffffc0204348:	25450513          	addi	a0,a0,596 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc020434c:	942fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204350:	00002617          	auipc	a2,0x2
ffffffffc0204354:	2f060613          	addi	a2,a2,752 # ffffffffc0206640 <default_pmm_manager+0x108>
ffffffffc0204358:	06900593          	li	a1,105
ffffffffc020435c:	00002517          	auipc	a0,0x2
ffffffffc0204360:	23c50513          	addi	a0,a0,572 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc0204364:	92afc0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204368:	86be                	mv	a3,a5
ffffffffc020436a:	00002617          	auipc	a2,0x2
ffffffffc020436e:	2ae60613          	addi	a2,a2,686 # ffffffffc0206618 <default_pmm_manager+0xe0>
ffffffffc0204372:	19400593          	li	a1,404
ffffffffc0204376:	00003517          	auipc	a0,0x3
ffffffffc020437a:	c3250513          	addi	a0,a0,-974 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc020437e:	910fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204382:	00002617          	auipc	a2,0x2
ffffffffc0204386:	29660613          	addi	a2,a2,662 # ffffffffc0206618 <default_pmm_manager+0xe0>
ffffffffc020438a:	07700593          	li	a1,119
ffffffffc020438e:	00002517          	auipc	a0,0x2
ffffffffc0204392:	20a50513          	addi	a0,a0,522 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc0204396:	8f8fc0ef          	jal	ra,ffffffffc020048e <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc020439a:	00003617          	auipc	a2,0x3
ffffffffc020439e:	c4660613          	addi	a2,a2,-954 # ffffffffc0206fe0 <default_pmm_manager+0xaa8>
ffffffffc02043a2:	03f00593          	li	a1,63
ffffffffc02043a6:	00003517          	auipc	a0,0x3
ffffffffc02043aa:	c4a50513          	addi	a0,a0,-950 # ffffffffc0206ff0 <default_pmm_manager+0xab8>
ffffffffc02043ae:	8e0fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02043b2 <kernel_thread>:
{
ffffffffc02043b2:	7129                	addi	sp,sp,-320
ffffffffc02043b4:	fa22                	sd	s0,304(sp)
ffffffffc02043b6:	f626                	sd	s1,296(sp)
ffffffffc02043b8:	f24a                	sd	s2,288(sp)
ffffffffc02043ba:	84ae                	mv	s1,a1
ffffffffc02043bc:	892a                	mv	s2,a0
ffffffffc02043be:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02043c0:	4581                	li	a1,0
ffffffffc02043c2:	12000613          	li	a2,288
ffffffffc02043c6:	850a                	mv	a0,sp
{
ffffffffc02043c8:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02043ca:	304010ef          	jal	ra,ffffffffc02056ce <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02043ce:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02043d0:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02043d2:	100027f3          	csrr	a5,sstatus
ffffffffc02043d6:	edd7f793          	andi	a5,a5,-291
ffffffffc02043da:	1207e793          	ori	a5,a5,288
ffffffffc02043de:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043e0:	860a                	mv	a2,sp
ffffffffc02043e2:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02043e6:	00000797          	auipc	a5,0x0
ffffffffc02043ea:	9e078793          	addi	a5,a5,-1568 # ffffffffc0203dc6 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043ee:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02043f0:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02043f2:	bbdff0ef          	jal	ra,ffffffffc0203fae <do_fork>
}
ffffffffc02043f6:	70f2                	ld	ra,312(sp)
ffffffffc02043f8:	7452                	ld	s0,304(sp)
ffffffffc02043fa:	74b2                	ld	s1,296(sp)
ffffffffc02043fc:	7912                	ld	s2,288(sp)
ffffffffc02043fe:	6131                	addi	sp,sp,320
ffffffffc0204400:	8082                	ret

ffffffffc0204402 <do_exit>:
{
ffffffffc0204402:	7179                	addi	sp,sp,-48
ffffffffc0204404:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204406:	000a6417          	auipc	s0,0xa6
ffffffffc020440a:	4f240413          	addi	s0,s0,1266 # ffffffffc02aa8f8 <current>
ffffffffc020440e:	601c                	ld	a5,0(s0)
{
ffffffffc0204410:	f406                	sd	ra,40(sp)
ffffffffc0204412:	ec26                	sd	s1,24(sp)
ffffffffc0204414:	e84a                	sd	s2,16(sp)
ffffffffc0204416:	e44e                	sd	s3,8(sp)
ffffffffc0204418:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc020441a:	000a6717          	auipc	a4,0xa6
ffffffffc020441e:	4e673703          	ld	a4,1254(a4) # ffffffffc02aa900 <idleproc>
ffffffffc0204422:	0ce78c63          	beq	a5,a4,ffffffffc02044fa <do_exit+0xf8>
    if (current == initproc)
ffffffffc0204426:	000a6497          	auipc	s1,0xa6
ffffffffc020442a:	4e248493          	addi	s1,s1,1250 # ffffffffc02aa908 <initproc>
ffffffffc020442e:	6098                	ld	a4,0(s1)
ffffffffc0204430:	0ee78b63          	beq	a5,a4,ffffffffc0204526 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc0204434:	0287b983          	ld	s3,40(a5)
ffffffffc0204438:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc020443a:	02098663          	beqz	s3,ffffffffc0204466 <do_exit+0x64>
ffffffffc020443e:	000a6797          	auipc	a5,0xa6
ffffffffc0204442:	48a7b783          	ld	a5,1162(a5) # ffffffffc02aa8c8 <boot_pgdir_pa>
ffffffffc0204446:	577d                	li	a4,-1
ffffffffc0204448:	177e                	slli	a4,a4,0x3f
ffffffffc020444a:	83b1                	srli	a5,a5,0xc
ffffffffc020444c:	8fd9                	or	a5,a5,a4
ffffffffc020444e:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204452:	0309a783          	lw	a5,48(s3)
ffffffffc0204456:	fff7871b          	addiw	a4,a5,-1
ffffffffc020445a:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc020445e:	cb55                	beqz	a4,ffffffffc0204512 <do_exit+0x110>
        current->mm = NULL;
ffffffffc0204460:	601c                	ld	a5,0(s0)
ffffffffc0204462:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204466:	601c                	ld	a5,0(s0)
ffffffffc0204468:	470d                	li	a4,3
ffffffffc020446a:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc020446c:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204470:	100027f3          	csrr	a5,sstatus
ffffffffc0204474:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204476:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204478:	e3f9                	bnez	a5,ffffffffc020453e <do_exit+0x13c>
        proc = current->parent;
ffffffffc020447a:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc020447c:	800007b7          	lui	a5,0x80000
ffffffffc0204480:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204482:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204484:	0ec52703          	lw	a4,236(a0)
ffffffffc0204488:	0af70f63          	beq	a4,a5,ffffffffc0204546 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc020448c:	6018                	ld	a4,0(s0)
ffffffffc020448e:	7b7c                	ld	a5,240(a4)
ffffffffc0204490:	c3a1                	beqz	a5,ffffffffc02044d0 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204492:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204496:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204498:	0985                	addi	s3,s3,1
ffffffffc020449a:	a021                	j	ffffffffc02044a2 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc020449c:	6018                	ld	a4,0(s0)
ffffffffc020449e:	7b7c                	ld	a5,240(a4)
ffffffffc02044a0:	cb85                	beqz	a5,ffffffffc02044d0 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc02044a2:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fc0>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02044a6:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02044a8:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02044aa:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc02044ac:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02044b0:	10e7b023          	sd	a4,256(a5)
ffffffffc02044b4:	c311                	beqz	a4,ffffffffc02044b8 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc02044b6:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044b8:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02044ba:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02044bc:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02044be:	fd271fe3          	bne	a4,s2,ffffffffc020449c <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02044c2:	0ec52783          	lw	a5,236(a0)
ffffffffc02044c6:	fd379be3          	bne	a5,s3,ffffffffc020449c <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc02044ca:	373000ef          	jal	ra,ffffffffc020503c <wakeup_proc>
ffffffffc02044ce:	b7f9                	j	ffffffffc020449c <do_exit+0x9a>
    if (flag)
ffffffffc02044d0:	020a1263          	bnez	s4,ffffffffc02044f4 <do_exit+0xf2>
    schedule();
ffffffffc02044d4:	3e9000ef          	jal	ra,ffffffffc02050bc <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02044d8:	601c                	ld	a5,0(s0)
ffffffffc02044da:	00003617          	auipc	a2,0x3
ffffffffc02044de:	b4e60613          	addi	a2,a2,-1202 # ffffffffc0207028 <default_pmm_manager+0xaf0>
ffffffffc02044e2:	24d00593          	li	a1,589
ffffffffc02044e6:	43d4                	lw	a3,4(a5)
ffffffffc02044e8:	00003517          	auipc	a0,0x3
ffffffffc02044ec:	ac050513          	addi	a0,a0,-1344 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc02044f0:	f9ffb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc02044f4:	cbafc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02044f8:	bff1                	j	ffffffffc02044d4 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02044fa:	00003617          	auipc	a2,0x3
ffffffffc02044fe:	b0e60613          	addi	a2,a2,-1266 # ffffffffc0207008 <default_pmm_manager+0xad0>
ffffffffc0204502:	21900593          	li	a1,537
ffffffffc0204506:	00003517          	auipc	a0,0x3
ffffffffc020450a:	aa250513          	addi	a0,a0,-1374 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc020450e:	f81fb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc0204512:	854e                	mv	a0,s3
ffffffffc0204514:	c84ff0ef          	jal	ra,ffffffffc0203998 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204518:	854e                	mv	a0,s3
ffffffffc020451a:	9b3ff0ef          	jal	ra,ffffffffc0203ecc <put_pgdir>
            mm_destroy(mm);
ffffffffc020451e:	854e                	mv	a0,s3
ffffffffc0204520:	adcff0ef          	jal	ra,ffffffffc02037fc <mm_destroy>
ffffffffc0204524:	bf35                	j	ffffffffc0204460 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204526:	00003617          	auipc	a2,0x3
ffffffffc020452a:	af260613          	addi	a2,a2,-1294 # ffffffffc0207018 <default_pmm_manager+0xae0>
ffffffffc020452e:	21d00593          	li	a1,541
ffffffffc0204532:	00003517          	auipc	a0,0x3
ffffffffc0204536:	a7650513          	addi	a0,a0,-1418 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc020453a:	f55fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc020453e:	c76fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204542:	4a05                	li	s4,1
ffffffffc0204544:	bf1d                	j	ffffffffc020447a <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204546:	2f7000ef          	jal	ra,ffffffffc020503c <wakeup_proc>
ffffffffc020454a:	b789                	j	ffffffffc020448c <do_exit+0x8a>

ffffffffc020454c <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc020454c:	715d                	addi	sp,sp,-80
ffffffffc020454e:	f84a                	sd	s2,48(sp)
ffffffffc0204550:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0204552:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204556:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204558:	fc26                	sd	s1,56(sp)
ffffffffc020455a:	f052                	sd	s4,32(sp)
ffffffffc020455c:	ec56                	sd	s5,24(sp)
ffffffffc020455e:	e85a                	sd	s6,16(sp)
ffffffffc0204560:	e45e                	sd	s7,8(sp)
ffffffffc0204562:	e486                	sd	ra,72(sp)
ffffffffc0204564:	e0a2                	sd	s0,64(sp)
ffffffffc0204566:	84aa                	mv	s1,a0
ffffffffc0204568:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc020456a:	000a6b97          	auipc	s7,0xa6
ffffffffc020456e:	38eb8b93          	addi	s7,s7,910 # ffffffffc02aa8f8 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204572:	00050b1b          	sext.w	s6,a0
ffffffffc0204576:	fff50a9b          	addiw	s5,a0,-1
ffffffffc020457a:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc020457c:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc020457e:	ccbd                	beqz	s1,ffffffffc02045fc <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204580:	0359e863          	bltu	s3,s5,ffffffffc02045b0 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204584:	45a9                	li	a1,10
ffffffffc0204586:	855a                	mv	a0,s6
ffffffffc0204588:	4a1000ef          	jal	ra,ffffffffc0205228 <hash32>
ffffffffc020458c:	02051793          	slli	a5,a0,0x20
ffffffffc0204590:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204594:	000a2797          	auipc	a5,0xa2
ffffffffc0204598:	2f478793          	addi	a5,a5,756 # ffffffffc02a6888 <hash_list>
ffffffffc020459c:	953e                	add	a0,a0,a5
ffffffffc020459e:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc02045a0:	a029                	j	ffffffffc02045aa <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc02045a2:	f2c42783          	lw	a5,-212(s0)
ffffffffc02045a6:	02978163          	beq	a5,s1,ffffffffc02045c8 <do_wait.part.0+0x7c>
ffffffffc02045aa:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc02045ac:	fe851be3          	bne	a0,s0,ffffffffc02045a2 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc02045b0:	5579                	li	a0,-2
}
ffffffffc02045b2:	60a6                	ld	ra,72(sp)
ffffffffc02045b4:	6406                	ld	s0,64(sp)
ffffffffc02045b6:	74e2                	ld	s1,56(sp)
ffffffffc02045b8:	7942                	ld	s2,48(sp)
ffffffffc02045ba:	79a2                	ld	s3,40(sp)
ffffffffc02045bc:	7a02                	ld	s4,32(sp)
ffffffffc02045be:	6ae2                	ld	s5,24(sp)
ffffffffc02045c0:	6b42                	ld	s6,16(sp)
ffffffffc02045c2:	6ba2                	ld	s7,8(sp)
ffffffffc02045c4:	6161                	addi	sp,sp,80
ffffffffc02045c6:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02045c8:	000bb683          	ld	a3,0(s7)
ffffffffc02045cc:	f4843783          	ld	a5,-184(s0)
ffffffffc02045d0:	fed790e3          	bne	a5,a3,ffffffffc02045b0 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045d4:	f2842703          	lw	a4,-216(s0)
ffffffffc02045d8:	478d                	li	a5,3
ffffffffc02045da:	0ef70b63          	beq	a4,a5,ffffffffc02046d0 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc02045de:	4785                	li	a5,1
ffffffffc02045e0:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc02045e2:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc02045e6:	2d7000ef          	jal	ra,ffffffffc02050bc <schedule>
        if (current->flags & PF_EXITING)
ffffffffc02045ea:	000bb783          	ld	a5,0(s7)
ffffffffc02045ee:	0b07a783          	lw	a5,176(a5)
ffffffffc02045f2:	8b85                	andi	a5,a5,1
ffffffffc02045f4:	d7c9                	beqz	a5,ffffffffc020457e <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02045f6:	555d                	li	a0,-9
ffffffffc02045f8:	e0bff0ef          	jal	ra,ffffffffc0204402 <do_exit>
        proc = current->cptr;
ffffffffc02045fc:	000bb683          	ld	a3,0(s7)
ffffffffc0204600:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204602:	d45d                	beqz	s0,ffffffffc02045b0 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204604:	470d                	li	a4,3
ffffffffc0204606:	a021                	j	ffffffffc020460e <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204608:	10043403          	ld	s0,256(s0)
ffffffffc020460c:	d869                	beqz	s0,ffffffffc02045de <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020460e:	401c                	lw	a5,0(s0)
ffffffffc0204610:	fee79ce3          	bne	a5,a4,ffffffffc0204608 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204614:	000a6797          	auipc	a5,0xa6
ffffffffc0204618:	2ec7b783          	ld	a5,748(a5) # ffffffffc02aa900 <idleproc>
ffffffffc020461c:	0c878963          	beq	a5,s0,ffffffffc02046ee <do_wait.part.0+0x1a2>
ffffffffc0204620:	000a6797          	auipc	a5,0xa6
ffffffffc0204624:	2e87b783          	ld	a5,744(a5) # ffffffffc02aa908 <initproc>
ffffffffc0204628:	0cf40363          	beq	s0,a5,ffffffffc02046ee <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc020462c:	000a0663          	beqz	s4,ffffffffc0204638 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204630:	0e842783          	lw	a5,232(s0)
ffffffffc0204634:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc8>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204638:	100027f3          	csrr	a5,sstatus
ffffffffc020463c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020463e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204640:	e7c1                	bnez	a5,ffffffffc02046c8 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204642:	6c70                	ld	a2,216(s0)
ffffffffc0204644:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204646:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc020464a:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc020464c:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020464e:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204650:	6470                	ld	a2,200(s0)
ffffffffc0204652:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204654:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204656:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204658:	c319                	beqz	a4,ffffffffc020465e <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc020465a:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc020465c:	7c7c                	ld	a5,248(s0)
ffffffffc020465e:	c3b5                	beqz	a5,ffffffffc02046c2 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204660:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204664:	000a6717          	auipc	a4,0xa6
ffffffffc0204668:	2ac70713          	addi	a4,a4,684 # ffffffffc02aa910 <nr_process>
ffffffffc020466c:	431c                	lw	a5,0(a4)
ffffffffc020466e:	37fd                	addiw	a5,a5,-1
ffffffffc0204670:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204672:	e5a9                	bnez	a1,ffffffffc02046bc <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204674:	6814                	ld	a3,16(s0)
ffffffffc0204676:	c02007b7          	lui	a5,0xc0200
ffffffffc020467a:	04f6ee63          	bltu	a3,a5,ffffffffc02046d6 <do_wait.part.0+0x18a>
ffffffffc020467e:	000a6797          	auipc	a5,0xa6
ffffffffc0204682:	2727b783          	ld	a5,626(a5) # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0204686:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204688:	82b1                	srli	a3,a3,0xc
ffffffffc020468a:	000a6797          	auipc	a5,0xa6
ffffffffc020468e:	24e7b783          	ld	a5,590(a5) # ffffffffc02aa8d8 <npage>
ffffffffc0204692:	06f6fa63          	bgeu	a3,a5,ffffffffc0204706 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204696:	00003517          	auipc	a0,0x3
ffffffffc020469a:	1ca53503          	ld	a0,458(a0) # ffffffffc0207860 <nbase>
ffffffffc020469e:	8e89                	sub	a3,a3,a0
ffffffffc02046a0:	069a                	slli	a3,a3,0x6
ffffffffc02046a2:	000a6517          	auipc	a0,0xa6
ffffffffc02046a6:	23e53503          	ld	a0,574(a0) # ffffffffc02aa8e0 <pages>
ffffffffc02046aa:	9536                	add	a0,a0,a3
ffffffffc02046ac:	4589                	li	a1,2
ffffffffc02046ae:	829fd0ef          	jal	ra,ffffffffc0201ed6 <free_pages>
    kfree(proc);
ffffffffc02046b2:	8522                	mv	a0,s0
ffffffffc02046b4:	eb6fd0ef          	jal	ra,ffffffffc0201d6a <kfree>
    return 0;
ffffffffc02046b8:	4501                	li	a0,0
ffffffffc02046ba:	bde5                	j	ffffffffc02045b2 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc02046bc:	af2fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02046c0:	bf55                	j	ffffffffc0204674 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc02046c2:	701c                	ld	a5,32(s0)
ffffffffc02046c4:	fbf8                	sd	a4,240(a5)
ffffffffc02046c6:	bf79                	j	ffffffffc0204664 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc02046c8:	aecfc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02046cc:	4585                	li	a1,1
ffffffffc02046ce:	bf95                	j	ffffffffc0204642 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02046d0:	f2840413          	addi	s0,s0,-216
ffffffffc02046d4:	b781                	j	ffffffffc0204614 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc02046d6:	00002617          	auipc	a2,0x2
ffffffffc02046da:	f4260613          	addi	a2,a2,-190 # ffffffffc0206618 <default_pmm_manager+0xe0>
ffffffffc02046de:	07700593          	li	a1,119
ffffffffc02046e2:	00002517          	auipc	a0,0x2
ffffffffc02046e6:	eb650513          	addi	a0,a0,-330 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc02046ea:	da5fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc02046ee:	00003617          	auipc	a2,0x3
ffffffffc02046f2:	95a60613          	addi	a2,a2,-1702 # ffffffffc0207048 <default_pmm_manager+0xb10>
ffffffffc02046f6:	37400593          	li	a1,884
ffffffffc02046fa:	00003517          	auipc	a0,0x3
ffffffffc02046fe:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204702:	d8dfb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204706:	00002617          	auipc	a2,0x2
ffffffffc020470a:	f3a60613          	addi	a2,a2,-198 # ffffffffc0206640 <default_pmm_manager+0x108>
ffffffffc020470e:	06900593          	li	a1,105
ffffffffc0204712:	00002517          	auipc	a0,0x2
ffffffffc0204716:	e8650513          	addi	a0,a0,-378 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc020471a:	d75fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020471e <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc020471e:	1141                	addi	sp,sp,-16
ffffffffc0204720:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204722:	ff4fd0ef          	jal	ra,ffffffffc0201f16 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204726:	d90fd0ef          	jal	ra,ffffffffc0201cb6 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc020472a:	4601                	li	a2,0
ffffffffc020472c:	4581                	li	a1,0
ffffffffc020472e:	fffff517          	auipc	a0,0xfffff
ffffffffc0204732:	72050513          	addi	a0,a0,1824 # ffffffffc0203e4e <user_main>
ffffffffc0204736:	c7dff0ef          	jal	ra,ffffffffc02043b2 <kernel_thread>
    if (pid <= 0)
ffffffffc020473a:	00a04563          	bgtz	a0,ffffffffc0204744 <init_main+0x26>
ffffffffc020473e:	a071                	j	ffffffffc02047ca <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204740:	17d000ef          	jal	ra,ffffffffc02050bc <schedule>
    if (code_store != NULL)
ffffffffc0204744:	4581                	li	a1,0
ffffffffc0204746:	4501                	li	a0,0
ffffffffc0204748:	e05ff0ef          	jal	ra,ffffffffc020454c <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc020474c:	d975                	beqz	a0,ffffffffc0204740 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc020474e:	00003517          	auipc	a0,0x3
ffffffffc0204752:	93a50513          	addi	a0,a0,-1734 # ffffffffc0207088 <default_pmm_manager+0xb50>
ffffffffc0204756:	a3ffb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020475a:	000a6797          	auipc	a5,0xa6
ffffffffc020475e:	1ae7b783          	ld	a5,430(a5) # ffffffffc02aa908 <initproc>
ffffffffc0204762:	7bf8                	ld	a4,240(a5)
ffffffffc0204764:	e339                	bnez	a4,ffffffffc02047aa <init_main+0x8c>
ffffffffc0204766:	7ff8                	ld	a4,248(a5)
ffffffffc0204768:	e329                	bnez	a4,ffffffffc02047aa <init_main+0x8c>
ffffffffc020476a:	1007b703          	ld	a4,256(a5)
ffffffffc020476e:	ef15                	bnez	a4,ffffffffc02047aa <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204770:	000a6697          	auipc	a3,0xa6
ffffffffc0204774:	1a06a683          	lw	a3,416(a3) # ffffffffc02aa910 <nr_process>
ffffffffc0204778:	4709                	li	a4,2
ffffffffc020477a:	0ae69463          	bne	a3,a4,ffffffffc0204822 <init_main+0x104>
    return listelm->next;
ffffffffc020477e:	000a6697          	auipc	a3,0xa6
ffffffffc0204782:	10a68693          	addi	a3,a3,266 # ffffffffc02aa888 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204786:	6698                	ld	a4,8(a3)
ffffffffc0204788:	0c878793          	addi	a5,a5,200
ffffffffc020478c:	06f71b63          	bne	a4,a5,ffffffffc0204802 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204790:	629c                	ld	a5,0(a3)
ffffffffc0204792:	04f71863          	bne	a4,a5,ffffffffc02047e2 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204796:	00003517          	auipc	a0,0x3
ffffffffc020479a:	9da50513          	addi	a0,a0,-1574 # ffffffffc0207170 <default_pmm_manager+0xc38>
ffffffffc020479e:	9f7fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02047a2:	60a2                	ld	ra,8(sp)
ffffffffc02047a4:	4501                	li	a0,0
ffffffffc02047a6:	0141                	addi	sp,sp,16
ffffffffc02047a8:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02047aa:	00003697          	auipc	a3,0x3
ffffffffc02047ae:	90668693          	addi	a3,a3,-1786 # ffffffffc02070b0 <default_pmm_manager+0xb78>
ffffffffc02047b2:	00001617          	auipc	a2,0x1
ffffffffc02047b6:	7a660613          	addi	a2,a2,1958 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02047ba:	3e200593          	li	a1,994
ffffffffc02047be:	00002517          	auipc	a0,0x2
ffffffffc02047c2:	7ea50513          	addi	a0,a0,2026 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc02047c6:	cc9fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc02047ca:	00003617          	auipc	a2,0x3
ffffffffc02047ce:	89e60613          	addi	a2,a2,-1890 # ffffffffc0207068 <default_pmm_manager+0xb30>
ffffffffc02047d2:	3d900593          	li	a1,985
ffffffffc02047d6:	00002517          	auipc	a0,0x2
ffffffffc02047da:	7d250513          	addi	a0,a0,2002 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc02047de:	cb1fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02047e2:	00003697          	auipc	a3,0x3
ffffffffc02047e6:	95e68693          	addi	a3,a3,-1698 # ffffffffc0207140 <default_pmm_manager+0xc08>
ffffffffc02047ea:	00001617          	auipc	a2,0x1
ffffffffc02047ee:	76e60613          	addi	a2,a2,1902 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02047f2:	3e500593          	li	a1,997
ffffffffc02047f6:	00002517          	auipc	a0,0x2
ffffffffc02047fa:	7b250513          	addi	a0,a0,1970 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc02047fe:	c91fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204802:	00003697          	auipc	a3,0x3
ffffffffc0204806:	90e68693          	addi	a3,a3,-1778 # ffffffffc0207110 <default_pmm_manager+0xbd8>
ffffffffc020480a:	00001617          	auipc	a2,0x1
ffffffffc020480e:	74e60613          	addi	a2,a2,1870 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0204812:	3e400593          	li	a1,996
ffffffffc0204816:	00002517          	auipc	a0,0x2
ffffffffc020481a:	79250513          	addi	a0,a0,1938 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc020481e:	c71fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc0204822:	00003697          	auipc	a3,0x3
ffffffffc0204826:	8de68693          	addi	a3,a3,-1826 # ffffffffc0207100 <default_pmm_manager+0xbc8>
ffffffffc020482a:	00001617          	auipc	a2,0x1
ffffffffc020482e:	72e60613          	addi	a2,a2,1838 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0204832:	3e300593          	li	a1,995
ffffffffc0204836:	00002517          	auipc	a0,0x2
ffffffffc020483a:	77250513          	addi	a0,a0,1906 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc020483e:	c51fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204842 <do_execve>:
{
ffffffffc0204842:	7171                	addi	sp,sp,-176
ffffffffc0204844:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204846:	000a6d97          	auipc	s11,0xa6
ffffffffc020484a:	0b2d8d93          	addi	s11,s11,178 # ffffffffc02aa8f8 <current>
ffffffffc020484e:	000db783          	ld	a5,0(s11)
{
ffffffffc0204852:	e54e                	sd	s3,136(sp)
ffffffffc0204854:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204856:	0287b983          	ld	s3,40(a5)
{
ffffffffc020485a:	e94a                	sd	s2,144(sp)
ffffffffc020485c:	f4de                	sd	s7,104(sp)
ffffffffc020485e:	892a                	mv	s2,a0
ffffffffc0204860:	8bb2                	mv	s7,a2
ffffffffc0204862:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204864:	862e                	mv	a2,a1
ffffffffc0204866:	4681                	li	a3,0
ffffffffc0204868:	85aa                	mv	a1,a0
ffffffffc020486a:	854e                	mv	a0,s3
{
ffffffffc020486c:	f506                	sd	ra,168(sp)
ffffffffc020486e:	f122                	sd	s0,160(sp)
ffffffffc0204870:	e152                	sd	s4,128(sp)
ffffffffc0204872:	fcd6                	sd	s5,120(sp)
ffffffffc0204874:	f8da                	sd	s6,112(sp)
ffffffffc0204876:	f0e2                	sd	s8,96(sp)
ffffffffc0204878:	ece6                	sd	s9,88(sp)
ffffffffc020487a:	e8ea                	sd	s10,80(sp)
ffffffffc020487c:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020487e:	cb4ff0ef          	jal	ra,ffffffffc0203d32 <user_mem_check>
ffffffffc0204882:	40050a63          	beqz	a0,ffffffffc0204c96 <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204886:	4641                	li	a2,16
ffffffffc0204888:	4581                	li	a1,0
ffffffffc020488a:	1808                	addi	a0,sp,48
ffffffffc020488c:	643000ef          	jal	ra,ffffffffc02056ce <memset>
    memcpy(local_name, name, len);
ffffffffc0204890:	47bd                	li	a5,15
ffffffffc0204892:	8626                	mv	a2,s1
ffffffffc0204894:	1e97e263          	bltu	a5,s1,ffffffffc0204a78 <do_execve+0x236>
ffffffffc0204898:	85ca                	mv	a1,s2
ffffffffc020489a:	1808                	addi	a0,sp,48
ffffffffc020489c:	645000ef          	jal	ra,ffffffffc02056e0 <memcpy>
    if (mm != NULL)
ffffffffc02048a0:	1e098363          	beqz	s3,ffffffffc0204a86 <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc02048a4:	00002517          	auipc	a0,0x2
ffffffffc02048a8:	4c450513          	addi	a0,a0,1220 # ffffffffc0206d68 <default_pmm_manager+0x830>
ffffffffc02048ac:	921fb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc02048b0:	000a6797          	auipc	a5,0xa6
ffffffffc02048b4:	0187b783          	ld	a5,24(a5) # ffffffffc02aa8c8 <boot_pgdir_pa>
ffffffffc02048b8:	577d                	li	a4,-1
ffffffffc02048ba:	177e                	slli	a4,a4,0x3f
ffffffffc02048bc:	83b1                	srli	a5,a5,0xc
ffffffffc02048be:	8fd9                	or	a5,a5,a4
ffffffffc02048c0:	18079073          	csrw	satp,a5
ffffffffc02048c4:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b98>
ffffffffc02048c8:	fff7871b          	addiw	a4,a5,-1
ffffffffc02048cc:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02048d0:	2c070463          	beqz	a4,ffffffffc0204b98 <do_execve+0x356>
        current->mm = NULL;
ffffffffc02048d4:	000db783          	ld	a5,0(s11)
ffffffffc02048d8:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc02048dc:	de1fe0ef          	jal	ra,ffffffffc02036bc <mm_create>
ffffffffc02048e0:	84aa                	mv	s1,a0
ffffffffc02048e2:	1c050d63          	beqz	a0,ffffffffc0204abc <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc02048e6:	4505                	li	a0,1
ffffffffc02048e8:	db0fd0ef          	jal	ra,ffffffffc0201e98 <alloc_pages>
ffffffffc02048ec:	3a050963          	beqz	a0,ffffffffc0204c9e <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc02048f0:	000a6c97          	auipc	s9,0xa6
ffffffffc02048f4:	ff0c8c93          	addi	s9,s9,-16 # ffffffffc02aa8e0 <pages>
ffffffffc02048f8:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc02048fc:	000a6c17          	auipc	s8,0xa6
ffffffffc0204900:	fdcc0c13          	addi	s8,s8,-36 # ffffffffc02aa8d8 <npage>
    return page - pages + nbase;
ffffffffc0204904:	00003717          	auipc	a4,0x3
ffffffffc0204908:	f5c73703          	ld	a4,-164(a4) # ffffffffc0207860 <nbase>
ffffffffc020490c:	40d506b3          	sub	a3,a0,a3
ffffffffc0204910:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204912:	5afd                	li	s5,-1
ffffffffc0204914:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0204918:	96ba                	add	a3,a3,a4
ffffffffc020491a:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc020491c:	00cad713          	srli	a4,s5,0xc
ffffffffc0204920:	ec3a                	sd	a4,24(sp)
ffffffffc0204922:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204924:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204926:	38f77063          	bgeu	a4,a5,ffffffffc0204ca6 <do_execve+0x464>
ffffffffc020492a:	000a6b17          	auipc	s6,0xa6
ffffffffc020492e:	fc6b0b13          	addi	s6,s6,-58 # ffffffffc02aa8f0 <va_pa_offset>
ffffffffc0204932:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204936:	6605                	lui	a2,0x1
ffffffffc0204938:	000a6597          	auipc	a1,0xa6
ffffffffc020493c:	f985b583          	ld	a1,-104(a1) # ffffffffc02aa8d0 <boot_pgdir_va>
ffffffffc0204940:	9936                	add	s2,s2,a3
ffffffffc0204942:	854a                	mv	a0,s2
ffffffffc0204944:	59d000ef          	jal	ra,ffffffffc02056e0 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204948:	7782                	ld	a5,32(sp)
ffffffffc020494a:	4398                	lw	a4,0(a5)
ffffffffc020494c:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204950:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204954:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b943f>
ffffffffc0204958:	14f71863          	bne	a4,a5,ffffffffc0204aa8 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020495c:	7682                	ld	a3,32(sp)
ffffffffc020495e:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204962:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204966:	00371793          	slli	a5,a4,0x3
ffffffffc020496a:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020496c:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020496e:	078e                	slli	a5,a5,0x3
ffffffffc0204970:	97ce                	add	a5,a5,s3
ffffffffc0204972:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204974:	00f9fc63          	bgeu	s3,a5,ffffffffc020498c <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204978:	0009a783          	lw	a5,0(s3)
ffffffffc020497c:	4705                	li	a4,1
ffffffffc020497e:	14e78163          	beq	a5,a4,ffffffffc0204ac0 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204982:	77a2                	ld	a5,40(sp)
ffffffffc0204984:	03898993          	addi	s3,s3,56
ffffffffc0204988:	fef9e8e3          	bltu	s3,a5,ffffffffc0204978 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc020498c:	4701                	li	a4,0
ffffffffc020498e:	46ad                	li	a3,11
ffffffffc0204990:	00100637          	lui	a2,0x100
ffffffffc0204994:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204998:	8526                	mv	a0,s1
ffffffffc020499a:	eb5fe0ef          	jal	ra,ffffffffc020384e <mm_map>
ffffffffc020499e:	8a2a                	mv	s4,a0
ffffffffc02049a0:	1e051263          	bnez	a0,ffffffffc0204b84 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc02049a4:	6c88                	ld	a0,24(s1)
ffffffffc02049a6:	467d                	li	a2,31
ffffffffc02049a8:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02049ac:	c2bfe0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc02049b0:	38050363          	beqz	a0,ffffffffc0204d36 <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc02049b4:	6c88                	ld	a0,24(s1)
ffffffffc02049b6:	467d                	li	a2,31
ffffffffc02049b8:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc02049bc:	c1bfe0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc02049c0:	34050b63          	beqz	a0,ffffffffc0204d16 <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc02049c4:	6c88                	ld	a0,24(s1)
ffffffffc02049c6:	467d                	li	a2,31
ffffffffc02049c8:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc02049cc:	c0bfe0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc02049d0:	32050363          	beqz	a0,ffffffffc0204cf6 <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc02049d4:	6c88                	ld	a0,24(s1)
ffffffffc02049d6:	467d                	li	a2,31
ffffffffc02049d8:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc02049dc:	bfbfe0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc02049e0:	2e050b63          	beqz	a0,ffffffffc0204cd6 <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc02049e4:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc02049e6:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02049ea:	6c94                	ld	a3,24(s1)
ffffffffc02049ec:	2785                	addiw	a5,a5,1
ffffffffc02049ee:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc02049f0:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02049f2:	c02007b7          	lui	a5,0xc0200
ffffffffc02049f6:	2cf6e463          	bltu	a3,a5,ffffffffc0204cbe <do_execve+0x47c>
ffffffffc02049fa:	000b3783          	ld	a5,0(s6)
ffffffffc02049fe:	577d                	li	a4,-1
ffffffffc0204a00:	177e                	slli	a4,a4,0x3f
ffffffffc0204a02:	8e9d                	sub	a3,a3,a5
ffffffffc0204a04:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204a08:	f654                	sd	a3,168(a2)
ffffffffc0204a0a:	8fd9                	or	a5,a5,a4
ffffffffc0204a0c:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204a10:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204a12:	4581                	li	a1,0
ffffffffc0204a14:	12000613          	li	a2,288
ffffffffc0204a18:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204a1a:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204a1e:	4b1000ef          	jal	ra,ffffffffc02056ce <memset>
    tf->epc = elf->e_entry;
ffffffffc0204a22:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a24:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204a28:	edf4f493          	andi	s1,s1,-289
    tf->epc = elf->e_entry;
ffffffffc0204a2c:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a2e:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a30:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_exit_out_size+0xffffffff7fff4f74>
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a34:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204a36:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a3a:	4641                	li	a2,16
ffffffffc0204a3c:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0204a3e:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0204a40:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204a44:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204a48:	854a                	mv	a0,s2
ffffffffc0204a4a:	485000ef          	jal	ra,ffffffffc02056ce <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204a4e:	463d                	li	a2,15
ffffffffc0204a50:	180c                	addi	a1,sp,48
ffffffffc0204a52:	854a                	mv	a0,s2
ffffffffc0204a54:	48d000ef          	jal	ra,ffffffffc02056e0 <memcpy>
}
ffffffffc0204a58:	70aa                	ld	ra,168(sp)
ffffffffc0204a5a:	740a                	ld	s0,160(sp)
ffffffffc0204a5c:	64ea                	ld	s1,152(sp)
ffffffffc0204a5e:	694a                	ld	s2,144(sp)
ffffffffc0204a60:	69aa                	ld	s3,136(sp)
ffffffffc0204a62:	7ae6                	ld	s5,120(sp)
ffffffffc0204a64:	7b46                	ld	s6,112(sp)
ffffffffc0204a66:	7ba6                	ld	s7,104(sp)
ffffffffc0204a68:	7c06                	ld	s8,96(sp)
ffffffffc0204a6a:	6ce6                	ld	s9,88(sp)
ffffffffc0204a6c:	6d46                	ld	s10,80(sp)
ffffffffc0204a6e:	6da6                	ld	s11,72(sp)
ffffffffc0204a70:	8552                	mv	a0,s4
ffffffffc0204a72:	6a0a                	ld	s4,128(sp)
ffffffffc0204a74:	614d                	addi	sp,sp,176
ffffffffc0204a76:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204a78:	463d                	li	a2,15
ffffffffc0204a7a:	85ca                	mv	a1,s2
ffffffffc0204a7c:	1808                	addi	a0,sp,48
ffffffffc0204a7e:	463000ef          	jal	ra,ffffffffc02056e0 <memcpy>
    if (mm != NULL)
ffffffffc0204a82:	e20991e3          	bnez	s3,ffffffffc02048a4 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204a86:	000db783          	ld	a5,0(s11)
ffffffffc0204a8a:	779c                	ld	a5,40(a5)
ffffffffc0204a8c:	e40788e3          	beqz	a5,ffffffffc02048dc <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204a90:	00002617          	auipc	a2,0x2
ffffffffc0204a94:	70060613          	addi	a2,a2,1792 # ffffffffc0207190 <default_pmm_manager+0xc58>
ffffffffc0204a98:	25900593          	li	a1,601
ffffffffc0204a9c:	00002517          	auipc	a0,0x2
ffffffffc0204aa0:	50c50513          	addi	a0,a0,1292 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204aa4:	9ebfb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204aa8:	8526                	mv	a0,s1
ffffffffc0204aaa:	c22ff0ef          	jal	ra,ffffffffc0203ecc <put_pgdir>
    mm_destroy(mm);
ffffffffc0204aae:	8526                	mv	a0,s1
ffffffffc0204ab0:	d4dfe0ef          	jal	ra,ffffffffc02037fc <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204ab4:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204ab6:	8552                	mv	a0,s4
ffffffffc0204ab8:	94bff0ef          	jal	ra,ffffffffc0204402 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204abc:	5a71                	li	s4,-4
ffffffffc0204abe:	bfe5                	j	ffffffffc0204ab6 <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204ac0:	0289b603          	ld	a2,40(s3)
ffffffffc0204ac4:	0209b783          	ld	a5,32(s3)
ffffffffc0204ac8:	1cf66d63          	bltu	a2,a5,ffffffffc0204ca2 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204acc:	0049a783          	lw	a5,4(s3)
ffffffffc0204ad0:	0017f693          	andi	a3,a5,1
ffffffffc0204ad4:	c291                	beqz	a3,ffffffffc0204ad8 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204ad6:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204ad8:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204adc:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204ade:	e779                	bnez	a4,ffffffffc0204bac <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204ae0:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204ae2:	c781                	beqz	a5,ffffffffc0204aea <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204ae4:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204ae8:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204aea:	0026f793          	andi	a5,a3,2
ffffffffc0204aee:	e3f1                	bnez	a5,ffffffffc0204bb2 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204af0:	0046f793          	andi	a5,a3,4
ffffffffc0204af4:	c399                	beqz	a5,ffffffffc0204afa <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204af6:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204afa:	0109b583          	ld	a1,16(s3)
ffffffffc0204afe:	4701                	li	a4,0
ffffffffc0204b00:	8526                	mv	a0,s1
ffffffffc0204b02:	d4dfe0ef          	jal	ra,ffffffffc020384e <mm_map>
ffffffffc0204b06:	8a2a                	mv	s4,a0
ffffffffc0204b08:	ed35                	bnez	a0,ffffffffc0204b84 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b0a:	0109bb83          	ld	s7,16(s3)
ffffffffc0204b0e:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b10:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b14:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204b18:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b1c:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204b1e:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204b20:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204b22:	054be963          	bltu	s7,s4,ffffffffc0204b74 <do_execve+0x332>
ffffffffc0204b26:	aa95                	j	ffffffffc0204c9a <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204b28:	6785                	lui	a5,0x1
ffffffffc0204b2a:	415b8533          	sub	a0,s7,s5
ffffffffc0204b2e:	9abe                	add	s5,s5,a5
ffffffffc0204b30:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204b34:	015a7463          	bgeu	s4,s5,ffffffffc0204b3c <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204b38:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204b3c:	000cb683          	ld	a3,0(s9)
ffffffffc0204b40:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204b42:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204b46:	40d406b3          	sub	a3,s0,a3
ffffffffc0204b4a:	8699                	srai	a3,a3,0x6
ffffffffc0204b4c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204b4e:	67e2                	ld	a5,24(sp)
ffffffffc0204b50:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b54:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b56:	14b87863          	bgeu	a6,a1,ffffffffc0204ca6 <do_execve+0x464>
ffffffffc0204b5a:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b5e:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204b60:	9bb2                	add	s7,s7,a2
ffffffffc0204b62:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b64:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204b66:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204b68:	379000ef          	jal	ra,ffffffffc02056e0 <memcpy>
            start += size, from += size;
ffffffffc0204b6c:	6622                	ld	a2,8(sp)
ffffffffc0204b6e:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204b70:	054bf363          	bgeu	s7,s4,ffffffffc0204bb6 <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204b74:	6c88                	ld	a0,24(s1)
ffffffffc0204b76:	866a                	mv	a2,s10
ffffffffc0204b78:	85d6                	mv	a1,s5
ffffffffc0204b7a:	a5dfe0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc0204b7e:	842a                	mv	s0,a0
ffffffffc0204b80:	f545                	bnez	a0,ffffffffc0204b28 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204b82:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204b84:	8526                	mv	a0,s1
ffffffffc0204b86:	e13fe0ef          	jal	ra,ffffffffc0203998 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204b8a:	8526                	mv	a0,s1
ffffffffc0204b8c:	b40ff0ef          	jal	ra,ffffffffc0203ecc <put_pgdir>
    mm_destroy(mm);
ffffffffc0204b90:	8526                	mv	a0,s1
ffffffffc0204b92:	c6bfe0ef          	jal	ra,ffffffffc02037fc <mm_destroy>
    return ret;
ffffffffc0204b96:	b705                	j	ffffffffc0204ab6 <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204b98:	854e                	mv	a0,s3
ffffffffc0204b9a:	dfffe0ef          	jal	ra,ffffffffc0203998 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204b9e:	854e                	mv	a0,s3
ffffffffc0204ba0:	b2cff0ef          	jal	ra,ffffffffc0203ecc <put_pgdir>
            mm_destroy(mm);
ffffffffc0204ba4:	854e                	mv	a0,s3
ffffffffc0204ba6:	c57fe0ef          	jal	ra,ffffffffc02037fc <mm_destroy>
ffffffffc0204baa:	b32d                	j	ffffffffc02048d4 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204bac:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bb0:	fb95                	bnez	a5,ffffffffc0204ae4 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204bb2:	4d5d                	li	s10,23
ffffffffc0204bb4:	bf35                	j	ffffffffc0204af0 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204bb6:	0109b683          	ld	a3,16(s3)
ffffffffc0204bba:	0289b903          	ld	s2,40(s3)
ffffffffc0204bbe:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204bc0:	075bfd63          	bgeu	s7,s5,ffffffffc0204c3a <do_execve+0x3f8>
            if (start == end)
ffffffffc0204bc4:	db790fe3          	beq	s2,s7,ffffffffc0204982 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204bc8:	6785                	lui	a5,0x1
ffffffffc0204bca:	00fb8533          	add	a0,s7,a5
ffffffffc0204bce:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204bd2:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204bd6:	0b597d63          	bgeu	s2,s5,ffffffffc0204c90 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204bda:	000cb683          	ld	a3,0(s9)
ffffffffc0204bde:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204be0:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204be4:	40d406b3          	sub	a3,s0,a3
ffffffffc0204be8:	8699                	srai	a3,a3,0x6
ffffffffc0204bea:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204bec:	67e2                	ld	a5,24(sp)
ffffffffc0204bee:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204bf2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204bf4:	0ac5f963          	bgeu	a1,a2,ffffffffc0204ca6 <do_execve+0x464>
ffffffffc0204bf8:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204bfc:	8652                	mv	a2,s4
ffffffffc0204bfe:	4581                	li	a1,0
ffffffffc0204c00:	96c2                	add	a3,a3,a6
ffffffffc0204c02:	9536                	add	a0,a0,a3
ffffffffc0204c04:	2cb000ef          	jal	ra,ffffffffc02056ce <memset>
            start += size;
ffffffffc0204c08:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204c0c:	03597463          	bgeu	s2,s5,ffffffffc0204c34 <do_execve+0x3f2>
ffffffffc0204c10:	d6e909e3          	beq	s2,a4,ffffffffc0204982 <do_execve+0x140>
ffffffffc0204c14:	00002697          	auipc	a3,0x2
ffffffffc0204c18:	5a468693          	addi	a3,a3,1444 # ffffffffc02071b8 <default_pmm_manager+0xc80>
ffffffffc0204c1c:	00001617          	auipc	a2,0x1
ffffffffc0204c20:	33c60613          	addi	a2,a2,828 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0204c24:	2c200593          	li	a1,706
ffffffffc0204c28:	00002517          	auipc	a0,0x2
ffffffffc0204c2c:	38050513          	addi	a0,a0,896 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204c30:	85ffb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204c34:	ff5710e3          	bne	a4,s5,ffffffffc0204c14 <do_execve+0x3d2>
ffffffffc0204c38:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204c3a:	d52bf4e3          	bgeu	s7,s2,ffffffffc0204982 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204c3e:	6c88                	ld	a0,24(s1)
ffffffffc0204c40:	866a                	mv	a2,s10
ffffffffc0204c42:	85d6                	mv	a1,s5
ffffffffc0204c44:	993fe0ef          	jal	ra,ffffffffc02035d6 <pgdir_alloc_page>
ffffffffc0204c48:	842a                	mv	s0,a0
ffffffffc0204c4a:	dd05                	beqz	a0,ffffffffc0204b82 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c4c:	6785                	lui	a5,0x1
ffffffffc0204c4e:	415b8533          	sub	a0,s7,s5
ffffffffc0204c52:	9abe                	add	s5,s5,a5
ffffffffc0204c54:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204c58:	01597463          	bgeu	s2,s5,ffffffffc0204c60 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204c5c:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204c60:	000cb683          	ld	a3,0(s9)
ffffffffc0204c64:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204c66:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204c6a:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c6e:	8699                	srai	a3,a3,0x6
ffffffffc0204c70:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204c72:	67e2                	ld	a5,24(sp)
ffffffffc0204c74:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c78:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c7a:	02b87663          	bgeu	a6,a1,ffffffffc0204ca6 <do_execve+0x464>
ffffffffc0204c7e:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c82:	4581                	li	a1,0
            start += size;
ffffffffc0204c84:	9bb2                	add	s7,s7,a2
ffffffffc0204c86:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204c88:	9536                	add	a0,a0,a3
ffffffffc0204c8a:	245000ef          	jal	ra,ffffffffc02056ce <memset>
ffffffffc0204c8e:	b775                	j	ffffffffc0204c3a <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204c90:	417a8a33          	sub	s4,s5,s7
ffffffffc0204c94:	b799                	j	ffffffffc0204bda <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204c96:	5a75                	li	s4,-3
ffffffffc0204c98:	b3c1                	j	ffffffffc0204a58 <do_execve+0x216>
        while (start < end)
ffffffffc0204c9a:	86de                	mv	a3,s7
ffffffffc0204c9c:	bf39                	j	ffffffffc0204bba <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204c9e:	5a71                	li	s4,-4
ffffffffc0204ca0:	bdc5                	j	ffffffffc0204b90 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204ca2:	5a61                	li	s4,-8
ffffffffc0204ca4:	b5c5                	j	ffffffffc0204b84 <do_execve+0x342>
ffffffffc0204ca6:	00002617          	auipc	a2,0x2
ffffffffc0204caa:	8ca60613          	addi	a2,a2,-1846 # ffffffffc0206570 <default_pmm_manager+0x38>
ffffffffc0204cae:	07100593          	li	a1,113
ffffffffc0204cb2:	00002517          	auipc	a0,0x2
ffffffffc0204cb6:	8e650513          	addi	a0,a0,-1818 # ffffffffc0206598 <default_pmm_manager+0x60>
ffffffffc0204cba:	fd4fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204cbe:	00002617          	auipc	a2,0x2
ffffffffc0204cc2:	95a60613          	addi	a2,a2,-1702 # ffffffffc0206618 <default_pmm_manager+0xe0>
ffffffffc0204cc6:	2e100593          	li	a1,737
ffffffffc0204cca:	00002517          	auipc	a0,0x2
ffffffffc0204cce:	2de50513          	addi	a0,a0,734 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204cd2:	fbcfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204cd6:	00002697          	auipc	a3,0x2
ffffffffc0204cda:	5fa68693          	addi	a3,a3,1530 # ffffffffc02072d0 <default_pmm_manager+0xd98>
ffffffffc0204cde:	00001617          	auipc	a2,0x1
ffffffffc0204ce2:	27a60613          	addi	a2,a2,634 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0204ce6:	2dc00593          	li	a1,732
ffffffffc0204cea:	00002517          	auipc	a0,0x2
ffffffffc0204cee:	2be50513          	addi	a0,a0,702 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204cf2:	f9cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204cf6:	00002697          	auipc	a3,0x2
ffffffffc0204cfa:	59268693          	addi	a3,a3,1426 # ffffffffc0207288 <default_pmm_manager+0xd50>
ffffffffc0204cfe:	00001617          	auipc	a2,0x1
ffffffffc0204d02:	25a60613          	addi	a2,a2,602 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0204d06:	2db00593          	li	a1,731
ffffffffc0204d0a:	00002517          	auipc	a0,0x2
ffffffffc0204d0e:	29e50513          	addi	a0,a0,670 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204d12:	f7cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d16:	00002697          	auipc	a3,0x2
ffffffffc0204d1a:	52a68693          	addi	a3,a3,1322 # ffffffffc0207240 <default_pmm_manager+0xd08>
ffffffffc0204d1e:	00001617          	auipc	a2,0x1
ffffffffc0204d22:	23a60613          	addi	a2,a2,570 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0204d26:	2da00593          	li	a1,730
ffffffffc0204d2a:	00002517          	auipc	a0,0x2
ffffffffc0204d2e:	27e50513          	addi	a0,a0,638 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204d32:	f5cfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204d36:	00002697          	auipc	a3,0x2
ffffffffc0204d3a:	4c268693          	addi	a3,a3,1218 # ffffffffc02071f8 <default_pmm_manager+0xcc0>
ffffffffc0204d3e:	00001617          	auipc	a2,0x1
ffffffffc0204d42:	21a60613          	addi	a2,a2,538 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0204d46:	2d900593          	li	a1,729
ffffffffc0204d4a:	00002517          	auipc	a0,0x2
ffffffffc0204d4e:	25e50513          	addi	a0,a0,606 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204d52:	f3cfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204d56 <do_yield>:
    current->need_resched = 1;
ffffffffc0204d56:	000a6797          	auipc	a5,0xa6
ffffffffc0204d5a:	ba27b783          	ld	a5,-1118(a5) # ffffffffc02aa8f8 <current>
ffffffffc0204d5e:	4705                	li	a4,1
ffffffffc0204d60:	ef98                	sd	a4,24(a5)
}
ffffffffc0204d62:	4501                	li	a0,0
ffffffffc0204d64:	8082                	ret

ffffffffc0204d66 <do_wait>:
{
ffffffffc0204d66:	1101                	addi	sp,sp,-32
ffffffffc0204d68:	e822                	sd	s0,16(sp)
ffffffffc0204d6a:	e426                	sd	s1,8(sp)
ffffffffc0204d6c:	ec06                	sd	ra,24(sp)
ffffffffc0204d6e:	842e                	mv	s0,a1
ffffffffc0204d70:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204d72:	c999                	beqz	a1,ffffffffc0204d88 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204d74:	000a6797          	auipc	a5,0xa6
ffffffffc0204d78:	b847b783          	ld	a5,-1148(a5) # ffffffffc02aa8f8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204d7c:	7788                	ld	a0,40(a5)
ffffffffc0204d7e:	4685                	li	a3,1
ffffffffc0204d80:	4611                	li	a2,4
ffffffffc0204d82:	fb1fe0ef          	jal	ra,ffffffffc0203d32 <user_mem_check>
ffffffffc0204d86:	c909                	beqz	a0,ffffffffc0204d98 <do_wait+0x32>
ffffffffc0204d88:	85a2                	mv	a1,s0
}
ffffffffc0204d8a:	6442                	ld	s0,16(sp)
ffffffffc0204d8c:	60e2                	ld	ra,24(sp)
ffffffffc0204d8e:	8526                	mv	a0,s1
ffffffffc0204d90:	64a2                	ld	s1,8(sp)
ffffffffc0204d92:	6105                	addi	sp,sp,32
ffffffffc0204d94:	fb8ff06f          	j	ffffffffc020454c <do_wait.part.0>
ffffffffc0204d98:	60e2                	ld	ra,24(sp)
ffffffffc0204d9a:	6442                	ld	s0,16(sp)
ffffffffc0204d9c:	64a2                	ld	s1,8(sp)
ffffffffc0204d9e:	5575                	li	a0,-3
ffffffffc0204da0:	6105                	addi	sp,sp,32
ffffffffc0204da2:	8082                	ret

ffffffffc0204da4 <do_kill>:
{
ffffffffc0204da4:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204da6:	6789                	lui	a5,0x2
{
ffffffffc0204da8:	e406                	sd	ra,8(sp)
ffffffffc0204daa:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204dac:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204db0:	17f9                	addi	a5,a5,-2
ffffffffc0204db2:	02e7e963          	bltu	a5,a4,ffffffffc0204de4 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204db6:	842a                	mv	s0,a0
ffffffffc0204db8:	45a9                	li	a1,10
ffffffffc0204dba:	2501                	sext.w	a0,a0
ffffffffc0204dbc:	46c000ef          	jal	ra,ffffffffc0205228 <hash32>
ffffffffc0204dc0:	02051793          	slli	a5,a0,0x20
ffffffffc0204dc4:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204dc8:	000a2797          	auipc	a5,0xa2
ffffffffc0204dcc:	ac078793          	addi	a5,a5,-1344 # ffffffffc02a6888 <hash_list>
ffffffffc0204dd0:	953e                	add	a0,a0,a5
ffffffffc0204dd2:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204dd4:	a029                	j	ffffffffc0204dde <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204dd6:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204dda:	00870b63          	beq	a4,s0,ffffffffc0204df0 <do_kill+0x4c>
ffffffffc0204dde:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204de0:	fef51be3          	bne	a0,a5,ffffffffc0204dd6 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204de4:	5475                	li	s0,-3
}
ffffffffc0204de6:	60a2                	ld	ra,8(sp)
ffffffffc0204de8:	8522                	mv	a0,s0
ffffffffc0204dea:	6402                	ld	s0,0(sp)
ffffffffc0204dec:	0141                	addi	sp,sp,16
ffffffffc0204dee:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204df0:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204df4:	00177693          	andi	a3,a4,1
ffffffffc0204df8:	e295                	bnez	a3,ffffffffc0204e1c <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204dfa:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204dfc:	00176713          	ori	a4,a4,1
ffffffffc0204e00:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204e04:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204e06:	fe06d0e3          	bgez	a3,ffffffffc0204de6 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204e0a:	f2878513          	addi	a0,a5,-216
ffffffffc0204e0e:	22e000ef          	jal	ra,ffffffffc020503c <wakeup_proc>
}
ffffffffc0204e12:	60a2                	ld	ra,8(sp)
ffffffffc0204e14:	8522                	mv	a0,s0
ffffffffc0204e16:	6402                	ld	s0,0(sp)
ffffffffc0204e18:	0141                	addi	sp,sp,16
ffffffffc0204e1a:	8082                	ret
        return -E_KILLED;
ffffffffc0204e1c:	545d                	li	s0,-9
ffffffffc0204e1e:	b7e1                	j	ffffffffc0204de6 <do_kill+0x42>

ffffffffc0204e20 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204e20:	1101                	addi	sp,sp,-32
ffffffffc0204e22:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204e24:	000a6797          	auipc	a5,0xa6
ffffffffc0204e28:	a6478793          	addi	a5,a5,-1436 # ffffffffc02aa888 <proc_list>
ffffffffc0204e2c:	ec06                	sd	ra,24(sp)
ffffffffc0204e2e:	e822                	sd	s0,16(sp)
ffffffffc0204e30:	e04a                	sd	s2,0(sp)
ffffffffc0204e32:	000a2497          	auipc	s1,0xa2
ffffffffc0204e36:	a5648493          	addi	s1,s1,-1450 # ffffffffc02a6888 <hash_list>
ffffffffc0204e3a:	e79c                	sd	a5,8(a5)
ffffffffc0204e3c:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204e3e:	000a6717          	auipc	a4,0xa6
ffffffffc0204e42:	a4a70713          	addi	a4,a4,-1462 # ffffffffc02aa888 <proc_list>
ffffffffc0204e46:	87a6                	mv	a5,s1
ffffffffc0204e48:	e79c                	sd	a5,8(a5)
ffffffffc0204e4a:	e39c                	sd	a5,0(a5)
ffffffffc0204e4c:	07c1                	addi	a5,a5,16
ffffffffc0204e4e:	fef71de3          	bne	a4,a5,ffffffffc0204e48 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204e52:	f7dfe0ef          	jal	ra,ffffffffc0203dce <alloc_proc>
ffffffffc0204e56:	000a6917          	auipc	s2,0xa6
ffffffffc0204e5a:	aaa90913          	addi	s2,s2,-1366 # ffffffffc02aa900 <idleproc>
ffffffffc0204e5e:	00a93023          	sd	a0,0(s2)
ffffffffc0204e62:	0e050f63          	beqz	a0,ffffffffc0204f60 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204e66:	4789                	li	a5,2
ffffffffc0204e68:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e6a:	00003797          	auipc	a5,0x3
ffffffffc0204e6e:	19678793          	addi	a5,a5,406 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e72:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204e76:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204e78:	4785                	li	a5,1
ffffffffc0204e7a:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e7c:	4641                	li	a2,16
ffffffffc0204e7e:	4581                	li	a1,0
ffffffffc0204e80:	8522                	mv	a0,s0
ffffffffc0204e82:	04d000ef          	jal	ra,ffffffffc02056ce <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204e86:	463d                	li	a2,15
ffffffffc0204e88:	00002597          	auipc	a1,0x2
ffffffffc0204e8c:	4a858593          	addi	a1,a1,1192 # ffffffffc0207330 <default_pmm_manager+0xdf8>
ffffffffc0204e90:	8522                	mv	a0,s0
ffffffffc0204e92:	04f000ef          	jal	ra,ffffffffc02056e0 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204e96:	000a6717          	auipc	a4,0xa6
ffffffffc0204e9a:	a7a70713          	addi	a4,a4,-1414 # ffffffffc02aa910 <nr_process>
ffffffffc0204e9e:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204ea0:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204ea4:	4601                	li	a2,0
    nr_process++;
ffffffffc0204ea6:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204ea8:	4581                	li	a1,0
ffffffffc0204eaa:	00000517          	auipc	a0,0x0
ffffffffc0204eae:	87450513          	addi	a0,a0,-1932 # ffffffffc020471e <init_main>
    nr_process++;
ffffffffc0204eb2:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204eb4:	000a6797          	auipc	a5,0xa6
ffffffffc0204eb8:	a4d7b223          	sd	a3,-1468(a5) # ffffffffc02aa8f8 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204ebc:	cf6ff0ef          	jal	ra,ffffffffc02043b2 <kernel_thread>
ffffffffc0204ec0:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204ec2:	08a05363          	blez	a0,ffffffffc0204f48 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ec6:	6789                	lui	a5,0x2
ffffffffc0204ec8:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204ecc:	17f9                	addi	a5,a5,-2
ffffffffc0204ece:	2501                	sext.w	a0,a0
ffffffffc0204ed0:	02e7e363          	bltu	a5,a4,ffffffffc0204ef6 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204ed4:	45a9                	li	a1,10
ffffffffc0204ed6:	352000ef          	jal	ra,ffffffffc0205228 <hash32>
ffffffffc0204eda:	02051793          	slli	a5,a0,0x20
ffffffffc0204ede:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204ee2:	96a6                	add	a3,a3,s1
ffffffffc0204ee4:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204ee6:	a029                	j	ffffffffc0204ef0 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204ee8:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c9c>
ffffffffc0204eec:	04870b63          	beq	a4,s0,ffffffffc0204f42 <proc_init+0x122>
    return listelm->next;
ffffffffc0204ef0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204ef2:	fef69be3          	bne	a3,a5,ffffffffc0204ee8 <proc_init+0xc8>
    return NULL;
ffffffffc0204ef6:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ef8:	0b478493          	addi	s1,a5,180
ffffffffc0204efc:	4641                	li	a2,16
ffffffffc0204efe:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204f00:	000a6417          	auipc	s0,0xa6
ffffffffc0204f04:	a0840413          	addi	s0,s0,-1528 # ffffffffc02aa908 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f08:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204f0a:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f0c:	7c2000ef          	jal	ra,ffffffffc02056ce <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f10:	463d                	li	a2,15
ffffffffc0204f12:	00002597          	auipc	a1,0x2
ffffffffc0204f16:	44658593          	addi	a1,a1,1094 # ffffffffc0207358 <default_pmm_manager+0xe20>
ffffffffc0204f1a:	8526                	mv	a0,s1
ffffffffc0204f1c:	7c4000ef          	jal	ra,ffffffffc02056e0 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f20:	00093783          	ld	a5,0(s2)
ffffffffc0204f24:	cbb5                	beqz	a5,ffffffffc0204f98 <proc_init+0x178>
ffffffffc0204f26:	43dc                	lw	a5,4(a5)
ffffffffc0204f28:	eba5                	bnez	a5,ffffffffc0204f98 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f2a:	601c                	ld	a5,0(s0)
ffffffffc0204f2c:	c7b1                	beqz	a5,ffffffffc0204f78 <proc_init+0x158>
ffffffffc0204f2e:	43d8                	lw	a4,4(a5)
ffffffffc0204f30:	4785                	li	a5,1
ffffffffc0204f32:	04f71363          	bne	a4,a5,ffffffffc0204f78 <proc_init+0x158>
}
ffffffffc0204f36:	60e2                	ld	ra,24(sp)
ffffffffc0204f38:	6442                	ld	s0,16(sp)
ffffffffc0204f3a:	64a2                	ld	s1,8(sp)
ffffffffc0204f3c:	6902                	ld	s2,0(sp)
ffffffffc0204f3e:	6105                	addi	sp,sp,32
ffffffffc0204f40:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204f42:	f2878793          	addi	a5,a5,-216
ffffffffc0204f46:	bf4d                	j	ffffffffc0204ef8 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0204f48:	00002617          	auipc	a2,0x2
ffffffffc0204f4c:	3f060613          	addi	a2,a2,1008 # ffffffffc0207338 <default_pmm_manager+0xe00>
ffffffffc0204f50:	40800593          	li	a1,1032
ffffffffc0204f54:	00002517          	auipc	a0,0x2
ffffffffc0204f58:	05450513          	addi	a0,a0,84 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204f5c:	d32fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204f60:	00002617          	auipc	a2,0x2
ffffffffc0204f64:	3b860613          	addi	a2,a2,952 # ffffffffc0207318 <default_pmm_manager+0xde0>
ffffffffc0204f68:	3f900593          	li	a1,1017
ffffffffc0204f6c:	00002517          	auipc	a0,0x2
ffffffffc0204f70:	03c50513          	addi	a0,a0,60 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204f74:	d1afb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204f78:	00002697          	auipc	a3,0x2
ffffffffc0204f7c:	41068693          	addi	a3,a3,1040 # ffffffffc0207388 <default_pmm_manager+0xe50>
ffffffffc0204f80:	00001617          	auipc	a2,0x1
ffffffffc0204f84:	fd860613          	addi	a2,a2,-40 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0204f88:	40f00593          	li	a1,1039
ffffffffc0204f8c:	00002517          	auipc	a0,0x2
ffffffffc0204f90:	01c50513          	addi	a0,a0,28 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204f94:	cfafb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204f98:	00002697          	auipc	a3,0x2
ffffffffc0204f9c:	3c868693          	addi	a3,a3,968 # ffffffffc0207360 <default_pmm_manager+0xe28>
ffffffffc0204fa0:	00001617          	auipc	a2,0x1
ffffffffc0204fa4:	fb860613          	addi	a2,a2,-72 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc0204fa8:	40e00593          	li	a1,1038
ffffffffc0204fac:	00002517          	auipc	a0,0x2
ffffffffc0204fb0:	ffc50513          	addi	a0,a0,-4 # ffffffffc0206fa8 <default_pmm_manager+0xa70>
ffffffffc0204fb4:	cdafb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204fb8 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204fb8:	1141                	addi	sp,sp,-16
ffffffffc0204fba:	e022                	sd	s0,0(sp)
ffffffffc0204fbc:	e406                	sd	ra,8(sp)
ffffffffc0204fbe:	000a6417          	auipc	s0,0xa6
ffffffffc0204fc2:	93a40413          	addi	s0,s0,-1734 # ffffffffc02aa8f8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204fc6:	6018                	ld	a4,0(s0)
ffffffffc0204fc8:	6f1c                	ld	a5,24(a4)
ffffffffc0204fca:	dffd                	beqz	a5,ffffffffc0204fc8 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204fcc:	0f0000ef          	jal	ra,ffffffffc02050bc <schedule>
ffffffffc0204fd0:	bfdd                	j	ffffffffc0204fc6 <cpu_idle+0xe>

ffffffffc0204fd2 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204fd2:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204fd6:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204fda:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204fdc:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204fde:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204fe2:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204fe6:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204fea:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204fee:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204ff2:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204ff6:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204ffa:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204ffe:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205002:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205006:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020500a:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020500e:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205010:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205012:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205016:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020501a:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020501e:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205022:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205026:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020502a:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020502e:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205032:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205036:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020503a:	8082                	ret

ffffffffc020503c <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020503c:	4118                	lw	a4,0(a0)
{
ffffffffc020503e:	1101                	addi	sp,sp,-32
ffffffffc0205040:	ec06                	sd	ra,24(sp)
ffffffffc0205042:	e822                	sd	s0,16(sp)
ffffffffc0205044:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205046:	478d                	li	a5,3
ffffffffc0205048:	04f70b63          	beq	a4,a5,ffffffffc020509e <wakeup_proc+0x62>
ffffffffc020504c:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020504e:	100027f3          	csrr	a5,sstatus
ffffffffc0205052:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205054:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205056:	ef9d                	bnez	a5,ffffffffc0205094 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205058:	4789                	li	a5,2
ffffffffc020505a:	02f70163          	beq	a4,a5,ffffffffc020507c <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc020505e:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205060:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc0205064:	e491                	bnez	s1,ffffffffc0205070 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205066:	60e2                	ld	ra,24(sp)
ffffffffc0205068:	6442                	ld	s0,16(sp)
ffffffffc020506a:	64a2                	ld	s1,8(sp)
ffffffffc020506c:	6105                	addi	sp,sp,32
ffffffffc020506e:	8082                	ret
ffffffffc0205070:	6442                	ld	s0,16(sp)
ffffffffc0205072:	60e2                	ld	ra,24(sp)
ffffffffc0205074:	64a2                	ld	s1,8(sp)
ffffffffc0205076:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205078:	937fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc020507c:	00002617          	auipc	a2,0x2
ffffffffc0205080:	36c60613          	addi	a2,a2,876 # ffffffffc02073e8 <default_pmm_manager+0xeb0>
ffffffffc0205084:	45d1                	li	a1,20
ffffffffc0205086:	00002517          	auipc	a0,0x2
ffffffffc020508a:	34a50513          	addi	a0,a0,842 # ffffffffc02073d0 <default_pmm_manager+0xe98>
ffffffffc020508e:	c68fb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205092:	bfc9                	j	ffffffffc0205064 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205094:	921fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205098:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020509a:	4485                	li	s1,1
ffffffffc020509c:	bf75                	j	ffffffffc0205058 <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020509e:	00002697          	auipc	a3,0x2
ffffffffc02050a2:	31268693          	addi	a3,a3,786 # ffffffffc02073b0 <default_pmm_manager+0xe78>
ffffffffc02050a6:	00001617          	auipc	a2,0x1
ffffffffc02050aa:	eb260613          	addi	a2,a2,-334 # ffffffffc0205f58 <commands+0x5f8>
ffffffffc02050ae:	45a5                	li	a1,9
ffffffffc02050b0:	00002517          	auipc	a0,0x2
ffffffffc02050b4:	32050513          	addi	a0,a0,800 # ffffffffc02073d0 <default_pmm_manager+0xe98>
ffffffffc02050b8:	bd6fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02050bc <schedule>:

void schedule(void)
{
ffffffffc02050bc:	1141                	addi	sp,sp,-16
ffffffffc02050be:	e406                	sd	ra,8(sp)
ffffffffc02050c0:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02050c2:	100027f3          	csrr	a5,sstatus
ffffffffc02050c6:	8b89                	andi	a5,a5,2
ffffffffc02050c8:	4401                	li	s0,0
ffffffffc02050ca:	efbd                	bnez	a5,ffffffffc0205148 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02050cc:	000a6897          	auipc	a7,0xa6
ffffffffc02050d0:	82c8b883          	ld	a7,-2004(a7) # ffffffffc02aa8f8 <current>
ffffffffc02050d4:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02050d8:	000a6517          	auipc	a0,0xa6
ffffffffc02050dc:	82853503          	ld	a0,-2008(a0) # ffffffffc02aa900 <idleproc>
ffffffffc02050e0:	04a88e63          	beq	a7,a0,ffffffffc020513c <schedule+0x80>
ffffffffc02050e4:	0c888693          	addi	a3,a7,200
ffffffffc02050e8:	000a5617          	auipc	a2,0xa5
ffffffffc02050ec:	7a060613          	addi	a2,a2,1952 # ffffffffc02aa888 <proc_list>
        le = last;
ffffffffc02050f0:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02050f2:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02050f4:	4809                	li	a6,2
ffffffffc02050f6:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02050f8:	00c78863          	beq	a5,a2,ffffffffc0205108 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc02050fc:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205100:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205104:	03070163          	beq	a4,a6,ffffffffc0205126 <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc0205108:	fef697e3          	bne	a3,a5,ffffffffc02050f6 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020510c:	ed89                	bnez	a1,ffffffffc0205126 <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020510e:	451c                	lw	a5,8(a0)
ffffffffc0205110:	2785                	addiw	a5,a5,1
ffffffffc0205112:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205114:	00a88463          	beq	a7,a0,ffffffffc020511c <schedule+0x60>
        {
            proc_run(next);
ffffffffc0205118:	e2bfe0ef          	jal	ra,ffffffffc0203f42 <proc_run>
    if (flag)
ffffffffc020511c:	e819                	bnez	s0,ffffffffc0205132 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020511e:	60a2                	ld	ra,8(sp)
ffffffffc0205120:	6402                	ld	s0,0(sp)
ffffffffc0205122:	0141                	addi	sp,sp,16
ffffffffc0205124:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205126:	4198                	lw	a4,0(a1)
ffffffffc0205128:	4789                	li	a5,2
ffffffffc020512a:	fef712e3          	bne	a4,a5,ffffffffc020510e <schedule+0x52>
ffffffffc020512e:	852e                	mv	a0,a1
ffffffffc0205130:	bff9                	j	ffffffffc020510e <schedule+0x52>
}
ffffffffc0205132:	6402                	ld	s0,0(sp)
ffffffffc0205134:	60a2                	ld	ra,8(sp)
ffffffffc0205136:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0205138:	877fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020513c:	000a5617          	auipc	a2,0xa5
ffffffffc0205140:	74c60613          	addi	a2,a2,1868 # ffffffffc02aa888 <proc_list>
ffffffffc0205144:	86b2                	mv	a3,a2
ffffffffc0205146:	b76d                	j	ffffffffc02050f0 <schedule+0x34>
        intr_disable();
ffffffffc0205148:	86dfb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc020514c:	4405                	li	s0,1
ffffffffc020514e:	bfbd                	j	ffffffffc02050cc <schedule+0x10>

ffffffffc0205150 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205150:	000a5797          	auipc	a5,0xa5
ffffffffc0205154:	7a87b783          	ld	a5,1960(a5) # ffffffffc02aa8f8 <current>
}
ffffffffc0205158:	43c8                	lw	a0,4(a5)
ffffffffc020515a:	8082                	ret

ffffffffc020515c <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc020515c:	4501                	li	a0,0
ffffffffc020515e:	8082                	ret

ffffffffc0205160 <sys_putc>:
    cputchar(c);
ffffffffc0205160:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205162:	1141                	addi	sp,sp,-16
ffffffffc0205164:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205166:	864fb0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc020516a:	60a2                	ld	ra,8(sp)
ffffffffc020516c:	4501                	li	a0,0
ffffffffc020516e:	0141                	addi	sp,sp,16
ffffffffc0205170:	8082                	ret

ffffffffc0205172 <sys_kill>:
    return do_kill(pid);
ffffffffc0205172:	4108                	lw	a0,0(a0)
ffffffffc0205174:	c31ff06f          	j	ffffffffc0204da4 <do_kill>

ffffffffc0205178 <sys_yield>:
    return do_yield();
ffffffffc0205178:	bdfff06f          	j	ffffffffc0204d56 <do_yield>

ffffffffc020517c <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc020517c:	6d14                	ld	a3,24(a0)
ffffffffc020517e:	6910                	ld	a2,16(a0)
ffffffffc0205180:	650c                	ld	a1,8(a0)
ffffffffc0205182:	6108                	ld	a0,0(a0)
ffffffffc0205184:	ebeff06f          	j	ffffffffc0204842 <do_execve>

ffffffffc0205188 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205188:	650c                	ld	a1,8(a0)
ffffffffc020518a:	4108                	lw	a0,0(a0)
ffffffffc020518c:	bdbff06f          	j	ffffffffc0204d66 <do_wait>

ffffffffc0205190 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205190:	000a5797          	auipc	a5,0xa5
ffffffffc0205194:	7687b783          	ld	a5,1896(a5) # ffffffffc02aa8f8 <current>
ffffffffc0205198:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020519a:	4501                	li	a0,0
ffffffffc020519c:	6a0c                	ld	a1,16(a2)
ffffffffc020519e:	e11fe06f          	j	ffffffffc0203fae <do_fork>

ffffffffc02051a2 <sys_exit>:
    return do_exit(error_code);
ffffffffc02051a2:	4108                	lw	a0,0(a0)
ffffffffc02051a4:	a5eff06f          	j	ffffffffc0204402 <do_exit>

ffffffffc02051a8 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02051a8:	715d                	addi	sp,sp,-80
ffffffffc02051aa:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02051ac:	000a5497          	auipc	s1,0xa5
ffffffffc02051b0:	74c48493          	addi	s1,s1,1868 # ffffffffc02aa8f8 <current>
ffffffffc02051b4:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02051b6:	e0a2                	sd	s0,64(sp)
ffffffffc02051b8:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02051ba:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02051bc:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02051be:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02051c0:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02051c4:	0327ee63          	bltu	a5,s2,ffffffffc0205200 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc02051c8:	00391713          	slli	a4,s2,0x3
ffffffffc02051cc:	00002797          	auipc	a5,0x2
ffffffffc02051d0:	28478793          	addi	a5,a5,644 # ffffffffc0207450 <syscalls>
ffffffffc02051d4:	97ba                	add	a5,a5,a4
ffffffffc02051d6:	639c                	ld	a5,0(a5)
ffffffffc02051d8:	c785                	beqz	a5,ffffffffc0205200 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc02051da:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02051dc:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02051de:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02051e0:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02051e2:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02051e4:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02051e6:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02051e8:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02051ea:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02051ec:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02051ee:	0028                	addi	a0,sp,8
ffffffffc02051f0:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02051f2:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02051f4:	e828                	sd	a0,80(s0)
}
ffffffffc02051f6:	6406                	ld	s0,64(sp)
ffffffffc02051f8:	74e2                	ld	s1,56(sp)
ffffffffc02051fa:	7942                	ld	s2,48(sp)
ffffffffc02051fc:	6161                	addi	sp,sp,80
ffffffffc02051fe:	8082                	ret
    print_trapframe(tf);
ffffffffc0205200:	8522                	mv	a0,s0
ffffffffc0205202:	9a3fb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205206:	609c                	ld	a5,0(s1)
ffffffffc0205208:	86ca                	mv	a3,s2
ffffffffc020520a:	00002617          	auipc	a2,0x2
ffffffffc020520e:	1fe60613          	addi	a2,a2,510 # ffffffffc0207408 <default_pmm_manager+0xed0>
ffffffffc0205212:	43d8                	lw	a4,4(a5)
ffffffffc0205214:	06200593          	li	a1,98
ffffffffc0205218:	0b478793          	addi	a5,a5,180
ffffffffc020521c:	00002517          	auipc	a0,0x2
ffffffffc0205220:	21c50513          	addi	a0,a0,540 # ffffffffc0207438 <default_pmm_manager+0xf00>
ffffffffc0205224:	a6afb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205228 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205228:	9e3707b7          	lui	a5,0x9e370
ffffffffc020522c:	2785                	addiw	a5,a5,1
ffffffffc020522e:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205232:	02000793          	li	a5,32
ffffffffc0205236:	9f8d                	subw	a5,a5,a1
}
ffffffffc0205238:	00f5553b          	srlw	a0,a0,a5
ffffffffc020523c:	8082                	ret

ffffffffc020523e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020523e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205242:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205244:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205248:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020524a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020524e:	f022                	sd	s0,32(sp)
ffffffffc0205250:	ec26                	sd	s1,24(sp)
ffffffffc0205252:	e84a                	sd	s2,16(sp)
ffffffffc0205254:	f406                	sd	ra,40(sp)
ffffffffc0205256:	e44e                	sd	s3,8(sp)
ffffffffc0205258:	84aa                	mv	s1,a0
ffffffffc020525a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020525c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205260:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205262:	03067e63          	bgeu	a2,a6,ffffffffc020529e <printnum+0x60>
ffffffffc0205266:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205268:	00805763          	blez	s0,ffffffffc0205276 <printnum+0x38>
ffffffffc020526c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020526e:	85ca                	mv	a1,s2
ffffffffc0205270:	854e                	mv	a0,s3
ffffffffc0205272:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205274:	fc65                	bnez	s0,ffffffffc020526c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205276:	1a02                	slli	s4,s4,0x20
ffffffffc0205278:	00002797          	auipc	a5,0x2
ffffffffc020527c:	2d878793          	addi	a5,a5,728 # ffffffffc0207550 <syscalls+0x100>
ffffffffc0205280:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205284:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205286:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205288:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020528c:	70a2                	ld	ra,40(sp)
ffffffffc020528e:	69a2                	ld	s3,8(sp)
ffffffffc0205290:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205292:	85ca                	mv	a1,s2
ffffffffc0205294:	87a6                	mv	a5,s1
}
ffffffffc0205296:	6942                	ld	s2,16(sp)
ffffffffc0205298:	64e2                	ld	s1,24(sp)
ffffffffc020529a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020529c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020529e:	03065633          	divu	a2,a2,a6
ffffffffc02052a2:	8722                	mv	a4,s0
ffffffffc02052a4:	f9bff0ef          	jal	ra,ffffffffc020523e <printnum>
ffffffffc02052a8:	b7f9                	j	ffffffffc0205276 <printnum+0x38>

ffffffffc02052aa <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02052aa:	7119                	addi	sp,sp,-128
ffffffffc02052ac:	f4a6                	sd	s1,104(sp)
ffffffffc02052ae:	f0ca                	sd	s2,96(sp)
ffffffffc02052b0:	ecce                	sd	s3,88(sp)
ffffffffc02052b2:	e8d2                	sd	s4,80(sp)
ffffffffc02052b4:	e4d6                	sd	s5,72(sp)
ffffffffc02052b6:	e0da                	sd	s6,64(sp)
ffffffffc02052b8:	fc5e                	sd	s7,56(sp)
ffffffffc02052ba:	f06a                	sd	s10,32(sp)
ffffffffc02052bc:	fc86                	sd	ra,120(sp)
ffffffffc02052be:	f8a2                	sd	s0,112(sp)
ffffffffc02052c0:	f862                	sd	s8,48(sp)
ffffffffc02052c2:	f466                	sd	s9,40(sp)
ffffffffc02052c4:	ec6e                	sd	s11,24(sp)
ffffffffc02052c6:	892a                	mv	s2,a0
ffffffffc02052c8:	84ae                	mv	s1,a1
ffffffffc02052ca:	8d32                	mv	s10,a2
ffffffffc02052cc:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052ce:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02052d2:	5b7d                	li	s6,-1
ffffffffc02052d4:	00002a97          	auipc	s5,0x2
ffffffffc02052d8:	2a8a8a93          	addi	s5,s5,680 # ffffffffc020757c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02052dc:	00002b97          	auipc	s7,0x2
ffffffffc02052e0:	4bcb8b93          	addi	s7,s7,1212 # ffffffffc0207798 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052e4:	000d4503          	lbu	a0,0(s10)
ffffffffc02052e8:	001d0413          	addi	s0,s10,1
ffffffffc02052ec:	01350a63          	beq	a0,s3,ffffffffc0205300 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02052f0:	c121                	beqz	a0,ffffffffc0205330 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02052f2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052f4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02052f6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02052f8:	fff44503          	lbu	a0,-1(s0)
ffffffffc02052fc:	ff351ae3          	bne	a0,s3,ffffffffc02052f0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205300:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0205304:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0205308:	4c81                	li	s9,0
ffffffffc020530a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020530c:	5c7d                	li	s8,-1
ffffffffc020530e:	5dfd                	li	s11,-1
ffffffffc0205310:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205314:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205316:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020531a:	0ff5f593          	zext.b	a1,a1
ffffffffc020531e:	00140d13          	addi	s10,s0,1
ffffffffc0205322:	04b56263          	bltu	a0,a1,ffffffffc0205366 <vprintfmt+0xbc>
ffffffffc0205326:	058a                	slli	a1,a1,0x2
ffffffffc0205328:	95d6                	add	a1,a1,s5
ffffffffc020532a:	4194                	lw	a3,0(a1)
ffffffffc020532c:	96d6                	add	a3,a3,s5
ffffffffc020532e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205330:	70e6                	ld	ra,120(sp)
ffffffffc0205332:	7446                	ld	s0,112(sp)
ffffffffc0205334:	74a6                	ld	s1,104(sp)
ffffffffc0205336:	7906                	ld	s2,96(sp)
ffffffffc0205338:	69e6                	ld	s3,88(sp)
ffffffffc020533a:	6a46                	ld	s4,80(sp)
ffffffffc020533c:	6aa6                	ld	s5,72(sp)
ffffffffc020533e:	6b06                	ld	s6,64(sp)
ffffffffc0205340:	7be2                	ld	s7,56(sp)
ffffffffc0205342:	7c42                	ld	s8,48(sp)
ffffffffc0205344:	7ca2                	ld	s9,40(sp)
ffffffffc0205346:	7d02                	ld	s10,32(sp)
ffffffffc0205348:	6de2                	ld	s11,24(sp)
ffffffffc020534a:	6109                	addi	sp,sp,128
ffffffffc020534c:	8082                	ret
            padc = '0';
ffffffffc020534e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205350:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205354:	846a                	mv	s0,s10
ffffffffc0205356:	00140d13          	addi	s10,s0,1
ffffffffc020535a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020535e:	0ff5f593          	zext.b	a1,a1
ffffffffc0205362:	fcb572e3          	bgeu	a0,a1,ffffffffc0205326 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0205366:	85a6                	mv	a1,s1
ffffffffc0205368:	02500513          	li	a0,37
ffffffffc020536c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020536e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205372:	8d22                	mv	s10,s0
ffffffffc0205374:	f73788e3          	beq	a5,s3,ffffffffc02052e4 <vprintfmt+0x3a>
ffffffffc0205378:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020537c:	1d7d                	addi	s10,s10,-1
ffffffffc020537e:	ff379de3          	bne	a5,s3,ffffffffc0205378 <vprintfmt+0xce>
ffffffffc0205382:	b78d                	j	ffffffffc02052e4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205384:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205388:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020538c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020538e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205392:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205396:	02d86463          	bltu	a6,a3,ffffffffc02053be <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020539a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020539e:	002c169b          	slliw	a3,s8,0x2
ffffffffc02053a2:	0186873b          	addw	a4,a3,s8
ffffffffc02053a6:	0017171b          	slliw	a4,a4,0x1
ffffffffc02053aa:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02053ac:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02053b0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02053b2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02053b6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02053ba:	fed870e3          	bgeu	a6,a3,ffffffffc020539a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02053be:	f40ddce3          	bgez	s11,ffffffffc0205316 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02053c2:	8de2                	mv	s11,s8
ffffffffc02053c4:	5c7d                	li	s8,-1
ffffffffc02053c6:	bf81                	j	ffffffffc0205316 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02053c8:	fffdc693          	not	a3,s11
ffffffffc02053cc:	96fd                	srai	a3,a3,0x3f
ffffffffc02053ce:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053d2:	00144603          	lbu	a2,1(s0)
ffffffffc02053d6:	2d81                	sext.w	s11,s11
ffffffffc02053d8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02053da:	bf35                	j	ffffffffc0205316 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02053dc:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053e0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02053e4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053e6:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02053e8:	bfd9                	j	ffffffffc02053be <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02053ea:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02053ec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02053f0:	01174463          	blt	a4,a7,ffffffffc02053f8 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02053f4:	1a088e63          	beqz	a7,ffffffffc02055b0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02053f8:	000a3603          	ld	a2,0(s4)
ffffffffc02053fc:	46c1                	li	a3,16
ffffffffc02053fe:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205400:	2781                	sext.w	a5,a5
ffffffffc0205402:	876e                	mv	a4,s11
ffffffffc0205404:	85a6                	mv	a1,s1
ffffffffc0205406:	854a                	mv	a0,s2
ffffffffc0205408:	e37ff0ef          	jal	ra,ffffffffc020523e <printnum>
            break;
ffffffffc020540c:	bde1                	j	ffffffffc02052e4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020540e:	000a2503          	lw	a0,0(s4)
ffffffffc0205412:	85a6                	mv	a1,s1
ffffffffc0205414:	0a21                	addi	s4,s4,8
ffffffffc0205416:	9902                	jalr	s2
            break;
ffffffffc0205418:	b5f1                	j	ffffffffc02052e4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020541a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020541c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205420:	01174463          	blt	a4,a7,ffffffffc0205428 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205424:	18088163          	beqz	a7,ffffffffc02055a6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205428:	000a3603          	ld	a2,0(s4)
ffffffffc020542c:	46a9                	li	a3,10
ffffffffc020542e:	8a2e                	mv	s4,a1
ffffffffc0205430:	bfc1                	j	ffffffffc0205400 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205432:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0205436:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205438:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020543a:	bdf1                	j	ffffffffc0205316 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020543c:	85a6                	mv	a1,s1
ffffffffc020543e:	02500513          	li	a0,37
ffffffffc0205442:	9902                	jalr	s2
            break;
ffffffffc0205444:	b545                	j	ffffffffc02052e4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205446:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020544a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020544c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020544e:	b5e1                	j	ffffffffc0205316 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205450:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205452:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205456:	01174463          	blt	a4,a7,ffffffffc020545e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020545a:	14088163          	beqz	a7,ffffffffc020559c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020545e:	000a3603          	ld	a2,0(s4)
ffffffffc0205462:	46a1                	li	a3,8
ffffffffc0205464:	8a2e                	mv	s4,a1
ffffffffc0205466:	bf69                	j	ffffffffc0205400 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205468:	03000513          	li	a0,48
ffffffffc020546c:	85a6                	mv	a1,s1
ffffffffc020546e:	e03e                	sd	a5,0(sp)
ffffffffc0205470:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205472:	85a6                	mv	a1,s1
ffffffffc0205474:	07800513          	li	a0,120
ffffffffc0205478:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020547a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020547c:	6782                	ld	a5,0(sp)
ffffffffc020547e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205480:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205484:	bfb5                	j	ffffffffc0205400 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205486:	000a3403          	ld	s0,0(s4)
ffffffffc020548a:	008a0713          	addi	a4,s4,8
ffffffffc020548e:	e03a                	sd	a4,0(sp)
ffffffffc0205490:	14040263          	beqz	s0,ffffffffc02055d4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205494:	0fb05763          	blez	s11,ffffffffc0205582 <vprintfmt+0x2d8>
ffffffffc0205498:	02d00693          	li	a3,45
ffffffffc020549c:	0cd79163          	bne	a5,a3,ffffffffc020555e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02054a0:	00044783          	lbu	a5,0(s0)
ffffffffc02054a4:	0007851b          	sext.w	a0,a5
ffffffffc02054a8:	cf85                	beqz	a5,ffffffffc02054e0 <vprintfmt+0x236>
ffffffffc02054aa:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02054ae:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02054b2:	000c4563          	bltz	s8,ffffffffc02054bc <vprintfmt+0x212>
ffffffffc02054b6:	3c7d                	addiw	s8,s8,-1
ffffffffc02054b8:	036c0263          	beq	s8,s6,ffffffffc02054dc <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02054bc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02054be:	0e0c8e63          	beqz	s9,ffffffffc02055ba <vprintfmt+0x310>
ffffffffc02054c2:	3781                	addiw	a5,a5,-32
ffffffffc02054c4:	0ef47b63          	bgeu	s0,a5,ffffffffc02055ba <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02054c8:	03f00513          	li	a0,63
ffffffffc02054cc:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02054ce:	000a4783          	lbu	a5,0(s4)
ffffffffc02054d2:	3dfd                	addiw	s11,s11,-1
ffffffffc02054d4:	0a05                	addi	s4,s4,1
ffffffffc02054d6:	0007851b          	sext.w	a0,a5
ffffffffc02054da:	ffe1                	bnez	a5,ffffffffc02054b2 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02054dc:	01b05963          	blez	s11,ffffffffc02054ee <vprintfmt+0x244>
ffffffffc02054e0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02054e2:	85a6                	mv	a1,s1
ffffffffc02054e4:	02000513          	li	a0,32
ffffffffc02054e8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02054ea:	fe0d9be3          	bnez	s11,ffffffffc02054e0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02054ee:	6a02                	ld	s4,0(sp)
ffffffffc02054f0:	bbd5                	j	ffffffffc02052e4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02054f2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02054f4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02054f8:	01174463          	blt	a4,a7,ffffffffc0205500 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02054fc:	08088d63          	beqz	a7,ffffffffc0205596 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205500:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205504:	0a044d63          	bltz	s0,ffffffffc02055be <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205508:	8622                	mv	a2,s0
ffffffffc020550a:	8a66                	mv	s4,s9
ffffffffc020550c:	46a9                	li	a3,10
ffffffffc020550e:	bdcd                	j	ffffffffc0205400 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205510:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205514:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205516:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205518:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020551c:	8fb5                	xor	a5,a5,a3
ffffffffc020551e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205522:	02d74163          	blt	a4,a3,ffffffffc0205544 <vprintfmt+0x29a>
ffffffffc0205526:	00369793          	slli	a5,a3,0x3
ffffffffc020552a:	97de                	add	a5,a5,s7
ffffffffc020552c:	639c                	ld	a5,0(a5)
ffffffffc020552e:	cb99                	beqz	a5,ffffffffc0205544 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205530:	86be                	mv	a3,a5
ffffffffc0205532:	00000617          	auipc	a2,0x0
ffffffffc0205536:	1ee60613          	addi	a2,a2,494 # ffffffffc0205720 <etext+0x28>
ffffffffc020553a:	85a6                	mv	a1,s1
ffffffffc020553c:	854a                	mv	a0,s2
ffffffffc020553e:	0ce000ef          	jal	ra,ffffffffc020560c <printfmt>
ffffffffc0205542:	b34d                	j	ffffffffc02052e4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205544:	00002617          	auipc	a2,0x2
ffffffffc0205548:	02c60613          	addi	a2,a2,44 # ffffffffc0207570 <syscalls+0x120>
ffffffffc020554c:	85a6                	mv	a1,s1
ffffffffc020554e:	854a                	mv	a0,s2
ffffffffc0205550:	0bc000ef          	jal	ra,ffffffffc020560c <printfmt>
ffffffffc0205554:	bb41                	j	ffffffffc02052e4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205556:	00002417          	auipc	s0,0x2
ffffffffc020555a:	01240413          	addi	s0,s0,18 # ffffffffc0207568 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020555e:	85e2                	mv	a1,s8
ffffffffc0205560:	8522                	mv	a0,s0
ffffffffc0205562:	e43e                	sd	a5,8(sp)
ffffffffc0205564:	0e2000ef          	jal	ra,ffffffffc0205646 <strnlen>
ffffffffc0205568:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020556c:	01b05b63          	blez	s11,ffffffffc0205582 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205570:	67a2                	ld	a5,8(sp)
ffffffffc0205572:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205576:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205578:	85a6                	mv	a1,s1
ffffffffc020557a:	8552                	mv	a0,s4
ffffffffc020557c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020557e:	fe0d9ce3          	bnez	s11,ffffffffc0205576 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205582:	00044783          	lbu	a5,0(s0)
ffffffffc0205586:	00140a13          	addi	s4,s0,1
ffffffffc020558a:	0007851b          	sext.w	a0,a5
ffffffffc020558e:	d3a5                	beqz	a5,ffffffffc02054ee <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205590:	05e00413          	li	s0,94
ffffffffc0205594:	bf39                	j	ffffffffc02054b2 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205596:	000a2403          	lw	s0,0(s4)
ffffffffc020559a:	b7ad                	j	ffffffffc0205504 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020559c:	000a6603          	lwu	a2,0(s4)
ffffffffc02055a0:	46a1                	li	a3,8
ffffffffc02055a2:	8a2e                	mv	s4,a1
ffffffffc02055a4:	bdb1                	j	ffffffffc0205400 <vprintfmt+0x156>
ffffffffc02055a6:	000a6603          	lwu	a2,0(s4)
ffffffffc02055aa:	46a9                	li	a3,10
ffffffffc02055ac:	8a2e                	mv	s4,a1
ffffffffc02055ae:	bd89                	j	ffffffffc0205400 <vprintfmt+0x156>
ffffffffc02055b0:	000a6603          	lwu	a2,0(s4)
ffffffffc02055b4:	46c1                	li	a3,16
ffffffffc02055b6:	8a2e                	mv	s4,a1
ffffffffc02055b8:	b5a1                	j	ffffffffc0205400 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02055ba:	9902                	jalr	s2
ffffffffc02055bc:	bf09                	j	ffffffffc02054ce <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02055be:	85a6                	mv	a1,s1
ffffffffc02055c0:	02d00513          	li	a0,45
ffffffffc02055c4:	e03e                	sd	a5,0(sp)
ffffffffc02055c6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02055c8:	6782                	ld	a5,0(sp)
ffffffffc02055ca:	8a66                	mv	s4,s9
ffffffffc02055cc:	40800633          	neg	a2,s0
ffffffffc02055d0:	46a9                	li	a3,10
ffffffffc02055d2:	b53d                	j	ffffffffc0205400 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02055d4:	03b05163          	blez	s11,ffffffffc02055f6 <vprintfmt+0x34c>
ffffffffc02055d8:	02d00693          	li	a3,45
ffffffffc02055dc:	f6d79de3          	bne	a5,a3,ffffffffc0205556 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02055e0:	00002417          	auipc	s0,0x2
ffffffffc02055e4:	f8840413          	addi	s0,s0,-120 # ffffffffc0207568 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055e8:	02800793          	li	a5,40
ffffffffc02055ec:	02800513          	li	a0,40
ffffffffc02055f0:	00140a13          	addi	s4,s0,1
ffffffffc02055f4:	bd6d                	j	ffffffffc02054ae <vprintfmt+0x204>
ffffffffc02055f6:	00002a17          	auipc	s4,0x2
ffffffffc02055fa:	f73a0a13          	addi	s4,s4,-141 # ffffffffc0207569 <syscalls+0x119>
ffffffffc02055fe:	02800513          	li	a0,40
ffffffffc0205602:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205606:	05e00413          	li	s0,94
ffffffffc020560a:	b565                	j	ffffffffc02054b2 <vprintfmt+0x208>

ffffffffc020560c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020560c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020560e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205612:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205614:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205616:	ec06                	sd	ra,24(sp)
ffffffffc0205618:	f83a                	sd	a4,48(sp)
ffffffffc020561a:	fc3e                	sd	a5,56(sp)
ffffffffc020561c:	e0c2                	sd	a6,64(sp)
ffffffffc020561e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205620:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205622:	c89ff0ef          	jal	ra,ffffffffc02052aa <vprintfmt>
}
ffffffffc0205626:	60e2                	ld	ra,24(sp)
ffffffffc0205628:	6161                	addi	sp,sp,80
ffffffffc020562a:	8082                	ret

ffffffffc020562c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020562c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205630:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205632:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205634:	cb81                	beqz	a5,ffffffffc0205644 <strlen+0x18>
        cnt ++;
ffffffffc0205636:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205638:	00a707b3          	add	a5,a4,a0
ffffffffc020563c:	0007c783          	lbu	a5,0(a5)
ffffffffc0205640:	fbfd                	bnez	a5,ffffffffc0205636 <strlen+0xa>
ffffffffc0205642:	8082                	ret
    }
    return cnt;
}
ffffffffc0205644:	8082                	ret

ffffffffc0205646 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205646:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205648:	e589                	bnez	a1,ffffffffc0205652 <strnlen+0xc>
ffffffffc020564a:	a811                	j	ffffffffc020565e <strnlen+0x18>
        cnt ++;
ffffffffc020564c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020564e:	00f58863          	beq	a1,a5,ffffffffc020565e <strnlen+0x18>
ffffffffc0205652:	00f50733          	add	a4,a0,a5
ffffffffc0205656:	00074703          	lbu	a4,0(a4)
ffffffffc020565a:	fb6d                	bnez	a4,ffffffffc020564c <strnlen+0x6>
ffffffffc020565c:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020565e:	852e                	mv	a0,a1
ffffffffc0205660:	8082                	ret

ffffffffc0205662 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205662:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205664:	0005c703          	lbu	a4,0(a1)
ffffffffc0205668:	0785                	addi	a5,a5,1
ffffffffc020566a:	0585                	addi	a1,a1,1
ffffffffc020566c:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205670:	fb75                	bnez	a4,ffffffffc0205664 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205672:	8082                	ret

ffffffffc0205674 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205674:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205678:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020567c:	cb89                	beqz	a5,ffffffffc020568e <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020567e:	0505                	addi	a0,a0,1
ffffffffc0205680:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205682:	fee789e3          	beq	a5,a4,ffffffffc0205674 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205686:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020568a:	9d19                	subw	a0,a0,a4
ffffffffc020568c:	8082                	ret
ffffffffc020568e:	4501                	li	a0,0
ffffffffc0205690:	bfed                	j	ffffffffc020568a <strcmp+0x16>

ffffffffc0205692 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205692:	c20d                	beqz	a2,ffffffffc02056b4 <strncmp+0x22>
ffffffffc0205694:	962e                	add	a2,a2,a1
ffffffffc0205696:	a031                	j	ffffffffc02056a2 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205698:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020569a:	00e79a63          	bne	a5,a4,ffffffffc02056ae <strncmp+0x1c>
ffffffffc020569e:	00b60b63          	beq	a2,a1,ffffffffc02056b4 <strncmp+0x22>
ffffffffc02056a2:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02056a6:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02056a8:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02056ac:	f7f5                	bnez	a5,ffffffffc0205698 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02056ae:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02056b2:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02056b4:	4501                	li	a0,0
ffffffffc02056b6:	8082                	ret

ffffffffc02056b8 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02056b8:	00054783          	lbu	a5,0(a0)
ffffffffc02056bc:	c799                	beqz	a5,ffffffffc02056ca <strchr+0x12>
        if (*s == c) {
ffffffffc02056be:	00f58763          	beq	a1,a5,ffffffffc02056cc <strchr+0x14>
    while (*s != '\0') {
ffffffffc02056c2:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02056c6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02056c8:	fbfd                	bnez	a5,ffffffffc02056be <strchr+0x6>
    }
    return NULL;
ffffffffc02056ca:	4501                	li	a0,0
}
ffffffffc02056cc:	8082                	ret

ffffffffc02056ce <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02056ce:	ca01                	beqz	a2,ffffffffc02056de <memset+0x10>
ffffffffc02056d0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02056d2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02056d4:	0785                	addi	a5,a5,1
ffffffffc02056d6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02056da:	fec79de3          	bne	a5,a2,ffffffffc02056d4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02056de:	8082                	ret

ffffffffc02056e0 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02056e0:	ca19                	beqz	a2,ffffffffc02056f6 <memcpy+0x16>
ffffffffc02056e2:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02056e4:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02056e6:	0005c703          	lbu	a4,0(a1)
ffffffffc02056ea:	0585                	addi	a1,a1,1
ffffffffc02056ec:	0785                	addi	a5,a5,1
ffffffffc02056ee:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02056f2:	fec59ae3          	bne	a1,a2,ffffffffc02056e6 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02056f6:	8082                	ret
