
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	80c50513          	addi	a0,a0,-2036 # ffffffffc0201858 <etext+0x6>
{
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0fe000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	81650513          	addi	a0,a0,-2026 # ffffffffc0201878 <etext+0x26>
ffffffffc020006a:	0ea000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	7e458593          	addi	a1,a1,2020 # ffffffffc0201852 <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	82250513          	addi	a0,a0,-2014 # ffffffffc0201898 <etext+0x46>
ffffffffc020007e:	0d6000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <buddy_area>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	82e50513          	addi	a0,a0,-2002 # ffffffffc02018b8 <etext+0x66>
ffffffffc0200092:	0c2000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	23258593          	addi	a1,a1,562 # ffffffffc02062c8 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	83a50513          	addi	a0,a0,-1990 # ffffffffc02018d8 <etext+0x86>
ffffffffc02000a6:	0ae000ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char *)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006597          	auipc	a1,0x6
ffffffffc02000ae:	61d58593          	addi	a1,a1,1565 # ffffffffc02066c7 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	82c50513          	addi	a0,a0,-2004 # ffffffffc02018f8 <etext+0xa6>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a8bd                	j	ffffffffc0200154 <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <buddy_area>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	1e860613          	addi	a2,a2,488 # ffffffffc02062c8 <end>
{
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
{
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	750010ef          	jal	ra,ffffffffc0201840 <memset>
    dtb_init();
ffffffffc02000f4:	134000ef          	jal	ra,ffffffffc0200228 <dtb_init>
    cons_init(); // init the console
ffffffffc02000f8:	126000ef          	jal	ra,ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    // cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	82c50513          	addi	a0,a0,-2004 # ffffffffc0201928 <etext+0xd6>
ffffffffc0200104:	086000ef          	jal	ra,ffffffffc020018a <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init(); // init physical memory management
ffffffffc020010c:	337000ef          	jal	ra,ffffffffc0200c42 <pmm_init>

    slub_init();  // 初始化SLUB
ffffffffc0200110:	02a010ef          	jal	ra,ffffffffc020113a <slub_init>
    slub_check(); // 测试SLUB
ffffffffc0200114:	0ae010ef          	jal	ra,ffffffffc02011c2 <slub_check>
    /* do nothing */
    while (1)
ffffffffc0200118:	a001                	j	ffffffffc0200118 <kern_init+0x40>

ffffffffc020011a <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020011a:	1141                	addi	sp,sp,-16
ffffffffc020011c:	e022                	sd	s0,0(sp)
ffffffffc020011e:	e406                	sd	ra,8(sp)
ffffffffc0200120:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200122:	0fe000ef          	jal	ra,ffffffffc0200220 <cons_putc>
    (*cnt) ++;
ffffffffc0200126:	401c                	lw	a5,0(s0)
}
ffffffffc0200128:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc020012a:	2785                	addiw	a5,a5,1
ffffffffc020012c:	c01c                	sw	a5,0(s0)
}
ffffffffc020012e:	6402                	ld	s0,0(sp)
ffffffffc0200130:	0141                	addi	sp,sp,16
ffffffffc0200132:	8082                	ret

ffffffffc0200134 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200134:	1101                	addi	sp,sp,-32
ffffffffc0200136:	862a                	mv	a2,a0
ffffffffc0200138:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013a:	00000517          	auipc	a0,0x0
ffffffffc020013e:	fe050513          	addi	a0,a0,-32 # ffffffffc020011a <cputch>
ffffffffc0200142:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200144:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200146:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200148:	2d0010ef          	jal	ra,ffffffffc0201418 <vprintfmt>
    return cnt;
}
ffffffffc020014c:	60e2                	ld	ra,24(sp)
ffffffffc020014e:	4532                	lw	a0,12(sp)
ffffffffc0200150:	6105                	addi	sp,sp,32
ffffffffc0200152:	8082                	ret

ffffffffc0200154 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200154:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200156:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc020015a:	8e2a                	mv	t3,a0
ffffffffc020015c:	f42e                	sd	a1,40(sp)
ffffffffc020015e:	f832                	sd	a2,48(sp)
ffffffffc0200160:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200162:	00000517          	auipc	a0,0x0
ffffffffc0200166:	fb850513          	addi	a0,a0,-72 # ffffffffc020011a <cputch>
ffffffffc020016a:	004c                	addi	a1,sp,4
ffffffffc020016c:	869a                	mv	a3,t1
ffffffffc020016e:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200170:	ec06                	sd	ra,24(sp)
ffffffffc0200172:	e0ba                	sd	a4,64(sp)
ffffffffc0200174:	e4be                	sd	a5,72(sp)
ffffffffc0200176:	e8c2                	sd	a6,80(sp)
ffffffffc0200178:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020017a:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc020017c:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020017e:	29a010ef          	jal	ra,ffffffffc0201418 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200182:	60e2                	ld	ra,24(sp)
ffffffffc0200184:	4512                	lw	a0,4(sp)
ffffffffc0200186:	6125                	addi	sp,sp,96
ffffffffc0200188:	8082                	ret

ffffffffc020018a <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020018a:	1101                	addi	sp,sp,-32
ffffffffc020018c:	e822                	sd	s0,16(sp)
ffffffffc020018e:	ec06                	sd	ra,24(sp)
ffffffffc0200190:	e426                	sd	s1,8(sp)
ffffffffc0200192:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200194:	00054503          	lbu	a0,0(a0)
ffffffffc0200198:	c51d                	beqz	a0,ffffffffc02001c6 <cputs+0x3c>
ffffffffc020019a:	0405                	addi	s0,s0,1
ffffffffc020019c:	4485                	li	s1,1
ffffffffc020019e:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001a0:	080000ef          	jal	ra,ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001a4:	00044503          	lbu	a0,0(s0)
ffffffffc02001a8:	008487bb          	addw	a5,s1,s0
ffffffffc02001ac:	0405                	addi	s0,s0,1
ffffffffc02001ae:	f96d                	bnez	a0,ffffffffc02001a0 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001b0:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001b4:	4529                	li	a0,10
ffffffffc02001b6:	06a000ef          	jal	ra,ffffffffc0200220 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001ba:	60e2                	ld	ra,24(sp)
ffffffffc02001bc:	8522                	mv	a0,s0
ffffffffc02001be:	6442                	ld	s0,16(sp)
ffffffffc02001c0:	64a2                	ld	s1,8(sp)
ffffffffc02001c2:	6105                	addi	sp,sp,32
ffffffffc02001c4:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001c6:	4405                	li	s0,1
ffffffffc02001c8:	b7f5                	j	ffffffffc02001b4 <cputs+0x2a>

ffffffffc02001ca <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001ca:	00006317          	auipc	t1,0x6
ffffffffc02001ce:	0b630313          	addi	t1,t1,182 # ffffffffc0206280 <is_panic>
ffffffffc02001d2:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d6:	715d                	addi	sp,sp,-80
ffffffffc02001d8:	ec06                	sd	ra,24(sp)
ffffffffc02001da:	e822                	sd	s0,16(sp)
ffffffffc02001dc:	f436                	sd	a3,40(sp)
ffffffffc02001de:	f83a                	sd	a4,48(sp)
ffffffffc02001e0:	fc3e                	sd	a5,56(sp)
ffffffffc02001e2:	e0c2                	sd	a6,64(sp)
ffffffffc02001e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e6:	000e0363          	beqz	t3,ffffffffc02001ec <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001ea:	a001                	j	ffffffffc02001ea <__panic+0x20>
    is_panic = 1;
ffffffffc02001ec:	4785                	li	a5,1
ffffffffc02001ee:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001f2:	8432                	mv	s0,a2
ffffffffc02001f4:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f6:	862e                	mv	a2,a1
ffffffffc02001f8:	85aa                	mv	a1,a0
ffffffffc02001fa:	00001517          	auipc	a0,0x1
ffffffffc02001fe:	74e50513          	addi	a0,a0,1870 # ffffffffc0201948 <etext+0xf6>
    va_start(ap, fmt);
ffffffffc0200202:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200204:	f51ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200208:	65a2                	ld	a1,8(sp)
ffffffffc020020a:	8522                	mv	a0,s0
ffffffffc020020c:	f29ff0ef          	jal	ra,ffffffffc0200134 <vcprintf>
    cprintf("\n");
ffffffffc0200210:	00002517          	auipc	a0,0x2
ffffffffc0200214:	a6050513          	addi	a0,a0,-1440 # ffffffffc0201c70 <etext+0x41e>
ffffffffc0200218:	f3dff0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc020021c:	b7f9                	j	ffffffffc02001ea <__panic+0x20>

ffffffffc020021e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200220:	0ff57513          	zext.b	a0,a0
ffffffffc0200224:	5760106f          	j	ffffffffc020179a <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020022a:	00001517          	auipc	a0,0x1
ffffffffc020022e:	73e50513          	addi	a0,a0,1854 # ffffffffc0201968 <etext+0x116>
void dtb_init(void) {
ffffffffc0200232:	fc86                	sd	ra,120(sp)
ffffffffc0200234:	f8a2                	sd	s0,112(sp)
ffffffffc0200236:	e8d2                	sd	s4,80(sp)
ffffffffc0200238:	f4a6                	sd	s1,104(sp)
ffffffffc020023a:	f0ca                	sd	s2,96(sp)
ffffffffc020023c:	ecce                	sd	s3,88(sp)
ffffffffc020023e:	e4d6                	sd	s5,72(sp)
ffffffffc0200240:	e0da                	sd	s6,64(sp)
ffffffffc0200242:	fc5e                	sd	s7,56(sp)
ffffffffc0200244:	f862                	sd	s8,48(sp)
ffffffffc0200246:	f466                	sd	s9,40(sp)
ffffffffc0200248:	f06a                	sd	s10,32(sp)
ffffffffc020024a:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020024c:	f09ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200250:	00006597          	auipc	a1,0x6
ffffffffc0200254:	db05b583          	ld	a1,-592(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200258:	00001517          	auipc	a0,0x1
ffffffffc020025c:	72050513          	addi	a0,a0,1824 # ffffffffc0201978 <etext+0x126>
ffffffffc0200260:	ef5ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200264:	00006417          	auipc	s0,0x6
ffffffffc0200268:	da440413          	addi	s0,s0,-604 # ffffffffc0206008 <boot_dtb>
ffffffffc020026c:	600c                	ld	a1,0(s0)
ffffffffc020026e:	00001517          	auipc	a0,0x1
ffffffffc0200272:	71a50513          	addi	a0,a0,1818 # ffffffffc0201988 <etext+0x136>
ffffffffc0200276:	edfff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020027a:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020027e:	00001517          	auipc	a0,0x1
ffffffffc0200282:	72250513          	addi	a0,a0,1826 # ffffffffc02019a0 <etext+0x14e>
    if (boot_dtb == 0) {
ffffffffc0200286:	120a0463          	beqz	s4,ffffffffc02003ae <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020028a:	57f5                	li	a5,-3
ffffffffc020028c:	07fa                	slli	a5,a5,0x1e
ffffffffc020028e:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200292:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200294:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020029e:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002aa:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ae:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b0:	8ec9                	or	a3,a3,a0
ffffffffc02002b2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002b6:	1b7d                	addi	s6,s6,-1
ffffffffc02002b8:	0167f7b3          	and	a5,a5,s6
ffffffffc02002bc:	8dd5                	or	a1,a1,a3
ffffffffc02002be:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002c0:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002c4:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002c6:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9c25>
ffffffffc02002ca:	10f59163          	bne	a1,a5,ffffffffc02003cc <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ce:	471c                	lw	a5,8(a4)
ffffffffc02002d0:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002d2:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d4:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d8:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002dc:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f8:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002fc:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002fe:	01146433          	or	s0,s0,a7
ffffffffc0200302:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200306:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020030a:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020030c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200310:	8c49                	or	s0,s0,a0
ffffffffc0200312:	0166f6b3          	and	a3,a3,s6
ffffffffc0200316:	00ca6a33          	or	s4,s4,a2
ffffffffc020031a:	0167f7b3          	and	a5,a5,s6
ffffffffc020031e:	8c55                	or	s0,s0,a3
ffffffffc0200320:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200324:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200326:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200328:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020032a:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020032e:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200330:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200332:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200336:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200338:	00001917          	auipc	s2,0x1
ffffffffc020033c:	6b890913          	addi	s2,s2,1720 # ffffffffc02019f0 <etext+0x19e>
ffffffffc0200340:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200342:	4d91                	li	s11,4
ffffffffc0200344:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200346:	00001497          	auipc	s1,0x1
ffffffffc020034a:	6a248493          	addi	s1,s1,1698 # ffffffffc02019e8 <etext+0x196>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020034e:	000a2703          	lw	a4,0(s4)
ffffffffc0200352:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200356:	0087569b          	srliw	a3,a4,0x8
ffffffffc020035a:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200362:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200366:	0107571b          	srliw	a4,a4,0x10
ffffffffc020036a:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020036c:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200370:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200374:	8fd5                	or	a5,a5,a3
ffffffffc0200376:	00eb7733          	and	a4,s6,a4
ffffffffc020037a:	8fd9                	or	a5,a5,a4
ffffffffc020037c:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020037e:	09778c63          	beq	a5,s7,ffffffffc0200416 <dtb_init+0x1ee>
ffffffffc0200382:	00fbea63          	bltu	s7,a5,ffffffffc0200396 <dtb_init+0x16e>
ffffffffc0200386:	07a78663          	beq	a5,s10,ffffffffc02003f2 <dtb_init+0x1ca>
ffffffffc020038a:	4709                	li	a4,2
ffffffffc020038c:	00e79763          	bne	a5,a4,ffffffffc020039a <dtb_init+0x172>
ffffffffc0200390:	4c81                	li	s9,0
ffffffffc0200392:	8a56                	mv	s4,s5
ffffffffc0200394:	bf6d                	j	ffffffffc020034e <dtb_init+0x126>
ffffffffc0200396:	ffb78ee3          	beq	a5,s11,ffffffffc0200392 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020039a:	00001517          	auipc	a0,0x1
ffffffffc020039e:	6ce50513          	addi	a0,a0,1742 # ffffffffc0201a68 <etext+0x216>
ffffffffc02003a2:	db3ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02003a6:	00001517          	auipc	a0,0x1
ffffffffc02003aa:	6fa50513          	addi	a0,a0,1786 # ffffffffc0201aa0 <etext+0x24e>
}
ffffffffc02003ae:	7446                	ld	s0,112(sp)
ffffffffc02003b0:	70e6                	ld	ra,120(sp)
ffffffffc02003b2:	74a6                	ld	s1,104(sp)
ffffffffc02003b4:	7906                	ld	s2,96(sp)
ffffffffc02003b6:	69e6                	ld	s3,88(sp)
ffffffffc02003b8:	6a46                	ld	s4,80(sp)
ffffffffc02003ba:	6aa6                	ld	s5,72(sp)
ffffffffc02003bc:	6b06                	ld	s6,64(sp)
ffffffffc02003be:	7be2                	ld	s7,56(sp)
ffffffffc02003c0:	7c42                	ld	s8,48(sp)
ffffffffc02003c2:	7ca2                	ld	s9,40(sp)
ffffffffc02003c4:	7d02                	ld	s10,32(sp)
ffffffffc02003c6:	6de2                	ld	s11,24(sp)
ffffffffc02003c8:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003ca:	b369                	j	ffffffffc0200154 <cprintf>
}
ffffffffc02003cc:	7446                	ld	s0,112(sp)
ffffffffc02003ce:	70e6                	ld	ra,120(sp)
ffffffffc02003d0:	74a6                	ld	s1,104(sp)
ffffffffc02003d2:	7906                	ld	s2,96(sp)
ffffffffc02003d4:	69e6                	ld	s3,88(sp)
ffffffffc02003d6:	6a46                	ld	s4,80(sp)
ffffffffc02003d8:	6aa6                	ld	s5,72(sp)
ffffffffc02003da:	6b06                	ld	s6,64(sp)
ffffffffc02003dc:	7be2                	ld	s7,56(sp)
ffffffffc02003de:	7c42                	ld	s8,48(sp)
ffffffffc02003e0:	7ca2                	ld	s9,40(sp)
ffffffffc02003e2:	7d02                	ld	s10,32(sp)
ffffffffc02003e4:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e6:	00001517          	auipc	a0,0x1
ffffffffc02003ea:	5da50513          	addi	a0,a0,1498 # ffffffffc02019c0 <etext+0x16e>
}
ffffffffc02003ee:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003f0:	b395                	j	ffffffffc0200154 <cprintf>
                int name_len = strlen(name);
