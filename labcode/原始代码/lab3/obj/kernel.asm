
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
ffffffffc020005a:	fb250513          	addi	a0,a0,-78 # ffffffffc0202008 <etext>
{
ffffffffc020005e:	e406                	sd	ra,8(sp)
    cprintf("Testing breakpoint exception...\n");
ffffffffc0200060:	0b8000ef          	jal	ra,ffffffffc0200118 <cprintf>
    asm volatile("ebreak");
ffffffffc0200064:	9002                	ebreak
    cprintf("After ebreak: breakpoint exception handled successfully!\n");
ffffffffc0200066:	00002517          	auipc	a0,0x2
ffffffffc020006a:	fca50513          	addi	a0,a0,-54 # ffffffffc0202030 <etext+0x28>
ffffffffc020006e:	0aa000ef          	jal	ra,ffffffffc0200118 <cprintf>

    // 测试非法指令异常
    cprintf("\nTesting illegal instruction exception...\n");
ffffffffc0200072:	00002517          	auipc	a0,0x2
ffffffffc0200076:	ffe50513          	addi	a0,a0,-2 # ffffffffc0202070 <etext+0x68>
ffffffffc020007a:	09e000ef          	jal	ra,ffffffffc0200118 <cprintf>
ffffffffc020007e:	0000                	unimp
ffffffffc0200080:	0000                	unimp
    asm volatile(".word 0x00000000"); // 未定义指令
    cprintf("After illegal instruction: exception handled successfully!\n");
}
ffffffffc0200082:	60a2                	ld	ra,8(sp)
    cprintf("After illegal instruction: exception handled successfully!\n");
ffffffffc0200084:	00002517          	auipc	a0,0x2
ffffffffc0200088:	01c50513          	addi	a0,a0,28 # ffffffffc02020a0 <etext+0x98>
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
ffffffffc02000a8:	74f010ef          	jal	ra,ffffffffc0201ff6 <memset>
    dtb_init();
ffffffffc02000ac:	412000ef          	jal	ra,ffffffffc02004be <dtb_init>
    cons_init(); // init the console
ffffffffc02000b0:	400000ef          	jal	ra,ffffffffc02004b0 <cons_init>
    cputs(message);
ffffffffc02000b4:	00002517          	auipc	a0,0x2
ffffffffc02000b8:	02c50513          	addi	a0,a0,44 # ffffffffc02020e0 <etext+0xd8>
ffffffffc02000bc:	094000ef          	jal	ra,ffffffffc0200150 <cputs>
    print_kerninfo();
ffffffffc02000c0:	0e0000ef          	jal	ra,ffffffffc02001a0 <print_kerninfo>
    idt_init(); // init interrupt descriptor table
ffffffffc02000c4:	7b6000ef          	jal	ra,ffffffffc020087a <idt_init>
    pmm_init(); // init physical memory management
ffffffffc02000c8:	7b2010ef          	jal	ra,ffffffffc020187a <pmm_init>
    idt_init(); // init interrupt descriptor table
ffffffffc02000cc:	7ae000ef          	jal	ra,ffffffffc020087a <idt_init>
    clock_init();  // init clock interrupt
ffffffffc02000d0:	39e000ef          	jal	ra,ffffffffc020046e <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000d4:	79a000ef          	jal	ra,ffffffffc020086e <intr_enable>
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
ffffffffc02000e6:	3cc000ef          	jal	ra,ffffffffc02004b2 <cons_putc>
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
ffffffffc020010c:	1bb010ef          	jal	ra,ffffffffc0201ac6 <vprintfmt>
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
ffffffffc0200142:	185010ef          	jal	ra,ffffffffc0201ac6 <vprintfmt>
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
ffffffffc020014e:	a695                	j	ffffffffc02004b2 <cons_putc>

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
ffffffffc0200166:	34c000ef          	jal	ra,ffffffffc02004b2 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020016a:	00044503          	lbu	a0,0(s0)
ffffffffc020016e:	008487bb          	addw	a5,s1,s0
ffffffffc0200172:	0405                	addi	s0,s0,1
ffffffffc0200174:	f96d                	bnez	a0,ffffffffc0200166 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200176:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020017a:	4529                	li	a0,10
ffffffffc020017c:	336000ef          	jal	ra,ffffffffc02004b2 <cons_putc>
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
ffffffffc0200194:	326000ef          	jal	ra,ffffffffc02004ba <cons_getc>
ffffffffc0200198:	dd75                	beqz	a0,ffffffffc0200194 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020019a:	60a2                	ld	ra,8(sp)
ffffffffc020019c:	0141                	addi	sp,sp,16
ffffffffc020019e:	8082                	ret

ffffffffc02001a0 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02001a0:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001a2:	00002517          	auipc	a0,0x2
ffffffffc02001a6:	f5e50513          	addi	a0,a0,-162 # ffffffffc0202100 <etext+0xf8>
void print_kerninfo(void) {
ffffffffc02001aa:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001ac:	f6dff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001b0:	00000597          	auipc	a1,0x0
ffffffffc02001b4:	ee058593          	addi	a1,a1,-288 # ffffffffc0200090 <kern_init>
ffffffffc02001b8:	00002517          	auipc	a0,0x2
ffffffffc02001bc:	f6850513          	addi	a0,a0,-152 # ffffffffc0202120 <etext+0x118>
ffffffffc02001c0:	f59ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001c4:	00002597          	auipc	a1,0x2
ffffffffc02001c8:	e4458593          	addi	a1,a1,-444 # ffffffffc0202008 <etext>
ffffffffc02001cc:	00002517          	auipc	a0,0x2
ffffffffc02001d0:	f7450513          	addi	a0,a0,-140 # ffffffffc0202140 <etext+0x138>
ffffffffc02001d4:	f45ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001d8:	00007597          	auipc	a1,0x7
ffffffffc02001dc:	e5058593          	addi	a1,a1,-432 # ffffffffc0207028 <free_area>
ffffffffc02001e0:	00002517          	auipc	a0,0x2
ffffffffc02001e4:	f8050513          	addi	a0,a0,-128 # ffffffffc0202160 <etext+0x158>
ffffffffc02001e8:	f31ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001ec:	00007597          	auipc	a1,0x7
ffffffffc02001f0:	2ac58593          	addi	a1,a1,684 # ffffffffc0207498 <end>
ffffffffc02001f4:	00002517          	auipc	a0,0x2
ffffffffc02001f8:	f8c50513          	addi	a0,a0,-116 # ffffffffc0202180 <etext+0x178>
ffffffffc02001fc:	f1dff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200200:	00007597          	auipc	a1,0x7
ffffffffc0200204:	69758593          	addi	a1,a1,1687 # ffffffffc0207897 <end+0x3ff>
ffffffffc0200208:	00000797          	auipc	a5,0x0
ffffffffc020020c:	e8878793          	addi	a5,a5,-376 # ffffffffc0200090 <kern_init>
ffffffffc0200210:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200214:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200218:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020021a:	3ff5f593          	andi	a1,a1,1023
ffffffffc020021e:	95be                	add	a1,a1,a5
ffffffffc0200220:	85a9                	srai	a1,a1,0xa
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	f7e50513          	addi	a0,a0,-130 # ffffffffc02021a0 <etext+0x198>
}
ffffffffc020022a:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020022c:	b5f5                	j	ffffffffc0200118 <cprintf>

ffffffffc020022e <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc020022e:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200230:	00002617          	auipc	a2,0x2
ffffffffc0200234:	fa060613          	addi	a2,a2,-96 # ffffffffc02021d0 <etext+0x1c8>
ffffffffc0200238:	04d00593          	li	a1,77
ffffffffc020023c:	00002517          	auipc	a0,0x2
ffffffffc0200240:	fac50513          	addi	a0,a0,-84 # ffffffffc02021e8 <etext+0x1e0>
void print_stackframe(void) {
ffffffffc0200244:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200246:	1cc000ef          	jal	ra,ffffffffc0200412 <__panic>

ffffffffc020024a <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020024c:	00002617          	auipc	a2,0x2
ffffffffc0200250:	fb460613          	addi	a2,a2,-76 # ffffffffc0202200 <etext+0x1f8>
ffffffffc0200254:	00002597          	auipc	a1,0x2
ffffffffc0200258:	fcc58593          	addi	a1,a1,-52 # ffffffffc0202220 <etext+0x218>
ffffffffc020025c:	00002517          	auipc	a0,0x2
ffffffffc0200260:	fcc50513          	addi	a0,a0,-52 # ffffffffc0202228 <etext+0x220>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200264:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200266:	eb3ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
ffffffffc020026a:	00002617          	auipc	a2,0x2
ffffffffc020026e:	fce60613          	addi	a2,a2,-50 # ffffffffc0202238 <etext+0x230>
ffffffffc0200272:	00002597          	auipc	a1,0x2
ffffffffc0200276:	fee58593          	addi	a1,a1,-18 # ffffffffc0202260 <etext+0x258>
ffffffffc020027a:	00002517          	auipc	a0,0x2
ffffffffc020027e:	fae50513          	addi	a0,a0,-82 # ffffffffc0202228 <etext+0x220>
ffffffffc0200282:	e97ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
ffffffffc0200286:	00002617          	auipc	a2,0x2
ffffffffc020028a:	fea60613          	addi	a2,a2,-22 # ffffffffc0202270 <etext+0x268>
ffffffffc020028e:	00002597          	auipc	a1,0x2
ffffffffc0200292:	00258593          	addi	a1,a1,2 # ffffffffc0202290 <etext+0x288>
ffffffffc0200296:	00002517          	auipc	a0,0x2
ffffffffc020029a:	f9250513          	addi	a0,a0,-110 # ffffffffc0202228 <etext+0x220>
ffffffffc020029e:	e7bff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    }
    return 0;
}
ffffffffc02002a2:	60a2                	ld	ra,8(sp)
ffffffffc02002a4:	4501                	li	a0,0
ffffffffc02002a6:	0141                	addi	sp,sp,16
ffffffffc02002a8:	8082                	ret

ffffffffc02002aa <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002aa:	1141                	addi	sp,sp,-16
ffffffffc02002ac:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ae:	ef3ff0ef          	jal	ra,ffffffffc02001a0 <print_kerninfo>
    return 0;
}
ffffffffc02002b2:	60a2                	ld	ra,8(sp)
ffffffffc02002b4:	4501                	li	a0,0
ffffffffc02002b6:	0141                	addi	sp,sp,16
ffffffffc02002b8:	8082                	ret

ffffffffc02002ba <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ba:	1141                	addi	sp,sp,-16
ffffffffc02002bc:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002be:	f71ff0ef          	jal	ra,ffffffffc020022e <print_stackframe>
    return 0;
}
ffffffffc02002c2:	60a2                	ld	ra,8(sp)
ffffffffc02002c4:	4501                	li	a0,0
ffffffffc02002c6:	0141                	addi	sp,sp,16
ffffffffc02002c8:	8082                	ret

