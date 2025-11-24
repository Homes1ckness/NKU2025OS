
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
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
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	09028293          	addi	t0,t0,144 # ffffffffc0200090 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <test_exceptions>:

void grade_backtrace(void) { grade_backtrace0(0, (uintptr_t)kern_init, 0xffff0000); }

// LAB3 CHALLENGE3: 异常测试函数
void test_exceptions(void)
{
ffffffffc0200054:	1141                	addi	sp,sp,-16
    // 测试断点异常
    cprintf("Testing breakpoint exception...\n");
ffffffffc0200056:	00002517          	auipc	a0,0x2
ffffffffc020005a:	efa50513          	addi	a0,a0,-262 # ffffffffc0201f50 <etext+0x6>
{
ffffffffc020005e:	e406                	sd	ra,8(sp)
    cprintf("Testing breakpoint exception...\n");
ffffffffc0200060:	0b8000ef          	jal	ra,ffffffffc0200118 <cprintf>
    asm volatile("ebreak");
ffffffffc0200064:	9002                	ebreak
    cprintf("After ebreak: breakpoint exception handled successfully!\n");
ffffffffc0200066:	00002517          	auipc	a0,0x2
ffffffffc020006a:	f1250513          	addi	a0,a0,-238 # ffffffffc0201f78 <etext+0x2e>
ffffffffc020006e:	0aa000ef          	jal	ra,ffffffffc0200118 <cprintf>

    // 测试非法指令异常
    cprintf("\nTesting illegal instruction exception...\n");
ffffffffc0200072:	00002517          	auipc	a0,0x2
ffffffffc0200076:	f4650513          	addi	a0,a0,-186 # ffffffffc0201fb8 <etext+0x6e>
ffffffffc020007a:	09e000ef          	jal	ra,ffffffffc0200118 <cprintf>
ffffffffc020007e:	0000                	unimp
ffffffffc0200080:	0000                	unimp
    asm volatile(".word 0x00000000"); // 未定义指令
    cprintf("After illegal instruction: exception handled successfully!\n");
}
ffffffffc0200082:	60a2                	ld	ra,8(sp)
    cprintf("After illegal instruction: exception handled successfully!\n");
ffffffffc0200084:	00002517          	auipc	a0,0x2
ffffffffc0200088:	f6450513          	addi	a0,a0,-156 # ffffffffc0201fe8 <etext+0x9e>
}
ffffffffc020008c:	0141                	addi	sp,sp,16
    cprintf("After illegal instruction: exception handled successfully!\n");
ffffffffc020008e:	a069                	j	ffffffffc0200118 <cprintf>

ffffffffc0200090 <kern_init>:
    memset(edata, 0, end - edata);
ffffffffc0200090:	00007517          	auipc	a0,0x7
ffffffffc0200094:	f9850513          	addi	a0,a0,-104 # ffffffffc0207028 <free_area>
ffffffffc0200098:	00007617          	auipc	a2,0x7
ffffffffc020009c:	40060613          	addi	a2,a2,1024 # ffffffffc0207498 <end>
{
ffffffffc02000a0:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000a2:	8e09                	sub	a2,a2,a0
ffffffffc02000a4:	4581                	li	a1,0
{
ffffffffc02000a6:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000a8:	185010ef          	jal	ra,ffffffffc0201a2c <memset>
    dtb_init();
ffffffffc02000ac:	3c2000ef          	jal	ra,ffffffffc020046e <dtb_init>
    cons_init(); // init the console
ffffffffc02000b0:	7b2000ef          	jal	ra,ffffffffc0200862 <cons_init>
    cputs(message);
ffffffffc02000b4:	00002517          	auipc	a0,0x2
ffffffffc02000b8:	f7450513          	addi	a0,a0,-140 # ffffffffc0202028 <etext+0xde>
ffffffffc02000bc:	094000ef          	jal	ra,ffffffffc0200150 <cputs>
    print_kerninfo();
ffffffffc02000c0:	13c000ef          	jal	ra,ffffffffc02001fc <print_kerninfo>
    idt_init(); // init interrupt descriptor table
ffffffffc02000c4:	7b8000ef          	jal	ra,ffffffffc020087c <idt_init>
    pmm_init(); // init physical memory management
ffffffffc02000c8:	4d9000ef          	jal	ra,ffffffffc0200da0 <pmm_init>
    idt_init(); // init interrupt descriptor table
ffffffffc02000cc:	7b0000ef          	jal	ra,ffffffffc020087c <idt_init>
    clock_init();  // init clock interrupt
ffffffffc02000d0:	74e000ef          	jal	ra,ffffffffc020081e <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000d4:	79c000ef          	jal	ra,ffffffffc0200870 <intr_enable>
    test_exceptions();
ffffffffc02000d8:	f7dff0ef          	jal	ra,ffffffffc0200054 <test_exceptions>
    while (1)
ffffffffc02000dc:	a001                	j	ffffffffc02000dc <kern_init+0x4c>

ffffffffc02000de <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000de:	1141                	addi	sp,sp,-16
ffffffffc02000e0:	e022                	sd	s0,0(sp)
ffffffffc02000e2:	e406                	sd	ra,8(sp)
ffffffffc02000e4:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000e6:	77e000ef          	jal	ra,ffffffffc0200864 <cons_putc>
    (*cnt) ++;
ffffffffc02000ea:	401c                	lw	a5,0(s0)
}
ffffffffc02000ec:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000ee:	2785                	addiw	a5,a5,1
ffffffffc02000f0:	c01c                	sw	a5,0(s0)
}
ffffffffc02000f2:	6402                	ld	s0,0(sp)
ffffffffc02000f4:	0141                	addi	sp,sp,16
ffffffffc02000f6:	8082                	ret

ffffffffc02000f8 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000f8:	1101                	addi	sp,sp,-32
ffffffffc02000fa:	862a                	mv	a2,a0
ffffffffc02000fc:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000fe:	00000517          	auipc	a0,0x0
ffffffffc0200102:	fe050513          	addi	a0,a0,-32 # ffffffffc02000de <cputch>
ffffffffc0200106:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200108:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020010a:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020010c:	19f010ef          	jal	ra,ffffffffc0201aaa <vprintfmt>
    return cnt;
}
ffffffffc0200110:	60e2                	ld	ra,24(sp)
ffffffffc0200112:	4532                	lw	a0,12(sp)
ffffffffc0200114:	6105                	addi	sp,sp,32
ffffffffc0200116:	8082                	ret

ffffffffc0200118 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200118:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020011a:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc020011e:	8e2a                	mv	t3,a0
ffffffffc0200120:	f42e                	sd	a1,40(sp)
ffffffffc0200122:	f832                	sd	a2,48(sp)
ffffffffc0200124:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200126:	00000517          	auipc	a0,0x0
ffffffffc020012a:	fb850513          	addi	a0,a0,-72 # ffffffffc02000de <cputch>
ffffffffc020012e:	004c                	addi	a1,sp,4
ffffffffc0200130:	869a                	mv	a3,t1
ffffffffc0200132:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200134:	ec06                	sd	ra,24(sp)
ffffffffc0200136:	e0ba                	sd	a4,64(sp)
ffffffffc0200138:	e4be                	sd	a5,72(sp)
ffffffffc020013a:	e8c2                	sd	a6,80(sp)
ffffffffc020013c:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020013e:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200140:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200142:	169010ef          	jal	ra,ffffffffc0201aaa <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200146:	60e2                	ld	ra,24(sp)
ffffffffc0200148:	4512                	lw	a0,4(sp)
ffffffffc020014a:	6125                	addi	sp,sp,96
ffffffffc020014c:	8082                	ret

ffffffffc020014e <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020014e:	af19                	j	ffffffffc0200864 <cons_putc>

ffffffffc0200150 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200150:	1101                	addi	sp,sp,-32
ffffffffc0200152:	e822                	sd	s0,16(sp)
ffffffffc0200154:	ec06                	sd	ra,24(sp)
ffffffffc0200156:	e426                	sd	s1,8(sp)
ffffffffc0200158:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020015a:	00054503          	lbu	a0,0(a0)
ffffffffc020015e:	c51d                	beqz	a0,ffffffffc020018c <cputs+0x3c>
ffffffffc0200160:	0405                	addi	s0,s0,1
ffffffffc0200162:	4485                	li	s1,1
ffffffffc0200164:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200166:	6fe000ef          	jal	ra,ffffffffc0200864 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020016a:	00044503          	lbu	a0,0(s0)
ffffffffc020016e:	008487bb          	addw	a5,s1,s0
ffffffffc0200172:	0405                	addi	s0,s0,1
ffffffffc0200174:	f96d                	bnez	a0,ffffffffc0200166 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200176:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020017a:	4529                	li	a0,10
ffffffffc020017c:	6e8000ef          	jal	ra,ffffffffc0200864 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200180:	60e2                	ld	ra,24(sp)
ffffffffc0200182:	8522                	mv	a0,s0
ffffffffc0200184:	6442                	ld	s0,16(sp)
ffffffffc0200186:	64a2                	ld	s1,8(sp)
ffffffffc0200188:	6105                	addi	sp,sp,32
ffffffffc020018a:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	4405                	li	s0,1
ffffffffc020018e:	b7f5                	j	ffffffffc020017a <cputs+0x2a>

ffffffffc0200190 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200190:	1141                	addi	sp,sp,-16
ffffffffc0200192:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200194:	6d8000ef          	jal	ra,ffffffffc020086c <cons_getc>
ffffffffc0200198:	dd75                	beqz	a0,ffffffffc0200194 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020019a:	60a2                	ld	ra,8(sp)
ffffffffc020019c:	0141                	addi	sp,sp,16
ffffffffc020019e:	8082                	ret

ffffffffc02001a0 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001a0:	00007317          	auipc	t1,0x7
ffffffffc02001a4:	2a030313          	addi	t1,t1,672 # ffffffffc0207440 <is_panic>
ffffffffc02001a8:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ac:	715d                	addi	sp,sp,-80
ffffffffc02001ae:	ec06                	sd	ra,24(sp)
ffffffffc02001b0:	e822                	sd	s0,16(sp)
ffffffffc02001b2:	f436                	sd	a3,40(sp)
ffffffffc02001b4:	f83a                	sd	a4,48(sp)
ffffffffc02001b6:	fc3e                	sd	a5,56(sp)
ffffffffc02001b8:	e0c2                	sd	a6,64(sp)
ffffffffc02001ba:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001bc:	020e1a63          	bnez	t3,ffffffffc02001f0 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02001c0:	4785                	li	a5,1
ffffffffc02001c2:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02001c6:	8432                	mv	s0,a2
ffffffffc02001c8:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ca:	862e                	mv	a2,a1
ffffffffc02001cc:	85aa                	mv	a1,a0
ffffffffc02001ce:	00002517          	auipc	a0,0x2
ffffffffc02001d2:	e7a50513          	addi	a0,a0,-390 # ffffffffc0202048 <etext+0xfe>
    va_start(ap, fmt);
ffffffffc02001d6:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001d8:	f41ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02001dc:	65a2                	ld	a1,8(sp)
ffffffffc02001de:	8522                	mv	a0,s0
ffffffffc02001e0:	f19ff0ef          	jal	ra,ffffffffc02000f8 <vcprintf>
    cprintf("\n");
ffffffffc02001e4:	00002517          	auipc	a0,0x2
ffffffffc02001e8:	dcc50513          	addi	a0,a0,-564 # ffffffffc0201fb0 <etext+0x66>
ffffffffc02001ec:	f2dff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02001f0:	686000ef          	jal	ra,ffffffffc0200876 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02001f4:	4501                	li	a0,0
ffffffffc02001f6:	130000ef          	jal	ra,ffffffffc0200326 <kmonitor>
    while (1) {
ffffffffc02001fa:	bfed                	j	ffffffffc02001f4 <__panic+0x54>

ffffffffc02001fc <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02001fc:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001fe:	00002517          	auipc	a0,0x2
ffffffffc0200202:	e6a50513          	addi	a0,a0,-406 # ffffffffc0202068 <etext+0x11e>
void print_kerninfo(void) {
ffffffffc0200206:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200208:	f11ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020020c:	00000597          	auipc	a1,0x0
ffffffffc0200210:	e8458593          	addi	a1,a1,-380 # ffffffffc0200090 <kern_init>
ffffffffc0200214:	00002517          	auipc	a0,0x2
ffffffffc0200218:	e7450513          	addi	a0,a0,-396 # ffffffffc0202088 <etext+0x13e>
ffffffffc020021c:	efdff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200220:	00002597          	auipc	a1,0x2
ffffffffc0200224:	d2a58593          	addi	a1,a1,-726 # ffffffffc0201f4a <etext>
ffffffffc0200228:	00002517          	auipc	a0,0x2
ffffffffc020022c:	e8050513          	addi	a0,a0,-384 # ffffffffc02020a8 <etext+0x15e>
ffffffffc0200230:	ee9ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200234:	00007597          	auipc	a1,0x7
ffffffffc0200238:	df458593          	addi	a1,a1,-524 # ffffffffc0207028 <free_area>
ffffffffc020023c:	00002517          	auipc	a0,0x2
ffffffffc0200240:	e8c50513          	addi	a0,a0,-372 # ffffffffc02020c8 <etext+0x17e>
ffffffffc0200244:	ed5ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200248:	00007597          	auipc	a1,0x7
ffffffffc020024c:	25058593          	addi	a1,a1,592 # ffffffffc0207498 <end>
ffffffffc0200250:	00002517          	auipc	a0,0x2
ffffffffc0200254:	e9850513          	addi	a0,a0,-360 # ffffffffc02020e8 <etext+0x19e>
ffffffffc0200258:	ec1ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020025c:	00007597          	auipc	a1,0x7
ffffffffc0200260:	63b58593          	addi	a1,a1,1595 # ffffffffc0207897 <end+0x3ff>
ffffffffc0200264:	00000797          	auipc	a5,0x0
ffffffffc0200268:	e2c78793          	addi	a5,a5,-468 # ffffffffc0200090 <kern_init>
ffffffffc020026c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200270:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200274:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200276:	3ff5f593          	andi	a1,a1,1023
ffffffffc020027a:	95be                	add	a1,a1,a5
ffffffffc020027c:	85a9                	srai	a1,a1,0xa
ffffffffc020027e:	00002517          	auipc	a0,0x2
ffffffffc0200282:	e8a50513          	addi	a0,a0,-374 # ffffffffc0202108 <etext+0x1be>
}
ffffffffc0200286:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200288:	bd41                	j	ffffffffc0200118 <cprintf>

ffffffffc020028a <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc020028a:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020028c:	00002617          	auipc	a2,0x2
ffffffffc0200290:	eac60613          	addi	a2,a2,-340 # ffffffffc0202138 <etext+0x1ee>
ffffffffc0200294:	04d00593          	li	a1,77
ffffffffc0200298:	00002517          	auipc	a0,0x2
ffffffffc020029c:	eb850513          	addi	a0,a0,-328 # ffffffffc0202150 <etext+0x206>
void print_stackframe(void) {
ffffffffc02002a0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002a2:	effff0ef          	jal	ra,ffffffffc02001a0 <__panic>

ffffffffc02002a6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a8:	00002617          	auipc	a2,0x2
ffffffffc02002ac:	ec060613          	addi	a2,a2,-320 # ffffffffc0202168 <etext+0x21e>
ffffffffc02002b0:	00002597          	auipc	a1,0x2
ffffffffc02002b4:	ed858593          	addi	a1,a1,-296 # ffffffffc0202188 <etext+0x23e>
ffffffffc02002b8:	00002517          	auipc	a0,0x2
ffffffffc02002bc:	ed850513          	addi	a0,a0,-296 # ffffffffc0202190 <etext+0x246>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002c0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c2:	e57ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
ffffffffc02002c6:	00002617          	auipc	a2,0x2
ffffffffc02002ca:	eda60613          	addi	a2,a2,-294 # ffffffffc02021a0 <etext+0x256>
ffffffffc02002ce:	00002597          	auipc	a1,0x2
ffffffffc02002d2:	efa58593          	addi	a1,a1,-262 # ffffffffc02021c8 <etext+0x27e>
ffffffffc02002d6:	00002517          	auipc	a0,0x2
ffffffffc02002da:	eba50513          	addi	a0,a0,-326 # ffffffffc0202190 <etext+0x246>
ffffffffc02002de:	e3bff0ef          	jal	ra,ffffffffc0200118 <cprintf>
ffffffffc02002e2:	00002617          	auipc	a2,0x2
ffffffffc02002e6:	ef660613          	addi	a2,a2,-266 # ffffffffc02021d8 <etext+0x28e>
ffffffffc02002ea:	00002597          	auipc	a1,0x2
ffffffffc02002ee:	f0e58593          	addi	a1,a1,-242 # ffffffffc02021f8 <etext+0x2ae>
ffffffffc02002f2:	00002517          	auipc	a0,0x2
ffffffffc02002f6:	e9e50513          	addi	a0,a0,-354 # ffffffffc0202190 <etext+0x246>
ffffffffc02002fa:	e1fff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    }
    return 0;
}
ffffffffc02002fe:	60a2                	ld	ra,8(sp)
ffffffffc0200300:	4501                	li	a0,0
ffffffffc0200302:	0141                	addi	sp,sp,16
ffffffffc0200304:	8082                	ret

ffffffffc0200306 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200306:	1141                	addi	sp,sp,-16
ffffffffc0200308:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020030a:	ef3ff0ef          	jal	ra,ffffffffc02001fc <print_kerninfo>
    return 0;
}
ffffffffc020030e:	60a2                	ld	ra,8(sp)
ffffffffc0200310:	4501                	li	a0,0
ffffffffc0200312:	0141                	addi	sp,sp,16
ffffffffc0200314:	8082                	ret