ffffffffc02003f2:	8556                	mv	a0,s5
ffffffffc02003f4:	3c0010ef          	jal	ra,ffffffffc02017b4 <strlen>
ffffffffc02003f8:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	4619                	li	a2,6
ffffffffc02003fc:	85a6                	mv	a1,s1
ffffffffc02003fe:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200400:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200402:	418010ef          	jal	ra,ffffffffc020181a <strncmp>
ffffffffc0200406:	e111                	bnez	a0,ffffffffc020040a <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200408:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020040a:	0a91                	addi	s5,s5,4
ffffffffc020040c:	9ad2                	add	s5,s5,s4
ffffffffc020040e:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200412:	8a56                	mv	s4,s5
ffffffffc0200414:	bf2d                	j	ffffffffc020034e <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200416:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020041a:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020041e:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200422:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042a:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020042e:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200432:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200436:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020043a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020043e:	00eaeab3          	or	s5,s5,a4
ffffffffc0200442:	00fb77b3          	and	a5,s6,a5
ffffffffc0200446:	00faeab3          	or	s5,s5,a5
ffffffffc020044a:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020044c:	000c9c63          	bnez	s9,ffffffffc0200464 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200450:	1a82                	slli	s5,s5,0x20
ffffffffc0200452:	00368793          	addi	a5,a3,3
ffffffffc0200456:	020ada93          	srli	s5,s5,0x20
ffffffffc020045a:	9abe                	add	s5,s5,a5
ffffffffc020045c:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200460:	8a56                	mv	s4,s5
ffffffffc0200462:	b5f5                	j	ffffffffc020034e <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200464:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200468:	85ca                	mv	a1,s2
ffffffffc020046a:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200470:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200474:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200478:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200480:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200482:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200486:	0087979b          	slliw	a5,a5,0x8
ffffffffc020048a:	8d59                	or	a0,a0,a4
ffffffffc020048c:	00fb77b3          	and	a5,s6,a5
ffffffffc0200490:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200492:	1502                	slli	a0,a0,0x20
ffffffffc0200494:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200496:	9522                	add	a0,a0,s0
ffffffffc0200498:	364010ef          	jal	ra,ffffffffc02017fc <strcmp>
ffffffffc020049c:	66a2                	ld	a3,8(sp)
ffffffffc020049e:	f94d                	bnez	a0,ffffffffc0200450 <dtb_init+0x228>
ffffffffc02004a0:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200450 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02004a4:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a8:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004ac:	00001517          	auipc	a0,0x1
ffffffffc02004b0:	54c50513          	addi	a0,a0,1356 # ffffffffc02019f8 <etext+0x1a6>
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b8:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004bc:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c0:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004c4:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004cc:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d0:	0187d693          	srli	a3,a5,0x18
ffffffffc02004d4:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d8:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004dc:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004e4:	010f6f33          	or	t5,t5,a6
ffffffffc02004e8:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004ec:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f4:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f8:	0186f6b3          	and	a3,a3,s8
ffffffffc02004fc:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200500:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200504:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200508:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020050c:	8361                	srli	a4,a4,0x18
ffffffffc020050e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200512:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200516:	01e6e6b3          	or	a3,a3,t5
ffffffffc020051a:	00cb7633          	and	a2,s6,a2
ffffffffc020051e:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200522:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200526:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200532:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200536:	0088989b          	slliw	a7,a7,0x8
ffffffffc020053a:	011b78b3          	and	a7,s6,a7
ffffffffc020053e:	005eeeb3          	or	t4,t4,t0
ffffffffc0200542:	00c6e733          	or	a4,a3,a2
ffffffffc0200546:	006c6c33          	or	s8,s8,t1
ffffffffc020054a:	010b76b3          	and	a3,s6,a6
ffffffffc020054e:	00bb7b33          	and	s6,s6,a1
ffffffffc0200552:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200556:	016c6b33          	or	s6,s8,s6
ffffffffc020055a:	01146433          	or	s0,s0,a7
ffffffffc020055e:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200560:	1702                	slli	a4,a4,0x20
ffffffffc0200562:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200564:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200566:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200568:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020056a:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020056e:	0167eb33          	or	s6,a5,s6
ffffffffc0200572:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200574:	be1ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200578:	85a2                	mv	a1,s0
ffffffffc020057a:	00001517          	auipc	a0,0x1
ffffffffc020057e:	49e50513          	addi	a0,a0,1182 # ffffffffc0201a18 <etext+0x1c6>
ffffffffc0200582:	bd3ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200586:	014b5613          	srli	a2,s6,0x14
ffffffffc020058a:	85da                	mv	a1,s6
ffffffffc020058c:	00001517          	auipc	a0,0x1
ffffffffc0200590:	4a450513          	addi	a0,a0,1188 # ffffffffc0201a30 <etext+0x1de>
ffffffffc0200594:	bc1ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200598:	008b05b3          	add	a1,s6,s0
ffffffffc020059c:	15fd                	addi	a1,a1,-1
ffffffffc020059e:	00001517          	auipc	a0,0x1
ffffffffc02005a2:	4b250513          	addi	a0,a0,1202 # ffffffffc0201a50 <etext+0x1fe>
ffffffffc02005a6:	bafff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005aa:	00001517          	auipc	a0,0x1
ffffffffc02005ae:	4f650513          	addi	a0,a0,1270 # ffffffffc0201aa0 <etext+0x24e>
        memory_base = mem_base;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	cc87bb23          	sd	s0,-810(a5) # ffffffffc0206288 <memory_base>
        memory_size = mem_size;
ffffffffc02005ba:	00006797          	auipc	a5,0x6
ffffffffc02005be:	cd67bb23          	sd	s6,-810(a5) # ffffffffc0206290 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005c2:	b3f5                	j	ffffffffc02003ae <dtb_init+0x186>

ffffffffc02005c4 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005c4:	00006517          	auipc	a0,0x6
ffffffffc02005c8:	cc453503          	ld	a0,-828(a0) # ffffffffc0206288 <memory_base>
ffffffffc02005cc:	8082                	ret

ffffffffc02005ce <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005ce:	00006517          	auipc	a0,0x6
ffffffffc02005d2:	cc253503          	ld	a0,-830(a0) # ffffffffc0206290 <memory_size>
ffffffffc02005d6:	8082                	ret

ffffffffc02005d8 <buddy_init>:
}

static void
buddy_init(void)
{
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc02005d8:	00006717          	auipc	a4,0x6
ffffffffc02005dc:	af070713          	addi	a4,a4,-1296 # ffffffffc02060c8 <buddy_area+0xb0>
ffffffffc02005e0:	00006797          	auipc	a5,0x6
ffffffffc02005e4:	a3878793          	addi	a5,a5,-1480 # ffffffffc0206018 <buddy_area>
ffffffffc02005e8:	86ba                	mv	a3,a4
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005ea:	e79c                	sd	a5,8(a5)
ffffffffc02005ec:	e39c                	sd	a5,0(a5)
    {
        list_init(&buddy_area.free_list[i]);
        buddy_area.nr_free[i] = 0;
ffffffffc02005ee:	00072023          	sw	zero,0(a4)
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc02005f2:	07c1                	addi	a5,a5,16
ffffffffc02005f4:	0711                	addi	a4,a4,4
ffffffffc02005f6:	fed79ae3          	bne	a5,a3,ffffffffc02005ea <buddy_init+0x12>
    }
}
ffffffffc02005fa:	8082                	ret

ffffffffc02005fc <buddy_nr_free_pages>:

static size_t
buddy_nr_free_pages(void)
{
    size_t total = 0;
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc02005fc:	00006697          	auipc	a3,0x6
ffffffffc0200600:	acc68693          	addi	a3,a3,-1332 # ffffffffc02060c8 <buddy_area+0xb0>
ffffffffc0200604:	4701                	li	a4,0
    size_t total = 0;
ffffffffc0200606:	4501                	li	a0,0
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200608:	462d                	li	a2,11
    {
        total += buddy_area.nr_free[i] * (1 << i);
ffffffffc020060a:	429c                	lw	a5,0(a3)
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc020060c:	0691                	addi	a3,a3,4
        total += buddy_area.nr_free[i] * (1 << i);
ffffffffc020060e:	00e797bb          	sllw	a5,a5,a4
ffffffffc0200612:	1782                	slli	a5,a5,0x20
ffffffffc0200614:	9381                	srli	a5,a5,0x20
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200616:	2705                	addiw	a4,a4,1
        total += buddy_area.nr_free[i] * (1 << i);
ffffffffc0200618:	953e                	add	a0,a0,a5
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc020061a:	fec718e3          	bne	a4,a2,ffffffffc020060a <buddy_nr_free_pages+0xe>
    }
    return total;
}
ffffffffc020061e:	8082                	ret

ffffffffc0200620 <buddy_free_pages>:
{
ffffffffc0200620:	1141                	addi	sp,sp,-16
ffffffffc0200622:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200624:	16058463          	beqz	a1,ffffffffc020078c <buddy_free_pages+0x16c>
    while (size < n)
ffffffffc0200628:	4685                	li	a3,1
    size_t order = 0;
ffffffffc020062a:	4701                	li	a4,0
    size_t size = 1;
ffffffffc020062c:	4785                	li	a5,1
    while (size < n)
ffffffffc020062e:	00d58c63          	beq	a1,a3,ffffffffc0200646 <buddy_free_pages+0x26>
        size <<= 1;
ffffffffc0200632:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc0200634:	0705                	addi	a4,a4,1
    while (size < n)
ffffffffc0200636:	feb7eee3          	bltu	a5,a1,ffffffffc0200632 <buddy_free_pages+0x12>
    if (order >= MAX_ORDER)
ffffffffc020063a:	47a9                	li	a5,10
ffffffffc020063c:	10e7e163          	bltu	a5,a4,ffffffffc020073e <buddy_free_pages+0x11e>
    for (int i = 0; i < (1 << order); i++, p++)
ffffffffc0200640:	4605                	li	a2,1
ffffffffc0200642:	00e617bb          	sllw	a5,a2,a4
ffffffffc0200646:	00279613          	slli	a2,a5,0x2
ffffffffc020064a:	963e                	add	a2,a2,a5
ffffffffc020064c:	060e                	slli	a2,a2,0x3
ffffffffc020064e:	962a                	add	a2,a2,a0
    struct Page *p = base;
ffffffffc0200650:	87aa                	mv	a5,a0
        assert(!PageReserved(p));
ffffffffc0200652:	6794                	ld	a3,8(a5)
ffffffffc0200654:	8a85                	andi	a3,a3,1
ffffffffc0200656:	10069b63          	bnez	a3,ffffffffc020076c <buddy_free_pages+0x14c>
        p->flags = 0;
ffffffffc020065a:	0007b423          	sd	zero,8(a5)
    return KADDR(page2pa(page));
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020065e:	0007a023          	sw	zero,0(a5)
    for (int i = 0; i < (1 << order); i++, p++)
ffffffffc0200662:	02878793          	addi	a5,a5,40
ffffffffc0200666:	fec796e3          	bne	a5,a2,ffffffffc0200652 <buddy_free_pages+0x32>
    while (order < MAX_ORDER - 1)
ffffffffc020066a:	47a9                	li	a5,10
ffffffffc020066c:	0ef70463          	beq	a4,a5,ffffffffc0200754 <buddy_free_pages+0x134>
        if (buddy < pages || buddy >= pages + npage)
ffffffffc0200670:	00006797          	auipc	a5,0x6
ffffffffc0200674:	c287b783          	ld	a5,-984(a5) # ffffffffc0206298 <npage>
ffffffffc0200678:	00279e13          	slli	t3,a5,0x2
ffffffffc020067c:	9e3e                	add	t3,t3,a5
ffffffffc020067e:	02c70593          	addi	a1,a4,44
    size_t page_idx = page - pages;
ffffffffc0200682:	00006317          	auipc	t1,0x6
ffffffffc0200686:	c1e33303          	ld	t1,-994(t1) # ffffffffc02062a0 <pages>
        if (buddy < pages || buddy >= pages + npage)
ffffffffc020068a:	0e0e                	slli	t3,t3,0x3
ffffffffc020068c:	00006f17          	auipc	t5,0x6
ffffffffc0200690:	98cf0f13          	addi	t5,t5,-1652 # ffffffffc0206018 <buddy_area>
ffffffffc0200694:	058a                	slli	a1,a1,0x2
ffffffffc0200696:	9e1a                	add	t3,t3,t1
ffffffffc0200698:	95fa                	add	a1,a1,t5
ffffffffc020069a:	00002f97          	auipc	t6,0x2
ffffffffc020069e:	c4efbf83          	ld	t6,-946(t6) # ffffffffc02022e8 <error_string+0x38>
    size_t buddy_idx = page_idx ^ (1 << order);
ffffffffc02006a2:	4e85                	li	t4,1
    while (order < MAX_ORDER - 1)
ffffffffc02006a4:	42a9                	li	t0,10
ffffffffc02006a6:	a835                	j	ffffffffc02006e2 <buddy_free_pages+0xc2>
        if (buddy < pages || buddy >= pages + npage)
ffffffffc02006a8:	07c7f163          	bgeu	a5,t3,ffffffffc020070a <buddy_free_pages+0xea>
        if (!PageProperty(buddy) || buddy->property != order)
ffffffffc02006ac:	6794                	ld	a3,8(a5)
ffffffffc02006ae:	0026f613          	andi	a2,a3,2
ffffffffc02006b2:	ce21                	beqz	a2,ffffffffc020070a <buddy_free_pages+0xea>
ffffffffc02006b4:	0107e603          	lwu	a2,16(a5)
ffffffffc02006b8:	04c71963          	bne	a4,a2,ffffffffc020070a <buddy_free_pages+0xea>
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
ffffffffc02006bc:	0187b883          	ld	a7,24(a5)
ffffffffc02006c0:	7390                	ld	a2,32(a5)
        buddy_area.nr_free[order]--;
ffffffffc02006c2:	387d                	addiw	a6,a6,-1
        ClearPageProperty(buddy);
ffffffffc02006c4:	9af5                	andi	a3,a3,-3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02006c6:	00c8b423          	sd	a2,8(a7)
    next->prev = prev;
ffffffffc02006ca:	01163023          	sd	a7,0(a2) # ff0000 <kern_entry-0xffffffffbf210000>
        buddy_area.nr_free[order]--;
ffffffffc02006ce:	0105a023          	sw	a6,0(a1)
        ClearPageProperty(buddy);
ffffffffc02006d2:	e794                	sd	a3,8(a5)
        if (buddy < base)
ffffffffc02006d4:	00a7f363          	bgeu	a5,a0,ffffffffc02006da <buddy_free_pages+0xba>
ffffffffc02006d8:	853e                	mv	a0,a5
        order++;
ffffffffc02006da:	0705                	addi	a4,a4,1
    while (order < MAX_ORDER - 1)
ffffffffc02006dc:	0591                	addi	a1,a1,4
ffffffffc02006de:	06570363          	beq	a4,t0,ffffffffc0200744 <buddy_free_pages+0x124>
    size_t page_idx = page - pages;
ffffffffc02006e2:	406506b3          	sub	a3,a0,t1
ffffffffc02006e6:	868d                	srai	a3,a3,0x3
ffffffffc02006e8:	03f68633          	mul	a2,a3,t6
    size_t buddy_idx = page_idx ^ (1 << order);
ffffffffc02006ec:	00ee97bb          	sllw	a5,t4,a4
        buddy_area.nr_free[order]--;
ffffffffc02006f0:	0005a803          	lw	a6,0(a1)
ffffffffc02006f4:	0007089b          	sext.w	a7,a4
    size_t buddy_idx = page_idx ^ (1 << order);
ffffffffc02006f8:	00f646b3          	xor	a3,a2,a5
    return &pages[buddy_idx];
ffffffffc02006fc:	00269793          	slli	a5,a3,0x2
ffffffffc0200700:	97b6                	add	a5,a5,a3
ffffffffc0200702:	078e                	slli	a5,a5,0x3
ffffffffc0200704:	979a                	add	a5,a5,t1
        if (buddy < pages || buddy >= pages + npage)
ffffffffc0200706:	fa67f1e3          	bgeu	a5,t1,ffffffffc02006a8 <buddy_free_pages+0x88>
ffffffffc020070a:	00471793          	slli	a5,a4,0x4
ffffffffc020070e:	863e                	mv	a2,a5
    SetPageProperty(base);
ffffffffc0200710:	6514                	ld	a3,8(a0)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200712:	97fa                	add	a5,a5,t5
ffffffffc0200714:	678c                	ld	a1,8(a5)
ffffffffc0200716:	0026e693          	ori	a3,a3,2
ffffffffc020071a:	e514                	sd	a3,8(a0)
    base->property = order;
ffffffffc020071c:	01152823          	sw	a7,16(a0)
    list_add(&buddy_area.free_list[order], &(base->page_link));
ffffffffc0200720:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0200724:	e194                	sd	a3,0(a1)
    buddy_area.nr_free[order]++;
ffffffffc0200726:	02c70713          	addi	a4,a4,44
ffffffffc020072a:	e794                	sd	a3,8(a5)
ffffffffc020072c:	070a                	slli	a4,a4,0x2
    list_add(&buddy_area.free_list[order], &(base->page_link));
ffffffffc020072e:	00cf07b3          	add	a5,t5,a2
    elm->next = next;
ffffffffc0200732:	f10c                	sd	a1,32(a0)
    elm->prev = prev;
ffffffffc0200734:	ed1c                	sd	a5,24(a0)
    buddy_area.nr_free[order]++;
ffffffffc0200736:	977a                	add	a4,a4,t5
ffffffffc0200738:	2805                	addiw	a6,a6,1
ffffffffc020073a:	01072023          	sw	a6,0(a4)
}
ffffffffc020073e:	60a2                	ld	ra,8(sp)
ffffffffc0200740:	0141                	addi	sp,sp,16
ffffffffc0200742:	8082                	ret
    buddy_area.nr_free[order]++;
ffffffffc0200744:	0d8f2803          	lw	a6,216(t5)
ffffffffc0200748:	0a000613          	li	a2,160
ffffffffc020074c:	48a9                	li	a7,10
ffffffffc020074e:	00471793          	slli	a5,a4,0x4
ffffffffc0200752:	bf7d                	j	ffffffffc0200710 <buddy_free_pages+0xf0>
ffffffffc0200754:	00006f17          	auipc	t5,0x6
ffffffffc0200758:	8c4f0f13          	addi	t5,t5,-1852 # ffffffffc0206018 <buddy_area>
ffffffffc020075c:	0d8f2803          	lw	a6,216(t5)
ffffffffc0200760:	0a000613          	li	a2,160
ffffffffc0200764:	48a9                	li	a7,10
ffffffffc0200766:	0a000793          	li	a5,160
ffffffffc020076a:	b75d                	j	ffffffffc0200710 <buddy_free_pages+0xf0>
        assert(!PageReserved(p));
ffffffffc020076c:	00001697          	auipc	a3,0x1
ffffffffc0200770:	38468693          	addi	a3,a3,900 # ffffffffc0201af0 <etext+0x29e>
ffffffffc0200774:	00001617          	auipc	a2,0x1
ffffffffc0200778:	34c60613          	addi	a2,a2,844 # ffffffffc0201ac0 <etext+0x26e>
ffffffffc020077c:	0b900593          	li	a1,185
ffffffffc0200780:	00001517          	auipc	a0,0x1
ffffffffc0200784:	35850513          	addi	a0,a0,856 # ffffffffc0201ad8 <etext+0x286>
ffffffffc0200788:	a43ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc020078c:	00001697          	auipc	a3,0x1
ffffffffc0200790:	32c68693          	addi	a3,a3,812 # ffffffffc0201ab8 <etext+0x266>
ffffffffc0200794:	00001617          	auipc	a2,0x1
ffffffffc0200798:	32c60613          	addi	a2,a2,812 # ffffffffc0201ac0 <etext+0x26e>
ffffffffc020079c:	0ad00593          	li	a1,173
ffffffffc02007a0:	00001517          	auipc	a0,0x1
ffffffffc02007a4:	33850513          	addi	a0,a0,824 # ffffffffc0201ad8 <etext+0x286>
ffffffffc02007a8:	a23ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02007ac <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc02007ac:	c971                	beqz	a0,ffffffffc0200880 <buddy_alloc_pages+0xd4>
    while (size < n)
ffffffffc02007ae:	4705                	li	a4,1
    size_t order = 0;
ffffffffc02007b0:	4601                	li	a2,0
    size_t size = 1;
ffffffffc02007b2:	4785                	li	a5,1
    while (size < n)
ffffffffc02007b4:	00e50963          	beq	a0,a4,ffffffffc02007c6 <buddy_alloc_pages+0x1a>
        size <<= 1;
ffffffffc02007b8:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc02007ba:	0605                	addi	a2,a2,1
    while (size < n)
ffffffffc02007bc:	fea7eee3          	bltu	a5,a0,ffffffffc02007b8 <buddy_alloc_pages+0xc>
    if (order >= MAX_ORDER)
ffffffffc02007c0:	47a9                	li	a5,10
ffffffffc02007c2:	02c7e363          	bltu	a5,a2,ffffffffc02007e8 <buddy_alloc_pages+0x3c>
ffffffffc02007c6:	00006597          	auipc	a1,0x6
ffffffffc02007ca:	85258593          	addi	a1,a1,-1966 # ffffffffc0206018 <buddy_area>
ffffffffc02007ce:	00461793          	slli	a5,a2,0x4
ffffffffc02007d2:	97ae                	add	a5,a5,a1
    size_t order = 0;