ffffffffc02002ca <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002ca:	7115                	addi	sp,sp,-224
ffffffffc02002cc:	ed5e                	sd	s7,152(sp)
ffffffffc02002ce:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002d0:	00002517          	auipc	a0,0x2
ffffffffc02002d4:	fd050513          	addi	a0,a0,-48 # ffffffffc02022a0 <etext+0x298>
kmonitor(struct trapframe *tf) {
ffffffffc02002d8:	ed86                	sd	ra,216(sp)
ffffffffc02002da:	e9a2                	sd	s0,208(sp)
ffffffffc02002dc:	e5a6                	sd	s1,200(sp)
ffffffffc02002de:	e1ca                	sd	s2,192(sp)
ffffffffc02002e0:	fd4e                	sd	s3,184(sp)
ffffffffc02002e2:	f952                	sd	s4,176(sp)
ffffffffc02002e4:	f556                	sd	s5,168(sp)
ffffffffc02002e6:	f15a                	sd	s6,160(sp)
ffffffffc02002e8:	e962                	sd	s8,144(sp)
ffffffffc02002ea:	e566                	sd	s9,136(sp)
ffffffffc02002ec:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ee:	e2bff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002f2:	00002517          	auipc	a0,0x2
ffffffffc02002f6:	fd650513          	addi	a0,a0,-42 # ffffffffc02022c8 <etext+0x2c0>
ffffffffc02002fa:	e1fff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    if (tf != NULL) {
ffffffffc02002fe:	000b8563          	beqz	s7,ffffffffc0200308 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200302:	855e                	mv	a0,s7
ffffffffc0200304:	756000ef          	jal	ra,ffffffffc0200a5a <print_trapframe>
ffffffffc0200308:	00002c17          	auipc	s8,0x2
ffffffffc020030c:	030c0c13          	addi	s8,s8,48 # ffffffffc0202338 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200310:	00002917          	auipc	s2,0x2
ffffffffc0200314:	fe090913          	addi	s2,s2,-32 # ffffffffc02022f0 <etext+0x2e8>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200318:	00002497          	auipc	s1,0x2
ffffffffc020031c:	fe048493          	addi	s1,s1,-32 # ffffffffc02022f8 <etext+0x2f0>
        if (argc == MAXARGS - 1) {
ffffffffc0200320:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200322:	00002b17          	auipc	s6,0x2
ffffffffc0200326:	fdeb0b13          	addi	s6,s6,-34 # ffffffffc0202300 <etext+0x2f8>
        argv[argc ++] = buf;
ffffffffc020032a:	00002a17          	auipc	s4,0x2
ffffffffc020032e:	ef6a0a13          	addi	s4,s4,-266 # ffffffffc0202220 <etext+0x218>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200332:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200334:	854a                	mv	a0,s2
ffffffffc0200336:	313010ef          	jal	ra,ffffffffc0201e48 <readline>
ffffffffc020033a:	842a                	mv	s0,a0
ffffffffc020033c:	dd65                	beqz	a0,ffffffffc0200334 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020033e:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200342:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200344:	e1bd                	bnez	a1,ffffffffc02003aa <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200346:	fe0c87e3          	beqz	s9,ffffffffc0200334 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020034a:	6582                	ld	a1,0(sp)
ffffffffc020034c:	00002d17          	auipc	s10,0x2
ffffffffc0200350:	fecd0d13          	addi	s10,s10,-20 # ffffffffc0202338 <commands>
        argv[argc ++] = buf;
ffffffffc0200354:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200356:	4401                	li	s0,0
ffffffffc0200358:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020035a:	443010ef          	jal	ra,ffffffffc0201f9c <strcmp>
ffffffffc020035e:	c919                	beqz	a0,ffffffffc0200374 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200360:	2405                	addiw	s0,s0,1
ffffffffc0200362:	0b540063          	beq	s0,s5,ffffffffc0200402 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200366:	000d3503          	ld	a0,0(s10)
ffffffffc020036a:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020036c:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020036e:	42f010ef          	jal	ra,ffffffffc0201f9c <strcmp>
ffffffffc0200372:	f57d                	bnez	a0,ffffffffc0200360 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200374:	00141793          	slli	a5,s0,0x1
ffffffffc0200378:	97a2                	add	a5,a5,s0
ffffffffc020037a:	078e                	slli	a5,a5,0x3
ffffffffc020037c:	97e2                	add	a5,a5,s8
ffffffffc020037e:	6b9c                	ld	a5,16(a5)
ffffffffc0200380:	865e                	mv	a2,s7
ffffffffc0200382:	002c                	addi	a1,sp,8
ffffffffc0200384:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200388:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020038a:	fa0555e3          	bgez	a0,ffffffffc0200334 <kmonitor+0x6a>
}
ffffffffc020038e:	60ee                	ld	ra,216(sp)
ffffffffc0200390:	644e                	ld	s0,208(sp)
ffffffffc0200392:	64ae                	ld	s1,200(sp)
ffffffffc0200394:	690e                	ld	s2,192(sp)
ffffffffc0200396:	79ea                	ld	s3,184(sp)
ffffffffc0200398:	7a4a                	ld	s4,176(sp)
ffffffffc020039a:	7aaa                	ld	s5,168(sp)
ffffffffc020039c:	7b0a                	ld	s6,160(sp)
ffffffffc020039e:	6bea                	ld	s7,152(sp)
ffffffffc02003a0:	6c4a                	ld	s8,144(sp)
ffffffffc02003a2:	6caa                	ld	s9,136(sp)
ffffffffc02003a4:	6d0a                	ld	s10,128(sp)
ffffffffc02003a6:	612d                	addi	sp,sp,224
ffffffffc02003a8:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003aa:	8526                	mv	a0,s1
ffffffffc02003ac:	435010ef          	jal	ra,ffffffffc0201fe0 <strchr>
ffffffffc02003b0:	c901                	beqz	a0,ffffffffc02003c0 <kmonitor+0xf6>
ffffffffc02003b2:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003b6:	00040023          	sb	zero,0(s0)
ffffffffc02003ba:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003bc:	d5c9                	beqz	a1,ffffffffc0200346 <kmonitor+0x7c>
ffffffffc02003be:	b7f5                	j	ffffffffc02003aa <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02003c0:	00044783          	lbu	a5,0(s0)
ffffffffc02003c4:	d3c9                	beqz	a5,ffffffffc0200346 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02003c6:	033c8963          	beq	s9,s3,ffffffffc02003f8 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02003ca:	003c9793          	slli	a5,s9,0x3
ffffffffc02003ce:	0118                	addi	a4,sp,128
ffffffffc02003d0:	97ba                	add	a5,a5,a4
ffffffffc02003d2:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003d6:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003da:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003dc:	e591                	bnez	a1,ffffffffc02003e8 <kmonitor+0x11e>
ffffffffc02003de:	b7b5                	j	ffffffffc020034a <kmonitor+0x80>
ffffffffc02003e0:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003e4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003e6:	d1a5                	beqz	a1,ffffffffc0200346 <kmonitor+0x7c>
ffffffffc02003e8:	8526                	mv	a0,s1
ffffffffc02003ea:	3f7010ef          	jal	ra,ffffffffc0201fe0 <strchr>
ffffffffc02003ee:	d96d                	beqz	a0,ffffffffc02003e0 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f0:	00044583          	lbu	a1,0(s0)
ffffffffc02003f4:	d9a9                	beqz	a1,ffffffffc0200346 <kmonitor+0x7c>
ffffffffc02003f6:	bf55                	j	ffffffffc02003aa <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003f8:	45c1                	li	a1,16
ffffffffc02003fa:	855a                	mv	a0,s6
ffffffffc02003fc:	d1dff0ef          	jal	ra,ffffffffc0200118 <cprintf>
ffffffffc0200400:	b7e9                	j	ffffffffc02003ca <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200402:	6582                	ld	a1,0(sp)
ffffffffc0200404:	00002517          	auipc	a0,0x2
ffffffffc0200408:	f1c50513          	addi	a0,a0,-228 # ffffffffc0202320 <etext+0x318>
ffffffffc020040c:	d0dff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    return 0;
ffffffffc0200410:	b715                	j	ffffffffc0200334 <kmonitor+0x6a>

ffffffffc0200412 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200412:	00007317          	auipc	t1,0x7
ffffffffc0200416:	02e30313          	addi	t1,t1,46 # ffffffffc0207440 <is_panic>
ffffffffc020041a:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020041e:	715d                	addi	sp,sp,-80
ffffffffc0200420:	ec06                	sd	ra,24(sp)
ffffffffc0200422:	e822                	sd	s0,16(sp)
ffffffffc0200424:	f436                	sd	a3,40(sp)
ffffffffc0200426:	f83a                	sd	a4,48(sp)
ffffffffc0200428:	fc3e                	sd	a5,56(sp)
ffffffffc020042a:	e0c2                	sd	a6,64(sp)
ffffffffc020042c:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020042e:	020e1a63          	bnez	t3,ffffffffc0200462 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200432:	4785                	li	a5,1
ffffffffc0200434:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200438:	8432                	mv	s0,a2
ffffffffc020043a:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020043c:	862e                	mv	a2,a1
ffffffffc020043e:	85aa                	mv	a1,a0
ffffffffc0200440:	00002517          	auipc	a0,0x2
ffffffffc0200444:	f4050513          	addi	a0,a0,-192 # ffffffffc0202380 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200448:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020044a:	ccfff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020044e:	65a2                	ld	a1,8(sp)
ffffffffc0200450:	8522                	mv	a0,s0
ffffffffc0200452:	ca7ff0ef          	jal	ra,ffffffffc02000f8 <vcprintf>
    cprintf("\n");
ffffffffc0200456:	00002517          	auipc	a0,0x2
ffffffffc020045a:	c1250513          	addi	a0,a0,-1006 # ffffffffc0202068 <etext+0x60>
ffffffffc020045e:	cbbff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200462:	412000ef          	jal	ra,ffffffffc0200874 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200466:	4501                	li	a0,0
ffffffffc0200468:	e63ff0ef          	jal	ra,ffffffffc02002ca <kmonitor>
    while (1) {
ffffffffc020046c:	bfed                	j	ffffffffc0200466 <__panic+0x54>

ffffffffc020046e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020046e:	1141                	addi	sp,sp,-16
ffffffffc0200470:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200472:	02000793          	li	a5,32
ffffffffc0200476:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020047a:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020047e:	67e1                	lui	a5,0x18
ffffffffc0200480:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200484:	953e                	add	a0,a0,a5
ffffffffc0200486:	291010ef          	jal	ra,ffffffffc0201f16 <sbi_set_timer>
}
ffffffffc020048a:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020048c:	00007797          	auipc	a5,0x7
ffffffffc0200490:	fa07be23          	sd	zero,-68(a5) # ffffffffc0207448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200494:	00002517          	auipc	a0,0x2
ffffffffc0200498:	f0c50513          	addi	a0,a0,-244 # ffffffffc02023a0 <commands+0x68>
}
ffffffffc020049c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020049e:	b9ad                	j	ffffffffc0200118 <cprintf>

ffffffffc02004a0 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004a0:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004a4:	67e1                	lui	a5,0x18
ffffffffc02004a6:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004aa:	953e                	add	a0,a0,a5
ffffffffc02004ac:	26b0106f          	j	ffffffffc0201f16 <sbi_set_timer>

ffffffffc02004b0 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004b0:	8082                	ret

ffffffffc02004b2 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc02004b2:	0ff57513          	zext.b	a0,a0
ffffffffc02004b6:	2470106f          	j	ffffffffc0201efc <sbi_console_putchar>

ffffffffc02004ba <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc02004ba:	2770106f          	j	ffffffffc0201f30 <sbi_console_getchar>

ffffffffc02004be <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004be:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02004c0:	00002517          	auipc	a0,0x2
ffffffffc02004c4:	f0050513          	addi	a0,a0,-256 # ffffffffc02023c0 <commands+0x88>
void dtb_init(void) {
ffffffffc02004c8:	fc86                	sd	ra,120(sp)
ffffffffc02004ca:	f8a2                	sd	s0,112(sp)
ffffffffc02004cc:	e8d2                	sd	s4,80(sp)
ffffffffc02004ce:	f4a6                	sd	s1,104(sp)
ffffffffc02004d0:	f0ca                	sd	s2,96(sp)
ffffffffc02004d2:	ecce                	sd	s3,88(sp)
ffffffffc02004d4:	e4d6                	sd	s5,72(sp)
ffffffffc02004d6:	e0da                	sd	s6,64(sp)
ffffffffc02004d8:	fc5e                	sd	s7,56(sp)
ffffffffc02004da:	f862                	sd	s8,48(sp)
ffffffffc02004dc:	f466                	sd	s9,40(sp)
ffffffffc02004de:	f06a                	sd	s10,32(sp)
ffffffffc02004e0:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004e2:	c37ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004e6:	00007597          	auipc	a1,0x7
ffffffffc02004ea:	b1a5b583          	ld	a1,-1254(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc02004ee:	00002517          	auipc	a0,0x2
ffffffffc02004f2:	ee250513          	addi	a0,a0,-286 # ffffffffc02023d0 <commands+0x98>
ffffffffc02004f6:	c23ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004fa:	00007417          	auipc	s0,0x7
ffffffffc02004fe:	b0e40413          	addi	s0,s0,-1266 # ffffffffc0207008 <boot_dtb>
ffffffffc0200502:	600c                	ld	a1,0(s0)
ffffffffc0200504:	00002517          	auipc	a0,0x2
ffffffffc0200508:	edc50513          	addi	a0,a0,-292 # ffffffffc02023e0 <commands+0xa8>
ffffffffc020050c:	c0dff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200510:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200514:	00002517          	auipc	a0,0x2
ffffffffc0200518:	ee450513          	addi	a0,a0,-284 # ffffffffc02023f8 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc020051c:	120a0463          	beqz	s4,ffffffffc0200644 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200520:	57f5                	li	a5,-3
ffffffffc0200522:	07fa                	slli	a5,a5,0x1e
ffffffffc0200524:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200528:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200530:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200534:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200538:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200540:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200544:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200546:	8ec9                	or	a3,a3,a0
ffffffffc0200548:	0087979b          	slliw	a5,a5,0x8
ffffffffc020054c:	1b7d                	addi	s6,s6,-1
ffffffffc020054e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200552:	8dd5                	or	a1,a1,a3
ffffffffc0200554:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200556:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020055a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020055c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a55>
ffffffffc0200560:	10f59163          	bne	a1,a5,ffffffffc0200662 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200564:	471c                	lw	a5,8(a4)
ffffffffc0200566:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200568:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020056a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020056e:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200572:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200576:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020057a:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020057e:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200582:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200586:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058a:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058e:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200592:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200594:	01146433          	or	s0,s0,a7
ffffffffc0200598:	0086969b          	slliw	a3,a3,0x8
ffffffffc020059c:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02005a6:	8c49                	or	s0,s0,a0
ffffffffc02005a8:	0166f6b3          	and	a3,a3,s6
ffffffffc02005ac:	00ca6a33          	or	s4,s4,a2
ffffffffc02005b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02005b4:	8c55                	or	s0,s0,a3
ffffffffc02005b6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005ba:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005bc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005be:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005c0:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005c4:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005c6:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c8:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc02005cc:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005ce:	00002917          	auipc	s2,0x2
ffffffffc02005d2:	e7a90913          	addi	s2,s2,-390 # ffffffffc0202448 <commands+0x110>
ffffffffc02005d6:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005d8:	4d91                	li	s11,4
ffffffffc02005da:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005dc:	00002497          	auipc	s1,0x2
ffffffffc02005e0:	e6448493          	addi	s1,s1,-412 # ffffffffc0202440 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005e4:	000a2703          	lw	a4,0(s4)
ffffffffc02005e8:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ec:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005f0:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f4:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f8:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005fc:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200600:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200602:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200606:	0087171b          	slliw	a4,a4,0x8
ffffffffc020060a:	8fd5                	or	a5,a5,a3
ffffffffc020060c:	00eb7733          	and	a4,s6,a4
ffffffffc0200610:	8fd9                	or	a5,a5,a4
ffffffffc0200612:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200614:	09778c63          	beq	a5,s7,ffffffffc02006ac <dtb_init+0x1ee>
ffffffffc0200618:	00fbea63          	bltu	s7,a5,ffffffffc020062c <dtb_init+0x16e>
ffffffffc020061c:	07a78663          	beq	a5,s10,ffffffffc0200688 <dtb_init+0x1ca>
ffffffffc0200620:	4709                	li	a4,2
ffffffffc0200622:	00e79763          	bne	a5,a4,ffffffffc0200630 <dtb_init+0x172>
ffffffffc0200626:	4c81                	li	s9,0
ffffffffc0200628:	8a56                	mv	s4,s5
ffffffffc020062a:	bf6d                	j	ffffffffc02005e4 <dtb_init+0x126>
ffffffffc020062c:	ffb78ee3          	beq	a5,s11,ffffffffc0200628 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200630:	00002517          	auipc	a0,0x2
ffffffffc0200634:	e9050513          	addi	a0,a0,-368 # ffffffffc02024c0 <commands+0x188>
ffffffffc0200638:	ae1ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	ebc50513          	addi	a0,a0,-324 # ffffffffc02024f8 <commands+0x1c0>
}
ffffffffc0200644:	7446                	ld	s0,112(sp)
ffffffffc0200646:	70e6                	ld	ra,120(sp)
ffffffffc0200648:	74a6                	ld	s1,104(sp)
ffffffffc020064a:	7906                	ld	s2,96(sp)
ffffffffc020064c:	69e6                	ld	s3,88(sp)
ffffffffc020064e:	6a46                	ld	s4,80(sp)
ffffffffc0200650:	6aa6                	ld	s5,72(sp)
ffffffffc0200652:	6b06                	ld	s6,64(sp)
ffffffffc0200654:	7be2                	ld	s7,56(sp)
ffffffffc0200656:	7c42                	ld	s8,48(sp)
ffffffffc0200658:	7ca2                	ld	s9,40(sp)
ffffffffc020065a:	7d02                	ld	s10,32(sp)
ffffffffc020065c:	6de2                	ld	s11,24(sp)
ffffffffc020065e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200660:	bc65                	j	ffffffffc0200118 <cprintf>
}
ffffffffc0200662:	7446                	ld	s0,112(sp)
ffffffffc0200664:	70e6                	ld	ra,120(sp)
ffffffffc0200666:	74a6                	ld	s1,104(sp)
ffffffffc0200668:	7906                	ld	s2,96(sp)
ffffffffc020066a:	69e6                	ld	s3,88(sp)
ffffffffc020066c:	6a46                	ld	s4,80(sp)
ffffffffc020066e:	6aa6                	ld	s5,72(sp)
ffffffffc0200670:	6b06                	ld	s6,64(sp)
ffffffffc0200672:	7be2                	ld	s7,56(sp)
ffffffffc0200674:	7c42                	ld	s8,48(sp)
ffffffffc0200676:	7ca2                	ld	s9,40(sp)
ffffffffc0200678:	7d02                	ld	s10,32(sp)
ffffffffc020067a:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020067c:	00002517          	auipc	a0,0x2
ffffffffc0200680:	d9c50513          	addi	a0,a0,-612 # ffffffffc0202418 <commands+0xe0>
}
ffffffffc0200684:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200686:	bc49                	j	ffffffffc0200118 <cprintf>
                int name_len = strlen(name);
ffffffffc0200688:	8556                	mv	a0,s5
ffffffffc020068a:	0dd010ef          	jal	ra,ffffffffc0201f66 <strlen>
ffffffffc020068e:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200690:	4619                	li	a2,6
ffffffffc0200692:	85a6                	mv	a1,s1
ffffffffc0200694:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200696:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200698:	123010ef          	jal	ra,ffffffffc0201fba <strncmp>
ffffffffc020069c:	e111                	bnez	a0,ffffffffc02006a0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020069e:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006a0:	0a91                	addi	s5,s5,4
ffffffffc02006a2:	9ad2                	add	s5,s5,s4
ffffffffc02006a4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006a8:	8a56                	mv	s4,s5
ffffffffc02006aa:	bf2d                	j	ffffffffc02005e4 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006ac:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006b0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02006b8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006bc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c0:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c4:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006c8:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006cc:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d0:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006d4:	00eaeab3          	or	s5,s5,a4
ffffffffc02006d8:	00fb77b3          	and	a5,s6,a5
ffffffffc02006dc:	00faeab3          	or	s5,s5,a5
ffffffffc02006e0:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006e2:	000c9c63          	bnez	s9,ffffffffc02006fa <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006e6:	1a82                	slli	s5,s5,0x20
ffffffffc02006e8:	00368793          	addi	a5,a3,3
ffffffffc02006ec:	020ada93          	srli	s5,s5,0x20
ffffffffc02006f0:	9abe                	add	s5,s5,a5
ffffffffc02006f2:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006f6:	8a56                	mv	s4,s5
ffffffffc02006f8:	b5f5                	j	ffffffffc02005e4 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006fa:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006fe:	85ca                	mv	a1,s2
ffffffffc0200700:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200706:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020070e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200712:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200716:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200718:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200720:	8d59                	or	a0,a0,a4
ffffffffc0200722:	00fb77b3          	and	a5,s6,a5
ffffffffc0200726:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200728:	1502                	slli	a0,a0,0x20
ffffffffc020072a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020072c:	9522                	add	a0,a0,s0
ffffffffc020072e:	06f010ef          	jal	ra,ffffffffc0201f9c <strcmp>
ffffffffc0200732:	66a2                	ld	a3,8(sp)
ffffffffc0200734:	f94d                	bnez	a0,ffffffffc02006e6 <dtb_init+0x228>
ffffffffc0200736:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006e6 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020073a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020073e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200742:	00002517          	auipc	a0,0x2
ffffffffc0200746:	d0e50513          	addi	a0,a0,-754 # ffffffffc0202450 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc020074a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200752:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200756:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020075a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020075e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200762:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200766:	0187d693          	srli	a3,a5,0x18
ffffffffc020076a:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020076e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200772:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200776:	0106561b          	srliw	a2,a2,0x10
ffffffffc020077a:	010f6f33          	or	t5,t5,a6
ffffffffc020077e:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200782:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200786:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078a:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020078e:	0186f6b3          	and	a3,a3,s8
ffffffffc0200792:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200796:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020079a:	0107581b          	srliw	a6,a4,0x10
ffffffffc020079e:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a2:	8361                	srli	a4,a4,0x18
ffffffffc02007a4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02007ac:	01e6e6b3          	or	a3,a3,t5
ffffffffc02007b0:	00cb7633          	and	a2,s6,a2
ffffffffc02007b4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02007b8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02007bc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c0:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c4:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c8:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007cc:	0088989b          	slliw	a7,a7,0x8
ffffffffc02007d0:	011b78b3          	and	a7,s6,a7
ffffffffc02007d4:	005eeeb3          	or	t4,t4,t0
ffffffffc02007d8:	00c6e733          	or	a4,a3,a2
ffffffffc02007dc:	006c6c33          	or	s8,s8,t1
ffffffffc02007e0:	010b76b3          	and	a3,s6,a6
ffffffffc02007e4:	00bb7b33          	and	s6,s6,a1
ffffffffc02007e8:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007ec:	016c6b33          	or	s6,s8,s6
ffffffffc02007f0:	01146433          	or	s0,s0,a7
ffffffffc02007f4:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007f6:	1702                	slli	a4,a4,0x20
ffffffffc02007f8:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007fa:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007fc:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007fe:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200800:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200804:	0167eb33          	or	s6,a5,s6
ffffffffc0200808:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020080a:	90fff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020080e:	85a2                	mv	a1,s0
ffffffffc0200810:	00002517          	auipc	a0,0x2
ffffffffc0200814:	c6050513          	addi	a0,a0,-928 # ffffffffc0202470 <commands+0x138>
ffffffffc0200818:	901ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020081c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200820:	85da                	mv	a1,s6
ffffffffc0200822:	00002517          	auipc	a0,0x2
ffffffffc0200826:	c6650513          	addi	a0,a0,-922 # ffffffffc0202488 <commands+0x150>
ffffffffc020082a:	8efff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020082e:	008b05b3          	add	a1,s6,s0
ffffffffc0200832:	15fd                	addi	a1,a1,-1
ffffffffc0200834:	00002517          	auipc	a0,0x2
ffffffffc0200838:	c7450513          	addi	a0,a0,-908 # ffffffffc02024a8 <commands+0x170>
ffffffffc020083c:	8ddff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200840:	00002517          	auipc	a0,0x2
ffffffffc0200844:	cb850513          	addi	a0,a0,-840 # ffffffffc02024f8 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200848:	00007797          	auipc	a5,0x7
ffffffffc020084c:	c087b423          	sd	s0,-1016(a5) # ffffffffc0207450 <memory_base>
        memory_size = mem_size;
ffffffffc0200850:	00007797          	auipc	a5,0x7
ffffffffc0200854:	c167b423          	sd	s6,-1016(a5) # ffffffffc0207458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200858:	b3f5                	j	ffffffffc0200644 <dtb_init+0x186>

ffffffffc020085a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020085a:	00007517          	auipc	a0,0x7
ffffffffc020085e:	bf653503          	ld	a0,-1034(a0) # ffffffffc0207450 <memory_base>
ffffffffc0200862:	8082                	ret

ffffffffc0200864 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc0200864:	00007517          	auipc	a0,0x7
ffffffffc0200868:	bf453503          	ld	a0,-1036(a0) # ffffffffc0207458 <memory_size>
ffffffffc020086c:	8082                	ret

ffffffffc020086e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020086e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200872:	8082                	ret

ffffffffc0200874 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200874:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200878:	8082                	ret

ffffffffc020087a <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020087a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020087e:	00000797          	auipc	a5,0x0
ffffffffc0200882:	3b678793          	addi	a5,a5,950 # ffffffffc0200c34 <__alltraps>
ffffffffc0200886:	10579073          	csrw	stvec,a5
}
ffffffffc020088a:	8082                	ret