ffffffffc0200316 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200316:	1141                	addi	sp,sp,-16
ffffffffc0200318:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020031a:	f71ff0ef          	jal	ra,ffffffffc020028a <print_stackframe>
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200326:	7115                	addi	sp,sp,-224
ffffffffc0200328:	ed5e                	sd	s7,152(sp)
ffffffffc020032a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032c:	00002517          	auipc	a0,0x2
ffffffffc0200330:	edc50513          	addi	a0,a0,-292 # ffffffffc0202208 <etext+0x2be>
kmonitor(struct trapframe *tf) {
ffffffffc0200334:	ed86                	sd	ra,216(sp)
ffffffffc0200336:	e9a2                	sd	s0,208(sp)
ffffffffc0200338:	e5a6                	sd	s1,200(sp)
ffffffffc020033a:	e1ca                	sd	s2,192(sp)
ffffffffc020033c:	fd4e                	sd	s3,184(sp)
ffffffffc020033e:	f952                	sd	s4,176(sp)
ffffffffc0200340:	f556                	sd	s5,168(sp)
ffffffffc0200342:	f15a                	sd	s6,160(sp)
ffffffffc0200344:	e962                	sd	s8,144(sp)
ffffffffc0200346:	e566                	sd	s9,136(sp)
ffffffffc0200348:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034a:	dcfff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020034e:	00002517          	auipc	a0,0x2
ffffffffc0200352:	ee250513          	addi	a0,a0,-286 # ffffffffc0202230 <etext+0x2e6>
ffffffffc0200356:	dc3ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    if (tf != NULL) {
ffffffffc020035a:	000b8563          	beqz	s7,ffffffffc0200364 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020035e:	855e                	mv	a0,s7
ffffffffc0200360:	6fc000ef          	jal	ra,ffffffffc0200a5c <print_trapframe>
ffffffffc0200364:	00002c17          	auipc	s8,0x2
ffffffffc0200368:	f3cc0c13          	addi	s8,s8,-196 # ffffffffc02022a0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020036c:	00002917          	auipc	s2,0x2
ffffffffc0200370:	eec90913          	addi	s2,s2,-276 # ffffffffc0202258 <etext+0x30e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200374:	00002497          	auipc	s1,0x2
ffffffffc0200378:	eec48493          	addi	s1,s1,-276 # ffffffffc0202260 <etext+0x316>
        if (argc == MAXARGS - 1) {
ffffffffc020037c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020037e:	00002b17          	auipc	s6,0x2
ffffffffc0200382:	eeab0b13          	addi	s6,s6,-278 # ffffffffc0202268 <etext+0x31e>
        argv[argc ++] = buf;
ffffffffc0200386:	00002a17          	auipc	s4,0x2
ffffffffc020038a:	e02a0a13          	addi	s4,s4,-510 # ffffffffc0202188 <etext+0x23e>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020038e:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200390:	854a                	mv	a0,s2
ffffffffc0200392:	29b010ef          	jal	ra,ffffffffc0201e2c <readline>
ffffffffc0200396:	842a                	mv	s0,a0
ffffffffc0200398:	dd65                	beqz	a0,ffffffffc0200390 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020039a:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020039e:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a0:	e1bd                	bnez	a1,ffffffffc0200406 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02003a2:	fe0c87e3          	beqz	s9,ffffffffc0200390 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a6:	6582                	ld	a1,0(sp)
ffffffffc02003a8:	00002d17          	auipc	s10,0x2
ffffffffc02003ac:	ef8d0d13          	addi	s10,s10,-264 # ffffffffc02022a0 <commands>
        argv[argc ++] = buf;
ffffffffc02003b0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b2:	4401                	li	s0,0
ffffffffc02003b4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003b6:	61c010ef          	jal	ra,ffffffffc02019d2 <strcmp>
ffffffffc02003ba:	c919                	beqz	a0,ffffffffc02003d0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003bc:	2405                	addiw	s0,s0,1
ffffffffc02003be:	0b540063          	beq	s0,s5,ffffffffc020045e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003c2:	000d3503          	ld	a0,0(s10)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003c8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ca:	608010ef          	jal	ra,ffffffffc02019d2 <strcmp>
ffffffffc02003ce:	f57d                	bnez	a0,ffffffffc02003bc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003d0:	00141793          	slli	a5,s0,0x1
ffffffffc02003d4:	97a2                	add	a5,a5,s0
ffffffffc02003d6:	078e                	slli	a5,a5,0x3
ffffffffc02003d8:	97e2                	add	a5,a5,s8
ffffffffc02003da:	6b9c                	ld	a5,16(a5)
ffffffffc02003dc:	865e                	mv	a2,s7
ffffffffc02003de:	002c                	addi	a1,sp,8
ffffffffc02003e0:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003e4:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003e6:	fa0555e3          	bgez	a0,ffffffffc0200390 <kmonitor+0x6a>
}
ffffffffc02003ea:	60ee                	ld	ra,216(sp)
ffffffffc02003ec:	644e                	ld	s0,208(sp)
ffffffffc02003ee:	64ae                	ld	s1,200(sp)
ffffffffc02003f0:	690e                	ld	s2,192(sp)
ffffffffc02003f2:	79ea                	ld	s3,184(sp)
ffffffffc02003f4:	7a4a                	ld	s4,176(sp)
ffffffffc02003f6:	7aaa                	ld	s5,168(sp)
ffffffffc02003f8:	7b0a                	ld	s6,160(sp)
ffffffffc02003fa:	6bea                	ld	s7,152(sp)
ffffffffc02003fc:	6c4a                	ld	s8,144(sp)
ffffffffc02003fe:	6caa                	ld	s9,136(sp)
ffffffffc0200400:	6d0a                	ld	s10,128(sp)
ffffffffc0200402:	612d                	addi	sp,sp,224
ffffffffc0200404:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200406:	8526                	mv	a0,s1
ffffffffc0200408:	60e010ef          	jal	ra,ffffffffc0201a16 <strchr>
ffffffffc020040c:	c901                	beqz	a0,ffffffffc020041c <kmonitor+0xf6>
ffffffffc020040e:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200412:	00040023          	sb	zero,0(s0)
ffffffffc0200416:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200418:	d5c9                	beqz	a1,ffffffffc02003a2 <kmonitor+0x7c>
ffffffffc020041a:	b7f5                	j	ffffffffc0200406 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc020041c:	00044783          	lbu	a5,0(s0)
ffffffffc0200420:	d3c9                	beqz	a5,ffffffffc02003a2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200422:	033c8963          	beq	s9,s3,ffffffffc0200454 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200426:	003c9793          	slli	a5,s9,0x3
ffffffffc020042a:	0118                	addi	a4,sp,128
ffffffffc020042c:	97ba                	add	a5,a5,a4
ffffffffc020042e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200432:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200436:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200438:	e591                	bnez	a1,ffffffffc0200444 <kmonitor+0x11e>
ffffffffc020043a:	b7b5                	j	ffffffffc02003a6 <kmonitor+0x80>
ffffffffc020043c:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200440:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200442:	d1a5                	beqz	a1,ffffffffc02003a2 <kmonitor+0x7c>
ffffffffc0200444:	8526                	mv	a0,s1
ffffffffc0200446:	5d0010ef          	jal	ra,ffffffffc0201a16 <strchr>
ffffffffc020044a:	d96d                	beqz	a0,ffffffffc020043c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020044c:	00044583          	lbu	a1,0(s0)
ffffffffc0200450:	d9a9                	beqz	a1,ffffffffc02003a2 <kmonitor+0x7c>
ffffffffc0200452:	bf55                	j	ffffffffc0200406 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200454:	45c1                	li	a1,16
ffffffffc0200456:	855a                	mv	a0,s6
ffffffffc0200458:	cc1ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
ffffffffc020045c:	b7e9                	j	ffffffffc0200426 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020045e:	6582                	ld	a1,0(sp)
ffffffffc0200460:	00002517          	auipc	a0,0x2
ffffffffc0200464:	e2850513          	addi	a0,a0,-472 # ffffffffc0202288 <etext+0x33e>
ffffffffc0200468:	cb1ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    return 0;
ffffffffc020046c:	b715                	j	ffffffffc0200390 <kmonitor+0x6a>

ffffffffc020046e <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020046e:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200470:	00002517          	auipc	a0,0x2
ffffffffc0200474:	e7850513          	addi	a0,a0,-392 # ffffffffc02022e8 <commands+0x48>
void dtb_init(void) {
ffffffffc0200478:	fc86                	sd	ra,120(sp)
ffffffffc020047a:	f8a2                	sd	s0,112(sp)
ffffffffc020047c:	e8d2                	sd	s4,80(sp)
ffffffffc020047e:	f4a6                	sd	s1,104(sp)
ffffffffc0200480:	f0ca                	sd	s2,96(sp)
ffffffffc0200482:	ecce                	sd	s3,88(sp)
ffffffffc0200484:	e4d6                	sd	s5,72(sp)
ffffffffc0200486:	e0da                	sd	s6,64(sp)
ffffffffc0200488:	fc5e                	sd	s7,56(sp)
ffffffffc020048a:	f862                	sd	s8,48(sp)
ffffffffc020048c:	f466                	sd	s9,40(sp)
ffffffffc020048e:	f06a                	sd	s10,32(sp)
ffffffffc0200490:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200492:	c87ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200496:	00007597          	auipc	a1,0x7
ffffffffc020049a:	b6a5b583          	ld	a1,-1174(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc020049e:	00002517          	auipc	a0,0x2
ffffffffc02004a2:	e5a50513          	addi	a0,a0,-422 # ffffffffc02022f8 <commands+0x58>
ffffffffc02004a6:	c73ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004aa:	00007417          	auipc	s0,0x7
ffffffffc02004ae:	b5e40413          	addi	s0,s0,-1186 # ffffffffc0207008 <boot_dtb>
ffffffffc02004b2:	600c                	ld	a1,0(s0)
ffffffffc02004b4:	00002517          	auipc	a0,0x2
ffffffffc02004b8:	e5450513          	addi	a0,a0,-428 # ffffffffc0202308 <commands+0x68>
ffffffffc02004bc:	c5dff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004c0:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004c4:	00002517          	auipc	a0,0x2
ffffffffc02004c8:	e5c50513          	addi	a0,a0,-420 # ffffffffc0202320 <commands+0x80>
    if (boot_dtb == 0) {
ffffffffc02004cc:	120a0463          	beqz	s4,ffffffffc02005f4 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004d0:	57f5                	li	a5,-3
ffffffffc02004d2:	07fa                	slli	a5,a5,0x1e
ffffffffc02004d4:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004d8:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004da:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004de:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004e4:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e8:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f4:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f6:	8ec9                	or	a3,a3,a0
ffffffffc02004f8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004fc:	1b7d                	addi	s6,s6,-1
ffffffffc02004fe:	0167f7b3          	and	a5,a5,s6
ffffffffc0200502:	8dd5                	or	a1,a1,a3
ffffffffc0200504:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200506:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020050c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a55>
ffffffffc0200510:	10f59163          	bne	a1,a5,ffffffffc0200612 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200514:	471c                	lw	a5,8(a4)
ffffffffc0200516:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200518:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020051a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020051e:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200522:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200532:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200536:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053a:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053e:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200542:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200544:	01146433          	or	s0,s0,a7
ffffffffc0200548:	0086969b          	slliw	a3,a3,0x8
ffffffffc020054c:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200550:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200552:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200556:	8c49                	or	s0,s0,a0
ffffffffc0200558:	0166f6b3          	and	a3,a3,s6
ffffffffc020055c:	00ca6a33          	or	s4,s4,a2
ffffffffc0200560:	0167f7b3          	and	a5,a5,s6
ffffffffc0200564:	8c55                	or	s0,s0,a3
ffffffffc0200566:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020056a:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020056c:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020056e:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200570:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200574:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200576:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200578:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020057c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020057e:	00002917          	auipc	s2,0x2
ffffffffc0200582:	df290913          	addi	s2,s2,-526 # ffffffffc0202370 <commands+0xd0>
ffffffffc0200586:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200588:	4d91                	li	s11,4
ffffffffc020058a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020058c:	00002497          	auipc	s1,0x2
ffffffffc0200590:	ddc48493          	addi	s1,s1,-548 # ffffffffc0202368 <commands+0xc8>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200594:	000a2703          	lw	a4,0(s4)
ffffffffc0200598:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020059c:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005a0:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a4:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a8:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ac:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005b0:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b2:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005b6:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005ba:	8fd5                	or	a5,a5,a3
ffffffffc02005bc:	00eb7733          	and	a4,s6,a4
ffffffffc02005c0:	8fd9                	or	a5,a5,a4
ffffffffc02005c2:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005c4:	09778c63          	beq	a5,s7,ffffffffc020065c <dtb_init+0x1ee>
ffffffffc02005c8:	00fbea63          	bltu	s7,a5,ffffffffc02005dc <dtb_init+0x16e>
ffffffffc02005cc:	07a78663          	beq	a5,s10,ffffffffc0200638 <dtb_init+0x1ca>
ffffffffc02005d0:	4709                	li	a4,2
ffffffffc02005d2:	00e79763          	bne	a5,a4,ffffffffc02005e0 <dtb_init+0x172>
ffffffffc02005d6:	4c81                	li	s9,0
ffffffffc02005d8:	8a56                	mv	s4,s5
ffffffffc02005da:	bf6d                	j	ffffffffc0200594 <dtb_init+0x126>
ffffffffc02005dc:	ffb78ee3          	beq	a5,s11,ffffffffc02005d8 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005e0:	00002517          	auipc	a0,0x2
ffffffffc02005e4:	e0850513          	addi	a0,a0,-504 # ffffffffc02023e8 <commands+0x148>
ffffffffc02005e8:	b31ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005ec:	00002517          	auipc	a0,0x2
ffffffffc02005f0:	e3450513          	addi	a0,a0,-460 # ffffffffc0202420 <commands+0x180>
}
ffffffffc02005f4:	7446                	ld	s0,112(sp)
ffffffffc02005f6:	70e6                	ld	ra,120(sp)
ffffffffc02005f8:	74a6                	ld	s1,104(sp)
ffffffffc02005fa:	7906                	ld	s2,96(sp)
ffffffffc02005fc:	69e6                	ld	s3,88(sp)
ffffffffc02005fe:	6a46                	ld	s4,80(sp)
ffffffffc0200600:	6aa6                	ld	s5,72(sp)
ffffffffc0200602:	6b06                	ld	s6,64(sp)
ffffffffc0200604:	7be2                	ld	s7,56(sp)
ffffffffc0200606:	7c42                	ld	s8,48(sp)
ffffffffc0200608:	7ca2                	ld	s9,40(sp)
ffffffffc020060a:	7d02                	ld	s10,32(sp)
ffffffffc020060c:	6de2                	ld	s11,24(sp)
ffffffffc020060e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200610:	b621                	j	ffffffffc0200118 <cprintf>
}
ffffffffc0200612:	7446                	ld	s0,112(sp)
ffffffffc0200614:	70e6                	ld	ra,120(sp)
ffffffffc0200616:	74a6                	ld	s1,104(sp)
ffffffffc0200618:	7906                	ld	s2,96(sp)
ffffffffc020061a:	69e6                	ld	s3,88(sp)
ffffffffc020061c:	6a46                	ld	s4,80(sp)
ffffffffc020061e:	6aa6                	ld	s5,72(sp)
ffffffffc0200620:	6b06                	ld	s6,64(sp)
ffffffffc0200622:	7be2                	ld	s7,56(sp)
ffffffffc0200624:	7c42                	ld	s8,48(sp)
ffffffffc0200626:	7ca2                	ld	s9,40(sp)
ffffffffc0200628:	7d02                	ld	s10,32(sp)
ffffffffc020062a:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020062c:	00002517          	auipc	a0,0x2
ffffffffc0200630:	d1450513          	addi	a0,a0,-748 # ffffffffc0202340 <commands+0xa0>
}
ffffffffc0200634:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200636:	b4cd                	j	ffffffffc0200118 <cprintf>
                int name_len = strlen(name);
ffffffffc0200638:	8556                	mv	a0,s5
ffffffffc020063a:	362010ef          	jal	ra,ffffffffc020199c <strlen>
ffffffffc020063e:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200640:	4619                	li	a2,6
ffffffffc0200642:	85a6                	mv	a1,s1
ffffffffc0200644:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200646:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200648:	3a8010ef          	jal	ra,ffffffffc02019f0 <strncmp>
ffffffffc020064c:	e111                	bnez	a0,ffffffffc0200650 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020064e:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200650:	0a91                	addi	s5,s5,4
ffffffffc0200652:	9ad2                	add	s5,s5,s4
ffffffffc0200654:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200658:	8a56                	mv	s4,s5
ffffffffc020065a:	bf2d                	j	ffffffffc0200594 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020065c:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200660:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200664:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200668:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066c:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200674:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200678:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200684:	00eaeab3          	or	s5,s5,a4
ffffffffc0200688:	00fb77b3          	and	a5,s6,a5
ffffffffc020068c:	00faeab3          	or	s5,s5,a5
ffffffffc0200690:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200692:	000c9c63          	bnez	s9,ffffffffc02006aa <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200696:	1a82                	slli	s5,s5,0x20
ffffffffc0200698:	00368793          	addi	a5,a3,3
ffffffffc020069c:	020ada93          	srli	s5,s5,0x20
ffffffffc02006a0:	9abe                	add	s5,s5,a5
ffffffffc02006a2:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006a6:	8a56                	mv	s4,s5
ffffffffc02006a8:	b5f5                	j	ffffffffc0200594 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006aa:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ae:	85ca                	mv	a1,s2
ffffffffc02006b0:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b2:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006be:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c2:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006c6:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c8:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006cc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006d0:	8d59                	or	a0,a0,a4
ffffffffc02006d2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006d6:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006d8:	1502                	slli	a0,a0,0x20
ffffffffc02006da:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006dc:	9522                	add	a0,a0,s0
ffffffffc02006de:	2f4010ef          	jal	ra,ffffffffc02019d2 <strcmp>
ffffffffc02006e2:	66a2                	ld	a3,8(sp)
ffffffffc02006e4:	f94d                	bnez	a0,ffffffffc0200696 <dtb_init+0x228>
ffffffffc02006e6:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200696 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006ea:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006ee:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006f2:	00002517          	auipc	a0,0x2
ffffffffc02006f6:	c8650513          	addi	a0,a0,-890 # ffffffffc0202378 <commands+0xd8>
           fdt32_to_cpu(x >> 32);
ffffffffc02006fa:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fe:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200702:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200706:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020070a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200712:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200716:	0187d693          	srli	a3,a5,0x18
ffffffffc020071a:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020071e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200722:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200726:	0106561b          	srliw	a2,a2,0x10
ffffffffc020072a:	010f6f33          	or	t5,t5,a6
ffffffffc020072e:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200732:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200736:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073a:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073e:	0186f6b3          	and	a3,a3,s8
ffffffffc0200742:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200746:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020074a:	0107581b          	srliw	a6,a4,0x10
ffffffffc020074e:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200752:	8361                	srli	a4,a4,0x18
ffffffffc0200754:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200758:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020075c:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200760:	00cb7633          	and	a2,s6,a2
ffffffffc0200764:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200768:	0085959b          	slliw	a1,a1,0x8
ffffffffc020076c:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200770:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200774:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200778:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020077c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200780:	011b78b3          	and	a7,s6,a7
ffffffffc0200784:	005eeeb3          	or	t4,t4,t0
ffffffffc0200788:	00c6e733          	or	a4,a3,a2
ffffffffc020078c:	006c6c33          	or	s8,s8,t1
ffffffffc0200790:	010b76b3          	and	a3,s6,a6
ffffffffc0200794:	00bb7b33          	and	s6,s6,a1
ffffffffc0200798:	01d7e7b3          	or	a5,a5,t4
ffffffffc020079c:	016c6b33          	or	s6,s8,s6
ffffffffc02007a0:	01146433          	or	s0,s0,a7
ffffffffc02007a4:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007a6:	1702                	slli	a4,a4,0x20
ffffffffc02007a8:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007aa:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007ac:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007ae:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007b0:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007b4:	0167eb33          	or	s6,a5,s6
ffffffffc02007b8:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007ba:	95fff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007be:	85a2                	mv	a1,s0
ffffffffc02007c0:	00002517          	auipc	a0,0x2
ffffffffc02007c4:	bd850513          	addi	a0,a0,-1064 # ffffffffc0202398 <commands+0xf8>
ffffffffc02007c8:	951ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007cc:	014b5613          	srli	a2,s6,0x14
ffffffffc02007d0:	85da                	mv	a1,s6
ffffffffc02007d2:	00002517          	auipc	a0,0x2
ffffffffc02007d6:	bde50513          	addi	a0,a0,-1058 # ffffffffc02023b0 <commands+0x110>
ffffffffc02007da:	93fff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007de:	008b05b3          	add	a1,s6,s0
ffffffffc02007e2:	15fd                	addi	a1,a1,-1
ffffffffc02007e4:	00002517          	auipc	a0,0x2
ffffffffc02007e8:	bec50513          	addi	a0,a0,-1044 # ffffffffc02023d0 <commands+0x130>
ffffffffc02007ec:	92dff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02007f0:	00002517          	auipc	a0,0x2
ffffffffc02007f4:	c3050513          	addi	a0,a0,-976 # ffffffffc0202420 <commands+0x180>
        memory_base = mem_base;
ffffffffc02007f8:	00007797          	auipc	a5,0x7
ffffffffc02007fc:	c487b823          	sd	s0,-944(a5) # ffffffffc0207448 <memory_base>
        memory_size = mem_size;
ffffffffc0200800:	00007797          	auipc	a5,0x7
ffffffffc0200804:	c567b823          	sd	s6,-944(a5) # ffffffffc0207450 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200808:	b3f5                	j	ffffffffc02005f4 <dtb_init+0x186>

ffffffffc020080a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020080a:	00007517          	auipc	a0,0x7
ffffffffc020080e:	c3e53503          	ld	a0,-962(a0) # ffffffffc0207448 <memory_base>
ffffffffc0200812:	8082                	ret

ffffffffc0200814 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc0200814:	00007517          	auipc	a0,0x7
ffffffffc0200818:	c3c53503          	ld	a0,-964(a0) # ffffffffc0207450 <memory_size>
ffffffffc020081c:	8082                	ret

ffffffffc020081e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020081e:	1141                	addi	sp,sp,-16
ffffffffc0200820:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200822:	02000793          	li	a5,32
ffffffffc0200826:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020082a:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020082e:	67e1                	lui	a5,0x18
ffffffffc0200830:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200834:	953e                	add	a0,a0,a5
ffffffffc0200836:	6c4010ef          	jal	ra,ffffffffc0201efa <sbi_set_timer>
}
ffffffffc020083a:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020083c:	00007797          	auipc	a5,0x7
ffffffffc0200840:	c007be23          	sd	zero,-996(a5) # ffffffffc0207458 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200844:	00002517          	auipc	a0,0x2
ffffffffc0200848:	bf450513          	addi	a0,a0,-1036 # ffffffffc0202438 <commands+0x198>
}
ffffffffc020084c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020084e:	8cbff06f          	j	ffffffffc0200118 <cprintf>

ffffffffc0200852 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200852:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200856:	67e1                	lui	a5,0x18
ffffffffc0200858:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020085c:	953e                	add	a0,a0,a5
ffffffffc020085e:	69c0106f          	j	ffffffffc0201efa <sbi_set_timer>

ffffffffc0200862 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200862:	8082                	ret

ffffffffc0200864 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200864:	0ff57513          	zext.b	a0,a0
ffffffffc0200868:	6780106f          	j	ffffffffc0201ee0 <sbi_console_putchar>

ffffffffc020086c <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020086c:	6a80106f          	j	ffffffffc0201f14 <sbi_console_getchar>

ffffffffc0200870 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200870:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200874:	8082                	ret

ffffffffc0200876 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200876:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020087a:	8082                	ret

ffffffffc020087c <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020087c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200880:	00000797          	auipc	a5,0x0
ffffffffc0200884:	3b478793          	addi	a5,a5,948 # ffffffffc0200c34 <__alltraps>
ffffffffc0200888:	10579073          	csrw	stvec,a5
}
ffffffffc020088c:	8082                	ret