ffffffffc02007d4:	8732                	mv	a4,a2
    while (cur_order < MAX_ORDER && list_empty(&buddy_area.free_list[cur_order]))
ffffffffc02007d6:	46ad                	li	a3,11
    return list->next == list;
ffffffffc02007d8:	0087b303          	ld	t1,8(a5)
ffffffffc02007dc:	00f31863          	bne	t1,a5,ffffffffc02007ec <buddy_alloc_pages+0x40>
        cur_order++;
ffffffffc02007e0:	0705                	addi	a4,a4,1
    while (cur_order < MAX_ORDER && list_empty(&buddy_area.free_list[cur_order]))
ffffffffc02007e2:	07c1                	addi	a5,a5,16
ffffffffc02007e4:	fed71ae3          	bne	a4,a3,ffffffffc02007d8 <buddy_alloc_pages+0x2c>
        return NULL;
ffffffffc02007e8:	4501                	li	a0,0
}
ffffffffc02007ea:	8082                	ret
    buddy_area.nr_free[cur_order]--;
ffffffffc02007ec:	02c70793          	addi	a5,a4,44
ffffffffc02007f0:	078a                	slli	a5,a5,0x2
    __list_del(listelm->prev, listelm->next);
ffffffffc02007f2:	00033883          	ld	a7,0(t1)
ffffffffc02007f6:	00833803          	ld	a6,8(t1)
ffffffffc02007fa:	97ae                	add	a5,a5,a1
ffffffffc02007fc:	4388                	lw	a0,0(a5)
    ClearPageProperty(page);
ffffffffc02007fe:	ff033683          	ld	a3,-16(t1)
    prev->next = next;
ffffffffc0200802:	0108b423          	sd	a6,8(a7)
    next->prev = prev;
ffffffffc0200806:	01183023          	sd	a7,0(a6)
    buddy_area.nr_free[cur_order]--;
ffffffffc020080a:	357d                	addiw	a0,a0,-1
ffffffffc020080c:	c388                	sw	a0,0(a5)
    ClearPageProperty(page);
ffffffffc020080e:	ffd6f793          	andi	a5,a3,-3
ffffffffc0200812:	fef33823          	sd	a5,-16(t1)
    struct Page *page = le2page(le, page_link);
ffffffffc0200816:	fe830513          	addi	a0,t1,-24
    while (cur_order > order)
ffffffffc020081a:	06e67063          	bgeu	a2,a4,ffffffffc020087a <buddy_alloc_pages+0xce>
ffffffffc020081e:	02b70793          	addi	a5,a4,43
ffffffffc0200822:	fff70693          	addi	a3,a4,-1
ffffffffc0200826:	00469713          	slli	a4,a3,0x4
ffffffffc020082a:	078a                	slli	a5,a5,0x2
ffffffffc020082c:	972e                	add	a4,a4,a1
        struct Page *buddy = page + (1 << cur_order);
ffffffffc020082e:	4e85                	li	t4,1
ffffffffc0200830:	95be                	add	a1,a1,a5
ffffffffc0200832:	a011                	j	ffffffffc0200836 <buddy_alloc_pages+0x8a>
ffffffffc0200834:	16fd                	addi	a3,a3,-1
ffffffffc0200836:	00de983b          	sllw	a6,t4,a3
ffffffffc020083a:	00281793          	slli	a5,a6,0x2
ffffffffc020083e:	97c2                	add	a5,a5,a6
ffffffffc0200840:	078e                	slli	a5,a5,0x3
ffffffffc0200842:	97aa                	add	a5,a5,a0
        SetPageProperty(buddy);
ffffffffc0200844:	0087b883          	ld	a7,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200848:	00873e03          	ld	t3,8(a4)
        buddy->property = cur_order;
ffffffffc020084c:	cb94                	sw	a3,16(a5)
        SetPageProperty(buddy);
ffffffffc020084e:	0028e893          	ori	a7,a7,2
        buddy_area.nr_free[cur_order]++;
ffffffffc0200852:	0005a803          	lw	a6,0(a1)
        SetPageProperty(buddy);
ffffffffc0200856:	0117b423          	sd	a7,8(a5)
        list_add(&buddy_area.free_list[cur_order], &(buddy->page_link));
ffffffffc020085a:	01878893          	addi	a7,a5,24
    prev->next = next->prev = elm;
ffffffffc020085e:	011e3023          	sd	a7,0(t3)
ffffffffc0200862:	01173423          	sd	a7,8(a4)
    elm->prev = prev;
ffffffffc0200866:	ef98                	sd	a4,24(a5)
    elm->next = next;
ffffffffc0200868:	03c7b023          	sd	t3,32(a5)
        buddy_area.nr_free[cur_order]++;
ffffffffc020086c:	0018079b          	addiw	a5,a6,1
ffffffffc0200870:	c19c                	sw	a5,0(a1)
    while (cur_order > order)
ffffffffc0200872:	1741                	addi	a4,a4,-16
ffffffffc0200874:	15f1                	addi	a1,a1,-4
ffffffffc0200876:	fad61fe3          	bne	a2,a3,ffffffffc0200834 <buddy_alloc_pages+0x88>
    page->property = order;
ffffffffc020087a:	fec32c23          	sw	a2,-8(t1)
    return page;