ffffffffc020088c <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020088c:	610c                	ld	a1,0(a0)
{
ffffffffc020088e:	1141                	addi	sp,sp,-16
ffffffffc0200890:	e022                	sd	s0,0(sp)
ffffffffc0200892:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200894:	00002517          	auipc	a0,0x2
ffffffffc0200898:	c7c50513          	addi	a0,a0,-900 # ffffffffc0202510 <commands+0x1d8>
{
ffffffffc020089c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020089e:	87bff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02008a2:	640c                	ld	a1,8(s0)
ffffffffc02008a4:	00002517          	auipc	a0,0x2
ffffffffc02008a8:	c8450513          	addi	a0,a0,-892 # ffffffffc0202528 <commands+0x1f0>
ffffffffc02008ac:	86dff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02008b0:	680c                	ld	a1,16(s0)
ffffffffc02008b2:	00002517          	auipc	a0,0x2
ffffffffc02008b6:	c8e50513          	addi	a0,a0,-882 # ffffffffc0202540 <commands+0x208>
ffffffffc02008ba:	85fff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02008be:	6c0c                	ld	a1,24(s0)
ffffffffc02008c0:	00002517          	auipc	a0,0x2
ffffffffc02008c4:	c9850513          	addi	a0,a0,-872 # ffffffffc0202558 <commands+0x220>
ffffffffc02008c8:	851ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02008cc:	700c                	ld	a1,32(s0)
ffffffffc02008ce:	00002517          	auipc	a0,0x2
ffffffffc02008d2:	ca250513          	addi	a0,a0,-862 # ffffffffc0202570 <commands+0x238>
ffffffffc02008d6:	843ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008da:	740c                	ld	a1,40(s0)
ffffffffc02008dc:	00002517          	auipc	a0,0x2
ffffffffc02008e0:	cac50513          	addi	a0,a0,-852 # ffffffffc0202588 <commands+0x250>
ffffffffc02008e4:	835ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008e8:	780c                	ld	a1,48(s0)
ffffffffc02008ea:	00002517          	auipc	a0,0x2
ffffffffc02008ee:	cb650513          	addi	a0,a0,-842 # ffffffffc02025a0 <commands+0x268>
ffffffffc02008f2:	827ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008f6:	7c0c                	ld	a1,56(s0)
ffffffffc02008f8:	00002517          	auipc	a0,0x2
ffffffffc02008fc:	cc050513          	addi	a0,a0,-832 # ffffffffc02025b8 <commands+0x280>
ffffffffc0200900:	819ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200904:	602c                	ld	a1,64(s0)
ffffffffc0200906:	00002517          	auipc	a0,0x2
ffffffffc020090a:	cca50513          	addi	a0,a0,-822 # ffffffffc02025d0 <commands+0x298>
ffffffffc020090e:	80bff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200912:	642c                	ld	a1,72(s0)
ffffffffc0200914:	00002517          	auipc	a0,0x2
ffffffffc0200918:	cd450513          	addi	a0,a0,-812 # ffffffffc02025e8 <commands+0x2b0>
ffffffffc020091c:	ffcff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200920:	682c                	ld	a1,80(s0)
ffffffffc0200922:	00002517          	auipc	a0,0x2
ffffffffc0200926:	cde50513          	addi	a0,a0,-802 # ffffffffc0202600 <commands+0x2c8>
ffffffffc020092a:	feeff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020092e:	6c2c                	ld	a1,88(s0)
ffffffffc0200930:	00002517          	auipc	a0,0x2
ffffffffc0200934:	ce850513          	addi	a0,a0,-792 # ffffffffc0202618 <commands+0x2e0>
ffffffffc0200938:	fe0ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020093c:	702c                	ld	a1,96(s0)
ffffffffc020093e:	00002517          	auipc	a0,0x2
ffffffffc0200942:	cf250513          	addi	a0,a0,-782 # ffffffffc0202630 <commands+0x2f8>
ffffffffc0200946:	fd2ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020094a:	742c                	ld	a1,104(s0)
ffffffffc020094c:	00002517          	auipc	a0,0x2
ffffffffc0200950:	cfc50513          	addi	a0,a0,-772 # ffffffffc0202648 <commands+0x310>
ffffffffc0200954:	fc4ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200958:	782c                	ld	a1,112(s0)
ffffffffc020095a:	00002517          	auipc	a0,0x2
ffffffffc020095e:	d0650513          	addi	a0,a0,-762 # ffffffffc0202660 <commands+0x328>
ffffffffc0200962:	fb6ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200966:	7c2c                	ld	a1,120(s0)
ffffffffc0200968:	00002517          	auipc	a0,0x2
ffffffffc020096c:	d1050513          	addi	a0,a0,-752 # ffffffffc0202678 <commands+0x340>
ffffffffc0200970:	fa8ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200974:	604c                	ld	a1,128(s0)
ffffffffc0200976:	00002517          	auipc	a0,0x2
ffffffffc020097a:	d1a50513          	addi	a0,a0,-742 # ffffffffc0202690 <commands+0x358>
ffffffffc020097e:	f9aff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200982:	644c                	ld	a1,136(s0)
ffffffffc0200984:	00002517          	auipc	a0,0x2
ffffffffc0200988:	d2450513          	addi	a0,a0,-732 # ffffffffc02026a8 <commands+0x370>
ffffffffc020098c:	f8cff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200990:	684c                	ld	a1,144(s0)
ffffffffc0200992:	00002517          	auipc	a0,0x2
ffffffffc0200996:	d2e50513          	addi	a0,a0,-722 # ffffffffc02026c0 <commands+0x388>
ffffffffc020099a:	f7eff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020099e:	6c4c                	ld	a1,152(s0)
ffffffffc02009a0:	00002517          	auipc	a0,0x2
ffffffffc02009a4:	d3850513          	addi	a0,a0,-712 # ffffffffc02026d8 <commands+0x3a0>
ffffffffc02009a8:	f70ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02009ac:	704c                	ld	a1,160(s0)
ffffffffc02009ae:	00002517          	auipc	a0,0x2
ffffffffc02009b2:	d4250513          	addi	a0,a0,-702 # ffffffffc02026f0 <commands+0x3b8>
ffffffffc02009b6:	f62ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02009ba:	744c                	ld	a1,168(s0)
ffffffffc02009bc:	00002517          	auipc	a0,0x2
ffffffffc02009c0:	d4c50513          	addi	a0,a0,-692 # ffffffffc0202708 <commands+0x3d0>
ffffffffc02009c4:	f54ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02009c8:	784c                	ld	a1,176(s0)
ffffffffc02009ca:	00002517          	auipc	a0,0x2
ffffffffc02009ce:	d5650513          	addi	a0,a0,-682 # ffffffffc0202720 <commands+0x3e8>
ffffffffc02009d2:	f46ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009d6:	7c4c                	ld	a1,184(s0)
ffffffffc02009d8:	00002517          	auipc	a0,0x2
ffffffffc02009dc:	d6050513          	addi	a0,a0,-672 # ffffffffc0202738 <commands+0x400>
ffffffffc02009e0:	f38ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009e4:	606c                	ld	a1,192(s0)
ffffffffc02009e6:	00002517          	auipc	a0,0x2
ffffffffc02009ea:	d6a50513          	addi	a0,a0,-662 # ffffffffc0202750 <commands+0x418>
ffffffffc02009ee:	f2aff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009f2:	646c                	ld	a1,200(s0)
ffffffffc02009f4:	00002517          	auipc	a0,0x2
ffffffffc02009f8:	d7450513          	addi	a0,a0,-652 # ffffffffc0202768 <commands+0x430>
ffffffffc02009fc:	f1cff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a00:	686c                	ld	a1,208(s0)
ffffffffc0200a02:	00002517          	auipc	a0,0x2
ffffffffc0200a06:	d7e50513          	addi	a0,a0,-642 # ffffffffc0202780 <commands+0x448>
ffffffffc0200a0a:	f0eff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200a0e:	6c6c                	ld	a1,216(s0)
ffffffffc0200a10:	00002517          	auipc	a0,0x2
ffffffffc0200a14:	d8850513          	addi	a0,a0,-632 # ffffffffc0202798 <commands+0x460>
ffffffffc0200a18:	f00ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200a1c:	706c                	ld	a1,224(s0)
ffffffffc0200a1e:	00002517          	auipc	a0,0x2
ffffffffc0200a22:	d9250513          	addi	a0,a0,-622 # ffffffffc02027b0 <commands+0x478>
ffffffffc0200a26:	ef2ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200a2a:	746c                	ld	a1,232(s0)
ffffffffc0200a2c:	00002517          	auipc	a0,0x2
ffffffffc0200a30:	d9c50513          	addi	a0,a0,-612 # ffffffffc02027c8 <commands+0x490>
ffffffffc0200a34:	ee4ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a38:	786c                	ld	a1,240(s0)
ffffffffc0200a3a:	00002517          	auipc	a0,0x2
ffffffffc0200a3e:	da650513          	addi	a0,a0,-602 # ffffffffc02027e0 <commands+0x4a8>
ffffffffc0200a42:	ed6ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a46:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a48:	6402                	ld	s0,0(sp)
ffffffffc0200a4a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a4c:	00002517          	auipc	a0,0x2
ffffffffc0200a50:	dac50513          	addi	a0,a0,-596 # ffffffffc02027f8 <commands+0x4c0>
}
ffffffffc0200a54:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a56:	ec2ff06f          	j	ffffffffc0200118 <cprintf>

ffffffffc0200a5a <print_trapframe>:
{
ffffffffc0200a5a:	1141                	addi	sp,sp,-16
ffffffffc0200a5c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a5e:	85aa                	mv	a1,a0
{
ffffffffc0200a60:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a62:	00002517          	auipc	a0,0x2
ffffffffc0200a66:	dae50513          	addi	a0,a0,-594 # ffffffffc0202810 <commands+0x4d8>
{
ffffffffc0200a6a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a6c:	eacff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a70:	8522                	mv	a0,s0
ffffffffc0200a72:	e1bff0ef          	jal	ra,ffffffffc020088c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a76:	10043583          	ld	a1,256(s0)
ffffffffc0200a7a:	00002517          	auipc	a0,0x2
ffffffffc0200a7e:	dae50513          	addi	a0,a0,-594 # ffffffffc0202828 <commands+0x4f0>
ffffffffc0200a82:	e96ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a86:	10843583          	ld	a1,264(s0)
ffffffffc0200a8a:	00002517          	auipc	a0,0x2
ffffffffc0200a8e:	db650513          	addi	a0,a0,-586 # ffffffffc0202840 <commands+0x508>
ffffffffc0200a92:	e86ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a96:	11043583          	ld	a1,272(s0)
ffffffffc0200a9a:	00002517          	auipc	a0,0x2
ffffffffc0200a9e:	dbe50513          	addi	a0,a0,-578 # ffffffffc0202858 <commands+0x520>
ffffffffc0200aa2:	e76ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200aa6:	11843583          	ld	a1,280(s0)
}
ffffffffc0200aaa:	6402                	ld	s0,0(sp)
ffffffffc0200aac:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200aae:	00002517          	auipc	a0,0x2
ffffffffc0200ab2:	dc250513          	addi	a0,a0,-574 # ffffffffc0202870 <commands+0x538>
}
ffffffffc0200ab6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab8:	e60ff06f          	j	ffffffffc0200118 <cprintf>

ffffffffc0200abc <interrupt_handler>:

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200abc:	11853783          	ld	a5,280(a0)
ffffffffc0200ac0:	472d                	li	a4,11
ffffffffc0200ac2:	0786                	slli	a5,a5,0x1
ffffffffc0200ac4:	8385                	srli	a5,a5,0x1
ffffffffc0200ac6:	08f76563          	bltu	a4,a5,ffffffffc0200b50 <interrupt_handler+0x94>
ffffffffc0200aca:	00002717          	auipc	a4,0x2
ffffffffc0200ace:	e8670713          	addi	a4,a4,-378 # ffffffffc0202950 <commands+0x618>
ffffffffc0200ad2:	078a                	slli	a5,a5,0x2
ffffffffc0200ad4:	97ba                	add	a5,a5,a4
ffffffffc0200ad6:	439c                	lw	a5,0(a5)
ffffffffc0200ad8:	97ba                	add	a5,a5,a4
ffffffffc0200ada:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200adc:	00002517          	auipc	a0,0x2
ffffffffc0200ae0:	e0c50513          	addi	a0,a0,-500 # ffffffffc02028e8 <commands+0x5b0>
ffffffffc0200ae4:	e34ff06f          	j	ffffffffc0200118 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200ae8:	00002517          	auipc	a0,0x2
ffffffffc0200aec:	de050513          	addi	a0,a0,-544 # ffffffffc02028c8 <commands+0x590>
ffffffffc0200af0:	e28ff06f          	j	ffffffffc0200118 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200af4:	00002517          	auipc	a0,0x2
ffffffffc0200af8:	d9450513          	addi	a0,a0,-620 # ffffffffc0202888 <commands+0x550>
ffffffffc0200afc:	e1cff06f          	j	ffffffffc0200118 <cprintf>
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
ffffffffc0200b00:	00002517          	auipc	a0,0x2
ffffffffc0200b04:	e0850513          	addi	a0,a0,-504 # ffffffffc0202908 <commands+0x5d0>
ffffffffc0200b08:	e10ff06f          	j	ffffffffc0200118 <cprintf>
{
ffffffffc0200b0c:	1141                	addi	sp,sp,-16
ffffffffc0200b0e:	e022                	sd	s0,0(sp)
ffffffffc0200b10:	e406                	sd	ra,8(sp)
         * (4)判断打印次数,当打印次数为10时，调用<sbi.h>中的关机函数关机
         */
        // (1) 设置下次时钟中断
        clock_set_next_event();
        // (2) 计数器加一
        ticks++;
ffffffffc0200b12:	00007417          	auipc	s0,0x7
ffffffffc0200b16:	93640413          	addi	s0,s0,-1738 # ffffffffc0207448 <ticks>
        clock_set_next_event();
ffffffffc0200b1a:	987ff0ef          	jal	ra,ffffffffc02004a0 <clock_set_next_event>
        ticks++;
ffffffffc0200b1e:	601c                	ld	a5,0(s0)
        // (3) 每100次时钟中断打印一次
        if (ticks % TICK_NUM == 0)
ffffffffc0200b20:	06400713          	li	a4,100
        ticks++;
ffffffffc0200b24:	0785                	addi	a5,a5,1
ffffffffc0200b26:	e01c                	sd	a5,0(s0)
        if (ticks % TICK_NUM == 0)
ffffffffc0200b28:	601c                	ld	a5,0(s0)
ffffffffc0200b2a:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200b2e:	c395                	beqz	a5,ffffffffc0200b52 <interrupt_handler+0x96>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200b30:	60a2                	ld	ra,8(sp)
ffffffffc0200b32:	6402                	ld	s0,0(sp)
ffffffffc0200b34:	0141                	addi	sp,sp,16
ffffffffc0200b36:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200b38:	00002517          	auipc	a0,0x2
ffffffffc0200b3c:	df850513          	addi	a0,a0,-520 # ffffffffc0202930 <commands+0x5f8>
ffffffffc0200b40:	dd8ff06f          	j	ffffffffc0200118 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b44:	00002517          	auipc	a0,0x2
ffffffffc0200b48:	d6450513          	addi	a0,a0,-668 # ffffffffc02028a8 <commands+0x570>
ffffffffc0200b4c:	dccff06f          	j	ffffffffc0200118 <cprintf>
        print_trapframe(tf);
ffffffffc0200b50:	b729                	j	ffffffffc0200a5a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b52:	06400593          	li	a1,100
ffffffffc0200b56:	00002517          	auipc	a0,0x2
ffffffffc0200b5a:	dca50513          	addi	a0,a0,-566 # ffffffffc0202920 <commands+0x5e8>
ffffffffc0200b5e:	dbaff0ef          	jal	ra,ffffffffc0200118 <cprintf>
            if (ticks / TICK_NUM == 10)
ffffffffc0200b62:	601c                	ld	a5,0(s0)
ffffffffc0200b64:	06300713          	li	a4,99
ffffffffc0200b68:	c1878793          	addi	a5,a5,-1000
ffffffffc0200b6c:	fcf762e3          	bltu	a4,a5,ffffffffc0200b30 <interrupt_handler+0x74>
}
ffffffffc0200b70:	6402                	ld	s0,0(sp)
ffffffffc0200b72:	60a2                	ld	ra,8(sp)
ffffffffc0200b74:	0141                	addi	sp,sp,16
                sbi_shutdown();
ffffffffc0200b76:	3d60106f          	j	ffffffffc0201f4c <sbi_shutdown>

ffffffffc0200b7a <exception_handler>:

void exception_handler(struct trapframe *tf)
{
ffffffffc0200b7a:	1101                	addi	sp,sp,-32
ffffffffc0200b7c:	e822                	sd	s0,16(sp)
    switch (tf->cause)
ffffffffc0200b7e:	11853403          	ld	s0,280(a0)
{
ffffffffc0200b82:	e426                	sd	s1,8(sp)
ffffffffc0200b84:	e04a                	sd	s2,0(sp)
ffffffffc0200b86:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200b88:	490d                	li	s2,3
{
ffffffffc0200b8a:	84aa                	mv	s1,a0
    switch (tf->cause)
ffffffffc0200b8c:	05240f63          	beq	s0,s2,ffffffffc0200bea <exception_handler+0x70>
ffffffffc0200b90:	04896363          	bltu	s2,s0,ffffffffc0200bd6 <exception_handler+0x5c>
ffffffffc0200b94:	4789                	li	a5,2
ffffffffc0200b96:	02f41a63          	bne	s0,a5,ffffffffc0200bca <exception_handler+0x50>
        /*(1)输出指令异常类型（ Illegal instruction）
         *(2)输出异常指令地址
         *(3)更新 tf->epc寄存器
         */
        // (1) 输出异常类型
        cprintf("Exception type: Illegal instruction\n");
ffffffffc0200b9a:	00002517          	auipc	a0,0x2
ffffffffc0200b9e:	de650513          	addi	a0,a0,-538 # ffffffffc0202980 <commands+0x648>
ffffffffc0200ba2:	d76ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        // (2) 输出异常指令地址
        cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200ba6:	1084b583          	ld	a1,264(s1)
ffffffffc0200baa:	00002517          	auipc	a0,0x2
ffffffffc0200bae:	dfe50513          	addi	a0,a0,-514 # ffffffffc02029a8 <commands+0x670>
ffffffffc0200bb2:	d66ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        // (3) 更新epc寄存器
        // 检查指令长度：RISC-V压缩指令(C扩展)长度为2字节，标准指令长度为4字节
        // 指令的最低2位如果不是11，则是压缩指令(16位)，否则是标准指令(32位)
        unsigned int instruction = *(unsigned short *)tf->epc;
ffffffffc0200bb6:	1084b783          	ld	a5,264(s1)
        if ((instruction & 0x3) != 0x3)
ffffffffc0200bba:	0007d703          	lhu	a4,0(a5)
ffffffffc0200bbe:	8b0d                	andi	a4,a4,3
ffffffffc0200bc0:	05270a63          	beq	a4,s2,ffffffffc0200c14 <exception_handler+0x9a>
        // 检查指令长度：RISC-V压缩指令(C扩展)长度为2字节，标准指令长度为4字节
        // ebreak可能是压缩指令c.ebreak(2字节)或标准ebreak(4字节)
        unsigned int inst = *(unsigned short *)tf->epc;
        if ((inst & 0x3) != 0x3)
        {
            tf->epc += 2; // 压缩指令，长度2字节
ffffffffc0200bc4:	0789                	addi	a5,a5,2
ffffffffc0200bc6:	10f4b423          	sd	a5,264(s1)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bca:	60e2                	ld	ra,24(sp)
ffffffffc0200bcc:	6442                	ld	s0,16(sp)
ffffffffc0200bce:	64a2                	ld	s1,8(sp)
ffffffffc0200bd0:	6902                	ld	s2,0(sp)
ffffffffc0200bd2:	6105                	addi	sp,sp,32
ffffffffc0200bd4:	8082                	ret
    switch (tf->cause)
ffffffffc0200bd6:	1471                	addi	s0,s0,-4
ffffffffc0200bd8:	479d                	li	a5,7
ffffffffc0200bda:	fe87f8e3          	bgeu	a5,s0,ffffffffc0200bca <exception_handler+0x50>
}
ffffffffc0200bde:	6442                	ld	s0,16(sp)
ffffffffc0200be0:	60e2                	ld	ra,24(sp)
ffffffffc0200be2:	64a2                	ld	s1,8(sp)
ffffffffc0200be4:	6902                	ld	s2,0(sp)
ffffffffc0200be6:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200be8:	bd8d                	j	ffffffffc0200a5a <print_trapframe>
        cprintf("Exception type: breakpoint\n");
ffffffffc0200bea:	00002517          	auipc	a0,0x2
ffffffffc0200bee:	de650513          	addi	a0,a0,-538 # ffffffffc02029d0 <commands+0x698>
ffffffffc0200bf2:	d26ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200bf6:	1084b583          	ld	a1,264(s1)
ffffffffc0200bfa:	00002517          	auipc	a0,0x2
ffffffffc0200bfe:	df650513          	addi	a0,a0,-522 # ffffffffc02029f0 <commands+0x6b8>
ffffffffc0200c02:	d16ff0ef          	jal	ra,ffffffffc0200118 <cprintf>
        unsigned int inst = *(unsigned short *)tf->epc;
ffffffffc0200c06:	1084b783          	ld	a5,264(s1)
        if ((inst & 0x3) != 0x3)
ffffffffc0200c0a:	0007d703          	lhu	a4,0(a5)
ffffffffc0200c0e:	8b0d                	andi	a4,a4,3
ffffffffc0200c10:	fa871ae3          	bne	a4,s0,ffffffffc0200bc4 <exception_handler+0x4a>
}
ffffffffc0200c14:	60e2                	ld	ra,24(sp)
ffffffffc0200c16:	6442                	ld	s0,16(sp)
            tf->epc += 4; // 标准指令，长度4字节
ffffffffc0200c18:	0791                	addi	a5,a5,4
ffffffffc0200c1a:	10f4b423          	sd	a5,264(s1)
}
ffffffffc0200c1e:	6902                	ld	s2,0(sp)
ffffffffc0200c20:	64a2                	ld	s1,8(sp)
ffffffffc0200c22:	6105                	addi	sp,sp,32
ffffffffc0200c24:	8082                	ret

ffffffffc0200c26 <trap>:

static inline void trap_dispatch(struct trapframe *tf)
{
    if ((intptr_t)tf->cause < 0)
ffffffffc0200c26:	11853783          	ld	a5,280(a0)
ffffffffc0200c2a:	0007c363          	bltz	a5,ffffffffc0200c30 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200c2e:	b7b1                	j	ffffffffc0200b7a <exception_handler>
        interrupt_handler(tf);
ffffffffc0200c30:	b571                	j	ffffffffc0200abc <interrupt_handler>
	...

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
ffffffffc0200c98:	f8fff0ef          	jal	ra,ffffffffc0200c26 <trap>

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

ffffffffc0200cea <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200cea:	00006797          	auipc	a5,0x6
ffffffffc0200cee:	33e78793          	addi	a5,a5,830 # ffffffffc0207028 <free_area>
ffffffffc0200cf2:	e79c                	sd	a5,8(a5)
ffffffffc0200cf4:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200cf6:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200cfa:	8082                	ret

ffffffffc0200cfc <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200cfc:	00006517          	auipc	a0,0x6
ffffffffc0200d00:	33c56503          	lwu	a0,828(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200d04:	8082                	ret

ffffffffc0200d06 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200d06:	715d                	addi	sp,sp,-80
ffffffffc0200d08:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200d0a:	00006417          	auipc	s0,0x6
ffffffffc0200d0e:	31e40413          	addi	s0,s0,798 # ffffffffc0207028 <free_area>
ffffffffc0200d12:	641c                	ld	a5,8(s0)
ffffffffc0200d14:	e486                	sd	ra,72(sp)
ffffffffc0200d16:	fc26                	sd	s1,56(sp)
ffffffffc0200d18:	f84a                	sd	s2,48(sp)
ffffffffc0200d1a:	f44e                	sd	s3,40(sp)
ffffffffc0200d1c:	f052                	sd	s4,32(sp)
ffffffffc0200d1e:	ec56                	sd	s5,24(sp)
ffffffffc0200d20:	e85a                	sd	s6,16(sp)
ffffffffc0200d22:	e45e                	sd	s7,8(sp)
ffffffffc0200d24:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d26:	2c878763          	beq	a5,s0,ffffffffc0200ff4 <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200d2a:	4481                	li	s1,0
ffffffffc0200d2c:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d2e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d32:	8b09                	andi	a4,a4,2
ffffffffc0200d34:	2c070463          	beqz	a4,ffffffffc0200ffc <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200d38:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d3c:	679c                	ld	a5,8(a5)
ffffffffc0200d3e:	2905                	addiw	s2,s2,1
ffffffffc0200d40:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d42:	fe8796e3          	bne	a5,s0,ffffffffc0200d2e <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200d46:	89a6                	mv	s3,s1
ffffffffc0200d48:	2f9000ef          	jal	ra,ffffffffc0201840 <nr_free_pages>
ffffffffc0200d4c:	71351863          	bne	a0,s3,ffffffffc020145c <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d50:	4505                	li	a0,1
ffffffffc0200d52:	271000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200d56:	8a2a                	mv	s4,a0
ffffffffc0200d58:	44050263          	beqz	a0,ffffffffc020119c <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d5c:	4505                	li	a0,1
ffffffffc0200d5e:	265000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200d62:	89aa                	mv	s3,a0
ffffffffc0200d64:	70050c63          	beqz	a0,ffffffffc020147c <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d68:	4505                	li	a0,1
ffffffffc0200d6a:	259000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200d6e:	8aaa                	mv	s5,a0
ffffffffc0200d70:	4a050663          	beqz	a0,ffffffffc020121c <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200d74:	2b3a0463          	beq	s4,s3,ffffffffc020101c <default_check+0x316>
ffffffffc0200d78:	2aaa0263          	beq	s4,a0,ffffffffc020101c <default_check+0x316>
ffffffffc0200d7c:	2aa98063          	beq	s3,a0,ffffffffc020101c <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200d80:	000a2783          	lw	a5,0(s4)
ffffffffc0200d84:	2a079c63          	bnez	a5,ffffffffc020103c <default_check+0x336>
ffffffffc0200d88:	0009a783          	lw	a5,0(s3)
ffffffffc0200d8c:	2a079863          	bnez	a5,ffffffffc020103c <default_check+0x336>
ffffffffc0200d90:	411c                	lw	a5,0(a0)
ffffffffc0200d92:	2a079563          	bnez	a5,ffffffffc020103c <default_check+0x336>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d96:	00006797          	auipc	a5,0x6
ffffffffc0200d9a:	6d27b783          	ld	a5,1746(a5) # ffffffffc0207468 <pages>
ffffffffc0200d9e:	40fa0733          	sub	a4,s4,a5
ffffffffc0200da2:	870d                	srai	a4,a4,0x3
ffffffffc0200da4:	00002597          	auipc	a1,0x2
ffffffffc0200da8:	3f45b583          	ld	a1,1012(a1) # ffffffffc0203198 <error_string+0x38>
ffffffffc0200dac:	02b70733          	mul	a4,a4,a1
ffffffffc0200db0:	00002617          	auipc	a2,0x2
ffffffffc0200db4:	3f063603          	ld	a2,1008(a2) # ffffffffc02031a0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200db8:	00006697          	auipc	a3,0x6
ffffffffc0200dbc:	6a86b683          	ld	a3,1704(a3) # ffffffffc0207460 <npage>
ffffffffc0200dc0:	06b2                	slli	a3,a3,0xc
ffffffffc0200dc2:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dc4:	0732                	slli	a4,a4,0xc
ffffffffc0200dc6:	28d77b63          	bgeu	a4,a3,ffffffffc020105c <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dca:	40f98733          	sub	a4,s3,a5
ffffffffc0200dce:	870d                	srai	a4,a4,0x3
ffffffffc0200dd0:	02b70733          	mul	a4,a4,a1
ffffffffc0200dd4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dd6:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200dd8:	4cd77263          	bgeu	a4,a3,ffffffffc020129c <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ddc:	40f507b3          	sub	a5,a0,a5
ffffffffc0200de0:	878d                	srai	a5,a5,0x3
ffffffffc0200de2:	02b787b3          	mul	a5,a5,a1
ffffffffc0200de6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200de8:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200dea:	30d7f963          	bgeu	a5,a3,ffffffffc02010fc <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0200dee:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200df0:	00043c03          	ld	s8,0(s0)
ffffffffc0200df4:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200df8:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200dfc:	e400                	sd	s0,8(s0)
ffffffffc0200dfe:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200e00:	00006797          	auipc	a5,0x6
ffffffffc0200e04:	2207ac23          	sw	zero,568(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e08:	1bb000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200e0c:	2c051863          	bnez	a0,ffffffffc02010dc <default_check+0x3d6>
    free_page(p0);
ffffffffc0200e10:	4585                	li	a1,1
ffffffffc0200e12:	8552                	mv	a0,s4
ffffffffc0200e14:	1ed000ef          	jal	ra,ffffffffc0201800 <free_pages>
    free_page(p1);
ffffffffc0200e18:	4585                	li	a1,1
ffffffffc0200e1a:	854e                	mv	a0,s3
ffffffffc0200e1c:	1e5000ef          	jal	ra,ffffffffc0201800 <free_pages>
    free_page(p2);
ffffffffc0200e20:	4585                	li	a1,1
ffffffffc0200e22:	8556                	mv	a0,s5
ffffffffc0200e24:	1dd000ef          	jal	ra,ffffffffc0201800 <free_pages>
    assert(nr_free == 3);
ffffffffc0200e28:	4818                	lw	a4,16(s0)
ffffffffc0200e2a:	478d                	li	a5,3
ffffffffc0200e2c:	28f71863          	bne	a4,a5,ffffffffc02010bc <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e30:	4505                	li	a0,1
ffffffffc0200e32:	191000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200e36:	89aa                	mv	s3,a0
ffffffffc0200e38:	26050263          	beqz	a0,ffffffffc020109c <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e3c:	4505                	li	a0,1
ffffffffc0200e3e:	185000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200e42:	8aaa                	mv	s5,a0
ffffffffc0200e44:	3a050c63          	beqz	a0,ffffffffc02011fc <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e48:	4505                	li	a0,1
ffffffffc0200e4a:	179000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200e4e:	8a2a                	mv	s4,a0
ffffffffc0200e50:	38050663          	beqz	a0,ffffffffc02011dc <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0200e54:	4505                	li	a0,1
ffffffffc0200e56:	16d000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200e5a:	36051163          	bnez	a0,ffffffffc02011bc <default_check+0x4b6>
    free_page(p0);
ffffffffc0200e5e:	4585                	li	a1,1
ffffffffc0200e60:	854e                	mv	a0,s3
ffffffffc0200e62:	19f000ef          	jal	ra,ffffffffc0201800 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200e66:	641c                	ld	a5,8(s0)
ffffffffc0200e68:	20878a63          	beq	a5,s0,ffffffffc020107c <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0200e6c:	4505                	li	a0,1
ffffffffc0200e6e:	155000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200e72:	30a99563          	bne	s3,a0,ffffffffc020117c <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0200e76:	4505                	li	a0,1
ffffffffc0200e78:	14b000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200e7c:	2e051063          	bnez	a0,ffffffffc020115c <default_check+0x456>
    assert(nr_free == 0);
ffffffffc0200e80:	481c                	lw	a5,16(s0)
ffffffffc0200e82:	2a079d63          	bnez	a5,ffffffffc020113c <default_check+0x436>
    free_page(p);
ffffffffc0200e86:	854e                	mv	a0,s3
ffffffffc0200e88:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200e8a:	01843023          	sd	s8,0(s0)
ffffffffc0200e8e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200e92:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200e96:	16b000ef          	jal	ra,ffffffffc0201800 <free_pages>
    free_page(p1);
ffffffffc0200e9a:	4585                	li	a1,1
ffffffffc0200e9c:	8556                	mv	a0,s5
ffffffffc0200e9e:	163000ef          	jal	ra,ffffffffc0201800 <free_pages>
    free_page(p2);
ffffffffc0200ea2:	4585                	li	a1,1
ffffffffc0200ea4:	8552                	mv	a0,s4
ffffffffc0200ea6:	15b000ef          	jal	ra,ffffffffc0201800 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200eaa:	4515                	li	a0,5
ffffffffc0200eac:	117000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200eb0:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200eb2:	26050563          	beqz	a0,ffffffffc020111c <default_check+0x416>
ffffffffc0200eb6:	651c                	ld	a5,8(a0)
ffffffffc0200eb8:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200eba:	8b85                	andi	a5,a5,1
ffffffffc0200ebc:	54079063          	bnez	a5,ffffffffc02013fc <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200ec0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200ec2:	00043b03          	ld	s6,0(s0)
ffffffffc0200ec6:	00843a83          	ld	s5,8(s0)
ffffffffc0200eca:	e000                	sd	s0,0(s0)
ffffffffc0200ecc:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200ece:	0f5000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200ed2:	50051563          	bnez	a0,ffffffffc02013dc <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200ed6:	05098a13          	addi	s4,s3,80
ffffffffc0200eda:	8552                	mv	a0,s4
ffffffffc0200edc:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200ede:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200ee2:	00006797          	auipc	a5,0x6
ffffffffc0200ee6:	1407ab23          	sw	zero,342(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200eea:	117000ef          	jal	ra,ffffffffc0201800 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200eee:	4511                	li	a0,4
ffffffffc0200ef0:	0d3000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200ef4:	4c051463          	bnez	a0,ffffffffc02013bc <default_check+0x6b6>
ffffffffc0200ef8:	0589b783          	ld	a5,88(s3)
ffffffffc0200efc:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200efe:	8b85                	andi	a5,a5,1
ffffffffc0200f00:	48078e63          	beqz	a5,ffffffffc020139c <default_check+0x696>
ffffffffc0200f04:	0609a703          	lw	a4,96(s3)
ffffffffc0200f08:	478d                	li	a5,3
ffffffffc0200f0a:	48f71963          	bne	a4,a5,ffffffffc020139c <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200f0e:	450d                	li	a0,3
ffffffffc0200f10:	0b3000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200f14:	8c2a                	mv	s8,a0
ffffffffc0200f16:	46050363          	beqz	a0,ffffffffc020137c <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc0200f1a:	4505                	li	a0,1
ffffffffc0200f1c:	0a7000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200f20:	42051e63          	bnez	a0,ffffffffc020135c <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc0200f24:	418a1c63          	bne	s4,s8,ffffffffc020133c <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200f28:	4585                	li	a1,1
ffffffffc0200f2a:	854e                	mv	a0,s3
ffffffffc0200f2c:	0d5000ef          	jal	ra,ffffffffc0201800 <free_pages>
    free_pages(p1, 3);
ffffffffc0200f30:	458d                	li	a1,3
ffffffffc0200f32:	8552                	mv	a0,s4
ffffffffc0200f34:	0cd000ef          	jal	ra,ffffffffc0201800 <free_pages>
ffffffffc0200f38:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200f3c:	02898c13          	addi	s8,s3,40
ffffffffc0200f40:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200f42:	8b85                	andi	a5,a5,1
ffffffffc0200f44:	3c078c63          	beqz	a5,ffffffffc020131c <default_check+0x616>
ffffffffc0200f48:	0109a703          	lw	a4,16(s3)
ffffffffc0200f4c:	4785                	li	a5,1
ffffffffc0200f4e:	3cf71763          	bne	a4,a5,ffffffffc020131c <default_check+0x616>
ffffffffc0200f52:	008a3783          	ld	a5,8(s4)
ffffffffc0200f56:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200f58:	8b85                	andi	a5,a5,1
ffffffffc0200f5a:	3a078163          	beqz	a5,ffffffffc02012fc <default_check+0x5f6>
ffffffffc0200f5e:	010a2703          	lw	a4,16(s4)
ffffffffc0200f62:	478d                	li	a5,3
ffffffffc0200f64:	38f71c63          	bne	a4,a5,ffffffffc02012fc <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200f68:	4505                	li	a0,1
ffffffffc0200f6a:	059000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200f6e:	36a99763          	bne	s3,a0,ffffffffc02012dc <default_check+0x5d6>
    free_page(p0);
ffffffffc0200f72:	4585                	li	a1,1
ffffffffc0200f74:	08d000ef          	jal	ra,ffffffffc0201800 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200f78:	4509                	li	a0,2
ffffffffc0200f7a:	049000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200f7e:	32aa1f63          	bne	s4,a0,ffffffffc02012bc <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc0200f82:	4589                	li	a1,2
ffffffffc0200f84:	07d000ef          	jal	ra,ffffffffc0201800 <free_pages>
    free_page(p2);
ffffffffc0200f88:	4585                	li	a1,1
ffffffffc0200f8a:	8562                	mv	a0,s8
ffffffffc0200f8c:	075000ef          	jal	ra,ffffffffc0201800 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f90:	4515                	li	a0,5
ffffffffc0200f92:	031000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200f96:	89aa                	mv	s3,a0
ffffffffc0200f98:	48050263          	beqz	a0,ffffffffc020141c <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc0200f9c:	4505                	li	a0,1
ffffffffc0200f9e:	025000ef          	jal	ra,ffffffffc02017c2 <alloc_pages>
ffffffffc0200fa2:	2c051d63          	bnez	a0,ffffffffc020127c <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0200fa6:	481c                	lw	a5,16(s0)
ffffffffc0200fa8:	2a079a63          	bnez	a5,ffffffffc020125c <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200fac:	4595                	li	a1,5
ffffffffc0200fae:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200fb0:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200fb4:	01643023          	sd	s6,0(s0)
ffffffffc0200fb8:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200fbc:	045000ef          	jal	ra,ffffffffc0201800 <free_pages>
    return listelm->next;
ffffffffc0200fc0:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fc2:	00878963          	beq	a5,s0,ffffffffc0200fd4 <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200fc6:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fca:	679c                	ld	a5,8(a5)
ffffffffc0200fcc:	397d                	addiw	s2,s2,-1
ffffffffc0200fce:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fd0:	fe879be3          	bne	a5,s0,ffffffffc0200fc6 <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0200fd4:	26091463          	bnez	s2,ffffffffc020123c <default_check+0x536>
    assert(total == 0);
ffffffffc0200fd8:	46049263          	bnez	s1,ffffffffc020143c <default_check+0x736>
}
ffffffffc0200fdc:	60a6                	ld	ra,72(sp)
ffffffffc0200fde:	6406                	ld	s0,64(sp)
ffffffffc0200fe0:	74e2                	ld	s1,56(sp)
ffffffffc0200fe2:	7942                	ld	s2,48(sp)
ffffffffc0200fe4:	79a2                	ld	s3,40(sp)
ffffffffc0200fe6:	7a02                	ld	s4,32(sp)
ffffffffc0200fe8:	6ae2                	ld	s5,24(sp)
ffffffffc0200fea:	6b42                	ld	s6,16(sp)
ffffffffc0200fec:	6ba2                	ld	s7,8(sp)
ffffffffc0200fee:	6c02                	ld	s8,0(sp)
ffffffffc0200ff0:	6161                	addi	sp,sp,80
ffffffffc0200ff2:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ff4:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200ff6:	4481                	li	s1,0
ffffffffc0200ff8:	4901                	li	s2,0
ffffffffc0200ffa:	b3b9                	j	ffffffffc0200d48 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200ffc:	00002697          	auipc	a3,0x2
ffffffffc0201000:	a1468693          	addi	a3,a3,-1516 # ffffffffc0202a10 <commands+0x6d8>
ffffffffc0201004:	00002617          	auipc	a2,0x2
ffffffffc0201008:	a1c60613          	addi	a2,a2,-1508 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020100c:	0f000593          	li	a1,240
ffffffffc0201010:	00002517          	auipc	a0,0x2
ffffffffc0201014:	a2850513          	addi	a0,a0,-1496 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201018:	bfaff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020101c:	00002697          	auipc	a3,0x2
ffffffffc0201020:	ab468693          	addi	a3,a3,-1356 # ffffffffc0202ad0 <commands+0x798>
ffffffffc0201024:	00002617          	auipc	a2,0x2
ffffffffc0201028:	9fc60613          	addi	a2,a2,-1540 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020102c:	0bd00593          	li	a1,189
ffffffffc0201030:	00002517          	auipc	a0,0x2
ffffffffc0201034:	a0850513          	addi	a0,a0,-1528 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201038:	bdaff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020103c:	00002697          	auipc	a3,0x2
ffffffffc0201040:	abc68693          	addi	a3,a3,-1348 # ffffffffc0202af8 <commands+0x7c0>
ffffffffc0201044:	00002617          	auipc	a2,0x2
ffffffffc0201048:	9dc60613          	addi	a2,a2,-1572 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020104c:	0be00593          	li	a1,190
ffffffffc0201050:	00002517          	auipc	a0,0x2
ffffffffc0201054:	9e850513          	addi	a0,a0,-1560 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201058:	bbaff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020105c:	00002697          	auipc	a3,0x2
ffffffffc0201060:	adc68693          	addi	a3,a3,-1316 # ffffffffc0202b38 <commands+0x800>
ffffffffc0201064:	00002617          	auipc	a2,0x2
ffffffffc0201068:	9bc60613          	addi	a2,a2,-1604 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020106c:	0c000593          	li	a1,192
ffffffffc0201070:	00002517          	auipc	a0,0x2
ffffffffc0201074:	9c850513          	addi	a0,a0,-1592 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201078:	b9aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(!list_empty(&free_list));
ffffffffc020107c:	00002697          	auipc	a3,0x2
ffffffffc0201080:	b4468693          	addi	a3,a3,-1212 # ffffffffc0202bc0 <commands+0x888>
ffffffffc0201084:	00002617          	auipc	a2,0x2
ffffffffc0201088:	99c60613          	addi	a2,a2,-1636 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020108c:	0d900593          	li	a1,217
ffffffffc0201090:	00002517          	auipc	a0,0x2
ffffffffc0201094:	9a850513          	addi	a0,a0,-1624 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201098:	b7aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020109c:	00002697          	auipc	a3,0x2
ffffffffc02010a0:	9d468693          	addi	a3,a3,-1580 # ffffffffc0202a70 <commands+0x738>
ffffffffc02010a4:	00002617          	auipc	a2,0x2
ffffffffc02010a8:	97c60613          	addi	a2,a2,-1668 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02010ac:	0d200593          	li	a1,210
ffffffffc02010b0:	00002517          	auipc	a0,0x2
ffffffffc02010b4:	98850513          	addi	a0,a0,-1656 # ffffffffc0202a38 <commands+0x700>
ffffffffc02010b8:	b5aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(nr_free == 3);
ffffffffc02010bc:	00002697          	auipc	a3,0x2
ffffffffc02010c0:	af468693          	addi	a3,a3,-1292 # ffffffffc0202bb0 <commands+0x878>
ffffffffc02010c4:	00002617          	auipc	a2,0x2
ffffffffc02010c8:	95c60613          	addi	a2,a2,-1700 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02010cc:	0d000593          	li	a1,208
ffffffffc02010d0:	00002517          	auipc	a0,0x2
ffffffffc02010d4:	96850513          	addi	a0,a0,-1688 # ffffffffc0202a38 <commands+0x700>
ffffffffc02010d8:	b3aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010dc:	00002697          	auipc	a3,0x2
ffffffffc02010e0:	abc68693          	addi	a3,a3,-1348 # ffffffffc0202b98 <commands+0x860>
ffffffffc02010e4:	00002617          	auipc	a2,0x2
ffffffffc02010e8:	93c60613          	addi	a2,a2,-1732 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02010ec:	0cb00593          	li	a1,203
ffffffffc02010f0:	00002517          	auipc	a0,0x2
ffffffffc02010f4:	94850513          	addi	a0,a0,-1720 # ffffffffc0202a38 <commands+0x700>
ffffffffc02010f8:	b1aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010fc:	00002697          	auipc	a3,0x2
ffffffffc0201100:	a7c68693          	addi	a3,a3,-1412 # ffffffffc0202b78 <commands+0x840>
ffffffffc0201104:	00002617          	auipc	a2,0x2
ffffffffc0201108:	91c60613          	addi	a2,a2,-1764 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020110c:	0c200593          	li	a1,194
ffffffffc0201110:	00002517          	auipc	a0,0x2
ffffffffc0201114:	92850513          	addi	a0,a0,-1752 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201118:	afaff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(p0 != NULL);
ffffffffc020111c:	00002697          	auipc	a3,0x2
ffffffffc0201120:	aec68693          	addi	a3,a3,-1300 # ffffffffc0202c08 <commands+0x8d0>
ffffffffc0201124:	00002617          	auipc	a2,0x2
ffffffffc0201128:	8fc60613          	addi	a2,a2,-1796 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020112c:	0f800593          	li	a1,248
ffffffffc0201130:	00002517          	auipc	a0,0x2
ffffffffc0201134:	90850513          	addi	a0,a0,-1784 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201138:	adaff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(nr_free == 0);
ffffffffc020113c:	00002697          	auipc	a3,0x2
ffffffffc0201140:	abc68693          	addi	a3,a3,-1348 # ffffffffc0202bf8 <commands+0x8c0>
ffffffffc0201144:	00002617          	auipc	a2,0x2
ffffffffc0201148:	8dc60613          	addi	a2,a2,-1828 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020114c:	0df00593          	li	a1,223
ffffffffc0201150:	00002517          	auipc	a0,0x2
ffffffffc0201154:	8e850513          	addi	a0,a0,-1816 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201158:	abaff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020115c:	00002697          	auipc	a3,0x2
ffffffffc0201160:	a3c68693          	addi	a3,a3,-1476 # ffffffffc0202b98 <commands+0x860>
ffffffffc0201164:	00002617          	auipc	a2,0x2
ffffffffc0201168:	8bc60613          	addi	a2,a2,-1860 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020116c:	0dd00593          	li	a1,221
ffffffffc0201170:	00002517          	auipc	a0,0x2
ffffffffc0201174:	8c850513          	addi	a0,a0,-1848 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201178:	a9aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020117c:	00002697          	auipc	a3,0x2
ffffffffc0201180:	a5c68693          	addi	a3,a3,-1444 # ffffffffc0202bd8 <commands+0x8a0>
ffffffffc0201184:	00002617          	auipc	a2,0x2
ffffffffc0201188:	89c60613          	addi	a2,a2,-1892 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020118c:	0dc00593          	li	a1,220
ffffffffc0201190:	00002517          	auipc	a0,0x2
ffffffffc0201194:	8a850513          	addi	a0,a0,-1880 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201198:	a7aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020119c:	00002697          	auipc	a3,0x2
ffffffffc02011a0:	8d468693          	addi	a3,a3,-1836 # ffffffffc0202a70 <commands+0x738>
ffffffffc02011a4:	00002617          	auipc	a2,0x2
ffffffffc02011a8:	87c60613          	addi	a2,a2,-1924 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02011ac:	0b900593          	li	a1,185
ffffffffc02011b0:	00002517          	auipc	a0,0x2
ffffffffc02011b4:	88850513          	addi	a0,a0,-1912 # ffffffffc0202a38 <commands+0x700>
ffffffffc02011b8:	a5aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011bc:	00002697          	auipc	a3,0x2
ffffffffc02011c0:	9dc68693          	addi	a3,a3,-1572 # ffffffffc0202b98 <commands+0x860>
ffffffffc02011c4:	00002617          	auipc	a2,0x2
ffffffffc02011c8:	85c60613          	addi	a2,a2,-1956 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02011cc:	0d600593          	li	a1,214
ffffffffc02011d0:	00002517          	auipc	a0,0x2
ffffffffc02011d4:	86850513          	addi	a0,a0,-1944 # ffffffffc0202a38 <commands+0x700>
ffffffffc02011d8:	a3aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011dc:	00002697          	auipc	a3,0x2
ffffffffc02011e0:	8d468693          	addi	a3,a3,-1836 # ffffffffc0202ab0 <commands+0x778>
ffffffffc02011e4:	00002617          	auipc	a2,0x2
ffffffffc02011e8:	83c60613          	addi	a2,a2,-1988 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02011ec:	0d400593          	li	a1,212
ffffffffc02011f0:	00002517          	auipc	a0,0x2
ffffffffc02011f4:	84850513          	addi	a0,a0,-1976 # ffffffffc0202a38 <commands+0x700>
ffffffffc02011f8:	a1aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011fc:	00002697          	auipc	a3,0x2
ffffffffc0201200:	89468693          	addi	a3,a3,-1900 # ffffffffc0202a90 <commands+0x758>
ffffffffc0201204:	00002617          	auipc	a2,0x2
ffffffffc0201208:	81c60613          	addi	a2,a2,-2020 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020120c:	0d300593          	li	a1,211
ffffffffc0201210:	00002517          	auipc	a0,0x2
ffffffffc0201214:	82850513          	addi	a0,a0,-2008 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201218:	9faff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020121c:	00002697          	auipc	a3,0x2
ffffffffc0201220:	89468693          	addi	a3,a3,-1900 # ffffffffc0202ab0 <commands+0x778>
ffffffffc0201224:	00001617          	auipc	a2,0x1
ffffffffc0201228:	7fc60613          	addi	a2,a2,2044 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020122c:	0bb00593          	li	a1,187
ffffffffc0201230:	00002517          	auipc	a0,0x2
ffffffffc0201234:	80850513          	addi	a0,a0,-2040 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201238:	9daff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(count == 0);
ffffffffc020123c:	00002697          	auipc	a3,0x2
ffffffffc0201240:	b1c68693          	addi	a3,a3,-1252 # ffffffffc0202d58 <commands+0xa20>
ffffffffc0201244:	00001617          	auipc	a2,0x1
ffffffffc0201248:	7dc60613          	addi	a2,a2,2012 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020124c:	12500593          	li	a1,293
ffffffffc0201250:	00001517          	auipc	a0,0x1
ffffffffc0201254:	7e850513          	addi	a0,a0,2024 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201258:	9baff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(nr_free == 0);
ffffffffc020125c:	00002697          	auipc	a3,0x2
ffffffffc0201260:	99c68693          	addi	a3,a3,-1636 # ffffffffc0202bf8 <commands+0x8c0>
ffffffffc0201264:	00001617          	auipc	a2,0x1
ffffffffc0201268:	7bc60613          	addi	a2,a2,1980 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020126c:	11a00593          	li	a1,282
ffffffffc0201270:	00001517          	auipc	a0,0x1
ffffffffc0201274:	7c850513          	addi	a0,a0,1992 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201278:	99aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020127c:	00002697          	auipc	a3,0x2
ffffffffc0201280:	91c68693          	addi	a3,a3,-1764 # ffffffffc0202b98 <commands+0x860>
ffffffffc0201284:	00001617          	auipc	a2,0x1
ffffffffc0201288:	79c60613          	addi	a2,a2,1948 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020128c:	11800593          	li	a1,280
ffffffffc0201290:	00001517          	auipc	a0,0x1
ffffffffc0201294:	7a850513          	addi	a0,a0,1960 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201298:	97aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020129c:	00002697          	auipc	a3,0x2
ffffffffc02012a0:	8bc68693          	addi	a3,a3,-1860 # ffffffffc0202b58 <commands+0x820>
ffffffffc02012a4:	00001617          	auipc	a2,0x1
ffffffffc02012a8:	77c60613          	addi	a2,a2,1916 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02012ac:	0c100593          	li	a1,193
ffffffffc02012b0:	00001517          	auipc	a0,0x1
ffffffffc02012b4:	78850513          	addi	a0,a0,1928 # ffffffffc0202a38 <commands+0x700>
ffffffffc02012b8:	95aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02012bc:	00002697          	auipc	a3,0x2
ffffffffc02012c0:	a5c68693          	addi	a3,a3,-1444 # ffffffffc0202d18 <commands+0x9e0>
ffffffffc02012c4:	00001617          	auipc	a2,0x1
ffffffffc02012c8:	75c60613          	addi	a2,a2,1884 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02012cc:	11200593          	li	a1,274
ffffffffc02012d0:	00001517          	auipc	a0,0x1
ffffffffc02012d4:	76850513          	addi	a0,a0,1896 # ffffffffc0202a38 <commands+0x700>
ffffffffc02012d8:	93aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02012dc:	00002697          	auipc	a3,0x2
ffffffffc02012e0:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0202cf8 <commands+0x9c0>
ffffffffc02012e4:	00001617          	auipc	a2,0x1
ffffffffc02012e8:	73c60613          	addi	a2,a2,1852 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02012ec:	11000593          	li	a1,272
ffffffffc02012f0:	00001517          	auipc	a0,0x1
ffffffffc02012f4:	74850513          	addi	a0,a0,1864 # ffffffffc0202a38 <commands+0x700>
ffffffffc02012f8:	91aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02012fc:	00002697          	auipc	a3,0x2
ffffffffc0201300:	9d468693          	addi	a3,a3,-1580 # ffffffffc0202cd0 <commands+0x998>
ffffffffc0201304:	00001617          	auipc	a2,0x1
ffffffffc0201308:	71c60613          	addi	a2,a2,1820 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020130c:	10e00593          	li	a1,270
ffffffffc0201310:	00001517          	auipc	a0,0x1
ffffffffc0201314:	72850513          	addi	a0,a0,1832 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201318:	8faff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020131c:	00002697          	auipc	a3,0x2
ffffffffc0201320:	98c68693          	addi	a3,a3,-1652 # ffffffffc0202ca8 <commands+0x970>
ffffffffc0201324:	00001617          	auipc	a2,0x1
ffffffffc0201328:	6fc60613          	addi	a2,a2,1788 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020132c:	10d00593          	li	a1,269
ffffffffc0201330:	00001517          	auipc	a0,0x1
ffffffffc0201334:	70850513          	addi	a0,a0,1800 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201338:	8daff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(p0 + 2 == p1);
ffffffffc020133c:	00002697          	auipc	a3,0x2
ffffffffc0201340:	95c68693          	addi	a3,a3,-1700 # ffffffffc0202c98 <commands+0x960>
ffffffffc0201344:	00001617          	auipc	a2,0x1
ffffffffc0201348:	6dc60613          	addi	a2,a2,1756 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020134c:	10800593          	li	a1,264
ffffffffc0201350:	00001517          	auipc	a0,0x1
ffffffffc0201354:	6e850513          	addi	a0,a0,1768 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201358:	8baff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020135c:	00002697          	auipc	a3,0x2
ffffffffc0201360:	83c68693          	addi	a3,a3,-1988 # ffffffffc0202b98 <commands+0x860>
ffffffffc0201364:	00001617          	auipc	a2,0x1
ffffffffc0201368:	6bc60613          	addi	a2,a2,1724 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020136c:	10700593          	li	a1,263
ffffffffc0201370:	00001517          	auipc	a0,0x1
ffffffffc0201374:	6c850513          	addi	a0,a0,1736 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201378:	89aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020137c:	00002697          	auipc	a3,0x2
ffffffffc0201380:	8fc68693          	addi	a3,a3,-1796 # ffffffffc0202c78 <commands+0x940>
ffffffffc0201384:	00001617          	auipc	a2,0x1
ffffffffc0201388:	69c60613          	addi	a2,a2,1692 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020138c:	10600593          	li	a1,262
ffffffffc0201390:	00001517          	auipc	a0,0x1
ffffffffc0201394:	6a850513          	addi	a0,a0,1704 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201398:	87aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020139c:	00002697          	auipc	a3,0x2
ffffffffc02013a0:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0202c48 <commands+0x910>
ffffffffc02013a4:	00001617          	auipc	a2,0x1
ffffffffc02013a8:	67c60613          	addi	a2,a2,1660 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02013ac:	10500593          	li	a1,261
ffffffffc02013b0:	00001517          	auipc	a0,0x1
ffffffffc02013b4:	68850513          	addi	a0,a0,1672 # ffffffffc0202a38 <commands+0x700>
ffffffffc02013b8:	85aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02013bc:	00002697          	auipc	a3,0x2
ffffffffc02013c0:	87468693          	addi	a3,a3,-1932 # ffffffffc0202c30 <commands+0x8f8>
ffffffffc02013c4:	00001617          	auipc	a2,0x1
ffffffffc02013c8:	65c60613          	addi	a2,a2,1628 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02013cc:	10400593          	li	a1,260
ffffffffc02013d0:	00001517          	auipc	a0,0x1
ffffffffc02013d4:	66850513          	addi	a0,a0,1640 # ffffffffc0202a38 <commands+0x700>
ffffffffc02013d8:	83aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013dc:	00001697          	auipc	a3,0x1
ffffffffc02013e0:	7bc68693          	addi	a3,a3,1980 # ffffffffc0202b98 <commands+0x860>
ffffffffc02013e4:	00001617          	auipc	a2,0x1
ffffffffc02013e8:	63c60613          	addi	a2,a2,1596 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02013ec:	0fe00593          	li	a1,254
ffffffffc02013f0:	00001517          	auipc	a0,0x1
ffffffffc02013f4:	64850513          	addi	a0,a0,1608 # ffffffffc0202a38 <commands+0x700>
ffffffffc02013f8:	81aff0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(!PageProperty(p0));
ffffffffc02013fc:	00002697          	auipc	a3,0x2
ffffffffc0201400:	81c68693          	addi	a3,a3,-2020 # ffffffffc0202c18 <commands+0x8e0>
ffffffffc0201404:	00001617          	auipc	a2,0x1
ffffffffc0201408:	61c60613          	addi	a2,a2,1564 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020140c:	0f900593          	li	a1,249
ffffffffc0201410:	00001517          	auipc	a0,0x1
ffffffffc0201414:	62850513          	addi	a0,a0,1576 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201418:	ffbfe0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020141c:	00002697          	auipc	a3,0x2
ffffffffc0201420:	91c68693          	addi	a3,a3,-1764 # ffffffffc0202d38 <commands+0xa00>
ffffffffc0201424:	00001617          	auipc	a2,0x1
ffffffffc0201428:	5fc60613          	addi	a2,a2,1532 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020142c:	11700593          	li	a1,279
ffffffffc0201430:	00001517          	auipc	a0,0x1
ffffffffc0201434:	60850513          	addi	a0,a0,1544 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201438:	fdbfe0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(total == 0);
ffffffffc020143c:	00002697          	auipc	a3,0x2
ffffffffc0201440:	92c68693          	addi	a3,a3,-1748 # ffffffffc0202d68 <commands+0xa30>
ffffffffc0201444:	00001617          	auipc	a2,0x1
ffffffffc0201448:	5dc60613          	addi	a2,a2,1500 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020144c:	12600593          	li	a1,294
ffffffffc0201450:	00001517          	auipc	a0,0x1
ffffffffc0201454:	5e850513          	addi	a0,a0,1512 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201458:	fbbfe0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(total == nr_free_pages());
ffffffffc020145c:	00001697          	auipc	a3,0x1
ffffffffc0201460:	5f468693          	addi	a3,a3,1524 # ffffffffc0202a50 <commands+0x718>
ffffffffc0201464:	00001617          	auipc	a2,0x1
ffffffffc0201468:	5bc60613          	addi	a2,a2,1468 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020146c:	0f300593          	li	a1,243
ffffffffc0201470:	00001517          	auipc	a0,0x1
ffffffffc0201474:	5c850513          	addi	a0,a0,1480 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201478:	f9bfe0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020147c:	00001697          	auipc	a3,0x1
ffffffffc0201480:	61468693          	addi	a3,a3,1556 # ffffffffc0202a90 <commands+0x758>
ffffffffc0201484:	00001617          	auipc	a2,0x1
ffffffffc0201488:	59c60613          	addi	a2,a2,1436 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc020148c:	0ba00593          	li	a1,186
ffffffffc0201490:	00001517          	auipc	a0,0x1
ffffffffc0201494:	5a850513          	addi	a0,a0,1448 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201498:	f7bfe0ef          	jal	ra,ffffffffc0200412 <__panic>

ffffffffc020149c <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc020149c:	1141                	addi	sp,sp,-16
ffffffffc020149e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02014a0:	14058a63          	beqz	a1,ffffffffc02015f4 <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc02014a4:	00259693          	slli	a3,a1,0x2
ffffffffc02014a8:	96ae                	add	a3,a3,a1
ffffffffc02014aa:	068e                	slli	a3,a3,0x3
ffffffffc02014ac:	96aa                	add	a3,a3,a0
ffffffffc02014ae:	87aa                	mv	a5,a0
ffffffffc02014b0:	02d50263          	beq	a0,a3,ffffffffc02014d4 <default_free_pages+0x38>
ffffffffc02014b4:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02014b6:	8b05                	andi	a4,a4,1
ffffffffc02014b8:	10071e63          	bnez	a4,ffffffffc02015d4 <default_free_pages+0x138>
ffffffffc02014bc:	6798                	ld	a4,8(a5)
ffffffffc02014be:	8b09                	andi	a4,a4,2
ffffffffc02014c0:	10071a63          	bnez	a4,ffffffffc02015d4 <default_free_pages+0x138>
        p->flags = 0;
ffffffffc02014c4:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02014c8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02014cc:	02878793          	addi	a5,a5,40
ffffffffc02014d0:	fed792e3          	bne	a5,a3,ffffffffc02014b4 <default_free_pages+0x18>
    base->property = n;
ffffffffc02014d4:	2581                	sext.w	a1,a1
ffffffffc02014d6:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02014d8:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014dc:	4789                	li	a5,2
ffffffffc02014de:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02014e2:	00006697          	auipc	a3,0x6
ffffffffc02014e6:	b4668693          	addi	a3,a3,-1210 # ffffffffc0207028 <free_area>
ffffffffc02014ea:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02014ec:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02014ee:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02014f2:	9db9                	addw	a1,a1,a4
ffffffffc02014f4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02014f6:	0ad78863          	beq	a5,a3,ffffffffc02015a6 <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc02014fa:	fe878713          	addi	a4,a5,-24
ffffffffc02014fe:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201502:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201504:	00e56a63          	bltu	a0,a4,ffffffffc0201518 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc0201508:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020150a:	06d70263          	beq	a4,a3,ffffffffc020156e <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc020150e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201510:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201514:	fee57ae3          	bgeu	a0,a4,ffffffffc0201508 <default_free_pages+0x6c>
ffffffffc0201518:	c199                	beqz	a1,ffffffffc020151e <default_free_pages+0x82>
ffffffffc020151a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020151e:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201520:	e390                	sd	a2,0(a5)
ffffffffc0201522:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201524:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201526:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201528:	02d70063          	beq	a4,a3,ffffffffc0201548 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc020152c:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201530:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc0201534:	02081613          	slli	a2,a6,0x20
ffffffffc0201538:	9201                	srli	a2,a2,0x20
ffffffffc020153a:	00261793          	slli	a5,a2,0x2
ffffffffc020153e:	97b2                	add	a5,a5,a2
ffffffffc0201540:	078e                	slli	a5,a5,0x3
ffffffffc0201542:	97ae                	add	a5,a5,a1
ffffffffc0201544:	02f50f63          	beq	a0,a5,ffffffffc0201582 <default_free_pages+0xe6>
    return listelm->next;
ffffffffc0201548:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc020154a:	00d70f63          	beq	a4,a3,ffffffffc0201568 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc020154e:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201550:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201554:	02059613          	slli	a2,a1,0x20
ffffffffc0201558:	9201                	srli	a2,a2,0x20
ffffffffc020155a:	00261793          	slli	a5,a2,0x2
ffffffffc020155e:	97b2                	add	a5,a5,a2
ffffffffc0201560:	078e                	slli	a5,a5,0x3
ffffffffc0201562:	97aa                	add	a5,a5,a0
ffffffffc0201564:	04f68863          	beq	a3,a5,ffffffffc02015b4 <default_free_pages+0x118>
}
ffffffffc0201568:	60a2                	ld	ra,8(sp)
ffffffffc020156a:	0141                	addi	sp,sp,16
ffffffffc020156c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020156e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201570:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201572:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201574:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201576:	02d70563          	beq	a4,a3,ffffffffc02015a0 <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc020157a:	8832                	mv	a6,a2
ffffffffc020157c:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020157e:	87ba                	mv	a5,a4
ffffffffc0201580:	bf41                	j	ffffffffc0201510 <default_free_pages+0x74>
            p->property += base->property;
ffffffffc0201582:	491c                	lw	a5,16(a0)
ffffffffc0201584:	0107883b          	addw	a6,a5,a6
ffffffffc0201588:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020158c:	57f5                	li	a5,-3
ffffffffc020158e:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201592:	6d10                	ld	a2,24(a0)
ffffffffc0201594:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc0201596:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201598:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc020159a:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc020159c:	e390                	sd	a2,0(a5)
ffffffffc020159e:	b775                	j	ffffffffc020154a <default_free_pages+0xae>
ffffffffc02015a0:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015a2:	873e                	mv	a4,a5
ffffffffc02015a4:	b761                	j	ffffffffc020152c <default_free_pages+0x90>
}
ffffffffc02015a6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02015a8:	e390                	sd	a2,0(a5)
ffffffffc02015aa:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015ac:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015ae:	ed1c                	sd	a5,24(a0)
ffffffffc02015b0:	0141                	addi	sp,sp,16
ffffffffc02015b2:	8082                	ret
            base->property += p->property;
ffffffffc02015b4:	ff872783          	lw	a5,-8(a4)
ffffffffc02015b8:	ff070693          	addi	a3,a4,-16
ffffffffc02015bc:	9dbd                	addw	a1,a1,a5
ffffffffc02015be:	c90c                	sw	a1,16(a0)
ffffffffc02015c0:	57f5                	li	a5,-3
ffffffffc02015c2:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015c6:	6314                	ld	a3,0(a4)
ffffffffc02015c8:	671c                	ld	a5,8(a4)
}
ffffffffc02015ca:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02015cc:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02015ce:	e394                	sd	a3,0(a5)
ffffffffc02015d0:	0141                	addi	sp,sp,16
ffffffffc02015d2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02015d4:	00001697          	auipc	a3,0x1
ffffffffc02015d8:	7ac68693          	addi	a3,a3,1964 # ffffffffc0202d80 <commands+0xa48>
ffffffffc02015dc:	00001617          	auipc	a2,0x1
ffffffffc02015e0:	44460613          	addi	a2,a2,1092 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02015e4:	08300593          	li	a1,131
ffffffffc02015e8:	00001517          	auipc	a0,0x1
ffffffffc02015ec:	45050513          	addi	a0,a0,1104 # ffffffffc0202a38 <commands+0x700>
ffffffffc02015f0:	e23fe0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(n > 0);
ffffffffc02015f4:	00001697          	auipc	a3,0x1
ffffffffc02015f8:	78468693          	addi	a3,a3,1924 # ffffffffc0202d78 <commands+0xa40>
ffffffffc02015fc:	00001617          	auipc	a2,0x1
ffffffffc0201600:	42460613          	addi	a2,a2,1060 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc0201604:	08000593          	li	a1,128
ffffffffc0201608:	00001517          	auipc	a0,0x1
ffffffffc020160c:	43050513          	addi	a0,a0,1072 # ffffffffc0202a38 <commands+0x700>
ffffffffc0201610:	e03fe0ef          	jal	ra,ffffffffc0200412 <__panic>

ffffffffc0201614 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201614:	c959                	beqz	a0,ffffffffc02016aa <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc0201616:	00006597          	auipc	a1,0x6
ffffffffc020161a:	a1258593          	addi	a1,a1,-1518 # ffffffffc0207028 <free_area>
ffffffffc020161e:	0105a803          	lw	a6,16(a1)
ffffffffc0201622:	862a                	mv	a2,a0
ffffffffc0201624:	02081793          	slli	a5,a6,0x20
ffffffffc0201628:	9381                	srli	a5,a5,0x20
ffffffffc020162a:	00a7ee63          	bltu	a5,a0,ffffffffc0201646 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020162e:	87ae                	mv	a5,a1
ffffffffc0201630:	a801                	j	ffffffffc0201640 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201632:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201636:	02071693          	slli	a3,a4,0x20
ffffffffc020163a:	9281                	srli	a3,a3,0x20
ffffffffc020163c:	00c6f763          	bgeu	a3,a2,ffffffffc020164a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201640:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201642:	feb798e3          	bne	a5,a1,ffffffffc0201632 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201646:	4501                	li	a0,0
}
ffffffffc0201648:	8082                	ret
    return listelm->prev;
ffffffffc020164a:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020164e:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201652:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0201656:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc020165a:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc020165e:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201662:	02d67b63          	bgeu	a2,a3,ffffffffc0201698 <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc0201666:	00261693          	slli	a3,a2,0x2
ffffffffc020166a:	96b2                	add	a3,a3,a2
ffffffffc020166c:	068e                	slli	a3,a3,0x3
ffffffffc020166e:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0201670:	41c7073b          	subw	a4,a4,t3
ffffffffc0201674:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201676:	00868613          	addi	a2,a3,8
ffffffffc020167a:	4709                	li	a4,2
ffffffffc020167c:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201680:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201684:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc0201688:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020168c:	e310                	sd	a2,0(a4)
ffffffffc020168e:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201692:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc0201694:	0116bc23          	sd	a7,24(a3)
ffffffffc0201698:	41c8083b          	subw	a6,a6,t3
ffffffffc020169c:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02016a0:	5775                	li	a4,-3
ffffffffc02016a2:	17c1                	addi	a5,a5,-16
ffffffffc02016a4:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02016a8:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02016aa:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02016ac:	00001697          	auipc	a3,0x1
ffffffffc02016b0:	6cc68693          	addi	a3,a3,1740 # ffffffffc0202d78 <commands+0xa40>
ffffffffc02016b4:	00001617          	auipc	a2,0x1
ffffffffc02016b8:	36c60613          	addi	a2,a2,876 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02016bc:	06200593          	li	a1,98
ffffffffc02016c0:	00001517          	auipc	a0,0x1
ffffffffc02016c4:	37850513          	addi	a0,a0,888 # ffffffffc0202a38 <commands+0x700>
default_alloc_pages(size_t n) {
ffffffffc02016c8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016ca:	d49fe0ef          	jal	ra,ffffffffc0200412 <__panic>

ffffffffc02016ce <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02016ce:	1141                	addi	sp,sp,-16
ffffffffc02016d0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016d2:	c9e1                	beqz	a1,ffffffffc02017a2 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02016d4:	00259693          	slli	a3,a1,0x2
ffffffffc02016d8:	96ae                	add	a3,a3,a1
ffffffffc02016da:	068e                	slli	a3,a3,0x3
ffffffffc02016dc:	96aa                	add	a3,a3,a0
ffffffffc02016de:	87aa                	mv	a5,a0
ffffffffc02016e0:	00d50f63          	beq	a0,a3,ffffffffc02016fe <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02016e4:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02016e6:	8b05                	andi	a4,a4,1
ffffffffc02016e8:	cf49                	beqz	a4,ffffffffc0201782 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02016ea:	0007a823          	sw	zero,16(a5)
ffffffffc02016ee:	0007b423          	sd	zero,8(a5)
ffffffffc02016f2:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02016f6:	02878793          	addi	a5,a5,40
ffffffffc02016fa:	fed795e3          	bne	a5,a3,ffffffffc02016e4 <default_init_memmap+0x16>
    base->property = n;
ffffffffc02016fe:	2581                	sext.w	a1,a1
ffffffffc0201700:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201702:	4789                	li	a5,2
ffffffffc0201704:	00850713          	addi	a4,a0,8
ffffffffc0201708:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020170c:	00006697          	auipc	a3,0x6
ffffffffc0201710:	91c68693          	addi	a3,a3,-1764 # ffffffffc0207028 <free_area>
ffffffffc0201714:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201716:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201718:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020171c:	9db9                	addw	a1,a1,a4
ffffffffc020171e:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201720:	04d78a63          	beq	a5,a3,ffffffffc0201774 <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0201724:	fe878713          	addi	a4,a5,-24
ffffffffc0201728:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020172c:	4581                	li	a1,0
            if (base < page) {
ffffffffc020172e:	00e56a63          	bltu	a0,a4,ffffffffc0201742 <default_init_memmap+0x74>
    return listelm->next;
ffffffffc0201732:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201734:	02d70263          	beq	a4,a3,ffffffffc0201758 <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc0201738:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020173a:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020173e:	fee57ae3          	bgeu	a0,a4,ffffffffc0201732 <default_init_memmap+0x64>
ffffffffc0201742:	c199                	beqz	a1,ffffffffc0201748 <default_init_memmap+0x7a>
ffffffffc0201744:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201748:	6398                	ld	a4,0(a5)
}
ffffffffc020174a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020174c:	e390                	sd	a2,0(a5)
ffffffffc020174e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201750:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201752:	ed18                	sd	a4,24(a0)
ffffffffc0201754:	0141                	addi	sp,sp,16
ffffffffc0201756:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201758:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020175a:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020175c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020175e:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201760:	00d70663          	beq	a4,a3,ffffffffc020176c <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201764:	8832                	mv	a6,a2
ffffffffc0201766:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201768:	87ba                	mv	a5,a4
ffffffffc020176a:	bfc1                	j	ffffffffc020173a <default_init_memmap+0x6c>
}
ffffffffc020176c:	60a2                	ld	ra,8(sp)
ffffffffc020176e:	e290                	sd	a2,0(a3)
ffffffffc0201770:	0141                	addi	sp,sp,16
ffffffffc0201772:	8082                	ret
ffffffffc0201774:	60a2                	ld	ra,8(sp)
ffffffffc0201776:	e390                	sd	a2,0(a5)
ffffffffc0201778:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020177a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020177c:	ed1c                	sd	a5,24(a0)
ffffffffc020177e:	0141                	addi	sp,sp,16
ffffffffc0201780:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201782:	00001697          	auipc	a3,0x1
ffffffffc0201786:	62668693          	addi	a3,a3,1574 # ffffffffc0202da8 <commands+0xa70>
ffffffffc020178a:	00001617          	auipc	a2,0x1
ffffffffc020178e:	29660613          	addi	a2,a2,662 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc0201792:	04900593          	li	a1,73
ffffffffc0201796:	00001517          	auipc	a0,0x1
ffffffffc020179a:	2a250513          	addi	a0,a0,674 # ffffffffc0202a38 <commands+0x700>
ffffffffc020179e:	c75fe0ef          	jal	ra,ffffffffc0200412 <__panic>
    assert(n > 0);
ffffffffc02017a2:	00001697          	auipc	a3,0x1
ffffffffc02017a6:	5d668693          	addi	a3,a3,1494 # ffffffffc0202d78 <commands+0xa40>
ffffffffc02017aa:	00001617          	auipc	a2,0x1
ffffffffc02017ae:	27660613          	addi	a2,a2,630 # ffffffffc0202a20 <commands+0x6e8>
ffffffffc02017b2:	04600593          	li	a1,70
ffffffffc02017b6:	00001517          	auipc	a0,0x1
ffffffffc02017ba:	28250513          	addi	a0,a0,642 # ffffffffc0202a38 <commands+0x700>
ffffffffc02017be:	c55fe0ef          	jal	ra,ffffffffc0200412 <__panic>

ffffffffc02017c2 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017c2:	100027f3          	csrr	a5,sstatus
ffffffffc02017c6:	8b89                	andi	a5,a5,2
ffffffffc02017c8:	e799                	bnez	a5,ffffffffc02017d6 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02017ca:	00006797          	auipc	a5,0x6
ffffffffc02017ce:	ca67b783          	ld	a5,-858(a5) # ffffffffc0207470 <pmm_manager>
ffffffffc02017d2:	6f9c                	ld	a5,24(a5)
ffffffffc02017d4:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc02017d6:	1141                	addi	sp,sp,-16
ffffffffc02017d8:	e406                	sd	ra,8(sp)
ffffffffc02017da:	e022                	sd	s0,0(sp)
ffffffffc02017dc:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02017de:	896ff0ef          	jal	ra,ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02017e2:	00006797          	auipc	a5,0x6
ffffffffc02017e6:	c8e7b783          	ld	a5,-882(a5) # ffffffffc0207470 <pmm_manager>
ffffffffc02017ea:	6f9c                	ld	a5,24(a5)
ffffffffc02017ec:	8522                	mv	a0,s0
ffffffffc02017ee:	9782                	jalr	a5
ffffffffc02017f0:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02017f2:	87cff0ef          	jal	ra,ffffffffc020086e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02017f6:	60a2                	ld	ra,8(sp)
ffffffffc02017f8:	8522                	mv	a0,s0
ffffffffc02017fa:	6402                	ld	s0,0(sp)
ffffffffc02017fc:	0141                	addi	sp,sp,16
ffffffffc02017fe:	8082                	ret

ffffffffc0201800 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201800:	100027f3          	csrr	a5,sstatus
ffffffffc0201804:	8b89                	andi	a5,a5,2
ffffffffc0201806:	e799                	bnez	a5,ffffffffc0201814 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201808:	00006797          	auipc	a5,0x6
ffffffffc020180c:	c687b783          	ld	a5,-920(a5) # ffffffffc0207470 <pmm_manager>
ffffffffc0201810:	739c                	ld	a5,32(a5)
ffffffffc0201812:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201814:	1101                	addi	sp,sp,-32
ffffffffc0201816:	ec06                	sd	ra,24(sp)
ffffffffc0201818:	e822                	sd	s0,16(sp)
ffffffffc020181a:	e426                	sd	s1,8(sp)
ffffffffc020181c:	842a                	mv	s0,a0
ffffffffc020181e:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201820:	854ff0ef          	jal	ra,ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201824:	00006797          	auipc	a5,0x6
ffffffffc0201828:	c4c7b783          	ld	a5,-948(a5) # ffffffffc0207470 <pmm_manager>
ffffffffc020182c:	739c                	ld	a5,32(a5)
ffffffffc020182e:	85a6                	mv	a1,s1
ffffffffc0201830:	8522                	mv	a0,s0
ffffffffc0201832:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201834:	6442                	ld	s0,16(sp)
ffffffffc0201836:	60e2                	ld	ra,24(sp)
ffffffffc0201838:	64a2                	ld	s1,8(sp)
ffffffffc020183a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020183c:	832ff06f          	j	ffffffffc020086e <intr_enable>

ffffffffc0201840 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201840:	100027f3          	csrr	a5,sstatus
ffffffffc0201844:	8b89                	andi	a5,a5,2
ffffffffc0201846:	e799                	bnez	a5,ffffffffc0201854 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201848:	00006797          	auipc	a5,0x6
ffffffffc020184c:	c287b783          	ld	a5,-984(a5) # ffffffffc0207470 <pmm_manager>
ffffffffc0201850:	779c                	ld	a5,40(a5)
ffffffffc0201852:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201854:	1141                	addi	sp,sp,-16
ffffffffc0201856:	e406                	sd	ra,8(sp)
ffffffffc0201858:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020185a:	81aff0ef          	jal	ra,ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020185e:	00006797          	auipc	a5,0x6
ffffffffc0201862:	c127b783          	ld	a5,-1006(a5) # ffffffffc0207470 <pmm_manager>
ffffffffc0201866:	779c                	ld	a5,40(a5)
ffffffffc0201868:	9782                	jalr	a5
ffffffffc020186a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020186c:	802ff0ef          	jal	ra,ffffffffc020086e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201870:	60a2                	ld	ra,8(sp)
ffffffffc0201872:	8522                	mv	a0,s0
ffffffffc0201874:	6402                	ld	s0,0(sp)
ffffffffc0201876:	0141                	addi	sp,sp,16
ffffffffc0201878:	8082                	ret

ffffffffc020187a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020187a:	00001797          	auipc	a5,0x1
ffffffffc020187e:	55678793          	addi	a5,a5,1366 # ffffffffc0202dd0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201882:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201884:	7179                	addi	sp,sp,-48
ffffffffc0201886:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201888:	00001517          	auipc	a0,0x1
ffffffffc020188c:	58050513          	addi	a0,a0,1408 # ffffffffc0202e08 <default_pmm_manager+0x38>
    pmm_manager = &default_pmm_manager;
ffffffffc0201890:	00006417          	auipc	s0,0x6
ffffffffc0201894:	be040413          	addi	s0,s0,-1056 # ffffffffc0207470 <pmm_manager>
void pmm_init(void) {
ffffffffc0201898:	f406                	sd	ra,40(sp)
ffffffffc020189a:	ec26                	sd	s1,24(sp)
ffffffffc020189c:	e44e                	sd	s3,8(sp)
ffffffffc020189e:	e84a                	sd	s2,16(sp)
ffffffffc02018a0:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02018a2:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02018a4:	875fe0ef          	jal	ra,ffffffffc0200118 <cprintf>
    pmm_manager->init();
ffffffffc02018a8:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02018aa:	00006497          	auipc	s1,0x6
ffffffffc02018ae:	bde48493          	addi	s1,s1,-1058 # ffffffffc0207488 <va_pa_offset>
    pmm_manager->init();
ffffffffc02018b2:	679c                	ld	a5,8(a5)
ffffffffc02018b4:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02018b6:	57f5                	li	a5,-3
ffffffffc02018b8:	07fa                	slli	a5,a5,0x1e
ffffffffc02018ba:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02018bc:	f9ffe0ef          	jal	ra,ffffffffc020085a <get_memory_base>
ffffffffc02018c0:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02018c2:	fa3fe0ef          	jal	ra,ffffffffc0200864 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02018c6:	16050163          	beqz	a0,ffffffffc0201a28 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02018ca:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc02018cc:	00001517          	auipc	a0,0x1
ffffffffc02018d0:	58450513          	addi	a0,a0,1412 # ffffffffc0202e50 <default_pmm_manager+0x80>
ffffffffc02018d4:	845fe0ef          	jal	ra,ffffffffc0200118 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02018d8:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02018dc:	864e                	mv	a2,s3
ffffffffc02018de:	fffa0693          	addi	a3,s4,-1
ffffffffc02018e2:	85ca                	mv	a1,s2
ffffffffc02018e4:	00001517          	auipc	a0,0x1
ffffffffc02018e8:	58450513          	addi	a0,a0,1412 # ffffffffc0202e68 <default_pmm_manager+0x98>
ffffffffc02018ec:	82dfe0ef          	jal	ra,ffffffffc0200118 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02018f0:	c80007b7          	lui	a5,0xc8000
ffffffffc02018f4:	8652                	mv	a2,s4
ffffffffc02018f6:	0d47e863          	bltu	a5,s4,ffffffffc02019c6 <pmm_init+0x14c>
ffffffffc02018fa:	00007797          	auipc	a5,0x7
ffffffffc02018fe:	b9d78793          	addi	a5,a5,-1123 # ffffffffc0208497 <end+0xfff>
ffffffffc0201902:	757d                	lui	a0,0xfffff
ffffffffc0201904:	8d7d                	and	a0,a0,a5
ffffffffc0201906:	8231                	srli	a2,a2,0xc
ffffffffc0201908:	00006597          	auipc	a1,0x6
ffffffffc020190c:	b5858593          	addi	a1,a1,-1192 # ffffffffc0207460 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201910:	00006817          	auipc	a6,0x6
ffffffffc0201914:	b5880813          	addi	a6,a6,-1192 # ffffffffc0207468 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201918:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020191a:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020191e:	000807b7          	lui	a5,0x80
ffffffffc0201922:	02f60663          	beq	a2,a5,ffffffffc020194e <pmm_init+0xd4>
ffffffffc0201926:	4701                	li	a4,0
ffffffffc0201928:	4781                	li	a5,0
ffffffffc020192a:	4305                	li	t1,1
ffffffffc020192c:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201930:	953a                	add	a0,a0,a4
ffffffffc0201932:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf7b70>
ffffffffc0201936:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020193a:	6190                	ld	a2,0(a1)
ffffffffc020193c:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc020193e:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201942:	011606b3          	add	a3,a2,a7
ffffffffc0201946:	02870713          	addi	a4,a4,40
ffffffffc020194a:	fed7e3e3          	bltu	a5,a3,ffffffffc0201930 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020194e:	00261693          	slli	a3,a2,0x2
ffffffffc0201952:	96b2                	add	a3,a3,a2
ffffffffc0201954:	fec007b7          	lui	a5,0xfec00
ffffffffc0201958:	97aa                	add	a5,a5,a0
ffffffffc020195a:	068e                	slli	a3,a3,0x3
ffffffffc020195c:	96be                	add	a3,a3,a5
ffffffffc020195e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201962:	0af6e763          	bltu	a3,a5,ffffffffc0201a10 <pmm_init+0x196>
ffffffffc0201966:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201968:	77fd                	lui	a5,0xfffff
ffffffffc020196a:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020196e:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201970:	04b6ee63          	bltu	a3,a1,ffffffffc02019cc <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201974:	601c                	ld	a5,0(s0)
ffffffffc0201976:	7b9c                	ld	a5,48(a5)
ffffffffc0201978:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020197a:	00001517          	auipc	a0,0x1
ffffffffc020197e:	57650513          	addi	a0,a0,1398 # ffffffffc0202ef0 <default_pmm_manager+0x120>
ffffffffc0201982:	f96fe0ef          	jal	ra,ffffffffc0200118 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201986:	00004597          	auipc	a1,0x4
ffffffffc020198a:	67a58593          	addi	a1,a1,1658 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc020198e:	00006797          	auipc	a5,0x6
ffffffffc0201992:	aeb7b923          	sd	a1,-1294(a5) # ffffffffc0207480 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201996:	c02007b7          	lui	a5,0xc0200
ffffffffc020199a:	0af5e363          	bltu	a1,a5,ffffffffc0201a40 <pmm_init+0x1c6>
ffffffffc020199e:	6090                	ld	a2,0(s1)
}
ffffffffc02019a0:	7402                	ld	s0,32(sp)
ffffffffc02019a2:	70a2                	ld	ra,40(sp)
ffffffffc02019a4:	64e2                	ld	s1,24(sp)
ffffffffc02019a6:	6942                	ld	s2,16(sp)
ffffffffc02019a8:	69a2                	ld	s3,8(sp)
ffffffffc02019aa:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02019ac:	40c58633          	sub	a2,a1,a2
ffffffffc02019b0:	00006797          	auipc	a5,0x6
ffffffffc02019b4:	acc7b423          	sd	a2,-1336(a5) # ffffffffc0207478 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02019b8:	00001517          	auipc	a0,0x1
ffffffffc02019bc:	55850513          	addi	a0,a0,1368 # ffffffffc0202f10 <default_pmm_manager+0x140>
}
ffffffffc02019c0:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02019c2:	f56fe06f          	j	ffffffffc0200118 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02019c6:	c8000637          	lui	a2,0xc8000
ffffffffc02019ca:	bf05                	j	ffffffffc02018fa <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02019cc:	6705                	lui	a4,0x1
ffffffffc02019ce:	177d                	addi	a4,a4,-1
ffffffffc02019d0:	96ba                	add	a3,a3,a4
ffffffffc02019d2:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02019d4:	00c6d793          	srli	a5,a3,0xc
ffffffffc02019d8:	02c7f063          	bgeu	a5,a2,ffffffffc02019f8 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc02019dc:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02019de:	fff80737          	lui	a4,0xfff80
ffffffffc02019e2:	973e                	add	a4,a4,a5
ffffffffc02019e4:	00271793          	slli	a5,a4,0x2
ffffffffc02019e8:	97ba                	add	a5,a5,a4
ffffffffc02019ea:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02019ec:	8d95                	sub	a1,a1,a3
ffffffffc02019ee:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02019f0:	81b1                	srli	a1,a1,0xc
ffffffffc02019f2:	953e                	add	a0,a0,a5
ffffffffc02019f4:	9702                	jalr	a4
}
ffffffffc02019f6:	bfbd                	j	ffffffffc0201974 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc02019f8:	00001617          	auipc	a2,0x1
ffffffffc02019fc:	4c860613          	addi	a2,a2,1224 # ffffffffc0202ec0 <default_pmm_manager+0xf0>
ffffffffc0201a00:	06b00593          	li	a1,107
ffffffffc0201a04:	00001517          	auipc	a0,0x1
ffffffffc0201a08:	4dc50513          	addi	a0,a0,1244 # ffffffffc0202ee0 <default_pmm_manager+0x110>
ffffffffc0201a0c:	a07fe0ef          	jal	ra,ffffffffc0200412 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201a10:	00001617          	auipc	a2,0x1
ffffffffc0201a14:	48860613          	addi	a2,a2,1160 # ffffffffc0202e98 <default_pmm_manager+0xc8>
ffffffffc0201a18:	07100593          	li	a1,113
ffffffffc0201a1c:	00001517          	auipc	a0,0x1
ffffffffc0201a20:	42450513          	addi	a0,a0,1060 # ffffffffc0202e40 <default_pmm_manager+0x70>
ffffffffc0201a24:	9effe0ef          	jal	ra,ffffffffc0200412 <__panic>
        panic("DTB memory info not available");