ffffffffc020088e <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020088e:	610c                	ld	a1,0(a0)
{
ffffffffc0200890:	1141                	addi	sp,sp,-16
ffffffffc0200892:	e022                	sd	s0,0(sp)
ffffffffc0200894:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200896:	00002517          	auipc	a0,0x2
ffffffffc020089a:	bc250513          	addi	a0,a0,-1086 # ffffffffc0202458 <commands+0x1b8>
{
ffffffffc020089e:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02008a0:	879ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02008a4:	640c                	ld	a1,8(s0)
ffffffffc02008a6:	00002517          	auipc	a0,0x2
ffffffffc02008aa:	bca50513          	addi	a0,a0,-1078 # ffffffffc0202470 <commands+0x1d0>
ffffffffc02008ae:	86bff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02008b2:	680c                	ld	a1,16(s0)
ffffffffc02008b4:	00002517          	auipc	a0,0x2
ffffffffc02008b8:	bd450513          	addi	a0,a0,-1068 # ffffffffc0202488 <commands+0x1e8>
ffffffffc02008bc:	85dff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02008c0:	6c0c                	ld	a1,24(s0)
ffffffffc02008c2:	00002517          	auipc	a0,0x2
ffffffffc02008c6:	bde50513          	addi	a0,a0,-1058 # ffffffffc02024a0 <commands+0x200>
ffffffffc02008ca:	84fff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02008ce:	700c                	ld	a1,32(s0)
ffffffffc02008d0:	00002517          	auipc	a0,0x2
ffffffffc02008d4:	be850513          	addi	a0,a0,-1048 # ffffffffc02024b8 <commands+0x218>
ffffffffc02008d8:	841ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008dc:	740c                	ld	a1,40(s0)
ffffffffc02008de:	00002517          	auipc	a0,0x2
ffffffffc02008e2:	bf250513          	addi	a0,a0,-1038 # ffffffffc02024d0 <commands+0x230>
ffffffffc02008e6:	833ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008ea:	780c                	ld	a1,48(s0)
ffffffffc02008ec:	00002517          	auipc	a0,0x2
ffffffffc02008f0:	bfc50513          	addi	a0,a0,-1028 # ffffffffc02024e8 <commands+0x248>
ffffffffc02008f4:	825ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008f8:	7c0c                	ld	a1,56(s0)
ffffffffc02008fa:	00002517          	auipc	a0,0x2
ffffffffc02008fe:	c0650513          	addi	a0,a0,-1018 # ffffffffc0202500 <commands+0x260>
ffffffffc0200902:	817ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200906:	602c                	ld	a1,64(s0)
ffffffffc0200908:	00002517          	auipc	a0,0x2
ffffffffc020090c:	c1050513          	addi	a0,a0,-1008 # ffffffffc0202518 <commands+0x278>
ffffffffc0200910:	809ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200914:	642c                	ld	a1,72(s0)
ffffffffc0200916:	00002517          	auipc	a0,0x2
ffffffffc020091a:	c1a50513          	addi	a0,a0,-998 # ffffffffc0202530 <commands+0x290>
ffffffffc020091e:	ffaff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200922:	682c                	ld	a1,80(s0)
ffffffffc0200924:	00002517          	auipc	a0,0x2
ffffffffc0200928:	c2450513          	addi	a0,a0,-988 # ffffffffc0202548 <commands+0x2a8>
ffffffffc020092c:	fecff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200930:	6c2c                	ld	a1,88(s0)
ffffffffc0200932:	00002517          	auipc	a0,0x2
ffffffffc0200936:	c2e50513          	addi	a0,a0,-978 # ffffffffc0202560 <commands+0x2c0>
ffffffffc020093a:	fdeff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020093e:	702c                	ld	a1,96(s0)
ffffffffc0200940:	00002517          	auipc	a0,0x2
ffffffffc0200944:	c3850513          	addi	a0,a0,-968 # ffffffffc0202578 <commands+0x2d8>
ffffffffc0200948:	fd0ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020094c:	742c                	ld	a1,104(s0)
ffffffffc020094e:	00002517          	auipc	a0,0x2
ffffffffc0200952:	c4250513          	addi	a0,a0,-958 # ffffffffc0202590 <commands+0x2f0>
ffffffffc0200956:	fc2ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020095a:	782c                	ld	a1,112(s0)
ffffffffc020095c:	00002517          	auipc	a0,0x2
ffffffffc0200960:	c4c50513          	addi	a0,a0,-948 # ffffffffc02025a8 <commands+0x308>
ffffffffc0200964:	fb4ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200968:	7c2c                	ld	a1,120(s0)
ffffffffc020096a:	00002517          	auipc	a0,0x2
ffffffffc020096e:	c5650513          	addi	a0,a0,-938 # ffffffffc02025c0 <commands+0x320>
ffffffffc0200972:	fa6ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200976:	604c                	ld	a1,128(s0)
ffffffffc0200978:	00002517          	auipc	a0,0x2
ffffffffc020097c:	c6050513          	addi	a0,a0,-928 # ffffffffc02025d8 <commands+0x338>
ffffffffc0200980:	f98ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200984:	644c                	ld	a1,136(s0)
ffffffffc0200986:	00002517          	auipc	a0,0x2
ffffffffc020098a:	c6a50513          	addi	a0,a0,-918 # ffffffffc02025f0 <commands+0x350>
ffffffffc020098e:	f8aff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200992:	684c                	ld	a1,144(s0)
ffffffffc0200994:	00002517          	auipc	a0,0x2
ffffffffc0200998:	c7450513          	addi	a0,a0,-908 # ffffffffc0202608 <commands+0x368>
ffffffffc020099c:	f7cff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02009a0:	6c4c                	ld	a1,152(s0)
ffffffffc02009a2:	00002517          	auipc	a0,0x2
ffffffffc02009a6:	c7e50513          	addi	a0,a0,-898 # ffffffffc0202620 <commands+0x380>
ffffffffc02009aa:	f6eff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02009ae:	704c                	ld	a1,160(s0)
ffffffffc02009b0:	00002517          	auipc	a0,0x2
ffffffffc02009b4:	c8850513          	addi	a0,a0,-888 # ffffffffc0202638 <commands+0x398>
ffffffffc02009b8:	f60ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02009bc:	744c                	ld	a1,168(s0)
ffffffffc02009be:	00002517          	auipc	a0,0x2
ffffffffc02009c2:	c9250513          	addi	a0,a0,-878 # ffffffffc0202650 <commands+0x3b0>
ffffffffc02009c6:	f52ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02009ca:	784c                	ld	a1,176(s0)
ffffffffc02009cc:	00002517          	auipc	a0,0x2
ffffffffc02009d0:	c9c50513          	addi	a0,a0,-868 # ffffffffc0202668 <commands+0x3c8>
ffffffffc02009d4:	f44ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009d8:	7c4c                	ld	a1,184(s0)
ffffffffc02009da:	00002517          	auipc	a0,0x2
ffffffffc02009de:	ca650513          	addi	a0,a0,-858 # ffffffffc0202680 <commands+0x3e0>
ffffffffc02009e2:	f36ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009e6:	606c                	ld	a1,192(s0)
ffffffffc02009e8:	00002517          	auipc	a0,0x2
ffffffffc02009ec:	cb050513          	addi	a0,a0,-848 # ffffffffc0202698 <commands+0x3f8>
ffffffffc02009f0:	f28ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009f4:	646c                	ld	a1,200(s0)
ffffffffc02009f6:	00002517          	auipc	a0,0x2
ffffffffc02009fa:	cba50513          	addi	a0,a0,-838 # ffffffffc02026b0 <commands+0x410>
ffffffffc02009fe:	f1aff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a02:	686c                	ld	a1,208(s0)
ffffffffc0200a04:	00002517          	auipc	a0,0x2
ffffffffc0200a08:	cc450513          	addi	a0,a0,-828 # ffffffffc02026c8 <commands+0x428>
ffffffffc0200a0c:	f0cff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200a10:	6c6c                	ld	a1,216(s0)
ffffffffc0200a12:	00002517          	auipc	a0,0x2
ffffffffc0200a16:	cce50513          	addi	a0,a0,-818 # ffffffffc02026e0 <commands+0x440>
ffffffffc0200a1a:	efeff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200a1e:	706c                	ld	a1,224(s0)
ffffffffc0200a20:	00002517          	auipc	a0,0x2
ffffffffc0200a24:	cd850513          	addi	a0,a0,-808 # ffffffffc02026f8 <commands+0x458>
ffffffffc0200a28:	ef0ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200a2c:	746c                	ld	a1,232(s0)
ffffffffc0200a2e:	00002517          	auipc	a0,0x2
ffffffffc0200a32:	ce250513          	addi	a0,a0,-798 # ffffffffc0202710 <commands+0x470>
ffffffffc0200a36:	ee2ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a3a:	786c                	ld	a1,240(s0)
ffffffffc0200a3c:	00002517          	auipc	a0,0x2
ffffffffc0200a40:	cec50513          	addi	a0,a0,-788 # ffffffffc0202728 <commands+0x488>
ffffffffc0200a44:	ed4ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a48:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a4a:	6402                	ld	s0,0(sp)
ffffffffc0200a4c:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a4e:	00002517          	auipc	a0,0x2
ffffffffc0200a52:	cf250513          	addi	a0,a0,-782 # ffffffffc0202740 <commands+0x4a0>
}
ffffffffc0200a56:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a58:	ec0ff06f          	j	ffffffffc0200118 <cprintf>

ffffffffc0200a5c <print_trapframe>:
{
ffffffffc0200a5c:	1141                	addi	sp,sp,-16
ffffffffc0200a5e:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a60:	85aa                	mv	a1,a0
{
ffffffffc0200a62:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a64:	00002517          	auipc	a0,0x2
ffffffffc0200a68:	cf450513          	addi	a0,a0,-780 # ffffffffc0202758 <commands+0x4b8>
{
ffffffffc0200a6c:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a6e:	eaaff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a72:	8522                	mv	a0,s0
ffffffffc0200a74:	e1bff0ef          	jal	ra,ffffffffc020088e <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a78:	10043583          	ld	a1,256(s0)
ffffffffc0200a7c:	00002517          	auipc	a0,0x2
ffffffffc0200a80:	cf450513          	addi	a0,a0,-780 # ffffffffc0202770 <commands+0x4d0>
ffffffffc0200a84:	e94ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a88:	10843583          	ld	a1,264(s0)
ffffffffc0200a8c:	00002517          	auipc	a0,0x2
ffffffffc0200a90:	cfc50513          	addi	a0,a0,-772 # ffffffffc0202788 <commands+0x4e8>
ffffffffc0200a94:	e84ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a98:	11043583          	ld	a1,272(s0)
ffffffffc0200a9c:	00002517          	auipc	a0,0x2
ffffffffc0200aa0:	d0450513          	addi	a0,a0,-764 # ffffffffc02027a0 <commands+0x500>
ffffffffc0200aa4:	e74ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200aa8:	11843583          	ld	a1,280(s0)
}
ffffffffc0200aac:	6402                	ld	s0,0(sp)
ffffffffc0200aae:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab0:	00002517          	auipc	a0,0x2
ffffffffc0200ab4:	d0850513          	addi	a0,a0,-760 # ffffffffc02027b8 <commands+0x518>
}
ffffffffc0200ab8:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200aba:	e5eff06f          	j	ffffffffc0200118 <cprintf>

ffffffffc0200abe <interrupt_handler>:

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200abe:	11853783          	ld	a5,280(a0)
ffffffffc0200ac2:	472d                	li	a4,11
ffffffffc0200ac4:	0786                	slli	a5,a5,0x1
ffffffffc0200ac6:	8385                	srli	a5,a5,0x1
ffffffffc0200ac8:	08f76563          	bltu	a4,a5,ffffffffc0200b52 <interrupt_handler+0x94>
ffffffffc0200acc:	00002717          	auipc	a4,0x2
ffffffffc0200ad0:	dcc70713          	addi	a4,a4,-564 # ffffffffc0202898 <commands+0x5f8>
ffffffffc0200ad4:	078a                	slli	a5,a5,0x2
ffffffffc0200ad6:	97ba                	add	a5,a5,a4
ffffffffc0200ad8:	439c                	lw	a5,0(a5)
ffffffffc0200ada:	97ba                	add	a5,a5,a4
ffffffffc0200adc:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ade:	00002517          	auipc	a0,0x2
ffffffffc0200ae2:	d5250513          	addi	a0,a0,-686 # ffffffffc0202830 <commands+0x590>
ffffffffc0200ae6:	e32ff06f          	j	ffffffffc0200118 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200aea:	00002517          	auipc	a0,0x2
ffffffffc0200aee:	d2650513          	addi	a0,a0,-730 # ffffffffc0202810 <commands+0x570>
ffffffffc0200af2:	e26ff06f          	j	ffffffffc0200118 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200af6:	00002517          	auipc	a0,0x2
ffffffffc0200afa:	cda50513          	addi	a0,a0,-806 # ffffffffc02027d0 <commands+0x530>
ffffffffc0200afe:	e1aff06f          	j	ffffffffc0200118 <cprintf>
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
ffffffffc0200b02:	00002517          	auipc	a0,0x2
ffffffffc0200b06:	d4e50513          	addi	a0,a0,-690 # ffffffffc0202850 <commands+0x5b0>
ffffffffc0200b0a:	e0eff06f          	j	ffffffffc0200118 <cprintf>
{
ffffffffc0200b0e:	1141                	addi	sp,sp,-16
ffffffffc0200b10:	e022                	sd	s0,0(sp)
ffffffffc0200b12:	e406                	sd	ra,8(sp)
         * (4)判断打印次数,当打印次数为10时，调用<sbi.h>中的关机函数关机
         */
        // (1) 设置下次时钟中断
        clock_set_next_event();
        // (2) 计数器加一
        ticks++;
ffffffffc0200b14:	00007417          	auipc	s0,0x7
ffffffffc0200b18:	94440413          	addi	s0,s0,-1724 # ffffffffc0207458 <ticks>
        clock_set_next_event();
ffffffffc0200b1c:	d37ff0ef          	jal	ra,ffffffffc0200852 <clock_set_next_event>
        ticks++;
ffffffffc0200b20:	601c                	ld	a5,0(s0)
        // (3) 每100次时钟中断打印一次
        if (ticks % TICK_NUM == 0)
ffffffffc0200b22:	06400713          	li	a4,100
        ticks++;
ffffffffc0200b26:	0785                	addi	a5,a5,1
ffffffffc0200b28:	e01c                	sd	a5,0(s0)
        if (ticks % TICK_NUM == 0)
ffffffffc0200b2a:	601c                	ld	a5,0(s0)
ffffffffc0200b2c:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200b30:	c395                	beqz	a5,ffffffffc0200b54 <interrupt_handler+0x96>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200b32:	60a2                	ld	ra,8(sp)
ffffffffc0200b34:	6402                	ld	s0,0(sp)
ffffffffc0200b36:	0141                	addi	sp,sp,16
ffffffffc0200b38:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200b3a:	00002517          	auipc	a0,0x2
ffffffffc0200b3e:	d3e50513          	addi	a0,a0,-706 # ffffffffc0202878 <commands+0x5d8>
ffffffffc0200b42:	dd6ff06f          	j	ffffffffc0200118 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b46:	00002517          	auipc	a0,0x2
ffffffffc0200b4a:	caa50513          	addi	a0,a0,-854 # ffffffffc02027f0 <commands+0x550>
ffffffffc0200b4e:	dcaff06f          	j	ffffffffc0200118 <cprintf>
        print_trapframe(tf);
ffffffffc0200b52:	b729                	j	ffffffffc0200a5c <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b54:	06400593          	li	a1,100
ffffffffc0200b58:	00002517          	auipc	a0,0x2
ffffffffc0200b5c:	d1050513          	addi	a0,a0,-752 # ffffffffc0202868 <commands+0x5c8>
ffffffffc0200b60:	db8ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
            if (ticks / TICK_NUM == 10)
ffffffffc0200b64:	601c                	ld	a5,0(s0)
ffffffffc0200b66:	06300713          	li	a4,99
ffffffffc0200b6a:	c1878793          	addi	a5,a5,-1000
ffffffffc0200b6e:	fcf762e3          	bltu	a4,a5,ffffffffc0200b32 <interrupt_handler+0x74>
}
ffffffffc0200b72:	6402                	ld	s0,0(sp)
ffffffffc0200b74:	60a2                	ld	ra,8(sp)
ffffffffc0200b76:	0141                	addi	sp,sp,16
                sbi_shutdown();
ffffffffc0200b78:	3b80106f          	j	ffffffffc0201f30 <sbi_shutdown>

ffffffffc0200b7c <exception_handler>:

void exception_handler(struct trapframe *tf)
{
ffffffffc0200b7c:	1101                	addi	sp,sp,-32
ffffffffc0200b7e:	e822                	sd	s0,16(sp)
    switch (tf->cause)
ffffffffc0200b80:	11853403          	ld	s0,280(a0)
{
ffffffffc0200b84:	e426                	sd	s1,8(sp)
ffffffffc0200b86:	e04a                	sd	s2,0(sp)
ffffffffc0200b88:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200b8a:	490d                	li	s2,3
{
ffffffffc0200b8c:	84aa                	mv	s1,a0
    switch (tf->cause)
ffffffffc0200b8e:	05240f63          	beq	s0,s2,ffffffffc0200bec <exception_handler+0x70>
ffffffffc0200b92:	04896363          	bltu	s2,s0,ffffffffc0200bd8 <exception_handler+0x5c>
ffffffffc0200b96:	4789                	li	a5,2
ffffffffc0200b98:	02f41a63          	bne	s0,a5,ffffffffc0200bcc <exception_handler+0x50>
        /*(1)输出指令异常类型（ Illegal instruction）
         *(2)输出异常指令地址
         *(3)更新 tf->epc寄存器
         */
        // (1) 输出异常类型
        cprintf("Exception type: Illegal instruction\n");
ffffffffc0200b9c:	00002517          	auipc	a0,0x2
ffffffffc0200ba0:	d2c50513          	addi	a0,a0,-724 # ffffffffc02028c8 <commands+0x628>
ffffffffc0200ba4:	d74ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        // (2) 输出异常指令地址
        cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200ba8:	1084b583          	ld	a1,264(s1)
ffffffffc0200bac:	00002517          	auipc	a0,0x2
ffffffffc0200bb0:	d4450513          	addi	a0,a0,-700 # ffffffffc02028f0 <commands+0x650>
ffffffffc0200bb4:	d64ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        // (3) 更新epc寄存器
        // 检查指令长度：RISC-V压缩指令(C扩展)长度为2字节，标准指令长度为4字节
        // 指令的最低2位如果不是11，则是压缩指令(16位)，否则是标准指令(32位)
        unsigned int instruction = *(unsigned short *)tf->epc;
ffffffffc0200bb8:	1084b783          	ld	a5,264(s1)
        if ((instruction & 0x3) != 0x3)
ffffffffc0200bbc:	0007d703          	lhu	a4,0(a5)
ffffffffc0200bc0:	8b0d                	andi	a4,a4,3
ffffffffc0200bc2:	05270a63          	beq	a4,s2,ffffffffc0200c16 <exception_handler+0x9a>
        // 检查指令长度：RISC-V压缩指令(C扩展)长度为2字节，标准指令长度为4字节
        // ebreak可能是压缩指令c.ebreak(2字节)或标准ebreak(4字节)
        unsigned int inst = *(unsigned short *)tf->epc;
        if ((inst & 0x3) != 0x3)
        {
            tf->epc += 2; // 压缩指令，长度2字节
ffffffffc0200bc6:	0789                	addi	a5,a5,2
ffffffffc0200bc8:	10f4b423          	sd	a5,264(s1)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bcc:	60e2                	ld	ra,24(sp)
ffffffffc0200bce:	6442                	ld	s0,16(sp)
ffffffffc0200bd0:	64a2                	ld	s1,8(sp)
ffffffffc0200bd2:	6902                	ld	s2,0(sp)
ffffffffc0200bd4:	6105                	addi	sp,sp,32
ffffffffc0200bd6:	8082                	ret
    switch (tf->cause)
ffffffffc0200bd8:	1471                	addi	s0,s0,-4
ffffffffc0200bda:	479d                	li	a5,7
ffffffffc0200bdc:	fe87f8e3          	bgeu	a5,s0,ffffffffc0200bcc <exception_handler+0x50>
}
ffffffffc0200be0:	6442                	ld	s0,16(sp)
ffffffffc0200be2:	60e2                	ld	ra,24(sp)
ffffffffc0200be4:	64a2                	ld	s1,8(sp)
ffffffffc0200be6:	6902                	ld	s2,0(sp)
ffffffffc0200be8:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200bea:	bd8d                	j	ffffffffc0200a5c <print_trapframe>
        cprintf("Exception type: breakpoint\n");
ffffffffc0200bec:	00002517          	auipc	a0,0x2
ffffffffc0200bf0:	d2c50513          	addi	a0,a0,-724 # ffffffffc0202918 <commands+0x678>
ffffffffc0200bf4:	d24ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200bf8:	1084b583          	ld	a1,264(s1)
ffffffffc0200bfc:	00002517          	auipc	a0,0x2
ffffffffc0200c00:	d3c50513          	addi	a0,a0,-708 # ffffffffc0202938 <commands+0x698>
ffffffffc0200c04:	d14ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        unsigned int inst = *(unsigned short *)tf->epc;
ffffffffc0200c08:	1084b783          	ld	a5,264(s1)
        if ((inst & 0x3) != 0x3)
ffffffffc0200c0c:	0007d703          	lhu	a4,0(a5)
ffffffffc0200c10:	8b0d                	andi	a4,a4,3
ffffffffc0200c12:	fa871ae3          	bne	a4,s0,ffffffffc0200bc6 <exception_handler+0x4a>
}
ffffffffc0200c16:	60e2                	ld	ra,24(sp)
ffffffffc0200c18:	6442                	ld	s0,16(sp)
            tf->epc += 4; // 标准指令，长度4字节
ffffffffc0200c1a:	0791                	addi	a5,a5,4
ffffffffc0200c1c:	10f4b423          	sd	a5,264(s1)
}
ffffffffc0200c20:	6902                	ld	s2,0(sp)
ffffffffc0200c22:	64a2                	ld	s1,8(sp)
ffffffffc0200c24:	6105                	addi	sp,sp,32
ffffffffc0200c26:	8082                	ret

ffffffffc0200c28 <trap>:

static inline void trap_dispatch(struct trapframe *tf)
{
    if ((intptr_t)tf->cause < 0)
ffffffffc0200c28:	11853783          	ld	a5,280(a0)
ffffffffc0200c2c:	0007c363          	bltz	a5,ffffffffc0200c32 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200c30:	b7b1                	j	ffffffffc0200b7c <exception_handler>
        interrupt_handler(tf);
ffffffffc0200c32:	b571                	j	ffffffffc0200abe <interrupt_handler>

ffffffffc0200c34 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200c34:	14011073          	csrw	sscratch,sp
ffffffffc0200c38:	712d                	addi	sp,sp,-288
ffffffffc0200c3a:	e002                	sd	zero,0(sp)
ffffffffc0200c3c:	e406                	sd	ra,8(sp)
ffffffffc0200c3e:	ec0e                	sd	gp,24(sp)
ffffffffc0200c40:	f012                	sd	tp,32(sp)
ffffffffc0200c42:	f416                	sd	t0,40(sp)
ffffffffc0200c44:	f81a                	sd	t1,48(sp)
ffffffffc0200c46:	fc1e                	sd	t2,56(sp)
ffffffffc0200c48:	e0a2                	sd	s0,64(sp)
ffffffffc0200c4a:	e4a6                	sd	s1,72(sp)
ffffffffc0200c4c:	e8aa                	sd	a0,80(sp)
ffffffffc0200c4e:	ecae                	sd	a1,88(sp)
ffffffffc0200c50:	f0b2                	sd	a2,96(sp)
ffffffffc0200c52:	f4b6                	sd	a3,104(sp)
ffffffffc0200c54:	f8ba                	sd	a4,112(sp)
ffffffffc0200c56:	fcbe                	sd	a5,120(sp)
ffffffffc0200c58:	e142                	sd	a6,128(sp)
ffffffffc0200c5a:	e546                	sd	a7,136(sp)
ffffffffc0200c5c:	e94a                	sd	s2,144(sp)
ffffffffc0200c5e:	ed4e                	sd	s3,152(sp)
ffffffffc0200c60:	f152                	sd	s4,160(sp)
ffffffffc0200c62:	f556                	sd	s5,168(sp)
ffffffffc0200c64:	f95a                	sd	s6,176(sp)
ffffffffc0200c66:	fd5e                	sd	s7,184(sp)
ffffffffc0200c68:	e1e2                	sd	s8,192(sp)
ffffffffc0200c6a:	e5e6                	sd	s9,200(sp)
ffffffffc0200c6c:	e9ea                	sd	s10,208(sp)
ffffffffc0200c6e:	edee                	sd	s11,216(sp)
ffffffffc0200c70:	f1f2                	sd	t3,224(sp)
ffffffffc0200c72:	f5f6                	sd	t4,232(sp)
ffffffffc0200c74:	f9fa                	sd	t5,240(sp)
ffffffffc0200c76:	fdfe                	sd	t6,248(sp)
ffffffffc0200c78:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c7c:	100024f3          	csrr	s1,sstatus
ffffffffc0200c80:	14102973          	csrr	s2,sepc
ffffffffc0200c84:	143029f3          	csrr	s3,stval
ffffffffc0200c88:	14202a73          	csrr	s4,scause
ffffffffc0200c8c:	e822                	sd	s0,16(sp)
ffffffffc0200c8e:	e226                	sd	s1,256(sp)
ffffffffc0200c90:	e64a                	sd	s2,264(sp)
ffffffffc0200c92:	ea4e                	sd	s3,272(sp)
ffffffffc0200c94:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c96:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c98:	f91ff0ef          	jal	ra,ffffffffc0200c28 <trap>

ffffffffc0200c9c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c9c:	6492                	ld	s1,256(sp)
ffffffffc0200c9e:	6932                	ld	s2,264(sp)
ffffffffc0200ca0:	10049073          	csrw	sstatus,s1
ffffffffc0200ca4:	14191073          	csrw	sepc,s2
ffffffffc0200ca8:	60a2                	ld	ra,8(sp)
ffffffffc0200caa:	61e2                	ld	gp,24(sp)
ffffffffc0200cac:	7202                	ld	tp,32(sp)
ffffffffc0200cae:	72a2                	ld	t0,40(sp)
ffffffffc0200cb0:	7342                	ld	t1,48(sp)
ffffffffc0200cb2:	73e2                	ld	t2,56(sp)
ffffffffc0200cb4:	6406                	ld	s0,64(sp)
ffffffffc0200cb6:	64a6                	ld	s1,72(sp)
ffffffffc0200cb8:	6546                	ld	a0,80(sp)
ffffffffc0200cba:	65e6                	ld	a1,88(sp)
ffffffffc0200cbc:	7606                	ld	a2,96(sp)
ffffffffc0200cbe:	76a6                	ld	a3,104(sp)
ffffffffc0200cc0:	7746                	ld	a4,112(sp)
ffffffffc0200cc2:	77e6                	ld	a5,120(sp)
ffffffffc0200cc4:	680a                	ld	a6,128(sp)
ffffffffc0200cc6:	68aa                	ld	a7,136(sp)
ffffffffc0200cc8:	694a                	ld	s2,144(sp)
ffffffffc0200cca:	69ea                	ld	s3,152(sp)
ffffffffc0200ccc:	7a0a                	ld	s4,160(sp)
ffffffffc0200cce:	7aaa                	ld	s5,168(sp)
ffffffffc0200cd0:	7b4a                	ld	s6,176(sp)
ffffffffc0200cd2:	7bea                	ld	s7,184(sp)
ffffffffc0200cd4:	6c0e                	ld	s8,192(sp)
ffffffffc0200cd6:	6cae                	ld	s9,200(sp)
ffffffffc0200cd8:	6d4e                	ld	s10,208(sp)
ffffffffc0200cda:	6dee                	ld	s11,216(sp)
ffffffffc0200cdc:	7e0e                	ld	t3,224(sp)
ffffffffc0200cde:	7eae                	ld	t4,232(sp)
ffffffffc0200ce0:	7f4e                	ld	t5,240(sp)
ffffffffc0200ce2:	7fee                	ld	t6,248(sp)
ffffffffc0200ce4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200ce6:	10200073          	sret

ffffffffc0200cea <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200cea:	100027f3          	csrr	a5,sstatus
ffffffffc0200cee:	8b89                	andi	a5,a5,2
ffffffffc0200cf0:	e799                	bnez	a5,ffffffffc0200cfe <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200cf2:	00006797          	auipc	a5,0x6
ffffffffc0200cf6:	77e7b783          	ld	a5,1918(a5) # ffffffffc0207470 <pmm_manager>
ffffffffc0200cfa:	6f9c                	ld	a5,24(a5)
ffffffffc0200cfc:	8782                	jr	a5
{
ffffffffc0200cfe:	1141                	addi	sp,sp,-16
ffffffffc0200d00:	e406                	sd	ra,8(sp)
ffffffffc0200d02:	e022                	sd	s0,0(sp)
ffffffffc0200d04:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200d06:	b71ff0ef          	jal	ra,ffffffffc0200876 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200d0a:	00006797          	auipc	a5,0x6
ffffffffc0200d0e:	7667b783          	ld	a5,1894(a5) # ffffffffc0207470 <pmm_manager>
ffffffffc0200d12:	6f9c                	ld	a5,24(a5)
ffffffffc0200d14:	8522                	mv	a0,s0
ffffffffc0200d16:	9782                	jalr	a5
ffffffffc0200d18:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0200d1a:	b57ff0ef          	jal	ra,ffffffffc0200870 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200d1e:	60a2                	ld	ra,8(sp)
ffffffffc0200d20:	8522                	mv	a0,s0
ffffffffc0200d22:	6402                	ld	s0,0(sp)
ffffffffc0200d24:	0141                	addi	sp,sp,16
ffffffffc0200d26:	8082                	ret

ffffffffc0200d28 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200d28:	100027f3          	csrr	a5,sstatus
ffffffffc0200d2c:	8b89                	andi	a5,a5,2
ffffffffc0200d2e:	e799                	bnez	a5,ffffffffc0200d3c <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200d30:	00006797          	auipc	a5,0x6
ffffffffc0200d34:	7407b783          	ld	a5,1856(a5) # ffffffffc0207470 <pmm_manager>
ffffffffc0200d38:	739c                	ld	a5,32(a5)
ffffffffc0200d3a:	8782                	jr	a5
{
ffffffffc0200d3c:	1101                	addi	sp,sp,-32
ffffffffc0200d3e:	ec06                	sd	ra,24(sp)
ffffffffc0200d40:	e822                	sd	s0,16(sp)
ffffffffc0200d42:	e426                	sd	s1,8(sp)
ffffffffc0200d44:	842a                	mv	s0,a0
ffffffffc0200d46:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200d48:	b2fff0ef          	jal	ra,ffffffffc0200876 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200d4c:	00006797          	auipc	a5,0x6
ffffffffc0200d50:	7247b783          	ld	a5,1828(a5) # ffffffffc0207470 <pmm_manager>
ffffffffc0200d54:	739c                	ld	a5,32(a5)
ffffffffc0200d56:	85a6                	mv	a1,s1
ffffffffc0200d58:	8522                	mv	a0,s0
ffffffffc0200d5a:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200d5c:	6442                	ld	s0,16(sp)
ffffffffc0200d5e:	60e2                	ld	ra,24(sp)
ffffffffc0200d60:	64a2                	ld	s1,8(sp)
ffffffffc0200d62:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200d64:	b631                	j	ffffffffc0200870 <intr_enable>

ffffffffc0200d66 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200d66:	100027f3          	csrr	a5,sstatus
ffffffffc0200d6a:	8b89                	andi	a5,a5,2
ffffffffc0200d6c:	e799                	bnez	a5,ffffffffc0200d7a <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200d6e:	00006797          	auipc	a5,0x6
ffffffffc0200d72:	7027b783          	ld	a5,1794(a5) # ffffffffc0207470 <pmm_manager>
ffffffffc0200d76:	779c                	ld	a5,40(a5)
ffffffffc0200d78:	8782                	jr	a5
{
ffffffffc0200d7a:	1141                	addi	sp,sp,-16
ffffffffc0200d7c:	e406                	sd	ra,8(sp)
ffffffffc0200d7e:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200d80:	af7ff0ef          	jal	ra,ffffffffc0200876 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200d84:	00006797          	auipc	a5,0x6
ffffffffc0200d88:	6ec7b783          	ld	a5,1772(a5) # ffffffffc0207470 <pmm_manager>
ffffffffc0200d8c:	779c                	ld	a5,40(a5)
ffffffffc0200d8e:	9782                	jalr	a5
ffffffffc0200d90:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200d92:	adfff0ef          	jal	ra,ffffffffc0200870 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200d96:	60a2                	ld	ra,8(sp)
ffffffffc0200d98:	8522                	mv	a0,s0
ffffffffc0200d9a:	6402                	ld	s0,0(sp)
ffffffffc0200d9c:	0141                	addi	sp,sp,16
ffffffffc0200d9e:	8082                	ret

ffffffffc0200da0 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200da0:	00002797          	auipc	a5,0x2
ffffffffc0200da4:	05078793          	addi	a5,a5,80 # ffffffffc0202df0 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200da8:	638c                	ld	a1,0(a5)
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void)
{
ffffffffc0200daa:	7179                	addi	sp,sp,-48
ffffffffc0200dac:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200dae:	00002517          	auipc	a0,0x2
ffffffffc0200db2:	baa50513          	addi	a0,a0,-1110 # ffffffffc0202958 <commands+0x6b8>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200db6:	00006417          	auipc	s0,0x6
ffffffffc0200dba:	6ba40413          	addi	s0,s0,1722 # ffffffffc0207470 <pmm_manager>
{
ffffffffc0200dbe:	f406                	sd	ra,40(sp)
ffffffffc0200dc0:	ec26                	sd	s1,24(sp)
ffffffffc0200dc2:	e44e                	sd	s3,8(sp)
ffffffffc0200dc4:	e84a                	sd	s2,16(sp)
ffffffffc0200dc6:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200dc8:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200dca:	b4eff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    pmm_manager->init();
ffffffffc0200dce:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200dd0:	00006497          	auipc	s1,0x6
ffffffffc0200dd4:	6b848493          	addi	s1,s1,1720 # ffffffffc0207488 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200dd8:	679c                	ld	a5,8(a5)
ffffffffc0200dda:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200ddc:	57f5                	li	a5,-3
ffffffffc0200dde:	07fa                	slli	a5,a5,0x1e
ffffffffc0200de0:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200de2:	a29ff0ef          	jal	ra,ffffffffc020080a <get_memory_base>
ffffffffc0200de6:	89aa                	mv	s3,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0200de8:	a2dff0ef          	jal	ra,ffffffffc0200814 <get_memory_size>
    if (mem_size == 0)
ffffffffc0200dec:	16050963          	beqz	a0,ffffffffc0200f5e <pmm_init+0x1be>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0200df0:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200df2:	00002517          	auipc	a0,0x2
ffffffffc0200df6:	bae50513          	addi	a0,a0,-1106 # ffffffffc02029a0 <commands+0x700>
ffffffffc0200dfa:	b1eff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0200dfe:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200e02:	864e                	mv	a2,s3
ffffffffc0200e04:	fffa0693          	addi	a3,s4,-1
ffffffffc0200e08:	85ca                	mv	a1,s2
ffffffffc0200e0a:	00002517          	auipc	a0,0x2
ffffffffc0200e0e:	bae50513          	addi	a0,a0,-1106 # ffffffffc02029b8 <commands+0x718>
ffffffffc0200e12:	b06ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200e16:	c80007b7          	lui	a5,0xc8000
ffffffffc0200e1a:	8652                	mv	a2,s4
ffffffffc0200e1c:	0f47e063          	bltu	a5,s4,ffffffffc0200efc <pmm_init+0x15c>
ffffffffc0200e20:	00007797          	auipc	a5,0x7
ffffffffc0200e24:	67778793          	addi	a5,a5,1655 # ffffffffc0208497 <end+0xfff>
ffffffffc0200e28:	757d                	lui	a0,0xfffff
ffffffffc0200e2a:	8d7d                	and	a0,a0,a5
ffffffffc0200e2c:	8231                	srli	a2,a2,0xc
ffffffffc0200e2e:	00006597          	auipc	a1,0x6
ffffffffc0200e32:	63258593          	addi	a1,a1,1586 # ffffffffc0207460 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200e36:	00006817          	auipc	a6,0x6
ffffffffc0200e3a:	63280813          	addi	a6,a6,1586 # ffffffffc0207468 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0200e3e:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200e40:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0200e44:	000807b7          	lui	a5,0x80
ffffffffc0200e48:	02f60663          	beq	a2,a5,ffffffffc0200e74 <pmm_init+0xd4>
ffffffffc0200e4c:	4701                	li	a4,0
ffffffffc0200e4e:	4781                	li	a5,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200e50:	4305                	li	t1,1
ffffffffc0200e52:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0200e56:	953a                	add	a0,a0,a4
ffffffffc0200e58:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf7b70>
ffffffffc0200e5c:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0200e60:	6190                	ld	a2,0(a1)
ffffffffc0200e62:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0200e64:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0200e68:	011606b3          	add	a3,a2,a7
ffffffffc0200e6c:	02870713          	addi	a4,a4,40
ffffffffc0200e70:	fed7e3e3          	bltu	a5,a3,ffffffffc0200e56 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200e74:	00261693          	slli	a3,a2,0x2
ffffffffc0200e78:	96b2                	add	a3,a3,a2
ffffffffc0200e7a:	fec007b7          	lui	a5,0xfec00
ffffffffc0200e7e:	97aa                	add	a5,a5,a0
ffffffffc0200e80:	068e                	slli	a3,a3,0x3
ffffffffc0200e82:	96be                	add	a3,a3,a5
ffffffffc0200e84:	c02007b7          	lui	a5,0xc0200
ffffffffc0200e88:	0af6ef63          	bltu	a3,a5,ffffffffc0200f46 <pmm_init+0x1a6>
ffffffffc0200e8c:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200e8e:	77fd                	lui	a5,0xfffff
ffffffffc0200e90:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200e94:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end)
ffffffffc0200e96:	06b6e663          	bltu	a3,a1,ffffffffc0200f02 <pmm_init+0x162>

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    

    extern char boot_page_table_sv39[];
    satp_virtual = (pte_t *)boot_page_table_sv39;
ffffffffc0200e9a:	00005597          	auipc	a1,0x5
ffffffffc0200e9e:	16658593          	addi	a1,a1,358 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0200ea2:	00006797          	auipc	a5,0x6
ffffffffc0200ea6:	5cb7bf23          	sd	a1,1502(a5) # ffffffffc0207480 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200eaa:	c02007b7          	lui	a5,0xc0200
ffffffffc0200eae:	0cf5e463          	bltu	a1,a5,ffffffffc0200f76 <pmm_init+0x1d6>
ffffffffc0200eb2:	6094                	ld	a3,0(s1)
    // cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
    cprintf("satp virtual address: 0x%016lx\n", satp_virtual);
ffffffffc0200eb4:	00002517          	auipc	a0,0x2
ffffffffc0200eb8:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0202a40 <commands+0x7a0>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200ebc:	00006497          	auipc	s1,0x6
ffffffffc0200ec0:	5bc48493          	addi	s1,s1,1468 # ffffffffc0207478 <satp_physical>
ffffffffc0200ec4:	40d586b3          	sub	a3,a1,a3
ffffffffc0200ec8:	e094                	sd	a3,0(s1)
    cprintf("satp virtual address: 0x%016lx\n", satp_virtual);
ffffffffc0200eca:	a4eff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("satp physical address: 0x%016lx\n", satp_physical);
ffffffffc0200ece:	608c                	ld	a1,0(s1)
ffffffffc0200ed0:	00002517          	auipc	a0,0x2
ffffffffc0200ed4:	b9050513          	addi	a0,a0,-1136 # ffffffffc0202a60 <commands+0x7c0>
ffffffffc0200ed8:	a40ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    check_alloc_page();
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0200edc:	601c                	ld	a5,0(s0)
ffffffffc0200ede:	7b9c                	ld	a5,48(a5)
ffffffffc0200ee0:	9782                	jalr	a5
}
ffffffffc0200ee2:	7402                	ld	s0,32(sp)
ffffffffc0200ee4:	70a2                	ld	ra,40(sp)
ffffffffc0200ee6:	64e2                	ld	s1,24(sp)
ffffffffc0200ee8:	6942                	ld	s2,16(sp)
ffffffffc0200eea:	69a2                	ld	s3,8(sp)
ffffffffc0200eec:	6a02                	ld	s4,0(sp)
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200eee:	00002517          	auipc	a0,0x2
ffffffffc0200ef2:	b9a50513          	addi	a0,a0,-1126 # ffffffffc0202a88 <commands+0x7e8>
}
ffffffffc0200ef6:	6145                	addi	sp,sp,48
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200ef8:	a20ff06f          	j	ffffffffc0200118 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200efc:	c8000637          	lui	a2,0xc8000
ffffffffc0200f00:	b705                	j	ffffffffc0200e20 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200f02:	6705                	lui	a4,0x1
ffffffffc0200f04:	177d                	addi	a4,a4,-1
ffffffffc0200f06:	96ba                	add	a3,a3,a4
ffffffffc0200f08:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200f0a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200f0e:	02c7f063          	bgeu	a5,a2,ffffffffc0200f2e <pmm_init+0x18e>
    pmm_manager->init_memmap(base, n);
ffffffffc0200f12:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200f14:	fff80737          	lui	a4,0xfff80
ffffffffc0200f18:	973e                	add	a4,a4,a5
ffffffffc0200f1a:	00271793          	slli	a5,a4,0x2
ffffffffc0200f1e:	97ba                	add	a5,a5,a4
ffffffffc0200f20:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200f22:	8d95                	sub	a1,a1,a3
ffffffffc0200f24:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200f26:	81b1                	srli	a1,a1,0xc
ffffffffc0200f28:	953e                	add	a0,a0,a5
ffffffffc0200f2a:	9702                	jalr	a4
}
ffffffffc0200f2c:	b7bd                	j	ffffffffc0200e9a <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc0200f2e:	00002617          	auipc	a2,0x2
ffffffffc0200f32:	ae260613          	addi	a2,a2,-1310 # ffffffffc0202a10 <commands+0x770>
ffffffffc0200f36:	06b00593          	li	a1,107
ffffffffc0200f3a:	00002517          	auipc	a0,0x2
ffffffffc0200f3e:	af650513          	addi	a0,a0,-1290 # ffffffffc0202a30 <commands+0x790>
ffffffffc0200f42:	a5eff0ef          	jal	ra,ffffffffc02001a0 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200f46:	00002617          	auipc	a2,0x2
ffffffffc0200f4a:	aa260613          	addi	a2,a2,-1374 # ffffffffc02029e8 <commands+0x748>
ffffffffc0200f4e:	07900593          	li	a1,121
ffffffffc0200f52:	00002517          	auipc	a0,0x2
ffffffffc0200f56:	a3e50513          	addi	a0,a0,-1474 # ffffffffc0202990 <commands+0x6f0>
ffffffffc0200f5a:	a46ff0ef          	jal	ra,ffffffffc02001a0 <__panic>
        panic("DTB memory info not available");
ffffffffc0200f5e:	00002617          	auipc	a2,0x2
ffffffffc0200f62:	a1260613          	addi	a2,a2,-1518 # ffffffffc0202970 <commands+0x6d0>
ffffffffc0200f66:	06000593          	li	a1,96
ffffffffc0200f6a:	00002517          	auipc	a0,0x2
ffffffffc0200f6e:	a2650513          	addi	a0,a0,-1498 # ffffffffc0202990 <commands+0x6f0>
ffffffffc0200f72:	a2eff0ef          	jal	ra,ffffffffc02001a0 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200f76:	86ae                	mv	a3,a1
ffffffffc0200f78:	00002617          	auipc	a2,0x2
ffffffffc0200f7c:	a7060613          	addi	a2,a2,-1424 # ffffffffc02029e8 <commands+0x748>
ffffffffc0200f80:	09600593          	li	a1,150
ffffffffc0200f84:	00002517          	auipc	a0,0x2
ffffffffc0200f88:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0202990 <commands+0x6f0>
ffffffffc0200f8c:	a14ff0ef          	jal	ra,ffffffffc02001a0 <__panic>

ffffffffc0200f90 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f90:	00006797          	auipc	a5,0x6
ffffffffc0200f94:	09878793          	addi	a5,a5,152 # ffffffffc0207028 <free_area>
ffffffffc0200f98:	e79c                	sd	a5,8(a5)
ffffffffc0200f9a:	e39c                	sd	a5,0(a5)

static void
best_fit_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200f9c:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200fa0:	8082                	ret

ffffffffc0200fa2 <best_fit_nr_free_pages>:

static size_t
best_fit_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200fa2:	00006517          	auipc	a0,0x6
ffffffffc0200fa6:	09656503          	lwu	a0,150(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200faa:	8082                	ret

ffffffffc0200fac <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200fac:	c14d                	beqz	a0,ffffffffc020104e <best_fit_alloc_pages+0xa2>
    if (n > nr_free)
ffffffffc0200fae:	00006617          	auipc	a2,0x6
ffffffffc0200fb2:	07a60613          	addi	a2,a2,122 # ffffffffc0207028 <free_area>
ffffffffc0200fb6:	01062803          	lw	a6,16(a2)
ffffffffc0200fba:	86aa                	mv	a3,a0
ffffffffc0200fbc:	02081793          	slli	a5,a6,0x20
ffffffffc0200fc0:	9381                	srli	a5,a5,0x20
ffffffffc0200fc2:	08a7e463          	bltu	a5,a0,ffffffffc020104a <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200fc6:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200fc8:	0018059b          	addiw	a1,a6,1
ffffffffc0200fcc:	1582                	slli	a1,a1,0x20
ffffffffc0200fce:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200fd0:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fd2:	06c78b63          	beq	a5,a2,ffffffffc0201048 <best_fit_alloc_pages+0x9c>
        if (p->property >= n && p->property < min_size)
ffffffffc0200fd6:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200fda:	00d76763          	bltu	a4,a3,ffffffffc0200fe8 <best_fit_alloc_pages+0x3c>
ffffffffc0200fde:	00b77563          	bgeu	a4,a1,ffffffffc0200fe8 <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200fe2:	fe878513          	addi	a0,a5,-24
ffffffffc0200fe6:	85ba                	mv	a1,a4
ffffffffc0200fe8:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fea:	fec796e3          	bne	a5,a2,ffffffffc0200fd6 <best_fit_alloc_pages+0x2a>
    if (page != NULL)
ffffffffc0200fee:	cd29                	beqz	a0,ffffffffc0201048 <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200ff0:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200ff2:	6d18                	ld	a4,24(a0)
        if (page->property > n)
ffffffffc0200ff4:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200ff6:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200ffa:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200ffc:	e398                	sd	a4,0(a5)
        if (page->property > n)
ffffffffc0200ffe:	02059793          	slli	a5,a1,0x20
ffffffffc0201002:	9381                	srli	a5,a5,0x20
ffffffffc0201004:	02f6f863          	bgeu	a3,a5,ffffffffc0201034 <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc0201008:	00269793          	slli	a5,a3,0x2
ffffffffc020100c:	97b6                	add	a5,a5,a3
ffffffffc020100e:	078e                	slli	a5,a5,0x3
ffffffffc0201010:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0201012:	411585bb          	subw	a1,a1,a7
ffffffffc0201016:	cb8c                	sw	a1,16(a5)
ffffffffc0201018:	4689                	li	a3,2
ffffffffc020101a:	00878593          	addi	a1,a5,8
ffffffffc020101e:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201022:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0201024:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc0201028:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc020102c:	e28c                	sd	a1,0(a3)
ffffffffc020102e:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0201030:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0201032:	ef98                	sd	a4,24(a5)
ffffffffc0201034:	4118083b          	subw	a6,a6,a7
ffffffffc0201038:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020103c:	57f5                	li	a5,-3
ffffffffc020103e:	00850713          	addi	a4,a0,8
ffffffffc0201042:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0201046:	8082                	ret
}
ffffffffc0201048:	8082                	ret
        return NULL;
ffffffffc020104a:	4501                	li	a0,0
ffffffffc020104c:	8082                	ret
{
ffffffffc020104e:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201050:	00002697          	auipc	a3,0x2
ffffffffc0201054:	a5868693          	addi	a3,a3,-1448 # ffffffffc0202aa8 <commands+0x808>
ffffffffc0201058:	00002617          	auipc	a2,0x2
ffffffffc020105c:	a5860613          	addi	a2,a2,-1448 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201060:	06e00593          	li	a1,110
ffffffffc0201064:	00002517          	auipc	a0,0x2
ffffffffc0201068:	a6450513          	addi	a0,a0,-1436 # ffffffffc0202ac8 <commands+0x828>
{
ffffffffc020106c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020106e:	932ff0ef          	jal	ra,ffffffffc02001a0 <__panic>

ffffffffc0201072 <best_fit_check>:

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void)
{
ffffffffc0201072:	715d                	addi	sp,sp,-80
ffffffffc0201074:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0201076:	00006417          	auipc	s0,0x6
ffffffffc020107a:	fb240413          	addi	s0,s0,-78 # ffffffffc0207028 <free_area>
ffffffffc020107e:	641c                	ld	a5,8(s0)
ffffffffc0201080:	e486                	sd	ra,72(sp)
ffffffffc0201082:	fc26                	sd	s1,56(sp)
ffffffffc0201084:	f84a                	sd	s2,48(sp)
ffffffffc0201086:	f44e                	sd	s3,40(sp)
ffffffffc0201088:	f052                	sd	s4,32(sp)
ffffffffc020108a:	ec56                	sd	s5,24(sp)
ffffffffc020108c:	e85a                	sd	s6,16(sp)
ffffffffc020108e:	e45e                	sd	s7,8(sp)
ffffffffc0201090:	e062                	sd	s8,0(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201092:	26878b63          	beq	a5,s0,ffffffffc0201308 <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0201096:	4481                	li	s1,0
ffffffffc0201098:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020109a:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020109e:	8b09                	andi	a4,a4,2
ffffffffc02010a0:	26070863          	beqz	a4,ffffffffc0201310 <best_fit_check+0x29e>
        count++, total += p->property;
ffffffffc02010a4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010a8:	679c                	ld	a5,8(a5)
ffffffffc02010aa:	2905                	addiw	s2,s2,1
ffffffffc02010ac:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02010ae:	fe8796e3          	bne	a5,s0,ffffffffc020109a <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02010b2:	89a6                	mv	s3,s1
ffffffffc02010b4:	cb3ff0ef          	jal	ra,ffffffffc0200d66 <nr_free_pages>
ffffffffc02010b8:	33351c63          	bne	a0,s3,ffffffffc02013f0 <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010bc:	4505                	li	a0,1
ffffffffc02010be:	c2dff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc02010c2:	8a2a                	mv	s4,a0
ffffffffc02010c4:	36050663          	beqz	a0,ffffffffc0201430 <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010c8:	4505                	li	a0,1
ffffffffc02010ca:	c21ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc02010ce:	89aa                	mv	s3,a0
ffffffffc02010d0:	34050063          	beqz	a0,ffffffffc0201410 <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010d4:	4505                	li	a0,1
ffffffffc02010d6:	c15ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc02010da:	8aaa                	mv	s5,a0
ffffffffc02010dc:	2c050a63          	beqz	a0,ffffffffc02013b0 <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010e0:	253a0863          	beq	s4,s3,ffffffffc0201330 <best_fit_check+0x2be>
ffffffffc02010e4:	24aa0663          	beq	s4,a0,ffffffffc0201330 <best_fit_check+0x2be>
ffffffffc02010e8:	24a98463          	beq	s3,a0,ffffffffc0201330 <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02010ec:	000a2783          	lw	a5,0(s4)
ffffffffc02010f0:	26079063          	bnez	a5,ffffffffc0201350 <best_fit_check+0x2de>
ffffffffc02010f4:	0009a783          	lw	a5,0(s3)
ffffffffc02010f8:	24079c63          	bnez	a5,ffffffffc0201350 <best_fit_check+0x2de>
ffffffffc02010fc:	411c                	lw	a5,0(a0)
ffffffffc02010fe:	24079963          	bnez	a5,ffffffffc0201350 <best_fit_check+0x2de>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201102:	00006797          	auipc	a5,0x6
ffffffffc0201106:	3667b783          	ld	a5,870(a5) # ffffffffc0207468 <pages>
ffffffffc020110a:	40fa0733          	sub	a4,s4,a5
ffffffffc020110e:	870d                	srai	a4,a4,0x3
ffffffffc0201110:	00002597          	auipc	a1,0x2
ffffffffc0201114:	f685b583          	ld	a1,-152(a1) # ffffffffc0203078 <nbase+0x8>
ffffffffc0201118:	02b70733          	mul	a4,a4,a1
ffffffffc020111c:	00002617          	auipc	a2,0x2
ffffffffc0201120:	f5463603          	ld	a2,-172(a2) # ffffffffc0203070 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201124:	00006697          	auipc	a3,0x6
ffffffffc0201128:	33c6b683          	ld	a3,828(a3) # ffffffffc0207460 <npage>
ffffffffc020112c:	06b2                	slli	a3,a3,0xc
ffffffffc020112e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201130:	0732                	slli	a4,a4,0xc
ffffffffc0201132:	22d77f63          	bgeu	a4,a3,ffffffffc0201370 <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201136:	40f98733          	sub	a4,s3,a5
ffffffffc020113a:	870d                	srai	a4,a4,0x3
ffffffffc020113c:	02b70733          	mul	a4,a4,a1
ffffffffc0201140:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201142:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201144:	3ed77663          	bgeu	a4,a3,ffffffffc0201530 <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201148:	40f507b3          	sub	a5,a0,a5
ffffffffc020114c:	878d                	srai	a5,a5,0x3
ffffffffc020114e:	02b787b3          	mul	a5,a5,a1
ffffffffc0201152:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201154:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201156:	3ad7fd63          	bgeu	a5,a3,ffffffffc0201510 <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc020115a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020115c:	00043c03          	ld	s8,0(s0)
ffffffffc0201160:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201164:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0201168:	e400                	sd	s0,8(s0)
ffffffffc020116a:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc020116c:	00006797          	auipc	a5,0x6
ffffffffc0201170:	ec07a623          	sw	zero,-308(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201174:	b77ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc0201178:	36051c63          	bnez	a0,ffffffffc02014f0 <best_fit_check+0x47e>
    free_page(p0);
ffffffffc020117c:	4585                	li	a1,1
ffffffffc020117e:	8552                	mv	a0,s4
ffffffffc0201180:	ba9ff0ef          	jal	ra,ffffffffc0200d28 <free_pages>
    free_page(p1);
ffffffffc0201184:	4585                	li	a1,1
ffffffffc0201186:	854e                	mv	a0,s3
ffffffffc0201188:	ba1ff0ef          	jal	ra,ffffffffc0200d28 <free_pages>
    free_page(p2);
ffffffffc020118c:	4585                	li	a1,1
ffffffffc020118e:	8556                	mv	a0,s5
ffffffffc0201190:	b99ff0ef          	jal	ra,ffffffffc0200d28 <free_pages>
    assert(nr_free == 3);
ffffffffc0201194:	4818                	lw	a4,16(s0)
ffffffffc0201196:	478d                	li	a5,3
ffffffffc0201198:	32f71c63          	bne	a4,a5,ffffffffc02014d0 <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020119c:	4505                	li	a0,1
ffffffffc020119e:	b4dff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc02011a2:	89aa                	mv	s3,a0
ffffffffc02011a4:	30050663          	beqz	a0,ffffffffc02014b0 <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011a8:	4505                	li	a0,1
ffffffffc02011aa:	b41ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc02011ae:	8aaa                	mv	s5,a0
ffffffffc02011b0:	2e050063          	beqz	a0,ffffffffc0201490 <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011b4:	4505                	li	a0,1
ffffffffc02011b6:	b35ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc02011ba:	8a2a                	mv	s4,a0
ffffffffc02011bc:	2a050a63          	beqz	a0,ffffffffc0201470 <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc02011c0:	4505                	li	a0,1
ffffffffc02011c2:	b29ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc02011c6:	28051563          	bnez	a0,ffffffffc0201450 <best_fit_check+0x3de>
    free_page(p0);
ffffffffc02011ca:	4585                	li	a1,1
ffffffffc02011cc:	854e                	mv	a0,s3
ffffffffc02011ce:	b5bff0ef          	jal	ra,ffffffffc0200d28 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02011d2:	641c                	ld	a5,8(s0)
ffffffffc02011d4:	1a878e63          	beq	a5,s0,ffffffffc0201390 <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc02011d8:	4505                	li	a0,1
ffffffffc02011da:	b11ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc02011de:	52a99963          	bne	s3,a0,ffffffffc0201710 <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc02011e2:	4505                	li	a0,1
ffffffffc02011e4:	b07ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc02011e8:	50051463          	bnez	a0,ffffffffc02016f0 <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc02011ec:	481c                	lw	a5,16(s0)
ffffffffc02011ee:	4e079163          	bnez	a5,ffffffffc02016d0 <best_fit_check+0x65e>
    free_page(p);
ffffffffc02011f2:	854e                	mv	a0,s3
ffffffffc02011f4:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02011f6:	01843023          	sd	s8,0(s0)
ffffffffc02011fa:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02011fe:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201202:	b27ff0ef          	jal	ra,ffffffffc0200d28 <free_pages>
    free_page(p1);
ffffffffc0201206:	4585                	li	a1,1
ffffffffc0201208:	8556                	mv	a0,s5
ffffffffc020120a:	b1fff0ef          	jal	ra,ffffffffc0200d28 <free_pages>
    free_page(p2);
ffffffffc020120e:	4585                	li	a1,1
ffffffffc0201210:	8552                	mv	a0,s4
ffffffffc0201212:	b17ff0ef          	jal	ra,ffffffffc0200d28 <free_pages>

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201216:	4515                	li	a0,5
ffffffffc0201218:	ad3ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc020121c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020121e:	48050963          	beqz	a0,ffffffffc02016b0 <best_fit_check+0x63e>
ffffffffc0201222:	651c                	ld	a5,8(a0)
ffffffffc0201224:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0201226:	8b85                	andi	a5,a5,1
ffffffffc0201228:	46079463          	bnez	a5,ffffffffc0201690 <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020122c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020122e:	00043a83          	ld	s5,0(s0)
ffffffffc0201232:	00843a03          	ld	s4,8(s0)
ffffffffc0201236:	e000                	sd	s0,0(s0)
ffffffffc0201238:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020123a:	ab1ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc020123e:	42051963          	bnez	a0,ffffffffc0201670 <best_fit_check+0x5fe>
#endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0201242:	4589                	li	a1,2
ffffffffc0201244:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0201248:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc020124c:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0201250:	00006797          	auipc	a5,0x6
ffffffffc0201254:	de07a423          	sw	zero,-536(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0201258:	ad1ff0ef          	jal	ra,ffffffffc0200d28 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc020125c:	8562                	mv	a0,s8
ffffffffc020125e:	4585                	li	a1,1
ffffffffc0201260:	ac9ff0ef          	jal	ra,ffffffffc0200d28 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201264:	4511                	li	a0,4
ffffffffc0201266:	a85ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc020126a:	3e051363          	bnez	a0,ffffffffc0201650 <best_fit_check+0x5de>
ffffffffc020126e:	0309b783          	ld	a5,48(s3)
ffffffffc0201272:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0201274:	8b85                	andi	a5,a5,1
ffffffffc0201276:	3a078d63          	beqz	a5,ffffffffc0201630 <best_fit_check+0x5be>
ffffffffc020127a:	0389a703          	lw	a4,56(s3)
ffffffffc020127e:	4789                	li	a5,2
ffffffffc0201280:	3af71863          	bne	a4,a5,ffffffffc0201630 <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0201284:	4505                	li	a0,1
ffffffffc0201286:	a65ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc020128a:	8baa                	mv	s7,a0
ffffffffc020128c:	38050263          	beqz	a0,ffffffffc0201610 <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL); // best fit feature
ffffffffc0201290:	4509                	li	a0,2
ffffffffc0201292:	a59ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc0201296:	34050d63          	beqz	a0,ffffffffc02015f0 <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc020129a:	337c1b63          	bne	s8,s7,ffffffffc02015d0 <best_fit_check+0x55e>
#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc020129e:	854e                	mv	a0,s3
ffffffffc02012a0:	4595                	li	a1,5
ffffffffc02012a2:	a87ff0ef          	jal	ra,ffffffffc0200d28 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02012a6:	4515                	li	a0,5
ffffffffc02012a8:	a43ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc02012ac:	89aa                	mv	s3,a0
ffffffffc02012ae:	30050163          	beqz	a0,ffffffffc02015b0 <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc02012b2:	4505                	li	a0,1
ffffffffc02012b4:	a37ff0ef          	jal	ra,ffffffffc0200cea <alloc_pages>
ffffffffc02012b8:	2c051c63          	bnez	a0,ffffffffc0201590 <best_fit_check+0x51e>

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    assert(nr_free == 0);
ffffffffc02012bc:	481c                	lw	a5,16(s0)
ffffffffc02012be:	2a079963          	bnez	a5,ffffffffc0201570 <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02012c2:	4595                	li	a1,5
ffffffffc02012c4:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02012c6:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc02012ca:	01543023          	sd	s5,0(s0)
ffffffffc02012ce:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc02012d2:	a57ff0ef          	jal	ra,ffffffffc0200d28 <free_pages>
    return listelm->next;
ffffffffc02012d6:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02012d8:	00878963          	beq	a5,s0,ffffffffc02012ea <best_fit_check+0x278>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02012dc:	ff87a703          	lw	a4,-8(a5)
ffffffffc02012e0:	679c                	ld	a5,8(a5)
ffffffffc02012e2:	397d                	addiw	s2,s2,-1
ffffffffc02012e4:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02012e6:	fe879be3          	bne	a5,s0,ffffffffc02012dc <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc02012ea:	26091363          	bnez	s2,ffffffffc0201550 <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc02012ee:	e0ed                	bnez	s1,ffffffffc02013d0 <best_fit_check+0x35e>
#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
}
ffffffffc02012f0:	60a6                	ld	ra,72(sp)
ffffffffc02012f2:	6406                	ld	s0,64(sp)
ffffffffc02012f4:	74e2                	ld	s1,56(sp)
ffffffffc02012f6:	7942                	ld	s2,48(sp)
ffffffffc02012f8:	79a2                	ld	s3,40(sp)
ffffffffc02012fa:	7a02                	ld	s4,32(sp)
ffffffffc02012fc:	6ae2                	ld	s5,24(sp)
ffffffffc02012fe:	6b42                	ld	s6,16(sp)
ffffffffc0201300:	6ba2                	ld	s7,8(sp)
ffffffffc0201302:	6c02                	ld	s8,0(sp)
ffffffffc0201304:	6161                	addi	sp,sp,80
ffffffffc0201306:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201308:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020130a:	4481                	li	s1,0
ffffffffc020130c:	4901                	li	s2,0
ffffffffc020130e:	b35d                	j	ffffffffc02010b4 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0201310:	00001697          	auipc	a3,0x1
ffffffffc0201314:	7d068693          	addi	a3,a3,2000 # ffffffffc0202ae0 <commands+0x840>
ffffffffc0201318:	00001617          	auipc	a2,0x1
ffffffffc020131c:	79860613          	addi	a2,a2,1944 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201320:	11800593          	li	a1,280
ffffffffc0201324:	00001517          	auipc	a0,0x1
ffffffffc0201328:	7a450513          	addi	a0,a0,1956 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020132c:	e75fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201330:	00002697          	auipc	a3,0x2
ffffffffc0201334:	84068693          	addi	a3,a3,-1984 # ffffffffc0202b70 <commands+0x8d0>
ffffffffc0201338:	00001617          	auipc	a2,0x1
ffffffffc020133c:	77860613          	addi	a2,a2,1912 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201340:	0e200593          	li	a1,226
ffffffffc0201344:	00001517          	auipc	a0,0x1
ffffffffc0201348:	78450513          	addi	a0,a0,1924 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020134c:	e55fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201350:	00002697          	auipc	a3,0x2
ffffffffc0201354:	84868693          	addi	a3,a3,-1976 # ffffffffc0202b98 <commands+0x8f8>
ffffffffc0201358:	00001617          	auipc	a2,0x1
ffffffffc020135c:	75860613          	addi	a2,a2,1880 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201360:	0e300593          	li	a1,227
ffffffffc0201364:	00001517          	auipc	a0,0x1
ffffffffc0201368:	76450513          	addi	a0,a0,1892 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020136c:	e35fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201370:	00002697          	auipc	a3,0x2
ffffffffc0201374:	86868693          	addi	a3,a3,-1944 # ffffffffc0202bd8 <commands+0x938>
ffffffffc0201378:	00001617          	auipc	a2,0x1
ffffffffc020137c:	73860613          	addi	a2,a2,1848 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201380:	0e500593          	li	a1,229
ffffffffc0201384:	00001517          	auipc	a0,0x1
ffffffffc0201388:	74450513          	addi	a0,a0,1860 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020138c:	e15fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201390:	00002697          	auipc	a3,0x2
ffffffffc0201394:	8d068693          	addi	a3,a3,-1840 # ffffffffc0202c60 <commands+0x9c0>
ffffffffc0201398:	00001617          	auipc	a2,0x1
ffffffffc020139c:	71860613          	addi	a2,a2,1816 # ffffffffc0202ab0 <commands+0x810>
ffffffffc02013a0:	0fe00593          	li	a1,254
ffffffffc02013a4:	00001517          	auipc	a0,0x1
ffffffffc02013a8:	72450513          	addi	a0,a0,1828 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02013ac:	df5fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013b0:	00001697          	auipc	a3,0x1
ffffffffc02013b4:	7a068693          	addi	a3,a3,1952 # ffffffffc0202b50 <commands+0x8b0>
ffffffffc02013b8:	00001617          	auipc	a2,0x1
ffffffffc02013bc:	6f860613          	addi	a2,a2,1784 # ffffffffc0202ab0 <commands+0x810>
ffffffffc02013c0:	0e000593          	li	a1,224
ffffffffc02013c4:	00001517          	auipc	a0,0x1
ffffffffc02013c8:	70450513          	addi	a0,a0,1796 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02013cc:	dd5fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(total == 0);
ffffffffc02013d0:	00002697          	auipc	a3,0x2
ffffffffc02013d4:	9c068693          	addi	a3,a3,-1600 # ffffffffc0202d90 <commands+0xaf0>
ffffffffc02013d8:	00001617          	auipc	a2,0x1
ffffffffc02013dc:	6d860613          	addi	a2,a2,1752 # ffffffffc0202ab0 <commands+0x810>
ffffffffc02013e0:	15b00593          	li	a1,347
ffffffffc02013e4:	00001517          	auipc	a0,0x1
ffffffffc02013e8:	6e450513          	addi	a0,a0,1764 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02013ec:	db5fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(total == nr_free_pages());
ffffffffc02013f0:	00001697          	auipc	a3,0x1
ffffffffc02013f4:	70068693          	addi	a3,a3,1792 # ffffffffc0202af0 <commands+0x850>
ffffffffc02013f8:	00001617          	auipc	a2,0x1
ffffffffc02013fc:	6b860613          	addi	a2,a2,1720 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201400:	11b00593          	li	a1,283
ffffffffc0201404:	00001517          	auipc	a0,0x1
ffffffffc0201408:	6c450513          	addi	a0,a0,1732 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020140c:	d95fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201410:	00001697          	auipc	a3,0x1
ffffffffc0201414:	72068693          	addi	a3,a3,1824 # ffffffffc0202b30 <commands+0x890>
ffffffffc0201418:	00001617          	auipc	a2,0x1
ffffffffc020141c:	69860613          	addi	a2,a2,1688 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201420:	0df00593          	li	a1,223
ffffffffc0201424:	00001517          	auipc	a0,0x1
ffffffffc0201428:	6a450513          	addi	a0,a0,1700 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020142c:	d75fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201430:	00001697          	auipc	a3,0x1
ffffffffc0201434:	6e068693          	addi	a3,a3,1760 # ffffffffc0202b10 <commands+0x870>
ffffffffc0201438:	00001617          	auipc	a2,0x1
ffffffffc020143c:	67860613          	addi	a2,a2,1656 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201440:	0de00593          	li	a1,222
ffffffffc0201444:	00001517          	auipc	a0,0x1
ffffffffc0201448:	68450513          	addi	a0,a0,1668 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020144c:	d55fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201450:	00001697          	auipc	a3,0x1
ffffffffc0201454:	7e868693          	addi	a3,a3,2024 # ffffffffc0202c38 <commands+0x998>
ffffffffc0201458:	00001617          	auipc	a2,0x1
ffffffffc020145c:	65860613          	addi	a2,a2,1624 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201460:	0fb00593          	li	a1,251
ffffffffc0201464:	00001517          	auipc	a0,0x1
ffffffffc0201468:	66450513          	addi	a0,a0,1636 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020146c:	d35fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201470:	00001697          	auipc	a3,0x1
ffffffffc0201474:	6e068693          	addi	a3,a3,1760 # ffffffffc0202b50 <commands+0x8b0>
ffffffffc0201478:	00001617          	auipc	a2,0x1
ffffffffc020147c:	63860613          	addi	a2,a2,1592 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201480:	0f900593          	li	a1,249
ffffffffc0201484:	00001517          	auipc	a0,0x1
ffffffffc0201488:	64450513          	addi	a0,a0,1604 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020148c:	d15fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201490:	00001697          	auipc	a3,0x1
ffffffffc0201494:	6a068693          	addi	a3,a3,1696 # ffffffffc0202b30 <commands+0x890>
ffffffffc0201498:	00001617          	auipc	a2,0x1
ffffffffc020149c:	61860613          	addi	a2,a2,1560 # ffffffffc0202ab0 <commands+0x810>
ffffffffc02014a0:	0f800593          	li	a1,248
ffffffffc02014a4:	00001517          	auipc	a0,0x1
ffffffffc02014a8:	62450513          	addi	a0,a0,1572 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02014ac:	cf5fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02014b0:	00001697          	auipc	a3,0x1
ffffffffc02014b4:	66068693          	addi	a3,a3,1632 # ffffffffc0202b10 <commands+0x870>
ffffffffc02014b8:	00001617          	auipc	a2,0x1
ffffffffc02014bc:	5f860613          	addi	a2,a2,1528 # ffffffffc0202ab0 <commands+0x810>
ffffffffc02014c0:	0f700593          	li	a1,247
ffffffffc02014c4:	00001517          	auipc	a0,0x1
ffffffffc02014c8:	60450513          	addi	a0,a0,1540 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02014cc:	cd5fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(nr_free == 3);
ffffffffc02014d0:	00001697          	auipc	a3,0x1
ffffffffc02014d4:	78068693          	addi	a3,a3,1920 # ffffffffc0202c50 <commands+0x9b0>
ffffffffc02014d8:	00001617          	auipc	a2,0x1
ffffffffc02014dc:	5d860613          	addi	a2,a2,1496 # ffffffffc0202ab0 <commands+0x810>
ffffffffc02014e0:	0f500593          	li	a1,245
ffffffffc02014e4:	00001517          	auipc	a0,0x1
ffffffffc02014e8:	5e450513          	addi	a0,a0,1508 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02014ec:	cb5fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014f0:	00001697          	auipc	a3,0x1
ffffffffc02014f4:	74868693          	addi	a3,a3,1864 # ffffffffc0202c38 <commands+0x998>
ffffffffc02014f8:	00001617          	auipc	a2,0x1
ffffffffc02014fc:	5b860613          	addi	a2,a2,1464 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201500:	0f000593          	li	a1,240
ffffffffc0201504:	00001517          	auipc	a0,0x1
ffffffffc0201508:	5c450513          	addi	a0,a0,1476 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020150c:	c95fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201510:	00001697          	auipc	a3,0x1
ffffffffc0201514:	70868693          	addi	a3,a3,1800 # ffffffffc0202c18 <commands+0x978>
ffffffffc0201518:	00001617          	auipc	a2,0x1
ffffffffc020151c:	59860613          	addi	a2,a2,1432 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201520:	0e700593          	li	a1,231
ffffffffc0201524:	00001517          	auipc	a0,0x1
ffffffffc0201528:	5a450513          	addi	a0,a0,1444 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020152c:	c75fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201530:	00001697          	auipc	a3,0x1
ffffffffc0201534:	6c868693          	addi	a3,a3,1736 # ffffffffc0202bf8 <commands+0x958>
ffffffffc0201538:	00001617          	auipc	a2,0x1
ffffffffc020153c:	57860613          	addi	a2,a2,1400 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201540:	0e600593          	li	a1,230
ffffffffc0201544:	00001517          	auipc	a0,0x1
ffffffffc0201548:	58450513          	addi	a0,a0,1412 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020154c:	c55fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(count == 0);
ffffffffc0201550:	00002697          	auipc	a3,0x2
ffffffffc0201554:	83068693          	addi	a3,a3,-2000 # ffffffffc0202d80 <commands+0xae0>
ffffffffc0201558:	00001617          	auipc	a2,0x1
ffffffffc020155c:	55860613          	addi	a2,a2,1368 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201560:	15a00593          	li	a1,346
ffffffffc0201564:	00001517          	auipc	a0,0x1
ffffffffc0201568:	56450513          	addi	a0,a0,1380 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020156c:	c35fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(nr_free == 0);
ffffffffc0201570:	00001697          	auipc	a3,0x1
ffffffffc0201574:	72868693          	addi	a3,a3,1832 # ffffffffc0202c98 <commands+0x9f8>
ffffffffc0201578:	00001617          	auipc	a2,0x1
ffffffffc020157c:	53860613          	addi	a2,a2,1336 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201580:	14e00593          	li	a1,334
ffffffffc0201584:	00001517          	auipc	a0,0x1
ffffffffc0201588:	54450513          	addi	a0,a0,1348 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020158c:	c15fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201590:	00001697          	auipc	a3,0x1
ffffffffc0201594:	6a868693          	addi	a3,a3,1704 # ffffffffc0202c38 <commands+0x998>
ffffffffc0201598:	00001617          	auipc	a2,0x1
ffffffffc020159c:	51860613          	addi	a2,a2,1304 # ffffffffc0202ab0 <commands+0x810>
ffffffffc02015a0:	14800593          	li	a1,328
ffffffffc02015a4:	00001517          	auipc	a0,0x1
ffffffffc02015a8:	52450513          	addi	a0,a0,1316 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02015ac:	bf5fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015b0:	00001697          	auipc	a3,0x1
ffffffffc02015b4:	7b068693          	addi	a3,a3,1968 # ffffffffc0202d60 <commands+0xac0>
ffffffffc02015b8:	00001617          	auipc	a2,0x1
ffffffffc02015bc:	4f860613          	addi	a2,a2,1272 # ffffffffc0202ab0 <commands+0x810>
ffffffffc02015c0:	14700593          	li	a1,327
ffffffffc02015c4:	00001517          	auipc	a0,0x1
ffffffffc02015c8:	50450513          	addi	a0,a0,1284 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02015cc:	bd5fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(p0 + 4 == p1);
ffffffffc02015d0:	00001697          	auipc	a3,0x1
ffffffffc02015d4:	78068693          	addi	a3,a3,1920 # ffffffffc0202d50 <commands+0xab0>
ffffffffc02015d8:	00001617          	auipc	a2,0x1
ffffffffc02015dc:	4d860613          	addi	a2,a2,1240 # ffffffffc0202ab0 <commands+0x810>
ffffffffc02015e0:	13f00593          	li	a1,319
ffffffffc02015e4:	00001517          	auipc	a0,0x1
ffffffffc02015e8:	4e450513          	addi	a0,a0,1252 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02015ec:	bb5fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(alloc_pages(2) != NULL); // best fit feature
ffffffffc02015f0:	00001697          	auipc	a3,0x1
ffffffffc02015f4:	74868693          	addi	a3,a3,1864 # ffffffffc0202d38 <commands+0xa98>
ffffffffc02015f8:	00001617          	auipc	a2,0x1
ffffffffc02015fc:	4b860613          	addi	a2,a2,1208 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201600:	13e00593          	li	a1,318
ffffffffc0201604:	00001517          	auipc	a0,0x1
ffffffffc0201608:	4c450513          	addi	a0,a0,1220 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020160c:	b95fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0201610:	00001697          	auipc	a3,0x1
ffffffffc0201614:	70868693          	addi	a3,a3,1800 # ffffffffc0202d18 <commands+0xa78>
ffffffffc0201618:	00001617          	auipc	a2,0x1
ffffffffc020161c:	49860613          	addi	a2,a2,1176 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201620:	13d00593          	li	a1,317
ffffffffc0201624:	00001517          	auipc	a0,0x1
ffffffffc0201628:	4a450513          	addi	a0,a0,1188 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020162c:	b75fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0201630:	00001697          	auipc	a3,0x1
ffffffffc0201634:	6b868693          	addi	a3,a3,1720 # ffffffffc0202ce8 <commands+0xa48>
ffffffffc0201638:	00001617          	auipc	a2,0x1
ffffffffc020163c:	47860613          	addi	a2,a2,1144 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201640:	13b00593          	li	a1,315
ffffffffc0201644:	00001517          	auipc	a0,0x1
ffffffffc0201648:	48450513          	addi	a0,a0,1156 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020164c:	b55fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201650:	00001697          	auipc	a3,0x1
ffffffffc0201654:	68068693          	addi	a3,a3,1664 # ffffffffc0202cd0 <commands+0xa30>
ffffffffc0201658:	00001617          	auipc	a2,0x1
ffffffffc020165c:	45860613          	addi	a2,a2,1112 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201660:	13a00593          	li	a1,314
ffffffffc0201664:	00001517          	auipc	a0,0x1
ffffffffc0201668:	46450513          	addi	a0,a0,1124 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020166c:	b35fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201670:	00001697          	auipc	a3,0x1
ffffffffc0201674:	5c868693          	addi	a3,a3,1480 # ffffffffc0202c38 <commands+0x998>
ffffffffc0201678:	00001617          	auipc	a2,0x1
ffffffffc020167c:	43860613          	addi	a2,a2,1080 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201680:	12e00593          	li	a1,302
ffffffffc0201684:	00001517          	auipc	a0,0x1
ffffffffc0201688:	44450513          	addi	a0,a0,1092 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020168c:	b15fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201690:	00001697          	auipc	a3,0x1
ffffffffc0201694:	62868693          	addi	a3,a3,1576 # ffffffffc0202cb8 <commands+0xa18>
ffffffffc0201698:	00001617          	auipc	a2,0x1
ffffffffc020169c:	41860613          	addi	a2,a2,1048 # ffffffffc0202ab0 <commands+0x810>
ffffffffc02016a0:	12500593          	li	a1,293
ffffffffc02016a4:	00001517          	auipc	a0,0x1
ffffffffc02016a8:	42450513          	addi	a0,a0,1060 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02016ac:	af5fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(p0 != NULL);
ffffffffc02016b0:	00001697          	auipc	a3,0x1
ffffffffc02016b4:	5f868693          	addi	a3,a3,1528 # ffffffffc0202ca8 <commands+0xa08>
ffffffffc02016b8:	00001617          	auipc	a2,0x1
ffffffffc02016bc:	3f860613          	addi	a2,a2,1016 # ffffffffc0202ab0 <commands+0x810>
ffffffffc02016c0:	12400593          	li	a1,292
ffffffffc02016c4:	00001517          	auipc	a0,0x1
ffffffffc02016c8:	40450513          	addi	a0,a0,1028 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02016cc:	ad5fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(nr_free == 0);
ffffffffc02016d0:	00001697          	auipc	a3,0x1
ffffffffc02016d4:	5c868693          	addi	a3,a3,1480 # ffffffffc0202c98 <commands+0x9f8>
ffffffffc02016d8:	00001617          	auipc	a2,0x1
ffffffffc02016dc:	3d860613          	addi	a2,a2,984 # ffffffffc0202ab0 <commands+0x810>
ffffffffc02016e0:	10400593          	li	a1,260
ffffffffc02016e4:	00001517          	auipc	a0,0x1
ffffffffc02016e8:	3e450513          	addi	a0,a0,996 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02016ec:	ab5fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016f0:	00001697          	auipc	a3,0x1
ffffffffc02016f4:	54868693          	addi	a3,a3,1352 # ffffffffc0202c38 <commands+0x998>
ffffffffc02016f8:	00001617          	auipc	a2,0x1
ffffffffc02016fc:	3b860613          	addi	a2,a2,952 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201700:	10200593          	li	a1,258
ffffffffc0201704:	00001517          	auipc	a0,0x1
ffffffffc0201708:	3c450513          	addi	a0,a0,964 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020170c:	a95fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201710:	00001697          	auipc	a3,0x1
ffffffffc0201714:	56868693          	addi	a3,a3,1384 # ffffffffc0202c78 <commands+0x9d8>
ffffffffc0201718:	00001617          	auipc	a2,0x1
ffffffffc020171c:	39860613          	addi	a2,a2,920 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201720:	10100593          	li	a1,257
ffffffffc0201724:	00001517          	auipc	a0,0x1
ffffffffc0201728:	3a450513          	addi	a0,a0,932 # ffffffffc0202ac8 <commands+0x828>
ffffffffc020172c:	a75fe0ef          	jal	ra,ffffffffc02001a0 <__panic>

ffffffffc0201730 <best_fit_free_pages>:
{
ffffffffc0201730:	1141                	addi	sp,sp,-16
ffffffffc0201732:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201734:	14058a63          	beqz	a1,ffffffffc0201888 <best_fit_free_pages+0x158>
    for (; p != base + n; p++)
ffffffffc0201738:	00259693          	slli	a3,a1,0x2
ffffffffc020173c:	96ae                	add	a3,a3,a1
ffffffffc020173e:	068e                	slli	a3,a3,0x3
ffffffffc0201740:	96aa                	add	a3,a3,a0
ffffffffc0201742:	87aa                	mv	a5,a0
ffffffffc0201744:	02d50263          	beq	a0,a3,ffffffffc0201768 <best_fit_free_pages+0x38>
ffffffffc0201748:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020174a:	8b05                	andi	a4,a4,1
ffffffffc020174c:	10071e63          	bnez	a4,ffffffffc0201868 <best_fit_free_pages+0x138>
ffffffffc0201750:	6798                	ld	a4,8(a5)
ffffffffc0201752:	8b09                	andi	a4,a4,2
ffffffffc0201754:	10071a63          	bnez	a4,ffffffffc0201868 <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc0201758:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020175c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201760:	02878793          	addi	a5,a5,40
ffffffffc0201764:	fed792e3          	bne	a5,a3,ffffffffc0201748 <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc0201768:	2581                	sext.w	a1,a1
ffffffffc020176a:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020176c:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201770:	4789                	li	a5,2
ffffffffc0201772:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201776:	00006697          	auipc	a3,0x6
ffffffffc020177a:	8b268693          	addi	a3,a3,-1870 # ffffffffc0207028 <free_area>
ffffffffc020177e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201780:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201782:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201786:	9db9                	addw	a1,a1,a4
ffffffffc0201788:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc020178a:	0ad78863          	beq	a5,a3,ffffffffc020183a <best_fit_free_pages+0x10a>
            struct Page *page = le2page(le, page_link);
ffffffffc020178e:	fe878713          	addi	a4,a5,-24
ffffffffc0201792:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201796:	4581                	li	a1,0
            if (base < page)
ffffffffc0201798:	00e56a63          	bltu	a0,a4,ffffffffc02017ac <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc020179c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020179e:	06d70263          	beq	a4,a3,ffffffffc0201802 <best_fit_free_pages+0xd2>
    for (; p != base + n; p++)
ffffffffc02017a2:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017a4:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017a8:	fee57ae3          	bgeu	a0,a4,ffffffffc020179c <best_fit_free_pages+0x6c>
ffffffffc02017ac:	c199                	beqz	a1,ffffffffc02017b2 <best_fit_free_pages+0x82>
ffffffffc02017ae:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017b2:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02017b4:	e390                	sd	a2,0(a5)
ffffffffc02017b6:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02017b8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017ba:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02017bc:	02d70063          	beq	a4,a3,ffffffffc02017dc <best_fit_free_pages+0xac>
        if (p + p->property == base)
ffffffffc02017c0:	ff872803          	lw	a6,-8(a4) # fffffffffff7fff8 <end+0x3fd78b60>
        p = le2page(le, page_link);
ffffffffc02017c4:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base)
ffffffffc02017c8:	02081613          	slli	a2,a6,0x20
ffffffffc02017cc:	9201                	srli	a2,a2,0x20
ffffffffc02017ce:	00261793          	slli	a5,a2,0x2
ffffffffc02017d2:	97b2                	add	a5,a5,a2
ffffffffc02017d4:	078e                	slli	a5,a5,0x3
ffffffffc02017d6:	97ae                	add	a5,a5,a1
ffffffffc02017d8:	02f50f63          	beq	a0,a5,ffffffffc0201816 <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc02017dc:	7118                	ld	a4,32(a0)
    if (le != &free_list)
ffffffffc02017de:	00d70f63          	beq	a4,a3,ffffffffc02017fc <best_fit_free_pages+0xcc>
        if (base + base->property == p)
ffffffffc02017e2:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02017e4:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p)
ffffffffc02017e8:	02059613          	slli	a2,a1,0x20
ffffffffc02017ec:	9201                	srli	a2,a2,0x20
ffffffffc02017ee:	00261793          	slli	a5,a2,0x2
ffffffffc02017f2:	97b2                	add	a5,a5,a2
ffffffffc02017f4:	078e                	slli	a5,a5,0x3
ffffffffc02017f6:	97aa                	add	a5,a5,a0
ffffffffc02017f8:	04f68863          	beq	a3,a5,ffffffffc0201848 <best_fit_free_pages+0x118>
}
ffffffffc02017fc:	60a2                	ld	ra,8(sp)
ffffffffc02017fe:	0141                	addi	sp,sp,16
ffffffffc0201800:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201802:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201804:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201806:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201808:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc020180a:	02d70563          	beq	a4,a3,ffffffffc0201834 <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc020180e:	8832                	mv	a6,a2
ffffffffc0201810:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201812:	87ba                	mv	a5,a4
ffffffffc0201814:	bf41                	j	ffffffffc02017a4 <best_fit_free_pages+0x74>
            p->property += base->property;
ffffffffc0201816:	491c                	lw	a5,16(a0)
ffffffffc0201818:	0107883b          	addw	a6,a5,a6
ffffffffc020181c:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201820:	57f5                	li	a5,-3
ffffffffc0201822:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201826:	6d10                	ld	a2,24(a0)
ffffffffc0201828:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc020182a:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc020182c:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc020182e:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201830:	e390                	sd	a2,0(a5)
ffffffffc0201832:	b775                	j	ffffffffc02017de <best_fit_free_pages+0xae>
ffffffffc0201834:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201836:	873e                	mv	a4,a5
ffffffffc0201838:	b761                	j	ffffffffc02017c0 <best_fit_free_pages+0x90>
}
ffffffffc020183a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020183c:	e390                	sd	a2,0(a5)
ffffffffc020183e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201840:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201842:	ed1c                	sd	a5,24(a0)
ffffffffc0201844:	0141                	addi	sp,sp,16
ffffffffc0201846:	8082                	ret
            base->property += p->property;
ffffffffc0201848:	ff872783          	lw	a5,-8(a4)
ffffffffc020184c:	ff070693          	addi	a3,a4,-16
ffffffffc0201850:	9dbd                	addw	a1,a1,a5
ffffffffc0201852:	c90c                	sw	a1,16(a0)
ffffffffc0201854:	57f5                	li	a5,-3
ffffffffc0201856:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020185a:	6314                	ld	a3,0(a4)
ffffffffc020185c:	671c                	ld	a5,8(a4)
}
ffffffffc020185e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201860:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201862:	e394                	sd	a3,0(a5)
ffffffffc0201864:	0141                	addi	sp,sp,16
ffffffffc0201866:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201868:	00001697          	auipc	a3,0x1
ffffffffc020186c:	53868693          	addi	a3,a3,1336 # ffffffffc0202da0 <commands+0xb00>
ffffffffc0201870:	00001617          	auipc	a2,0x1
ffffffffc0201874:	24060613          	addi	a2,a2,576 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201878:	09a00593          	li	a1,154
ffffffffc020187c:	00001517          	auipc	a0,0x1
ffffffffc0201880:	24c50513          	addi	a0,a0,588 # ffffffffc0202ac8 <commands+0x828>
ffffffffc0201884:	91dfe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(n > 0);
ffffffffc0201888:	00001697          	auipc	a3,0x1
ffffffffc020188c:	22068693          	addi	a3,a3,544 # ffffffffc0202aa8 <commands+0x808>
ffffffffc0201890:	00001617          	auipc	a2,0x1
ffffffffc0201894:	22060613          	addi	a2,a2,544 # ffffffffc0202ab0 <commands+0x810>
ffffffffc0201898:	09600593          	li	a1,150
ffffffffc020189c:	00001517          	auipc	a0,0x1
ffffffffc02018a0:	22c50513          	addi	a0,a0,556 # ffffffffc0202ac8 <commands+0x828>
ffffffffc02018a4:	8fdfe0ef          	jal	ra,ffffffffc02001a0 <__panic>

ffffffffc02018a8 <best_fit_init_memmap>:
{
ffffffffc02018a8:	1141                	addi	sp,sp,-16
ffffffffc02018aa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02018ac:	c9e1                	beqz	a1,ffffffffc020197c <best_fit_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc02018ae:	00259693          	slli	a3,a1,0x2
ffffffffc02018b2:	96ae                	add	a3,a3,a1
ffffffffc02018b4:	068e                	slli	a3,a3,0x3
ffffffffc02018b6:	96aa                	add	a3,a3,a0
ffffffffc02018b8:	87aa                	mv	a5,a0
ffffffffc02018ba:	00d50f63          	beq	a0,a3,ffffffffc02018d8 <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02018be:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02018c0:	8b05                	andi	a4,a4,1
ffffffffc02018c2:	cf49                	beqz	a4,ffffffffc020195c <best_fit_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02018c4:	0007a823          	sw	zero,16(a5)
ffffffffc02018c8:	0007b423          	sd	zero,8(a5)
ffffffffc02018cc:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02018d0:	02878793          	addi	a5,a5,40
ffffffffc02018d4:	fed795e3          	bne	a5,a3,ffffffffc02018be <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc02018d8:	2581                	sext.w	a1,a1
ffffffffc02018da:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018dc:	4789                	li	a5,2
ffffffffc02018de:	00850713          	addi	a4,a0,8
ffffffffc02018e2:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018e6:	00005697          	auipc	a3,0x5
ffffffffc02018ea:	74268693          	addi	a3,a3,1858 # ffffffffc0207028 <free_area>
ffffffffc02018ee:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02018f0:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02018f2:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02018f6:	9db9                	addw	a1,a1,a4
ffffffffc02018f8:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc02018fa:	04d78a63          	beq	a5,a3,ffffffffc020194e <best_fit_init_memmap+0xa6>
            struct Page *page = le2page(le, page_link);
ffffffffc02018fe:	fe878713          	addi	a4,a5,-24
ffffffffc0201902:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201906:	4581                	li	a1,0
            if (base < page)
ffffffffc0201908:	00e56a63          	bltu	a0,a4,ffffffffc020191c <best_fit_init_memmap+0x74>
    return listelm->next;
ffffffffc020190c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020190e:	02d70263          	beq	a4,a3,ffffffffc0201932 <best_fit_init_memmap+0x8a>
    for (; p != base + n; p++)
ffffffffc0201912:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201914:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201918:	fee57ae3          	bgeu	a0,a4,ffffffffc020190c <best_fit_init_memmap+0x64>
ffffffffc020191c:	c199                	beqz	a1,ffffffffc0201922 <best_fit_init_memmap+0x7a>
ffffffffc020191e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201922:	6398                	ld	a4,0(a5)
}
ffffffffc0201924:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201926:	e390                	sd	a2,0(a5)
ffffffffc0201928:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020192a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020192c:	ed18                	sd	a4,24(a0)
ffffffffc020192e:	0141                	addi	sp,sp,16
ffffffffc0201930:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201932:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201934:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201936:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201938:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc020193a:	00d70663          	beq	a4,a3,ffffffffc0201946 <best_fit_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc020193e:	8832                	mv	a6,a2
ffffffffc0201940:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201942:	87ba                	mv	a5,a4
ffffffffc0201944:	bfc1                	j	ffffffffc0201914 <best_fit_init_memmap+0x6c>
}
ffffffffc0201946:	60a2                	ld	ra,8(sp)
ffffffffc0201948:	e290                	sd	a2,0(a3)
ffffffffc020194a:	0141                	addi	sp,sp,16
ffffffffc020194c:	8082                	ret
ffffffffc020194e:	60a2                	ld	ra,8(sp)
ffffffffc0201950:	e390                	sd	a2,0(a5)
ffffffffc0201952:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201954:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201956:	ed1c                	sd	a5,24(a0)
ffffffffc0201958:	0141                	addi	sp,sp,16
ffffffffc020195a:	8082                	ret
        assert(PageReserved(p));
ffffffffc020195c:	00001697          	auipc	a3,0x1
ffffffffc0201960:	46c68693          	addi	a3,a3,1132 # ffffffffc0202dc8 <commands+0xb28>
ffffffffc0201964:	00001617          	auipc	a2,0x1
ffffffffc0201968:	14c60613          	addi	a2,a2,332 # ffffffffc0202ab0 <commands+0x810>
ffffffffc020196c:	04d00593          	li	a1,77
ffffffffc0201970:	00001517          	auipc	a0,0x1
ffffffffc0201974:	15850513          	addi	a0,a0,344 # ffffffffc0202ac8 <commands+0x828>
ffffffffc0201978:	829fe0ef          	jal	ra,ffffffffc02001a0 <__panic>
    assert(n > 0);
ffffffffc020197c:	00001697          	auipc	a3,0x1
ffffffffc0201980:	12c68693          	addi	a3,a3,300 # ffffffffc0202aa8 <commands+0x808>
ffffffffc0201984:	00001617          	auipc	a2,0x1
ffffffffc0201988:	12c60613          	addi	a2,a2,300 # ffffffffc0202ab0 <commands+0x810>
ffffffffc020198c:	04900593          	li	a1,73
ffffffffc0201990:	00001517          	auipc	a0,0x1
ffffffffc0201994:	13850513          	addi	a0,a0,312 # ffffffffc0202ac8 <commands+0x828>
ffffffffc0201998:	809fe0ef          	jal	ra,ffffffffc02001a0 <__panic>

ffffffffc020199c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020199c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02019a0:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02019a2:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02019a4:	cb81                	beqz	a5,ffffffffc02019b4 <strlen+0x18>
        cnt ++;
ffffffffc02019a6:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02019a8:	00a707b3          	add	a5,a4,a0
ffffffffc02019ac:	0007c783          	lbu	a5,0(a5)
ffffffffc02019b0:	fbfd                	bnez	a5,ffffffffc02019a6 <strlen+0xa>
ffffffffc02019b2:	8082                	ret
    }
    return cnt;
}
ffffffffc02019b4:	8082                	ret