ffffffffc020087e:	8082                	ret
{
ffffffffc0200880:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200882:	00001697          	auipc	a3,0x1
ffffffffc0200886:	23668693          	addi	a3,a3,566 # ffffffffc0201ab8 <etext+0x266>
ffffffffc020088a:	00001617          	auipc	a2,0x1
ffffffffc020088e:	23660613          	addi	a2,a2,566 # ffffffffc0201ac0 <etext+0x26e>
ffffffffc0200892:	08000593          	li	a1,128
ffffffffc0200896:	00001517          	auipc	a0,0x1
ffffffffc020089a:	24250513          	addi	a0,a0,578 # ffffffffc0201ad8 <etext+0x286>
{
ffffffffc020089e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02008a0:	92bff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02008a4 <buddy_init_mmp>:
{
ffffffffc02008a4:	1141                	addi	sp,sp,-16
ffffffffc02008a6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02008a8:	c9f5                	beqz	a1,ffffffffc020099c <buddy_init_mmp+0xf8>
    for (; p != base + n; p++)
ffffffffc02008aa:	00259693          	slli	a3,a1,0x2
ffffffffc02008ae:	96ae                	add	a3,a3,a1
ffffffffc02008b0:	068e                	slli	a3,a3,0x3
ffffffffc02008b2:	96aa                	add	a3,a3,a0
ffffffffc02008b4:	87aa                	mv	a5,a0
ffffffffc02008b6:	00d50f63          	beq	a0,a3,ffffffffc02008d4 <buddy_init_mmp+0x30>
        assert(PageReserved(p));
ffffffffc02008ba:	6798                	ld	a4,8(a5)
ffffffffc02008bc:	8b05                	andi	a4,a4,1
ffffffffc02008be:	cf5d                	beqz	a4,ffffffffc020097c <buddy_init_mmp+0xd8>
        p->flags = 0;
ffffffffc02008c0:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc02008c4:	0007a823          	sw	zero,16(a5)
ffffffffc02008c8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02008cc:	02878793          	addi	a5,a5,40
ffffffffc02008d0:	fed795e3          	bne	a5,a3,ffffffffc02008ba <buddy_init_mmp+0x16>
ffffffffc02008d4:	00005e97          	auipc	t4,0x5
ffffffffc02008d8:	744e8e93          	addi	t4,t4,1860 # ffffffffc0206018 <buddy_area>
        while (size * 2 <= remain && order < MAX_ORDER - 1)
ffffffffc02008dc:	4f05                	li	t5,1
ffffffffc02008de:	4629                	li	a2,10
        cur += size;
ffffffffc02008e0:	00005f97          	auipc	t6,0x5
ffffffffc02008e4:	7d8f8f93          	addi	t6,t6,2008 # ffffffffc02060b8 <buddy_area+0xa0>
        size_t order = 0;
ffffffffc02008e8:	4781                	li	a5,0
ffffffffc02008ea:	4709                	li	a4,2
        while (size * 2 <= remain && order < MAX_ORDER - 1)
ffffffffc02008ec:	09e58163          	beq	a1,t5,ffffffffc020096e <buddy_init_mmp+0xca>
            size <<= 1;
ffffffffc02008f0:	86ba                	mv	a3,a4
        while (size * 2 <= remain && order < MAX_ORDER - 1)
ffffffffc02008f2:	0706                	slli	a4,a4,0x1
            order++;
ffffffffc02008f4:	0785                	addi	a5,a5,1
        while (size * 2 <= remain && order < MAX_ORDER - 1)
ffffffffc02008f6:	06e5e163          	bltu	a1,a4,ffffffffc0200958 <buddy_init_mmp+0xb4>
ffffffffc02008fa:	fec79be3          	bne	a5,a2,ffffffffc02008f0 <buddy_init_mmp+0x4c>
        cur += size;
ffffffffc02008fe:	00269713          	slli	a4,a3,0x2
ffffffffc0200902:	9736                	add	a4,a4,a3
ffffffffc0200904:	070e                	slli	a4,a4,0x3
ffffffffc0200906:	82fe                	mv	t0,t6
ffffffffc0200908:	4e29                	li	t3,10
ffffffffc020090a:	00479813          	slli	a6,a5,0x4
        SetPageProperty(cur);
ffffffffc020090e:	00853883          	ld	a7,8(a0)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200912:	9876                	add	a6,a6,t4
        buddy_area.nr_free[order]++;
ffffffffc0200914:	02c78793          	addi	a5,a5,44
ffffffffc0200918:	00883303          	ld	t1,8(a6)
ffffffffc020091c:	078a                	slli	a5,a5,0x2
ffffffffc020091e:	97f6                	add	a5,a5,t4
        SetPageProperty(cur);
ffffffffc0200920:	0028e893          	ori	a7,a7,2
        cur->property = order;
ffffffffc0200924:	01c52823          	sw	t3,16(a0)
        SetPageProperty(cur);
ffffffffc0200928:	01153423          	sd	a7,8(a0)
        list_add(&buddy_area.free_list[order], &(cur->page_link));
ffffffffc020092c:	01850e13          	addi	t3,a0,24
        buddy_area.nr_free[order]++;
ffffffffc0200930:	0007a883          	lw	a7,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200934:	01c33023          	sd	t3,0(t1)
ffffffffc0200938:	01c83423          	sd	t3,8(a6)
    elm->next = next;
ffffffffc020093c:	02653023          	sd	t1,32(a0)
    elm->prev = prev;
ffffffffc0200940:	00553c23          	sd	t0,24(a0)
ffffffffc0200944:	0018881b          	addiw	a6,a7,1
ffffffffc0200948:	0107a023          	sw	a6,0(a5)
        remain -= size;
ffffffffc020094c:	8d95                	sub	a1,a1,a3
        cur += size;
ffffffffc020094e:	953a                	add	a0,a0,a4
    while (remain > 0)
ffffffffc0200950:	fdc1                	bnez	a1,ffffffffc02008e8 <buddy_init_mmp+0x44>
}
ffffffffc0200952:	60a2                	ld	ra,8(sp)
ffffffffc0200954:	0141                	addi	sp,sp,16
ffffffffc0200956:	8082                	ret
        cur += size;
ffffffffc0200958:	00269713          	slli	a4,a3,0x2
        list_add(&buddy_area.free_list[order], &(cur->page_link));
ffffffffc020095c:	00479813          	slli	a6,a5,0x4
        cur += size;
ffffffffc0200960:	9736                	add	a4,a4,a3
        cur->property = order;
ffffffffc0200962:	00078e1b          	sext.w	t3,a5
        list_add(&buddy_area.free_list[order], &(cur->page_link));
ffffffffc0200966:	010e82b3          	add	t0,t4,a6
        cur += size;
ffffffffc020096a:	070e                	slli	a4,a4,0x3
ffffffffc020096c:	b74d                	j	ffffffffc020090e <buddy_init_mmp+0x6a>
        size_t size = 1;
ffffffffc020096e:	4685                	li	a3,1
        while (size * 2 <= remain && order < MAX_ORDER - 1)
ffffffffc0200970:	02800713          	li	a4,40
ffffffffc0200974:	82f6                	mv	t0,t4
ffffffffc0200976:	4e01                	li	t3,0
ffffffffc0200978:	4801                	li	a6,0
ffffffffc020097a:	bf51                	j	ffffffffc020090e <buddy_init_mmp+0x6a>
        assert(PageReserved(p));
ffffffffc020097c:	00001697          	auipc	a3,0x1
ffffffffc0200980:	18c68693          	addi	a3,a3,396 # ffffffffc0201b08 <etext+0x2b6>
ffffffffc0200984:	00001617          	auipc	a2,0x1
ffffffffc0200988:	13c60613          	addi	a2,a2,316 # ffffffffc0201ac0 <etext+0x26e>
ffffffffc020098c:	05c00593          	li	a1,92
ffffffffc0200990:	00001517          	auipc	a0,0x1
ffffffffc0200994:	14850513          	addi	a0,a0,328 # ffffffffc0201ad8 <etext+0x286>
ffffffffc0200998:	833ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(n > 0);
ffffffffc020099c:	00001697          	auipc	a3,0x1
ffffffffc02009a0:	11c68693          	addi	a3,a3,284 # ffffffffc0201ab8 <etext+0x266>
ffffffffc02009a4:	00001617          	auipc	a2,0x1
ffffffffc02009a8:	11c60613          	addi	a2,a2,284 # ffffffffc0201ac0 <etext+0x26e>
ffffffffc02009ac:	05600593          	li	a1,86
ffffffffc02009b0:	00001517          	auipc	a0,0x1
ffffffffc02009b4:	12850513          	addi	a0,a0,296 # ffffffffc0201ad8 <etext+0x286>
ffffffffc02009b8:	813ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02009bc <buddy_check>:

static void
buddy_check(void)
{
ffffffffc02009bc:	7175                	addi	sp,sp,-144

    // 分配和释放
    struct Page *p0, *p1, *p2;

    p0 = alloc_pages(1);
ffffffffc02009be:	4505                	li	a0,1
{
ffffffffc02009c0:	e506                	sd	ra,136(sp)
ffffffffc02009c2:	e122                	sd	s0,128(sp)
ffffffffc02009c4:	fca6                	sd	s1,120(sp)
ffffffffc02009c6:	f8ca                	sd	s2,112(sp)
ffffffffc02009c8:	f4ce                	sd	s3,104(sp)
ffffffffc02009ca:	f0d2                	sd	s4,96(sp)
ffffffffc02009cc:	ecd6                	sd	s5,88(sp)
    p0 = alloc_pages(1);
ffffffffc02009ce:	25c000ef          	jal	ra,ffffffffc0200c2a <alloc_pages>
    assert(p0 != NULL);
ffffffffc02009d2:	22050c63          	beqz	a0,ffffffffc0200c0a <buddy_check+0x24e>
ffffffffc02009d6:	892a                	mv	s2,a0

    p1 = alloc_pages(2);
ffffffffc02009d8:	4509                	li	a0,2
ffffffffc02009da:	250000ef          	jal	ra,ffffffffc0200c2a <alloc_pages>
ffffffffc02009de:	84aa                	mv	s1,a0
    assert(p1 != NULL);
ffffffffc02009e0:	20050563          	beqz	a0,ffffffffc0200bea <buddy_check+0x22e>

    p2 = alloc_pages(4);
ffffffffc02009e4:	4511                	li	a0,4
ffffffffc02009e6:	244000ef          	jal	ra,ffffffffc0200c2a <alloc_pages>
ffffffffc02009ea:	842a                	mv	s0,a0
    assert(p2 != NULL);
ffffffffc02009ec:	1a050f63          	beqz	a0,ffffffffc0200baa <buddy_check+0x1ee>

    cprintf("Allocated: p0=%p (1 page), p1=%p (2 pages), p2=%p (4 pages)\n", p0, p1, p2);
ffffffffc02009f0:	86aa                	mv	a3,a0
ffffffffc02009f2:	8626                	mv	a2,s1
ffffffffc02009f4:	85ca                	mv	a1,s2
ffffffffc02009f6:	00001517          	auipc	a0,0x1
ffffffffc02009fa:	15250513          	addi	a0,a0,338 # ffffffffc0201b48 <etext+0x2f6>
ffffffffc02009fe:	f56ff0ef          	jal	ra,ffffffffc0200154 <cprintf>

    free_pages(p0, 1);
ffffffffc0200a02:	4585                	li	a1,1
ffffffffc0200a04:	854a                	mv	a0,s2
ffffffffc0200a06:	230000ef          	jal	ra,ffffffffc0200c36 <free_pages>
    free_pages(p1, 2);
ffffffffc0200a0a:	8526                	mv	a0,s1
ffffffffc0200a0c:	4589                	li	a1,2
ffffffffc0200a0e:	228000ef          	jal	ra,ffffffffc0200c36 <free_pages>
    free_pages(p2, 4);
ffffffffc0200a12:	4591                	li	a1,4
ffffffffc0200a14:	8522                	mv	a0,s0
ffffffffc0200a16:	220000ef          	jal	ra,ffffffffc0200c36 <free_pages>

    cprintf("Freed all pages\n");
ffffffffc0200a1a:	00001517          	auipc	a0,0x1
ffffffffc0200a1e:	16e50513          	addi	a0,a0,366 # ffffffffc0201b88 <etext+0x336>
ffffffffc0200a22:	f32ff0ef          	jal	ra,ffffffffc0200154 <cprintf>

    // 测试2：合并
    p0 = alloc_pages(1);
ffffffffc0200a26:	4505                	li	a0,1
ffffffffc0200a28:	202000ef          	jal	ra,ffffffffc0200c2a <alloc_pages>
ffffffffc0200a2c:	84aa                	mv	s1,a0
    p1 = alloc_pages(1);
ffffffffc0200a2e:	4505                	li	a0,1
ffffffffc0200a30:	1fa000ef          	jal	ra,ffffffffc0200c2a <alloc_pages>

    cprintf("Allocated two 1-page blocks: p0=%p, p1=%p\n", p0, p1);
ffffffffc0200a34:	862a                	mv	a2,a0
    p1 = alloc_pages(1);
ffffffffc0200a36:	842a                	mv	s0,a0
    cprintf("Allocated two 1-page blocks: p0=%p, p1=%p\n", p0, p1);
ffffffffc0200a38:	85a6                	mv	a1,s1
ffffffffc0200a3a:	00001517          	auipc	a0,0x1
ffffffffc0200a3e:	16650513          	addi	a0,a0,358 # ffffffffc0201ba0 <etext+0x34e>
ffffffffc0200a42:	f12ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    size_t page1_idx = page1 - pages;
ffffffffc0200a46:	00006797          	auipc	a5,0x6
ffffffffc0200a4a:	85a7b783          	ld	a5,-1958(a5) # ffffffffc02062a0 <pages>
ffffffffc0200a4e:	40f485b3          	sub	a1,s1,a5
    size_t page2_idx = page2 - pages;
ffffffffc0200a52:	40f407b3          	sub	a5,s0,a5
    size_t page1_idx = page1 - pages;
ffffffffc0200a56:	00002617          	auipc	a2,0x2
ffffffffc0200a5a:	89263603          	ld	a2,-1902(a2) # ffffffffc02022e8 <error_string+0x38>
ffffffffc0200a5e:	4035d693          	srai	a3,a1,0x3
    size_t page2_idx = page2 - pages;
ffffffffc0200a62:	4037d713          	srai	a4,a5,0x3
    size_t page1_idx = page1 - pages;
ffffffffc0200a66:	02c686b3          	mul	a3,a3,a2
    size_t page2_idx = page2 - pages;
ffffffffc0200a6a:	02c70733          	mul	a4,a4,a2
    if ((page1_idx / block_size) != (page2_idx / block_size))
ffffffffc0200a6e:	0016d513          	srli	a0,a3,0x1
ffffffffc0200a72:	00175613          	srli	a2,a4,0x1
ffffffffc0200a76:	0ec50a63          	beq	a0,a2,ffffffffc0200b6a <buddy_check+0x1ae>
    if (is_buddy(p0, p1, 0))
    {
        cprintf("p0 and p1 are buddies\n");
    }

    free_pages(p0, 1);
ffffffffc0200a7a:	4585                	li	a1,1
ffffffffc0200a7c:	8526                	mv	a0,s1
ffffffffc0200a7e:	1b8000ef          	jal	ra,ffffffffc0200c36 <free_pages>
    free_pages(p1, 1);
ffffffffc0200a82:	8522                	mv	a0,s0
ffffffffc0200a84:	4585                	li	a1,1
ffffffffc0200a86:	1b0000ef          	jal	ra,ffffffffc0200c36 <free_pages>

    // 测试3：大块分配
    p0 = alloc_pages(16);
ffffffffc0200a8a:	4541                	li	a0,16
ffffffffc0200a8c:	19e000ef          	jal	ra,ffffffffc0200c2a <alloc_pages>
ffffffffc0200a90:	842a                	mv	s0,a0
    assert(p0 != NULL);
ffffffffc0200a92:	12050c63          	beqz	a0,ffffffffc0200bca <buddy_check+0x20e>
    cprintf("Allocated 16 pages: p0=%p\n", p0);
ffffffffc0200a96:	85aa                	mv	a1,a0
ffffffffc0200a98:	00001517          	auipc	a0,0x1
ffffffffc0200a9c:	15050513          	addi	a0,a0,336 # ffffffffc0201be8 <etext+0x396>
ffffffffc0200aa0:	eb4ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    free_pages(p0, 16);
ffffffffc0200aa4:	8522                	mv	a0,s0
ffffffffc0200aa6:	45c1                	li	a1,16
ffffffffc0200aa8:	840a                	mv	s0,sp
ffffffffc0200aaa:	18c000ef          	jal	ra,ffffffffc0200c36 <free_pages>

    // 测试4：碎片
    struct Page *pages_array[10];
    for (int i = 0; i < 10; i++)
ffffffffc0200aae:	05010913          	addi	s2,sp,80
    free_pages(p0, 16);
ffffffffc0200ab2:	84a2                	mv	s1,s0
    {
        pages_array[i] = alloc_pages(1);
ffffffffc0200ab4:	4505                	li	a0,1
ffffffffc0200ab6:	174000ef          	jal	ra,ffffffffc0200c2a <alloc_pages>
ffffffffc0200aba:	e088                	sd	a0,0(s1)
        assert(pages_array[i] != NULL);
ffffffffc0200abc:	c579                	beqz	a0,ffffffffc0200b8a <buddy_check+0x1ce>
    for (int i = 0; i < 10; i++)
ffffffffc0200abe:	04a1                	addi	s1,s1,8
ffffffffc0200ac0:	ff249ae3          	bne	s1,s2,ffffffffc0200ab4 <buddy_check+0xf8>
    }
    cprintf("Allocated 10 single pages\n");
ffffffffc0200ac4:	00001517          	auipc	a0,0x1
ffffffffc0200ac8:	15c50513          	addi	a0,a0,348 # ffffffffc0201c20 <etext+0x3ce>
ffffffffc0200acc:	e88ff0ef          	jal	ra,ffffffffc0200154 <cprintf>

    for (int i = 0; i < 10; i++)
    {
        free_pages(pages_array[i], 1);
ffffffffc0200ad0:	6008                	ld	a0,0(s0)
ffffffffc0200ad2:	4585                	li	a1,1
    for (int i = 0; i < 10; i++)
ffffffffc0200ad4:	0421                	addi	s0,s0,8
        free_pages(pages_array[i], 1);
ffffffffc0200ad6:	160000ef          	jal	ra,ffffffffc0200c36 <free_pages>
    for (int i = 0; i < 10; i++)
ffffffffc0200ada:	ff241be3          	bne	s0,s2,ffffffffc0200ad0 <buddy_check+0x114>
    }
    cprintf("Freed 10 single pages\n");
ffffffffc0200ade:	00001517          	auipc	a0,0x1
ffffffffc0200ae2:	16250513          	addi	a0,a0,354 # ffffffffc0201c40 <etext+0x3ee>
ffffffffc0200ae6:	e6eff0ef          	jal	ra,ffffffffc0200154 <cprintf>

    cprintf("\nFree blocks statistics:\n");
ffffffffc0200aea:	00001517          	auipc	a0,0x1
ffffffffc0200aee:	16e50513          	addi	a0,a0,366 # ffffffffc0201c58 <etext+0x406>
ffffffffc0200af2:	00005497          	auipc	s1,0x5
ffffffffc0200af6:	5d648493          	addi	s1,s1,1494 # ffffffffc02060c8 <buddy_area+0xb0>
ffffffffc0200afa:	e5aff0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc0200afe:	8926                	mv	s2,s1
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200b00:	4401                	li	s0,0
    {
        if (buddy_area.nr_free[i] > 0)
        {
            cprintf("Order %d (2^%d=%d pages): %d blocks\n",
ffffffffc0200b02:	4a85                	li	s5,1
ffffffffc0200b04:	00001a17          	auipc	s4,0x1
ffffffffc0200b08:	174a0a13          	addi	s4,s4,372 # ffffffffc0201c78 <etext+0x426>
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200b0c:	49ad                	li	s3,11
ffffffffc0200b0e:	a029                	j	ffffffffc0200b18 <buddy_check+0x15c>
ffffffffc0200b10:	2405                	addiw	s0,s0,1
ffffffffc0200b12:	0911                	addi	s2,s2,4
ffffffffc0200b14:	03340063          	beq	s0,s3,ffffffffc0200b34 <buddy_check+0x178>
        if (buddy_area.nr_free[i] > 0)
ffffffffc0200b18:	00092703          	lw	a4,0(s2)
ffffffffc0200b1c:	db75                	beqz	a4,ffffffffc0200b10 <buddy_check+0x154>
            cprintf("Order %d (2^%d=%d pages): %d blocks\n",
ffffffffc0200b1e:	008a96bb          	sllw	a3,s5,s0
ffffffffc0200b22:	8622                	mv	a2,s0
ffffffffc0200b24:	85a2                	mv	a1,s0
ffffffffc0200b26:	8552                	mv	a0,s4
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200b28:	2405                	addiw	s0,s0,1
            cprintf("Order %d (2^%d=%d pages): %d blocks\n",
ffffffffc0200b2a:	e2aff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200b2e:	0911                	addi	s2,s2,4
ffffffffc0200b30:	ff3414e3          	bne	s0,s3,ffffffffc0200b18 <buddy_check+0x15c>
    size_t total = 0;
ffffffffc0200b34:	4581                	li	a1,0
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200b36:	4701                	li	a4,0
ffffffffc0200b38:	46ad                	li	a3,11
        total += buddy_area.nr_free[i] * (1 << i);
ffffffffc0200b3a:	409c                	lw	a5,0(s1)
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200b3c:	0491                	addi	s1,s1,4
        total += buddy_area.nr_free[i] * (1 << i);
ffffffffc0200b3e:	00e797bb          	sllw	a5,a5,a4
ffffffffc0200b42:	1782                	slli	a5,a5,0x20
ffffffffc0200b44:	9381                	srli	a5,a5,0x20
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200b46:	2705                	addiw	a4,a4,1
        total += buddy_area.nr_free[i] * (1 << i);
ffffffffc0200b48:	95be                	add	a1,a1,a5
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200b4a:	fed718e3          	bne	a4,a3,ffffffffc0200b3a <buddy_check+0x17e>
        }
    }

    cprintf("Total free pages: %d\n", buddy_nr_free_pages());
    ;
}
ffffffffc0200b4e:	640a                	ld	s0,128(sp)
ffffffffc0200b50:	60aa                	ld	ra,136(sp)
ffffffffc0200b52:	74e6                	ld	s1,120(sp)
ffffffffc0200b54:	7946                	ld	s2,112(sp)
ffffffffc0200b56:	79a6                	ld	s3,104(sp)
ffffffffc0200b58:	7a06                	ld	s4,96(sp)
ffffffffc0200b5a:	6ae6                	ld	s5,88(sp)
    cprintf("Total free pages: %d\n", buddy_nr_free_pages());
ffffffffc0200b5c:	00001517          	auipc	a0,0x1
ffffffffc0200b60:	14450513          	addi	a0,a0,324 # ffffffffc0201ca0 <etext+0x44e>
}
ffffffffc0200b64:	6149                	addi	sp,sp,144
    cprintf("Total free pages: %d\n", buddy_nr_free_pages());
ffffffffc0200b66:	deeff06f          	j	ffffffffc0200154 <cprintf>
    size_t diff = page1_idx > page2_idx ? page1_idx - page2_idx : page2_idx - page1_idx;
ffffffffc0200b6a:	40d70633          	sub	a2,a4,a3
ffffffffc0200b6e:	00b7f463          	bgeu	a5,a1,ffffffffc0200b76 <buddy_check+0x1ba>
ffffffffc0200b72:	40e68633          	sub	a2,a3,a4
    if (is_buddy(p0, p1, 0))
ffffffffc0200b76:	4785                	li	a5,1
ffffffffc0200b78:	f0f611e3          	bne	a2,a5,ffffffffc0200a7a <buddy_check+0xbe>
        cprintf("p0 and p1 are buddies\n");
ffffffffc0200b7c:	00001517          	auipc	a0,0x1
ffffffffc0200b80:	05450513          	addi	a0,a0,84 # ffffffffc0201bd0 <etext+0x37e>
ffffffffc0200b84:	dd0ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc0200b88:	bdcd                	j	ffffffffc0200a7a <buddy_check+0xbe>
        assert(pages_array[i] != NULL);
ffffffffc0200b8a:	00001697          	auipc	a3,0x1
ffffffffc0200b8e:	07e68693          	addi	a3,a3,126 # ffffffffc0201c08 <etext+0x3b6>
ffffffffc0200b92:	00001617          	auipc	a2,0x1
ffffffffc0200b96:	f2e60613          	addi	a2,a2,-210 # ffffffffc0201ac0 <etext+0x26e>
ffffffffc0200b9a:	11e00593          	li	a1,286
ffffffffc0200b9e:	00001517          	auipc	a0,0x1
ffffffffc0200ba2:	f3a50513          	addi	a0,a0,-198 # ffffffffc0201ad8 <etext+0x286>
ffffffffc0200ba6:	e24ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p2 != NULL);
ffffffffc0200baa:	00001697          	auipc	a3,0x1
ffffffffc0200bae:	f8e68693          	addi	a3,a3,-114 # ffffffffc0201b38 <etext+0x2e6>
ffffffffc0200bb2:	00001617          	auipc	a2,0x1
ffffffffc0200bb6:	f0e60613          	addi	a2,a2,-242 # ffffffffc0201ac0 <etext+0x26e>
ffffffffc0200bba:	0fa00593          	li	a1,250
ffffffffc0200bbe:	00001517          	auipc	a0,0x1
ffffffffc0200bc2:	f1a50513          	addi	a0,a0,-230 # ffffffffc0201ad8 <etext+0x286>
ffffffffc0200bc6:	e04ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p0 != NULL);
ffffffffc0200bca:	00001697          	auipc	a3,0x1
ffffffffc0200bce:	f4e68693          	addi	a3,a3,-178 # ffffffffc0201b18 <etext+0x2c6>
ffffffffc0200bd2:	00001617          	auipc	a2,0x1
ffffffffc0200bd6:	eee60613          	addi	a2,a2,-274 # ffffffffc0201ac0 <etext+0x26e>
ffffffffc0200bda:	11500593          	li	a1,277
ffffffffc0200bde:	00001517          	auipc	a0,0x1
ffffffffc0200be2:	efa50513          	addi	a0,a0,-262 # ffffffffc0201ad8 <etext+0x286>
ffffffffc0200be6:	de4ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p1 != NULL);
ffffffffc0200bea:	00001697          	auipc	a3,0x1
ffffffffc0200bee:	f3e68693          	addi	a3,a3,-194 # ffffffffc0201b28 <etext+0x2d6>
ffffffffc0200bf2:	00001617          	auipc	a2,0x1
ffffffffc0200bf6:	ece60613          	addi	a2,a2,-306 # ffffffffc0201ac0 <etext+0x26e>
ffffffffc0200bfa:	0f700593          	li	a1,247
ffffffffc0200bfe:	00001517          	auipc	a0,0x1
ffffffffc0200c02:	eda50513          	addi	a0,a0,-294 # ffffffffc0201ad8 <etext+0x286>
ffffffffc0200c06:	dc4ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(p0 != NULL);
ffffffffc0200c0a:	00001697          	auipc	a3,0x1
ffffffffc0200c0e:	f0e68693          	addi	a3,a3,-242 # ffffffffc0201b18 <etext+0x2c6>
ffffffffc0200c12:	00001617          	auipc	a2,0x1
ffffffffc0200c16:	eae60613          	addi	a2,a2,-338 # ffffffffc0201ac0 <etext+0x26e>
ffffffffc0200c1a:	0f400593          	li	a1,244
ffffffffc0200c1e:	00001517          	auipc	a0,0x1
ffffffffc0200c22:	eba50513          	addi	a0,a0,-326 # ffffffffc0201ad8 <etext+0x286>
ffffffffc0200c26:	da4ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200c2a <alloc_pages>:

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n)
{
    return pmm_manager->alloc_pages(n);
ffffffffc0200c2a:	00005797          	auipc	a5,0x5
ffffffffc0200c2e:	67e7b783          	ld	a5,1662(a5) # ffffffffc02062a8 <pmm_manager>
ffffffffc0200c32:	6f9c                	ld	a5,24(a5)
ffffffffc0200c34:	8782                	jr	a5

ffffffffc0200c36 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n)
{
    pmm_manager->free_pages(base, n);
ffffffffc0200c36:	00005797          	auipc	a5,0x5
ffffffffc0200c3a:	6727b783          	ld	a5,1650(a5) # ffffffffc02062a8 <pmm_manager>
ffffffffc0200c3e:	739c                	ld	a5,32(a5)
ffffffffc0200c40:	8782                	jr	a5

ffffffffc0200c42 <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200c42:	00001797          	auipc	a5,0x1
ffffffffc0200c46:	08e78793          	addi	a5,a5,142 # ffffffffc0201cd0 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c4a:	638c                	ld	a1,0(a5)
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void)
{
ffffffffc0200c4c:	7179                	addi	sp,sp,-48
ffffffffc0200c4e:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c50:	00001517          	auipc	a0,0x1
ffffffffc0200c54:	0b850513          	addi	a0,a0,184 # ffffffffc0201d08 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200c58:	00005417          	auipc	s0,0x5
ffffffffc0200c5c:	65040413          	addi	s0,s0,1616 # ffffffffc02062a8 <pmm_manager>
{
ffffffffc0200c60:	f406                	sd	ra,40(sp)
ffffffffc0200c62:	ec26                	sd	s1,24(sp)
ffffffffc0200c64:	e44e                	sd	s3,8(sp)
ffffffffc0200c66:	e84a                	sd	s2,16(sp)
ffffffffc0200c68:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200c6a:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c6c:	ce8ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    pmm_manager->init();
ffffffffc0200c70:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200c72:	00005497          	auipc	s1,0x5
ffffffffc0200c76:	64e48493          	addi	s1,s1,1614 # ffffffffc02062c0 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200c7a:	679c                	ld	a5,8(a5)
ffffffffc0200c7c:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200c7e:	57f5                	li	a5,-3
ffffffffc0200c80:	07fa                	slli	a5,a5,0x1e
ffffffffc0200c82:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200c84:	941ff0ef          	jal	ra,ffffffffc02005c4 <get_memory_base>
ffffffffc0200c88:	89aa                	mv	s3,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0200c8a:	945ff0ef          	jal	ra,ffffffffc02005ce <get_memory_size>
    if (mem_size == 0)
ffffffffc0200c8e:	14050d63          	beqz	a0,ffffffffc0200de8 <pmm_init+0x1a6>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0200c92:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200c94:	00001517          	auipc	a0,0x1
ffffffffc0200c98:	0bc50513          	addi	a0,a0,188 # ffffffffc0201d50 <buddy_pmm_manager+0x80>
ffffffffc0200c9c:	cb8ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0200ca0:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200ca4:	864e                	mv	a2,s3
ffffffffc0200ca6:	fffa0693          	addi	a3,s4,-1
ffffffffc0200caa:	85ca                	mv	a1,s2
ffffffffc0200cac:	00001517          	auipc	a0,0x1
ffffffffc0200cb0:	0bc50513          	addi	a0,a0,188 # ffffffffc0201d68 <buddy_pmm_manager+0x98>
ffffffffc0200cb4:	ca0ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200cb8:	c80007b7          	lui	a5,0xc8000
ffffffffc0200cbc:	8652                	mv	a2,s4
ffffffffc0200cbe:	0d47e463          	bltu	a5,s4,ffffffffc0200d86 <pmm_init+0x144>
ffffffffc0200cc2:	00006797          	auipc	a5,0x6
ffffffffc0200cc6:	60578793          	addi	a5,a5,1541 # ffffffffc02072c7 <end+0xfff>
ffffffffc0200cca:	757d                	lui	a0,0xfffff
ffffffffc0200ccc:	8d7d                	and	a0,a0,a5
ffffffffc0200cce:	8231                	srli	a2,a2,0xc
ffffffffc0200cd0:	00005797          	auipc	a5,0x5
ffffffffc0200cd4:	5cc7b423          	sd	a2,1480(a5) # ffffffffc0206298 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200cd8:	00005797          	auipc	a5,0x5
ffffffffc0200cdc:	5ca7b423          	sd	a0,1480(a5) # ffffffffc02062a0 <pages>
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0200ce0:	000807b7          	lui	a5,0x80
ffffffffc0200ce4:	002005b7          	lui	a1,0x200
ffffffffc0200ce8:	02f60563          	beq	a2,a5,ffffffffc0200d12 <pmm_init+0xd0>
ffffffffc0200cec:	00261593          	slli	a1,a2,0x2
ffffffffc0200cf0:	00c586b3          	add	a3,a1,a2
ffffffffc0200cf4:	fec007b7          	lui	a5,0xfec00
ffffffffc0200cf8:	97aa                	add	a5,a5,a0
ffffffffc0200cfa:	068e                	slli	a3,a3,0x3
ffffffffc0200cfc:	96be                	add	a3,a3,a5
ffffffffc0200cfe:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc0200d00:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0200d02:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9d60>
        SetPageReserved(pages + i);
ffffffffc0200d06:	00176713          	ori	a4,a4,1
ffffffffc0200d0a:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0200d0e:	fef699e3          	bne	a3,a5,ffffffffc0200d00 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200d12:	95b2                	add	a1,a1,a2
ffffffffc0200d14:	fec006b7          	lui	a3,0xfec00
ffffffffc0200d18:	96aa                	add	a3,a3,a0
ffffffffc0200d1a:	058e                	slli	a1,a1,0x3
ffffffffc0200d1c:	96ae                	add	a3,a3,a1
ffffffffc0200d1e:	c02007b7          	lui	a5,0xc0200
ffffffffc0200d22:	0af6e763          	bltu	a3,a5,ffffffffc0200dd0 <pmm_init+0x18e>
ffffffffc0200d26:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0200d28:	77fd                	lui	a5,0xfffff
ffffffffc0200d2a:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200d2e:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end)
ffffffffc0200d30:	04b6ee63          	bltu	a3,a1,ffffffffc0200d8c <pmm_init+0x14a>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0200d34:	601c                	ld	a5,0(s0)
ffffffffc0200d36:	7b9c                	ld	a5,48(a5)
ffffffffc0200d38:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200d3a:	00001517          	auipc	a0,0x1
ffffffffc0200d3e:	0b650513          	addi	a0,a0,182 # ffffffffc0201df0 <buddy_pmm_manager+0x120>
ffffffffc0200d42:	c12ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    satp_virtual = (pte_t *)boot_page_table_sv39;
ffffffffc0200d46:	00004597          	auipc	a1,0x4
ffffffffc0200d4a:	2ba58593          	addi	a1,a1,698 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200d4e:	00005797          	auipc	a5,0x5
ffffffffc0200d52:	56b7b523          	sd	a1,1386(a5) # ffffffffc02062b8 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200d56:	c02007b7          	lui	a5,0xc0200
ffffffffc0200d5a:	0af5e363          	bltu	a1,a5,ffffffffc0200e00 <pmm_init+0x1be>
ffffffffc0200d5e:	6090                	ld	a2,0(s1)
}
ffffffffc0200d60:	7402                	ld	s0,32(sp)
ffffffffc0200d62:	70a2                	ld	ra,40(sp)
ffffffffc0200d64:	64e2                	ld	s1,24(sp)
ffffffffc0200d66:	6942                	ld	s2,16(sp)
ffffffffc0200d68:	69a2                	ld	s3,8(sp)
ffffffffc0200d6a:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200d6c:	40c58633          	sub	a2,a1,a2
ffffffffc0200d70:	00005797          	auipc	a5,0x5
ffffffffc0200d74:	54c7b023          	sd	a2,1344(a5) # ffffffffc02062b0 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200d78:	00001517          	auipc	a0,0x1
ffffffffc0200d7c:	09850513          	addi	a0,a0,152 # ffffffffc0201e10 <buddy_pmm_manager+0x140>
}
ffffffffc0200d80:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200d82:	bd2ff06f          	j	ffffffffc0200154 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200d86:	c8000637          	lui	a2,0xc8000
ffffffffc0200d8a:	bf25                	j	ffffffffc0200cc2 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200d8c:	6705                	lui	a4,0x1
ffffffffc0200d8e:	177d                	addi	a4,a4,-1
ffffffffc0200d90:	96ba                	add	a3,a3,a4
ffffffffc0200d92:	8efd                	and	a3,a3,a5
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa)
{
    if (PPN(pa) >= npage)
ffffffffc0200d94:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200d98:	02c7f063          	bgeu	a5,a2,ffffffffc0200db8 <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc0200d9c:	6010                	ld	a2,0(s0)
    {
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200d9e:	fff80737          	lui	a4,0xfff80
ffffffffc0200da2:	973e                	add	a4,a4,a5
ffffffffc0200da4:	00271793          	slli	a5,a4,0x2
ffffffffc0200da8:	97ba                	add	a5,a5,a4
ffffffffc0200daa:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200dac:	8d95                	sub	a1,a1,a3
ffffffffc0200dae:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200db0:	81b1                	srli	a1,a1,0xc
ffffffffc0200db2:	953e                	add	a0,a0,a5
ffffffffc0200db4:	9702                	jalr	a4
}
ffffffffc0200db6:	bfbd                	j	ffffffffc0200d34 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0200db8:	00001617          	auipc	a2,0x1
ffffffffc0200dbc:	00860613          	addi	a2,a2,8 # ffffffffc0201dc0 <buddy_pmm_manager+0xf0>
ffffffffc0200dc0:	07300593          	li	a1,115
ffffffffc0200dc4:	00001517          	auipc	a0,0x1
ffffffffc0200dc8:	01c50513          	addi	a0,a0,28 # ffffffffc0201de0 <buddy_pmm_manager+0x110>
ffffffffc0200dcc:	bfeff0ef          	jal	ra,ffffffffc02001ca <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200dd0:	00001617          	auipc	a2,0x1
ffffffffc0200dd4:	fc860613          	addi	a2,a2,-56 # ffffffffc0201d98 <buddy_pmm_manager+0xc8>
ffffffffc0200dd8:	06800593          	li	a1,104
ffffffffc0200ddc:	00001517          	auipc	a0,0x1
ffffffffc0200de0:	f6450513          	addi	a0,a0,-156 # ffffffffc0201d40 <buddy_pmm_manager+0x70>
ffffffffc0200de4:	be6ff0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("DTB memory info not available");
ffffffffc0200de8:	00001617          	auipc	a2,0x1
ffffffffc0200dec:	f3860613          	addi	a2,a2,-200 # ffffffffc0201d20 <buddy_pmm_manager+0x50>
ffffffffc0200df0:	04e00593          	li	a1,78
ffffffffc0200df4:	00001517          	auipc	a0,0x1
ffffffffc0200df8:	f4c50513          	addi	a0,a0,-180 # ffffffffc0201d40 <buddy_pmm_manager+0x70>
ffffffffc0200dfc:	bceff0ef          	jal	ra,ffffffffc02001ca <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200e00:	86ae                	mv	a3,a1
ffffffffc0200e02:	00001617          	auipc	a2,0x1
ffffffffc0200e06:	f9660613          	addi	a2,a2,-106 # ffffffffc0201d98 <buddy_pmm_manager+0xc8>
ffffffffc0200e0a:	08500593          	li	a1,133
ffffffffc0200e0e:	00001517          	auipc	a0,0x1
ffffffffc0200e12:	f3250513          	addi	a0,a0,-206 # ffffffffc0201d40 <buddy_pmm_manager+0x70>
ffffffffc0200e16:	bb4ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200e1a <kfree.part.0>:

    return object;
}