ffffffffc0201a28:	00001617          	auipc	a2,0x1
ffffffffc0201a2c:	3f860613          	addi	a2,a2,1016 # ffffffffc0202e20 <default_pmm_manager+0x50>
ffffffffc0201a30:	05a00593          	li	a1,90
ffffffffc0201a34:	00001517          	auipc	a0,0x1
ffffffffc0201a38:	40c50513          	addi	a0,a0,1036 # ffffffffc0202e40 <default_pmm_manager+0x70>
ffffffffc0201a3c:	9d7fe0ef          	jal	ra,ffffffffc0200412 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201a40:	86ae                	mv	a3,a1
ffffffffc0201a42:	00001617          	auipc	a2,0x1
ffffffffc0201a46:	45660613          	addi	a2,a2,1110 # ffffffffc0202e98 <default_pmm_manager+0xc8>
ffffffffc0201a4a:	08c00593          	li	a1,140
ffffffffc0201a4e:	00001517          	auipc	a0,0x1
ffffffffc0201a52:	3f250513          	addi	a0,a0,1010 # ffffffffc0202e40 <default_pmm_manager+0x70>
ffffffffc0201a56:	9bdfe0ef          	jal	ra,ffffffffc0200412 <__panic>

ffffffffc0201a5a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201a5a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a5e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201a60:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a64:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201a66:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a6a:	f022                	sd	s0,32(sp)
ffffffffc0201a6c:	ec26                	sd	s1,24(sp)
ffffffffc0201a6e:	e84a                	sd	s2,16(sp)
ffffffffc0201a70:	f406                	sd	ra,40(sp)
ffffffffc0201a72:	e44e                	sd	s3,8(sp)
ffffffffc0201a74:	84aa                	mv	s1,a0
ffffffffc0201a76:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a78:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201a7c:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201a7e:	03067e63          	bgeu	a2,a6,ffffffffc0201aba <printnum+0x60>
ffffffffc0201a82:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a84:	00805763          	blez	s0,ffffffffc0201a92 <printnum+0x38>
ffffffffc0201a88:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a8a:	85ca                	mv	a1,s2
ffffffffc0201a8c:	854e                	mv	a0,s3
ffffffffc0201a8e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a90:	fc65                	bnez	s0,ffffffffc0201a88 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a92:	1a02                	slli	s4,s4,0x20
ffffffffc0201a94:	00001797          	auipc	a5,0x1
ffffffffc0201a98:	4bc78793          	addi	a5,a5,1212 # ffffffffc0202f50 <default_pmm_manager+0x180>
ffffffffc0201a9c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201aa0:	9a3e                	add	s4,s4,a5
}
ffffffffc0201aa2:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201aa4:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201aa8:	70a2                	ld	ra,40(sp)
ffffffffc0201aaa:	69a2                	ld	s3,8(sp)
ffffffffc0201aac:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201aae:	85ca                	mv	a1,s2
ffffffffc0201ab0:	87a6                	mv	a5,s1
}
ffffffffc0201ab2:	6942                	ld	s2,16(sp)
ffffffffc0201ab4:	64e2                	ld	s1,24(sp)
ffffffffc0201ab6:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201ab8:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201aba:	03065633          	divu	a2,a2,a6
ffffffffc0201abe:	8722                	mv	a4,s0
ffffffffc0201ac0:	f9bff0ef          	jal	ra,ffffffffc0201a5a <printnum>
ffffffffc0201ac4:	b7f9                	j	ffffffffc0201a92 <printnum+0x38>