ffffffffc02019b6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02019b6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02019b8:	e589                	bnez	a1,ffffffffc02019c2 <strnlen+0xc>
ffffffffc02019ba:	a811                	j	ffffffffc02019ce <strnlen+0x18>
        cnt ++;
ffffffffc02019bc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02019be:	00f58863          	beq	a1,a5,ffffffffc02019ce <strnlen+0x18>
ffffffffc02019c2:	00f50733          	add	a4,a0,a5
ffffffffc02019c6:	00074703          	lbu	a4,0(a4)
ffffffffc02019ca:	fb6d                	bnez	a4,ffffffffc02019bc <strnlen+0x6>
ffffffffc02019cc:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02019ce:	852e                	mv	a0,a1
ffffffffc02019d0:	8082                	ret

ffffffffc02019d2 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02019d2:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02019d6:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02019da:	cb89                	beqz	a5,ffffffffc02019ec <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02019dc:	0505                	addi	a0,a0,1
ffffffffc02019de:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02019e0:	fee789e3          	beq	a5,a4,ffffffffc02019d2 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02019e4:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02019e8:	9d19                	subw	a0,a0,a4
ffffffffc02019ea:	8082                	ret
ffffffffc02019ec:	4501                	li	a0,0
ffffffffc02019ee:	bfed                	j	ffffffffc02019e8 <strcmp+0x16>