// 释放对象
void kfree(void *obj)
ffffffffc0200e1a:	1141                	addi	sp,sp,-16
ffffffffc0200e1c:	e406                	sd	ra,8(sp)
ffffffffc0200e1e:	e022                	sd	s0,0(sp)
    uintptr_t pa = PADDR(addr);
ffffffffc0200e20:	c02007b7          	lui	a5,0xc0200
void kfree(void *obj)
ffffffffc0200e24:	85aa                	mv	a1,a0
    uintptr_t pa = PADDR(addr);
ffffffffc0200e26:	12f56363          	bltu	a0,a5,ffffffffc0200f4c <kfree.part.0+0x132>
ffffffffc0200e2a:	00005617          	auipc	a2,0x5
ffffffffc0200e2e:	49663603          	ld	a2,1174(a2) # ffffffffc02062c0 <va_pa_offset>
ffffffffc0200e32:	40c507b3          	sub	a5,a0,a2
    if (PPN(pa) >= npage)
ffffffffc0200e36:	83b1                	srli	a5,a5,0xc
ffffffffc0200e38:	00005817          	auipc	a6,0x5
ffffffffc0200e3c:	46083803          	ld	a6,1120(a6) # ffffffffc0206298 <npage>
ffffffffc0200e40:	0f07fa63          	bgeu	a5,a6,ffffffffc0200f34 <kfree.part.0+0x11a>
    return &pages[PPN(pa) - nbase];
ffffffffc0200e44:	00001717          	auipc	a4,0x1
ffffffffc0200e48:	4ac73703          	ld	a4,1196(a4) # ffffffffc02022f0 <nbase>
ffffffffc0200e4c:	8f99                	sub	a5,a5,a4
ffffffffc0200e4e:	00279513          	slli	a0,a5,0x2
ffffffffc0200e52:	97aa                	add	a5,a5,a0
ffffffffc0200e54:	078e                	slli	a5,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e56:	00001517          	auipc	a0,0x1
ffffffffc0200e5a:	49253503          	ld	a0,1170(a0) # ffffffffc02022e8 <error_string+0x38>
ffffffffc0200e5e:	4037d693          	srai	a3,a5,0x3
ffffffffc0200e62:	02a686b3          	mul	a3,a3,a0
    return &pages[PPN(pa) - nbase];
ffffffffc0200e66:	00005517          	auipc	a0,0x5
ffffffffc0200e6a:	43a53503          	ld	a0,1082(a0) # ffffffffc02062a0 <pages>
ffffffffc0200e6e:	953e                	add	a0,a0,a5
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e70:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0200e72:	00c69713          	slli	a4,a3,0xc
ffffffffc0200e76:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e78:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0200e7a:	0b077163          	bgeu	a4,a6,ffffffffc0200f1c <kfree.part.0+0x102>
ffffffffc0200e7e:	96b2                	add	a3,a3,a2
    struct Page *page = addr_to_page(obj);
    struct slab *slab = (struct slab *)page2kva(page);

    // 找到对应cache
    struct slub_cache *cache = NULL;
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc0200e80:	00005317          	auipc	t1,0x5
ffffffffc0200e84:	27830313          	addi	t1,t1,632 # ffffffffc02060f8 <caches>
    {
        if (caches[i].object_size >= ((char *)obj - (char *)slab))
ffffffffc0200e88:	40d58833          	sub	a6,a1,a3
ffffffffc0200e8c:	871a                	mv	a4,t1
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc0200e8e:	4781                	li	a5,0
ffffffffc0200e90:	489d                	li	a7,7
        if (caches[i].object_size >= ((char *)obj - (char *)slab))
ffffffffc0200e92:	6310                	ld	a2,0(a4)
ffffffffc0200e94:	01067c63          	bgeu	a2,a6,ffffffffc0200eac <kfree.part.0+0x92>
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc0200e98:	2785                	addiw	a5,a5,1
ffffffffc0200e9a:	03870713          	addi	a4,a4,56
ffffffffc0200e9e:	ff179ae3          	bne	a5,a7,ffffffffc0200e92 <kfree.part.0+0x78>
    {
        // 从full变为partial
        list_del(&slab->slab_link);
        list_add(&cache->slabs_partial, &slab->slab_link);
    }
}
ffffffffc0200ea2:	6402                	ld	s0,0(sp)
ffffffffc0200ea4:	60a2                	ld	ra,8(sp)
        free_page(page);
ffffffffc0200ea6:	4585                	li	a1,1
}
ffffffffc0200ea8:	0141                	addi	sp,sp,16
        free_page(page);
ffffffffc0200eaa:	b371                	j	ffffffffc0200c36 <free_pages>
    *(void **)obj = slab->freelist;
ffffffffc0200eac:	0006b803          	ld	a6,0(a3) # fffffffffec00000 <end+0x3e9f9d38>
    if (slab->free_count == cache->objects_per_slab)
ffffffffc0200eb0:	00379713          	slli	a4,a5,0x3
ffffffffc0200eb4:	8f1d                	sub	a4,a4,a5
    bool was_full = (slab->free_count == 0);
ffffffffc0200eb6:	0106b883          	ld	a7,16(a3)
    slab->inuse--;
ffffffffc0200eba:	6690                	ld	a2,8(a3)
    if (slab->free_count == cache->objects_per_slab)
ffffffffc0200ebc:	070e                	slli	a4,a4,0x3
    *(void **)obj = slab->freelist;
ffffffffc0200ebe:	0105b023          	sd	a6,0(a1)
    if (slab->free_count == cache->objects_per_slab)
ffffffffc0200ec2:	00e30433          	add	s0,t1,a4
ffffffffc0200ec6:	641c                	ld	a5,8(s0)
    slab->inuse--;
ffffffffc0200ec8:	167d                	addi	a2,a2,-1
    slab->free_count++;
ffffffffc0200eca:	00188813          	addi	a6,a7,1
    slab->freelist = obj;
ffffffffc0200ece:	e28c                	sd	a1,0(a3)
    slab->inuse--;
ffffffffc0200ed0:	e690                	sd	a2,8(a3)
    slab->free_count++;
ffffffffc0200ed2:	0106b823          	sd	a6,16(a3)
    if (slab->free_count == cache->objects_per_slab)
ffffffffc0200ed6:	02f80563          	beq	a6,a5,ffffffffc0200f00 <kfree.part.0+0xe6>
    else if (was_full)
ffffffffc0200eda:	00089f63          	bnez	a7,ffffffffc0200ef8 <kfree.part.0+0xde>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200ede:	7288                	ld	a0,32(a3)
ffffffffc0200ee0:	768c                	ld	a1,40(a3)
        list_add(&cache->slabs_partial, &slab->slab_link);
ffffffffc0200ee2:	02068613          	addi	a2,a3,32
ffffffffc0200ee6:	0741                	addi	a4,a4,16
    prev->next = next;
ffffffffc0200ee8:	e50c                	sd	a1,8(a0)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200eea:	6c1c                	ld	a5,24(s0)
    next->prev = prev;
ffffffffc0200eec:	e188                	sd	a0,0(a1)
ffffffffc0200eee:	971a                	add	a4,a4,t1
    prev->next = next->prev = elm;
ffffffffc0200ef0:	e390                	sd	a2,0(a5)
ffffffffc0200ef2:	ec10                	sd	a2,24(s0)
    elm->next = next;
ffffffffc0200ef4:	f69c                	sd	a5,40(a3)
    elm->prev = prev;
ffffffffc0200ef6:	f298                	sd	a4,32(a3)
}
ffffffffc0200ef8:	60a2                	ld	ra,8(sp)
ffffffffc0200efa:	6402                	ld	s0,0(sp)
ffffffffc0200efc:	0141                	addi	sp,sp,16
ffffffffc0200efe:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0200f00:	769c                	ld	a5,40(a3)
ffffffffc0200f02:	7298                	ld	a4,32(a3)
        free_page(page);
ffffffffc0200f04:	4585                	li	a1,1
    prev->next = next;
ffffffffc0200f06:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200f08:	e398                	sd	a4,0(a5)
ffffffffc0200f0a:	d2dff0ef          	jal	ra,ffffffffc0200c36 <free_pages>
        cache->nr_slabs--;
ffffffffc0200f0e:	581c                	lw	a5,48(s0)
}
ffffffffc0200f10:	60a2                	ld	ra,8(sp)
        cache->nr_slabs--;
ffffffffc0200f12:	37fd                	addiw	a5,a5,-1
ffffffffc0200f14:	d81c                	sw	a5,48(s0)
}
ffffffffc0200f16:	6402                	ld	s0,0(sp)
ffffffffc0200f18:	0141                	addi	sp,sp,16
ffffffffc0200f1a:	8082                	ret
ffffffffc0200f1c:	00001617          	auipc	a2,0x1
ffffffffc0200f20:	f4460613          	addi	a2,a2,-188 # ffffffffc0201e60 <buddy_pmm_manager+0x190>
ffffffffc0200f24:	05d00593          	li	a1,93
ffffffffc0200f28:	00001517          	auipc	a0,0x1
ffffffffc0200f2c:	eb850513          	addi	a0,a0,-328 # ffffffffc0201de0 <buddy_pmm_manager+0x110>
ffffffffc0200f30:	a9aff0ef          	jal	ra,ffffffffc02001ca <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200f34:	00001617          	auipc	a2,0x1
ffffffffc0200f38:	e8c60613          	addi	a2,a2,-372 # ffffffffc0201dc0 <buddy_pmm_manager+0xf0>
ffffffffc0200f3c:	07300593          	li	a1,115
ffffffffc0200f40:	00001517          	auipc	a0,0x1
ffffffffc0200f44:	ea050513          	addi	a0,a0,-352 # ffffffffc0201de0 <buddy_pmm_manager+0x110>
ffffffffc0200f48:	a82ff0ef          	jal	ra,ffffffffc02001ca <__panic>
    uintptr_t pa = PADDR(addr);
ffffffffc0200f4c:	86aa                	mv	a3,a0
ffffffffc0200f4e:	00001617          	auipc	a2,0x1
ffffffffc0200f52:	e4a60613          	addi	a2,a2,-438 # ffffffffc0201d98 <buddy_pmm_manager+0xc8>
ffffffffc0200f56:	45ed                	li	a1,27
ffffffffc0200f58:	00001517          	auipc	a0,0x1
ffffffffc0200f5c:	ef850513          	addi	a0,a0,-264 # ffffffffc0201e50 <buddy_pmm_manager+0x180>
ffffffffc0200f60:	a6aff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc0200f64 <kmalloc.part.0>:
void *kmalloc(size_t size)
ffffffffc0200f64:	7139                	addi	sp,sp,-64
ffffffffc0200f66:	f822                	sd	s0,48(sp)
ffffffffc0200f68:	fc06                	sd	ra,56(sp)
ffffffffc0200f6a:	f426                	sd	s1,40(sp)
ffffffffc0200f6c:	f04a                	sd	s2,32(sp)
ffffffffc0200f6e:	ec4e                	sd	s3,24(sp)
ffffffffc0200f70:	e852                	sd	s4,16(sp)
ffffffffc0200f72:	e456                	sd	s5,8(sp)
ffffffffc0200f74:	4741                	li	a4,16
ffffffffc0200f76:	00001797          	auipc	a5,0x1
ffffffffc0200f7a:	0ea78793          	addi	a5,a5,234 # ffffffffc0202060 <size_classes>
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc0200f7e:	4401                	li	s0,0
ffffffffc0200f80:	469d                	li	a3,7
        if (size <= size_classes[i])
ffffffffc0200f82:	00a77963          	bgeu	a4,a0,ffffffffc0200f94 <kmalloc.part.0+0x30>
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc0200f86:	2405                	addiw	s0,s0,1
ffffffffc0200f88:	07a1                	addi	a5,a5,8
ffffffffc0200f8a:	12d40c63          	beq	s0,a3,ffffffffc02010c2 <kmalloc.part.0+0x15e>
        if (size <= size_classes[i])
ffffffffc0200f8e:	6398                	ld	a4,0(a5)
ffffffffc0200f90:	fea76be3          	bltu	a4,a0,ffffffffc0200f86 <kmalloc.part.0+0x22>
    if (!list_empty(&cache->slabs_partial))