ffffffffc0201ac6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201ac6:	7119                	addi	sp,sp,-128
ffffffffc0201ac8:	f4a6                	sd	s1,104(sp)
ffffffffc0201aca:	f0ca                	sd	s2,96(sp)
ffffffffc0201acc:	ecce                	sd	s3,88(sp)
ffffffffc0201ace:	e8d2                	sd	s4,80(sp)
ffffffffc0201ad0:	e4d6                	sd	s5,72(sp)
ffffffffc0201ad2:	e0da                	sd	s6,64(sp)
ffffffffc0201ad4:	fc5e                	sd	s7,56(sp)
ffffffffc0201ad6:	f06a                	sd	s10,32(sp)
ffffffffc0201ad8:	fc86                	sd	ra,120(sp)
ffffffffc0201ada:	f8a2                	sd	s0,112(sp)
ffffffffc0201adc:	f862                	sd	s8,48(sp)
ffffffffc0201ade:	f466                	sd	s9,40(sp)
ffffffffc0201ae0:	ec6e                	sd	s11,24(sp)
ffffffffc0201ae2:	892a                	mv	s2,a0
ffffffffc0201ae4:	84ae                	mv	s1,a1
ffffffffc0201ae6:	8d32                	mv	s10,a2
ffffffffc0201ae8:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201aea:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201aee:	5b7d                	li	s6,-1
ffffffffc0201af0:	00001a97          	auipc	s5,0x1
ffffffffc0201af4:	494a8a93          	addi	s5,s5,1172 # ffffffffc0202f84 <default_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201af8:	00001b97          	auipc	s7,0x1
ffffffffc0201afc:	668b8b93          	addi	s7,s7,1640 # ffffffffc0203160 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b00:	000d4503          	lbu	a0,0(s10)
ffffffffc0201b04:	001d0413          	addi	s0,s10,1
ffffffffc0201b08:	01350a63          	beq	a0,s3,ffffffffc0201b1c <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201b0c:	c121                	beqz	a0,ffffffffc0201b4c <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201b0e:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b10:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201b12:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b14:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201b18:	ff351ae3          	bne	a0,s3,ffffffffc0201b0c <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b1c:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201b20:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201b24:	4c81                	li	s9,0
ffffffffc0201b26:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201b28:	5c7d                	li	s8,-1
ffffffffc0201b2a:	5dfd                	li	s11,-1
ffffffffc0201b2c:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201b30:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b32:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b36:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b3a:	00140d13          	addi	s10,s0,1
ffffffffc0201b3e:	04b56263          	bltu	a0,a1,ffffffffc0201b82 <vprintfmt+0xbc>
ffffffffc0201b42:	058a                	slli	a1,a1,0x2
ffffffffc0201b44:	95d6                	add	a1,a1,s5
ffffffffc0201b46:	4194                	lw	a3,0(a1)
ffffffffc0201b48:	96d6                	add	a3,a3,s5
ffffffffc0201b4a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201b4c:	70e6                	ld	ra,120(sp)
ffffffffc0201b4e:	7446                	ld	s0,112(sp)
ffffffffc0201b50:	74a6                	ld	s1,104(sp)
ffffffffc0201b52:	7906                	ld	s2,96(sp)
ffffffffc0201b54:	69e6                	ld	s3,88(sp)
ffffffffc0201b56:	6a46                	ld	s4,80(sp)
ffffffffc0201b58:	6aa6                	ld	s5,72(sp)
ffffffffc0201b5a:	6b06                	ld	s6,64(sp)
ffffffffc0201b5c:	7be2                	ld	s7,56(sp)
ffffffffc0201b5e:	7c42                	ld	s8,48(sp)
ffffffffc0201b60:	7ca2                	ld	s9,40(sp)
ffffffffc0201b62:	7d02                	ld	s10,32(sp)
ffffffffc0201b64:	6de2                	ld	s11,24(sp)
ffffffffc0201b66:	6109                	addi	sp,sp,128
ffffffffc0201b68:	8082                	ret
            padc = '0';