ffffffffc02019f0 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02019f0:	c20d                	beqz	a2,ffffffffc0201a12 <strncmp+0x22>
ffffffffc02019f2:	962e                	add	a2,a2,a1
ffffffffc02019f4:	a031                	j	ffffffffc0201a00 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02019f6:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02019f8:	00e79a63          	bne	a5,a4,ffffffffc0201a0c <strncmp+0x1c>
ffffffffc02019fc:	00b60b63          	beq	a2,a1,ffffffffc0201a12 <strncmp+0x22>
ffffffffc0201a00:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201a04:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201a06:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201a0a:	f7f5                	bnez	a5,ffffffffc02019f6 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a0c:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201a10:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a12:	4501                	li	a0,0
ffffffffc0201a14:	8082                	ret

ffffffffc0201a16 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201a16:	00054783          	lbu	a5,0(a0)
ffffffffc0201a1a:	c799                	beqz	a5,ffffffffc0201a28 <strchr+0x12>
        if (*s == c) {
ffffffffc0201a1c:	00f58763          	beq	a1,a5,ffffffffc0201a2a <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201a20:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201a24:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201a26:	fbfd                	bnez	a5,ffffffffc0201a1c <strchr+0x6>
    }
    return NULL;
ffffffffc0201a28:	4501                	li	a0,0
}
ffffffffc0201a2a:	8082                	ret