ffffffffc0200f94:	00341493          	slli	s1,s0,0x3
ffffffffc0200f98:	408487b3          	sub	a5,s1,s0
ffffffffc0200f9c:	00379a93          	slli	s5,a5,0x3
    return list->next == list;
ffffffffc0200fa0:	00005a17          	auipc	s4,0x5
ffffffffc0200fa4:	158a0a13          	addi	s4,s4,344 # ffffffffc02060f8 <caches>
ffffffffc0200fa8:	015a0933          	add	s2,s4,s5
ffffffffc0200fac:	01893983          	ld	s3,24(s2)
ffffffffc0200fb0:	010a8793          	addi	a5,s5,16
ffffffffc0200fb4:	97d2                	add	a5,a5,s4
        slab = to_struct(le, struct slab, slab_link);
ffffffffc0200fb6:	fe098693          	addi	a3,s3,-32
    if (!list_empty(&cache->slabs_partial))
ffffffffc0200fba:	06f98763          	beq	s3,a5,ffffffffc0201028 <kmalloc.part.0+0xc4>
    void *object = slab->freelist;
ffffffffc0200fbe:	0006b903          	ld	s2,0(a3)
    if (object == NULL)
ffffffffc0200fc2:	14090963          	beqz	s2,ffffffffc0201114 <kmalloc.part.0+0x1b0>
    slab->inuse++;
ffffffffc0200fc6:	6698                	ld	a4,8(a3)
    slab->free_count--;
ffffffffc0200fc8:	6a9c                	ld	a5,16(a3)
    slab->freelist = *(void **)object;
ffffffffc0200fca:	00093603          	ld	a2,0(s2)
    slab->inuse++;
ffffffffc0200fce:	0705                	addi	a4,a4,1
    slab->free_count--;
ffffffffc0200fd0:	17fd                	addi	a5,a5,-1
    slab->freelist = *(void **)object;
ffffffffc0200fd2:	e290                	sd	a2,0(a3)
    slab->inuse++;
ffffffffc0200fd4:	e698                	sd	a4,8(a3)
    slab->free_count--;
ffffffffc0200fd6:	ea9c                	sd	a5,16(a3)
    if (slab->free_count == 0)
ffffffffc0200fd8:	c785                	beqz	a5,ffffffffc0201000 <kmalloc.part.0+0x9c>
    memset(object, 0, cache->object_size);