ffffffffc0201b6a:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201b6c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b70:	846a                	mv	s0,s10
ffffffffc0201b72:	00140d13          	addi	s10,s0,1
ffffffffc0201b76:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b7a:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b7e:	fcb572e3          	bgeu	a0,a1,ffffffffc0201b42 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201b82:	85a6                	mv	a1,s1
ffffffffc0201b84:	02500513          	li	a0,37
ffffffffc0201b88:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b8a:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b8e:	8d22                	mv	s10,s0
ffffffffc0201b90:	f73788e3          	beq	a5,s3,ffffffffc0201b00 <vprintfmt+0x3a>
ffffffffc0201b94:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201b98:	1d7d                	addi	s10,s10,-1
ffffffffc0201b9a:	ff379de3          	bne	a5,s3,ffffffffc0201b94 <vprintfmt+0xce>
ffffffffc0201b9e:	b78d                	j	ffffffffc0201b00 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201ba0:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201ba4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ba8:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201baa:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201bae:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201bb2:	02d86463          	bltu	a6,a3,ffffffffc0201bda <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201bb6:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201bba:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201bbe:	0186873b          	addw	a4,a3,s8
ffffffffc0201bc2:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201bc6:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201bc8:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201bcc:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201bce:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201bd2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201bd6:	fed870e3          	bgeu	a6,a3,ffffffffc0201bb6 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201bda:	f40ddce3          	bgez	s11,ffffffffc0201b32 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201bde:	8de2                	mv	s11,s8
ffffffffc0201be0:	5c7d                	li	s8,-1
ffffffffc0201be2:	bf81                	j	ffffffffc0201b32 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201be4:	fffdc693          	not	a3,s11
ffffffffc0201be8:	96fd                	srai	a3,a3,0x3f
ffffffffc0201bea:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bee:	00144603          	lbu	a2,1(s0)
ffffffffc0201bf2:	2d81                	sext.w	s11,s11
ffffffffc0201bf4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201bf6:	bf35                	j	ffffffffc0201b32 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201bf8:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bfc:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201c00:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c02:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201c04:	bfd9                	j	ffffffffc0201bda <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201c06:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c08:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c0c:	01174463          	blt	a4,a7,ffffffffc0201c14 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201c10:	1a088e63          	beqz	a7,ffffffffc0201dcc <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201c14:	000a3603          	ld	a2,0(s4)
ffffffffc0201c18:	46c1                	li	a3,16
ffffffffc0201c1a:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201c1c:	2781                	sext.w	a5,a5
ffffffffc0201c1e:	876e                	mv	a4,s11
ffffffffc0201c20:	85a6                	mv	a1,s1
ffffffffc0201c22:	854a                	mv	a0,s2
ffffffffc0201c24:	e37ff0ef          	jal	ra,ffffffffc0201a5a <printnum>
            break;