ffffffffc0201a2c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201a2c:	ca01                	beqz	a2,ffffffffc0201a3c <memset+0x10>
ffffffffc0201a2e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201a30:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201a32:	0785                	addi	a5,a5,1
ffffffffc0201a34:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201a38:	fec79de3          	bne	a5,a2,ffffffffc0201a32 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201a3c:	8082                	ret

ffffffffc0201a3e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201a3e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a42:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201a44:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a48:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201a4a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a4e:	f022                	sd	s0,32(sp)
ffffffffc0201a50:	ec26                	sd	s1,24(sp)
ffffffffc0201a52:	e84a                	sd	s2,16(sp)
ffffffffc0201a54:	f406                	sd	ra,40(sp)
ffffffffc0201a56:	e44e                	sd	s3,8(sp)
ffffffffc0201a58:	84aa                	mv	s1,a0
ffffffffc0201a5a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a5c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201a60:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201a62:	03067e63          	bgeu	a2,a6,ffffffffc0201a9e <printnum+0x60>
ffffffffc0201a66:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a68:	00805763          	blez	s0,ffffffffc0201a76 <printnum+0x38>
ffffffffc0201a6c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a6e:	85ca                	mv	a1,s2
ffffffffc0201a70:	854e                	mv	a0,s3
ffffffffc0201a72:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a74:	fc65                	bnez	s0,ffffffffc0201a6c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a76:	1a02                	slli	s4,s4,0x20
ffffffffc0201a78:	00001797          	auipc	a5,0x1
ffffffffc0201a7c:	3b078793          	addi	a5,a5,944 # ffffffffc0202e28 <best_fit_pmm_manager+0x38>
ffffffffc0201a80:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a84:	9a3e                	add	s4,s4,a5
}
ffffffffc0201a86:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a88:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201a8c:	70a2                	ld	ra,40(sp)
ffffffffc0201a8e:	69a2                	ld	s3,8(sp)
ffffffffc0201a90:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a92:	85ca                	mv	a1,s2
ffffffffc0201a94:	87a6                	mv	a5,s1
}
ffffffffc0201a96:	6942                	ld	s2,16(sp)
ffffffffc0201a98:	64e2                	ld	s1,24(sp)
ffffffffc0201a9a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a9c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a9e:	03065633          	divu	a2,a2,a6
ffffffffc0201aa2:	8722                	mv	a4,s0
ffffffffc0201aa4:	f9bff0ef          	jal	ra,ffffffffc0201a3e <printnum>
ffffffffc0201aa8:	b7f9                	j	ffffffffc0201a76 <printnum+0x38>

