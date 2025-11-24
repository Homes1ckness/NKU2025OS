
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
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
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

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
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49260613          	addi	a2,a2,1170 # ffffffffc020d4e4 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	1ed030ef          	jal	ra,ffffffffc0203a4e <memset>
    dtb_init();
ffffffffc0200066:	452000ef          	jal	ra,ffffffffc02004b8 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	053000ef          	jal	ra,ffffffffc02008bc <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	e3258593          	addi	a1,a1,-462 # ffffffffc0203ea0 <etext>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e4a50513          	addi	a0,a0,-438 # ffffffffc0203ec0 <etext+0x20>
ffffffffc020007e:	062000ef          	jal	ra,ffffffffc02000e0 <cprintf>

    print_kerninfo();
ffffffffc0200082:	1b8000ef          	jal	ra,ffffffffc020023a <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	228010ef          	jal	ra,ffffffffc02012ae <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	0a5000ef          	jal	ra,ffffffffc020092e <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	0af000ef          	jal	ra,ffffffffc020093c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	791010ef          	jal	ra,ffffffffc0202022 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	5e6030ef          	jal	ra,ffffffffc020367c <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	7ce000ef          	jal	ra,ffffffffc0200868 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	093000ef          	jal	ra,ffffffffc0200930 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	029030ef          	jal	ra,ffffffffc02038ca <cpu_idle>

ffffffffc02000a6 <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc02000a6:	1141                	addi	sp,sp,-16
ffffffffc02000a8:	e022                	sd	s0,0(sp)
ffffffffc02000aa:	e406                	sd	ra,8(sp)
ffffffffc02000ac:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000ae:	011000ef          	jal	ra,ffffffffc02008be <cons_putc>
    (*cnt)++;
ffffffffc02000b2:	401c                	lw	a5,0(s0)
}
ffffffffc02000b4:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc02000b6:	2785                	addiw	a5,a5,1
ffffffffc02000b8:	c01c                	sw	a5,0(s0)
}
ffffffffc02000ba:	6402                	ld	s0,0(sp)
ffffffffc02000bc:	0141                	addi	sp,sp,16
ffffffffc02000be:	8082                	ret

ffffffffc02000c0 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc02000c0:	1101                	addi	sp,sp,-32
ffffffffc02000c2:	862a                	mv	a2,a0
ffffffffc02000c4:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000c6:	00000517          	auipc	a0,0x0
ffffffffc02000ca:	fe050513          	addi	a0,a0,-32 # ffffffffc02000a6 <cputch>
ffffffffc02000ce:	006c                	addi	a1,sp,12
{
ffffffffc02000d0:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000d2:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000d4:	235030ef          	jal	ra,ffffffffc0203b08 <vprintfmt>
    return cnt;
}
ffffffffc02000d8:	60e2                	ld	ra,24(sp)
ffffffffc02000da:	4532                	lw	a0,12(sp)
ffffffffc02000dc:	6105                	addi	sp,sp,32
ffffffffc02000de:	8082                	ret

ffffffffc02000e0 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc02000e0:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000e2:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
{
ffffffffc02000e6:	8e2a                	mv	t3,a0
ffffffffc02000e8:	f42e                	sd	a1,40(sp)
ffffffffc02000ea:	f832                	sd	a2,48(sp)
ffffffffc02000ec:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02000ee:	00000517          	auipc	a0,0x0
ffffffffc02000f2:	fb850513          	addi	a0,a0,-72 # ffffffffc02000a6 <cputch>
ffffffffc02000f6:	004c                	addi	a1,sp,4
ffffffffc02000f8:	869a                	mv	a3,t1
ffffffffc02000fa:	8672                	mv	a2,t3
{
ffffffffc02000fc:	ec06                	sd	ra,24(sp)
ffffffffc02000fe:	e0ba                	sd	a4,64(sp)
ffffffffc0200100:	e4be                	sd	a5,72(sp)
ffffffffc0200102:	e8c2                	sd	a6,80(sp)
ffffffffc0200104:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200106:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200108:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020010a:	1ff030ef          	jal	ra,ffffffffc0203b08 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020010e:	60e2                	ld	ra,24(sp)
ffffffffc0200110:	4512                	lw	a0,4(sp)
ffffffffc0200112:	6125                	addi	sp,sp,96
ffffffffc0200114:	8082                	ret

ffffffffc0200116 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc0200116:	7a80006f          	j	ffffffffc02008be <cons_putc>

ffffffffc020011a <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020011a:	1141                	addi	sp,sp,-16
ffffffffc020011c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020011e:	7d4000ef          	jal	ra,ffffffffc02008f2 <cons_getc>
ffffffffc0200122:	dd75                	beqz	a0,ffffffffc020011e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200124:	60a2                	ld	ra,8(sp)
ffffffffc0200126:	0141                	addi	sp,sp,16
ffffffffc0200128:	8082                	ret

ffffffffc020012a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020012a:	715d                	addi	sp,sp,-80
ffffffffc020012c:	e486                	sd	ra,72(sp)
ffffffffc020012e:	e0a6                	sd	s1,64(sp)
ffffffffc0200130:	fc4a                	sd	s2,56(sp)
ffffffffc0200132:	f84e                	sd	s3,48(sp)
ffffffffc0200134:	f452                	sd	s4,40(sp)
ffffffffc0200136:	f056                	sd	s5,32(sp)
ffffffffc0200138:	ec5a                	sd	s6,24(sp)
ffffffffc020013a:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc020013c:	c901                	beqz	a0,ffffffffc020014c <readline+0x22>
ffffffffc020013e:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0200140:	00004517          	auipc	a0,0x4
ffffffffc0200144:	d8850513          	addi	a0,a0,-632 # ffffffffc0203ec8 <etext+0x28>
ffffffffc0200148:	f99ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
readline(const char *prompt) {
ffffffffc020014c:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020014e:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0200150:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0200152:	4aa9                	li	s5,10
ffffffffc0200154:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200156:	00009b97          	auipc	s7,0x9
ffffffffc020015a:	edab8b93          	addi	s7,s7,-294 # ffffffffc0209030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020015e:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0200162:	fb9ff0ef          	jal	ra,ffffffffc020011a <getchar>
        if (c < 0) {
ffffffffc0200166:	00054a63          	bltz	a0,ffffffffc020017a <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020016a:	00a95a63          	bge	s2,a0,ffffffffc020017e <readline+0x54>
ffffffffc020016e:	029a5263          	bge	s4,s1,ffffffffc0200192 <readline+0x68>
        c = getchar();
ffffffffc0200172:	fa9ff0ef          	jal	ra,ffffffffc020011a <getchar>
        if (c < 0) {
ffffffffc0200176:	fe055ae3          	bgez	a0,ffffffffc020016a <readline+0x40>
            return NULL;
ffffffffc020017a:	4501                	li	a0,0
ffffffffc020017c:	a091                	j	ffffffffc02001c0 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc020017e:	03351463          	bne	a0,s3,ffffffffc02001a6 <readline+0x7c>
ffffffffc0200182:	e8a9                	bnez	s1,ffffffffc02001d4 <readline+0xaa>
        c = getchar();
ffffffffc0200184:	f97ff0ef          	jal	ra,ffffffffc020011a <getchar>
        if (c < 0) {
ffffffffc0200188:	fe0549e3          	bltz	a0,ffffffffc020017a <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020018c:	fea959e3          	bge	s2,a0,ffffffffc020017e <readline+0x54>
ffffffffc0200190:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200192:	e42a                	sd	a0,8(sp)
ffffffffc0200194:	f83ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            buf[i ++] = c;
ffffffffc0200198:	6522                	ld	a0,8(sp)
ffffffffc020019a:	009b87b3          	add	a5,s7,s1
ffffffffc020019e:	2485                	addiw	s1,s1,1
ffffffffc02001a0:	00a78023          	sb	a0,0(a5)
ffffffffc02001a4:	bf7d                	j	ffffffffc0200162 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02001a6:	01550463          	beq	a0,s5,ffffffffc02001ae <readline+0x84>
ffffffffc02001aa:	fb651ce3          	bne	a0,s6,ffffffffc0200162 <readline+0x38>
            cputchar(c);
ffffffffc02001ae:	f69ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            buf[i] = '\0';
ffffffffc02001b2:	00009517          	auipc	a0,0x9
ffffffffc02001b6:	e7e50513          	addi	a0,a0,-386 # ffffffffc0209030 <buf>
ffffffffc02001ba:	94aa                	add	s1,s1,a0
ffffffffc02001bc:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02001c0:	60a6                	ld	ra,72(sp)
ffffffffc02001c2:	6486                	ld	s1,64(sp)
ffffffffc02001c4:	7962                	ld	s2,56(sp)
ffffffffc02001c6:	79c2                	ld	s3,48(sp)
ffffffffc02001c8:	7a22                	ld	s4,40(sp)
ffffffffc02001ca:	7a82                	ld	s5,32(sp)
ffffffffc02001cc:	6b62                	ld	s6,24(sp)
ffffffffc02001ce:	6bc2                	ld	s7,16(sp)
ffffffffc02001d0:	6161                	addi	sp,sp,80
ffffffffc02001d2:	8082                	ret
            cputchar(c);
ffffffffc02001d4:	4521                	li	a0,8
ffffffffc02001d6:	f41ff0ef          	jal	ra,ffffffffc0200116 <cputchar>
            i --;
ffffffffc02001da:	34fd                	addiw	s1,s1,-1
ffffffffc02001dc:	b759                	j	ffffffffc0200162 <readline+0x38>

ffffffffc02001de <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001de:	0000d317          	auipc	t1,0xd
ffffffffc02001e2:	28a30313          	addi	t1,t1,650 # ffffffffc020d468 <is_panic>
ffffffffc02001e6:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ea:	715d                	addi	sp,sp,-80
ffffffffc02001ec:	ec06                	sd	ra,24(sp)
ffffffffc02001ee:	e822                	sd	s0,16(sp)
ffffffffc02001f0:	f436                	sd	a3,40(sp)
ffffffffc02001f2:	f83a                	sd	a4,48(sp)
ffffffffc02001f4:	fc3e                	sd	a5,56(sp)
ffffffffc02001f6:	e0c2                	sd	a6,64(sp)
ffffffffc02001f8:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001fa:	020e1a63          	bnez	t3,ffffffffc020022e <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02001fe:	4785                	li	a5,1
ffffffffc0200200:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200204:	8432                	mv	s0,a2
ffffffffc0200206:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200208:	862e                	mv	a2,a1
ffffffffc020020a:	85aa                	mv	a1,a0
ffffffffc020020c:	00004517          	auipc	a0,0x4
ffffffffc0200210:	cc450513          	addi	a0,a0,-828 # ffffffffc0203ed0 <etext+0x30>
    va_start(ap, fmt);
ffffffffc0200214:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200216:	ecbff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020021a:	65a2                	ld	a1,8(sp)
ffffffffc020021c:	8522                	mv	a0,s0
ffffffffc020021e:	ea3ff0ef          	jal	ra,ffffffffc02000c0 <vcprintf>
    cprintf("\n");
ffffffffc0200222:	00005517          	auipc	a0,0x5
ffffffffc0200226:	a5e50513          	addi	a0,a0,-1442 # ffffffffc0204c80 <commands+0xb58>
ffffffffc020022a:	eb7ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020022e:	708000ef          	jal	ra,ffffffffc0200936 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200232:	4501                	li	a0,0
ffffffffc0200234:	130000ef          	jal	ra,ffffffffc0200364 <kmonitor>
    while (1) {
ffffffffc0200238:	bfed                	j	ffffffffc0200232 <__panic+0x54>

ffffffffc020023a <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020023a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020023c:	00004517          	auipc	a0,0x4
ffffffffc0200240:	cb450513          	addi	a0,a0,-844 # ffffffffc0203ef0 <etext+0x50>
{
ffffffffc0200244:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200246:	e9bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020024a:	00000597          	auipc	a1,0x0
ffffffffc020024e:	e0058593          	addi	a1,a1,-512 # ffffffffc020004a <kern_init>
ffffffffc0200252:	00004517          	auipc	a0,0x4
ffffffffc0200256:	cbe50513          	addi	a0,a0,-834 # ffffffffc0203f10 <etext+0x70>
ffffffffc020025a:	e87ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020025e:	00004597          	auipc	a1,0x4
ffffffffc0200262:	c4258593          	addi	a1,a1,-958 # ffffffffc0203ea0 <etext>
ffffffffc0200266:	00004517          	auipc	a0,0x4
ffffffffc020026a:	cca50513          	addi	a0,a0,-822 # ffffffffc0203f30 <etext+0x90>
ffffffffc020026e:	e73ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200272:	00009597          	auipc	a1,0x9
ffffffffc0200276:	dbe58593          	addi	a1,a1,-578 # ffffffffc0209030 <buf>
ffffffffc020027a:	00004517          	auipc	a0,0x4
ffffffffc020027e:	cd650513          	addi	a0,a0,-810 # ffffffffc0203f50 <etext+0xb0>
ffffffffc0200282:	e5fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200286:	0000d597          	auipc	a1,0xd
ffffffffc020028a:	25e58593          	addi	a1,a1,606 # ffffffffc020d4e4 <end>
ffffffffc020028e:	00004517          	auipc	a0,0x4
ffffffffc0200292:	ce250513          	addi	a0,a0,-798 # ffffffffc0203f70 <etext+0xd0>
ffffffffc0200296:	e4bff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020029a:	0000d597          	auipc	a1,0xd
ffffffffc020029e:	64958593          	addi	a1,a1,1609 # ffffffffc020d8e3 <end+0x3ff>
ffffffffc02002a2:	00000797          	auipc	a5,0x0
ffffffffc02002a6:	da878793          	addi	a5,a5,-600 # ffffffffc020004a <kern_init>
ffffffffc02002aa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002ae:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02002b2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002b8:	95be                	add	a1,a1,a5
ffffffffc02002ba:	85a9                	srai	a1,a1,0xa
ffffffffc02002bc:	00004517          	auipc	a0,0x4
ffffffffc02002c0:	cd450513          	addi	a0,a0,-812 # ffffffffc0203f90 <etext+0xf0>
}
ffffffffc02002c4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002c6:	bd29                	j	ffffffffc02000e0 <cprintf>

ffffffffc02002c8 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002c8:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ca:	00004617          	auipc	a2,0x4
ffffffffc02002ce:	cf660613          	addi	a2,a2,-778 # ffffffffc0203fc0 <etext+0x120>
ffffffffc02002d2:	04900593          	li	a1,73
ffffffffc02002d6:	00004517          	auipc	a0,0x4
ffffffffc02002da:	d0250513          	addi	a0,a0,-766 # ffffffffc0203fd8 <etext+0x138>
{
ffffffffc02002de:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002e0:	effff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02002e4 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	00004617          	auipc	a2,0x4
ffffffffc02002ea:	d0a60613          	addi	a2,a2,-758 # ffffffffc0203ff0 <etext+0x150>
ffffffffc02002ee:	00004597          	auipc	a1,0x4
ffffffffc02002f2:	d2258593          	addi	a1,a1,-734 # ffffffffc0204010 <etext+0x170>
ffffffffc02002f6:	00004517          	auipc	a0,0x4
ffffffffc02002fa:	d2250513          	addi	a0,a0,-734 # ffffffffc0204018 <etext+0x178>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200300:	de1ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc0200304:	00004617          	auipc	a2,0x4
ffffffffc0200308:	d2460613          	addi	a2,a2,-732 # ffffffffc0204028 <etext+0x188>
ffffffffc020030c:	00004597          	auipc	a1,0x4
ffffffffc0200310:	d4458593          	addi	a1,a1,-700 # ffffffffc0204050 <etext+0x1b0>
ffffffffc0200314:	00004517          	auipc	a0,0x4
ffffffffc0200318:	d0450513          	addi	a0,a0,-764 # ffffffffc0204018 <etext+0x178>
ffffffffc020031c:	dc5ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc0200320:	00004617          	auipc	a2,0x4
ffffffffc0200324:	d4060613          	addi	a2,a2,-704 # ffffffffc0204060 <etext+0x1c0>
ffffffffc0200328:	00004597          	auipc	a1,0x4
ffffffffc020032c:	d5858593          	addi	a1,a1,-680 # ffffffffc0204080 <etext+0x1e0>
ffffffffc0200330:	00004517          	auipc	a0,0x4
ffffffffc0200334:	ce850513          	addi	a0,a0,-792 # ffffffffc0204018 <etext+0x178>
ffffffffc0200338:	da9ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    return 0;
}
ffffffffc020033c:	60a2                	ld	ra,8(sp)
ffffffffc020033e:	4501                	li	a0,0
ffffffffc0200340:	0141                	addi	sp,sp,16
ffffffffc0200342:	8082                	ret

ffffffffc0200344 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200344:	1141                	addi	sp,sp,-16
ffffffffc0200346:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200348:	ef3ff0ef          	jal	ra,ffffffffc020023a <print_kerninfo>
    return 0;
}
ffffffffc020034c:	60a2                	ld	ra,8(sp)
ffffffffc020034e:	4501                	li	a0,0
ffffffffc0200350:	0141                	addi	sp,sp,16
ffffffffc0200352:	8082                	ret

ffffffffc0200354 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200354:	1141                	addi	sp,sp,-16
ffffffffc0200356:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200358:	f71ff0ef          	jal	ra,ffffffffc02002c8 <print_stackframe>
    return 0;
}
ffffffffc020035c:	60a2                	ld	ra,8(sp)
ffffffffc020035e:	4501                	li	a0,0
ffffffffc0200360:	0141                	addi	sp,sp,16
ffffffffc0200362:	8082                	ret

ffffffffc0200364 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200364:	7115                	addi	sp,sp,-224
ffffffffc0200366:	ed5e                	sd	s7,152(sp)
ffffffffc0200368:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	00004517          	auipc	a0,0x4
ffffffffc020036e:	d2650513          	addi	a0,a0,-730 # ffffffffc0204090 <etext+0x1f0>
kmonitor(struct trapframe *tf) {
ffffffffc0200372:	ed86                	sd	ra,216(sp)
ffffffffc0200374:	e9a2                	sd	s0,208(sp)
ffffffffc0200376:	e5a6                	sd	s1,200(sp)
ffffffffc0200378:	e1ca                	sd	s2,192(sp)
ffffffffc020037a:	fd4e                	sd	s3,184(sp)
ffffffffc020037c:	f952                	sd	s4,176(sp)
ffffffffc020037e:	f556                	sd	s5,168(sp)
ffffffffc0200380:	f15a                	sd	s6,160(sp)
ffffffffc0200382:	e962                	sd	s8,144(sp)
ffffffffc0200384:	e566                	sd	s9,136(sp)
ffffffffc0200386:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200388:	d59ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020038c:	00004517          	auipc	a0,0x4
ffffffffc0200390:	d2c50513          	addi	a0,a0,-724 # ffffffffc02040b8 <etext+0x218>
ffffffffc0200394:	d4dff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    if (tf != NULL) {
ffffffffc0200398:	000b8563          	beqz	s7,ffffffffc02003a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020039c:	855e                	mv	a0,s7
ffffffffc020039e:	77e000ef          	jal	ra,ffffffffc0200b1c <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02003a2:	4501                	li	a0,0
ffffffffc02003a4:	4581                	li	a1,0
ffffffffc02003a6:	4601                	li	a2,0
ffffffffc02003a8:	48a1                	li	a7,8
ffffffffc02003aa:	00000073          	ecall
ffffffffc02003ae:	00004c17          	auipc	s8,0x4
ffffffffc02003b2:	d7ac0c13          	addi	s8,s8,-646 # ffffffffc0204128 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003b6:	00004917          	auipc	s2,0x4
ffffffffc02003ba:	d2a90913          	addi	s2,s2,-726 # ffffffffc02040e0 <etext+0x240>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003be:	00004497          	auipc	s1,0x4
ffffffffc02003c2:	d2a48493          	addi	s1,s1,-726 # ffffffffc02040e8 <etext+0x248>
        if (argc == MAXARGS - 1) {
ffffffffc02003c6:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003c8:	00004b17          	auipc	s6,0x4
ffffffffc02003cc:	d28b0b13          	addi	s6,s6,-728 # ffffffffc02040f0 <etext+0x250>
        argv[argc ++] = buf;
ffffffffc02003d0:	00004a17          	auipc	s4,0x4
ffffffffc02003d4:	c40a0a13          	addi	s4,s4,-960 # ffffffffc0204010 <etext+0x170>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d8:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003da:	854a                	mv	a0,s2
ffffffffc02003dc:	d4fff0ef          	jal	ra,ffffffffc020012a <readline>
ffffffffc02003e0:	842a                	mv	s0,a0
ffffffffc02003e2:	dd65                	beqz	a0,ffffffffc02003da <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003e4:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003e8:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ea:	e1bd                	bnez	a1,ffffffffc0200450 <kmonitor+0xec>
    if (argc == 0) {
ffffffffc02003ec:	fe0c87e3          	beqz	s9,ffffffffc02003da <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003f0:	6582                	ld	a1,0(sp)
ffffffffc02003f2:	00004d17          	auipc	s10,0x4
ffffffffc02003f6:	d36d0d13          	addi	s10,s10,-714 # ffffffffc0204128 <commands>
        argv[argc ++] = buf;
ffffffffc02003fa:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003fc:	4401                	li	s0,0
ffffffffc02003fe:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200400:	5f4030ef          	jal	ra,ffffffffc02039f4 <strcmp>
ffffffffc0200404:	c919                	beqz	a0,ffffffffc020041a <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200406:	2405                	addiw	s0,s0,1
ffffffffc0200408:	0b540063          	beq	s0,s5,ffffffffc02004a8 <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020040c:	000d3503          	ld	a0,0(s10)
ffffffffc0200410:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200412:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200414:	5e0030ef          	jal	ra,ffffffffc02039f4 <strcmp>
ffffffffc0200418:	f57d                	bnez	a0,ffffffffc0200406 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041a:	00141793          	slli	a5,s0,0x1
ffffffffc020041e:	97a2                	add	a5,a5,s0
ffffffffc0200420:	078e                	slli	a5,a5,0x3
ffffffffc0200422:	97e2                	add	a5,a5,s8
ffffffffc0200424:	6b9c                	ld	a5,16(a5)
ffffffffc0200426:	865e                	mv	a2,s7
ffffffffc0200428:	002c                	addi	a1,sp,8
ffffffffc020042a:	fffc851b          	addiw	a0,s9,-1
ffffffffc020042e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200430:	fa0555e3          	bgez	a0,ffffffffc02003da <kmonitor+0x76>
}
ffffffffc0200434:	60ee                	ld	ra,216(sp)
ffffffffc0200436:	644e                	ld	s0,208(sp)
ffffffffc0200438:	64ae                	ld	s1,200(sp)
ffffffffc020043a:	690e                	ld	s2,192(sp)
ffffffffc020043c:	79ea                	ld	s3,184(sp)
ffffffffc020043e:	7a4a                	ld	s4,176(sp)
ffffffffc0200440:	7aaa                	ld	s5,168(sp)
ffffffffc0200442:	7b0a                	ld	s6,160(sp)
ffffffffc0200444:	6bea                	ld	s7,152(sp)
ffffffffc0200446:	6c4a                	ld	s8,144(sp)
ffffffffc0200448:	6caa                	ld	s9,136(sp)
ffffffffc020044a:	6d0a                	ld	s10,128(sp)
ffffffffc020044c:	612d                	addi	sp,sp,224
ffffffffc020044e:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200450:	8526                	mv	a0,s1
ffffffffc0200452:	5e6030ef          	jal	ra,ffffffffc0203a38 <strchr>
ffffffffc0200456:	c901                	beqz	a0,ffffffffc0200466 <kmonitor+0x102>
ffffffffc0200458:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020045c:	00040023          	sb	zero,0(s0)
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200462:	d5c9                	beqz	a1,ffffffffc02003ec <kmonitor+0x88>
ffffffffc0200464:	b7f5                	j	ffffffffc0200450 <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200466:	00044783          	lbu	a5,0(s0)
ffffffffc020046a:	d3c9                	beqz	a5,ffffffffc02003ec <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc020046c:	033c8963          	beq	s9,s3,ffffffffc020049e <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc0200470:	003c9793          	slli	a5,s9,0x3
ffffffffc0200474:	0118                	addi	a4,sp,128
ffffffffc0200476:	97ba                	add	a5,a5,a4
ffffffffc0200478:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020047c:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200480:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200482:	e591                	bnez	a1,ffffffffc020048e <kmonitor+0x12a>
ffffffffc0200484:	b7b5                	j	ffffffffc02003f0 <kmonitor+0x8c>
ffffffffc0200486:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020048a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020048c:	d1a5                	beqz	a1,ffffffffc02003ec <kmonitor+0x88>
ffffffffc020048e:	8526                	mv	a0,s1
ffffffffc0200490:	5a8030ef          	jal	ra,ffffffffc0203a38 <strchr>
ffffffffc0200494:	d96d                	beqz	a0,ffffffffc0200486 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200496:	00044583          	lbu	a1,0(s0)
ffffffffc020049a:	d9a9                	beqz	a1,ffffffffc02003ec <kmonitor+0x88>
ffffffffc020049c:	bf55                	j	ffffffffc0200450 <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020049e:	45c1                	li	a1,16
ffffffffc02004a0:	855a                	mv	a0,s6
ffffffffc02004a2:	c3fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc02004a6:	b7e9                	j	ffffffffc0200470 <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02004a8:	6582                	ld	a1,0(sp)
ffffffffc02004aa:	00004517          	auipc	a0,0x4
ffffffffc02004ae:	c6650513          	addi	a0,a0,-922 # ffffffffc0204110 <etext+0x270>
ffffffffc02004b2:	c2fff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return 0;
ffffffffc02004b6:	b715                	j	ffffffffc02003da <kmonitor+0x76>

ffffffffc02004b8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004b8:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02004ba:	00004517          	auipc	a0,0x4
ffffffffc02004be:	cb650513          	addi	a0,a0,-842 # ffffffffc0204170 <commands+0x48>
void dtb_init(void) {
ffffffffc02004c2:	fc86                	sd	ra,120(sp)
ffffffffc02004c4:	f8a2                	sd	s0,112(sp)
ffffffffc02004c6:	e8d2                	sd	s4,80(sp)
ffffffffc02004c8:	f4a6                	sd	s1,104(sp)
ffffffffc02004ca:	f0ca                	sd	s2,96(sp)
ffffffffc02004cc:	ecce                	sd	s3,88(sp)
ffffffffc02004ce:	e4d6                	sd	s5,72(sp)
ffffffffc02004d0:	e0da                	sd	s6,64(sp)
ffffffffc02004d2:	fc5e                	sd	s7,56(sp)
ffffffffc02004d4:	f862                	sd	s8,48(sp)
ffffffffc02004d6:	f466                	sd	s9,40(sp)
ffffffffc02004d8:	f06a                	sd	s10,32(sp)
ffffffffc02004da:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004dc:	c05ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004e0:	00009597          	auipc	a1,0x9
ffffffffc02004e4:	b205b583          	ld	a1,-1248(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc02004e8:	00004517          	auipc	a0,0x4
ffffffffc02004ec:	c9850513          	addi	a0,a0,-872 # ffffffffc0204180 <commands+0x58>
ffffffffc02004f0:	bf1ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004f4:	00009417          	auipc	s0,0x9
ffffffffc02004f8:	b1440413          	addi	s0,s0,-1260 # ffffffffc0209008 <boot_dtb>
ffffffffc02004fc:	600c                	ld	a1,0(s0)
ffffffffc02004fe:	00004517          	auipc	a0,0x4
ffffffffc0200502:	c9250513          	addi	a0,a0,-878 # ffffffffc0204190 <commands+0x68>
ffffffffc0200506:	bdbff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020050a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020050e:	00004517          	auipc	a0,0x4
ffffffffc0200512:	c9a50513          	addi	a0,a0,-870 # ffffffffc02041a8 <commands+0x80>
    if (boot_dtb == 0) {
ffffffffc0200516:	120a0463          	beqz	s4,ffffffffc020063e <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020051a:	57f5                	li	a5,-3
ffffffffc020051c:	07fa                	slli	a5,a5,0x1e
ffffffffc020051e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200522:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200524:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200528:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020052e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200532:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200536:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053e:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200540:	8ec9                	or	a3,a3,a0
ffffffffc0200542:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200546:	1b7d                	addi	s6,s6,-1
ffffffffc0200548:	0167f7b3          	and	a5,a5,s6
ffffffffc020054c:	8dd5                	or	a1,a1,a3
ffffffffc020054e:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200550:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200554:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200556:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed2a09>
ffffffffc020055a:	10f59163          	bne	a1,a5,ffffffffc020065c <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020055e:	471c                	lw	a5,8(a4)
ffffffffc0200560:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200562:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200564:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200568:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020056c:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200570:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200574:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200578:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020057c:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200580:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200584:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200588:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058c:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058e:	01146433          	or	s0,s0,a7
ffffffffc0200592:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200596:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020059a:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020059c:	0087979b          	slliw	a5,a5,0x8
ffffffffc02005a0:	8c49                	or	s0,s0,a0
ffffffffc02005a2:	0166f6b3          	and	a3,a3,s6
ffffffffc02005a6:	00ca6a33          	or	s4,s4,a2
ffffffffc02005aa:	0167f7b3          	and	a5,a5,s6
ffffffffc02005ae:	8c55                	or	s0,s0,a3
ffffffffc02005b0:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b4:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005b6:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b8:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005ba:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005be:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005c0:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc02005c6:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005c8:	00004917          	auipc	s2,0x4
ffffffffc02005cc:	c3090913          	addi	s2,s2,-976 # ffffffffc02041f8 <commands+0xd0>
ffffffffc02005d0:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005d2:	4d91                	li	s11,4
ffffffffc02005d4:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005d6:	00004497          	auipc	s1,0x4
ffffffffc02005da:	c1a48493          	addi	s1,s1,-998 # ffffffffc02041f0 <commands+0xc8>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005de:	000a2703          	lw	a4,0(s4)
ffffffffc02005e2:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005ea:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ee:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f2:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f6:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005fa:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005fc:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200600:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200604:	8fd5                	or	a5,a5,a3
ffffffffc0200606:	00eb7733          	and	a4,s6,a4
ffffffffc020060a:	8fd9                	or	a5,a5,a4
ffffffffc020060c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020060e:	09778c63          	beq	a5,s7,ffffffffc02006a6 <dtb_init+0x1ee>
ffffffffc0200612:	00fbea63          	bltu	s7,a5,ffffffffc0200626 <dtb_init+0x16e>
ffffffffc0200616:	07a78663          	beq	a5,s10,ffffffffc0200682 <dtb_init+0x1ca>
ffffffffc020061a:	4709                	li	a4,2
ffffffffc020061c:	00e79763          	bne	a5,a4,ffffffffc020062a <dtb_init+0x172>
ffffffffc0200620:	4c81                	li	s9,0
ffffffffc0200622:	8a56                	mv	s4,s5
ffffffffc0200624:	bf6d                	j	ffffffffc02005de <dtb_init+0x126>
ffffffffc0200626:	ffb78ee3          	beq	a5,s11,ffffffffc0200622 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020062a:	00004517          	auipc	a0,0x4
ffffffffc020062e:	c4650513          	addi	a0,a0,-954 # ffffffffc0204270 <commands+0x148>
ffffffffc0200632:	aafff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200636:	00004517          	auipc	a0,0x4
ffffffffc020063a:	c7250513          	addi	a0,a0,-910 # ffffffffc02042a8 <commands+0x180>
}
ffffffffc020063e:	7446                	ld	s0,112(sp)
ffffffffc0200640:	70e6                	ld	ra,120(sp)
ffffffffc0200642:	74a6                	ld	s1,104(sp)
ffffffffc0200644:	7906                	ld	s2,96(sp)
ffffffffc0200646:	69e6                	ld	s3,88(sp)
ffffffffc0200648:	6a46                	ld	s4,80(sp)
ffffffffc020064a:	6aa6                	ld	s5,72(sp)
ffffffffc020064c:	6b06                	ld	s6,64(sp)
ffffffffc020064e:	7be2                	ld	s7,56(sp)
ffffffffc0200650:	7c42                	ld	s8,48(sp)
ffffffffc0200652:	7ca2                	ld	s9,40(sp)
ffffffffc0200654:	7d02                	ld	s10,32(sp)
ffffffffc0200656:	6de2                	ld	s11,24(sp)
ffffffffc0200658:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020065a:	b459                	j	ffffffffc02000e0 <cprintf>
}
ffffffffc020065c:	7446                	ld	s0,112(sp)
ffffffffc020065e:	70e6                	ld	ra,120(sp)
ffffffffc0200660:	74a6                	ld	s1,104(sp)
ffffffffc0200662:	7906                	ld	s2,96(sp)
ffffffffc0200664:	69e6                	ld	s3,88(sp)
ffffffffc0200666:	6a46                	ld	s4,80(sp)
ffffffffc0200668:	6aa6                	ld	s5,72(sp)
ffffffffc020066a:	6b06                	ld	s6,64(sp)
ffffffffc020066c:	7be2                	ld	s7,56(sp)
ffffffffc020066e:	7c42                	ld	s8,48(sp)
ffffffffc0200670:	7ca2                	ld	s9,40(sp)
ffffffffc0200672:	7d02                	ld	s10,32(sp)
ffffffffc0200674:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200676:	00004517          	auipc	a0,0x4
ffffffffc020067a:	b5250513          	addi	a0,a0,-1198 # ffffffffc02041c8 <commands+0xa0>
}
ffffffffc020067e:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200680:	b485                	j	ffffffffc02000e0 <cprintf>
                int name_len = strlen(name);
ffffffffc0200682:	8556                	mv	a0,s5
ffffffffc0200684:	328030ef          	jal	ra,ffffffffc02039ac <strlen>
ffffffffc0200688:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020068a:	4619                	li	a2,6
ffffffffc020068c:	85a6                	mv	a1,s1
ffffffffc020068e:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200690:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200692:	380030ef          	jal	ra,ffffffffc0203a12 <strncmp>
ffffffffc0200696:	e111                	bnez	a0,ffffffffc020069a <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200698:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020069a:	0a91                	addi	s5,s5,4
ffffffffc020069c:	9ad2                	add	s5,s5,s4
ffffffffc020069e:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006a2:	8a56                	mv	s4,s5
ffffffffc02006a4:	bf2d                	j	ffffffffc02005de <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a6:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006aa:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ae:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02006b2:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006c2:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c6:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ca:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006ce:	00eaeab3          	or	s5,s5,a4
ffffffffc02006d2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006d6:	00faeab3          	or	s5,s5,a5
ffffffffc02006da:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006dc:	000c9c63          	bnez	s9,ffffffffc02006f4 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006e0:	1a82                	slli	s5,s5,0x20
ffffffffc02006e2:	00368793          	addi	a5,a3,3
ffffffffc02006e6:	020ada93          	srli	s5,s5,0x20
ffffffffc02006ea:	9abe                	add	s5,s5,a5
ffffffffc02006ec:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006f0:	8a56                	mv	s4,s5
ffffffffc02006f2:	b5f5                	j	ffffffffc02005de <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006f4:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f8:	85ca                	mv	a1,s2
ffffffffc02006fa:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fc:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200700:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200704:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200708:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020070c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200710:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200712:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200716:	0087979b          	slliw	a5,a5,0x8
ffffffffc020071a:	8d59                	or	a0,a0,a4
ffffffffc020071c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200720:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200722:	1502                	slli	a0,a0,0x20
ffffffffc0200724:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200726:	9522                	add	a0,a0,s0
ffffffffc0200728:	2cc030ef          	jal	ra,ffffffffc02039f4 <strcmp>
ffffffffc020072c:	66a2                	ld	a3,8(sp)
ffffffffc020072e:	f94d                	bnez	a0,ffffffffc02006e0 <dtb_init+0x228>
ffffffffc0200730:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006e0 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200734:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200738:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020073c:	00004517          	auipc	a0,0x4
ffffffffc0200740:	ac450513          	addi	a0,a0,-1340 # ffffffffc0204200 <commands+0xd8>
           fdt32_to_cpu(x >> 32);
ffffffffc0200744:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200748:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020074c:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200750:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200754:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200758:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075c:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200760:	0187d693          	srli	a3,a5,0x18
ffffffffc0200764:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200768:	0087579b          	srliw	a5,a4,0x8
ffffffffc020076c:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200770:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200774:	010f6f33          	or	t5,t5,a6
ffffffffc0200778:	0187529b          	srliw	t0,a4,0x18
ffffffffc020077c:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200780:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200784:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	0186f6b3          	and	a3,a3,s8
ffffffffc020078c:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200790:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200794:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200798:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079c:	8361                	srli	a4,a4,0x18
ffffffffc020079e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02007a6:	01e6e6b3          	or	a3,a3,t5
ffffffffc02007aa:	00cb7633          	and	a2,s6,a2
ffffffffc02007ae:	0088181b          	slliw	a6,a6,0x8
ffffffffc02007b2:	0085959b          	slliw	a1,a1,0x8
ffffffffc02007b6:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ba:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007be:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c2:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c6:	0088989b          	slliw	a7,a7,0x8
ffffffffc02007ca:	011b78b3          	and	a7,s6,a7
ffffffffc02007ce:	005eeeb3          	or	t4,t4,t0
ffffffffc02007d2:	00c6e733          	or	a4,a3,a2
ffffffffc02007d6:	006c6c33          	or	s8,s8,t1
ffffffffc02007da:	010b76b3          	and	a3,s6,a6
ffffffffc02007de:	00bb7b33          	and	s6,s6,a1
ffffffffc02007e2:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007e6:	016c6b33          	or	s6,s8,s6
ffffffffc02007ea:	01146433          	or	s0,s0,a7
ffffffffc02007ee:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007f0:	1702                	slli	a4,a4,0x20
ffffffffc02007f2:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007f4:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007f6:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007f8:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007fa:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007fe:	0167eb33          	or	s6,a5,s6
ffffffffc0200802:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200804:	8ddff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200808:	85a2                	mv	a1,s0
ffffffffc020080a:	00004517          	auipc	a0,0x4
ffffffffc020080e:	a1650513          	addi	a0,a0,-1514 # ffffffffc0204220 <commands+0xf8>
ffffffffc0200812:	8cfff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200816:	014b5613          	srli	a2,s6,0x14
ffffffffc020081a:	85da                	mv	a1,s6
ffffffffc020081c:	00004517          	auipc	a0,0x4
ffffffffc0200820:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0204238 <commands+0x110>
ffffffffc0200824:	8bdff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200828:	008b05b3          	add	a1,s6,s0
ffffffffc020082c:	15fd                	addi	a1,a1,-1
ffffffffc020082e:	00004517          	auipc	a0,0x4
ffffffffc0200832:	a2a50513          	addi	a0,a0,-1494 # ffffffffc0204258 <commands+0x130>
ffffffffc0200836:	8abff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc020083a:	00004517          	auipc	a0,0x4
ffffffffc020083e:	a6e50513          	addi	a0,a0,-1426 # ffffffffc02042a8 <commands+0x180>
        memory_base = mem_base;
ffffffffc0200842:	0000d797          	auipc	a5,0xd
ffffffffc0200846:	c287b723          	sd	s0,-978(a5) # ffffffffc020d470 <memory_base>
        memory_size = mem_size;
ffffffffc020084a:	0000d797          	auipc	a5,0xd
ffffffffc020084e:	c367b723          	sd	s6,-978(a5) # ffffffffc020d478 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200852:	b3f5                	j	ffffffffc020063e <dtb_init+0x186>

ffffffffc0200854 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200854:	0000d517          	auipc	a0,0xd
ffffffffc0200858:	c1c53503          	ld	a0,-996(a0) # ffffffffc020d470 <memory_base>
ffffffffc020085c:	8082                	ret

ffffffffc020085e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc020085e:	0000d517          	auipc	a0,0xd
ffffffffc0200862:	c1a53503          	ld	a0,-998(a0) # ffffffffc020d478 <memory_size>
ffffffffc0200866:	8082                	ret

ffffffffc0200868 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200868:	67e1                	lui	a5,0x18
ffffffffc020086a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020086e:	0000d717          	auipc	a4,0xd
ffffffffc0200872:	c0f73d23          	sd	a5,-998(a4) # ffffffffc020d488 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200876:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020087a:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020087c:	953e                	add	a0,a0,a5
ffffffffc020087e:	4601                	li	a2,0
ffffffffc0200880:	4881                	li	a7,0
ffffffffc0200882:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200886:	02000793          	li	a5,32
ffffffffc020088a:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020088e:	00004517          	auipc	a0,0x4
ffffffffc0200892:	a3250513          	addi	a0,a0,-1486 # ffffffffc02042c0 <commands+0x198>
    ticks = 0;
ffffffffc0200896:	0000d797          	auipc	a5,0xd
ffffffffc020089a:	be07b523          	sd	zero,-1046(a5) # ffffffffc020d480 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020089e:	843ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc02008a2 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02008a2:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02008a6:	0000d797          	auipc	a5,0xd
ffffffffc02008aa:	be27b783          	ld	a5,-1054(a5) # ffffffffc020d488 <timebase>
ffffffffc02008ae:	953e                	add	a0,a0,a5
ffffffffc02008b0:	4581                	li	a1,0
ffffffffc02008b2:	4601                	li	a2,0
ffffffffc02008b4:	4881                	li	a7,0
ffffffffc02008b6:	00000073          	ecall
ffffffffc02008ba:	8082                	ret

ffffffffc02008bc <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02008bc:	8082                	ret

ffffffffc02008be <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02008be:	100027f3          	csrr	a5,sstatus
ffffffffc02008c2:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02008c4:	0ff57513          	zext.b	a0,a0
ffffffffc02008c8:	e799                	bnez	a5,ffffffffc02008d6 <cons_putc+0x18>
ffffffffc02008ca:	4581                	li	a1,0
ffffffffc02008cc:	4601                	li	a2,0
ffffffffc02008ce:	4885                	li	a7,1
ffffffffc02008d0:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02008d4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02008d6:	1101                	addi	sp,sp,-32
ffffffffc02008d8:	ec06                	sd	ra,24(sp)
ffffffffc02008da:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02008dc:	05a000ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc02008e0:	6522                	ld	a0,8(sp)
ffffffffc02008e2:	4581                	li	a1,0
ffffffffc02008e4:	4601                	li	a2,0
ffffffffc02008e6:	4885                	li	a7,1
ffffffffc02008e8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02008ec:	60e2                	ld	ra,24(sp)
ffffffffc02008ee:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02008f0:	a081                	j	ffffffffc0200930 <intr_enable>

ffffffffc02008f2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02008f2:	100027f3          	csrr	a5,sstatus
ffffffffc02008f6:	8b89                	andi	a5,a5,2
ffffffffc02008f8:	eb89                	bnez	a5,ffffffffc020090a <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02008fa:	4501                	li	a0,0
ffffffffc02008fc:	4581                	li	a1,0
ffffffffc02008fe:	4601                	li	a2,0
ffffffffc0200900:	4889                	li	a7,2
ffffffffc0200902:	00000073          	ecall
ffffffffc0200906:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200908:	8082                	ret
int cons_getc(void) {
ffffffffc020090a:	1101                	addi	sp,sp,-32
ffffffffc020090c:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020090e:	028000ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc0200912:	4501                	li	a0,0
ffffffffc0200914:	4581                	li	a1,0
ffffffffc0200916:	4601                	li	a2,0
ffffffffc0200918:	4889                	li	a7,2
ffffffffc020091a:	00000073          	ecall
ffffffffc020091e:	2501                	sext.w	a0,a0
ffffffffc0200920:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200922:	00e000ef          	jal	ra,ffffffffc0200930 <intr_enable>
}
ffffffffc0200926:	60e2                	ld	ra,24(sp)
ffffffffc0200928:	6522                	ld	a0,8(sp)
ffffffffc020092a:	6105                	addi	sp,sp,32
ffffffffc020092c:	8082                	ret

ffffffffc020092e <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020092e:	8082                	ret

ffffffffc0200930 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200930:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200934:	8082                	ret

ffffffffc0200936 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200936:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020093a:	8082                	ret

ffffffffc020093c <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020093c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200940:	00000797          	auipc	a5,0x0
ffffffffc0200944:	3b878793          	addi	a5,a5,952 # ffffffffc0200cf8 <__alltraps>
ffffffffc0200948:	10579073          	csrw	stvec,a5
}
ffffffffc020094c:	8082                	ret

ffffffffc020094e <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020094e:	610c                	ld	a1,0(a0)
{
ffffffffc0200950:	1141                	addi	sp,sp,-16
ffffffffc0200952:	e022                	sd	s0,0(sp)
ffffffffc0200954:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200956:	00004517          	auipc	a0,0x4
ffffffffc020095a:	98a50513          	addi	a0,a0,-1654 # ffffffffc02042e0 <commands+0x1b8>
{
ffffffffc020095e:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200960:	f80ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200964:	640c                	ld	a1,8(s0)
ffffffffc0200966:	00004517          	auipc	a0,0x4
ffffffffc020096a:	99250513          	addi	a0,a0,-1646 # ffffffffc02042f8 <commands+0x1d0>
ffffffffc020096e:	f72ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200972:	680c                	ld	a1,16(s0)
ffffffffc0200974:	00004517          	auipc	a0,0x4
ffffffffc0200978:	99c50513          	addi	a0,a0,-1636 # ffffffffc0204310 <commands+0x1e8>
ffffffffc020097c:	f64ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200980:	6c0c                	ld	a1,24(s0)
ffffffffc0200982:	00004517          	auipc	a0,0x4
ffffffffc0200986:	9a650513          	addi	a0,a0,-1626 # ffffffffc0204328 <commands+0x200>
ffffffffc020098a:	f56ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020098e:	700c                	ld	a1,32(s0)
ffffffffc0200990:	00004517          	auipc	a0,0x4
ffffffffc0200994:	9b050513          	addi	a0,a0,-1616 # ffffffffc0204340 <commands+0x218>
ffffffffc0200998:	f48ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020099c:	740c                	ld	a1,40(s0)
ffffffffc020099e:	00004517          	auipc	a0,0x4
ffffffffc02009a2:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0204358 <commands+0x230>
ffffffffc02009a6:	f3aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02009aa:	780c                	ld	a1,48(s0)
ffffffffc02009ac:	00004517          	auipc	a0,0x4
ffffffffc02009b0:	9c450513          	addi	a0,a0,-1596 # ffffffffc0204370 <commands+0x248>
ffffffffc02009b4:	f2cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009b8:	7c0c                	ld	a1,56(s0)
ffffffffc02009ba:	00004517          	auipc	a0,0x4
ffffffffc02009be:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0204388 <commands+0x260>
ffffffffc02009c2:	f1eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009c6:	602c                	ld	a1,64(s0)
ffffffffc02009c8:	00004517          	auipc	a0,0x4
ffffffffc02009cc:	9d850513          	addi	a0,a0,-1576 # ffffffffc02043a0 <commands+0x278>
ffffffffc02009d0:	f10ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009d4:	642c                	ld	a1,72(s0)
ffffffffc02009d6:	00004517          	auipc	a0,0x4
ffffffffc02009da:	9e250513          	addi	a0,a0,-1566 # ffffffffc02043b8 <commands+0x290>
ffffffffc02009de:	f02ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009e2:	682c                	ld	a1,80(s0)
ffffffffc02009e4:	00004517          	auipc	a0,0x4
ffffffffc02009e8:	9ec50513          	addi	a0,a0,-1556 # ffffffffc02043d0 <commands+0x2a8>
ffffffffc02009ec:	ef4ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009f0:	6c2c                	ld	a1,88(s0)
ffffffffc02009f2:	00004517          	auipc	a0,0x4
ffffffffc02009f6:	9f650513          	addi	a0,a0,-1546 # ffffffffc02043e8 <commands+0x2c0>
ffffffffc02009fa:	ee6ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009fe:	702c                	ld	a1,96(s0)
ffffffffc0200a00:	00004517          	auipc	a0,0x4
ffffffffc0200a04:	a0050513          	addi	a0,a0,-1536 # ffffffffc0204400 <commands+0x2d8>
ffffffffc0200a08:	ed8ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a0c:	742c                	ld	a1,104(s0)
ffffffffc0200a0e:	00004517          	auipc	a0,0x4
ffffffffc0200a12:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0204418 <commands+0x2f0>
ffffffffc0200a16:	ecaff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a1a:	782c                	ld	a1,112(s0)
ffffffffc0200a1c:	00004517          	auipc	a0,0x4
ffffffffc0200a20:	a1450513          	addi	a0,a0,-1516 # ffffffffc0204430 <commands+0x308>
ffffffffc0200a24:	ebcff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a28:	7c2c                	ld	a1,120(s0)
ffffffffc0200a2a:	00004517          	auipc	a0,0x4
ffffffffc0200a2e:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0204448 <commands+0x320>
ffffffffc0200a32:	eaeff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a36:	604c                	ld	a1,128(s0)
ffffffffc0200a38:	00004517          	auipc	a0,0x4
ffffffffc0200a3c:	a2850513          	addi	a0,a0,-1496 # ffffffffc0204460 <commands+0x338>
ffffffffc0200a40:	ea0ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a44:	644c                	ld	a1,136(s0)
ffffffffc0200a46:	00004517          	auipc	a0,0x4
ffffffffc0200a4a:	a3250513          	addi	a0,a0,-1486 # ffffffffc0204478 <commands+0x350>
ffffffffc0200a4e:	e92ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a52:	684c                	ld	a1,144(s0)
ffffffffc0200a54:	00004517          	auipc	a0,0x4
ffffffffc0200a58:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0204490 <commands+0x368>
ffffffffc0200a5c:	e84ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a60:	6c4c                	ld	a1,152(s0)
ffffffffc0200a62:	00004517          	auipc	a0,0x4
ffffffffc0200a66:	a4650513          	addi	a0,a0,-1466 # ffffffffc02044a8 <commands+0x380>
ffffffffc0200a6a:	e76ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a6e:	704c                	ld	a1,160(s0)
ffffffffc0200a70:	00004517          	auipc	a0,0x4
ffffffffc0200a74:	a5050513          	addi	a0,a0,-1456 # ffffffffc02044c0 <commands+0x398>
ffffffffc0200a78:	e68ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a7c:	744c                	ld	a1,168(s0)
ffffffffc0200a7e:	00004517          	auipc	a0,0x4
ffffffffc0200a82:	a5a50513          	addi	a0,a0,-1446 # ffffffffc02044d8 <commands+0x3b0>
ffffffffc0200a86:	e5aff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a8a:	784c                	ld	a1,176(s0)
ffffffffc0200a8c:	00004517          	auipc	a0,0x4
ffffffffc0200a90:	a6450513          	addi	a0,a0,-1436 # ffffffffc02044f0 <commands+0x3c8>
ffffffffc0200a94:	e4cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a98:	7c4c                	ld	a1,184(s0)
ffffffffc0200a9a:	00004517          	auipc	a0,0x4
ffffffffc0200a9e:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0204508 <commands+0x3e0>
ffffffffc0200aa2:	e3eff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200aa6:	606c                	ld	a1,192(s0)
ffffffffc0200aa8:	00004517          	auipc	a0,0x4
ffffffffc0200aac:	a7850513          	addi	a0,a0,-1416 # ffffffffc0204520 <commands+0x3f8>
ffffffffc0200ab0:	e30ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200ab4:	646c                	ld	a1,200(s0)
ffffffffc0200ab6:	00004517          	auipc	a0,0x4
ffffffffc0200aba:	a8250513          	addi	a0,a0,-1406 # ffffffffc0204538 <commands+0x410>
ffffffffc0200abe:	e22ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200ac2:	686c                	ld	a1,208(s0)
ffffffffc0200ac4:	00004517          	auipc	a0,0x4
ffffffffc0200ac8:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0204550 <commands+0x428>
ffffffffc0200acc:	e14ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200ad0:	6c6c                	ld	a1,216(s0)
ffffffffc0200ad2:	00004517          	auipc	a0,0x4
ffffffffc0200ad6:	a9650513          	addi	a0,a0,-1386 # ffffffffc0204568 <commands+0x440>
ffffffffc0200ada:	e06ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ade:	706c                	ld	a1,224(s0)
ffffffffc0200ae0:	00004517          	auipc	a0,0x4
ffffffffc0200ae4:	aa050513          	addi	a0,a0,-1376 # ffffffffc0204580 <commands+0x458>
ffffffffc0200ae8:	df8ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200aec:	746c                	ld	a1,232(s0)
ffffffffc0200aee:	00004517          	auipc	a0,0x4
ffffffffc0200af2:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0204598 <commands+0x470>
ffffffffc0200af6:	deaff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200afa:	786c                	ld	a1,240(s0)
ffffffffc0200afc:	00004517          	auipc	a0,0x4
ffffffffc0200b00:	ab450513          	addi	a0,a0,-1356 # ffffffffc02045b0 <commands+0x488>
ffffffffc0200b04:	ddcff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b08:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b0a:	6402                	ld	s0,0(sp)
ffffffffc0200b0c:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b0e:	00004517          	auipc	a0,0x4
ffffffffc0200b12:	aba50513          	addi	a0,a0,-1350 # ffffffffc02045c8 <commands+0x4a0>
}
ffffffffc0200b16:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b18:	dc8ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0200b1c <print_trapframe>:
{
ffffffffc0200b1c:	1141                	addi	sp,sp,-16
ffffffffc0200b1e:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b20:	85aa                	mv	a1,a0
{
ffffffffc0200b22:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b24:	00004517          	auipc	a0,0x4
ffffffffc0200b28:	abc50513          	addi	a0,a0,-1348 # ffffffffc02045e0 <commands+0x4b8>
{
ffffffffc0200b2c:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b2e:	db2ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b32:	8522                	mv	a0,s0
ffffffffc0200b34:	e1bff0ef          	jal	ra,ffffffffc020094e <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b38:	10043583          	ld	a1,256(s0)
ffffffffc0200b3c:	00004517          	auipc	a0,0x4
ffffffffc0200b40:	abc50513          	addi	a0,a0,-1348 # ffffffffc02045f8 <commands+0x4d0>
ffffffffc0200b44:	d9cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b48:	10843583          	ld	a1,264(s0)
ffffffffc0200b4c:	00004517          	auipc	a0,0x4
ffffffffc0200b50:	ac450513          	addi	a0,a0,-1340 # ffffffffc0204610 <commands+0x4e8>
ffffffffc0200b54:	d8cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b58:	11043583          	ld	a1,272(s0)
ffffffffc0200b5c:	00004517          	auipc	a0,0x4
ffffffffc0200b60:	acc50513          	addi	a0,a0,-1332 # ffffffffc0204628 <commands+0x500>
ffffffffc0200b64:	d7cff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b68:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b6c:	6402                	ld	s0,0(sp)
ffffffffc0200b6e:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b70:	00004517          	auipc	a0,0x4
ffffffffc0200b74:	ad050513          	addi	a0,a0,-1328 # ffffffffc0204640 <commands+0x518>
}
ffffffffc0200b78:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b7a:	d66ff06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0200b7e <interrupt_handler>:

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b7e:	11853783          	ld	a5,280(a0)
ffffffffc0200b82:	472d                	li	a4,11
ffffffffc0200b84:	0786                	slli	a5,a5,0x1
ffffffffc0200b86:	8385                	srli	a5,a5,0x1
ffffffffc0200b88:	08f76563          	bltu	a4,a5,ffffffffc0200c12 <interrupt_handler+0x94>
ffffffffc0200b8c:	00004717          	auipc	a4,0x4
ffffffffc0200b90:	b9470713          	addi	a4,a4,-1132 # ffffffffc0204720 <commands+0x5f8>
ffffffffc0200b94:	078a                	slli	a5,a5,0x2
ffffffffc0200b96:	97ba                	add	a5,a5,a4
ffffffffc0200b98:	439c                	lw	a5,0(a5)
ffffffffc0200b9a:	97ba                	add	a5,a5,a4
ffffffffc0200b9c:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b9e:	00004517          	auipc	a0,0x4
ffffffffc0200ba2:	b1a50513          	addi	a0,a0,-1254 # ffffffffc02046b8 <commands+0x590>
ffffffffc0200ba6:	d3aff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200baa:	00004517          	auipc	a0,0x4
ffffffffc0200bae:	aee50513          	addi	a0,a0,-1298 # ffffffffc0204698 <commands+0x570>
ffffffffc0200bb2:	d2eff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200bb6:	00004517          	auipc	a0,0x4
ffffffffc0200bba:	aa250513          	addi	a0,a0,-1374 # ffffffffc0204658 <commands+0x530>
ffffffffc0200bbe:	d22ff06f          	j	ffffffffc02000e0 <cprintf>
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
ffffffffc0200bc2:	00004517          	auipc	a0,0x4
ffffffffc0200bc6:	b1650513          	addi	a0,a0,-1258 # ffffffffc02046d8 <commands+0x5b0>
ffffffffc0200bca:	d16ff06f          	j	ffffffffc02000e0 <cprintf>
{
ffffffffc0200bce:	1141                	addi	sp,sp,-16
ffffffffc0200bd0:	e022                	sd	s0,0(sp)
ffffffffc0200bd2:	e406                	sd	ra,8(sp)
         * (4)判断打印次数,当打印次数为10时，调用<sbi.h>中的关机函数关机
         */
        // (1) 设置下次时钟中断
        clock_set_next_event();
        // (2) 计数器加一
        ticks++;
ffffffffc0200bd4:	0000d417          	auipc	s0,0xd
ffffffffc0200bd8:	8ac40413          	addi	s0,s0,-1876 # ffffffffc020d480 <ticks>
        clock_set_next_event();
ffffffffc0200bdc:	cc7ff0ef          	jal	ra,ffffffffc02008a2 <clock_set_next_event>
        ticks++;
ffffffffc0200be0:	601c                	ld	a5,0(s0)
        // (3) 每100次时钟中断打印一次
        if (ticks % TICK_NUM == 0)
ffffffffc0200be2:	06400713          	li	a4,100
        ticks++;
ffffffffc0200be6:	0785                	addi	a5,a5,1
ffffffffc0200be8:	e01c                	sd	a5,0(s0)
        if (ticks % TICK_NUM == 0)
ffffffffc0200bea:	601c                	ld	a5,0(s0)
ffffffffc0200bec:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200bf0:	c395                	beqz	a5,ffffffffc0200c14 <interrupt_handler+0x96>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bf2:	60a2                	ld	ra,8(sp)
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	0141                	addi	sp,sp,16
ffffffffc0200bf8:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bfa:	00004517          	auipc	a0,0x4
ffffffffc0200bfe:	b0650513          	addi	a0,a0,-1274 # ffffffffc0204700 <commands+0x5d8>
ffffffffc0200c02:	cdeff06f          	j	ffffffffc02000e0 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c06:	00004517          	auipc	a0,0x4
ffffffffc0200c0a:	a7250513          	addi	a0,a0,-1422 # ffffffffc0204678 <commands+0x550>
ffffffffc0200c0e:	cd2ff06f          	j	ffffffffc02000e0 <cprintf>
        print_trapframe(tf);
ffffffffc0200c12:	b729                	j	ffffffffc0200b1c <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c14:	06400593          	li	a1,100
ffffffffc0200c18:	00004517          	auipc	a0,0x4
ffffffffc0200c1c:	ad850513          	addi	a0,a0,-1320 # ffffffffc02046f0 <commands+0x5c8>
ffffffffc0200c20:	cc0ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
            if (ticks / TICK_NUM == 10)
ffffffffc0200c24:	601c                	ld	a5,0(s0)
ffffffffc0200c26:	06300713          	li	a4,99
ffffffffc0200c2a:	c1878793          	addi	a5,a5,-1000
ffffffffc0200c2e:	fcf762e3          	bltu	a4,a5,ffffffffc0200bf2 <interrupt_handler+0x74>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200c32:	4501                	li	a0,0
ffffffffc0200c34:	4581                	li	a1,0
ffffffffc0200c36:	4601                	li	a2,0
ffffffffc0200c38:	48a1                	li	a7,8
ffffffffc0200c3a:	00000073          	ecall
}
ffffffffc0200c3e:	bf55                	j	ffffffffc0200bf2 <interrupt_handler+0x74>

ffffffffc0200c40 <exception_handler>:

void exception_handler(struct trapframe *tf)
{
ffffffffc0200c40:	1101                	addi	sp,sp,-32
ffffffffc0200c42:	e822                	sd	s0,16(sp)
    switch (tf->cause)
ffffffffc0200c44:	11853403          	ld	s0,280(a0)
{
ffffffffc0200c48:	e426                	sd	s1,8(sp)
ffffffffc0200c4a:	e04a                	sd	s2,0(sp)
ffffffffc0200c4c:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200c4e:	490d                	li	s2,3
{
ffffffffc0200c50:	84aa                	mv	s1,a0
    switch (tf->cause)
ffffffffc0200c52:	05240f63          	beq	s0,s2,ffffffffc0200cb0 <exception_handler+0x70>
ffffffffc0200c56:	04896363          	bltu	s2,s0,ffffffffc0200c9c <exception_handler+0x5c>
ffffffffc0200c5a:	4789                	li	a5,2
ffffffffc0200c5c:	02f41a63          	bne	s0,a5,ffffffffc0200c90 <exception_handler+0x50>
        /*(1)输出指令异常类型（ Illegal instruction）
         *(2)输出异常指令地址
         *(3)更新 tf->epc寄存器
         */
        // (1) 输出异常类型
        cprintf("Exception type: Illegal instruction\n");
ffffffffc0200c60:	00004517          	auipc	a0,0x4
ffffffffc0200c64:	af050513          	addi	a0,a0,-1296 # ffffffffc0204750 <commands+0x628>
ffffffffc0200c68:	c78ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        // (2) 输出异常指令地址
        cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200c6c:	1084b583          	ld	a1,264(s1)
ffffffffc0200c70:	00004517          	auipc	a0,0x4
ffffffffc0200c74:	b0850513          	addi	a0,a0,-1272 # ffffffffc0204778 <commands+0x650>
ffffffffc0200c78:	c68ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        // (3) 更新epc寄存器
        // 检查指令长度：RISC-V压缩指令(C扩展)长度为2字节，标准指令长度为4字节
        // 指令的最低2位如果不是11，则是压缩指令(16位)，否则是标准指令(32位)
        unsigned int instruction = *(unsigned short *)tf->epc;
ffffffffc0200c7c:	1084b783          	ld	a5,264(s1)
        if ((instruction & 0x3) != 0x3)
ffffffffc0200c80:	0007d703          	lhu	a4,0(a5)
ffffffffc0200c84:	8b0d                	andi	a4,a4,3
ffffffffc0200c86:	05270a63          	beq	a4,s2,ffffffffc0200cda <exception_handler+0x9a>
        // 检查指令长度：RISC-V压缩指令(C扩展)长度为2字节，标准指令长度为4字节
        // ebreak可能是压缩指令c.ebreak(2字节)或标准ebreak(4字节)
        unsigned int inst = *(unsigned short *)tf->epc;
        if ((inst & 0x3) != 0x3)
        {
            tf->epc += 2; // 压缩指令，长度2字节
ffffffffc0200c8a:	0789                	addi	a5,a5,2
ffffffffc0200c8c:	10f4b423          	sd	a5,264(s1)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c90:	60e2                	ld	ra,24(sp)
ffffffffc0200c92:	6442                	ld	s0,16(sp)
ffffffffc0200c94:	64a2                	ld	s1,8(sp)
ffffffffc0200c96:	6902                	ld	s2,0(sp)
ffffffffc0200c98:	6105                	addi	sp,sp,32
ffffffffc0200c9a:	8082                	ret
    switch (tf->cause)
ffffffffc0200c9c:	1471                	addi	s0,s0,-4
ffffffffc0200c9e:	479d                	li	a5,7
ffffffffc0200ca0:	fe87f8e3          	bgeu	a5,s0,ffffffffc0200c90 <exception_handler+0x50>
}
ffffffffc0200ca4:	6442                	ld	s0,16(sp)
ffffffffc0200ca6:	60e2                	ld	ra,24(sp)
ffffffffc0200ca8:	64a2                	ld	s1,8(sp)
ffffffffc0200caa:	6902                	ld	s2,0(sp)
ffffffffc0200cac:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200cae:	b5bd                	j	ffffffffc0200b1c <print_trapframe>
        cprintf("Exception type: breakpoint\n");
ffffffffc0200cb0:	00004517          	auipc	a0,0x4
ffffffffc0200cb4:	af050513          	addi	a0,a0,-1296 # ffffffffc02047a0 <commands+0x678>
ffffffffc0200cb8:	c28ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200cbc:	1084b583          	ld	a1,264(s1)
ffffffffc0200cc0:	00004517          	auipc	a0,0x4
ffffffffc0200cc4:	b0050513          	addi	a0,a0,-1280 # ffffffffc02047c0 <commands+0x698>
ffffffffc0200cc8:	c18ff0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        unsigned int inst = *(unsigned short *)tf->epc;
ffffffffc0200ccc:	1084b783          	ld	a5,264(s1)
        if ((inst & 0x3) != 0x3)
ffffffffc0200cd0:	0007d703          	lhu	a4,0(a5)
ffffffffc0200cd4:	8b0d                	andi	a4,a4,3
ffffffffc0200cd6:	fa871ae3          	bne	a4,s0,ffffffffc0200c8a <exception_handler+0x4a>
}
ffffffffc0200cda:	60e2                	ld	ra,24(sp)
ffffffffc0200cdc:	6442                	ld	s0,16(sp)
            tf->epc += 4; // 标准指令，长度4字节
ffffffffc0200cde:	0791                	addi	a5,a5,4
ffffffffc0200ce0:	10f4b423          	sd	a5,264(s1)
}
ffffffffc0200ce4:	6902                	ld	s2,0(sp)
ffffffffc0200ce6:	64a2                	ld	s1,8(sp)
ffffffffc0200ce8:	6105                	addi	sp,sp,32
ffffffffc0200cea:	8082                	ret

ffffffffc0200cec <trap>:

static inline void trap_dispatch(struct trapframe *tf)
{
    if ((intptr_t)tf->cause < 0)
ffffffffc0200cec:	11853783          	ld	a5,280(a0)
ffffffffc0200cf0:	0007c363          	bltz	a5,ffffffffc0200cf6 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200cf4:	b7b1                	j	ffffffffc0200c40 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200cf6:	b561                	j	ffffffffc0200b7e <interrupt_handler>

ffffffffc0200cf8 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200cf8:	14011073          	csrw	sscratch,sp
ffffffffc0200cfc:	712d                	addi	sp,sp,-288
ffffffffc0200cfe:	e406                	sd	ra,8(sp)
ffffffffc0200d00:	ec0e                	sd	gp,24(sp)
ffffffffc0200d02:	f012                	sd	tp,32(sp)
ffffffffc0200d04:	f416                	sd	t0,40(sp)
ffffffffc0200d06:	f81a                	sd	t1,48(sp)
ffffffffc0200d08:	fc1e                	sd	t2,56(sp)
ffffffffc0200d0a:	e0a2                	sd	s0,64(sp)
ffffffffc0200d0c:	e4a6                	sd	s1,72(sp)
ffffffffc0200d0e:	e8aa                	sd	a0,80(sp)
ffffffffc0200d10:	ecae                	sd	a1,88(sp)
ffffffffc0200d12:	f0b2                	sd	a2,96(sp)
ffffffffc0200d14:	f4b6                	sd	a3,104(sp)
ffffffffc0200d16:	f8ba                	sd	a4,112(sp)
ffffffffc0200d18:	fcbe                	sd	a5,120(sp)
ffffffffc0200d1a:	e142                	sd	a6,128(sp)
ffffffffc0200d1c:	e546                	sd	a7,136(sp)
ffffffffc0200d1e:	e94a                	sd	s2,144(sp)
ffffffffc0200d20:	ed4e                	sd	s3,152(sp)
ffffffffc0200d22:	f152                	sd	s4,160(sp)
ffffffffc0200d24:	f556                	sd	s5,168(sp)
ffffffffc0200d26:	f95a                	sd	s6,176(sp)
ffffffffc0200d28:	fd5e                	sd	s7,184(sp)
ffffffffc0200d2a:	e1e2                	sd	s8,192(sp)
ffffffffc0200d2c:	e5e6                	sd	s9,200(sp)
ffffffffc0200d2e:	e9ea                	sd	s10,208(sp)
ffffffffc0200d30:	edee                	sd	s11,216(sp)
ffffffffc0200d32:	f1f2                	sd	t3,224(sp)
ffffffffc0200d34:	f5f6                	sd	t4,232(sp)
ffffffffc0200d36:	f9fa                	sd	t5,240(sp)
ffffffffc0200d38:	fdfe                	sd	t6,248(sp)
ffffffffc0200d3a:	14002473          	csrr	s0,sscratch
ffffffffc0200d3e:	100024f3          	csrr	s1,sstatus
ffffffffc0200d42:	14102973          	csrr	s2,sepc
ffffffffc0200d46:	143029f3          	csrr	s3,stval
ffffffffc0200d4a:	14202a73          	csrr	s4,scause
ffffffffc0200d4e:	e822                	sd	s0,16(sp)
ffffffffc0200d50:	e226                	sd	s1,256(sp)
ffffffffc0200d52:	e64a                	sd	s2,264(sp)
ffffffffc0200d54:	ea4e                	sd	s3,272(sp)
ffffffffc0200d56:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d58:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d5a:	f93ff0ef          	jal	ra,ffffffffc0200cec <trap>

ffffffffc0200d5e <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d5e:	6492                	ld	s1,256(sp)
ffffffffc0200d60:	6932                	ld	s2,264(sp)
ffffffffc0200d62:	10049073          	csrw	sstatus,s1
ffffffffc0200d66:	14191073          	csrw	sepc,s2
ffffffffc0200d6a:	60a2                	ld	ra,8(sp)
ffffffffc0200d6c:	61e2                	ld	gp,24(sp)
ffffffffc0200d6e:	7202                	ld	tp,32(sp)
ffffffffc0200d70:	72a2                	ld	t0,40(sp)
ffffffffc0200d72:	7342                	ld	t1,48(sp)
ffffffffc0200d74:	73e2                	ld	t2,56(sp)
ffffffffc0200d76:	6406                	ld	s0,64(sp)
ffffffffc0200d78:	64a6                	ld	s1,72(sp)
ffffffffc0200d7a:	6546                	ld	a0,80(sp)
ffffffffc0200d7c:	65e6                	ld	a1,88(sp)
ffffffffc0200d7e:	7606                	ld	a2,96(sp)
ffffffffc0200d80:	76a6                	ld	a3,104(sp)
ffffffffc0200d82:	7746                	ld	a4,112(sp)
ffffffffc0200d84:	77e6                	ld	a5,120(sp)
ffffffffc0200d86:	680a                	ld	a6,128(sp)
ffffffffc0200d88:	68aa                	ld	a7,136(sp)
ffffffffc0200d8a:	694a                	ld	s2,144(sp)
ffffffffc0200d8c:	69ea                	ld	s3,152(sp)
ffffffffc0200d8e:	7a0a                	ld	s4,160(sp)
ffffffffc0200d90:	7aaa                	ld	s5,168(sp)
ffffffffc0200d92:	7b4a                	ld	s6,176(sp)
ffffffffc0200d94:	7bea                	ld	s7,184(sp)
ffffffffc0200d96:	6c0e                	ld	s8,192(sp)
ffffffffc0200d98:	6cae                	ld	s9,200(sp)
ffffffffc0200d9a:	6d4e                	ld	s10,208(sp)
ffffffffc0200d9c:	6dee                	ld	s11,216(sp)
ffffffffc0200d9e:	7e0e                	ld	t3,224(sp)
ffffffffc0200da0:	7eae                	ld	t4,232(sp)
ffffffffc0200da2:	7f4e                	ld	t5,240(sp)
ffffffffc0200da4:	7fee                	ld	t6,248(sp)
ffffffffc0200da6:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200da8:	10200073          	sret

ffffffffc0200dac <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200dac:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200dae:	bf45                	j	ffffffffc0200d5e <__trapret>
	...

ffffffffc0200db2 <pa2page.part.0>:
{
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *
pa2page(uintptr_t pa)
ffffffffc0200db2:	1141                	addi	sp,sp,-16
{
    if (PPN(pa) >= npage)
    {
        panic("pa2page called with invalid pa");
ffffffffc0200db4:	00004617          	auipc	a2,0x4
ffffffffc0200db8:	a2c60613          	addi	a2,a2,-1492 # ffffffffc02047e0 <commands+0x6b8>
ffffffffc0200dbc:	06900593          	li	a1,105
ffffffffc0200dc0:	00004517          	auipc	a0,0x4
ffffffffc0200dc4:	a4050513          	addi	a0,a0,-1472 # ffffffffc0204800 <commands+0x6d8>
pa2page(uintptr_t pa)
ffffffffc0200dc8:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200dca:	c14ff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0200dce <pte2page.part.0>:
{
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte)
ffffffffc0200dce:	1141                	addi	sp,sp,-16
{
    if (!(pte & PTE_V))
    {
        panic("pte2page called with invalid pte");
ffffffffc0200dd0:	00004617          	auipc	a2,0x4
ffffffffc0200dd4:	a4060613          	addi	a2,a2,-1472 # ffffffffc0204810 <commands+0x6e8>
ffffffffc0200dd8:	07f00593          	li	a1,127
ffffffffc0200ddc:	00004517          	auipc	a0,0x4
ffffffffc0200de0:	a2450513          	addi	a0,a0,-1500 # ffffffffc0204800 <commands+0x6d8>
pte2page(pte_t pte)
ffffffffc0200de4:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0200de6:	bf8ff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0200dea <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200dea:	100027f3          	csrr	a5,sstatus
ffffffffc0200dee:	8b89                	andi	a5,a5,2
ffffffffc0200df0:	e799                	bnez	a5,ffffffffc0200dfe <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200df2:	0000c797          	auipc	a5,0xc
ffffffffc0200df6:	6be7b783          	ld	a5,1726(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200dfa:	6f9c                	ld	a5,24(a5)
ffffffffc0200dfc:	8782                	jr	a5
{
ffffffffc0200dfe:	1141                	addi	sp,sp,-16
ffffffffc0200e00:	e406                	sd	ra,8(sp)
ffffffffc0200e02:	e022                	sd	s0,0(sp)
ffffffffc0200e04:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200e06:	b31ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200e0a:	0000c797          	auipc	a5,0xc
ffffffffc0200e0e:	6a67b783          	ld	a5,1702(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200e12:	6f9c                	ld	a5,24(a5)
ffffffffc0200e14:	8522                	mv	a0,s0
ffffffffc0200e16:	9782                	jalr	a5
ffffffffc0200e18:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200e1a:	b17ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200e1e:	60a2                	ld	ra,8(sp)
ffffffffc0200e20:	8522                	mv	a0,s0
ffffffffc0200e22:	6402                	ld	s0,0(sp)
ffffffffc0200e24:	0141                	addi	sp,sp,16
ffffffffc0200e26:	8082                	ret

ffffffffc0200e28 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200e28:	100027f3          	csrr	a5,sstatus
ffffffffc0200e2c:	8b89                	andi	a5,a5,2
ffffffffc0200e2e:	e799                	bnez	a5,ffffffffc0200e3c <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200e30:	0000c797          	auipc	a5,0xc
ffffffffc0200e34:	6807b783          	ld	a5,1664(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200e38:	739c                	ld	a5,32(a5)
ffffffffc0200e3a:	8782                	jr	a5
{
ffffffffc0200e3c:	1101                	addi	sp,sp,-32
ffffffffc0200e3e:	ec06                	sd	ra,24(sp)
ffffffffc0200e40:	e822                	sd	s0,16(sp)
ffffffffc0200e42:	e426                	sd	s1,8(sp)
ffffffffc0200e44:	842a                	mv	s0,a0
ffffffffc0200e46:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200e48:	aefff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200e4c:	0000c797          	auipc	a5,0xc
ffffffffc0200e50:	6647b783          	ld	a5,1636(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200e54:	739c                	ld	a5,32(a5)
ffffffffc0200e56:	85a6                	mv	a1,s1
ffffffffc0200e58:	8522                	mv	a0,s0
ffffffffc0200e5a:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200e5c:	6442                	ld	s0,16(sp)
ffffffffc0200e5e:	60e2                	ld	ra,24(sp)
ffffffffc0200e60:	64a2                	ld	s1,8(sp)
ffffffffc0200e62:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200e64:	b4f1                	j	ffffffffc0200930 <intr_enable>

ffffffffc0200e66 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200e66:	100027f3          	csrr	a5,sstatus
ffffffffc0200e6a:	8b89                	andi	a5,a5,2
ffffffffc0200e6c:	e799                	bnez	a5,ffffffffc0200e7a <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200e6e:	0000c797          	auipc	a5,0xc
ffffffffc0200e72:	6427b783          	ld	a5,1602(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200e76:	779c                	ld	a5,40(a5)
ffffffffc0200e78:	8782                	jr	a5
{
ffffffffc0200e7a:	1141                	addi	sp,sp,-16
ffffffffc0200e7c:	e406                	sd	ra,8(sp)
ffffffffc0200e7e:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200e80:	ab7ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200e84:	0000c797          	auipc	a5,0xc
ffffffffc0200e88:	62c7b783          	ld	a5,1580(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200e8c:	779c                	ld	a5,40(a5)
ffffffffc0200e8e:	9782                	jalr	a5
ffffffffc0200e90:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200e92:	a9fff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200e96:	60a2                	ld	ra,8(sp)
ffffffffc0200e98:	8522                	mv	a0,s0
ffffffffc0200e9a:	6402                	ld	s0,0(sp)
ffffffffc0200e9c:	0141                	addi	sp,sp,16
ffffffffc0200e9e:	8082                	ret

ffffffffc0200ea0 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200ea0:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0200ea4:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0200ea8:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200eaa:	078e                	slli	a5,a5,0x3
{
ffffffffc0200eac:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200eae:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0200eb2:	6094                	ld	a3,0(s1)
{
ffffffffc0200eb4:	f04a                	sd	s2,32(sp)
ffffffffc0200eb6:	ec4e                	sd	s3,24(sp)
ffffffffc0200eb8:	e852                	sd	s4,16(sp)
ffffffffc0200eba:	fc06                	sd	ra,56(sp)
ffffffffc0200ebc:	f822                	sd	s0,48(sp)
ffffffffc0200ebe:	e456                	sd	s5,8(sp)
ffffffffc0200ec0:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0200ec2:	0016f793          	andi	a5,a3,1
{
ffffffffc0200ec6:	892e                	mv	s2,a1
ffffffffc0200ec8:	8a32                	mv	s4,a2
ffffffffc0200eca:	0000c997          	auipc	s3,0xc
ffffffffc0200ece:	5d698993          	addi	s3,s3,1494 # ffffffffc020d4a0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0200ed2:	efbd                	bnez	a5,ffffffffc0200f50 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200ed4:	14060c63          	beqz	a2,ffffffffc020102c <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200ed8:	100027f3          	csrr	a5,sstatus
ffffffffc0200edc:	8b89                	andi	a5,a5,2
ffffffffc0200ede:	14079963          	bnez	a5,ffffffffc0201030 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200ee2:	0000c797          	auipc	a5,0xc
ffffffffc0200ee6:	5ce7b783          	ld	a5,1486(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200eea:	6f9c                	ld	a5,24(a5)
ffffffffc0200eec:	4505                	li	a0,1
ffffffffc0200eee:	9782                	jalr	a5
ffffffffc0200ef0:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200ef2:	12040d63          	beqz	s0,ffffffffc020102c <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0200ef6:	0000cb17          	auipc	s6,0xc
ffffffffc0200efa:	5b2b0b13          	addi	s6,s6,1458 # ffffffffc020d4a8 <pages>
ffffffffc0200efe:	000b3503          	ld	a0,0(s6)
ffffffffc0200f02:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200f06:	0000c997          	auipc	s3,0xc
ffffffffc0200f0a:	59a98993          	addi	s3,s3,1434 # ffffffffc020d4a0 <npage>
ffffffffc0200f0e:	40a40533          	sub	a0,s0,a0
ffffffffc0200f12:	8519                	srai	a0,a0,0x6
ffffffffc0200f14:	9556                	add	a0,a0,s5
ffffffffc0200f16:	0009b703          	ld	a4,0(s3)
ffffffffc0200f1a:	00c51793          	slli	a5,a0,0xc
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0200f1e:	4685                	li	a3,1
ffffffffc0200f20:	c014                	sw	a3,0(s0)
ffffffffc0200f22:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f24:	0532                	slli	a0,a0,0xc
ffffffffc0200f26:	16e7f763          	bgeu	a5,a4,ffffffffc0201094 <get_pte+0x1f4>
ffffffffc0200f2a:	0000c797          	auipc	a5,0xc
ffffffffc0200f2e:	58e7b783          	ld	a5,1422(a5) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0200f32:	6605                	lui	a2,0x1
ffffffffc0200f34:	4581                	li	a1,0
ffffffffc0200f36:	953e                	add	a0,a0,a5
ffffffffc0200f38:	317020ef          	jal	ra,ffffffffc0203a4e <memset>
    return page - pages + nbase;
ffffffffc0200f3c:	000b3683          	ld	a3,0(s6)
ffffffffc0200f40:	40d406b3          	sub	a3,s0,a3
ffffffffc0200f44:	8699                	srai	a3,a3,0x6
ffffffffc0200f46:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200f48:	06aa                	slli	a3,a3,0xa
ffffffffc0200f4a:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200f4e:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0200f50:	77fd                	lui	a5,0xfffff
ffffffffc0200f52:	068a                	slli	a3,a3,0x2
ffffffffc0200f54:	0009b703          	ld	a4,0(s3)
ffffffffc0200f58:	8efd                	and	a3,a3,a5
ffffffffc0200f5a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200f5e:	10e7ff63          	bgeu	a5,a4,ffffffffc020107c <get_pte+0x1dc>
ffffffffc0200f62:	0000ca97          	auipc	s5,0xc
ffffffffc0200f66:	556a8a93          	addi	s5,s5,1366 # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0200f6a:	000ab403          	ld	s0,0(s5)
ffffffffc0200f6e:	01595793          	srli	a5,s2,0x15
ffffffffc0200f72:	1ff7f793          	andi	a5,a5,511
ffffffffc0200f76:	96a2                	add	a3,a3,s0
ffffffffc0200f78:	00379413          	slli	s0,a5,0x3
ffffffffc0200f7c:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0200f7e:	6014                	ld	a3,0(s0)
ffffffffc0200f80:	0016f793          	andi	a5,a3,1
ffffffffc0200f84:	ebad                	bnez	a5,ffffffffc0200ff6 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200f86:	0a0a0363          	beqz	s4,ffffffffc020102c <get_pte+0x18c>
ffffffffc0200f8a:	100027f3          	csrr	a5,sstatus
ffffffffc0200f8e:	8b89                	andi	a5,a5,2
ffffffffc0200f90:	efcd                	bnez	a5,ffffffffc020104a <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200f92:	0000c797          	auipc	a5,0xc
ffffffffc0200f96:	51e7b783          	ld	a5,1310(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0200f9a:	6f9c                	ld	a5,24(a5)
ffffffffc0200f9c:	4505                	li	a0,1
ffffffffc0200f9e:	9782                	jalr	a5
ffffffffc0200fa0:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0200fa2:	c4c9                	beqz	s1,ffffffffc020102c <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0200fa4:	0000cb17          	auipc	s6,0xc
ffffffffc0200fa8:	504b0b13          	addi	s6,s6,1284 # ffffffffc020d4a8 <pages>
ffffffffc0200fac:	000b3503          	ld	a0,0(s6)
ffffffffc0200fb0:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0200fb4:	0009b703          	ld	a4,0(s3)
ffffffffc0200fb8:	40a48533          	sub	a0,s1,a0
ffffffffc0200fbc:	8519                	srai	a0,a0,0x6
ffffffffc0200fbe:	9552                	add	a0,a0,s4
ffffffffc0200fc0:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0200fc4:	4685                	li	a3,1
ffffffffc0200fc6:	c094                	sw	a3,0(s1)
ffffffffc0200fc8:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200fca:	0532                	slli	a0,a0,0xc
ffffffffc0200fcc:	0ee7f163          	bgeu	a5,a4,ffffffffc02010ae <get_pte+0x20e>
ffffffffc0200fd0:	000ab783          	ld	a5,0(s5)
ffffffffc0200fd4:	6605                	lui	a2,0x1
ffffffffc0200fd6:	4581                	li	a1,0
ffffffffc0200fd8:	953e                	add	a0,a0,a5
ffffffffc0200fda:	275020ef          	jal	ra,ffffffffc0203a4e <memset>
    return page - pages + nbase;
ffffffffc0200fde:	000b3683          	ld	a3,0(s6)
ffffffffc0200fe2:	40d486b3          	sub	a3,s1,a3
ffffffffc0200fe6:	8699                	srai	a3,a3,0x6
ffffffffc0200fe8:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0200fea:	06aa                	slli	a3,a3,0xa
ffffffffc0200fec:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0200ff0:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0200ff2:	0009b703          	ld	a4,0(s3)
ffffffffc0200ff6:	068a                	slli	a3,a3,0x2
ffffffffc0200ff8:	757d                	lui	a0,0xfffff
ffffffffc0200ffa:	8ee9                	and	a3,a3,a0
ffffffffc0200ffc:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201000:	06e7f263          	bgeu	a5,a4,ffffffffc0201064 <get_pte+0x1c4>
ffffffffc0201004:	000ab503          	ld	a0,0(s5)
ffffffffc0201008:	00c95913          	srli	s2,s2,0xc
ffffffffc020100c:	1ff97913          	andi	s2,s2,511
ffffffffc0201010:	96aa                	add	a3,a3,a0
ffffffffc0201012:	00391513          	slli	a0,s2,0x3
ffffffffc0201016:	9536                	add	a0,a0,a3
}
ffffffffc0201018:	70e2                	ld	ra,56(sp)
ffffffffc020101a:	7442                	ld	s0,48(sp)
ffffffffc020101c:	74a2                	ld	s1,40(sp)
ffffffffc020101e:	7902                	ld	s2,32(sp)
ffffffffc0201020:	69e2                	ld	s3,24(sp)
ffffffffc0201022:	6a42                	ld	s4,16(sp)
ffffffffc0201024:	6aa2                	ld	s5,8(sp)
ffffffffc0201026:	6b02                	ld	s6,0(sp)
ffffffffc0201028:	6121                	addi	sp,sp,64
ffffffffc020102a:	8082                	ret
            return NULL;
ffffffffc020102c:	4501                	li	a0,0
ffffffffc020102e:	b7ed                	j	ffffffffc0201018 <get_pte+0x178>
        intr_disable();
ffffffffc0201030:	907ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201034:	0000c797          	auipc	a5,0xc
ffffffffc0201038:	47c7b783          	ld	a5,1148(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc020103c:	6f9c                	ld	a5,24(a5)
ffffffffc020103e:	4505                	li	a0,1
ffffffffc0201040:	9782                	jalr	a5
ffffffffc0201042:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201044:	8edff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201048:	b56d                	j	ffffffffc0200ef2 <get_pte+0x52>
        intr_disable();
ffffffffc020104a:	8edff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc020104e:	0000c797          	auipc	a5,0xc
ffffffffc0201052:	4627b783          	ld	a5,1122(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0201056:	6f9c                	ld	a5,24(a5)
ffffffffc0201058:	4505                	li	a0,1
ffffffffc020105a:	9782                	jalr	a5
ffffffffc020105c:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc020105e:	8d3ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201062:	b781                	j	ffffffffc0200fa2 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201064:	00003617          	auipc	a2,0x3
ffffffffc0201068:	7d460613          	addi	a2,a2,2004 # ffffffffc0204838 <commands+0x710>
ffffffffc020106c:	0fb00593          	li	a1,251
ffffffffc0201070:	00003517          	auipc	a0,0x3
ffffffffc0201074:	7f050513          	addi	a0,a0,2032 # ffffffffc0204860 <commands+0x738>
ffffffffc0201078:	966ff0ef          	jal	ra,ffffffffc02001de <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020107c:	00003617          	auipc	a2,0x3
ffffffffc0201080:	7bc60613          	addi	a2,a2,1980 # ffffffffc0204838 <commands+0x710>
ffffffffc0201084:	0ee00593          	li	a1,238
ffffffffc0201088:	00003517          	auipc	a0,0x3
ffffffffc020108c:	7d850513          	addi	a0,a0,2008 # ffffffffc0204860 <commands+0x738>
ffffffffc0201090:	94eff0ef          	jal	ra,ffffffffc02001de <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201094:	86aa                	mv	a3,a0
ffffffffc0201096:	00003617          	auipc	a2,0x3
ffffffffc020109a:	7a260613          	addi	a2,a2,1954 # ffffffffc0204838 <commands+0x710>
ffffffffc020109e:	0eb00593          	li	a1,235
ffffffffc02010a2:	00003517          	auipc	a0,0x3
ffffffffc02010a6:	7be50513          	addi	a0,a0,1982 # ffffffffc0204860 <commands+0x738>
ffffffffc02010aa:	934ff0ef          	jal	ra,ffffffffc02001de <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02010ae:	86aa                	mv	a3,a0
ffffffffc02010b0:	00003617          	auipc	a2,0x3
ffffffffc02010b4:	78860613          	addi	a2,a2,1928 # ffffffffc0204838 <commands+0x710>
ffffffffc02010b8:	0f800593          	li	a1,248
ffffffffc02010bc:	00003517          	auipc	a0,0x3
ffffffffc02010c0:	7a450513          	addi	a0,a0,1956 # ffffffffc0204860 <commands+0x738>
ffffffffc02010c4:	91aff0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02010c8 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02010c8:	1141                	addi	sp,sp,-16
ffffffffc02010ca:	e022                	sd	s0,0(sp)
ffffffffc02010cc:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02010ce:	4601                	li	a2,0
{
ffffffffc02010d0:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02010d2:	dcfff0ef          	jal	ra,ffffffffc0200ea0 <get_pte>
    if (ptep_store != NULL)
ffffffffc02010d6:	c011                	beqz	s0,ffffffffc02010da <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02010d8:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02010da:	c511                	beqz	a0,ffffffffc02010e6 <get_page+0x1e>
ffffffffc02010dc:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02010de:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02010e0:	0017f713          	andi	a4,a5,1
ffffffffc02010e4:	e709                	bnez	a4,ffffffffc02010ee <get_page+0x26>
}
ffffffffc02010e6:	60a2                	ld	ra,8(sp)
ffffffffc02010e8:	6402                	ld	s0,0(sp)
ffffffffc02010ea:	0141                	addi	sp,sp,16
ffffffffc02010ec:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02010ee:	078a                	slli	a5,a5,0x2
ffffffffc02010f0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02010f2:	0000c717          	auipc	a4,0xc
ffffffffc02010f6:	3ae73703          	ld	a4,942(a4) # ffffffffc020d4a0 <npage>
ffffffffc02010fa:	00e7ff63          	bgeu	a5,a4,ffffffffc0201118 <get_page+0x50>
ffffffffc02010fe:	60a2                	ld	ra,8(sp)
ffffffffc0201100:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201102:	fff80537          	lui	a0,0xfff80
ffffffffc0201106:	97aa                	add	a5,a5,a0
ffffffffc0201108:	079a                	slli	a5,a5,0x6
ffffffffc020110a:	0000c517          	auipc	a0,0xc
ffffffffc020110e:	39e53503          	ld	a0,926(a0) # ffffffffc020d4a8 <pages>
ffffffffc0201112:	953e                	add	a0,a0,a5
ffffffffc0201114:	0141                	addi	sp,sp,16
ffffffffc0201116:	8082                	ret
ffffffffc0201118:	c9bff0ef          	jal	ra,ffffffffc0200db2 <pa2page.part.0>

ffffffffc020111c <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc020111c:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020111e:	4601                	li	a2,0
{
ffffffffc0201120:	ec26                	sd	s1,24(sp)
ffffffffc0201122:	f406                	sd	ra,40(sp)
ffffffffc0201124:	f022                	sd	s0,32(sp)
ffffffffc0201126:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201128:	d79ff0ef          	jal	ra,ffffffffc0200ea0 <get_pte>
    if (ptep != NULL)
ffffffffc020112c:	c511                	beqz	a0,ffffffffc0201138 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc020112e:	611c                	ld	a5,0(a0)
ffffffffc0201130:	842a                	mv	s0,a0
ffffffffc0201132:	0017f713          	andi	a4,a5,1
ffffffffc0201136:	e711                	bnez	a4,ffffffffc0201142 <page_remove+0x26>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201138:	70a2                	ld	ra,40(sp)
ffffffffc020113a:	7402                	ld	s0,32(sp)
ffffffffc020113c:	64e2                	ld	s1,24(sp)
ffffffffc020113e:	6145                	addi	sp,sp,48
ffffffffc0201140:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201142:	078a                	slli	a5,a5,0x2
ffffffffc0201144:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201146:	0000c717          	auipc	a4,0xc
ffffffffc020114a:	35a73703          	ld	a4,858(a4) # ffffffffc020d4a0 <npage>
ffffffffc020114e:	06e7f363          	bgeu	a5,a4,ffffffffc02011b4 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201152:	fff80537          	lui	a0,0xfff80
ffffffffc0201156:	97aa                	add	a5,a5,a0
ffffffffc0201158:	079a                	slli	a5,a5,0x6
ffffffffc020115a:	0000c517          	auipc	a0,0xc
ffffffffc020115e:	34e53503          	ld	a0,846(a0) # ffffffffc020d4a8 <pages>
ffffffffc0201162:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201164:	411c                	lw	a5,0(a0)
ffffffffc0201166:	fff7871b          	addiw	a4,a5,-1
ffffffffc020116a:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020116c:	cb11                	beqz	a4,ffffffffc0201180 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc020116e:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201172:	12048073          	sfence.vma	s1
}
ffffffffc0201176:	70a2                	ld	ra,40(sp)
ffffffffc0201178:	7402                	ld	s0,32(sp)
ffffffffc020117a:	64e2                	ld	s1,24(sp)
ffffffffc020117c:	6145                	addi	sp,sp,48
ffffffffc020117e:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201180:	100027f3          	csrr	a5,sstatus
ffffffffc0201184:	8b89                	andi	a5,a5,2
ffffffffc0201186:	eb89                	bnez	a5,ffffffffc0201198 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0201188:	0000c797          	auipc	a5,0xc
ffffffffc020118c:	3287b783          	ld	a5,808(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0201190:	739c                	ld	a5,32(a5)
ffffffffc0201192:	4585                	li	a1,1
ffffffffc0201194:	9782                	jalr	a5
    if (flag) {
ffffffffc0201196:	bfe1                	j	ffffffffc020116e <page_remove+0x52>
        intr_disable();
ffffffffc0201198:	e42a                	sd	a0,8(sp)
ffffffffc020119a:	f9cff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc020119e:	0000c797          	auipc	a5,0xc
ffffffffc02011a2:	3127b783          	ld	a5,786(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc02011a6:	739c                	ld	a5,32(a5)
ffffffffc02011a8:	6522                	ld	a0,8(sp)
ffffffffc02011aa:	4585                	li	a1,1
ffffffffc02011ac:	9782                	jalr	a5
        intr_enable();
ffffffffc02011ae:	f82ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02011b2:	bf75                	j	ffffffffc020116e <page_remove+0x52>
ffffffffc02011b4:	bffff0ef          	jal	ra,ffffffffc0200db2 <pa2page.part.0>

ffffffffc02011b8 <page_insert>:
{
ffffffffc02011b8:	7139                	addi	sp,sp,-64
ffffffffc02011ba:	e852                	sd	s4,16(sp)
ffffffffc02011bc:	8a32                	mv	s4,a2
ffffffffc02011be:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02011c0:	4605                	li	a2,1
{
ffffffffc02011c2:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02011c4:	85d2                	mv	a1,s4
{
ffffffffc02011c6:	f426                	sd	s1,40(sp)
ffffffffc02011c8:	fc06                	sd	ra,56(sp)
ffffffffc02011ca:	f04a                	sd	s2,32(sp)
ffffffffc02011cc:	ec4e                	sd	s3,24(sp)
ffffffffc02011ce:	e456                	sd	s5,8(sp)
ffffffffc02011d0:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02011d2:	ccfff0ef          	jal	ra,ffffffffc0200ea0 <get_pte>
    if (ptep == NULL)
ffffffffc02011d6:	c961                	beqz	a0,ffffffffc02012a6 <page_insert+0xee>
    page->ref += 1;
ffffffffc02011d8:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc02011da:	611c                	ld	a5,0(a0)
ffffffffc02011dc:	89aa                	mv	s3,a0
ffffffffc02011de:	0016871b          	addiw	a4,a3,1
ffffffffc02011e2:	c018                	sw	a4,0(s0)
ffffffffc02011e4:	0017f713          	andi	a4,a5,1
ffffffffc02011e8:	ef05                	bnez	a4,ffffffffc0201220 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02011ea:	0000c717          	auipc	a4,0xc
ffffffffc02011ee:	2be73703          	ld	a4,702(a4) # ffffffffc020d4a8 <pages>
ffffffffc02011f2:	8c19                	sub	s0,s0,a4
ffffffffc02011f4:	000807b7          	lui	a5,0x80
ffffffffc02011f8:	8419                	srai	s0,s0,0x6
ffffffffc02011fa:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02011fc:	042a                	slli	s0,s0,0xa
ffffffffc02011fe:	8cc1                	or	s1,s1,s0
ffffffffc0201200:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0201204:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201208:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc020120c:	4501                	li	a0,0
}
ffffffffc020120e:	70e2                	ld	ra,56(sp)
ffffffffc0201210:	7442                	ld	s0,48(sp)
ffffffffc0201212:	74a2                	ld	s1,40(sp)
ffffffffc0201214:	7902                	ld	s2,32(sp)
ffffffffc0201216:	69e2                	ld	s3,24(sp)
ffffffffc0201218:	6a42                	ld	s4,16(sp)
ffffffffc020121a:	6aa2                	ld	s5,8(sp)
ffffffffc020121c:	6121                	addi	sp,sp,64
ffffffffc020121e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201220:	078a                	slli	a5,a5,0x2
ffffffffc0201222:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201224:	0000c717          	auipc	a4,0xc
ffffffffc0201228:	27c73703          	ld	a4,636(a4) # ffffffffc020d4a0 <npage>
ffffffffc020122c:	06e7ff63          	bgeu	a5,a4,ffffffffc02012aa <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0201230:	0000ca97          	auipc	s5,0xc
ffffffffc0201234:	278a8a93          	addi	s5,s5,632 # ffffffffc020d4a8 <pages>
ffffffffc0201238:	000ab703          	ld	a4,0(s5)
ffffffffc020123c:	fff80937          	lui	s2,0xfff80
ffffffffc0201240:	993e                	add	s2,s2,a5
ffffffffc0201242:	091a                	slli	s2,s2,0x6
ffffffffc0201244:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0201246:	01240c63          	beq	s0,s2,ffffffffc020125e <page_insert+0xa6>
    page->ref -= 1;
ffffffffc020124a:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd72b1c>
ffffffffc020124e:	fff7869b          	addiw	a3,a5,-1
ffffffffc0201252:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0201256:	c691                	beqz	a3,ffffffffc0201262 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201258:	120a0073          	sfence.vma	s4
}
ffffffffc020125c:	bf59                	j	ffffffffc02011f2 <page_insert+0x3a>
ffffffffc020125e:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201260:	bf49                	j	ffffffffc02011f2 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201262:	100027f3          	csrr	a5,sstatus
ffffffffc0201266:	8b89                	andi	a5,a5,2
ffffffffc0201268:	ef91                	bnez	a5,ffffffffc0201284 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc020126a:	0000c797          	auipc	a5,0xc
ffffffffc020126e:	2467b783          	ld	a5,582(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0201272:	739c                	ld	a5,32(a5)
ffffffffc0201274:	4585                	li	a1,1
ffffffffc0201276:	854a                	mv	a0,s2
ffffffffc0201278:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020127a:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020127e:	120a0073          	sfence.vma	s4
ffffffffc0201282:	bf85                	j	ffffffffc02011f2 <page_insert+0x3a>
        intr_disable();
ffffffffc0201284:	eb2ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201288:	0000c797          	auipc	a5,0xc
ffffffffc020128c:	2287b783          	ld	a5,552(a5) # ffffffffc020d4b0 <pmm_manager>
ffffffffc0201290:	739c                	ld	a5,32(a5)
ffffffffc0201292:	4585                	li	a1,1
ffffffffc0201294:	854a                	mv	a0,s2
ffffffffc0201296:	9782                	jalr	a5
        intr_enable();
ffffffffc0201298:	e98ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc020129c:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02012a0:	120a0073          	sfence.vma	s4
ffffffffc02012a4:	b7b9                	j	ffffffffc02011f2 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02012a6:	5571                	li	a0,-4
ffffffffc02012a8:	b79d                	j	ffffffffc020120e <page_insert+0x56>
ffffffffc02012aa:	b09ff0ef          	jal	ra,ffffffffc0200db2 <pa2page.part.0>

ffffffffc02012ae <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02012ae:	00004797          	auipc	a5,0x4
ffffffffc02012b2:	1da78793          	addi	a5,a5,474 # ffffffffc0205488 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012b6:	638c                	ld	a1,0(a5)
{
ffffffffc02012b8:	7159                	addi	sp,sp,-112
ffffffffc02012ba:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012bc:	00003517          	auipc	a0,0x3
ffffffffc02012c0:	5b450513          	addi	a0,a0,1460 # ffffffffc0204870 <commands+0x748>
    pmm_manager = &default_pmm_manager;
ffffffffc02012c4:	0000cb17          	auipc	s6,0xc
ffffffffc02012c8:	1ecb0b13          	addi	s6,s6,492 # ffffffffc020d4b0 <pmm_manager>
{
ffffffffc02012cc:	f486                	sd	ra,104(sp)
ffffffffc02012ce:	e8ca                	sd	s2,80(sp)
ffffffffc02012d0:	e4ce                	sd	s3,72(sp)
ffffffffc02012d2:	f0a2                	sd	s0,96(sp)
ffffffffc02012d4:	eca6                	sd	s1,88(sp)
ffffffffc02012d6:	e0d2                	sd	s4,64(sp)
ffffffffc02012d8:	fc56                	sd	s5,56(sp)
ffffffffc02012da:	f45e                	sd	s7,40(sp)
ffffffffc02012dc:	f062                	sd	s8,32(sp)
ffffffffc02012de:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02012e0:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012e4:	dfdfe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    pmm_manager->init();
ffffffffc02012e8:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02012ec:	0000c997          	auipc	s3,0xc
ffffffffc02012f0:	1cc98993          	addi	s3,s3,460 # ffffffffc020d4b8 <va_pa_offset>
    pmm_manager->init();
ffffffffc02012f4:	679c                	ld	a5,8(a5)
ffffffffc02012f6:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02012f8:	57f5                	li	a5,-3
ffffffffc02012fa:	07fa                	slli	a5,a5,0x1e
ffffffffc02012fc:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201300:	d54ff0ef          	jal	ra,ffffffffc0200854 <get_memory_base>
ffffffffc0201304:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201306:	d58ff0ef          	jal	ra,ffffffffc020085e <get_memory_size>
    if (mem_size == 0) {
ffffffffc020130a:	200505e3          	beqz	a0,ffffffffc0201d14 <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020130e:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0201310:	00003517          	auipc	a0,0x3
ffffffffc0201314:	59850513          	addi	a0,a0,1432 # ffffffffc02048a8 <commands+0x780>
ffffffffc0201318:	dc9fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020131c:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201320:	fff40693          	addi	a3,s0,-1
ffffffffc0201324:	864a                	mv	a2,s2
ffffffffc0201326:	85a6                	mv	a1,s1
ffffffffc0201328:	00003517          	auipc	a0,0x3
ffffffffc020132c:	59850513          	addi	a0,a0,1432 # ffffffffc02048c0 <commands+0x798>
ffffffffc0201330:	db1fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201334:	c8000737          	lui	a4,0xc8000
ffffffffc0201338:	87a2                	mv	a5,s0
ffffffffc020133a:	54876163          	bltu	a4,s0,ffffffffc020187c <pmm_init+0x5ce>
ffffffffc020133e:	757d                	lui	a0,0xfffff
ffffffffc0201340:	0000d617          	auipc	a2,0xd
ffffffffc0201344:	1a360613          	addi	a2,a2,419 # ffffffffc020e4e3 <end+0xfff>
ffffffffc0201348:	8e69                	and	a2,a2,a0
ffffffffc020134a:	0000c497          	auipc	s1,0xc
ffffffffc020134e:	15648493          	addi	s1,s1,342 # ffffffffc020d4a0 <npage>
ffffffffc0201352:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201356:	0000cb97          	auipc	s7,0xc
ffffffffc020135a:	152b8b93          	addi	s7,s7,338 # ffffffffc020d4a8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020135e:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201360:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201364:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201368:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020136a:	02f50863          	beq	a0,a5,ffffffffc020139a <pmm_init+0xec>
ffffffffc020136e:	4781                	li	a5,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201370:	4585                	li	a1,1
ffffffffc0201372:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201376:	00679513          	slli	a0,a5,0x6
ffffffffc020137a:	9532                	add	a0,a0,a2
ffffffffc020137c:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fdf1b24>
ffffffffc0201380:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201384:	6088                	ld	a0,0(s1)
ffffffffc0201386:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0201388:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020138c:	00d50733          	add	a4,a0,a3
ffffffffc0201390:	fee7e3e3          	bltu	a5,a4,ffffffffc0201376 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201394:	071a                	slli	a4,a4,0x6
ffffffffc0201396:	00e606b3          	add	a3,a2,a4
ffffffffc020139a:	c02007b7          	lui	a5,0xc0200
ffffffffc020139e:	2ef6ece3          	bltu	a3,a5,ffffffffc0201e96 <pmm_init+0xbe8>
ffffffffc02013a2:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02013a6:	77fd                	lui	a5,0xfffff
ffffffffc02013a8:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02013aa:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02013ac:	5086eb63          	bltu	a3,s0,ffffffffc02018c2 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02013b0:	00003517          	auipc	a0,0x3
ffffffffc02013b4:	56050513          	addi	a0,a0,1376 # ffffffffc0204910 <commands+0x7e8>
ffffffffc02013b8:	d29fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02013bc:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02013c0:	0000c917          	auipc	s2,0xc
ffffffffc02013c4:	0d890913          	addi	s2,s2,216 # ffffffffc020d498 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02013c8:	7b9c                	ld	a5,48(a5)
ffffffffc02013ca:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02013cc:	00003517          	auipc	a0,0x3
ffffffffc02013d0:	55c50513          	addi	a0,a0,1372 # ffffffffc0204928 <commands+0x800>
ffffffffc02013d4:	d0dfe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02013d8:	00007697          	auipc	a3,0x7
ffffffffc02013dc:	c2868693          	addi	a3,a3,-984 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc02013e0:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02013e4:	c02007b7          	lui	a5,0xc0200
ffffffffc02013e8:	28f6ebe3          	bltu	a3,a5,ffffffffc0201e7e <pmm_init+0xbd0>
ffffffffc02013ec:	0009b783          	ld	a5,0(s3)
ffffffffc02013f0:	8e9d                	sub	a3,a3,a5
ffffffffc02013f2:	0000c797          	auipc	a5,0xc
ffffffffc02013f6:	08d7bf23          	sd	a3,158(a5) # ffffffffc020d490 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02013fa:	100027f3          	csrr	a5,sstatus
ffffffffc02013fe:	8b89                	andi	a5,a5,2
ffffffffc0201400:	4a079763          	bnez	a5,ffffffffc02018ae <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201404:	000b3783          	ld	a5,0(s6)
ffffffffc0201408:	779c                	ld	a5,40(a5)
ffffffffc020140a:	9782                	jalr	a5
ffffffffc020140c:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020140e:	6098                	ld	a4,0(s1)
ffffffffc0201410:	c80007b7          	lui	a5,0xc8000
ffffffffc0201414:	83b1                	srli	a5,a5,0xc
ffffffffc0201416:	66e7e363          	bltu	a5,a4,ffffffffc0201a7c <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020141a:	00093503          	ld	a0,0(s2)
ffffffffc020141e:	62050f63          	beqz	a0,ffffffffc0201a5c <pmm_init+0x7ae>
ffffffffc0201422:	03451793          	slli	a5,a0,0x34
ffffffffc0201426:	62079b63          	bnez	a5,ffffffffc0201a5c <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020142a:	4601                	li	a2,0
ffffffffc020142c:	4581                	li	a1,0
ffffffffc020142e:	c9bff0ef          	jal	ra,ffffffffc02010c8 <get_page>
ffffffffc0201432:	60051563          	bnez	a0,ffffffffc0201a3c <pmm_init+0x78e>
ffffffffc0201436:	100027f3          	csrr	a5,sstatus
ffffffffc020143a:	8b89                	andi	a5,a5,2
ffffffffc020143c:	44079e63          	bnez	a5,ffffffffc0201898 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201440:	000b3783          	ld	a5,0(s6)
ffffffffc0201444:	4505                	li	a0,1
ffffffffc0201446:	6f9c                	ld	a5,24(a5)
ffffffffc0201448:	9782                	jalr	a5
ffffffffc020144a:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020144c:	00093503          	ld	a0,0(s2)
ffffffffc0201450:	4681                	li	a3,0
ffffffffc0201452:	4601                	li	a2,0
ffffffffc0201454:	85d2                	mv	a1,s4
ffffffffc0201456:	d63ff0ef          	jal	ra,ffffffffc02011b8 <page_insert>
ffffffffc020145a:	26051ae3          	bnez	a0,ffffffffc0201ece <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020145e:	00093503          	ld	a0,0(s2)
ffffffffc0201462:	4601                	li	a2,0
ffffffffc0201464:	4581                	li	a1,0
ffffffffc0201466:	a3bff0ef          	jal	ra,ffffffffc0200ea0 <get_pte>
ffffffffc020146a:	240502e3          	beqz	a0,ffffffffc0201eae <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc020146e:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0201470:	0017f713          	andi	a4,a5,1
ffffffffc0201474:	5a070263          	beqz	a4,ffffffffc0201a18 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0201478:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020147a:	078a                	slli	a5,a5,0x2
ffffffffc020147c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020147e:	58e7fb63          	bgeu	a5,a4,ffffffffc0201a14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201482:	000bb683          	ld	a3,0(s7)
ffffffffc0201486:	fff80637          	lui	a2,0xfff80
ffffffffc020148a:	97b2                	add	a5,a5,a2
ffffffffc020148c:	079a                	slli	a5,a5,0x6
ffffffffc020148e:	97b6                	add	a5,a5,a3
ffffffffc0201490:	14fa17e3          	bne	s4,a5,ffffffffc0201dde <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0201494:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc0201498:	4785                	li	a5,1
ffffffffc020149a:	12f692e3          	bne	a3,a5,ffffffffc0201dbe <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020149e:	00093503          	ld	a0,0(s2)
ffffffffc02014a2:	77fd                	lui	a5,0xfffff
ffffffffc02014a4:	6114                	ld	a3,0(a0)
ffffffffc02014a6:	068a                	slli	a3,a3,0x2
ffffffffc02014a8:	8efd                	and	a3,a3,a5
ffffffffc02014aa:	00c6d613          	srli	a2,a3,0xc
ffffffffc02014ae:	0ee67ce3          	bgeu	a2,a4,ffffffffc0201da6 <pmm_init+0xaf8>
ffffffffc02014b2:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02014b6:	96e2                	add	a3,a3,s8
ffffffffc02014b8:	0006ba83          	ld	s5,0(a3)
ffffffffc02014bc:	0a8a                	slli	s5,s5,0x2
ffffffffc02014be:	00fafab3          	and	s5,s5,a5
ffffffffc02014c2:	00cad793          	srli	a5,s5,0xc
ffffffffc02014c6:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0201d8c <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02014ca:	4601                	li	a2,0
ffffffffc02014cc:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02014ce:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02014d0:	9d1ff0ef          	jal	ra,ffffffffc0200ea0 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02014d4:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02014d6:	55551363          	bne	a0,s5,ffffffffc0201a1c <pmm_init+0x76e>
ffffffffc02014da:	100027f3          	csrr	a5,sstatus
ffffffffc02014de:	8b89                	andi	a5,a5,2
ffffffffc02014e0:	3a079163          	bnez	a5,ffffffffc0201882 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc02014e4:	000b3783          	ld	a5,0(s6)
ffffffffc02014e8:	4505                	li	a0,1
ffffffffc02014ea:	6f9c                	ld	a5,24(a5)
ffffffffc02014ec:	9782                	jalr	a5
ffffffffc02014ee:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02014f0:	00093503          	ld	a0,0(s2)
ffffffffc02014f4:	46d1                	li	a3,20
ffffffffc02014f6:	6605                	lui	a2,0x1
ffffffffc02014f8:	85e2                	mv	a1,s8
ffffffffc02014fa:	cbfff0ef          	jal	ra,ffffffffc02011b8 <page_insert>
ffffffffc02014fe:	060517e3          	bnez	a0,ffffffffc0201d6c <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201502:	00093503          	ld	a0,0(s2)
ffffffffc0201506:	4601                	li	a2,0
ffffffffc0201508:	6585                	lui	a1,0x1
ffffffffc020150a:	997ff0ef          	jal	ra,ffffffffc0200ea0 <get_pte>
ffffffffc020150e:	02050fe3          	beqz	a0,ffffffffc0201d4c <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0201512:	611c                	ld	a5,0(a0)
ffffffffc0201514:	0107f713          	andi	a4,a5,16
ffffffffc0201518:	7c070e63          	beqz	a4,ffffffffc0201cf4 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc020151c:	8b91                	andi	a5,a5,4
ffffffffc020151e:	7a078b63          	beqz	a5,ffffffffc0201cd4 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0201522:	00093503          	ld	a0,0(s2)
ffffffffc0201526:	611c                	ld	a5,0(a0)
ffffffffc0201528:	8bc1                	andi	a5,a5,16
ffffffffc020152a:	78078563          	beqz	a5,ffffffffc0201cb4 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc020152e:	000c2703          	lw	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc0201532:	4785                	li	a5,1
ffffffffc0201534:	76f71063          	bne	a4,a5,ffffffffc0201c94 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0201538:	4681                	li	a3,0
ffffffffc020153a:	6605                	lui	a2,0x1
ffffffffc020153c:	85d2                	mv	a1,s4
ffffffffc020153e:	c7bff0ef          	jal	ra,ffffffffc02011b8 <page_insert>
ffffffffc0201542:	72051963          	bnez	a0,ffffffffc0201c74 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0201546:	000a2703          	lw	a4,0(s4)
ffffffffc020154a:	4789                	li	a5,2
ffffffffc020154c:	70f71463          	bne	a4,a5,ffffffffc0201c54 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0201550:	000c2783          	lw	a5,0(s8)
ffffffffc0201554:	6e079063          	bnez	a5,ffffffffc0201c34 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201558:	00093503          	ld	a0,0(s2)
ffffffffc020155c:	4601                	li	a2,0
ffffffffc020155e:	6585                	lui	a1,0x1
ffffffffc0201560:	941ff0ef          	jal	ra,ffffffffc0200ea0 <get_pte>
ffffffffc0201564:	6a050863          	beqz	a0,ffffffffc0201c14 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0201568:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc020156a:	00177793          	andi	a5,a4,1
ffffffffc020156e:	4a078563          	beqz	a5,ffffffffc0201a18 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0201572:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201574:	00271793          	slli	a5,a4,0x2
ffffffffc0201578:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020157a:	48d7fd63          	bgeu	a5,a3,ffffffffc0201a14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020157e:	000bb683          	ld	a3,0(s7)
ffffffffc0201582:	fff80ab7          	lui	s5,0xfff80
ffffffffc0201586:	97d6                	add	a5,a5,s5
ffffffffc0201588:	079a                	slli	a5,a5,0x6
ffffffffc020158a:	97b6                	add	a5,a5,a3
ffffffffc020158c:	66fa1463          	bne	s4,a5,ffffffffc0201bf4 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201590:	8b41                	andi	a4,a4,16
ffffffffc0201592:	64071163          	bnez	a4,ffffffffc0201bd4 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0201596:	00093503          	ld	a0,0(s2)
ffffffffc020159a:	4581                	li	a1,0
ffffffffc020159c:	b81ff0ef          	jal	ra,ffffffffc020111c <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02015a0:	000a2c83          	lw	s9,0(s4)
ffffffffc02015a4:	4785                	li	a5,1
ffffffffc02015a6:	60fc9763          	bne	s9,a5,ffffffffc0201bb4 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc02015aa:	000c2783          	lw	a5,0(s8)
ffffffffc02015ae:	5e079363          	bnez	a5,ffffffffc0201b94 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc02015b2:	00093503          	ld	a0,0(s2)
ffffffffc02015b6:	6585                	lui	a1,0x1
ffffffffc02015b8:	b65ff0ef          	jal	ra,ffffffffc020111c <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02015bc:	000a2783          	lw	a5,0(s4)
ffffffffc02015c0:	52079a63          	bnez	a5,ffffffffc0201af4 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc02015c4:	000c2783          	lw	a5,0(s8)
ffffffffc02015c8:	50079663          	bnez	a5,ffffffffc0201ad4 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc02015cc:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02015d0:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02015d2:	000a3683          	ld	a3,0(s4)
ffffffffc02015d6:	068a                	slli	a3,a3,0x2
ffffffffc02015d8:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02015da:	42b6fd63          	bgeu	a3,a1,ffffffffc0201a14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02015de:	000bb503          	ld	a0,0(s7)
ffffffffc02015e2:	96d6                	add	a3,a3,s5
ffffffffc02015e4:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc02015e6:	00d507b3          	add	a5,a0,a3
ffffffffc02015ea:	439c                	lw	a5,0(a5)
ffffffffc02015ec:	4d979463          	bne	a5,s9,ffffffffc0201ab4 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc02015f0:	8699                	srai	a3,a3,0x6
ffffffffc02015f2:	00080637          	lui	a2,0x80
ffffffffc02015f6:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02015f8:	00c69713          	slli	a4,a3,0xc
ffffffffc02015fc:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02015fe:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201600:	48b77e63          	bgeu	a4,a1,ffffffffc0201a9c <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201604:	0009b703          	ld	a4,0(s3)
ffffffffc0201608:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc020160a:	629c                	ld	a5,0(a3)
ffffffffc020160c:	078a                	slli	a5,a5,0x2
ffffffffc020160e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201610:	40b7f263          	bgeu	a5,a1,ffffffffc0201a14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201614:	8f91                	sub	a5,a5,a2
ffffffffc0201616:	079a                	slli	a5,a5,0x6
ffffffffc0201618:	953e                	add	a0,a0,a5
ffffffffc020161a:	100027f3          	csrr	a5,sstatus
ffffffffc020161e:	8b89                	andi	a5,a5,2
ffffffffc0201620:	30079963          	bnez	a5,ffffffffc0201932 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0201624:	000b3783          	ld	a5,0(s6)
ffffffffc0201628:	4585                	li	a1,1
ffffffffc020162a:	739c                	ld	a5,32(a5)
ffffffffc020162c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020162e:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0201632:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201634:	078a                	slli	a5,a5,0x2
ffffffffc0201636:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201638:	3ce7fe63          	bgeu	a5,a4,ffffffffc0201a14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020163c:	000bb503          	ld	a0,0(s7)
ffffffffc0201640:	fff80737          	lui	a4,0xfff80
ffffffffc0201644:	97ba                	add	a5,a5,a4
ffffffffc0201646:	079a                	slli	a5,a5,0x6
ffffffffc0201648:	953e                	add	a0,a0,a5
ffffffffc020164a:	100027f3          	csrr	a5,sstatus
ffffffffc020164e:	8b89                	andi	a5,a5,2
ffffffffc0201650:	2c079563          	bnez	a5,ffffffffc020191a <pmm_init+0x66c>
ffffffffc0201654:	000b3783          	ld	a5,0(s6)
ffffffffc0201658:	4585                	li	a1,1
ffffffffc020165a:	739c                	ld	a5,32(a5)
ffffffffc020165c:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc020165e:	00093783          	ld	a5,0(s2)
ffffffffc0201662:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b1c>
    asm volatile("sfence.vma");
ffffffffc0201666:	12000073          	sfence.vma
ffffffffc020166a:	100027f3          	csrr	a5,sstatus
ffffffffc020166e:	8b89                	andi	a5,a5,2
ffffffffc0201670:	28079b63          	bnez	a5,ffffffffc0201906 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201674:	000b3783          	ld	a5,0(s6)
ffffffffc0201678:	779c                	ld	a5,40(a5)
ffffffffc020167a:	9782                	jalr	a5
ffffffffc020167c:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc020167e:	4b441b63          	bne	s0,s4,ffffffffc0201b34 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201682:	00003517          	auipc	a0,0x3
ffffffffc0201686:	5e650513          	addi	a0,a0,1510 # ffffffffc0204c68 <commands+0xb40>
ffffffffc020168a:	a57fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
ffffffffc020168e:	100027f3          	csrr	a5,sstatus
ffffffffc0201692:	8b89                	andi	a5,a5,2
ffffffffc0201694:	24079f63          	bnez	a5,ffffffffc02018f2 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201698:	000b3783          	ld	a5,0(s6)
ffffffffc020169c:	779c                	ld	a5,40(a5)
ffffffffc020169e:	9782                	jalr	a5
ffffffffc02016a0:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02016a2:	6098                	ld	a4,0(s1)
ffffffffc02016a4:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02016a8:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02016aa:	00c71793          	slli	a5,a4,0xc
ffffffffc02016ae:	6a05                	lui	s4,0x1
ffffffffc02016b0:	02f47c63          	bgeu	s0,a5,ffffffffc02016e8 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02016b4:	00c45793          	srli	a5,s0,0xc
ffffffffc02016b8:	00093503          	ld	a0,0(s2)
ffffffffc02016bc:	2ee7ff63          	bgeu	a5,a4,ffffffffc02019ba <pmm_init+0x70c>
ffffffffc02016c0:	0009b583          	ld	a1,0(s3)
ffffffffc02016c4:	4601                	li	a2,0
ffffffffc02016c6:	95a2                	add	a1,a1,s0
ffffffffc02016c8:	fd8ff0ef          	jal	ra,ffffffffc0200ea0 <get_pte>
ffffffffc02016cc:	32050463          	beqz	a0,ffffffffc02019f4 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02016d0:	611c                	ld	a5,0(a0)
ffffffffc02016d2:	078a                	slli	a5,a5,0x2
ffffffffc02016d4:	0157f7b3          	and	a5,a5,s5
ffffffffc02016d8:	2e879e63          	bne	a5,s0,ffffffffc02019d4 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02016dc:	6098                	ld	a4,0(s1)
ffffffffc02016de:	9452                	add	s0,s0,s4
ffffffffc02016e0:	00c71793          	slli	a5,a4,0xc
ffffffffc02016e4:	fcf468e3          	bltu	s0,a5,ffffffffc02016b4 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc02016e8:	00093783          	ld	a5,0(s2)
ffffffffc02016ec:	639c                	ld	a5,0(a5)
ffffffffc02016ee:	42079363          	bnez	a5,ffffffffc0201b14 <pmm_init+0x866>
ffffffffc02016f2:	100027f3          	csrr	a5,sstatus
ffffffffc02016f6:	8b89                	andi	a5,a5,2
ffffffffc02016f8:	24079963          	bnez	a5,ffffffffc020194a <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc02016fc:	000b3783          	ld	a5,0(s6)
ffffffffc0201700:	4505                	li	a0,1
ffffffffc0201702:	6f9c                	ld	a5,24(a5)
ffffffffc0201704:	9782                	jalr	a5
ffffffffc0201706:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201708:	00093503          	ld	a0,0(s2)
ffffffffc020170c:	4699                	li	a3,6
ffffffffc020170e:	10000613          	li	a2,256
ffffffffc0201712:	85d2                	mv	a1,s4
ffffffffc0201714:	aa5ff0ef          	jal	ra,ffffffffc02011b8 <page_insert>
ffffffffc0201718:	44051e63          	bnez	a0,ffffffffc0201b74 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc020171c:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0201720:	4785                	li	a5,1
ffffffffc0201722:	42f71963          	bne	a4,a5,ffffffffc0201b54 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201726:	00093503          	ld	a0,0(s2)
ffffffffc020172a:	6405                	lui	s0,0x1
ffffffffc020172c:	4699                	li	a3,6
ffffffffc020172e:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0201732:	85d2                	mv	a1,s4
ffffffffc0201734:	a85ff0ef          	jal	ra,ffffffffc02011b8 <page_insert>
ffffffffc0201738:	72051363          	bnez	a0,ffffffffc0201e5e <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc020173c:	000a2703          	lw	a4,0(s4)
ffffffffc0201740:	4789                	li	a5,2
ffffffffc0201742:	6ef71e63          	bne	a4,a5,ffffffffc0201e3e <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0201746:	00003597          	auipc	a1,0x3
ffffffffc020174a:	66a58593          	addi	a1,a1,1642 # ffffffffc0204db0 <commands+0xc88>
ffffffffc020174e:	10000513          	li	a0,256
ffffffffc0201752:	290020ef          	jal	ra,ffffffffc02039e2 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201756:	10040593          	addi	a1,s0,256
ffffffffc020175a:	10000513          	li	a0,256
ffffffffc020175e:	296020ef          	jal	ra,ffffffffc02039f4 <strcmp>
ffffffffc0201762:	6a051e63          	bnez	a0,ffffffffc0201e1e <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0201766:	000bb683          	ld	a3,0(s7)
ffffffffc020176a:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc020176e:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0201770:	40da06b3          	sub	a3,s4,a3
ffffffffc0201774:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0201776:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0201778:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc020177a:	8031                	srli	s0,s0,0xc
ffffffffc020177c:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201780:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201782:	30f77d63          	bgeu	a4,a5,ffffffffc0201a9c <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201786:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020178a:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020178e:	96be                	add	a3,a3,a5
ffffffffc0201790:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201794:	218020ef          	jal	ra,ffffffffc02039ac <strlen>
ffffffffc0201798:	66051363          	bnez	a0,ffffffffc0201dfe <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc020179c:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02017a0:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02017a2:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fdf1b1c>
ffffffffc02017a6:	068a                	slli	a3,a3,0x2
ffffffffc02017a8:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc02017aa:	26f6f563          	bgeu	a3,a5,ffffffffc0201a14 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc02017ae:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02017b0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02017b2:	2ef47563          	bgeu	s0,a5,ffffffffc0201a9c <pmm_init+0x7ee>
ffffffffc02017b6:	0009b403          	ld	s0,0(s3)
ffffffffc02017ba:	9436                	add	s0,s0,a3
ffffffffc02017bc:	100027f3          	csrr	a5,sstatus
ffffffffc02017c0:	8b89                	andi	a5,a5,2
ffffffffc02017c2:	1e079163          	bnez	a5,ffffffffc02019a4 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc02017c6:	000b3783          	ld	a5,0(s6)
ffffffffc02017ca:	4585                	li	a1,1
ffffffffc02017cc:	8552                	mv	a0,s4
ffffffffc02017ce:	739c                	ld	a5,32(a5)
ffffffffc02017d0:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02017d2:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc02017d4:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02017d6:	078a                	slli	a5,a5,0x2
ffffffffc02017d8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02017da:	22e7fd63          	bgeu	a5,a4,ffffffffc0201a14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02017de:	000bb503          	ld	a0,0(s7)
ffffffffc02017e2:	fff80737          	lui	a4,0xfff80
ffffffffc02017e6:	97ba                	add	a5,a5,a4
ffffffffc02017e8:	079a                	slli	a5,a5,0x6
ffffffffc02017ea:	953e                	add	a0,a0,a5
ffffffffc02017ec:	100027f3          	csrr	a5,sstatus
ffffffffc02017f0:	8b89                	andi	a5,a5,2
ffffffffc02017f2:	18079d63          	bnez	a5,ffffffffc020198c <pmm_init+0x6de>
ffffffffc02017f6:	000b3783          	ld	a5,0(s6)
ffffffffc02017fa:	4585                	li	a1,1
ffffffffc02017fc:	739c                	ld	a5,32(a5)
ffffffffc02017fe:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201800:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0201804:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201806:	078a                	slli	a5,a5,0x2
ffffffffc0201808:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020180a:	20e7f563          	bgeu	a5,a4,ffffffffc0201a14 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020180e:	000bb503          	ld	a0,0(s7)
ffffffffc0201812:	fff80737          	lui	a4,0xfff80
ffffffffc0201816:	97ba                	add	a5,a5,a4
ffffffffc0201818:	079a                	slli	a5,a5,0x6
ffffffffc020181a:	953e                	add	a0,a0,a5
ffffffffc020181c:	100027f3          	csrr	a5,sstatus
ffffffffc0201820:	8b89                	andi	a5,a5,2
ffffffffc0201822:	14079963          	bnez	a5,ffffffffc0201974 <pmm_init+0x6c6>
ffffffffc0201826:	000b3783          	ld	a5,0(s6)
ffffffffc020182a:	4585                	li	a1,1
ffffffffc020182c:	739c                	ld	a5,32(a5)
ffffffffc020182e:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0201830:	00093783          	ld	a5,0(s2)
ffffffffc0201834:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0201838:	12000073          	sfence.vma
ffffffffc020183c:	100027f3          	csrr	a5,sstatus
ffffffffc0201840:	8b89                	andi	a5,a5,2
ffffffffc0201842:	10079f63          	bnez	a5,ffffffffc0201960 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201846:	000b3783          	ld	a5,0(s6)
ffffffffc020184a:	779c                	ld	a5,40(a5)
ffffffffc020184c:	9782                	jalr	a5
ffffffffc020184e:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0201850:	4c8c1e63          	bne	s8,s0,ffffffffc0201d2c <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0201854:	00003517          	auipc	a0,0x3
ffffffffc0201858:	5d450513          	addi	a0,a0,1492 # ffffffffc0204e28 <commands+0xd00>
ffffffffc020185c:	885fe0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}
ffffffffc0201860:	7406                	ld	s0,96(sp)
ffffffffc0201862:	70a6                	ld	ra,104(sp)
ffffffffc0201864:	64e6                	ld	s1,88(sp)
ffffffffc0201866:	6946                	ld	s2,80(sp)
ffffffffc0201868:	69a6                	ld	s3,72(sp)
ffffffffc020186a:	6a06                	ld	s4,64(sp)
ffffffffc020186c:	7ae2                	ld	s5,56(sp)
ffffffffc020186e:	7b42                	ld	s6,48(sp)
ffffffffc0201870:	7ba2                	ld	s7,40(sp)
ffffffffc0201872:	7c02                	ld	s8,32(sp)
ffffffffc0201874:	6ce2                	ld	s9,24(sp)
ffffffffc0201876:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0201878:	4ef0006f          	j	ffffffffc0202566 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc020187c:	c80007b7          	lui	a5,0xc8000
ffffffffc0201880:	bc7d                	j	ffffffffc020133e <pmm_init+0x90>
        intr_disable();
ffffffffc0201882:	8b4ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201886:	000b3783          	ld	a5,0(s6)
ffffffffc020188a:	4505                	li	a0,1
ffffffffc020188c:	6f9c                	ld	a5,24(a5)
ffffffffc020188e:	9782                	jalr	a5
ffffffffc0201890:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0201892:	89eff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201896:	b9a9                	j	ffffffffc02014f0 <pmm_init+0x242>
        intr_disable();
ffffffffc0201898:	89eff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc020189c:	000b3783          	ld	a5,0(s6)
ffffffffc02018a0:	4505                	li	a0,1
ffffffffc02018a2:	6f9c                	ld	a5,24(a5)
ffffffffc02018a4:	9782                	jalr	a5
ffffffffc02018a6:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02018a8:	888ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02018ac:	b645                	j	ffffffffc020144c <pmm_init+0x19e>
        intr_disable();
ffffffffc02018ae:	888ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02018b2:	000b3783          	ld	a5,0(s6)
ffffffffc02018b6:	779c                	ld	a5,40(a5)
ffffffffc02018b8:	9782                	jalr	a5
ffffffffc02018ba:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02018bc:	874ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02018c0:	b6b9                	j	ffffffffc020140e <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02018c2:	6705                	lui	a4,0x1
ffffffffc02018c4:	177d                	addi	a4,a4,-1
ffffffffc02018c6:	96ba                	add	a3,a3,a4
ffffffffc02018c8:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc02018ca:	00c7d713          	srli	a4,a5,0xc
ffffffffc02018ce:	14a77363          	bgeu	a4,a0,ffffffffc0201a14 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc02018d2:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc02018d6:	fff80537          	lui	a0,0xfff80
ffffffffc02018da:	972a                	add	a4,a4,a0
ffffffffc02018dc:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02018de:	8c1d                	sub	s0,s0,a5
ffffffffc02018e0:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc02018e4:	00c45593          	srli	a1,s0,0xc
ffffffffc02018e8:	9532                	add	a0,a0,a2
ffffffffc02018ea:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02018ec:	0009b583          	ld	a1,0(s3)
}
ffffffffc02018f0:	b4c1                	j	ffffffffc02013b0 <pmm_init+0x102>
        intr_disable();
ffffffffc02018f2:	844ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02018f6:	000b3783          	ld	a5,0(s6)
ffffffffc02018fa:	779c                	ld	a5,40(a5)
ffffffffc02018fc:	9782                	jalr	a5
ffffffffc02018fe:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0201900:	830ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201904:	bb79                	j	ffffffffc02016a2 <pmm_init+0x3f4>
        intr_disable();
ffffffffc0201906:	830ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc020190a:	000b3783          	ld	a5,0(s6)
ffffffffc020190e:	779c                	ld	a5,40(a5)
ffffffffc0201910:	9782                	jalr	a5
ffffffffc0201912:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0201914:	81cff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201918:	b39d                	j	ffffffffc020167e <pmm_init+0x3d0>
ffffffffc020191a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020191c:	81aff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201920:	000b3783          	ld	a5,0(s6)
ffffffffc0201924:	6522                	ld	a0,8(sp)
ffffffffc0201926:	4585                	li	a1,1
ffffffffc0201928:	739c                	ld	a5,32(a5)
ffffffffc020192a:	9782                	jalr	a5
        intr_enable();
ffffffffc020192c:	804ff0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201930:	b33d                	j	ffffffffc020165e <pmm_init+0x3b0>
ffffffffc0201932:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201934:	802ff0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc0201938:	000b3783          	ld	a5,0(s6)
ffffffffc020193c:	6522                	ld	a0,8(sp)
ffffffffc020193e:	4585                	li	a1,1
ffffffffc0201940:	739c                	ld	a5,32(a5)
ffffffffc0201942:	9782                	jalr	a5
        intr_enable();
ffffffffc0201944:	fedfe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201948:	b1dd                	j	ffffffffc020162e <pmm_init+0x380>
        intr_disable();
ffffffffc020194a:	fedfe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020194e:	000b3783          	ld	a5,0(s6)
ffffffffc0201952:	4505                	li	a0,1
ffffffffc0201954:	6f9c                	ld	a5,24(a5)
ffffffffc0201956:	9782                	jalr	a5
ffffffffc0201958:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020195a:	fd7fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc020195e:	b36d                	j	ffffffffc0201708 <pmm_init+0x45a>
        intr_disable();
ffffffffc0201960:	fd7fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201964:	000b3783          	ld	a5,0(s6)
ffffffffc0201968:	779c                	ld	a5,40(a5)
ffffffffc020196a:	9782                	jalr	a5
ffffffffc020196c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020196e:	fc3fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc0201972:	bdf9                	j	ffffffffc0201850 <pmm_init+0x5a2>
ffffffffc0201974:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201976:	fc1fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020197a:	000b3783          	ld	a5,0(s6)
ffffffffc020197e:	6522                	ld	a0,8(sp)
ffffffffc0201980:	4585                	li	a1,1
ffffffffc0201982:	739c                	ld	a5,32(a5)
ffffffffc0201984:	9782                	jalr	a5
        intr_enable();
ffffffffc0201986:	fabfe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc020198a:	b55d                	j	ffffffffc0201830 <pmm_init+0x582>
ffffffffc020198c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020198e:	fa9fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc0201992:	000b3783          	ld	a5,0(s6)
ffffffffc0201996:	6522                	ld	a0,8(sp)
ffffffffc0201998:	4585                	li	a1,1
ffffffffc020199a:	739c                	ld	a5,32(a5)
ffffffffc020199c:	9782                	jalr	a5
        intr_enable();
ffffffffc020199e:	f93fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02019a2:	bdb9                	j	ffffffffc0201800 <pmm_init+0x552>
        intr_disable();
ffffffffc02019a4:	f93fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
ffffffffc02019a8:	000b3783          	ld	a5,0(s6)
ffffffffc02019ac:	4585                	li	a1,1
ffffffffc02019ae:	8552                	mv	a0,s4
ffffffffc02019b0:	739c                	ld	a5,32(a5)
ffffffffc02019b2:	9782                	jalr	a5
        intr_enable();
ffffffffc02019b4:	f7dfe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02019b8:	bd29                	j	ffffffffc02017d2 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02019ba:	86a2                	mv	a3,s0
ffffffffc02019bc:	00003617          	auipc	a2,0x3
ffffffffc02019c0:	e7c60613          	addi	a2,a2,-388 # ffffffffc0204838 <commands+0x710>
ffffffffc02019c4:	1a400593          	li	a1,420
ffffffffc02019c8:	00003517          	auipc	a0,0x3
ffffffffc02019cc:	e9850513          	addi	a0,a0,-360 # ffffffffc0204860 <commands+0x738>
ffffffffc02019d0:	80ffe0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02019d4:	00003697          	auipc	a3,0x3
ffffffffc02019d8:	2f468693          	addi	a3,a3,756 # ffffffffc0204cc8 <commands+0xba0>
ffffffffc02019dc:	00003617          	auipc	a2,0x3
ffffffffc02019e0:	f8c60613          	addi	a2,a2,-116 # ffffffffc0204968 <commands+0x840>
ffffffffc02019e4:	1a500593          	li	a1,421
ffffffffc02019e8:	00003517          	auipc	a0,0x3
ffffffffc02019ec:	e7850513          	addi	a0,a0,-392 # ffffffffc0204860 <commands+0x738>
ffffffffc02019f0:	feefe0ef          	jal	ra,ffffffffc02001de <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02019f4:	00003697          	auipc	a3,0x3
ffffffffc02019f8:	29468693          	addi	a3,a3,660 # ffffffffc0204c88 <commands+0xb60>
ffffffffc02019fc:	00003617          	auipc	a2,0x3
ffffffffc0201a00:	f6c60613          	addi	a2,a2,-148 # ffffffffc0204968 <commands+0x840>
ffffffffc0201a04:	1a400593          	li	a1,420
ffffffffc0201a08:	00003517          	auipc	a0,0x3
ffffffffc0201a0c:	e5850513          	addi	a0,a0,-424 # ffffffffc0204860 <commands+0x738>
ffffffffc0201a10:	fcefe0ef          	jal	ra,ffffffffc02001de <__panic>
ffffffffc0201a14:	b9eff0ef          	jal	ra,ffffffffc0200db2 <pa2page.part.0>
ffffffffc0201a18:	bb6ff0ef          	jal	ra,ffffffffc0200dce <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0201a1c:	00003697          	auipc	a3,0x3
ffffffffc0201a20:	06468693          	addi	a3,a3,100 # ffffffffc0204a80 <commands+0x958>
ffffffffc0201a24:	00003617          	auipc	a2,0x3
ffffffffc0201a28:	f4460613          	addi	a2,a2,-188 # ffffffffc0204968 <commands+0x840>
ffffffffc0201a2c:	17400593          	li	a1,372
ffffffffc0201a30:	00003517          	auipc	a0,0x3
ffffffffc0201a34:	e3050513          	addi	a0,a0,-464 # ffffffffc0204860 <commands+0x738>
ffffffffc0201a38:	fa6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0201a3c:	00003697          	auipc	a3,0x3
ffffffffc0201a40:	f8468693          	addi	a3,a3,-124 # ffffffffc02049c0 <commands+0x898>
ffffffffc0201a44:	00003617          	auipc	a2,0x3
ffffffffc0201a48:	f2460613          	addi	a2,a2,-220 # ffffffffc0204968 <commands+0x840>
ffffffffc0201a4c:	16700593          	li	a1,359
ffffffffc0201a50:	00003517          	auipc	a0,0x3
ffffffffc0201a54:	e1050513          	addi	a0,a0,-496 # ffffffffc0204860 <commands+0x738>
ffffffffc0201a58:	f86fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0201a5c:	00003697          	auipc	a3,0x3
ffffffffc0201a60:	f2468693          	addi	a3,a3,-220 # ffffffffc0204980 <commands+0x858>
ffffffffc0201a64:	00003617          	auipc	a2,0x3
ffffffffc0201a68:	f0460613          	addi	a2,a2,-252 # ffffffffc0204968 <commands+0x840>
ffffffffc0201a6c:	16600593          	li	a1,358
ffffffffc0201a70:	00003517          	auipc	a0,0x3
ffffffffc0201a74:	df050513          	addi	a0,a0,-528 # ffffffffc0204860 <commands+0x738>
ffffffffc0201a78:	f66fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201a7c:	00003697          	auipc	a3,0x3
ffffffffc0201a80:	ecc68693          	addi	a3,a3,-308 # ffffffffc0204948 <commands+0x820>
ffffffffc0201a84:	00003617          	auipc	a2,0x3
ffffffffc0201a88:	ee460613          	addi	a2,a2,-284 # ffffffffc0204968 <commands+0x840>
ffffffffc0201a8c:	16500593          	li	a1,357
ffffffffc0201a90:	00003517          	auipc	a0,0x3
ffffffffc0201a94:	dd050513          	addi	a0,a0,-560 # ffffffffc0204860 <commands+0x738>
ffffffffc0201a98:	f46fe0ef          	jal	ra,ffffffffc02001de <__panic>
    return KADDR(page2pa(page));
ffffffffc0201a9c:	00003617          	auipc	a2,0x3
ffffffffc0201aa0:	d9c60613          	addi	a2,a2,-612 # ffffffffc0204838 <commands+0x710>
ffffffffc0201aa4:	07100593          	li	a1,113
ffffffffc0201aa8:	00003517          	auipc	a0,0x3
ffffffffc0201aac:	d5850513          	addi	a0,a0,-680 # ffffffffc0204800 <commands+0x6d8>
ffffffffc0201ab0:	f2efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0201ab4:	00003697          	auipc	a3,0x3
ffffffffc0201ab8:	15c68693          	addi	a3,a3,348 # ffffffffc0204c10 <commands+0xae8>
ffffffffc0201abc:	00003617          	auipc	a2,0x3
ffffffffc0201ac0:	eac60613          	addi	a2,a2,-340 # ffffffffc0204968 <commands+0x840>
ffffffffc0201ac4:	18d00593          	li	a1,397
ffffffffc0201ac8:	00003517          	auipc	a0,0x3
ffffffffc0201acc:	d9850513          	addi	a0,a0,-616 # ffffffffc0204860 <commands+0x738>
ffffffffc0201ad0:	f0efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201ad4:	00003697          	auipc	a3,0x3
ffffffffc0201ad8:	0f468693          	addi	a3,a3,244 # ffffffffc0204bc8 <commands+0xaa0>
ffffffffc0201adc:	00003617          	auipc	a2,0x3
ffffffffc0201ae0:	e8c60613          	addi	a2,a2,-372 # ffffffffc0204968 <commands+0x840>
ffffffffc0201ae4:	18b00593          	li	a1,395
ffffffffc0201ae8:	00003517          	auipc	a0,0x3
ffffffffc0201aec:	d7850513          	addi	a0,a0,-648 # ffffffffc0204860 <commands+0x738>
ffffffffc0201af0:	eeefe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0201af4:	00003697          	auipc	a3,0x3
ffffffffc0201af8:	10468693          	addi	a3,a3,260 # ffffffffc0204bf8 <commands+0xad0>
ffffffffc0201afc:	00003617          	auipc	a2,0x3
ffffffffc0201b00:	e6c60613          	addi	a2,a2,-404 # ffffffffc0204968 <commands+0x840>
ffffffffc0201b04:	18a00593          	li	a1,394
ffffffffc0201b08:	00003517          	auipc	a0,0x3
ffffffffc0201b0c:	d5850513          	addi	a0,a0,-680 # ffffffffc0204860 <commands+0x738>
ffffffffc0201b10:	ecefe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0201b14:	00003697          	auipc	a3,0x3
ffffffffc0201b18:	1cc68693          	addi	a3,a3,460 # ffffffffc0204ce0 <commands+0xbb8>
ffffffffc0201b1c:	00003617          	auipc	a2,0x3
ffffffffc0201b20:	e4c60613          	addi	a2,a2,-436 # ffffffffc0204968 <commands+0x840>
ffffffffc0201b24:	1a800593          	li	a1,424
ffffffffc0201b28:	00003517          	auipc	a0,0x3
ffffffffc0201b2c:	d3850513          	addi	a0,a0,-712 # ffffffffc0204860 <commands+0x738>
ffffffffc0201b30:	eaefe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0201b34:	00003697          	auipc	a3,0x3
ffffffffc0201b38:	10c68693          	addi	a3,a3,268 # ffffffffc0204c40 <commands+0xb18>
ffffffffc0201b3c:	00003617          	auipc	a2,0x3
ffffffffc0201b40:	e2c60613          	addi	a2,a2,-468 # ffffffffc0204968 <commands+0x840>
ffffffffc0201b44:	19500593          	li	a1,405
ffffffffc0201b48:	00003517          	auipc	a0,0x3
ffffffffc0201b4c:	d1850513          	addi	a0,a0,-744 # ffffffffc0204860 <commands+0x738>
ffffffffc0201b50:	e8efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p) == 1);
ffffffffc0201b54:	00003697          	auipc	a3,0x3
ffffffffc0201b58:	1e468693          	addi	a3,a3,484 # ffffffffc0204d38 <commands+0xc10>
ffffffffc0201b5c:	00003617          	auipc	a2,0x3
ffffffffc0201b60:	e0c60613          	addi	a2,a2,-500 # ffffffffc0204968 <commands+0x840>
ffffffffc0201b64:	1ad00593          	li	a1,429
ffffffffc0201b68:	00003517          	auipc	a0,0x3
ffffffffc0201b6c:	cf850513          	addi	a0,a0,-776 # ffffffffc0204860 <commands+0x738>
ffffffffc0201b70:	e6efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201b74:	00003697          	auipc	a3,0x3
ffffffffc0201b78:	18468693          	addi	a3,a3,388 # ffffffffc0204cf8 <commands+0xbd0>
ffffffffc0201b7c:	00003617          	auipc	a2,0x3
ffffffffc0201b80:	dec60613          	addi	a2,a2,-532 # ffffffffc0204968 <commands+0x840>
ffffffffc0201b84:	1ac00593          	li	a1,428
ffffffffc0201b88:	00003517          	auipc	a0,0x3
ffffffffc0201b8c:	cd850513          	addi	a0,a0,-808 # ffffffffc0204860 <commands+0x738>
ffffffffc0201b90:	e4efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201b94:	00003697          	auipc	a3,0x3
ffffffffc0201b98:	03468693          	addi	a3,a3,52 # ffffffffc0204bc8 <commands+0xaa0>
ffffffffc0201b9c:	00003617          	auipc	a2,0x3
ffffffffc0201ba0:	dcc60613          	addi	a2,a2,-564 # ffffffffc0204968 <commands+0x840>
ffffffffc0201ba4:	18700593          	li	a1,391
ffffffffc0201ba8:	00003517          	auipc	a0,0x3
ffffffffc0201bac:	cb850513          	addi	a0,a0,-840 # ffffffffc0204860 <commands+0x738>
ffffffffc0201bb0:	e2efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201bb4:	00003697          	auipc	a3,0x3
ffffffffc0201bb8:	eb468693          	addi	a3,a3,-332 # ffffffffc0204a68 <commands+0x940>
ffffffffc0201bbc:	00003617          	auipc	a2,0x3
ffffffffc0201bc0:	dac60613          	addi	a2,a2,-596 # ffffffffc0204968 <commands+0x840>
ffffffffc0201bc4:	18600593          	li	a1,390
ffffffffc0201bc8:	00003517          	auipc	a0,0x3
ffffffffc0201bcc:	c9850513          	addi	a0,a0,-872 # ffffffffc0204860 <commands+0x738>
ffffffffc0201bd0:	e0efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201bd4:	00003697          	auipc	a3,0x3
ffffffffc0201bd8:	00c68693          	addi	a3,a3,12 # ffffffffc0204be0 <commands+0xab8>
ffffffffc0201bdc:	00003617          	auipc	a2,0x3
ffffffffc0201be0:	d8c60613          	addi	a2,a2,-628 # ffffffffc0204968 <commands+0x840>
ffffffffc0201be4:	18300593          	li	a1,387
ffffffffc0201be8:	00003517          	auipc	a0,0x3
ffffffffc0201bec:	c7850513          	addi	a0,a0,-904 # ffffffffc0204860 <commands+0x738>
ffffffffc0201bf0:	deefe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201bf4:	00003697          	auipc	a3,0x3
ffffffffc0201bf8:	e5c68693          	addi	a3,a3,-420 # ffffffffc0204a50 <commands+0x928>
ffffffffc0201bfc:	00003617          	auipc	a2,0x3
ffffffffc0201c00:	d6c60613          	addi	a2,a2,-660 # ffffffffc0204968 <commands+0x840>
ffffffffc0201c04:	18200593          	li	a1,386
ffffffffc0201c08:	00003517          	auipc	a0,0x3
ffffffffc0201c0c:	c5850513          	addi	a0,a0,-936 # ffffffffc0204860 <commands+0x738>
ffffffffc0201c10:	dcefe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201c14:	00003697          	auipc	a3,0x3
ffffffffc0201c18:	edc68693          	addi	a3,a3,-292 # ffffffffc0204af0 <commands+0x9c8>
ffffffffc0201c1c:	00003617          	auipc	a2,0x3
ffffffffc0201c20:	d4c60613          	addi	a2,a2,-692 # ffffffffc0204968 <commands+0x840>
ffffffffc0201c24:	18100593          	li	a1,385
ffffffffc0201c28:	00003517          	auipc	a0,0x3
ffffffffc0201c2c:	c3850513          	addi	a0,a0,-968 # ffffffffc0204860 <commands+0x738>
ffffffffc0201c30:	daefe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201c34:	00003697          	auipc	a3,0x3
ffffffffc0201c38:	f9468693          	addi	a3,a3,-108 # ffffffffc0204bc8 <commands+0xaa0>
ffffffffc0201c3c:	00003617          	auipc	a2,0x3
ffffffffc0201c40:	d2c60613          	addi	a2,a2,-724 # ffffffffc0204968 <commands+0x840>
ffffffffc0201c44:	18000593          	li	a1,384
ffffffffc0201c48:	00003517          	auipc	a0,0x3
ffffffffc0201c4c:	c1850513          	addi	a0,a0,-1000 # ffffffffc0204860 <commands+0x738>
ffffffffc0201c50:	d8efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0201c54:	00003697          	auipc	a3,0x3
ffffffffc0201c58:	f5c68693          	addi	a3,a3,-164 # ffffffffc0204bb0 <commands+0xa88>
ffffffffc0201c5c:	00003617          	auipc	a2,0x3
ffffffffc0201c60:	d0c60613          	addi	a2,a2,-756 # ffffffffc0204968 <commands+0x840>
ffffffffc0201c64:	17f00593          	li	a1,383
ffffffffc0201c68:	00003517          	auipc	a0,0x3
ffffffffc0201c6c:	bf850513          	addi	a0,a0,-1032 # ffffffffc0204860 <commands+0x738>
ffffffffc0201c70:	d6efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0201c74:	00003697          	auipc	a3,0x3
ffffffffc0201c78:	f0c68693          	addi	a3,a3,-244 # ffffffffc0204b80 <commands+0xa58>
ffffffffc0201c7c:	00003617          	auipc	a2,0x3
ffffffffc0201c80:	cec60613          	addi	a2,a2,-788 # ffffffffc0204968 <commands+0x840>
ffffffffc0201c84:	17e00593          	li	a1,382
ffffffffc0201c88:	00003517          	auipc	a0,0x3
ffffffffc0201c8c:	bd850513          	addi	a0,a0,-1064 # ffffffffc0204860 <commands+0x738>
ffffffffc0201c90:	d4efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0201c94:	00003697          	auipc	a3,0x3
ffffffffc0201c98:	ed468693          	addi	a3,a3,-300 # ffffffffc0204b68 <commands+0xa40>
ffffffffc0201c9c:	00003617          	auipc	a2,0x3
ffffffffc0201ca0:	ccc60613          	addi	a2,a2,-820 # ffffffffc0204968 <commands+0x840>
ffffffffc0201ca4:	17c00593          	li	a1,380
ffffffffc0201ca8:	00003517          	auipc	a0,0x3
ffffffffc0201cac:	bb850513          	addi	a0,a0,-1096 # ffffffffc0204860 <commands+0x738>
ffffffffc0201cb0:	d2efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0201cb4:	00003697          	auipc	a3,0x3
ffffffffc0201cb8:	e9468693          	addi	a3,a3,-364 # ffffffffc0204b48 <commands+0xa20>
ffffffffc0201cbc:	00003617          	auipc	a2,0x3
ffffffffc0201cc0:	cac60613          	addi	a2,a2,-852 # ffffffffc0204968 <commands+0x840>
ffffffffc0201cc4:	17b00593          	li	a1,379
ffffffffc0201cc8:	00003517          	auipc	a0,0x3
ffffffffc0201ccc:	b9850513          	addi	a0,a0,-1128 # ffffffffc0204860 <commands+0x738>
ffffffffc0201cd0:	d0efe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(*ptep & PTE_W);
ffffffffc0201cd4:	00003697          	auipc	a3,0x3
ffffffffc0201cd8:	e6468693          	addi	a3,a3,-412 # ffffffffc0204b38 <commands+0xa10>
ffffffffc0201cdc:	00003617          	auipc	a2,0x3
ffffffffc0201ce0:	c8c60613          	addi	a2,a2,-884 # ffffffffc0204968 <commands+0x840>
ffffffffc0201ce4:	17a00593          	li	a1,378
ffffffffc0201ce8:	00003517          	auipc	a0,0x3
ffffffffc0201cec:	b7850513          	addi	a0,a0,-1160 # ffffffffc0204860 <commands+0x738>
ffffffffc0201cf0:	ceefe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(*ptep & PTE_U);
ffffffffc0201cf4:	00003697          	auipc	a3,0x3
ffffffffc0201cf8:	e3468693          	addi	a3,a3,-460 # ffffffffc0204b28 <commands+0xa00>
ffffffffc0201cfc:	00003617          	auipc	a2,0x3
ffffffffc0201d00:	c6c60613          	addi	a2,a2,-916 # ffffffffc0204968 <commands+0x840>
ffffffffc0201d04:	17900593          	li	a1,377
ffffffffc0201d08:	00003517          	auipc	a0,0x3
ffffffffc0201d0c:	b5850513          	addi	a0,a0,-1192 # ffffffffc0204860 <commands+0x738>
ffffffffc0201d10:	ccefe0ef          	jal	ra,ffffffffc02001de <__panic>
        panic("DTB memory info not available");
ffffffffc0201d14:	00003617          	auipc	a2,0x3
ffffffffc0201d18:	b7460613          	addi	a2,a2,-1164 # ffffffffc0204888 <commands+0x760>
ffffffffc0201d1c:	06400593          	li	a1,100
ffffffffc0201d20:	00003517          	auipc	a0,0x3
ffffffffc0201d24:	b4050513          	addi	a0,a0,-1216 # ffffffffc0204860 <commands+0x738>
ffffffffc0201d28:	cb6fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0201d2c:	00003697          	auipc	a3,0x3
ffffffffc0201d30:	f1468693          	addi	a3,a3,-236 # ffffffffc0204c40 <commands+0xb18>
ffffffffc0201d34:	00003617          	auipc	a2,0x3
ffffffffc0201d38:	c3460613          	addi	a2,a2,-972 # ffffffffc0204968 <commands+0x840>
ffffffffc0201d3c:	1bf00593          	li	a1,447
ffffffffc0201d40:	00003517          	auipc	a0,0x3
ffffffffc0201d44:	b2050513          	addi	a0,a0,-1248 # ffffffffc0204860 <commands+0x738>
ffffffffc0201d48:	c96fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0201d4c:	00003697          	auipc	a3,0x3
ffffffffc0201d50:	da468693          	addi	a3,a3,-604 # ffffffffc0204af0 <commands+0x9c8>
ffffffffc0201d54:	00003617          	auipc	a2,0x3
ffffffffc0201d58:	c1460613          	addi	a2,a2,-1004 # ffffffffc0204968 <commands+0x840>
ffffffffc0201d5c:	17800593          	li	a1,376
ffffffffc0201d60:	00003517          	auipc	a0,0x3
ffffffffc0201d64:	b0050513          	addi	a0,a0,-1280 # ffffffffc0204860 <commands+0x738>
ffffffffc0201d68:	c76fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201d6c:	00003697          	auipc	a3,0x3
ffffffffc0201d70:	d4468693          	addi	a3,a3,-700 # ffffffffc0204ab0 <commands+0x988>
ffffffffc0201d74:	00003617          	auipc	a2,0x3
ffffffffc0201d78:	bf460613          	addi	a2,a2,-1036 # ffffffffc0204968 <commands+0x840>
ffffffffc0201d7c:	17700593          	li	a1,375
ffffffffc0201d80:	00003517          	auipc	a0,0x3
ffffffffc0201d84:	ae050513          	addi	a0,a0,-1312 # ffffffffc0204860 <commands+0x738>
ffffffffc0201d88:	c56fe0ef          	jal	ra,ffffffffc02001de <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d8c:	86d6                	mv	a3,s5
ffffffffc0201d8e:	00003617          	auipc	a2,0x3
ffffffffc0201d92:	aaa60613          	addi	a2,a2,-1366 # ffffffffc0204838 <commands+0x710>
ffffffffc0201d96:	17300593          	li	a1,371
ffffffffc0201d9a:	00003517          	auipc	a0,0x3
ffffffffc0201d9e:	ac650513          	addi	a0,a0,-1338 # ffffffffc0204860 <commands+0x738>
ffffffffc0201da2:	c3cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0201da6:	00003617          	auipc	a2,0x3
ffffffffc0201daa:	a9260613          	addi	a2,a2,-1390 # ffffffffc0204838 <commands+0x710>
ffffffffc0201dae:	17200593          	li	a1,370
ffffffffc0201db2:	00003517          	auipc	a0,0x3
ffffffffc0201db6:	aae50513          	addi	a0,a0,-1362 # ffffffffc0204860 <commands+0x738>
ffffffffc0201dba:	c24fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201dbe:	00003697          	auipc	a3,0x3
ffffffffc0201dc2:	caa68693          	addi	a3,a3,-854 # ffffffffc0204a68 <commands+0x940>
ffffffffc0201dc6:	00003617          	auipc	a2,0x3
ffffffffc0201dca:	ba260613          	addi	a2,a2,-1118 # ffffffffc0204968 <commands+0x840>
ffffffffc0201dce:	17000593          	li	a1,368
ffffffffc0201dd2:	00003517          	auipc	a0,0x3
ffffffffc0201dd6:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0204860 <commands+0x738>
ffffffffc0201dda:	c04fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201dde:	00003697          	auipc	a3,0x3
ffffffffc0201de2:	c7268693          	addi	a3,a3,-910 # ffffffffc0204a50 <commands+0x928>
ffffffffc0201de6:	00003617          	auipc	a2,0x3
ffffffffc0201dea:	b8260613          	addi	a2,a2,-1150 # ffffffffc0204968 <commands+0x840>
ffffffffc0201dee:	16f00593          	li	a1,367
ffffffffc0201df2:	00003517          	auipc	a0,0x3
ffffffffc0201df6:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0204860 <commands+0x738>
ffffffffc0201dfa:	be4fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201dfe:	00003697          	auipc	a3,0x3
ffffffffc0201e02:	00268693          	addi	a3,a3,2 # ffffffffc0204e00 <commands+0xcd8>
ffffffffc0201e06:	00003617          	auipc	a2,0x3
ffffffffc0201e0a:	b6260613          	addi	a2,a2,-1182 # ffffffffc0204968 <commands+0x840>
ffffffffc0201e0e:	1b600593          	li	a1,438
ffffffffc0201e12:	00003517          	auipc	a0,0x3
ffffffffc0201e16:	a4e50513          	addi	a0,a0,-1458 # ffffffffc0204860 <commands+0x738>
ffffffffc0201e1a:	bc4fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201e1e:	00003697          	auipc	a3,0x3
ffffffffc0201e22:	faa68693          	addi	a3,a3,-86 # ffffffffc0204dc8 <commands+0xca0>
ffffffffc0201e26:	00003617          	auipc	a2,0x3
ffffffffc0201e2a:	b4260613          	addi	a2,a2,-1214 # ffffffffc0204968 <commands+0x840>
ffffffffc0201e2e:	1b300593          	li	a1,435
ffffffffc0201e32:	00003517          	auipc	a0,0x3
ffffffffc0201e36:	a2e50513          	addi	a0,a0,-1490 # ffffffffc0204860 <commands+0x738>
ffffffffc0201e3a:	ba4fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p) == 2);
ffffffffc0201e3e:	00003697          	auipc	a3,0x3
ffffffffc0201e42:	f5a68693          	addi	a3,a3,-166 # ffffffffc0204d98 <commands+0xc70>
ffffffffc0201e46:	00003617          	auipc	a2,0x3
ffffffffc0201e4a:	b2260613          	addi	a2,a2,-1246 # ffffffffc0204968 <commands+0x840>
ffffffffc0201e4e:	1af00593          	li	a1,431
ffffffffc0201e52:	00003517          	auipc	a0,0x3
ffffffffc0201e56:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0204860 <commands+0x738>
ffffffffc0201e5a:	b84fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201e5e:	00003697          	auipc	a3,0x3
ffffffffc0201e62:	ef268693          	addi	a3,a3,-270 # ffffffffc0204d50 <commands+0xc28>
ffffffffc0201e66:	00003617          	auipc	a2,0x3
ffffffffc0201e6a:	b0260613          	addi	a2,a2,-1278 # ffffffffc0204968 <commands+0x840>
ffffffffc0201e6e:	1ae00593          	li	a1,430
ffffffffc0201e72:	00003517          	auipc	a0,0x3
ffffffffc0201e76:	9ee50513          	addi	a0,a0,-1554 # ffffffffc0204860 <commands+0x738>
ffffffffc0201e7a:	b64fe0ef          	jal	ra,ffffffffc02001de <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0201e7e:	00003617          	auipc	a2,0x3
ffffffffc0201e82:	a6a60613          	addi	a2,a2,-1430 # ffffffffc02048e8 <commands+0x7c0>
ffffffffc0201e86:	0cb00593          	li	a1,203
ffffffffc0201e8a:	00003517          	auipc	a0,0x3
ffffffffc0201e8e:	9d650513          	addi	a0,a0,-1578 # ffffffffc0204860 <commands+0x738>
ffffffffc0201e92:	b4cfe0ef          	jal	ra,ffffffffc02001de <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201e96:	00003617          	auipc	a2,0x3
ffffffffc0201e9a:	a5260613          	addi	a2,a2,-1454 # ffffffffc02048e8 <commands+0x7c0>
ffffffffc0201e9e:	08000593          	li	a1,128
ffffffffc0201ea2:	00003517          	auipc	a0,0x3
ffffffffc0201ea6:	9be50513          	addi	a0,a0,-1602 # ffffffffc0204860 <commands+0x738>
ffffffffc0201eaa:	b34fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0201eae:	00003697          	auipc	a3,0x3
ffffffffc0201eb2:	b7268693          	addi	a3,a3,-1166 # ffffffffc0204a20 <commands+0x8f8>
ffffffffc0201eb6:	00003617          	auipc	a2,0x3
ffffffffc0201eba:	ab260613          	addi	a2,a2,-1358 # ffffffffc0204968 <commands+0x840>
ffffffffc0201ebe:	16e00593          	li	a1,366
ffffffffc0201ec2:	00003517          	auipc	a0,0x3
ffffffffc0201ec6:	99e50513          	addi	a0,a0,-1634 # ffffffffc0204860 <commands+0x738>
ffffffffc0201eca:	b14fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0201ece:	00003697          	auipc	a3,0x3
ffffffffc0201ed2:	b2268693          	addi	a3,a3,-1246 # ffffffffc02049f0 <commands+0x8c8>
ffffffffc0201ed6:	00003617          	auipc	a2,0x3
ffffffffc0201eda:	a9260613          	addi	a2,a2,-1390 # ffffffffc0204968 <commands+0x840>
ffffffffc0201ede:	16b00593          	li	a1,363
ffffffffc0201ee2:	00003517          	auipc	a0,0x3
ffffffffc0201ee6:	97e50513          	addi	a0,a0,-1666 # ffffffffc0204860 <commands+0x738>
ffffffffc0201eea:	af4fe0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0201eee <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0201eee:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0201ef0:	00003697          	auipc	a3,0x3
ffffffffc0201ef4:	f5868693          	addi	a3,a3,-168 # ffffffffc0204e48 <commands+0xd20>
ffffffffc0201ef8:	00003617          	auipc	a2,0x3
ffffffffc0201efc:	a7060613          	addi	a2,a2,-1424 # ffffffffc0204968 <commands+0x840>
ffffffffc0201f00:	08800593          	li	a1,136
ffffffffc0201f04:	00003517          	auipc	a0,0x3
ffffffffc0201f08:	f6450513          	addi	a0,a0,-156 # ffffffffc0204e68 <commands+0xd40>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0201f0c:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0201f0e:	ad0fe0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0201f12 <find_vma>:
{
ffffffffc0201f12:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0201f14:	c505                	beqz	a0,ffffffffc0201f3c <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0201f16:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0201f18:	c501                	beqz	a0,ffffffffc0201f20 <find_vma+0xe>
ffffffffc0201f1a:	651c                	ld	a5,8(a0)
ffffffffc0201f1c:	02f5f263          	bgeu	a1,a5,ffffffffc0201f40 <find_vma+0x2e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0201f20:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0201f22:	00f68d63          	beq	a3,a5,ffffffffc0201f3c <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0201f26:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7df2b04>
ffffffffc0201f2a:	00e5e663          	bltu	a1,a4,ffffffffc0201f36 <find_vma+0x24>
ffffffffc0201f2e:	ff07b703          	ld	a4,-16(a5)
ffffffffc0201f32:	00e5ec63          	bltu	a1,a4,ffffffffc0201f4a <find_vma+0x38>
ffffffffc0201f36:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0201f38:	fef697e3          	bne	a3,a5,ffffffffc0201f26 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0201f3c:	4501                	li	a0,0
}
ffffffffc0201f3e:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0201f40:	691c                	ld	a5,16(a0)
ffffffffc0201f42:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0201f20 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0201f46:	ea88                	sd	a0,16(a3)
ffffffffc0201f48:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0201f4a:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0201f4e:	ea88                	sd	a0,16(a3)
ffffffffc0201f50:	8082                	ret

ffffffffc0201f52 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201f52:	6590                	ld	a2,8(a1)
ffffffffc0201f54:	0105b803          	ld	a6,16(a1)
{
ffffffffc0201f58:	1141                	addi	sp,sp,-16
ffffffffc0201f5a:	e406                	sd	ra,8(sp)
ffffffffc0201f5c:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201f5e:	01066763          	bltu	a2,a6,ffffffffc0201f6c <insert_vma_struct+0x1a>
ffffffffc0201f62:	a085                	j	ffffffffc0201fc2 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0201f64:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201f68:	04e66863          	bltu	a2,a4,ffffffffc0201fb8 <insert_vma_struct+0x66>
ffffffffc0201f6c:	86be                	mv	a3,a5
ffffffffc0201f6e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0201f70:	fef51ae3          	bne	a0,a5,ffffffffc0201f64 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0201f74:	02a68463          	beq	a3,a0,ffffffffc0201f9c <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0201f78:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0201f7c:	fe86b883          	ld	a7,-24(a3)
ffffffffc0201f80:	08e8f163          	bgeu	a7,a4,ffffffffc0202002 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201f84:	04e66f63          	bltu	a2,a4,ffffffffc0201fe2 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0201f88:	00f50a63          	beq	a0,a5,ffffffffc0201f9c <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0201f8c:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201f90:	05076963          	bltu	a4,a6,ffffffffc0201fe2 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0201f94:	ff07b603          	ld	a2,-16(a5)
ffffffffc0201f98:	02c77363          	bgeu	a4,a2,ffffffffc0201fbe <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0201f9c:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0201f9e:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0201fa0:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201fa4:	e390                	sd	a2,0(a5)
ffffffffc0201fa6:	e690                	sd	a2,8(a3)
}
ffffffffc0201fa8:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0201faa:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0201fac:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0201fae:	0017079b          	addiw	a5,a4,1
ffffffffc0201fb2:	d11c                	sw	a5,32(a0)
}
ffffffffc0201fb4:	0141                	addi	sp,sp,16
ffffffffc0201fb6:	8082                	ret
    if (le_prev != list)
ffffffffc0201fb8:	fca690e3          	bne	a3,a0,ffffffffc0201f78 <insert_vma_struct+0x26>
ffffffffc0201fbc:	bfd1                	j	ffffffffc0201f90 <insert_vma_struct+0x3e>
ffffffffc0201fbe:	f31ff0ef          	jal	ra,ffffffffc0201eee <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201fc2:	00003697          	auipc	a3,0x3
ffffffffc0201fc6:	eb668693          	addi	a3,a3,-330 # ffffffffc0204e78 <commands+0xd50>
ffffffffc0201fca:	00003617          	auipc	a2,0x3
ffffffffc0201fce:	99e60613          	addi	a2,a2,-1634 # ffffffffc0204968 <commands+0x840>
ffffffffc0201fd2:	08e00593          	li	a1,142
ffffffffc0201fd6:	00003517          	auipc	a0,0x3
ffffffffc0201fda:	e9250513          	addi	a0,a0,-366 # ffffffffc0204e68 <commands+0xd40>
ffffffffc0201fde:	a00fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201fe2:	00003697          	auipc	a3,0x3
ffffffffc0201fe6:	ed668693          	addi	a3,a3,-298 # ffffffffc0204eb8 <commands+0xd90>
ffffffffc0201fea:	00003617          	auipc	a2,0x3
ffffffffc0201fee:	97e60613          	addi	a2,a2,-1666 # ffffffffc0204968 <commands+0x840>
ffffffffc0201ff2:	08700593          	li	a1,135
ffffffffc0201ff6:	00003517          	auipc	a0,0x3
ffffffffc0201ffa:	e7250513          	addi	a0,a0,-398 # ffffffffc0204e68 <commands+0xd40>
ffffffffc0201ffe:	9e0fe0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202002:	00003697          	auipc	a3,0x3
ffffffffc0202006:	e9668693          	addi	a3,a3,-362 # ffffffffc0204e98 <commands+0xd70>
ffffffffc020200a:	00003617          	auipc	a2,0x3
ffffffffc020200e:	95e60613          	addi	a2,a2,-1698 # ffffffffc0204968 <commands+0x840>
ffffffffc0202012:	08600593          	li	a1,134
ffffffffc0202016:	00003517          	auipc	a0,0x3
ffffffffc020201a:	e5250513          	addi	a0,a0,-430 # ffffffffc0204e68 <commands+0xd40>
ffffffffc020201e:	9c0fe0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202022 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202022:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202024:	03000513          	li	a0,48
{
ffffffffc0202028:	fc06                	sd	ra,56(sp)
ffffffffc020202a:	f822                	sd	s0,48(sp)
ffffffffc020202c:	f426                	sd	s1,40(sp)
ffffffffc020202e:	f04a                	sd	s2,32(sp)
ffffffffc0202030:	ec4e                	sd	s3,24(sp)
ffffffffc0202032:	e852                	sd	s4,16(sp)
ffffffffc0202034:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202036:	550000ef          	jal	ra,ffffffffc0202586 <kmalloc>
    if (mm != NULL)
ffffffffc020203a:	2e050f63          	beqz	a0,ffffffffc0202338 <vmm_init+0x316>
ffffffffc020203e:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0202040:	e508                	sd	a0,8(a0)
ffffffffc0202042:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202044:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202048:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020204c:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202050:	02053423          	sd	zero,40(a0)
ffffffffc0202054:	03200413          	li	s0,50
ffffffffc0202058:	a811                	j	ffffffffc020206c <vmm_init+0x4a>
        vma->vm_start = vm_start;
ffffffffc020205a:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc020205c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020205e:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0202062:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202064:	8526                	mv	a0,s1
ffffffffc0202066:	eedff0ef          	jal	ra,ffffffffc0201f52 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc020206a:	c80d                	beqz	s0,ffffffffc020209c <vmm_init+0x7a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020206c:	03000513          	li	a0,48
ffffffffc0202070:	516000ef          	jal	ra,ffffffffc0202586 <kmalloc>
ffffffffc0202074:	85aa                	mv	a1,a0
ffffffffc0202076:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc020207a:	f165                	bnez	a0,ffffffffc020205a <vmm_init+0x38>
        assert(vma != NULL);
ffffffffc020207c:	00003697          	auipc	a3,0x3
ffffffffc0202080:	fd468693          	addi	a3,a3,-44 # ffffffffc0205050 <commands+0xf28>
ffffffffc0202084:	00003617          	auipc	a2,0x3
ffffffffc0202088:	8e460613          	addi	a2,a2,-1820 # ffffffffc0204968 <commands+0x840>
ffffffffc020208c:	0da00593          	li	a1,218
ffffffffc0202090:	00003517          	auipc	a0,0x3
ffffffffc0202094:	dd850513          	addi	a0,a0,-552 # ffffffffc0204e68 <commands+0xd40>
ffffffffc0202098:	946fe0ef          	jal	ra,ffffffffc02001de <__panic>
ffffffffc020209c:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc02020a0:	1f900913          	li	s2,505
ffffffffc02020a4:	a819                	j	ffffffffc02020ba <vmm_init+0x98>
        vma->vm_start = vm_start;
ffffffffc02020a6:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02020a8:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02020aa:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02020ae:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02020b0:	8526                	mv	a0,s1
ffffffffc02020b2:	ea1ff0ef          	jal	ra,ffffffffc0201f52 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02020b6:	03240a63          	beq	s0,s2,ffffffffc02020ea <vmm_init+0xc8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02020ba:	03000513          	li	a0,48
ffffffffc02020be:	4c8000ef          	jal	ra,ffffffffc0202586 <kmalloc>
ffffffffc02020c2:	85aa                	mv	a1,a0
ffffffffc02020c4:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc02020c8:	fd79                	bnez	a0,ffffffffc02020a6 <vmm_init+0x84>
        assert(vma != NULL);
ffffffffc02020ca:	00003697          	auipc	a3,0x3
ffffffffc02020ce:	f8668693          	addi	a3,a3,-122 # ffffffffc0205050 <commands+0xf28>
ffffffffc02020d2:	00003617          	auipc	a2,0x3
ffffffffc02020d6:	89660613          	addi	a2,a2,-1898 # ffffffffc0204968 <commands+0x840>
ffffffffc02020da:	0e100593          	li	a1,225
ffffffffc02020de:	00003517          	auipc	a0,0x3
ffffffffc02020e2:	d8a50513          	addi	a0,a0,-630 # ffffffffc0204e68 <commands+0xd40>
ffffffffc02020e6:	8f8fe0ef          	jal	ra,ffffffffc02001de <__panic>
    return listelm->next;
ffffffffc02020ea:	649c                	ld	a5,8(s1)
ffffffffc02020ec:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc02020ee:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc02020f2:	18f48363          	beq	s1,a5,ffffffffc0202278 <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02020f6:	fe87b603          	ld	a2,-24(a5)
ffffffffc02020fa:	ffe70693          	addi	a3,a4,-2 # ffe <kern_entry-0xffffffffc01ff002>
ffffffffc02020fe:	10d61d63          	bne	a2,a3,ffffffffc0202218 <vmm_init+0x1f6>
ffffffffc0202102:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202106:	10e69963          	bne	a3,a4,ffffffffc0202218 <vmm_init+0x1f6>
    for (i = 1; i <= step2; i++)
ffffffffc020210a:	0715                	addi	a4,a4,5
ffffffffc020210c:	679c                	ld	a5,8(a5)
ffffffffc020210e:	feb712e3          	bne	a4,a1,ffffffffc02020f2 <vmm_init+0xd0>
ffffffffc0202112:	4a1d                	li	s4,7
ffffffffc0202114:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202116:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc020211a:	85a2                	mv	a1,s0
ffffffffc020211c:	8526                	mv	a0,s1
ffffffffc020211e:	df5ff0ef          	jal	ra,ffffffffc0201f12 <find_vma>
ffffffffc0202122:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202124:	18050a63          	beqz	a0,ffffffffc02022b8 <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202128:	00140593          	addi	a1,s0,1
ffffffffc020212c:	8526                	mv	a0,s1
ffffffffc020212e:	de5ff0ef          	jal	ra,ffffffffc0201f12 <find_vma>
ffffffffc0202132:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202134:	16050263          	beqz	a0,ffffffffc0202298 <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202138:	85d2                	mv	a1,s4
ffffffffc020213a:	8526                	mv	a0,s1
ffffffffc020213c:	dd7ff0ef          	jal	ra,ffffffffc0201f12 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202140:	18051c63          	bnez	a0,ffffffffc02022d8 <vmm_init+0x2b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202144:	00340593          	addi	a1,s0,3
ffffffffc0202148:	8526                	mv	a0,s1
ffffffffc020214a:	dc9ff0ef          	jal	ra,ffffffffc0201f12 <find_vma>
        assert(vma4 == NULL);
ffffffffc020214e:	1c051563          	bnez	a0,ffffffffc0202318 <vmm_init+0x2f6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202152:	00440593          	addi	a1,s0,4
ffffffffc0202156:	8526                	mv	a0,s1
ffffffffc0202158:	dbbff0ef          	jal	ra,ffffffffc0201f12 <find_vma>
        assert(vma5 == NULL);
ffffffffc020215c:	18051e63          	bnez	a0,ffffffffc02022f8 <vmm_init+0x2d6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202160:	00893783          	ld	a5,8(s2)
ffffffffc0202164:	0c879a63          	bne	a5,s0,ffffffffc0202238 <vmm_init+0x216>
ffffffffc0202168:	01093783          	ld	a5,16(s2)
ffffffffc020216c:	0d479663          	bne	a5,s4,ffffffffc0202238 <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202170:	0089b783          	ld	a5,8(s3)
ffffffffc0202174:	0e879263          	bne	a5,s0,ffffffffc0202258 <vmm_init+0x236>
ffffffffc0202178:	0109b783          	ld	a5,16(s3)
ffffffffc020217c:	0d479e63          	bne	a5,s4,ffffffffc0202258 <vmm_init+0x236>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202180:	0415                	addi	s0,s0,5
ffffffffc0202182:	0a15                	addi	s4,s4,5
ffffffffc0202184:	f9541be3          	bne	s0,s5,ffffffffc020211a <vmm_init+0xf8>
ffffffffc0202188:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc020218a:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc020218c:	85a2                	mv	a1,s0
ffffffffc020218e:	8526                	mv	a0,s1
ffffffffc0202190:	d83ff0ef          	jal	ra,ffffffffc0201f12 <find_vma>
ffffffffc0202194:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0202198:	c90d                	beqz	a0,ffffffffc02021ca <vmm_init+0x1a8>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc020219a:	6914                	ld	a3,16(a0)
ffffffffc020219c:	6510                	ld	a2,8(a0)
ffffffffc020219e:	00003517          	auipc	a0,0x3
ffffffffc02021a2:	e3a50513          	addi	a0,a0,-454 # ffffffffc0204fd8 <commands+0xeb0>
ffffffffc02021a6:	f3bfd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02021aa:	00003697          	auipc	a3,0x3
ffffffffc02021ae:	e5668693          	addi	a3,a3,-426 # ffffffffc0205000 <commands+0xed8>
ffffffffc02021b2:	00002617          	auipc	a2,0x2
ffffffffc02021b6:	7b660613          	addi	a2,a2,1974 # ffffffffc0204968 <commands+0x840>
ffffffffc02021ba:	10700593          	li	a1,263
ffffffffc02021be:	00003517          	auipc	a0,0x3
ffffffffc02021c2:	caa50513          	addi	a0,a0,-854 # ffffffffc0204e68 <commands+0xd40>
ffffffffc02021c6:	818fe0ef          	jal	ra,ffffffffc02001de <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc02021ca:	147d                	addi	s0,s0,-1
ffffffffc02021cc:	fd2410e3          	bne	s0,s2,ffffffffc020218c <vmm_init+0x16a>
ffffffffc02021d0:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc02021d2:	00a48c63          	beq	s1,a0,ffffffffc02021ea <vmm_init+0x1c8>
    __list_del(listelm->prev, listelm->next);
ffffffffc02021d6:	6118                	ld	a4,0(a0)
ffffffffc02021d8:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02021da:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02021dc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02021de:	e398                	sd	a4,0(a5)
ffffffffc02021e0:	456000ef          	jal	ra,ffffffffc0202636 <kfree>
    return listelm->next;
ffffffffc02021e4:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc02021e6:	fea498e3          	bne	s1,a0,ffffffffc02021d6 <vmm_init+0x1b4>
    kfree(mm); // kfree mm
ffffffffc02021ea:	8526                	mv	a0,s1
ffffffffc02021ec:	44a000ef          	jal	ra,ffffffffc0202636 <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02021f0:	00003517          	auipc	a0,0x3
ffffffffc02021f4:	e2850513          	addi	a0,a0,-472 # ffffffffc0205018 <commands+0xef0>
ffffffffc02021f8:	ee9fd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
}
ffffffffc02021fc:	7442                	ld	s0,48(sp)
ffffffffc02021fe:	70e2                	ld	ra,56(sp)
ffffffffc0202200:	74a2                	ld	s1,40(sp)
ffffffffc0202202:	7902                	ld	s2,32(sp)
ffffffffc0202204:	69e2                	ld	s3,24(sp)
ffffffffc0202206:	6a42                	ld	s4,16(sp)
ffffffffc0202208:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc020220a:	00003517          	auipc	a0,0x3
ffffffffc020220e:	e2e50513          	addi	a0,a0,-466 # ffffffffc0205038 <commands+0xf10>
}
ffffffffc0202212:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202214:	ecdfd06f          	j	ffffffffc02000e0 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202218:	00003697          	auipc	a3,0x3
ffffffffc020221c:	cd868693          	addi	a3,a3,-808 # ffffffffc0204ef0 <commands+0xdc8>
ffffffffc0202220:	00002617          	auipc	a2,0x2
ffffffffc0202224:	74860613          	addi	a2,a2,1864 # ffffffffc0204968 <commands+0x840>
ffffffffc0202228:	0eb00593          	li	a1,235
ffffffffc020222c:	00003517          	auipc	a0,0x3
ffffffffc0202230:	c3c50513          	addi	a0,a0,-964 # ffffffffc0204e68 <commands+0xd40>
ffffffffc0202234:	fabfd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202238:	00003697          	auipc	a3,0x3
ffffffffc020223c:	d4068693          	addi	a3,a3,-704 # ffffffffc0204f78 <commands+0xe50>
ffffffffc0202240:	00002617          	auipc	a2,0x2
ffffffffc0202244:	72860613          	addi	a2,a2,1832 # ffffffffc0204968 <commands+0x840>
ffffffffc0202248:	0fc00593          	li	a1,252
ffffffffc020224c:	00003517          	auipc	a0,0x3
ffffffffc0202250:	c1c50513          	addi	a0,a0,-996 # ffffffffc0204e68 <commands+0xd40>
ffffffffc0202254:	f8bfd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202258:	00003697          	auipc	a3,0x3
ffffffffc020225c:	d5068693          	addi	a3,a3,-688 # ffffffffc0204fa8 <commands+0xe80>
ffffffffc0202260:	00002617          	auipc	a2,0x2
ffffffffc0202264:	70860613          	addi	a2,a2,1800 # ffffffffc0204968 <commands+0x840>
ffffffffc0202268:	0fd00593          	li	a1,253
ffffffffc020226c:	00003517          	auipc	a0,0x3
ffffffffc0202270:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0204e68 <commands+0xd40>
ffffffffc0202274:	f6bfd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0202278:	00003697          	auipc	a3,0x3
ffffffffc020227c:	c6068693          	addi	a3,a3,-928 # ffffffffc0204ed8 <commands+0xdb0>
ffffffffc0202280:	00002617          	auipc	a2,0x2
ffffffffc0202284:	6e860613          	addi	a2,a2,1768 # ffffffffc0204968 <commands+0x840>
ffffffffc0202288:	0e900593          	li	a1,233
ffffffffc020228c:	00003517          	auipc	a0,0x3
ffffffffc0202290:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0204e68 <commands+0xd40>
ffffffffc0202294:	f4bfd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma2 != NULL);
ffffffffc0202298:	00003697          	auipc	a3,0x3
ffffffffc020229c:	ca068693          	addi	a3,a3,-864 # ffffffffc0204f38 <commands+0xe10>
ffffffffc02022a0:	00002617          	auipc	a2,0x2
ffffffffc02022a4:	6c860613          	addi	a2,a2,1736 # ffffffffc0204968 <commands+0x840>
ffffffffc02022a8:	0f400593          	li	a1,244
ffffffffc02022ac:	00003517          	auipc	a0,0x3
ffffffffc02022b0:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0204e68 <commands+0xd40>
ffffffffc02022b4:	f2bfd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma1 != NULL);
ffffffffc02022b8:	00003697          	auipc	a3,0x3
ffffffffc02022bc:	c7068693          	addi	a3,a3,-912 # ffffffffc0204f28 <commands+0xe00>
ffffffffc02022c0:	00002617          	auipc	a2,0x2
ffffffffc02022c4:	6a860613          	addi	a2,a2,1704 # ffffffffc0204968 <commands+0x840>
ffffffffc02022c8:	0f200593          	li	a1,242
ffffffffc02022cc:	00003517          	auipc	a0,0x3
ffffffffc02022d0:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0204e68 <commands+0xd40>
ffffffffc02022d4:	f0bfd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma3 == NULL);
ffffffffc02022d8:	00003697          	auipc	a3,0x3
ffffffffc02022dc:	c7068693          	addi	a3,a3,-912 # ffffffffc0204f48 <commands+0xe20>
ffffffffc02022e0:	00002617          	auipc	a2,0x2
ffffffffc02022e4:	68860613          	addi	a2,a2,1672 # ffffffffc0204968 <commands+0x840>
ffffffffc02022e8:	0f600593          	li	a1,246
ffffffffc02022ec:	00003517          	auipc	a0,0x3
ffffffffc02022f0:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0204e68 <commands+0xd40>
ffffffffc02022f4:	eebfd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma5 == NULL);
ffffffffc02022f8:	00003697          	auipc	a3,0x3
ffffffffc02022fc:	c7068693          	addi	a3,a3,-912 # ffffffffc0204f68 <commands+0xe40>
ffffffffc0202300:	00002617          	auipc	a2,0x2
ffffffffc0202304:	66860613          	addi	a2,a2,1640 # ffffffffc0204968 <commands+0x840>
ffffffffc0202308:	0fa00593          	li	a1,250
ffffffffc020230c:	00003517          	auipc	a0,0x3
ffffffffc0202310:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0204e68 <commands+0xd40>
ffffffffc0202314:	ecbfd0ef          	jal	ra,ffffffffc02001de <__panic>
        assert(vma4 == NULL);
ffffffffc0202318:	00003697          	auipc	a3,0x3
ffffffffc020231c:	c4068693          	addi	a3,a3,-960 # ffffffffc0204f58 <commands+0xe30>
ffffffffc0202320:	00002617          	auipc	a2,0x2
ffffffffc0202324:	64860613          	addi	a2,a2,1608 # ffffffffc0204968 <commands+0x840>
ffffffffc0202328:	0f800593          	li	a1,248
ffffffffc020232c:	00003517          	auipc	a0,0x3
ffffffffc0202330:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0204e68 <commands+0xd40>
ffffffffc0202334:	eabfd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(mm != NULL);
ffffffffc0202338:	00003697          	auipc	a3,0x3
ffffffffc020233c:	d2868693          	addi	a3,a3,-728 # ffffffffc0205060 <commands+0xf38>
ffffffffc0202340:	00002617          	auipc	a2,0x2
ffffffffc0202344:	62860613          	addi	a2,a2,1576 # ffffffffc0204968 <commands+0x840>
ffffffffc0202348:	0d200593          	li	a1,210
ffffffffc020234c:	00003517          	auipc	a0,0x3
ffffffffc0202350:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0204e68 <commands+0xd40>
ffffffffc0202354:	e8bfd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202358 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0202358:	c94d                	beqz	a0,ffffffffc020240a <slob_free+0xb2>
{
ffffffffc020235a:	1141                	addi	sp,sp,-16
ffffffffc020235c:	e022                	sd	s0,0(sp)
ffffffffc020235e:	e406                	sd	ra,8(sp)
ffffffffc0202360:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0202362:	e9c1                	bnez	a1,ffffffffc02023f2 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202364:	100027f3          	csrr	a5,sstatus
ffffffffc0202368:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020236a:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020236c:	ebd9                	bnez	a5,ffffffffc0202402 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020236e:	00007617          	auipc	a2,0x7
ffffffffc0202372:	cb260613          	addi	a2,a2,-846 # ffffffffc0209020 <slobfree>
ffffffffc0202376:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0202378:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020237a:	679c                	ld	a5,8(a5)
ffffffffc020237c:	02877a63          	bgeu	a4,s0,ffffffffc02023b0 <slob_free+0x58>
ffffffffc0202380:	00f46463          	bltu	s0,a5,ffffffffc0202388 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0202384:	fef76ae3          	bltu	a4,a5,ffffffffc0202378 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0202388:	400c                	lw	a1,0(s0)
ffffffffc020238a:	00459693          	slli	a3,a1,0x4
ffffffffc020238e:	96a2                	add	a3,a3,s0
ffffffffc0202390:	02d78a63          	beq	a5,a3,ffffffffc02023c4 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0202394:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0202396:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0202398:	00469793          	slli	a5,a3,0x4
ffffffffc020239c:	97ba                	add	a5,a5,a4
ffffffffc020239e:	02f40e63          	beq	s0,a5,ffffffffc02023da <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02023a2:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02023a4:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc02023a6:	e129                	bnez	a0,ffffffffc02023e8 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02023a8:	60a2                	ld	ra,8(sp)
ffffffffc02023aa:	6402                	ld	s0,0(sp)
ffffffffc02023ac:	0141                	addi	sp,sp,16
ffffffffc02023ae:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02023b0:	fcf764e3          	bltu	a4,a5,ffffffffc0202378 <slob_free+0x20>
ffffffffc02023b4:	fcf472e3          	bgeu	s0,a5,ffffffffc0202378 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc02023b8:	400c                	lw	a1,0(s0)
ffffffffc02023ba:	00459693          	slli	a3,a1,0x4
ffffffffc02023be:	96a2                	add	a3,a3,s0
ffffffffc02023c0:	fcd79ae3          	bne	a5,a3,ffffffffc0202394 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc02023c4:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02023c6:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02023c8:	9db5                	addw	a1,a1,a3
ffffffffc02023ca:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc02023cc:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02023ce:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02023d0:	00469793          	slli	a5,a3,0x4
ffffffffc02023d4:	97ba                	add	a5,a5,a4
ffffffffc02023d6:	fcf416e3          	bne	s0,a5,ffffffffc02023a2 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc02023da:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc02023dc:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc02023de:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc02023e0:	9ebd                	addw	a3,a3,a5
ffffffffc02023e2:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc02023e4:	e70c                	sd	a1,8(a4)
ffffffffc02023e6:	d169                	beqz	a0,ffffffffc02023a8 <slob_free+0x50>
}
ffffffffc02023e8:	6402                	ld	s0,0(sp)
ffffffffc02023ea:	60a2                	ld	ra,8(sp)
ffffffffc02023ec:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02023ee:	d42fe06f          	j	ffffffffc0200930 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc02023f2:	25bd                	addiw	a1,a1,15
ffffffffc02023f4:	8191                	srli	a1,a1,0x4
ffffffffc02023f6:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02023f8:	100027f3          	csrr	a5,sstatus
ffffffffc02023fc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02023fe:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202400:	d7bd                	beqz	a5,ffffffffc020236e <slob_free+0x16>
        intr_disable();
ffffffffc0202402:	d34fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        return 1;
ffffffffc0202406:	4505                	li	a0,1
ffffffffc0202408:	b79d                	j	ffffffffc020236e <slob_free+0x16>
ffffffffc020240a:	8082                	ret

ffffffffc020240c <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc020240c:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020240e:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0202410:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0202414:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0202416:	9d5fe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
	if (!page)
ffffffffc020241a:	c91d                	beqz	a0,ffffffffc0202450 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc020241c:	0000b697          	auipc	a3,0xb
ffffffffc0202420:	08c6b683          	ld	a3,140(a3) # ffffffffc020d4a8 <pages>
ffffffffc0202424:	8d15                	sub	a0,a0,a3
ffffffffc0202426:	8519                	srai	a0,a0,0x6
ffffffffc0202428:	00003697          	auipc	a3,0x3
ffffffffc020242c:	4906b683          	ld	a3,1168(a3) # ffffffffc02058b8 <nbase>
ffffffffc0202430:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0202432:	00c51793          	slli	a5,a0,0xc
ffffffffc0202436:	83b1                	srli	a5,a5,0xc
ffffffffc0202438:	0000b717          	auipc	a4,0xb
ffffffffc020243c:	06873703          	ld	a4,104(a4) # ffffffffc020d4a0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202440:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0202442:	00e7fa63          	bgeu	a5,a4,ffffffffc0202456 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0202446:	0000b697          	auipc	a3,0xb
ffffffffc020244a:	0726b683          	ld	a3,114(a3) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc020244e:	9536                	add	a0,a0,a3
}
ffffffffc0202450:	60a2                	ld	ra,8(sp)
ffffffffc0202452:	0141                	addi	sp,sp,16
ffffffffc0202454:	8082                	ret
ffffffffc0202456:	86aa                	mv	a3,a0
ffffffffc0202458:	00002617          	auipc	a2,0x2
ffffffffc020245c:	3e060613          	addi	a2,a2,992 # ffffffffc0204838 <commands+0x710>
ffffffffc0202460:	07100593          	li	a1,113
ffffffffc0202464:	00002517          	auipc	a0,0x2
ffffffffc0202468:	39c50513          	addi	a0,a0,924 # ffffffffc0204800 <commands+0x6d8>
ffffffffc020246c:	d73fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202470 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0202470:	1101                	addi	sp,sp,-32
ffffffffc0202472:	ec06                	sd	ra,24(sp)
ffffffffc0202474:	e822                	sd	s0,16(sp)
ffffffffc0202476:	e426                	sd	s1,8(sp)
ffffffffc0202478:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc020247a:	01050713          	addi	a4,a0,16
ffffffffc020247e:	6785                	lui	a5,0x1
ffffffffc0202480:	0cf77363          	bgeu	a4,a5,ffffffffc0202546 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0202484:	00f50493          	addi	s1,a0,15
ffffffffc0202488:	8091                	srli	s1,s1,0x4
ffffffffc020248a:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020248c:	10002673          	csrr	a2,sstatus
ffffffffc0202490:	8a09                	andi	a2,a2,2
ffffffffc0202492:	e25d                	bnez	a2,ffffffffc0202538 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0202494:	00007917          	auipc	s2,0x7
ffffffffc0202498:	b8c90913          	addi	s2,s2,-1140 # ffffffffc0209020 <slobfree>
ffffffffc020249c:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02024a0:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc02024a2:	4398                	lw	a4,0(a5)
ffffffffc02024a4:	08975e63          	bge	a4,s1,ffffffffc0202540 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc02024a8:	00d78b63          	beq	a5,a3,ffffffffc02024be <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02024ac:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02024ae:	4018                	lw	a4,0(s0)
ffffffffc02024b0:	02975a63          	bge	a4,s1,ffffffffc02024e4 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc02024b4:	00093683          	ld	a3,0(s2)
ffffffffc02024b8:	87a2                	mv	a5,s0
ffffffffc02024ba:	fed799e3          	bne	a5,a3,ffffffffc02024ac <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc02024be:	ee31                	bnez	a2,ffffffffc020251a <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02024c0:	4501                	li	a0,0
ffffffffc02024c2:	f4bff0ef          	jal	ra,ffffffffc020240c <__slob_get_free_pages.constprop.0>
ffffffffc02024c6:	842a                	mv	s0,a0
			if (!cur)
ffffffffc02024c8:	cd05                	beqz	a0,ffffffffc0202500 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc02024ca:	6585                	lui	a1,0x1
ffffffffc02024cc:	e8dff0ef          	jal	ra,ffffffffc0202358 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02024d0:	10002673          	csrr	a2,sstatus
ffffffffc02024d4:	8a09                	andi	a2,a2,2
ffffffffc02024d6:	ee05                	bnez	a2,ffffffffc020250e <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc02024d8:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02024dc:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02024de:	4018                	lw	a4,0(s0)
ffffffffc02024e0:	fc974ae3          	blt	a4,s1,ffffffffc02024b4 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc02024e4:	04e48763          	beq	s1,a4,ffffffffc0202532 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc02024e8:	00449693          	slli	a3,s1,0x4
ffffffffc02024ec:	96a2                	add	a3,a3,s0
ffffffffc02024ee:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc02024f0:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc02024f2:	9f05                	subw	a4,a4,s1
ffffffffc02024f4:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc02024f6:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc02024f8:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc02024fa:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc02024fe:	e20d                	bnez	a2,ffffffffc0202520 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0202500:	60e2                	ld	ra,24(sp)
ffffffffc0202502:	8522                	mv	a0,s0
ffffffffc0202504:	6442                	ld	s0,16(sp)
ffffffffc0202506:	64a2                	ld	s1,8(sp)
ffffffffc0202508:	6902                	ld	s2,0(sp)
ffffffffc020250a:	6105                	addi	sp,sp,32
ffffffffc020250c:	8082                	ret
        intr_disable();
ffffffffc020250e:	c28fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
			cur = slobfree;
ffffffffc0202512:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0202516:	4605                	li	a2,1
ffffffffc0202518:	b7d1                	j	ffffffffc02024dc <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc020251a:	c16fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc020251e:	b74d                	j	ffffffffc02024c0 <slob_alloc.constprop.0+0x50>
ffffffffc0202520:	c10fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
}
ffffffffc0202524:	60e2                	ld	ra,24(sp)
ffffffffc0202526:	8522                	mv	a0,s0
ffffffffc0202528:	6442                	ld	s0,16(sp)
ffffffffc020252a:	64a2                	ld	s1,8(sp)
ffffffffc020252c:	6902                	ld	s2,0(sp)
ffffffffc020252e:	6105                	addi	sp,sp,32
ffffffffc0202530:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0202532:	6418                	ld	a4,8(s0)
ffffffffc0202534:	e798                	sd	a4,8(a5)
ffffffffc0202536:	b7d1                	j	ffffffffc02024fa <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0202538:	bfefe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        return 1;
ffffffffc020253c:	4605                	li	a2,1
ffffffffc020253e:	bf99                	j	ffffffffc0202494 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0202540:	843e                	mv	s0,a5
ffffffffc0202542:	87b6                	mv	a5,a3
ffffffffc0202544:	b745                	j	ffffffffc02024e4 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0202546:	00003697          	auipc	a3,0x3
ffffffffc020254a:	b2a68693          	addi	a3,a3,-1238 # ffffffffc0205070 <commands+0xf48>
ffffffffc020254e:	00002617          	auipc	a2,0x2
ffffffffc0202552:	41a60613          	addi	a2,a2,1050 # ffffffffc0204968 <commands+0x840>
ffffffffc0202556:	06300593          	li	a1,99
ffffffffc020255a:	00003517          	auipc	a0,0x3
ffffffffc020255e:	b3650513          	addi	a0,a0,-1226 # ffffffffc0205090 <commands+0xf68>
ffffffffc0202562:	c7dfd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202566 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0202566:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0202568:	00003517          	auipc	a0,0x3
ffffffffc020256c:	b4050513          	addi	a0,a0,-1216 # ffffffffc02050a8 <commands+0xf80>
{
ffffffffc0202570:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0202572:	b6ffd0ef          	jal	ra,ffffffffc02000e0 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0202576:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0202578:	00003517          	auipc	a0,0x3
ffffffffc020257c:	b4850513          	addi	a0,a0,-1208 # ffffffffc02050c0 <commands+0xf98>
}
ffffffffc0202580:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0202582:	b5ffd06f          	j	ffffffffc02000e0 <cprintf>

ffffffffc0202586 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0202586:	1101                	addi	sp,sp,-32
ffffffffc0202588:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc020258a:	6905                	lui	s2,0x1
{
ffffffffc020258c:	e822                	sd	s0,16(sp)
ffffffffc020258e:	ec06                	sd	ra,24(sp)
ffffffffc0202590:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0202592:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0202596:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0202598:	04a7f963          	bgeu	a5,a0,ffffffffc02025ea <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc020259c:	4561                	li	a0,24
ffffffffc020259e:	ed3ff0ef          	jal	ra,ffffffffc0202470 <slob_alloc.constprop.0>
ffffffffc02025a2:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc02025a4:	c929                	beqz	a0,ffffffffc02025f6 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc02025a6:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc02025aa:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc02025ac:	00f95763          	bge	s2,a5,ffffffffc02025ba <kmalloc+0x34>
ffffffffc02025b0:	6705                	lui	a4,0x1
ffffffffc02025b2:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc02025b4:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc02025b6:	fef74ee3          	blt	a4,a5,ffffffffc02025b2 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc02025ba:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc02025bc:	e51ff0ef          	jal	ra,ffffffffc020240c <__slob_get_free_pages.constprop.0>
ffffffffc02025c0:	e488                	sd	a0,8(s1)
ffffffffc02025c2:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc02025c4:	c525                	beqz	a0,ffffffffc020262c <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02025c6:	100027f3          	csrr	a5,sstatus
ffffffffc02025ca:	8b89                	andi	a5,a5,2
ffffffffc02025cc:	ef8d                	bnez	a5,ffffffffc0202606 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc02025ce:	0000b797          	auipc	a5,0xb
ffffffffc02025d2:	ef278793          	addi	a5,a5,-270 # ffffffffc020d4c0 <bigblocks>
ffffffffc02025d6:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc02025d8:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc02025da:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc02025dc:	60e2                	ld	ra,24(sp)
ffffffffc02025de:	8522                	mv	a0,s0
ffffffffc02025e0:	6442                	ld	s0,16(sp)
ffffffffc02025e2:	64a2                	ld	s1,8(sp)
ffffffffc02025e4:	6902                	ld	s2,0(sp)
ffffffffc02025e6:	6105                	addi	sp,sp,32
ffffffffc02025e8:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc02025ea:	0541                	addi	a0,a0,16
ffffffffc02025ec:	e85ff0ef          	jal	ra,ffffffffc0202470 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc02025f0:	01050413          	addi	s0,a0,16
ffffffffc02025f4:	f565                	bnez	a0,ffffffffc02025dc <kmalloc+0x56>
ffffffffc02025f6:	4401                	li	s0,0
}
ffffffffc02025f8:	60e2                	ld	ra,24(sp)
ffffffffc02025fa:	8522                	mv	a0,s0
ffffffffc02025fc:	6442                	ld	s0,16(sp)
ffffffffc02025fe:	64a2                	ld	s1,8(sp)
ffffffffc0202600:	6902                	ld	s2,0(sp)
ffffffffc0202602:	6105                	addi	sp,sp,32
ffffffffc0202604:	8082                	ret
        intr_disable();
ffffffffc0202606:	b30fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
		bb->next = bigblocks;
ffffffffc020260a:	0000b797          	auipc	a5,0xb
ffffffffc020260e:	eb678793          	addi	a5,a5,-330 # ffffffffc020d4c0 <bigblocks>
ffffffffc0202612:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0202614:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0202616:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0202618:	b18fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
		return bb->pages;
ffffffffc020261c:	6480                	ld	s0,8(s1)
}
ffffffffc020261e:	60e2                	ld	ra,24(sp)
ffffffffc0202620:	64a2                	ld	s1,8(sp)
ffffffffc0202622:	8522                	mv	a0,s0
ffffffffc0202624:	6442                	ld	s0,16(sp)
ffffffffc0202626:	6902                	ld	s2,0(sp)
ffffffffc0202628:	6105                	addi	sp,sp,32
ffffffffc020262a:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc020262c:	45e1                	li	a1,24
ffffffffc020262e:	8526                	mv	a0,s1
ffffffffc0202630:	d29ff0ef          	jal	ra,ffffffffc0202358 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0202634:	b765                	j	ffffffffc02025dc <kmalloc+0x56>

ffffffffc0202636 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0202636:	c179                	beqz	a0,ffffffffc02026fc <kfree+0xc6>
{
ffffffffc0202638:	1101                	addi	sp,sp,-32
ffffffffc020263a:	e822                	sd	s0,16(sp)
ffffffffc020263c:	ec06                	sd	ra,24(sp)
ffffffffc020263e:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0202640:	03451793          	slli	a5,a0,0x34
ffffffffc0202644:	842a                	mv	s0,a0
ffffffffc0202646:	e7c1                	bnez	a5,ffffffffc02026ce <kfree+0x98>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202648:	100027f3          	csrr	a5,sstatus
ffffffffc020264c:	8b89                	andi	a5,a5,2
ffffffffc020264e:	ebc9                	bnez	a5,ffffffffc02026e0 <kfree+0xaa>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0202650:	0000b797          	auipc	a5,0xb
ffffffffc0202654:	e707b783          	ld	a5,-400(a5) # ffffffffc020d4c0 <bigblocks>
    return 0;
ffffffffc0202658:	4601                	li	a2,0
ffffffffc020265a:	cbb5                	beqz	a5,ffffffffc02026ce <kfree+0x98>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc020265c:	0000b697          	auipc	a3,0xb
ffffffffc0202660:	e6468693          	addi	a3,a3,-412 # ffffffffc020d4c0 <bigblocks>
ffffffffc0202664:	a021                	j	ffffffffc020266c <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0202666:	01048693          	addi	a3,s1,16
ffffffffc020266a:	c3ad                	beqz	a5,ffffffffc02026cc <kfree+0x96>
		{
			if (bb->pages == block)
ffffffffc020266c:	6798                	ld	a4,8(a5)
ffffffffc020266e:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0202670:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0202672:	fe871ae3          	bne	a4,s0,ffffffffc0202666 <kfree+0x30>
				*last = bb->next;
ffffffffc0202676:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0202678:	ee3d                	bnez	a2,ffffffffc02026f6 <kfree+0xc0>
    return pa2page(PADDR(kva));
ffffffffc020267a:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc020267e:	4098                	lw	a4,0(s1)
ffffffffc0202680:	08f46b63          	bltu	s0,a5,ffffffffc0202716 <kfree+0xe0>
ffffffffc0202684:	0000b697          	auipc	a3,0xb
ffffffffc0202688:	e346b683          	ld	a3,-460(a3) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc020268c:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc020268e:	8031                	srli	s0,s0,0xc
ffffffffc0202690:	0000b797          	auipc	a5,0xb
ffffffffc0202694:	e107b783          	ld	a5,-496(a5) # ffffffffc020d4a0 <npage>
ffffffffc0202698:	06f47363          	bgeu	s0,a5,ffffffffc02026fe <kfree+0xc8>
    return &pages[PPN(pa) - nbase];
ffffffffc020269c:	00003517          	auipc	a0,0x3
ffffffffc02026a0:	21c53503          	ld	a0,540(a0) # ffffffffc02058b8 <nbase>
ffffffffc02026a4:	8c09                	sub	s0,s0,a0
ffffffffc02026a6:	041a                	slli	s0,s0,0x6
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc02026a8:	0000b517          	auipc	a0,0xb
ffffffffc02026ac:	e0053503          	ld	a0,-512(a0) # ffffffffc020d4a8 <pages>
ffffffffc02026b0:	4585                	li	a1,1
ffffffffc02026b2:	9522                	add	a0,a0,s0
ffffffffc02026b4:	00e595bb          	sllw	a1,a1,a4
ffffffffc02026b8:	f70fe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc02026bc:	6442                	ld	s0,16(sp)
ffffffffc02026be:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc02026c0:	8526                	mv	a0,s1
}
ffffffffc02026c2:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc02026c4:	45e1                	li	a1,24
}
ffffffffc02026c6:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc02026c8:	c91ff06f          	j	ffffffffc0202358 <slob_free>
ffffffffc02026cc:	e215                	bnez	a2,ffffffffc02026f0 <kfree+0xba>
ffffffffc02026ce:	ff040513          	addi	a0,s0,-16
}
ffffffffc02026d2:	6442                	ld	s0,16(sp)
ffffffffc02026d4:	60e2                	ld	ra,24(sp)
ffffffffc02026d6:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc02026d8:	4581                	li	a1,0
}
ffffffffc02026da:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc02026dc:	c7dff06f          	j	ffffffffc0202358 <slob_free>
        intr_disable();
ffffffffc02026e0:	a56fe0ef          	jal	ra,ffffffffc0200936 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc02026e4:	0000b797          	auipc	a5,0xb
ffffffffc02026e8:	ddc7b783          	ld	a5,-548(a5) # ffffffffc020d4c0 <bigblocks>
        return 1;
ffffffffc02026ec:	4605                	li	a2,1
ffffffffc02026ee:	f7bd                	bnez	a5,ffffffffc020265c <kfree+0x26>
        intr_enable();
ffffffffc02026f0:	a40fe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02026f4:	bfe9                	j	ffffffffc02026ce <kfree+0x98>
ffffffffc02026f6:	a3afe0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02026fa:	b741                	j	ffffffffc020267a <kfree+0x44>
ffffffffc02026fc:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc02026fe:	00002617          	auipc	a2,0x2
ffffffffc0202702:	0e260613          	addi	a2,a2,226 # ffffffffc02047e0 <commands+0x6b8>
ffffffffc0202706:	06900593          	li	a1,105
ffffffffc020270a:	00002517          	auipc	a0,0x2
ffffffffc020270e:	0f650513          	addi	a0,a0,246 # ffffffffc0204800 <commands+0x6d8>
ffffffffc0202712:	acdfd0ef          	jal	ra,ffffffffc02001de <__panic>
    return pa2page(PADDR(kva));
ffffffffc0202716:	86a2                	mv	a3,s0
ffffffffc0202718:	00002617          	auipc	a2,0x2
ffffffffc020271c:	1d060613          	addi	a2,a2,464 # ffffffffc02048e8 <commands+0x7c0>
ffffffffc0202720:	07700593          	li	a1,119
ffffffffc0202724:	00002517          	auipc	a0,0x2
ffffffffc0202728:	0dc50513          	addi	a0,a0,220 # ffffffffc0204800 <commands+0x6d8>
ffffffffc020272c:	ab3fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202730 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc0202730:	00007797          	auipc	a5,0x7
ffffffffc0202734:	d0078793          	addi	a5,a5,-768 # ffffffffc0209430 <free_area>
ffffffffc0202738:	e79c                	sd	a5,8(a5)
ffffffffc020273a:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc020273c:	0007a823          	sw	zero,16(a5)
}
ffffffffc0202740:	8082                	ret

ffffffffc0202742 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0202742:	00007517          	auipc	a0,0x7
ffffffffc0202746:	cfe56503          	lwu	a0,-770(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc020274a:	8082                	ret

ffffffffc020274c <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc020274c:	715d                	addi	sp,sp,-80
ffffffffc020274e:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0202750:	00007417          	auipc	s0,0x7
ffffffffc0202754:	ce040413          	addi	s0,s0,-800 # ffffffffc0209430 <free_area>
ffffffffc0202758:	641c                	ld	a5,8(s0)
ffffffffc020275a:	e486                	sd	ra,72(sp)
ffffffffc020275c:	fc26                	sd	s1,56(sp)
ffffffffc020275e:	f84a                	sd	s2,48(sp)
ffffffffc0202760:	f44e                	sd	s3,40(sp)
ffffffffc0202762:	f052                	sd	s4,32(sp)
ffffffffc0202764:	ec56                	sd	s5,24(sp)
ffffffffc0202766:	e85a                	sd	s6,16(sp)
ffffffffc0202768:	e45e                	sd	s7,8(sp)
ffffffffc020276a:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020276c:	2a878d63          	beq	a5,s0,ffffffffc0202a26 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0202770:	4481                	li	s1,0
ffffffffc0202772:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202774:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0202778:	8b09                	andi	a4,a4,2
ffffffffc020277a:	2a070a63          	beqz	a4,ffffffffc0202a2e <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc020277e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202782:	679c                	ld	a5,8(a5)
ffffffffc0202784:	2905                	addiw	s2,s2,1
ffffffffc0202786:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202788:	fe8796e3          	bne	a5,s0,ffffffffc0202774 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020278c:	89a6                	mv	s3,s1
ffffffffc020278e:	ed8fe0ef          	jal	ra,ffffffffc0200e66 <nr_free_pages>
ffffffffc0202792:	6f351e63          	bne	a0,s3,ffffffffc0202e8e <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202796:	4505                	li	a0,1
ffffffffc0202798:	e52fe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc020279c:	8aaa                	mv	s5,a0
ffffffffc020279e:	42050863          	beqz	a0,ffffffffc0202bce <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02027a2:	4505                	li	a0,1
ffffffffc02027a4:	e46fe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc02027a8:	89aa                	mv	s3,a0
ffffffffc02027aa:	70050263          	beqz	a0,ffffffffc0202eae <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02027ae:	4505                	li	a0,1
ffffffffc02027b0:	e3afe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc02027b4:	8a2a                	mv	s4,a0
ffffffffc02027b6:	48050c63          	beqz	a0,ffffffffc0202c4e <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02027ba:	293a8a63          	beq	s5,s3,ffffffffc0202a4e <default_check+0x302>
ffffffffc02027be:	28aa8863          	beq	s5,a0,ffffffffc0202a4e <default_check+0x302>
ffffffffc02027c2:	28a98663          	beq	s3,a0,ffffffffc0202a4e <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02027c6:	000aa783          	lw	a5,0(s5)
ffffffffc02027ca:	2a079263          	bnez	a5,ffffffffc0202a6e <default_check+0x322>
ffffffffc02027ce:	0009a783          	lw	a5,0(s3)
ffffffffc02027d2:	28079e63          	bnez	a5,ffffffffc0202a6e <default_check+0x322>
ffffffffc02027d6:	411c                	lw	a5,0(a0)
ffffffffc02027d8:	28079b63          	bnez	a5,ffffffffc0202a6e <default_check+0x322>
    return page - pages + nbase;
ffffffffc02027dc:	0000b797          	auipc	a5,0xb
ffffffffc02027e0:	ccc7b783          	ld	a5,-820(a5) # ffffffffc020d4a8 <pages>
ffffffffc02027e4:	40fa8733          	sub	a4,s5,a5
ffffffffc02027e8:	00003617          	auipc	a2,0x3
ffffffffc02027ec:	0d063603          	ld	a2,208(a2) # ffffffffc02058b8 <nbase>
ffffffffc02027f0:	8719                	srai	a4,a4,0x6
ffffffffc02027f2:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02027f4:	0000b697          	auipc	a3,0xb
ffffffffc02027f8:	cac6b683          	ld	a3,-852(a3) # ffffffffc020d4a0 <npage>
ffffffffc02027fc:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02027fe:	0732                	slli	a4,a4,0xc
ffffffffc0202800:	28d77763          	bgeu	a4,a3,ffffffffc0202a8e <default_check+0x342>
    return page - pages + nbase;
ffffffffc0202804:	40f98733          	sub	a4,s3,a5
ffffffffc0202808:	8719                	srai	a4,a4,0x6
ffffffffc020280a:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020280c:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020280e:	4cd77063          	bgeu	a4,a3,ffffffffc0202cce <default_check+0x582>
    return page - pages + nbase;
ffffffffc0202812:	40f507b3          	sub	a5,a0,a5
ffffffffc0202816:	8799                	srai	a5,a5,0x6
ffffffffc0202818:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020281a:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020281c:	30d7f963          	bgeu	a5,a3,ffffffffc0202b2e <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0202820:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0202822:	00043c03          	ld	s8,0(s0)
ffffffffc0202826:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc020282a:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020282e:	e400                	sd	s0,8(s0)
ffffffffc0202830:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0202832:	00007797          	auipc	a5,0x7
ffffffffc0202836:	c007a723          	sw	zero,-1010(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc020283a:	db0fe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc020283e:	2c051863          	bnez	a0,ffffffffc0202b0e <default_check+0x3c2>
    free_page(p0);
ffffffffc0202842:	4585                	li	a1,1
ffffffffc0202844:	8556                	mv	a0,s5
ffffffffc0202846:	de2fe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
    free_page(p1);
ffffffffc020284a:	4585                	li	a1,1
ffffffffc020284c:	854e                	mv	a0,s3
ffffffffc020284e:	ddafe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
    free_page(p2);
ffffffffc0202852:	4585                	li	a1,1
ffffffffc0202854:	8552                	mv	a0,s4
ffffffffc0202856:	dd2fe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
    assert(nr_free == 3);
ffffffffc020285a:	4818                	lw	a4,16(s0)
ffffffffc020285c:	478d                	li	a5,3
ffffffffc020285e:	28f71863          	bne	a4,a5,ffffffffc0202aee <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202862:	4505                	li	a0,1
ffffffffc0202864:	d86fe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc0202868:	89aa                	mv	s3,a0
ffffffffc020286a:	26050263          	beqz	a0,ffffffffc0202ace <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020286e:	4505                	li	a0,1
ffffffffc0202870:	d7afe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc0202874:	8aaa                	mv	s5,a0
ffffffffc0202876:	3a050c63          	beqz	a0,ffffffffc0202c2e <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020287a:	4505                	li	a0,1
ffffffffc020287c:	d6efe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc0202880:	8a2a                	mv	s4,a0
ffffffffc0202882:	38050663          	beqz	a0,ffffffffc0202c0e <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0202886:	4505                	li	a0,1
ffffffffc0202888:	d62fe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc020288c:	36051163          	bnez	a0,ffffffffc0202bee <default_check+0x4a2>
    free_page(p0);
ffffffffc0202890:	4585                	li	a1,1
ffffffffc0202892:	854e                	mv	a0,s3
ffffffffc0202894:	d94fe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0202898:	641c                	ld	a5,8(s0)
ffffffffc020289a:	20878a63          	beq	a5,s0,ffffffffc0202aae <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc020289e:	4505                	li	a0,1
ffffffffc02028a0:	d4afe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc02028a4:	30a99563          	bne	s3,a0,ffffffffc0202bae <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc02028a8:	4505                	li	a0,1
ffffffffc02028aa:	d40fe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc02028ae:	2e051063          	bnez	a0,ffffffffc0202b8e <default_check+0x442>
    assert(nr_free == 0);
ffffffffc02028b2:	481c                	lw	a5,16(s0)
ffffffffc02028b4:	2a079d63          	bnez	a5,ffffffffc0202b6e <default_check+0x422>
    free_page(p);
ffffffffc02028b8:	854e                	mv	a0,s3
ffffffffc02028ba:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02028bc:	01843023          	sd	s8,0(s0)
ffffffffc02028c0:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02028c4:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02028c8:	d60fe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
    free_page(p1);
ffffffffc02028cc:	4585                	li	a1,1
ffffffffc02028ce:	8556                	mv	a0,s5
ffffffffc02028d0:	d58fe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
    free_page(p2);
ffffffffc02028d4:	4585                	li	a1,1
ffffffffc02028d6:	8552                	mv	a0,s4
ffffffffc02028d8:	d50fe0ef          	jal	ra,ffffffffc0200e28 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02028dc:	4515                	li	a0,5
ffffffffc02028de:	d0cfe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc02028e2:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02028e4:	26050563          	beqz	a0,ffffffffc0202b4e <default_check+0x402>
ffffffffc02028e8:	651c                	ld	a5,8(a0)
ffffffffc02028ea:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc02028ec:	8b85                	andi	a5,a5,1
ffffffffc02028ee:	54079063          	bnez	a5,ffffffffc0202e2e <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02028f2:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02028f4:	00043b03          	ld	s6,0(s0)
ffffffffc02028f8:	00843a83          	ld	s5,8(s0)
ffffffffc02028fc:	e000                	sd	s0,0(s0)
ffffffffc02028fe:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0202900:	ceafe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc0202904:	50051563          	bnez	a0,ffffffffc0202e0e <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0202908:	08098a13          	addi	s4,s3,128
ffffffffc020290c:	8552                	mv	a0,s4
ffffffffc020290e:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0202910:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0202914:	00007797          	auipc	a5,0x7
ffffffffc0202918:	b207a623          	sw	zero,-1236(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020291c:	d0cfe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0202920:	4511                	li	a0,4
ffffffffc0202922:	cc8fe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc0202926:	4c051463          	bnez	a0,ffffffffc0202dee <default_check+0x6a2>
ffffffffc020292a:	0889b783          	ld	a5,136(s3)
ffffffffc020292e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202930:	8b85                	andi	a5,a5,1
ffffffffc0202932:	48078e63          	beqz	a5,ffffffffc0202dce <default_check+0x682>
ffffffffc0202936:	0909a703          	lw	a4,144(s3)
ffffffffc020293a:	478d                	li	a5,3
ffffffffc020293c:	48f71963          	bne	a4,a5,ffffffffc0202dce <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202940:	450d                	li	a0,3
ffffffffc0202942:	ca8fe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc0202946:	8c2a                	mv	s8,a0
ffffffffc0202948:	46050363          	beqz	a0,ffffffffc0202dae <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020294c:	4505                	li	a0,1
ffffffffc020294e:	c9cfe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc0202952:	42051e63          	bnez	a0,ffffffffc0202d8e <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0202956:	418a1c63          	bne	s4,s8,ffffffffc0202d6e <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc020295a:	4585                	li	a1,1
ffffffffc020295c:	854e                	mv	a0,s3
ffffffffc020295e:	ccafe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
    free_pages(p1, 3);
ffffffffc0202962:	458d                	li	a1,3
ffffffffc0202964:	8552                	mv	a0,s4
ffffffffc0202966:	cc2fe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
ffffffffc020296a:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc020296e:	04098c13          	addi	s8,s3,64
ffffffffc0202972:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202974:	8b85                	andi	a5,a5,1
ffffffffc0202976:	3c078c63          	beqz	a5,ffffffffc0202d4e <default_check+0x602>
ffffffffc020297a:	0109a703          	lw	a4,16(s3)
ffffffffc020297e:	4785                	li	a5,1
ffffffffc0202980:	3cf71763          	bne	a4,a5,ffffffffc0202d4e <default_check+0x602>
ffffffffc0202984:	008a3783          	ld	a5,8(s4)
ffffffffc0202988:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020298a:	8b85                	andi	a5,a5,1
ffffffffc020298c:	3a078163          	beqz	a5,ffffffffc0202d2e <default_check+0x5e2>
ffffffffc0202990:	010a2703          	lw	a4,16(s4)
ffffffffc0202994:	478d                	li	a5,3
ffffffffc0202996:	38f71c63          	bne	a4,a5,ffffffffc0202d2e <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020299a:	4505                	li	a0,1
ffffffffc020299c:	c4efe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc02029a0:	36a99763          	bne	s3,a0,ffffffffc0202d0e <default_check+0x5c2>
    free_page(p0);
ffffffffc02029a4:	4585                	li	a1,1
ffffffffc02029a6:	c82fe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02029aa:	4509                	li	a0,2
ffffffffc02029ac:	c3efe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc02029b0:	32aa1f63          	bne	s4,a0,ffffffffc0202cee <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02029b4:	4589                	li	a1,2
ffffffffc02029b6:	c72fe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
    free_page(p2);
ffffffffc02029ba:	4585                	li	a1,1
ffffffffc02029bc:	8562                	mv	a0,s8
ffffffffc02029be:	c6afe0ef          	jal	ra,ffffffffc0200e28 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02029c2:	4515                	li	a0,5
ffffffffc02029c4:	c26fe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc02029c8:	89aa                	mv	s3,a0
ffffffffc02029ca:	48050263          	beqz	a0,ffffffffc0202e4e <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02029ce:	4505                	li	a0,1
ffffffffc02029d0:	c1afe0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
ffffffffc02029d4:	2c051d63          	bnez	a0,ffffffffc0202cae <default_check+0x562>

    assert(nr_free == 0);
ffffffffc02029d8:	481c                	lw	a5,16(s0)
ffffffffc02029da:	2a079a63          	bnez	a5,ffffffffc0202c8e <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02029de:	4595                	li	a1,5
ffffffffc02029e0:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02029e2:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02029e6:	01643023          	sd	s6,0(s0)
ffffffffc02029ea:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02029ee:	c3afe0ef          	jal	ra,ffffffffc0200e28 <free_pages>
    return listelm->next;
ffffffffc02029f2:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02029f4:	00878963          	beq	a5,s0,ffffffffc0202a06 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02029f8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02029fc:	679c                	ld	a5,8(a5)
ffffffffc02029fe:	397d                	addiw	s2,s2,-1
ffffffffc0202a00:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202a02:	fe879be3          	bne	a5,s0,ffffffffc02029f8 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0202a06:	26091463          	bnez	s2,ffffffffc0202c6e <default_check+0x522>
    assert(total == 0);
ffffffffc0202a0a:	46049263          	bnez	s1,ffffffffc0202e6e <default_check+0x722>
}
ffffffffc0202a0e:	60a6                	ld	ra,72(sp)
ffffffffc0202a10:	6406                	ld	s0,64(sp)
ffffffffc0202a12:	74e2                	ld	s1,56(sp)
ffffffffc0202a14:	7942                	ld	s2,48(sp)
ffffffffc0202a16:	79a2                	ld	s3,40(sp)
ffffffffc0202a18:	7a02                	ld	s4,32(sp)
ffffffffc0202a1a:	6ae2                	ld	s5,24(sp)
ffffffffc0202a1c:	6b42                	ld	s6,16(sp)
ffffffffc0202a1e:	6ba2                	ld	s7,8(sp)
ffffffffc0202a20:	6c02                	ld	s8,0(sp)
ffffffffc0202a22:	6161                	addi	sp,sp,80
ffffffffc0202a24:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202a26:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0202a28:	4481                	li	s1,0
ffffffffc0202a2a:	4901                	li	s2,0
ffffffffc0202a2c:	b38d                	j	ffffffffc020278e <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0202a2e:	00002697          	auipc	a3,0x2
ffffffffc0202a32:	6b268693          	addi	a3,a3,1714 # ffffffffc02050e0 <commands+0xfb8>
ffffffffc0202a36:	00002617          	auipc	a2,0x2
ffffffffc0202a3a:	f3260613          	addi	a2,a2,-206 # ffffffffc0204968 <commands+0x840>
ffffffffc0202a3e:	0f000593          	li	a1,240
ffffffffc0202a42:	00002517          	auipc	a0,0x2
ffffffffc0202a46:	6ae50513          	addi	a0,a0,1710 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202a4a:	f94fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0202a4e:	00002697          	auipc	a3,0x2
ffffffffc0202a52:	73a68693          	addi	a3,a3,1850 # ffffffffc0205188 <commands+0x1060>
ffffffffc0202a56:	00002617          	auipc	a2,0x2
ffffffffc0202a5a:	f1260613          	addi	a2,a2,-238 # ffffffffc0204968 <commands+0x840>
ffffffffc0202a5e:	0bd00593          	li	a1,189
ffffffffc0202a62:	00002517          	auipc	a0,0x2
ffffffffc0202a66:	68e50513          	addi	a0,a0,1678 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202a6a:	f74fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0202a6e:	00002697          	auipc	a3,0x2
ffffffffc0202a72:	74268693          	addi	a3,a3,1858 # ffffffffc02051b0 <commands+0x1088>
ffffffffc0202a76:	00002617          	auipc	a2,0x2
ffffffffc0202a7a:	ef260613          	addi	a2,a2,-270 # ffffffffc0204968 <commands+0x840>
ffffffffc0202a7e:	0be00593          	li	a1,190
ffffffffc0202a82:	00002517          	auipc	a0,0x2
ffffffffc0202a86:	66e50513          	addi	a0,a0,1646 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202a8a:	f54fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0202a8e:	00002697          	auipc	a3,0x2
ffffffffc0202a92:	76268693          	addi	a3,a3,1890 # ffffffffc02051f0 <commands+0x10c8>
ffffffffc0202a96:	00002617          	auipc	a2,0x2
ffffffffc0202a9a:	ed260613          	addi	a2,a2,-302 # ffffffffc0204968 <commands+0x840>
ffffffffc0202a9e:	0c000593          	li	a1,192
ffffffffc0202aa2:	00002517          	auipc	a0,0x2
ffffffffc0202aa6:	64e50513          	addi	a0,a0,1614 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202aaa:	f34fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(!list_empty(&free_list));
ffffffffc0202aae:	00002697          	auipc	a3,0x2
ffffffffc0202ab2:	7ca68693          	addi	a3,a3,1994 # ffffffffc0205278 <commands+0x1150>
ffffffffc0202ab6:	00002617          	auipc	a2,0x2
ffffffffc0202aba:	eb260613          	addi	a2,a2,-334 # ffffffffc0204968 <commands+0x840>
ffffffffc0202abe:	0d900593          	li	a1,217
ffffffffc0202ac2:	00002517          	auipc	a0,0x2
ffffffffc0202ac6:	62e50513          	addi	a0,a0,1582 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202aca:	f14fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202ace:	00002697          	auipc	a3,0x2
ffffffffc0202ad2:	65a68693          	addi	a3,a3,1626 # ffffffffc0205128 <commands+0x1000>
ffffffffc0202ad6:	00002617          	auipc	a2,0x2
ffffffffc0202ada:	e9260613          	addi	a2,a2,-366 # ffffffffc0204968 <commands+0x840>
ffffffffc0202ade:	0d200593          	li	a1,210
ffffffffc0202ae2:	00002517          	auipc	a0,0x2
ffffffffc0202ae6:	60e50513          	addi	a0,a0,1550 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202aea:	ef4fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free == 3);
ffffffffc0202aee:	00002697          	auipc	a3,0x2
ffffffffc0202af2:	77a68693          	addi	a3,a3,1914 # ffffffffc0205268 <commands+0x1140>
ffffffffc0202af6:	00002617          	auipc	a2,0x2
ffffffffc0202afa:	e7260613          	addi	a2,a2,-398 # ffffffffc0204968 <commands+0x840>
ffffffffc0202afe:	0d000593          	li	a1,208
ffffffffc0202b02:	00002517          	auipc	a0,0x2
ffffffffc0202b06:	5ee50513          	addi	a0,a0,1518 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202b0a:	ed4fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202b0e:	00002697          	auipc	a3,0x2
ffffffffc0202b12:	74268693          	addi	a3,a3,1858 # ffffffffc0205250 <commands+0x1128>
ffffffffc0202b16:	00002617          	auipc	a2,0x2
ffffffffc0202b1a:	e5260613          	addi	a2,a2,-430 # ffffffffc0204968 <commands+0x840>
ffffffffc0202b1e:	0cb00593          	li	a1,203
ffffffffc0202b22:	00002517          	auipc	a0,0x2
ffffffffc0202b26:	5ce50513          	addi	a0,a0,1486 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202b2a:	eb4fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0202b2e:	00002697          	auipc	a3,0x2
ffffffffc0202b32:	70268693          	addi	a3,a3,1794 # ffffffffc0205230 <commands+0x1108>
ffffffffc0202b36:	00002617          	auipc	a2,0x2
ffffffffc0202b3a:	e3260613          	addi	a2,a2,-462 # ffffffffc0204968 <commands+0x840>
ffffffffc0202b3e:	0c200593          	li	a1,194
ffffffffc0202b42:	00002517          	auipc	a0,0x2
ffffffffc0202b46:	5ae50513          	addi	a0,a0,1454 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202b4a:	e94fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(p0 != NULL);
ffffffffc0202b4e:	00002697          	auipc	a3,0x2
ffffffffc0202b52:	77268693          	addi	a3,a3,1906 # ffffffffc02052c0 <commands+0x1198>
ffffffffc0202b56:	00002617          	auipc	a2,0x2
ffffffffc0202b5a:	e1260613          	addi	a2,a2,-494 # ffffffffc0204968 <commands+0x840>
ffffffffc0202b5e:	0f800593          	li	a1,248
ffffffffc0202b62:	00002517          	auipc	a0,0x2
ffffffffc0202b66:	58e50513          	addi	a0,a0,1422 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202b6a:	e74fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free == 0);
ffffffffc0202b6e:	00002697          	auipc	a3,0x2
ffffffffc0202b72:	74268693          	addi	a3,a3,1858 # ffffffffc02052b0 <commands+0x1188>
ffffffffc0202b76:	00002617          	auipc	a2,0x2
ffffffffc0202b7a:	df260613          	addi	a2,a2,-526 # ffffffffc0204968 <commands+0x840>
ffffffffc0202b7e:	0df00593          	li	a1,223
ffffffffc0202b82:	00002517          	auipc	a0,0x2
ffffffffc0202b86:	56e50513          	addi	a0,a0,1390 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202b8a:	e54fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202b8e:	00002697          	auipc	a3,0x2
ffffffffc0202b92:	6c268693          	addi	a3,a3,1730 # ffffffffc0205250 <commands+0x1128>
ffffffffc0202b96:	00002617          	auipc	a2,0x2
ffffffffc0202b9a:	dd260613          	addi	a2,a2,-558 # ffffffffc0204968 <commands+0x840>
ffffffffc0202b9e:	0dd00593          	li	a1,221
ffffffffc0202ba2:	00002517          	auipc	a0,0x2
ffffffffc0202ba6:	54e50513          	addi	a0,a0,1358 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202baa:	e34fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0202bae:	00002697          	auipc	a3,0x2
ffffffffc0202bb2:	6e268693          	addi	a3,a3,1762 # ffffffffc0205290 <commands+0x1168>
ffffffffc0202bb6:	00002617          	auipc	a2,0x2
ffffffffc0202bba:	db260613          	addi	a2,a2,-590 # ffffffffc0204968 <commands+0x840>
ffffffffc0202bbe:	0dc00593          	li	a1,220
ffffffffc0202bc2:	00002517          	auipc	a0,0x2
ffffffffc0202bc6:	52e50513          	addi	a0,a0,1326 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202bca:	e14fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202bce:	00002697          	auipc	a3,0x2
ffffffffc0202bd2:	55a68693          	addi	a3,a3,1370 # ffffffffc0205128 <commands+0x1000>
ffffffffc0202bd6:	00002617          	auipc	a2,0x2
ffffffffc0202bda:	d9260613          	addi	a2,a2,-622 # ffffffffc0204968 <commands+0x840>
ffffffffc0202bde:	0b900593          	li	a1,185
ffffffffc0202be2:	00002517          	auipc	a0,0x2
ffffffffc0202be6:	50e50513          	addi	a0,a0,1294 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202bea:	df4fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202bee:	00002697          	auipc	a3,0x2
ffffffffc0202bf2:	66268693          	addi	a3,a3,1634 # ffffffffc0205250 <commands+0x1128>
ffffffffc0202bf6:	00002617          	auipc	a2,0x2
ffffffffc0202bfa:	d7260613          	addi	a2,a2,-654 # ffffffffc0204968 <commands+0x840>
ffffffffc0202bfe:	0d600593          	li	a1,214
ffffffffc0202c02:	00002517          	auipc	a0,0x2
ffffffffc0202c06:	4ee50513          	addi	a0,a0,1262 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202c0a:	dd4fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202c0e:	00002697          	auipc	a3,0x2
ffffffffc0202c12:	55a68693          	addi	a3,a3,1370 # ffffffffc0205168 <commands+0x1040>
ffffffffc0202c16:	00002617          	auipc	a2,0x2
ffffffffc0202c1a:	d5260613          	addi	a2,a2,-686 # ffffffffc0204968 <commands+0x840>
ffffffffc0202c1e:	0d400593          	li	a1,212
ffffffffc0202c22:	00002517          	auipc	a0,0x2
ffffffffc0202c26:	4ce50513          	addi	a0,a0,1230 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202c2a:	db4fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202c2e:	00002697          	auipc	a3,0x2
ffffffffc0202c32:	51a68693          	addi	a3,a3,1306 # ffffffffc0205148 <commands+0x1020>
ffffffffc0202c36:	00002617          	auipc	a2,0x2
ffffffffc0202c3a:	d3260613          	addi	a2,a2,-718 # ffffffffc0204968 <commands+0x840>
ffffffffc0202c3e:	0d300593          	li	a1,211
ffffffffc0202c42:	00002517          	auipc	a0,0x2
ffffffffc0202c46:	4ae50513          	addi	a0,a0,1198 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202c4a:	d94fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202c4e:	00002697          	auipc	a3,0x2
ffffffffc0202c52:	51a68693          	addi	a3,a3,1306 # ffffffffc0205168 <commands+0x1040>
ffffffffc0202c56:	00002617          	auipc	a2,0x2
ffffffffc0202c5a:	d1260613          	addi	a2,a2,-750 # ffffffffc0204968 <commands+0x840>
ffffffffc0202c5e:	0bb00593          	li	a1,187
ffffffffc0202c62:	00002517          	auipc	a0,0x2
ffffffffc0202c66:	48e50513          	addi	a0,a0,1166 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202c6a:	d74fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(count == 0);
ffffffffc0202c6e:	00002697          	auipc	a3,0x2
ffffffffc0202c72:	7a268693          	addi	a3,a3,1954 # ffffffffc0205410 <commands+0x12e8>
ffffffffc0202c76:	00002617          	auipc	a2,0x2
ffffffffc0202c7a:	cf260613          	addi	a2,a2,-782 # ffffffffc0204968 <commands+0x840>
ffffffffc0202c7e:	12500593          	li	a1,293
ffffffffc0202c82:	00002517          	auipc	a0,0x2
ffffffffc0202c86:	46e50513          	addi	a0,a0,1134 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202c8a:	d54fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(nr_free == 0);
ffffffffc0202c8e:	00002697          	auipc	a3,0x2
ffffffffc0202c92:	62268693          	addi	a3,a3,1570 # ffffffffc02052b0 <commands+0x1188>
ffffffffc0202c96:	00002617          	auipc	a2,0x2
ffffffffc0202c9a:	cd260613          	addi	a2,a2,-814 # ffffffffc0204968 <commands+0x840>
ffffffffc0202c9e:	11a00593          	li	a1,282
ffffffffc0202ca2:	00002517          	auipc	a0,0x2
ffffffffc0202ca6:	44e50513          	addi	a0,a0,1102 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202caa:	d34fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202cae:	00002697          	auipc	a3,0x2
ffffffffc0202cb2:	5a268693          	addi	a3,a3,1442 # ffffffffc0205250 <commands+0x1128>
ffffffffc0202cb6:	00002617          	auipc	a2,0x2
ffffffffc0202cba:	cb260613          	addi	a2,a2,-846 # ffffffffc0204968 <commands+0x840>
ffffffffc0202cbe:	11800593          	li	a1,280
ffffffffc0202cc2:	00002517          	auipc	a0,0x2
ffffffffc0202cc6:	42e50513          	addi	a0,a0,1070 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202cca:	d14fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202cce:	00002697          	auipc	a3,0x2
ffffffffc0202cd2:	54268693          	addi	a3,a3,1346 # ffffffffc0205210 <commands+0x10e8>
ffffffffc0202cd6:	00002617          	auipc	a2,0x2
ffffffffc0202cda:	c9260613          	addi	a2,a2,-878 # ffffffffc0204968 <commands+0x840>
ffffffffc0202cde:	0c100593          	li	a1,193
ffffffffc0202ce2:	00002517          	auipc	a0,0x2
ffffffffc0202ce6:	40e50513          	addi	a0,a0,1038 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202cea:	cf4fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202cee:	00002697          	auipc	a3,0x2
ffffffffc0202cf2:	6e268693          	addi	a3,a3,1762 # ffffffffc02053d0 <commands+0x12a8>
ffffffffc0202cf6:	00002617          	auipc	a2,0x2
ffffffffc0202cfa:	c7260613          	addi	a2,a2,-910 # ffffffffc0204968 <commands+0x840>
ffffffffc0202cfe:	11200593          	li	a1,274
ffffffffc0202d02:	00002517          	auipc	a0,0x2
ffffffffc0202d06:	3ee50513          	addi	a0,a0,1006 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202d0a:	cd4fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202d0e:	00002697          	auipc	a3,0x2
ffffffffc0202d12:	6a268693          	addi	a3,a3,1698 # ffffffffc02053b0 <commands+0x1288>
ffffffffc0202d16:	00002617          	auipc	a2,0x2
ffffffffc0202d1a:	c5260613          	addi	a2,a2,-942 # ffffffffc0204968 <commands+0x840>
ffffffffc0202d1e:	11000593          	li	a1,272
ffffffffc0202d22:	00002517          	auipc	a0,0x2
ffffffffc0202d26:	3ce50513          	addi	a0,a0,974 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202d2a:	cb4fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0202d2e:	00002697          	auipc	a3,0x2
ffffffffc0202d32:	65a68693          	addi	a3,a3,1626 # ffffffffc0205388 <commands+0x1260>
ffffffffc0202d36:	00002617          	auipc	a2,0x2
ffffffffc0202d3a:	c3260613          	addi	a2,a2,-974 # ffffffffc0204968 <commands+0x840>
ffffffffc0202d3e:	10e00593          	li	a1,270
ffffffffc0202d42:	00002517          	auipc	a0,0x2
ffffffffc0202d46:	3ae50513          	addi	a0,a0,942 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202d4a:	c94fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202d4e:	00002697          	auipc	a3,0x2
ffffffffc0202d52:	61268693          	addi	a3,a3,1554 # ffffffffc0205360 <commands+0x1238>
ffffffffc0202d56:	00002617          	auipc	a2,0x2
ffffffffc0202d5a:	c1260613          	addi	a2,a2,-1006 # ffffffffc0204968 <commands+0x840>
ffffffffc0202d5e:	10d00593          	li	a1,269
ffffffffc0202d62:	00002517          	auipc	a0,0x2
ffffffffc0202d66:	38e50513          	addi	a0,a0,910 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202d6a:	c74fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(p0 + 2 == p1);
ffffffffc0202d6e:	00002697          	auipc	a3,0x2
ffffffffc0202d72:	5e268693          	addi	a3,a3,1506 # ffffffffc0205350 <commands+0x1228>
ffffffffc0202d76:	00002617          	auipc	a2,0x2
ffffffffc0202d7a:	bf260613          	addi	a2,a2,-1038 # ffffffffc0204968 <commands+0x840>
ffffffffc0202d7e:	10800593          	li	a1,264
ffffffffc0202d82:	00002517          	auipc	a0,0x2
ffffffffc0202d86:	36e50513          	addi	a0,a0,878 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202d8a:	c54fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202d8e:	00002697          	auipc	a3,0x2
ffffffffc0202d92:	4c268693          	addi	a3,a3,1218 # ffffffffc0205250 <commands+0x1128>
ffffffffc0202d96:	00002617          	auipc	a2,0x2
ffffffffc0202d9a:	bd260613          	addi	a2,a2,-1070 # ffffffffc0204968 <commands+0x840>
ffffffffc0202d9e:	10700593          	li	a1,263
ffffffffc0202da2:	00002517          	auipc	a0,0x2
ffffffffc0202da6:	34e50513          	addi	a0,a0,846 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202daa:	c34fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202dae:	00002697          	auipc	a3,0x2
ffffffffc0202db2:	58268693          	addi	a3,a3,1410 # ffffffffc0205330 <commands+0x1208>
ffffffffc0202db6:	00002617          	auipc	a2,0x2
ffffffffc0202dba:	bb260613          	addi	a2,a2,-1102 # ffffffffc0204968 <commands+0x840>
ffffffffc0202dbe:	10600593          	li	a1,262
ffffffffc0202dc2:	00002517          	auipc	a0,0x2
ffffffffc0202dc6:	32e50513          	addi	a0,a0,814 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202dca:	c14fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202dce:	00002697          	auipc	a3,0x2
ffffffffc0202dd2:	53268693          	addi	a3,a3,1330 # ffffffffc0205300 <commands+0x11d8>
ffffffffc0202dd6:	00002617          	auipc	a2,0x2
ffffffffc0202dda:	b9260613          	addi	a2,a2,-1134 # ffffffffc0204968 <commands+0x840>
ffffffffc0202dde:	10500593          	li	a1,261
ffffffffc0202de2:	00002517          	auipc	a0,0x2
ffffffffc0202de6:	30e50513          	addi	a0,a0,782 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202dea:	bf4fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0202dee:	00002697          	auipc	a3,0x2
ffffffffc0202df2:	4fa68693          	addi	a3,a3,1274 # ffffffffc02052e8 <commands+0x11c0>
ffffffffc0202df6:	00002617          	auipc	a2,0x2
ffffffffc0202dfa:	b7260613          	addi	a2,a2,-1166 # ffffffffc0204968 <commands+0x840>
ffffffffc0202dfe:	10400593          	li	a1,260
ffffffffc0202e02:	00002517          	auipc	a0,0x2
ffffffffc0202e06:	2ee50513          	addi	a0,a0,750 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202e0a:	bd4fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202e0e:	00002697          	auipc	a3,0x2
ffffffffc0202e12:	44268693          	addi	a3,a3,1090 # ffffffffc0205250 <commands+0x1128>
ffffffffc0202e16:	00002617          	auipc	a2,0x2
ffffffffc0202e1a:	b5260613          	addi	a2,a2,-1198 # ffffffffc0204968 <commands+0x840>
ffffffffc0202e1e:	0fe00593          	li	a1,254
ffffffffc0202e22:	00002517          	auipc	a0,0x2
ffffffffc0202e26:	2ce50513          	addi	a0,a0,718 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202e2a:	bb4fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(!PageProperty(p0));
ffffffffc0202e2e:	00002697          	auipc	a3,0x2
ffffffffc0202e32:	4a268693          	addi	a3,a3,1186 # ffffffffc02052d0 <commands+0x11a8>
ffffffffc0202e36:	00002617          	auipc	a2,0x2
ffffffffc0202e3a:	b3260613          	addi	a2,a2,-1230 # ffffffffc0204968 <commands+0x840>
ffffffffc0202e3e:	0f900593          	li	a1,249
ffffffffc0202e42:	00002517          	auipc	a0,0x2
ffffffffc0202e46:	2ae50513          	addi	a0,a0,686 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202e4a:	b94fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202e4e:	00002697          	auipc	a3,0x2
ffffffffc0202e52:	5a268693          	addi	a3,a3,1442 # ffffffffc02053f0 <commands+0x12c8>
ffffffffc0202e56:	00002617          	auipc	a2,0x2
ffffffffc0202e5a:	b1260613          	addi	a2,a2,-1262 # ffffffffc0204968 <commands+0x840>
ffffffffc0202e5e:	11700593          	li	a1,279
ffffffffc0202e62:	00002517          	auipc	a0,0x2
ffffffffc0202e66:	28e50513          	addi	a0,a0,654 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202e6a:	b74fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(total == 0);
ffffffffc0202e6e:	00002697          	auipc	a3,0x2
ffffffffc0202e72:	5b268693          	addi	a3,a3,1458 # ffffffffc0205420 <commands+0x12f8>
ffffffffc0202e76:	00002617          	auipc	a2,0x2
ffffffffc0202e7a:	af260613          	addi	a2,a2,-1294 # ffffffffc0204968 <commands+0x840>
ffffffffc0202e7e:	12600593          	li	a1,294
ffffffffc0202e82:	00002517          	auipc	a0,0x2
ffffffffc0202e86:	26e50513          	addi	a0,a0,622 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202e8a:	b54fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(total == nr_free_pages());
ffffffffc0202e8e:	00002697          	auipc	a3,0x2
ffffffffc0202e92:	27a68693          	addi	a3,a3,634 # ffffffffc0205108 <commands+0xfe0>
ffffffffc0202e96:	00002617          	auipc	a2,0x2
ffffffffc0202e9a:	ad260613          	addi	a2,a2,-1326 # ffffffffc0204968 <commands+0x840>
ffffffffc0202e9e:	0f300593          	li	a1,243
ffffffffc0202ea2:	00002517          	auipc	a0,0x2
ffffffffc0202ea6:	24e50513          	addi	a0,a0,590 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202eaa:	b34fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202eae:	00002697          	auipc	a3,0x2
ffffffffc0202eb2:	29a68693          	addi	a3,a3,666 # ffffffffc0205148 <commands+0x1020>
ffffffffc0202eb6:	00002617          	auipc	a2,0x2
ffffffffc0202eba:	ab260613          	addi	a2,a2,-1358 # ffffffffc0204968 <commands+0x840>
ffffffffc0202ebe:	0ba00593          	li	a1,186
ffffffffc0202ec2:	00002517          	auipc	a0,0x2
ffffffffc0202ec6:	22e50513          	addi	a0,a0,558 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0202eca:	b14fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0202ece <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0202ece:	1141                	addi	sp,sp,-16
ffffffffc0202ed0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202ed2:	14058463          	beqz	a1,ffffffffc020301a <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc0202ed6:	00659693          	slli	a3,a1,0x6
ffffffffc0202eda:	96aa                	add	a3,a3,a0
ffffffffc0202edc:	87aa                	mv	a5,a0
ffffffffc0202ede:	02d50263          	beq	a0,a3,ffffffffc0202f02 <default_free_pages+0x34>
ffffffffc0202ee2:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202ee4:	8b05                	andi	a4,a4,1
ffffffffc0202ee6:	10071a63          	bnez	a4,ffffffffc0202ffa <default_free_pages+0x12c>
ffffffffc0202eea:	6798                	ld	a4,8(a5)
ffffffffc0202eec:	8b09                	andi	a4,a4,2
ffffffffc0202eee:	10071663          	bnez	a4,ffffffffc0202ffa <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0202ef2:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0202ef6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0202efa:	04078793          	addi	a5,a5,64
ffffffffc0202efe:	fed792e3          	bne	a5,a3,ffffffffc0202ee2 <default_free_pages+0x14>
    base->property = n;
ffffffffc0202f02:	2581                	sext.w	a1,a1
ffffffffc0202f04:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0202f06:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0202f0a:	4789                	li	a5,2
ffffffffc0202f0c:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0202f10:	00006697          	auipc	a3,0x6
ffffffffc0202f14:	52068693          	addi	a3,a3,1312 # ffffffffc0209430 <free_area>
ffffffffc0202f18:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0202f1a:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0202f1c:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0202f20:	9db9                	addw	a1,a1,a4
ffffffffc0202f22:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0202f24:	0ad78463          	beq	a5,a3,ffffffffc0202fcc <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc0202f28:	fe878713          	addi	a4,a5,-24
ffffffffc0202f2c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0202f30:	4581                	li	a1,0
            if (base < page) {
ffffffffc0202f32:	00e56a63          	bltu	a0,a4,ffffffffc0202f46 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0202f36:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0202f38:	04d70c63          	beq	a4,a3,ffffffffc0202f90 <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc0202f3c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0202f3e:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0202f42:	fee57ae3          	bgeu	a0,a4,ffffffffc0202f36 <default_free_pages+0x68>
ffffffffc0202f46:	c199                	beqz	a1,ffffffffc0202f4c <default_free_pages+0x7e>
ffffffffc0202f48:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0202f4c:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0202f4e:	e390                	sd	a2,0(a5)
ffffffffc0202f50:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0202f52:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202f54:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0202f56:	00d70d63          	beq	a4,a3,ffffffffc0202f70 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0202f5a:	ff872583          	lw	a1,-8(a4) # ff8 <kern_entry-0xffffffffc01ff008>
        p = le2page(le, page_link);
ffffffffc0202f5e:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0202f62:	02059813          	slli	a6,a1,0x20
ffffffffc0202f66:	01a85793          	srli	a5,a6,0x1a
ffffffffc0202f6a:	97b2                	add	a5,a5,a2
ffffffffc0202f6c:	02f50c63          	beq	a0,a5,ffffffffc0202fa4 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0202f70:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0202f72:	00d78c63          	beq	a5,a3,ffffffffc0202f8a <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0202f76:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0202f78:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0202f7c:	02061593          	slli	a1,a2,0x20
ffffffffc0202f80:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0202f84:	972a                	add	a4,a4,a0
ffffffffc0202f86:	04e68a63          	beq	a3,a4,ffffffffc0202fda <default_free_pages+0x10c>
}
ffffffffc0202f8a:	60a2                	ld	ra,8(sp)
ffffffffc0202f8c:	0141                	addi	sp,sp,16
ffffffffc0202f8e:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0202f90:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202f92:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0202f94:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0202f96:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202f98:	02d70763          	beq	a4,a3,ffffffffc0202fc6 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0202f9c:	8832                	mv	a6,a2
ffffffffc0202f9e:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0202fa0:	87ba                	mv	a5,a4
ffffffffc0202fa2:	bf71                	j	ffffffffc0202f3e <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0202fa4:	491c                	lw	a5,16(a0)
ffffffffc0202fa6:	9dbd                	addw	a1,a1,a5
ffffffffc0202fa8:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0202fac:	57f5                	li	a5,-3
ffffffffc0202fae:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202fb2:	01853803          	ld	a6,24(a0)
ffffffffc0202fb6:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0202fb8:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0202fba:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0202fbe:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0202fc0:	0105b023          	sd	a6,0(a1) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0202fc4:	b77d                	j	ffffffffc0202f72 <default_free_pages+0xa4>
ffffffffc0202fc6:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202fc8:	873e                	mv	a4,a5
ffffffffc0202fca:	bf41                	j	ffffffffc0202f5a <default_free_pages+0x8c>
}
ffffffffc0202fcc:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0202fce:	e390                	sd	a2,0(a5)
ffffffffc0202fd0:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202fd2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202fd4:	ed1c                	sd	a5,24(a0)
ffffffffc0202fd6:	0141                	addi	sp,sp,16
ffffffffc0202fd8:	8082                	ret
            base->property += p->property;
ffffffffc0202fda:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202fde:	ff078693          	addi	a3,a5,-16
ffffffffc0202fe2:	9e39                	addw	a2,a2,a4
ffffffffc0202fe4:	c910                	sw	a2,16(a0)
ffffffffc0202fe6:	5775                	li	a4,-3
ffffffffc0202fe8:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202fec:	6398                	ld	a4,0(a5)
ffffffffc0202fee:	679c                	ld	a5,8(a5)
}
ffffffffc0202ff0:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0202ff2:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202ff4:	e398                	sd	a4,0(a5)
ffffffffc0202ff6:	0141                	addi	sp,sp,16
ffffffffc0202ff8:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202ffa:	00002697          	auipc	a3,0x2
ffffffffc0202ffe:	43e68693          	addi	a3,a3,1086 # ffffffffc0205438 <commands+0x1310>
ffffffffc0203002:	00002617          	auipc	a2,0x2
ffffffffc0203006:	96660613          	addi	a2,a2,-1690 # ffffffffc0204968 <commands+0x840>
ffffffffc020300a:	08300593          	li	a1,131
ffffffffc020300e:	00002517          	auipc	a0,0x2
ffffffffc0203012:	0e250513          	addi	a0,a0,226 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0203016:	9c8fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(n > 0);
ffffffffc020301a:	00002697          	auipc	a3,0x2
ffffffffc020301e:	41668693          	addi	a3,a3,1046 # ffffffffc0205430 <commands+0x1308>
ffffffffc0203022:	00002617          	auipc	a2,0x2
ffffffffc0203026:	94660613          	addi	a2,a2,-1722 # ffffffffc0204968 <commands+0x840>
ffffffffc020302a:	08000593          	li	a1,128
ffffffffc020302e:	00002517          	auipc	a0,0x2
ffffffffc0203032:	0c250513          	addi	a0,a0,194 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc0203036:	9a8fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc020303a <default_alloc_pages>:
    assert(n > 0);
ffffffffc020303a:	c941                	beqz	a0,ffffffffc02030ca <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc020303c:	00006597          	auipc	a1,0x6
ffffffffc0203040:	3f458593          	addi	a1,a1,1012 # ffffffffc0209430 <free_area>
ffffffffc0203044:	0105a803          	lw	a6,16(a1)
ffffffffc0203048:	872a                	mv	a4,a0
ffffffffc020304a:	02081793          	slli	a5,a6,0x20
ffffffffc020304e:	9381                	srli	a5,a5,0x20
ffffffffc0203050:	00a7ee63          	bltu	a5,a0,ffffffffc020306c <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0203054:	87ae                	mv	a5,a1
ffffffffc0203056:	a801                	j	ffffffffc0203066 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0203058:	ff87a683          	lw	a3,-8(a5)
ffffffffc020305c:	02069613          	slli	a2,a3,0x20
ffffffffc0203060:	9201                	srli	a2,a2,0x20
ffffffffc0203062:	00e67763          	bgeu	a2,a4,ffffffffc0203070 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0203066:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0203068:	feb798e3          	bne	a5,a1,ffffffffc0203058 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020306c:	4501                	li	a0,0
}
ffffffffc020306e:	8082                	ret
    return listelm->prev;
ffffffffc0203070:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203074:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0203078:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020307c:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0203080:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0203084:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0203088:	02c77863          	bgeu	a4,a2,ffffffffc02030b8 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc020308c:	071a                	slli	a4,a4,0x6
ffffffffc020308e:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0203090:	41c686bb          	subw	a3,a3,t3
ffffffffc0203094:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203096:	00870613          	addi	a2,a4,8
ffffffffc020309a:	4689                	li	a3,2
ffffffffc020309c:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02030a0:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02030a4:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02030a8:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02030ac:	e290                	sd	a2,0(a3)
ffffffffc02030ae:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02030b2:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02030b4:	01173c23          	sd	a7,24(a4)
ffffffffc02030b8:	41c8083b          	subw	a6,a6,t3
ffffffffc02030bc:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02030c0:	5775                	li	a4,-3
ffffffffc02030c2:	17c1                	addi	a5,a5,-16
ffffffffc02030c4:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02030c8:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02030ca:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02030cc:	00002697          	auipc	a3,0x2
ffffffffc02030d0:	36468693          	addi	a3,a3,868 # ffffffffc0205430 <commands+0x1308>
ffffffffc02030d4:	00002617          	auipc	a2,0x2
ffffffffc02030d8:	89460613          	addi	a2,a2,-1900 # ffffffffc0204968 <commands+0x840>
ffffffffc02030dc:	06200593          	li	a1,98
ffffffffc02030e0:	00002517          	auipc	a0,0x2
ffffffffc02030e4:	01050513          	addi	a0,a0,16 # ffffffffc02050f0 <commands+0xfc8>
default_alloc_pages(size_t n) {
ffffffffc02030e8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02030ea:	8f4fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02030ee <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02030ee:	1141                	addi	sp,sp,-16
ffffffffc02030f0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02030f2:	c5f1                	beqz	a1,ffffffffc02031be <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc02030f4:	00659693          	slli	a3,a1,0x6
ffffffffc02030f8:	96aa                	add	a3,a3,a0
ffffffffc02030fa:	87aa                	mv	a5,a0
ffffffffc02030fc:	00d50f63          	beq	a0,a3,ffffffffc020311a <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203100:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0203102:	8b05                	andi	a4,a4,1
ffffffffc0203104:	cf49                	beqz	a4,ffffffffc020319e <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0203106:	0007a823          	sw	zero,16(a5)
ffffffffc020310a:	0007b423          	sd	zero,8(a5)
ffffffffc020310e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0203112:	04078793          	addi	a5,a5,64
ffffffffc0203116:	fed795e3          	bne	a5,a3,ffffffffc0203100 <default_init_memmap+0x12>
    base->property = n;
ffffffffc020311a:	2581                	sext.w	a1,a1
ffffffffc020311c:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020311e:	4789                	li	a5,2
ffffffffc0203120:	00850713          	addi	a4,a0,8
ffffffffc0203124:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0203128:	00006697          	auipc	a3,0x6
ffffffffc020312c:	30868693          	addi	a3,a3,776 # ffffffffc0209430 <free_area>
ffffffffc0203130:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0203132:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0203134:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0203138:	9db9                	addw	a1,a1,a4
ffffffffc020313a:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020313c:	04d78a63          	beq	a5,a3,ffffffffc0203190 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc0203140:	fe878713          	addi	a4,a5,-24
ffffffffc0203144:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0203148:	4581                	li	a1,0
            if (base < page) {
ffffffffc020314a:	00e56a63          	bltu	a0,a4,ffffffffc020315e <default_init_memmap+0x70>
    return listelm->next;
ffffffffc020314e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0203150:	02d70263          	beq	a4,a3,ffffffffc0203174 <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc0203154:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0203156:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020315a:	fee57ae3          	bgeu	a0,a4,ffffffffc020314e <default_init_memmap+0x60>
ffffffffc020315e:	c199                	beqz	a1,ffffffffc0203164 <default_init_memmap+0x76>
ffffffffc0203160:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203164:	6398                	ld	a4,0(a5)
}
ffffffffc0203166:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0203168:	e390                	sd	a2,0(a5)
ffffffffc020316a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020316c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020316e:	ed18                	sd	a4,24(a0)
ffffffffc0203170:	0141                	addi	sp,sp,16
ffffffffc0203172:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0203174:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203176:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0203178:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020317a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020317c:	00d70663          	beq	a4,a3,ffffffffc0203188 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0203180:	8832                	mv	a6,a2
ffffffffc0203182:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0203184:	87ba                	mv	a5,a4
ffffffffc0203186:	bfc1                	j	ffffffffc0203156 <default_init_memmap+0x68>
}
ffffffffc0203188:	60a2                	ld	ra,8(sp)
ffffffffc020318a:	e290                	sd	a2,0(a3)
ffffffffc020318c:	0141                	addi	sp,sp,16
ffffffffc020318e:	8082                	ret
ffffffffc0203190:	60a2                	ld	ra,8(sp)
ffffffffc0203192:	e390                	sd	a2,0(a5)
ffffffffc0203194:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203196:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0203198:	ed1c                	sd	a5,24(a0)
ffffffffc020319a:	0141                	addi	sp,sp,16
ffffffffc020319c:	8082                	ret
        assert(PageReserved(p));
ffffffffc020319e:	00002697          	auipc	a3,0x2
ffffffffc02031a2:	2c268693          	addi	a3,a3,706 # ffffffffc0205460 <commands+0x1338>
ffffffffc02031a6:	00001617          	auipc	a2,0x1
ffffffffc02031aa:	7c260613          	addi	a2,a2,1986 # ffffffffc0204968 <commands+0x840>
ffffffffc02031ae:	04900593          	li	a1,73
ffffffffc02031b2:	00002517          	auipc	a0,0x2
ffffffffc02031b6:	f3e50513          	addi	a0,a0,-194 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc02031ba:	824fd0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(n > 0);
ffffffffc02031be:	00002697          	auipc	a3,0x2
ffffffffc02031c2:	27268693          	addi	a3,a3,626 # ffffffffc0205430 <commands+0x1308>
ffffffffc02031c6:	00001617          	auipc	a2,0x1
ffffffffc02031ca:	7a260613          	addi	a2,a2,1954 # ffffffffc0204968 <commands+0x840>
ffffffffc02031ce:	04600593          	li	a1,70
ffffffffc02031d2:	00002517          	auipc	a0,0x2
ffffffffc02031d6:	f1e50513          	addi	a0,a0,-226 # ffffffffc02050f0 <commands+0xfc8>
ffffffffc02031da:	804fd0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02031de <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02031de:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02031e2:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02031e6:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02031e8:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02031ea:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02031ee:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02031f2:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02031f6:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02031fa:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02031fe:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0203202:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0203206:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020320a:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc020320e:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0203212:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0203216:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020321a:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020321c:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc020321e:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0203222:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0203226:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020322a:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020322e:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0203232:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0203236:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020323a:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020323e:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0203242:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0203246:	8082                	ret

ffffffffc0203248 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203248:	8526                	mv	a0,s1
	jalr s0
ffffffffc020324a:	9402                	jalr	s0

	jal do_exit
ffffffffc020324c:	414000ef          	jal	ra,ffffffffc0203660 <do_exit>

ffffffffc0203250 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203250:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203252:	0e800513          	li	a0,232
{
ffffffffc0203256:	e022                	sd	s0,0(sp)
ffffffffc0203258:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020325a:	b2cff0ef          	jal	ra,ffffffffc0202586 <kmalloc>
ffffffffc020325e:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203260:	c521                	beqz	a0,ffffffffc02032a8 <alloc_proc+0x58>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;                      // 设置进程为未初始化状态
ffffffffc0203262:	57fd                	li	a5,-1
ffffffffc0203264:	1782                	slli	a5,a5,0x20
ffffffffc0203266:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                                 // 初始化运行次数为0
        proc->kstack = 0;                               // 内核栈地址初始化为0
        proc->need_resched = 0;                         // 不需要调度
        proc->parent = NULL;                            // 没有父进程
        proc->mm = NULL;                                // 未分配内存管理结构
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文
ffffffffc0203268:	07000613          	li	a2,112
ffffffffc020326c:	4581                	li	a1,0
        proc->runs = 0;                                 // 初始化运行次数为0
ffffffffc020326e:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;                               // 内核栈地址初始化为0
ffffffffc0203272:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                         // 不需要调度
ffffffffc0203276:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;                            // 没有父进程
ffffffffc020327a:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                                // 未分配内存管理结构
ffffffffc020327e:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 初始化上下文
ffffffffc0203282:	03050513          	addi	a0,a0,48
ffffffffc0203286:	7c8000ef          	jal	ra,ffffffffc0203a4e <memset>
        proc->tf = NULL;                                // 中断帧指针初始化为NULL
        proc->pgdir = boot_pgdir_pa;                    // 使用内核页目录表
ffffffffc020328a:	0000a797          	auipc	a5,0xa
ffffffffc020328e:	2067b783          	ld	a5,518(a5) # ffffffffc020d490 <boot_pgdir_pa>
        proc->tf = NULL;                                // 中断帧指针初始化为NULL
ffffffffc0203292:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;                    // 使用内核页目录表
ffffffffc0203296:	f45c                	sd	a5,168(s0)
        proc->flags = 0;                                // 初始化标志位为0
ffffffffc0203298:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);       // 初始化进程名
ffffffffc020329c:	4641                	li	a2,16
ffffffffc020329e:	4581                	li	a1,0
ffffffffc02032a0:	0b440513          	addi	a0,s0,180
ffffffffc02032a4:	7aa000ef          	jal	ra,ffffffffc0203a4e <memset>
    }
    return proc;
}
ffffffffc02032a8:	60a2                	ld	ra,8(sp)
ffffffffc02032aa:	8522                	mv	a0,s0
ffffffffc02032ac:	6402                	ld	s0,0(sp)
ffffffffc02032ae:	0141                	addi	sp,sp,16
ffffffffc02032b0:	8082                	ret

ffffffffc02032b2 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc02032b2:	0000a797          	auipc	a5,0xa
ffffffffc02032b6:	2167b783          	ld	a5,534(a5) # ffffffffc020d4c8 <current>
ffffffffc02032ba:	73c8                	ld	a0,160(a5)
ffffffffc02032bc:	af1fd06f          	j	ffffffffc0200dac <forkrets>

ffffffffc02032c0 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02032c0:	7179                	addi	sp,sp,-48
ffffffffc02032c2:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc02032c4:	0000a497          	auipc	s1,0xa
ffffffffc02032c8:	18448493          	addi	s1,s1,388 # ffffffffc020d448 <name.2>
{
ffffffffc02032cc:	f022                	sd	s0,32(sp)
ffffffffc02032ce:	e84a                	sd	s2,16(sp)
ffffffffc02032d0:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032d2:	0000a917          	auipc	s2,0xa
ffffffffc02032d6:	1f693903          	ld	s2,502(s2) # ffffffffc020d4c8 <current>
    memset(name, 0, sizeof(name));
ffffffffc02032da:	4641                	li	a2,16
ffffffffc02032dc:	4581                	li	a1,0
ffffffffc02032de:	8526                	mv	a0,s1
{
ffffffffc02032e0:	f406                	sd	ra,40(sp)
ffffffffc02032e2:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032e4:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc02032e8:	766000ef          	jal	ra,ffffffffc0203a4e <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02032ec:	0b490593          	addi	a1,s2,180
ffffffffc02032f0:	463d                	li	a2,15
ffffffffc02032f2:	8526                	mv	a0,s1
ffffffffc02032f4:	76c000ef          	jal	ra,ffffffffc0203a60 <memcpy>
ffffffffc02032f8:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032fa:	85ce                	mv	a1,s3
ffffffffc02032fc:	00002517          	auipc	a0,0x2
ffffffffc0203300:	1c450513          	addi	a0,a0,452 # ffffffffc02054c0 <default_pmm_manager+0x38>
ffffffffc0203304:	dddfc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc0203308:	85a2                	mv	a1,s0
ffffffffc020330a:	00002517          	auipc	a0,0x2
ffffffffc020330e:	1de50513          	addi	a0,a0,478 # ffffffffc02054e8 <default_pmm_manager+0x60>
ffffffffc0203312:	dcffc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc0203316:	00002517          	auipc	a0,0x2
ffffffffc020331a:	1e250513          	addi	a0,a0,482 # ffffffffc02054f8 <default_pmm_manager+0x70>
ffffffffc020331e:	dc3fc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    return 0;
}
ffffffffc0203322:	70a2                	ld	ra,40(sp)
ffffffffc0203324:	7402                	ld	s0,32(sp)
ffffffffc0203326:	64e2                	ld	s1,24(sp)
ffffffffc0203328:	6942                	ld	s2,16(sp)
ffffffffc020332a:	69a2                	ld	s3,8(sp)
ffffffffc020332c:	4501                	li	a0,0
ffffffffc020332e:	6145                	addi	sp,sp,48
ffffffffc0203330:	8082                	ret

ffffffffc0203332 <proc_run>:
{
ffffffffc0203332:	7179                	addi	sp,sp,-48
ffffffffc0203334:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc0203336:	0000a917          	auipc	s2,0xa
ffffffffc020333a:	19290913          	addi	s2,s2,402 # ffffffffc020d4c8 <current>
{
ffffffffc020333e:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0203340:	00093483          	ld	s1,0(s2)
{
ffffffffc0203344:	f406                	sd	ra,40(sp)
ffffffffc0203346:	e84e                	sd	s3,16(sp)
    if (proc != current)
ffffffffc0203348:	02a48963          	beq	s1,a0,ffffffffc020337a <proc_run+0x48>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020334c:	100027f3          	csrr	a5,sstatus
ffffffffc0203350:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203352:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203354:	e3a1                	bnez	a5,ffffffffc0203394 <proc_run+0x62>
            lsatp(next->pgdir);
ffffffffc0203356:	755c                	ld	a5,168(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203358:	80000737          	lui	a4,0x80000
            current = proc;
ffffffffc020335c:	00a93023          	sd	a0,0(s2)
ffffffffc0203360:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc0203364:	8fd9                	or	a5,a5,a4
ffffffffc0203366:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc020336a:	03050593          	addi	a1,a0,48
ffffffffc020336e:	03048513          	addi	a0,s1,48
ffffffffc0203372:	e6dff0ef          	jal	ra,ffffffffc02031de <switch_to>
    if (flag) {
ffffffffc0203376:	00099863          	bnez	s3,ffffffffc0203386 <proc_run+0x54>
}
ffffffffc020337a:	70a2                	ld	ra,40(sp)
ffffffffc020337c:	7482                	ld	s1,32(sp)
ffffffffc020337e:	6962                	ld	s2,24(sp)
ffffffffc0203380:	69c2                	ld	s3,16(sp)
ffffffffc0203382:	6145                	addi	sp,sp,48
ffffffffc0203384:	8082                	ret
ffffffffc0203386:	70a2                	ld	ra,40(sp)
ffffffffc0203388:	7482                	ld	s1,32(sp)
ffffffffc020338a:	6962                	ld	s2,24(sp)
ffffffffc020338c:	69c2                	ld	s3,16(sp)
ffffffffc020338e:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203390:	da0fd06f          	j	ffffffffc0200930 <intr_enable>
ffffffffc0203394:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203396:	da0fd0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        return 1;
ffffffffc020339a:	6522                	ld	a0,8(sp)
ffffffffc020339c:	4985                	li	s3,1
ffffffffc020339e:	bf65                	j	ffffffffc0203356 <proc_run+0x24>

ffffffffc02033a0 <do_fork>:
{
ffffffffc02033a0:	7179                	addi	sp,sp,-48
ffffffffc02033a2:	ec26                	sd	s1,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02033a4:	0000a497          	auipc	s1,0xa
ffffffffc02033a8:	13c48493          	addi	s1,s1,316 # ffffffffc020d4e0 <nr_process>
ffffffffc02033ac:	4098                	lw	a4,0(s1)
{
ffffffffc02033ae:	f406                	sd	ra,40(sp)
ffffffffc02033b0:	f022                	sd	s0,32(sp)
ffffffffc02033b2:	e84a                	sd	s2,16(sp)
ffffffffc02033b4:	e44e                	sd	s3,8(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02033b6:	6785                	lui	a5,0x1
ffffffffc02033b8:	20f75963          	bge	a4,a5,ffffffffc02035ca <do_fork+0x22a>
ffffffffc02033bc:	892e                	mv	s2,a1
ffffffffc02033be:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc02033c0:	e91ff0ef          	jal	ra,ffffffffc0203250 <alloc_proc>
ffffffffc02033c4:	89aa                	mv	s3,a0
ffffffffc02033c6:	20050763          	beqz	a0,ffffffffc02035d4 <do_fork+0x234>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02033ca:	4509                	li	a0,2
ffffffffc02033cc:	a1ffd0ef          	jal	ra,ffffffffc0200dea <alloc_pages>
    if (page != NULL)
ffffffffc02033d0:	1e050863          	beqz	a0,ffffffffc02035c0 <do_fork+0x220>
    return page - pages + nbase;
ffffffffc02033d4:	0000a697          	auipc	a3,0xa
ffffffffc02033d8:	0d46b683          	ld	a3,212(a3) # ffffffffc020d4a8 <pages>
ffffffffc02033dc:	40d506b3          	sub	a3,a0,a3
ffffffffc02033e0:	8699                	srai	a3,a3,0x6
ffffffffc02033e2:	00002517          	auipc	a0,0x2
ffffffffc02033e6:	4d653503          	ld	a0,1238(a0) # ffffffffc02058b8 <nbase>
ffffffffc02033ea:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc02033ec:	00c69793          	slli	a5,a3,0xc
ffffffffc02033f0:	83b1                	srli	a5,a5,0xc
ffffffffc02033f2:	0000a717          	auipc	a4,0xa
ffffffffc02033f6:	0ae73703          	ld	a4,174(a4) # ffffffffc020d4a0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02033fa:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033fc:	1ee7fe63          	bgeu	a5,a4,ffffffffc02035f8 <do_fork+0x258>
    assert(current->mm == NULL);
ffffffffc0203400:	0000a797          	auipc	a5,0xa
ffffffffc0203404:	0c87b783          	ld	a5,200(a5) # ffffffffc020d4c8 <current>
ffffffffc0203408:	779c                	ld	a5,40(a5)
ffffffffc020340a:	0000a717          	auipc	a4,0xa
ffffffffc020340e:	0ae73703          	ld	a4,174(a4) # ffffffffc020d4b8 <va_pa_offset>
ffffffffc0203412:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203414:	00d9b823          	sd	a3,16(s3)
    assert(current->mm == NULL);
ffffffffc0203418:	1c079063          	bnez	a5,ffffffffc02035d8 <do_fork+0x238>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc020341c:	6789                	lui	a5,0x2
ffffffffc020341e:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc0203422:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0203424:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0203426:	0ad9b023          	sd	a3,160(s3)
    *(proc->tf) = *tf;
ffffffffc020342a:	87b6                	mv	a5,a3
ffffffffc020342c:	12040893          	addi	a7,s0,288
ffffffffc0203430:	00063803          	ld	a6,0(a2)
ffffffffc0203434:	6608                	ld	a0,8(a2)
ffffffffc0203436:	6a0c                	ld	a1,16(a2)
ffffffffc0203438:	6e18                	ld	a4,24(a2)
ffffffffc020343a:	0107b023          	sd	a6,0(a5)
ffffffffc020343e:	e788                	sd	a0,8(a5)
ffffffffc0203440:	eb8c                	sd	a1,16(a5)
ffffffffc0203442:	ef98                	sd	a4,24(a5)
ffffffffc0203444:	02060613          	addi	a2,a2,32
ffffffffc0203448:	02078793          	addi	a5,a5,32
ffffffffc020344c:	ff1612e3          	bne	a2,a7,ffffffffc0203430 <do_fork+0x90>
    proc->tf->gpr.a0 = 0;
ffffffffc0203450:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203454:	12090463          	beqz	s2,ffffffffc020357c <do_fork+0x1dc>
ffffffffc0203458:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020345c:	00000797          	auipc	a5,0x0
ffffffffc0203460:	e5678793          	addi	a5,a5,-426 # ffffffffc02032b2 <forkret>
ffffffffc0203464:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203468:	02d9bc23          	sd	a3,56(s3)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020346c:	100027f3          	csrr	a5,sstatus
ffffffffc0203470:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203472:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203474:	12079563          	bnez	a5,ffffffffc020359e <do_fork+0x1fe>
    if (++last_pid >= MAX_PID)
ffffffffc0203478:	00006817          	auipc	a6,0x6
ffffffffc020347c:	bb080813          	addi	a6,a6,-1104 # ffffffffc0209028 <last_pid.1>
ffffffffc0203480:	00082783          	lw	a5,0(a6)
ffffffffc0203484:	6709                	lui	a4,0x2
ffffffffc0203486:	0017851b          	addiw	a0,a5,1
ffffffffc020348a:	00a82023          	sw	a0,0(a6)
ffffffffc020348e:	08e55063          	bge	a0,a4,ffffffffc020350e <do_fork+0x16e>
    if (last_pid >= next_safe)
ffffffffc0203492:	00006317          	auipc	t1,0x6
ffffffffc0203496:	b9a30313          	addi	t1,t1,-1126 # ffffffffc020902c <next_safe.0>
ffffffffc020349a:	00032783          	lw	a5,0(t1)
ffffffffc020349e:	0000a417          	auipc	s0,0xa
ffffffffc02034a2:	fba40413          	addi	s0,s0,-70 # ffffffffc020d458 <proc_list>
ffffffffc02034a6:	06f55c63          	bge	a0,a5,ffffffffc020351e <do_fork+0x17e>
        proc->pid = get_pid();
ffffffffc02034aa:	00a9a223          	sw	a0,4(s3)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02034ae:	45a9                	li	a1,10
ffffffffc02034b0:	2501                	sext.w	a0,a0
ffffffffc02034b2:	1d9000ef          	jal	ra,ffffffffc0203e8a <hash32>
ffffffffc02034b6:	02051793          	slli	a5,a0,0x20
ffffffffc02034ba:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02034be:	00006797          	auipc	a5,0x6
ffffffffc02034c2:	f8a78793          	addi	a5,a5,-118 # ffffffffc0209448 <hash_list>
ffffffffc02034c6:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02034c8:	6510                	ld	a2,8(a0)
ffffffffc02034ca:	0d898793          	addi	a5,s3,216
ffffffffc02034ce:	6414                	ld	a3,8(s0)
        nr_process++;
ffffffffc02034d0:	4098                	lw	a4,0(s1)
    prev->next = next->prev = elm;
ffffffffc02034d2:	e21c                	sd	a5,0(a2)
ffffffffc02034d4:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc02034d6:	0ec9b023          	sd	a2,224(s3)
        list_add(&proc_list, &(proc->list_link));
ffffffffc02034da:	0c898793          	addi	a5,s3,200
    elm->prev = prev;
ffffffffc02034de:	0ca9bc23          	sd	a0,216(s3)
    prev->next = next->prev = elm;
ffffffffc02034e2:	e29c                	sd	a5,0(a3)
        nr_process++;
ffffffffc02034e4:	2705                	addiw	a4,a4,1
ffffffffc02034e6:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02034e8:	0cd9b823          	sd	a3,208(s3)
    elm->prev = prev;
ffffffffc02034ec:	0c89b423          	sd	s0,200(s3)
ffffffffc02034f0:	c098                	sw	a4,0(s1)
    if (flag) {
ffffffffc02034f2:	0a091a63          	bnez	s2,ffffffffc02035a6 <do_fork+0x206>
    wakeup_proc(proc);
ffffffffc02034f6:	854e                	mv	a0,s3
ffffffffc02034f8:	3ee000ef          	jal	ra,ffffffffc02038e6 <wakeup_proc>
    ret = proc->pid;
ffffffffc02034fc:	0049a503          	lw	a0,4(s3)
}
ffffffffc0203500:	70a2                	ld	ra,40(sp)
ffffffffc0203502:	7402                	ld	s0,32(sp)
ffffffffc0203504:	64e2                	ld	s1,24(sp)
ffffffffc0203506:	6942                	ld	s2,16(sp)
ffffffffc0203508:	69a2                	ld	s3,8(sp)
ffffffffc020350a:	6145                	addi	sp,sp,48
ffffffffc020350c:	8082                	ret
        last_pid = 1;
ffffffffc020350e:	4785                	li	a5,1
ffffffffc0203510:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0203514:	4505                	li	a0,1
ffffffffc0203516:	00006317          	auipc	t1,0x6
ffffffffc020351a:	b1630313          	addi	t1,t1,-1258 # ffffffffc020902c <next_safe.0>
    return listelm->next;
ffffffffc020351e:	0000a417          	auipc	s0,0xa
ffffffffc0203522:	f3a40413          	addi	s0,s0,-198 # ffffffffc020d458 <proc_list>
ffffffffc0203526:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc020352a:	6789                	lui	a5,0x2
ffffffffc020352c:	00f32023          	sw	a5,0(t1)
ffffffffc0203530:	86aa                	mv	a3,a0
ffffffffc0203532:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0203534:	6e89                	lui	t4,0x2
ffffffffc0203536:	088e0063          	beq	t3,s0,ffffffffc02035b6 <do_fork+0x216>
ffffffffc020353a:	88ae                	mv	a7,a1
ffffffffc020353c:	87f2                	mv	a5,t3
ffffffffc020353e:	6609                	lui	a2,0x2
ffffffffc0203540:	a811                	j	ffffffffc0203554 <do_fork+0x1b4>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203542:	00e6d663          	bge	a3,a4,ffffffffc020354e <do_fork+0x1ae>
ffffffffc0203546:	00c75463          	bge	a4,a2,ffffffffc020354e <do_fork+0x1ae>
ffffffffc020354a:	863a                	mv	a2,a4
ffffffffc020354c:	4885                	li	a7,1
ffffffffc020354e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203550:	00878d63          	beq	a5,s0,ffffffffc020356a <do_fork+0x1ca>
            if (proc->pid == last_pid)
ffffffffc0203554:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc0203558:	fed715e3          	bne	a4,a3,ffffffffc0203542 <do_fork+0x1a2>
                if (++last_pid >= next_safe)
ffffffffc020355c:	2685                	addiw	a3,a3,1
ffffffffc020355e:	04c6d763          	bge	a3,a2,ffffffffc02035ac <do_fork+0x20c>
ffffffffc0203562:	679c                	ld	a5,8(a5)
ffffffffc0203564:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0203566:	fe8797e3          	bne	a5,s0,ffffffffc0203554 <do_fork+0x1b4>
ffffffffc020356a:	c581                	beqz	a1,ffffffffc0203572 <do_fork+0x1d2>
ffffffffc020356c:	00d82023          	sw	a3,0(a6)
ffffffffc0203570:	8536                	mv	a0,a3
ffffffffc0203572:	f2088ce3          	beqz	a7,ffffffffc02034aa <do_fork+0x10a>
ffffffffc0203576:	00c32023          	sw	a2,0(t1)
ffffffffc020357a:	bf05                	j	ffffffffc02034aa <do_fork+0x10a>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020357c:	8936                	mv	s2,a3
ffffffffc020357e:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203582:	00000797          	auipc	a5,0x0
ffffffffc0203586:	d3078793          	addi	a5,a5,-720 # ffffffffc02032b2 <forkret>
ffffffffc020358a:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020358e:	02d9bc23          	sd	a3,56(s3)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203592:	100027f3          	csrr	a5,sstatus
ffffffffc0203596:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203598:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020359a:	ec078fe3          	beqz	a5,ffffffffc0203478 <do_fork+0xd8>
        intr_disable();
ffffffffc020359e:	b98fd0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        return 1;
ffffffffc02035a2:	4905                	li	s2,1
ffffffffc02035a4:	bdd1                	j	ffffffffc0203478 <do_fork+0xd8>
        intr_enable();
ffffffffc02035a6:	b8afd0ef          	jal	ra,ffffffffc0200930 <intr_enable>
ffffffffc02035aa:	b7b1                	j	ffffffffc02034f6 <do_fork+0x156>
                    if (last_pid >= MAX_PID)
ffffffffc02035ac:	01d6c363          	blt	a3,t4,ffffffffc02035b2 <do_fork+0x212>
                        last_pid = 1;
ffffffffc02035b0:	4685                	li	a3,1
                    goto repeat;
ffffffffc02035b2:	4585                	li	a1,1
ffffffffc02035b4:	b749                	j	ffffffffc0203536 <do_fork+0x196>
ffffffffc02035b6:	cd81                	beqz	a1,ffffffffc02035ce <do_fork+0x22e>
ffffffffc02035b8:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02035bc:	8536                	mv	a0,a3
ffffffffc02035be:	b5f5                	j	ffffffffc02034aa <do_fork+0x10a>
    kfree(proc);
ffffffffc02035c0:	854e                	mv	a0,s3
ffffffffc02035c2:	874ff0ef          	jal	ra,ffffffffc0202636 <kfree>
    ret = -E_NO_MEM;
ffffffffc02035c6:	5571                	li	a0,-4
    goto fork_out;
ffffffffc02035c8:	bf25                	j	ffffffffc0203500 <do_fork+0x160>
    int ret = -E_NO_FREE_PROC;
ffffffffc02035ca:	556d                	li	a0,-5
ffffffffc02035cc:	bf15                	j	ffffffffc0203500 <do_fork+0x160>
    return last_pid;
ffffffffc02035ce:	00082503          	lw	a0,0(a6)
ffffffffc02035d2:	bde1                	j	ffffffffc02034aa <do_fork+0x10a>
    ret = -E_NO_MEM;
ffffffffc02035d4:	5571                	li	a0,-4
    return ret;
ffffffffc02035d6:	b72d                	j	ffffffffc0203500 <do_fork+0x160>
    assert(current->mm == NULL);
ffffffffc02035d8:	00002697          	auipc	a3,0x2
ffffffffc02035dc:	f4068693          	addi	a3,a3,-192 # ffffffffc0205518 <default_pmm_manager+0x90>
ffffffffc02035e0:	00001617          	auipc	a2,0x1
ffffffffc02035e4:	38860613          	addi	a2,a2,904 # ffffffffc0204968 <commands+0x840>
ffffffffc02035e8:	12400593          	li	a1,292
ffffffffc02035ec:	00002517          	auipc	a0,0x2
ffffffffc02035f0:	f4450513          	addi	a0,a0,-188 # ffffffffc0205530 <default_pmm_manager+0xa8>
ffffffffc02035f4:	bebfc0ef          	jal	ra,ffffffffc02001de <__panic>
ffffffffc02035f8:	00001617          	auipc	a2,0x1
ffffffffc02035fc:	24060613          	addi	a2,a2,576 # ffffffffc0204838 <commands+0x710>
ffffffffc0203600:	07100593          	li	a1,113
ffffffffc0203604:	00001517          	auipc	a0,0x1
ffffffffc0203608:	1fc50513          	addi	a0,a0,508 # ffffffffc0204800 <commands+0x6d8>
ffffffffc020360c:	bd3fc0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0203610 <kernel_thread>:
{
ffffffffc0203610:	7129                	addi	sp,sp,-320
ffffffffc0203612:	fa22                	sd	s0,304(sp)
ffffffffc0203614:	f626                	sd	s1,296(sp)
ffffffffc0203616:	f24a                	sd	s2,288(sp)
ffffffffc0203618:	84ae                	mv	s1,a1
ffffffffc020361a:	892a                	mv	s2,a0
ffffffffc020361c:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020361e:	4581                	li	a1,0
ffffffffc0203620:	12000613          	li	a2,288
ffffffffc0203624:	850a                	mv	a0,sp
{
ffffffffc0203626:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203628:	426000ef          	jal	ra,ffffffffc0203a4e <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020362c:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020362e:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0203630:	100027f3          	csrr	a5,sstatus
ffffffffc0203634:	edd7f793          	andi	a5,a5,-291
ffffffffc0203638:	1207e793          	ori	a5,a5,288
ffffffffc020363c:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020363e:	860a                	mv	a2,sp
ffffffffc0203640:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0203644:	00000797          	auipc	a5,0x0
ffffffffc0203648:	c0478793          	addi	a5,a5,-1020 # ffffffffc0203248 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020364c:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020364e:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203650:	d51ff0ef          	jal	ra,ffffffffc02033a0 <do_fork>
}
ffffffffc0203654:	70f2                	ld	ra,312(sp)
ffffffffc0203656:	7452                	ld	s0,304(sp)
ffffffffc0203658:	74b2                	ld	s1,296(sp)
ffffffffc020365a:	7912                	ld	s2,288(sp)
ffffffffc020365c:	6131                	addi	sp,sp,320
ffffffffc020365e:	8082                	ret

ffffffffc0203660 <do_exit>:
{
ffffffffc0203660:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc0203662:	00002617          	auipc	a2,0x2
ffffffffc0203666:	ee660613          	addi	a2,a2,-282 # ffffffffc0205548 <default_pmm_manager+0xc0>
ffffffffc020366a:	18c00593          	li	a1,396
ffffffffc020366e:	00002517          	auipc	a0,0x2
ffffffffc0203672:	ec250513          	addi	a0,a0,-318 # ffffffffc0205530 <default_pmm_manager+0xa8>
{
ffffffffc0203676:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc0203678:	b67fc0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc020367c <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc020367c:	7179                	addi	sp,sp,-48
ffffffffc020367e:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc0203680:	0000a797          	auipc	a5,0xa
ffffffffc0203684:	dd878793          	addi	a5,a5,-552 # ffffffffc020d458 <proc_list>
ffffffffc0203688:	f406                	sd	ra,40(sp)
ffffffffc020368a:	f022                	sd	s0,32(sp)
ffffffffc020368c:	e84a                	sd	s2,16(sp)
ffffffffc020368e:	e44e                	sd	s3,8(sp)
ffffffffc0203690:	00006497          	auipc	s1,0x6
ffffffffc0203694:	db848493          	addi	s1,s1,-584 # ffffffffc0209448 <hash_list>
ffffffffc0203698:	e79c                	sd	a5,8(a5)
ffffffffc020369a:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc020369c:	0000a717          	auipc	a4,0xa
ffffffffc02036a0:	dac70713          	addi	a4,a4,-596 # ffffffffc020d448 <name.2>
ffffffffc02036a4:	87a6                	mv	a5,s1
ffffffffc02036a6:	e79c                	sd	a5,8(a5)
ffffffffc02036a8:	e39c                	sd	a5,0(a5)
ffffffffc02036aa:	07c1                	addi	a5,a5,16
ffffffffc02036ac:	fef71de3          	bne	a4,a5,ffffffffc02036a6 <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc02036b0:	ba1ff0ef          	jal	ra,ffffffffc0203250 <alloc_proc>
ffffffffc02036b4:	0000a917          	auipc	s2,0xa
ffffffffc02036b8:	e1c90913          	addi	s2,s2,-484 # ffffffffc020d4d0 <idleproc>
ffffffffc02036bc:	00a93023          	sd	a0,0(s2)
ffffffffc02036c0:	18050d63          	beqz	a0,ffffffffc020385a <proc_init+0x1de>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc02036c4:	07000513          	li	a0,112
ffffffffc02036c8:	ebffe0ef          	jal	ra,ffffffffc0202586 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02036cc:	07000613          	li	a2,112
ffffffffc02036d0:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc02036d2:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02036d4:	37a000ef          	jal	ra,ffffffffc0203a4e <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc02036d8:	00093503          	ld	a0,0(s2)
ffffffffc02036dc:	85a2                	mv	a1,s0
ffffffffc02036de:	07000613          	li	a2,112
ffffffffc02036e2:	03050513          	addi	a0,a0,48
ffffffffc02036e6:	392000ef          	jal	ra,ffffffffc0203a78 <memcmp>
ffffffffc02036ea:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02036ec:	453d                	li	a0,15
ffffffffc02036ee:	e99fe0ef          	jal	ra,ffffffffc0202586 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02036f2:	463d                	li	a2,15
ffffffffc02036f4:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02036f6:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02036f8:	356000ef          	jal	ra,ffffffffc0203a4e <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc02036fc:	00093503          	ld	a0,0(s2)
ffffffffc0203700:	463d                	li	a2,15
ffffffffc0203702:	85a2                	mv	a1,s0
ffffffffc0203704:	0b450513          	addi	a0,a0,180
ffffffffc0203708:	370000ef          	jal	ra,ffffffffc0203a78 <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc020370c:	00093783          	ld	a5,0(s2)
ffffffffc0203710:	0000a717          	auipc	a4,0xa
ffffffffc0203714:	d8073703          	ld	a4,-640(a4) # ffffffffc020d490 <boot_pgdir_pa>
ffffffffc0203718:	77d4                	ld	a3,168(a5)
ffffffffc020371a:	0ee68463          	beq	a3,a4,ffffffffc0203802 <proc_init+0x186>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc020371e:	4709                	li	a4,2
ffffffffc0203720:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0203722:	00003717          	auipc	a4,0x3
ffffffffc0203726:	8de70713          	addi	a4,a4,-1826 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020372a:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020372e:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc0203730:	4705                	li	a4,1
ffffffffc0203732:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203734:	4641                	li	a2,16
ffffffffc0203736:	4581                	li	a1,0
ffffffffc0203738:	8522                	mv	a0,s0
ffffffffc020373a:	314000ef          	jal	ra,ffffffffc0203a4e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020373e:	463d                	li	a2,15
ffffffffc0203740:	00002597          	auipc	a1,0x2
ffffffffc0203744:	e5058593          	addi	a1,a1,-432 # ffffffffc0205590 <default_pmm_manager+0x108>
ffffffffc0203748:	8522                	mv	a0,s0
ffffffffc020374a:	316000ef          	jal	ra,ffffffffc0203a60 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc020374e:	0000a717          	auipc	a4,0xa
ffffffffc0203752:	d9270713          	addi	a4,a4,-622 # ffffffffc020d4e0 <nr_process>
ffffffffc0203756:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0203758:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020375c:	4601                	li	a2,0
    nr_process++;
ffffffffc020375e:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203760:	00002597          	auipc	a1,0x2
ffffffffc0203764:	e3858593          	addi	a1,a1,-456 # ffffffffc0205598 <default_pmm_manager+0x110>
ffffffffc0203768:	00000517          	auipc	a0,0x0
ffffffffc020376c:	b5850513          	addi	a0,a0,-1192 # ffffffffc02032c0 <init_main>
    nr_process++;
ffffffffc0203770:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0203772:	0000a797          	auipc	a5,0xa
ffffffffc0203776:	d4d7bb23          	sd	a3,-682(a5) # ffffffffc020d4c8 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020377a:	e97ff0ef          	jal	ra,ffffffffc0203610 <kernel_thread>
ffffffffc020377e:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0203780:	0ea05963          	blez	a0,ffffffffc0203872 <proc_init+0x1f6>
    if (0 < pid && pid < MAX_PID)
ffffffffc0203784:	6789                	lui	a5,0x2
ffffffffc0203786:	fff5071b          	addiw	a4,a0,-1
ffffffffc020378a:	17f9                	addi	a5,a5,-2
ffffffffc020378c:	2501                	sext.w	a0,a0
ffffffffc020378e:	02e7e363          	bltu	a5,a4,ffffffffc02037b4 <proc_init+0x138>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0203792:	45a9                	li	a1,10
ffffffffc0203794:	6f6000ef          	jal	ra,ffffffffc0203e8a <hash32>
ffffffffc0203798:	02051793          	slli	a5,a0,0x20
ffffffffc020379c:	01c7d693          	srli	a3,a5,0x1c
ffffffffc02037a0:	96a6                	add	a3,a3,s1
ffffffffc02037a2:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02037a4:	a029                	j	ffffffffc02037ae <proc_init+0x132>
            if (proc->pid == pid)
ffffffffc02037a6:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc02037aa:	0a870563          	beq	a4,s0,ffffffffc0203854 <proc_init+0x1d8>
    return listelm->next;
ffffffffc02037ae:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02037b0:	fef69be3          	bne	a3,a5,ffffffffc02037a6 <proc_init+0x12a>
    return NULL;
ffffffffc02037b4:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02037b6:	0b478493          	addi	s1,a5,180
ffffffffc02037ba:	4641                	li	a2,16
ffffffffc02037bc:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02037be:	0000a417          	auipc	s0,0xa
ffffffffc02037c2:	d1a40413          	addi	s0,s0,-742 # ffffffffc020d4d8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02037c6:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc02037c8:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02037ca:	284000ef          	jal	ra,ffffffffc0203a4e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02037ce:	463d                	li	a2,15
ffffffffc02037d0:	00002597          	auipc	a1,0x2
ffffffffc02037d4:	df858593          	addi	a1,a1,-520 # ffffffffc02055c8 <default_pmm_manager+0x140>
ffffffffc02037d8:	8526                	mv	a0,s1
ffffffffc02037da:	286000ef          	jal	ra,ffffffffc0203a60 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02037de:	00093783          	ld	a5,0(s2)
ffffffffc02037e2:	c7e1                	beqz	a5,ffffffffc02038aa <proc_init+0x22e>
ffffffffc02037e4:	43dc                	lw	a5,4(a5)
ffffffffc02037e6:	e3f1                	bnez	a5,ffffffffc02038aa <proc_init+0x22e>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02037e8:	601c                	ld	a5,0(s0)
ffffffffc02037ea:	c3c5                	beqz	a5,ffffffffc020388a <proc_init+0x20e>
ffffffffc02037ec:	43d8                	lw	a4,4(a5)
ffffffffc02037ee:	4785                	li	a5,1
ffffffffc02037f0:	08f71d63          	bne	a4,a5,ffffffffc020388a <proc_init+0x20e>
}
ffffffffc02037f4:	70a2                	ld	ra,40(sp)
ffffffffc02037f6:	7402                	ld	s0,32(sp)
ffffffffc02037f8:	64e2                	ld	s1,24(sp)
ffffffffc02037fa:	6942                	ld	s2,16(sp)
ffffffffc02037fc:	69a2                	ld	s3,8(sp)
ffffffffc02037fe:	6145                	addi	sp,sp,48
ffffffffc0203800:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203802:	73d8                	ld	a4,160(a5)
ffffffffc0203804:	ff09                	bnez	a4,ffffffffc020371e <proc_init+0xa2>
ffffffffc0203806:	f0099ce3          	bnez	s3,ffffffffc020371e <proc_init+0xa2>
ffffffffc020380a:	6394                	ld	a3,0(a5)
ffffffffc020380c:	577d                	li	a4,-1
ffffffffc020380e:	1702                	slli	a4,a4,0x20
ffffffffc0203810:	f0e697e3          	bne	a3,a4,ffffffffc020371e <proc_init+0xa2>
ffffffffc0203814:	4798                	lw	a4,8(a5)
ffffffffc0203816:	f00714e3          	bnez	a4,ffffffffc020371e <proc_init+0xa2>
ffffffffc020381a:	6b98                	ld	a4,16(a5)
ffffffffc020381c:	f00711e3          	bnez	a4,ffffffffc020371e <proc_init+0xa2>
ffffffffc0203820:	4f98                	lw	a4,24(a5)
ffffffffc0203822:	2701                	sext.w	a4,a4
ffffffffc0203824:	ee071de3          	bnez	a4,ffffffffc020371e <proc_init+0xa2>
ffffffffc0203828:	7398                	ld	a4,32(a5)
ffffffffc020382a:	ee071ae3          	bnez	a4,ffffffffc020371e <proc_init+0xa2>
ffffffffc020382e:	7798                	ld	a4,40(a5)
ffffffffc0203830:	ee0717e3          	bnez	a4,ffffffffc020371e <proc_init+0xa2>
ffffffffc0203834:	0b07a703          	lw	a4,176(a5)
ffffffffc0203838:	8d59                	or	a0,a0,a4
ffffffffc020383a:	0005071b          	sext.w	a4,a0
ffffffffc020383e:	ee0710e3          	bnez	a4,ffffffffc020371e <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc0203842:	00002517          	auipc	a0,0x2
ffffffffc0203846:	d3650513          	addi	a0,a0,-714 # ffffffffc0205578 <default_pmm_manager+0xf0>
ffffffffc020384a:	897fc0ef          	jal	ra,ffffffffc02000e0 <cprintf>
    idleproc->pid = 0;
ffffffffc020384e:	00093783          	ld	a5,0(s2)
ffffffffc0203852:	b5f1                	j	ffffffffc020371e <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0203854:	f2878793          	addi	a5,a5,-216
ffffffffc0203858:	bfb9                	j	ffffffffc02037b6 <proc_init+0x13a>
        panic("cannot alloc idleproc.\n");
ffffffffc020385a:	00002617          	auipc	a2,0x2
ffffffffc020385e:	d0660613          	addi	a2,a2,-762 # ffffffffc0205560 <default_pmm_manager+0xd8>
ffffffffc0203862:	1a700593          	li	a1,423
ffffffffc0203866:	00002517          	auipc	a0,0x2
ffffffffc020386a:	cca50513          	addi	a0,a0,-822 # ffffffffc0205530 <default_pmm_manager+0xa8>
ffffffffc020386e:	971fc0ef          	jal	ra,ffffffffc02001de <__panic>
        panic("create init_main failed.\n");
ffffffffc0203872:	00002617          	auipc	a2,0x2
ffffffffc0203876:	d3660613          	addi	a2,a2,-714 # ffffffffc02055a8 <default_pmm_manager+0x120>
ffffffffc020387a:	1c400593          	li	a1,452
ffffffffc020387e:	00002517          	auipc	a0,0x2
ffffffffc0203882:	cb250513          	addi	a0,a0,-846 # ffffffffc0205530 <default_pmm_manager+0xa8>
ffffffffc0203886:	959fc0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020388a:	00002697          	auipc	a3,0x2
ffffffffc020388e:	d6e68693          	addi	a3,a3,-658 # ffffffffc02055f8 <default_pmm_manager+0x170>
ffffffffc0203892:	00001617          	auipc	a2,0x1
ffffffffc0203896:	0d660613          	addi	a2,a2,214 # ffffffffc0204968 <commands+0x840>
ffffffffc020389a:	1cb00593          	li	a1,459
ffffffffc020389e:	00002517          	auipc	a0,0x2
ffffffffc02038a2:	c9250513          	addi	a0,a0,-878 # ffffffffc0205530 <default_pmm_manager+0xa8>
ffffffffc02038a6:	939fc0ef          	jal	ra,ffffffffc02001de <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02038aa:	00002697          	auipc	a3,0x2
ffffffffc02038ae:	d2668693          	addi	a3,a3,-730 # ffffffffc02055d0 <default_pmm_manager+0x148>
ffffffffc02038b2:	00001617          	auipc	a2,0x1
ffffffffc02038b6:	0b660613          	addi	a2,a2,182 # ffffffffc0204968 <commands+0x840>
ffffffffc02038ba:	1ca00593          	li	a1,458
ffffffffc02038be:	00002517          	auipc	a0,0x2
ffffffffc02038c2:	c7250513          	addi	a0,a0,-910 # ffffffffc0205530 <default_pmm_manager+0xa8>
ffffffffc02038c6:	919fc0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc02038ca <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02038ca:	1141                	addi	sp,sp,-16
ffffffffc02038cc:	e022                	sd	s0,0(sp)
ffffffffc02038ce:	e406                	sd	ra,8(sp)
ffffffffc02038d0:	0000a417          	auipc	s0,0xa
ffffffffc02038d4:	bf840413          	addi	s0,s0,-1032 # ffffffffc020d4c8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02038d8:	6018                	ld	a4,0(s0)
ffffffffc02038da:	4f1c                	lw	a5,24(a4)
ffffffffc02038dc:	2781                	sext.w	a5,a5
ffffffffc02038de:	dff5                	beqz	a5,ffffffffc02038da <cpu_idle+0x10>
        {
            schedule();
ffffffffc02038e0:	038000ef          	jal	ra,ffffffffc0203918 <schedule>
ffffffffc02038e4:	bfd5                	j	ffffffffc02038d8 <cpu_idle+0xe>

ffffffffc02038e6 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038e6:	411c                	lw	a5,0(a0)
ffffffffc02038e8:	4705                	li	a4,1
ffffffffc02038ea:	37f9                	addiw	a5,a5,-2
ffffffffc02038ec:	00f77563          	bgeu	a4,a5,ffffffffc02038f6 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc02038f0:	4789                	li	a5,2
ffffffffc02038f2:	c11c                	sw	a5,0(a0)
ffffffffc02038f4:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc02038f6:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038f8:	00002697          	auipc	a3,0x2
ffffffffc02038fc:	d2868693          	addi	a3,a3,-728 # ffffffffc0205620 <default_pmm_manager+0x198>
ffffffffc0203900:	00001617          	auipc	a2,0x1
ffffffffc0203904:	06860613          	addi	a2,a2,104 # ffffffffc0204968 <commands+0x840>
ffffffffc0203908:	45a5                	li	a1,9
ffffffffc020390a:	00002517          	auipc	a0,0x2
ffffffffc020390e:	d5650513          	addi	a0,a0,-682 # ffffffffc0205660 <default_pmm_manager+0x1d8>
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203912:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203914:	8cbfc0ef          	jal	ra,ffffffffc02001de <__panic>

ffffffffc0203918 <schedule>:
}

void
schedule(void) {
ffffffffc0203918:	1141                	addi	sp,sp,-16
ffffffffc020391a:	e406                	sd	ra,8(sp)
ffffffffc020391c:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020391e:	100027f3          	csrr	a5,sstatus
ffffffffc0203922:	8b89                	andi	a5,a5,2
ffffffffc0203924:	4401                	li	s0,0
ffffffffc0203926:	efbd                	bnez	a5,ffffffffc02039a4 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0203928:	0000a897          	auipc	a7,0xa
ffffffffc020392c:	ba08b883          	ld	a7,-1120(a7) # ffffffffc020d4c8 <current>
ffffffffc0203930:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203934:	0000a517          	auipc	a0,0xa
ffffffffc0203938:	b9c53503          	ld	a0,-1124(a0) # ffffffffc020d4d0 <idleproc>
ffffffffc020393c:	04a88e63          	beq	a7,a0,ffffffffc0203998 <schedule+0x80>
ffffffffc0203940:	0c888693          	addi	a3,a7,200
ffffffffc0203944:	0000a617          	auipc	a2,0xa
ffffffffc0203948:	b1460613          	addi	a2,a2,-1260 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc020394c:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020394e:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203950:	4809                	li	a6,2
ffffffffc0203952:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0203954:	00c78863          	beq	a5,a2,ffffffffc0203964 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203958:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020395c:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203960:	03070163          	beq	a4,a6,ffffffffc0203982 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0203964:	fef697e3          	bne	a3,a5,ffffffffc0203952 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203968:	ed89                	bnez	a1,ffffffffc0203982 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc020396a:	451c                	lw	a5,8(a0)
ffffffffc020396c:	2785                	addiw	a5,a5,1
ffffffffc020396e:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0203970:	00a88463          	beq	a7,a0,ffffffffc0203978 <schedule+0x60>
            proc_run(next);
ffffffffc0203974:	9bfff0ef          	jal	ra,ffffffffc0203332 <proc_run>
    if (flag) {
ffffffffc0203978:	e819                	bnez	s0,ffffffffc020398e <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020397a:	60a2                	ld	ra,8(sp)
ffffffffc020397c:	6402                	ld	s0,0(sp)
ffffffffc020397e:	0141                	addi	sp,sp,16
ffffffffc0203980:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203982:	4198                	lw	a4,0(a1)
ffffffffc0203984:	4789                	li	a5,2
ffffffffc0203986:	fef712e3          	bne	a4,a5,ffffffffc020396a <schedule+0x52>
ffffffffc020398a:	852e                	mv	a0,a1
ffffffffc020398c:	bff9                	j	ffffffffc020396a <schedule+0x52>
}
ffffffffc020398e:	6402                	ld	s0,0(sp)
ffffffffc0203990:	60a2                	ld	ra,8(sp)
ffffffffc0203992:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0203994:	f9dfc06f          	j	ffffffffc0200930 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203998:	0000a617          	auipc	a2,0xa
ffffffffc020399c:	ac060613          	addi	a2,a2,-1344 # ffffffffc020d458 <proc_list>
ffffffffc02039a0:	86b2                	mv	a3,a2
ffffffffc02039a2:	b76d                	j	ffffffffc020394c <schedule+0x34>
        intr_disable();
ffffffffc02039a4:	f93fc0ef          	jal	ra,ffffffffc0200936 <intr_disable>
        return 1;
ffffffffc02039a8:	4405                	li	s0,1
ffffffffc02039aa:	bfbd                	j	ffffffffc0203928 <schedule+0x10>

ffffffffc02039ac <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02039ac:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02039b0:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02039b2:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02039b4:	cb81                	beqz	a5,ffffffffc02039c4 <strlen+0x18>
        cnt ++;
ffffffffc02039b6:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02039b8:	00a707b3          	add	a5,a4,a0
ffffffffc02039bc:	0007c783          	lbu	a5,0(a5)
ffffffffc02039c0:	fbfd                	bnez	a5,ffffffffc02039b6 <strlen+0xa>
ffffffffc02039c2:	8082                	ret
    }
    return cnt;
}
ffffffffc02039c4:	8082                	ret

ffffffffc02039c6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02039c6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02039c8:	e589                	bnez	a1,ffffffffc02039d2 <strnlen+0xc>
ffffffffc02039ca:	a811                	j	ffffffffc02039de <strnlen+0x18>
        cnt ++;
ffffffffc02039cc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02039ce:	00f58863          	beq	a1,a5,ffffffffc02039de <strnlen+0x18>
ffffffffc02039d2:	00f50733          	add	a4,a0,a5
ffffffffc02039d6:	00074703          	lbu	a4,0(a4)
ffffffffc02039da:	fb6d                	bnez	a4,ffffffffc02039cc <strnlen+0x6>
ffffffffc02039dc:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02039de:	852e                	mv	a0,a1
ffffffffc02039e0:	8082                	ret

ffffffffc02039e2 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02039e2:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02039e4:	0005c703          	lbu	a4,0(a1)
ffffffffc02039e8:	0785                	addi	a5,a5,1
ffffffffc02039ea:	0585                	addi	a1,a1,1
ffffffffc02039ec:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02039f0:	fb75                	bnez	a4,ffffffffc02039e4 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02039f2:	8082                	ret

ffffffffc02039f4 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02039f4:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02039f8:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02039fc:	cb89                	beqz	a5,ffffffffc0203a0e <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02039fe:	0505                	addi	a0,a0,1
ffffffffc0203a00:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203a02:	fee789e3          	beq	a5,a4,ffffffffc02039f4 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203a06:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203a0a:	9d19                	subw	a0,a0,a4
ffffffffc0203a0c:	8082                	ret
ffffffffc0203a0e:	4501                	li	a0,0
ffffffffc0203a10:	bfed                	j	ffffffffc0203a0a <strcmp+0x16>

ffffffffc0203a12 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203a12:	c20d                	beqz	a2,ffffffffc0203a34 <strncmp+0x22>
ffffffffc0203a14:	962e                	add	a2,a2,a1
ffffffffc0203a16:	a031                	j	ffffffffc0203a22 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0203a18:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203a1a:	00e79a63          	bne	a5,a4,ffffffffc0203a2e <strncmp+0x1c>
ffffffffc0203a1e:	00b60b63          	beq	a2,a1,ffffffffc0203a34 <strncmp+0x22>
ffffffffc0203a22:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203a26:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203a28:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203a2c:	f7f5                	bnez	a5,ffffffffc0203a18 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203a2e:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0203a32:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203a34:	4501                	li	a0,0
ffffffffc0203a36:	8082                	ret

ffffffffc0203a38 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203a38:	00054783          	lbu	a5,0(a0)
ffffffffc0203a3c:	c799                	beqz	a5,ffffffffc0203a4a <strchr+0x12>
        if (*s == c) {
ffffffffc0203a3e:	00f58763          	beq	a1,a5,ffffffffc0203a4c <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203a42:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203a46:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203a48:	fbfd                	bnez	a5,ffffffffc0203a3e <strchr+0x6>
    }
    return NULL;
ffffffffc0203a4a:	4501                	li	a0,0
}
ffffffffc0203a4c:	8082                	ret

ffffffffc0203a4e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203a4e:	ca01                	beqz	a2,ffffffffc0203a5e <memset+0x10>
ffffffffc0203a50:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203a52:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203a54:	0785                	addi	a5,a5,1
ffffffffc0203a56:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203a5a:	fec79de3          	bne	a5,a2,ffffffffc0203a54 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203a5e:	8082                	ret

ffffffffc0203a60 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203a60:	ca19                	beqz	a2,ffffffffc0203a76 <memcpy+0x16>
ffffffffc0203a62:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203a64:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203a66:	0005c703          	lbu	a4,0(a1)
ffffffffc0203a6a:	0585                	addi	a1,a1,1
ffffffffc0203a6c:	0785                	addi	a5,a5,1
ffffffffc0203a6e:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203a72:	fec59ae3          	bne	a1,a2,ffffffffc0203a66 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203a76:	8082                	ret

ffffffffc0203a78 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203a78:	c205                	beqz	a2,ffffffffc0203a98 <memcmp+0x20>
ffffffffc0203a7a:	962e                	add	a2,a2,a1
ffffffffc0203a7c:	a019                	j	ffffffffc0203a82 <memcmp+0xa>
ffffffffc0203a7e:	00c58d63          	beq	a1,a2,ffffffffc0203a98 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203a82:	00054783          	lbu	a5,0(a0)
ffffffffc0203a86:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203a8a:	0505                	addi	a0,a0,1
ffffffffc0203a8c:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203a8e:	fee788e3          	beq	a5,a4,ffffffffc0203a7e <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203a92:	40e7853b          	subw	a0,a5,a4
ffffffffc0203a96:	8082                	ret
    }
    return 0;
ffffffffc0203a98:	4501                	li	a0,0
}
ffffffffc0203a9a:	8082                	ret

ffffffffc0203a9c <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203a9c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203aa0:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203aa2:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203aa6:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203aa8:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203aac:	f022                	sd	s0,32(sp)
ffffffffc0203aae:	ec26                	sd	s1,24(sp)
ffffffffc0203ab0:	e84a                	sd	s2,16(sp)
ffffffffc0203ab2:	f406                	sd	ra,40(sp)
ffffffffc0203ab4:	e44e                	sd	s3,8(sp)
ffffffffc0203ab6:	84aa                	mv	s1,a0
ffffffffc0203ab8:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203aba:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203abe:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0203ac0:	03067e63          	bgeu	a2,a6,ffffffffc0203afc <printnum+0x60>
ffffffffc0203ac4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203ac6:	00805763          	blez	s0,ffffffffc0203ad4 <printnum+0x38>
ffffffffc0203aca:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203acc:	85ca                	mv	a1,s2
ffffffffc0203ace:	854e                	mv	a0,s3
ffffffffc0203ad0:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203ad2:	fc65                	bnez	s0,ffffffffc0203aca <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203ad4:	1a02                	slli	s4,s4,0x20
ffffffffc0203ad6:	00002797          	auipc	a5,0x2
ffffffffc0203ada:	ba278793          	addi	a5,a5,-1118 # ffffffffc0205678 <default_pmm_manager+0x1f0>
ffffffffc0203ade:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203ae2:	9a3e                	add	s4,s4,a5
}
ffffffffc0203ae4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203ae6:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203aea:	70a2                	ld	ra,40(sp)
ffffffffc0203aec:	69a2                	ld	s3,8(sp)
ffffffffc0203aee:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203af0:	85ca                	mv	a1,s2
ffffffffc0203af2:	87a6                	mv	a5,s1
}
ffffffffc0203af4:	6942                	ld	s2,16(sp)
ffffffffc0203af6:	64e2                	ld	s1,24(sp)
ffffffffc0203af8:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203afa:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203afc:	03065633          	divu	a2,a2,a6
ffffffffc0203b00:	8722                	mv	a4,s0
ffffffffc0203b02:	f9bff0ef          	jal	ra,ffffffffc0203a9c <printnum>
ffffffffc0203b06:	b7f9                	j	ffffffffc0203ad4 <printnum+0x38>

ffffffffc0203b08 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203b08:	7119                	addi	sp,sp,-128
ffffffffc0203b0a:	f4a6                	sd	s1,104(sp)
ffffffffc0203b0c:	f0ca                	sd	s2,96(sp)
ffffffffc0203b0e:	ecce                	sd	s3,88(sp)
ffffffffc0203b10:	e8d2                	sd	s4,80(sp)
ffffffffc0203b12:	e4d6                	sd	s5,72(sp)
ffffffffc0203b14:	e0da                	sd	s6,64(sp)
ffffffffc0203b16:	fc5e                	sd	s7,56(sp)
ffffffffc0203b18:	f06a                	sd	s10,32(sp)
ffffffffc0203b1a:	fc86                	sd	ra,120(sp)
ffffffffc0203b1c:	f8a2                	sd	s0,112(sp)
ffffffffc0203b1e:	f862                	sd	s8,48(sp)
ffffffffc0203b20:	f466                	sd	s9,40(sp)
ffffffffc0203b22:	ec6e                	sd	s11,24(sp)
ffffffffc0203b24:	892a                	mv	s2,a0
ffffffffc0203b26:	84ae                	mv	s1,a1
ffffffffc0203b28:	8d32                	mv	s10,a2
ffffffffc0203b2a:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203b2c:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203b30:	5b7d                	li	s6,-1
ffffffffc0203b32:	00002a97          	auipc	s5,0x2
ffffffffc0203b36:	b72a8a93          	addi	s5,s5,-1166 # ffffffffc02056a4 <default_pmm_manager+0x21c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203b3a:	00002b97          	auipc	s7,0x2
ffffffffc0203b3e:	d46b8b93          	addi	s7,s7,-698 # ffffffffc0205880 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203b42:	000d4503          	lbu	a0,0(s10)
ffffffffc0203b46:	001d0413          	addi	s0,s10,1
ffffffffc0203b4a:	01350a63          	beq	a0,s3,ffffffffc0203b5e <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0203b4e:	c121                	beqz	a0,ffffffffc0203b8e <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0203b50:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203b52:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203b54:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203b56:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203b5a:	ff351ae3          	bne	a0,s3,ffffffffc0203b4e <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b5e:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203b62:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203b66:	4c81                	li	s9,0
ffffffffc0203b68:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0203b6a:	5c7d                	li	s8,-1
ffffffffc0203b6c:	5dfd                	li	s11,-1
ffffffffc0203b6e:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0203b72:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b74:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203b78:	0ff5f593          	zext.b	a1,a1
ffffffffc0203b7c:	00140d13          	addi	s10,s0,1
ffffffffc0203b80:	04b56263          	bltu	a0,a1,ffffffffc0203bc4 <vprintfmt+0xbc>
ffffffffc0203b84:	058a                	slli	a1,a1,0x2
ffffffffc0203b86:	95d6                	add	a1,a1,s5
ffffffffc0203b88:	4194                	lw	a3,0(a1)
ffffffffc0203b8a:	96d6                	add	a3,a3,s5
ffffffffc0203b8c:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203b8e:	70e6                	ld	ra,120(sp)
ffffffffc0203b90:	7446                	ld	s0,112(sp)
ffffffffc0203b92:	74a6                	ld	s1,104(sp)
ffffffffc0203b94:	7906                	ld	s2,96(sp)
ffffffffc0203b96:	69e6                	ld	s3,88(sp)
ffffffffc0203b98:	6a46                	ld	s4,80(sp)
ffffffffc0203b9a:	6aa6                	ld	s5,72(sp)
ffffffffc0203b9c:	6b06                	ld	s6,64(sp)
ffffffffc0203b9e:	7be2                	ld	s7,56(sp)
ffffffffc0203ba0:	7c42                	ld	s8,48(sp)
ffffffffc0203ba2:	7ca2                	ld	s9,40(sp)
ffffffffc0203ba4:	7d02                	ld	s10,32(sp)
ffffffffc0203ba6:	6de2                	ld	s11,24(sp)
ffffffffc0203ba8:	6109                	addi	sp,sp,128
ffffffffc0203baa:	8082                	ret
            padc = '0';
ffffffffc0203bac:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0203bae:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bb2:	846a                	mv	s0,s10
ffffffffc0203bb4:	00140d13          	addi	s10,s0,1
ffffffffc0203bb8:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203bbc:	0ff5f593          	zext.b	a1,a1
ffffffffc0203bc0:	fcb572e3          	bgeu	a0,a1,ffffffffc0203b84 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0203bc4:	85a6                	mv	a1,s1
ffffffffc0203bc6:	02500513          	li	a0,37
ffffffffc0203bca:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203bcc:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203bd0:	8d22                	mv	s10,s0
ffffffffc0203bd2:	f73788e3          	beq	a5,s3,ffffffffc0203b42 <vprintfmt+0x3a>
ffffffffc0203bd6:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0203bda:	1d7d                	addi	s10,s10,-1
ffffffffc0203bdc:	ff379de3          	bne	a5,s3,ffffffffc0203bd6 <vprintfmt+0xce>
ffffffffc0203be0:	b78d                	j	ffffffffc0203b42 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0203be2:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0203be6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bea:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203bec:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203bf0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203bf4:	02d86463          	bltu	a6,a3,ffffffffc0203c1c <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0203bf8:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203bfc:	002c169b          	slliw	a3,s8,0x2
ffffffffc0203c00:	0186873b          	addw	a4,a3,s8
ffffffffc0203c04:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203c08:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0203c0a:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203c0e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203c10:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0203c14:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203c18:	fed870e3          	bgeu	a6,a3,ffffffffc0203bf8 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0203c1c:	f40ddce3          	bgez	s11,ffffffffc0203b74 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0203c20:	8de2                	mv	s11,s8
ffffffffc0203c22:	5c7d                	li	s8,-1
ffffffffc0203c24:	bf81                	j	ffffffffc0203b74 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0203c26:	fffdc693          	not	a3,s11
ffffffffc0203c2a:	96fd                	srai	a3,a3,0x3f
ffffffffc0203c2c:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c30:	00144603          	lbu	a2,1(s0)
ffffffffc0203c34:	2d81                	sext.w	s11,s11
ffffffffc0203c36:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203c38:	bf35                	j	ffffffffc0203b74 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0203c3a:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c3e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203c42:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c44:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0203c46:	bfd9                	j	ffffffffc0203c1c <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0203c48:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c4a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203c4e:	01174463          	blt	a4,a7,ffffffffc0203c56 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0203c52:	1a088e63          	beqz	a7,ffffffffc0203e0e <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0203c56:	000a3603          	ld	a2,0(s4)
ffffffffc0203c5a:	46c1                	li	a3,16
ffffffffc0203c5c:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203c5e:	2781                	sext.w	a5,a5
ffffffffc0203c60:	876e                	mv	a4,s11
ffffffffc0203c62:	85a6                	mv	a1,s1
ffffffffc0203c64:	854a                	mv	a0,s2
ffffffffc0203c66:	e37ff0ef          	jal	ra,ffffffffc0203a9c <printnum>
            break;
ffffffffc0203c6a:	bde1                	j	ffffffffc0203b42 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0203c6c:	000a2503          	lw	a0,0(s4)
ffffffffc0203c70:	85a6                	mv	a1,s1
ffffffffc0203c72:	0a21                	addi	s4,s4,8
ffffffffc0203c74:	9902                	jalr	s2
            break;
ffffffffc0203c76:	b5f1                	j	ffffffffc0203b42 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203c78:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c7a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203c7e:	01174463          	blt	a4,a7,ffffffffc0203c86 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0203c82:	18088163          	beqz	a7,ffffffffc0203e04 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0203c86:	000a3603          	ld	a2,0(s4)
ffffffffc0203c8a:	46a9                	li	a3,10
ffffffffc0203c8c:	8a2e                	mv	s4,a1
ffffffffc0203c8e:	bfc1                	j	ffffffffc0203c5e <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c90:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203c94:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c96:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203c98:	bdf1                	j	ffffffffc0203b74 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0203c9a:	85a6                	mv	a1,s1
ffffffffc0203c9c:	02500513          	li	a0,37
ffffffffc0203ca0:	9902                	jalr	s2
            break;
ffffffffc0203ca2:	b545                	j	ffffffffc0203b42 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ca4:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0203ca8:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203caa:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203cac:	b5e1                	j	ffffffffc0203b74 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0203cae:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203cb0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203cb4:	01174463          	blt	a4,a7,ffffffffc0203cbc <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0203cb8:	14088163          	beqz	a7,ffffffffc0203dfa <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0203cbc:	000a3603          	ld	a2,0(s4)
ffffffffc0203cc0:	46a1                	li	a3,8
ffffffffc0203cc2:	8a2e                	mv	s4,a1
ffffffffc0203cc4:	bf69                	j	ffffffffc0203c5e <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0203cc6:	03000513          	li	a0,48
ffffffffc0203cca:	85a6                	mv	a1,s1
ffffffffc0203ccc:	e03e                	sd	a5,0(sp)
ffffffffc0203cce:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203cd0:	85a6                	mv	a1,s1
ffffffffc0203cd2:	07800513          	li	a0,120
ffffffffc0203cd6:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203cd8:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203cda:	6782                	ld	a5,0(sp)
ffffffffc0203cdc:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203cde:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0203ce2:	bfb5                	j	ffffffffc0203c5e <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203ce4:	000a3403          	ld	s0,0(s4)
ffffffffc0203ce8:	008a0713          	addi	a4,s4,8
ffffffffc0203cec:	e03a                	sd	a4,0(sp)
ffffffffc0203cee:	14040263          	beqz	s0,ffffffffc0203e32 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0203cf2:	0fb05763          	blez	s11,ffffffffc0203de0 <vprintfmt+0x2d8>
ffffffffc0203cf6:	02d00693          	li	a3,45
ffffffffc0203cfa:	0cd79163          	bne	a5,a3,ffffffffc0203dbc <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203cfe:	00044783          	lbu	a5,0(s0)
ffffffffc0203d02:	0007851b          	sext.w	a0,a5
ffffffffc0203d06:	cf85                	beqz	a5,ffffffffc0203d3e <vprintfmt+0x236>
ffffffffc0203d08:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d0c:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d10:	000c4563          	bltz	s8,ffffffffc0203d1a <vprintfmt+0x212>
ffffffffc0203d14:	3c7d                	addiw	s8,s8,-1
ffffffffc0203d16:	036c0263          	beq	s8,s6,ffffffffc0203d3a <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0203d1a:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d1c:	0e0c8e63          	beqz	s9,ffffffffc0203e18 <vprintfmt+0x310>
ffffffffc0203d20:	3781                	addiw	a5,a5,-32
ffffffffc0203d22:	0ef47b63          	bgeu	s0,a5,ffffffffc0203e18 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0203d26:	03f00513          	li	a0,63
ffffffffc0203d2a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d2c:	000a4783          	lbu	a5,0(s4)
ffffffffc0203d30:	3dfd                	addiw	s11,s11,-1
ffffffffc0203d32:	0a05                	addi	s4,s4,1
ffffffffc0203d34:	0007851b          	sext.w	a0,a5
ffffffffc0203d38:	ffe1                	bnez	a5,ffffffffc0203d10 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0203d3a:	01b05963          	blez	s11,ffffffffc0203d4c <vprintfmt+0x244>
ffffffffc0203d3e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0203d40:	85a6                	mv	a1,s1
ffffffffc0203d42:	02000513          	li	a0,32
ffffffffc0203d46:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203d48:	fe0d9be3          	bnez	s11,ffffffffc0203d3e <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203d4c:	6a02                	ld	s4,0(sp)
ffffffffc0203d4e:	bbd5                	j	ffffffffc0203b42 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203d50:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203d52:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0203d56:	01174463          	blt	a4,a7,ffffffffc0203d5e <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0203d5a:	08088d63          	beqz	a7,ffffffffc0203df4 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0203d5e:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203d62:	0a044d63          	bltz	s0,ffffffffc0203e1c <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0203d66:	8622                	mv	a2,s0
ffffffffc0203d68:	8a66                	mv	s4,s9
ffffffffc0203d6a:	46a9                	li	a3,10
ffffffffc0203d6c:	bdcd                	j	ffffffffc0203c5e <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0203d6e:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203d72:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203d74:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203d76:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203d7a:	8fb5                	xor	a5,a5,a3
ffffffffc0203d7c:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203d80:	02d74163          	blt	a4,a3,ffffffffc0203da2 <vprintfmt+0x29a>
ffffffffc0203d84:	00369793          	slli	a5,a3,0x3
ffffffffc0203d88:	97de                	add	a5,a5,s7
ffffffffc0203d8a:	639c                	ld	a5,0(a5)
ffffffffc0203d8c:	cb99                	beqz	a5,ffffffffc0203da2 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203d8e:	86be                	mv	a3,a5
ffffffffc0203d90:	00000617          	auipc	a2,0x0
ffffffffc0203d94:	13860613          	addi	a2,a2,312 # ffffffffc0203ec8 <etext+0x28>
ffffffffc0203d98:	85a6                	mv	a1,s1
ffffffffc0203d9a:	854a                	mv	a0,s2
ffffffffc0203d9c:	0ce000ef          	jal	ra,ffffffffc0203e6a <printfmt>
ffffffffc0203da0:	b34d                	j	ffffffffc0203b42 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203da2:	00002617          	auipc	a2,0x2
ffffffffc0203da6:	8f660613          	addi	a2,a2,-1802 # ffffffffc0205698 <default_pmm_manager+0x210>
ffffffffc0203daa:	85a6                	mv	a1,s1
ffffffffc0203dac:	854a                	mv	a0,s2
ffffffffc0203dae:	0bc000ef          	jal	ra,ffffffffc0203e6a <printfmt>
ffffffffc0203db2:	bb41                	j	ffffffffc0203b42 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0203db4:	00002417          	auipc	s0,0x2
ffffffffc0203db8:	8dc40413          	addi	s0,s0,-1828 # ffffffffc0205690 <default_pmm_manager+0x208>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203dbc:	85e2                	mv	a1,s8
ffffffffc0203dbe:	8522                	mv	a0,s0
ffffffffc0203dc0:	e43e                	sd	a5,8(sp)
ffffffffc0203dc2:	c05ff0ef          	jal	ra,ffffffffc02039c6 <strnlen>
ffffffffc0203dc6:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203dca:	01b05b63          	blez	s11,ffffffffc0203de0 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0203dce:	67a2                	ld	a5,8(sp)
ffffffffc0203dd0:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203dd4:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0203dd6:	85a6                	mv	a1,s1
ffffffffc0203dd8:	8552                	mv	a0,s4
ffffffffc0203dda:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203ddc:	fe0d9ce3          	bnez	s11,ffffffffc0203dd4 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203de0:	00044783          	lbu	a5,0(s0)
ffffffffc0203de4:	00140a13          	addi	s4,s0,1
ffffffffc0203de8:	0007851b          	sext.w	a0,a5
ffffffffc0203dec:	d3a5                	beqz	a5,ffffffffc0203d4c <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203dee:	05e00413          	li	s0,94
ffffffffc0203df2:	bf39                	j	ffffffffc0203d10 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0203df4:	000a2403          	lw	s0,0(s4)
ffffffffc0203df8:	b7ad                	j	ffffffffc0203d62 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0203dfa:	000a6603          	lwu	a2,0(s4)
ffffffffc0203dfe:	46a1                	li	a3,8
ffffffffc0203e00:	8a2e                	mv	s4,a1
ffffffffc0203e02:	bdb1                	j	ffffffffc0203c5e <vprintfmt+0x156>
ffffffffc0203e04:	000a6603          	lwu	a2,0(s4)
ffffffffc0203e08:	46a9                	li	a3,10
ffffffffc0203e0a:	8a2e                	mv	s4,a1
ffffffffc0203e0c:	bd89                	j	ffffffffc0203c5e <vprintfmt+0x156>
ffffffffc0203e0e:	000a6603          	lwu	a2,0(s4)
ffffffffc0203e12:	46c1                	li	a3,16
ffffffffc0203e14:	8a2e                	mv	s4,a1
ffffffffc0203e16:	b5a1                	j	ffffffffc0203c5e <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0203e18:	9902                	jalr	s2
ffffffffc0203e1a:	bf09                	j	ffffffffc0203d2c <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0203e1c:	85a6                	mv	a1,s1
ffffffffc0203e1e:	02d00513          	li	a0,45
ffffffffc0203e22:	e03e                	sd	a5,0(sp)
ffffffffc0203e24:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203e26:	6782                	ld	a5,0(sp)
ffffffffc0203e28:	8a66                	mv	s4,s9
ffffffffc0203e2a:	40800633          	neg	a2,s0
ffffffffc0203e2e:	46a9                	li	a3,10
ffffffffc0203e30:	b53d                	j	ffffffffc0203c5e <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0203e32:	03b05163          	blez	s11,ffffffffc0203e54 <vprintfmt+0x34c>
ffffffffc0203e36:	02d00693          	li	a3,45
ffffffffc0203e3a:	f6d79de3          	bne	a5,a3,ffffffffc0203db4 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0203e3e:	00002417          	auipc	s0,0x2
ffffffffc0203e42:	85240413          	addi	s0,s0,-1966 # ffffffffc0205690 <default_pmm_manager+0x208>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203e46:	02800793          	li	a5,40
ffffffffc0203e4a:	02800513          	li	a0,40
ffffffffc0203e4e:	00140a13          	addi	s4,s0,1
ffffffffc0203e52:	bd6d                	j	ffffffffc0203d0c <vprintfmt+0x204>
ffffffffc0203e54:	00002a17          	auipc	s4,0x2
ffffffffc0203e58:	83da0a13          	addi	s4,s4,-1987 # ffffffffc0205691 <default_pmm_manager+0x209>
ffffffffc0203e5c:	02800513          	li	a0,40
ffffffffc0203e60:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203e64:	05e00413          	li	s0,94
ffffffffc0203e68:	b565                	j	ffffffffc0203d10 <vprintfmt+0x208>

ffffffffc0203e6a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203e6a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203e6c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203e70:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203e72:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203e74:	ec06                	sd	ra,24(sp)
ffffffffc0203e76:	f83a                	sd	a4,48(sp)
ffffffffc0203e78:	fc3e                	sd	a5,56(sp)
ffffffffc0203e7a:	e0c2                	sd	a6,64(sp)
ffffffffc0203e7c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203e7e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203e80:	c89ff0ef          	jal	ra,ffffffffc0203b08 <vprintfmt>
}
ffffffffc0203e84:	60e2                	ld	ra,24(sp)
ffffffffc0203e86:	6161                	addi	sp,sp,80
ffffffffc0203e88:	8082                	ret

ffffffffc0203e8a <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0203e8a:	9e3707b7          	lui	a5,0x9e370
ffffffffc0203e8e:	2785                	addiw	a5,a5,1
ffffffffc0203e90:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0203e94:	02000793          	li	a5,32
ffffffffc0203e98:	9f8d                	subw	a5,a5,a1
}
ffffffffc0203e9a:	00f5553b          	srlw	a0,a0,a5
ffffffffc0203e9e:	8082                	ret