ffffffffc0201c28:	bde1                	j	ffffffffc0201b00 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201c2a:	000a2503          	lw	a0,0(s4)
ffffffffc0201c2e:	85a6                	mv	a1,s1
ffffffffc0201c30:	0a21                	addi	s4,s4,8
ffffffffc0201c32:	9902                	jalr	s2
            break;
ffffffffc0201c34:	b5f1                	j	ffffffffc0201b00 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c36:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c38:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c3c:	01174463          	blt	a4,a7,ffffffffc0201c44 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201c40:	18088163          	beqz	a7,ffffffffc0201dc2 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201c44:	000a3603          	ld	a2,0(s4)
ffffffffc0201c48:	46a9                	li	a3,10
ffffffffc0201c4a:	8a2e                	mv	s4,a1
ffffffffc0201c4c:	bfc1                	j	ffffffffc0201c1c <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c4e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201c52:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c54:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c56:	bdf1                	j	ffffffffc0201b32 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201c58:	85a6                	mv	a1,s1
ffffffffc0201c5a:	02500513          	li	a0,37
ffffffffc0201c5e:	9902                	jalr	s2
            break;
ffffffffc0201c60:	b545                	j	ffffffffc0201b00 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c62:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201c66:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c68:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c6a:	b5e1                	j	ffffffffc0201b32 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201c6c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c6e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c72:	01174463          	blt	a4,a7,ffffffffc0201c7a <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201c76:	14088163          	beqz	a7,ffffffffc0201db8 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201c7a:	000a3603          	ld	a2,0(s4)
ffffffffc0201c7e:	46a1                	li	a3,8
ffffffffc0201c80:	8a2e                	mv	s4,a1
ffffffffc0201c82:	bf69                	j	ffffffffc0201c1c <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201c84:	03000513          	li	a0,48
ffffffffc0201c88:	85a6                	mv	a1,s1
ffffffffc0201c8a:	e03e                	sd	a5,0(sp)
ffffffffc0201c8c:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c8e:	85a6                	mv	a1,s1
ffffffffc0201c90:	07800513          	li	a0,120
ffffffffc0201c94:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c96:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201c98:	6782                	ld	a5,0(sp)
ffffffffc0201c9a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c9c:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201ca0:	bfb5                	j	ffffffffc0201c1c <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201ca2:	000a3403          	ld	s0,0(s4)
ffffffffc0201ca6:	008a0713          	addi	a4,s4,8
ffffffffc0201caa:	e03a                	sd	a4,0(sp)
ffffffffc0201cac:	14040263          	beqz	s0,ffffffffc0201df0 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201cb0:	0fb05763          	blez	s11,ffffffffc0201d9e <vprintfmt+0x2d8>
ffffffffc0201cb4:	02d00693          	li	a3,45
ffffffffc0201cb8:	0cd79163          	bne	a5,a3,ffffffffc0201d7a <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cbc:	00044783          	lbu	a5,0(s0)
ffffffffc0201cc0:	0007851b          	sext.w	a0,a5
ffffffffc0201cc4:	cf85                	beqz	a5,ffffffffc0201cfc <vprintfmt+0x236>
ffffffffc0201cc6:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cca:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cce:	000c4563          	bltz	s8,ffffffffc0201cd8 <vprintfmt+0x212>
ffffffffc0201cd2:	3c7d                	addiw	s8,s8,-1
ffffffffc0201cd4:	036c0263          	beq	s8,s6,ffffffffc0201cf8 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201cd8:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cda:	0e0c8e63          	beqz	s9,ffffffffc0201dd6 <vprintfmt+0x310>
ffffffffc0201cde:	3781                	addiw	a5,a5,-32
ffffffffc0201ce0:	0ef47b63          	bgeu	s0,a5,ffffffffc0201dd6 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201ce4:	03f00513          	li	a0,63
ffffffffc0201ce8:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cea:	000a4783          	lbu	a5,0(s4)
ffffffffc0201cee:	3dfd                	addiw	s11,s11,-1
ffffffffc0201cf0:	0a05                	addi	s4,s4,1
ffffffffc0201cf2:	0007851b          	sext.w	a0,a5
ffffffffc0201cf6:	ffe1                	bnez	a5,ffffffffc0201cce <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201cf8:	01b05963          	blez	s11,ffffffffc0201d0a <vprintfmt+0x244>
ffffffffc0201cfc:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201cfe:	85a6                	mv	a1,s1
ffffffffc0201d00:	02000513          	li	a0,32
ffffffffc0201d04:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201d06:	fe0d9be3          	bnez	s11,ffffffffc0201cfc <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d0a:	6a02                	ld	s4,0(sp)
ffffffffc0201d0c:	bbd5                	j	ffffffffc0201b00 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201d0e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201d10:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201d14:	01174463          	blt	a4,a7,ffffffffc0201d1c <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201d18:	08088d63          	beqz	a7,ffffffffc0201db2 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201d1c:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201d20:	0a044d63          	bltz	s0,ffffffffc0201dda <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201d24:	8622                	mv	a2,s0
ffffffffc0201d26:	8a66                	mv	s4,s9
ffffffffc0201d28:	46a9                	li	a3,10
ffffffffc0201d2a:	bdcd                	j	ffffffffc0201c1c <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201d2c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d30:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201d32:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201d34:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201d38:	8fb5                	xor	a5,a5,a3
ffffffffc0201d3a:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d3e:	02d74163          	blt	a4,a3,ffffffffc0201d60 <vprintfmt+0x29a>
ffffffffc0201d42:	00369793          	slli	a5,a3,0x3
ffffffffc0201d46:	97de                	add	a5,a5,s7
ffffffffc0201d48:	639c                	ld	a5,0(a5)
ffffffffc0201d4a:	cb99                	beqz	a5,ffffffffc0201d60 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201d4c:	86be                	mv	a3,a5
ffffffffc0201d4e:	00001617          	auipc	a2,0x1
ffffffffc0201d52:	23260613          	addi	a2,a2,562 # ffffffffc0202f80 <default_pmm_manager+0x1b0>
ffffffffc0201d56:	85a6                	mv	a1,s1
ffffffffc0201d58:	854a                	mv	a0,s2
ffffffffc0201d5a:	0ce000ef          	jal	ra,ffffffffc0201e28 <printfmt>
ffffffffc0201d5e:	b34d                	j	ffffffffc0201b00 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201d60:	00001617          	auipc	a2,0x1
ffffffffc0201d64:	21060613          	addi	a2,a2,528 # ffffffffc0202f70 <default_pmm_manager+0x1a0>
ffffffffc0201d68:	85a6                	mv	a1,s1
ffffffffc0201d6a:	854a                	mv	a0,s2
ffffffffc0201d6c:	0bc000ef          	jal	ra,ffffffffc0201e28 <printfmt>
ffffffffc0201d70:	bb41                	j	ffffffffc0201b00 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201d72:	00001417          	auipc	s0,0x1
ffffffffc0201d76:	1f640413          	addi	s0,s0,502 # ffffffffc0202f68 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d7a:	85e2                	mv	a1,s8
ffffffffc0201d7c:	8522                	mv	a0,s0
ffffffffc0201d7e:	e43e                	sd	a5,8(sp)
ffffffffc0201d80:	200000ef          	jal	ra,ffffffffc0201f80 <strnlen>
ffffffffc0201d84:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201d88:	01b05b63          	blez	s11,ffffffffc0201d9e <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201d8c:	67a2                	ld	a5,8(sp)
ffffffffc0201d8e:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d92:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201d94:	85a6                	mv	a1,s1
ffffffffc0201d96:	8552                	mv	a0,s4
ffffffffc0201d98:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d9a:	fe0d9ce3          	bnez	s11,ffffffffc0201d92 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d9e:	00044783          	lbu	a5,0(s0)
ffffffffc0201da2:	00140a13          	addi	s4,s0,1
ffffffffc0201da6:	0007851b          	sext.w	a0,a5
ffffffffc0201daa:	d3a5                	beqz	a5,ffffffffc0201d0a <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201dac:	05e00413          	li	s0,94
ffffffffc0201db0:	bf39                	j	ffffffffc0201cce <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201db2:	000a2403          	lw	s0,0(s4)
ffffffffc0201db6:	b7ad                	j	ffffffffc0201d20 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201db8:	000a6603          	lwu	a2,0(s4)
ffffffffc0201dbc:	46a1                	li	a3,8
ffffffffc0201dbe:	8a2e                	mv	s4,a1
ffffffffc0201dc0:	bdb1                	j	ffffffffc0201c1c <vprintfmt+0x156>
ffffffffc0201dc2:	000a6603          	lwu	a2,0(s4)
ffffffffc0201dc6:	46a9                	li	a3,10
ffffffffc0201dc8:	8a2e                	mv	s4,a1
ffffffffc0201dca:	bd89                	j	ffffffffc0201c1c <vprintfmt+0x156>
ffffffffc0201dcc:	000a6603          	lwu	a2,0(s4)
ffffffffc0201dd0:	46c1                	li	a3,16
ffffffffc0201dd2:	8a2e                	mv	s4,a1
ffffffffc0201dd4:	b5a1                	j	ffffffffc0201c1c <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201dd6:	9902                	jalr	s2
ffffffffc0201dd8:	bf09                	j	ffffffffc0201cea <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201dda:	85a6                	mv	a1,s1
ffffffffc0201ddc:	02d00513          	li	a0,45
ffffffffc0201de0:	e03e                	sd	a5,0(sp)
ffffffffc0201de2:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201de4:	6782                	ld	a5,0(sp)
ffffffffc0201de6:	8a66                	mv	s4,s9
ffffffffc0201de8:	40800633          	neg	a2,s0
ffffffffc0201dec:	46a9                	li	a3,10
ffffffffc0201dee:	b53d                	j	ffffffffc0201c1c <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201df0:	03b05163          	blez	s11,ffffffffc0201e12 <vprintfmt+0x34c>
ffffffffc0201df4:	02d00693          	li	a3,45
ffffffffc0201df8:	f6d79de3          	bne	a5,a3,ffffffffc0201d72 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201dfc:	00001417          	auipc	s0,0x1
ffffffffc0201e00:	16c40413          	addi	s0,s0,364 # ffffffffc0202f68 <default_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e04:	02800793          	li	a5,40
ffffffffc0201e08:	02800513          	li	a0,40
ffffffffc0201e0c:	00140a13          	addi	s4,s0,1
ffffffffc0201e10:	bd6d                	j	ffffffffc0201cca <vprintfmt+0x204>
ffffffffc0201e12:	00001a17          	auipc	s4,0x1
ffffffffc0201e16:	157a0a13          	addi	s4,s4,343 # ffffffffc0202f69 <default_pmm_manager+0x199>
ffffffffc0201e1a:	02800513          	li	a0,40
ffffffffc0201e1e:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e22:	05e00413          	li	s0,94
ffffffffc0201e26:	b565                	j	ffffffffc0201cce <vprintfmt+0x208>