ffffffffc0200fda:	40848433          	sub	s0,s1,s0
ffffffffc0200fde:	040e                	slli	s0,s0,0x3
ffffffffc0200fe0:	9452                	add	s0,s0,s4
ffffffffc0200fe2:	6010                	ld	a2,0(s0)
ffffffffc0200fe4:	4581                	li	a1,0
ffffffffc0200fe6:	854a                	mv	a0,s2
ffffffffc0200fe8:	059000ef          	jal	ra,ffffffffc0201840 <memset>
}
ffffffffc0200fec:	70e2                	ld	ra,56(sp)
ffffffffc0200fee:	7442                	ld	s0,48(sp)
ffffffffc0200ff0:	74a2                	ld	s1,40(sp)
ffffffffc0200ff2:	69e2                	ld	s3,24(sp)
ffffffffc0200ff4:	6a42                	ld	s4,16(sp)
ffffffffc0200ff6:	6aa2                	ld	s5,8(sp)
ffffffffc0200ff8:	854a                	mv	a0,s2
ffffffffc0200ffa:	7902                	ld	s2,32(sp)
ffffffffc0200ffc:	6121                	addi	sp,sp,64
ffffffffc0200ffe:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0201000:	7290                	ld	a2,32(a3)
ffffffffc0201002:	7698                	ld	a4,40(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201004:	408487b3          	sub	a5,s1,s0
ffffffffc0201008:	078e                	slli	a5,a5,0x3
    prev->next = next;
ffffffffc020100a:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc020100c:	e310                	sd	a2,0(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc020100e:	97d2                	add	a5,a5,s4
ffffffffc0201010:	7790                	ld	a2,40(a5)
        list_add(&cache->slabs_full, &slab->slab_link);
ffffffffc0201012:	02068593          	addi	a1,a3,32
ffffffffc0201016:	020a8713          	addi	a4,s5,32
    prev->next = next->prev = elm;
ffffffffc020101a:	e20c                	sd	a1,0(a2)
ffffffffc020101c:	f78c                	sd	a1,40(a5)
ffffffffc020101e:	00ea07b3          	add	a5,s4,a4
    elm->next = next;
ffffffffc0201022:	f690                	sd	a2,40(a3)
    elm->prev = prev;
ffffffffc0201024:	f29c                	sd	a5,32(a3)
}
ffffffffc0201026:	bf55                	j	ffffffffc0200fda <kmalloc.part.0+0x76>
    struct Page *page = alloc_page();
ffffffffc0201028:	4505                	li	a0,1
ffffffffc020102a:	c01ff0ef          	jal	ra,ffffffffc0200c2a <alloc_pages>
    if (page == NULL)
ffffffffc020102e:	c16d                	beqz	a0,ffffffffc0201110 <kmalloc.part.0+0x1ac>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201030:	00005697          	auipc	a3,0x5
ffffffffc0201034:	2706b683          	ld	a3,624(a3) # ffffffffc02062a0 <pages>
ffffffffc0201038:	40d506b3          	sub	a3,a0,a3
ffffffffc020103c:	00001797          	auipc	a5,0x1
ffffffffc0201040:	2ac7b783          	ld	a5,684(a5) # ffffffffc02022e8 <error_string+0x38>
ffffffffc0201044:	868d                	srai	a3,a3,0x3
ffffffffc0201046:	02f686b3          	mul	a3,a3,a5
ffffffffc020104a:	00001797          	auipc	a5,0x1
ffffffffc020104e:	2a67b783          	ld	a5,678(a5) # ffffffffc02022f0 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201052:	00005717          	auipc	a4,0x5
ffffffffc0201056:	24673703          	ld	a4,582(a4) # ffffffffc0206298 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020105a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020105c:	00c69793          	slli	a5,a3,0xc
ffffffffc0201060:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201062:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201064:	0ae7ff63          	bgeu	a5,a4,ffffffffc0201122 <kmalloc.part.0+0x1be>
    slab->free_count = cache->objects_per_slab;
ffffffffc0201068:	00893703          	ld	a4,8(s2)
ffffffffc020106c:	00005797          	auipc	a5,0x5
ffffffffc0201070:	2547b783          	ld	a5,596(a5) # ffffffffc02062c0 <va_pa_offset>
ffffffffc0201074:	96be                	add	a3,a3,a5
    char *obj_start = (char *)slab + slab_struct_size;
ffffffffc0201076:	03068793          	addi	a5,a3,48
    slab->page = page;
ffffffffc020107a:	ee88                	sd	a0,24(a3)
    slab->inuse = 0;
ffffffffc020107c:	0006b423          	sd	zero,8(a3)
    slab->free_count = cache->objects_per_slab;
ffffffffc0201080:	ea98                	sd	a4,16(a3)
    slab->freelist = obj_start;
ffffffffc0201082:	e29c                	sd	a5,0(a3)
    for (size_t i = 0; i < cache->objects_per_slab - 1; i++)
ffffffffc0201084:	fff70513          	addi	a0,a4,-1
ffffffffc0201088:	c911                	beqz	a0,ffffffffc020109c <kmalloc.part.0+0x138>
ffffffffc020108a:	4701                	li	a4,0
        char *next = current + cache->object_size;
ffffffffc020108c:	00093583          	ld	a1,0(s2)
ffffffffc0201090:	863e                	mv	a2,a5
    for (size_t i = 0; i < cache->objects_per_slab - 1; i++)
ffffffffc0201092:	0705                	addi	a4,a4,1
        char *next = current + cache->object_size;
ffffffffc0201094:	97ae                	add	a5,a5,a1
        *(void **)current = next;
ffffffffc0201096:	e21c                	sd	a5,0(a2)
    for (size_t i = 0; i < cache->objects_per_slab - 1; i++)
ffffffffc0201098:	fea71ae3          	bne	a4,a0,ffffffffc020108c <kmalloc.part.0+0x128>
    __list_add(elm, listelm, listelm->next);
ffffffffc020109c:	40848733          	sub	a4,s1,s0
ffffffffc02010a0:	070e                	slli	a4,a4,0x3
    *(void **)current = NULL;
ffffffffc02010a2:	0007b023          	sd	zero,0(a5)
ffffffffc02010a6:	00ea07b3          	add	a5,s4,a4
ffffffffc02010aa:	6f98                	ld	a4,24(a5)
        list_add(&cache->slabs_partial, &slab->slab_link);
ffffffffc02010ac:	02068613          	addi	a2,a3,32
    prev->next = next->prev = elm;
ffffffffc02010b0:	e310                	sd	a2,0(a4)
ffffffffc02010b2:	ef90                	sd	a2,24(a5)
    elm->next = next;
ffffffffc02010b4:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc02010b6:	0336b023          	sd	s3,32(a3)
        cache->nr_slabs++;
ffffffffc02010ba:	5b98                	lw	a4,48(a5)
ffffffffc02010bc:	2705                	addiw	a4,a4,1
ffffffffc02010be:	db98                	sw	a4,48(a5)
ffffffffc02010c0:	bdfd                	j	ffffffffc0200fbe <kmalloc.part.0+0x5a>
        struct Page *page = alloc_pages(pages);
ffffffffc02010c2:	4505                	li	a0,1
ffffffffc02010c4:	b67ff0ef          	jal	ra,ffffffffc0200c2a <alloc_pages>
        return page ? page2kva(page) : NULL;
ffffffffc02010c8:	c521                	beqz	a0,ffffffffc0201110 <kmalloc.part.0+0x1ac>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02010ca:	00005797          	auipc	a5,0x5
ffffffffc02010ce:	1d67b783          	ld	a5,470(a5) # ffffffffc02062a0 <pages>
ffffffffc02010d2:	40f507b3          	sub	a5,a0,a5
ffffffffc02010d6:	00001717          	auipc	a4,0x1
ffffffffc02010da:	21273703          	ld	a4,530(a4) # ffffffffc02022e8 <error_string+0x38>
ffffffffc02010de:	878d                	srai	a5,a5,0x3
ffffffffc02010e0:	02e787b3          	mul	a5,a5,a4
ffffffffc02010e4:	00001717          	auipc	a4,0x1
ffffffffc02010e8:	20c73703          	ld	a4,524(a4) # ffffffffc02022f0 <nbase>
    return KADDR(page2pa(page));
ffffffffc02010ec:	00005617          	auipc	a2,0x5
ffffffffc02010f0:	1ac63603          	ld	a2,428(a2) # ffffffffc0206298 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02010f4:	97ba                	add	a5,a5,a4
    return KADDR(page2pa(page));
ffffffffc02010f6:	00c79713          	slli	a4,a5,0xc
ffffffffc02010fa:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02010fc:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0201100:	02c77163          	bgeu	a4,a2,ffffffffc0201122 <kmalloc.part.0+0x1be>
ffffffffc0201104:	00005917          	auipc	s2,0x5
ffffffffc0201108:	1bc93903          	ld	s2,444(s2) # ffffffffc02062c0 <va_pa_offset>
ffffffffc020110c:	9936                	add	s2,s2,a3
ffffffffc020110e:	bdf9                	j	ffffffffc0200fec <kmalloc.part.0+0x88>
            return NULL;
ffffffffc0201110:	4901                	li	s2,0
ffffffffc0201112:	bde9                	j	ffffffffc0200fec <kmalloc.part.0+0x88>
        cprintf("Error: freelist is NULL but slab is in partial list!\n");
ffffffffc0201114:	00001517          	auipc	a0,0x1
ffffffffc0201118:	d7450513          	addi	a0,a0,-652 # ffffffffc0201e88 <buddy_pmm_manager+0x1b8>
ffffffffc020111c:	838ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
        return NULL;
ffffffffc0201120:	b5f1                	j	ffffffffc0200fec <kmalloc.part.0+0x88>
ffffffffc0201122:	00001617          	auipc	a2,0x1
ffffffffc0201126:	d3e60613          	addi	a2,a2,-706 # ffffffffc0201e60 <buddy_pmm_manager+0x190>
ffffffffc020112a:	05d00593          	li	a1,93
ffffffffc020112e:	00001517          	auipc	a0,0x1
ffffffffc0201132:	cb250513          	addi	a0,a0,-846 # ffffffffc0201de0 <buddy_pmm_manager+0x110>
ffffffffc0201136:	894ff0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc020113a <slub_init>:
{
ffffffffc020113a:	7139                	addi	sp,sp,-64
    cprintf("Initializing Slabs\n");
ffffffffc020113c:	00001517          	auipc	a0,0x1
ffffffffc0201140:	d8450513          	addi	a0,a0,-636 # ffffffffc0201ec0 <buddy_pmm_manager+0x1f0>
{
ffffffffc0201144:	f822                	sd	s0,48(sp)
ffffffffc0201146:	f426                	sd	s1,40(sp)
ffffffffc0201148:	f04a                	sd	s2,32(sp)
ffffffffc020114a:	ec4e                	sd	s3,24(sp)
ffffffffc020114c:	e852                	sd	s4,16(sp)
ffffffffc020114e:	e456                	sd	s5,8(sp)
ffffffffc0201150:	fc06                	sd	ra,56(sp)
        caches[i].objects_per_slab = available / size_classes[i];
ffffffffc0201152:	6985                	lui	s3,0x1
    cprintf("Initializing Slabs\n");
ffffffffc0201154:	800ff0ef          	jal	ra,ffffffffc0200154 <cprintf>
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc0201158:	00005417          	auipc	s0,0x5
ffffffffc020115c:	fb040413          	addi	s0,s0,-80 # ffffffffc0206108 <caches+0x10>
ffffffffc0201160:	00001917          	auipc	s2,0x1
ffffffffc0201164:	f0090913          	addi	s2,s2,-256 # ffffffffc0202060 <size_classes>
    cprintf("Initializing Slabs\n");
ffffffffc0201168:	4641                	li	a2,16
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc020116a:	4481                	li	s1,0
        caches[i].objects_per_slab = available / size_classes[i];
ffffffffc020116c:	fd098993          	addi	s3,s3,-48 # fd0 <kern_entry-0xffffffffc01ff030>
        cprintf("  Size class %d: object_size=%d, objects_per_slab=%d\n",
ffffffffc0201170:	00001a97          	auipc	s5,0x1
ffffffffc0201174:	d68a8a93          	addi	s5,s5,-664 # ffffffffc0201ed8 <buddy_pmm_manager+0x208>
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc0201178:	4a1d                	li	s4,7
ffffffffc020117a:	a019                	j	ffffffffc0201180 <slub_init+0x46>
        caches[i].object_size = size_classes[i];
ffffffffc020117c:	00093603          	ld	a2,0(s2)
        caches[i].objects_per_slab = available / size_classes[i];
ffffffffc0201180:	02c9d6b3          	divu	a3,s3,a2
ffffffffc0201184:	01040793          	addi	a5,s0,16
        caches[i].object_size = size_classes[i];
ffffffffc0201188:	fec43823          	sd	a2,-16(s0)
    elm->prev = elm->next = elm;
ffffffffc020118c:	ec1c                	sd	a5,24(s0)
ffffffffc020118e:	e81c                	sd	a5,16(s0)
        caches[i].nr_slabs = 0;
ffffffffc0201190:	02042023          	sw	zero,32(s0)
ffffffffc0201194:	e400                	sd	s0,8(s0)
ffffffffc0201196:	e000                	sd	s0,0(s0)
        cprintf("  Size class %d: object_size=%d, objects_per_slab=%d\n",
ffffffffc0201198:	85a6                	mv	a1,s1
ffffffffc020119a:	8556                	mv	a0,s5
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc020119c:	2485                	addiw	s1,s1,1
ffffffffc020119e:	03840413          	addi	s0,s0,56
ffffffffc02011a2:	0921                	addi	s2,s2,8
        caches[i].objects_per_slab = available / size_classes[i];
ffffffffc02011a4:	fcd43023          	sd	a3,-64(s0)
        cprintf("  Size class %d: object_size=%d, objects_per_slab=%d\n",
ffffffffc02011a8:	fadfe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc02011ac:	fd4498e3          	bne	s1,s4,ffffffffc020117c <slub_init+0x42>
}
ffffffffc02011b0:	70e2                	ld	ra,56(sp)
ffffffffc02011b2:	7442                	ld	s0,48(sp)
ffffffffc02011b4:	74a2                	ld	s1,40(sp)
ffffffffc02011b6:	7902                	ld	s2,32(sp)
ffffffffc02011b8:	69e2                	ld	s3,24(sp)
ffffffffc02011ba:	6a42                	ld	s4,16(sp)
ffffffffc02011bc:	6aa2                	ld	s5,8(sp)
ffffffffc02011be:	6121                	addi	sp,sp,64
ffffffffc02011c0:	8082                	ret

ffffffffc02011c2 <slub_check>:

void slub_check(void)
{
ffffffffc02011c2:	712d                	addi	sp,sp,-288
    cprintf("\nSLUB Test:\n");
ffffffffc02011c4:	00001517          	auipc	a0,0x1
ffffffffc02011c8:	d4c50513          	addi	a0,a0,-692 # ffffffffc0201f10 <buddy_pmm_manager+0x240>
{
ffffffffc02011cc:	ee06                	sd	ra,280(sp)
ffffffffc02011ce:	ea22                	sd	s0,272(sp)
ffffffffc02011d0:	e626                	sd	s1,264(sp)
ffffffffc02011d2:	fdce                	sd	s3,248(sp)
ffffffffc02011d4:	e24a                	sd	s2,256(sp)
    cprintf("\nSLUB Test:\n");
ffffffffc02011d6:	f7ffe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    if (size == 0 || size > SLUB_MAX_SIZE)
ffffffffc02011da:	4541                	li	a0,16
ffffffffc02011dc:	d89ff0ef          	jal	ra,ffffffffc0200f64 <kmalloc.part.0>
ffffffffc02011e0:	842a                	mv	s0,a0
ffffffffc02011e2:	02000513          	li	a0,32
ffffffffc02011e6:	d7fff0ef          	jal	ra,ffffffffc0200f64 <kmalloc.part.0>
ffffffffc02011ea:	84aa                	mv	s1,a0
ffffffffc02011ec:	04000513          	li	a0,64
ffffffffc02011f0:	d75ff0ef          	jal	ra,ffffffffc0200f64 <kmalloc.part.0>
ffffffffc02011f4:	89aa                	mv	s3,a0
ffffffffc02011f6:	08000513          	li	a0,128
ffffffffc02011fa:	d6bff0ef          	jal	ra,ffffffffc0200f64 <kmalloc.part.0>
    void *obj1 = kmalloc(16);
    void *obj2 = kmalloc(32);
    void *obj3 = kmalloc(64);
    void *obj4 = kmalloc(128);

    assert(obj1 != NULL && obj2 != NULL && obj3 != NULL && obj4 != NULL);
ffffffffc02011fe:	18040763          	beqz	s0,ffffffffc020138c <slub_check+0x1ca>
ffffffffc0201202:	18048563          	beqz	s1,ffffffffc020138c <slub_check+0x1ca>
ffffffffc0201206:	18098363          	beqz	s3,ffffffffc020138c <slub_check+0x1ca>
ffffffffc020120a:	892a                	mv	s2,a0
ffffffffc020120c:	18050063          	beqz	a0,ffffffffc020138c <slub_check+0x1ca>
    cprintf("  Allocated: obj1=%p, obj2=%p, obj3=%p, obj4=%p\n",
ffffffffc0201210:	872a                	mv	a4,a0
ffffffffc0201212:	86ce                	mv	a3,s3
ffffffffc0201214:	8626                	mv	a2,s1
ffffffffc0201216:	85a2                	mv	a1,s0
ffffffffc0201218:	00001517          	auipc	a0,0x1
ffffffffc020121c:	d4850513          	addi	a0,a0,-696 # ffffffffc0201f60 <buddy_pmm_manager+0x290>
ffffffffc0201220:	f35fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
            obj1, obj2, obj3, obj4);

    // 使用对象

    strcpy((char *)obj1, "liuliu");
ffffffffc0201224:	00001597          	auipc	a1,0x1
ffffffffc0201228:	d7458593          	addi	a1,a1,-652 # ffffffffc0201f98 <buddy_pmm_manager+0x2c8>
ffffffffc020122c:	8522                	mv	a0,s0
ffffffffc020122e:	5bc000ef          	jal	ra,ffffffffc02017ea <strcpy>
    *(int *)obj2 = 666666;
ffffffffc0201232:	000a3637          	lui	a2,0xa3
ffffffffc0201236:	c2a60613          	addi	a2,a2,-982 # a2c2a <kern_entry-0xffffffffc015d3d6>
    cprintf("  obj1='%s', obj2=%d\n", (char *)obj1, *(int *)obj2);
ffffffffc020123a:	85a2                	mv	a1,s0
    *(int *)obj2 = 666666;
ffffffffc020123c:	c090                	sw	a2,0(s1)
    cprintf("  obj1='%s', obj2=%d\n", (char *)obj1, *(int *)obj2);
ffffffffc020123e:	00001517          	auipc	a0,0x1
ffffffffc0201242:	d6250513          	addi	a0,a0,-670 # ffffffffc0201fa0 <buddy_pmm_manager+0x2d0>
ffffffffc0201246:	f0ffe0ef          	jal	ra,ffffffffc0200154 <cprintf>

    // 释放对象
    cprintf("Free objects\n");
ffffffffc020124a:	00001517          	auipc	a0,0x1
ffffffffc020124e:	d6e50513          	addi	a0,a0,-658 # ffffffffc0201fb8 <buddy_pmm_manager+0x2e8>
ffffffffc0201252:	f03fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    if (obj == NULL)
ffffffffc0201256:	8522                	mv	a0,s0
ffffffffc0201258:	bc3ff0ef          	jal	ra,ffffffffc0200e1a <kfree.part.0>
ffffffffc020125c:	8526                	mv	a0,s1
ffffffffc020125e:	bbdff0ef          	jal	ra,ffffffffc0200e1a <kfree.part.0>
ffffffffc0201262:	854e                	mv	a0,s3
ffffffffc0201264:	bb7ff0ef          	jal	ra,ffffffffc0200e1a <kfree.part.0>
ffffffffc0201268:	854a                	mv	a0,s2
ffffffffc020126a:	bb1ff0ef          	jal	ra,ffffffffc0200e1a <kfree.part.0>
    kfree(obj1);
    kfree(obj2);
    kfree(obj3);
    kfree(obj4);
    cprintf(" freed\n");
ffffffffc020126e:	05010993          	addi	s3,sp,80
ffffffffc0201272:	00001517          	auipc	a0,0x1
ffffffffc0201276:	d5650513          	addi	a0,a0,-682 # ffffffffc0201fc8 <buddy_pmm_manager+0x2f8>
ffffffffc020127a:	edbfe0ef          	jal	ra,ffffffffc0200154 <cprintf>

    // 分配和释放

#define BATCH_SIZE 20
    void *objs[BATCH_SIZE];
    for (int i = 0; i < BATCH_SIZE; i++)
ffffffffc020127e:	844e                	mv	s0,s3
ffffffffc0201280:	0f010913          	addi	s2,sp,240
    cprintf(" freed\n");
ffffffffc0201284:	84ce                	mv	s1,s3
    if (size == 0 || size > SLUB_MAX_SIZE)
ffffffffc0201286:	04000513          	li	a0,64
ffffffffc020128a:	cdbff0ef          	jal	ra,ffffffffc0200f64 <kmalloc.part.0>
    {
        objs[i] = kmalloc(64);
ffffffffc020128e:	e088                	sd	a0,0(s1)
        assert(objs[i] != NULL);
ffffffffc0201290:	0c050e63          	beqz	a0,ffffffffc020136c <slub_check+0x1aa>
    for (int i = 0; i < BATCH_SIZE; i++)
ffffffffc0201294:	04a1                	addi	s1,s1,8
ffffffffc0201296:	ff2498e3          	bne	s1,s2,ffffffffc0201286 <slub_check+0xc4>
    }
    cprintf("  Allocated %d objects\n", BATCH_SIZE);
ffffffffc020129a:	45d1                	li	a1,20
ffffffffc020129c:	00001517          	auipc	a0,0x1
ffffffffc02012a0:	d4450513          	addi	a0,a0,-700 # ffffffffc0201fe0 <buddy_pmm_manager+0x310>
ffffffffc02012a4:	eb1fe0ef          	jal	ra,ffffffffc0200154 <cprintf>

    for (int i = 0; i < BATCH_SIZE; i++)
    {
        kfree(objs[i]);
ffffffffc02012a8:	6008                	ld	a0,0(s0)
    if (obj == NULL)
ffffffffc02012aa:	c119                	beqz	a0,ffffffffc02012b0 <slub_check+0xee>
ffffffffc02012ac:	b6fff0ef          	jal	ra,ffffffffc0200e1a <kfree.part.0>
    for (int i = 0; i < BATCH_SIZE; i++)
ffffffffc02012b0:	0421                	addi	s0,s0,8
ffffffffc02012b2:	ff241be3          	bne	s0,s2,ffffffffc02012a8 <slub_check+0xe6>
    }
    cprintf("  Freed %d objects\n", BATCH_SIZE);
ffffffffc02012b6:	45d1                	li	a1,20
ffffffffc02012b8:	00001517          	auipc	a0,0x1
ffffffffc02012bc:	d4050513          	addi	a0,a0,-704 # ffffffffc0201ff8 <buddy_pmm_manager+0x328>
ffffffffc02012c0:	840a                	mv	s0,sp
ffffffffc02012c2:	e93fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
ffffffffc02012c6:	84a2                	mv	s1,s0
    if (size == 0 || size > SLUB_MAX_SIZE)
ffffffffc02012c8:	4541                	li	a0,16
ffffffffc02012ca:	c9bff0ef          	jal	ra,ffffffffc0200f64 <kmalloc.part.0>

    // 碎片
    void *small[10];
    for (int i = 0; i < 10; i++)
    {
        small[i] = kmalloc(16);
ffffffffc02012ce:	e088                	sd	a0,0(s1)
    for (int i = 0; i < 10; i++)
ffffffffc02012d0:	04a1                	addi	s1,s1,8
ffffffffc02012d2:	ff349be3          	bne	s1,s3,ffffffffc02012c8 <slub_check+0x106>
ffffffffc02012d6:	84a2                	mv	s1,s0
    }

    // 释放一半
    for (int i = 0; i < 5; i++)
    {
        kfree(small[i * 2]);
ffffffffc02012d8:	6088                	ld	a0,0(s1)
    if (obj == NULL)
ffffffffc02012da:	c119                	beqz	a0,ffffffffc02012e0 <slub_check+0x11e>
ffffffffc02012dc:	b3fff0ef          	jal	ra,ffffffffc0200e1a <kfree.part.0>
    for (int i = 0; i < 5; i++)
ffffffffc02012e0:	04c1                	addi	s1,s1,16
ffffffffc02012e2:	ff349be3          	bne	s1,s3,ffffffffc02012d8 <slub_check+0x116>
ffffffffc02012e6:	84a2                	mv	s1,s0
    if (size == 0 || size > SLUB_MAX_SIZE)
ffffffffc02012e8:	4541                	li	a0,16
ffffffffc02012ea:	c7bff0ef          	jal	ra,ffffffffc0200f64 <kmalloc.part.0>
    }

    // 再分配
    for (int i = 0; i < 5; i++)
    {
        small[i * 2] = kmalloc(16);
ffffffffc02012ee:	e088                	sd	a0,0(s1)
    for (int i = 0; i < 5; i++)
ffffffffc02012f0:	04c1                	addi	s1,s1,16
ffffffffc02012f2:	ff349be3          	bne	s1,s3,ffffffffc02012e8 <slub_check+0x126>
    }

    // 全部释放
    for (int i = 0; i < 10; i++)
    {
        kfree(small[i]);
ffffffffc02012f6:	6008                	ld	a0,0(s0)
    if (obj == NULL)
ffffffffc02012f8:	c119                	beqz	a0,ffffffffc02012fe <slub_check+0x13c>
ffffffffc02012fa:	b21ff0ef          	jal	ra,ffffffffc0200e1a <kfree.part.0>
    for (int i = 0; i < 10; i++)
ffffffffc02012fe:	0421                	addi	s0,s0,8
ffffffffc0201300:	ff341be3          	bne	s0,s3,ffffffffc02012f6 <slub_check+0x134>
    }
    cprintf("  Fragmentation test passed\n");
ffffffffc0201304:	00001517          	auipc	a0,0x1
ffffffffc0201308:	d0c50513          	addi	a0,a0,-756 # ffffffffc0202010 <buddy_pmm_manager+0x340>
ffffffffc020130c:	e49fe0ef          	jal	ra,ffffffffc0200154 <cprintf>

    cprintf("\nSLUB Statistics:\n");
ffffffffc0201310:	00001517          	auipc	a0,0x1
ffffffffc0201314:	d2050513          	addi	a0,a0,-736 # ffffffffc0202030 <buddy_pmm_manager+0x360>
ffffffffc0201318:	e3dfe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc020131c:	00005417          	auipc	s0,0x5
ffffffffc0201320:	ddc40413          	addi	s0,s0,-548 # ffffffffc02060f8 <caches>
ffffffffc0201324:	00001497          	auipc	s1,0x1
ffffffffc0201328:	d3c48493          	addi	s1,s1,-708 # ffffffffc0202060 <size_classes>
ffffffffc020132c:	00005917          	auipc	s2,0x5
ffffffffc0201330:	f5490913          	addi	s2,s2,-172 # ffffffffc0206280 <is_panic>
    {
        if (caches[i].nr_slabs > 0)
        {
            cprintf("  Size %d: %d slabs\n",
ffffffffc0201334:	00001997          	auipc	s3,0x1
ffffffffc0201338:	d1498993          	addi	s3,s3,-748 # ffffffffc0202048 <buddy_pmm_manager+0x378>
ffffffffc020133c:	a031                	j	ffffffffc0201348 <slub_check+0x186>
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc020133e:	03840413          	addi	s0,s0,56
ffffffffc0201342:	04a1                	addi	s1,s1,8
ffffffffc0201344:	01240d63          	beq	s0,s2,ffffffffc020135e <slub_check+0x19c>
        if (caches[i].nr_slabs > 0)
ffffffffc0201348:	5810                	lw	a2,48(s0)
ffffffffc020134a:	da75                	beqz	a2,ffffffffc020133e <slub_check+0x17c>
            cprintf("  Size %d: %d slabs\n",
ffffffffc020134c:	608c                	ld	a1,0(s1)
ffffffffc020134e:	854e                	mv	a0,s3
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc0201350:	03840413          	addi	s0,s0,56
            cprintf("  Size %d: %d slabs\n",
ffffffffc0201354:	e01fe0ef          	jal	ra,ffffffffc0200154 <cprintf>
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc0201358:	04a1                	addi	s1,s1,8
ffffffffc020135a:	ff2417e3          	bne	s0,s2,ffffffffc0201348 <slub_check+0x186>
                    size_classes[i], caches[i].nr_slabs);
        }
    }
}
ffffffffc020135e:	60f2                	ld	ra,280(sp)
ffffffffc0201360:	6452                	ld	s0,272(sp)
ffffffffc0201362:	64b2                	ld	s1,264(sp)
ffffffffc0201364:	6912                	ld	s2,256(sp)
ffffffffc0201366:	79ee                	ld	s3,248(sp)
ffffffffc0201368:	6115                	addi	sp,sp,288
ffffffffc020136a:	8082                	ret
        assert(objs[i] != NULL);
ffffffffc020136c:	00001697          	auipc	a3,0x1
ffffffffc0201370:	c6468693          	addi	a3,a3,-924 # ffffffffc0201fd0 <buddy_pmm_manager+0x300>
ffffffffc0201374:	00000617          	auipc	a2,0x0
ffffffffc0201378:	74c60613          	addi	a2,a2,1868 # ffffffffc0201ac0 <etext+0x26e>
ffffffffc020137c:	0ed00593          	li	a1,237
ffffffffc0201380:	00001517          	auipc	a0,0x1
ffffffffc0201384:	ad050513          	addi	a0,a0,-1328 # ffffffffc0201e50 <buddy_pmm_manager+0x180>
ffffffffc0201388:	e43fe0ef          	jal	ra,ffffffffc02001ca <__panic>
    assert(obj1 != NULL && obj2 != NULL && obj3 != NULL && obj4 != NULL);
ffffffffc020138c:	00001697          	auipc	a3,0x1
ffffffffc0201390:	b9468693          	addi	a3,a3,-1132 # ffffffffc0201f20 <buddy_pmm_manager+0x250>
ffffffffc0201394:	00000617          	auipc	a2,0x0
ffffffffc0201398:	72c60613          	addi	a2,a2,1836 # ffffffffc0201ac0 <etext+0x26e>
ffffffffc020139c:	0d400593          	li	a1,212
ffffffffc02013a0:	00001517          	auipc	a0,0x1
ffffffffc02013a4:	ab050513          	addi	a0,a0,-1360 # ffffffffc0201e50 <buddy_pmm_manager+0x180>
ffffffffc02013a8:	e23fe0ef          	jal	ra,ffffffffc02001ca <__panic>

ffffffffc02013ac <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02013ac:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02013b0:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02013b2:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02013b6:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02013b8:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02013bc:	f022                	sd	s0,32(sp)
ffffffffc02013be:	ec26                	sd	s1,24(sp)
ffffffffc02013c0:	e84a                	sd	s2,16(sp)
ffffffffc02013c2:	f406                	sd	ra,40(sp)
ffffffffc02013c4:	e44e                	sd	s3,8(sp)
ffffffffc02013c6:	84aa                	mv	s1,a0
ffffffffc02013c8:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02013ca:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02013ce:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02013d0:	03067e63          	bgeu	a2,a6,ffffffffc020140c <printnum+0x60>
ffffffffc02013d4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02013d6:	00805763          	blez	s0,ffffffffc02013e4 <printnum+0x38>
ffffffffc02013da:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02013dc:	85ca                	mv	a1,s2
ffffffffc02013de:	854e                	mv	a0,s3
ffffffffc02013e0:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02013e2:	fc65                	bnez	s0,ffffffffc02013da <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02013e4:	1a02                	slli	s4,s4,0x20
ffffffffc02013e6:	00001797          	auipc	a5,0x1
ffffffffc02013ea:	cba78793          	addi	a5,a5,-838 # ffffffffc02020a0 <size_classes+0x40>
ffffffffc02013ee:	020a5a13          	srli	s4,s4,0x20
ffffffffc02013f2:	9a3e                	add	s4,s4,a5
}
ffffffffc02013f4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02013f6:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02013fa:	70a2                	ld	ra,40(sp)
ffffffffc02013fc:	69a2                	ld	s3,8(sp)
ffffffffc02013fe:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201400:	85ca                	mv	a1,s2
ffffffffc0201402:	87a6                	mv	a5,s1
}
ffffffffc0201404:	6942                	ld	s2,16(sp)
ffffffffc0201406:	64e2                	ld	s1,24(sp)
ffffffffc0201408:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020140a:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020140c:	03065633          	divu	a2,a2,a6
ffffffffc0201410:	8722                	mv	a4,s0
ffffffffc0201412:	f9bff0ef          	jal	ra,ffffffffc02013ac <printnum>
ffffffffc0201416:	b7f9                	j	ffffffffc02013e4 <printnum+0x38>

ffffffffc0201418 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201418:	7119                	addi	sp,sp,-128
ffffffffc020141a:	f4a6                	sd	s1,104(sp)
ffffffffc020141c:	f0ca                	sd	s2,96(sp)
ffffffffc020141e:	ecce                	sd	s3,88(sp)
ffffffffc0201420:	e8d2                	sd	s4,80(sp)
ffffffffc0201422:	e4d6                	sd	s5,72(sp)
ffffffffc0201424:	e0da                	sd	s6,64(sp)
ffffffffc0201426:	fc5e                	sd	s7,56(sp)
ffffffffc0201428:	f06a                	sd	s10,32(sp)
ffffffffc020142a:	fc86                	sd	ra,120(sp)
ffffffffc020142c:	f8a2                	sd	s0,112(sp)
ffffffffc020142e:	f862                	sd	s8,48(sp)
ffffffffc0201430:	f466                	sd	s9,40(sp)
ffffffffc0201432:	ec6e                	sd	s11,24(sp)
ffffffffc0201434:	892a                	mv	s2,a0
ffffffffc0201436:	84ae                	mv	s1,a1
ffffffffc0201438:	8d32                	mv	s10,a2
ffffffffc020143a:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020143c:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201440:	5b7d                	li	s6,-1
ffffffffc0201442:	00001a97          	auipc	s5,0x1
ffffffffc0201446:	c92a8a93          	addi	s5,s5,-878 # ffffffffc02020d4 <size_classes+0x74>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020144a:	00001b97          	auipc	s7,0x1
ffffffffc020144e:	e66b8b93          	addi	s7,s7,-410 # ffffffffc02022b0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201452:	000d4503          	lbu	a0,0(s10)
ffffffffc0201456:	001d0413          	addi	s0,s10,1
ffffffffc020145a:	01350a63          	beq	a0,s3,ffffffffc020146e <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020145e:	c121                	beqz	a0,ffffffffc020149e <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201460:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201462:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201464:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201466:	fff44503          	lbu	a0,-1(s0)
ffffffffc020146a:	ff351ae3          	bne	a0,s3,ffffffffc020145e <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020146e:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201472:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201476:	4c81                	li	s9,0
ffffffffc0201478:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020147a:	5c7d                	li	s8,-1
ffffffffc020147c:	5dfd                	li	s11,-1
ffffffffc020147e:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201482:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201484:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201488:	0ff5f593          	zext.b	a1,a1
ffffffffc020148c:	00140d13          	addi	s10,s0,1
ffffffffc0201490:	04b56263          	bltu	a0,a1,ffffffffc02014d4 <vprintfmt+0xbc>
ffffffffc0201494:	058a                	slli	a1,a1,0x2
ffffffffc0201496:	95d6                	add	a1,a1,s5
ffffffffc0201498:	4194                	lw	a3,0(a1)
ffffffffc020149a:	96d6                	add	a3,a3,s5
ffffffffc020149c:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020149e:	70e6                	ld	ra,120(sp)
ffffffffc02014a0:	7446                	ld	s0,112(sp)
ffffffffc02014a2:	74a6                	ld	s1,104(sp)
ffffffffc02014a4:	7906                	ld	s2,96(sp)
ffffffffc02014a6:	69e6                	ld	s3,88(sp)
ffffffffc02014a8:	6a46                	ld	s4,80(sp)
ffffffffc02014aa:	6aa6                	ld	s5,72(sp)
ffffffffc02014ac:	6b06                	ld	s6,64(sp)
ffffffffc02014ae:	7be2                	ld	s7,56(sp)
ffffffffc02014b0:	7c42                	ld	s8,48(sp)
ffffffffc02014b2:	7ca2                	ld	s9,40(sp)
ffffffffc02014b4:	7d02                	ld	s10,32(sp)
ffffffffc02014b6:	6de2                	ld	s11,24(sp)
ffffffffc02014b8:	6109                	addi	sp,sp,128
ffffffffc02014ba:	8082                	ret
            padc = '0';
ffffffffc02014bc:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02014be:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014c2:	846a                	mv	s0,s10
ffffffffc02014c4:	00140d13          	addi	s10,s0,1
ffffffffc02014c8:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02014cc:	0ff5f593          	zext.b	a1,a1
ffffffffc02014d0:	fcb572e3          	bgeu	a0,a1,ffffffffc0201494 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02014d4:	85a6                	mv	a1,s1
ffffffffc02014d6:	02500513          	li	a0,37
ffffffffc02014da:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02014dc:	fff44783          	lbu	a5,-1(s0)
ffffffffc02014e0:	8d22                	mv	s10,s0
ffffffffc02014e2:	f73788e3          	beq	a5,s3,ffffffffc0201452 <vprintfmt+0x3a>
ffffffffc02014e6:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02014ea:	1d7d                	addi	s10,s10,-1
ffffffffc02014ec:	ff379de3          	bne	a5,s3,ffffffffc02014e6 <vprintfmt+0xce>
ffffffffc02014f0:	b78d                	j	ffffffffc0201452 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02014f2:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02014f6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014fa:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02014fc:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201500:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201504:	02d86463          	bltu	a6,a3,ffffffffc020152c <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201508:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020150c:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201510:	0186873b          	addw	a4,a3,s8
ffffffffc0201514:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201518:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020151a:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020151e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201520:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201524:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201528:	fed870e3          	bgeu	a6,a3,ffffffffc0201508 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020152c:	f40ddce3          	bgez	s11,ffffffffc0201484 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201530:	8de2                	mv	s11,s8
ffffffffc0201532:	5c7d                	li	s8,-1
ffffffffc0201534:	bf81                	j	ffffffffc0201484 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201536:	fffdc693          	not	a3,s11
ffffffffc020153a:	96fd                	srai	a3,a3,0x3f
ffffffffc020153c:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201540:	00144603          	lbu	a2,1(s0)
ffffffffc0201544:	2d81                	sext.w	s11,s11
ffffffffc0201546:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201548:	bf35                	j	ffffffffc0201484 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020154a:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020154e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201552:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201554:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201556:	bfd9                	j	ffffffffc020152c <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201558:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020155a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020155e:	01174463          	blt	a4,a7,ffffffffc0201566 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201562:	1a088e63          	beqz	a7,ffffffffc020171e <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201566:	000a3603          	ld	a2,0(s4)
ffffffffc020156a:	46c1                	li	a3,16
ffffffffc020156c:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020156e:	2781                	sext.w	a5,a5
ffffffffc0201570:	876e                	mv	a4,s11
ffffffffc0201572:	85a6                	mv	a1,s1
ffffffffc0201574:	854a                	mv	a0,s2
ffffffffc0201576:	e37ff0ef          	jal	ra,ffffffffc02013ac <printnum>
            break;
ffffffffc020157a:	bde1                	j	ffffffffc0201452 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020157c:	000a2503          	lw	a0,0(s4)
ffffffffc0201580:	85a6                	mv	a1,s1
ffffffffc0201582:	0a21                	addi	s4,s4,8
ffffffffc0201584:	9902                	jalr	s2
            break;
ffffffffc0201586:	b5f1                	j	ffffffffc0201452 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201588:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020158a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020158e:	01174463          	blt	a4,a7,ffffffffc0201596 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201592:	18088163          	beqz	a7,ffffffffc0201714 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201596:	000a3603          	ld	a2,0(s4)
ffffffffc020159a:	46a9                	li	a3,10
ffffffffc020159c:	8a2e                	mv	s4,a1
ffffffffc020159e:	bfc1                	j	ffffffffc020156e <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015a0:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02015a4:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015a6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02015a8:	bdf1                	j	ffffffffc0201484 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02015aa:	85a6                	mv	a1,s1
ffffffffc02015ac:	02500513          	li	a0,37
ffffffffc02015b0:	9902                	jalr	s2
            break;
ffffffffc02015b2:	b545                	j	ffffffffc0201452 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015b4:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02015b8:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015ba:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02015bc:	b5e1                	j	ffffffffc0201484 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02015be:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02015c0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02015c4:	01174463          	blt	a4,a7,ffffffffc02015cc <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02015c8:	14088163          	beqz	a7,ffffffffc020170a <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02015cc:	000a3603          	ld	a2,0(s4)
ffffffffc02015d0:	46a1                	li	a3,8
ffffffffc02015d2:	8a2e                	mv	s4,a1
ffffffffc02015d4:	bf69                	j	ffffffffc020156e <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02015d6:	03000513          	li	a0,48
ffffffffc02015da:	85a6                	mv	a1,s1
ffffffffc02015dc:	e03e                	sd	a5,0(sp)
ffffffffc02015de:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02015e0:	85a6                	mv	a1,s1
ffffffffc02015e2:	07800513          	li	a0,120
ffffffffc02015e6:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02015e8:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02015ea:	6782                	ld	a5,0(sp)
ffffffffc02015ec:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02015ee:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02015f2:	bfb5                	j	ffffffffc020156e <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02015f4:	000a3403          	ld	s0,0(s4)
ffffffffc02015f8:	008a0713          	addi	a4,s4,8
ffffffffc02015fc:	e03a                	sd	a4,0(sp)
ffffffffc02015fe:	14040263          	beqz	s0,ffffffffc0201742 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201602:	0fb05763          	blez	s11,ffffffffc02016f0 <vprintfmt+0x2d8>
ffffffffc0201606:	02d00693          	li	a3,45
ffffffffc020160a:	0cd79163          	bne	a5,a3,ffffffffc02016cc <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020160e:	00044783          	lbu	a5,0(s0)
ffffffffc0201612:	0007851b          	sext.w	a0,a5
ffffffffc0201616:	cf85                	beqz	a5,ffffffffc020164e <vprintfmt+0x236>
ffffffffc0201618:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020161c:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201620:	000c4563          	bltz	s8,ffffffffc020162a <vprintfmt+0x212>
ffffffffc0201624:	3c7d                	addiw	s8,s8,-1
ffffffffc0201626:	036c0263          	beq	s8,s6,ffffffffc020164a <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020162a:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020162c:	0e0c8e63          	beqz	s9,ffffffffc0201728 <vprintfmt+0x310>
ffffffffc0201630:	3781                	addiw	a5,a5,-32
ffffffffc0201632:	0ef47b63          	bgeu	s0,a5,ffffffffc0201728 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201636:	03f00513          	li	a0,63
ffffffffc020163a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020163c:	000a4783          	lbu	a5,0(s4)
ffffffffc0201640:	3dfd                	addiw	s11,s11,-1
ffffffffc0201642:	0a05                	addi	s4,s4,1
ffffffffc0201644:	0007851b          	sext.w	a0,a5
ffffffffc0201648:	ffe1                	bnez	a5,ffffffffc0201620 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020164a:	01b05963          	blez	s11,ffffffffc020165c <vprintfmt+0x244>
ffffffffc020164e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201650:	85a6                	mv	a1,s1
ffffffffc0201652:	02000513          	li	a0,32
ffffffffc0201656:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201658:	fe0d9be3          	bnez	s11,ffffffffc020164e <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020165c:	6a02                	ld	s4,0(sp)
ffffffffc020165e:	bbd5                	j	ffffffffc0201452 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201660:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201662:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201666:	01174463          	blt	a4,a7,ffffffffc020166e <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020166a:	08088d63          	beqz	a7,ffffffffc0201704 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020166e:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201672:	0a044d63          	bltz	s0,ffffffffc020172c <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201676:	8622                	mv	a2,s0
ffffffffc0201678:	8a66                	mv	s4,s9
ffffffffc020167a:	46a9                	li	a3,10
ffffffffc020167c:	bdcd                	j	ffffffffc020156e <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020167e:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201682:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201684:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201686:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020168a:	8fb5                	xor	a5,a5,a3
ffffffffc020168c:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201690:	02d74163          	blt	a4,a3,ffffffffc02016b2 <vprintfmt+0x29a>
ffffffffc0201694:	00369793          	slli	a5,a3,0x3
ffffffffc0201698:	97de                	add	a5,a5,s7
ffffffffc020169a:	639c                	ld	a5,0(a5)
ffffffffc020169c:	cb99                	beqz	a5,ffffffffc02016b2 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020169e:	86be                	mv	a3,a5
ffffffffc02016a0:	00001617          	auipc	a2,0x1
ffffffffc02016a4:	a3060613          	addi	a2,a2,-1488 # ffffffffc02020d0 <size_classes+0x70>
ffffffffc02016a8:	85a6                	mv	a1,s1
ffffffffc02016aa:	854a                	mv	a0,s2
ffffffffc02016ac:	0ce000ef          	jal	ra,ffffffffc020177a <printfmt>
ffffffffc02016b0:	b34d                	j	ffffffffc0201452 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02016b2:	00001617          	auipc	a2,0x1
ffffffffc02016b6:	a0e60613          	addi	a2,a2,-1522 # ffffffffc02020c0 <size_classes+0x60>
ffffffffc02016ba:	85a6                	mv	a1,s1
ffffffffc02016bc:	854a                	mv	a0,s2
ffffffffc02016be:	0bc000ef          	jal	ra,ffffffffc020177a <printfmt>
ffffffffc02016c2:	bb41                	j	ffffffffc0201452 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02016c4:	00001417          	auipc	s0,0x1
ffffffffc02016c8:	9f440413          	addi	s0,s0,-1548 # ffffffffc02020b8 <size_classes+0x58>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02016cc:	85e2                	mv	a1,s8
ffffffffc02016ce:	8522                	mv	a0,s0
ffffffffc02016d0:	e43e                	sd	a5,8(sp)
ffffffffc02016d2:	0fc000ef          	jal	ra,ffffffffc02017ce <strnlen>
ffffffffc02016d6:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02016da:	01b05b63          	blez	s11,ffffffffc02016f0 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02016de:	67a2                	ld	a5,8(sp)
ffffffffc02016e0:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02016e4:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02016e6:	85a6                	mv	a1,s1
ffffffffc02016e8:	8552                	mv	a0,s4
ffffffffc02016ea:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02016ec:	fe0d9ce3          	bnez	s11,ffffffffc02016e4 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016f0:	00044783          	lbu	a5,0(s0)
ffffffffc02016f4:	00140a13          	addi	s4,s0,1
ffffffffc02016f8:	0007851b          	sext.w	a0,a5
ffffffffc02016fc:	d3a5                	beqz	a5,ffffffffc020165c <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016fe:	05e00413          	li	s0,94
ffffffffc0201702:	bf39                	j	ffffffffc0201620 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201704:	000a2403          	lw	s0,0(s4)
ffffffffc0201708:	b7ad                	j	ffffffffc0201672 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020170a:	000a6603          	lwu	a2,0(s4)
ffffffffc020170e:	46a1                	li	a3,8
ffffffffc0201710:	8a2e                	mv	s4,a1
ffffffffc0201712:	bdb1                	j	ffffffffc020156e <vprintfmt+0x156>
ffffffffc0201714:	000a6603          	lwu	a2,0(s4)
ffffffffc0201718:	46a9                	li	a3,10
ffffffffc020171a:	8a2e                	mv	s4,a1
ffffffffc020171c:	bd89                	j	ffffffffc020156e <vprintfmt+0x156>
ffffffffc020171e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201722:	46c1                	li	a3,16
ffffffffc0201724:	8a2e                	mv	s4,a1
ffffffffc0201726:	b5a1                	j	ffffffffc020156e <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201728:	9902                	jalr	s2
ffffffffc020172a:	bf09                	j	ffffffffc020163c <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020172c:	85a6                	mv	a1,s1
ffffffffc020172e:	02d00513          	li	a0,45
ffffffffc0201732:	e03e                	sd	a5,0(sp)
ffffffffc0201734:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201736:	6782                	ld	a5,0(sp)
ffffffffc0201738:	8a66                	mv	s4,s9
ffffffffc020173a:	40800633          	neg	a2,s0
ffffffffc020173e:	46a9                	li	a3,10
ffffffffc0201740:	b53d                	j	ffffffffc020156e <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201742:	03b05163          	blez	s11,ffffffffc0201764 <vprintfmt+0x34c>
ffffffffc0201746:	02d00693          	li	a3,45
ffffffffc020174a:	f6d79de3          	bne	a5,a3,ffffffffc02016c4 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020174e:	00001417          	auipc	s0,0x1
ffffffffc0201752:	96a40413          	addi	s0,s0,-1686 # ffffffffc02020b8 <size_classes+0x58>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201756:	02800793          	li	a5,40
ffffffffc020175a:	02800513          	li	a0,40
ffffffffc020175e:	00140a13          	addi	s4,s0,1
ffffffffc0201762:	bd6d                	j	ffffffffc020161c <vprintfmt+0x204>
ffffffffc0201764:	00001a17          	auipc	s4,0x1
ffffffffc0201768:	955a0a13          	addi	s4,s4,-1707 # ffffffffc02020b9 <size_classes+0x59>
ffffffffc020176c:	02800513          	li	a0,40
ffffffffc0201770:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201774:	05e00413          	li	s0,94
ffffffffc0201778:	b565                	j	ffffffffc0201620 <vprintfmt+0x208>

ffffffffc020177a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020177a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020177c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201780:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201782:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201784:	ec06                	sd	ra,24(sp)
ffffffffc0201786:	f83a                	sd	a4,48(sp)
ffffffffc0201788:	fc3e                	sd	a5,56(sp)
ffffffffc020178a:	e0c2                	sd	a6,64(sp)
ffffffffc020178c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020178e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201790:	c89ff0ef          	jal	ra,ffffffffc0201418 <vprintfmt>
}
ffffffffc0201794:	60e2                	ld	ra,24(sp)
ffffffffc0201796:	6161                	addi	sp,sp,80
ffffffffc0201798:	8082                	ret

ffffffffc020179a <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020179a:	4781                	li	a5,0
ffffffffc020179c:	00005717          	auipc	a4,0x5
ffffffffc02017a0:	87473703          	ld	a4,-1932(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc02017a4:	88ba                	mv	a7,a4
ffffffffc02017a6:	852a                	mv	a0,a0
ffffffffc02017a8:	85be                	mv	a1,a5
ffffffffc02017aa:	863e                	mv	a2,a5
ffffffffc02017ac:	00000073          	ecall
ffffffffc02017b0:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02017b2:	8082                	ret

ffffffffc02017b4 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02017b4:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02017b8:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02017ba:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02017bc:	cb81                	beqz	a5,ffffffffc02017cc <strlen+0x18>
        cnt ++;
ffffffffc02017be:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02017c0:	00a707b3          	add	a5,a4,a0
ffffffffc02017c4:	0007c783          	lbu	a5,0(a5)
ffffffffc02017c8:	fbfd                	bnez	a5,ffffffffc02017be <strlen+0xa>
ffffffffc02017ca:	8082                	ret
    }
    return cnt;
}
ffffffffc02017cc:	8082                	ret

ffffffffc02017ce <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02017ce:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02017d0:	e589                	bnez	a1,ffffffffc02017da <strnlen+0xc>
ffffffffc02017d2:	a811                	j	ffffffffc02017e6 <strnlen+0x18>
        cnt ++;
ffffffffc02017d4:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02017d6:	00f58863          	beq	a1,a5,ffffffffc02017e6 <strnlen+0x18>
ffffffffc02017da:	00f50733          	add	a4,a0,a5
ffffffffc02017de:	00074703          	lbu	a4,0(a4)
ffffffffc02017e2:	fb6d                	bnez	a4,ffffffffc02017d4 <strnlen+0x6>
ffffffffc02017e4:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02017e6:	852e                	mv	a0,a1
ffffffffc02017e8:	8082                	ret

ffffffffc02017ea <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02017ea:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02017ec:	0005c703          	lbu	a4,0(a1)
ffffffffc02017f0:	0785                	addi	a5,a5,1
ffffffffc02017f2:	0585                	addi	a1,a1,1
ffffffffc02017f4:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02017f8:	fb75                	bnez	a4,ffffffffc02017ec <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02017fa:	8082                	ret

ffffffffc02017fc <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02017fc:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201800:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201804:	cb89                	beqz	a5,ffffffffc0201816 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201806:	0505                	addi	a0,a0,1
ffffffffc0201808:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020180a:	fee789e3          	beq	a5,a4,ffffffffc02017fc <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020180e:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201812:	9d19                	subw	a0,a0,a4
ffffffffc0201814:	8082                	ret
ffffffffc0201816:	4501                	li	a0,0
ffffffffc0201818:	bfed                	j	ffffffffc0201812 <strcmp+0x16>

ffffffffc020181a <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020181a:	c20d                	beqz	a2,ffffffffc020183c <strncmp+0x22>
ffffffffc020181c:	962e                	add	a2,a2,a1
ffffffffc020181e:	a031                	j	ffffffffc020182a <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201820:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201822:	00e79a63          	bne	a5,a4,ffffffffc0201836 <strncmp+0x1c>
ffffffffc0201826:	00b60b63          	beq	a2,a1,ffffffffc020183c <strncmp+0x22>
ffffffffc020182a:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020182e:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201830:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201834:	f7f5                	bnez	a5,ffffffffc0201820 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201836:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020183a:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020183c:	4501                	li	a0,0
ffffffffc020183e:	8082                	ret

ffffffffc0201840 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201840:	ca01                	beqz	a2,ffffffffc0201850 <memset+0x10>
ffffffffc0201842:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201844:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201846:	0785                	addi	a5,a5,1
ffffffffc0201848:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020184c:	fec79de3          	bne	a5,a2,ffffffffc0201846 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201850:	8082                	ret