ffffffffc0201aaa <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201aaa:	7119                	addi	sp,sp,-128
ffffffffc0201aac:	f4a6                	sd	s1,104(sp)
ffffffffc0201aae:	f0ca                	sd	s2,96(sp)
ffffffffc0201ab0:	ecce                	sd	s3,88(sp)
ffffffffc0201ab2:	e8d2                	sd	s4,80(sp)
ffffffffc0201ab4:	e4d6                	sd	s5,72(sp)
ffffffffc0201ab6:	e0da                	sd	s6,64(sp)
ffffffffc0201ab8:	fc5e                	sd	s7,56(sp)
ffffffffc0201aba:	f06a                	sd	s10,32(sp)
ffffffffc0201abc:	fc86                	sd	ra,120(sp)
ffffffffc0201abe:	f8a2                	sd	s0,112(sp)
ffffffffc0201ac0:	f862                	sd	s8,48(sp)
ffffffffc0201ac2:	f466                	sd	s9,40(sp)
ffffffffc0201ac4:	ec6e                	sd	s11,24(sp)
ffffffffc0201ac6:	892a                	mv	s2,a0
ffffffffc0201ac8:	84ae                	mv	s1,a1
ffffffffc0201aca:	8d32                	mv	s10,a2
ffffffffc0201acc:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ace:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201ad2:	5b7d                	li	s6,-1
ffffffffc0201ad4:	00001a97          	auipc	s5,0x1
ffffffffc0201ad8:	388a8a93          	addi	s5,s5,904 # ffffffffc0202e5c <best_fit_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201adc:	00001b97          	auipc	s7,0x1
ffffffffc0201ae0:	55cb8b93          	addi	s7,s7,1372 # ffffffffc0203038 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ae4:	000d4503          	lbu	a0,0(s10)
ffffffffc0201ae8:	001d0413          	addi	s0,s10,1
ffffffffc0201aec:	01350a63          	beq	a0,s3,ffffffffc0201b00 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201af0:	c121                	beqz	a0,ffffffffc0201b30 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201af2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201af4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201af6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201af8:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201afc:	ff351ae3          	bne	a0,s3,ffffffffc0201af0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b00:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201b04:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201b08:	4c81                	li	s9,0
ffffffffc0201b0a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201b0c:	5c7d                	li	s8,-1
ffffffffc0201b0e:	5dfd                	li	s11,-1
ffffffffc0201b10:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201b14:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b16:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b1a:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b1e:	00140d13          	addi	s10,s0,1
ffffffffc0201b22:	04b56263          	bltu	a0,a1,ffffffffc0201b66 <vprintfmt+0xbc>
ffffffffc0201b26:	058a                	slli	a1,a1,0x2
ffffffffc0201b28:	95d6                	add	a1,a1,s5
ffffffffc0201b2a:	4194                	lw	a3,0(a1)
ffffffffc0201b2c:	96d6                	add	a3,a3,s5
ffffffffc0201b2e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201b30:	70e6                	ld	ra,120(sp)
ffffffffc0201b32:	7446                	ld	s0,112(sp)
ffffffffc0201b34:	74a6                	ld	s1,104(sp)
ffffffffc0201b36:	7906                	ld	s2,96(sp)
ffffffffc0201b38:	69e6                	ld	s3,88(sp)
ffffffffc0201b3a:	6a46                	ld	s4,80(sp)
ffffffffc0201b3c:	6aa6                	ld	s5,72(sp)
ffffffffc0201b3e:	6b06                	ld	s6,64(sp)
ffffffffc0201b40:	7be2                	ld	s7,56(sp)
ffffffffc0201b42:	7c42                	ld	s8,48(sp)
ffffffffc0201b44:	7ca2                	ld	s9,40(sp)
ffffffffc0201b46:	7d02                	ld	s10,32(sp)
ffffffffc0201b48:	6de2                	ld	s11,24(sp)
ffffffffc0201b4a:	6109                	addi	sp,sp,128
ffffffffc0201b4c:	8082                	ret
            padc = '0';