ffffffffc0201e28 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e28:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201e2a:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e2e:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e30:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e32:	ec06                	sd	ra,24(sp)
ffffffffc0201e34:	f83a                	sd	a4,48(sp)
ffffffffc0201e36:	fc3e                	sd	a5,56(sp)
ffffffffc0201e38:	e0c2                	sd	a6,64(sp)
ffffffffc0201e3a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201e3c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e3e:	c89ff0ef          	jal	ra,ffffffffc0201ac6 <vprintfmt>
}
ffffffffc0201e42:	60e2                	ld	ra,24(sp)
ffffffffc0201e44:	6161                	addi	sp,sp,80
ffffffffc0201e46:	8082                	ret

ffffffffc0201e48 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201e48:	715d                	addi	sp,sp,-80
ffffffffc0201e4a:	e486                	sd	ra,72(sp)
ffffffffc0201e4c:	e0a6                	sd	s1,64(sp)
ffffffffc0201e4e:	fc4a                	sd	s2,56(sp)
ffffffffc0201e50:	f84e                	sd	s3,48(sp)
ffffffffc0201e52:	f452                	sd	s4,40(sp)
ffffffffc0201e54:	f056                	sd	s5,32(sp)
ffffffffc0201e56:	ec5a                	sd	s6,24(sp)
ffffffffc0201e58:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201e5a:	c901                	beqz	a0,ffffffffc0201e6a <readline+0x22>
ffffffffc0201e5c:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201e5e:	00001517          	auipc	a0,0x1
ffffffffc0201e62:	12250513          	addi	a0,a0,290 # ffffffffc0202f80 <default_pmm_manager+0x1b0>
ffffffffc0201e66:	ab2fe0ef          	jal	ra,ffffffffc0200118 <cprintf>
readline(const char *prompt) {
ffffffffc0201e6a:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e6c:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201e6e:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201e70:	4aa9                	li	s5,10
ffffffffc0201e72:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201e74:	00005b97          	auipc	s7,0x5
ffffffffc0201e78:	1ccb8b93          	addi	s7,s7,460 # ffffffffc0207040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e7c:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201e80:	b10fe0ef          	jal	ra,ffffffffc0200190 <getchar>
        if (c < 0) {
ffffffffc0201e84:	00054a63          	bltz	a0,ffffffffc0201e98 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e88:	00a95a63          	bge	s2,a0,ffffffffc0201e9c <readline+0x54>
ffffffffc0201e8c:	029a5263          	bge	s4,s1,ffffffffc0201eb0 <readline+0x68>
        c = getchar();
ffffffffc0201e90:	b00fe0ef          	jal	ra,ffffffffc0200190 <getchar>
        if (c < 0) {
ffffffffc0201e94:	fe055ae3          	bgez	a0,ffffffffc0201e88 <readline+0x40>
            return NULL;
ffffffffc0201e98:	4501                	li	a0,0
ffffffffc0201e9a:	a091                	j	ffffffffc0201ede <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201e9c:	03351463          	bne	a0,s3,ffffffffc0201ec4 <readline+0x7c>
ffffffffc0201ea0:	e8a9                	bnez	s1,ffffffffc0201ef2 <readline+0xaa>
        c = getchar();
ffffffffc0201ea2:	aeefe0ef          	jal	ra,ffffffffc0200190 <getchar>
        if (c < 0) {
ffffffffc0201ea6:	fe0549e3          	bltz	a0,ffffffffc0201e98 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201eaa:	fea959e3          	bge	s2,a0,ffffffffc0201e9c <readline+0x54>
ffffffffc0201eae:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201eb0:	e42a                	sd	a0,8(sp)
ffffffffc0201eb2:	a9cfe0ef          	jal	ra,ffffffffc020014e <cputchar>
            buf[i ++] = c;
ffffffffc0201eb6:	6522                	ld	a0,8(sp)
ffffffffc0201eb8:	009b87b3          	add	a5,s7,s1
ffffffffc0201ebc:	2485                	addiw	s1,s1,1
ffffffffc0201ebe:	00a78023          	sb	a0,0(a5)
ffffffffc0201ec2:	bf7d                	j	ffffffffc0201e80 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201ec4:	01550463          	beq	a0,s5,ffffffffc0201ecc <readline+0x84>
ffffffffc0201ec8:	fb651ce3          	bne	a0,s6,ffffffffc0201e80 <readline+0x38>
            cputchar(c);
ffffffffc0201ecc:	a82fe0ef          	jal	ra,ffffffffc020014e <cputchar>
            buf[i] = '\0';
ffffffffc0201ed0:	00005517          	auipc	a0,0x5
ffffffffc0201ed4:	17050513          	addi	a0,a0,368 # ffffffffc0207040 <buf>
ffffffffc0201ed8:	94aa                	add	s1,s1,a0
ffffffffc0201eda:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201ede:	60a6                	ld	ra,72(sp)
ffffffffc0201ee0:	6486                	ld	s1,64(sp)
ffffffffc0201ee2:	7962                	ld	s2,56(sp)
ffffffffc0201ee4:	79c2                	ld	s3,48(sp)
ffffffffc0201ee6:	7a22                	ld	s4,40(sp)
ffffffffc0201ee8:	7a82                	ld	s5,32(sp)
ffffffffc0201eea:	6b62                	ld	s6,24(sp)
ffffffffc0201eec:	6bc2                	ld	s7,16(sp)
ffffffffc0201eee:	6161                	addi	sp,sp,80
ffffffffc0201ef0:	8082                	ret
            cputchar(c);
ffffffffc0201ef2:	4521                	li	a0,8
ffffffffc0201ef4:	a5afe0ef          	jal	ra,ffffffffc020014e <cputchar>
            i --;
ffffffffc0201ef8:	34fd                	addiw	s1,s1,-1
ffffffffc0201efa:	b759                	j	ffffffffc0201e80 <readline+0x38>

ffffffffc0201efc <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201efc:	4781                	li	a5,0
ffffffffc0201efe:	00005717          	auipc	a4,0x5
ffffffffc0201f02:	11a73703          	ld	a4,282(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201f06:	88ba                	mv	a7,a4
ffffffffc0201f08:	852a                	mv	a0,a0
ffffffffc0201f0a:	85be                	mv	a1,a5
ffffffffc0201f0c:	863e                	mv	a2,a5
ffffffffc0201f0e:	00000073          	ecall
ffffffffc0201f12:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201f14:	8082                	ret

ffffffffc0201f16 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201f16:	4781                	li	a5,0
ffffffffc0201f18:	00005717          	auipc	a4,0x5
ffffffffc0201f1c:	57873703          	ld	a4,1400(a4) # ffffffffc0207490 <SBI_SET_TIMER>
ffffffffc0201f20:	88ba                	mv	a7,a4
ffffffffc0201f22:	852a                	mv	a0,a0
ffffffffc0201f24:	85be                	mv	a1,a5
ffffffffc0201f26:	863e                	mv	a2,a5
ffffffffc0201f28:	00000073          	ecall
ffffffffc0201f2c:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201f2e:	8082                	ret

ffffffffc0201f30 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201f30:	4501                	li	a0,0
ffffffffc0201f32:	00005797          	auipc	a5,0x5
ffffffffc0201f36:	0de7b783          	ld	a5,222(a5) # ffffffffc0207010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201f3a:	88be                	mv	a7,a5
ffffffffc0201f3c:	852a                	mv	a0,a0
ffffffffc0201f3e:	85aa                	mv	a1,a0
ffffffffc0201f40:	862a                	mv	a2,a0
ffffffffc0201f42:	00000073          	ecall
ffffffffc0201f46:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201f48:	2501                	sext.w	a0,a0
ffffffffc0201f4a:	8082                	ret

ffffffffc0201f4c <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201f4c:	4781                	li	a5,0
ffffffffc0201f4e:	00005717          	auipc	a4,0x5
ffffffffc0201f52:	0d273703          	ld	a4,210(a4) # ffffffffc0207020 <SBI_SHUTDOWN>
ffffffffc0201f56:	88ba                	mv	a7,a4
ffffffffc0201f58:	853e                	mv	a0,a5
ffffffffc0201f5a:	85be                	mv	a1,a5
ffffffffc0201f5c:	863e                	mv	a2,a5
ffffffffc0201f5e:	00000073          	ecall
ffffffffc0201f62:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201f64:	8082                	ret

ffffffffc0201f66 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201f66:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201f6a:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201f6c:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201f6e:	cb81                	beqz	a5,ffffffffc0201f7e <strlen+0x18>
        cnt ++;
ffffffffc0201f70:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201f72:	00a707b3          	add	a5,a4,a0
ffffffffc0201f76:	0007c783          	lbu	a5,0(a5)
ffffffffc0201f7a:	fbfd                	bnez	a5,ffffffffc0201f70 <strlen+0xa>
ffffffffc0201f7c:	8082                	ret
    }
    return cnt;
}
ffffffffc0201f7e:	8082                	ret

ffffffffc0201f80 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201f80:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f82:	e589                	bnez	a1,ffffffffc0201f8c <strnlen+0xc>
ffffffffc0201f84:	a811                	j	ffffffffc0201f98 <strnlen+0x18>
        cnt ++;
ffffffffc0201f86:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f88:	00f58863          	beq	a1,a5,ffffffffc0201f98 <strnlen+0x18>
ffffffffc0201f8c:	00f50733          	add	a4,a0,a5
ffffffffc0201f90:	00074703          	lbu	a4,0(a4)
ffffffffc0201f94:	fb6d                	bnez	a4,ffffffffc0201f86 <strnlen+0x6>
ffffffffc0201f96:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201f98:	852e                	mv	a0,a1
ffffffffc0201f9a:	8082                	ret

ffffffffc0201f9c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f9c:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fa0:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201fa4:	cb89                	beqz	a5,ffffffffc0201fb6 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201fa6:	0505                	addi	a0,a0,1
ffffffffc0201fa8:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201faa:	fee789e3          	beq	a5,a4,ffffffffc0201f9c <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fae:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201fb2:	9d19                	subw	a0,a0,a4
ffffffffc0201fb4:	8082                	ret
ffffffffc0201fb6:	4501                	li	a0,0
ffffffffc0201fb8:	bfed                	j	ffffffffc0201fb2 <strcmp+0x16>

ffffffffc0201fba <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fba:	c20d                	beqz	a2,ffffffffc0201fdc <strncmp+0x22>
ffffffffc0201fbc:	962e                	add	a2,a2,a1
ffffffffc0201fbe:	a031                	j	ffffffffc0201fca <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201fc0:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fc2:	00e79a63          	bne	a5,a4,ffffffffc0201fd6 <strncmp+0x1c>
ffffffffc0201fc6:	00b60b63          	beq	a2,a1,ffffffffc0201fdc <strncmp+0x22>
ffffffffc0201fca:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201fce:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fd0:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201fd4:	f7f5                	bnez	a5,ffffffffc0201fc0 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fd6:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201fda:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fdc:	4501                	li	a0,0
ffffffffc0201fde:	8082                	ret

ffffffffc0201fe0 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201fe0:	00054783          	lbu	a5,0(a0)
ffffffffc0201fe4:	c799                	beqz	a5,ffffffffc0201ff2 <strchr+0x12>
        if (*s == c) {
ffffffffc0201fe6:	00f58763          	beq	a1,a5,ffffffffc0201ff4 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201fea:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201fee:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201ff0:	fbfd                	bnez	a5,ffffffffc0201fe6 <strchr+0x6>
    }
    return NULL;
ffffffffc0201ff2:	4501                	li	a0,0
}
ffffffffc0201ff4:	8082                	ret

ffffffffc0201ff6 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201ff6:	ca01                	beqz	a2,ffffffffc0202006 <memset+0x10>
ffffffffc0201ff8:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201ffa:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201ffc:	0785                	addi	a5,a5,1
ffffffffc0201ffe:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0202002:	fec79de3          	bne	a5,a2,ffffffffc0201ffc <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0202006:	8082                	ret
