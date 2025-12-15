
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000c297          	auipc	t0,0xc
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020c000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000c297          	auipc	t0,0xc
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020c008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020b2b7          	lui	t0,0xc020b
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
ffffffffc020003c:	c020b137          	lui	sp,0xc020b

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
ffffffffc020004a:	000d6517          	auipc	a0,0xd6
ffffffffc020004e:	10250513          	addi	a0,a0,258 # ffffffffc02d614c <edata>
ffffffffc0200052:	000da617          	auipc	a2,0xda
ffffffffc0200056:	5a260613          	addi	a2,a2,1442 # ffffffffc02da5f4 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	461050ef          	jal	ra,ffffffffc0205cc2 <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	c8258593          	addi	a1,a1,-894 # ffffffffc0205cf0 <etext+0x4>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	c9a50513          	addi	a0,a0,-870 # ffffffffc0205d10 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	6f4020ef          	jal	ra,ffffffffc020277a <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	37b030ef          	jal	ra,ffffffffc0203c0c <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	37e050ef          	jal	ra,ffffffffc0205414 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	50a050ef          	jal	ra,ffffffffc02055ac <cpu_idle>

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
ffffffffc02000bc:	00006517          	auipc	a0,0x6
ffffffffc02000c0:	c5c50513          	addi	a0,a0,-932 # ffffffffc0205d18 <etext+0x2c>
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
ffffffffc02000d2:	000d6b97          	auipc	s7,0xd6
ffffffffc02000d6:	07eb8b93          	addi	s7,s7,126 # ffffffffc02d6150 <buf>
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
ffffffffc020012e:	000d6517          	auipc	a0,0xd6
ffffffffc0200132:	02250513          	addi	a0,a0,34 # ffffffffc02d6150 <buf>
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
ffffffffc0200188:	716050ef          	jal	ra,ffffffffc020589e <vprintfmt>
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
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
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
ffffffffc02001be:	6e0050ef          	jal	ra,ffffffffc020589e <vprintfmt>
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
ffffffffc020021e:	00006517          	auipc	a0,0x6
ffffffffc0200222:	b0250513          	addi	a0,a0,-1278 # ffffffffc0205d20 <etext+0x34>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00006517          	auipc	a0,0x6
ffffffffc0200238:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0205d40 <etext+0x54>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00006597          	auipc	a1,0x6
ffffffffc0200244:	aac58593          	addi	a1,a1,-1364 # ffffffffc0205cec <etext>
ffffffffc0200248:	00006517          	auipc	a0,0x6
ffffffffc020024c:	b1850513          	addi	a0,a0,-1256 # ffffffffc0205d60 <etext+0x74>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000d6597          	auipc	a1,0xd6
ffffffffc0200258:	ef858593          	addi	a1,a1,-264 # ffffffffc02d614c <edata>
ffffffffc020025c:	00006517          	auipc	a0,0x6
ffffffffc0200260:	b2450513          	addi	a0,a0,-1244 # ffffffffc0205d80 <etext+0x94>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000da597          	auipc	a1,0xda
ffffffffc020026c:	38c58593          	addi	a1,a1,908 # ffffffffc02da5f4 <end>
ffffffffc0200270:	00006517          	auipc	a0,0x6
ffffffffc0200274:	b3050513          	addi	a0,a0,-1232 # ffffffffc0205da0 <etext+0xb4>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000da597          	auipc	a1,0xda
ffffffffc0200280:	77758593          	addi	a1,a1,1911 # ffffffffc02da9f3 <end+0x3ff>
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
ffffffffc020029e:	00006517          	auipc	a0,0x6
ffffffffc02002a2:	b2250513          	addi	a0,a0,-1246 # ffffffffc0205dc0 <etext+0xd4>
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
ffffffffc02002ac:	00006617          	auipc	a2,0x6
ffffffffc02002b0:	b4460613          	addi	a2,a2,-1212 # ffffffffc0205df0 <etext+0x104>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00006517          	auipc	a0,0x6
ffffffffc02002bc:	b5050513          	addi	a0,a0,-1200 # ffffffffc0205e08 <etext+0x11c>
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
ffffffffc02002c8:	00006617          	auipc	a2,0x6
ffffffffc02002cc:	b5860613          	addi	a2,a2,-1192 # ffffffffc0205e20 <etext+0x134>
ffffffffc02002d0:	00006597          	auipc	a1,0x6
ffffffffc02002d4:	b7058593          	addi	a1,a1,-1168 # ffffffffc0205e40 <etext+0x154>
ffffffffc02002d8:	00006517          	auipc	a0,0x6
ffffffffc02002dc:	b7050513          	addi	a0,a0,-1168 # ffffffffc0205e48 <etext+0x15c>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00006617          	auipc	a2,0x6
ffffffffc02002ea:	b7260613          	addi	a2,a2,-1166 # ffffffffc0205e58 <etext+0x16c>
ffffffffc02002ee:	00006597          	auipc	a1,0x6
ffffffffc02002f2:	b9258593          	addi	a1,a1,-1134 # ffffffffc0205e80 <etext+0x194>
ffffffffc02002f6:	00006517          	auipc	a0,0x6
ffffffffc02002fa:	b5250513          	addi	a0,a0,-1198 # ffffffffc0205e48 <etext+0x15c>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00006617          	auipc	a2,0x6
ffffffffc0200306:	b8e60613          	addi	a2,a2,-1138 # ffffffffc0205e90 <etext+0x1a4>
ffffffffc020030a:	00006597          	auipc	a1,0x6
ffffffffc020030e:	ba658593          	addi	a1,a1,-1114 # ffffffffc0205eb0 <etext+0x1c4>
ffffffffc0200312:	00006517          	auipc	a0,0x6
ffffffffc0200316:	b3650513          	addi	a0,a0,-1226 # ffffffffc0205e48 <etext+0x15c>
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
ffffffffc020034c:	00006517          	auipc	a0,0x6
ffffffffc0200350:	b7450513          	addi	a0,a0,-1164 # ffffffffc0205ec0 <etext+0x1d4>
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
ffffffffc020036e:	00006517          	auipc	a0,0x6
ffffffffc0200372:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0205ee8 <etext+0x1fc>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00006c17          	auipc	s8,0x6
ffffffffc0200388:	bd4c0c13          	addi	s8,s8,-1068 # ffffffffc0205f58 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00006917          	auipc	s2,0x6
ffffffffc0200390:	b8490913          	addi	s2,s2,-1148 # ffffffffc0205f10 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00006497          	auipc	s1,0x6
ffffffffc0200398:	b8448493          	addi	s1,s1,-1148 # ffffffffc0205f18 <etext+0x22c>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00006b17          	auipc	s6,0x6
ffffffffc02003a2:	b82b0b13          	addi	s6,s6,-1150 # ffffffffc0205f20 <etext+0x234>
        argv[argc++] = buf;
ffffffffc02003a6:	00006a17          	auipc	s4,0x6
ffffffffc02003aa:	a9aa0a13          	addi	s4,s4,-1382 # ffffffffc0205e40 <etext+0x154>
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
ffffffffc02003c8:	00006d17          	auipc	s10,0x6
ffffffffc02003cc:	b90d0d13          	addi	s10,s10,-1136 # ffffffffc0205f58 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	093050ef          	jal	ra,ffffffffc0205c68 <strcmp>
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
ffffffffc02003ea:	07f050ef          	jal	ra,ffffffffc0205c68 <strcmp>
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
ffffffffc0200428:	085050ef          	jal	ra,ffffffffc0205cac <strchr>
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
ffffffffc0200466:	047050ef          	jal	ra,ffffffffc0205cac <strchr>
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
ffffffffc0200480:	00006517          	auipc	a0,0x6
ffffffffc0200484:	ac050513          	addi	a0,a0,-1344 # ffffffffc0205f40 <etext+0x254>
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
ffffffffc020048e:	000da317          	auipc	t1,0xda
ffffffffc0200492:	0ea30313          	addi	t1,t1,234 # ffffffffc02da578 <is_panic>
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
ffffffffc02004bc:	00006517          	auipc	a0,0x6
ffffffffc02004c0:	ae450513          	addi	a0,a0,-1308 # ffffffffc0205fa0 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00007517          	auipc	a0,0x7
ffffffffc02004d6:	c6650513          	addi	a0,a0,-922 # ffffffffc0207138 <default_pmm_manager+0x578>
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
ffffffffc0200506:	00006517          	auipc	a0,0x6
ffffffffc020050a:	aba50513          	addi	a0,a0,-1350 # ffffffffc0205fc0 <commands+0x68>
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
ffffffffc0200526:	00007517          	auipc	a0,0x7
ffffffffc020052a:	c1250513          	addi	a0,a0,-1006 # ffffffffc0207138 <default_pmm_manager+0x578>
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
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_cowtest_out_size+0x89b0>
ffffffffc0200540:	000da717          	auipc	a4,0xda
ffffffffc0200544:	04f73423          	sd	a5,72(a4) # ffffffffc02da588 <timebase>
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
ffffffffc0200560:	00006517          	auipc	a0,0x6
ffffffffc0200564:	a8050513          	addi	a0,a0,-1408 # ffffffffc0205fe0 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000da797          	auipc	a5,0xda
ffffffffc020056c:	0007bc23          	sd	zero,24(a5) # ffffffffc02da580 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000da797          	auipc	a5,0xda
ffffffffc020057a:	0127b783          	ld	a5,18(a5) # ffffffffc02da588 <timebase>
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
ffffffffc0200600:	00006517          	auipc	a0,0x6
ffffffffc0200604:	a0050513          	addi	a0,a0,-1536 # ffffffffc0206000 <commands+0xa8>
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
ffffffffc0200626:	0000c597          	auipc	a1,0xc
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020c000 <boot_hartid>
ffffffffc020062e:	00006517          	auipc	a0,0x6
ffffffffc0200632:	9e250513          	addi	a0,a0,-1566 # ffffffffc0206010 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000c417          	auipc	s0,0xc
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020c008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00006517          	auipc	a0,0x6
ffffffffc0200648:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0206020 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00006517          	auipc	a0,0x6
ffffffffc0200658:	9e450513          	addi	a0,a0,-1564 # ffffffffc0206038 <commands+0xe0>
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
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe058f9>
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
ffffffffc020070e:	00006917          	auipc	s2,0x6
ffffffffc0200712:	97a90913          	addi	s2,s2,-1670 # ffffffffc0206088 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00006497          	auipc	s1,0x6
ffffffffc0200720:	96448493          	addi	s1,s1,-1692 # ffffffffc0206080 <commands+0x128>
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
ffffffffc0200770:	00006517          	auipc	a0,0x6
ffffffffc0200774:	99050513          	addi	a0,a0,-1648 # ffffffffc0206100 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00006517          	auipc	a0,0x6
ffffffffc0200780:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0206138 <commands+0x1e0>
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
ffffffffc02007bc:	00006517          	auipc	a0,0x6
ffffffffc02007c0:	89c50513          	addi	a0,a0,-1892 # ffffffffc0206058 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	456050ef          	jal	ra,ffffffffc0205c20 <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	4ae050ef          	jal	ra,ffffffffc0205c86 <strncmp>
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
ffffffffc020086e:	3fa050ef          	jal	ra,ffffffffc0205c68 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00006517          	auipc	a0,0x6
ffffffffc0200886:	80e50513          	addi	a0,a0,-2034 # ffffffffc0206090 <commands+0x138>
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
ffffffffc0200954:	76050513          	addi	a0,a0,1888 # ffffffffc02060b0 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	76650513          	addi	a0,a0,1894 # ffffffffc02060c8 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	77450513          	addi	a0,a0,1908 # ffffffffc02060e8 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	7b850513          	addi	a0,a0,1976 # ffffffffc0206138 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000da797          	auipc	a5,0xda
ffffffffc020098c:	c087b423          	sd	s0,-1016(a5) # ffffffffc02da590 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000da797          	auipc	a5,0xda
ffffffffc0200994:	c167b423          	sd	s6,-1016(a5) # ffffffffc02da598 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000da517          	auipc	a0,0xda
ffffffffc020099e:	bf653503          	ld	a0,-1034(a0) # ffffffffc02da590 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000da517          	auipc	a0,0xda
ffffffffc02009a8:	bf453503          	ld	a0,-1036(a0) # ffffffffc02da598 <memory_size>
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
ffffffffc02009c4:	4e878793          	addi	a5,a5,1256 # ffffffffc0200ea8 <__alltraps>
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
ffffffffc02009e2:	77250513          	addi	a0,a0,1906 # ffffffffc0206150 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	77a50513          	addi	a0,a0,1914 # ffffffffc0206168 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	78450513          	addi	a0,a0,1924 # ffffffffc0206180 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	78e50513          	addi	a0,a0,1934 # ffffffffc0206198 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	79850513          	addi	a0,a0,1944 # ffffffffc02061b0 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	7a250513          	addi	a0,a0,1954 # ffffffffc02061c8 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	7ac50513          	addi	a0,a0,1964 # ffffffffc02061e0 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	7b650513          	addi	a0,a0,1974 # ffffffffc02061f8 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	7c050513          	addi	a0,a0,1984 # ffffffffc0206210 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	7ca50513          	addi	a0,a0,1994 # ffffffffc0206228 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	7d450513          	addi	a0,a0,2004 # ffffffffc0206240 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	7de50513          	addi	a0,a0,2014 # ffffffffc0206258 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	7e850513          	addi	a0,a0,2024 # ffffffffc0206270 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	7f250513          	addi	a0,a0,2034 # ffffffffc0206288 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	7fc50513          	addi	a0,a0,2044 # ffffffffc02062a0 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00006517          	auipc	a0,0x6
ffffffffc0200ab6:	80650513          	addi	a0,a0,-2042 # ffffffffc02062b8 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00006517          	auipc	a0,0x6
ffffffffc0200ac4:	81050513          	addi	a0,a0,-2032 # ffffffffc02062d0 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00006517          	auipc	a0,0x6
ffffffffc0200ad2:	81a50513          	addi	a0,a0,-2022 # ffffffffc02062e8 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00006517          	auipc	a0,0x6
ffffffffc0200ae0:	82450513          	addi	a0,a0,-2012 # ffffffffc0206300 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00006517          	auipc	a0,0x6
ffffffffc0200aee:	82e50513          	addi	a0,a0,-2002 # ffffffffc0206318 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00006517          	auipc	a0,0x6
ffffffffc0200afc:	83850513          	addi	a0,a0,-1992 # ffffffffc0206330 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00006517          	auipc	a0,0x6
ffffffffc0200b0a:	84250513          	addi	a0,a0,-1982 # ffffffffc0206348 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00006517          	auipc	a0,0x6
ffffffffc0200b18:	84c50513          	addi	a0,a0,-1972 # ffffffffc0206360 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00006517          	auipc	a0,0x6
ffffffffc0200b26:	85650513          	addi	a0,a0,-1962 # ffffffffc0206378 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00006517          	auipc	a0,0x6
ffffffffc0200b34:	86050513          	addi	a0,a0,-1952 # ffffffffc0206390 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00006517          	auipc	a0,0x6
ffffffffc0200b42:	86a50513          	addi	a0,a0,-1942 # ffffffffc02063a8 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00006517          	auipc	a0,0x6
ffffffffc0200b50:	87450513          	addi	a0,a0,-1932 # ffffffffc02063c0 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00006517          	auipc	a0,0x6
ffffffffc0200b5e:	87e50513          	addi	a0,a0,-1922 # ffffffffc02063d8 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00006517          	auipc	a0,0x6
ffffffffc0200b6c:	88850513          	addi	a0,a0,-1912 # ffffffffc02063f0 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00006517          	auipc	a0,0x6
ffffffffc0200b7a:	89250513          	addi	a0,a0,-1902 # ffffffffc0206408 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00006517          	auipc	a0,0x6
ffffffffc0200b88:	89c50513          	addi	a0,a0,-1892 # ffffffffc0206420 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00006517          	auipc	a0,0x6
ffffffffc0200b9a:	8a250513          	addi	a0,a0,-1886 # ffffffffc0206438 <commands+0x4e0>
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
ffffffffc0200bac:	00006517          	auipc	a0,0x6
ffffffffc0200bb0:	8a450513          	addi	a0,a0,-1884 # ffffffffc0206450 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00006517          	auipc	a0,0x6
ffffffffc0200bc8:	8a450513          	addi	a0,a0,-1884 # ffffffffc0206468 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00006517          	auipc	a0,0x6
ffffffffc0200bd8:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0206480 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00006517          	auipc	a0,0x6
ffffffffc0200be8:	8b450513          	addi	a0,a0,-1868 # ffffffffc0206498 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00006517          	auipc	a0,0x6
ffffffffc0200bfc:	8b050513          	addi	a0,a0,-1872 # ffffffffc02064a8 <commands+0x550>
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
ffffffffc0200c14:	00006717          	auipc	a4,0x6
ffffffffc0200c18:	98c70713          	addi	a4,a4,-1652 # ffffffffc02065a0 <commands+0x648>
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
ffffffffc0200c26:	00006517          	auipc	a0,0x6
ffffffffc0200c2a:	8fa50513          	addi	a0,a0,-1798 # ffffffffc0206520 <commands+0x5c8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c32:	00006517          	auipc	a0,0x6
ffffffffc0200c36:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0206500 <commands+0x5a8>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c3e:	00006517          	auipc	a0,0x6
ffffffffc0200c42:	88250513          	addi	a0,a0,-1918 # ffffffffc02064c0 <commands+0x568>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c4a:	00006517          	auipc	a0,0x6
ffffffffc0200c4e:	89650513          	addi	a0,a0,-1898 # ffffffffc02064e0 <commands+0x588>
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
ffffffffc0200c5e:	000da797          	auipc	a5,0xda
ffffffffc0200c62:	92278793          	addi	a5,a5,-1758 # ffffffffc02da580 <ticks>
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
ffffffffc0200c78:	000da797          	auipc	a5,0xda
ffffffffc0200c7c:	9607b783          	ld	a5,-1696(a5) # ffffffffc02da5d8 <current>
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
ffffffffc0200c8c:	00006517          	auipc	a0,0x6
ffffffffc0200c90:	8f450513          	addi	a0,a0,-1804 # ffffffffc0206580 <commands+0x628>
ffffffffc0200c94:	d00ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c98:	b731                	j	ffffffffc0200ba4 <print_trapframe>
            assert(current != NULL);
ffffffffc0200c9a:	00006697          	auipc	a3,0x6
ffffffffc0200c9e:	8a668693          	addi	a3,a3,-1882 # ffffffffc0206540 <commands+0x5e8>
ffffffffc0200ca2:	00006617          	auipc	a2,0x6
ffffffffc0200ca6:	8ae60613          	addi	a2,a2,-1874 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0200caa:	08800593          	li	a1,136
ffffffffc0200cae:	00006517          	auipc	a0,0x6
ffffffffc0200cb2:	8ba50513          	addi	a0,a0,-1862 # ffffffffc0206568 <commands+0x610>
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
ffffffffc0200cc8:	0ef76a63          	bltu	a4,a5,ffffffffc0200dbc <exception_handler+0x102>
ffffffffc0200ccc:	00006717          	auipc	a4,0x6
ffffffffc0200cd0:	b0c70713          	addi	a4,a4,-1268 # ffffffffc02067d8 <commands+0x880>
ffffffffc0200cd4:	078a                	slli	a5,a5,0x2
ffffffffc0200cd6:	97ba                	add	a5,a5,a4
ffffffffc0200cd8:	439c                	lw	a5,0(a5)
ffffffffc0200cda:	97ba                	add	a5,a5,a4
ffffffffc0200cdc:	8782                	jr	a5
        
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200cde:	00006517          	auipc	a0,0x6
ffffffffc0200ce2:	9c250513          	addi	a0,a0,-1598 # ffffffffc02066a0 <commands+0x748>
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
ffffffffc0200cfa:	2a30406f          	j	ffffffffc020579c <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cfe:	00006517          	auipc	a0,0x6
ffffffffc0200d02:	9c250513          	addi	a0,a0,-1598 # ffffffffc02066c0 <commands+0x768>
}
ffffffffc0200d06:	6402                	ld	s0,0(sp)
ffffffffc0200d08:	60a2                	ld	ra,8(sp)
ffffffffc0200d0a:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200d0c:	c88ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d10:	00006517          	auipc	a0,0x6
ffffffffc0200d14:	9d050513          	addi	a0,a0,-1584 # ffffffffc02066e0 <commands+0x788>
ffffffffc0200d18:	b7fd                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200d1a:	00006517          	auipc	a0,0x6
ffffffffc0200d1e:	9e650513          	addi	a0,a0,-1562 # ffffffffc0206700 <commands+0x7a8>
ffffffffc0200d22:	b7d5                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Load page fault\n");
ffffffffc0200d24:	00006517          	auipc	a0,0x6
ffffffffc0200d28:	9f450513          	addi	a0,a0,-1548 # ffffffffc0206718 <commands+0x7c0>
ffffffffc0200d2c:	bfe9                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Store/AMO page fault at 0x%x\n", tf->tval);
ffffffffc0200d2e:	11053583          	ld	a1,272(a0)
ffffffffc0200d32:	00006517          	auipc	a0,0x6
ffffffffc0200d36:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0206730 <commands+0x7d8>
ffffffffc0200d3a:	c5aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (current != NULL && current->mm != NULL)
ffffffffc0200d3e:	000da797          	auipc	a5,0xda
ffffffffc0200d42:	89a7b783          	ld	a5,-1894(a5) # ffffffffc02da5d8 <current>
ffffffffc0200d46:	c7d9                	beqz	a5,ffffffffc0200dd4 <exception_handler+0x11a>
ffffffffc0200d48:	7788                	ld	a0,40(a5)
ffffffffc0200d4a:	c549                	beqz	a0,ffffffffc0200dd4 <exception_handler+0x11a>
            int cow_ret = do_pgfault_cow(current->mm, tf->cause, tf->tval);
ffffffffc0200d4c:	11043603          	ld	a2,272(s0)
ffffffffc0200d50:	11842583          	lw	a1,280(s0)
ffffffffc0200d54:	270030ef          	jal	ra,ffffffffc0203fc4 <do_pgfault_cow>
            if (cow_ret == 0)
ffffffffc0200d58:	e53d                	bnez	a0,ffffffffc0200dc6 <exception_handler+0x10c>
                cprintf("COW page fault handled successfully\n");
ffffffffc0200d5a:	00006517          	auipc	a0,0x6
ffffffffc0200d5e:	9f650513          	addi	a0,a0,-1546 # ffffffffc0206750 <commands+0x7f8>
ffffffffc0200d62:	b755                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d64:	00006517          	auipc	a0,0x6
ffffffffc0200d68:	86c50513          	addi	a0,a0,-1940 # ffffffffc02065d0 <commands+0x678>
ffffffffc0200d6c:	bf69                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200d6e:	00006517          	auipc	a0,0x6
ffffffffc0200d72:	88250513          	addi	a0,a0,-1918 # ffffffffc02065f0 <commands+0x698>
ffffffffc0200d76:	bf41                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200d78:	00006517          	auipc	a0,0x6
ffffffffc0200d7c:	89850513          	addi	a0,a0,-1896 # ffffffffc0206610 <commands+0x6b8>
ffffffffc0200d80:	b759                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200d82:	00006517          	auipc	a0,0x6
ffffffffc0200d86:	8a650513          	addi	a0,a0,-1882 # ffffffffc0206628 <commands+0x6d0>
ffffffffc0200d8a:	c0aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200d8e:	6458                	ld	a4,136(s0)
ffffffffc0200d90:	47a9                	li	a5,10
ffffffffc0200d92:	06f70263          	beq	a4,a5,ffffffffc0200df6 <exception_handler+0x13c>
}
ffffffffc0200d96:	60a2                	ld	ra,8(sp)
ffffffffc0200d98:	6402                	ld	s0,0(sp)
ffffffffc0200d9a:	0141                	addi	sp,sp,16
ffffffffc0200d9c:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200d9e:	00006517          	auipc	a0,0x6
ffffffffc0200da2:	89a50513          	addi	a0,a0,-1894 # ffffffffc0206638 <commands+0x6e0>
ffffffffc0200da6:	b785                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200da8:	00006517          	auipc	a0,0x6
ffffffffc0200dac:	8b050513          	addi	a0,a0,-1872 # ffffffffc0206658 <commands+0x700>
ffffffffc0200db0:	bf99                	j	ffffffffc0200d06 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200db2:	00006517          	auipc	a0,0x6
ffffffffc0200db6:	8d650513          	addi	a0,a0,-1834 # ffffffffc0206688 <commands+0x730>
ffffffffc0200dba:	b7b1                	j	ffffffffc0200d06 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200dbc:	8522                	mv	a0,s0
}
ffffffffc0200dbe:	6402                	ld	s0,0(sp)
ffffffffc0200dc0:	60a2                	ld	ra,8(sp)
ffffffffc0200dc2:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200dc4:	b3c5                	j	ffffffffc0200ba4 <print_trapframe>
            cprintf("Not a COW page fault (ret=%d), handling as normal page fault\n", cow_ret);
ffffffffc0200dc6:	85aa                	mv	a1,a0
ffffffffc0200dc8:	00006517          	auipc	a0,0x6
ffffffffc0200dcc:	9b050513          	addi	a0,a0,-1616 # ffffffffc0206778 <commands+0x820>
ffffffffc0200dd0:	bc4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("Store/AMO page fault (non-COW)\n");
ffffffffc0200dd4:	00006517          	auipc	a0,0x6
ffffffffc0200dd8:	9e450513          	addi	a0,a0,-1564 # ffffffffc02067b8 <commands+0x860>
ffffffffc0200ddc:	b72d                	j	ffffffffc0200d06 <exception_handler+0x4c>
        panic("AMO address misaligned\n");
ffffffffc0200dde:	00006617          	auipc	a2,0x6
ffffffffc0200de2:	89260613          	addi	a2,a2,-1902 # ffffffffc0206670 <commands+0x718>
ffffffffc0200de6:	0c200593          	li	a1,194
ffffffffc0200dea:	00005517          	auipc	a0,0x5
ffffffffc0200dee:	77e50513          	addi	a0,a0,1918 # ffffffffc0206568 <commands+0x610>
ffffffffc0200df2:	e9cff0ef          	jal	ra,ffffffffc020048e <__panic>
            tf->epc += 4;
ffffffffc0200df6:	10843783          	ld	a5,264(s0)
ffffffffc0200dfa:	0791                	addi	a5,a5,4
ffffffffc0200dfc:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200e00:	19d040ef          	jal	ra,ffffffffc020579c <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e04:	000d9797          	auipc	a5,0xd9
ffffffffc0200e08:	7d47b783          	ld	a5,2004(a5) # ffffffffc02da5d8 <current>
ffffffffc0200e0c:	6b9c                	ld	a5,16(a5)
ffffffffc0200e0e:	8522                	mv	a0,s0
}
ffffffffc0200e10:	6402                	ld	s0,0(sp)
ffffffffc0200e12:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e14:	6589                	lui	a1,0x2
ffffffffc0200e16:	95be                	add	a1,a1,a5
}
ffffffffc0200e18:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200e1a:	aab1                	j	ffffffffc0200f76 <kernel_execve_ret>

ffffffffc0200e1c <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200e1c:	1101                	addi	sp,sp,-32
ffffffffc0200e1e:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200e20:	000d9417          	auipc	s0,0xd9
ffffffffc0200e24:	7b840413          	addi	s0,s0,1976 # ffffffffc02da5d8 <current>
ffffffffc0200e28:	6018                	ld	a4,0(s0)
{
ffffffffc0200e2a:	ec06                	sd	ra,24(sp)
ffffffffc0200e2c:	e426                	sd	s1,8(sp)
ffffffffc0200e2e:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e30:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200e34:	cf1d                	beqz	a4,ffffffffc0200e72 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e36:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200e3a:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200e3e:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e40:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e44:	0206c463          	bltz	a3,ffffffffc0200e6c <trap+0x50>
        exception_handler(tf);
ffffffffc0200e48:	e73ff0ef          	jal	ra,ffffffffc0200cba <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200e4c:	601c                	ld	a5,0(s0)
ffffffffc0200e4e:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200e52:	e499                	bnez	s1,ffffffffc0200e60 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200e54:	0b07a703          	lw	a4,176(a5)
ffffffffc0200e58:	8b05                	andi	a4,a4,1
ffffffffc0200e5a:	e329                	bnez	a4,ffffffffc0200e9c <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e5c:	6f9c                	ld	a5,24(a5)
ffffffffc0200e5e:	eb85                	bnez	a5,ffffffffc0200e8e <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200e60:	60e2                	ld	ra,24(sp)
ffffffffc0200e62:	6442                	ld	s0,16(sp)
ffffffffc0200e64:	64a2                	ld	s1,8(sp)
ffffffffc0200e66:	6902                	ld	s2,0(sp)
ffffffffc0200e68:	6105                	addi	sp,sp,32
ffffffffc0200e6a:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e6c:	d9bff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200e70:	bff1                	j	ffffffffc0200e4c <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e72:	0006c863          	bltz	a3,ffffffffc0200e82 <trap+0x66>
}
ffffffffc0200e76:	6442                	ld	s0,16(sp)
ffffffffc0200e78:	60e2                	ld	ra,24(sp)
ffffffffc0200e7a:	64a2                	ld	s1,8(sp)
ffffffffc0200e7c:	6902                	ld	s2,0(sp)
ffffffffc0200e7e:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200e80:	bd2d                	j	ffffffffc0200cba <exception_handler>
}
ffffffffc0200e82:	6442                	ld	s0,16(sp)
ffffffffc0200e84:	60e2                	ld	ra,24(sp)
ffffffffc0200e86:	64a2                	ld	s1,8(sp)
ffffffffc0200e88:	6902                	ld	s2,0(sp)
ffffffffc0200e8a:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e8c:	bbad                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200e8e:	6442                	ld	s0,16(sp)
ffffffffc0200e90:	60e2                	ld	ra,24(sp)
ffffffffc0200e92:	64a2                	ld	s1,8(sp)
ffffffffc0200e94:	6902                	ld	s2,0(sp)
ffffffffc0200e96:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e98:	0190406f          	j	ffffffffc02056b0 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e9c:	555d                	li	a0,-9
ffffffffc0200e9e:	377030ef          	jal	ra,ffffffffc0204a14 <do_exit>
            if (current->need_resched)
ffffffffc0200ea2:	601c                	ld	a5,0(s0)
ffffffffc0200ea4:	bf65                	j	ffffffffc0200e5c <trap+0x40>
	...

ffffffffc0200ea8 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ea8:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200eac:	00011463          	bnez	sp,ffffffffc0200eb4 <__alltraps+0xc>
ffffffffc0200eb0:	14002173          	csrr	sp,sscratch
ffffffffc0200eb4:	712d                	addi	sp,sp,-288
ffffffffc0200eb6:	e002                	sd	zero,0(sp)
ffffffffc0200eb8:	e406                	sd	ra,8(sp)
ffffffffc0200eba:	ec0e                	sd	gp,24(sp)
ffffffffc0200ebc:	f012                	sd	tp,32(sp)
ffffffffc0200ebe:	f416                	sd	t0,40(sp)
ffffffffc0200ec0:	f81a                	sd	t1,48(sp)
ffffffffc0200ec2:	fc1e                	sd	t2,56(sp)
ffffffffc0200ec4:	e0a2                	sd	s0,64(sp)
ffffffffc0200ec6:	e4a6                	sd	s1,72(sp)
ffffffffc0200ec8:	e8aa                	sd	a0,80(sp)
ffffffffc0200eca:	ecae                	sd	a1,88(sp)
ffffffffc0200ecc:	f0b2                	sd	a2,96(sp)
ffffffffc0200ece:	f4b6                	sd	a3,104(sp)
ffffffffc0200ed0:	f8ba                	sd	a4,112(sp)
ffffffffc0200ed2:	fcbe                	sd	a5,120(sp)
ffffffffc0200ed4:	e142                	sd	a6,128(sp)
ffffffffc0200ed6:	e546                	sd	a7,136(sp)
ffffffffc0200ed8:	e94a                	sd	s2,144(sp)
ffffffffc0200eda:	ed4e                	sd	s3,152(sp)
ffffffffc0200edc:	f152                	sd	s4,160(sp)
ffffffffc0200ede:	f556                	sd	s5,168(sp)
ffffffffc0200ee0:	f95a                	sd	s6,176(sp)
ffffffffc0200ee2:	fd5e                	sd	s7,184(sp)
ffffffffc0200ee4:	e1e2                	sd	s8,192(sp)
ffffffffc0200ee6:	e5e6                	sd	s9,200(sp)
ffffffffc0200ee8:	e9ea                	sd	s10,208(sp)
ffffffffc0200eea:	edee                	sd	s11,216(sp)
ffffffffc0200eec:	f1f2                	sd	t3,224(sp)
ffffffffc0200eee:	f5f6                	sd	t4,232(sp)
ffffffffc0200ef0:	f9fa                	sd	t5,240(sp)
ffffffffc0200ef2:	fdfe                	sd	t6,248(sp)
ffffffffc0200ef4:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ef8:	100024f3          	csrr	s1,sstatus
ffffffffc0200efc:	14102973          	csrr	s2,sepc
ffffffffc0200f00:	143029f3          	csrr	s3,stval
ffffffffc0200f04:	14202a73          	csrr	s4,scause
ffffffffc0200f08:	e822                	sd	s0,16(sp)
ffffffffc0200f0a:	e226                	sd	s1,256(sp)
ffffffffc0200f0c:	e64a                	sd	s2,264(sp)
ffffffffc0200f0e:	ea4e                	sd	s3,272(sp)
ffffffffc0200f10:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200f12:	850a                	mv	a0,sp
    jal trap
ffffffffc0200f14:	f09ff0ef          	jal	ra,ffffffffc0200e1c <trap>

ffffffffc0200f18 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200f18:	6492                	ld	s1,256(sp)
ffffffffc0200f1a:	6932                	ld	s2,264(sp)
ffffffffc0200f1c:	1004f413          	andi	s0,s1,256
ffffffffc0200f20:	e401                	bnez	s0,ffffffffc0200f28 <__trapret+0x10>
ffffffffc0200f22:	1200                	addi	s0,sp,288
ffffffffc0200f24:	14041073          	csrw	sscratch,s0
ffffffffc0200f28:	10049073          	csrw	sstatus,s1
ffffffffc0200f2c:	14191073          	csrw	sepc,s2
ffffffffc0200f30:	60a2                	ld	ra,8(sp)
ffffffffc0200f32:	61e2                	ld	gp,24(sp)
ffffffffc0200f34:	7202                	ld	tp,32(sp)
ffffffffc0200f36:	72a2                	ld	t0,40(sp)
ffffffffc0200f38:	7342                	ld	t1,48(sp)
ffffffffc0200f3a:	73e2                	ld	t2,56(sp)
ffffffffc0200f3c:	6406                	ld	s0,64(sp)
ffffffffc0200f3e:	64a6                	ld	s1,72(sp)
ffffffffc0200f40:	6546                	ld	a0,80(sp)
ffffffffc0200f42:	65e6                	ld	a1,88(sp)
ffffffffc0200f44:	7606                	ld	a2,96(sp)
ffffffffc0200f46:	76a6                	ld	a3,104(sp)
ffffffffc0200f48:	7746                	ld	a4,112(sp)
ffffffffc0200f4a:	77e6                	ld	a5,120(sp)
ffffffffc0200f4c:	680a                	ld	a6,128(sp)
ffffffffc0200f4e:	68aa                	ld	a7,136(sp)
ffffffffc0200f50:	694a                	ld	s2,144(sp)
ffffffffc0200f52:	69ea                	ld	s3,152(sp)
ffffffffc0200f54:	7a0a                	ld	s4,160(sp)
ffffffffc0200f56:	7aaa                	ld	s5,168(sp)
ffffffffc0200f58:	7b4a                	ld	s6,176(sp)
ffffffffc0200f5a:	7bea                	ld	s7,184(sp)
ffffffffc0200f5c:	6c0e                	ld	s8,192(sp)
ffffffffc0200f5e:	6cae                	ld	s9,200(sp)
ffffffffc0200f60:	6d4e                	ld	s10,208(sp)
ffffffffc0200f62:	6dee                	ld	s11,216(sp)
ffffffffc0200f64:	7e0e                	ld	t3,224(sp)
ffffffffc0200f66:	7eae                	ld	t4,232(sp)
ffffffffc0200f68:	7f4e                	ld	t5,240(sp)
ffffffffc0200f6a:	7fee                	ld	t6,248(sp)
ffffffffc0200f6c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f6e:	10200073          	sret

ffffffffc0200f72 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f72:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200f74:	b755                	j	ffffffffc0200f18 <__trapret>

ffffffffc0200f76 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200f76:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7ce8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200f7a:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200f7e:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200f82:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200f86:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200f8a:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200f8e:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200f92:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200f96:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200f9a:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200f9c:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200f9e:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200fa0:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200fa2:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200fa4:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200fa6:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200fa8:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200faa:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200fac:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200fae:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200fb0:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200fb2:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200fb4:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200fb6:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200fb8:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200fba:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200fbc:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200fbe:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200fc0:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200fc2:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200fc4:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200fc6:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200fc8:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200fca:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200fcc:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200fce:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200fd0:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200fd2:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200fd4:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200fd6:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200fd8:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200fda:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200fdc:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200fde:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200fe0:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200fe2:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200fe4:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200fe6:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200fe8:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200fea:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200fec:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200fee:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200ff0:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200ff2:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200ff4:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200ff6:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200ff8:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200ffa:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200ffc:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200ffe:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0201000:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0201002:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0201004:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0201006:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0201008:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc020100a:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc020100c:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc020100e:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0201010:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0201012:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0201014:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0201016:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0201018:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc020101a:	812e                	mv	sp,a1
ffffffffc020101c:	bdf5                	j	ffffffffc0200f18 <__trapret>

ffffffffc020101e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020101e:	000d5797          	auipc	a5,0xd5
ffffffffc0201022:	53278793          	addi	a5,a5,1330 # ffffffffc02d6550 <free_area>
ffffffffc0201026:	e79c                	sd	a5,8(a5)
ffffffffc0201028:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc020102a:	0007a823          	sw	zero,16(a5)
}
ffffffffc020102e:	8082                	ret

ffffffffc0201030 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0201030:	000d5517          	auipc	a0,0xd5
ffffffffc0201034:	53056503          	lwu	a0,1328(a0) # ffffffffc02d6560 <free_area+0x10>
ffffffffc0201038:	8082                	ret

ffffffffc020103a <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc020103a:	715d                	addi	sp,sp,-80
ffffffffc020103c:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020103e:	000d5417          	auipc	s0,0xd5
ffffffffc0201042:	51240413          	addi	s0,s0,1298 # ffffffffc02d6550 <free_area>
ffffffffc0201046:	641c                	ld	a5,8(s0)
ffffffffc0201048:	e486                	sd	ra,72(sp)
ffffffffc020104a:	fc26                	sd	s1,56(sp)
ffffffffc020104c:	f84a                	sd	s2,48(sp)
ffffffffc020104e:	f44e                	sd	s3,40(sp)
ffffffffc0201050:	f052                	sd	s4,32(sp)
ffffffffc0201052:	ec56                	sd	s5,24(sp)
ffffffffc0201054:	e85a                	sd	s6,16(sp)
ffffffffc0201056:	e45e                	sd	s7,8(sp)
ffffffffc0201058:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020105a:	2a878d63          	beq	a5,s0,ffffffffc0201314 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc020105e:	4481                	li	s1,0
ffffffffc0201060:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201062:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201066:	8b09                	andi	a4,a4,2
ffffffffc0201068:	2a070a63          	beqz	a4,ffffffffc020131c <default_check+0x2e2>
        count++, total += p->property;
ffffffffc020106c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201070:	679c                	ld	a5,8(a5)
ffffffffc0201072:	2905                	addiw	s2,s2,1
ffffffffc0201074:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201076:	fe8796e3          	bne	a5,s0,ffffffffc0201062 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020107a:	89a6                	mv	s3,s1
ffffffffc020107c:	6df000ef          	jal	ra,ffffffffc0201f5a <nr_free_pages>
ffffffffc0201080:	6f351e63          	bne	a0,s3,ffffffffc020177c <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201084:	4505                	li	a0,1
ffffffffc0201086:	657000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc020108a:	8aaa                	mv	s5,a0
ffffffffc020108c:	42050863          	beqz	a0,ffffffffc02014bc <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201090:	4505                	li	a0,1
ffffffffc0201092:	64b000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc0201096:	89aa                	mv	s3,a0
ffffffffc0201098:	70050263          	beqz	a0,ffffffffc020179c <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020109c:	4505                	li	a0,1
ffffffffc020109e:	63f000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc02010a2:	8a2a                	mv	s4,a0
ffffffffc02010a4:	48050c63          	beqz	a0,ffffffffc020153c <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010a8:	293a8a63          	beq	s5,s3,ffffffffc020133c <default_check+0x302>
ffffffffc02010ac:	28aa8863          	beq	s5,a0,ffffffffc020133c <default_check+0x302>
ffffffffc02010b0:	28a98663          	beq	s3,a0,ffffffffc020133c <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02010b4:	000aa783          	lw	a5,0(s5)
ffffffffc02010b8:	2a079263          	bnez	a5,ffffffffc020135c <default_check+0x322>
ffffffffc02010bc:	0009a783          	lw	a5,0(s3)
ffffffffc02010c0:	28079e63          	bnez	a5,ffffffffc020135c <default_check+0x322>
ffffffffc02010c4:	411c                	lw	a5,0(a0)
ffffffffc02010c6:	28079b63          	bnez	a5,ffffffffc020135c <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc02010ca:	000d9797          	auipc	a5,0xd9
ffffffffc02010ce:	4f67b783          	ld	a5,1270(a5) # ffffffffc02da5c0 <pages>
ffffffffc02010d2:	40fa8733          	sub	a4,s5,a5
ffffffffc02010d6:	00007617          	auipc	a2,0x7
ffffffffc02010da:	14a63603          	ld	a2,330(a2) # ffffffffc0208220 <nbase>
ffffffffc02010de:	8719                	srai	a4,a4,0x6
ffffffffc02010e0:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010e2:	000d9697          	auipc	a3,0xd9
ffffffffc02010e6:	4d66b683          	ld	a3,1238(a3) # ffffffffc02da5b8 <npage>
ffffffffc02010ea:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc02010ec:	0732                	slli	a4,a4,0xc
ffffffffc02010ee:	28d77763          	bgeu	a4,a3,ffffffffc020137c <default_check+0x342>
    return page - pages + nbase;
ffffffffc02010f2:	40f98733          	sub	a4,s3,a5
ffffffffc02010f6:	8719                	srai	a4,a4,0x6
ffffffffc02010f8:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010fa:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010fc:	4cd77063          	bgeu	a4,a3,ffffffffc02015bc <default_check+0x582>
    return page - pages + nbase;
ffffffffc0201100:	40f507b3          	sub	a5,a0,a5
ffffffffc0201104:	8799                	srai	a5,a5,0x6
ffffffffc0201106:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201108:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020110a:	30d7f963          	bgeu	a5,a3,ffffffffc020141c <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc020110e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201110:	00043c03          	ld	s8,0(s0)
ffffffffc0201114:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201118:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020111c:	e400                	sd	s0,8(s0)
ffffffffc020111e:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201120:	000d5797          	auipc	a5,0xd5
ffffffffc0201124:	4407a023          	sw	zero,1088(a5) # ffffffffc02d6560 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201128:	5b5000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc020112c:	2c051863          	bnez	a0,ffffffffc02013fc <default_check+0x3c2>
    free_page(p0);
ffffffffc0201130:	4585                	li	a1,1
ffffffffc0201132:	8556                	mv	a0,s5
ffffffffc0201134:	5e7000ef          	jal	ra,ffffffffc0201f1a <free_pages>
    free_page(p1);
ffffffffc0201138:	4585                	li	a1,1
ffffffffc020113a:	854e                	mv	a0,s3
ffffffffc020113c:	5df000ef          	jal	ra,ffffffffc0201f1a <free_pages>
    free_page(p2);
ffffffffc0201140:	4585                	li	a1,1
ffffffffc0201142:	8552                	mv	a0,s4
ffffffffc0201144:	5d7000ef          	jal	ra,ffffffffc0201f1a <free_pages>
    assert(nr_free == 3);
ffffffffc0201148:	4818                	lw	a4,16(s0)
ffffffffc020114a:	478d                	li	a5,3
ffffffffc020114c:	28f71863          	bne	a4,a5,ffffffffc02013dc <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201150:	4505                	li	a0,1
ffffffffc0201152:	58b000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc0201156:	89aa                	mv	s3,a0
ffffffffc0201158:	26050263          	beqz	a0,ffffffffc02013bc <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020115c:	4505                	li	a0,1
ffffffffc020115e:	57f000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc0201162:	8aaa                	mv	s5,a0
ffffffffc0201164:	3a050c63          	beqz	a0,ffffffffc020151c <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201168:	4505                	li	a0,1
ffffffffc020116a:	573000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc020116e:	8a2a                	mv	s4,a0
ffffffffc0201170:	38050663          	beqz	a0,ffffffffc02014fc <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201174:	4505                	li	a0,1
ffffffffc0201176:	567000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc020117a:	36051163          	bnez	a0,ffffffffc02014dc <default_check+0x4a2>
    free_page(p0);
ffffffffc020117e:	4585                	li	a1,1
ffffffffc0201180:	854e                	mv	a0,s3
ffffffffc0201182:	599000ef          	jal	ra,ffffffffc0201f1a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201186:	641c                	ld	a5,8(s0)
ffffffffc0201188:	20878a63          	beq	a5,s0,ffffffffc020139c <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc020118c:	4505                	li	a0,1
ffffffffc020118e:	54f000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc0201192:	30a99563          	bne	s3,a0,ffffffffc020149c <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201196:	4505                	li	a0,1
ffffffffc0201198:	545000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc020119c:	2e051063          	bnez	a0,ffffffffc020147c <default_check+0x442>
    assert(nr_free == 0);
ffffffffc02011a0:	481c                	lw	a5,16(s0)
ffffffffc02011a2:	2a079d63          	bnez	a5,ffffffffc020145c <default_check+0x422>
    free_page(p);
ffffffffc02011a6:	854e                	mv	a0,s3
ffffffffc02011a8:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02011aa:	01843023          	sd	s8,0(s0)
ffffffffc02011ae:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02011b2:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02011b6:	565000ef          	jal	ra,ffffffffc0201f1a <free_pages>
    free_page(p1);
ffffffffc02011ba:	4585                	li	a1,1
ffffffffc02011bc:	8556                	mv	a0,s5
ffffffffc02011be:	55d000ef          	jal	ra,ffffffffc0201f1a <free_pages>
    free_page(p2);
ffffffffc02011c2:	4585                	li	a1,1
ffffffffc02011c4:	8552                	mv	a0,s4
ffffffffc02011c6:	555000ef          	jal	ra,ffffffffc0201f1a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02011ca:	4515                	li	a0,5
ffffffffc02011cc:	511000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc02011d0:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02011d2:	26050563          	beqz	a0,ffffffffc020143c <default_check+0x402>
ffffffffc02011d6:	651c                	ld	a5,8(a0)
ffffffffc02011d8:	8385                	srli	a5,a5,0x1
ffffffffc02011da:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc02011dc:	54079063          	bnez	a5,ffffffffc020171c <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02011e0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02011e2:	00043b03          	ld	s6,0(s0)
ffffffffc02011e6:	00843a83          	ld	s5,8(s0)
ffffffffc02011ea:	e000                	sd	s0,0(s0)
ffffffffc02011ec:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02011ee:	4ef000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc02011f2:	50051563          	bnez	a0,ffffffffc02016fc <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02011f6:	08098a13          	addi	s4,s3,128
ffffffffc02011fa:	8552                	mv	a0,s4
ffffffffc02011fc:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02011fe:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201202:	000d5797          	auipc	a5,0xd5
ffffffffc0201206:	3407af23          	sw	zero,862(a5) # ffffffffc02d6560 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020120a:	511000ef          	jal	ra,ffffffffc0201f1a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020120e:	4511                	li	a0,4
ffffffffc0201210:	4cd000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc0201214:	4c051463          	bnez	a0,ffffffffc02016dc <default_check+0x6a2>
ffffffffc0201218:	0889b783          	ld	a5,136(s3)
ffffffffc020121c:	8385                	srli	a5,a5,0x1
ffffffffc020121e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201220:	48078e63          	beqz	a5,ffffffffc02016bc <default_check+0x682>
ffffffffc0201224:	0909a703          	lw	a4,144(s3)
ffffffffc0201228:	478d                	li	a5,3
ffffffffc020122a:	48f71963          	bne	a4,a5,ffffffffc02016bc <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020122e:	450d                	li	a0,3
ffffffffc0201230:	4ad000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc0201234:	8c2a                	mv	s8,a0
ffffffffc0201236:	46050363          	beqz	a0,ffffffffc020169c <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020123a:	4505                	li	a0,1
ffffffffc020123c:	4a1000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc0201240:	42051e63          	bnez	a0,ffffffffc020167c <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201244:	418a1c63          	bne	s4,s8,ffffffffc020165c <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201248:	4585                	li	a1,1
ffffffffc020124a:	854e                	mv	a0,s3
ffffffffc020124c:	4cf000ef          	jal	ra,ffffffffc0201f1a <free_pages>
    free_pages(p1, 3);
ffffffffc0201250:	458d                	li	a1,3
ffffffffc0201252:	8552                	mv	a0,s4
ffffffffc0201254:	4c7000ef          	jal	ra,ffffffffc0201f1a <free_pages>
ffffffffc0201258:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc020125c:	04098c13          	addi	s8,s3,64
ffffffffc0201260:	8385                	srli	a5,a5,0x1
ffffffffc0201262:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201264:	3c078c63          	beqz	a5,ffffffffc020163c <default_check+0x602>
ffffffffc0201268:	0109a703          	lw	a4,16(s3)
ffffffffc020126c:	4785                	li	a5,1
ffffffffc020126e:	3cf71763          	bne	a4,a5,ffffffffc020163c <default_check+0x602>
ffffffffc0201272:	008a3783          	ld	a5,8(s4)
ffffffffc0201276:	8385                	srli	a5,a5,0x1
ffffffffc0201278:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020127a:	3a078163          	beqz	a5,ffffffffc020161c <default_check+0x5e2>
ffffffffc020127e:	010a2703          	lw	a4,16(s4)
ffffffffc0201282:	478d                	li	a5,3
ffffffffc0201284:	38f71c63          	bne	a4,a5,ffffffffc020161c <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201288:	4505                	li	a0,1
ffffffffc020128a:	453000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc020128e:	36a99763          	bne	s3,a0,ffffffffc02015fc <default_check+0x5c2>
    free_page(p0);
ffffffffc0201292:	4585                	li	a1,1
ffffffffc0201294:	487000ef          	jal	ra,ffffffffc0201f1a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201298:	4509                	li	a0,2
ffffffffc020129a:	443000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc020129e:	32aa1f63          	bne	s4,a0,ffffffffc02015dc <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02012a2:	4589                	li	a1,2
ffffffffc02012a4:	477000ef          	jal	ra,ffffffffc0201f1a <free_pages>
    free_page(p2);
ffffffffc02012a8:	4585                	li	a1,1
ffffffffc02012aa:	8562                	mv	a0,s8
ffffffffc02012ac:	46f000ef          	jal	ra,ffffffffc0201f1a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02012b0:	4515                	li	a0,5
ffffffffc02012b2:	42b000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc02012b6:	89aa                	mv	s3,a0
ffffffffc02012b8:	48050263          	beqz	a0,ffffffffc020173c <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02012bc:	4505                	li	a0,1
ffffffffc02012be:	41f000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc02012c2:	2c051d63          	bnez	a0,ffffffffc020159c <default_check+0x562>

    assert(nr_free == 0);
ffffffffc02012c6:	481c                	lw	a5,16(s0)
ffffffffc02012c8:	2a079a63          	bnez	a5,ffffffffc020157c <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02012cc:	4595                	li	a1,5
ffffffffc02012ce:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02012d0:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02012d4:	01643023          	sd	s6,0(s0)
ffffffffc02012d8:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02012dc:	43f000ef          	jal	ra,ffffffffc0201f1a <free_pages>
    return listelm->next;
ffffffffc02012e0:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02012e2:	00878963          	beq	a5,s0,ffffffffc02012f4 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02012e6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02012ea:	679c                	ld	a5,8(a5)
ffffffffc02012ec:	397d                	addiw	s2,s2,-1
ffffffffc02012ee:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02012f0:	fe879be3          	bne	a5,s0,ffffffffc02012e6 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02012f4:	26091463          	bnez	s2,ffffffffc020155c <default_check+0x522>
    assert(total == 0);
ffffffffc02012f8:	46049263          	bnez	s1,ffffffffc020175c <default_check+0x722>
}
ffffffffc02012fc:	60a6                	ld	ra,72(sp)
ffffffffc02012fe:	6406                	ld	s0,64(sp)
ffffffffc0201300:	74e2                	ld	s1,56(sp)
ffffffffc0201302:	7942                	ld	s2,48(sp)
ffffffffc0201304:	79a2                	ld	s3,40(sp)
ffffffffc0201306:	7a02                	ld	s4,32(sp)
ffffffffc0201308:	6ae2                	ld	s5,24(sp)
ffffffffc020130a:	6b42                	ld	s6,16(sp)
ffffffffc020130c:	6ba2                	ld	s7,8(sp)
ffffffffc020130e:	6c02                	ld	s8,0(sp)
ffffffffc0201310:	6161                	addi	sp,sp,80
ffffffffc0201312:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201314:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201316:	4481                	li	s1,0
ffffffffc0201318:	4901                	li	s2,0
ffffffffc020131a:	b38d                	j	ffffffffc020107c <default_check+0x42>
        assert(PageProperty(p));
ffffffffc020131c:	00005697          	auipc	a3,0x5
ffffffffc0201320:	4fc68693          	addi	a3,a3,1276 # ffffffffc0206818 <commands+0x8c0>
ffffffffc0201324:	00005617          	auipc	a2,0x5
ffffffffc0201328:	22c60613          	addi	a2,a2,556 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020132c:	11000593          	li	a1,272
ffffffffc0201330:	00005517          	auipc	a0,0x5
ffffffffc0201334:	4f850513          	addi	a0,a0,1272 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201338:	956ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020133c:	00005697          	auipc	a3,0x5
ffffffffc0201340:	58468693          	addi	a3,a3,1412 # ffffffffc02068c0 <commands+0x968>
ffffffffc0201344:	00005617          	auipc	a2,0x5
ffffffffc0201348:	20c60613          	addi	a2,a2,524 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020134c:	0db00593          	li	a1,219
ffffffffc0201350:	00005517          	auipc	a0,0x5
ffffffffc0201354:	4d850513          	addi	a0,a0,1240 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201358:	936ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020135c:	00005697          	auipc	a3,0x5
ffffffffc0201360:	58c68693          	addi	a3,a3,1420 # ffffffffc02068e8 <commands+0x990>
ffffffffc0201364:	00005617          	auipc	a2,0x5
ffffffffc0201368:	1ec60613          	addi	a2,a2,492 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020136c:	0dc00593          	li	a1,220
ffffffffc0201370:	00005517          	auipc	a0,0x5
ffffffffc0201374:	4b850513          	addi	a0,a0,1208 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201378:	916ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020137c:	00005697          	auipc	a3,0x5
ffffffffc0201380:	5ac68693          	addi	a3,a3,1452 # ffffffffc0206928 <commands+0x9d0>
ffffffffc0201384:	00005617          	auipc	a2,0x5
ffffffffc0201388:	1cc60613          	addi	a2,a2,460 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020138c:	0de00593          	li	a1,222
ffffffffc0201390:	00005517          	auipc	a0,0x5
ffffffffc0201394:	49850513          	addi	a0,a0,1176 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201398:	8f6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc020139c:	00005697          	auipc	a3,0x5
ffffffffc02013a0:	61468693          	addi	a3,a3,1556 # ffffffffc02069b0 <commands+0xa58>
ffffffffc02013a4:	00005617          	auipc	a2,0x5
ffffffffc02013a8:	1ac60613          	addi	a2,a2,428 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02013ac:	0f700593          	li	a1,247
ffffffffc02013b0:	00005517          	auipc	a0,0x5
ffffffffc02013b4:	47850513          	addi	a0,a0,1144 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02013b8:	8d6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013bc:	00005697          	auipc	a3,0x5
ffffffffc02013c0:	4a468693          	addi	a3,a3,1188 # ffffffffc0206860 <commands+0x908>
ffffffffc02013c4:	00005617          	auipc	a2,0x5
ffffffffc02013c8:	18c60613          	addi	a2,a2,396 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02013cc:	0f000593          	li	a1,240
ffffffffc02013d0:	00005517          	auipc	a0,0x5
ffffffffc02013d4:	45850513          	addi	a0,a0,1112 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02013d8:	8b6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc02013dc:	00005697          	auipc	a3,0x5
ffffffffc02013e0:	5c468693          	addi	a3,a3,1476 # ffffffffc02069a0 <commands+0xa48>
ffffffffc02013e4:	00005617          	auipc	a2,0x5
ffffffffc02013e8:	16c60613          	addi	a2,a2,364 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02013ec:	0ee00593          	li	a1,238
ffffffffc02013f0:	00005517          	auipc	a0,0x5
ffffffffc02013f4:	43850513          	addi	a0,a0,1080 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02013f8:	896ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013fc:	00005697          	auipc	a3,0x5
ffffffffc0201400:	58c68693          	addi	a3,a3,1420 # ffffffffc0206988 <commands+0xa30>
ffffffffc0201404:	00005617          	auipc	a2,0x5
ffffffffc0201408:	14c60613          	addi	a2,a2,332 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020140c:	0e900593          	li	a1,233
ffffffffc0201410:	00005517          	auipc	a0,0x5
ffffffffc0201414:	41850513          	addi	a0,a0,1048 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201418:	876ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020141c:	00005697          	auipc	a3,0x5
ffffffffc0201420:	54c68693          	addi	a3,a3,1356 # ffffffffc0206968 <commands+0xa10>
ffffffffc0201424:	00005617          	auipc	a2,0x5
ffffffffc0201428:	12c60613          	addi	a2,a2,300 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020142c:	0e000593          	li	a1,224
ffffffffc0201430:	00005517          	auipc	a0,0x5
ffffffffc0201434:	3f850513          	addi	a0,a0,1016 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201438:	856ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc020143c:	00005697          	auipc	a3,0x5
ffffffffc0201440:	5bc68693          	addi	a3,a3,1468 # ffffffffc02069f8 <commands+0xaa0>
ffffffffc0201444:	00005617          	auipc	a2,0x5
ffffffffc0201448:	10c60613          	addi	a2,a2,268 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020144c:	11800593          	li	a1,280
ffffffffc0201450:	00005517          	auipc	a0,0x5
ffffffffc0201454:	3d850513          	addi	a0,a0,984 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201458:	836ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020145c:	00005697          	auipc	a3,0x5
ffffffffc0201460:	58c68693          	addi	a3,a3,1420 # ffffffffc02069e8 <commands+0xa90>
ffffffffc0201464:	00005617          	auipc	a2,0x5
ffffffffc0201468:	0ec60613          	addi	a2,a2,236 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020146c:	0fd00593          	li	a1,253
ffffffffc0201470:	00005517          	auipc	a0,0x5
ffffffffc0201474:	3b850513          	addi	a0,a0,952 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201478:	816ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020147c:	00005697          	auipc	a3,0x5
ffffffffc0201480:	50c68693          	addi	a3,a3,1292 # ffffffffc0206988 <commands+0xa30>
ffffffffc0201484:	00005617          	auipc	a2,0x5
ffffffffc0201488:	0cc60613          	addi	a2,a2,204 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020148c:	0fb00593          	li	a1,251
ffffffffc0201490:	00005517          	auipc	a0,0x5
ffffffffc0201494:	39850513          	addi	a0,a0,920 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201498:	ff7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020149c:	00005697          	auipc	a3,0x5
ffffffffc02014a0:	52c68693          	addi	a3,a3,1324 # ffffffffc02069c8 <commands+0xa70>
ffffffffc02014a4:	00005617          	auipc	a2,0x5
ffffffffc02014a8:	0ac60613          	addi	a2,a2,172 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02014ac:	0fa00593          	li	a1,250
ffffffffc02014b0:	00005517          	auipc	a0,0x5
ffffffffc02014b4:	37850513          	addi	a0,a0,888 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02014b8:	fd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02014bc:	00005697          	auipc	a3,0x5
ffffffffc02014c0:	3a468693          	addi	a3,a3,932 # ffffffffc0206860 <commands+0x908>
ffffffffc02014c4:	00005617          	auipc	a2,0x5
ffffffffc02014c8:	08c60613          	addi	a2,a2,140 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02014cc:	0d700593          	li	a1,215
ffffffffc02014d0:	00005517          	auipc	a0,0x5
ffffffffc02014d4:	35850513          	addi	a0,a0,856 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02014d8:	fb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014dc:	00005697          	auipc	a3,0x5
ffffffffc02014e0:	4ac68693          	addi	a3,a3,1196 # ffffffffc0206988 <commands+0xa30>
ffffffffc02014e4:	00005617          	auipc	a2,0x5
ffffffffc02014e8:	06c60613          	addi	a2,a2,108 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02014ec:	0f400593          	li	a1,244
ffffffffc02014f0:	00005517          	auipc	a0,0x5
ffffffffc02014f4:	33850513          	addi	a0,a0,824 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02014f8:	f97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014fc:	00005697          	auipc	a3,0x5
ffffffffc0201500:	3a468693          	addi	a3,a3,932 # ffffffffc02068a0 <commands+0x948>
ffffffffc0201504:	00005617          	auipc	a2,0x5
ffffffffc0201508:	04c60613          	addi	a2,a2,76 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020150c:	0f200593          	li	a1,242
ffffffffc0201510:	00005517          	auipc	a0,0x5
ffffffffc0201514:	31850513          	addi	a0,a0,792 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201518:	f77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020151c:	00005697          	auipc	a3,0x5
ffffffffc0201520:	36468693          	addi	a3,a3,868 # ffffffffc0206880 <commands+0x928>
ffffffffc0201524:	00005617          	auipc	a2,0x5
ffffffffc0201528:	02c60613          	addi	a2,a2,44 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020152c:	0f100593          	li	a1,241
ffffffffc0201530:	00005517          	auipc	a0,0x5
ffffffffc0201534:	2f850513          	addi	a0,a0,760 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201538:	f57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020153c:	00005697          	auipc	a3,0x5
ffffffffc0201540:	36468693          	addi	a3,a3,868 # ffffffffc02068a0 <commands+0x948>
ffffffffc0201544:	00005617          	auipc	a2,0x5
ffffffffc0201548:	00c60613          	addi	a2,a2,12 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020154c:	0d900593          	li	a1,217
ffffffffc0201550:	00005517          	auipc	a0,0x5
ffffffffc0201554:	2d850513          	addi	a0,a0,728 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201558:	f37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc020155c:	00005697          	auipc	a3,0x5
ffffffffc0201560:	5ec68693          	addi	a3,a3,1516 # ffffffffc0206b48 <commands+0xbf0>
ffffffffc0201564:	00005617          	auipc	a2,0x5
ffffffffc0201568:	fec60613          	addi	a2,a2,-20 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020156c:	14600593          	li	a1,326
ffffffffc0201570:	00005517          	auipc	a0,0x5
ffffffffc0201574:	2b850513          	addi	a0,a0,696 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201578:	f17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020157c:	00005697          	auipc	a3,0x5
ffffffffc0201580:	46c68693          	addi	a3,a3,1132 # ffffffffc02069e8 <commands+0xa90>
ffffffffc0201584:	00005617          	auipc	a2,0x5
ffffffffc0201588:	fcc60613          	addi	a2,a2,-52 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020158c:	13a00593          	li	a1,314
ffffffffc0201590:	00005517          	auipc	a0,0x5
ffffffffc0201594:	29850513          	addi	a0,a0,664 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201598:	ef7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020159c:	00005697          	auipc	a3,0x5
ffffffffc02015a0:	3ec68693          	addi	a3,a3,1004 # ffffffffc0206988 <commands+0xa30>
ffffffffc02015a4:	00005617          	auipc	a2,0x5
ffffffffc02015a8:	fac60613          	addi	a2,a2,-84 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02015ac:	13800593          	li	a1,312
ffffffffc02015b0:	00005517          	auipc	a0,0x5
ffffffffc02015b4:	27850513          	addi	a0,a0,632 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02015b8:	ed7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02015bc:	00005697          	auipc	a3,0x5
ffffffffc02015c0:	38c68693          	addi	a3,a3,908 # ffffffffc0206948 <commands+0x9f0>
ffffffffc02015c4:	00005617          	auipc	a2,0x5
ffffffffc02015c8:	f8c60613          	addi	a2,a2,-116 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02015cc:	0df00593          	li	a1,223
ffffffffc02015d0:	00005517          	auipc	a0,0x5
ffffffffc02015d4:	25850513          	addi	a0,a0,600 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02015d8:	eb7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02015dc:	00005697          	auipc	a3,0x5
ffffffffc02015e0:	52c68693          	addi	a3,a3,1324 # ffffffffc0206b08 <commands+0xbb0>
ffffffffc02015e4:	00005617          	auipc	a2,0x5
ffffffffc02015e8:	f6c60613          	addi	a2,a2,-148 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02015ec:	13200593          	li	a1,306
ffffffffc02015f0:	00005517          	auipc	a0,0x5
ffffffffc02015f4:	23850513          	addi	a0,a0,568 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02015f8:	e97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02015fc:	00005697          	auipc	a3,0x5
ffffffffc0201600:	4ec68693          	addi	a3,a3,1260 # ffffffffc0206ae8 <commands+0xb90>
ffffffffc0201604:	00005617          	auipc	a2,0x5
ffffffffc0201608:	f4c60613          	addi	a2,a2,-180 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020160c:	13000593          	li	a1,304
ffffffffc0201610:	00005517          	auipc	a0,0x5
ffffffffc0201614:	21850513          	addi	a0,a0,536 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201618:	e77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020161c:	00005697          	auipc	a3,0x5
ffffffffc0201620:	4a468693          	addi	a3,a3,1188 # ffffffffc0206ac0 <commands+0xb68>
ffffffffc0201624:	00005617          	auipc	a2,0x5
ffffffffc0201628:	f2c60613          	addi	a2,a2,-212 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020162c:	12e00593          	li	a1,302
ffffffffc0201630:	00005517          	auipc	a0,0x5
ffffffffc0201634:	1f850513          	addi	a0,a0,504 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201638:	e57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020163c:	00005697          	auipc	a3,0x5
ffffffffc0201640:	45c68693          	addi	a3,a3,1116 # ffffffffc0206a98 <commands+0xb40>
ffffffffc0201644:	00005617          	auipc	a2,0x5
ffffffffc0201648:	f0c60613          	addi	a2,a2,-244 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020164c:	12d00593          	li	a1,301
ffffffffc0201650:	00005517          	auipc	a0,0x5
ffffffffc0201654:	1d850513          	addi	a0,a0,472 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201658:	e37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc020165c:	00005697          	auipc	a3,0x5
ffffffffc0201660:	42c68693          	addi	a3,a3,1068 # ffffffffc0206a88 <commands+0xb30>
ffffffffc0201664:	00005617          	auipc	a2,0x5
ffffffffc0201668:	eec60613          	addi	a2,a2,-276 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020166c:	12800593          	li	a1,296
ffffffffc0201670:	00005517          	auipc	a0,0x5
ffffffffc0201674:	1b850513          	addi	a0,a0,440 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201678:	e17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020167c:	00005697          	auipc	a3,0x5
ffffffffc0201680:	30c68693          	addi	a3,a3,780 # ffffffffc0206988 <commands+0xa30>
ffffffffc0201684:	00005617          	auipc	a2,0x5
ffffffffc0201688:	ecc60613          	addi	a2,a2,-308 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020168c:	12700593          	li	a1,295
ffffffffc0201690:	00005517          	auipc	a0,0x5
ffffffffc0201694:	19850513          	addi	a0,a0,408 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201698:	df7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020169c:	00005697          	auipc	a3,0x5
ffffffffc02016a0:	3cc68693          	addi	a3,a3,972 # ffffffffc0206a68 <commands+0xb10>
ffffffffc02016a4:	00005617          	auipc	a2,0x5
ffffffffc02016a8:	eac60613          	addi	a2,a2,-340 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02016ac:	12600593          	li	a1,294
ffffffffc02016b0:	00005517          	auipc	a0,0x5
ffffffffc02016b4:	17850513          	addi	a0,a0,376 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02016b8:	dd7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02016bc:	00005697          	auipc	a3,0x5
ffffffffc02016c0:	37c68693          	addi	a3,a3,892 # ffffffffc0206a38 <commands+0xae0>
ffffffffc02016c4:	00005617          	auipc	a2,0x5
ffffffffc02016c8:	e8c60613          	addi	a2,a2,-372 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02016cc:	12500593          	li	a1,293
ffffffffc02016d0:	00005517          	auipc	a0,0x5
ffffffffc02016d4:	15850513          	addi	a0,a0,344 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02016d8:	db7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02016dc:	00005697          	auipc	a3,0x5
ffffffffc02016e0:	34468693          	addi	a3,a3,836 # ffffffffc0206a20 <commands+0xac8>
ffffffffc02016e4:	00005617          	auipc	a2,0x5
ffffffffc02016e8:	e6c60613          	addi	a2,a2,-404 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02016ec:	12400593          	li	a1,292
ffffffffc02016f0:	00005517          	auipc	a0,0x5
ffffffffc02016f4:	13850513          	addi	a0,a0,312 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02016f8:	d97fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016fc:	00005697          	auipc	a3,0x5
ffffffffc0201700:	28c68693          	addi	a3,a3,652 # ffffffffc0206988 <commands+0xa30>
ffffffffc0201704:	00005617          	auipc	a2,0x5
ffffffffc0201708:	e4c60613          	addi	a2,a2,-436 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020170c:	11e00593          	li	a1,286
ffffffffc0201710:	00005517          	auipc	a0,0x5
ffffffffc0201714:	11850513          	addi	a0,a0,280 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201718:	d77fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc020171c:	00005697          	auipc	a3,0x5
ffffffffc0201720:	2ec68693          	addi	a3,a3,748 # ffffffffc0206a08 <commands+0xab0>
ffffffffc0201724:	00005617          	auipc	a2,0x5
ffffffffc0201728:	e2c60613          	addi	a2,a2,-468 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020172c:	11900593          	li	a1,281
ffffffffc0201730:	00005517          	auipc	a0,0x5
ffffffffc0201734:	0f850513          	addi	a0,a0,248 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201738:	d57fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020173c:	00005697          	auipc	a3,0x5
ffffffffc0201740:	3ec68693          	addi	a3,a3,1004 # ffffffffc0206b28 <commands+0xbd0>
ffffffffc0201744:	00005617          	auipc	a2,0x5
ffffffffc0201748:	e0c60613          	addi	a2,a2,-500 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020174c:	13700593          	li	a1,311
ffffffffc0201750:	00005517          	auipc	a0,0x5
ffffffffc0201754:	0d850513          	addi	a0,a0,216 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201758:	d37fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc020175c:	00005697          	auipc	a3,0x5
ffffffffc0201760:	3fc68693          	addi	a3,a3,1020 # ffffffffc0206b58 <commands+0xc00>
ffffffffc0201764:	00005617          	auipc	a2,0x5
ffffffffc0201768:	dec60613          	addi	a2,a2,-532 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020176c:	14700593          	li	a1,327
ffffffffc0201770:	00005517          	auipc	a0,0x5
ffffffffc0201774:	0b850513          	addi	a0,a0,184 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201778:	d17fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc020177c:	00005697          	auipc	a3,0x5
ffffffffc0201780:	0c468693          	addi	a3,a3,196 # ffffffffc0206840 <commands+0x8e8>
ffffffffc0201784:	00005617          	auipc	a2,0x5
ffffffffc0201788:	dcc60613          	addi	a2,a2,-564 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020178c:	11300593          	li	a1,275
ffffffffc0201790:	00005517          	auipc	a0,0x5
ffffffffc0201794:	09850513          	addi	a0,a0,152 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201798:	cf7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020179c:	00005697          	auipc	a3,0x5
ffffffffc02017a0:	0e468693          	addi	a3,a3,228 # ffffffffc0206880 <commands+0x928>
ffffffffc02017a4:	00005617          	auipc	a2,0x5
ffffffffc02017a8:	dac60613          	addi	a2,a2,-596 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02017ac:	0d800593          	li	a1,216
ffffffffc02017b0:	00005517          	auipc	a0,0x5
ffffffffc02017b4:	07850513          	addi	a0,a0,120 # ffffffffc0206828 <commands+0x8d0>
ffffffffc02017b8:	cd7fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02017bc <default_free_pages>:
{
ffffffffc02017bc:	1141                	addi	sp,sp,-16
ffffffffc02017be:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017c0:	14058463          	beqz	a1,ffffffffc0201908 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc02017c4:	00659693          	slli	a3,a1,0x6
ffffffffc02017c8:	96aa                	add	a3,a3,a0
ffffffffc02017ca:	87aa                	mv	a5,a0
ffffffffc02017cc:	02d50263          	beq	a0,a3,ffffffffc02017f0 <default_free_pages+0x34>
ffffffffc02017d0:	6798                	ld	a4,8(a5)
ffffffffc02017d2:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017d4:	10071a63          	bnez	a4,ffffffffc02018e8 <default_free_pages+0x12c>
ffffffffc02017d8:	6798                	ld	a4,8(a5)
ffffffffc02017da:	8b09                	andi	a4,a4,2
ffffffffc02017dc:	10071663          	bnez	a4,ffffffffc02018e8 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02017e0:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02017e4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02017e8:	04078793          	addi	a5,a5,64
ffffffffc02017ec:	fed792e3          	bne	a5,a3,ffffffffc02017d0 <default_free_pages+0x14>
    base->property = n;
ffffffffc02017f0:	2581                	sext.w	a1,a1
ffffffffc02017f2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02017f4:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017f8:	4789                	li	a5,2
ffffffffc02017fa:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02017fe:	000d5697          	auipc	a3,0xd5
ffffffffc0201802:	d5268693          	addi	a3,a3,-686 # ffffffffc02d6550 <free_area>
ffffffffc0201806:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201808:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020180a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020180e:	9db9                	addw	a1,a1,a4
ffffffffc0201810:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201812:	0ad78463          	beq	a5,a3,ffffffffc02018ba <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201816:	fe878713          	addi	a4,a5,-24
ffffffffc020181a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020181e:	4581                	li	a1,0
            if (base < page)
ffffffffc0201820:	00e56a63          	bltu	a0,a4,ffffffffc0201834 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201824:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201826:	04d70c63          	beq	a4,a3,ffffffffc020187e <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc020182a:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc020182c:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201830:	fee57ae3          	bgeu	a0,a4,ffffffffc0201824 <default_free_pages+0x68>
ffffffffc0201834:	c199                	beqz	a1,ffffffffc020183a <default_free_pages+0x7e>
ffffffffc0201836:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020183a:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020183c:	e390                	sd	a2,0(a5)
ffffffffc020183e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201840:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201842:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0201844:	00d70d63          	beq	a4,a3,ffffffffc020185e <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201848:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc020184c:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201850:	02059813          	slli	a6,a1,0x20
ffffffffc0201854:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201858:	97b2                	add	a5,a5,a2
ffffffffc020185a:	02f50c63          	beq	a0,a5,ffffffffc0201892 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020185e:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201860:	00d78c63          	beq	a5,a3,ffffffffc0201878 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201864:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201866:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc020186a:	02061593          	slli	a1,a2,0x20
ffffffffc020186e:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201872:	972a                	add	a4,a4,a0
ffffffffc0201874:	04e68a63          	beq	a3,a4,ffffffffc02018c8 <default_free_pages+0x10c>
}
ffffffffc0201878:	60a2                	ld	ra,8(sp)
ffffffffc020187a:	0141                	addi	sp,sp,16
ffffffffc020187c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020187e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201880:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201882:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201884:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201886:	02d70763          	beq	a4,a3,ffffffffc02018b4 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc020188a:	8832                	mv	a6,a2
ffffffffc020188c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020188e:	87ba                	mv	a5,a4
ffffffffc0201890:	bf71                	j	ffffffffc020182c <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201892:	491c                	lw	a5,16(a0)
ffffffffc0201894:	9dbd                	addw	a1,a1,a5
ffffffffc0201896:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020189a:	57f5                	li	a5,-3
ffffffffc020189c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018a0:	01853803          	ld	a6,24(a0)
ffffffffc02018a4:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02018a6:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02018a8:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc02018ac:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02018ae:	0105b023          	sd	a6,0(a1)
ffffffffc02018b2:	b77d                	j	ffffffffc0201860 <default_free_pages+0xa4>
ffffffffc02018b4:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc02018b6:	873e                	mv	a4,a5
ffffffffc02018b8:	bf41                	j	ffffffffc0201848 <default_free_pages+0x8c>
}
ffffffffc02018ba:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018bc:	e390                	sd	a2,0(a5)
ffffffffc02018be:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018c0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018c2:	ed1c                	sd	a5,24(a0)
ffffffffc02018c4:	0141                	addi	sp,sp,16
ffffffffc02018c6:	8082                	ret
            base->property += p->property;
ffffffffc02018c8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02018cc:	ff078693          	addi	a3,a5,-16
ffffffffc02018d0:	9e39                	addw	a2,a2,a4
ffffffffc02018d2:	c910                	sw	a2,16(a0)
ffffffffc02018d4:	5775                	li	a4,-3
ffffffffc02018d6:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018da:	6398                	ld	a4,0(a5)
ffffffffc02018dc:	679c                	ld	a5,8(a5)
}
ffffffffc02018de:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02018e0:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02018e2:	e398                	sd	a4,0(a5)
ffffffffc02018e4:	0141                	addi	sp,sp,16
ffffffffc02018e6:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02018e8:	00005697          	auipc	a3,0x5
ffffffffc02018ec:	28868693          	addi	a3,a3,648 # ffffffffc0206b70 <commands+0xc18>
ffffffffc02018f0:	00005617          	auipc	a2,0x5
ffffffffc02018f4:	c6060613          	addi	a2,a2,-928 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02018f8:	09400593          	li	a1,148
ffffffffc02018fc:	00005517          	auipc	a0,0x5
ffffffffc0201900:	f2c50513          	addi	a0,a0,-212 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201904:	b8bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201908:	00005697          	auipc	a3,0x5
ffffffffc020190c:	26068693          	addi	a3,a3,608 # ffffffffc0206b68 <commands+0xc10>
ffffffffc0201910:	00005617          	auipc	a2,0x5
ffffffffc0201914:	c4060613          	addi	a2,a2,-960 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0201918:	09000593          	li	a1,144
ffffffffc020191c:	00005517          	auipc	a0,0x5
ffffffffc0201920:	f0c50513          	addi	a0,a0,-244 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201924:	b6bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201928 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201928:	c941                	beqz	a0,ffffffffc02019b8 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc020192a:	000d5597          	auipc	a1,0xd5
ffffffffc020192e:	c2658593          	addi	a1,a1,-986 # ffffffffc02d6550 <free_area>
ffffffffc0201932:	0105a803          	lw	a6,16(a1)
ffffffffc0201936:	872a                	mv	a4,a0
ffffffffc0201938:	02081793          	slli	a5,a6,0x20
ffffffffc020193c:	9381                	srli	a5,a5,0x20
ffffffffc020193e:	00a7ee63          	bltu	a5,a0,ffffffffc020195a <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201942:	87ae                	mv	a5,a1
ffffffffc0201944:	a801                	j	ffffffffc0201954 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201946:	ff87a683          	lw	a3,-8(a5)
ffffffffc020194a:	02069613          	slli	a2,a3,0x20
ffffffffc020194e:	9201                	srli	a2,a2,0x20
ffffffffc0201950:	00e67763          	bgeu	a2,a4,ffffffffc020195e <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201954:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201956:	feb798e3          	bne	a5,a1,ffffffffc0201946 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020195a:	4501                	li	a0,0
}
ffffffffc020195c:	8082                	ret
    return listelm->prev;
ffffffffc020195e:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201962:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201966:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020196a:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc020196e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201972:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201976:	02c77863          	bgeu	a4,a2,ffffffffc02019a6 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc020197a:	071a                	slli	a4,a4,0x6
ffffffffc020197c:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020197e:	41c686bb          	subw	a3,a3,t3
ffffffffc0201982:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201984:	00870613          	addi	a2,a4,8
ffffffffc0201988:	4689                	li	a3,2
ffffffffc020198a:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020198e:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201992:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201996:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020199a:	e290                	sd	a2,0(a3)
ffffffffc020199c:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02019a0:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02019a2:	01173c23          	sd	a7,24(a4)
ffffffffc02019a6:	41c8083b          	subw	a6,a6,t3
ffffffffc02019aa:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02019ae:	5775                	li	a4,-3
ffffffffc02019b0:	17c1                	addi	a5,a5,-16
ffffffffc02019b2:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02019b6:	8082                	ret
{
ffffffffc02019b8:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02019ba:	00005697          	auipc	a3,0x5
ffffffffc02019be:	1ae68693          	addi	a3,a3,430 # ffffffffc0206b68 <commands+0xc10>
ffffffffc02019c2:	00005617          	auipc	a2,0x5
ffffffffc02019c6:	b8e60613          	addi	a2,a2,-1138 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02019ca:	06c00593          	li	a1,108
ffffffffc02019ce:	00005517          	auipc	a0,0x5
ffffffffc02019d2:	e5a50513          	addi	a0,a0,-422 # ffffffffc0206828 <commands+0x8d0>
{
ffffffffc02019d6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019d8:	ab7fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02019dc <default_init_memmap>:
{
ffffffffc02019dc:	1141                	addi	sp,sp,-16
ffffffffc02019de:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019e0:	c5f1                	beqz	a1,ffffffffc0201aac <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc02019e2:	00659693          	slli	a3,a1,0x6
ffffffffc02019e6:	96aa                	add	a3,a3,a0
ffffffffc02019e8:	87aa                	mv	a5,a0
ffffffffc02019ea:	00d50f63          	beq	a0,a3,ffffffffc0201a08 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02019ee:	6798                	ld	a4,8(a5)
ffffffffc02019f0:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc02019f2:	cf49                	beqz	a4,ffffffffc0201a8c <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02019f4:	0007a823          	sw	zero,16(a5)
ffffffffc02019f8:	0007b423          	sd	zero,8(a5)
ffffffffc02019fc:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201a00:	04078793          	addi	a5,a5,64
ffffffffc0201a04:	fed795e3          	bne	a5,a3,ffffffffc02019ee <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201a08:	2581                	sext.w	a1,a1
ffffffffc0201a0a:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201a0c:	4789                	li	a5,2
ffffffffc0201a0e:	00850713          	addi	a4,a0,8
ffffffffc0201a12:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201a16:	000d5697          	auipc	a3,0xd5
ffffffffc0201a1a:	b3a68693          	addi	a3,a3,-1222 # ffffffffc02d6550 <free_area>
ffffffffc0201a1e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201a20:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a22:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201a26:	9db9                	addw	a1,a1,a4
ffffffffc0201a28:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a2a:	04d78a63          	beq	a5,a3,ffffffffc0201a7e <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a2e:	fe878713          	addi	a4,a5,-24
ffffffffc0201a32:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201a36:	4581                	li	a1,0
            if (base < page)
ffffffffc0201a38:	00e56a63          	bltu	a0,a4,ffffffffc0201a4c <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201a3c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201a3e:	02d70263          	beq	a4,a3,ffffffffc0201a62 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201a42:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201a44:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201a48:	fee57ae3          	bgeu	a0,a4,ffffffffc0201a3c <default_init_memmap+0x60>
ffffffffc0201a4c:	c199                	beqz	a1,ffffffffc0201a52 <default_init_memmap+0x76>
ffffffffc0201a4e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201a52:	6398                	ld	a4,0(a5)
}
ffffffffc0201a54:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201a56:	e390                	sd	a2,0(a5)
ffffffffc0201a58:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201a5a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a5c:	ed18                	sd	a4,24(a0)
ffffffffc0201a5e:	0141                	addi	sp,sp,16
ffffffffc0201a60:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201a62:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a64:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a66:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a68:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a6a:	00d70663          	beq	a4,a3,ffffffffc0201a76 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201a6e:	8832                	mv	a6,a2
ffffffffc0201a70:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201a72:	87ba                	mv	a5,a4
ffffffffc0201a74:	bfc1                	j	ffffffffc0201a44 <default_init_memmap+0x68>
}
ffffffffc0201a76:	60a2                	ld	ra,8(sp)
ffffffffc0201a78:	e290                	sd	a2,0(a3)
ffffffffc0201a7a:	0141                	addi	sp,sp,16
ffffffffc0201a7c:	8082                	ret
ffffffffc0201a7e:	60a2                	ld	ra,8(sp)
ffffffffc0201a80:	e390                	sd	a2,0(a5)
ffffffffc0201a82:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a84:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a86:	ed1c                	sd	a5,24(a0)
ffffffffc0201a88:	0141                	addi	sp,sp,16
ffffffffc0201a8a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a8c:	00005697          	auipc	a3,0x5
ffffffffc0201a90:	10c68693          	addi	a3,a3,268 # ffffffffc0206b98 <commands+0xc40>
ffffffffc0201a94:	00005617          	auipc	a2,0x5
ffffffffc0201a98:	abc60613          	addi	a2,a2,-1348 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0201a9c:	04b00593          	li	a1,75
ffffffffc0201aa0:	00005517          	auipc	a0,0x5
ffffffffc0201aa4:	d8850513          	addi	a0,a0,-632 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201aa8:	9e7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201aac:	00005697          	auipc	a3,0x5
ffffffffc0201ab0:	0bc68693          	addi	a3,a3,188 # ffffffffc0206b68 <commands+0xc10>
ffffffffc0201ab4:	00005617          	auipc	a2,0x5
ffffffffc0201ab8:	a9c60613          	addi	a2,a2,-1380 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0201abc:	04700593          	li	a1,71
ffffffffc0201ac0:	00005517          	auipc	a0,0x5
ffffffffc0201ac4:	d6850513          	addi	a0,a0,-664 # ffffffffc0206828 <commands+0x8d0>
ffffffffc0201ac8:	9c7fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201acc <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201acc:	c94d                	beqz	a0,ffffffffc0201b7e <slob_free+0xb2>
{
ffffffffc0201ace:	1141                	addi	sp,sp,-16
ffffffffc0201ad0:	e022                	sd	s0,0(sp)
ffffffffc0201ad2:	e406                	sd	ra,8(sp)
ffffffffc0201ad4:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201ad6:	e9c1                	bnez	a1,ffffffffc0201b66 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ad8:	100027f3          	csrr	a5,sstatus
ffffffffc0201adc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201ade:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ae0:	ebd9                	bnez	a5,ffffffffc0201b76 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ae2:	000d4617          	auipc	a2,0xd4
ffffffffc0201ae6:	65660613          	addi	a2,a2,1622 # ffffffffc02d6138 <slobfree>
ffffffffc0201aea:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201aec:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201aee:	679c                	ld	a5,8(a5)
ffffffffc0201af0:	02877a63          	bgeu	a4,s0,ffffffffc0201b24 <slob_free+0x58>
ffffffffc0201af4:	00f46463          	bltu	s0,a5,ffffffffc0201afc <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201af8:	fef76ae3          	bltu	a4,a5,ffffffffc0201aec <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201afc:	400c                	lw	a1,0(s0)
ffffffffc0201afe:	00459693          	slli	a3,a1,0x4
ffffffffc0201b02:	96a2                	add	a3,a3,s0
ffffffffc0201b04:	02d78a63          	beq	a5,a3,ffffffffc0201b38 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201b08:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201b0a:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b0c:	00469793          	slli	a5,a3,0x4
ffffffffc0201b10:	97ba                	add	a5,a5,a4
ffffffffc0201b12:	02f40e63          	beq	s0,a5,ffffffffc0201b4e <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201b16:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201b18:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201b1a:	e129                	bnez	a0,ffffffffc0201b5c <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b1c:	60a2                	ld	ra,8(sp)
ffffffffc0201b1e:	6402                	ld	s0,0(sp)
ffffffffc0201b20:	0141                	addi	sp,sp,16
ffffffffc0201b22:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b24:	fcf764e3          	bltu	a4,a5,ffffffffc0201aec <slob_free+0x20>
ffffffffc0201b28:	fcf472e3          	bgeu	s0,a5,ffffffffc0201aec <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201b2c:	400c                	lw	a1,0(s0)
ffffffffc0201b2e:	00459693          	slli	a3,a1,0x4
ffffffffc0201b32:	96a2                	add	a3,a3,s0
ffffffffc0201b34:	fcd79ae3          	bne	a5,a3,ffffffffc0201b08 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201b38:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b3a:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b3c:	9db5                	addw	a1,a1,a3
ffffffffc0201b3e:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201b40:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201b42:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b44:	00469793          	slli	a5,a3,0x4
ffffffffc0201b48:	97ba                	add	a5,a5,a4
ffffffffc0201b4a:	fcf416e3          	bne	s0,a5,ffffffffc0201b16 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201b4e:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201b50:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201b52:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201b54:	9ebd                	addw	a3,a3,a5
ffffffffc0201b56:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201b58:	e70c                	sd	a1,8(a4)
ffffffffc0201b5a:	d169                	beqz	a0,ffffffffc0201b1c <slob_free+0x50>
}
ffffffffc0201b5c:	6402                	ld	s0,0(sp)
ffffffffc0201b5e:	60a2                	ld	ra,8(sp)
ffffffffc0201b60:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201b62:	e4dfe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201b66:	25bd                	addiw	a1,a1,15
ffffffffc0201b68:	8191                	srli	a1,a1,0x4
ffffffffc0201b6a:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b6c:	100027f3          	csrr	a5,sstatus
ffffffffc0201b70:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b72:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b74:	d7bd                	beqz	a5,ffffffffc0201ae2 <slob_free+0x16>
        intr_disable();
ffffffffc0201b76:	e3ffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201b7a:	4505                	li	a0,1
ffffffffc0201b7c:	b79d                	j	ffffffffc0201ae2 <slob_free+0x16>
ffffffffc0201b7e:	8082                	ret

ffffffffc0201b80 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b80:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b82:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b84:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b88:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b8a:	352000ef          	jal	ra,ffffffffc0201edc <alloc_pages>
	if (!page)
ffffffffc0201b8e:	c91d                	beqz	a0,ffffffffc0201bc4 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b90:	000d9697          	auipc	a3,0xd9
ffffffffc0201b94:	a306b683          	ld	a3,-1488(a3) # ffffffffc02da5c0 <pages>
ffffffffc0201b98:	8d15                	sub	a0,a0,a3
ffffffffc0201b9a:	8519                	srai	a0,a0,0x6
ffffffffc0201b9c:	00006697          	auipc	a3,0x6
ffffffffc0201ba0:	6846b683          	ld	a3,1668(a3) # ffffffffc0208220 <nbase>
ffffffffc0201ba4:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201ba6:	00c51793          	slli	a5,a0,0xc
ffffffffc0201baa:	83b1                	srli	a5,a5,0xc
ffffffffc0201bac:	000d9717          	auipc	a4,0xd9
ffffffffc0201bb0:	a0c73703          	ld	a4,-1524(a4) # ffffffffc02da5b8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201bb4:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201bb6:	00e7fa63          	bgeu	a5,a4,ffffffffc0201bca <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201bba:	000d9697          	auipc	a3,0xd9
ffffffffc0201bbe:	a166b683          	ld	a3,-1514(a3) # ffffffffc02da5d0 <va_pa_offset>
ffffffffc0201bc2:	9536                	add	a0,a0,a3
}
ffffffffc0201bc4:	60a2                	ld	ra,8(sp)
ffffffffc0201bc6:	0141                	addi	sp,sp,16
ffffffffc0201bc8:	8082                	ret
ffffffffc0201bca:	86aa                	mv	a3,a0
ffffffffc0201bcc:	00005617          	auipc	a2,0x5
ffffffffc0201bd0:	02c60613          	addi	a2,a2,44 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc0201bd4:	07200593          	li	a1,114
ffffffffc0201bd8:	00005517          	auipc	a0,0x5
ffffffffc0201bdc:	04850513          	addi	a0,a0,72 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc0201be0:	8affe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201be4 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201be4:	1101                	addi	sp,sp,-32
ffffffffc0201be6:	ec06                	sd	ra,24(sp)
ffffffffc0201be8:	e822                	sd	s0,16(sp)
ffffffffc0201bea:	e426                	sd	s1,8(sp)
ffffffffc0201bec:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bee:	01050713          	addi	a4,a0,16
ffffffffc0201bf2:	6785                	lui	a5,0x1
ffffffffc0201bf4:	0cf77363          	bgeu	a4,a5,ffffffffc0201cba <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201bf8:	00f50493          	addi	s1,a0,15
ffffffffc0201bfc:	8091                	srli	s1,s1,0x4
ffffffffc0201bfe:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c00:	10002673          	csrr	a2,sstatus
ffffffffc0201c04:	8a09                	andi	a2,a2,2
ffffffffc0201c06:	e25d                	bnez	a2,ffffffffc0201cac <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201c08:	000d4917          	auipc	s2,0xd4
ffffffffc0201c0c:	53090913          	addi	s2,s2,1328 # ffffffffc02d6138 <slobfree>
ffffffffc0201c10:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c14:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201c16:	4398                	lw	a4,0(a5)
ffffffffc0201c18:	08975e63          	bge	a4,s1,ffffffffc0201cb4 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201c1c:	00f68b63          	beq	a3,a5,ffffffffc0201c32 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c20:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c22:	4018                	lw	a4,0(s0)
ffffffffc0201c24:	02975a63          	bge	a4,s1,ffffffffc0201c58 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201c28:	00093683          	ld	a3,0(s2)
ffffffffc0201c2c:	87a2                	mv	a5,s0
ffffffffc0201c2e:	fef699e3          	bne	a3,a5,ffffffffc0201c20 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201c32:	ee31                	bnez	a2,ffffffffc0201c8e <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c34:	4501                	li	a0,0
ffffffffc0201c36:	f4bff0ef          	jal	ra,ffffffffc0201b80 <__slob_get_free_pages.constprop.0>
ffffffffc0201c3a:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201c3c:	cd05                	beqz	a0,ffffffffc0201c74 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c3e:	6585                	lui	a1,0x1
ffffffffc0201c40:	e8dff0ef          	jal	ra,ffffffffc0201acc <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c44:	10002673          	csrr	a2,sstatus
ffffffffc0201c48:	8a09                	andi	a2,a2,2
ffffffffc0201c4a:	ee05                	bnez	a2,ffffffffc0201c82 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201c4c:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c50:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c52:	4018                	lw	a4,0(s0)
ffffffffc0201c54:	fc974ae3          	blt	a4,s1,ffffffffc0201c28 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c58:	04e48763          	beq	s1,a4,ffffffffc0201ca6 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201c5c:	00449693          	slli	a3,s1,0x4
ffffffffc0201c60:	96a2                	add	a3,a3,s0
ffffffffc0201c62:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201c64:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201c66:	9f05                	subw	a4,a4,s1
ffffffffc0201c68:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201c6a:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201c6c:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201c6e:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201c72:	e20d                	bnez	a2,ffffffffc0201c94 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201c74:	60e2                	ld	ra,24(sp)
ffffffffc0201c76:	8522                	mv	a0,s0
ffffffffc0201c78:	6442                	ld	s0,16(sp)
ffffffffc0201c7a:	64a2                	ld	s1,8(sp)
ffffffffc0201c7c:	6902                	ld	s2,0(sp)
ffffffffc0201c7e:	6105                	addi	sp,sp,32
ffffffffc0201c80:	8082                	ret
        intr_disable();
ffffffffc0201c82:	d33fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201c86:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201c8a:	4605                	li	a2,1
ffffffffc0201c8c:	b7d1                	j	ffffffffc0201c50 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201c8e:	d21fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201c92:	b74d                	j	ffffffffc0201c34 <slob_alloc.constprop.0+0x50>
ffffffffc0201c94:	d1bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201c98:	60e2                	ld	ra,24(sp)
ffffffffc0201c9a:	8522                	mv	a0,s0
ffffffffc0201c9c:	6442                	ld	s0,16(sp)
ffffffffc0201c9e:	64a2                	ld	s1,8(sp)
ffffffffc0201ca0:	6902                	ld	s2,0(sp)
ffffffffc0201ca2:	6105                	addi	sp,sp,32
ffffffffc0201ca4:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201ca6:	6418                	ld	a4,8(s0)
ffffffffc0201ca8:	e798                	sd	a4,8(a5)
ffffffffc0201caa:	b7d1                	j	ffffffffc0201c6e <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201cac:	d09fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201cb0:	4605                	li	a2,1
ffffffffc0201cb2:	bf99                	j	ffffffffc0201c08 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201cb4:	843e                	mv	s0,a5
ffffffffc0201cb6:	87b6                	mv	a5,a3
ffffffffc0201cb8:	b745                	j	ffffffffc0201c58 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201cba:	00005697          	auipc	a3,0x5
ffffffffc0201cbe:	f7668693          	addi	a3,a3,-138 # ffffffffc0206c30 <default_pmm_manager+0x70>
ffffffffc0201cc2:	00005617          	auipc	a2,0x5
ffffffffc0201cc6:	88e60613          	addi	a2,a2,-1906 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0201cca:	06300593          	li	a1,99
ffffffffc0201cce:	00005517          	auipc	a0,0x5
ffffffffc0201cd2:	f8250513          	addi	a0,a0,-126 # ffffffffc0206c50 <default_pmm_manager+0x90>
ffffffffc0201cd6:	fb8fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201cda <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201cda:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201cdc:	00005517          	auipc	a0,0x5
ffffffffc0201ce0:	f8c50513          	addi	a0,a0,-116 # ffffffffc0206c68 <default_pmm_manager+0xa8>
{
ffffffffc0201ce4:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201ce6:	caefe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201cea:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cec:	00005517          	auipc	a0,0x5
ffffffffc0201cf0:	f9450513          	addi	a0,a0,-108 # ffffffffc0206c80 <default_pmm_manager+0xc0>
}
ffffffffc0201cf4:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cf6:	c9efe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201cfa <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201cfa:	4501                	li	a0,0
ffffffffc0201cfc:	8082                	ret

ffffffffc0201cfe <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201cfe:	1101                	addi	sp,sp,-32
ffffffffc0201d00:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d02:	6905                	lui	s2,0x1
{
ffffffffc0201d04:	e822                	sd	s0,16(sp)
ffffffffc0201d06:	ec06                	sd	ra,24(sp)
ffffffffc0201d08:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d0a:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bd9>
{
ffffffffc0201d0e:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d10:	04a7f963          	bgeu	a5,a0,ffffffffc0201d62 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201d14:	4561                	li	a0,24
ffffffffc0201d16:	ecfff0ef          	jal	ra,ffffffffc0201be4 <slob_alloc.constprop.0>
ffffffffc0201d1a:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201d1c:	c929                	beqz	a0,ffffffffc0201d6e <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201d1e:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201d22:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d24:	00f95763          	bge	s2,a5,ffffffffc0201d32 <kmalloc+0x34>
ffffffffc0201d28:	6705                	lui	a4,0x1
ffffffffc0201d2a:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201d2c:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d2e:	fef74ee3          	blt	a4,a5,ffffffffc0201d2a <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201d32:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d34:	e4dff0ef          	jal	ra,ffffffffc0201b80 <__slob_get_free_pages.constprop.0>
ffffffffc0201d38:	e488                	sd	a0,8(s1)
ffffffffc0201d3a:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201d3c:	c525                	beqz	a0,ffffffffc0201da4 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d3e:	100027f3          	csrr	a5,sstatus
ffffffffc0201d42:	8b89                	andi	a5,a5,2
ffffffffc0201d44:	ef8d                	bnez	a5,ffffffffc0201d7e <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201d46:	000d9797          	auipc	a5,0xd9
ffffffffc0201d4a:	85a78793          	addi	a5,a5,-1958 # ffffffffc02da5a0 <bigblocks>
ffffffffc0201d4e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d50:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d52:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201d54:	60e2                	ld	ra,24(sp)
ffffffffc0201d56:	8522                	mv	a0,s0
ffffffffc0201d58:	6442                	ld	s0,16(sp)
ffffffffc0201d5a:	64a2                	ld	s1,8(sp)
ffffffffc0201d5c:	6902                	ld	s2,0(sp)
ffffffffc0201d5e:	6105                	addi	sp,sp,32
ffffffffc0201d60:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d62:	0541                	addi	a0,a0,16
ffffffffc0201d64:	e81ff0ef          	jal	ra,ffffffffc0201be4 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d68:	01050413          	addi	s0,a0,16
ffffffffc0201d6c:	f565                	bnez	a0,ffffffffc0201d54 <kmalloc+0x56>
ffffffffc0201d6e:	4401                	li	s0,0
}
ffffffffc0201d70:	60e2                	ld	ra,24(sp)
ffffffffc0201d72:	8522                	mv	a0,s0
ffffffffc0201d74:	6442                	ld	s0,16(sp)
ffffffffc0201d76:	64a2                	ld	s1,8(sp)
ffffffffc0201d78:	6902                	ld	s2,0(sp)
ffffffffc0201d7a:	6105                	addi	sp,sp,32
ffffffffc0201d7c:	8082                	ret
        intr_disable();
ffffffffc0201d7e:	c37fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d82:	000d9797          	auipc	a5,0xd9
ffffffffc0201d86:	81e78793          	addi	a5,a5,-2018 # ffffffffc02da5a0 <bigblocks>
ffffffffc0201d8a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d8c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d8e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201d90:	c1ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201d94:	6480                	ld	s0,8(s1)
}
ffffffffc0201d96:	60e2                	ld	ra,24(sp)
ffffffffc0201d98:	64a2                	ld	s1,8(sp)
ffffffffc0201d9a:	8522                	mv	a0,s0
ffffffffc0201d9c:	6442                	ld	s0,16(sp)
ffffffffc0201d9e:	6902                	ld	s2,0(sp)
ffffffffc0201da0:	6105                	addi	sp,sp,32
ffffffffc0201da2:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201da4:	45e1                	li	a1,24
ffffffffc0201da6:	8526                	mv	a0,s1
ffffffffc0201da8:	d25ff0ef          	jal	ra,ffffffffc0201acc <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201dac:	b765                	j	ffffffffc0201d54 <kmalloc+0x56>

ffffffffc0201dae <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201dae:	c169                	beqz	a0,ffffffffc0201e70 <kfree+0xc2>
{
ffffffffc0201db0:	1101                	addi	sp,sp,-32
ffffffffc0201db2:	e822                	sd	s0,16(sp)
ffffffffc0201db4:	ec06                	sd	ra,24(sp)
ffffffffc0201db6:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201db8:	03451793          	slli	a5,a0,0x34
ffffffffc0201dbc:	842a                	mv	s0,a0
ffffffffc0201dbe:	e3d9                	bnez	a5,ffffffffc0201e44 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dc0:	100027f3          	csrr	a5,sstatus
ffffffffc0201dc4:	8b89                	andi	a5,a5,2
ffffffffc0201dc6:	e7d9                	bnez	a5,ffffffffc0201e54 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201dc8:	000d8797          	auipc	a5,0xd8
ffffffffc0201dcc:	7d87b783          	ld	a5,2008(a5) # ffffffffc02da5a0 <bigblocks>
    return 0;
ffffffffc0201dd0:	4601                	li	a2,0
ffffffffc0201dd2:	cbad                	beqz	a5,ffffffffc0201e44 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201dd4:	000d8697          	auipc	a3,0xd8
ffffffffc0201dd8:	7cc68693          	addi	a3,a3,1996 # ffffffffc02da5a0 <bigblocks>
ffffffffc0201ddc:	a021                	j	ffffffffc0201de4 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201dde:	01048693          	addi	a3,s1,16
ffffffffc0201de2:	c3a5                	beqz	a5,ffffffffc0201e42 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201de4:	6798                	ld	a4,8(a5)
ffffffffc0201de6:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201de8:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201dea:	fe871ae3          	bne	a4,s0,ffffffffc0201dde <kfree+0x30>
				*last = bb->next;
ffffffffc0201dee:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201df0:	ee2d                	bnez	a2,ffffffffc0201e6a <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201df2:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201df6:	4098                	lw	a4,0(s1)
ffffffffc0201df8:	08f46963          	bltu	s0,a5,ffffffffc0201e8a <kfree+0xdc>
ffffffffc0201dfc:	000d8697          	auipc	a3,0xd8
ffffffffc0201e00:	7d46b683          	ld	a3,2004(a3) # ffffffffc02da5d0 <va_pa_offset>
ffffffffc0201e04:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201e06:	8031                	srli	s0,s0,0xc
ffffffffc0201e08:	000d8797          	auipc	a5,0xd8
ffffffffc0201e0c:	7b07b783          	ld	a5,1968(a5) # ffffffffc02da5b8 <npage>
ffffffffc0201e10:	06f47163          	bgeu	s0,a5,ffffffffc0201e72 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e14:	00006517          	auipc	a0,0x6
ffffffffc0201e18:	40c53503          	ld	a0,1036(a0) # ffffffffc0208220 <nbase>
ffffffffc0201e1c:	8c09                	sub	s0,s0,a0
ffffffffc0201e1e:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201e20:	000d8517          	auipc	a0,0xd8
ffffffffc0201e24:	7a053503          	ld	a0,1952(a0) # ffffffffc02da5c0 <pages>
ffffffffc0201e28:	4585                	li	a1,1
ffffffffc0201e2a:	9522                	add	a0,a0,s0
ffffffffc0201e2c:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201e30:	0ea000ef          	jal	ra,ffffffffc0201f1a <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e34:	6442                	ld	s0,16(sp)
ffffffffc0201e36:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e38:	8526                	mv	a0,s1
}
ffffffffc0201e3a:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e3c:	45e1                	li	a1,24
}
ffffffffc0201e3e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e40:	b171                	j	ffffffffc0201acc <slob_free>
ffffffffc0201e42:	e20d                	bnez	a2,ffffffffc0201e64 <kfree+0xb6>
ffffffffc0201e44:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201e48:	6442                	ld	s0,16(sp)
ffffffffc0201e4a:	60e2                	ld	ra,24(sp)
ffffffffc0201e4c:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e4e:	4581                	li	a1,0
}
ffffffffc0201e50:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e52:	b9ad                	j	ffffffffc0201acc <slob_free>
        intr_disable();
ffffffffc0201e54:	b61fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e58:	000d8797          	auipc	a5,0xd8
ffffffffc0201e5c:	7487b783          	ld	a5,1864(a5) # ffffffffc02da5a0 <bigblocks>
        return 1;
ffffffffc0201e60:	4605                	li	a2,1
ffffffffc0201e62:	fbad                	bnez	a5,ffffffffc0201dd4 <kfree+0x26>
        intr_enable();
ffffffffc0201e64:	b4bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e68:	bff1                	j	ffffffffc0201e44 <kfree+0x96>
ffffffffc0201e6a:	b45fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e6e:	b751                	j	ffffffffc0201df2 <kfree+0x44>
ffffffffc0201e70:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e72:	00005617          	auipc	a2,0x5
ffffffffc0201e76:	e5660613          	addi	a2,a2,-426 # ffffffffc0206cc8 <default_pmm_manager+0x108>
ffffffffc0201e7a:	06a00593          	li	a1,106
ffffffffc0201e7e:	00005517          	auipc	a0,0x5
ffffffffc0201e82:	da250513          	addi	a0,a0,-606 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc0201e86:	e08fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e8a:	86a2                	mv	a3,s0
ffffffffc0201e8c:	00005617          	auipc	a2,0x5
ffffffffc0201e90:	e1460613          	addi	a2,a2,-492 # ffffffffc0206ca0 <default_pmm_manager+0xe0>
ffffffffc0201e94:	07800593          	li	a1,120
ffffffffc0201e98:	00005517          	auipc	a0,0x5
ffffffffc0201e9c:	d8850513          	addi	a0,a0,-632 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc0201ea0:	deefe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ea4 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201ea4:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201ea6:	00005617          	auipc	a2,0x5
ffffffffc0201eaa:	e2260613          	addi	a2,a2,-478 # ffffffffc0206cc8 <default_pmm_manager+0x108>
ffffffffc0201eae:	06a00593          	li	a1,106
ffffffffc0201eb2:	00005517          	auipc	a0,0x5
ffffffffc0201eb6:	d6e50513          	addi	a0,a0,-658 # ffffffffc0206c20 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201eba:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201ebc:	dd2fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ec0 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201ec0:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201ec2:	00005617          	auipc	a2,0x5
ffffffffc0201ec6:	e2660613          	addi	a2,a2,-474 # ffffffffc0206ce8 <default_pmm_manager+0x128>
ffffffffc0201eca:	08000593          	li	a1,128
ffffffffc0201ece:	00005517          	auipc	a0,0x5
ffffffffc0201ed2:	d5250513          	addi	a0,a0,-686 # ffffffffc0206c20 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201ed6:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201ed8:	db6fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201edc <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201edc:	100027f3          	csrr	a5,sstatus
ffffffffc0201ee0:	8b89                	andi	a5,a5,2
ffffffffc0201ee2:	e799                	bnez	a5,ffffffffc0201ef0 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ee4:	000d8797          	auipc	a5,0xd8
ffffffffc0201ee8:	6e47b783          	ld	a5,1764(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc0201eec:	6f9c                	ld	a5,24(a5)
ffffffffc0201eee:	8782                	jr	a5
{
ffffffffc0201ef0:	1141                	addi	sp,sp,-16
ffffffffc0201ef2:	e406                	sd	ra,8(sp)
ffffffffc0201ef4:	e022                	sd	s0,0(sp)
ffffffffc0201ef6:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201ef8:	abdfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201efc:	000d8797          	auipc	a5,0xd8
ffffffffc0201f00:	6cc7b783          	ld	a5,1740(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc0201f04:	6f9c                	ld	a5,24(a5)
ffffffffc0201f06:	8522                	mv	a0,s0
ffffffffc0201f08:	9782                	jalr	a5
ffffffffc0201f0a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f0c:	aa3fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201f10:	60a2                	ld	ra,8(sp)
ffffffffc0201f12:	8522                	mv	a0,s0
ffffffffc0201f14:	6402                	ld	s0,0(sp)
ffffffffc0201f16:	0141                	addi	sp,sp,16
ffffffffc0201f18:	8082                	ret

ffffffffc0201f1a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f1a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f1e:	8b89                	andi	a5,a5,2
ffffffffc0201f20:	e799                	bnez	a5,ffffffffc0201f2e <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201f22:	000d8797          	auipc	a5,0xd8
ffffffffc0201f26:	6a67b783          	ld	a5,1702(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc0201f2a:	739c                	ld	a5,32(a5)
ffffffffc0201f2c:	8782                	jr	a5
{
ffffffffc0201f2e:	1101                	addi	sp,sp,-32
ffffffffc0201f30:	ec06                	sd	ra,24(sp)
ffffffffc0201f32:	e822                	sd	s0,16(sp)
ffffffffc0201f34:	e426                	sd	s1,8(sp)
ffffffffc0201f36:	842a                	mv	s0,a0
ffffffffc0201f38:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201f3a:	a7bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f3e:	000d8797          	auipc	a5,0xd8
ffffffffc0201f42:	68a7b783          	ld	a5,1674(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc0201f46:	739c                	ld	a5,32(a5)
ffffffffc0201f48:	85a6                	mv	a1,s1
ffffffffc0201f4a:	8522                	mv	a0,s0
ffffffffc0201f4c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f4e:	6442                	ld	s0,16(sp)
ffffffffc0201f50:	60e2                	ld	ra,24(sp)
ffffffffc0201f52:	64a2                	ld	s1,8(sp)
ffffffffc0201f54:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f56:	a59fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201f5a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f5a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f5e:	8b89                	andi	a5,a5,2
ffffffffc0201f60:	e799                	bnez	a5,ffffffffc0201f6e <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f62:	000d8797          	auipc	a5,0xd8
ffffffffc0201f66:	6667b783          	ld	a5,1638(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc0201f6a:	779c                	ld	a5,40(a5)
ffffffffc0201f6c:	8782                	jr	a5
{
ffffffffc0201f6e:	1141                	addi	sp,sp,-16
ffffffffc0201f70:	e406                	sd	ra,8(sp)
ffffffffc0201f72:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f74:	a41fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f78:	000d8797          	auipc	a5,0xd8
ffffffffc0201f7c:	6507b783          	ld	a5,1616(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc0201f80:	779c                	ld	a5,40(a5)
ffffffffc0201f82:	9782                	jalr	a5
ffffffffc0201f84:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f86:	a29fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f8a:	60a2                	ld	ra,8(sp)
ffffffffc0201f8c:	8522                	mv	a0,s0
ffffffffc0201f8e:	6402                	ld	s0,0(sp)
ffffffffc0201f90:	0141                	addi	sp,sp,16
ffffffffc0201f92:	8082                	ret

ffffffffc0201f94 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f94:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f98:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201f9c:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f9e:	078e                	slli	a5,a5,0x3
{
ffffffffc0201fa0:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201fa2:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201fa6:	6094                	ld	a3,0(s1)
{
ffffffffc0201fa8:	f04a                	sd	s2,32(sp)
ffffffffc0201faa:	ec4e                	sd	s3,24(sp)
ffffffffc0201fac:	e852                	sd	s4,16(sp)
ffffffffc0201fae:	fc06                	sd	ra,56(sp)
ffffffffc0201fb0:	f822                	sd	s0,48(sp)
ffffffffc0201fb2:	e456                	sd	s5,8(sp)
ffffffffc0201fb4:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201fb6:	0016f793          	andi	a5,a3,1
{
ffffffffc0201fba:	892e                	mv	s2,a1
ffffffffc0201fbc:	8a32                	mv	s4,a2
ffffffffc0201fbe:	000d8997          	auipc	s3,0xd8
ffffffffc0201fc2:	5fa98993          	addi	s3,s3,1530 # ffffffffc02da5b8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201fc6:	efbd                	bnez	a5,ffffffffc0202044 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fc8:	14060c63          	beqz	a2,ffffffffc0202120 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201fcc:	100027f3          	csrr	a5,sstatus
ffffffffc0201fd0:	8b89                	andi	a5,a5,2
ffffffffc0201fd2:	14079963          	bnez	a5,ffffffffc0202124 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fd6:	000d8797          	auipc	a5,0xd8
ffffffffc0201fda:	5f27b783          	ld	a5,1522(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc0201fde:	6f9c                	ld	a5,24(a5)
ffffffffc0201fe0:	4505                	li	a0,1
ffffffffc0201fe2:	9782                	jalr	a5
ffffffffc0201fe4:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fe6:	12040d63          	beqz	s0,ffffffffc0202120 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201fea:	000d8b17          	auipc	s6,0xd8
ffffffffc0201fee:	5d6b0b13          	addi	s6,s6,1494 # ffffffffc02da5c0 <pages>
ffffffffc0201ff2:	000b3503          	ld	a0,0(s6)
ffffffffc0201ff6:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ffa:	000d8997          	auipc	s3,0xd8
ffffffffc0201ffe:	5be98993          	addi	s3,s3,1470 # ffffffffc02da5b8 <npage>
ffffffffc0202002:	40a40533          	sub	a0,s0,a0
ffffffffc0202006:	8519                	srai	a0,a0,0x6
ffffffffc0202008:	9556                	add	a0,a0,s5
ffffffffc020200a:	0009b703          	ld	a4,0(s3)
ffffffffc020200e:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202012:	4685                	li	a3,1
ffffffffc0202014:	c014                	sw	a3,0(s0)
ffffffffc0202016:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202018:	0532                	slli	a0,a0,0xc
ffffffffc020201a:	16e7f763          	bgeu	a5,a4,ffffffffc0202188 <get_pte+0x1f4>
ffffffffc020201e:	000d8797          	auipc	a5,0xd8
ffffffffc0202022:	5b27b783          	ld	a5,1458(a5) # ffffffffc02da5d0 <va_pa_offset>
ffffffffc0202026:	6605                	lui	a2,0x1
ffffffffc0202028:	4581                	li	a1,0
ffffffffc020202a:	953e                	add	a0,a0,a5
ffffffffc020202c:	497030ef          	jal	ra,ffffffffc0205cc2 <memset>
    return page - pages + nbase;
ffffffffc0202030:	000b3683          	ld	a3,0(s6)
ffffffffc0202034:	40d406b3          	sub	a3,s0,a3
ffffffffc0202038:	8699                	srai	a3,a3,0x6
ffffffffc020203a:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020203c:	06aa                	slli	a3,a3,0xa
ffffffffc020203e:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202042:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202044:	77fd                	lui	a5,0xfffff
ffffffffc0202046:	068a                	slli	a3,a3,0x2
ffffffffc0202048:	0009b703          	ld	a4,0(s3)
ffffffffc020204c:	8efd                	and	a3,a3,a5
ffffffffc020204e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202052:	10e7ff63          	bgeu	a5,a4,ffffffffc0202170 <get_pte+0x1dc>
ffffffffc0202056:	000d8a97          	auipc	s5,0xd8
ffffffffc020205a:	57aa8a93          	addi	s5,s5,1402 # ffffffffc02da5d0 <va_pa_offset>
ffffffffc020205e:	000ab403          	ld	s0,0(s5)
ffffffffc0202062:	01595793          	srli	a5,s2,0x15
ffffffffc0202066:	1ff7f793          	andi	a5,a5,511
ffffffffc020206a:	96a2                	add	a3,a3,s0
ffffffffc020206c:	00379413          	slli	s0,a5,0x3
ffffffffc0202070:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202072:	6014                	ld	a3,0(s0)
ffffffffc0202074:	0016f793          	andi	a5,a3,1
ffffffffc0202078:	ebad                	bnez	a5,ffffffffc02020ea <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020207a:	0a0a0363          	beqz	s4,ffffffffc0202120 <get_pte+0x18c>
ffffffffc020207e:	100027f3          	csrr	a5,sstatus
ffffffffc0202082:	8b89                	andi	a5,a5,2
ffffffffc0202084:	efcd                	bnez	a5,ffffffffc020213e <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202086:	000d8797          	auipc	a5,0xd8
ffffffffc020208a:	5427b783          	ld	a5,1346(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc020208e:	6f9c                	ld	a5,24(a5)
ffffffffc0202090:	4505                	li	a0,1
ffffffffc0202092:	9782                	jalr	a5
ffffffffc0202094:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202096:	c4c9                	beqz	s1,ffffffffc0202120 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202098:	000d8b17          	auipc	s6,0xd8
ffffffffc020209c:	528b0b13          	addi	s6,s6,1320 # ffffffffc02da5c0 <pages>
ffffffffc02020a0:	000b3503          	ld	a0,0(s6)
ffffffffc02020a4:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020a8:	0009b703          	ld	a4,0(s3)
ffffffffc02020ac:	40a48533          	sub	a0,s1,a0
ffffffffc02020b0:	8519                	srai	a0,a0,0x6
ffffffffc02020b2:	9552                	add	a0,a0,s4
ffffffffc02020b4:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02020b8:	4685                	li	a3,1
ffffffffc02020ba:	c094                	sw	a3,0(s1)
ffffffffc02020bc:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02020be:	0532                	slli	a0,a0,0xc
ffffffffc02020c0:	0ee7f163          	bgeu	a5,a4,ffffffffc02021a2 <get_pte+0x20e>
ffffffffc02020c4:	000ab783          	ld	a5,0(s5)
ffffffffc02020c8:	6605                	lui	a2,0x1
ffffffffc02020ca:	4581                	li	a1,0
ffffffffc02020cc:	953e                	add	a0,a0,a5
ffffffffc02020ce:	3f5030ef          	jal	ra,ffffffffc0205cc2 <memset>
    return page - pages + nbase;
ffffffffc02020d2:	000b3683          	ld	a3,0(s6)
ffffffffc02020d6:	40d486b3          	sub	a3,s1,a3
ffffffffc02020da:	8699                	srai	a3,a3,0x6
ffffffffc02020dc:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020de:	06aa                	slli	a3,a3,0xa
ffffffffc02020e0:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02020e4:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020e6:	0009b703          	ld	a4,0(s3)
ffffffffc02020ea:	068a                	slli	a3,a3,0x2
ffffffffc02020ec:	757d                	lui	a0,0xfffff
ffffffffc02020ee:	8ee9                	and	a3,a3,a0
ffffffffc02020f0:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020f4:	06e7f263          	bgeu	a5,a4,ffffffffc0202158 <get_pte+0x1c4>
ffffffffc02020f8:	000ab503          	ld	a0,0(s5)
ffffffffc02020fc:	00c95913          	srli	s2,s2,0xc
ffffffffc0202100:	1ff97913          	andi	s2,s2,511
ffffffffc0202104:	96aa                	add	a3,a3,a0
ffffffffc0202106:	00391513          	slli	a0,s2,0x3
ffffffffc020210a:	9536                	add	a0,a0,a3
}
ffffffffc020210c:	70e2                	ld	ra,56(sp)
ffffffffc020210e:	7442                	ld	s0,48(sp)
ffffffffc0202110:	74a2                	ld	s1,40(sp)
ffffffffc0202112:	7902                	ld	s2,32(sp)
ffffffffc0202114:	69e2                	ld	s3,24(sp)
ffffffffc0202116:	6a42                	ld	s4,16(sp)
ffffffffc0202118:	6aa2                	ld	s5,8(sp)
ffffffffc020211a:	6b02                	ld	s6,0(sp)
ffffffffc020211c:	6121                	addi	sp,sp,64
ffffffffc020211e:	8082                	ret
            return NULL;
ffffffffc0202120:	4501                	li	a0,0
ffffffffc0202122:	b7ed                	j	ffffffffc020210c <get_pte+0x178>
        intr_disable();
ffffffffc0202124:	891fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202128:	000d8797          	auipc	a5,0xd8
ffffffffc020212c:	4a07b783          	ld	a5,1184(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc0202130:	6f9c                	ld	a5,24(a5)
ffffffffc0202132:	4505                	li	a0,1
ffffffffc0202134:	9782                	jalr	a5
ffffffffc0202136:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202138:	877fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020213c:	b56d                	j	ffffffffc0201fe6 <get_pte+0x52>
        intr_disable();
ffffffffc020213e:	877fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202142:	000d8797          	auipc	a5,0xd8
ffffffffc0202146:	4867b783          	ld	a5,1158(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc020214a:	6f9c                	ld	a5,24(a5)
ffffffffc020214c:	4505                	li	a0,1
ffffffffc020214e:	9782                	jalr	a5
ffffffffc0202150:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0202152:	85dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202156:	b781                	j	ffffffffc0202096 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202158:	00005617          	auipc	a2,0x5
ffffffffc020215c:	aa060613          	addi	a2,a2,-1376 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc0202160:	0fa00593          	li	a1,250
ffffffffc0202164:	00005517          	auipc	a0,0x5
ffffffffc0202168:	bac50513          	addi	a0,a0,-1108 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020216c:	b22fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202170:	00005617          	auipc	a2,0x5
ffffffffc0202174:	a8860613          	addi	a2,a2,-1400 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc0202178:	0ed00593          	li	a1,237
ffffffffc020217c:	00005517          	auipc	a0,0x5
ffffffffc0202180:	b9450513          	addi	a0,a0,-1132 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0202184:	b0afe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202188:	86aa                	mv	a3,a0
ffffffffc020218a:	00005617          	auipc	a2,0x5
ffffffffc020218e:	a6e60613          	addi	a2,a2,-1426 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc0202192:	0e900593          	li	a1,233
ffffffffc0202196:	00005517          	auipc	a0,0x5
ffffffffc020219a:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020219e:	af0fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021a2:	86aa                	mv	a3,a0
ffffffffc02021a4:	00005617          	auipc	a2,0x5
ffffffffc02021a8:	a5460613          	addi	a2,a2,-1452 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc02021ac:	0f700593          	li	a1,247
ffffffffc02021b0:	00005517          	auipc	a0,0x5
ffffffffc02021b4:	b6050513          	addi	a0,a0,-1184 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02021b8:	ad6fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02021bc <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02021bc:	1141                	addi	sp,sp,-16
ffffffffc02021be:	e022                	sd	s0,0(sp)
ffffffffc02021c0:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021c2:	4601                	li	a2,0
{
ffffffffc02021c4:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021c6:	dcfff0ef          	jal	ra,ffffffffc0201f94 <get_pte>
    if (ptep_store != NULL)
ffffffffc02021ca:	c011                	beqz	s0,ffffffffc02021ce <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02021cc:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021ce:	c511                	beqz	a0,ffffffffc02021da <get_page+0x1e>
ffffffffc02021d0:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02021d2:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021d4:	0017f713          	andi	a4,a5,1
ffffffffc02021d8:	e709                	bnez	a4,ffffffffc02021e2 <get_page+0x26>
}
ffffffffc02021da:	60a2                	ld	ra,8(sp)
ffffffffc02021dc:	6402                	ld	s0,0(sp)
ffffffffc02021de:	0141                	addi	sp,sp,16
ffffffffc02021e0:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02021e2:	078a                	slli	a5,a5,0x2
ffffffffc02021e4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021e6:	000d8717          	auipc	a4,0xd8
ffffffffc02021ea:	3d273703          	ld	a4,978(a4) # ffffffffc02da5b8 <npage>
ffffffffc02021ee:	00e7ff63          	bgeu	a5,a4,ffffffffc020220c <get_page+0x50>
ffffffffc02021f2:	60a2                	ld	ra,8(sp)
ffffffffc02021f4:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02021f6:	fff80537          	lui	a0,0xfff80
ffffffffc02021fa:	97aa                	add	a5,a5,a0
ffffffffc02021fc:	079a                	slli	a5,a5,0x6
ffffffffc02021fe:	000d8517          	auipc	a0,0xd8
ffffffffc0202202:	3c253503          	ld	a0,962(a0) # ffffffffc02da5c0 <pages>
ffffffffc0202206:	953e                	add	a0,a0,a5
ffffffffc0202208:	0141                	addi	sp,sp,16
ffffffffc020220a:	8082                	ret
ffffffffc020220c:	c99ff0ef          	jal	ra,ffffffffc0201ea4 <pa2page.part.0>

ffffffffc0202210 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202210:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202212:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202216:	f486                	sd	ra,104(sp)
ffffffffc0202218:	f0a2                	sd	s0,96(sp)
ffffffffc020221a:	eca6                	sd	s1,88(sp)
ffffffffc020221c:	e8ca                	sd	s2,80(sp)
ffffffffc020221e:	e4ce                	sd	s3,72(sp)
ffffffffc0202220:	e0d2                	sd	s4,64(sp)
ffffffffc0202222:	fc56                	sd	s5,56(sp)
ffffffffc0202224:	f85a                	sd	s6,48(sp)
ffffffffc0202226:	f45e                	sd	s7,40(sp)
ffffffffc0202228:	f062                	sd	s8,32(sp)
ffffffffc020222a:	ec66                	sd	s9,24(sp)
ffffffffc020222c:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020222e:	17d2                	slli	a5,a5,0x34
ffffffffc0202230:	e3ed                	bnez	a5,ffffffffc0202312 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc0202232:	002007b7          	lui	a5,0x200
ffffffffc0202236:	842e                	mv	s0,a1
ffffffffc0202238:	0ef5ed63          	bltu	a1,a5,ffffffffc0202332 <unmap_range+0x122>
ffffffffc020223c:	8932                	mv	s2,a2
ffffffffc020223e:	0ec5fa63          	bgeu	a1,a2,ffffffffc0202332 <unmap_range+0x122>
ffffffffc0202242:	4785                	li	a5,1
ffffffffc0202244:	07fe                	slli	a5,a5,0x1f
ffffffffc0202246:	0ec7e663          	bltu	a5,a2,ffffffffc0202332 <unmap_range+0x122>
ffffffffc020224a:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020224c:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020224e:	000d8c97          	auipc	s9,0xd8
ffffffffc0202252:	36ac8c93          	addi	s9,s9,874 # ffffffffc02da5b8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202256:	000d8c17          	auipc	s8,0xd8
ffffffffc020225a:	36ac0c13          	addi	s8,s8,874 # ffffffffc02da5c0 <pages>
ffffffffc020225e:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc0202262:	000d8d17          	auipc	s10,0xd8
ffffffffc0202266:	366d0d13          	addi	s10,s10,870 # ffffffffc02da5c8 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020226a:	00200b37          	lui	s6,0x200
ffffffffc020226e:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202272:	4601                	li	a2,0
ffffffffc0202274:	85a2                	mv	a1,s0
ffffffffc0202276:	854e                	mv	a0,s3
ffffffffc0202278:	d1dff0ef          	jal	ra,ffffffffc0201f94 <get_pte>
ffffffffc020227c:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020227e:	cd29                	beqz	a0,ffffffffc02022d8 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc0202280:	611c                	ld	a5,0(a0)
ffffffffc0202282:	e395                	bnez	a5,ffffffffc02022a6 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202284:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202286:	ff2466e3          	bltu	s0,s2,ffffffffc0202272 <unmap_range+0x62>
}
ffffffffc020228a:	70a6                	ld	ra,104(sp)
ffffffffc020228c:	7406                	ld	s0,96(sp)
ffffffffc020228e:	64e6                	ld	s1,88(sp)
ffffffffc0202290:	6946                	ld	s2,80(sp)
ffffffffc0202292:	69a6                	ld	s3,72(sp)
ffffffffc0202294:	6a06                	ld	s4,64(sp)
ffffffffc0202296:	7ae2                	ld	s5,56(sp)
ffffffffc0202298:	7b42                	ld	s6,48(sp)
ffffffffc020229a:	7ba2                	ld	s7,40(sp)
ffffffffc020229c:	7c02                	ld	s8,32(sp)
ffffffffc020229e:	6ce2                	ld	s9,24(sp)
ffffffffc02022a0:	6d42                	ld	s10,16(sp)
ffffffffc02022a2:	6165                	addi	sp,sp,112
ffffffffc02022a4:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc02022a6:	0017f713          	andi	a4,a5,1
ffffffffc02022aa:	df69                	beqz	a4,ffffffffc0202284 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc02022ac:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02022b0:	078a                	slli	a5,a5,0x2
ffffffffc02022b2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02022b4:	08e7ff63          	bgeu	a5,a4,ffffffffc0202352 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc02022b8:	000c3503          	ld	a0,0(s8)
ffffffffc02022bc:	97de                	add	a5,a5,s7
ffffffffc02022be:	079a                	slli	a5,a5,0x6
ffffffffc02022c0:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02022c2:	411c                	lw	a5,0(a0)
ffffffffc02022c4:	fff7871b          	addiw	a4,a5,-1
ffffffffc02022c8:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02022ca:	cf11                	beqz	a4,ffffffffc02022e6 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc02022cc:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02022d0:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02022d4:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02022d6:	bf45                	j	ffffffffc0202286 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022d8:	945a                	add	s0,s0,s6
ffffffffc02022da:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc02022de:	d455                	beqz	s0,ffffffffc020228a <unmap_range+0x7a>
ffffffffc02022e0:	f92469e3          	bltu	s0,s2,ffffffffc0202272 <unmap_range+0x62>
ffffffffc02022e4:	b75d                	j	ffffffffc020228a <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02022e6:	100027f3          	csrr	a5,sstatus
ffffffffc02022ea:	8b89                	andi	a5,a5,2
ffffffffc02022ec:	e799                	bnez	a5,ffffffffc02022fa <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc02022ee:	000d3783          	ld	a5,0(s10)
ffffffffc02022f2:	4585                	li	a1,1
ffffffffc02022f4:	739c                	ld	a5,32(a5)
ffffffffc02022f6:	9782                	jalr	a5
    if (flag)
ffffffffc02022f8:	bfd1                	j	ffffffffc02022cc <unmap_range+0xbc>
ffffffffc02022fa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02022fc:	eb8fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202300:	000d3783          	ld	a5,0(s10)
ffffffffc0202304:	6522                	ld	a0,8(sp)
ffffffffc0202306:	4585                	li	a1,1
ffffffffc0202308:	739c                	ld	a5,32(a5)
ffffffffc020230a:	9782                	jalr	a5
        intr_enable();
ffffffffc020230c:	ea2fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202310:	bf75                	j	ffffffffc02022cc <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202312:	00005697          	auipc	a3,0x5
ffffffffc0202316:	a0e68693          	addi	a3,a3,-1522 # ffffffffc0206d20 <default_pmm_manager+0x160>
ffffffffc020231a:	00004617          	auipc	a2,0x4
ffffffffc020231e:	23660613          	addi	a2,a2,566 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0202322:	12000593          	li	a1,288
ffffffffc0202326:	00005517          	auipc	a0,0x5
ffffffffc020232a:	9ea50513          	addi	a0,a0,-1558 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020232e:	960fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202332:	00005697          	auipc	a3,0x5
ffffffffc0202336:	a1e68693          	addi	a3,a3,-1506 # ffffffffc0206d50 <default_pmm_manager+0x190>
ffffffffc020233a:	00004617          	auipc	a2,0x4
ffffffffc020233e:	21660613          	addi	a2,a2,534 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0202342:	12100593          	li	a1,289
ffffffffc0202346:	00005517          	auipc	a0,0x5
ffffffffc020234a:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020234e:	940fe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202352:	b53ff0ef          	jal	ra,ffffffffc0201ea4 <pa2page.part.0>

ffffffffc0202356 <exit_range>:
{
ffffffffc0202356:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202358:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020235c:	fc86                	sd	ra,120(sp)
ffffffffc020235e:	f8a2                	sd	s0,112(sp)
ffffffffc0202360:	f4a6                	sd	s1,104(sp)
ffffffffc0202362:	f0ca                	sd	s2,96(sp)
ffffffffc0202364:	ecce                	sd	s3,88(sp)
ffffffffc0202366:	e8d2                	sd	s4,80(sp)
ffffffffc0202368:	e4d6                	sd	s5,72(sp)
ffffffffc020236a:	e0da                	sd	s6,64(sp)
ffffffffc020236c:	fc5e                	sd	s7,56(sp)
ffffffffc020236e:	f862                	sd	s8,48(sp)
ffffffffc0202370:	f466                	sd	s9,40(sp)
ffffffffc0202372:	f06a                	sd	s10,32(sp)
ffffffffc0202374:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202376:	17d2                	slli	a5,a5,0x34
ffffffffc0202378:	20079a63          	bnez	a5,ffffffffc020258c <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc020237c:	002007b7          	lui	a5,0x200
ffffffffc0202380:	24f5e463          	bltu	a1,a5,ffffffffc02025c8 <exit_range+0x272>
ffffffffc0202384:	8ab2                	mv	s5,a2
ffffffffc0202386:	24c5f163          	bgeu	a1,a2,ffffffffc02025c8 <exit_range+0x272>
ffffffffc020238a:	4785                	li	a5,1
ffffffffc020238c:	07fe                	slli	a5,a5,0x1f
ffffffffc020238e:	22c7ed63          	bltu	a5,a2,ffffffffc02025c8 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202392:	c00009b7          	lui	s3,0xc0000
ffffffffc0202396:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020239a:	ffe00937          	lui	s2,0xffe00
ffffffffc020239e:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc02023a2:	5cfd                	li	s9,-1
ffffffffc02023a4:	8c2a                	mv	s8,a0
ffffffffc02023a6:	0125f933          	and	s2,a1,s2
ffffffffc02023aa:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc02023ac:	000d8d17          	auipc	s10,0xd8
ffffffffc02023b0:	20cd0d13          	addi	s10,s10,524 # ffffffffc02da5b8 <npage>
    return KADDR(page2pa(page));
ffffffffc02023b4:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023b8:	000d8717          	auipc	a4,0xd8
ffffffffc02023bc:	20870713          	addi	a4,a4,520 # ffffffffc02da5c0 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc02023c0:	000d8d97          	auipc	s11,0xd8
ffffffffc02023c4:	208d8d93          	addi	s11,s11,520 # ffffffffc02da5c8 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02023c8:	c0000437          	lui	s0,0xc0000
ffffffffc02023cc:	944e                	add	s0,s0,s3
ffffffffc02023ce:	8079                	srli	s0,s0,0x1e
ffffffffc02023d0:	1ff47413          	andi	s0,s0,511
ffffffffc02023d4:	040e                	slli	s0,s0,0x3
ffffffffc02023d6:	9462                	add	s0,s0,s8
ffffffffc02023d8:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_cowtest_out_size+0xffffffffbfff0310>
        if (pde1 & PTE_V)
ffffffffc02023dc:	001a7793          	andi	a5,s4,1
ffffffffc02023e0:	eb99                	bnez	a5,ffffffffc02023f6 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc02023e2:	12098463          	beqz	s3,ffffffffc020250a <exit_range+0x1b4>
ffffffffc02023e6:	400007b7          	lui	a5,0x40000
ffffffffc02023ea:	97ce                	add	a5,a5,s3
ffffffffc02023ec:	894e                	mv	s2,s3
ffffffffc02023ee:	1159fe63          	bgeu	s3,s5,ffffffffc020250a <exit_range+0x1b4>
ffffffffc02023f2:	89be                	mv	s3,a5
ffffffffc02023f4:	bfd1                	j	ffffffffc02023c8 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc02023f6:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023fa:	0a0a                	slli	s4,s4,0x2
ffffffffc02023fc:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202400:	1cfa7263          	bgeu	s4,a5,ffffffffc02025c4 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202404:	fff80637          	lui	a2,0xfff80
ffffffffc0202408:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc020240a:	000806b7          	lui	a3,0x80
ffffffffc020240e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202410:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202414:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202416:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202418:	18f5fa63          	bgeu	a1,a5,ffffffffc02025ac <exit_range+0x256>
ffffffffc020241c:	000d8817          	auipc	a6,0xd8
ffffffffc0202420:	1b480813          	addi	a6,a6,436 # ffffffffc02da5d0 <va_pa_offset>
ffffffffc0202424:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202428:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc020242a:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc020242e:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202430:	00080337          	lui	t1,0x80
ffffffffc0202434:	6885                	lui	a7,0x1
ffffffffc0202436:	a819                	j	ffffffffc020244c <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc0202438:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc020243a:	002007b7          	lui	a5,0x200
ffffffffc020243e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202440:	08090c63          	beqz	s2,ffffffffc02024d8 <exit_range+0x182>
ffffffffc0202444:	09397a63          	bgeu	s2,s3,ffffffffc02024d8 <exit_range+0x182>
ffffffffc0202448:	0f597063          	bgeu	s2,s5,ffffffffc0202528 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc020244c:	01595493          	srli	s1,s2,0x15
ffffffffc0202450:	1ff4f493          	andi	s1,s1,511
ffffffffc0202454:	048e                	slli	s1,s1,0x3
ffffffffc0202456:	94da                	add	s1,s1,s6
ffffffffc0202458:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc020245a:	0017f693          	andi	a3,a5,1
ffffffffc020245e:	dee9                	beqz	a3,ffffffffc0202438 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202460:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202464:	078a                	slli	a5,a5,0x2
ffffffffc0202466:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202468:	14b7fe63          	bgeu	a5,a1,ffffffffc02025c4 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020246c:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020246e:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc0202472:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202476:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020247a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020247c:	12bef863          	bgeu	t4,a1,ffffffffc02025ac <exit_range+0x256>
ffffffffc0202480:	00083783          	ld	a5,0(a6)
ffffffffc0202484:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202486:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc020248a:	629c                	ld	a5,0(a3)
ffffffffc020248c:	8b85                	andi	a5,a5,1
ffffffffc020248e:	f7d5                	bnez	a5,ffffffffc020243a <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202490:	06a1                	addi	a3,a3,8
ffffffffc0202492:	fed59ce3          	bne	a1,a3,ffffffffc020248a <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202496:	631c                	ld	a5,0(a4)
ffffffffc0202498:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020249a:	100027f3          	csrr	a5,sstatus
ffffffffc020249e:	8b89                	andi	a5,a5,2
ffffffffc02024a0:	e7d9                	bnez	a5,ffffffffc020252e <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc02024a2:	000db783          	ld	a5,0(s11)
ffffffffc02024a6:	4585                	li	a1,1
ffffffffc02024a8:	e032                	sd	a2,0(sp)
ffffffffc02024aa:	739c                	ld	a5,32(a5)
ffffffffc02024ac:	9782                	jalr	a5
    if (flag)
ffffffffc02024ae:	6602                	ld	a2,0(sp)
ffffffffc02024b0:	000d8817          	auipc	a6,0xd8
ffffffffc02024b4:	12080813          	addi	a6,a6,288 # ffffffffc02da5d0 <va_pa_offset>
ffffffffc02024b8:	fff80e37          	lui	t3,0xfff80
ffffffffc02024bc:	00080337          	lui	t1,0x80
ffffffffc02024c0:	6885                	lui	a7,0x1
ffffffffc02024c2:	000d8717          	auipc	a4,0xd8
ffffffffc02024c6:	0fe70713          	addi	a4,a4,254 # ffffffffc02da5c0 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024ca:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc02024ce:	002007b7          	lui	a5,0x200
ffffffffc02024d2:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02024d4:	f60918e3          	bnez	s2,ffffffffc0202444 <exit_range+0xee>
            if (free_pd0)
ffffffffc02024d8:	f00b85e3          	beqz	s7,ffffffffc02023e2 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc02024dc:	000d3783          	ld	a5,0(s10)
ffffffffc02024e0:	0efa7263          	bgeu	s4,a5,ffffffffc02025c4 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02024e4:	6308                	ld	a0,0(a4)
ffffffffc02024e6:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02024e8:	100027f3          	csrr	a5,sstatus
ffffffffc02024ec:	8b89                	andi	a5,a5,2
ffffffffc02024ee:	efad                	bnez	a5,ffffffffc0202568 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02024f0:	000db783          	ld	a5,0(s11)
ffffffffc02024f4:	4585                	li	a1,1
ffffffffc02024f6:	739c                	ld	a5,32(a5)
ffffffffc02024f8:	9782                	jalr	a5
ffffffffc02024fa:	000d8717          	auipc	a4,0xd8
ffffffffc02024fe:	0c670713          	addi	a4,a4,198 # ffffffffc02da5c0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202502:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0202506:	ee0990e3          	bnez	s3,ffffffffc02023e6 <exit_range+0x90>
}
ffffffffc020250a:	70e6                	ld	ra,120(sp)
ffffffffc020250c:	7446                	ld	s0,112(sp)
ffffffffc020250e:	74a6                	ld	s1,104(sp)
ffffffffc0202510:	7906                	ld	s2,96(sp)
ffffffffc0202512:	69e6                	ld	s3,88(sp)
ffffffffc0202514:	6a46                	ld	s4,80(sp)
ffffffffc0202516:	6aa6                	ld	s5,72(sp)
ffffffffc0202518:	6b06                	ld	s6,64(sp)
ffffffffc020251a:	7be2                	ld	s7,56(sp)
ffffffffc020251c:	7c42                	ld	s8,48(sp)
ffffffffc020251e:	7ca2                	ld	s9,40(sp)
ffffffffc0202520:	7d02                	ld	s10,32(sp)
ffffffffc0202522:	6de2                	ld	s11,24(sp)
ffffffffc0202524:	6109                	addi	sp,sp,128
ffffffffc0202526:	8082                	ret
            if (free_pd0)
ffffffffc0202528:	ea0b8fe3          	beqz	s7,ffffffffc02023e6 <exit_range+0x90>
ffffffffc020252c:	bf45                	j	ffffffffc02024dc <exit_range+0x186>
ffffffffc020252e:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202530:	e42a                	sd	a0,8(sp)
ffffffffc0202532:	c82fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202536:	000db783          	ld	a5,0(s11)
ffffffffc020253a:	6522                	ld	a0,8(sp)
ffffffffc020253c:	4585                	li	a1,1
ffffffffc020253e:	739c                	ld	a5,32(a5)
ffffffffc0202540:	9782                	jalr	a5
        intr_enable();
ffffffffc0202542:	c6cfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202546:	6602                	ld	a2,0(sp)
ffffffffc0202548:	000d8717          	auipc	a4,0xd8
ffffffffc020254c:	07870713          	addi	a4,a4,120 # ffffffffc02da5c0 <pages>
ffffffffc0202550:	6885                	lui	a7,0x1
ffffffffc0202552:	00080337          	lui	t1,0x80
ffffffffc0202556:	fff80e37          	lui	t3,0xfff80
ffffffffc020255a:	000d8817          	auipc	a6,0xd8
ffffffffc020255e:	07680813          	addi	a6,a6,118 # ffffffffc02da5d0 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202562:	0004b023          	sd	zero,0(s1)
ffffffffc0202566:	b7a5                	j	ffffffffc02024ce <exit_range+0x178>
ffffffffc0202568:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020256a:	c4afe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020256e:	000db783          	ld	a5,0(s11)
ffffffffc0202572:	6502                	ld	a0,0(sp)
ffffffffc0202574:	4585                	li	a1,1
ffffffffc0202576:	739c                	ld	a5,32(a5)
ffffffffc0202578:	9782                	jalr	a5
        intr_enable();
ffffffffc020257a:	c34fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020257e:	000d8717          	auipc	a4,0xd8
ffffffffc0202582:	04270713          	addi	a4,a4,66 # ffffffffc02da5c0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202586:	00043023          	sd	zero,0(s0)
ffffffffc020258a:	bfb5                	j	ffffffffc0202506 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020258c:	00004697          	auipc	a3,0x4
ffffffffc0202590:	79468693          	addi	a3,a3,1940 # ffffffffc0206d20 <default_pmm_manager+0x160>
ffffffffc0202594:	00004617          	auipc	a2,0x4
ffffffffc0202598:	fbc60613          	addi	a2,a2,-68 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020259c:	13500593          	li	a1,309
ffffffffc02025a0:	00004517          	auipc	a0,0x4
ffffffffc02025a4:	77050513          	addi	a0,a0,1904 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02025a8:	ee7fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02025ac:	00004617          	auipc	a2,0x4
ffffffffc02025b0:	64c60613          	addi	a2,a2,1612 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc02025b4:	07200593          	li	a1,114
ffffffffc02025b8:	00004517          	auipc	a0,0x4
ffffffffc02025bc:	66850513          	addi	a0,a0,1640 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc02025c0:	ecffd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02025c4:	8e1ff0ef          	jal	ra,ffffffffc0201ea4 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02025c8:	00004697          	auipc	a3,0x4
ffffffffc02025cc:	78868693          	addi	a3,a3,1928 # ffffffffc0206d50 <default_pmm_manager+0x190>
ffffffffc02025d0:	00004617          	auipc	a2,0x4
ffffffffc02025d4:	f8060613          	addi	a2,a2,-128 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02025d8:	13600593          	li	a1,310
ffffffffc02025dc:	00004517          	auipc	a0,0x4
ffffffffc02025e0:	73450513          	addi	a0,a0,1844 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02025e4:	eabfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02025e8 <page_remove>:
{
ffffffffc02025e8:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025ea:	4601                	li	a2,0
{
ffffffffc02025ec:	ec26                	sd	s1,24(sp)
ffffffffc02025ee:	f406                	sd	ra,40(sp)
ffffffffc02025f0:	f022                	sd	s0,32(sp)
ffffffffc02025f2:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025f4:	9a1ff0ef          	jal	ra,ffffffffc0201f94 <get_pte>
    if (ptep != NULL)
ffffffffc02025f8:	c511                	beqz	a0,ffffffffc0202604 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02025fa:	611c                	ld	a5,0(a0)
ffffffffc02025fc:	842a                	mv	s0,a0
ffffffffc02025fe:	0017f713          	andi	a4,a5,1
ffffffffc0202602:	e711                	bnez	a4,ffffffffc020260e <page_remove+0x26>
}
ffffffffc0202604:	70a2                	ld	ra,40(sp)
ffffffffc0202606:	7402                	ld	s0,32(sp)
ffffffffc0202608:	64e2                	ld	s1,24(sp)
ffffffffc020260a:	6145                	addi	sp,sp,48
ffffffffc020260c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020260e:	078a                	slli	a5,a5,0x2
ffffffffc0202610:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202612:	000d8717          	auipc	a4,0xd8
ffffffffc0202616:	fa673703          	ld	a4,-90(a4) # ffffffffc02da5b8 <npage>
ffffffffc020261a:	06e7f363          	bgeu	a5,a4,ffffffffc0202680 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020261e:	fff80537          	lui	a0,0xfff80
ffffffffc0202622:	97aa                	add	a5,a5,a0
ffffffffc0202624:	079a                	slli	a5,a5,0x6
ffffffffc0202626:	000d8517          	auipc	a0,0xd8
ffffffffc020262a:	f9a53503          	ld	a0,-102(a0) # ffffffffc02da5c0 <pages>
ffffffffc020262e:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202630:	411c                	lw	a5,0(a0)
ffffffffc0202632:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202636:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202638:	cb11                	beqz	a4,ffffffffc020264c <page_remove+0x64>
        *ptep = 0;
ffffffffc020263a:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020263e:	12048073          	sfence.vma	s1
}
ffffffffc0202642:	70a2                	ld	ra,40(sp)
ffffffffc0202644:	7402                	ld	s0,32(sp)
ffffffffc0202646:	64e2                	ld	s1,24(sp)
ffffffffc0202648:	6145                	addi	sp,sp,48
ffffffffc020264a:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020264c:	100027f3          	csrr	a5,sstatus
ffffffffc0202650:	8b89                	andi	a5,a5,2
ffffffffc0202652:	eb89                	bnez	a5,ffffffffc0202664 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202654:	000d8797          	auipc	a5,0xd8
ffffffffc0202658:	f747b783          	ld	a5,-140(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc020265c:	739c                	ld	a5,32(a5)
ffffffffc020265e:	4585                	li	a1,1
ffffffffc0202660:	9782                	jalr	a5
    if (flag)
ffffffffc0202662:	bfe1                	j	ffffffffc020263a <page_remove+0x52>
        intr_disable();
ffffffffc0202664:	e42a                	sd	a0,8(sp)
ffffffffc0202666:	b4efe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020266a:	000d8797          	auipc	a5,0xd8
ffffffffc020266e:	f5e7b783          	ld	a5,-162(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc0202672:	739c                	ld	a5,32(a5)
ffffffffc0202674:	6522                	ld	a0,8(sp)
ffffffffc0202676:	4585                	li	a1,1
ffffffffc0202678:	9782                	jalr	a5
        intr_enable();
ffffffffc020267a:	b34fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020267e:	bf75                	j	ffffffffc020263a <page_remove+0x52>
ffffffffc0202680:	825ff0ef          	jal	ra,ffffffffc0201ea4 <pa2page.part.0>

ffffffffc0202684 <page_insert>:
{
ffffffffc0202684:	7139                	addi	sp,sp,-64
ffffffffc0202686:	e852                	sd	s4,16(sp)
ffffffffc0202688:	8a32                	mv	s4,a2
ffffffffc020268a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020268c:	4605                	li	a2,1
{
ffffffffc020268e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202690:	85d2                	mv	a1,s4
{
ffffffffc0202692:	f426                	sd	s1,40(sp)
ffffffffc0202694:	fc06                	sd	ra,56(sp)
ffffffffc0202696:	f04a                	sd	s2,32(sp)
ffffffffc0202698:	ec4e                	sd	s3,24(sp)
ffffffffc020269a:	e456                	sd	s5,8(sp)
ffffffffc020269c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020269e:	8f7ff0ef          	jal	ra,ffffffffc0201f94 <get_pte>
    if (ptep == NULL)
ffffffffc02026a2:	c961                	beqz	a0,ffffffffc0202772 <page_insert+0xee>
    page->ref += 1;
ffffffffc02026a4:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc02026a6:	611c                	ld	a5,0(a0)
ffffffffc02026a8:	89aa                	mv	s3,a0
ffffffffc02026aa:	0016871b          	addiw	a4,a3,1
ffffffffc02026ae:	c018                	sw	a4,0(s0)
ffffffffc02026b0:	0017f713          	andi	a4,a5,1
ffffffffc02026b4:	ef05                	bnez	a4,ffffffffc02026ec <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02026b6:	000d8717          	auipc	a4,0xd8
ffffffffc02026ba:	f0a73703          	ld	a4,-246(a4) # ffffffffc02da5c0 <pages>
ffffffffc02026be:	8c19                	sub	s0,s0,a4
ffffffffc02026c0:	000807b7          	lui	a5,0x80
ffffffffc02026c4:	8419                	srai	s0,s0,0x6
ffffffffc02026c6:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02026c8:	042a                	slli	s0,s0,0xa
ffffffffc02026ca:	8cc1                	or	s1,s1,s0
ffffffffc02026cc:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02026d0:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_cowtest_out_size+0xffffffffbfff0310>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026d4:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02026d8:	4501                	li	a0,0
}
ffffffffc02026da:	70e2                	ld	ra,56(sp)
ffffffffc02026dc:	7442                	ld	s0,48(sp)
ffffffffc02026de:	74a2                	ld	s1,40(sp)
ffffffffc02026e0:	7902                	ld	s2,32(sp)
ffffffffc02026e2:	69e2                	ld	s3,24(sp)
ffffffffc02026e4:	6a42                	ld	s4,16(sp)
ffffffffc02026e6:	6aa2                	ld	s5,8(sp)
ffffffffc02026e8:	6121                	addi	sp,sp,64
ffffffffc02026ea:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02026ec:	078a                	slli	a5,a5,0x2
ffffffffc02026ee:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026f0:	000d8717          	auipc	a4,0xd8
ffffffffc02026f4:	ec873703          	ld	a4,-312(a4) # ffffffffc02da5b8 <npage>
ffffffffc02026f8:	06e7ff63          	bgeu	a5,a4,ffffffffc0202776 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02026fc:	000d8a97          	auipc	s5,0xd8
ffffffffc0202700:	ec4a8a93          	addi	s5,s5,-316 # ffffffffc02da5c0 <pages>
ffffffffc0202704:	000ab703          	ld	a4,0(s5)
ffffffffc0202708:	fff80937          	lui	s2,0xfff80
ffffffffc020270c:	993e                	add	s2,s2,a5
ffffffffc020270e:	091a                	slli	s2,s2,0x6
ffffffffc0202710:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202712:	01240c63          	beq	s0,s2,ffffffffc020272a <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202716:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fca5a0c>
ffffffffc020271a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020271e:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc0202722:	c691                	beqz	a3,ffffffffc020272e <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202724:	120a0073          	sfence.vma	s4
}
ffffffffc0202728:	bf59                	j	ffffffffc02026be <page_insert+0x3a>
ffffffffc020272a:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020272c:	bf49                	j	ffffffffc02026be <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020272e:	100027f3          	csrr	a5,sstatus
ffffffffc0202732:	8b89                	andi	a5,a5,2
ffffffffc0202734:	ef91                	bnez	a5,ffffffffc0202750 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202736:	000d8797          	auipc	a5,0xd8
ffffffffc020273a:	e927b783          	ld	a5,-366(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc020273e:	739c                	ld	a5,32(a5)
ffffffffc0202740:	4585                	li	a1,1
ffffffffc0202742:	854a                	mv	a0,s2
ffffffffc0202744:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202746:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020274a:	120a0073          	sfence.vma	s4
ffffffffc020274e:	bf85                	j	ffffffffc02026be <page_insert+0x3a>
        intr_disable();
ffffffffc0202750:	a64fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202754:	000d8797          	auipc	a5,0xd8
ffffffffc0202758:	e747b783          	ld	a5,-396(a5) # ffffffffc02da5c8 <pmm_manager>
ffffffffc020275c:	739c                	ld	a5,32(a5)
ffffffffc020275e:	4585                	li	a1,1
ffffffffc0202760:	854a                	mv	a0,s2
ffffffffc0202762:	9782                	jalr	a5
        intr_enable();
ffffffffc0202764:	a4afe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202768:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020276c:	120a0073          	sfence.vma	s4
ffffffffc0202770:	b7b9                	j	ffffffffc02026be <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202772:	5571                	li	a0,-4
ffffffffc0202774:	b79d                	j	ffffffffc02026da <page_insert+0x56>
ffffffffc0202776:	f2eff0ef          	jal	ra,ffffffffc0201ea4 <pa2page.part.0>

ffffffffc020277a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020277a:	00004797          	auipc	a5,0x4
ffffffffc020277e:	44678793          	addi	a5,a5,1094 # ffffffffc0206bc0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202782:	638c                	ld	a1,0(a5)
{
ffffffffc0202784:	7159                	addi	sp,sp,-112
ffffffffc0202786:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202788:	00004517          	auipc	a0,0x4
ffffffffc020278c:	5e050513          	addi	a0,a0,1504 # ffffffffc0206d68 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202790:	000d8b17          	auipc	s6,0xd8
ffffffffc0202794:	e38b0b13          	addi	s6,s6,-456 # ffffffffc02da5c8 <pmm_manager>
{
ffffffffc0202798:	f486                	sd	ra,104(sp)
ffffffffc020279a:	e8ca                	sd	s2,80(sp)
ffffffffc020279c:	e4ce                	sd	s3,72(sp)
ffffffffc020279e:	f0a2                	sd	s0,96(sp)
ffffffffc02027a0:	eca6                	sd	s1,88(sp)
ffffffffc02027a2:	e0d2                	sd	s4,64(sp)
ffffffffc02027a4:	fc56                	sd	s5,56(sp)
ffffffffc02027a6:	f45e                	sd	s7,40(sp)
ffffffffc02027a8:	f062                	sd	s8,32(sp)
ffffffffc02027aa:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02027ac:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027b0:	9e5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc02027b4:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027b8:	000d8997          	auipc	s3,0xd8
ffffffffc02027bc:	e1898993          	addi	s3,s3,-488 # ffffffffc02da5d0 <va_pa_offset>
    pmm_manager->init();
ffffffffc02027c0:	679c                	ld	a5,8(a5)
ffffffffc02027c2:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027c4:	57f5                	li	a5,-3
ffffffffc02027c6:	07fa                	slli	a5,a5,0x1e
ffffffffc02027c8:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02027cc:	9cefe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc02027d0:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02027d2:	9d2fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc02027d6:	200505e3          	beqz	a0,ffffffffc02031e0 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027da:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02027dc:	00004517          	auipc	a0,0x4
ffffffffc02027e0:	5c450513          	addi	a0,a0,1476 # ffffffffc0206da0 <default_pmm_manager+0x1e0>
ffffffffc02027e4:	9b1fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027e8:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02027ec:	fff40693          	addi	a3,s0,-1
ffffffffc02027f0:	864a                	mv	a2,s2
ffffffffc02027f2:	85a6                	mv	a1,s1
ffffffffc02027f4:	00004517          	auipc	a0,0x4
ffffffffc02027f8:	5c450513          	addi	a0,a0,1476 # ffffffffc0206db8 <default_pmm_manager+0x1f8>
ffffffffc02027fc:	999fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202800:	c8000737          	lui	a4,0xc8000
ffffffffc0202804:	87a2                	mv	a5,s0
ffffffffc0202806:	54876163          	bltu	a4,s0,ffffffffc0202d48 <pmm_init+0x5ce>
ffffffffc020280a:	757d                	lui	a0,0xfffff
ffffffffc020280c:	000d9617          	auipc	a2,0xd9
ffffffffc0202810:	de760613          	addi	a2,a2,-537 # ffffffffc02db5f3 <end+0xfff>
ffffffffc0202814:	8e69                	and	a2,a2,a0
ffffffffc0202816:	000d8497          	auipc	s1,0xd8
ffffffffc020281a:	da248493          	addi	s1,s1,-606 # ffffffffc02da5b8 <npage>
ffffffffc020281e:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202822:	000d8b97          	auipc	s7,0xd8
ffffffffc0202826:	d9eb8b93          	addi	s7,s7,-610 # ffffffffc02da5c0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020282a:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020282c:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202830:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202834:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202836:	02f50863          	beq	a0,a5,ffffffffc0202866 <pmm_init+0xec>
ffffffffc020283a:	4781                	li	a5,0
ffffffffc020283c:	4585                	li	a1,1
ffffffffc020283e:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202842:	00679513          	slli	a0,a5,0x6
ffffffffc0202846:	9532                	add	a0,a0,a2
ffffffffc0202848:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd24a14>
ffffffffc020284c:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202850:	6088                	ld	a0,0(s1)
ffffffffc0202852:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202854:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202858:	00d50733          	add	a4,a0,a3
ffffffffc020285c:	fee7e3e3          	bltu	a5,a4,ffffffffc0202842 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202860:	071a                	slli	a4,a4,0x6
ffffffffc0202862:	00e606b3          	add	a3,a2,a4
ffffffffc0202866:	c02007b7          	lui	a5,0xc0200
ffffffffc020286a:	2ef6ece3          	bltu	a3,a5,ffffffffc0203362 <pmm_init+0xbe8>
ffffffffc020286e:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202872:	77fd                	lui	a5,0xfffff
ffffffffc0202874:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202876:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202878:	5086eb63          	bltu	a3,s0,ffffffffc0202d8e <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020287c:	00004517          	auipc	a0,0x4
ffffffffc0202880:	56450513          	addi	a0,a0,1380 # ffffffffc0206de0 <default_pmm_manager+0x220>
ffffffffc0202884:	911fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202888:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020288c:	000d8917          	auipc	s2,0xd8
ffffffffc0202890:	d2490913          	addi	s2,s2,-732 # ffffffffc02da5b0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202894:	7b9c                	ld	a5,48(a5)
ffffffffc0202896:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202898:	00004517          	auipc	a0,0x4
ffffffffc020289c:	56050513          	addi	a0,a0,1376 # ffffffffc0206df8 <default_pmm_manager+0x238>
ffffffffc02028a0:	8f5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028a4:	00008697          	auipc	a3,0x8
ffffffffc02028a8:	75c68693          	addi	a3,a3,1884 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc02028ac:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02028b0:	c02007b7          	lui	a5,0xc0200
ffffffffc02028b4:	28f6ebe3          	bltu	a3,a5,ffffffffc020334a <pmm_init+0xbd0>
ffffffffc02028b8:	0009b783          	ld	a5,0(s3)
ffffffffc02028bc:	8e9d                	sub	a3,a3,a5
ffffffffc02028be:	000d8797          	auipc	a5,0xd8
ffffffffc02028c2:	ced7b523          	sd	a3,-790(a5) # ffffffffc02da5a8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02028c6:	100027f3          	csrr	a5,sstatus
ffffffffc02028ca:	8b89                	andi	a5,a5,2
ffffffffc02028cc:	4a079763          	bnez	a5,ffffffffc0202d7a <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc02028d0:	000b3783          	ld	a5,0(s6)
ffffffffc02028d4:	779c                	ld	a5,40(a5)
ffffffffc02028d6:	9782                	jalr	a5
ffffffffc02028d8:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028da:	6098                	ld	a4,0(s1)
ffffffffc02028dc:	c80007b7          	lui	a5,0xc8000
ffffffffc02028e0:	83b1                	srli	a5,a5,0xc
ffffffffc02028e2:	66e7e363          	bltu	a5,a4,ffffffffc0202f48 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028e6:	00093503          	ld	a0,0(s2)
ffffffffc02028ea:	62050f63          	beqz	a0,ffffffffc0202f28 <pmm_init+0x7ae>
ffffffffc02028ee:	03451793          	slli	a5,a0,0x34
ffffffffc02028f2:	62079b63          	bnez	a5,ffffffffc0202f28 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028f6:	4601                	li	a2,0
ffffffffc02028f8:	4581                	li	a1,0
ffffffffc02028fa:	8c3ff0ef          	jal	ra,ffffffffc02021bc <get_page>
ffffffffc02028fe:	60051563          	bnez	a0,ffffffffc0202f08 <pmm_init+0x78e>
ffffffffc0202902:	100027f3          	csrr	a5,sstatus
ffffffffc0202906:	8b89                	andi	a5,a5,2
ffffffffc0202908:	44079e63          	bnez	a5,ffffffffc0202d64 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc020290c:	000b3783          	ld	a5,0(s6)
ffffffffc0202910:	4505                	li	a0,1
ffffffffc0202912:	6f9c                	ld	a5,24(a5)
ffffffffc0202914:	9782                	jalr	a5
ffffffffc0202916:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202918:	00093503          	ld	a0,0(s2)
ffffffffc020291c:	4681                	li	a3,0
ffffffffc020291e:	4601                	li	a2,0
ffffffffc0202920:	85d2                	mv	a1,s4
ffffffffc0202922:	d63ff0ef          	jal	ra,ffffffffc0202684 <page_insert>
ffffffffc0202926:	26051ae3          	bnez	a0,ffffffffc020339a <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020292a:	00093503          	ld	a0,0(s2)
ffffffffc020292e:	4601                	li	a2,0
ffffffffc0202930:	4581                	li	a1,0
ffffffffc0202932:	e62ff0ef          	jal	ra,ffffffffc0201f94 <get_pte>
ffffffffc0202936:	240502e3          	beqz	a0,ffffffffc020337a <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc020293a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc020293c:	0017f713          	andi	a4,a5,1
ffffffffc0202940:	5a070263          	beqz	a4,ffffffffc0202ee4 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202944:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202946:	078a                	slli	a5,a5,0x2
ffffffffc0202948:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020294a:	58e7fb63          	bgeu	a5,a4,ffffffffc0202ee0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020294e:	000bb683          	ld	a3,0(s7)
ffffffffc0202952:	fff80637          	lui	a2,0xfff80
ffffffffc0202956:	97b2                	add	a5,a5,a2
ffffffffc0202958:	079a                	slli	a5,a5,0x6
ffffffffc020295a:	97b6                	add	a5,a5,a3
ffffffffc020295c:	14fa17e3          	bne	s4,a5,ffffffffc02032aa <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202960:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc8>
ffffffffc0202964:	4785                	li	a5,1
ffffffffc0202966:	12f692e3          	bne	a3,a5,ffffffffc020328a <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020296a:	00093503          	ld	a0,0(s2)
ffffffffc020296e:	77fd                	lui	a5,0xfffff
ffffffffc0202970:	6114                	ld	a3,0(a0)
ffffffffc0202972:	068a                	slli	a3,a3,0x2
ffffffffc0202974:	8efd                	and	a3,a3,a5
ffffffffc0202976:	00c6d613          	srli	a2,a3,0xc
ffffffffc020297a:	0ee67ce3          	bgeu	a2,a4,ffffffffc0203272 <pmm_init+0xaf8>
ffffffffc020297e:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202982:	96e2                	add	a3,a3,s8
ffffffffc0202984:	0006ba83          	ld	s5,0(a3)
ffffffffc0202988:	0a8a                	slli	s5,s5,0x2
ffffffffc020298a:	00fafab3          	and	s5,s5,a5
ffffffffc020298e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202992:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0203258 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202996:	4601                	li	a2,0
ffffffffc0202998:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020299a:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020299c:	df8ff0ef          	jal	ra,ffffffffc0201f94 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029a0:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029a2:	55551363          	bne	a0,s5,ffffffffc0202ee8 <pmm_init+0x76e>
ffffffffc02029a6:	100027f3          	csrr	a5,sstatus
ffffffffc02029aa:	8b89                	andi	a5,a5,2
ffffffffc02029ac:	3a079163          	bnez	a5,ffffffffc0202d4e <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc02029b0:	000b3783          	ld	a5,0(s6)
ffffffffc02029b4:	4505                	li	a0,1
ffffffffc02029b6:	6f9c                	ld	a5,24(a5)
ffffffffc02029b8:	9782                	jalr	a5
ffffffffc02029ba:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02029bc:	00093503          	ld	a0,0(s2)
ffffffffc02029c0:	46d1                	li	a3,20
ffffffffc02029c2:	6605                	lui	a2,0x1
ffffffffc02029c4:	85e2                	mv	a1,s8
ffffffffc02029c6:	cbfff0ef          	jal	ra,ffffffffc0202684 <page_insert>
ffffffffc02029ca:	060517e3          	bnez	a0,ffffffffc0203238 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029ce:	00093503          	ld	a0,0(s2)
ffffffffc02029d2:	4601                	li	a2,0
ffffffffc02029d4:	6585                	lui	a1,0x1
ffffffffc02029d6:	dbeff0ef          	jal	ra,ffffffffc0201f94 <get_pte>
ffffffffc02029da:	02050fe3          	beqz	a0,ffffffffc0203218 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc02029de:	611c                	ld	a5,0(a0)
ffffffffc02029e0:	0107f713          	andi	a4,a5,16
ffffffffc02029e4:	7c070e63          	beqz	a4,ffffffffc02031c0 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02029e8:	8b91                	andi	a5,a5,4
ffffffffc02029ea:	7a078b63          	beqz	a5,ffffffffc02031a0 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02029ee:	00093503          	ld	a0,0(s2)
ffffffffc02029f2:	611c                	ld	a5,0(a0)
ffffffffc02029f4:	8bc1                	andi	a5,a5,16
ffffffffc02029f6:	78078563          	beqz	a5,ffffffffc0203180 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02029fa:	000c2703          	lw	a4,0(s8)
ffffffffc02029fe:	4785                	li	a5,1
ffffffffc0202a00:	76f71063          	bne	a4,a5,ffffffffc0203160 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202a04:	4681                	li	a3,0
ffffffffc0202a06:	6605                	lui	a2,0x1
ffffffffc0202a08:	85d2                	mv	a1,s4
ffffffffc0202a0a:	c7bff0ef          	jal	ra,ffffffffc0202684 <page_insert>
ffffffffc0202a0e:	72051963          	bnez	a0,ffffffffc0203140 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202a12:	000a2703          	lw	a4,0(s4)
ffffffffc0202a16:	4789                	li	a5,2
ffffffffc0202a18:	70f71463          	bne	a4,a5,ffffffffc0203120 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202a1c:	000c2783          	lw	a5,0(s8)
ffffffffc0202a20:	6e079063          	bnez	a5,ffffffffc0203100 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a24:	00093503          	ld	a0,0(s2)
ffffffffc0202a28:	4601                	li	a2,0
ffffffffc0202a2a:	6585                	lui	a1,0x1
ffffffffc0202a2c:	d68ff0ef          	jal	ra,ffffffffc0201f94 <get_pte>
ffffffffc0202a30:	6a050863          	beqz	a0,ffffffffc02030e0 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a34:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a36:	00177793          	andi	a5,a4,1
ffffffffc0202a3a:	4a078563          	beqz	a5,ffffffffc0202ee4 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202a3e:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a40:	00271793          	slli	a5,a4,0x2
ffffffffc0202a44:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a46:	48d7fd63          	bgeu	a5,a3,ffffffffc0202ee0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a4a:	000bb683          	ld	a3,0(s7)
ffffffffc0202a4e:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a52:	97d6                	add	a5,a5,s5
ffffffffc0202a54:	079a                	slli	a5,a5,0x6
ffffffffc0202a56:	97b6                	add	a5,a5,a3
ffffffffc0202a58:	66fa1463          	bne	s4,a5,ffffffffc02030c0 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a5c:	8b41                	andi	a4,a4,16
ffffffffc0202a5e:	64071163          	bnez	a4,ffffffffc02030a0 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a62:	00093503          	ld	a0,0(s2)
ffffffffc0202a66:	4581                	li	a1,0
ffffffffc0202a68:	b81ff0ef          	jal	ra,ffffffffc02025e8 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a6c:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a70:	4785                	li	a5,1
ffffffffc0202a72:	60fc9763          	bne	s9,a5,ffffffffc0203080 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202a76:	000c2783          	lw	a5,0(s8)
ffffffffc0202a7a:	5e079363          	bnez	a5,ffffffffc0203060 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a7e:	00093503          	ld	a0,0(s2)
ffffffffc0202a82:	6585                	lui	a1,0x1
ffffffffc0202a84:	b65ff0ef          	jal	ra,ffffffffc02025e8 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a88:	000a2783          	lw	a5,0(s4)
ffffffffc0202a8c:	52079a63          	bnez	a5,ffffffffc0202fc0 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202a90:	000c2783          	lw	a5,0(s8)
ffffffffc0202a94:	50079663          	bnez	a5,ffffffffc0202fa0 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a98:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a9c:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a9e:	000a3683          	ld	a3,0(s4)
ffffffffc0202aa2:	068a                	slli	a3,a3,0x2
ffffffffc0202aa4:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aa6:	42b6fd63          	bgeu	a3,a1,ffffffffc0202ee0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202aaa:	000bb503          	ld	a0,0(s7)
ffffffffc0202aae:	96d6                	add	a3,a3,s5
ffffffffc0202ab0:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202ab2:	00d507b3          	add	a5,a0,a3
ffffffffc0202ab6:	439c                	lw	a5,0(a5)
ffffffffc0202ab8:	4d979463          	bne	a5,s9,ffffffffc0202f80 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202abc:	8699                	srai	a3,a3,0x6
ffffffffc0202abe:	00080637          	lui	a2,0x80
ffffffffc0202ac2:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202ac4:	00c69713          	slli	a4,a3,0xc
ffffffffc0202ac8:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202aca:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202acc:	48b77e63          	bgeu	a4,a1,ffffffffc0202f68 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202ad0:	0009b703          	ld	a4,0(s3)
ffffffffc0202ad4:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ad6:	629c                	ld	a5,0(a3)
ffffffffc0202ad8:	078a                	slli	a5,a5,0x2
ffffffffc0202ada:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202adc:	40b7f263          	bgeu	a5,a1,ffffffffc0202ee0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ae0:	8f91                	sub	a5,a5,a2
ffffffffc0202ae2:	079a                	slli	a5,a5,0x6
ffffffffc0202ae4:	953e                	add	a0,a0,a5
ffffffffc0202ae6:	100027f3          	csrr	a5,sstatus
ffffffffc0202aea:	8b89                	andi	a5,a5,2
ffffffffc0202aec:	30079963          	bnez	a5,ffffffffc0202dfe <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202af0:	000b3783          	ld	a5,0(s6)
ffffffffc0202af4:	4585                	li	a1,1
ffffffffc0202af6:	739c                	ld	a5,32(a5)
ffffffffc0202af8:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202afa:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202afe:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b00:	078a                	slli	a5,a5,0x2
ffffffffc0202b02:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b04:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202ee0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b08:	000bb503          	ld	a0,0(s7)
ffffffffc0202b0c:	fff80737          	lui	a4,0xfff80
ffffffffc0202b10:	97ba                	add	a5,a5,a4
ffffffffc0202b12:	079a                	slli	a5,a5,0x6
ffffffffc0202b14:	953e                	add	a0,a0,a5
ffffffffc0202b16:	100027f3          	csrr	a5,sstatus
ffffffffc0202b1a:	8b89                	andi	a5,a5,2
ffffffffc0202b1c:	2c079563          	bnez	a5,ffffffffc0202de6 <pmm_init+0x66c>
ffffffffc0202b20:	000b3783          	ld	a5,0(s6)
ffffffffc0202b24:	4585                	li	a1,1
ffffffffc0202b26:	739c                	ld	a5,32(a5)
ffffffffc0202b28:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b2a:	00093783          	ld	a5,0(s2)
ffffffffc0202b2e:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd24a0c>
    asm volatile("sfence.vma");
ffffffffc0202b32:	12000073          	sfence.vma
ffffffffc0202b36:	100027f3          	csrr	a5,sstatus
ffffffffc0202b3a:	8b89                	andi	a5,a5,2
ffffffffc0202b3c:	28079b63          	bnez	a5,ffffffffc0202dd2 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b40:	000b3783          	ld	a5,0(s6)
ffffffffc0202b44:	779c                	ld	a5,40(a5)
ffffffffc0202b46:	9782                	jalr	a5
ffffffffc0202b48:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b4a:	4b441b63          	bne	s0,s4,ffffffffc0203000 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b4e:	00004517          	auipc	a0,0x4
ffffffffc0202b52:	5d250513          	addi	a0,a0,1490 # ffffffffc0207120 <default_pmm_manager+0x560>
ffffffffc0202b56:	e3efd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202b5a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b5e:	8b89                	andi	a5,a5,2
ffffffffc0202b60:	24079f63          	bnez	a5,ffffffffc0202dbe <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b64:	000b3783          	ld	a5,0(s6)
ffffffffc0202b68:	779c                	ld	a5,40(a5)
ffffffffc0202b6a:	9782                	jalr	a5
ffffffffc0202b6c:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b6e:	6098                	ld	a4,0(s1)
ffffffffc0202b70:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b74:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b76:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b7a:	6a05                	lui	s4,0x1
ffffffffc0202b7c:	02f47c63          	bgeu	s0,a5,ffffffffc0202bb4 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b80:	00c45793          	srli	a5,s0,0xc
ffffffffc0202b84:	00093503          	ld	a0,0(s2)
ffffffffc0202b88:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202e86 <pmm_init+0x70c>
ffffffffc0202b8c:	0009b583          	ld	a1,0(s3)
ffffffffc0202b90:	4601                	li	a2,0
ffffffffc0202b92:	95a2                	add	a1,a1,s0
ffffffffc0202b94:	c00ff0ef          	jal	ra,ffffffffc0201f94 <get_pte>
ffffffffc0202b98:	32050463          	beqz	a0,ffffffffc0202ec0 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b9c:	611c                	ld	a5,0(a0)
ffffffffc0202b9e:	078a                	slli	a5,a5,0x2
ffffffffc0202ba0:	0157f7b3          	and	a5,a5,s5
ffffffffc0202ba4:	2e879e63          	bne	a5,s0,ffffffffc0202ea0 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202ba8:	6098                	ld	a4,0(s1)
ffffffffc0202baa:	9452                	add	s0,s0,s4
ffffffffc0202bac:	00c71793          	slli	a5,a4,0xc
ffffffffc0202bb0:	fcf468e3          	bltu	s0,a5,ffffffffc0202b80 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202bb4:	00093783          	ld	a5,0(s2)
ffffffffc0202bb8:	639c                	ld	a5,0(a5)
ffffffffc0202bba:	42079363          	bnez	a5,ffffffffc0202fe0 <pmm_init+0x866>
ffffffffc0202bbe:	100027f3          	csrr	a5,sstatus
ffffffffc0202bc2:	8b89                	andi	a5,a5,2
ffffffffc0202bc4:	24079963          	bnez	a5,ffffffffc0202e16 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202bc8:	000b3783          	ld	a5,0(s6)
ffffffffc0202bcc:	4505                	li	a0,1
ffffffffc0202bce:	6f9c                	ld	a5,24(a5)
ffffffffc0202bd0:	9782                	jalr	a5
ffffffffc0202bd2:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202bd4:	00093503          	ld	a0,0(s2)
ffffffffc0202bd8:	4699                	li	a3,6
ffffffffc0202bda:	10000613          	li	a2,256
ffffffffc0202bde:	85d2                	mv	a1,s4
ffffffffc0202be0:	aa5ff0ef          	jal	ra,ffffffffc0202684 <page_insert>
ffffffffc0202be4:	44051e63          	bnez	a0,ffffffffc0203040 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202be8:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc8>
ffffffffc0202bec:	4785                	li	a5,1
ffffffffc0202bee:	42f71963          	bne	a4,a5,ffffffffc0203020 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202bf2:	00093503          	ld	a0,0(s2)
ffffffffc0202bf6:	6405                	lui	s0,0x1
ffffffffc0202bf8:	4699                	li	a3,6
ffffffffc0202bfa:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ac8>
ffffffffc0202bfe:	85d2                	mv	a1,s4
ffffffffc0202c00:	a85ff0ef          	jal	ra,ffffffffc0202684 <page_insert>
ffffffffc0202c04:	72051363          	bnez	a0,ffffffffc020332a <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202c08:	000a2703          	lw	a4,0(s4)
ffffffffc0202c0c:	4789                	li	a5,2
ffffffffc0202c0e:	6ef71e63          	bne	a4,a5,ffffffffc020330a <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c12:	00004597          	auipc	a1,0x4
ffffffffc0202c16:	65658593          	addi	a1,a1,1622 # ffffffffc0207268 <default_pmm_manager+0x6a8>
ffffffffc0202c1a:	10000513          	li	a0,256
ffffffffc0202c1e:	038030ef          	jal	ra,ffffffffc0205c56 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c22:	10040593          	addi	a1,s0,256
ffffffffc0202c26:	10000513          	li	a0,256
ffffffffc0202c2a:	03e030ef          	jal	ra,ffffffffc0205c68 <strcmp>
ffffffffc0202c2e:	6a051e63          	bnez	a0,ffffffffc02032ea <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202c32:	000bb683          	ld	a3,0(s7)
ffffffffc0202c36:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202c3a:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202c3c:	40da06b3          	sub	a3,s4,a3
ffffffffc0202c40:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202c42:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202c44:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202c46:	8031                	srli	s0,s0,0xc
ffffffffc0202c48:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c4c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c4e:	30f77d63          	bgeu	a4,a5,ffffffffc0202f68 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c52:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c56:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c5a:	96be                	add	a3,a3,a5
ffffffffc0202c5c:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c60:	7c1020ef          	jal	ra,ffffffffc0205c20 <strlen>
ffffffffc0202c64:	66051363          	bnez	a0,ffffffffc02032ca <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c68:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c6c:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c6e:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd24a0c>
ffffffffc0202c72:	068a                	slli	a3,a3,0x2
ffffffffc0202c74:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c76:	26f6f563          	bgeu	a3,a5,ffffffffc0202ee0 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202c7a:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c7c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c7e:	2ef47563          	bgeu	s0,a5,ffffffffc0202f68 <pmm_init+0x7ee>
ffffffffc0202c82:	0009b403          	ld	s0,0(s3)
ffffffffc0202c86:	9436                	add	s0,s0,a3
ffffffffc0202c88:	100027f3          	csrr	a5,sstatus
ffffffffc0202c8c:	8b89                	andi	a5,a5,2
ffffffffc0202c8e:	1e079163          	bnez	a5,ffffffffc0202e70 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202c92:	000b3783          	ld	a5,0(s6)
ffffffffc0202c96:	4585                	li	a1,1
ffffffffc0202c98:	8552                	mv	a0,s4
ffffffffc0202c9a:	739c                	ld	a5,32(a5)
ffffffffc0202c9c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c9e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202ca0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ca2:	078a                	slli	a5,a5,0x2
ffffffffc0202ca4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ca6:	22e7fd63          	bgeu	a5,a4,ffffffffc0202ee0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202caa:	000bb503          	ld	a0,0(s7)
ffffffffc0202cae:	fff80737          	lui	a4,0xfff80
ffffffffc0202cb2:	97ba                	add	a5,a5,a4
ffffffffc0202cb4:	079a                	slli	a5,a5,0x6
ffffffffc0202cb6:	953e                	add	a0,a0,a5
ffffffffc0202cb8:	100027f3          	csrr	a5,sstatus
ffffffffc0202cbc:	8b89                	andi	a5,a5,2
ffffffffc0202cbe:	18079d63          	bnez	a5,ffffffffc0202e58 <pmm_init+0x6de>
ffffffffc0202cc2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cc6:	4585                	li	a1,1
ffffffffc0202cc8:	739c                	ld	a5,32(a5)
ffffffffc0202cca:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ccc:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202cd0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cd2:	078a                	slli	a5,a5,0x2
ffffffffc0202cd4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cd6:	20e7f563          	bgeu	a5,a4,ffffffffc0202ee0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cda:	000bb503          	ld	a0,0(s7)
ffffffffc0202cde:	fff80737          	lui	a4,0xfff80
ffffffffc0202ce2:	97ba                	add	a5,a5,a4
ffffffffc0202ce4:	079a                	slli	a5,a5,0x6
ffffffffc0202ce6:	953e                	add	a0,a0,a5
ffffffffc0202ce8:	100027f3          	csrr	a5,sstatus
ffffffffc0202cec:	8b89                	andi	a5,a5,2
ffffffffc0202cee:	14079963          	bnez	a5,ffffffffc0202e40 <pmm_init+0x6c6>
ffffffffc0202cf2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cf6:	4585                	li	a1,1
ffffffffc0202cf8:	739c                	ld	a5,32(a5)
ffffffffc0202cfa:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202cfc:	00093783          	ld	a5,0(s2)
ffffffffc0202d00:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202d04:	12000073          	sfence.vma
ffffffffc0202d08:	100027f3          	csrr	a5,sstatus
ffffffffc0202d0c:	8b89                	andi	a5,a5,2
ffffffffc0202d0e:	10079f63          	bnez	a5,ffffffffc0202e2c <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d12:	000b3783          	ld	a5,0(s6)
ffffffffc0202d16:	779c                	ld	a5,40(a5)
ffffffffc0202d18:	9782                	jalr	a5
ffffffffc0202d1a:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d1c:	4c8c1e63          	bne	s8,s0,ffffffffc02031f8 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d20:	00004517          	auipc	a0,0x4
ffffffffc0202d24:	5c050513          	addi	a0,a0,1472 # ffffffffc02072e0 <default_pmm_manager+0x720>
ffffffffc0202d28:	c6cfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202d2c:	7406                	ld	s0,96(sp)
ffffffffc0202d2e:	70a6                	ld	ra,104(sp)
ffffffffc0202d30:	64e6                	ld	s1,88(sp)
ffffffffc0202d32:	6946                	ld	s2,80(sp)
ffffffffc0202d34:	69a6                	ld	s3,72(sp)
ffffffffc0202d36:	6a06                	ld	s4,64(sp)
ffffffffc0202d38:	7ae2                	ld	s5,56(sp)
ffffffffc0202d3a:	7b42                	ld	s6,48(sp)
ffffffffc0202d3c:	7ba2                	ld	s7,40(sp)
ffffffffc0202d3e:	7c02                	ld	s8,32(sp)
ffffffffc0202d40:	6ce2                	ld	s9,24(sp)
ffffffffc0202d42:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d44:	f97fe06f          	j	ffffffffc0201cda <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202d48:	c80007b7          	lui	a5,0xc8000
ffffffffc0202d4c:	bc7d                	j	ffffffffc020280a <pmm_init+0x90>
        intr_disable();
ffffffffc0202d4e:	c67fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d52:	000b3783          	ld	a5,0(s6)
ffffffffc0202d56:	4505                	li	a0,1
ffffffffc0202d58:	6f9c                	ld	a5,24(a5)
ffffffffc0202d5a:	9782                	jalr	a5
ffffffffc0202d5c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d5e:	c51fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d62:	b9a9                	j	ffffffffc02029bc <pmm_init+0x242>
        intr_disable();
ffffffffc0202d64:	c51fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d68:	000b3783          	ld	a5,0(s6)
ffffffffc0202d6c:	4505                	li	a0,1
ffffffffc0202d6e:	6f9c                	ld	a5,24(a5)
ffffffffc0202d70:	9782                	jalr	a5
ffffffffc0202d72:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d74:	c3bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d78:	b645                	j	ffffffffc0202918 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202d7a:	c3bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d7e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d82:	779c                	ld	a5,40(a5)
ffffffffc0202d84:	9782                	jalr	a5
ffffffffc0202d86:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d88:	c27fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d8c:	b6b9                	j	ffffffffc02028da <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d8e:	6705                	lui	a4,0x1
ffffffffc0202d90:	177d                	addi	a4,a4,-1
ffffffffc0202d92:	96ba                	add	a3,a3,a4
ffffffffc0202d94:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d96:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d9a:	14a77363          	bgeu	a4,a0,ffffffffc0202ee0 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d9e:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202da2:	fff80537          	lui	a0,0xfff80
ffffffffc0202da6:	972a                	add	a4,a4,a0
ffffffffc0202da8:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202daa:	8c1d                	sub	s0,s0,a5
ffffffffc0202dac:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202db0:	00c45593          	srli	a1,s0,0xc
ffffffffc0202db4:	9532                	add	a0,a0,a2
ffffffffc0202db6:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202db8:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202dbc:	b4c1                	j	ffffffffc020287c <pmm_init+0x102>
        intr_disable();
ffffffffc0202dbe:	bf7fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dc2:	000b3783          	ld	a5,0(s6)
ffffffffc0202dc6:	779c                	ld	a5,40(a5)
ffffffffc0202dc8:	9782                	jalr	a5
ffffffffc0202dca:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202dcc:	be3fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dd0:	bb79                	j	ffffffffc0202b6e <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202dd2:	be3fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202dd6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dda:	779c                	ld	a5,40(a5)
ffffffffc0202ddc:	9782                	jalr	a5
ffffffffc0202dde:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202de0:	bcffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202de4:	b39d                	j	ffffffffc0202b4a <pmm_init+0x3d0>
ffffffffc0202de6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202de8:	bcdfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202dec:	000b3783          	ld	a5,0(s6)
ffffffffc0202df0:	6522                	ld	a0,8(sp)
ffffffffc0202df2:	4585                	li	a1,1
ffffffffc0202df4:	739c                	ld	a5,32(a5)
ffffffffc0202df6:	9782                	jalr	a5
        intr_enable();
ffffffffc0202df8:	bb7fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dfc:	b33d                	j	ffffffffc0202b2a <pmm_init+0x3b0>
ffffffffc0202dfe:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e00:	bb5fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e04:	000b3783          	ld	a5,0(s6)
ffffffffc0202e08:	6522                	ld	a0,8(sp)
ffffffffc0202e0a:	4585                	li	a1,1
ffffffffc0202e0c:	739c                	ld	a5,32(a5)
ffffffffc0202e0e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e10:	b9ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e14:	b1dd                	j	ffffffffc0202afa <pmm_init+0x380>
        intr_disable();
ffffffffc0202e16:	b9ffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e1a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e1e:	4505                	li	a0,1
ffffffffc0202e20:	6f9c                	ld	a5,24(a5)
ffffffffc0202e22:	9782                	jalr	a5
ffffffffc0202e24:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e26:	b89fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e2a:	b36d                	j	ffffffffc0202bd4 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202e2c:	b89fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e30:	000b3783          	ld	a5,0(s6)
ffffffffc0202e34:	779c                	ld	a5,40(a5)
ffffffffc0202e36:	9782                	jalr	a5
ffffffffc0202e38:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e3a:	b75fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e3e:	bdf9                	j	ffffffffc0202d1c <pmm_init+0x5a2>
ffffffffc0202e40:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e42:	b73fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e46:	000b3783          	ld	a5,0(s6)
ffffffffc0202e4a:	6522                	ld	a0,8(sp)
ffffffffc0202e4c:	4585                	li	a1,1
ffffffffc0202e4e:	739c                	ld	a5,32(a5)
ffffffffc0202e50:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e52:	b5dfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e56:	b55d                	j	ffffffffc0202cfc <pmm_init+0x582>
ffffffffc0202e58:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e5a:	b5bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e5e:	000b3783          	ld	a5,0(s6)
ffffffffc0202e62:	6522                	ld	a0,8(sp)
ffffffffc0202e64:	4585                	li	a1,1
ffffffffc0202e66:	739c                	ld	a5,32(a5)
ffffffffc0202e68:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e6a:	b45fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e6e:	bdb9                	j	ffffffffc0202ccc <pmm_init+0x552>
        intr_disable();
ffffffffc0202e70:	b45fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e74:	000b3783          	ld	a5,0(s6)
ffffffffc0202e78:	4585                	li	a1,1
ffffffffc0202e7a:	8552                	mv	a0,s4
ffffffffc0202e7c:	739c                	ld	a5,32(a5)
ffffffffc0202e7e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e80:	b2ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e84:	bd29                	j	ffffffffc0202c9e <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e86:	86a2                	mv	a3,s0
ffffffffc0202e88:	00004617          	auipc	a2,0x4
ffffffffc0202e8c:	d7060613          	addi	a2,a2,-656 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc0202e90:	29900593          	li	a1,665
ffffffffc0202e94:	00004517          	auipc	a0,0x4
ffffffffc0202e98:	e7c50513          	addi	a0,a0,-388 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0202e9c:	df2fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ea0:	00004697          	auipc	a3,0x4
ffffffffc0202ea4:	2e068693          	addi	a3,a3,736 # ffffffffc0207180 <default_pmm_manager+0x5c0>
ffffffffc0202ea8:	00003617          	auipc	a2,0x3
ffffffffc0202eac:	6a860613          	addi	a2,a2,1704 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0202eb0:	29a00593          	li	a1,666
ffffffffc0202eb4:	00004517          	auipc	a0,0x4
ffffffffc0202eb8:	e5c50513          	addi	a0,a0,-420 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0202ebc:	dd2fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ec0:	00004697          	auipc	a3,0x4
ffffffffc0202ec4:	28068693          	addi	a3,a3,640 # ffffffffc0207140 <default_pmm_manager+0x580>
ffffffffc0202ec8:	00003617          	auipc	a2,0x3
ffffffffc0202ecc:	68860613          	addi	a2,a2,1672 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0202ed0:	29900593          	li	a1,665
ffffffffc0202ed4:	00004517          	auipc	a0,0x4
ffffffffc0202ed8:	e3c50513          	addi	a0,a0,-452 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0202edc:	db2fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202ee0:	fc5fe0ef          	jal	ra,ffffffffc0201ea4 <pa2page.part.0>
ffffffffc0202ee4:	fddfe0ef          	jal	ra,ffffffffc0201ec0 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202ee8:	00004697          	auipc	a3,0x4
ffffffffc0202eec:	05068693          	addi	a3,a3,80 # ffffffffc0206f38 <default_pmm_manager+0x378>
ffffffffc0202ef0:	00003617          	auipc	a2,0x3
ffffffffc0202ef4:	66060613          	addi	a2,a2,1632 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0202ef8:	26900593          	li	a1,617
ffffffffc0202efc:	00004517          	auipc	a0,0x4
ffffffffc0202f00:	e1450513          	addi	a0,a0,-492 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0202f04:	d8afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202f08:	00004697          	auipc	a3,0x4
ffffffffc0202f0c:	f7068693          	addi	a3,a3,-144 # ffffffffc0206e78 <default_pmm_manager+0x2b8>
ffffffffc0202f10:	00003617          	auipc	a2,0x3
ffffffffc0202f14:	64060613          	addi	a2,a2,1600 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0202f18:	25c00593          	li	a1,604
ffffffffc0202f1c:	00004517          	auipc	a0,0x4
ffffffffc0202f20:	df450513          	addi	a0,a0,-524 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0202f24:	d6afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f28:	00004697          	auipc	a3,0x4
ffffffffc0202f2c:	f1068693          	addi	a3,a3,-240 # ffffffffc0206e38 <default_pmm_manager+0x278>
ffffffffc0202f30:	00003617          	auipc	a2,0x3
ffffffffc0202f34:	62060613          	addi	a2,a2,1568 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0202f38:	25b00593          	li	a1,603
ffffffffc0202f3c:	00004517          	auipc	a0,0x4
ffffffffc0202f40:	dd450513          	addi	a0,a0,-556 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0202f44:	d4afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f48:	00004697          	auipc	a3,0x4
ffffffffc0202f4c:	ed068693          	addi	a3,a3,-304 # ffffffffc0206e18 <default_pmm_manager+0x258>
ffffffffc0202f50:	00003617          	auipc	a2,0x3
ffffffffc0202f54:	60060613          	addi	a2,a2,1536 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0202f58:	25a00593          	li	a1,602
ffffffffc0202f5c:	00004517          	auipc	a0,0x4
ffffffffc0202f60:	db450513          	addi	a0,a0,-588 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0202f64:	d2afd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f68:	00004617          	auipc	a2,0x4
ffffffffc0202f6c:	c9060613          	addi	a2,a2,-880 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc0202f70:	07200593          	li	a1,114
ffffffffc0202f74:	00004517          	auipc	a0,0x4
ffffffffc0202f78:	cac50513          	addi	a0,a0,-852 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc0202f7c:	d12fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f80:	00004697          	auipc	a3,0x4
ffffffffc0202f84:	14868693          	addi	a3,a3,328 # ffffffffc02070c8 <default_pmm_manager+0x508>
ffffffffc0202f88:	00003617          	auipc	a2,0x3
ffffffffc0202f8c:	5c860613          	addi	a2,a2,1480 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0202f90:	28200593          	li	a1,642
ffffffffc0202f94:	00004517          	auipc	a0,0x4
ffffffffc0202f98:	d7c50513          	addi	a0,a0,-644 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0202f9c:	cf2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fa0:	00004697          	auipc	a3,0x4
ffffffffc0202fa4:	0e068693          	addi	a3,a3,224 # ffffffffc0207080 <default_pmm_manager+0x4c0>
ffffffffc0202fa8:	00003617          	auipc	a2,0x3
ffffffffc0202fac:	5a860613          	addi	a2,a2,1448 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0202fb0:	28000593          	li	a1,640
ffffffffc0202fb4:	00004517          	auipc	a0,0x4
ffffffffc0202fb8:	d5c50513          	addi	a0,a0,-676 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0202fbc:	cd2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202fc0:	00004697          	auipc	a3,0x4
ffffffffc0202fc4:	0f068693          	addi	a3,a3,240 # ffffffffc02070b0 <default_pmm_manager+0x4f0>
ffffffffc0202fc8:	00003617          	auipc	a2,0x3
ffffffffc0202fcc:	58860613          	addi	a2,a2,1416 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0202fd0:	27f00593          	li	a1,639
ffffffffc0202fd4:	00004517          	auipc	a0,0x4
ffffffffc0202fd8:	d3c50513          	addi	a0,a0,-708 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0202fdc:	cb2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202fe0:	00004697          	auipc	a3,0x4
ffffffffc0202fe4:	1b868693          	addi	a3,a3,440 # ffffffffc0207198 <default_pmm_manager+0x5d8>
ffffffffc0202fe8:	00003617          	auipc	a2,0x3
ffffffffc0202fec:	56860613          	addi	a2,a2,1384 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0202ff0:	29d00593          	li	a1,669
ffffffffc0202ff4:	00004517          	auipc	a0,0x4
ffffffffc0202ff8:	d1c50513          	addi	a0,a0,-740 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0202ffc:	c92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203000:	00004697          	auipc	a3,0x4
ffffffffc0203004:	0f868693          	addi	a3,a3,248 # ffffffffc02070f8 <default_pmm_manager+0x538>
ffffffffc0203008:	00003617          	auipc	a2,0x3
ffffffffc020300c:	54860613          	addi	a2,a2,1352 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203010:	28a00593          	li	a1,650
ffffffffc0203014:	00004517          	auipc	a0,0x4
ffffffffc0203018:	cfc50513          	addi	a0,a0,-772 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020301c:	c72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203020:	00004697          	auipc	a3,0x4
ffffffffc0203024:	1d068693          	addi	a3,a3,464 # ffffffffc02071f0 <default_pmm_manager+0x630>
ffffffffc0203028:	00003617          	auipc	a2,0x3
ffffffffc020302c:	52860613          	addi	a2,a2,1320 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203030:	2a200593          	li	a1,674
ffffffffc0203034:	00004517          	auipc	a0,0x4
ffffffffc0203038:	cdc50513          	addi	a0,a0,-804 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020303c:	c52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203040:	00004697          	auipc	a3,0x4
ffffffffc0203044:	17068693          	addi	a3,a3,368 # ffffffffc02071b0 <default_pmm_manager+0x5f0>
ffffffffc0203048:	00003617          	auipc	a2,0x3
ffffffffc020304c:	50860613          	addi	a2,a2,1288 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203050:	2a100593          	li	a1,673
ffffffffc0203054:	00004517          	auipc	a0,0x4
ffffffffc0203058:	cbc50513          	addi	a0,a0,-836 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020305c:	c32fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203060:	00004697          	auipc	a3,0x4
ffffffffc0203064:	02068693          	addi	a3,a3,32 # ffffffffc0207080 <default_pmm_manager+0x4c0>
ffffffffc0203068:	00003617          	auipc	a2,0x3
ffffffffc020306c:	4e860613          	addi	a2,a2,1256 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203070:	27c00593          	li	a1,636
ffffffffc0203074:	00004517          	auipc	a0,0x4
ffffffffc0203078:	c9c50513          	addi	a0,a0,-868 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020307c:	c12fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203080:	00004697          	auipc	a3,0x4
ffffffffc0203084:	ea068693          	addi	a3,a3,-352 # ffffffffc0206f20 <default_pmm_manager+0x360>
ffffffffc0203088:	00003617          	auipc	a2,0x3
ffffffffc020308c:	4c860613          	addi	a2,a2,1224 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203090:	27b00593          	li	a1,635
ffffffffc0203094:	00004517          	auipc	a0,0x4
ffffffffc0203098:	c7c50513          	addi	a0,a0,-900 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020309c:	bf2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02030a0:	00004697          	auipc	a3,0x4
ffffffffc02030a4:	ff868693          	addi	a3,a3,-8 # ffffffffc0207098 <default_pmm_manager+0x4d8>
ffffffffc02030a8:	00003617          	auipc	a2,0x3
ffffffffc02030ac:	4a860613          	addi	a2,a2,1192 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02030b0:	27800593          	li	a1,632
ffffffffc02030b4:	00004517          	auipc	a0,0x4
ffffffffc02030b8:	c5c50513          	addi	a0,a0,-932 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02030bc:	bd2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02030c0:	00004697          	auipc	a3,0x4
ffffffffc02030c4:	e4868693          	addi	a3,a3,-440 # ffffffffc0206f08 <default_pmm_manager+0x348>
ffffffffc02030c8:	00003617          	auipc	a2,0x3
ffffffffc02030cc:	48860613          	addi	a2,a2,1160 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02030d0:	27700593          	li	a1,631
ffffffffc02030d4:	00004517          	auipc	a0,0x4
ffffffffc02030d8:	c3c50513          	addi	a0,a0,-964 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02030dc:	bb2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030e0:	00004697          	auipc	a3,0x4
ffffffffc02030e4:	ec868693          	addi	a3,a3,-312 # ffffffffc0206fa8 <default_pmm_manager+0x3e8>
ffffffffc02030e8:	00003617          	auipc	a2,0x3
ffffffffc02030ec:	46860613          	addi	a2,a2,1128 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02030f0:	27600593          	li	a1,630
ffffffffc02030f4:	00004517          	auipc	a0,0x4
ffffffffc02030f8:	c1c50513          	addi	a0,a0,-996 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02030fc:	b92fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203100:	00004697          	auipc	a3,0x4
ffffffffc0203104:	f8068693          	addi	a3,a3,-128 # ffffffffc0207080 <default_pmm_manager+0x4c0>
ffffffffc0203108:	00003617          	auipc	a2,0x3
ffffffffc020310c:	44860613          	addi	a2,a2,1096 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203110:	27500593          	li	a1,629
ffffffffc0203114:	00004517          	auipc	a0,0x4
ffffffffc0203118:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020311c:	b72fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203120:	00004697          	auipc	a3,0x4
ffffffffc0203124:	f4868693          	addi	a3,a3,-184 # ffffffffc0207068 <default_pmm_manager+0x4a8>
ffffffffc0203128:	00003617          	auipc	a2,0x3
ffffffffc020312c:	42860613          	addi	a2,a2,1064 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203130:	27400593          	li	a1,628
ffffffffc0203134:	00004517          	auipc	a0,0x4
ffffffffc0203138:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020313c:	b52fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203140:	00004697          	auipc	a3,0x4
ffffffffc0203144:	ef868693          	addi	a3,a3,-264 # ffffffffc0207038 <default_pmm_manager+0x478>
ffffffffc0203148:	00003617          	auipc	a2,0x3
ffffffffc020314c:	40860613          	addi	a2,a2,1032 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203150:	27300593          	li	a1,627
ffffffffc0203154:	00004517          	auipc	a0,0x4
ffffffffc0203158:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020315c:	b32fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203160:	00004697          	auipc	a3,0x4
ffffffffc0203164:	ec068693          	addi	a3,a3,-320 # ffffffffc0207020 <default_pmm_manager+0x460>
ffffffffc0203168:	00003617          	auipc	a2,0x3
ffffffffc020316c:	3e860613          	addi	a2,a2,1000 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203170:	27100593          	li	a1,625
ffffffffc0203174:	00004517          	auipc	a0,0x4
ffffffffc0203178:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020317c:	b12fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203180:	00004697          	auipc	a3,0x4
ffffffffc0203184:	e8068693          	addi	a3,a3,-384 # ffffffffc0207000 <default_pmm_manager+0x440>
ffffffffc0203188:	00003617          	auipc	a2,0x3
ffffffffc020318c:	3c860613          	addi	a2,a2,968 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203190:	27000593          	li	a1,624
ffffffffc0203194:	00004517          	auipc	a0,0x4
ffffffffc0203198:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020319c:	af2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc02031a0:	00004697          	auipc	a3,0x4
ffffffffc02031a4:	e5068693          	addi	a3,a3,-432 # ffffffffc0206ff0 <default_pmm_manager+0x430>
ffffffffc02031a8:	00003617          	auipc	a2,0x3
ffffffffc02031ac:	3a860613          	addi	a2,a2,936 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02031b0:	26f00593          	li	a1,623
ffffffffc02031b4:	00004517          	auipc	a0,0x4
ffffffffc02031b8:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02031bc:	ad2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc02031c0:	00004697          	auipc	a3,0x4
ffffffffc02031c4:	e2068693          	addi	a3,a3,-480 # ffffffffc0206fe0 <default_pmm_manager+0x420>
ffffffffc02031c8:	00003617          	auipc	a2,0x3
ffffffffc02031cc:	38860613          	addi	a2,a2,904 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02031d0:	26e00593          	li	a1,622
ffffffffc02031d4:	00004517          	auipc	a0,0x4
ffffffffc02031d8:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02031dc:	ab2fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc02031e0:	00004617          	auipc	a2,0x4
ffffffffc02031e4:	ba060613          	addi	a2,a2,-1120 # ffffffffc0206d80 <default_pmm_manager+0x1c0>
ffffffffc02031e8:	06500593          	li	a1,101
ffffffffc02031ec:	00004517          	auipc	a0,0x4
ffffffffc02031f0:	b2450513          	addi	a0,a0,-1244 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02031f4:	a9afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02031f8:	00004697          	auipc	a3,0x4
ffffffffc02031fc:	f0068693          	addi	a3,a3,-256 # ffffffffc02070f8 <default_pmm_manager+0x538>
ffffffffc0203200:	00003617          	auipc	a2,0x3
ffffffffc0203204:	35060613          	addi	a2,a2,848 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203208:	2b400593          	li	a1,692
ffffffffc020320c:	00004517          	auipc	a0,0x4
ffffffffc0203210:	b0450513          	addi	a0,a0,-1276 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203214:	a7afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203218:	00004697          	auipc	a3,0x4
ffffffffc020321c:	d9068693          	addi	a3,a3,-624 # ffffffffc0206fa8 <default_pmm_manager+0x3e8>
ffffffffc0203220:	00003617          	auipc	a2,0x3
ffffffffc0203224:	33060613          	addi	a2,a2,816 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203228:	26d00593          	li	a1,621
ffffffffc020322c:	00004517          	auipc	a0,0x4
ffffffffc0203230:	ae450513          	addi	a0,a0,-1308 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203234:	a5afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203238:	00004697          	auipc	a3,0x4
ffffffffc020323c:	d3068693          	addi	a3,a3,-720 # ffffffffc0206f68 <default_pmm_manager+0x3a8>
ffffffffc0203240:	00003617          	auipc	a2,0x3
ffffffffc0203244:	31060613          	addi	a2,a2,784 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203248:	26c00593          	li	a1,620
ffffffffc020324c:	00004517          	auipc	a0,0x4
ffffffffc0203250:	ac450513          	addi	a0,a0,-1340 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203254:	a3afd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203258:	86d6                	mv	a3,s5
ffffffffc020325a:	00004617          	auipc	a2,0x4
ffffffffc020325e:	99e60613          	addi	a2,a2,-1634 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc0203262:	26800593          	li	a1,616
ffffffffc0203266:	00004517          	auipc	a0,0x4
ffffffffc020326a:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020326e:	a20fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203272:	00004617          	auipc	a2,0x4
ffffffffc0203276:	98660613          	addi	a2,a2,-1658 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc020327a:	26700593          	li	a1,615
ffffffffc020327e:	00004517          	auipc	a0,0x4
ffffffffc0203282:	a9250513          	addi	a0,a0,-1390 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203286:	a08fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020328a:	00004697          	auipc	a3,0x4
ffffffffc020328e:	c9668693          	addi	a3,a3,-874 # ffffffffc0206f20 <default_pmm_manager+0x360>
ffffffffc0203292:	00003617          	auipc	a2,0x3
ffffffffc0203296:	2be60613          	addi	a2,a2,702 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020329a:	26500593          	li	a1,613
ffffffffc020329e:	00004517          	auipc	a0,0x4
ffffffffc02032a2:	a7250513          	addi	a0,a0,-1422 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02032a6:	9e8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02032aa:	00004697          	auipc	a3,0x4
ffffffffc02032ae:	c5e68693          	addi	a3,a3,-930 # ffffffffc0206f08 <default_pmm_manager+0x348>
ffffffffc02032b2:	00003617          	auipc	a2,0x3
ffffffffc02032b6:	29e60613          	addi	a2,a2,670 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02032ba:	26400593          	li	a1,612
ffffffffc02032be:	00004517          	auipc	a0,0x4
ffffffffc02032c2:	a5250513          	addi	a0,a0,-1454 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02032c6:	9c8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02032ca:	00004697          	auipc	a3,0x4
ffffffffc02032ce:	fee68693          	addi	a3,a3,-18 # ffffffffc02072b8 <default_pmm_manager+0x6f8>
ffffffffc02032d2:	00003617          	auipc	a2,0x3
ffffffffc02032d6:	27e60613          	addi	a2,a2,638 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02032da:	2ab00593          	li	a1,683
ffffffffc02032de:	00004517          	auipc	a0,0x4
ffffffffc02032e2:	a3250513          	addi	a0,a0,-1486 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02032e6:	9a8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02032ea:	00004697          	auipc	a3,0x4
ffffffffc02032ee:	f9668693          	addi	a3,a3,-106 # ffffffffc0207280 <default_pmm_manager+0x6c0>
ffffffffc02032f2:	00003617          	auipc	a2,0x3
ffffffffc02032f6:	25e60613          	addi	a2,a2,606 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02032fa:	2a800593          	li	a1,680
ffffffffc02032fe:	00004517          	auipc	a0,0x4
ffffffffc0203302:	a1250513          	addi	a0,a0,-1518 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203306:	988fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc020330a:	00004697          	auipc	a3,0x4
ffffffffc020330e:	f4668693          	addi	a3,a3,-186 # ffffffffc0207250 <default_pmm_manager+0x690>
ffffffffc0203312:	00003617          	auipc	a2,0x3
ffffffffc0203316:	23e60613          	addi	a2,a2,574 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020331a:	2a400593          	li	a1,676
ffffffffc020331e:	00004517          	auipc	a0,0x4
ffffffffc0203322:	9f250513          	addi	a0,a0,-1550 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203326:	968fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020332a:	00004697          	auipc	a3,0x4
ffffffffc020332e:	ede68693          	addi	a3,a3,-290 # ffffffffc0207208 <default_pmm_manager+0x648>
ffffffffc0203332:	00003617          	auipc	a2,0x3
ffffffffc0203336:	21e60613          	addi	a2,a2,542 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020333a:	2a300593          	li	a1,675
ffffffffc020333e:	00004517          	auipc	a0,0x4
ffffffffc0203342:	9d250513          	addi	a0,a0,-1582 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203346:	948fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020334a:	00004617          	auipc	a2,0x4
ffffffffc020334e:	95660613          	addi	a2,a2,-1706 # ffffffffc0206ca0 <default_pmm_manager+0xe0>
ffffffffc0203352:	0c900593          	li	a1,201
ffffffffc0203356:	00004517          	auipc	a0,0x4
ffffffffc020335a:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020335e:	930fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203362:	00004617          	auipc	a2,0x4
ffffffffc0203366:	93e60613          	addi	a2,a2,-1730 # ffffffffc0206ca0 <default_pmm_manager+0xe0>
ffffffffc020336a:	08100593          	li	a1,129
ffffffffc020336e:	00004517          	auipc	a0,0x4
ffffffffc0203372:	9a250513          	addi	a0,a0,-1630 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203376:	918fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020337a:	00004697          	auipc	a3,0x4
ffffffffc020337e:	b5e68693          	addi	a3,a3,-1186 # ffffffffc0206ed8 <default_pmm_manager+0x318>
ffffffffc0203382:	00003617          	auipc	a2,0x3
ffffffffc0203386:	1ce60613          	addi	a2,a2,462 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020338a:	26300593          	li	a1,611
ffffffffc020338e:	00004517          	auipc	a0,0x4
ffffffffc0203392:	98250513          	addi	a0,a0,-1662 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203396:	8f8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020339a:	00004697          	auipc	a3,0x4
ffffffffc020339e:	b0e68693          	addi	a3,a3,-1266 # ffffffffc0206ea8 <default_pmm_manager+0x2e8>
ffffffffc02033a2:	00003617          	auipc	a2,0x3
ffffffffc02033a6:	1ae60613          	addi	a2,a2,430 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02033aa:	26000593          	li	a1,608
ffffffffc02033ae:	00004517          	auipc	a0,0x4
ffffffffc02033b2:	96250513          	addi	a0,a0,-1694 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02033b6:	8d8fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02033ba <copy_range>:
{
ffffffffc02033ba:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033bc:	00d667b3          	or	a5,a2,a3
{
ffffffffc02033c0:	f486                	sd	ra,104(sp)
ffffffffc02033c2:	f0a2                	sd	s0,96(sp)
ffffffffc02033c4:	eca6                	sd	s1,88(sp)
ffffffffc02033c6:	e8ca                	sd	s2,80(sp)
ffffffffc02033c8:	e4ce                	sd	s3,72(sp)
ffffffffc02033ca:	e0d2                	sd	s4,64(sp)
ffffffffc02033cc:	fc56                	sd	s5,56(sp)
ffffffffc02033ce:	f85a                	sd	s6,48(sp)
ffffffffc02033d0:	f45e                	sd	s7,40(sp)
ffffffffc02033d2:	f062                	sd	s8,32(sp)
ffffffffc02033d4:	ec66                	sd	s9,24(sp)
ffffffffc02033d6:	e86a                	sd	s10,16(sp)
ffffffffc02033d8:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033da:	17d2                	slli	a5,a5,0x34
ffffffffc02033dc:	20079f63          	bnez	a5,ffffffffc02035fa <copy_range+0x240>
    assert(USER_ACCESS(start, end));
ffffffffc02033e0:	002007b7          	lui	a5,0x200
ffffffffc02033e4:	8432                	mv	s0,a2
ffffffffc02033e6:	1af66263          	bltu	a2,a5,ffffffffc020358a <copy_range+0x1d0>
ffffffffc02033ea:	8936                	mv	s2,a3
ffffffffc02033ec:	18d67f63          	bgeu	a2,a3,ffffffffc020358a <copy_range+0x1d0>
ffffffffc02033f0:	4785                	li	a5,1
ffffffffc02033f2:	07fe                	slli	a5,a5,0x1f
ffffffffc02033f4:	18d7eb63          	bltu	a5,a3,ffffffffc020358a <copy_range+0x1d0>
ffffffffc02033f8:	5b7d                	li	s6,-1
ffffffffc02033fa:	8aaa                	mv	s5,a0
ffffffffc02033fc:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc02033fe:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc0203400:	000d7c17          	auipc	s8,0xd7
ffffffffc0203404:	1b8c0c13          	addi	s8,s8,440 # ffffffffc02da5b8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203408:	000d7b97          	auipc	s7,0xd7
ffffffffc020340c:	1b8b8b93          	addi	s7,s7,440 # ffffffffc02da5c0 <pages>
    return KADDR(page2pa(page));
ffffffffc0203410:	00cb5b13          	srli	s6,s6,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc0203414:	000d7c97          	auipc	s9,0xd7
ffffffffc0203418:	1b4c8c93          	addi	s9,s9,436 # ffffffffc02da5c8 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020341c:	4601                	li	a2,0
ffffffffc020341e:	85a2                	mv	a1,s0
ffffffffc0203420:	854e                	mv	a0,s3
ffffffffc0203422:	b73fe0ef          	jal	ra,ffffffffc0201f94 <get_pte>
ffffffffc0203426:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0203428:	0e050c63          	beqz	a0,ffffffffc0203520 <copy_range+0x166>
        if (*ptep & PTE_V)
ffffffffc020342c:	611c                	ld	a5,0(a0)
ffffffffc020342e:	8b85                	andi	a5,a5,1
ffffffffc0203430:	e785                	bnez	a5,ffffffffc0203458 <copy_range+0x9e>
        start += PGSIZE;
ffffffffc0203432:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0203434:	ff2464e3          	bltu	s0,s2,ffffffffc020341c <copy_range+0x62>
    return 0;
ffffffffc0203438:	4501                	li	a0,0
}
ffffffffc020343a:	70a6                	ld	ra,104(sp)
ffffffffc020343c:	7406                	ld	s0,96(sp)
ffffffffc020343e:	64e6                	ld	s1,88(sp)
ffffffffc0203440:	6946                	ld	s2,80(sp)
ffffffffc0203442:	69a6                	ld	s3,72(sp)
ffffffffc0203444:	6a06                	ld	s4,64(sp)
ffffffffc0203446:	7ae2                	ld	s5,56(sp)
ffffffffc0203448:	7b42                	ld	s6,48(sp)
ffffffffc020344a:	7ba2                	ld	s7,40(sp)
ffffffffc020344c:	7c02                	ld	s8,32(sp)
ffffffffc020344e:	6ce2                	ld	s9,24(sp)
ffffffffc0203450:	6d42                	ld	s10,16(sp)
ffffffffc0203452:	6da2                	ld	s11,8(sp)
ffffffffc0203454:	6165                	addi	sp,sp,112
ffffffffc0203456:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203458:	4605                	li	a2,1
ffffffffc020345a:	85a2                	mv	a1,s0
ffffffffc020345c:	8556                	mv	a0,s5
ffffffffc020345e:	b37fe0ef          	jal	ra,ffffffffc0201f94 <get_pte>
ffffffffc0203462:	c56d                	beqz	a0,ffffffffc020354c <copy_range+0x192>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203464:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203466:	0017f713          	andi	a4,a5,1
ffffffffc020346a:	01f7f493          	andi	s1,a5,31
ffffffffc020346e:	16070a63          	beqz	a4,ffffffffc02035e2 <copy_range+0x228>
    if (PPN(pa) >= npage)
ffffffffc0203472:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203476:	078a                	slli	a5,a5,0x2
ffffffffc0203478:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020347c:	14d77763          	bgeu	a4,a3,ffffffffc02035ca <copy_range+0x210>
    return &pages[PPN(pa) - nbase];
ffffffffc0203480:	000bb783          	ld	a5,0(s7)
ffffffffc0203484:	fff806b7          	lui	a3,0xfff80
ffffffffc0203488:	9736                	add	a4,a4,a3
ffffffffc020348a:	071a                	slli	a4,a4,0x6
ffffffffc020348c:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203490:	10002773          	csrr	a4,sstatus
ffffffffc0203494:	8b09                	andi	a4,a4,2
ffffffffc0203496:	e345                	bnez	a4,ffffffffc0203536 <copy_range+0x17c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203498:	000cb703          	ld	a4,0(s9)
ffffffffc020349c:	4505                	li	a0,1
ffffffffc020349e:	6f18                	ld	a4,24(a4)
ffffffffc02034a0:	9702                	jalr	a4
ffffffffc02034a2:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc02034a4:	0c0d8363          	beqz	s11,ffffffffc020356a <copy_range+0x1b0>
            assert(npage != NULL);
ffffffffc02034a8:	100d0163          	beqz	s10,ffffffffc02035aa <copy_range+0x1f0>
    return page - pages + nbase;
ffffffffc02034ac:	000bb703          	ld	a4,0(s7)
ffffffffc02034b0:	000805b7          	lui	a1,0x80
    return KADDR(page2pa(page));
ffffffffc02034b4:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02034b8:	40ed86b3          	sub	a3,s11,a4
ffffffffc02034bc:	8699                	srai	a3,a3,0x6
ffffffffc02034be:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc02034c0:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02034c4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02034c6:	08c7f663          	bgeu	a5,a2,ffffffffc0203552 <copy_range+0x198>
    return page - pages + nbase;
ffffffffc02034ca:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc02034ce:	000d7717          	auipc	a4,0xd7
ffffffffc02034d2:	10270713          	addi	a4,a4,258 # ffffffffc02da5d0 <va_pa_offset>
ffffffffc02034d6:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc02034d8:	8799                	srai	a5,a5,0x6
ffffffffc02034da:	97ae                	add	a5,a5,a1
    return KADDR(page2pa(page));
ffffffffc02034dc:	0167f733          	and	a4,a5,s6
ffffffffc02034e0:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02034e4:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02034e6:	06c77563          	bgeu	a4,a2,ffffffffc0203550 <copy_range+0x196>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02034ea:	6605                	lui	a2,0x1
ffffffffc02034ec:	953e                	add	a0,a0,a5
ffffffffc02034ee:	7e6020ef          	jal	ra,ffffffffc0205cd4 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc02034f2:	86a6                	mv	a3,s1
ffffffffc02034f4:	8622                	mv	a2,s0
ffffffffc02034f6:	85ea                	mv	a1,s10
ffffffffc02034f8:	8556                	mv	a0,s5
ffffffffc02034fa:	98aff0ef          	jal	ra,ffffffffc0202684 <page_insert>
            assert(ret == 0);
ffffffffc02034fe:	d915                	beqz	a0,ffffffffc0203432 <copy_range+0x78>
ffffffffc0203500:	00004697          	auipc	a3,0x4
ffffffffc0203504:	e2068693          	addi	a3,a3,-480 # ffffffffc0207320 <default_pmm_manager+0x760>
ffffffffc0203508:	00003617          	auipc	a2,0x3
ffffffffc020350c:	04860613          	addi	a2,a2,72 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203510:	1b200593          	li	a1,434
ffffffffc0203514:	00003517          	auipc	a0,0x3
ffffffffc0203518:	7fc50513          	addi	a0,a0,2044 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc020351c:	f73fc0ef          	jal	ra,ffffffffc020048e <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203520:	00200637          	lui	a2,0x200
ffffffffc0203524:	9432                	add	s0,s0,a2
ffffffffc0203526:	ffe00637          	lui	a2,0xffe00
ffffffffc020352a:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc020352c:	f00406e3          	beqz	s0,ffffffffc0203438 <copy_range+0x7e>
ffffffffc0203530:	ef2466e3          	bltu	s0,s2,ffffffffc020341c <copy_range+0x62>
ffffffffc0203534:	b711                	j	ffffffffc0203438 <copy_range+0x7e>
        intr_disable();
ffffffffc0203536:	c7efd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020353a:	000cb703          	ld	a4,0(s9)
ffffffffc020353e:	4505                	li	a0,1
ffffffffc0203540:	6f18                	ld	a4,24(a4)
ffffffffc0203542:	9702                	jalr	a4
ffffffffc0203544:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc0203546:	c68fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020354a:	bfa9                	j	ffffffffc02034a4 <copy_range+0xea>
                return -E_NO_MEM;
ffffffffc020354c:	5571                	li	a0,-4
ffffffffc020354e:	b5f5                	j	ffffffffc020343a <copy_range+0x80>
ffffffffc0203550:	86be                	mv	a3,a5
ffffffffc0203552:	00003617          	auipc	a2,0x3
ffffffffc0203556:	6a660613          	addi	a2,a2,1702 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc020355a:	07200593          	li	a1,114
ffffffffc020355e:	00003517          	auipc	a0,0x3
ffffffffc0203562:	6c250513          	addi	a0,a0,1730 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc0203566:	f29fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc020356a:	00004697          	auipc	a3,0x4
ffffffffc020356e:	d9668693          	addi	a3,a3,-618 # ffffffffc0207300 <default_pmm_manager+0x740>
ffffffffc0203572:	00003617          	auipc	a2,0x3
ffffffffc0203576:	fde60613          	addi	a2,a2,-34 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020357a:	19400593          	li	a1,404
ffffffffc020357e:	00003517          	auipc	a0,0x3
ffffffffc0203582:	79250513          	addi	a0,a0,1938 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203586:	f09fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020358a:	00003697          	auipc	a3,0x3
ffffffffc020358e:	7c668693          	addi	a3,a3,1990 # ffffffffc0206d50 <default_pmm_manager+0x190>
ffffffffc0203592:	00003617          	auipc	a2,0x3
ffffffffc0203596:	fbe60613          	addi	a2,a2,-66 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020359a:	17c00593          	li	a1,380
ffffffffc020359e:	00003517          	auipc	a0,0x3
ffffffffc02035a2:	77250513          	addi	a0,a0,1906 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02035a6:	ee9fc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(npage != NULL);
ffffffffc02035aa:	00004697          	auipc	a3,0x4
ffffffffc02035ae:	d6668693          	addi	a3,a3,-666 # ffffffffc0207310 <default_pmm_manager+0x750>
ffffffffc02035b2:	00003617          	auipc	a2,0x3
ffffffffc02035b6:	f9e60613          	addi	a2,a2,-98 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02035ba:	19500593          	li	a1,405
ffffffffc02035be:	00003517          	auipc	a0,0x3
ffffffffc02035c2:	75250513          	addi	a0,a0,1874 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02035c6:	ec9fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02035ca:	00003617          	auipc	a2,0x3
ffffffffc02035ce:	6fe60613          	addi	a2,a2,1790 # ffffffffc0206cc8 <default_pmm_manager+0x108>
ffffffffc02035d2:	06a00593          	li	a1,106
ffffffffc02035d6:	00003517          	auipc	a0,0x3
ffffffffc02035da:	64a50513          	addi	a0,a0,1610 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc02035de:	eb1fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02035e2:	00003617          	auipc	a2,0x3
ffffffffc02035e6:	70660613          	addi	a2,a2,1798 # ffffffffc0206ce8 <default_pmm_manager+0x128>
ffffffffc02035ea:	08000593          	li	a1,128
ffffffffc02035ee:	00003517          	auipc	a0,0x3
ffffffffc02035f2:	63250513          	addi	a0,a0,1586 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc02035f6:	e99fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02035fa:	00003697          	auipc	a3,0x3
ffffffffc02035fe:	72668693          	addi	a3,a3,1830 # ffffffffc0206d20 <default_pmm_manager+0x160>
ffffffffc0203602:	00003617          	auipc	a2,0x3
ffffffffc0203606:	f4e60613          	addi	a2,a2,-178 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020360a:	17b00593          	li	a1,379
ffffffffc020360e:	00003517          	auipc	a0,0x3
ffffffffc0203612:	70250513          	addi	a0,a0,1794 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203616:	e79fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020361a <copy_range_cow>:
{
ffffffffc020361a:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020361c:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203620:	ec86                	sd	ra,88(sp)
ffffffffc0203622:	e8a2                	sd	s0,80(sp)
ffffffffc0203624:	e4a6                	sd	s1,72(sp)
ffffffffc0203626:	e0ca                	sd	s2,64(sp)
ffffffffc0203628:	fc4e                	sd	s3,56(sp)
ffffffffc020362a:	f852                	sd	s4,48(sp)
ffffffffc020362c:	f456                	sd	s5,40(sp)
ffffffffc020362e:	f05a                	sd	s6,32(sp)
ffffffffc0203630:	ec5e                	sd	s7,24(sp)
ffffffffc0203632:	e862                	sd	s8,16(sp)
ffffffffc0203634:	e466                	sd	s9,8(sp)
ffffffffc0203636:	e06a                	sd	s10,0(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203638:	17d2                	slli	a5,a5,0x34
ffffffffc020363a:	16079a63          	bnez	a5,ffffffffc02037ae <copy_range_cow+0x194>
    assert(USER_ACCESS(start, end));
ffffffffc020363e:	002007b7          	lui	a5,0x200
ffffffffc0203642:	8d32                	mv	s10,a2
ffffffffc0203644:	0ef66963          	bltu	a2,a5,ffffffffc0203736 <copy_range_cow+0x11c>
ffffffffc0203648:	84b6                	mv	s1,a3
ffffffffc020364a:	0ed67663          	bgeu	a2,a3,ffffffffc0203736 <copy_range_cow+0x11c>
ffffffffc020364e:	4785                	li	a5,1
ffffffffc0203650:	07fe                	slli	a5,a5,0x1f
ffffffffc0203652:	0ed7e263          	bltu	a5,a3,ffffffffc0203736 <copy_range_cow+0x11c>
ffffffffc0203656:	8a2a                	mv	s4,a0
ffffffffc0203658:	892e                	mv	s2,a1
        start += PGSIZE;
ffffffffc020365a:	6985                	lui	s3,0x1
    if (PPN(pa) >= npage)
ffffffffc020365c:	000d7b97          	auipc	s7,0xd7
ffffffffc0203660:	f5cb8b93          	addi	s7,s7,-164 # ffffffffc02da5b8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203664:	000d7b17          	auipc	s6,0xd7
ffffffffc0203668:	f5cb0b13          	addi	s6,s6,-164 # ffffffffc02da5c0 <pages>
ffffffffc020366c:	fff80ab7          	lui	s5,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203670:	00200cb7          	lui	s9,0x200
ffffffffc0203674:	ffe00c37          	lui	s8,0xffe00
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203678:	4601                	li	a2,0
ffffffffc020367a:	85ea                	mv	a1,s10
ffffffffc020367c:	854a                	mv	a0,s2
ffffffffc020367e:	917fe0ef          	jal	ra,ffffffffc0201f94 <get_pte>
ffffffffc0203682:	842a                	mv	s0,a0
        if (ptep == NULL)
ffffffffc0203684:	c159                	beqz	a0,ffffffffc020370a <copy_range_cow+0xf0>
        if (*ptep & PTE_V)
ffffffffc0203686:	611c                	ld	a5,0(a0)
ffffffffc0203688:	8b85                	andi	a5,a5,1
ffffffffc020368a:	e39d                	bnez	a5,ffffffffc02036b0 <copy_range_cow+0x96>
        start += PGSIZE;
ffffffffc020368c:	9d4e                	add	s10,s10,s3
    } while (start != 0 && start < end);
ffffffffc020368e:	fe9d65e3          	bltu	s10,s1,ffffffffc0203678 <copy_range_cow+0x5e>
    return 0;
ffffffffc0203692:	4501                	li	a0,0
}
ffffffffc0203694:	60e6                	ld	ra,88(sp)
ffffffffc0203696:	6446                	ld	s0,80(sp)
ffffffffc0203698:	64a6                	ld	s1,72(sp)
ffffffffc020369a:	6906                	ld	s2,64(sp)
ffffffffc020369c:	79e2                	ld	s3,56(sp)
ffffffffc020369e:	7a42                	ld	s4,48(sp)
ffffffffc02036a0:	7aa2                	ld	s5,40(sp)
ffffffffc02036a2:	7b02                	ld	s6,32(sp)
ffffffffc02036a4:	6be2                	ld	s7,24(sp)
ffffffffc02036a6:	6c42                	ld	s8,16(sp)
ffffffffc02036a8:	6ca2                	ld	s9,8(sp)
ffffffffc02036aa:	6d02                	ld	s10,0(sp)
ffffffffc02036ac:	6125                	addi	sp,sp,96
ffffffffc02036ae:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02036b0:	4605                	li	a2,1
ffffffffc02036b2:	85ea                	mv	a1,s10
ffffffffc02036b4:	8552                	mv	a0,s4
ffffffffc02036b6:	8dffe0ef          	jal	ra,ffffffffc0201f94 <get_pte>
ffffffffc02036ba:	c125                	beqz	a0,ffffffffc020371a <copy_range_cow+0x100>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02036bc:	601c                	ld	a5,0(s0)
    if (!(pte & PTE_V))
ffffffffc02036be:	0017f713          	andi	a4,a5,1
ffffffffc02036c2:	0007869b          	sext.w	a3,a5
ffffffffc02036c6:	cf21                	beqz	a4,ffffffffc020371e <copy_range_cow+0x104>
    if (PPN(pa) >= npage)
ffffffffc02036c8:	000bb703          	ld	a4,0(s7)
    return pa2page(PTE_ADDR(pte));
ffffffffc02036cc:	078a                	slli	a5,a5,0x2
ffffffffc02036ce:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02036d0:	0ce7f363          	bgeu	a5,a4,ffffffffc0203796 <copy_range_cow+0x17c>
    return &pages[PPN(pa) - nbase];
ffffffffc02036d4:	000b3583          	ld	a1,0(s6)
ffffffffc02036d8:	97d6                	add	a5,a5,s5
ffffffffc02036da:	079a                	slli	a5,a5,0x6
ffffffffc02036dc:	95be                	add	a1,a1,a5
            assert(page != NULL);
ffffffffc02036de:	cdc1                	beqz	a1,ffffffffc0203776 <copy_range_cow+0x15c>
    page->ref += 1;
ffffffffc02036e0:	419c                	lw	a5,0(a1)
            uint32_t cow_perm = (perm & ~PTE_W) | PTE_COW;
ffffffffc02036e2:	8aed                	andi	a3,a3,27
            int ret = page_insert(to, page, start, cow_perm);
ffffffffc02036e4:	1006e693          	ori	a3,a3,256
ffffffffc02036e8:	2785                	addiw	a5,a5,1
ffffffffc02036ea:	c19c                	sw	a5,0(a1)
ffffffffc02036ec:	866a                	mv	a2,s10
ffffffffc02036ee:	8552                	mv	a0,s4
ffffffffc02036f0:	f95fe0ef          	jal	ra,ffffffffc0202684 <page_insert>
            assert(ret == 0);
ffffffffc02036f4:	e12d                	bnez	a0,ffffffffc0203756 <copy_range_cow+0x13c>
            *ptep = (*ptep & ~PTE_W) | PTE_COW;
ffffffffc02036f6:	601c                	ld	a5,0(s0)
ffffffffc02036f8:	efb7f793          	andi	a5,a5,-261
ffffffffc02036fc:	1007e793          	ori	a5,a5,256
ffffffffc0203700:	e01c                	sd	a5,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203702:	120d0073          	sfence.vma	s10
        start += PGSIZE;
ffffffffc0203706:	9d4e                	add	s10,s10,s3
    } while (start != 0 && start < end);
ffffffffc0203708:	b759                	j	ffffffffc020368e <copy_range_cow+0x74>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020370a:	9d66                	add	s10,s10,s9
ffffffffc020370c:	018d7d33          	and	s10,s10,s8
    } while (start != 0 && start < end);
ffffffffc0203710:	f80d01e3          	beqz	s10,ffffffffc0203692 <copy_range_cow+0x78>
ffffffffc0203714:	f69d62e3          	bltu	s10,s1,ffffffffc0203678 <copy_range_cow+0x5e>
ffffffffc0203718:	bfad                	j	ffffffffc0203692 <copy_range_cow+0x78>
                return -E_NO_MEM;
ffffffffc020371a:	5571                	li	a0,-4
ffffffffc020371c:	bfa5                	j	ffffffffc0203694 <copy_range_cow+0x7a>
        panic("pte2page called with invalid pte");
ffffffffc020371e:	00003617          	auipc	a2,0x3
ffffffffc0203722:	5ca60613          	addi	a2,a2,1482 # ffffffffc0206ce8 <default_pmm_manager+0x128>
ffffffffc0203726:	08000593          	li	a1,128
ffffffffc020372a:	00003517          	auipc	a0,0x3
ffffffffc020372e:	4f650513          	addi	a0,a0,1270 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc0203732:	d5dfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203736:	00003697          	auipc	a3,0x3
ffffffffc020373a:	61a68693          	addi	a3,a3,1562 # ffffffffc0206d50 <default_pmm_manager+0x190>
ffffffffc020373e:	00003617          	auipc	a2,0x3
ffffffffc0203742:	e1260613          	addi	a2,a2,-494 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203746:	1be00593          	li	a1,446
ffffffffc020374a:	00003517          	auipc	a0,0x3
ffffffffc020374e:	5c650513          	addi	a0,a0,1478 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203752:	d3dfc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(ret == 0);
ffffffffc0203756:	00004697          	auipc	a3,0x4
ffffffffc020375a:	bca68693          	addi	a3,a3,-1078 # ffffffffc0207320 <default_pmm_manager+0x760>
ffffffffc020375e:	00003617          	auipc	a2,0x3
ffffffffc0203762:	df260613          	addi	a2,a2,-526 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203766:	1ea00593          	li	a1,490
ffffffffc020376a:	00003517          	auipc	a0,0x3
ffffffffc020376e:	5a650513          	addi	a0,a0,1446 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203772:	d1dfc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc0203776:	00004697          	auipc	a3,0x4
ffffffffc020377a:	b8a68693          	addi	a3,a3,-1142 # ffffffffc0207300 <default_pmm_manager+0x740>
ffffffffc020377e:	00003617          	auipc	a2,0x3
ffffffffc0203782:	dd260613          	addi	a2,a2,-558 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203786:	1d900593          	li	a1,473
ffffffffc020378a:	00003517          	auipc	a0,0x3
ffffffffc020378e:	58650513          	addi	a0,a0,1414 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203792:	cfdfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203796:	00003617          	auipc	a2,0x3
ffffffffc020379a:	53260613          	addi	a2,a2,1330 # ffffffffc0206cc8 <default_pmm_manager+0x108>
ffffffffc020379e:	06a00593          	li	a1,106
ffffffffc02037a2:	00003517          	auipc	a0,0x3
ffffffffc02037a6:	47e50513          	addi	a0,a0,1150 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc02037aa:	ce5fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02037ae:	00003697          	auipc	a3,0x3
ffffffffc02037b2:	57268693          	addi	a3,a3,1394 # ffffffffc0206d20 <default_pmm_manager+0x160>
ffffffffc02037b6:	00003617          	auipc	a2,0x3
ffffffffc02037ba:	d9a60613          	addi	a2,a2,-614 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02037be:	1bd00593          	li	a1,445
ffffffffc02037c2:	00003517          	auipc	a0,0x3
ffffffffc02037c6:	54e50513          	addi	a0,a0,1358 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc02037ca:	cc5fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02037ce <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02037ce:	12058073          	sfence.vma	a1
}
ffffffffc02037d2:	8082                	ret

ffffffffc02037d4 <pgdir_alloc_page>:
{
ffffffffc02037d4:	7179                	addi	sp,sp,-48
ffffffffc02037d6:	ec26                	sd	s1,24(sp)
ffffffffc02037d8:	e84a                	sd	s2,16(sp)
ffffffffc02037da:	e052                	sd	s4,0(sp)
ffffffffc02037dc:	f406                	sd	ra,40(sp)
ffffffffc02037de:	f022                	sd	s0,32(sp)
ffffffffc02037e0:	e44e                	sd	s3,8(sp)
ffffffffc02037e2:	8a2a                	mv	s4,a0
ffffffffc02037e4:	84ae                	mv	s1,a1
ffffffffc02037e6:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02037e8:	100027f3          	csrr	a5,sstatus
ffffffffc02037ec:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02037ee:	000d7997          	auipc	s3,0xd7
ffffffffc02037f2:	dda98993          	addi	s3,s3,-550 # ffffffffc02da5c8 <pmm_manager>
ffffffffc02037f6:	ef8d                	bnez	a5,ffffffffc0203830 <pgdir_alloc_page+0x5c>
ffffffffc02037f8:	0009b783          	ld	a5,0(s3)
ffffffffc02037fc:	4505                	li	a0,1
ffffffffc02037fe:	6f9c                	ld	a5,24(a5)
ffffffffc0203800:	9782                	jalr	a5
ffffffffc0203802:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0203804:	cc09                	beqz	s0,ffffffffc020381e <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203806:	86ca                	mv	a3,s2
ffffffffc0203808:	8626                	mv	a2,s1
ffffffffc020380a:	85a2                	mv	a1,s0
ffffffffc020380c:	8552                	mv	a0,s4
ffffffffc020380e:	e77fe0ef          	jal	ra,ffffffffc0202684 <page_insert>
ffffffffc0203812:	e915                	bnez	a0,ffffffffc0203846 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203814:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0203816:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc0203818:	4785                	li	a5,1
ffffffffc020381a:	04f71e63          	bne	a4,a5,ffffffffc0203876 <pgdir_alloc_page+0xa2>
}
ffffffffc020381e:	70a2                	ld	ra,40(sp)
ffffffffc0203820:	8522                	mv	a0,s0
ffffffffc0203822:	7402                	ld	s0,32(sp)
ffffffffc0203824:	64e2                	ld	s1,24(sp)
ffffffffc0203826:	6942                	ld	s2,16(sp)
ffffffffc0203828:	69a2                	ld	s3,8(sp)
ffffffffc020382a:	6a02                	ld	s4,0(sp)
ffffffffc020382c:	6145                	addi	sp,sp,48
ffffffffc020382e:	8082                	ret
        intr_disable();
ffffffffc0203830:	984fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203834:	0009b783          	ld	a5,0(s3)
ffffffffc0203838:	4505                	li	a0,1
ffffffffc020383a:	6f9c                	ld	a5,24(a5)
ffffffffc020383c:	9782                	jalr	a5
ffffffffc020383e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203840:	96efd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203844:	b7c1                	j	ffffffffc0203804 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203846:	100027f3          	csrr	a5,sstatus
ffffffffc020384a:	8b89                	andi	a5,a5,2
ffffffffc020384c:	eb89                	bnez	a5,ffffffffc020385e <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc020384e:	0009b783          	ld	a5,0(s3)
ffffffffc0203852:	8522                	mv	a0,s0
ffffffffc0203854:	4585                	li	a1,1
ffffffffc0203856:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203858:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020385a:	9782                	jalr	a5
    if (flag)
ffffffffc020385c:	b7c9                	j	ffffffffc020381e <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc020385e:	956fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203862:	0009b783          	ld	a5,0(s3)
ffffffffc0203866:	8522                	mv	a0,s0
ffffffffc0203868:	4585                	li	a1,1
ffffffffc020386a:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020386c:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020386e:	9782                	jalr	a5
        intr_enable();
ffffffffc0203870:	93efd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203874:	b76d                	j	ffffffffc020381e <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203876:	00004697          	auipc	a3,0x4
ffffffffc020387a:	aba68693          	addi	a3,a3,-1350 # ffffffffc0207330 <default_pmm_manager+0x770>
ffffffffc020387e:	00003617          	auipc	a2,0x3
ffffffffc0203882:	cd260613          	addi	a2,a2,-814 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203886:	24100593          	li	a1,577
ffffffffc020388a:	00003517          	auipc	a0,0x3
ffffffffc020388e:	48650513          	addi	a0,a0,1158 # ffffffffc0206d10 <default_pmm_manager+0x150>
ffffffffc0203892:	bfdfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203896 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203896:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203898:	00004697          	auipc	a3,0x4
ffffffffc020389c:	ab068693          	addi	a3,a3,-1360 # ffffffffc0207348 <default_pmm_manager+0x788>
ffffffffc02038a0:	00003617          	auipc	a2,0x3
ffffffffc02038a4:	cb060613          	addi	a2,a2,-848 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02038a8:	07400593          	li	a1,116
ffffffffc02038ac:	00004517          	auipc	a0,0x4
ffffffffc02038b0:	abc50513          	addi	a0,a0,-1348 # ffffffffc0207368 <default_pmm_manager+0x7a8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02038b4:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02038b6:	bd9fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02038ba <mm_create>:
{
ffffffffc02038ba:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038bc:	04000513          	li	a0,64
{
ffffffffc02038c0:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038c2:	c3cfe0ef          	jal	ra,ffffffffc0201cfe <kmalloc>
    if (mm != NULL)
ffffffffc02038c6:	cd19                	beqz	a0,ffffffffc02038e4 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02038c8:	e508                	sd	a0,8(a0)
ffffffffc02038ca:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02038cc:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02038d0:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02038d4:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02038d8:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02038dc:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02038e0:	02053c23          	sd	zero,56(a0)
}
ffffffffc02038e4:	60a2                	ld	ra,8(sp)
ffffffffc02038e6:	0141                	addi	sp,sp,16
ffffffffc02038e8:	8082                	ret

ffffffffc02038ea <find_vma>:
{
ffffffffc02038ea:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02038ec:	c505                	beqz	a0,ffffffffc0203914 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02038ee:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02038f0:	c501                	beqz	a0,ffffffffc02038f8 <find_vma+0xe>
ffffffffc02038f2:	651c                	ld	a5,8(a0)
ffffffffc02038f4:	02f5f263          	bgeu	a1,a5,ffffffffc0203918 <find_vma+0x2e>
    return listelm->next;
ffffffffc02038f8:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc02038fa:	00f68d63          	beq	a3,a5,ffffffffc0203914 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02038fe:	fe87b703          	ld	a4,-24(a5) # 1fffe8 <_binary_obj___user_cowtest_out_size+0x1f02f8>
ffffffffc0203902:	00e5e663          	bltu	a1,a4,ffffffffc020390e <find_vma+0x24>
ffffffffc0203906:	ff07b703          	ld	a4,-16(a5)
ffffffffc020390a:	00e5ec63          	bltu	a1,a4,ffffffffc0203922 <find_vma+0x38>
ffffffffc020390e:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203910:	fef697e3          	bne	a3,a5,ffffffffc02038fe <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203914:	4501                	li	a0,0
}
ffffffffc0203916:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203918:	691c                	ld	a5,16(a0)
ffffffffc020391a:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02038f8 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc020391e:	ea88                	sd	a0,16(a3)
ffffffffc0203920:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203922:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203926:	ea88                	sd	a0,16(a3)
ffffffffc0203928:	8082                	ret

ffffffffc020392a <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc020392a:	6590                	ld	a2,8(a1)
ffffffffc020392c:	0105b803          	ld	a6,16(a1) # 80010 <_binary_obj___user_cowtest_out_size+0x70320>
{
ffffffffc0203930:	1141                	addi	sp,sp,-16
ffffffffc0203932:	e406                	sd	ra,8(sp)
ffffffffc0203934:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203936:	01066763          	bltu	a2,a6,ffffffffc0203944 <insert_vma_struct+0x1a>
ffffffffc020393a:	a085                	j	ffffffffc020399a <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020393c:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203940:	04e66863          	bltu	a2,a4,ffffffffc0203990 <insert_vma_struct+0x66>
ffffffffc0203944:	86be                	mv	a3,a5
ffffffffc0203946:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203948:	fef51ae3          	bne	a0,a5,ffffffffc020393c <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020394c:	02a68463          	beq	a3,a0,ffffffffc0203974 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203950:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203954:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203958:	08e8f163          	bgeu	a7,a4,ffffffffc02039da <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020395c:	04e66f63          	bltu	a2,a4,ffffffffc02039ba <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203960:	00f50a63          	beq	a0,a5,ffffffffc0203974 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203964:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203968:	05076963          	bltu	a4,a6,ffffffffc02039ba <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020396c:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203970:	02c77363          	bgeu	a4,a2,ffffffffc0203996 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203974:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203976:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203978:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020397c:	e390                	sd	a2,0(a5)
ffffffffc020397e:	e690                	sd	a2,8(a3)
}
ffffffffc0203980:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203982:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203984:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203986:	0017079b          	addiw	a5,a4,1
ffffffffc020398a:	d11c                	sw	a5,32(a0)
}
ffffffffc020398c:	0141                	addi	sp,sp,16
ffffffffc020398e:	8082                	ret
    if (le_prev != list)
ffffffffc0203990:	fca690e3          	bne	a3,a0,ffffffffc0203950 <insert_vma_struct+0x26>
ffffffffc0203994:	bfd1                	j	ffffffffc0203968 <insert_vma_struct+0x3e>
ffffffffc0203996:	f01ff0ef          	jal	ra,ffffffffc0203896 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020399a:	00004697          	auipc	a3,0x4
ffffffffc020399e:	9de68693          	addi	a3,a3,-1570 # ffffffffc0207378 <default_pmm_manager+0x7b8>
ffffffffc02039a2:	00003617          	auipc	a2,0x3
ffffffffc02039a6:	bae60613          	addi	a2,a2,-1106 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02039aa:	07a00593          	li	a1,122
ffffffffc02039ae:	00004517          	auipc	a0,0x4
ffffffffc02039b2:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc02039b6:	ad9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02039ba:	00004697          	auipc	a3,0x4
ffffffffc02039be:	9fe68693          	addi	a3,a3,-1538 # ffffffffc02073b8 <default_pmm_manager+0x7f8>
ffffffffc02039c2:	00003617          	auipc	a2,0x3
ffffffffc02039c6:	b8e60613          	addi	a2,a2,-1138 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02039ca:	07300593          	li	a1,115
ffffffffc02039ce:	00004517          	auipc	a0,0x4
ffffffffc02039d2:	99a50513          	addi	a0,a0,-1638 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc02039d6:	ab9fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02039da:	00004697          	auipc	a3,0x4
ffffffffc02039de:	9be68693          	addi	a3,a3,-1602 # ffffffffc0207398 <default_pmm_manager+0x7d8>
ffffffffc02039e2:	00003617          	auipc	a2,0x3
ffffffffc02039e6:	b6e60613          	addi	a2,a2,-1170 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02039ea:	07200593          	li	a1,114
ffffffffc02039ee:	00004517          	auipc	a0,0x4
ffffffffc02039f2:	97a50513          	addi	a0,a0,-1670 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc02039f6:	a99fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039fa <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02039fa:	591c                	lw	a5,48(a0)
{
ffffffffc02039fc:	1141                	addi	sp,sp,-16
ffffffffc02039fe:	e406                	sd	ra,8(sp)
ffffffffc0203a00:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203a02:	e78d                	bnez	a5,ffffffffc0203a2c <mm_destroy+0x32>
ffffffffc0203a04:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203a06:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203a08:	00a40c63          	beq	s0,a0,ffffffffc0203a20 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203a0c:	6118                	ld	a4,0(a0)
ffffffffc0203a0e:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203a10:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203a12:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203a14:	e398                	sd	a4,0(a5)
ffffffffc0203a16:	b98fe0ef          	jal	ra,ffffffffc0201dae <kfree>
    return listelm->next;
ffffffffc0203a1a:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203a1c:	fea418e3          	bne	s0,a0,ffffffffc0203a0c <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203a20:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203a22:	6402                	ld	s0,0(sp)
ffffffffc0203a24:	60a2                	ld	ra,8(sp)
ffffffffc0203a26:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203a28:	b86fe06f          	j	ffffffffc0201dae <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203a2c:	00004697          	auipc	a3,0x4
ffffffffc0203a30:	9ac68693          	addi	a3,a3,-1620 # ffffffffc02073d8 <default_pmm_manager+0x818>
ffffffffc0203a34:	00003617          	auipc	a2,0x3
ffffffffc0203a38:	b1c60613          	addi	a2,a2,-1252 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203a3c:	09e00593          	li	a1,158
ffffffffc0203a40:	00004517          	auipc	a0,0x4
ffffffffc0203a44:	92850513          	addi	a0,a0,-1752 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203a48:	a47fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a4c <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203a4c:	7139                	addi	sp,sp,-64
ffffffffc0203a4e:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203a50:	6405                	lui	s0,0x1
ffffffffc0203a52:	147d                	addi	s0,s0,-1
ffffffffc0203a54:	77fd                	lui	a5,0xfffff
ffffffffc0203a56:	9622                	add	a2,a2,s0
ffffffffc0203a58:	962e                	add	a2,a2,a1
{
ffffffffc0203a5a:	f426                	sd	s1,40(sp)
ffffffffc0203a5c:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203a5e:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203a62:	f04a                	sd	s2,32(sp)
ffffffffc0203a64:	ec4e                	sd	s3,24(sp)
ffffffffc0203a66:	e852                	sd	s4,16(sp)
ffffffffc0203a68:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203a6a:	002005b7          	lui	a1,0x200
ffffffffc0203a6e:	00f67433          	and	s0,a2,a5
ffffffffc0203a72:	06b4e363          	bltu	s1,a1,ffffffffc0203ad8 <mm_map+0x8c>
ffffffffc0203a76:	0684f163          	bgeu	s1,s0,ffffffffc0203ad8 <mm_map+0x8c>
ffffffffc0203a7a:	4785                	li	a5,1
ffffffffc0203a7c:	07fe                	slli	a5,a5,0x1f
ffffffffc0203a7e:	0487ed63          	bltu	a5,s0,ffffffffc0203ad8 <mm_map+0x8c>
ffffffffc0203a82:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203a84:	cd21                	beqz	a0,ffffffffc0203adc <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203a86:	85a6                	mv	a1,s1
ffffffffc0203a88:	8ab6                	mv	s5,a3
ffffffffc0203a8a:	8a3a                	mv	s4,a4
ffffffffc0203a8c:	e5fff0ef          	jal	ra,ffffffffc02038ea <find_vma>
ffffffffc0203a90:	c501                	beqz	a0,ffffffffc0203a98 <mm_map+0x4c>
ffffffffc0203a92:	651c                	ld	a5,8(a0)
ffffffffc0203a94:	0487e263          	bltu	a5,s0,ffffffffc0203ad8 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a98:	03000513          	li	a0,48
ffffffffc0203a9c:	a62fe0ef          	jal	ra,ffffffffc0201cfe <kmalloc>
ffffffffc0203aa0:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203aa2:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203aa4:	02090163          	beqz	s2,ffffffffc0203ac6 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203aa8:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0203aaa:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0203aae:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0203ab2:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0203ab6:	85ca                	mv	a1,s2
ffffffffc0203ab8:	e73ff0ef          	jal	ra,ffffffffc020392a <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0203abc:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc0203abe:	000a0463          	beqz	s4,ffffffffc0203ac6 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0203ac2:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bc8>

out:
    return ret;
}
ffffffffc0203ac6:	70e2                	ld	ra,56(sp)
ffffffffc0203ac8:	7442                	ld	s0,48(sp)
ffffffffc0203aca:	74a2                	ld	s1,40(sp)
ffffffffc0203acc:	7902                	ld	s2,32(sp)
ffffffffc0203ace:	69e2                	ld	s3,24(sp)
ffffffffc0203ad0:	6a42                	ld	s4,16(sp)
ffffffffc0203ad2:	6aa2                	ld	s5,8(sp)
ffffffffc0203ad4:	6121                	addi	sp,sp,64
ffffffffc0203ad6:	8082                	ret
        return -E_INVAL;
ffffffffc0203ad8:	5575                	li	a0,-3
ffffffffc0203ada:	b7f5                	j	ffffffffc0203ac6 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0203adc:	00004697          	auipc	a3,0x4
ffffffffc0203ae0:	91468693          	addi	a3,a3,-1772 # ffffffffc02073f0 <default_pmm_manager+0x830>
ffffffffc0203ae4:	00003617          	auipc	a2,0x3
ffffffffc0203ae8:	a6c60613          	addi	a2,a2,-1428 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203aec:	0b300593          	li	a1,179
ffffffffc0203af0:	00004517          	auipc	a0,0x4
ffffffffc0203af4:	87850513          	addi	a0,a0,-1928 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203af8:	997fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203afc <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203afc:	7139                	addi	sp,sp,-64
ffffffffc0203afe:	fc06                	sd	ra,56(sp)
ffffffffc0203b00:	f822                	sd	s0,48(sp)
ffffffffc0203b02:	f426                	sd	s1,40(sp)
ffffffffc0203b04:	f04a                	sd	s2,32(sp)
ffffffffc0203b06:	ec4e                	sd	s3,24(sp)
ffffffffc0203b08:	e852                	sd	s4,16(sp)
ffffffffc0203b0a:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203b0c:	c52d                	beqz	a0,ffffffffc0203b76 <dup_mmap+0x7a>
ffffffffc0203b0e:	892a                	mv	s2,a0
ffffffffc0203b10:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203b12:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203b14:	e595                	bnez	a1,ffffffffc0203b40 <dup_mmap+0x44>
ffffffffc0203b16:	a085                	j	ffffffffc0203b76 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203b18:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203b1a:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_cowtest_out_size+0x1f0318>
        vma->vm_end = vm_end;
ffffffffc0203b1e:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203b22:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203b26:	e05ff0ef          	jal	ra,ffffffffc020392a <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203b2a:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bd8>
ffffffffc0203b2e:	fe843603          	ld	a2,-24(s0)
ffffffffc0203b32:	6c8c                	ld	a1,24(s1)
ffffffffc0203b34:	01893503          	ld	a0,24(s2)
ffffffffc0203b38:	4701                	li	a4,0
ffffffffc0203b3a:	881ff0ef          	jal	ra,ffffffffc02033ba <copy_range>
ffffffffc0203b3e:	e105                	bnez	a0,ffffffffc0203b5e <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203b40:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203b42:	02848863          	beq	s1,s0,ffffffffc0203b72 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b46:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203b4a:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203b4e:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203b52:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b56:	9a8fe0ef          	jal	ra,ffffffffc0201cfe <kmalloc>
ffffffffc0203b5a:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203b5c:	fd55                	bnez	a0,ffffffffc0203b18 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203b5e:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203b60:	70e2                	ld	ra,56(sp)
ffffffffc0203b62:	7442                	ld	s0,48(sp)
ffffffffc0203b64:	74a2                	ld	s1,40(sp)
ffffffffc0203b66:	7902                	ld	s2,32(sp)
ffffffffc0203b68:	69e2                	ld	s3,24(sp)
ffffffffc0203b6a:	6a42                	ld	s4,16(sp)
ffffffffc0203b6c:	6aa2                	ld	s5,8(sp)
ffffffffc0203b6e:	6121                	addi	sp,sp,64
ffffffffc0203b70:	8082                	ret
    return 0;
ffffffffc0203b72:	4501                	li	a0,0
ffffffffc0203b74:	b7f5                	j	ffffffffc0203b60 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203b76:	00004697          	auipc	a3,0x4
ffffffffc0203b7a:	88a68693          	addi	a3,a3,-1910 # ffffffffc0207400 <default_pmm_manager+0x840>
ffffffffc0203b7e:	00003617          	auipc	a2,0x3
ffffffffc0203b82:	9d260613          	addi	a2,a2,-1582 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203b86:	0cf00593          	li	a1,207
ffffffffc0203b8a:	00003517          	auipc	a0,0x3
ffffffffc0203b8e:	7de50513          	addi	a0,a0,2014 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203b92:	8fdfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203b96 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203b96:	1101                	addi	sp,sp,-32
ffffffffc0203b98:	ec06                	sd	ra,24(sp)
ffffffffc0203b9a:	e822                	sd	s0,16(sp)
ffffffffc0203b9c:	e426                	sd	s1,8(sp)
ffffffffc0203b9e:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203ba0:	c531                	beqz	a0,ffffffffc0203bec <exit_mmap+0x56>
ffffffffc0203ba2:	591c                	lw	a5,48(a0)
ffffffffc0203ba4:	84aa                	mv	s1,a0
ffffffffc0203ba6:	e3b9                	bnez	a5,ffffffffc0203bec <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203ba8:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203baa:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203bae:	02850663          	beq	a0,s0,ffffffffc0203bda <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203bb2:	ff043603          	ld	a2,-16(s0)
ffffffffc0203bb6:	fe843583          	ld	a1,-24(s0)
ffffffffc0203bba:	854a                	mv	a0,s2
ffffffffc0203bbc:	e54fe0ef          	jal	ra,ffffffffc0202210 <unmap_range>
ffffffffc0203bc0:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203bc2:	fe8498e3          	bne	s1,s0,ffffffffc0203bb2 <exit_mmap+0x1c>
ffffffffc0203bc6:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203bc8:	00848c63          	beq	s1,s0,ffffffffc0203be0 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203bcc:	ff043603          	ld	a2,-16(s0)
ffffffffc0203bd0:	fe843583          	ld	a1,-24(s0)
ffffffffc0203bd4:	854a                	mv	a0,s2
ffffffffc0203bd6:	f80fe0ef          	jal	ra,ffffffffc0202356 <exit_range>
ffffffffc0203bda:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203bdc:	fe8498e3          	bne	s1,s0,ffffffffc0203bcc <exit_mmap+0x36>
    }
}
ffffffffc0203be0:	60e2                	ld	ra,24(sp)
ffffffffc0203be2:	6442                	ld	s0,16(sp)
ffffffffc0203be4:	64a2                	ld	s1,8(sp)
ffffffffc0203be6:	6902                	ld	s2,0(sp)
ffffffffc0203be8:	6105                	addi	sp,sp,32
ffffffffc0203bea:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203bec:	00004697          	auipc	a3,0x4
ffffffffc0203bf0:	83468693          	addi	a3,a3,-1996 # ffffffffc0207420 <default_pmm_manager+0x860>
ffffffffc0203bf4:	00003617          	auipc	a2,0x3
ffffffffc0203bf8:	95c60613          	addi	a2,a2,-1700 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203bfc:	0e800593          	li	a1,232
ffffffffc0203c00:	00003517          	auipc	a0,0x3
ffffffffc0203c04:	76850513          	addi	a0,a0,1896 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203c08:	887fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203c0c <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203c0c:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203c0e:	04000513          	li	a0,64
{
ffffffffc0203c12:	fc06                	sd	ra,56(sp)
ffffffffc0203c14:	f822                	sd	s0,48(sp)
ffffffffc0203c16:	f426                	sd	s1,40(sp)
ffffffffc0203c18:	f04a                	sd	s2,32(sp)
ffffffffc0203c1a:	ec4e                	sd	s3,24(sp)
ffffffffc0203c1c:	e852                	sd	s4,16(sp)
ffffffffc0203c1e:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203c20:	8defe0ef          	jal	ra,ffffffffc0201cfe <kmalloc>
    if (mm != NULL)
ffffffffc0203c24:	2e050663          	beqz	a0,ffffffffc0203f10 <vmm_init+0x304>
ffffffffc0203c28:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203c2a:	e508                	sd	a0,8(a0)
ffffffffc0203c2c:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203c2e:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203c32:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203c36:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203c3a:	02053423          	sd	zero,40(a0)
ffffffffc0203c3e:	02052823          	sw	zero,48(a0)
ffffffffc0203c42:	02053c23          	sd	zero,56(a0)
ffffffffc0203c46:	03200413          	li	s0,50
ffffffffc0203c4a:	a811                	j	ffffffffc0203c5e <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203c4c:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203c4e:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203c50:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203c54:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203c56:	8526                	mv	a0,s1
ffffffffc0203c58:	cd3ff0ef          	jal	ra,ffffffffc020392a <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203c5c:	c80d                	beqz	s0,ffffffffc0203c8e <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203c5e:	03000513          	li	a0,48
ffffffffc0203c62:	89cfe0ef          	jal	ra,ffffffffc0201cfe <kmalloc>
ffffffffc0203c66:	85aa                	mv	a1,a0
ffffffffc0203c68:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203c6c:	f165                	bnez	a0,ffffffffc0203c4c <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203c6e:	00004697          	auipc	a3,0x4
ffffffffc0203c72:	94a68693          	addi	a3,a3,-1718 # ffffffffc02075b8 <default_pmm_manager+0x9f8>
ffffffffc0203c76:	00003617          	auipc	a2,0x3
ffffffffc0203c7a:	8da60613          	addi	a2,a2,-1830 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203c7e:	12c00593          	li	a1,300
ffffffffc0203c82:	00003517          	auipc	a0,0x3
ffffffffc0203c86:	6e650513          	addi	a0,a0,1766 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203c8a:	805fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203c8e:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203c92:	1f900913          	li	s2,505
ffffffffc0203c96:	a819                	j	ffffffffc0203cac <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203c98:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203c9a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203c9c:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ca0:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203ca2:	8526                	mv	a0,s1
ffffffffc0203ca4:	c87ff0ef          	jal	ra,ffffffffc020392a <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ca8:	03240a63          	beq	s0,s2,ffffffffc0203cdc <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203cac:	03000513          	li	a0,48
ffffffffc0203cb0:	84efe0ef          	jal	ra,ffffffffc0201cfe <kmalloc>
ffffffffc0203cb4:	85aa                	mv	a1,a0
ffffffffc0203cb6:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203cba:	fd79                	bnez	a0,ffffffffc0203c98 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203cbc:	00004697          	auipc	a3,0x4
ffffffffc0203cc0:	8fc68693          	addi	a3,a3,-1796 # ffffffffc02075b8 <default_pmm_manager+0x9f8>
ffffffffc0203cc4:	00003617          	auipc	a2,0x3
ffffffffc0203cc8:	88c60613          	addi	a2,a2,-1908 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203ccc:	13300593          	li	a1,307
ffffffffc0203cd0:	00003517          	auipc	a0,0x3
ffffffffc0203cd4:	69850513          	addi	a0,a0,1688 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203cd8:	fb6fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203cdc:	649c                	ld	a5,8(s1)
ffffffffc0203cde:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203ce0:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203ce4:	16f48663          	beq	s1,a5,ffffffffc0203e50 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ce8:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd249f4>
ffffffffc0203cec:	ffe70693          	addi	a3,a4,-2
ffffffffc0203cf0:	10d61063          	bne	a2,a3,ffffffffc0203df0 <vmm_init+0x1e4>
ffffffffc0203cf4:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203cf8:	0ed71c63          	bne	a4,a3,ffffffffc0203df0 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203cfc:	0715                	addi	a4,a4,5
ffffffffc0203cfe:	679c                	ld	a5,8(a5)
ffffffffc0203d00:	feb712e3          	bne	a4,a1,ffffffffc0203ce4 <vmm_init+0xd8>
ffffffffc0203d04:	4a1d                	li	s4,7
ffffffffc0203d06:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203d08:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203d0c:	85a2                	mv	a1,s0
ffffffffc0203d0e:	8526                	mv	a0,s1
ffffffffc0203d10:	bdbff0ef          	jal	ra,ffffffffc02038ea <find_vma>
ffffffffc0203d14:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203d16:	16050d63          	beqz	a0,ffffffffc0203e90 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203d1a:	00140593          	addi	a1,s0,1
ffffffffc0203d1e:	8526                	mv	a0,s1
ffffffffc0203d20:	bcbff0ef          	jal	ra,ffffffffc02038ea <find_vma>
ffffffffc0203d24:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203d26:	14050563          	beqz	a0,ffffffffc0203e70 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203d2a:	85d2                	mv	a1,s4
ffffffffc0203d2c:	8526                	mv	a0,s1
ffffffffc0203d2e:	bbdff0ef          	jal	ra,ffffffffc02038ea <find_vma>
        assert(vma3 == NULL);
ffffffffc0203d32:	16051f63          	bnez	a0,ffffffffc0203eb0 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203d36:	00340593          	addi	a1,s0,3
ffffffffc0203d3a:	8526                	mv	a0,s1
ffffffffc0203d3c:	bafff0ef          	jal	ra,ffffffffc02038ea <find_vma>
        assert(vma4 == NULL);
ffffffffc0203d40:	1a051863          	bnez	a0,ffffffffc0203ef0 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203d44:	00440593          	addi	a1,s0,4
ffffffffc0203d48:	8526                	mv	a0,s1
ffffffffc0203d4a:	ba1ff0ef          	jal	ra,ffffffffc02038ea <find_vma>
        assert(vma5 == NULL);
ffffffffc0203d4e:	18051163          	bnez	a0,ffffffffc0203ed0 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203d52:	00893783          	ld	a5,8(s2)
ffffffffc0203d56:	0a879d63          	bne	a5,s0,ffffffffc0203e10 <vmm_init+0x204>
ffffffffc0203d5a:	01093783          	ld	a5,16(s2)
ffffffffc0203d5e:	0b479963          	bne	a5,s4,ffffffffc0203e10 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203d62:	0089b783          	ld	a5,8(s3)
ffffffffc0203d66:	0c879563          	bne	a5,s0,ffffffffc0203e30 <vmm_init+0x224>
ffffffffc0203d6a:	0109b783          	ld	a5,16(s3)
ffffffffc0203d6e:	0d479163          	bne	a5,s4,ffffffffc0203e30 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203d72:	0415                	addi	s0,s0,5
ffffffffc0203d74:	0a15                	addi	s4,s4,5
ffffffffc0203d76:	f9541be3          	bne	s0,s5,ffffffffc0203d0c <vmm_init+0x100>
ffffffffc0203d7a:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203d7c:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203d7e:	85a2                	mv	a1,s0
ffffffffc0203d80:	8526                	mv	a0,s1
ffffffffc0203d82:	b69ff0ef          	jal	ra,ffffffffc02038ea <find_vma>
ffffffffc0203d86:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203d8a:	c90d                	beqz	a0,ffffffffc0203dbc <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203d8c:	6914                	ld	a3,16(a0)
ffffffffc0203d8e:	6510                	ld	a2,8(a0)
ffffffffc0203d90:	00003517          	auipc	a0,0x3
ffffffffc0203d94:	7b050513          	addi	a0,a0,1968 # ffffffffc0207540 <default_pmm_manager+0x980>
ffffffffc0203d98:	bfcfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203d9c:	00003697          	auipc	a3,0x3
ffffffffc0203da0:	7cc68693          	addi	a3,a3,1996 # ffffffffc0207568 <default_pmm_manager+0x9a8>
ffffffffc0203da4:	00002617          	auipc	a2,0x2
ffffffffc0203da8:	7ac60613          	addi	a2,a2,1964 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203dac:	15900593          	li	a1,345
ffffffffc0203db0:	00003517          	auipc	a0,0x3
ffffffffc0203db4:	5b850513          	addi	a0,a0,1464 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203db8:	ed6fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203dbc:	147d                	addi	s0,s0,-1
ffffffffc0203dbe:	fd2410e3          	bne	s0,s2,ffffffffc0203d7e <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203dc2:	8526                	mv	a0,s1
ffffffffc0203dc4:	c37ff0ef          	jal	ra,ffffffffc02039fa <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203dc8:	00003517          	auipc	a0,0x3
ffffffffc0203dcc:	7b850513          	addi	a0,a0,1976 # ffffffffc0207580 <default_pmm_manager+0x9c0>
ffffffffc0203dd0:	bc4fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203dd4:	7442                	ld	s0,48(sp)
ffffffffc0203dd6:	70e2                	ld	ra,56(sp)
ffffffffc0203dd8:	74a2                	ld	s1,40(sp)
ffffffffc0203dda:	7902                	ld	s2,32(sp)
ffffffffc0203ddc:	69e2                	ld	s3,24(sp)
ffffffffc0203dde:	6a42                	ld	s4,16(sp)
ffffffffc0203de0:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203de2:	00003517          	auipc	a0,0x3
ffffffffc0203de6:	7be50513          	addi	a0,a0,1982 # ffffffffc02075a0 <default_pmm_manager+0x9e0>
}
ffffffffc0203dea:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203dec:	ba8fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203df0:	00003697          	auipc	a3,0x3
ffffffffc0203df4:	66868693          	addi	a3,a3,1640 # ffffffffc0207458 <default_pmm_manager+0x898>
ffffffffc0203df8:	00002617          	auipc	a2,0x2
ffffffffc0203dfc:	75860613          	addi	a2,a2,1880 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203e00:	13d00593          	li	a1,317
ffffffffc0203e04:	00003517          	auipc	a0,0x3
ffffffffc0203e08:	56450513          	addi	a0,a0,1380 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203e0c:	e82fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203e10:	00003697          	auipc	a3,0x3
ffffffffc0203e14:	6d068693          	addi	a3,a3,1744 # ffffffffc02074e0 <default_pmm_manager+0x920>
ffffffffc0203e18:	00002617          	auipc	a2,0x2
ffffffffc0203e1c:	73860613          	addi	a2,a2,1848 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203e20:	14e00593          	li	a1,334
ffffffffc0203e24:	00003517          	auipc	a0,0x3
ffffffffc0203e28:	54450513          	addi	a0,a0,1348 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203e2c:	e62fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203e30:	00003697          	auipc	a3,0x3
ffffffffc0203e34:	6e068693          	addi	a3,a3,1760 # ffffffffc0207510 <default_pmm_manager+0x950>
ffffffffc0203e38:	00002617          	auipc	a2,0x2
ffffffffc0203e3c:	71860613          	addi	a2,a2,1816 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203e40:	14f00593          	li	a1,335
ffffffffc0203e44:	00003517          	auipc	a0,0x3
ffffffffc0203e48:	52450513          	addi	a0,a0,1316 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203e4c:	e42fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203e50:	00003697          	auipc	a3,0x3
ffffffffc0203e54:	5f068693          	addi	a3,a3,1520 # ffffffffc0207440 <default_pmm_manager+0x880>
ffffffffc0203e58:	00002617          	auipc	a2,0x2
ffffffffc0203e5c:	6f860613          	addi	a2,a2,1784 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203e60:	13b00593          	li	a1,315
ffffffffc0203e64:	00003517          	auipc	a0,0x3
ffffffffc0203e68:	50450513          	addi	a0,a0,1284 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203e6c:	e22fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203e70:	00003697          	auipc	a3,0x3
ffffffffc0203e74:	63068693          	addi	a3,a3,1584 # ffffffffc02074a0 <default_pmm_manager+0x8e0>
ffffffffc0203e78:	00002617          	auipc	a2,0x2
ffffffffc0203e7c:	6d860613          	addi	a2,a2,1752 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203e80:	14600593          	li	a1,326
ffffffffc0203e84:	00003517          	auipc	a0,0x3
ffffffffc0203e88:	4e450513          	addi	a0,a0,1252 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203e8c:	e02fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203e90:	00003697          	auipc	a3,0x3
ffffffffc0203e94:	60068693          	addi	a3,a3,1536 # ffffffffc0207490 <default_pmm_manager+0x8d0>
ffffffffc0203e98:	00002617          	auipc	a2,0x2
ffffffffc0203e9c:	6b860613          	addi	a2,a2,1720 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203ea0:	14400593          	li	a1,324
ffffffffc0203ea4:	00003517          	auipc	a0,0x3
ffffffffc0203ea8:	4c450513          	addi	a0,a0,1220 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203eac:	de2fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203eb0:	00003697          	auipc	a3,0x3
ffffffffc0203eb4:	60068693          	addi	a3,a3,1536 # ffffffffc02074b0 <default_pmm_manager+0x8f0>
ffffffffc0203eb8:	00002617          	auipc	a2,0x2
ffffffffc0203ebc:	69860613          	addi	a2,a2,1688 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203ec0:	14800593          	li	a1,328
ffffffffc0203ec4:	00003517          	auipc	a0,0x3
ffffffffc0203ec8:	4a450513          	addi	a0,a0,1188 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203ecc:	dc2fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203ed0:	00003697          	auipc	a3,0x3
ffffffffc0203ed4:	60068693          	addi	a3,a3,1536 # ffffffffc02074d0 <default_pmm_manager+0x910>
ffffffffc0203ed8:	00002617          	auipc	a2,0x2
ffffffffc0203edc:	67860613          	addi	a2,a2,1656 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203ee0:	14c00593          	li	a1,332
ffffffffc0203ee4:	00003517          	auipc	a0,0x3
ffffffffc0203ee8:	48450513          	addi	a0,a0,1156 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203eec:	da2fc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203ef0:	00003697          	auipc	a3,0x3
ffffffffc0203ef4:	5d068693          	addi	a3,a3,1488 # ffffffffc02074c0 <default_pmm_manager+0x900>
ffffffffc0203ef8:	00002617          	auipc	a2,0x2
ffffffffc0203efc:	65860613          	addi	a2,a2,1624 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203f00:	14a00593          	li	a1,330
ffffffffc0203f04:	00003517          	auipc	a0,0x3
ffffffffc0203f08:	46450513          	addi	a0,a0,1124 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203f0c:	d82fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203f10:	00003697          	auipc	a3,0x3
ffffffffc0203f14:	4e068693          	addi	a3,a3,1248 # ffffffffc02073f0 <default_pmm_manager+0x830>
ffffffffc0203f18:	00002617          	auipc	a2,0x2
ffffffffc0203f1c:	63860613          	addi	a2,a2,1592 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0203f20:	12400593          	li	a1,292
ffffffffc0203f24:	00003517          	auipc	a0,0x3
ffffffffc0203f28:	44450513          	addi	a0,a0,1092 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0203f2c:	d62fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203f30 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203f30:	7179                	addi	sp,sp,-48
ffffffffc0203f32:	f022                	sd	s0,32(sp)
ffffffffc0203f34:	f406                	sd	ra,40(sp)
ffffffffc0203f36:	ec26                	sd	s1,24(sp)
ffffffffc0203f38:	e84a                	sd	s2,16(sp)
ffffffffc0203f3a:	e44e                	sd	s3,8(sp)
ffffffffc0203f3c:	e052                	sd	s4,0(sp)
ffffffffc0203f3e:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203f40:	c135                	beqz	a0,ffffffffc0203fa4 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203f42:	002007b7          	lui	a5,0x200
ffffffffc0203f46:	04f5e663          	bltu	a1,a5,ffffffffc0203f92 <user_mem_check+0x62>
ffffffffc0203f4a:	00c584b3          	add	s1,a1,a2
ffffffffc0203f4e:	0495f263          	bgeu	a1,s1,ffffffffc0203f92 <user_mem_check+0x62>
ffffffffc0203f52:	4785                	li	a5,1
ffffffffc0203f54:	07fe                	slli	a5,a5,0x1f
ffffffffc0203f56:	0297ee63          	bltu	a5,s1,ffffffffc0203f92 <user_mem_check+0x62>
ffffffffc0203f5a:	892a                	mv	s2,a0
ffffffffc0203f5c:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f5e:	6a05                	lui	s4,0x1
ffffffffc0203f60:	a821                	j	ffffffffc0203f78 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f62:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f66:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f68:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f6a:	c685                	beqz	a3,ffffffffc0203f92 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203f6c:	c399                	beqz	a5,ffffffffc0203f72 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203f6e:	02e46263          	bltu	s0,a4,ffffffffc0203f92 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203f72:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203f74:	04947663          	bgeu	s0,s1,ffffffffc0203fc0 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203f78:	85a2                	mv	a1,s0
ffffffffc0203f7a:	854a                	mv	a0,s2
ffffffffc0203f7c:	96fff0ef          	jal	ra,ffffffffc02038ea <find_vma>
ffffffffc0203f80:	c909                	beqz	a0,ffffffffc0203f92 <user_mem_check+0x62>
ffffffffc0203f82:	6518                	ld	a4,8(a0)
ffffffffc0203f84:	00e46763          	bltu	s0,a4,ffffffffc0203f92 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203f88:	4d1c                	lw	a5,24(a0)
ffffffffc0203f8a:	fc099ce3          	bnez	s3,ffffffffc0203f62 <user_mem_check+0x32>
ffffffffc0203f8e:	8b85                	andi	a5,a5,1
ffffffffc0203f90:	f3ed                	bnez	a5,ffffffffc0203f72 <user_mem_check+0x42>
            return 0;
ffffffffc0203f92:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203f94:	70a2                	ld	ra,40(sp)
ffffffffc0203f96:	7402                	ld	s0,32(sp)
ffffffffc0203f98:	64e2                	ld	s1,24(sp)
ffffffffc0203f9a:	6942                	ld	s2,16(sp)
ffffffffc0203f9c:	69a2                	ld	s3,8(sp)
ffffffffc0203f9e:	6a02                	ld	s4,0(sp)
ffffffffc0203fa0:	6145                	addi	sp,sp,48
ffffffffc0203fa2:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203fa4:	c02007b7          	lui	a5,0xc0200
ffffffffc0203fa8:	4501                	li	a0,0
ffffffffc0203faa:	fef5e5e3          	bltu	a1,a5,ffffffffc0203f94 <user_mem_check+0x64>
ffffffffc0203fae:	962e                	add	a2,a2,a1
ffffffffc0203fb0:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203f94 <user_mem_check+0x64>
ffffffffc0203fb4:	c8000537          	lui	a0,0xc8000
ffffffffc0203fb8:	0505                	addi	a0,a0,1
ffffffffc0203fba:	00a63533          	sltu	a0,a2,a0
ffffffffc0203fbe:	bfd9                	j	ffffffffc0203f94 <user_mem_check+0x64>
        return 1;
ffffffffc0203fc0:	4505                	li	a0,1
ffffffffc0203fc2:	bfc9                	j	ffffffffc0203f94 <user_mem_check+0x64>

ffffffffc0203fc4 <do_pgfault_cow>:

int do_pgfault_cow(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
ffffffffc0203fc4:	715d                	addi	sp,sp,-80
ffffffffc0203fc6:	e0a2                	sd	s0,64(sp)
ffffffffc0203fc8:	8432                	mv	s0,a2
ffffffffc0203fca:	f84a                	sd	s2,48(sp)
ffffffffc0203fcc:	862e                	mv	a2,a1
ffffffffc0203fce:	892a                	mv	s2,a0
    cprintf("[COW] Page fault at addr 0x%x, error_code=0x%x\n", addr, error_code);
ffffffffc0203fd0:	85a2                	mv	a1,s0
ffffffffc0203fd2:	00003517          	auipc	a0,0x3
ffffffffc0203fd6:	5f650513          	addi	a0,a0,1526 # ffffffffc02075c8 <default_pmm_manager+0xa08>
{
ffffffffc0203fda:	e486                	sd	ra,72(sp)
ffffffffc0203fdc:	fc26                	sd	s1,56(sp)
ffffffffc0203fde:	f44e                	sd	s3,40(sp)
ffffffffc0203fe0:	f052                	sd	s4,32(sp)
ffffffffc0203fe2:	ec56                	sd	s5,24(sp)
ffffffffc0203fe4:	e85a                	sd	s6,16(sp)
ffffffffc0203fe6:	e45e                	sd	s7,8(sp)
    cprintf("[COW] Page fault at addr 0x%x, error_code=0x%x\n", addr, error_code);
ffffffffc0203fe8:	9acfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    // 参数检查
    if (mm == NULL)
ffffffffc0203fec:	1c090b63          	beqz	s2,ffffffffc02041c2 <do_pgfault_cow+0x1fe>
        cprintf("[COW] ERROR: mm is NULL\n");
        return -E_INVAL;
    }
    
    // 将addr对齐到页边界
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203ff0:	75fd                	lui	a1,0xfffff
    
    // 获取页表项
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
ffffffffc0203ff2:	01893503          	ld	a0,24(s2)
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203ff6:	8c6d                	and	s0,s0,a1
    pte_t *ptep = get_pte(mm->pgdir, la, 0);
ffffffffc0203ff8:	4601                	li	a2,0
ffffffffc0203ffa:	85a2                	mv	a1,s0
ffffffffc0203ffc:	f99fd0ef          	jal	ra,ffffffffc0201f94 <get_pte>
ffffffffc0204000:	84aa                	mv	s1,a0
    
    // 检查页表项是否存在
    if (ptep == NULL || !(*ptep & PTE_V))
ffffffffc0204002:	1a050063          	beqz	a0,ffffffffc02041a2 <do_pgfault_cow+0x1de>
ffffffffc0204006:	610c                	ld	a1,0(a0)
ffffffffc0204008:	0015f793          	andi	a5,a1,1
ffffffffc020400c:	18078b63          	beqz	a5,ffffffffc02041a2 <do_pgfault_cow+0x1de>
        cprintf("[COW] ERROR: Page table entry not found or invalid\n");
        return -E_INVAL;
    }
    
    // 检查是否是COW页面
    if (!(*ptep & PTE_COW))
ffffffffc0204010:	1005f793          	andi	a5,a1,256
ffffffffc0204014:	18078f63          	beqz	a5,ffffffffc02041b2 <do_pgfault_cow+0x1ee>
    {
        cprintf("[COW] ERROR: Not a COW page (PTE=0x%x)\n", *ptep);
        return -E_INVAL;
    }
    
    cprintf("[COW] Valid COW page detected, PTE=0x%x\n", *ptep);
ffffffffc0204018:	00003517          	auipc	a0,0x3
ffffffffc020401c:	66050513          	addi	a0,a0,1632 # ffffffffc0207678 <default_pmm_manager+0xab8>
ffffffffc0204020:	974fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    // 获取当前物理页面
    struct Page *old_page = pte2page(*ptep);
ffffffffc0204024:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc0204026:	0017f713          	andi	a4,a5,1
ffffffffc020402a:	1a070c63          	beqz	a4,ffffffffc02041e2 <do_pgfault_cow+0x21e>
    if (PPN(pa) >= npage)
ffffffffc020402e:	000d6a97          	auipc	s5,0xd6
ffffffffc0204032:	58aa8a93          	addi	s5,s5,1418 # ffffffffc02da5b8 <npage>
ffffffffc0204036:	000ab703          	ld	a4,0(s5)
    return pa2page(PTE_ADDR(pte));
ffffffffc020403a:	078a                	slli	a5,a5,0x2
ffffffffc020403c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020403e:	1ce7fe63          	bgeu	a5,a4,ffffffffc020421a <do_pgfault_cow+0x256>
    return &pages[PPN(pa) - nbase];
ffffffffc0204042:	000d6b97          	auipc	s7,0xd6
ffffffffc0204046:	57eb8b93          	addi	s7,s7,1406 # ffffffffc02da5c0 <pages>
ffffffffc020404a:	000bb983          	ld	s3,0(s7)
ffffffffc020404e:	00004a17          	auipc	s4,0x4
ffffffffc0204052:	1d2a3a03          	ld	s4,466(s4) # ffffffffc0208220 <nbase>
ffffffffc0204056:	414787b3          	sub	a5,a5,s4
ffffffffc020405a:	079a                	slli	a5,a5,0x6
ffffffffc020405c:	99be                	add	s3,s3,a5
    assert(old_page != NULL);
ffffffffc020405e:	18098e63          	beqz	s3,ffffffffc02041fa <do_pgfault_cow+0x236>
    return page->ref;
ffffffffc0204062:	0009ab03          	lw	s6,0(s3)
    
    // 检查引用计数
    int ref_count = page_ref(old_page);
    cprintf("[COW] Physical page ref_count = %d\n", ref_count);
ffffffffc0204066:	00003517          	auipc	a0,0x3
ffffffffc020406a:	65a50513          	addi	a0,a0,1626 # ffffffffc02076c0 <default_pmm_manager+0xb00>
ffffffffc020406e:	85da                	mv	a1,s6
ffffffffc0204070:	924fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    // === 情况1：当前进程是唯一引用者（ref=1） ===
    // 不需要复制，直接授予写权限即可
    if (ref_count == 1)
ffffffffc0204074:	4785                	li	a5,1
ffffffffc0204076:	0efb0c63          	beq	s6,a5,ffffffffc020416e <do_pgfault_cow+0x1aa>
        return 0;
    }
    
    // === 情况2：多个进程共享（ref>1） ===
    // 需要分配新页面并复制数据
    cprintf("[COW] Multiple references (%d), performing copy\n", ref_count);
ffffffffc020407a:	85da                	mv	a1,s6
ffffffffc020407c:	00003517          	auipc	a0,0x3
ffffffffc0204080:	6dc50513          	addi	a0,a0,1756 # ffffffffc0207758 <default_pmm_manager+0xb98>
ffffffffc0204084:	910fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    // 1. 分配新的物理页面
    struct Page *new_page = alloc_page();
ffffffffc0204088:	4505                	li	a0,1
ffffffffc020408a:	e53fd0ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc020408e:	8b2a                	mv	s6,a0
    if (new_page == NULL)
ffffffffc0204090:	14050163          	beqz	a0,ffffffffc02041d2 <do_pgfault_cow+0x20e>
    {
        cprintf("[COW] ERROR: Failed to allocate new page\n");
        return -E_NO_MEM;
    }
    
    cprintf("[COW] New page allocated\n");
ffffffffc0204094:	00003517          	auipc	a0,0x3
ffffffffc0204098:	72c50513          	addi	a0,a0,1836 # ffffffffc02077c0 <default_pmm_manager+0xc00>
ffffffffc020409c:	8f8fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page - pages + nbase;
ffffffffc02040a0:	000bb683          	ld	a3,0(s7)
    return KADDR(page2pa(page));
ffffffffc02040a4:	000ab703          	ld	a4,0(s5)
    return page - pages + nbase;
ffffffffc02040a8:	40d985b3          	sub	a1,s3,a3
ffffffffc02040ac:	8599                	srai	a1,a1,0x6
ffffffffc02040ae:	95d2                	add	a1,a1,s4
    return KADDR(page2pa(page));
ffffffffc02040b0:	00c59793          	slli	a5,a1,0xc
ffffffffc02040b4:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02040b6:	05b2                	slli	a1,a1,0xc
    return KADDR(page2pa(page));
ffffffffc02040b8:	18e7f963          	bgeu	a5,a4,ffffffffc020424a <do_pgfault_cow+0x286>
    return page - pages + nbase;
ffffffffc02040bc:	40db06b3          	sub	a3,s6,a3
ffffffffc02040c0:	8699                	srai	a3,a3,0x6
ffffffffc02040c2:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc02040c4:	00c69793          	slli	a5,a3,0xc
ffffffffc02040c8:	000d6517          	auipc	a0,0xd6
ffffffffc02040cc:	50853503          	ld	a0,1288(a0) # ffffffffc02da5d0 <va_pa_offset>
ffffffffc02040d0:	83b1                	srli	a5,a5,0xc
ffffffffc02040d2:	95aa                	add	a1,a1,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02040d4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02040d6:	14e7fe63          	bgeu	a5,a4,ffffffffc0204232 <do_pgfault_cow+0x26e>
    
    // 2. 复制旧页面的内容到新页面
    void *old_kva = page2kva(old_page);
    void *new_kva = page2kva(new_page);
    memcpy(new_kva, old_kva, PGSIZE);
ffffffffc02040da:	6605                	lui	a2,0x1
ffffffffc02040dc:	9536                	add	a0,a0,a3
ffffffffc02040de:	3f7010ef          	jal	ra,ffffffffc0205cd4 <memcpy>
    
    cprintf("[COW] Page content copied\n");
ffffffffc02040e2:	00003517          	auipc	a0,0x3
ffffffffc02040e6:	6fe50513          	addi	a0,a0,1790 # ffffffffc02077e0 <default_pmm_manager+0xc20>
ffffffffc02040ea:	8aafc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    // 3. 准备新的权限：添加写权限，移除COW标记
    uint32_t perm = (*ptep & PTE_USER) | PTE_W;
ffffffffc02040ee:	6094                	ld	a3,0(s1)
    // 4. 建立新的映射
    //    page_insert会自动：
    //    - 解除旧映射（减少old_page的引用计数）
    //    - 建立新映射（new_page的引用计数变为1）
    //    - 刷新TLB
    int ret = page_insert(mm->pgdir, new_page, la, perm);
ffffffffc02040f0:	01893503          	ld	a0,24(s2)
ffffffffc02040f4:	8622                	mv	a2,s0
    uint32_t perm = (*ptep & PTE_USER) | PTE_W;
ffffffffc02040f6:	8aed                	andi	a3,a3,27
    int ret = page_insert(mm->pgdir, new_page, la, perm);
ffffffffc02040f8:	0046e693          	ori	a3,a3,4
ffffffffc02040fc:	85da                	mv	a1,s6
ffffffffc02040fe:	d86fe0ef          	jal	ra,ffffffffc0202684 <page_insert>
ffffffffc0204102:	84aa                	mv	s1,a0
    if (ret != 0)
ffffffffc0204104:	e931                	bnez	a0,ffffffffc0204158 <do_pgfault_cow+0x194>
        cprintf("[COW] ERROR: page_insert failed\n");
        free_page(new_page);
        return ret;
    }
    
    cprintf("[COW] New mapping established, PTE=0x%x\n", *get_pte(mm->pgdir, la, 0));
ffffffffc0204106:	01893503          	ld	a0,24(s2)
ffffffffc020410a:	4601                	li	a2,0
ffffffffc020410c:	85a2                	mv	a1,s0
ffffffffc020410e:	e87fd0ef          	jal	ra,ffffffffc0201f94 <get_pte>
ffffffffc0204112:	610c                	ld	a1,0(a0)
ffffffffc0204114:	00003517          	auipc	a0,0x3
ffffffffc0204118:	71450513          	addi	a0,a0,1812 # ffffffffc0207828 <default_pmm_manager+0xc68>
ffffffffc020411c:	878fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("[COW] Old page ref_count decreased to %d\n", page_ref(old_page));
ffffffffc0204120:	0009a583          	lw	a1,0(s3)
ffffffffc0204124:	00003517          	auipc	a0,0x3
ffffffffc0204128:	73450513          	addi	a0,a0,1844 # ffffffffc0207858 <default_pmm_manager+0xc98>
ffffffffc020412c:	868fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("[COW] New page ref_count = %d\n", page_ref(new_page));
ffffffffc0204130:	000b2583          	lw	a1,0(s6)
ffffffffc0204134:	00003517          	auipc	a0,0x3
ffffffffc0204138:	75450513          	addi	a0,a0,1876 # ffffffffc0207888 <default_pmm_manager+0xcc8>
ffffffffc020413c:	858fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    return 0;
}
ffffffffc0204140:	60a6                	ld	ra,72(sp)
ffffffffc0204142:	6406                	ld	s0,64(sp)
ffffffffc0204144:	7942                	ld	s2,48(sp)
ffffffffc0204146:	79a2                	ld	s3,40(sp)
ffffffffc0204148:	7a02                	ld	s4,32(sp)
ffffffffc020414a:	6ae2                	ld	s5,24(sp)
ffffffffc020414c:	6b42                	ld	s6,16(sp)
ffffffffc020414e:	6ba2                	ld	s7,8(sp)
ffffffffc0204150:	8526                	mv	a0,s1
ffffffffc0204152:	74e2                	ld	s1,56(sp)
ffffffffc0204154:	6161                	addi	sp,sp,80
ffffffffc0204156:	8082                	ret
        cprintf("[COW] ERROR: page_insert failed\n");
ffffffffc0204158:	00003517          	auipc	a0,0x3
ffffffffc020415c:	6a850513          	addi	a0,a0,1704 # ffffffffc0207800 <default_pmm_manager+0xc40>
ffffffffc0204160:	834fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        free_page(new_page);
ffffffffc0204164:	4585                	li	a1,1
ffffffffc0204166:	855a                	mv	a0,s6
ffffffffc0204168:	db3fd0ef          	jal	ra,ffffffffc0201f1a <free_pages>
        return ret;
ffffffffc020416c:	bfd1                	j	ffffffffc0204140 <do_pgfault_cow+0x17c>
        cprintf("[COW] Only one reference, granting write permission directly\n");
ffffffffc020416e:	00003517          	auipc	a0,0x3
ffffffffc0204172:	57a50513          	addi	a0,a0,1402 # ffffffffc02076e8 <default_pmm_manager+0xb28>
ffffffffc0204176:	81efc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        uint32_t perm = (*ptep & PTE_USER) | PTE_W;  // 添加写权限
ffffffffc020417a:	609c                	ld	a5,0(s1)
        tlb_invalidate(mm->pgdir, la);
ffffffffc020417c:	01893503          	ld	a0,24(s2)
ffffffffc0204180:	85a2                	mv	a1,s0
        *ptep = ((*ptep & ~0x3FF) | perm);  // 保留PPN，更新权限位
ffffffffc0204182:	c1b7f793          	andi	a5,a5,-997
ffffffffc0204186:	0047e793          	ori	a5,a5,4
ffffffffc020418a:	e09c                	sd	a5,0(s1)
        tlb_invalidate(mm->pgdir, la);
ffffffffc020418c:	e42ff0ef          	jal	ra,ffffffffc02037ce <tlb_invalidate>
        cprintf("[COW] Write permission granted, new PTE=0x%x\n", *ptep);
ffffffffc0204190:	608c                	ld	a1,0(s1)
ffffffffc0204192:	00003517          	auipc	a0,0x3
ffffffffc0204196:	59650513          	addi	a0,a0,1430 # ffffffffc0207728 <default_pmm_manager+0xb68>
        return 0;
ffffffffc020419a:	4481                	li	s1,0
        cprintf("[COW] Write permission granted, new PTE=0x%x\n", *ptep);
ffffffffc020419c:	ff9fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
        return 0;
ffffffffc02041a0:	b745                	j	ffffffffc0204140 <do_pgfault_cow+0x17c>
        cprintf("[COW] ERROR: Page table entry not found or invalid\n");
ffffffffc02041a2:	00003517          	auipc	a0,0x3
ffffffffc02041a6:	47650513          	addi	a0,a0,1142 # ffffffffc0207618 <default_pmm_manager+0xa58>
ffffffffc02041aa:	febfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
        return -E_INVAL;
ffffffffc02041ae:	54f5                	li	s1,-3
ffffffffc02041b0:	bf41                	j	ffffffffc0204140 <do_pgfault_cow+0x17c>
        cprintf("[COW] ERROR: Not a COW page (PTE=0x%x)\n", *ptep);
ffffffffc02041b2:	00003517          	auipc	a0,0x3
ffffffffc02041b6:	49e50513          	addi	a0,a0,1182 # ffffffffc0207650 <default_pmm_manager+0xa90>
ffffffffc02041ba:	fdbfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
        return -E_INVAL;
ffffffffc02041be:	54f5                	li	s1,-3
ffffffffc02041c0:	b741                	j	ffffffffc0204140 <do_pgfault_cow+0x17c>
        cprintf("[COW] ERROR: mm is NULL\n");
ffffffffc02041c2:	00003517          	auipc	a0,0x3
ffffffffc02041c6:	43650513          	addi	a0,a0,1078 # ffffffffc02075f8 <default_pmm_manager+0xa38>
ffffffffc02041ca:	fcbfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
        return -E_INVAL;
ffffffffc02041ce:	54f5                	li	s1,-3
ffffffffc02041d0:	bf85                	j	ffffffffc0204140 <do_pgfault_cow+0x17c>
        cprintf("[COW] ERROR: Failed to allocate new page\n");
ffffffffc02041d2:	00003517          	auipc	a0,0x3
ffffffffc02041d6:	5be50513          	addi	a0,a0,1470 # ffffffffc0207790 <default_pmm_manager+0xbd0>
ffffffffc02041da:	fbbfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
        return -E_NO_MEM;
ffffffffc02041de:	54f1                	li	s1,-4
ffffffffc02041e0:	b785                	j	ffffffffc0204140 <do_pgfault_cow+0x17c>
        panic("pte2page called with invalid pte");
ffffffffc02041e2:	00003617          	auipc	a2,0x3
ffffffffc02041e6:	b0660613          	addi	a2,a2,-1274 # ffffffffc0206ce8 <default_pmm_manager+0x128>
ffffffffc02041ea:	08000593          	li	a1,128
ffffffffc02041ee:	00003517          	auipc	a0,0x3
ffffffffc02041f2:	a3250513          	addi	a0,a0,-1486 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc02041f6:	a98fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(old_page != NULL);
ffffffffc02041fa:	00003697          	auipc	a3,0x3
ffffffffc02041fe:	4ae68693          	addi	a3,a3,1198 # ffffffffc02076a8 <default_pmm_manager+0xae8>
ffffffffc0204202:	00002617          	auipc	a2,0x2
ffffffffc0204206:	34e60613          	addi	a2,a2,846 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020420a:	1a500593          	li	a1,421
ffffffffc020420e:	00003517          	auipc	a0,0x3
ffffffffc0204212:	15a50513          	addi	a0,a0,346 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc0204216:	a78fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020421a:	00003617          	auipc	a2,0x3
ffffffffc020421e:	aae60613          	addi	a2,a2,-1362 # ffffffffc0206cc8 <default_pmm_manager+0x108>
ffffffffc0204222:	06a00593          	li	a1,106
ffffffffc0204226:	00003517          	auipc	a0,0x3
ffffffffc020422a:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc020422e:	a60fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0204232:	00003617          	auipc	a2,0x3
ffffffffc0204236:	9c660613          	addi	a2,a2,-1594 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc020423a:	07200593          	li	a1,114
ffffffffc020423e:	00003517          	auipc	a0,0x3
ffffffffc0204242:	9e250513          	addi	a0,a0,-1566 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc0204246:	a48fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc020424a:	86ae                	mv	a3,a1
ffffffffc020424c:	00003617          	auipc	a2,0x3
ffffffffc0204250:	9ac60613          	addi	a2,a2,-1620 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc0204254:	07200593          	li	a1,114
ffffffffc0204258:	00003517          	auipc	a0,0x3
ffffffffc020425c:	9c850513          	addi	a0,a0,-1592 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc0204260:	a2efc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204264 <dup_mmap_cow>:
 * 返回值：
 *   0   : 成功
 *  -E_NO_MEM : 内存分配失败
 */
int dup_mmap_cow(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0204264:	7139                	addi	sp,sp,-64
ffffffffc0204266:	fc06                	sd	ra,56(sp)
ffffffffc0204268:	f822                	sd	s0,48(sp)
ffffffffc020426a:	f426                	sd	s1,40(sp)
ffffffffc020426c:	f04a                	sd	s2,32(sp)
ffffffffc020426e:	ec4e                	sd	s3,24(sp)
ffffffffc0204270:	e852                	sd	s4,16(sp)
ffffffffc0204272:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0204274:	c52d                	beqz	a0,ffffffffc02042de <dup_mmap_cow+0x7a>
ffffffffc0204276:	892a                	mv	s2,a0
ffffffffc0204278:	84ae                	mv	s1,a1
    
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc020427a:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc020427c:	e595                	bnez	a1,ffffffffc02042a8 <dup_mmap_cow+0x44>
ffffffffc020427e:	a085                	j	ffffffffc02042de <dup_mmap_cow+0x7a>
        {
            return -E_NO_MEM;
        }
        
        // 插入到目标进程的VMA链表
        insert_vma_struct(to, nvma);
ffffffffc0204280:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0204282:	0155b423          	sd	s5,8(a1) # fffffffffffff008 <end+0x3fd24a14>
        vma->vm_end = vm_end;
ffffffffc0204286:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc020428a:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc020428e:	e9cff0ef          	jal	ra,ffffffffc020392a <insert_vma_struct>
        
        // 使用COW方式复制页面映射
        bool share = 0;  // COW中不使用此参数
        if (copy_range_cow(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0204292:	ff043683          	ld	a3,-16(s0)
ffffffffc0204296:	fe843603          	ld	a2,-24(s0)
ffffffffc020429a:	6c8c                	ld	a1,24(s1)
ffffffffc020429c:	01893503          	ld	a0,24(s2)
ffffffffc02042a0:	4701                	li	a4,0
ffffffffc02042a2:	b78ff0ef          	jal	ra,ffffffffc020361a <copy_range_cow>
ffffffffc02042a6:	e105                	bnez	a0,ffffffffc02042c6 <dup_mmap_cow+0x62>
    return listelm->prev;
ffffffffc02042a8:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc02042aa:	02848863          	beq	s1,s0,ffffffffc02042da <dup_mmap_cow+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02042ae:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc02042b2:	fe843a83          	ld	s5,-24(s0)
ffffffffc02042b6:	ff043a03          	ld	s4,-16(s0)
ffffffffc02042ba:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02042be:	a41fd0ef          	jal	ra,ffffffffc0201cfe <kmalloc>
ffffffffc02042c2:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc02042c4:	fd55                	bnez	a0,ffffffffc0204280 <dup_mmap_cow+0x1c>
            return -E_NO_MEM;
ffffffffc02042c6:	5571                	li	a0,-4
            return -E_NO_MEM;
        }
    }
    
    return 0;
ffffffffc02042c8:	70e2                	ld	ra,56(sp)
ffffffffc02042ca:	7442                	ld	s0,48(sp)
ffffffffc02042cc:	74a2                	ld	s1,40(sp)
ffffffffc02042ce:	7902                	ld	s2,32(sp)
ffffffffc02042d0:	69e2                	ld	s3,24(sp)
ffffffffc02042d2:	6a42                	ld	s4,16(sp)
ffffffffc02042d4:	6aa2                	ld	s5,8(sp)
ffffffffc02042d6:	6121                	addi	sp,sp,64
ffffffffc02042d8:	8082                	ret
    return 0;
ffffffffc02042da:	4501                	li	a0,0
ffffffffc02042dc:	b7f5                	j	ffffffffc02042c8 <dup_mmap_cow+0x64>
    assert(to != NULL && from != NULL);
ffffffffc02042de:	00003697          	auipc	a3,0x3
ffffffffc02042e2:	12268693          	addi	a3,a3,290 # ffffffffc0207400 <default_pmm_manager+0x840>
ffffffffc02042e6:	00002617          	auipc	a2,0x2
ffffffffc02042ea:	26a60613          	addi	a2,a2,618 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02042ee:	1fe00593          	li	a1,510
ffffffffc02042f2:	00003517          	auipc	a0,0x3
ffffffffc02042f6:	07650513          	addi	a0,a0,118 # ffffffffc0207368 <default_pmm_manager+0x7a8>
ffffffffc02042fa:	994fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02042fe <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc02042fe:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204300:	9402                	jalr	s0

	jal do_exit
ffffffffc0204302:	712000ef          	jal	ra,ffffffffc0204a14 <do_exit>

ffffffffc0204306 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0204306:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204308:	10800513          	li	a0,264
{
ffffffffc020430c:	e022                	sd	s0,0(sp)
ffffffffc020430e:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204310:	9effd0ef          	jal	ra,ffffffffc0201cfe <kmalloc>
ffffffffc0204314:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0204316:	cd21                	beqz	a0,ffffffffc020436e <alloc_proc+0x68>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->state = PROC_UNINIT;                      // 设置进程为未初始化状态
ffffffffc0204318:	57fd                	li	a5,-1
ffffffffc020431a:	1782                	slli	a5,a5,0x20
ffffffffc020431c:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                                 // 初始化运行次数为0
        proc->kstack = 0;                               // 内核栈地址初始化为0
        proc->need_resched = 0;                         // 不需要调度
        proc->parent = NULL;                            // 没有父进程
        proc->mm = NULL;                                // 未分配内存管理结构
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文
ffffffffc020431e:	07000613          	li	a2,112
ffffffffc0204322:	4581                	li	a1,0
        proc->runs = 0;                                 // 初始化运行次数为0
ffffffffc0204324:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;                               // 内核栈地址初始化为0
ffffffffc0204328:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                         // 不需要调度
ffffffffc020432c:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;                            // 没有父进程
ffffffffc0204330:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                                // 未分配内存管理结构
ffffffffc0204334:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文
ffffffffc0204338:	03050513          	addi	a0,a0,48
ffffffffc020433c:	187010ef          	jal	ra,ffffffffc0205cc2 <memset>
        proc->tf = NULL;                                // 中断帧指针初始化为NULL
        proc->pgdir = boot_pgdir_pa;                    // 使用内核页目录表
ffffffffc0204340:	000d6797          	auipc	a5,0xd6
ffffffffc0204344:	2687b783          	ld	a5,616(a5) # ffffffffc02da5a8 <boot_pgdir_pa>
        proc->tf = NULL;                                // 中断帧指针初始化为NULL
ffffffffc0204348:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;                    // 使用内核页目录表
ffffffffc020434c:	f45c                	sd	a5,168(s0)
        proc->flags = 0;                                // 初始化标志位为0
ffffffffc020434e:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);       // 初始化进程名
ffffffffc0204352:	4641                	li	a2,16
ffffffffc0204354:	4581                	li	a1,0
ffffffffc0204356:	0b440513          	addi	a0,s0,180
ffffffffc020435a:	169010ef          	jal	ra,ffffffffc0205cc2 <memset>
        // LAB5 新增字段初始化
        proc->wait_state = 0;                           // 初始化等待状态
ffffffffc020435e:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;                              // 子进程指针
ffffffffc0204362:	0e043823          	sd	zero,240(s0)
        proc->yptr = NULL;                              // 年幼兄弟进程指针
ffffffffc0204366:	0e043c23          	sd	zero,248(s0)
        proc->optr = NULL;                              // 年长兄弟进程指针
ffffffffc020436a:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc020436e:	60a2                	ld	ra,8(sp)
ffffffffc0204370:	8522                	mv	a0,s0
ffffffffc0204372:	6402                	ld	s0,0(sp)
ffffffffc0204374:	0141                	addi	sp,sp,16
ffffffffc0204376:	8082                	ret

ffffffffc0204378 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0204378:	000d6797          	auipc	a5,0xd6
ffffffffc020437c:	2607b783          	ld	a5,608(a5) # ffffffffc02da5d8 <current>
ffffffffc0204380:	73c8                	ld	a0,160(a5)
ffffffffc0204382:	bf1fc06f          	j	ffffffffc0200f72 <forkrets>

ffffffffc0204386 <user_main>:
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
#else
    KERNEL_EXECVE(exit);
ffffffffc0204386:	000d6797          	auipc	a5,0xd6
ffffffffc020438a:	2527b783          	ld	a5,594(a5) # ffffffffc02da5d8 <current>
ffffffffc020438e:	43cc                	lw	a1,4(a5)
{
ffffffffc0204390:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE(exit);
ffffffffc0204392:	00003617          	auipc	a2,0x3
ffffffffc0204396:	51660613          	addi	a2,a2,1302 # ffffffffc02078a8 <default_pmm_manager+0xce8>
ffffffffc020439a:	00003517          	auipc	a0,0x3
ffffffffc020439e:	51650513          	addi	a0,a0,1302 # ffffffffc02078b0 <default_pmm_manager+0xcf0>
{
ffffffffc02043a2:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE(exit);
ffffffffc02043a4:	df1fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02043a8:	3fe07797          	auipc	a5,0x3fe07
ffffffffc02043ac:	d9878793          	addi	a5,a5,-616 # b140 <_binary_obj___user_exit_out_size>
ffffffffc02043b0:	e43e                	sd	a5,8(sp)
ffffffffc02043b2:	00003517          	auipc	a0,0x3
ffffffffc02043b6:	4f650513          	addi	a0,a0,1270 # ffffffffc02078a8 <default_pmm_manager+0xce8>
ffffffffc02043ba:	00056797          	auipc	a5,0x56
ffffffffc02043be:	e8e78793          	addi	a5,a5,-370 # ffffffffc025a248 <_binary_obj___user_exit_out_start>
ffffffffc02043c2:	f03e                	sd	a5,32(sp)
ffffffffc02043c4:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc02043c6:	e802                	sd	zero,16(sp)
ffffffffc02043c8:	059010ef          	jal	ra,ffffffffc0205c20 <strlen>
ffffffffc02043cc:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc02043ce:	4511                	li	a0,4
ffffffffc02043d0:	55a2                	lw	a1,40(sp)
ffffffffc02043d2:	4662                	lw	a2,24(sp)
ffffffffc02043d4:	5682                	lw	a3,32(sp)
ffffffffc02043d6:	4722                	lw	a4,8(sp)
ffffffffc02043d8:	48a9                	li	a7,10
ffffffffc02043da:	9002                	ebreak
ffffffffc02043dc:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc02043de:	65c2                	ld	a1,16(sp)
ffffffffc02043e0:	00003517          	auipc	a0,0x3
ffffffffc02043e4:	4f850513          	addi	a0,a0,1272 # ffffffffc02078d8 <default_pmm_manager+0xd18>
ffffffffc02043e8:	dadfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
    panic("user_main execve failed.\n");
ffffffffc02043ec:	00003617          	auipc	a2,0x3
ffffffffc02043f0:	4fc60613          	addi	a2,a2,1276 # ffffffffc02078e8 <default_pmm_manager+0xd28>
ffffffffc02043f4:	41700593          	li	a1,1047
ffffffffc02043f8:	00003517          	auipc	a0,0x3
ffffffffc02043fc:	51050513          	addi	a0,a0,1296 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204400:	88efc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204404 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204404:	6d14                	ld	a3,24(a0)
{
ffffffffc0204406:	1141                	addi	sp,sp,-16
ffffffffc0204408:	e406                	sd	ra,8(sp)
ffffffffc020440a:	c02007b7          	lui	a5,0xc0200
ffffffffc020440e:	02f6ee63          	bltu	a3,a5,ffffffffc020444a <put_pgdir+0x46>
ffffffffc0204412:	000d6517          	auipc	a0,0xd6
ffffffffc0204416:	1be53503          	ld	a0,446(a0) # ffffffffc02da5d0 <va_pa_offset>
ffffffffc020441a:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc020441c:	82b1                	srli	a3,a3,0xc
ffffffffc020441e:	000d6797          	auipc	a5,0xd6
ffffffffc0204422:	19a7b783          	ld	a5,410(a5) # ffffffffc02da5b8 <npage>
ffffffffc0204426:	02f6fe63          	bgeu	a3,a5,ffffffffc0204462 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc020442a:	00004517          	auipc	a0,0x4
ffffffffc020442e:	df653503          	ld	a0,-522(a0) # ffffffffc0208220 <nbase>
}
ffffffffc0204432:	60a2                	ld	ra,8(sp)
ffffffffc0204434:	8e89                	sub	a3,a3,a0
ffffffffc0204436:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204438:	000d6517          	auipc	a0,0xd6
ffffffffc020443c:	18853503          	ld	a0,392(a0) # ffffffffc02da5c0 <pages>
ffffffffc0204440:	4585                	li	a1,1
ffffffffc0204442:	9536                	add	a0,a0,a3
}
ffffffffc0204444:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204446:	ad5fd06f          	j	ffffffffc0201f1a <free_pages>
    return pa2page(PADDR(kva));
ffffffffc020444a:	00003617          	auipc	a2,0x3
ffffffffc020444e:	85660613          	addi	a2,a2,-1962 # ffffffffc0206ca0 <default_pmm_manager+0xe0>
ffffffffc0204452:	07800593          	li	a1,120
ffffffffc0204456:	00002517          	auipc	a0,0x2
ffffffffc020445a:	7ca50513          	addi	a0,a0,1994 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc020445e:	830fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204462:	00003617          	auipc	a2,0x3
ffffffffc0204466:	86660613          	addi	a2,a2,-1946 # ffffffffc0206cc8 <default_pmm_manager+0x108>
ffffffffc020446a:	06a00593          	li	a1,106
ffffffffc020446e:	00002517          	auipc	a0,0x2
ffffffffc0204472:	7b250513          	addi	a0,a0,1970 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc0204476:	818fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020447a <setup_pgdir>:
{
ffffffffc020447a:	1101                	addi	sp,sp,-32
ffffffffc020447c:	e426                	sd	s1,8(sp)
ffffffffc020447e:	84aa                	mv	s1,a0
    if ((page = alloc_page()) == NULL)
ffffffffc0204480:	4505                	li	a0,1
{
ffffffffc0204482:	ec06                	sd	ra,24(sp)
ffffffffc0204484:	e822                	sd	s0,16(sp)
    if ((page = alloc_page()) == NULL)
ffffffffc0204486:	a57fd0ef          	jal	ra,ffffffffc0201edc <alloc_pages>
ffffffffc020448a:	c939                	beqz	a0,ffffffffc02044e0 <setup_pgdir+0x66>
    return page - pages + nbase;
ffffffffc020448c:	000d6697          	auipc	a3,0xd6
ffffffffc0204490:	1346b683          	ld	a3,308(a3) # ffffffffc02da5c0 <pages>
ffffffffc0204494:	40d506b3          	sub	a3,a0,a3
ffffffffc0204498:	8699                	srai	a3,a3,0x6
ffffffffc020449a:	00004417          	auipc	s0,0x4
ffffffffc020449e:	d8643403          	ld	s0,-634(s0) # ffffffffc0208220 <nbase>
ffffffffc02044a2:	96a2                	add	a3,a3,s0
    return KADDR(page2pa(page));
ffffffffc02044a4:	00c69793          	slli	a5,a3,0xc
ffffffffc02044a8:	83b1                	srli	a5,a5,0xc
ffffffffc02044aa:	000d6717          	auipc	a4,0xd6
ffffffffc02044ae:	10e73703          	ld	a4,270(a4) # ffffffffc02da5b8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02044b2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02044b4:	02e7f863          	bgeu	a5,a4,ffffffffc02044e4 <setup_pgdir+0x6a>
ffffffffc02044b8:	000d6417          	auipc	s0,0xd6
ffffffffc02044bc:	11843403          	ld	s0,280(s0) # ffffffffc02da5d0 <va_pa_offset>
ffffffffc02044c0:	9436                	add	s0,s0,a3
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02044c2:	6605                	lui	a2,0x1
ffffffffc02044c4:	000d6597          	auipc	a1,0xd6
ffffffffc02044c8:	0ec5b583          	ld	a1,236(a1) # ffffffffc02da5b0 <boot_pgdir_va>
ffffffffc02044cc:	8522                	mv	a0,s0
ffffffffc02044ce:	007010ef          	jal	ra,ffffffffc0205cd4 <memcpy>
    return 0;
ffffffffc02044d2:	4501                	li	a0,0
    mm->pgdir = pgdir;
ffffffffc02044d4:	ec80                	sd	s0,24(s1)
}
ffffffffc02044d6:	60e2                	ld	ra,24(sp)
ffffffffc02044d8:	6442                	ld	s0,16(sp)
ffffffffc02044da:	64a2                	ld	s1,8(sp)
ffffffffc02044dc:	6105                	addi	sp,sp,32
ffffffffc02044de:	8082                	ret
        return -E_NO_MEM;
ffffffffc02044e0:	5571                	li	a0,-4
ffffffffc02044e2:	bfd5                	j	ffffffffc02044d6 <setup_pgdir+0x5c>
ffffffffc02044e4:	00002617          	auipc	a2,0x2
ffffffffc02044e8:	71460613          	addi	a2,a2,1812 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc02044ec:	07200593          	li	a1,114
ffffffffc02044f0:	00002517          	auipc	a0,0x2
ffffffffc02044f4:	73050513          	addi	a0,a0,1840 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc02044f8:	f97fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02044fc <proc_run>:
{
ffffffffc02044fc:	7179                	addi	sp,sp,-48
ffffffffc02044fe:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0204500:	000d6917          	auipc	s2,0xd6
ffffffffc0204504:	0d890913          	addi	s2,s2,216 # ffffffffc02da5d8 <current>
{
ffffffffc0204508:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc020450a:	00093483          	ld	s1,0(s2)
{
ffffffffc020450e:	f406                	sd	ra,40(sp)
ffffffffc0204510:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0204512:	02a48863          	beq	s1,a0,ffffffffc0204542 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204516:	100027f3          	csrr	a5,sstatus
ffffffffc020451a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020451c:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020451e:	ef9d                	bnez	a5,ffffffffc020455c <proc_run+0x60>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0204520:	755c                	ld	a5,168(a0)
ffffffffc0204522:	577d                	li	a4,-1
ffffffffc0204524:	177e                	slli	a4,a4,0x3f
ffffffffc0204526:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0204528:	00a93023          	sd	a0,0(s2)
ffffffffc020452c:	8fd9                	or	a5,a5,a4
ffffffffc020452e:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0204532:	03050593          	addi	a1,a0,48
ffffffffc0204536:	03048513          	addi	a0,s1,48
ffffffffc020453a:	08c010ef          	jal	ra,ffffffffc02055c6 <switch_to>
    if (flag)
ffffffffc020453e:	00099863          	bnez	s3,ffffffffc020454e <proc_run+0x52>
}
ffffffffc0204542:	70a2                	ld	ra,40(sp)
ffffffffc0204544:	7482                	ld	s1,32(sp)
ffffffffc0204546:	6962                	ld	s2,24(sp)
ffffffffc0204548:	69c2                	ld	s3,16(sp)
ffffffffc020454a:	6145                	addi	sp,sp,48
ffffffffc020454c:	8082                	ret
ffffffffc020454e:	70a2                	ld	ra,40(sp)
ffffffffc0204550:	7482                	ld	s1,32(sp)
ffffffffc0204552:	6962                	ld	s2,24(sp)
ffffffffc0204554:	69c2                	ld	s3,16(sp)
ffffffffc0204556:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204558:	c56fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc020455c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020455e:	c56fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204562:	6522                	ld	a0,8(sp)
ffffffffc0204564:	4985                	li	s3,1
ffffffffc0204566:	bf6d                	j	ffffffffc0204520 <proc_run+0x24>

ffffffffc0204568 <do_fork>:
{
ffffffffc0204568:	7159                	addi	sp,sp,-112
ffffffffc020456a:	e8ca                	sd	s2,80(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020456c:	000d6917          	auipc	s2,0xd6
ffffffffc0204570:	08490913          	addi	s2,s2,132 # ffffffffc02da5f0 <nr_process>
ffffffffc0204574:	00092703          	lw	a4,0(s2)
{
ffffffffc0204578:	f486                	sd	ra,104(sp)
ffffffffc020457a:	f0a2                	sd	s0,96(sp)
ffffffffc020457c:	eca6                	sd	s1,88(sp)
ffffffffc020457e:	e4ce                	sd	s3,72(sp)
ffffffffc0204580:	e0d2                	sd	s4,64(sp)
ffffffffc0204582:	fc56                	sd	s5,56(sp)
ffffffffc0204584:	f85a                	sd	s6,48(sp)
ffffffffc0204586:	f45e                	sd	s7,40(sp)
ffffffffc0204588:	f062                	sd	s8,32(sp)
ffffffffc020458a:	ec66                	sd	s9,24(sp)
ffffffffc020458c:	e86a                	sd	s10,16(sp)
ffffffffc020458e:	e46e                	sd	s11,8(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0204590:	6785                	lui	a5,0x1
ffffffffc0204592:	38f75863          	bge	a4,a5,ffffffffc0204922 <do_fork+0x3ba>
ffffffffc0204596:	8a2a                	mv	s4,a0
ffffffffc0204598:	89ae                	mv	s3,a1
ffffffffc020459a:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc020459c:	d6bff0ef          	jal	ra,ffffffffc0204306 <alloc_proc>
ffffffffc02045a0:	84aa                	mv	s1,a0
ffffffffc02045a2:	32050363          	beqz	a0,ffffffffc02048c8 <do_fork+0x360>
    proc->parent = current;
ffffffffc02045a6:	000d6c97          	auipc	s9,0xd6
ffffffffc02045aa:	032c8c93          	addi	s9,s9,50 # ffffffffc02da5d8 <current>
ffffffffc02045ae:	000cb783          	ld	a5,0(s9)
    assert(current->wait_state == 0);
ffffffffc02045b2:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8adc>
    proc->parent = current;
ffffffffc02045b6:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc02045b8:	38071663          	bnez	a4,ffffffffc0204944 <do_fork+0x3dc>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02045bc:	4509                	li	a0,2
ffffffffc02045be:	91ffd0ef          	jal	ra,ffffffffc0201edc <alloc_pages>
    if (page != NULL)
ffffffffc02045c2:	30050063          	beqz	a0,ffffffffc02048c2 <do_fork+0x35a>
    return page - pages + nbase;
ffffffffc02045c6:	000d6a97          	auipc	s5,0xd6
ffffffffc02045ca:	ffaa8a93          	addi	s5,s5,-6 # ffffffffc02da5c0 <pages>
ffffffffc02045ce:	000ab683          	ld	a3,0(s5)
ffffffffc02045d2:	00004b17          	auipc	s6,0x4
ffffffffc02045d6:	c4eb0b13          	addi	s6,s6,-946 # ffffffffc0208220 <nbase>
ffffffffc02045da:	000b3783          	ld	a5,0(s6)
ffffffffc02045de:	40d506b3          	sub	a3,a0,a3
ffffffffc02045e2:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02045e4:	000d6b97          	auipc	s7,0xd6
ffffffffc02045e8:	fd4b8b93          	addi	s7,s7,-44 # ffffffffc02da5b8 <npage>
    return page - pages + nbase;
ffffffffc02045ec:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02045ee:	000bb703          	ld	a4,0(s7)
ffffffffc02045f2:	00c69793          	slli	a5,a3,0xc
ffffffffc02045f6:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02045f8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02045fa:	3ae7f963          	bgeu	a5,a4,ffffffffc02049ac <do_fork+0x444>
ffffffffc02045fe:	000d6c17          	auipc	s8,0xd6
ffffffffc0204602:	fd2c0c13          	addi	s8,s8,-46 # ffffffffc02da5d0 <va_pa_offset>
ffffffffc0204606:	000c3783          	ld	a5,0(s8)
        if (enable_cow) {
ffffffffc020460a:	000d2717          	auipc	a4,0xd2
ffffffffc020460e:	b3672703          	lw	a4,-1226(a4) # ffffffffc02d6140 <enable_cow>
ffffffffc0204612:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204614:	e894                	sd	a3,16(s1)
        if (enable_cow) {
ffffffffc0204616:	1a071663          	bnez	a4,ffffffffc02047c2 <do_fork+0x25a>
            cprintf("[FORK] Using traditional copy to duplicate memory\n");
ffffffffc020461a:	00003517          	auipc	a0,0x3
ffffffffc020461e:	37650513          	addi	a0,a0,886 # ffffffffc0207990 <default_pmm_manager+0xdd0>
ffffffffc0204622:	b73fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204626:	000cb783          	ld	a5,0(s9)
ffffffffc020462a:	0287bd83          	ld	s11,40(a5)
    if (oldmm == NULL)
ffffffffc020462e:	020d8763          	beqz	s11,ffffffffc020465c <do_fork+0xf4>
    if (clone_flags & CLONE_VM)
ffffffffc0204632:	100a7a13          	andi	s4,s4,256
ffffffffc0204636:	280a0f63          	beqz	s4,ffffffffc02048d4 <do_fork+0x36c>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc020463a:	030da783          	lw	a5,48(s11)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020463e:	018db683          	ld	a3,24(s11)
ffffffffc0204642:	c0200737          	lui	a4,0xc0200
ffffffffc0204646:	2785                	addiw	a5,a5,1
ffffffffc0204648:	02fda823          	sw	a5,48(s11)
    proc->mm = mm;
ffffffffc020464c:	03b4b423          	sd	s11,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204650:	30e6ea63          	bltu	a3,a4,ffffffffc0204964 <do_fork+0x3fc>
ffffffffc0204654:	000c3783          	ld	a5,0(s8)
ffffffffc0204658:	8e9d                	sub	a3,a3,a5
ffffffffc020465a:	f4d4                	sd	a3,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020465c:	6898                	ld	a4,16(s1)
ffffffffc020465e:	6789                	lui	a5,0x2
ffffffffc0204660:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7ce8>
ffffffffc0204664:	973e                	add	a4,a4,a5
    *(proc->tf) = *tf;
ffffffffc0204666:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204668:	f0d8                	sd	a4,160(s1)
    *(proc->tf) = *tf;
ffffffffc020466a:	87ba                	mv	a5,a4
ffffffffc020466c:	12040893          	addi	a7,s0,288
ffffffffc0204670:	00063803          	ld	a6,0(a2)
ffffffffc0204674:	6608                	ld	a0,8(a2)
ffffffffc0204676:	6a0c                	ld	a1,16(a2)
ffffffffc0204678:	6e14                	ld	a3,24(a2)
ffffffffc020467a:	0107b023          	sd	a6,0(a5)
ffffffffc020467e:	e788                	sd	a0,8(a5)
ffffffffc0204680:	eb8c                	sd	a1,16(a5)
ffffffffc0204682:	ef94                	sd	a3,24(a5)
ffffffffc0204684:	02060613          	addi	a2,a2,32
ffffffffc0204688:	02078793          	addi	a5,a5,32
ffffffffc020468c:	ff1612e3          	bne	a2,a7,ffffffffc0204670 <do_fork+0x108>
    proc->tf->gpr.a0 = 0;
ffffffffc0204690:	04073823          	sd	zero,80(a4) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204694:	00099363          	bnez	s3,ffffffffc020469a <do_fork+0x132>
ffffffffc0204698:	89ba                	mv	s3,a4
ffffffffc020469a:	01373823          	sd	s3,16(a4)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020469e:	00000797          	auipc	a5,0x0
ffffffffc02046a2:	cda78793          	addi	a5,a5,-806 # ffffffffc0204378 <forkret>
ffffffffc02046a6:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02046a8:	fc98                	sd	a4,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02046aa:	100027f3          	csrr	a5,sstatus
ffffffffc02046ae:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02046b0:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02046b2:	20079d63          	bnez	a5,ffffffffc02048cc <do_fork+0x364>
    if (++last_pid >= MAX_PID)
ffffffffc02046b6:	000d2817          	auipc	a6,0xd2
ffffffffc02046ba:	a8e80813          	addi	a6,a6,-1394 # ffffffffc02d6144 <last_pid.1>
ffffffffc02046be:	00082783          	lw	a5,0(a6)
ffffffffc02046c2:	6709                	lui	a4,0x2
ffffffffc02046c4:	0017851b          	addiw	a0,a5,1
ffffffffc02046c8:	00a82023          	sw	a0,0(a6)
ffffffffc02046cc:	14e55463          	bge	a0,a4,ffffffffc0204814 <do_fork+0x2ac>
    if (last_pid >= next_safe)
ffffffffc02046d0:	000d2317          	auipc	t1,0xd2
ffffffffc02046d4:	a7830313          	addi	t1,t1,-1416 # ffffffffc02d6148 <next_safe.0>
ffffffffc02046d8:	00032783          	lw	a5,0(t1)
ffffffffc02046dc:	000d6417          	auipc	s0,0xd6
ffffffffc02046e0:	e8c40413          	addi	s0,s0,-372 # ffffffffc02da568 <proc_list>
ffffffffc02046e4:	06f54063          	blt	a0,a5,ffffffffc0204744 <do_fork+0x1dc>
    return listelm->next;
ffffffffc02046e8:	000d6417          	auipc	s0,0xd6
ffffffffc02046ec:	e8040413          	addi	s0,s0,-384 # ffffffffc02da568 <proc_list>
ffffffffc02046f0:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc02046f4:	6789                	lui	a5,0x2
ffffffffc02046f6:	00f32023          	sw	a5,0(t1)
ffffffffc02046fa:	86aa                	mv	a3,a0
ffffffffc02046fc:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02046fe:	6e89                	lui	t4,0x2
ffffffffc0204700:	208e0c63          	beq	t3,s0,ffffffffc0204918 <do_fork+0x3b0>
ffffffffc0204704:	88ae                	mv	a7,a1
ffffffffc0204706:	87f2                	mv	a5,t3
ffffffffc0204708:	6609                	lui	a2,0x2
ffffffffc020470a:	a811                	j	ffffffffc020471e <do_fork+0x1b6>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020470c:	00e6d663          	bge	a3,a4,ffffffffc0204718 <do_fork+0x1b0>
ffffffffc0204710:	00c75463          	bge	a4,a2,ffffffffc0204718 <do_fork+0x1b0>
ffffffffc0204714:	863a                	mv	a2,a4
ffffffffc0204716:	4885                	li	a7,1
ffffffffc0204718:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020471a:	00878d63          	beq	a5,s0,ffffffffc0204734 <do_fork+0x1cc>
            if (proc->pid == last_pid)
ffffffffc020471e:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c8c>
ffffffffc0204722:	fed715e3          	bne	a4,a3,ffffffffc020470c <do_fork+0x1a4>
                if (++last_pid >= next_safe)
ffffffffc0204726:	2685                	addiw	a3,a3,1
ffffffffc0204728:	10c6d263          	bge	a3,a2,ffffffffc020482c <do_fork+0x2c4>
ffffffffc020472c:	679c                	ld	a5,8(a5)
ffffffffc020472e:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204730:	fe8797e3          	bne	a5,s0,ffffffffc020471e <do_fork+0x1b6>
ffffffffc0204734:	c581                	beqz	a1,ffffffffc020473c <do_fork+0x1d4>
ffffffffc0204736:	00d82023          	sw	a3,0(a6)
ffffffffc020473a:	8536                	mv	a0,a3
ffffffffc020473c:	00088463          	beqz	a7,ffffffffc0204744 <do_fork+0x1dc>
ffffffffc0204740:	00c32023          	sw	a2,0(t1)
        proc->pid = get_pid();
ffffffffc0204744:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204746:	45a9                	li	a1,10
ffffffffc0204748:	2501                	sext.w	a0,a0
ffffffffc020474a:	0d2010ef          	jal	ra,ffffffffc020581c <hash32>
ffffffffc020474e:	02051793          	slli	a5,a0,0x20
ffffffffc0204752:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204756:	000d2797          	auipc	a5,0xd2
ffffffffc020475a:	e1278793          	addi	a5,a5,-494 # ffffffffc02d6568 <hash_list>
ffffffffc020475e:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204760:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204762:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204764:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc0204768:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020476a:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc020476c:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020476e:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204770:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0204774:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc0204776:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc0204778:	e21c                	sd	a5,0(a2)
ffffffffc020477a:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc020477c:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc020477e:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204780:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204784:	10e4b023          	sd	a4,256(s1)
ffffffffc0204788:	c311                	beqz	a4,ffffffffc020478c <do_fork+0x224>
        proc->optr->yptr = proc;
ffffffffc020478a:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc020478c:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204790:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0204792:	2785                	addiw	a5,a5,1
ffffffffc0204794:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc0204798:	08099763          	bnez	s3,ffffffffc0204826 <do_fork+0x2be>
    wakeup_proc(proc);
ffffffffc020479c:	8526                	mv	a0,s1
ffffffffc020479e:	693000ef          	jal	ra,ffffffffc0205630 <wakeup_proc>
    ret = proc->pid;
ffffffffc02047a2:	40c8                	lw	a0,4(s1)
}
ffffffffc02047a4:	70a6                	ld	ra,104(sp)
ffffffffc02047a6:	7406                	ld	s0,96(sp)
ffffffffc02047a8:	64e6                	ld	s1,88(sp)
ffffffffc02047aa:	6946                	ld	s2,80(sp)
ffffffffc02047ac:	69a6                	ld	s3,72(sp)
ffffffffc02047ae:	6a06                	ld	s4,64(sp)
ffffffffc02047b0:	7ae2                	ld	s5,56(sp)
ffffffffc02047b2:	7b42                	ld	s6,48(sp)
ffffffffc02047b4:	7ba2                	ld	s7,40(sp)
ffffffffc02047b6:	7c02                	ld	s8,32(sp)
ffffffffc02047b8:	6ce2                	ld	s9,24(sp)
ffffffffc02047ba:	6d42                	ld	s10,16(sp)
ffffffffc02047bc:	6da2                	ld	s11,8(sp)
ffffffffc02047be:	6165                	addi	sp,sp,112
ffffffffc02047c0:	8082                	ret
            cprintf("[FORK] Using COW to copy memory\n");
ffffffffc02047c2:	00003517          	auipc	a0,0x3
ffffffffc02047c6:	17e50513          	addi	a0,a0,382 # ffffffffc0207940 <default_pmm_manager+0xd80>
ffffffffc02047ca:	9cbfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02047ce:	000cb783          	ld	a5,0(s9)
ffffffffc02047d2:	0287bd83          	ld	s11,40(a5)
    if (oldmm == NULL)
ffffffffc02047d6:	e80d83e3          	beqz	s11,ffffffffc020465c <do_fork+0xf4>
    if (clone_flags & CLONE_VM)
ffffffffc02047da:	100a7a13          	andi	s4,s4,256
ffffffffc02047de:	040a0c63          	beqz	s4,ffffffffc0204836 <do_fork+0x2ce>
ffffffffc02047e2:	030da783          	lw	a5,48(s11)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02047e6:	018db683          	ld	a3,24(s11)
ffffffffc02047ea:	c0200737          	lui	a4,0xc0200
ffffffffc02047ee:	2785                	addiw	a5,a5,1
ffffffffc02047f0:	02fda823          	sw	a5,48(s11)
    proc->mm = mm;
ffffffffc02047f4:	03b4b423          	sd	s11,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02047f8:	e4e6fee3          	bgeu	a3,a4,ffffffffc0204654 <do_fork+0xec>
ffffffffc02047fc:	00002617          	auipc	a2,0x2
ffffffffc0204800:	4a460613          	addi	a2,a2,1188 # ffffffffc0206ca0 <default_pmm_manager+0xe0>
ffffffffc0204804:	1d200593          	li	a1,466
ffffffffc0204808:	00003517          	auipc	a0,0x3
ffffffffc020480c:	10050513          	addi	a0,a0,256 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204810:	c7ffb0ef          	jal	ra,ffffffffc020048e <__panic>
        last_pid = 1;
ffffffffc0204814:	4785                	li	a5,1
ffffffffc0204816:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020481a:	4505                	li	a0,1
ffffffffc020481c:	000d2317          	auipc	t1,0xd2
ffffffffc0204820:	92c30313          	addi	t1,t1,-1748 # ffffffffc02d6148 <next_safe.0>
ffffffffc0204824:	b5d1                	j	ffffffffc02046e8 <do_fork+0x180>
        intr_enable();
ffffffffc0204826:	988fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020482a:	bf8d                	j	ffffffffc020479c <do_fork+0x234>
                    if (last_pid >= MAX_PID)
ffffffffc020482c:	01d6c363          	blt	a3,t4,ffffffffc0204832 <do_fork+0x2ca>
                        last_pid = 1;
ffffffffc0204830:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204832:	4585                	li	a1,1
ffffffffc0204834:	b5f1                	j	ffffffffc0204700 <do_fork+0x198>
    if ((mm = mm_create()) == NULL)
ffffffffc0204836:	884ff0ef          	jal	ra,ffffffffc02038ba <mm_create>
ffffffffc020483a:	8caa                	mv	s9,a0
ffffffffc020483c:	c939                	beqz	a0,ffffffffc0204892 <do_fork+0x32a>
    if (setup_pgdir(mm) != 0)
ffffffffc020483e:	c3dff0ef          	jal	ra,ffffffffc020447a <setup_pgdir>
ffffffffc0204842:	e529                	bnez	a0,ffffffffc020488c <do_fork+0x324>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204844:	038d8d13          	addi	s10,s11,56
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204848:	4785                	li	a5,1
ffffffffc020484a:	40fd37af          	amoor.d	a5,a5,(s10)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc020484e:	8b85                	andi	a5,a5,1
ffffffffc0204850:	4a05                	li	s4,1
ffffffffc0204852:	c799                	beqz	a5,ffffffffc0204860 <do_fork+0x2f8>
    {
        schedule();
ffffffffc0204854:	65d000ef          	jal	ra,ffffffffc02056b0 <schedule>
ffffffffc0204858:	414d37af          	amoor.d	a5,s4,(s10)
    while (!try_lock(lock))
ffffffffc020485c:	8b85                	andi	a5,a5,1
ffffffffc020485e:	fbfd                	bnez	a5,ffffffffc0204854 <do_fork+0x2ec>
        ret = dup_mmap_cow(mm, oldmm);
ffffffffc0204860:	85ee                	mv	a1,s11
ffffffffc0204862:	8566                	mv	a0,s9
ffffffffc0204864:	a01ff0ef          	jal	ra,ffffffffc0204264 <dup_mmap_cow>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204868:	57f9                	li	a5,-2
ffffffffc020486a:	60fd37af          	amoand.d	a5,a5,(s10)
ffffffffc020486e:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204870:	10078663          	beqz	a5,ffffffffc020497c <do_fork+0x414>
good_mm:
ffffffffc0204874:	8de6                	mv	s11,s9
    if (ret != 0)
ffffffffc0204876:	d535                	beqz	a0,ffffffffc02047e2 <do_fork+0x27a>
    exit_mmap(mm);
ffffffffc0204878:	8566                	mv	a0,s9
ffffffffc020487a:	b1cff0ef          	jal	ra,ffffffffc0203b96 <exit_mmap>
    put_pgdir(mm);
ffffffffc020487e:	8566                	mv	a0,s9
ffffffffc0204880:	b85ff0ef          	jal	ra,ffffffffc0204404 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204884:	8566                	mv	a0,s9
ffffffffc0204886:	974ff0ef          	jal	ra,ffffffffc02039fa <mm_destroy>
ffffffffc020488a:	a021                	j	ffffffffc0204892 <do_fork+0x32a>
ffffffffc020488c:	8566                	mv	a0,s9
ffffffffc020488e:	96cff0ef          	jal	ra,ffffffffc02039fa <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204892:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0204894:	c02007b7          	lui	a5,0xc0200
ffffffffc0204898:	0ef6ee63          	bltu	a3,a5,ffffffffc0204994 <do_fork+0x42c>
ffffffffc020489c:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc02048a0:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02048a4:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02048a8:	83b1                	srli	a5,a5,0xc
ffffffffc02048aa:	08e7f163          	bgeu	a5,a4,ffffffffc020492c <do_fork+0x3c4>
    return &pages[PPN(pa) - nbase];
ffffffffc02048ae:	000b3703          	ld	a4,0(s6)
ffffffffc02048b2:	000ab503          	ld	a0,0(s5)
ffffffffc02048b6:	4589                	li	a1,2
ffffffffc02048b8:	8f99                	sub	a5,a5,a4
ffffffffc02048ba:	079a                	slli	a5,a5,0x6
ffffffffc02048bc:	953e                	add	a0,a0,a5
ffffffffc02048be:	e5cfd0ef          	jal	ra,ffffffffc0201f1a <free_pages>
    kfree(proc);
ffffffffc02048c2:	8526                	mv	a0,s1
ffffffffc02048c4:	ceafd0ef          	jal	ra,ffffffffc0201dae <kfree>
    ret = -E_NO_MEM;
ffffffffc02048c8:	5571                	li	a0,-4
    return ret;
ffffffffc02048ca:	bde9                	j	ffffffffc02047a4 <do_fork+0x23c>
        intr_disable();
ffffffffc02048cc:	8e8fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc02048d0:	4985                	li	s3,1
ffffffffc02048d2:	b3d5                	j	ffffffffc02046b6 <do_fork+0x14e>
    if ((mm = mm_create()) == NULL)
ffffffffc02048d4:	fe7fe0ef          	jal	ra,ffffffffc02038ba <mm_create>
ffffffffc02048d8:	8caa                	mv	s9,a0
ffffffffc02048da:	dd45                	beqz	a0,ffffffffc0204892 <do_fork+0x32a>
    if (setup_pgdir(mm) != 0)
ffffffffc02048dc:	b9fff0ef          	jal	ra,ffffffffc020447a <setup_pgdir>
ffffffffc02048e0:	f555                	bnez	a0,ffffffffc020488c <do_fork+0x324>
ffffffffc02048e2:	038d8d13          	addi	s10,s11,56
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02048e6:	4785                	li	a5,1
ffffffffc02048e8:	40fd37af          	amoor.d	a5,a5,(s10)
    while (!try_lock(lock))
ffffffffc02048ec:	8b85                	andi	a5,a5,1
ffffffffc02048ee:	4a05                	li	s4,1
ffffffffc02048f0:	c799                	beqz	a5,ffffffffc02048fe <do_fork+0x396>
        schedule();
ffffffffc02048f2:	5bf000ef          	jal	ra,ffffffffc02056b0 <schedule>
ffffffffc02048f6:	414d37af          	amoor.d	a5,s4,(s10)
    while (!try_lock(lock))
ffffffffc02048fa:	8b85                	andi	a5,a5,1
ffffffffc02048fc:	fbfd                	bnez	a5,ffffffffc02048f2 <do_fork+0x38a>
        ret = dup_mmap(mm, oldmm);
ffffffffc02048fe:	85ee                	mv	a1,s11
ffffffffc0204900:	8566                	mv	a0,s9
ffffffffc0204902:	9faff0ef          	jal	ra,ffffffffc0203afc <dup_mmap>
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204906:	57f9                	li	a5,-2
ffffffffc0204908:	60fd37af          	amoand.d	a5,a5,(s10)
ffffffffc020490c:	8b85                	andi	a5,a5,1
    if (!test_and_clear_bit(0, lock))
ffffffffc020490e:	c7bd                	beqz	a5,ffffffffc020497c <do_fork+0x414>
good_mm:
ffffffffc0204910:	8de6                	mv	s11,s9
    if (ret != 0)
ffffffffc0204912:	d20504e3          	beqz	a0,ffffffffc020463a <do_fork+0xd2>
ffffffffc0204916:	b78d                	j	ffffffffc0204878 <do_fork+0x310>
ffffffffc0204918:	c599                	beqz	a1,ffffffffc0204926 <do_fork+0x3be>
ffffffffc020491a:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc020491e:	8536                	mv	a0,a3
ffffffffc0204920:	b515                	j	ffffffffc0204744 <do_fork+0x1dc>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204922:	556d                	li	a0,-5
ffffffffc0204924:	b541                	j	ffffffffc02047a4 <do_fork+0x23c>
    return last_pid;
ffffffffc0204926:	00082503          	lw	a0,0(a6)
ffffffffc020492a:	bd29                	j	ffffffffc0204744 <do_fork+0x1dc>
        panic("pa2page called with invalid pa");
ffffffffc020492c:	00002617          	auipc	a2,0x2
ffffffffc0204930:	39c60613          	addi	a2,a2,924 # ffffffffc0206cc8 <default_pmm_manager+0x108>
ffffffffc0204934:	06a00593          	li	a1,106
ffffffffc0204938:	00002517          	auipc	a0,0x2
ffffffffc020493c:	2e850513          	addi	a0,a0,744 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc0204940:	b4ffb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(current->wait_state == 0);
ffffffffc0204944:	00003697          	auipc	a3,0x3
ffffffffc0204948:	fdc68693          	addi	a3,a3,-36 # ffffffffc0207920 <default_pmm_manager+0xd60>
ffffffffc020494c:	00002617          	auipc	a2,0x2
ffffffffc0204950:	c0460613          	addi	a2,a2,-1020 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0204954:	22700593          	li	a1,551
ffffffffc0204958:	00003517          	auipc	a0,0x3
ffffffffc020495c:	fb050513          	addi	a0,a0,-80 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204960:	b2ffb0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204964:	00002617          	auipc	a2,0x2
ffffffffc0204968:	33c60613          	addi	a2,a2,828 # ffffffffc0206ca0 <default_pmm_manager+0xe0>
ffffffffc020496c:	19600593          	li	a1,406
ffffffffc0204970:	00003517          	auipc	a0,0x3
ffffffffc0204974:	f9850513          	addi	a0,a0,-104 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204978:	b17fb0ef          	jal	ra,ffffffffc020048e <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc020497c:	00003617          	auipc	a2,0x3
ffffffffc0204980:	fec60613          	addi	a2,a2,-20 # ffffffffc0207968 <default_pmm_manager+0xda8>
ffffffffc0204984:	03f00593          	li	a1,63
ffffffffc0204988:	00003517          	auipc	a0,0x3
ffffffffc020498c:	ff050513          	addi	a0,a0,-16 # ffffffffc0207978 <default_pmm_manager+0xdb8>
ffffffffc0204990:	afffb0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204994:	00002617          	auipc	a2,0x2
ffffffffc0204998:	30c60613          	addi	a2,a2,780 # ffffffffc0206ca0 <default_pmm_manager+0xe0>
ffffffffc020499c:	07800593          	li	a1,120
ffffffffc02049a0:	00002517          	auipc	a0,0x2
ffffffffc02049a4:	28050513          	addi	a0,a0,640 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc02049a8:	ae7fb0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02049ac:	00002617          	auipc	a2,0x2
ffffffffc02049b0:	24c60613          	addi	a2,a2,588 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc02049b4:	07200593          	li	a1,114
ffffffffc02049b8:	00002517          	auipc	a0,0x2
ffffffffc02049bc:	26850513          	addi	a0,a0,616 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc02049c0:	acffb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02049c4 <kernel_thread>:
{
ffffffffc02049c4:	7129                	addi	sp,sp,-320
ffffffffc02049c6:	fa22                	sd	s0,304(sp)
ffffffffc02049c8:	f626                	sd	s1,296(sp)
ffffffffc02049ca:	f24a                	sd	s2,288(sp)
ffffffffc02049cc:	84ae                	mv	s1,a1
ffffffffc02049ce:	892a                	mv	s2,a0
ffffffffc02049d0:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02049d2:	4581                	li	a1,0
ffffffffc02049d4:	12000613          	li	a2,288
ffffffffc02049d8:	850a                	mv	a0,sp
{
ffffffffc02049da:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02049dc:	2e6010ef          	jal	ra,ffffffffc0205cc2 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02049e0:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02049e2:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02049e4:	100027f3          	csrr	a5,sstatus
ffffffffc02049e8:	edd7f793          	andi	a5,a5,-291
ffffffffc02049ec:	1207e793          	ori	a5,a5,288
ffffffffc02049f0:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02049f2:	860a                	mv	a2,sp
ffffffffc02049f4:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02049f8:	00000797          	auipc	a5,0x0
ffffffffc02049fc:	90678793          	addi	a5,a5,-1786 # ffffffffc02042fe <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204a00:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204a02:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204a04:	b65ff0ef          	jal	ra,ffffffffc0204568 <do_fork>
}
ffffffffc0204a08:	70f2                	ld	ra,312(sp)
ffffffffc0204a0a:	7452                	ld	s0,304(sp)
ffffffffc0204a0c:	74b2                	ld	s1,296(sp)
ffffffffc0204a0e:	7912                	ld	s2,288(sp)
ffffffffc0204a10:	6131                	addi	sp,sp,320
ffffffffc0204a12:	8082                	ret

ffffffffc0204a14 <do_exit>:
{
ffffffffc0204a14:	7179                	addi	sp,sp,-48
ffffffffc0204a16:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204a18:	000d6417          	auipc	s0,0xd6
ffffffffc0204a1c:	bc040413          	addi	s0,s0,-1088 # ffffffffc02da5d8 <current>
ffffffffc0204a20:	601c                	ld	a5,0(s0)
{
ffffffffc0204a22:	f406                	sd	ra,40(sp)
ffffffffc0204a24:	ec26                	sd	s1,24(sp)
ffffffffc0204a26:	e84a                	sd	s2,16(sp)
ffffffffc0204a28:	e44e                	sd	s3,8(sp)
ffffffffc0204a2a:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc0204a2c:	000d6717          	auipc	a4,0xd6
ffffffffc0204a30:	bb473703          	ld	a4,-1100(a4) # ffffffffc02da5e0 <idleproc>
ffffffffc0204a34:	0ce78c63          	beq	a5,a4,ffffffffc0204b0c <do_exit+0xf8>
    if (current == initproc)
ffffffffc0204a38:	000d6497          	auipc	s1,0xd6
ffffffffc0204a3c:	bb048493          	addi	s1,s1,-1104 # ffffffffc02da5e8 <initproc>
ffffffffc0204a40:	6098                	ld	a4,0(s1)
ffffffffc0204a42:	0ee78b63          	beq	a5,a4,ffffffffc0204b38 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc0204a46:	0287b983          	ld	s3,40(a5)
ffffffffc0204a4a:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc0204a4c:	02098663          	beqz	s3,ffffffffc0204a78 <do_exit+0x64>
ffffffffc0204a50:	000d6797          	auipc	a5,0xd6
ffffffffc0204a54:	b587b783          	ld	a5,-1192(a5) # ffffffffc02da5a8 <boot_pgdir_pa>
ffffffffc0204a58:	577d                	li	a4,-1
ffffffffc0204a5a:	177e                	slli	a4,a4,0x3f
ffffffffc0204a5c:	83b1                	srli	a5,a5,0xc
ffffffffc0204a5e:	8fd9                	or	a5,a5,a4
ffffffffc0204a60:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204a64:	0309a783          	lw	a5,48(s3)
ffffffffc0204a68:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204a6c:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204a70:	cb55                	beqz	a4,ffffffffc0204b24 <do_exit+0x110>
        current->mm = NULL;
ffffffffc0204a72:	601c                	ld	a5,0(s0)
ffffffffc0204a74:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204a78:	601c                	ld	a5,0(s0)
ffffffffc0204a7a:	470d                	li	a4,3
ffffffffc0204a7c:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204a7e:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204a82:	100027f3          	csrr	a5,sstatus
ffffffffc0204a86:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204a88:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204a8a:	e3f9                	bnez	a5,ffffffffc0204b50 <do_exit+0x13c>
        proc = current->parent;
ffffffffc0204a8c:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204a8e:	800007b7          	lui	a5,0x80000
ffffffffc0204a92:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204a94:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204a96:	0ec52703          	lw	a4,236(a0)
ffffffffc0204a9a:	0af70f63          	beq	a4,a5,ffffffffc0204b58 <do_exit+0x144>
        while (current->cptr != NULL)
ffffffffc0204a9e:	6018                	ld	a4,0(s0)
ffffffffc0204aa0:	7b7c                	ld	a5,240(a4)
ffffffffc0204aa2:	c3a1                	beqz	a5,ffffffffc0204ae2 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204aa4:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204aa8:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204aaa:	0985                	addi	s3,s3,1
ffffffffc0204aac:	a021                	j	ffffffffc0204ab4 <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204aae:	6018                	ld	a4,0(s0)
ffffffffc0204ab0:	7b7c                	ld	a5,240(a4)
ffffffffc0204ab2:	cb85                	beqz	a5,ffffffffc0204ae2 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc0204ab4:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_cowtest_out_size+0xffffffff7fff0410>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204ab8:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204aba:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204abc:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204abe:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204ac2:	10e7b023          	sd	a4,256(a5)
ffffffffc0204ac6:	c311                	beqz	a4,ffffffffc0204aca <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc0204ac8:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204aca:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204acc:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204ace:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204ad0:	fd271fe3          	bne	a4,s2,ffffffffc0204aae <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204ad4:	0ec52783          	lw	a5,236(a0)
ffffffffc0204ad8:	fd379be3          	bne	a5,s3,ffffffffc0204aae <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0204adc:	355000ef          	jal	ra,ffffffffc0205630 <wakeup_proc>
ffffffffc0204ae0:	b7f9                	j	ffffffffc0204aae <do_exit+0x9a>
    if (flag)
ffffffffc0204ae2:	020a1263          	bnez	s4,ffffffffc0204b06 <do_exit+0xf2>
    schedule();
ffffffffc0204ae6:	3cb000ef          	jal	ra,ffffffffc02056b0 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204aea:	601c                	ld	a5,0(s0)
ffffffffc0204aec:	00003617          	auipc	a2,0x3
ffffffffc0204af0:	efc60613          	addi	a2,a2,-260 # ffffffffc02079e8 <default_pmm_manager+0xe28>
ffffffffc0204af4:	29800593          	li	a1,664
ffffffffc0204af8:	43d4                	lw	a3,4(a5)
ffffffffc0204afa:	00003517          	auipc	a0,0x3
ffffffffc0204afe:	e0e50513          	addi	a0,a0,-498 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204b02:	98dfb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc0204b06:	ea9fb0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204b0a:	bff1                	j	ffffffffc0204ae6 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0204b0c:	00003617          	auipc	a2,0x3
ffffffffc0204b10:	ebc60613          	addi	a2,a2,-324 # ffffffffc02079c8 <default_pmm_manager+0xe08>
ffffffffc0204b14:	26400593          	li	a1,612
ffffffffc0204b18:	00003517          	auipc	a0,0x3
ffffffffc0204b1c:	df050513          	addi	a0,a0,-528 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204b20:	96ffb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc0204b24:	854e                	mv	a0,s3
ffffffffc0204b26:	870ff0ef          	jal	ra,ffffffffc0203b96 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204b2a:	854e                	mv	a0,s3
ffffffffc0204b2c:	8d9ff0ef          	jal	ra,ffffffffc0204404 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204b30:	854e                	mv	a0,s3
ffffffffc0204b32:	ec9fe0ef          	jal	ra,ffffffffc02039fa <mm_destroy>
ffffffffc0204b36:	bf35                	j	ffffffffc0204a72 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0204b38:	00003617          	auipc	a2,0x3
ffffffffc0204b3c:	ea060613          	addi	a2,a2,-352 # ffffffffc02079d8 <default_pmm_manager+0xe18>
ffffffffc0204b40:	26800593          	li	a1,616
ffffffffc0204b44:	00003517          	auipc	a0,0x3
ffffffffc0204b48:	dc450513          	addi	a0,a0,-572 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204b4c:	943fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc0204b50:	e65fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204b54:	4a05                	li	s4,1
ffffffffc0204b56:	bf1d                	j	ffffffffc0204a8c <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0204b58:	2d9000ef          	jal	ra,ffffffffc0205630 <wakeup_proc>
ffffffffc0204b5c:	b789                	j	ffffffffc0204a9e <do_exit+0x8a>

ffffffffc0204b5e <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204b5e:	715d                	addi	sp,sp,-80
ffffffffc0204b60:	f84a                	sd	s2,48(sp)
ffffffffc0204b62:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0204b64:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc0204b68:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204b6a:	fc26                	sd	s1,56(sp)
ffffffffc0204b6c:	f052                	sd	s4,32(sp)
ffffffffc0204b6e:	ec56                	sd	s5,24(sp)
ffffffffc0204b70:	e85a                	sd	s6,16(sp)
ffffffffc0204b72:	e45e                	sd	s7,8(sp)
ffffffffc0204b74:	e486                	sd	ra,72(sp)
ffffffffc0204b76:	e0a2                	sd	s0,64(sp)
ffffffffc0204b78:	84aa                	mv	s1,a0
ffffffffc0204b7a:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204b7c:	000d6b97          	auipc	s7,0xd6
ffffffffc0204b80:	a5cb8b93          	addi	s7,s7,-1444 # ffffffffc02da5d8 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204b84:	00050b1b          	sext.w	s6,a0
ffffffffc0204b88:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204b8c:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204b8e:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204b90:	ccbd                	beqz	s1,ffffffffc0204c0e <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204b92:	0359e863          	bltu	s3,s5,ffffffffc0204bc2 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204b96:	45a9                	li	a1,10
ffffffffc0204b98:	855a                	mv	a0,s6
ffffffffc0204b9a:	483000ef          	jal	ra,ffffffffc020581c <hash32>
ffffffffc0204b9e:	02051793          	slli	a5,a0,0x20
ffffffffc0204ba2:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204ba6:	000d2797          	auipc	a5,0xd2
ffffffffc0204baa:	9c278793          	addi	a5,a5,-1598 # ffffffffc02d6568 <hash_list>
ffffffffc0204bae:	953e                	add	a0,a0,a5
ffffffffc0204bb0:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204bb2:	a029                	j	ffffffffc0204bbc <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204bb4:	f2c42783          	lw	a5,-212(s0)
ffffffffc0204bb8:	02978163          	beq	a5,s1,ffffffffc0204bda <do_wait.part.0+0x7c>
    return listelm->next;
ffffffffc0204bbc:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204bbe:	fe851be3          	bne	a0,s0,ffffffffc0204bb4 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0204bc2:	5579                	li	a0,-2
}
ffffffffc0204bc4:	60a6                	ld	ra,72(sp)
ffffffffc0204bc6:	6406                	ld	s0,64(sp)
ffffffffc0204bc8:	74e2                	ld	s1,56(sp)
ffffffffc0204bca:	7942                	ld	s2,48(sp)
ffffffffc0204bcc:	79a2                	ld	s3,40(sp)
ffffffffc0204bce:	7a02                	ld	s4,32(sp)
ffffffffc0204bd0:	6ae2                	ld	s5,24(sp)
ffffffffc0204bd2:	6b42                	ld	s6,16(sp)
ffffffffc0204bd4:	6ba2                	ld	s7,8(sp)
ffffffffc0204bd6:	6161                	addi	sp,sp,80
ffffffffc0204bd8:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204bda:	000bb683          	ld	a3,0(s7)
ffffffffc0204bde:	f4843783          	ld	a5,-184(s0)
ffffffffc0204be2:	fed790e3          	bne	a5,a3,ffffffffc0204bc2 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204be6:	f2842703          	lw	a4,-216(s0)
ffffffffc0204bea:	478d                	li	a5,3
ffffffffc0204bec:	0ef70b63          	beq	a4,a5,ffffffffc0204ce2 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0204bf0:	4785                	li	a5,1
ffffffffc0204bf2:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc0204bf4:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc0204bf8:	2b9000ef          	jal	ra,ffffffffc02056b0 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204bfc:	000bb783          	ld	a5,0(s7)
ffffffffc0204c00:	0b07a783          	lw	a5,176(a5)
ffffffffc0204c04:	8b85                	andi	a5,a5,1
ffffffffc0204c06:	d7c9                	beqz	a5,ffffffffc0204b90 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0204c08:	555d                	li	a0,-9
ffffffffc0204c0a:	e0bff0ef          	jal	ra,ffffffffc0204a14 <do_exit>
        proc = current->cptr;
ffffffffc0204c0e:	000bb683          	ld	a3,0(s7)
ffffffffc0204c12:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204c14:	d45d                	beqz	s0,ffffffffc0204bc2 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204c16:	470d                	li	a4,3
ffffffffc0204c18:	a021                	j	ffffffffc0204c20 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204c1a:	10043403          	ld	s0,256(s0)
ffffffffc0204c1e:	d869                	beqz	s0,ffffffffc0204bf0 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204c20:	401c                	lw	a5,0(s0)
ffffffffc0204c22:	fee79ce3          	bne	a5,a4,ffffffffc0204c1a <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc0204c26:	000d6797          	auipc	a5,0xd6
ffffffffc0204c2a:	9ba7b783          	ld	a5,-1606(a5) # ffffffffc02da5e0 <idleproc>
ffffffffc0204c2e:	0c878963          	beq	a5,s0,ffffffffc0204d00 <do_wait.part.0+0x1a2>
ffffffffc0204c32:	000d6797          	auipc	a5,0xd6
ffffffffc0204c36:	9b67b783          	ld	a5,-1610(a5) # ffffffffc02da5e8 <initproc>
ffffffffc0204c3a:	0cf40363          	beq	s0,a5,ffffffffc0204d00 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204c3e:	000a0663          	beqz	s4,ffffffffc0204c4a <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204c42:	0e842783          	lw	a5,232(s0)
ffffffffc0204c46:	00fa2023          	sw	a5,0(s4)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204c4a:	100027f3          	csrr	a5,sstatus
ffffffffc0204c4e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204c50:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204c52:	e7c1                	bnez	a5,ffffffffc0204cda <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204c54:	6c70                	ld	a2,216(s0)
ffffffffc0204c56:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc0204c58:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204c5c:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204c5e:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204c60:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204c62:	6470                	ld	a2,200(s0)
ffffffffc0204c64:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204c66:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204c68:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204c6a:	c319                	beqz	a4,ffffffffc0204c70 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204c6c:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204c6e:	7c7c                	ld	a5,248(s0)
ffffffffc0204c70:	c3b5                	beqz	a5,ffffffffc0204cd4 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204c72:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204c76:	000d6717          	auipc	a4,0xd6
ffffffffc0204c7a:	97a70713          	addi	a4,a4,-1670 # ffffffffc02da5f0 <nr_process>
ffffffffc0204c7e:	431c                	lw	a5,0(a4)
ffffffffc0204c80:	37fd                	addiw	a5,a5,-1
ffffffffc0204c82:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204c84:	e5a9                	bnez	a1,ffffffffc0204cce <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204c86:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204c88:	c02007b7          	lui	a5,0xc0200
ffffffffc0204c8c:	04f6ee63          	bltu	a3,a5,ffffffffc0204ce8 <do_wait.part.0+0x18a>
ffffffffc0204c90:	000d6797          	auipc	a5,0xd6
ffffffffc0204c94:	9407b783          	ld	a5,-1728(a5) # ffffffffc02da5d0 <va_pa_offset>
ffffffffc0204c98:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204c9a:	82b1                	srli	a3,a3,0xc
ffffffffc0204c9c:	000d6797          	auipc	a5,0xd6
ffffffffc0204ca0:	91c7b783          	ld	a5,-1764(a5) # ffffffffc02da5b8 <npage>
ffffffffc0204ca4:	06f6fa63          	bgeu	a3,a5,ffffffffc0204d18 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc0204ca8:	00003517          	auipc	a0,0x3
ffffffffc0204cac:	57853503          	ld	a0,1400(a0) # ffffffffc0208220 <nbase>
ffffffffc0204cb0:	8e89                	sub	a3,a3,a0
ffffffffc0204cb2:	069a                	slli	a3,a3,0x6
ffffffffc0204cb4:	000d6517          	auipc	a0,0xd6
ffffffffc0204cb8:	90c53503          	ld	a0,-1780(a0) # ffffffffc02da5c0 <pages>
ffffffffc0204cbc:	9536                	add	a0,a0,a3
ffffffffc0204cbe:	4589                	li	a1,2
ffffffffc0204cc0:	a5afd0ef          	jal	ra,ffffffffc0201f1a <free_pages>
    kfree(proc);
ffffffffc0204cc4:	8522                	mv	a0,s0
ffffffffc0204cc6:	8e8fd0ef          	jal	ra,ffffffffc0201dae <kfree>
    return 0;
ffffffffc0204cca:	4501                	li	a0,0
ffffffffc0204ccc:	bde5                	j	ffffffffc0204bc4 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204cce:	ce1fb0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204cd2:	bf55                	j	ffffffffc0204c86 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204cd4:	701c                	ld	a5,32(s0)
ffffffffc0204cd6:	fbf8                	sd	a4,240(a5)
ffffffffc0204cd8:	bf79                	j	ffffffffc0204c76 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0204cda:	cdbfb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204cde:	4585                	li	a1,1
ffffffffc0204ce0:	bf95                	j	ffffffffc0204c54 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204ce2:	f2840413          	addi	s0,s0,-216
ffffffffc0204ce6:	b781                	j	ffffffffc0204c26 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0204ce8:	00002617          	auipc	a2,0x2
ffffffffc0204cec:	fb860613          	addi	a2,a2,-72 # ffffffffc0206ca0 <default_pmm_manager+0xe0>
ffffffffc0204cf0:	07800593          	li	a1,120
ffffffffc0204cf4:	00002517          	auipc	a0,0x2
ffffffffc0204cf8:	f2c50513          	addi	a0,a0,-212 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc0204cfc:	f92fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0204d00:	00003617          	auipc	a2,0x3
ffffffffc0204d04:	d0860613          	addi	a2,a2,-760 # ffffffffc0207a08 <default_pmm_manager+0xe48>
ffffffffc0204d08:	3bf00593          	li	a1,959
ffffffffc0204d0c:	00003517          	auipc	a0,0x3
ffffffffc0204d10:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204d14:	f7afb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204d18:	00002617          	auipc	a2,0x2
ffffffffc0204d1c:	fb060613          	addi	a2,a2,-80 # ffffffffc0206cc8 <default_pmm_manager+0x108>
ffffffffc0204d20:	06a00593          	li	a1,106
ffffffffc0204d24:	00002517          	auipc	a0,0x2
ffffffffc0204d28:	efc50513          	addi	a0,a0,-260 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc0204d2c:	f62fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204d30 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204d30:	1141                	addi	sp,sp,-16
ffffffffc0204d32:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204d34:	a26fd0ef          	jal	ra,ffffffffc0201f5a <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0204d38:	fc3fc0ef          	jal	ra,ffffffffc0201cfa <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204d3c:	4601                	li	a2,0
ffffffffc0204d3e:	4581                	li	a1,0
ffffffffc0204d40:	fffff517          	auipc	a0,0xfffff
ffffffffc0204d44:	64650513          	addi	a0,a0,1606 # ffffffffc0204386 <user_main>
ffffffffc0204d48:	c7dff0ef          	jal	ra,ffffffffc02049c4 <kernel_thread>
    if (pid <= 0)
ffffffffc0204d4c:	00a04563          	bgtz	a0,ffffffffc0204d56 <init_main+0x26>
ffffffffc0204d50:	a071                	j	ffffffffc0204ddc <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204d52:	15f000ef          	jal	ra,ffffffffc02056b0 <schedule>
    if (code_store != NULL)
ffffffffc0204d56:	4581                	li	a1,0
ffffffffc0204d58:	4501                	li	a0,0
ffffffffc0204d5a:	e05ff0ef          	jal	ra,ffffffffc0204b5e <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204d5e:	d975                	beqz	a0,ffffffffc0204d52 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204d60:	00003517          	auipc	a0,0x3
ffffffffc0204d64:	ce850513          	addi	a0,a0,-792 # ffffffffc0207a48 <default_pmm_manager+0xe88>
ffffffffc0204d68:	c2cfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204d6c:	000d6797          	auipc	a5,0xd6
ffffffffc0204d70:	87c7b783          	ld	a5,-1924(a5) # ffffffffc02da5e8 <initproc>
ffffffffc0204d74:	7bf8                	ld	a4,240(a5)
ffffffffc0204d76:	e339                	bnez	a4,ffffffffc0204dbc <init_main+0x8c>
ffffffffc0204d78:	7ff8                	ld	a4,248(a5)
ffffffffc0204d7a:	e329                	bnez	a4,ffffffffc0204dbc <init_main+0x8c>
ffffffffc0204d7c:	1007b703          	ld	a4,256(a5)
ffffffffc0204d80:	ef15                	bnez	a4,ffffffffc0204dbc <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204d82:	000d6697          	auipc	a3,0xd6
ffffffffc0204d86:	86e6a683          	lw	a3,-1938(a3) # ffffffffc02da5f0 <nr_process>
ffffffffc0204d8a:	4709                	li	a4,2
ffffffffc0204d8c:	0ae69463          	bne	a3,a4,ffffffffc0204e34 <init_main+0x104>
    return listelm->next;
ffffffffc0204d90:	000d5697          	auipc	a3,0xd5
ffffffffc0204d94:	7d868693          	addi	a3,a3,2008 # ffffffffc02da568 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204d98:	6698                	ld	a4,8(a3)
ffffffffc0204d9a:	0c878793          	addi	a5,a5,200
ffffffffc0204d9e:	06f71b63          	bne	a4,a5,ffffffffc0204e14 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204da2:	629c                	ld	a5,0(a3)
ffffffffc0204da4:	04f71863          	bne	a4,a5,ffffffffc0204df4 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204da8:	00003517          	auipc	a0,0x3
ffffffffc0204dac:	d8850513          	addi	a0,a0,-632 # ffffffffc0207b30 <default_pmm_manager+0xf70>
ffffffffc0204db0:	be4fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0204db4:	60a2                	ld	ra,8(sp)
ffffffffc0204db6:	4501                	li	a0,0
ffffffffc0204db8:	0141                	addi	sp,sp,16
ffffffffc0204dba:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204dbc:	00003697          	auipc	a3,0x3
ffffffffc0204dc0:	cb468693          	addi	a3,a3,-844 # ffffffffc0207a70 <default_pmm_manager+0xeb0>
ffffffffc0204dc4:	00001617          	auipc	a2,0x1
ffffffffc0204dc8:	78c60613          	addi	a2,a2,1932 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0204dcc:	42d00593          	li	a1,1069
ffffffffc0204dd0:	00003517          	auipc	a0,0x3
ffffffffc0204dd4:	b3850513          	addi	a0,a0,-1224 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204dd8:	eb6fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204ddc:	00003617          	auipc	a2,0x3
ffffffffc0204de0:	c4c60613          	addi	a2,a2,-948 # ffffffffc0207a28 <default_pmm_manager+0xe68>
ffffffffc0204de4:	42400593          	li	a1,1060
ffffffffc0204de8:	00003517          	auipc	a0,0x3
ffffffffc0204dec:	b2050513          	addi	a0,a0,-1248 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204df0:	e9efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204df4:	00003697          	auipc	a3,0x3
ffffffffc0204df8:	d0c68693          	addi	a3,a3,-756 # ffffffffc0207b00 <default_pmm_manager+0xf40>
ffffffffc0204dfc:	00001617          	auipc	a2,0x1
ffffffffc0204e00:	75460613          	addi	a2,a2,1876 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0204e04:	43000593          	li	a1,1072
ffffffffc0204e08:	00003517          	auipc	a0,0x3
ffffffffc0204e0c:	b0050513          	addi	a0,a0,-1280 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204e10:	e7efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204e14:	00003697          	auipc	a3,0x3
ffffffffc0204e18:	cbc68693          	addi	a3,a3,-836 # ffffffffc0207ad0 <default_pmm_manager+0xf10>
ffffffffc0204e1c:	00001617          	auipc	a2,0x1
ffffffffc0204e20:	73460613          	addi	a2,a2,1844 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0204e24:	42f00593          	li	a1,1071
ffffffffc0204e28:	00003517          	auipc	a0,0x3
ffffffffc0204e2c:	ae050513          	addi	a0,a0,-1312 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204e30:	e5efb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc0204e34:	00003697          	auipc	a3,0x3
ffffffffc0204e38:	c8c68693          	addi	a3,a3,-884 # ffffffffc0207ac0 <default_pmm_manager+0xf00>
ffffffffc0204e3c:	00001617          	auipc	a2,0x1
ffffffffc0204e40:	71460613          	addi	a2,a2,1812 # ffffffffc0206550 <commands+0x5f8>
ffffffffc0204e44:	42e00593          	li	a1,1070
ffffffffc0204e48:	00003517          	auipc	a0,0x3
ffffffffc0204e4c:	ac050513          	addi	a0,a0,-1344 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204e50:	e3efb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204e54 <do_execve>:
{
ffffffffc0204e54:	7135                	addi	sp,sp,-160
ffffffffc0204e56:	ecde                	sd	s7,88(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204e58:	000d5b97          	auipc	s7,0xd5
ffffffffc0204e5c:	780b8b93          	addi	s7,s7,1920 # ffffffffc02da5d8 <current>
ffffffffc0204e60:	000bb783          	ld	a5,0(s7)
{
ffffffffc0204e64:	fcce                	sd	s3,120(sp)
ffffffffc0204e66:	e526                	sd	s1,136(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204e68:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204e6c:	e14a                	sd	s2,128(sp)
ffffffffc0204e6e:	f4d6                	sd	s5,104(sp)
ffffffffc0204e70:	892a                	mv	s2,a0
ffffffffc0204e72:	8ab2                	mv	s5,a2
ffffffffc0204e74:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204e76:	862e                	mv	a2,a1
ffffffffc0204e78:	4681                	li	a3,0
ffffffffc0204e7a:	85aa                	mv	a1,a0
ffffffffc0204e7c:	854e                	mv	a0,s3
{
ffffffffc0204e7e:	ed06                	sd	ra,152(sp)
ffffffffc0204e80:	e922                	sd	s0,144(sp)
ffffffffc0204e82:	f8d2                	sd	s4,112(sp)
ffffffffc0204e84:	f0da                	sd	s6,96(sp)
ffffffffc0204e86:	e8e2                	sd	s8,80(sp)
ffffffffc0204e88:	e4e6                	sd	s9,72(sp)
ffffffffc0204e8a:	e0ea                	sd	s10,64(sp)
ffffffffc0204e8c:	fc6e                	sd	s11,56(sp)
ffffffffc0204e8e:	e856                	sd	s5,16(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204e90:	8a0ff0ef          	jal	ra,ffffffffc0203f30 <user_mem_check>
ffffffffc0204e94:	3e050d63          	beqz	a0,ffffffffc020528e <do_execve+0x43a>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204e98:	4641                	li	a2,16
ffffffffc0204e9a:	4581                	li	a1,0
ffffffffc0204e9c:	1008                	addi	a0,sp,32
ffffffffc0204e9e:	625000ef          	jal	ra,ffffffffc0205cc2 <memset>
    memcpy(local_name, name, len);
ffffffffc0204ea2:	47bd                	li	a5,15
ffffffffc0204ea4:	8626                	mv	a2,s1
ffffffffc0204ea6:	0697ed63          	bltu	a5,s1,ffffffffc0204f20 <do_execve+0xcc>
ffffffffc0204eaa:	85ca                	mv	a1,s2
ffffffffc0204eac:	1008                	addi	a0,sp,32
ffffffffc0204eae:	627000ef          	jal	ra,ffffffffc0205cd4 <memcpy>
    if (mm != NULL)
ffffffffc0204eb2:	06098e63          	beqz	s3,ffffffffc0204f2e <do_execve+0xda>
        cputs("mm != NULL");
ffffffffc0204eb6:	00002517          	auipc	a0,0x2
ffffffffc0204eba:	53a50513          	addi	a0,a0,1338 # ffffffffc02073f0 <default_pmm_manager+0x830>
ffffffffc0204ebe:	b0efb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204ec2:	000d5797          	auipc	a5,0xd5
ffffffffc0204ec6:	6e67b783          	ld	a5,1766(a5) # ffffffffc02da5a8 <boot_pgdir_pa>
ffffffffc0204eca:	577d                	li	a4,-1
ffffffffc0204ecc:	177e                	slli	a4,a4,0x3f
ffffffffc0204ece:	83b1                	srli	a5,a5,0xc
ffffffffc0204ed0:	8fd9                	or	a5,a5,a4
ffffffffc0204ed2:	18079073          	csrw	satp,a5
ffffffffc0204ed6:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b98>
ffffffffc0204eda:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204ede:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204ee2:	28070d63          	beqz	a4,ffffffffc020517c <do_execve+0x328>
        current->mm = NULL;
ffffffffc0204ee6:	000bb783          	ld	a5,0(s7)
ffffffffc0204eea:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204eee:	9cdfe0ef          	jal	ra,ffffffffc02038ba <mm_create>
ffffffffc0204ef2:	84aa                	mv	s1,a0
ffffffffc0204ef4:	c135                	beqz	a0,ffffffffc0204f58 <do_execve+0x104>
    if (setup_pgdir(mm) != 0)
ffffffffc0204ef6:	d84ff0ef          	jal	ra,ffffffffc020447a <setup_pgdir>
ffffffffc0204efa:	e931                	bnez	a0,ffffffffc0204f4e <do_execve+0xfa>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204efc:	67c2                	ld	a5,16(sp)
ffffffffc0204efe:	4398                	lw	a4,0(a5)
ffffffffc0204f00:	464c47b7          	lui	a5,0x464c4
ffffffffc0204f04:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_cowtest_out_size+0x464b488f>
ffffffffc0204f08:	04f70a63          	beq	a4,a5,ffffffffc0204f5c <do_execve+0x108>
    put_pgdir(mm);
ffffffffc0204f0c:	8526                	mv	a0,s1
ffffffffc0204f0e:	cf6ff0ef          	jal	ra,ffffffffc0204404 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204f12:	8526                	mv	a0,s1
ffffffffc0204f14:	ae7fe0ef          	jal	ra,ffffffffc02039fa <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204f18:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204f1a:	8552                	mv	a0,s4
ffffffffc0204f1c:	af9ff0ef          	jal	ra,ffffffffc0204a14 <do_exit>
    memcpy(local_name, name, len);
ffffffffc0204f20:	463d                	li	a2,15
ffffffffc0204f22:	85ca                	mv	a1,s2
ffffffffc0204f24:	1008                	addi	a0,sp,32
ffffffffc0204f26:	5af000ef          	jal	ra,ffffffffc0205cd4 <memcpy>
    if (mm != NULL)
ffffffffc0204f2a:	f80996e3          	bnez	s3,ffffffffc0204eb6 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204f2e:	000bb783          	ld	a5,0(s7)
ffffffffc0204f32:	779c                	ld	a5,40(a5)
ffffffffc0204f34:	dfcd                	beqz	a5,ffffffffc0204eee <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204f36:	00003617          	auipc	a2,0x3
ffffffffc0204f3a:	c1a60613          	addi	a2,a2,-998 # ffffffffc0207b50 <default_pmm_manager+0xf90>
ffffffffc0204f3e:	2a400593          	li	a1,676
ffffffffc0204f42:	00003517          	auipc	a0,0x3
ffffffffc0204f46:	9c650513          	addi	a0,a0,-1594 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0204f4a:	d44fb0ef          	jal	ra,ffffffffc020048e <__panic>
    mm_destroy(mm);
ffffffffc0204f4e:	8526                	mv	a0,s1
ffffffffc0204f50:	aabfe0ef          	jal	ra,ffffffffc02039fa <mm_destroy>
    int ret = -E_NO_MEM;
ffffffffc0204f54:	5a71                	li	s4,-4
ffffffffc0204f56:	b7d1                	j	ffffffffc0204f1a <do_execve+0xc6>
ffffffffc0204f58:	5a71                	li	s4,-4
ffffffffc0204f5a:	b7c1                	j	ffffffffc0204f1a <do_execve+0xc6>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204f5c:	66c2                	ld	a3,16(sp)
ffffffffc0204f5e:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204f62:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204f66:	00371793          	slli	a5,a4,0x3
ffffffffc0204f6a:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204f6c:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204f6e:	078e                	slli	a5,a5,0x3
ffffffffc0204f70:	97ce                	add	a5,a5,s3
ffffffffc0204f72:	ec3e                	sd	a5,24(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204f74:	02f9fb63          	bgeu	s3,a5,ffffffffc0204faa <do_execve+0x156>
    return KADDR(page2pa(page));
ffffffffc0204f78:	57fd                	li	a5,-1
ffffffffc0204f7a:	83b1                	srli	a5,a5,0xc
    return page - pages + nbase;
ffffffffc0204f7c:	000d5d17          	auipc	s10,0xd5
ffffffffc0204f80:	644d0d13          	addi	s10,s10,1604 # ffffffffc02da5c0 <pages>
ffffffffc0204f84:	00003c97          	auipc	s9,0x3
ffffffffc0204f88:	29cc8c93          	addi	s9,s9,668 # ffffffffc0208220 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204f8c:	e43e                	sd	a5,8(sp)
ffffffffc0204f8e:	000d5c17          	auipc	s8,0xd5
ffffffffc0204f92:	62ac0c13          	addi	s8,s8,1578 # ffffffffc02da5b8 <npage>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204f96:	0009a703          	lw	a4,0(s3)
ffffffffc0204f9a:	4785                	li	a5,1
ffffffffc0204f9c:	0ef70f63          	beq	a4,a5,ffffffffc020509a <do_execve+0x246>
    for (; ph < ph_end; ph++)
ffffffffc0204fa0:	67e2                	ld	a5,24(sp)
ffffffffc0204fa2:	03898993          	addi	s3,s3,56
ffffffffc0204fa6:	fef9e8e3          	bltu	s3,a5,ffffffffc0204f96 <do_execve+0x142>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204faa:	4701                	li	a4,0
ffffffffc0204fac:	46ad                	li	a3,11
ffffffffc0204fae:	00100637          	lui	a2,0x100
ffffffffc0204fb2:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204fb6:	8526                	mv	a0,s1
ffffffffc0204fb8:	a95fe0ef          	jal	ra,ffffffffc0203a4c <mm_map>
ffffffffc0204fbc:	8a2a                	mv	s4,a0
ffffffffc0204fbe:	1a051563          	bnez	a0,ffffffffc0205168 <do_execve+0x314>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204fc2:	6c88                	ld	a0,24(s1)
ffffffffc0204fc4:	467d                	li	a2,31
ffffffffc0204fc6:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204fca:	80bfe0ef          	jal	ra,ffffffffc02037d4 <pgdir_alloc_page>
ffffffffc0204fce:	34050e63          	beqz	a0,ffffffffc020532a <do_execve+0x4d6>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204fd2:	6c88                	ld	a0,24(s1)
ffffffffc0204fd4:	467d                	li	a2,31
ffffffffc0204fd6:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204fda:	ffafe0ef          	jal	ra,ffffffffc02037d4 <pgdir_alloc_page>
ffffffffc0204fde:	32050663          	beqz	a0,ffffffffc020530a <do_execve+0x4b6>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204fe2:	6c88                	ld	a0,24(s1)
ffffffffc0204fe4:	467d                	li	a2,31
ffffffffc0204fe6:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204fea:	feafe0ef          	jal	ra,ffffffffc02037d4 <pgdir_alloc_page>
ffffffffc0204fee:	2e050e63          	beqz	a0,ffffffffc02052ea <do_execve+0x496>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ff2:	6c88                	ld	a0,24(s1)
ffffffffc0204ff4:	467d                	li	a2,31
ffffffffc0204ff6:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204ffa:	fdafe0ef          	jal	ra,ffffffffc02037d4 <pgdir_alloc_page>
ffffffffc0204ffe:	2c050663          	beqz	a0,ffffffffc02052ca <do_execve+0x476>
    mm->mm_count += 1;
ffffffffc0205002:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0205004:	000bb603          	ld	a2,0(s7)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0205008:	6c94                	ld	a3,24(s1)
ffffffffc020500a:	2785                	addiw	a5,a5,1
ffffffffc020500c:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc020500e:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0205010:	c02007b7          	lui	a5,0xc0200
ffffffffc0205014:	28f6ef63          	bltu	a3,a5,ffffffffc02052b2 <do_execve+0x45e>
ffffffffc0205018:	000d5797          	auipc	a5,0xd5
ffffffffc020501c:	5b87b783          	ld	a5,1464(a5) # ffffffffc02da5d0 <va_pa_offset>
ffffffffc0205020:	8e9d                	sub	a3,a3,a5
ffffffffc0205022:	577d                	li	a4,-1
ffffffffc0205024:	00c6d793          	srli	a5,a3,0xc
ffffffffc0205028:	177e                	slli	a4,a4,0x3f
ffffffffc020502a:	f654                	sd	a3,168(a2)
ffffffffc020502c:	8fd9                	or	a5,a5,a4
ffffffffc020502e:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0205032:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205034:	4581                	li	a1,0
ffffffffc0205036:	12000613          	li	a2,288
ffffffffc020503a:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc020503c:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205040:	483000ef          	jal	ra,ffffffffc0205cc2 <memset>
    tf->epc = elf->e_entry;
ffffffffc0205044:	67c2                	ld	a5,16(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205046:	000bb903          	ld	s2,0(s7)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc020504a:	edf4f493          	andi	s1,s1,-289
    tf->epc = elf->e_entry;
ffffffffc020504e:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0205050:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205052:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_cowtest_out_size+0xffffffff7fff03c4>
    tf->gpr.sp = USTACKTOP;
ffffffffc0205056:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0205058:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020505c:	4641                	li	a2,16
ffffffffc020505e:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0205060:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0205062:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0205066:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020506a:	854a                	mv	a0,s2
ffffffffc020506c:	457000ef          	jal	ra,ffffffffc0205cc2 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205070:	463d                	li	a2,15
ffffffffc0205072:	100c                	addi	a1,sp,32
ffffffffc0205074:	854a                	mv	a0,s2
ffffffffc0205076:	45f000ef          	jal	ra,ffffffffc0205cd4 <memcpy>
}
ffffffffc020507a:	60ea                	ld	ra,152(sp)
ffffffffc020507c:	644a                	ld	s0,144(sp)
ffffffffc020507e:	64aa                	ld	s1,136(sp)
ffffffffc0205080:	690a                	ld	s2,128(sp)
ffffffffc0205082:	79e6                	ld	s3,120(sp)
ffffffffc0205084:	7aa6                	ld	s5,104(sp)
ffffffffc0205086:	7b06                	ld	s6,96(sp)
ffffffffc0205088:	6be6                	ld	s7,88(sp)
ffffffffc020508a:	6c46                	ld	s8,80(sp)
ffffffffc020508c:	6ca6                	ld	s9,72(sp)
ffffffffc020508e:	6d06                	ld	s10,64(sp)
ffffffffc0205090:	7de2                	ld	s11,56(sp)
ffffffffc0205092:	8552                	mv	a0,s4
ffffffffc0205094:	7a46                	ld	s4,112(sp)
ffffffffc0205096:	610d                	addi	sp,sp,160
ffffffffc0205098:	8082                	ret
        if (ph->p_filesz > ph->p_memsz)
ffffffffc020509a:	0289b603          	ld	a2,40(s3)
ffffffffc020509e:	0209b783          	ld	a5,32(s3)
ffffffffc02050a2:	1ef66a63          	bltu	a2,a5,ffffffffc0205296 <do_execve+0x442>
        if (ph->p_flags & ELF_PF_X)
ffffffffc02050a6:	0049a783          	lw	a5,4(s3)
ffffffffc02050aa:	0017f693          	andi	a3,a5,1
ffffffffc02050ae:	c291                	beqz	a3,ffffffffc02050b2 <do_execve+0x25e>
            vm_flags |= VM_EXEC;
ffffffffc02050b0:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc02050b2:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc02050b6:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc02050b8:	ef61                	bnez	a4,ffffffffc0205190 <do_execve+0x33c>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc02050ba:	4b45                	li	s6,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc02050bc:	c781                	beqz	a5,ffffffffc02050c4 <do_execve+0x270>
            vm_flags |= VM_READ;
ffffffffc02050be:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc02050c2:	4b4d                	li	s6,19
        if (vm_flags & VM_WRITE)
ffffffffc02050c4:	0026f793          	andi	a5,a3,2
ffffffffc02050c8:	e7f9                	bnez	a5,ffffffffc0205196 <do_execve+0x342>
        if (vm_flags & VM_EXEC)
ffffffffc02050ca:	0046f793          	andi	a5,a3,4
ffffffffc02050ce:	c399                	beqz	a5,ffffffffc02050d4 <do_execve+0x280>
            perm |= PTE_X;
ffffffffc02050d0:	008b6b13          	ori	s6,s6,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc02050d4:	0109b583          	ld	a1,16(s3)
ffffffffc02050d8:	4701                	li	a4,0
ffffffffc02050da:	8526                	mv	a0,s1
ffffffffc02050dc:	971fe0ef          	jal	ra,ffffffffc0203a4c <mm_map>
ffffffffc02050e0:	8a2a                	mv	s4,a0
ffffffffc02050e2:	e159                	bnez	a0,ffffffffc0205168 <do_execve+0x314>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02050e4:	0109bd83          	ld	s11,16(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc02050e8:	67c2                	ld	a5,16(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc02050ea:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc02050ee:	0089b903          	ld	s2,8(s3)
        end = ph->p_va + ph->p_filesz;
ffffffffc02050f2:	9a6e                	add	s4,s4,s11
        unsigned char *from = binary + ph->p_offset;
ffffffffc02050f4:	993e                	add	s2,s2,a5
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02050f6:	77fd                	lui	a5,0xfffff
ffffffffc02050f8:	00fdfab3          	and	s5,s11,a5
        while (start < end)
ffffffffc02050fc:	054dee63          	bltu	s11,s4,ffffffffc0205158 <do_execve+0x304>
ffffffffc0205100:	aa49                	j	ffffffffc0205292 <do_execve+0x43e>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205102:	6785                	lui	a5,0x1
ffffffffc0205104:	415d8533          	sub	a0,s11,s5
ffffffffc0205108:	9abe                	add	s5,s5,a5
ffffffffc020510a:	41ba8633          	sub	a2,s5,s11
            if (end < la)
ffffffffc020510e:	015a7463          	bgeu	s4,s5,ffffffffc0205116 <do_execve+0x2c2>
                size -= la - end;
ffffffffc0205112:	41ba0633          	sub	a2,s4,s11
    return page - pages + nbase;
ffffffffc0205116:	000d3683          	ld	a3,0(s10)
ffffffffc020511a:	000cb803          	ld	a6,0(s9)
    return KADDR(page2pa(page));
ffffffffc020511e:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205120:	40d406b3          	sub	a3,s0,a3
ffffffffc0205124:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205126:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc020512a:	96c2                	add	a3,a3,a6
    return KADDR(page2pa(page));
ffffffffc020512c:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205130:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205132:	16b87463          	bgeu	a6,a1,ffffffffc020529a <do_execve+0x446>
ffffffffc0205136:	000d5797          	auipc	a5,0xd5
ffffffffc020513a:	49a78793          	addi	a5,a5,1178 # ffffffffc02da5d0 <va_pa_offset>
ffffffffc020513e:	0007b803          	ld	a6,0(a5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205142:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0205144:	9db2                	add	s11,s11,a2
ffffffffc0205146:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205148:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc020514a:	e032                	sd	a2,0(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc020514c:	389000ef          	jal	ra,ffffffffc0205cd4 <memcpy>
            start += size, from += size;
ffffffffc0205150:	6602                	ld	a2,0(sp)
ffffffffc0205152:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0205154:	054df363          	bgeu	s11,s4,ffffffffc020519a <do_execve+0x346>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0205158:	6c88                	ld	a0,24(s1)
ffffffffc020515a:	865a                	mv	a2,s6
ffffffffc020515c:	85d6                	mv	a1,s5
ffffffffc020515e:	e76fe0ef          	jal	ra,ffffffffc02037d4 <pgdir_alloc_page>
ffffffffc0205162:	842a                	mv	s0,a0
ffffffffc0205164:	fd59                	bnez	a0,ffffffffc0205102 <do_execve+0x2ae>
        ret = -E_NO_MEM;
ffffffffc0205166:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0205168:	8526                	mv	a0,s1
ffffffffc020516a:	a2dfe0ef          	jal	ra,ffffffffc0203b96 <exit_mmap>
    put_pgdir(mm);
ffffffffc020516e:	8526                	mv	a0,s1
ffffffffc0205170:	a94ff0ef          	jal	ra,ffffffffc0204404 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205174:	8526                	mv	a0,s1
ffffffffc0205176:	885fe0ef          	jal	ra,ffffffffc02039fa <mm_destroy>
    return ret;
ffffffffc020517a:	b345                	j	ffffffffc0204f1a <do_execve+0xc6>
            exit_mmap(mm);
ffffffffc020517c:	854e                	mv	a0,s3
ffffffffc020517e:	a19fe0ef          	jal	ra,ffffffffc0203b96 <exit_mmap>
            put_pgdir(mm);
ffffffffc0205182:	854e                	mv	a0,s3
ffffffffc0205184:	a80ff0ef          	jal	ra,ffffffffc0204404 <put_pgdir>
            mm_destroy(mm);
ffffffffc0205188:	854e                	mv	a0,s3
ffffffffc020518a:	871fe0ef          	jal	ra,ffffffffc02039fa <mm_destroy>
ffffffffc020518e:	bba1                	j	ffffffffc0204ee6 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0205190:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0205194:	f78d                	bnez	a5,ffffffffc02050be <do_execve+0x26a>
            perm |= (PTE_W | PTE_R);
ffffffffc0205196:	4b5d                	li	s6,23
ffffffffc0205198:	bf0d                	j	ffffffffc02050ca <do_execve+0x276>
        end = ph->p_va + ph->p_memsz;
ffffffffc020519a:	0109b903          	ld	s2,16(s3)
ffffffffc020519e:	0289b683          	ld	a3,40(s3)
ffffffffc02051a2:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc02051a4:	075dff63          	bgeu	s11,s5,ffffffffc0205222 <do_execve+0x3ce>
            if (start == end)
ffffffffc02051a8:	dfb90ce3          	beq	s2,s11,ffffffffc0204fa0 <do_execve+0x14c>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc02051ac:	6505                	lui	a0,0x1
ffffffffc02051ae:	956e                	add	a0,a0,s11
ffffffffc02051b0:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc02051b4:	41b90a33          	sub	s4,s2,s11
            if (end < la)
ffffffffc02051b8:	0d597863          	bgeu	s2,s5,ffffffffc0205288 <do_execve+0x434>
    return page - pages + nbase;
ffffffffc02051bc:	000d3683          	ld	a3,0(s10)
ffffffffc02051c0:	000cb583          	ld	a1,0(s9)
    return KADDR(page2pa(page));
ffffffffc02051c4:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc02051c6:	40d406b3          	sub	a3,s0,a3
ffffffffc02051ca:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02051cc:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02051d0:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc02051d2:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02051d6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02051d8:	0cc5f163          	bgeu	a1,a2,ffffffffc020529a <do_execve+0x446>
ffffffffc02051dc:	000d5617          	auipc	a2,0xd5
ffffffffc02051e0:	3f463603          	ld	a2,1012(a2) # ffffffffc02da5d0 <va_pa_offset>
ffffffffc02051e4:	96b2                	add	a3,a3,a2
            memset(page2kva(page) + off, 0, size);
ffffffffc02051e6:	4581                	li	a1,0
ffffffffc02051e8:	8652                	mv	a2,s4
ffffffffc02051ea:	9536                	add	a0,a0,a3
ffffffffc02051ec:	2d7000ef          	jal	ra,ffffffffc0205cc2 <memset>
            start += size;
ffffffffc02051f0:	01ba0733          	add	a4,s4,s11
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc02051f4:	03597463          	bgeu	s2,s5,ffffffffc020521c <do_execve+0x3c8>
ffffffffc02051f8:	dae904e3          	beq	s2,a4,ffffffffc0204fa0 <do_execve+0x14c>
ffffffffc02051fc:	00003697          	auipc	a3,0x3
ffffffffc0205200:	97c68693          	addi	a3,a3,-1668 # ffffffffc0207b78 <default_pmm_manager+0xfb8>
ffffffffc0205204:	00001617          	auipc	a2,0x1
ffffffffc0205208:	34c60613          	addi	a2,a2,844 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020520c:	30d00593          	li	a1,781
ffffffffc0205210:	00002517          	auipc	a0,0x2
ffffffffc0205214:	6f850513          	addi	a0,a0,1784 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0205218:	a76fb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc020521c:	ff5710e3          	bne	a4,s5,ffffffffc02051fc <do_execve+0x3a8>
ffffffffc0205220:	8dd6                	mv	s11,s5
ffffffffc0205222:	000d5a17          	auipc	s4,0xd5
ffffffffc0205226:	3aea0a13          	addi	s4,s4,942 # ffffffffc02da5d0 <va_pa_offset>
        while (start < end)
ffffffffc020522a:	052de763          	bltu	s11,s2,ffffffffc0205278 <do_execve+0x424>
ffffffffc020522e:	bb8d                	j	ffffffffc0204fa0 <do_execve+0x14c>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205230:	6785                	lui	a5,0x1
ffffffffc0205232:	415d8533          	sub	a0,s11,s5
ffffffffc0205236:	9abe                	add	s5,s5,a5
ffffffffc0205238:	41ba8633          	sub	a2,s5,s11
            if (end < la)
ffffffffc020523c:	01597463          	bgeu	s2,s5,ffffffffc0205244 <do_execve+0x3f0>
                size -= la - end;
ffffffffc0205240:	41b90633          	sub	a2,s2,s11
    return page - pages + nbase;
ffffffffc0205244:	000d3683          	ld	a3,0(s10)
ffffffffc0205248:	000cb803          	ld	a6,0(s9)
    return KADDR(page2pa(page));
ffffffffc020524c:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc020524e:	40d406b3          	sub	a3,s0,a3
ffffffffc0205252:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205254:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0205258:	96c2                	add	a3,a3,a6
    return KADDR(page2pa(page));
ffffffffc020525a:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc020525e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205260:	02b87d63          	bgeu	a6,a1,ffffffffc020529a <do_execve+0x446>
ffffffffc0205264:	000a3803          	ld	a6,0(s4)
            start += size;
ffffffffc0205268:	9db2                	add	s11,s11,a2
            memset(page2kva(page) + off, 0, size);
ffffffffc020526a:	4581                	li	a1,0
ffffffffc020526c:	96c2                	add	a3,a3,a6
ffffffffc020526e:	9536                	add	a0,a0,a3
ffffffffc0205270:	253000ef          	jal	ra,ffffffffc0205cc2 <memset>
        while (start < end)
ffffffffc0205274:	d32df6e3          	bgeu	s11,s2,ffffffffc0204fa0 <do_execve+0x14c>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0205278:	6c88                	ld	a0,24(s1)
ffffffffc020527a:	865a                	mv	a2,s6
ffffffffc020527c:	85d6                	mv	a1,s5
ffffffffc020527e:	d56fe0ef          	jal	ra,ffffffffc02037d4 <pgdir_alloc_page>
ffffffffc0205282:	842a                	mv	s0,a0
ffffffffc0205284:	f555                	bnez	a0,ffffffffc0205230 <do_execve+0x3dc>
ffffffffc0205286:	b5c5                	j	ffffffffc0205166 <do_execve+0x312>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205288:	41ba8a33          	sub	s4,s5,s11
ffffffffc020528c:	bf05                	j	ffffffffc02051bc <do_execve+0x368>
        return -E_INVAL;
ffffffffc020528e:	5a75                	li	s4,-3
ffffffffc0205290:	b3ed                	j	ffffffffc020507a <do_execve+0x226>
        while (start < end)
ffffffffc0205292:	896e                	mv	s2,s11
ffffffffc0205294:	b729                	j	ffffffffc020519e <do_execve+0x34a>
            ret = -E_INVAL_ELF;
ffffffffc0205296:	5a61                	li	s4,-8
ffffffffc0205298:	bdc1                	j	ffffffffc0205168 <do_execve+0x314>
ffffffffc020529a:	00002617          	auipc	a2,0x2
ffffffffc020529e:	95e60613          	addi	a2,a2,-1698 # ffffffffc0206bf8 <default_pmm_manager+0x38>
ffffffffc02052a2:	07200593          	li	a1,114
ffffffffc02052a6:	00002517          	auipc	a0,0x2
ffffffffc02052aa:	97a50513          	addi	a0,a0,-1670 # ffffffffc0206c20 <default_pmm_manager+0x60>
ffffffffc02052ae:	9e0fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02052b2:	00002617          	auipc	a2,0x2
ffffffffc02052b6:	9ee60613          	addi	a2,a2,-1554 # ffffffffc0206ca0 <default_pmm_manager+0xe0>
ffffffffc02052ba:	32c00593          	li	a1,812
ffffffffc02052be:	00002517          	auipc	a0,0x2
ffffffffc02052c2:	64a50513          	addi	a0,a0,1610 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc02052c6:	9c8fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc02052ca:	00003697          	auipc	a3,0x3
ffffffffc02052ce:	9c668693          	addi	a3,a3,-1594 # ffffffffc0207c90 <default_pmm_manager+0x10d0>
ffffffffc02052d2:	00001617          	auipc	a2,0x1
ffffffffc02052d6:	27e60613          	addi	a2,a2,638 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02052da:	32700593          	li	a1,807
ffffffffc02052de:	00002517          	auipc	a0,0x2
ffffffffc02052e2:	62a50513          	addi	a0,a0,1578 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc02052e6:	9a8fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc02052ea:	00003697          	auipc	a3,0x3
ffffffffc02052ee:	95e68693          	addi	a3,a3,-1698 # ffffffffc0207c48 <default_pmm_manager+0x1088>
ffffffffc02052f2:	00001617          	auipc	a2,0x1
ffffffffc02052f6:	25e60613          	addi	a2,a2,606 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02052fa:	32600593          	li	a1,806
ffffffffc02052fe:	00002517          	auipc	a0,0x2
ffffffffc0205302:	60a50513          	addi	a0,a0,1546 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0205306:	988fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc020530a:	00003697          	auipc	a3,0x3
ffffffffc020530e:	8f668693          	addi	a3,a3,-1802 # ffffffffc0207c00 <default_pmm_manager+0x1040>
ffffffffc0205312:	00001617          	auipc	a2,0x1
ffffffffc0205316:	23e60613          	addi	a2,a2,574 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020531a:	32500593          	li	a1,805
ffffffffc020531e:	00002517          	auipc	a0,0x2
ffffffffc0205322:	5ea50513          	addi	a0,a0,1514 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0205326:	968fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc020532a:	00003697          	auipc	a3,0x3
ffffffffc020532e:	88e68693          	addi	a3,a3,-1906 # ffffffffc0207bb8 <default_pmm_manager+0xff8>
ffffffffc0205332:	00001617          	auipc	a2,0x1
ffffffffc0205336:	21e60613          	addi	a2,a2,542 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020533a:	32400593          	li	a1,804
ffffffffc020533e:	00002517          	auipc	a0,0x2
ffffffffc0205342:	5ca50513          	addi	a0,a0,1482 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0205346:	948fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020534a <do_yield>:
    current->need_resched = 1;
ffffffffc020534a:	000d5797          	auipc	a5,0xd5
ffffffffc020534e:	28e7b783          	ld	a5,654(a5) # ffffffffc02da5d8 <current>
ffffffffc0205352:	4705                	li	a4,1
ffffffffc0205354:	ef98                	sd	a4,24(a5)
}
ffffffffc0205356:	4501                	li	a0,0
ffffffffc0205358:	8082                	ret

ffffffffc020535a <do_wait>:
{
ffffffffc020535a:	1101                	addi	sp,sp,-32
ffffffffc020535c:	e822                	sd	s0,16(sp)
ffffffffc020535e:	e426                	sd	s1,8(sp)
ffffffffc0205360:	ec06                	sd	ra,24(sp)
ffffffffc0205362:	842e                	mv	s0,a1
ffffffffc0205364:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0205366:	c999                	beqz	a1,ffffffffc020537c <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0205368:	000d5797          	auipc	a5,0xd5
ffffffffc020536c:	2707b783          	ld	a5,624(a5) # ffffffffc02da5d8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0205370:	7788                	ld	a0,40(a5)
ffffffffc0205372:	4685                	li	a3,1
ffffffffc0205374:	4611                	li	a2,4
ffffffffc0205376:	bbbfe0ef          	jal	ra,ffffffffc0203f30 <user_mem_check>
ffffffffc020537a:	c909                	beqz	a0,ffffffffc020538c <do_wait+0x32>
ffffffffc020537c:	85a2                	mv	a1,s0
}
ffffffffc020537e:	6442                	ld	s0,16(sp)
ffffffffc0205380:	60e2                	ld	ra,24(sp)
ffffffffc0205382:	8526                	mv	a0,s1
ffffffffc0205384:	64a2                	ld	s1,8(sp)
ffffffffc0205386:	6105                	addi	sp,sp,32
ffffffffc0205388:	fd6ff06f          	j	ffffffffc0204b5e <do_wait.part.0>
ffffffffc020538c:	60e2                	ld	ra,24(sp)
ffffffffc020538e:	6442                	ld	s0,16(sp)
ffffffffc0205390:	64a2                	ld	s1,8(sp)
ffffffffc0205392:	5575                	li	a0,-3
ffffffffc0205394:	6105                	addi	sp,sp,32
ffffffffc0205396:	8082                	ret

ffffffffc0205398 <do_kill>:
{
ffffffffc0205398:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc020539a:	6789                	lui	a5,0x2
{
ffffffffc020539c:	e406                	sd	ra,8(sp)
ffffffffc020539e:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc02053a0:	fff5071b          	addiw	a4,a0,-1
ffffffffc02053a4:	17f9                	addi	a5,a5,-2
ffffffffc02053a6:	02e7e963          	bltu	a5,a4,ffffffffc02053d8 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02053aa:	842a                	mv	s0,a0
ffffffffc02053ac:	45a9                	li	a1,10
ffffffffc02053ae:	2501                	sext.w	a0,a0
ffffffffc02053b0:	46c000ef          	jal	ra,ffffffffc020581c <hash32>
ffffffffc02053b4:	02051793          	slli	a5,a0,0x20
ffffffffc02053b8:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02053bc:	000d1797          	auipc	a5,0xd1
ffffffffc02053c0:	1ac78793          	addi	a5,a5,428 # ffffffffc02d6568 <hash_list>
ffffffffc02053c4:	953e                	add	a0,a0,a5
ffffffffc02053c6:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc02053c8:	a029                	j	ffffffffc02053d2 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc02053ca:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02053ce:	00870b63          	beq	a4,s0,ffffffffc02053e4 <do_kill+0x4c>
ffffffffc02053d2:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02053d4:	fef51be3          	bne	a0,a5,ffffffffc02053ca <do_kill+0x32>
    return -E_INVAL;
ffffffffc02053d8:	5475                	li	s0,-3
}
ffffffffc02053da:	60a2                	ld	ra,8(sp)
ffffffffc02053dc:	8522                	mv	a0,s0
ffffffffc02053de:	6402                	ld	s0,0(sp)
ffffffffc02053e0:	0141                	addi	sp,sp,16
ffffffffc02053e2:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc02053e4:	fd87a703          	lw	a4,-40(a5)
ffffffffc02053e8:	00177693          	andi	a3,a4,1
ffffffffc02053ec:	e295                	bnez	a3,ffffffffc0205410 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc02053ee:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc02053f0:	00176713          	ori	a4,a4,1
ffffffffc02053f4:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc02053f8:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc02053fa:	fe06d0e3          	bgez	a3,ffffffffc02053da <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc02053fe:	f2878513          	addi	a0,a5,-216
ffffffffc0205402:	22e000ef          	jal	ra,ffffffffc0205630 <wakeup_proc>
}
ffffffffc0205406:	60a2                	ld	ra,8(sp)
ffffffffc0205408:	8522                	mv	a0,s0
ffffffffc020540a:	6402                	ld	s0,0(sp)
ffffffffc020540c:	0141                	addi	sp,sp,16
ffffffffc020540e:	8082                	ret
        return -E_KILLED;
ffffffffc0205410:	545d                	li	s0,-9
ffffffffc0205412:	b7e1                	j	ffffffffc02053da <do_kill+0x42>

ffffffffc0205414 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0205414:	1101                	addi	sp,sp,-32
ffffffffc0205416:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205418:	000d5797          	auipc	a5,0xd5
ffffffffc020541c:	15078793          	addi	a5,a5,336 # ffffffffc02da568 <proc_list>
ffffffffc0205420:	ec06                	sd	ra,24(sp)
ffffffffc0205422:	e822                	sd	s0,16(sp)
ffffffffc0205424:	e04a                	sd	s2,0(sp)
ffffffffc0205426:	000d1497          	auipc	s1,0xd1
ffffffffc020542a:	14248493          	addi	s1,s1,322 # ffffffffc02d6568 <hash_list>
ffffffffc020542e:	e79c                	sd	a5,8(a5)
ffffffffc0205430:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0205432:	000d5717          	auipc	a4,0xd5
ffffffffc0205436:	13670713          	addi	a4,a4,310 # ffffffffc02da568 <proc_list>
ffffffffc020543a:	87a6                	mv	a5,s1
ffffffffc020543c:	e79c                	sd	a5,8(a5)
ffffffffc020543e:	e39c                	sd	a5,0(a5)
ffffffffc0205440:	07c1                	addi	a5,a5,16
ffffffffc0205442:	fef71de3          	bne	a4,a5,ffffffffc020543c <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0205446:	ec1fe0ef          	jal	ra,ffffffffc0204306 <alloc_proc>
ffffffffc020544a:	000d5917          	auipc	s2,0xd5
ffffffffc020544e:	19690913          	addi	s2,s2,406 # ffffffffc02da5e0 <idleproc>
ffffffffc0205452:	00a93023          	sd	a0,0(s2)
ffffffffc0205456:	0e050f63          	beqz	a0,ffffffffc0205554 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc020545a:	4789                	li	a5,2
ffffffffc020545c:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020545e:	00004797          	auipc	a5,0x4
ffffffffc0205462:	ba278793          	addi	a5,a5,-1118 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205466:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020546a:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc020546c:	4785                	li	a5,1
ffffffffc020546e:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205470:	4641                	li	a2,16
ffffffffc0205472:	4581                	li	a1,0
ffffffffc0205474:	8522                	mv	a0,s0
ffffffffc0205476:	04d000ef          	jal	ra,ffffffffc0205cc2 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020547a:	463d                	li	a2,15
ffffffffc020547c:	00003597          	auipc	a1,0x3
ffffffffc0205480:	87458593          	addi	a1,a1,-1932 # ffffffffc0207cf0 <default_pmm_manager+0x1130>
ffffffffc0205484:	8522                	mv	a0,s0
ffffffffc0205486:	04f000ef          	jal	ra,ffffffffc0205cd4 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc020548a:	000d5717          	auipc	a4,0xd5
ffffffffc020548e:	16670713          	addi	a4,a4,358 # ffffffffc02da5f0 <nr_process>
ffffffffc0205492:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205494:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205498:	4601                	li	a2,0
    nr_process++;
ffffffffc020549a:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020549c:	4581                	li	a1,0
ffffffffc020549e:	00000517          	auipc	a0,0x0
ffffffffc02054a2:	89250513          	addi	a0,a0,-1902 # ffffffffc0204d30 <init_main>
    nr_process++;
ffffffffc02054a6:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc02054a8:	000d5797          	auipc	a5,0xd5
ffffffffc02054ac:	12d7b823          	sd	a3,304(a5) # ffffffffc02da5d8 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc02054b0:	d14ff0ef          	jal	ra,ffffffffc02049c4 <kernel_thread>
ffffffffc02054b4:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc02054b6:	08a05363          	blez	a0,ffffffffc020553c <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc02054ba:	6789                	lui	a5,0x2
ffffffffc02054bc:	fff5071b          	addiw	a4,a0,-1
ffffffffc02054c0:	17f9                	addi	a5,a5,-2
ffffffffc02054c2:	2501                	sext.w	a0,a0
ffffffffc02054c4:	02e7e363          	bltu	a5,a4,ffffffffc02054ea <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02054c8:	45a9                	li	a1,10
ffffffffc02054ca:	352000ef          	jal	ra,ffffffffc020581c <hash32>
ffffffffc02054ce:	02051793          	slli	a5,a0,0x20
ffffffffc02054d2:	01c7d693          	srli	a3,a5,0x1c
ffffffffc02054d6:	96a6                	add	a3,a3,s1
ffffffffc02054d8:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02054da:	a029                	j	ffffffffc02054e4 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc02054dc:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c9c>
ffffffffc02054e0:	04870b63          	beq	a4,s0,ffffffffc0205536 <proc_init+0x122>
    return listelm->next;
ffffffffc02054e4:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02054e6:	fef69be3          	bne	a3,a5,ffffffffc02054dc <proc_init+0xc8>
    return NULL;
ffffffffc02054ea:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02054ec:	0b478493          	addi	s1,a5,180
ffffffffc02054f0:	4641                	li	a2,16
ffffffffc02054f2:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02054f4:	000d5417          	auipc	s0,0xd5
ffffffffc02054f8:	0f440413          	addi	s0,s0,244 # ffffffffc02da5e8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02054fc:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc02054fe:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205500:	7c2000ef          	jal	ra,ffffffffc0205cc2 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205504:	463d                	li	a2,15
ffffffffc0205506:	00003597          	auipc	a1,0x3
ffffffffc020550a:	81258593          	addi	a1,a1,-2030 # ffffffffc0207d18 <default_pmm_manager+0x1158>
ffffffffc020550e:	8526                	mv	a0,s1
ffffffffc0205510:	7c4000ef          	jal	ra,ffffffffc0205cd4 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205514:	00093783          	ld	a5,0(s2)
ffffffffc0205518:	cbb5                	beqz	a5,ffffffffc020558c <proc_init+0x178>
ffffffffc020551a:	43dc                	lw	a5,4(a5)
ffffffffc020551c:	eba5                	bnez	a5,ffffffffc020558c <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020551e:	601c                	ld	a5,0(s0)
ffffffffc0205520:	c7b1                	beqz	a5,ffffffffc020556c <proc_init+0x158>
ffffffffc0205522:	43d8                	lw	a4,4(a5)
ffffffffc0205524:	4785                	li	a5,1
ffffffffc0205526:	04f71363          	bne	a4,a5,ffffffffc020556c <proc_init+0x158>
}
ffffffffc020552a:	60e2                	ld	ra,24(sp)
ffffffffc020552c:	6442                	ld	s0,16(sp)
ffffffffc020552e:	64a2                	ld	s1,8(sp)
ffffffffc0205530:	6902                	ld	s2,0(sp)
ffffffffc0205532:	6105                	addi	sp,sp,32
ffffffffc0205534:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205536:	f2878793          	addi	a5,a5,-216
ffffffffc020553a:	bf4d                	j	ffffffffc02054ec <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc020553c:	00002617          	auipc	a2,0x2
ffffffffc0205540:	7bc60613          	addi	a2,a2,1980 # ffffffffc0207cf8 <default_pmm_manager+0x1138>
ffffffffc0205544:	45300593          	li	a1,1107
ffffffffc0205548:	00002517          	auipc	a0,0x2
ffffffffc020554c:	3c050513          	addi	a0,a0,960 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0205550:	f3ffa0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205554:	00002617          	auipc	a2,0x2
ffffffffc0205558:	78460613          	addi	a2,a2,1924 # ffffffffc0207cd8 <default_pmm_manager+0x1118>
ffffffffc020555c:	44400593          	li	a1,1092
ffffffffc0205560:	00002517          	auipc	a0,0x2
ffffffffc0205564:	3a850513          	addi	a0,a0,936 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0205568:	f27fa0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020556c:	00002697          	auipc	a3,0x2
ffffffffc0205570:	7dc68693          	addi	a3,a3,2012 # ffffffffc0207d48 <default_pmm_manager+0x1188>
ffffffffc0205574:	00001617          	auipc	a2,0x1
ffffffffc0205578:	fdc60613          	addi	a2,a2,-36 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020557c:	45a00593          	li	a1,1114
ffffffffc0205580:	00002517          	auipc	a0,0x2
ffffffffc0205584:	38850513          	addi	a0,a0,904 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc0205588:	f07fa0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020558c:	00002697          	auipc	a3,0x2
ffffffffc0205590:	79468693          	addi	a3,a3,1940 # ffffffffc0207d20 <default_pmm_manager+0x1160>
ffffffffc0205594:	00001617          	auipc	a2,0x1
ffffffffc0205598:	fbc60613          	addi	a2,a2,-68 # ffffffffc0206550 <commands+0x5f8>
ffffffffc020559c:	45900593          	li	a1,1113
ffffffffc02055a0:	00002517          	auipc	a0,0x2
ffffffffc02055a4:	36850513          	addi	a0,a0,872 # ffffffffc0207908 <default_pmm_manager+0xd48>
ffffffffc02055a8:	ee7fa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02055ac <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02055ac:	1141                	addi	sp,sp,-16
ffffffffc02055ae:	e022                	sd	s0,0(sp)
ffffffffc02055b0:	e406                	sd	ra,8(sp)
ffffffffc02055b2:	000d5417          	auipc	s0,0xd5
ffffffffc02055b6:	02640413          	addi	s0,s0,38 # ffffffffc02da5d8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02055ba:	6018                	ld	a4,0(s0)
ffffffffc02055bc:	6f1c                	ld	a5,24(a4)
ffffffffc02055be:	dffd                	beqz	a5,ffffffffc02055bc <cpu_idle+0x10>
        {
            schedule();
ffffffffc02055c0:	0f0000ef          	jal	ra,ffffffffc02056b0 <schedule>
ffffffffc02055c4:	bfdd                	j	ffffffffc02055ba <cpu_idle+0xe>

ffffffffc02055c6 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02055c6:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02055ca:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02055ce:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02055d0:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02055d2:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02055d6:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02055da:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02055de:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02055e2:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02055e6:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02055ea:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02055ee:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02055f2:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02055f6:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02055fa:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02055fe:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205602:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205604:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205606:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc020560a:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020560e:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205612:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205616:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc020561a:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020561e:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205622:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205626:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc020562a:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020562e:	8082                	ret

ffffffffc0205630 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205630:	4118                	lw	a4,0(a0)
{
ffffffffc0205632:	1101                	addi	sp,sp,-32
ffffffffc0205634:	ec06                	sd	ra,24(sp)
ffffffffc0205636:	e822                	sd	s0,16(sp)
ffffffffc0205638:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020563a:	478d                	li	a5,3
ffffffffc020563c:	04f70b63          	beq	a4,a5,ffffffffc0205692 <wakeup_proc+0x62>
ffffffffc0205640:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205642:	100027f3          	csrr	a5,sstatus
ffffffffc0205646:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205648:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020564a:	ef9d                	bnez	a5,ffffffffc0205688 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc020564c:	4789                	li	a5,2
ffffffffc020564e:	02f70163          	beq	a4,a5,ffffffffc0205670 <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc0205652:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205654:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc0205658:	e491                	bnez	s1,ffffffffc0205664 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020565a:	60e2                	ld	ra,24(sp)
ffffffffc020565c:	6442                	ld	s0,16(sp)
ffffffffc020565e:	64a2                	ld	s1,8(sp)
ffffffffc0205660:	6105                	addi	sp,sp,32
ffffffffc0205662:	8082                	ret
ffffffffc0205664:	6442                	ld	s0,16(sp)
ffffffffc0205666:	60e2                	ld	ra,24(sp)
ffffffffc0205668:	64a2                	ld	s1,8(sp)
ffffffffc020566a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020566c:	b42fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205670:	00002617          	auipc	a2,0x2
ffffffffc0205674:	73860613          	addi	a2,a2,1848 # ffffffffc0207da8 <default_pmm_manager+0x11e8>
ffffffffc0205678:	45d1                	li	a1,20
ffffffffc020567a:	00002517          	auipc	a0,0x2
ffffffffc020567e:	71650513          	addi	a0,a0,1814 # ffffffffc0207d90 <default_pmm_manager+0x11d0>
ffffffffc0205682:	e75fa0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205686:	bfc9                	j	ffffffffc0205658 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205688:	b2cfb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc020568c:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020568e:	4485                	li	s1,1
ffffffffc0205690:	bf75                	j	ffffffffc020564c <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205692:	00002697          	auipc	a3,0x2
ffffffffc0205696:	6de68693          	addi	a3,a3,1758 # ffffffffc0207d70 <default_pmm_manager+0x11b0>
ffffffffc020569a:	00001617          	auipc	a2,0x1
ffffffffc020569e:	eb660613          	addi	a2,a2,-330 # ffffffffc0206550 <commands+0x5f8>
ffffffffc02056a2:	45a5                	li	a1,9
ffffffffc02056a4:	00002517          	auipc	a0,0x2
ffffffffc02056a8:	6ec50513          	addi	a0,a0,1772 # ffffffffc0207d90 <default_pmm_manager+0x11d0>
ffffffffc02056ac:	de3fa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02056b0 <schedule>:

void schedule(void)
{
ffffffffc02056b0:	1141                	addi	sp,sp,-16
ffffffffc02056b2:	e406                	sd	ra,8(sp)
ffffffffc02056b4:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02056b6:	100027f3          	csrr	a5,sstatus
ffffffffc02056ba:	8b89                	andi	a5,a5,2
ffffffffc02056bc:	4401                	li	s0,0
ffffffffc02056be:	efbd                	bnez	a5,ffffffffc020573c <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02056c0:	000d5897          	auipc	a7,0xd5
ffffffffc02056c4:	f188b883          	ld	a7,-232(a7) # ffffffffc02da5d8 <current>
ffffffffc02056c8:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02056cc:	000d5517          	auipc	a0,0xd5
ffffffffc02056d0:	f1453503          	ld	a0,-236(a0) # ffffffffc02da5e0 <idleproc>
ffffffffc02056d4:	04a88e63          	beq	a7,a0,ffffffffc0205730 <schedule+0x80>
ffffffffc02056d8:	0c888693          	addi	a3,a7,200
ffffffffc02056dc:	000d5617          	auipc	a2,0xd5
ffffffffc02056e0:	e8c60613          	addi	a2,a2,-372 # ffffffffc02da568 <proc_list>
        le = last;
ffffffffc02056e4:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02056e6:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02056e8:	4809                	li	a6,2
ffffffffc02056ea:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02056ec:	00c78863          	beq	a5,a2,ffffffffc02056fc <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc02056f0:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02056f4:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02056f8:	03070163          	beq	a4,a6,ffffffffc020571a <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02056fc:	fef697e3          	bne	a3,a5,ffffffffc02056ea <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc0205700:	ed89                	bnez	a1,ffffffffc020571a <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc0205702:	451c                	lw	a5,8(a0)
ffffffffc0205704:	2785                	addiw	a5,a5,1
ffffffffc0205706:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205708:	00a88463          	beq	a7,a0,ffffffffc0205710 <schedule+0x60>
        {
            proc_run(next);
ffffffffc020570c:	df1fe0ef          	jal	ra,ffffffffc02044fc <proc_run>
    if (flag)
ffffffffc0205710:	e819                	bnez	s0,ffffffffc0205726 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205712:	60a2                	ld	ra,8(sp)
ffffffffc0205714:	6402                	ld	s0,0(sp)
ffffffffc0205716:	0141                	addi	sp,sp,16
ffffffffc0205718:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020571a:	4198                	lw	a4,0(a1)
ffffffffc020571c:	4789                	li	a5,2
ffffffffc020571e:	fef712e3          	bne	a4,a5,ffffffffc0205702 <schedule+0x52>
ffffffffc0205722:	852e                	mv	a0,a1
ffffffffc0205724:	bff9                	j	ffffffffc0205702 <schedule+0x52>
}
ffffffffc0205726:	6402                	ld	s0,0(sp)
ffffffffc0205728:	60a2                	ld	ra,8(sp)
ffffffffc020572a:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020572c:	a82fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205730:	000d5617          	auipc	a2,0xd5
ffffffffc0205734:	e3860613          	addi	a2,a2,-456 # ffffffffc02da568 <proc_list>
ffffffffc0205738:	86b2                	mv	a3,a2
ffffffffc020573a:	b76d                	j	ffffffffc02056e4 <schedule+0x34>
        intr_disable();
ffffffffc020573c:	a78fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0205740:	4405                	li	s0,1
ffffffffc0205742:	bfbd                	j	ffffffffc02056c0 <schedule+0x10>

ffffffffc0205744 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205744:	000d5797          	auipc	a5,0xd5
ffffffffc0205748:	e947b783          	ld	a5,-364(a5) # ffffffffc02da5d8 <current>
}
ffffffffc020574c:	43c8                	lw	a0,4(a5)
ffffffffc020574e:	8082                	ret

ffffffffc0205750 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205750:	4501                	li	a0,0
ffffffffc0205752:	8082                	ret

ffffffffc0205754 <sys_putc>:
    cputchar(c);
ffffffffc0205754:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205756:	1141                	addi	sp,sp,-16
ffffffffc0205758:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020575a:	a71fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc020575e:	60a2                	ld	ra,8(sp)
ffffffffc0205760:	4501                	li	a0,0
ffffffffc0205762:	0141                	addi	sp,sp,16
ffffffffc0205764:	8082                	ret

ffffffffc0205766 <sys_kill>:
    return do_kill(pid);
ffffffffc0205766:	4108                	lw	a0,0(a0)
ffffffffc0205768:	c31ff06f          	j	ffffffffc0205398 <do_kill>

ffffffffc020576c <sys_yield>:
    return do_yield();
ffffffffc020576c:	bdfff06f          	j	ffffffffc020534a <do_yield>

ffffffffc0205770 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205770:	6d14                	ld	a3,24(a0)
ffffffffc0205772:	6910                	ld	a2,16(a0)
ffffffffc0205774:	650c                	ld	a1,8(a0)
ffffffffc0205776:	6108                	ld	a0,0(a0)
ffffffffc0205778:	edcff06f          	j	ffffffffc0204e54 <do_execve>

ffffffffc020577c <sys_wait>:
    return do_wait(pid, store);
ffffffffc020577c:	650c                	ld	a1,8(a0)
ffffffffc020577e:	4108                	lw	a0,0(a0)
ffffffffc0205780:	bdbff06f          	j	ffffffffc020535a <do_wait>

ffffffffc0205784 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205784:	000d5797          	auipc	a5,0xd5
ffffffffc0205788:	e547b783          	ld	a5,-428(a5) # ffffffffc02da5d8 <current>
ffffffffc020578c:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020578e:	4501                	li	a0,0
ffffffffc0205790:	6a0c                	ld	a1,16(a2)
ffffffffc0205792:	dd7fe06f          	j	ffffffffc0204568 <do_fork>

ffffffffc0205796 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205796:	4108                	lw	a0,0(a0)
ffffffffc0205798:	a7cff06f          	j	ffffffffc0204a14 <do_exit>

ffffffffc020579c <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc020579c:	715d                	addi	sp,sp,-80
ffffffffc020579e:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02057a0:	000d5497          	auipc	s1,0xd5
ffffffffc02057a4:	e3848493          	addi	s1,s1,-456 # ffffffffc02da5d8 <current>
ffffffffc02057a8:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02057aa:	e0a2                	sd	s0,64(sp)
ffffffffc02057ac:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02057ae:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02057b0:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02057b2:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02057b4:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02057b8:	0327ee63          	bltu	a5,s2,ffffffffc02057f4 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc02057bc:	00391713          	slli	a4,s2,0x3
ffffffffc02057c0:	00002797          	auipc	a5,0x2
ffffffffc02057c4:	65078793          	addi	a5,a5,1616 # ffffffffc0207e10 <syscalls>
ffffffffc02057c8:	97ba                	add	a5,a5,a4
ffffffffc02057ca:	639c                	ld	a5,0(a5)
ffffffffc02057cc:	c785                	beqz	a5,ffffffffc02057f4 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc02057ce:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02057d0:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02057d2:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02057d4:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02057d6:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02057d8:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02057da:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02057dc:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02057de:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02057e0:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02057e2:	0028                	addi	a0,sp,8
ffffffffc02057e4:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02057e6:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02057e8:	e828                	sd	a0,80(s0)
}
ffffffffc02057ea:	6406                	ld	s0,64(sp)
ffffffffc02057ec:	74e2                	ld	s1,56(sp)
ffffffffc02057ee:	7942                	ld	s2,48(sp)
ffffffffc02057f0:	6161                	addi	sp,sp,80
ffffffffc02057f2:	8082                	ret
    print_trapframe(tf);
ffffffffc02057f4:	8522                	mv	a0,s0
ffffffffc02057f6:	baefb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02057fa:	609c                	ld	a5,0(s1)
ffffffffc02057fc:	86ca                	mv	a3,s2
ffffffffc02057fe:	00002617          	auipc	a2,0x2
ffffffffc0205802:	5ca60613          	addi	a2,a2,1482 # ffffffffc0207dc8 <default_pmm_manager+0x1208>
ffffffffc0205806:	43d8                	lw	a4,4(a5)
ffffffffc0205808:	06200593          	li	a1,98
ffffffffc020580c:	0b478793          	addi	a5,a5,180
ffffffffc0205810:	00002517          	auipc	a0,0x2
ffffffffc0205814:	5e850513          	addi	a0,a0,1512 # ffffffffc0207df8 <default_pmm_manager+0x1238>
ffffffffc0205818:	c77fa0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020581c <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020581c:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205820:	2785                	addiw	a5,a5,1
ffffffffc0205822:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205826:	02000793          	li	a5,32
ffffffffc020582a:	9f8d                	subw	a5,a5,a1
}
ffffffffc020582c:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205830:	8082                	ret

ffffffffc0205832 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205832:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205836:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205838:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020583c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020583e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205842:	f022                	sd	s0,32(sp)
ffffffffc0205844:	ec26                	sd	s1,24(sp)
ffffffffc0205846:	e84a                	sd	s2,16(sp)
ffffffffc0205848:	f406                	sd	ra,40(sp)
ffffffffc020584a:	e44e                	sd	s3,8(sp)
ffffffffc020584c:	84aa                	mv	s1,a0
ffffffffc020584e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205850:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205854:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205856:	03067e63          	bgeu	a2,a6,ffffffffc0205892 <printnum+0x60>
ffffffffc020585a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020585c:	00805763          	blez	s0,ffffffffc020586a <printnum+0x38>
ffffffffc0205860:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205862:	85ca                	mv	a1,s2
ffffffffc0205864:	854e                	mv	a0,s3
ffffffffc0205866:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205868:	fc65                	bnez	s0,ffffffffc0205860 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020586a:	1a02                	slli	s4,s4,0x20
ffffffffc020586c:	00002797          	auipc	a5,0x2
ffffffffc0205870:	6a478793          	addi	a5,a5,1700 # ffffffffc0207f10 <syscalls+0x100>
ffffffffc0205874:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205878:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020587a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020587c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205880:	70a2                	ld	ra,40(sp)
ffffffffc0205882:	69a2                	ld	s3,8(sp)
ffffffffc0205884:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205886:	85ca                	mv	a1,s2
ffffffffc0205888:	87a6                	mv	a5,s1
}
ffffffffc020588a:	6942                	ld	s2,16(sp)
ffffffffc020588c:	64e2                	ld	s1,24(sp)
ffffffffc020588e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205890:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205892:	03065633          	divu	a2,a2,a6
ffffffffc0205896:	8722                	mv	a4,s0
ffffffffc0205898:	f9bff0ef          	jal	ra,ffffffffc0205832 <printnum>
ffffffffc020589c:	b7f9                	j	ffffffffc020586a <printnum+0x38>

ffffffffc020589e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020589e:	7119                	addi	sp,sp,-128
ffffffffc02058a0:	f4a6                	sd	s1,104(sp)
ffffffffc02058a2:	f0ca                	sd	s2,96(sp)
ffffffffc02058a4:	ecce                	sd	s3,88(sp)
ffffffffc02058a6:	e8d2                	sd	s4,80(sp)
ffffffffc02058a8:	e4d6                	sd	s5,72(sp)
ffffffffc02058aa:	e0da                	sd	s6,64(sp)
ffffffffc02058ac:	fc5e                	sd	s7,56(sp)
ffffffffc02058ae:	f06a                	sd	s10,32(sp)
ffffffffc02058b0:	fc86                	sd	ra,120(sp)
ffffffffc02058b2:	f8a2                	sd	s0,112(sp)
ffffffffc02058b4:	f862                	sd	s8,48(sp)
ffffffffc02058b6:	f466                	sd	s9,40(sp)
ffffffffc02058b8:	ec6e                	sd	s11,24(sp)
ffffffffc02058ba:	892a                	mv	s2,a0
ffffffffc02058bc:	84ae                	mv	s1,a1
ffffffffc02058be:	8d32                	mv	s10,a2
ffffffffc02058c0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02058c2:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02058c6:	5b7d                	li	s6,-1
ffffffffc02058c8:	00002a97          	auipc	s5,0x2
ffffffffc02058cc:	674a8a93          	addi	s5,s5,1652 # ffffffffc0207f3c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02058d0:	00003b97          	auipc	s7,0x3
ffffffffc02058d4:	888b8b93          	addi	s7,s7,-1912 # ffffffffc0208158 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02058d8:	000d4503          	lbu	a0,0(s10)
ffffffffc02058dc:	001d0413          	addi	s0,s10,1
ffffffffc02058e0:	01350a63          	beq	a0,s3,ffffffffc02058f4 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02058e4:	c121                	beqz	a0,ffffffffc0205924 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02058e6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02058e8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02058ea:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02058ec:	fff44503          	lbu	a0,-1(s0)
ffffffffc02058f0:	ff351ae3          	bne	a0,s3,ffffffffc02058e4 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02058f4:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02058f8:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02058fc:	4c81                	li	s9,0
ffffffffc02058fe:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0205900:	5c7d                	li	s8,-1
ffffffffc0205902:	5dfd                	li	s11,-1
ffffffffc0205904:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0205908:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020590a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020590e:	0ff5f593          	zext.b	a1,a1
ffffffffc0205912:	00140d13          	addi	s10,s0,1
ffffffffc0205916:	04b56263          	bltu	a0,a1,ffffffffc020595a <vprintfmt+0xbc>
ffffffffc020591a:	058a                	slli	a1,a1,0x2
ffffffffc020591c:	95d6                	add	a1,a1,s5
ffffffffc020591e:	4194                	lw	a3,0(a1)
ffffffffc0205920:	96d6                	add	a3,a3,s5
ffffffffc0205922:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0205924:	70e6                	ld	ra,120(sp)
ffffffffc0205926:	7446                	ld	s0,112(sp)
ffffffffc0205928:	74a6                	ld	s1,104(sp)
ffffffffc020592a:	7906                	ld	s2,96(sp)
ffffffffc020592c:	69e6                	ld	s3,88(sp)
ffffffffc020592e:	6a46                	ld	s4,80(sp)
ffffffffc0205930:	6aa6                	ld	s5,72(sp)
ffffffffc0205932:	6b06                	ld	s6,64(sp)
ffffffffc0205934:	7be2                	ld	s7,56(sp)
ffffffffc0205936:	7c42                	ld	s8,48(sp)
ffffffffc0205938:	7ca2                	ld	s9,40(sp)
ffffffffc020593a:	7d02                	ld	s10,32(sp)
ffffffffc020593c:	6de2                	ld	s11,24(sp)
ffffffffc020593e:	6109                	addi	sp,sp,128
ffffffffc0205940:	8082                	ret
            padc = '0';
ffffffffc0205942:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205944:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205948:	846a                	mv	s0,s10
ffffffffc020594a:	00140d13          	addi	s10,s0,1
ffffffffc020594e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205952:	0ff5f593          	zext.b	a1,a1
ffffffffc0205956:	fcb572e3          	bgeu	a0,a1,ffffffffc020591a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020595a:	85a6                	mv	a1,s1
ffffffffc020595c:	02500513          	li	a0,37
ffffffffc0205960:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205962:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205966:	8d22                	mv	s10,s0
ffffffffc0205968:	f73788e3          	beq	a5,s3,ffffffffc02058d8 <vprintfmt+0x3a>
ffffffffc020596c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205970:	1d7d                	addi	s10,s10,-1
ffffffffc0205972:	ff379de3          	bne	a5,s3,ffffffffc020596c <vprintfmt+0xce>
ffffffffc0205976:	b78d                	j	ffffffffc02058d8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205978:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020597c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205980:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205982:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205986:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020598a:	02d86463          	bltu	a6,a3,ffffffffc02059b2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020598e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205992:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205996:	0186873b          	addw	a4,a3,s8
ffffffffc020599a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020599e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02059a0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02059a4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02059a6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02059aa:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02059ae:	fed870e3          	bgeu	a6,a3,ffffffffc020598e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02059b2:	f40ddce3          	bgez	s11,ffffffffc020590a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02059b6:	8de2                	mv	s11,s8
ffffffffc02059b8:	5c7d                	li	s8,-1
ffffffffc02059ba:	bf81                	j	ffffffffc020590a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02059bc:	fffdc693          	not	a3,s11
ffffffffc02059c0:	96fd                	srai	a3,a3,0x3f
ffffffffc02059c2:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059c6:	00144603          	lbu	a2,1(s0)
ffffffffc02059ca:	2d81                	sext.w	s11,s11
ffffffffc02059cc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02059ce:	bf35                	j	ffffffffc020590a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02059d0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059d4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02059d8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059da:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02059dc:	bfd9                	j	ffffffffc02059b2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02059de:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02059e0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02059e4:	01174463          	blt	a4,a7,ffffffffc02059ec <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02059e8:	1a088e63          	beqz	a7,ffffffffc0205ba4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02059ec:	000a3603          	ld	a2,0(s4)
ffffffffc02059f0:	46c1                	li	a3,16
ffffffffc02059f2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02059f4:	2781                	sext.w	a5,a5
ffffffffc02059f6:	876e                	mv	a4,s11
ffffffffc02059f8:	85a6                	mv	a1,s1
ffffffffc02059fa:	854a                	mv	a0,s2
ffffffffc02059fc:	e37ff0ef          	jal	ra,ffffffffc0205832 <printnum>
            break;
ffffffffc0205a00:	bde1                	j	ffffffffc02058d8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205a02:	000a2503          	lw	a0,0(s4)
ffffffffc0205a06:	85a6                	mv	a1,s1
ffffffffc0205a08:	0a21                	addi	s4,s4,8
ffffffffc0205a0a:	9902                	jalr	s2
            break;
ffffffffc0205a0c:	b5f1                	j	ffffffffc02058d8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205a0e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205a10:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205a14:	01174463          	blt	a4,a7,ffffffffc0205a1c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0205a18:	18088163          	beqz	a7,ffffffffc0205b9a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0205a1c:	000a3603          	ld	a2,0(s4)
ffffffffc0205a20:	46a9                	li	a3,10
ffffffffc0205a22:	8a2e                	mv	s4,a1
ffffffffc0205a24:	bfc1                	j	ffffffffc02059f4 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a26:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0205a2a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a2c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205a2e:	bdf1                	j	ffffffffc020590a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205a30:	85a6                	mv	a1,s1
ffffffffc0205a32:	02500513          	li	a0,37
ffffffffc0205a36:	9902                	jalr	s2
            break;
ffffffffc0205a38:	b545                	j	ffffffffc02058d8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a3a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0205a3e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205a40:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205a42:	b5e1                	j	ffffffffc020590a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205a44:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205a46:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205a4a:	01174463          	blt	a4,a7,ffffffffc0205a52 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0205a4e:	14088163          	beqz	a7,ffffffffc0205b90 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0205a52:	000a3603          	ld	a2,0(s4)
ffffffffc0205a56:	46a1                	li	a3,8
ffffffffc0205a58:	8a2e                	mv	s4,a1
ffffffffc0205a5a:	bf69                	j	ffffffffc02059f4 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0205a5c:	03000513          	li	a0,48
ffffffffc0205a60:	85a6                	mv	a1,s1
ffffffffc0205a62:	e03e                	sd	a5,0(sp)
ffffffffc0205a64:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205a66:	85a6                	mv	a1,s1
ffffffffc0205a68:	07800513          	li	a0,120
ffffffffc0205a6c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205a6e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205a70:	6782                	ld	a5,0(sp)
ffffffffc0205a72:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205a74:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205a78:	bfb5                	j	ffffffffc02059f4 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205a7a:	000a3403          	ld	s0,0(s4)
ffffffffc0205a7e:	008a0713          	addi	a4,s4,8
ffffffffc0205a82:	e03a                	sd	a4,0(sp)
ffffffffc0205a84:	14040263          	beqz	s0,ffffffffc0205bc8 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205a88:	0fb05763          	blez	s11,ffffffffc0205b76 <vprintfmt+0x2d8>
ffffffffc0205a8c:	02d00693          	li	a3,45
ffffffffc0205a90:	0cd79163          	bne	a5,a3,ffffffffc0205b52 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205a94:	00044783          	lbu	a5,0(s0)
ffffffffc0205a98:	0007851b          	sext.w	a0,a5
ffffffffc0205a9c:	cf85                	beqz	a5,ffffffffc0205ad4 <vprintfmt+0x236>
ffffffffc0205a9e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205aa2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205aa6:	000c4563          	bltz	s8,ffffffffc0205ab0 <vprintfmt+0x212>
ffffffffc0205aaa:	3c7d                	addiw	s8,s8,-1
ffffffffc0205aac:	036c0263          	beq	s8,s6,ffffffffc0205ad0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205ab0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205ab2:	0e0c8e63          	beqz	s9,ffffffffc0205bae <vprintfmt+0x310>
ffffffffc0205ab6:	3781                	addiw	a5,a5,-32
ffffffffc0205ab8:	0ef47b63          	bgeu	s0,a5,ffffffffc0205bae <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205abc:	03f00513          	li	a0,63
ffffffffc0205ac0:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205ac2:	000a4783          	lbu	a5,0(s4)
ffffffffc0205ac6:	3dfd                	addiw	s11,s11,-1
ffffffffc0205ac8:	0a05                	addi	s4,s4,1
ffffffffc0205aca:	0007851b          	sext.w	a0,a5
ffffffffc0205ace:	ffe1                	bnez	a5,ffffffffc0205aa6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205ad0:	01b05963          	blez	s11,ffffffffc0205ae2 <vprintfmt+0x244>
ffffffffc0205ad4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0205ad6:	85a6                	mv	a1,s1
ffffffffc0205ad8:	02000513          	li	a0,32
ffffffffc0205adc:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205ade:	fe0d9be3          	bnez	s11,ffffffffc0205ad4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205ae2:	6a02                	ld	s4,0(sp)
ffffffffc0205ae4:	bbd5                	j	ffffffffc02058d8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0205ae6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205ae8:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205aec:	01174463          	blt	a4,a7,ffffffffc0205af4 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205af0:	08088d63          	beqz	a7,ffffffffc0205b8a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0205af4:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205af8:	0a044d63          	bltz	s0,ffffffffc0205bb2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205afc:	8622                	mv	a2,s0
ffffffffc0205afe:	8a66                	mv	s4,s9
ffffffffc0205b00:	46a9                	li	a3,10
ffffffffc0205b02:	bdcd                	j	ffffffffc02059f4 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0205b04:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205b08:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0205b0a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205b0c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0205b10:	8fb5                	xor	a5,a5,a3
ffffffffc0205b12:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205b16:	02d74163          	blt	a4,a3,ffffffffc0205b38 <vprintfmt+0x29a>
ffffffffc0205b1a:	00369793          	slli	a5,a3,0x3
ffffffffc0205b1e:	97de                	add	a5,a5,s7
ffffffffc0205b20:	639c                	ld	a5,0(a5)
ffffffffc0205b22:	cb99                	beqz	a5,ffffffffc0205b38 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205b24:	86be                	mv	a3,a5
ffffffffc0205b26:	00000617          	auipc	a2,0x0
ffffffffc0205b2a:	1f260613          	addi	a2,a2,498 # ffffffffc0205d18 <etext+0x2c>
ffffffffc0205b2e:	85a6                	mv	a1,s1
ffffffffc0205b30:	854a                	mv	a0,s2
ffffffffc0205b32:	0ce000ef          	jal	ra,ffffffffc0205c00 <printfmt>
ffffffffc0205b36:	b34d                	j	ffffffffc02058d8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205b38:	00002617          	auipc	a2,0x2
ffffffffc0205b3c:	3f860613          	addi	a2,a2,1016 # ffffffffc0207f30 <syscalls+0x120>
ffffffffc0205b40:	85a6                	mv	a1,s1
ffffffffc0205b42:	854a                	mv	a0,s2
ffffffffc0205b44:	0bc000ef          	jal	ra,ffffffffc0205c00 <printfmt>
ffffffffc0205b48:	bb41                	j	ffffffffc02058d8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0205b4a:	00002417          	auipc	s0,0x2
ffffffffc0205b4e:	3de40413          	addi	s0,s0,990 # ffffffffc0207f28 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205b52:	85e2                	mv	a1,s8
ffffffffc0205b54:	8522                	mv	a0,s0
ffffffffc0205b56:	e43e                	sd	a5,8(sp)
ffffffffc0205b58:	0e2000ef          	jal	ra,ffffffffc0205c3a <strnlen>
ffffffffc0205b5c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205b60:	01b05b63          	blez	s11,ffffffffc0205b76 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205b64:	67a2                	ld	a5,8(sp)
ffffffffc0205b66:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205b6a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205b6c:	85a6                	mv	a1,s1
ffffffffc0205b6e:	8552                	mv	a0,s4
ffffffffc0205b70:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205b72:	fe0d9ce3          	bnez	s11,ffffffffc0205b6a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205b76:	00044783          	lbu	a5,0(s0)
ffffffffc0205b7a:	00140a13          	addi	s4,s0,1
ffffffffc0205b7e:	0007851b          	sext.w	a0,a5
ffffffffc0205b82:	d3a5                	beqz	a5,ffffffffc0205ae2 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205b84:	05e00413          	li	s0,94
ffffffffc0205b88:	bf39                	j	ffffffffc0205aa6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205b8a:	000a2403          	lw	s0,0(s4)
ffffffffc0205b8e:	b7ad                	j	ffffffffc0205af8 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205b90:	000a6603          	lwu	a2,0(s4)
ffffffffc0205b94:	46a1                	li	a3,8
ffffffffc0205b96:	8a2e                	mv	s4,a1
ffffffffc0205b98:	bdb1                	j	ffffffffc02059f4 <vprintfmt+0x156>
ffffffffc0205b9a:	000a6603          	lwu	a2,0(s4)
ffffffffc0205b9e:	46a9                	li	a3,10
ffffffffc0205ba0:	8a2e                	mv	s4,a1
ffffffffc0205ba2:	bd89                	j	ffffffffc02059f4 <vprintfmt+0x156>
ffffffffc0205ba4:	000a6603          	lwu	a2,0(s4)
ffffffffc0205ba8:	46c1                	li	a3,16
ffffffffc0205baa:	8a2e                	mv	s4,a1
ffffffffc0205bac:	b5a1                	j	ffffffffc02059f4 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205bae:	9902                	jalr	s2
ffffffffc0205bb0:	bf09                	j	ffffffffc0205ac2 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205bb2:	85a6                	mv	a1,s1
ffffffffc0205bb4:	02d00513          	li	a0,45
ffffffffc0205bb8:	e03e                	sd	a5,0(sp)
ffffffffc0205bba:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205bbc:	6782                	ld	a5,0(sp)
ffffffffc0205bbe:	8a66                	mv	s4,s9
ffffffffc0205bc0:	40800633          	neg	a2,s0
ffffffffc0205bc4:	46a9                	li	a3,10
ffffffffc0205bc6:	b53d                	j	ffffffffc02059f4 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205bc8:	03b05163          	blez	s11,ffffffffc0205bea <vprintfmt+0x34c>
ffffffffc0205bcc:	02d00693          	li	a3,45
ffffffffc0205bd0:	f6d79de3          	bne	a5,a3,ffffffffc0205b4a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0205bd4:	00002417          	auipc	s0,0x2
ffffffffc0205bd8:	35440413          	addi	s0,s0,852 # ffffffffc0207f28 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205bdc:	02800793          	li	a5,40
ffffffffc0205be0:	02800513          	li	a0,40
ffffffffc0205be4:	00140a13          	addi	s4,s0,1
ffffffffc0205be8:	bd6d                	j	ffffffffc0205aa2 <vprintfmt+0x204>
ffffffffc0205bea:	00002a17          	auipc	s4,0x2
ffffffffc0205bee:	33fa0a13          	addi	s4,s4,831 # ffffffffc0207f29 <syscalls+0x119>
ffffffffc0205bf2:	02800513          	li	a0,40
ffffffffc0205bf6:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205bfa:	05e00413          	li	s0,94
ffffffffc0205bfe:	b565                	j	ffffffffc0205aa6 <vprintfmt+0x208>

ffffffffc0205c00 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205c00:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205c02:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205c06:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205c08:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205c0a:	ec06                	sd	ra,24(sp)
ffffffffc0205c0c:	f83a                	sd	a4,48(sp)
ffffffffc0205c0e:	fc3e                	sd	a5,56(sp)
ffffffffc0205c10:	e0c2                	sd	a6,64(sp)
ffffffffc0205c12:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205c14:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205c16:	c89ff0ef          	jal	ra,ffffffffc020589e <vprintfmt>
}
ffffffffc0205c1a:	60e2                	ld	ra,24(sp)
ffffffffc0205c1c:	6161                	addi	sp,sp,80
ffffffffc0205c1e:	8082                	ret

ffffffffc0205c20 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205c20:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0205c24:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0205c26:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0205c28:	cb81                	beqz	a5,ffffffffc0205c38 <strlen+0x18>
        cnt ++;
ffffffffc0205c2a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0205c2c:	00a707b3          	add	a5,a4,a0
ffffffffc0205c30:	0007c783          	lbu	a5,0(a5)
ffffffffc0205c34:	fbfd                	bnez	a5,ffffffffc0205c2a <strlen+0xa>
ffffffffc0205c36:	8082                	ret
    }
    return cnt;
}
ffffffffc0205c38:	8082                	ret

ffffffffc0205c3a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205c3a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205c3c:	e589                	bnez	a1,ffffffffc0205c46 <strnlen+0xc>
ffffffffc0205c3e:	a811                	j	ffffffffc0205c52 <strnlen+0x18>
        cnt ++;
ffffffffc0205c40:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205c42:	00f58863          	beq	a1,a5,ffffffffc0205c52 <strnlen+0x18>
ffffffffc0205c46:	00f50733          	add	a4,a0,a5
ffffffffc0205c4a:	00074703          	lbu	a4,0(a4)
ffffffffc0205c4e:	fb6d                	bnez	a4,ffffffffc0205c40 <strnlen+0x6>
ffffffffc0205c50:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205c52:	852e                	mv	a0,a1
ffffffffc0205c54:	8082                	ret

ffffffffc0205c56 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205c56:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205c58:	0005c703          	lbu	a4,0(a1)
ffffffffc0205c5c:	0785                	addi	a5,a5,1
ffffffffc0205c5e:	0585                	addi	a1,a1,1
ffffffffc0205c60:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205c64:	fb75                	bnez	a4,ffffffffc0205c58 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205c66:	8082                	ret

ffffffffc0205c68 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205c68:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205c6c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205c70:	cb89                	beqz	a5,ffffffffc0205c82 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205c72:	0505                	addi	a0,a0,1
ffffffffc0205c74:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205c76:	fee789e3          	beq	a5,a4,ffffffffc0205c68 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205c7a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205c7e:	9d19                	subw	a0,a0,a4
ffffffffc0205c80:	8082                	ret
ffffffffc0205c82:	4501                	li	a0,0
ffffffffc0205c84:	bfed                	j	ffffffffc0205c7e <strcmp+0x16>

ffffffffc0205c86 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205c86:	c20d                	beqz	a2,ffffffffc0205ca8 <strncmp+0x22>
ffffffffc0205c88:	962e                	add	a2,a2,a1
ffffffffc0205c8a:	a031                	j	ffffffffc0205c96 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205c8c:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205c8e:	00e79a63          	bne	a5,a4,ffffffffc0205ca2 <strncmp+0x1c>
ffffffffc0205c92:	00b60b63          	beq	a2,a1,ffffffffc0205ca8 <strncmp+0x22>
ffffffffc0205c96:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205c9a:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205c9c:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205ca0:	f7f5                	bnez	a5,ffffffffc0205c8c <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205ca2:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205ca6:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205ca8:	4501                	li	a0,0
ffffffffc0205caa:	8082                	ret

ffffffffc0205cac <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205cac:	00054783          	lbu	a5,0(a0)
ffffffffc0205cb0:	c799                	beqz	a5,ffffffffc0205cbe <strchr+0x12>
        if (*s == c) {
ffffffffc0205cb2:	00f58763          	beq	a1,a5,ffffffffc0205cc0 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205cb6:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205cba:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205cbc:	fbfd                	bnez	a5,ffffffffc0205cb2 <strchr+0x6>
    }
    return NULL;
ffffffffc0205cbe:	4501                	li	a0,0
}
ffffffffc0205cc0:	8082                	ret

ffffffffc0205cc2 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205cc2:	ca01                	beqz	a2,ffffffffc0205cd2 <memset+0x10>
ffffffffc0205cc4:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205cc6:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205cc8:	0785                	addi	a5,a5,1
ffffffffc0205cca:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205cce:	fec79de3          	bne	a5,a2,ffffffffc0205cc8 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205cd2:	8082                	ret

ffffffffc0205cd4 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205cd4:	ca19                	beqz	a2,ffffffffc0205cea <memcpy+0x16>
ffffffffc0205cd6:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205cd8:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205cda:	0005c703          	lbu	a4,0(a1)
ffffffffc0205cde:	0585                	addi	a1,a1,1
ffffffffc0205ce0:	0785                	addi	a5,a5,1
ffffffffc0205ce2:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205ce6:	fec59ae3          	bne	a1,a2,ffffffffc0205cda <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205cea:	8082                	ret