ffffffffc0201b4e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201b50:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b54:	846a                	mv	s0,s10
ffffffffc0201b56:	00140d13          	addi	s10,s0,1
ffffffffc0201b5a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b5e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b62:	fcb572e3          	bgeu	a0,a1,ffffffffc0201b26 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201b66:	85a6                	mv	a1,s1
ffffffffc0201b68:	02500513          	li	a0,37
ffffffffc0201b6c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b6e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b72:	8d22                	mv	s10,s0
ffffffffc0201b74:	f73788e3          	beq	a5,s3,ffffffffc0201ae4 <vprintfmt+0x3a>
ffffffffc0201b78:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201b7c:	1d7d                	addi	s10,s10,-1
ffffffffc0201b7e:	ff379de3          	bne	a5,s3,ffffffffc0201b78 <vprintfmt+0xce>
ffffffffc0201b82:	b78d                	j	ffffffffc0201ae4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201b84:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201b88:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b8c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201b8e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201b92:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b96:	02d86463          	bltu	a6,a3,ffffffffc0201bbe <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201b9a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b9e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201ba2:	0186873b          	addw	a4,a3,s8
ffffffffc0201ba6:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201baa:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201bac:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201bb0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201bb2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201bb6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201bba:	fed870e3          	bgeu	a6,a3,ffffffffc0201b9a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201bbe:	f40ddce3          	bgez	s11,ffffffffc0201b16 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201bc2:	8de2                	mv	s11,s8
ffffffffc0201bc4:	5c7d                	li	s8,-1
ffffffffc0201bc6:	bf81                	j	ffffffffc0201b16 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201bc8:	fffdc693          	not	a3,s11
ffffffffc0201bcc:	96fd                	srai	a3,a3,0x3f
ffffffffc0201bce:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bd2:	00144603          	lbu	a2,1(s0)
ffffffffc0201bd6:	2d81                	sext.w	s11,s11
ffffffffc0201bd8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201bda:	bf35                	j	ffffffffc0201b16 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201bdc:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201be0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201be4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201be6:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201be8:	bfd9                	j	ffffffffc0201bbe <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201bea:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bf0:	01174463          	blt	a4,a7,ffffffffc0201bf8 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201bf4:	1a088e63          	beqz	a7,ffffffffc0201db0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201bf8:	000a3603          	ld	a2,0(s4)
ffffffffc0201bfc:	46c1                	li	a3,16
ffffffffc0201bfe:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201c00:	2781                	sext.w	a5,a5
ffffffffc0201c02:	876e                	mv	a4,s11
ffffffffc0201c04:	85a6                	mv	a1,s1
ffffffffc0201c06:	854a                	mv	a0,s2
ffffffffc0201c08:	e37ff0ef          	jal	ra,ffffffffc0201a3e <printnum>
            break;
ffffffffc0201c0c:	bde1                	j	ffffffffc0201ae4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201c0e:	000a2503          	lw	a0,0(s4)
ffffffffc0201c12:	85a6                	mv	a1,s1
ffffffffc0201c14:	0a21                	addi	s4,s4,8
ffffffffc0201c16:	9902                	jalr	s2
            break;
ffffffffc0201c18:	b5f1                	j	ffffffffc0201ae4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c1a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c1c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c20:	01174463          	blt	a4,a7,ffffffffc0201c28 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201c24:	18088163          	beqz	a7,ffffffffc0201da6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201c28:	000a3603          	ld	a2,0(s4)
ffffffffc0201c2c:	46a9                	li	a3,10
ffffffffc0201c2e:	8a2e                	mv	s4,a1
ffffffffc0201c30:	bfc1                	j	ffffffffc0201c00 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c32:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201c36:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c38:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c3a:	bdf1                	j	ffffffffc0201b16 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201c3c:	85a6                	mv	a1,s1
ffffffffc0201c3e:	02500513          	li	a0,37
ffffffffc0201c42:	9902                	jalr	s2
            break;
ffffffffc0201c44:	b545                	j	ffffffffc0201ae4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c46:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201c4a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c4c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c4e:	b5e1                	j	ffffffffc0201b16 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201c50:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c52:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c56:	01174463          	blt	a4,a7,ffffffffc0201c5e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201c5a:	14088163          	beqz	a7,ffffffffc0201d9c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201c5e:	000a3603          	ld	a2,0(s4)
ffffffffc0201c62:	46a1                	li	a3,8
ffffffffc0201c64:	8a2e                	mv	s4,a1
ffffffffc0201c66:	bf69                	j	ffffffffc0201c00 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201c68:	03000513          	li	a0,48
ffffffffc0201c6c:	85a6                	mv	a1,s1
ffffffffc0201c6e:	e03e                	sd	a5,0(sp)
ffffffffc0201c70:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c72:	85a6                	mv	a1,s1
ffffffffc0201c74:	07800513          	li	a0,120
ffffffffc0201c78:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c7a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201c7c:	6782                	ld	a5,0(sp)
ffffffffc0201c7e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c80:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201c84:	bfb5                	j	ffffffffc0201c00 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c86:	000a3403          	ld	s0,0(s4)
ffffffffc0201c8a:	008a0713          	addi	a4,s4,8
ffffffffc0201c8e:	e03a                	sd	a4,0(sp)
ffffffffc0201c90:	14040263          	beqz	s0,ffffffffc0201dd4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201c94:	0fb05763          	blez	s11,ffffffffc0201d82 <vprintfmt+0x2d8>
ffffffffc0201c98:	02d00693          	li	a3,45
ffffffffc0201c9c:	0cd79163          	bne	a5,a3,ffffffffc0201d5e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ca0:	00044783          	lbu	a5,0(s0)
ffffffffc0201ca4:	0007851b          	sext.w	a0,a5
ffffffffc0201ca8:	cf85                	beqz	a5,ffffffffc0201ce0 <vprintfmt+0x236>
ffffffffc0201caa:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cae:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cb2:	000c4563          	bltz	s8,ffffffffc0201cbc <vprintfmt+0x212>
ffffffffc0201cb6:	3c7d                	addiw	s8,s8,-1
ffffffffc0201cb8:	036c0263          	beq	s8,s6,ffffffffc0201cdc <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201cbc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cbe:	0e0c8e63          	beqz	s9,ffffffffc0201dba <vprintfmt+0x310>
ffffffffc0201cc2:	3781                	addiw	a5,a5,-32
ffffffffc0201cc4:	0ef47b63          	bgeu	s0,a5,ffffffffc0201dba <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201cc8:	03f00513          	li	a0,63
ffffffffc0201ccc:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cce:	000a4783          	lbu	a5,0(s4)
ffffffffc0201cd2:	3dfd                	addiw	s11,s11,-1
ffffffffc0201cd4:	0a05                	addi	s4,s4,1
ffffffffc0201cd6:	0007851b          	sext.w	a0,a5
ffffffffc0201cda:	ffe1                	bnez	a5,ffffffffc0201cb2 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201cdc:	01b05963          	blez	s11,ffffffffc0201cee <vprintfmt+0x244>
ffffffffc0201ce0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201ce2:	85a6                	mv	a1,s1
ffffffffc0201ce4:	02000513          	li	a0,32
ffffffffc0201ce8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201cea:	fe0d9be3          	bnez	s11,ffffffffc0201ce0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201cee:	6a02                	ld	s4,0(sp)
ffffffffc0201cf0:	bbd5                	j	ffffffffc0201ae4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201cf2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201cf4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201cf8:	01174463          	blt	a4,a7,ffffffffc0201d00 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201cfc:	08088d63          	beqz	a7,ffffffffc0201d96 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201d00:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201d04:	0a044d63          	bltz	s0,ffffffffc0201dbe <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201d08:	8622                	mv	a2,s0
ffffffffc0201d0a:	8a66                	mv	s4,s9
ffffffffc0201d0c:	46a9                	li	a3,10
ffffffffc0201d0e:	bdcd                	j	ffffffffc0201c00 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201d10:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d14:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201d16:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201d18:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201d1c:	8fb5                	xor	a5,a5,a3
ffffffffc0201d1e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d22:	02d74163          	blt	a4,a3,ffffffffc0201d44 <vprintfmt+0x29a>
ffffffffc0201d26:	00369793          	slli	a5,a3,0x3
ffffffffc0201d2a:	97de                	add	a5,a5,s7
ffffffffc0201d2c:	639c                	ld	a5,0(a5)
ffffffffc0201d2e:	cb99                	beqz	a5,ffffffffc0201d44 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201d30:	86be                	mv	a3,a5
ffffffffc0201d32:	00001617          	auipc	a2,0x1
ffffffffc0201d36:	12660613          	addi	a2,a2,294 # ffffffffc0202e58 <best_fit_pmm_manager+0x68>
ffffffffc0201d3a:	85a6                	mv	a1,s1
ffffffffc0201d3c:	854a                	mv	a0,s2
ffffffffc0201d3e:	0ce000ef          	jal	ra,ffffffffc0201e0c <printfmt>
ffffffffc0201d42:	b34d                	j	ffffffffc0201ae4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201d44:	00001617          	auipc	a2,0x1
ffffffffc0201d48:	10460613          	addi	a2,a2,260 # ffffffffc0202e48 <best_fit_pmm_manager+0x58>
ffffffffc0201d4c:	85a6                	mv	a1,s1
ffffffffc0201d4e:	854a                	mv	a0,s2
ffffffffc0201d50:	0bc000ef          	jal	ra,ffffffffc0201e0c <printfmt>
ffffffffc0201d54:	bb41                	j	ffffffffc0201ae4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201d56:	00001417          	auipc	s0,0x1
ffffffffc0201d5a:	0ea40413          	addi	s0,s0,234 # ffffffffc0202e40 <best_fit_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d5e:	85e2                	mv	a1,s8
ffffffffc0201d60:	8522                	mv	a0,s0
ffffffffc0201d62:	e43e                	sd	a5,8(sp)
ffffffffc0201d64:	c53ff0ef          	jal	ra,ffffffffc02019b6 <strnlen>
ffffffffc0201d68:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201d6c:	01b05b63          	blez	s11,ffffffffc0201d82 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201d70:	67a2                	ld	a5,8(sp)
ffffffffc0201d72:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d76:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201d78:	85a6                	mv	a1,s1
ffffffffc0201d7a:	8552                	mv	a0,s4
ffffffffc0201d7c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d7e:	fe0d9ce3          	bnez	s11,ffffffffc0201d76 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d82:	00044783          	lbu	a5,0(s0)
ffffffffc0201d86:	00140a13          	addi	s4,s0,1
ffffffffc0201d8a:	0007851b          	sext.w	a0,a5
ffffffffc0201d8e:	d3a5                	beqz	a5,ffffffffc0201cee <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d90:	05e00413          	li	s0,94
ffffffffc0201d94:	bf39                	j	ffffffffc0201cb2 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201d96:	000a2403          	lw	s0,0(s4)
ffffffffc0201d9a:	b7ad                	j	ffffffffc0201d04 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201d9c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201da0:	46a1                	li	a3,8
ffffffffc0201da2:	8a2e                	mv	s4,a1
ffffffffc0201da4:	bdb1                	j	ffffffffc0201c00 <vprintfmt+0x156>
ffffffffc0201da6:	000a6603          	lwu	a2,0(s4)
ffffffffc0201daa:	46a9                	li	a3,10
ffffffffc0201dac:	8a2e                	mv	s4,a1
ffffffffc0201dae:	bd89                	j	ffffffffc0201c00 <vprintfmt+0x156>
ffffffffc0201db0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201db4:	46c1                	li	a3,16
ffffffffc0201db6:	8a2e                	mv	s4,a1
ffffffffc0201db8:	b5a1                	j	ffffffffc0201c00 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201dba:	9902                	jalr	s2
ffffffffc0201dbc:	bf09                	j	ffffffffc0201cce <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201dbe:	85a6                	mv	a1,s1
ffffffffc0201dc0:	02d00513          	li	a0,45
ffffffffc0201dc4:	e03e                	sd	a5,0(sp)
ffffffffc0201dc6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201dc8:	6782                	ld	a5,0(sp)
ffffffffc0201dca:	8a66                	mv	s4,s9
ffffffffc0201dcc:	40800633          	neg	a2,s0
ffffffffc0201dd0:	46a9                	li	a3,10
ffffffffc0201dd2:	b53d                	j	ffffffffc0201c00 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201dd4:	03b05163          	blez	s11,ffffffffc0201df6 <vprintfmt+0x34c>
ffffffffc0201dd8:	02d00693          	li	a3,45
ffffffffc0201ddc:	f6d79de3          	bne	a5,a3,ffffffffc0201d56 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201de0:	00001417          	auipc	s0,0x1
ffffffffc0201de4:	06040413          	addi	s0,s0,96 # ffffffffc0202e40 <best_fit_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201de8:	02800793          	li	a5,40
ffffffffc0201dec:	02800513          	li	a0,40
ffffffffc0201df0:	00140a13          	addi	s4,s0,1
ffffffffc0201df4:	bd6d                	j	ffffffffc0201cae <vprintfmt+0x204>
ffffffffc0201df6:	00001a17          	auipc	s4,0x1
ffffffffc0201dfa:	04ba0a13          	addi	s4,s4,75 # ffffffffc0202e41 <best_fit_pmm_manager+0x51>
ffffffffc0201dfe:	02800513          	li	a0,40
ffffffffc0201e02:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e06:	05e00413          	li	s0,94
ffffffffc0201e0a:	b565                	j	ffffffffc0201cb2 <vprintfmt+0x208>

ffffffffc0201e0c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e0c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201e0e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e12:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e14:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e16:	ec06                	sd	ra,24(sp)
ffffffffc0201e18:	f83a                	sd	a4,48(sp)
ffffffffc0201e1a:	fc3e                	sd	a5,56(sp)
ffffffffc0201e1c:	e0c2                	sd	a6,64(sp)
ffffffffc0201e1e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201e20:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e22:	c89ff0ef          	jal	ra,ffffffffc0201aaa <vprintfmt>
}
ffffffffc0201e26:	60e2                	ld	ra,24(sp)
ffffffffc0201e28:	6161                	addi	sp,sp,80
ffffffffc0201e2a:	8082                	ret

ffffffffc0201e2c <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201e2c:	715d                	addi	sp,sp,-80
ffffffffc0201e2e:	e486                	sd	ra,72(sp)
ffffffffc0201e30:	e0a6                	sd	s1,64(sp)
ffffffffc0201e32:	fc4a                	sd	s2,56(sp)
ffffffffc0201e34:	f84e                	sd	s3,48(sp)
ffffffffc0201e36:	f452                	sd	s4,40(sp)
ffffffffc0201e38:	f056                	sd	s5,32(sp)
ffffffffc0201e3a:	ec5a                	sd	s6,24(sp)
ffffffffc0201e3c:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201e3e:	c901                	beqz	a0,ffffffffc0201e4e <readline+0x22>
ffffffffc0201e40:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201e42:	00001517          	auipc	a0,0x1
ffffffffc0201e46:	01650513          	addi	a0,a0,22 # ffffffffc0202e58 <best_fit_pmm_manager+0x68>
ffffffffc0201e4a:	acefe0ef          	jal	ra,ffffffffc0200118 <cprintf>
readline(const char *prompt) {
ffffffffc0201e4e:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e50:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201e52:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201e54:	4aa9                	li	s5,10
ffffffffc0201e56:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201e58:	00005b97          	auipc	s7,0x5
ffffffffc0201e5c:	1e8b8b93          	addi	s7,s7,488 # ffffffffc0207040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e60:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201e64:	b2cfe0ef          	jal	ra,ffffffffc0200190 <getchar>
        if (c < 0) {
ffffffffc0201e68:	00054a63          	bltz	a0,ffffffffc0201e7c <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e6c:	00a95a63          	bge	s2,a0,ffffffffc0201e80 <readline+0x54>
ffffffffc0201e70:	029a5263          	bge	s4,s1,ffffffffc0201e94 <readline+0x68>
        c = getchar();
ffffffffc0201e74:	b1cfe0ef          	jal	ra,ffffffffc0200190 <getchar>
        if (c < 0) {
ffffffffc0201e78:	fe055ae3          	bgez	a0,ffffffffc0201e6c <readline+0x40>
            return NULL;
ffffffffc0201e7c:	4501                	li	a0,0
ffffffffc0201e7e:	a091                	j	ffffffffc0201ec2 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201e80:	03351463          	bne	a0,s3,ffffffffc0201ea8 <readline+0x7c>
ffffffffc0201e84:	e8a9                	bnez	s1,ffffffffc0201ed6 <readline+0xaa>
        c = getchar();
ffffffffc0201e86:	b0afe0ef          	jal	ra,ffffffffc0200190 <getchar>
        if (c < 0) {
ffffffffc0201e8a:	fe0549e3          	bltz	a0,ffffffffc0201e7c <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e8e:	fea959e3          	bge	s2,a0,ffffffffc0201e80 <readline+0x54>
ffffffffc0201e92:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201e94:	e42a                	sd	a0,8(sp)
ffffffffc0201e96:	ab8fe0ef          	jal	ra,ffffffffc020014e <cputchar>
            buf[i ++] = c;
ffffffffc0201e9a:	6522                	ld	a0,8(sp)
ffffffffc0201e9c:	009b87b3          	add	a5,s7,s1
ffffffffc0201ea0:	2485                	addiw	s1,s1,1
ffffffffc0201ea2:	00a78023          	sb	a0,0(a5)
ffffffffc0201ea6:	bf7d                	j	ffffffffc0201e64 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201ea8:	01550463          	beq	a0,s5,ffffffffc0201eb0 <readline+0x84>
ffffffffc0201eac:	fb651ce3          	bne	a0,s6,ffffffffc0201e64 <readline+0x38>
            cputchar(c);
ffffffffc0201eb0:	a9efe0ef          	jal	ra,ffffffffc020014e <cputchar>
            buf[i] = '\0';
ffffffffc0201eb4:	00005517          	auipc	a0,0x5
ffffffffc0201eb8:	18c50513          	addi	a0,a0,396 # ffffffffc0207040 <buf>
ffffffffc0201ebc:	94aa                	add	s1,s1,a0
ffffffffc0201ebe:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201ec2:	60a6                	ld	ra,72(sp)
ffffffffc0201ec4:	6486                	ld	s1,64(sp)
ffffffffc0201ec6:	7962                	ld	s2,56(sp)
ffffffffc0201ec8:	79c2                	ld	s3,48(sp)
ffffffffc0201eca:	7a22                	ld	s4,40(sp)
ffffffffc0201ecc:	7a82                	ld	s5,32(sp)
ffffffffc0201ece:	6b62                	ld	s6,24(sp)
ffffffffc0201ed0:	6bc2                	ld	s7,16(sp)
ffffffffc0201ed2:	6161                	addi	sp,sp,80
ffffffffc0201ed4:	8082                	ret
            cputchar(c);
ffffffffc0201ed6:	4521                	li	a0,8
ffffffffc0201ed8:	a76fe0ef          	jal	ra,ffffffffc020014e <cputchar>
            i --;
ffffffffc0201edc:	34fd                	addiw	s1,s1,-1
ffffffffc0201ede:	b759                	j	ffffffffc0201e64 <readline+0x38>

ffffffffc0201ee0 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201ee0:	4781                	li	a5,0
ffffffffc0201ee2:	00005717          	auipc	a4,0x5
ffffffffc0201ee6:	13673703          	ld	a4,310(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201eea:	88ba                	mv	a7,a4
ffffffffc0201eec:	852a                	mv	a0,a0
ffffffffc0201eee:	85be                	mv	a1,a5
ffffffffc0201ef0:	863e                	mv	a2,a5
ffffffffc0201ef2:	00000073          	ecall
ffffffffc0201ef6:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201ef8:	8082                	ret

ffffffffc0201efa <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201efa:	4781                	li	a5,0
ffffffffc0201efc:	00005717          	auipc	a4,0x5
ffffffffc0201f00:	59473703          	ld	a4,1428(a4) # ffffffffc0207490 <SBI_SET_TIMER>
ffffffffc0201f04:	88ba                	mv	a7,a4
ffffffffc0201f06:	852a                	mv	a0,a0
ffffffffc0201f08:	85be                	mv	a1,a5
ffffffffc0201f0a:	863e                	mv	a2,a5
ffffffffc0201f0c:	00000073          	ecall
ffffffffc0201f10:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201f12:	8082                	ret

ffffffffc0201f14 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201f14:	4501                	li	a0,0
ffffffffc0201f16:	00005797          	auipc	a5,0x5
ffffffffc0201f1a:	0fa7b783          	ld	a5,250(a5) # ffffffffc0207010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201f1e:	88be                	mv	a7,a5
ffffffffc0201f20:	852a                	mv	a0,a0
ffffffffc0201f22:	85aa                	mv	a1,a0
ffffffffc0201f24:	862a                	mv	a2,a0
ffffffffc0201f26:	00000073          	ecall
ffffffffc0201f2a:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201f2c:	2501                	sext.w	a0,a0
ffffffffc0201f2e:	8082                	ret

ffffffffc0201f30 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201f30:	4781                	li	a5,0
ffffffffc0201f32:	00005717          	auipc	a4,0x5
ffffffffc0201f36:	0ee73703          	ld	a4,238(a4) # ffffffffc0207020 <SBI_SHUTDOWN>
ffffffffc0201f3a:	88ba                	mv	a7,a4
ffffffffc0201f3c:	853e                	mv	a0,a5
ffffffffc0201f3e:	85be                	mv	a1,a5
ffffffffc0201f40:	863e                	mv	a2,a5
ffffffffc0201f42:	00000073          	ecall
ffffffffc0201f46:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201f48:	8082                	ret
