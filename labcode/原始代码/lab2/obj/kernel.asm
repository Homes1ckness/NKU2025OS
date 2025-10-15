
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00005297          	auipc	t0,0x5
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0205000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00005297          	auipc	t0,0x5
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0205008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02042b7          	lui	t0,0xc0204
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
ffffffffc020003c:	c0204137          	lui	sp,0xc0204

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	60c50513          	addi	a0,a0,1548 # ffffffffc0201658 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	61650513          	addi	a0,a0,1558 # ffffffffc0201678 <etext+0x22>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	5e858593          	addi	a1,a1,1512 # ffffffffc0201656 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	62250513          	addi	a0,a0,1570 # ffffffffc0201698 <etext+0x42>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	62e50513          	addi	a0,a0,1582 # ffffffffc02016b8 <etext+0x62>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0205078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	63a50513          	addi	a0,a0,1594 # ffffffffc02016d8 <etext+0x82>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00005597          	auipc	a1,0x5
ffffffffc02000ae:	3cd58593          	addi	a1,a1,973 # ffffffffc0205477 <end+0x3ff>
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
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	62c50513          	addi	a0,a0,1580 # ffffffffc02016f8 <etext+0xa2>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00005517          	auipc	a0,0x5
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0205018 <free_area>
ffffffffc02000e0:	00005617          	auipc	a2,0x5
ffffffffc02000e4:	f9860613          	addi	a2,a2,-104 # ffffffffc0205078 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	14c010ef          	jal	ra,ffffffffc020123c <memset>
    dtb_init();
ffffffffc02000f4:	122000ef          	jal	ra,ffffffffc0200216 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	4ce000ef          	jal	ra,ffffffffc02005c6 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	62c50513          	addi	a0,a0,1580 # ffffffffc0201728 <etext+0xd2>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	4e8000ef          	jal	ra,ffffffffc02005f4 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	4ae000ef          	jal	ra,ffffffffc02005c8 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	17a010ef          	jal	ra,ffffffffc02012ba <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0204028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	144010ef          	jal	ra,ffffffffc02012ba <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	430000ef          	jal	ra,ffffffffc02005c8 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	41a000ef          	jal	ra,ffffffffc02005c8 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00005317          	auipc	t1,0x5
ffffffffc02001c6:	e6e30313          	addi	t1,t1,-402 # ffffffffc0205030 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	55650513          	addi	a0,a0,1366 # ffffffffc0201748 <etext+0xf2>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00001517          	auipc	a0,0x1
ffffffffc020020c:	51850513          	addi	a0,a0,1304 # ffffffffc0201720 <etext+0xca>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200216:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200218:	00001517          	auipc	a0,0x1
ffffffffc020021c:	55050513          	addi	a0,a0,1360 # ffffffffc0201768 <etext+0x112>
void dtb_init(void) {
ffffffffc0200220:	fc86                	sd	ra,120(sp)
ffffffffc0200222:	f8a2                	sd	s0,112(sp)
ffffffffc0200224:	e8d2                	sd	s4,80(sp)
ffffffffc0200226:	f4a6                	sd	s1,104(sp)
ffffffffc0200228:	f0ca                	sd	s2,96(sp)
ffffffffc020022a:	ecce                	sd	s3,88(sp)
ffffffffc020022c:	e4d6                	sd	s5,72(sp)
ffffffffc020022e:	e0da                	sd	s6,64(sp)
ffffffffc0200230:	fc5e                	sd	s7,56(sp)
ffffffffc0200232:	f862                	sd	s8,48(sp)
ffffffffc0200234:	f466                	sd	s9,40(sp)
ffffffffc0200236:	f06a                	sd	s10,32(sp)
ffffffffc0200238:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020023a:	f13ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023e:	00005597          	auipc	a1,0x5
ffffffffc0200242:	dc25b583          	ld	a1,-574(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200246:	00001517          	auipc	a0,0x1
ffffffffc020024a:	53250513          	addi	a0,a0,1330 # ffffffffc0201778 <etext+0x122>
ffffffffc020024e:	effff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200252:	00005417          	auipc	s0,0x5
ffffffffc0200256:	db640413          	addi	s0,s0,-586 # ffffffffc0205008 <boot_dtb>
ffffffffc020025a:	600c                	ld	a1,0(s0)
ffffffffc020025c:	00001517          	auipc	a0,0x1
ffffffffc0200260:	52c50513          	addi	a0,a0,1324 # ffffffffc0201788 <etext+0x132>
ffffffffc0200264:	ee9ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200268:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026c:	00001517          	auipc	a0,0x1
ffffffffc0200270:	53450513          	addi	a0,a0,1332 # ffffffffc02017a0 <etext+0x14a>
    if (boot_dtb == 0) {
ffffffffc0200274:	120a0463          	beqz	s4,ffffffffc020039c <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200278:	57f5                	li	a5,-3
ffffffffc020027a:	07fa                	slli	a5,a5,0x1e
ffffffffc020027c:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200280:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200282:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200286:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200288:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020028c:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200294:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029c:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029e:	8ec9                	or	a3,a3,a0
ffffffffc02002a0:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002a4:	1b7d                	addi	s6,s6,-1
ffffffffc02002a6:	0167f7b3          	and	a5,a5,s6
ffffffffc02002aa:	8dd5                	or	a1,a1,a3
ffffffffc02002ac:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002ae:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b2:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002b4:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfedae75>
ffffffffc02002b8:	10f59163          	bne	a1,a5,ffffffffc02003ba <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002bc:	471c                	lw	a5,8(a4)
ffffffffc02002be:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002c0:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c2:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002c6:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002ca:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ce:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d2:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002da:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002de:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e2:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e6:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ea:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ec:	01146433          	or	s0,s0,a7
ffffffffc02002f0:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002f4:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f8:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002fa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002fe:	8c49                	or	s0,s0,a0
ffffffffc0200300:	0166f6b3          	and	a3,a3,s6
ffffffffc0200304:	00ca6a33          	or	s4,s4,a2
ffffffffc0200308:	0167f7b3          	and	a5,a5,s6
ffffffffc020030c:	8c55                	or	s0,s0,a3
ffffffffc020030e:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200312:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200314:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200316:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200318:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200320:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200324:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200326:	00001917          	auipc	s2,0x1
ffffffffc020032a:	4ca90913          	addi	s2,s2,1226 # ffffffffc02017f0 <etext+0x19a>
ffffffffc020032e:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200330:	4d91                	li	s11,4
ffffffffc0200332:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200334:	00001497          	auipc	s1,0x1
ffffffffc0200338:	4b448493          	addi	s1,s1,1204 # ffffffffc02017e8 <etext+0x192>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033c:	000a2703          	lw	a4,0(s4)
ffffffffc0200340:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200344:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200348:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020034c:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200350:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200354:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200358:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200362:	8fd5                	or	a5,a5,a3
ffffffffc0200364:	00eb7733          	and	a4,s6,a4
ffffffffc0200368:	8fd9                	or	a5,a5,a4
ffffffffc020036a:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020036c:	09778c63          	beq	a5,s7,ffffffffc0200404 <dtb_init+0x1ee>
ffffffffc0200370:	00fbea63          	bltu	s7,a5,ffffffffc0200384 <dtb_init+0x16e>
ffffffffc0200374:	07a78663          	beq	a5,s10,ffffffffc02003e0 <dtb_init+0x1ca>
ffffffffc0200378:	4709                	li	a4,2
ffffffffc020037a:	00e79763          	bne	a5,a4,ffffffffc0200388 <dtb_init+0x172>
ffffffffc020037e:	4c81                	li	s9,0
ffffffffc0200380:	8a56                	mv	s4,s5
ffffffffc0200382:	bf6d                	j	ffffffffc020033c <dtb_init+0x126>
ffffffffc0200384:	ffb78ee3          	beq	a5,s11,ffffffffc0200380 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200388:	00001517          	auipc	a0,0x1
ffffffffc020038c:	4e050513          	addi	a0,a0,1248 # ffffffffc0201868 <etext+0x212>
ffffffffc0200390:	dbdff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200394:	00001517          	auipc	a0,0x1
ffffffffc0200398:	50c50513          	addi	a0,a0,1292 # ffffffffc02018a0 <etext+0x24a>
}
ffffffffc020039c:	7446                	ld	s0,112(sp)
ffffffffc020039e:	70e6                	ld	ra,120(sp)
ffffffffc02003a0:	74a6                	ld	s1,104(sp)
ffffffffc02003a2:	7906                	ld	s2,96(sp)
ffffffffc02003a4:	69e6                	ld	s3,88(sp)
ffffffffc02003a6:	6a46                	ld	s4,80(sp)
ffffffffc02003a8:	6aa6                	ld	s5,72(sp)
ffffffffc02003aa:	6b06                	ld	s6,64(sp)
ffffffffc02003ac:	7be2                	ld	s7,56(sp)
ffffffffc02003ae:	7c42                	ld	s8,48(sp)
ffffffffc02003b0:	7ca2                	ld	s9,40(sp)
ffffffffc02003b2:	7d02                	ld	s10,32(sp)
ffffffffc02003b4:	6de2                	ld	s11,24(sp)
ffffffffc02003b6:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003b8:	bb51                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003ba:	7446                	ld	s0,112(sp)
ffffffffc02003bc:	70e6                	ld	ra,120(sp)
ffffffffc02003be:	74a6                	ld	s1,104(sp)
ffffffffc02003c0:	7906                	ld	s2,96(sp)
ffffffffc02003c2:	69e6                	ld	s3,88(sp)
ffffffffc02003c4:	6a46                	ld	s4,80(sp)
ffffffffc02003c6:	6aa6                	ld	s5,72(sp)
ffffffffc02003c8:	6b06                	ld	s6,64(sp)
ffffffffc02003ca:	7be2                	ld	s7,56(sp)
ffffffffc02003cc:	7c42                	ld	s8,48(sp)
ffffffffc02003ce:	7ca2                	ld	s9,40(sp)
ffffffffc02003d0:	7d02                	ld	s10,32(sp)
ffffffffc02003d2:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003d4:	00001517          	auipc	a0,0x1
ffffffffc02003d8:	3ec50513          	addi	a0,a0,1004 # ffffffffc02017c0 <etext+0x16a>
}
ffffffffc02003dc:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	b3bd                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003e0:	8556                	mv	a0,s5
ffffffffc02003e2:	5e1000ef          	jal	ra,ffffffffc02011c2 <strlen>
ffffffffc02003e6:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e8:	4619                	li	a2,6
ffffffffc02003ea:	85a6                	mv	a1,s1
ffffffffc02003ec:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003ee:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f0:	627000ef          	jal	ra,ffffffffc0201216 <strncmp>
ffffffffc02003f4:	e111                	bnez	a0,ffffffffc02003f8 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02003f6:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003f8:	0a91                	addi	s5,s5,4
ffffffffc02003fa:	9ad2                	add	s5,s5,s4
ffffffffc02003fc:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200400:	8a56                	mv	s4,s5
ffffffffc0200402:	bf2d                	j	ffffffffc020033c <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200404:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200408:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040c:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200410:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200414:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200418:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041c:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200420:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200424:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200428:	0087979b          	slliw	a5,a5,0x8
ffffffffc020042c:	00eaeab3          	or	s5,s5,a4
ffffffffc0200430:	00fb77b3          	and	a5,s6,a5
ffffffffc0200434:	00faeab3          	or	s5,s5,a5
ffffffffc0200438:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020043a:	000c9c63          	bnez	s9,ffffffffc0200452 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020043e:	1a82                	slli	s5,s5,0x20
ffffffffc0200440:	00368793          	addi	a5,a3,3
ffffffffc0200444:	020ada93          	srli	s5,s5,0x20
ffffffffc0200448:	9abe                	add	s5,s5,a5
ffffffffc020044a:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020044e:	8a56                	mv	s4,s5
ffffffffc0200450:	b5f5                	j	ffffffffc020033c <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200452:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200456:	85ca                	mv	a1,s2
ffffffffc0200458:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020045a:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020045e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200462:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200466:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020046a:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020046e:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200470:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200478:	8d59                	or	a0,a0,a4
ffffffffc020047a:	00fb77b3          	and	a5,s6,a5
ffffffffc020047e:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200480:	1502                	slli	a0,a0,0x20
ffffffffc0200482:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200484:	9522                	add	a0,a0,s0
ffffffffc0200486:	573000ef          	jal	ra,ffffffffc02011f8 <strcmp>
ffffffffc020048a:	66a2                	ld	a3,8(sp)
ffffffffc020048c:	f94d                	bnez	a0,ffffffffc020043e <dtb_init+0x228>
ffffffffc020048e:	fb59f8e3          	bgeu	s3,s5,ffffffffc020043e <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200492:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200496:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020049a:	00001517          	auipc	a0,0x1
ffffffffc020049e:	35e50513          	addi	a0,a0,862 # ffffffffc02017f8 <etext+0x1a2>
           fdt32_to_cpu(x >> 32);
ffffffffc02004a2:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004a6:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004aa:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ae:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004b2:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b6:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ba:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004be:	0187d693          	srli	a3,a5,0x18
ffffffffc02004c2:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004c6:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004ca:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004d2:	010f6f33          	or	t5,t5,a6
ffffffffc02004d6:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004da:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004de:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e2:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e6:	0186f6b3          	and	a3,a3,s8
ffffffffc02004ea:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004ee:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f2:	0107581b          	srliw	a6,a4,0x10
ffffffffc02004f6:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fa:	8361                	srli	a4,a4,0x18
ffffffffc02004fc:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200504:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200508:	00cb7633          	and	a2,s6,a2
ffffffffc020050c:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200510:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200514:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200518:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051c:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200520:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200524:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200528:	011b78b3          	and	a7,s6,a7
ffffffffc020052c:	005eeeb3          	or	t4,t4,t0
ffffffffc0200530:	00c6e733          	or	a4,a3,a2
ffffffffc0200534:	006c6c33          	or	s8,s8,t1
ffffffffc0200538:	010b76b3          	and	a3,s6,a6
ffffffffc020053c:	00bb7b33          	and	s6,s6,a1
ffffffffc0200540:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200544:	016c6b33          	or	s6,s8,s6
ffffffffc0200548:	01146433          	or	s0,s0,a7
ffffffffc020054c:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc020054e:	1702                	slli	a4,a4,0x20
ffffffffc0200550:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200552:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200554:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200556:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	0167eb33          	or	s6,a5,s6
ffffffffc0200560:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200562:	bebff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200566:	85a2                	mv	a1,s0
ffffffffc0200568:	00001517          	auipc	a0,0x1
ffffffffc020056c:	2b050513          	addi	a0,a0,688 # ffffffffc0201818 <etext+0x1c2>
ffffffffc0200570:	bddff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200574:	014b5613          	srli	a2,s6,0x14
ffffffffc0200578:	85da                	mv	a1,s6
ffffffffc020057a:	00001517          	auipc	a0,0x1
ffffffffc020057e:	2b650513          	addi	a0,a0,694 # ffffffffc0201830 <etext+0x1da>
ffffffffc0200582:	bcbff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200586:	008b05b3          	add	a1,s6,s0
ffffffffc020058a:	15fd                	addi	a1,a1,-1
ffffffffc020058c:	00001517          	auipc	a0,0x1
ffffffffc0200590:	2c450513          	addi	a0,a0,708 # ffffffffc0201850 <etext+0x1fa>
ffffffffc0200594:	bb9ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200598:	00001517          	auipc	a0,0x1
ffffffffc020059c:	30850513          	addi	a0,a0,776 # ffffffffc02018a0 <etext+0x24a>
        memory_base = mem_base;
ffffffffc02005a0:	00005797          	auipc	a5,0x5
ffffffffc02005a4:	a887bc23          	sd	s0,-1384(a5) # ffffffffc0205038 <memory_base>
        memory_size = mem_size;
ffffffffc02005a8:	00005797          	auipc	a5,0x5
ffffffffc02005ac:	a967bc23          	sd	s6,-1384(a5) # ffffffffc0205040 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005b0:	b3f5                	j	ffffffffc020039c <dtb_init+0x186>

ffffffffc02005b2 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005b2:	00005517          	auipc	a0,0x5
ffffffffc02005b6:	a8653503          	ld	a0,-1402(a0) # ffffffffc0205038 <memory_base>
ffffffffc02005ba:	8082                	ret

ffffffffc02005bc <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005bc:	00005517          	auipc	a0,0x5
ffffffffc02005c0:	a8453503          	ld	a0,-1404(a0) # ffffffffc0205040 <memory_size>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02005c6:	8082                	ret

ffffffffc02005c8 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc02005c8:	0ff57513          	zext.b	a0,a0
ffffffffc02005cc:	0700106f          	j	ffffffffc020163c <sbi_console_putchar>

ffffffffc02005d0 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc02005d0:	00005797          	auipc	a5,0x5
ffffffffc02005d4:	a887b783          	ld	a5,-1400(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc02005d8:	6f9c                	ld	a5,24(a5)
ffffffffc02005da:	8782                	jr	a5

ffffffffc02005dc <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc02005dc:	00005797          	auipc	a5,0x5
ffffffffc02005e0:	a7c7b783          	ld	a5,-1412(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc02005e4:	739c                	ld	a5,32(a5)
ffffffffc02005e6:	8782                	jr	a5

ffffffffc02005e8 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc02005e8:	00005797          	auipc	a5,0x5
ffffffffc02005ec:	a707b783          	ld	a5,-1424(a5) # ffffffffc0205058 <pmm_manager>
ffffffffc02005f0:	779c                	ld	a5,40(a5)
ffffffffc02005f2:	8782                	jr	a5

ffffffffc02005f4 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02005f4:	00001797          	auipc	a5,0x1
ffffffffc02005f8:	77478793          	addi	a5,a5,1908 # ffffffffc0201d68 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02005fc:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02005fe:	7179                	addi	sp,sp,-48
ffffffffc0200600:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200602:	00001517          	auipc	a0,0x1
ffffffffc0200606:	2b650513          	addi	a0,a0,694 # ffffffffc02018b8 <etext+0x262>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020060a:	00005417          	auipc	s0,0x5
ffffffffc020060e:	a4e40413          	addi	s0,s0,-1458 # ffffffffc0205058 <pmm_manager>
void pmm_init(void) {
ffffffffc0200612:	f406                	sd	ra,40(sp)
ffffffffc0200614:	ec26                	sd	s1,24(sp)
ffffffffc0200616:	e44e                	sd	s3,8(sp)
ffffffffc0200618:	e84a                	sd	s2,16(sp)
ffffffffc020061a:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020061c:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020061e:	b2fff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0200622:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200624:	00005497          	auipc	s1,0x5
ffffffffc0200628:	a4c48493          	addi	s1,s1,-1460 # ffffffffc0205070 <va_pa_offset>
    pmm_manager->init();
ffffffffc020062c:	679c                	ld	a5,8(a5)
ffffffffc020062e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200630:	57f5                	li	a5,-3
ffffffffc0200632:	07fa                	slli	a5,a5,0x1e
ffffffffc0200634:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200636:	f7dff0ef          	jal	ra,ffffffffc02005b2 <get_memory_base>
ffffffffc020063a:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020063c:	f81ff0ef          	jal	ra,ffffffffc02005bc <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200640:	14050c63          	beqz	a0,ffffffffc0200798 <pmm_init+0x1a4>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200644:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0200646:	00001517          	auipc	a0,0x1
ffffffffc020064a:	2ba50513          	addi	a0,a0,698 # ffffffffc0201900 <etext+0x2aa>
ffffffffc020064e:	affff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200652:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200656:	864e                	mv	a2,s3
ffffffffc0200658:	fffa0693          	addi	a3,s4,-1
ffffffffc020065c:	85ca                	mv	a1,s2
ffffffffc020065e:	00001517          	auipc	a0,0x1
ffffffffc0200662:	2ba50513          	addi	a0,a0,698 # ffffffffc0201918 <etext+0x2c2>
ffffffffc0200666:	ae7ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020066a:	c80007b7          	lui	a5,0xc8000
ffffffffc020066e:	8652                	mv	a2,s4
ffffffffc0200670:	0d47e363          	bltu	a5,s4,ffffffffc0200736 <pmm_init+0x142>
ffffffffc0200674:	00006797          	auipc	a5,0x6
ffffffffc0200678:	a0378793          	addi	a5,a5,-1533 # ffffffffc0206077 <end+0xfff>
ffffffffc020067c:	757d                	lui	a0,0xfffff
ffffffffc020067e:	8d7d                	and	a0,a0,a5
ffffffffc0200680:	8231                	srli	a2,a2,0xc
ffffffffc0200682:	00005797          	auipc	a5,0x5
ffffffffc0200686:	9cc7b323          	sd	a2,-1594(a5) # ffffffffc0205048 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020068a:	00005797          	auipc	a5,0x5
ffffffffc020068e:	9ca7b323          	sd	a0,-1594(a5) # ffffffffc0205050 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200692:	000807b7          	lui	a5,0x80
ffffffffc0200696:	002005b7          	lui	a1,0x200
ffffffffc020069a:	02f60563          	beq	a2,a5,ffffffffc02006c4 <pmm_init+0xd0>
ffffffffc020069e:	00261593          	slli	a1,a2,0x2
ffffffffc02006a2:	00c586b3          	add	a3,a1,a2
ffffffffc02006a6:	fec007b7          	lui	a5,0xfec00
ffffffffc02006aa:	97aa                	add	a5,a5,a0
ffffffffc02006ac:	068e                	slli	a3,a3,0x3
ffffffffc02006ae:	96be                	add	a3,a3,a5
ffffffffc02006b0:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc02006b2:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02006b4:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9fafb0>
        SetPageReserved(pages + i);
ffffffffc02006b8:	00176713          	ori	a4,a4,1
ffffffffc02006bc:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02006c0:	fef699e3          	bne	a3,a5,ffffffffc02006b2 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02006c4:	95b2                	add	a1,a1,a2
ffffffffc02006c6:	fec006b7          	lui	a3,0xfec00
ffffffffc02006ca:	96aa                	add	a3,a3,a0
ffffffffc02006cc:	058e                	slli	a1,a1,0x3
ffffffffc02006ce:	96ae                	add	a3,a3,a1
ffffffffc02006d0:	c02007b7          	lui	a5,0xc0200
ffffffffc02006d4:	0af6e663          	bltu	a3,a5,ffffffffc0200780 <pmm_init+0x18c>
ffffffffc02006d8:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02006da:	77fd                	lui	a5,0xfffff
ffffffffc02006dc:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02006e0:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02006e2:	04b6ed63          	bltu	a3,a1,ffffffffc020073c <pmm_init+0x148>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02006e6:	601c                	ld	a5,0(s0)
ffffffffc02006e8:	7b9c                	ld	a5,48(a5)
ffffffffc02006ea:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02006ec:	00001517          	auipc	a0,0x1
ffffffffc02006f0:	2b450513          	addi	a0,a0,692 # ffffffffc02019a0 <etext+0x34a>
ffffffffc02006f4:	a59ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02006f8:	00004597          	auipc	a1,0x4
ffffffffc02006fc:	90858593          	addi	a1,a1,-1784 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc0200700:	00005797          	auipc	a5,0x5
ffffffffc0200704:	96b7b423          	sd	a1,-1688(a5) # ffffffffc0205068 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200708:	c02007b7          	lui	a5,0xc0200
ffffffffc020070c:	0af5e263          	bltu	a1,a5,ffffffffc02007b0 <pmm_init+0x1bc>
ffffffffc0200710:	6090                	ld	a2,0(s1)
}
ffffffffc0200712:	7402                	ld	s0,32(sp)
ffffffffc0200714:	70a2                	ld	ra,40(sp)
ffffffffc0200716:	64e2                	ld	s1,24(sp)
ffffffffc0200718:	6942                	ld	s2,16(sp)
ffffffffc020071a:	69a2                	ld	s3,8(sp)
ffffffffc020071c:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020071e:	40c58633          	sub	a2,a1,a2
ffffffffc0200722:	00005797          	auipc	a5,0x5
ffffffffc0200726:	92c7bf23          	sd	a2,-1730(a5) # ffffffffc0205060 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020072a:	00001517          	auipc	a0,0x1
ffffffffc020072e:	29650513          	addi	a0,a0,662 # ffffffffc02019c0 <etext+0x36a>
}
ffffffffc0200732:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200734:	bc21                	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0200736:	c8000637          	lui	a2,0xc8000
ffffffffc020073a:	bf2d                	j	ffffffffc0200674 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020073c:	6705                	lui	a4,0x1
ffffffffc020073e:	177d                	addi	a4,a4,-1
ffffffffc0200740:	96ba                	add	a3,a3,a4
ffffffffc0200742:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200744:	00c6d793          	srli	a5,a3,0xc
ffffffffc0200748:	02c7f063          	bgeu	a5,a2,ffffffffc0200768 <pmm_init+0x174>
    pmm_manager->init_memmap(base, n);
ffffffffc020074c:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020074e:	fff80737          	lui	a4,0xfff80
ffffffffc0200752:	973e                	add	a4,a4,a5
ffffffffc0200754:	00271793          	slli	a5,a4,0x2
ffffffffc0200758:	97ba                	add	a5,a5,a4
ffffffffc020075a:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020075c:	8d95                	sub	a1,a1,a3
ffffffffc020075e:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200760:	81b1                	srli	a1,a1,0xc
ffffffffc0200762:	953e                	add	a0,a0,a5
ffffffffc0200764:	9702                	jalr	a4
}
ffffffffc0200766:	b741                	j	ffffffffc02006e6 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0200768:	00001617          	auipc	a2,0x1
ffffffffc020076c:	20860613          	addi	a2,a2,520 # ffffffffc0201970 <etext+0x31a>
ffffffffc0200770:	06a00593          	li	a1,106
ffffffffc0200774:	00001517          	auipc	a0,0x1
ffffffffc0200778:	21c50513          	addi	a0,a0,540 # ffffffffc0201990 <etext+0x33a>
ffffffffc020077c:	a47ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200780:	00001617          	auipc	a2,0x1
ffffffffc0200784:	1c860613          	addi	a2,a2,456 # ffffffffc0201948 <etext+0x2f2>
ffffffffc0200788:	05f00593          	li	a1,95
ffffffffc020078c:	00001517          	auipc	a0,0x1
ffffffffc0200790:	16450513          	addi	a0,a0,356 # ffffffffc02018f0 <etext+0x29a>
ffffffffc0200794:	a2fff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0200798:	00001617          	auipc	a2,0x1
ffffffffc020079c:	13860613          	addi	a2,a2,312 # ffffffffc02018d0 <etext+0x27a>
ffffffffc02007a0:	04700593          	li	a1,71
ffffffffc02007a4:	00001517          	auipc	a0,0x1
ffffffffc02007a8:	14c50513          	addi	a0,a0,332 # ffffffffc02018f0 <etext+0x29a>
ffffffffc02007ac:	a17ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02007b0:	86ae                	mv	a3,a1
ffffffffc02007b2:	00001617          	auipc	a2,0x1
ffffffffc02007b6:	19660613          	addi	a2,a2,406 # ffffffffc0201948 <etext+0x2f2>
ffffffffc02007ba:	07a00593          	li	a1,122
ffffffffc02007be:	00001517          	auipc	a0,0x1
ffffffffc02007c2:	13250513          	addi	a0,a0,306 # ffffffffc02018f0 <etext+0x29a>
ffffffffc02007c6:	9fdff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02007ca <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02007ca:	00005797          	auipc	a5,0x5
ffffffffc02007ce:	84e78793          	addi	a5,a5,-1970 # ffffffffc0205018 <free_area>
ffffffffc02007d2:	e79c                	sd	a5,8(a5)
ffffffffc02007d4:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02007d6:	0007a823          	sw	zero,16(a5)
}
ffffffffc02007da:	8082                	ret

ffffffffc02007dc <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02007dc:	00005517          	auipc	a0,0x5
ffffffffc02007e0:	84c56503          	lwu	a0,-1972(a0) # ffffffffc0205028 <free_area+0x10>
ffffffffc02007e4:	8082                	ret

ffffffffc02007e6 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02007e6:	cd49                	beqz	a0,ffffffffc0200880 <best_fit_alloc_pages+0x9a>
    if (n > nr_free) {
ffffffffc02007e8:	00005617          	auipc	a2,0x5
ffffffffc02007ec:	83060613          	addi	a2,a2,-2000 # ffffffffc0205018 <free_area>
ffffffffc02007f0:	01062803          	lw	a6,16(a2)
ffffffffc02007f4:	86aa                	mv	a3,a0
ffffffffc02007f6:	02081793          	slli	a5,a6,0x20
ffffffffc02007fa:	9381                	srli	a5,a5,0x20
ffffffffc02007fc:	08a7e063          	bltu	a5,a0,ffffffffc020087c <best_fit_alloc_pages+0x96>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200800:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200802:	0018059b          	addiw	a1,a6,1
ffffffffc0200806:	1582                	slli	a1,a1,0x20
ffffffffc0200808:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc020080a:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc020080c:	06c78763          	beq	a5,a2,ffffffffc020087a <best_fit_alloc_pages+0x94>
        if (p->property >= n && p->property < min_size) {
ffffffffc0200810:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200814:	00d76763          	bltu	a4,a3,ffffffffc0200822 <best_fit_alloc_pages+0x3c>
ffffffffc0200818:	00b77563          	bgeu	a4,a1,ffffffffc0200822 <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc020081c:	fe878513          	addi	a0,a5,-24
ffffffffc0200820:	85ba                	mv	a1,a4
ffffffffc0200822:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200824:	fec796e3          	bne	a5,a2,ffffffffc0200810 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200828:	c929                	beqz	a0,ffffffffc020087a <best_fit_alloc_pages+0x94>
        if (page->property > n) {
ffffffffc020082a:	01052883          	lw	a7,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc020082e:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200830:	710c                	ld	a1,32(a0)
ffffffffc0200832:	02089793          	slli	a5,a7,0x20
ffffffffc0200836:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200838:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc020083a:	e198                	sd	a4,0(a1)
            p->property = page->property - n;
ffffffffc020083c:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc0200840:	02f6f563          	bgeu	a3,a5,ffffffffc020086a <best_fit_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc0200844:	00269793          	slli	a5,a3,0x2
ffffffffc0200848:	97b6                	add	a5,a5,a3
ffffffffc020084a:	078e                	slli	a5,a5,0x3
ffffffffc020084c:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc020084e:	6794                	ld	a3,8(a5)
            p->property = page->property - n;
ffffffffc0200850:	406888bb          	subw	a7,a7,t1
ffffffffc0200854:	0117a823          	sw	a7,16(a5)
            SetPageProperty(p);
ffffffffc0200858:	0026e693          	ori	a3,a3,2
ffffffffc020085c:	e794                	sd	a3,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc020085e:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200862:	e194                	sd	a3,0(a1)
ffffffffc0200864:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200866:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc0200868:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc020086a:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc020086c:	4068083b          	subw	a6,a6,t1
ffffffffc0200870:	01062823          	sw	a6,16(a2)
        ClearPageProperty(page);
ffffffffc0200874:	9bf5                	andi	a5,a5,-3
ffffffffc0200876:	e51c                	sd	a5,8(a0)
ffffffffc0200878:	8082                	ret
}
ffffffffc020087a:	8082                	ret
        return NULL;
ffffffffc020087c:	4501                	li	a0,0
ffffffffc020087e:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200880:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200882:	00001697          	auipc	a3,0x1
ffffffffc0200886:	17e68693          	addi	a3,a3,382 # ffffffffc0201a00 <etext+0x3aa>
ffffffffc020088a:	00001617          	auipc	a2,0x1
ffffffffc020088e:	17e60613          	addi	a2,a2,382 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200892:	06e00593          	li	a1,110
ffffffffc0200896:	00001517          	auipc	a0,0x1
ffffffffc020089a:	18a50513          	addi	a0,a0,394 # ffffffffc0201a20 <etext+0x3ca>
best_fit_alloc_pages(size_t n) {
ffffffffc020089e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02008a0:	923ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02008a4 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc02008a4:	715d                	addi	sp,sp,-80
ffffffffc02008a6:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02008a8:	00004417          	auipc	s0,0x4
ffffffffc02008ac:	77040413          	addi	s0,s0,1904 # ffffffffc0205018 <free_area>
ffffffffc02008b0:	641c                	ld	a5,8(s0)
ffffffffc02008b2:	e486                	sd	ra,72(sp)
ffffffffc02008b4:	fc26                	sd	s1,56(sp)
ffffffffc02008b6:	f84a                	sd	s2,48(sp)
ffffffffc02008b8:	f44e                	sd	s3,40(sp)
ffffffffc02008ba:	f052                	sd	s4,32(sp)
ffffffffc02008bc:	ec56                	sd	s5,24(sp)
ffffffffc02008be:	e85a                	sd	s6,16(sp)
ffffffffc02008c0:	e45e                	sd	s7,8(sp)
ffffffffc02008c2:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008c4:	26878f63          	beq	a5,s0,ffffffffc0200b42 <best_fit_check+0x29e>
    int count = 0, total = 0;
ffffffffc02008c8:	4481                	li	s1,0
ffffffffc02008ca:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02008cc:	ff07b703          	ld	a4,-16(a5)
ffffffffc02008d0:	8b09                	andi	a4,a4,2
ffffffffc02008d2:	26070c63          	beqz	a4,ffffffffc0200b4a <best_fit_check+0x2a6>
        count ++, total += p->property;
ffffffffc02008d6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02008da:	679c                	ld	a5,8(a5)
ffffffffc02008dc:	2905                	addiw	s2,s2,1
ffffffffc02008de:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008e0:	fe8796e3          	bne	a5,s0,ffffffffc02008cc <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02008e4:	89a6                	mv	s3,s1
ffffffffc02008e6:	d03ff0ef          	jal	ra,ffffffffc02005e8 <nr_free_pages>
ffffffffc02008ea:	35351063          	bne	a0,s3,ffffffffc0200c2a <best_fit_check+0x386>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02008ee:	4505                	li	a0,1
ffffffffc02008f0:	ce1ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02008f4:	8a2a                	mv	s4,a0
ffffffffc02008f6:	36050a63          	beqz	a0,ffffffffc0200c6a <best_fit_check+0x3c6>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02008fa:	4505                	li	a0,1
ffffffffc02008fc:	cd5ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200900:	89aa                	mv	s3,a0
ffffffffc0200902:	34050463          	beqz	a0,ffffffffc0200c4a <best_fit_check+0x3a6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200906:	4505                	li	a0,1
ffffffffc0200908:	cc9ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc020090c:	8aaa                	mv	s5,a0
ffffffffc020090e:	2c050e63          	beqz	a0,ffffffffc0200bea <best_fit_check+0x346>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200912:	253a0c63          	beq	s4,s3,ffffffffc0200b6a <best_fit_check+0x2c6>
ffffffffc0200916:	24aa0a63          	beq	s4,a0,ffffffffc0200b6a <best_fit_check+0x2c6>
ffffffffc020091a:	24a98863          	beq	s3,a0,ffffffffc0200b6a <best_fit_check+0x2c6>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020091e:	000a2783          	lw	a5,0(s4)
ffffffffc0200922:	26079463          	bnez	a5,ffffffffc0200b8a <best_fit_check+0x2e6>
ffffffffc0200926:	0009a783          	lw	a5,0(s3)
ffffffffc020092a:	26079063          	bnez	a5,ffffffffc0200b8a <best_fit_check+0x2e6>
ffffffffc020092e:	411c                	lw	a5,0(a0)
ffffffffc0200930:	24079d63          	bnez	a5,ffffffffc0200b8a <best_fit_check+0x2e6>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200934:	00004797          	auipc	a5,0x4
ffffffffc0200938:	71c7b783          	ld	a5,1820(a5) # ffffffffc0205050 <pages>
ffffffffc020093c:	40fa0733          	sub	a4,s4,a5
ffffffffc0200940:	870d                	srai	a4,a4,0x3
ffffffffc0200942:	00001597          	auipc	a1,0x1
ffffffffc0200946:	6ae5b583          	ld	a1,1710(a1) # ffffffffc0201ff0 <nbase+0x8>
ffffffffc020094a:	02b70733          	mul	a4,a4,a1
ffffffffc020094e:	00001617          	auipc	a2,0x1
ffffffffc0200952:	69a63603          	ld	a2,1690(a2) # ffffffffc0201fe8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200956:	00004697          	auipc	a3,0x4
ffffffffc020095a:	6f26b683          	ld	a3,1778(a3) # ffffffffc0205048 <npage>
ffffffffc020095e:	06b2                	slli	a3,a3,0xc
ffffffffc0200960:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200962:	0732                	slli	a4,a4,0xc
ffffffffc0200964:	24d77363          	bgeu	a4,a3,ffffffffc0200baa <best_fit_check+0x306>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200968:	40f98733          	sub	a4,s3,a5
ffffffffc020096c:	870d                	srai	a4,a4,0x3
ffffffffc020096e:	02b70733          	mul	a4,a4,a1
ffffffffc0200972:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200974:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200976:	3ed77a63          	bgeu	a4,a3,ffffffffc0200d6a <best_fit_check+0x4c6>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020097a:	40f507b3          	sub	a5,a0,a5
ffffffffc020097e:	878d                	srai	a5,a5,0x3
ffffffffc0200980:	02b787b3          	mul	a5,a5,a1
ffffffffc0200984:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200986:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200988:	3cd7f163          	bgeu	a5,a3,ffffffffc0200d4a <best_fit_check+0x4a6>
    assert(alloc_page() == NULL);
ffffffffc020098c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020098e:	00043c03          	ld	s8,0(s0)
ffffffffc0200992:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200996:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020099a:	e400                	sd	s0,8(s0)
ffffffffc020099c:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc020099e:	00004797          	auipc	a5,0x4
ffffffffc02009a2:	6807a523          	sw	zero,1674(a5) # ffffffffc0205028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02009a6:	c2bff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009aa:	38051063          	bnez	a0,ffffffffc0200d2a <best_fit_check+0x486>
    free_page(p0);
ffffffffc02009ae:	4585                	li	a1,1
ffffffffc02009b0:	8552                	mv	a0,s4
ffffffffc02009b2:	c2bff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p1);
ffffffffc02009b6:	4585                	li	a1,1
ffffffffc02009b8:	854e                	mv	a0,s3
ffffffffc02009ba:	c23ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p2);
ffffffffc02009be:	4585                	li	a1,1
ffffffffc02009c0:	8556                	mv	a0,s5
ffffffffc02009c2:	c1bff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert(nr_free == 3);
ffffffffc02009c6:	4818                	lw	a4,16(s0)
ffffffffc02009c8:	478d                	li	a5,3
ffffffffc02009ca:	34f71063          	bne	a4,a5,ffffffffc0200d0a <best_fit_check+0x466>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02009ce:	4505                	li	a0,1
ffffffffc02009d0:	c01ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009d4:	89aa                	mv	s3,a0
ffffffffc02009d6:	30050a63          	beqz	a0,ffffffffc0200cea <best_fit_check+0x446>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02009da:	4505                	li	a0,1
ffffffffc02009dc:	bf5ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009e0:	8aaa                	mv	s5,a0
ffffffffc02009e2:	2e050463          	beqz	a0,ffffffffc0200cca <best_fit_check+0x426>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009e6:	4505                	li	a0,1
ffffffffc02009e8:	be9ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009ec:	8a2a                	mv	s4,a0
ffffffffc02009ee:	2a050e63          	beqz	a0,ffffffffc0200caa <best_fit_check+0x406>
    assert(alloc_page() == NULL);
ffffffffc02009f2:	4505                	li	a0,1
ffffffffc02009f4:	bddff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc02009f8:	28051963          	bnez	a0,ffffffffc0200c8a <best_fit_check+0x3e6>
    free_page(p0);
ffffffffc02009fc:	4585                	li	a1,1
ffffffffc02009fe:	854e                	mv	a0,s3
ffffffffc0200a00:	bddff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200a04:	641c                	ld	a5,8(s0)
ffffffffc0200a06:	1c878263          	beq	a5,s0,ffffffffc0200bca <best_fit_check+0x326>
    assert((p = alloc_page()) == p0);
ffffffffc0200a0a:	4505                	li	a0,1
ffffffffc0200a0c:	bc5ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a10:	52a99d63          	bne	s3,a0,ffffffffc0200f4a <best_fit_check+0x6a6>
    assert(alloc_page() == NULL);
ffffffffc0200a14:	4505                	li	a0,1
ffffffffc0200a16:	bbbff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a1a:	50051863          	bnez	a0,ffffffffc0200f2a <best_fit_check+0x686>
    assert(nr_free == 0);
ffffffffc0200a1e:	481c                	lw	a5,16(s0)
ffffffffc0200a20:	4e079563          	bnez	a5,ffffffffc0200f0a <best_fit_check+0x666>
    free_page(p);
ffffffffc0200a24:	854e                	mv	a0,s3
ffffffffc0200a26:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200a28:	01843023          	sd	s8,0(s0)
ffffffffc0200a2c:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200a30:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200a34:	ba9ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p1);
ffffffffc0200a38:	4585                	li	a1,1
ffffffffc0200a3a:	8556                	mv	a0,s5
ffffffffc0200a3c:	ba1ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_page(p2);
ffffffffc0200a40:	4585                	li	a1,1
ffffffffc0200a42:	8552                	mv	a0,s4
ffffffffc0200a44:	b99ff0ef          	jal	ra,ffffffffc02005dc <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200a48:	4515                	li	a0,5
ffffffffc0200a4a:	b87ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a4e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200a50:	48050d63          	beqz	a0,ffffffffc0200eea <best_fit_check+0x646>
    assert(!PageProperty(p0));
ffffffffc0200a54:	651c                	ld	a5,8(a0)
ffffffffc0200a56:	8b89                	andi	a5,a5,2
ffffffffc0200a58:	46079963          	bnez	a5,ffffffffc0200eca <best_fit_check+0x626>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200a5c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200a5e:	00043b03          	ld	s6,0(s0)
ffffffffc0200a62:	00843a83          	ld	s5,8(s0)
ffffffffc0200a66:	e000                	sd	s0,0(s0)
ffffffffc0200a68:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200a6a:	b67ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a6e:	42051e63          	bnez	a0,ffffffffc0200eaa <best_fit_check+0x606>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200a72:	4589                	li	a1,2
ffffffffc0200a74:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200a78:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200a7c:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200a80:	00004797          	auipc	a5,0x4
ffffffffc0200a84:	5a07a423          	sw	zero,1448(a5) # ffffffffc0205028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200a88:	b55ff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200a8c:	8562                	mv	a0,s8
ffffffffc0200a8e:	4585                	li	a1,1
ffffffffc0200a90:	b4dff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200a94:	4511                	li	a0,4
ffffffffc0200a96:	b3bff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200a9a:	3e051863          	bnez	a0,ffffffffc0200e8a <best_fit_check+0x5e6>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200a9e:	0309b783          	ld	a5,48(s3)
ffffffffc0200aa2:	8b89                	andi	a5,a5,2
ffffffffc0200aa4:	3c078363          	beqz	a5,ffffffffc0200e6a <best_fit_check+0x5c6>
ffffffffc0200aa8:	0389a703          	lw	a4,56(s3)
ffffffffc0200aac:	4789                	li	a5,2
ffffffffc0200aae:	3af71e63          	bne	a4,a5,ffffffffc0200e6a <best_fit_check+0x5c6>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200ab2:	4505                	li	a0,1
ffffffffc0200ab4:	b1dff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200ab8:	8a2a                	mv	s4,a0
ffffffffc0200aba:	38050863          	beqz	a0,ffffffffc0200e4a <best_fit_check+0x5a6>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200abe:	4509                	li	a0,2
ffffffffc0200ac0:	b11ff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200ac4:	36050363          	beqz	a0,ffffffffc0200e2a <best_fit_check+0x586>
    assert(p0 + 4 == p1);
ffffffffc0200ac8:	354c1163          	bne	s8,s4,ffffffffc0200e0a <best_fit_check+0x566>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200acc:	854e                	mv	a0,s3
ffffffffc0200ace:	4595                	li	a1,5
ffffffffc0200ad0:	b0dff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200ad4:	4515                	li	a0,5
ffffffffc0200ad6:	afbff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200ada:	89aa                	mv	s3,a0
ffffffffc0200adc:	30050763          	beqz	a0,ffffffffc0200dea <best_fit_check+0x546>
    assert(alloc_page() == NULL);
ffffffffc0200ae0:	4505                	li	a0,1
ffffffffc0200ae2:	aefff0ef          	jal	ra,ffffffffc02005d0 <alloc_pages>
ffffffffc0200ae6:	2e051263          	bnez	a0,ffffffffc0200dca <best_fit_check+0x526>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200aea:	481c                	lw	a5,16(s0)
ffffffffc0200aec:	2a079f63          	bnez	a5,ffffffffc0200daa <best_fit_check+0x506>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200af0:	4595                	li	a1,5
ffffffffc0200af2:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200af4:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200af8:	01643023          	sd	s6,0(s0)
ffffffffc0200afc:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200b00:	addff0ef          	jal	ra,ffffffffc02005dc <free_pages>
    return listelm->next;
ffffffffc0200b04:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b06:	00878963          	beq	a5,s0,ffffffffc0200b18 <best_fit_check+0x274>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200b0a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200b0e:	679c                	ld	a5,8(a5)
ffffffffc0200b10:	397d                	addiw	s2,s2,-1
ffffffffc0200b12:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b14:	fe879be3          	bne	a5,s0,ffffffffc0200b0a <best_fit_check+0x266>
    }
    assert(count == 0);
ffffffffc0200b18:	26091963          	bnez	s2,ffffffffc0200d8a <best_fit_check+0x4e6>
    assert(total == 0);
ffffffffc0200b1c:	0e049763          	bnez	s1,ffffffffc0200c0a <best_fit_check+0x366>
    #endif


    // 添加成功信息
    cprintf("best_fit_check() succeeded!\n");
}
ffffffffc0200b20:	6406                	ld	s0,64(sp)
ffffffffc0200b22:	60a6                	ld	ra,72(sp)
ffffffffc0200b24:	74e2                	ld	s1,56(sp)
ffffffffc0200b26:	7942                	ld	s2,48(sp)
ffffffffc0200b28:	79a2                	ld	s3,40(sp)
ffffffffc0200b2a:	7a02                	ld	s4,32(sp)
ffffffffc0200b2c:	6ae2                	ld	s5,24(sp)
ffffffffc0200b2e:	6b42                	ld	s6,16(sp)
ffffffffc0200b30:	6ba2                	ld	s7,8(sp)
ffffffffc0200b32:	6c02                	ld	s8,0(sp)
    cprintf("best_fit_check() succeeded!\n");
ffffffffc0200b34:	00001517          	auipc	a0,0x1
ffffffffc0200b38:	1c450513          	addi	a0,a0,452 # ffffffffc0201cf8 <etext+0x6a2>
}
ffffffffc0200b3c:	6161                	addi	sp,sp,80
    cprintf("best_fit_check() succeeded!\n");
ffffffffc0200b3e:	e0eff06f          	j	ffffffffc020014c <cprintf>
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b42:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200b44:	4481                	li	s1,0
ffffffffc0200b46:	4901                	li	s2,0
ffffffffc0200b48:	bb79                	j	ffffffffc02008e6 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200b4a:	00001697          	auipc	a3,0x1
ffffffffc0200b4e:	eee68693          	addi	a3,a3,-274 # ffffffffc0201a38 <etext+0x3e2>
ffffffffc0200b52:	00001617          	auipc	a2,0x1
ffffffffc0200b56:	eb660613          	addi	a2,a2,-330 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200b5a:	11200593          	li	a1,274
ffffffffc0200b5e:	00001517          	auipc	a0,0x1
ffffffffc0200b62:	ec250513          	addi	a0,a0,-318 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200b66:	e5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200b6a:	00001697          	auipc	a3,0x1
ffffffffc0200b6e:	f5e68693          	addi	a3,a3,-162 # ffffffffc0201ac8 <etext+0x472>
ffffffffc0200b72:	00001617          	auipc	a2,0x1
ffffffffc0200b76:	e9660613          	addi	a2,a2,-362 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200b7a:	0de00593          	li	a1,222
ffffffffc0200b7e:	00001517          	auipc	a0,0x1
ffffffffc0200b82:	ea250513          	addi	a0,a0,-350 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200b86:	e3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b8a:	00001697          	auipc	a3,0x1
ffffffffc0200b8e:	f6668693          	addi	a3,a3,-154 # ffffffffc0201af0 <etext+0x49a>
ffffffffc0200b92:	00001617          	auipc	a2,0x1
ffffffffc0200b96:	e7660613          	addi	a2,a2,-394 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200b9a:	0df00593          	li	a1,223
ffffffffc0200b9e:	00001517          	auipc	a0,0x1
ffffffffc0200ba2:	e8250513          	addi	a0,a0,-382 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200ba6:	e1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200baa:	00001697          	auipc	a3,0x1
ffffffffc0200bae:	f8668693          	addi	a3,a3,-122 # ffffffffc0201b30 <etext+0x4da>
ffffffffc0200bb2:	00001617          	auipc	a2,0x1
ffffffffc0200bb6:	e5660613          	addi	a2,a2,-426 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200bba:	0e100593          	li	a1,225
ffffffffc0200bbe:	00001517          	auipc	a0,0x1
ffffffffc0200bc2:	e6250513          	addi	a0,a0,-414 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200bc6:	dfcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200bca:	00001697          	auipc	a3,0x1
ffffffffc0200bce:	fee68693          	addi	a3,a3,-18 # ffffffffc0201bb8 <etext+0x562>
ffffffffc0200bd2:	00001617          	auipc	a2,0x1
ffffffffc0200bd6:	e3660613          	addi	a2,a2,-458 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200bda:	0fa00593          	li	a1,250
ffffffffc0200bde:	00001517          	auipc	a0,0x1
ffffffffc0200be2:	e4250513          	addi	a0,a0,-446 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200be6:	ddcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200bea:	00001697          	auipc	a3,0x1
ffffffffc0200bee:	ebe68693          	addi	a3,a3,-322 # ffffffffc0201aa8 <etext+0x452>
ffffffffc0200bf2:	00001617          	auipc	a2,0x1
ffffffffc0200bf6:	e1660613          	addi	a2,a2,-490 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200bfa:	0dc00593          	li	a1,220
ffffffffc0200bfe:	00001517          	auipc	a0,0x1
ffffffffc0200c02:	e2250513          	addi	a0,a0,-478 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200c06:	dbcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == 0);
ffffffffc0200c0a:	00001697          	auipc	a3,0x1
ffffffffc0200c0e:	0de68693          	addi	a3,a3,222 # ffffffffc0201ce8 <etext+0x692>
ffffffffc0200c12:	00001617          	auipc	a2,0x1
ffffffffc0200c16:	df660613          	addi	a2,a2,-522 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200c1a:	15400593          	li	a1,340
ffffffffc0200c1e:	00001517          	auipc	a0,0x1
ffffffffc0200c22:	e0250513          	addi	a0,a0,-510 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200c26:	d9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200c2a:	00001697          	auipc	a3,0x1
ffffffffc0200c2e:	e1e68693          	addi	a3,a3,-482 # ffffffffc0201a48 <etext+0x3f2>
ffffffffc0200c32:	00001617          	auipc	a2,0x1
ffffffffc0200c36:	dd660613          	addi	a2,a2,-554 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200c3a:	11500593          	li	a1,277
ffffffffc0200c3e:	00001517          	auipc	a0,0x1
ffffffffc0200c42:	de250513          	addi	a0,a0,-542 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200c46:	d7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c4a:	00001697          	auipc	a3,0x1
ffffffffc0200c4e:	e3e68693          	addi	a3,a3,-450 # ffffffffc0201a88 <etext+0x432>
ffffffffc0200c52:	00001617          	auipc	a2,0x1
ffffffffc0200c56:	db660613          	addi	a2,a2,-586 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200c5a:	0db00593          	li	a1,219
ffffffffc0200c5e:	00001517          	auipc	a0,0x1
ffffffffc0200c62:	dc250513          	addi	a0,a0,-574 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200c66:	d5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c6a:	00001697          	auipc	a3,0x1
ffffffffc0200c6e:	dfe68693          	addi	a3,a3,-514 # ffffffffc0201a68 <etext+0x412>
ffffffffc0200c72:	00001617          	auipc	a2,0x1
ffffffffc0200c76:	d9660613          	addi	a2,a2,-618 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200c7a:	0da00593          	li	a1,218
ffffffffc0200c7e:	00001517          	auipc	a0,0x1
ffffffffc0200c82:	da250513          	addi	a0,a0,-606 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200c86:	d3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200c8a:	00001697          	auipc	a3,0x1
ffffffffc0200c8e:	f0668693          	addi	a3,a3,-250 # ffffffffc0201b90 <etext+0x53a>
ffffffffc0200c92:	00001617          	auipc	a2,0x1
ffffffffc0200c96:	d7660613          	addi	a2,a2,-650 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200c9a:	0f700593          	li	a1,247
ffffffffc0200c9e:	00001517          	auipc	a0,0x1
ffffffffc0200ca2:	d8250513          	addi	a0,a0,-638 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200ca6:	d1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200caa:	00001697          	auipc	a3,0x1
ffffffffc0200cae:	dfe68693          	addi	a3,a3,-514 # ffffffffc0201aa8 <etext+0x452>
ffffffffc0200cb2:	00001617          	auipc	a2,0x1
ffffffffc0200cb6:	d5660613          	addi	a2,a2,-682 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200cba:	0f500593          	li	a1,245
ffffffffc0200cbe:	00001517          	auipc	a0,0x1
ffffffffc0200cc2:	d6250513          	addi	a0,a0,-670 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200cc6:	cfcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200cca:	00001697          	auipc	a3,0x1
ffffffffc0200cce:	dbe68693          	addi	a3,a3,-578 # ffffffffc0201a88 <etext+0x432>
ffffffffc0200cd2:	00001617          	auipc	a2,0x1
ffffffffc0200cd6:	d3660613          	addi	a2,a2,-714 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200cda:	0f400593          	li	a1,244
ffffffffc0200cde:	00001517          	auipc	a0,0x1
ffffffffc0200ce2:	d4250513          	addi	a0,a0,-702 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200ce6:	cdcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200cea:	00001697          	auipc	a3,0x1
ffffffffc0200cee:	d7e68693          	addi	a3,a3,-642 # ffffffffc0201a68 <etext+0x412>
ffffffffc0200cf2:	00001617          	auipc	a2,0x1
ffffffffc0200cf6:	d1660613          	addi	a2,a2,-746 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200cfa:	0f300593          	li	a1,243
ffffffffc0200cfe:	00001517          	auipc	a0,0x1
ffffffffc0200d02:	d2250513          	addi	a0,a0,-734 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200d06:	cbcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 3);
ffffffffc0200d0a:	00001697          	auipc	a3,0x1
ffffffffc0200d0e:	e9e68693          	addi	a3,a3,-354 # ffffffffc0201ba8 <etext+0x552>
ffffffffc0200d12:	00001617          	auipc	a2,0x1
ffffffffc0200d16:	cf660613          	addi	a2,a2,-778 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200d1a:	0f100593          	li	a1,241
ffffffffc0200d1e:	00001517          	auipc	a0,0x1
ffffffffc0200d22:	d0250513          	addi	a0,a0,-766 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200d26:	c9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d2a:	00001697          	auipc	a3,0x1
ffffffffc0200d2e:	e6668693          	addi	a3,a3,-410 # ffffffffc0201b90 <etext+0x53a>
ffffffffc0200d32:	00001617          	auipc	a2,0x1
ffffffffc0200d36:	cd660613          	addi	a2,a2,-810 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200d3a:	0ec00593          	li	a1,236
ffffffffc0200d3e:	00001517          	auipc	a0,0x1
ffffffffc0200d42:	ce250513          	addi	a0,a0,-798 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200d46:	c7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d4a:	00001697          	auipc	a3,0x1
ffffffffc0200d4e:	e2668693          	addi	a3,a3,-474 # ffffffffc0201b70 <etext+0x51a>
ffffffffc0200d52:	00001617          	auipc	a2,0x1
ffffffffc0200d56:	cb660613          	addi	a2,a2,-842 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200d5a:	0e300593          	li	a1,227
ffffffffc0200d5e:	00001517          	auipc	a0,0x1
ffffffffc0200d62:	cc250513          	addi	a0,a0,-830 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200d66:	c5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d6a:	00001697          	auipc	a3,0x1
ffffffffc0200d6e:	de668693          	addi	a3,a3,-538 # ffffffffc0201b50 <etext+0x4fa>
ffffffffc0200d72:	00001617          	auipc	a2,0x1
ffffffffc0200d76:	c9660613          	addi	a2,a2,-874 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200d7a:	0e200593          	li	a1,226
ffffffffc0200d7e:	00001517          	auipc	a0,0x1
ffffffffc0200d82:	ca250513          	addi	a0,a0,-862 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200d86:	c3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(count == 0);
ffffffffc0200d8a:	00001697          	auipc	a3,0x1
ffffffffc0200d8e:	f4e68693          	addi	a3,a3,-178 # ffffffffc0201cd8 <etext+0x682>
ffffffffc0200d92:	00001617          	auipc	a2,0x1
ffffffffc0200d96:	c7660613          	addi	a2,a2,-906 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200d9a:	15300593          	li	a1,339
ffffffffc0200d9e:	00001517          	auipc	a0,0x1
ffffffffc0200da2:	c8250513          	addi	a0,a0,-894 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200da6:	c1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200daa:	00001697          	auipc	a3,0x1
ffffffffc0200dae:	e4668693          	addi	a3,a3,-442 # ffffffffc0201bf0 <etext+0x59a>
ffffffffc0200db2:	00001617          	auipc	a2,0x1
ffffffffc0200db6:	c5660613          	addi	a2,a2,-938 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200dba:	14800593          	li	a1,328
ffffffffc0200dbe:	00001517          	auipc	a0,0x1
ffffffffc0200dc2:	c6250513          	addi	a0,a0,-926 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200dc6:	bfcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200dca:	00001697          	auipc	a3,0x1
ffffffffc0200dce:	dc668693          	addi	a3,a3,-570 # ffffffffc0201b90 <etext+0x53a>
ffffffffc0200dd2:	00001617          	auipc	a2,0x1
ffffffffc0200dd6:	c3660613          	addi	a2,a2,-970 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200dda:	14200593          	li	a1,322
ffffffffc0200dde:	00001517          	auipc	a0,0x1
ffffffffc0200de2:	c4250513          	addi	a0,a0,-958 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200de6:	bdcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200dea:	00001697          	auipc	a3,0x1
ffffffffc0200dee:	ece68693          	addi	a3,a3,-306 # ffffffffc0201cb8 <etext+0x662>
ffffffffc0200df2:	00001617          	auipc	a2,0x1
ffffffffc0200df6:	c1660613          	addi	a2,a2,-1002 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200dfa:	14100593          	li	a1,321
ffffffffc0200dfe:	00001517          	auipc	a0,0x1
ffffffffc0200e02:	c2250513          	addi	a0,a0,-990 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200e06:	bbcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200e0a:	00001697          	auipc	a3,0x1
ffffffffc0200e0e:	e9e68693          	addi	a3,a3,-354 # ffffffffc0201ca8 <etext+0x652>
ffffffffc0200e12:	00001617          	auipc	a2,0x1
ffffffffc0200e16:	bf660613          	addi	a2,a2,-1034 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200e1a:	13900593          	li	a1,313
ffffffffc0200e1e:	00001517          	auipc	a0,0x1
ffffffffc0200e22:	c0250513          	addi	a0,a0,-1022 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200e26:	b9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200e2a:	00001697          	auipc	a3,0x1
ffffffffc0200e2e:	e6668693          	addi	a3,a3,-410 # ffffffffc0201c90 <etext+0x63a>
ffffffffc0200e32:	00001617          	auipc	a2,0x1
ffffffffc0200e36:	bd660613          	addi	a2,a2,-1066 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200e3a:	13800593          	li	a1,312
ffffffffc0200e3e:	00001517          	auipc	a0,0x1
ffffffffc0200e42:	be250513          	addi	a0,a0,-1054 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200e46:	b7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200e4a:	00001697          	auipc	a3,0x1
ffffffffc0200e4e:	e2668693          	addi	a3,a3,-474 # ffffffffc0201c70 <etext+0x61a>
ffffffffc0200e52:	00001617          	auipc	a2,0x1
ffffffffc0200e56:	bb660613          	addi	a2,a2,-1098 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200e5a:	13700593          	li	a1,311
ffffffffc0200e5e:	00001517          	auipc	a0,0x1
ffffffffc0200e62:	bc250513          	addi	a0,a0,-1086 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200e66:	b5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200e6a:	00001697          	auipc	a3,0x1
ffffffffc0200e6e:	dd668693          	addi	a3,a3,-554 # ffffffffc0201c40 <etext+0x5ea>
ffffffffc0200e72:	00001617          	auipc	a2,0x1
ffffffffc0200e76:	b9660613          	addi	a2,a2,-1130 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200e7a:	13500593          	li	a1,309
ffffffffc0200e7e:	00001517          	auipc	a0,0x1
ffffffffc0200e82:	ba250513          	addi	a0,a0,-1118 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200e86:	b3cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e8a:	00001697          	auipc	a3,0x1
ffffffffc0200e8e:	d9e68693          	addi	a3,a3,-610 # ffffffffc0201c28 <etext+0x5d2>
ffffffffc0200e92:	00001617          	auipc	a2,0x1
ffffffffc0200e96:	b7660613          	addi	a2,a2,-1162 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200e9a:	13400593          	li	a1,308
ffffffffc0200e9e:	00001517          	auipc	a0,0x1
ffffffffc0200ea2:	b8250513          	addi	a0,a0,-1150 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200ea6:	b1cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200eaa:	00001697          	auipc	a3,0x1
ffffffffc0200eae:	ce668693          	addi	a3,a3,-794 # ffffffffc0201b90 <etext+0x53a>
ffffffffc0200eb2:	00001617          	auipc	a2,0x1
ffffffffc0200eb6:	b5660613          	addi	a2,a2,-1194 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200eba:	12800593          	li	a1,296
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	b6250513          	addi	a0,a0,-1182 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200ec6:	afcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200eca:	00001697          	auipc	a3,0x1
ffffffffc0200ece:	d4668693          	addi	a3,a3,-698 # ffffffffc0201c10 <etext+0x5ba>
ffffffffc0200ed2:	00001617          	auipc	a2,0x1
ffffffffc0200ed6:	b3660613          	addi	a2,a2,-1226 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200eda:	11f00593          	li	a1,287
ffffffffc0200ede:	00001517          	auipc	a0,0x1
ffffffffc0200ee2:	b4250513          	addi	a0,a0,-1214 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200ee6:	adcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc0200eea:	00001697          	auipc	a3,0x1
ffffffffc0200eee:	d1668693          	addi	a3,a3,-746 # ffffffffc0201c00 <etext+0x5aa>
ffffffffc0200ef2:	00001617          	auipc	a2,0x1
ffffffffc0200ef6:	b1660613          	addi	a2,a2,-1258 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200efa:	11e00593          	li	a1,286
ffffffffc0200efe:	00001517          	auipc	a0,0x1
ffffffffc0200f02:	b2250513          	addi	a0,a0,-1246 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200f06:	abcff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200f0a:	00001697          	auipc	a3,0x1
ffffffffc0200f0e:	ce668693          	addi	a3,a3,-794 # ffffffffc0201bf0 <etext+0x59a>
ffffffffc0200f12:	00001617          	auipc	a2,0x1
ffffffffc0200f16:	af660613          	addi	a2,a2,-1290 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200f1a:	10000593          	li	a1,256
ffffffffc0200f1e:	00001517          	auipc	a0,0x1
ffffffffc0200f22:	b0250513          	addi	a0,a0,-1278 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200f26:	a9cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f2a:	00001697          	auipc	a3,0x1
ffffffffc0200f2e:	c6668693          	addi	a3,a3,-922 # ffffffffc0201b90 <etext+0x53a>
ffffffffc0200f32:	00001617          	auipc	a2,0x1
ffffffffc0200f36:	ad660613          	addi	a2,a2,-1322 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200f3a:	0fe00593          	li	a1,254
ffffffffc0200f3e:	00001517          	auipc	a0,0x1
ffffffffc0200f42:	ae250513          	addi	a0,a0,-1310 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200f46:	a7cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200f4a:	00001697          	auipc	a3,0x1
ffffffffc0200f4e:	c8668693          	addi	a3,a3,-890 # ffffffffc0201bd0 <etext+0x57a>
ffffffffc0200f52:	00001617          	auipc	a2,0x1
ffffffffc0200f56:	ab660613          	addi	a2,a2,-1354 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0200f5a:	0fd00593          	li	a1,253
ffffffffc0200f5e:	00001517          	auipc	a0,0x1
ffffffffc0200f62:	ac250513          	addi	a0,a0,-1342 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc0200f66:	a5cff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200f6a <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200f6a:	1141                	addi	sp,sp,-16
ffffffffc0200f6c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f6e:	14058d63          	beqz	a1,ffffffffc02010c8 <best_fit_free_pages+0x15e>
    for (; p != base + n; p ++) {
ffffffffc0200f72:	00259693          	slli	a3,a1,0x2
ffffffffc0200f76:	96ae                	add	a3,a3,a1
ffffffffc0200f78:	068e                	slli	a3,a3,0x3
ffffffffc0200f7a:	96aa                	add	a3,a3,a0
ffffffffc0200f7c:	87aa                	mv	a5,a0
ffffffffc0200f7e:	00d50e63          	beq	a0,a3,ffffffffc0200f9a <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200f82:	6798                	ld	a4,8(a5)
ffffffffc0200f84:	8b0d                	andi	a4,a4,3
ffffffffc0200f86:	12071163          	bnez	a4,ffffffffc02010a8 <best_fit_free_pages+0x13e>
        p->flags = 0;
ffffffffc0200f8a:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200f8e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f92:	02878793          	addi	a5,a5,40
ffffffffc0200f96:	fed796e3          	bne	a5,a3,ffffffffc0200f82 <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200f9a:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200f9e:	00004617          	auipc	a2,0x4
ffffffffc0200fa2:	07a60613          	addi	a2,a2,122 # ffffffffc0205018 <free_area>
ffffffffc0200fa6:	4a18                	lw	a4,16(a2)
    base->property = n;
ffffffffc0200fa8:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc0200faa:	661c                	ld	a5,8(a2)
    SetPageProperty(base);
ffffffffc0200fac:	0028e693          	ori	a3,a7,2
    base->property = n;
ffffffffc0200fb0:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200fb2:	e514                	sd	a3,8(a0)
    nr_free += n;
ffffffffc0200fb4:	9f2d                	addw	a4,a4,a1
ffffffffc0200fb6:	ca18                	sw	a4,16(a2)
    if (list_empty(&free_list)) {
ffffffffc0200fb8:	00c79763          	bne	a5,a2,ffffffffc0200fc6 <best_fit_free_pages+0x5c>
ffffffffc0200fbc:	a0bd                	j	ffffffffc020102a <best_fit_free_pages+0xc0>
    return listelm->next;
ffffffffc0200fbe:	6794                	ld	a3,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200fc0:	06c68e63          	beq	a3,a2,ffffffffc020103c <best_fit_free_pages+0xd2>
ffffffffc0200fc4:	87b6                	mv	a5,a3
            struct Page* page = le2page(le, page_link);
ffffffffc0200fc6:	fe878713          	addi	a4,a5,-24
ffffffffc0200fca:	86ba                	mv	a3,a4
            if (base < page) {
ffffffffc0200fcc:	fee579e3          	bgeu	a0,a4,ffffffffc0200fbe <best_fit_free_pages+0x54>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200fd0:	0007b803          	ld	a6,0(a5)
                list_add_before(le, &(base->page_link));
ffffffffc0200fd4:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200fd8:	e398                	sd	a4,0(a5)
ffffffffc0200fda:	00e83423          	sd	a4,8(a6)
    elm->next = next;
ffffffffc0200fde:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200fe0:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc0200fe4:	02c80563          	beq	a6,a2,ffffffffc020100e <best_fit_free_pages+0xa4>
        if (p + p->property == base) {
ffffffffc0200fe8:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200fec:	fe880713          	addi	a4,a6,-24
        if (p + p->property == base) {
ffffffffc0200ff0:	020e1313          	slli	t1,t3,0x20
ffffffffc0200ff4:	02035313          	srli	t1,t1,0x20
ffffffffc0200ff8:	00231693          	slli	a3,t1,0x2
ffffffffc0200ffc:	969a                	add	a3,a3,t1
ffffffffc0200ffe:	068e                	slli	a3,a3,0x3
ffffffffc0201000:	96ba                	add	a3,a3,a4
ffffffffc0201002:	06d50263          	beq	a0,a3,ffffffffc0201066 <best_fit_free_pages+0xfc>
    if (le != &free_list) {
ffffffffc0201006:	fe878693          	addi	a3,a5,-24
ffffffffc020100a:	00c78d63          	beq	a5,a2,ffffffffc0201024 <best_fit_free_pages+0xba>
        if (base + base->property == p) {
ffffffffc020100e:	490c                	lw	a1,16(a0)
ffffffffc0201010:	02059613          	slli	a2,a1,0x20
ffffffffc0201014:	9201                	srli	a2,a2,0x20
ffffffffc0201016:	00261713          	slli	a4,a2,0x2
ffffffffc020101a:	9732                	add	a4,a4,a2
ffffffffc020101c:	070e                	slli	a4,a4,0x3
ffffffffc020101e:	972a                	add	a4,a4,a0
ffffffffc0201020:	06e68163          	beq	a3,a4,ffffffffc0201082 <best_fit_free_pages+0x118>
}
ffffffffc0201024:	60a2                	ld	ra,8(sp)
ffffffffc0201026:	0141                	addi	sp,sp,16
ffffffffc0201028:	8082                	ret
ffffffffc020102a:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020102c:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201030:	e398                	sd	a4,0(a5)
ffffffffc0201032:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201034:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201036:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201038:	0141                	addi	sp,sp,16
ffffffffc020103a:	8082                	ret
ffffffffc020103c:	883e                	mv	a6,a5
        if (p + p->property == base) {
ffffffffc020103e:	ff882e03          	lw	t3,-8(a6)
                list_add(le, &(base->page_link));
ffffffffc0201042:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0201046:	e794                	sd	a3,8(a5)
        if (p + p->property == base) {
ffffffffc0201048:	020e1313          	slli	t1,t3,0x20
ffffffffc020104c:	02035313          	srli	t1,t1,0x20
ffffffffc0201050:	e214                	sd	a3,0(a2)
ffffffffc0201052:	00231693          	slli	a3,t1,0x2
ffffffffc0201056:	969a                	add	a3,a3,t1
ffffffffc0201058:	068e                	slli	a3,a3,0x3
    elm->prev = prev;
ffffffffc020105a:	ed1c                	sd	a5,24(a0)
    elm->next = next;
ffffffffc020105c:	f110                	sd	a2,32(a0)
ffffffffc020105e:	96ba                	add	a3,a3,a4
    elm->prev = prev;
ffffffffc0201060:	87b2                	mv	a5,a2
ffffffffc0201062:	fad512e3          	bne	a0,a3,ffffffffc0201006 <best_fit_free_pages+0x9c>
            p->property += base->property;
ffffffffc0201066:	01c585bb          	addw	a1,a1,t3
ffffffffc020106a:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc020106e:	ffd8f893          	andi	a7,a7,-3
ffffffffc0201072:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0201076:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc020107a:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc020107e:	853a                	mv	a0,a4
ffffffffc0201080:	b759                	j	ffffffffc0201006 <best_fit_free_pages+0x9c>
            base->property += p->property;
ffffffffc0201082:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0201086:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020108a:	0007b803          	ld	a6,0(a5)
ffffffffc020108e:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0201090:	9db5                	addw	a1,a1,a3
ffffffffc0201092:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0201094:	9b75                	andi	a4,a4,-3
ffffffffc0201096:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc020109a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020109c:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc02010a0:	01063023          	sd	a6,0(a2)
ffffffffc02010a4:	0141                	addi	sp,sp,16
ffffffffc02010a6:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02010a8:	00001697          	auipc	a3,0x1
ffffffffc02010ac:	c7068693          	addi	a3,a3,-912 # ffffffffc0201d18 <etext+0x6c2>
ffffffffc02010b0:	00001617          	auipc	a2,0x1
ffffffffc02010b4:	95860613          	addi	a2,a2,-1704 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc02010b8:	09600593          	li	a1,150
ffffffffc02010bc:	00001517          	auipc	a0,0x1
ffffffffc02010c0:	96450513          	addi	a0,a0,-1692 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc02010c4:	8feff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc02010c8:	00001697          	auipc	a3,0x1
ffffffffc02010cc:	93868693          	addi	a3,a3,-1736 # ffffffffc0201a00 <etext+0x3aa>
ffffffffc02010d0:	00001617          	auipc	a2,0x1
ffffffffc02010d4:	93860613          	addi	a2,a2,-1736 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc02010d8:	09300593          	li	a1,147
ffffffffc02010dc:	00001517          	auipc	a0,0x1
ffffffffc02010e0:	94450513          	addi	a0,a0,-1724 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc02010e4:	8deff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02010e8 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc02010e8:	1141                	addi	sp,sp,-16
ffffffffc02010ea:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02010ec:	c9dd                	beqz	a1,ffffffffc02011a2 <best_fit_init_memmap+0xba>
    for (; p != base + n; p ++) {
ffffffffc02010ee:	00259693          	slli	a3,a1,0x2
ffffffffc02010f2:	96ae                	add	a3,a3,a1
ffffffffc02010f4:	068e                	slli	a3,a3,0x3
ffffffffc02010f6:	96aa                	add	a3,a3,a0
ffffffffc02010f8:	87aa                	mv	a5,a0
ffffffffc02010fa:	00d50f63          	beq	a0,a3,ffffffffc0201118 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc02010fe:	6798                	ld	a4,8(a5)
ffffffffc0201100:	8b05                	andi	a4,a4,1
ffffffffc0201102:	c341                	beqz	a4,ffffffffc0201182 <best_fit_init_memmap+0x9a>
        p->flags = p->property = 0;
ffffffffc0201104:	0007a823          	sw	zero,16(a5)
ffffffffc0201108:	0007b423          	sd	zero,8(a5)
ffffffffc020110c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201110:	02878793          	addi	a5,a5,40
ffffffffc0201114:	fed795e3          	bne	a5,a3,ffffffffc02010fe <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0201118:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc020111a:	00004697          	auipc	a3,0x4
ffffffffc020111e:	efe68693          	addi	a3,a3,-258 # ffffffffc0205018 <free_area>
ffffffffc0201122:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0201124:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc0201126:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0201128:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc020112c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020112e:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0201130:	9db9                	addw	a1,a1,a4
ffffffffc0201132:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201134:	00d79763          	bne	a5,a3,ffffffffc0201142 <best_fit_init_memmap+0x5a>
ffffffffc0201138:	a01d                	j	ffffffffc020115e <best_fit_init_memmap+0x76>
    return listelm->next;
ffffffffc020113a:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020113c:	02d70a63          	beq	a4,a3,ffffffffc0201170 <best_fit_init_memmap+0x88>
ffffffffc0201140:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201142:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201146:	fee57ae3          	bgeu	a0,a4,ffffffffc020113a <best_fit_init_memmap+0x52>
    __list_add(elm, listelm->prev, listelm);
ffffffffc020114a:	6398                	ld	a4,0(a5)
                list_add_before(le, &(base->page_link));
ffffffffc020114c:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0201150:	e394                	sd	a3,0(a5)
}
ffffffffc0201152:	60a2                	ld	ra,8(sp)
ffffffffc0201154:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0201156:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201158:	ed18                	sd	a4,24(a0)
ffffffffc020115a:	0141                	addi	sp,sp,16
ffffffffc020115c:	8082                	ret
ffffffffc020115e:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201160:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201164:	e398                	sd	a4,0(a5)
ffffffffc0201166:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201168:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020116a:	ed1c                	sd	a5,24(a0)
}
ffffffffc020116c:	0141                	addi	sp,sp,16
ffffffffc020116e:	8082                	ret
ffffffffc0201170:	60a2                	ld	ra,8(sp)
                list_add(le, &(base->page_link));
ffffffffc0201172:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201176:	e798                	sd	a4,8(a5)
ffffffffc0201178:	e298                	sd	a4,0(a3)
    elm->next = next;
ffffffffc020117a:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc020117c:	ed1c                	sd	a5,24(a0)
}
ffffffffc020117e:	0141                	addi	sp,sp,16
ffffffffc0201180:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201182:	00001697          	auipc	a3,0x1
ffffffffc0201186:	bbe68693          	addi	a3,a3,-1090 # ffffffffc0201d40 <etext+0x6ea>
ffffffffc020118a:	00001617          	auipc	a2,0x1
ffffffffc020118e:	87e60613          	addi	a2,a2,-1922 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc0201192:	04a00593          	li	a1,74
ffffffffc0201196:	00001517          	auipc	a0,0x1
ffffffffc020119a:	88a50513          	addi	a0,a0,-1910 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc020119e:	824ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc02011a2:	00001697          	auipc	a3,0x1
ffffffffc02011a6:	85e68693          	addi	a3,a3,-1954 # ffffffffc0201a00 <etext+0x3aa>
ffffffffc02011aa:	00001617          	auipc	a2,0x1
ffffffffc02011ae:	85e60613          	addi	a2,a2,-1954 # ffffffffc0201a08 <etext+0x3b2>
ffffffffc02011b2:	04700593          	li	a1,71
ffffffffc02011b6:	00001517          	auipc	a0,0x1
ffffffffc02011ba:	86a50513          	addi	a0,a0,-1942 # ffffffffc0201a20 <etext+0x3ca>
ffffffffc02011be:	804ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02011c2 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02011c2:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02011c6:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02011c8:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02011ca:	cb81                	beqz	a5,ffffffffc02011da <strlen+0x18>
        cnt ++;
ffffffffc02011cc:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02011ce:	00a707b3          	add	a5,a4,a0
ffffffffc02011d2:	0007c783          	lbu	a5,0(a5)
ffffffffc02011d6:	fbfd                	bnez	a5,ffffffffc02011cc <strlen+0xa>
ffffffffc02011d8:	8082                	ret
    }
    return cnt;
}
ffffffffc02011da:	8082                	ret

ffffffffc02011dc <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02011dc:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02011de:	e589                	bnez	a1,ffffffffc02011e8 <strnlen+0xc>
ffffffffc02011e0:	a811                	j	ffffffffc02011f4 <strnlen+0x18>
        cnt ++;
ffffffffc02011e2:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02011e4:	00f58863          	beq	a1,a5,ffffffffc02011f4 <strnlen+0x18>
ffffffffc02011e8:	00f50733          	add	a4,a0,a5
ffffffffc02011ec:	00074703          	lbu	a4,0(a4) # fffffffffff80000 <end+0x3fd7af88>
ffffffffc02011f0:	fb6d                	bnez	a4,ffffffffc02011e2 <strnlen+0x6>
ffffffffc02011f2:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02011f4:	852e                	mv	a0,a1
ffffffffc02011f6:	8082                	ret

ffffffffc02011f8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02011f8:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02011fc:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201200:	cb89                	beqz	a5,ffffffffc0201212 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201202:	0505                	addi	a0,a0,1
ffffffffc0201204:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201206:	fee789e3          	beq	a5,a4,ffffffffc02011f8 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020120a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020120e:	9d19                	subw	a0,a0,a4
ffffffffc0201210:	8082                	ret
ffffffffc0201212:	4501                	li	a0,0
ffffffffc0201214:	bfed                	j	ffffffffc020120e <strcmp+0x16>

ffffffffc0201216 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201216:	c20d                	beqz	a2,ffffffffc0201238 <strncmp+0x22>
ffffffffc0201218:	962e                	add	a2,a2,a1
ffffffffc020121a:	a031                	j	ffffffffc0201226 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc020121c:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020121e:	00e79a63          	bne	a5,a4,ffffffffc0201232 <strncmp+0x1c>
ffffffffc0201222:	00b60b63          	beq	a2,a1,ffffffffc0201238 <strncmp+0x22>
ffffffffc0201226:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020122a:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020122c:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201230:	f7f5                	bnez	a5,ffffffffc020121c <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201232:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201236:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201238:	4501                	li	a0,0
ffffffffc020123a:	8082                	ret

ffffffffc020123c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020123c:	ca01                	beqz	a2,ffffffffc020124c <memset+0x10>
ffffffffc020123e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201240:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201242:	0785                	addi	a5,a5,1
ffffffffc0201244:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201248:	fec79de3          	bne	a5,a2,ffffffffc0201242 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020124c:	8082                	ret

ffffffffc020124e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020124e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201252:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201254:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201258:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020125a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020125e:	f022                	sd	s0,32(sp)
ffffffffc0201260:	ec26                	sd	s1,24(sp)
ffffffffc0201262:	e84a                	sd	s2,16(sp)
ffffffffc0201264:	f406                	sd	ra,40(sp)
ffffffffc0201266:	e44e                	sd	s3,8(sp)
ffffffffc0201268:	84aa                	mv	s1,a0
ffffffffc020126a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020126c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201270:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201272:	03067e63          	bgeu	a2,a6,ffffffffc02012ae <printnum+0x60>
ffffffffc0201276:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201278:	00805763          	blez	s0,ffffffffc0201286 <printnum+0x38>
ffffffffc020127c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020127e:	85ca                	mv	a1,s2
ffffffffc0201280:	854e                	mv	a0,s3
ffffffffc0201282:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201284:	fc65                	bnez	s0,ffffffffc020127c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201286:	1a02                	slli	s4,s4,0x20
ffffffffc0201288:	00001797          	auipc	a5,0x1
ffffffffc020128c:	b1878793          	addi	a5,a5,-1256 # ffffffffc0201da0 <best_fit_pmm_manager+0x38>
ffffffffc0201290:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201294:	9a3e                	add	s4,s4,a5
}
ffffffffc0201296:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201298:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020129c:	70a2                	ld	ra,40(sp)
ffffffffc020129e:	69a2                	ld	s3,8(sp)
ffffffffc02012a0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012a2:	85ca                	mv	a1,s2
ffffffffc02012a4:	87a6                	mv	a5,s1
}
ffffffffc02012a6:	6942                	ld	s2,16(sp)
ffffffffc02012a8:	64e2                	ld	s1,24(sp)
ffffffffc02012aa:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012ac:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02012ae:	03065633          	divu	a2,a2,a6
ffffffffc02012b2:	8722                	mv	a4,s0
ffffffffc02012b4:	f9bff0ef          	jal	ra,ffffffffc020124e <printnum>
ffffffffc02012b8:	b7f9                	j	ffffffffc0201286 <printnum+0x38>

ffffffffc02012ba <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02012ba:	7119                	addi	sp,sp,-128
ffffffffc02012bc:	f4a6                	sd	s1,104(sp)
ffffffffc02012be:	f0ca                	sd	s2,96(sp)
ffffffffc02012c0:	ecce                	sd	s3,88(sp)
ffffffffc02012c2:	e8d2                	sd	s4,80(sp)
ffffffffc02012c4:	e4d6                	sd	s5,72(sp)
ffffffffc02012c6:	e0da                	sd	s6,64(sp)
ffffffffc02012c8:	fc5e                	sd	s7,56(sp)
ffffffffc02012ca:	f06a                	sd	s10,32(sp)
ffffffffc02012cc:	fc86                	sd	ra,120(sp)
ffffffffc02012ce:	f8a2                	sd	s0,112(sp)
ffffffffc02012d0:	f862                	sd	s8,48(sp)
ffffffffc02012d2:	f466                	sd	s9,40(sp)
ffffffffc02012d4:	ec6e                	sd	s11,24(sp)
ffffffffc02012d6:	892a                	mv	s2,a0
ffffffffc02012d8:	84ae                	mv	s1,a1
ffffffffc02012da:	8d32                	mv	s10,a2
ffffffffc02012dc:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012de:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02012e2:	5b7d                	li	s6,-1
ffffffffc02012e4:	00001a97          	auipc	s5,0x1
ffffffffc02012e8:	af0a8a93          	addi	s5,s5,-1296 # ffffffffc0201dd4 <best_fit_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02012ec:	00001b97          	auipc	s7,0x1
ffffffffc02012f0:	cc4b8b93          	addi	s7,s7,-828 # ffffffffc0201fb0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012f4:	000d4503          	lbu	a0,0(s10)
ffffffffc02012f8:	001d0413          	addi	s0,s10,1
ffffffffc02012fc:	01350a63          	beq	a0,s3,ffffffffc0201310 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201300:	c121                	beqz	a0,ffffffffc0201340 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201302:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201304:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201306:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201308:	fff44503          	lbu	a0,-1(s0)
ffffffffc020130c:	ff351ae3          	bne	a0,s3,ffffffffc0201300 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201310:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201314:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201318:	4c81                	li	s9,0
ffffffffc020131a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020131c:	5c7d                	li	s8,-1
ffffffffc020131e:	5dfd                	li	s11,-1
ffffffffc0201320:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201324:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201326:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020132a:	0ff5f593          	zext.b	a1,a1
ffffffffc020132e:	00140d13          	addi	s10,s0,1
ffffffffc0201332:	04b56263          	bltu	a0,a1,ffffffffc0201376 <vprintfmt+0xbc>
ffffffffc0201336:	058a                	slli	a1,a1,0x2
ffffffffc0201338:	95d6                	add	a1,a1,s5
ffffffffc020133a:	4194                	lw	a3,0(a1)
ffffffffc020133c:	96d6                	add	a3,a3,s5
ffffffffc020133e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201340:	70e6                	ld	ra,120(sp)
ffffffffc0201342:	7446                	ld	s0,112(sp)
ffffffffc0201344:	74a6                	ld	s1,104(sp)
ffffffffc0201346:	7906                	ld	s2,96(sp)
ffffffffc0201348:	69e6                	ld	s3,88(sp)
ffffffffc020134a:	6a46                	ld	s4,80(sp)
ffffffffc020134c:	6aa6                	ld	s5,72(sp)
ffffffffc020134e:	6b06                	ld	s6,64(sp)
ffffffffc0201350:	7be2                	ld	s7,56(sp)
ffffffffc0201352:	7c42                	ld	s8,48(sp)
ffffffffc0201354:	7ca2                	ld	s9,40(sp)
ffffffffc0201356:	7d02                	ld	s10,32(sp)
ffffffffc0201358:	6de2                	ld	s11,24(sp)
ffffffffc020135a:	6109                	addi	sp,sp,128
ffffffffc020135c:	8082                	ret
            padc = '0';
ffffffffc020135e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201360:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201364:	846a                	mv	s0,s10
ffffffffc0201366:	00140d13          	addi	s10,s0,1
ffffffffc020136a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020136e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201372:	fcb572e3          	bgeu	a0,a1,ffffffffc0201336 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201376:	85a6                	mv	a1,s1
ffffffffc0201378:	02500513          	li	a0,37
ffffffffc020137c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020137e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201382:	8d22                	mv	s10,s0
ffffffffc0201384:	f73788e3          	beq	a5,s3,ffffffffc02012f4 <vprintfmt+0x3a>
ffffffffc0201388:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020138c:	1d7d                	addi	s10,s10,-1
ffffffffc020138e:	ff379de3          	bne	a5,s3,ffffffffc0201388 <vprintfmt+0xce>
ffffffffc0201392:	b78d                	j	ffffffffc02012f4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201394:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201398:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020139c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020139e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02013a2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02013a6:	02d86463          	bltu	a6,a3,ffffffffc02013ce <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02013aa:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02013ae:	002c169b          	slliw	a3,s8,0x2
ffffffffc02013b2:	0186873b          	addw	a4,a3,s8
ffffffffc02013b6:	0017171b          	slliw	a4,a4,0x1
ffffffffc02013ba:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02013bc:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02013c0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02013c2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02013c6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02013ca:	fed870e3          	bgeu	a6,a3,ffffffffc02013aa <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02013ce:	f40ddce3          	bgez	s11,ffffffffc0201326 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02013d2:	8de2                	mv	s11,s8
ffffffffc02013d4:	5c7d                	li	s8,-1
ffffffffc02013d6:	bf81                	j	ffffffffc0201326 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02013d8:	fffdc693          	not	a3,s11
ffffffffc02013dc:	96fd                	srai	a3,a3,0x3f
ffffffffc02013de:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013e2:	00144603          	lbu	a2,1(s0)
ffffffffc02013e6:	2d81                	sext.w	s11,s11
ffffffffc02013e8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013ea:	bf35                	j	ffffffffc0201326 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02013ec:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013f0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02013f4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013f6:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02013f8:	bfd9                	j	ffffffffc02013ce <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02013fa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013fc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201400:	01174463          	blt	a4,a7,ffffffffc0201408 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201404:	1a088e63          	beqz	a7,ffffffffc02015c0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201408:	000a3603          	ld	a2,0(s4)
ffffffffc020140c:	46c1                	li	a3,16
ffffffffc020140e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201410:	2781                	sext.w	a5,a5
ffffffffc0201412:	876e                	mv	a4,s11
ffffffffc0201414:	85a6                	mv	a1,s1
ffffffffc0201416:	854a                	mv	a0,s2
ffffffffc0201418:	e37ff0ef          	jal	ra,ffffffffc020124e <printnum>
            break;
ffffffffc020141c:	bde1                	j	ffffffffc02012f4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020141e:	000a2503          	lw	a0,0(s4)
ffffffffc0201422:	85a6                	mv	a1,s1
ffffffffc0201424:	0a21                	addi	s4,s4,8
ffffffffc0201426:	9902                	jalr	s2
            break;
ffffffffc0201428:	b5f1                	j	ffffffffc02012f4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020142a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020142c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201430:	01174463          	blt	a4,a7,ffffffffc0201438 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201434:	18088163          	beqz	a7,ffffffffc02015b6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201438:	000a3603          	ld	a2,0(s4)
ffffffffc020143c:	46a9                	li	a3,10
ffffffffc020143e:	8a2e                	mv	s4,a1
ffffffffc0201440:	bfc1                	j	ffffffffc0201410 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201442:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201446:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201448:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020144a:	bdf1                	j	ffffffffc0201326 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020144c:	85a6                	mv	a1,s1
ffffffffc020144e:	02500513          	li	a0,37
ffffffffc0201452:	9902                	jalr	s2
            break;
ffffffffc0201454:	b545                	j	ffffffffc02012f4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201456:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020145a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020145c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020145e:	b5e1                	j	ffffffffc0201326 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201460:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201462:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201466:	01174463          	blt	a4,a7,ffffffffc020146e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020146a:	14088163          	beqz	a7,ffffffffc02015ac <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020146e:	000a3603          	ld	a2,0(s4)
ffffffffc0201472:	46a1                	li	a3,8
ffffffffc0201474:	8a2e                	mv	s4,a1
ffffffffc0201476:	bf69                	j	ffffffffc0201410 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201478:	03000513          	li	a0,48
ffffffffc020147c:	85a6                	mv	a1,s1
ffffffffc020147e:	e03e                	sd	a5,0(sp)
ffffffffc0201480:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201482:	85a6                	mv	a1,s1
ffffffffc0201484:	07800513          	li	a0,120
ffffffffc0201488:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020148a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020148c:	6782                	ld	a5,0(sp)
ffffffffc020148e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201490:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201494:	bfb5                	j	ffffffffc0201410 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201496:	000a3403          	ld	s0,0(s4)
ffffffffc020149a:	008a0713          	addi	a4,s4,8
ffffffffc020149e:	e03a                	sd	a4,0(sp)
ffffffffc02014a0:	14040263          	beqz	s0,ffffffffc02015e4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02014a4:	0fb05763          	blez	s11,ffffffffc0201592 <vprintfmt+0x2d8>
ffffffffc02014a8:	02d00693          	li	a3,45
ffffffffc02014ac:	0cd79163          	bne	a5,a3,ffffffffc020156e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014b0:	00044783          	lbu	a5,0(s0)
ffffffffc02014b4:	0007851b          	sext.w	a0,a5
ffffffffc02014b8:	cf85                	beqz	a5,ffffffffc02014f0 <vprintfmt+0x236>
ffffffffc02014ba:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014be:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014c2:	000c4563          	bltz	s8,ffffffffc02014cc <vprintfmt+0x212>
ffffffffc02014c6:	3c7d                	addiw	s8,s8,-1
ffffffffc02014c8:	036c0263          	beq	s8,s6,ffffffffc02014ec <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02014cc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014ce:	0e0c8e63          	beqz	s9,ffffffffc02015ca <vprintfmt+0x310>
ffffffffc02014d2:	3781                	addiw	a5,a5,-32
ffffffffc02014d4:	0ef47b63          	bgeu	s0,a5,ffffffffc02015ca <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02014d8:	03f00513          	li	a0,63
ffffffffc02014dc:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014de:	000a4783          	lbu	a5,0(s4)
ffffffffc02014e2:	3dfd                	addiw	s11,s11,-1
ffffffffc02014e4:	0a05                	addi	s4,s4,1
ffffffffc02014e6:	0007851b          	sext.w	a0,a5
ffffffffc02014ea:	ffe1                	bnez	a5,ffffffffc02014c2 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02014ec:	01b05963          	blez	s11,ffffffffc02014fe <vprintfmt+0x244>
ffffffffc02014f0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02014f2:	85a6                	mv	a1,s1
ffffffffc02014f4:	02000513          	li	a0,32
ffffffffc02014f8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02014fa:	fe0d9be3          	bnez	s11,ffffffffc02014f0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014fe:	6a02                	ld	s4,0(sp)
ffffffffc0201500:	bbd5                	j	ffffffffc02012f4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201502:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201504:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201508:	01174463          	blt	a4,a7,ffffffffc0201510 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020150c:	08088d63          	beqz	a7,ffffffffc02015a6 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201510:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201514:	0a044d63          	bltz	s0,ffffffffc02015ce <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201518:	8622                	mv	a2,s0
ffffffffc020151a:	8a66                	mv	s4,s9
ffffffffc020151c:	46a9                	li	a3,10
ffffffffc020151e:	bdcd                	j	ffffffffc0201410 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201520:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201524:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201526:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201528:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020152c:	8fb5                	xor	a5,a5,a3
ffffffffc020152e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201532:	02d74163          	blt	a4,a3,ffffffffc0201554 <vprintfmt+0x29a>
ffffffffc0201536:	00369793          	slli	a5,a3,0x3
ffffffffc020153a:	97de                	add	a5,a5,s7
ffffffffc020153c:	639c                	ld	a5,0(a5)
ffffffffc020153e:	cb99                	beqz	a5,ffffffffc0201554 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201540:	86be                	mv	a3,a5
ffffffffc0201542:	00001617          	auipc	a2,0x1
ffffffffc0201546:	88e60613          	addi	a2,a2,-1906 # ffffffffc0201dd0 <best_fit_pmm_manager+0x68>
ffffffffc020154a:	85a6                	mv	a1,s1
ffffffffc020154c:	854a                	mv	a0,s2
ffffffffc020154e:	0ce000ef          	jal	ra,ffffffffc020161c <printfmt>
ffffffffc0201552:	b34d                	j	ffffffffc02012f4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201554:	00001617          	auipc	a2,0x1
ffffffffc0201558:	86c60613          	addi	a2,a2,-1940 # ffffffffc0201dc0 <best_fit_pmm_manager+0x58>
ffffffffc020155c:	85a6                	mv	a1,s1
ffffffffc020155e:	854a                	mv	a0,s2
ffffffffc0201560:	0bc000ef          	jal	ra,ffffffffc020161c <printfmt>
ffffffffc0201564:	bb41                	j	ffffffffc02012f4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201566:	00001417          	auipc	s0,0x1
ffffffffc020156a:	85240413          	addi	s0,s0,-1966 # ffffffffc0201db8 <best_fit_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020156e:	85e2                	mv	a1,s8
ffffffffc0201570:	8522                	mv	a0,s0
ffffffffc0201572:	e43e                	sd	a5,8(sp)
ffffffffc0201574:	c69ff0ef          	jal	ra,ffffffffc02011dc <strnlen>
ffffffffc0201578:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020157c:	01b05b63          	blez	s11,ffffffffc0201592 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201580:	67a2                	ld	a5,8(sp)
ffffffffc0201582:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201586:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201588:	85a6                	mv	a1,s1
ffffffffc020158a:	8552                	mv	a0,s4
ffffffffc020158c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020158e:	fe0d9ce3          	bnez	s11,ffffffffc0201586 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201592:	00044783          	lbu	a5,0(s0)
ffffffffc0201596:	00140a13          	addi	s4,s0,1
ffffffffc020159a:	0007851b          	sext.w	a0,a5
ffffffffc020159e:	d3a5                	beqz	a5,ffffffffc02014fe <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02015a0:	05e00413          	li	s0,94
ffffffffc02015a4:	bf39                	j	ffffffffc02014c2 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02015a6:	000a2403          	lw	s0,0(s4)
ffffffffc02015aa:	b7ad                	j	ffffffffc0201514 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02015ac:	000a6603          	lwu	a2,0(s4)
ffffffffc02015b0:	46a1                	li	a3,8
ffffffffc02015b2:	8a2e                	mv	s4,a1
ffffffffc02015b4:	bdb1                	j	ffffffffc0201410 <vprintfmt+0x156>
ffffffffc02015b6:	000a6603          	lwu	a2,0(s4)
ffffffffc02015ba:	46a9                	li	a3,10
ffffffffc02015bc:	8a2e                	mv	s4,a1
ffffffffc02015be:	bd89                	j	ffffffffc0201410 <vprintfmt+0x156>
ffffffffc02015c0:	000a6603          	lwu	a2,0(s4)
ffffffffc02015c4:	46c1                	li	a3,16
ffffffffc02015c6:	8a2e                	mv	s4,a1
ffffffffc02015c8:	b5a1                	j	ffffffffc0201410 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02015ca:	9902                	jalr	s2
ffffffffc02015cc:	bf09                	j	ffffffffc02014de <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02015ce:	85a6                	mv	a1,s1
ffffffffc02015d0:	02d00513          	li	a0,45
ffffffffc02015d4:	e03e                	sd	a5,0(sp)
ffffffffc02015d6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02015d8:	6782                	ld	a5,0(sp)
ffffffffc02015da:	8a66                	mv	s4,s9
ffffffffc02015dc:	40800633          	neg	a2,s0
ffffffffc02015e0:	46a9                	li	a3,10
ffffffffc02015e2:	b53d                	j	ffffffffc0201410 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02015e4:	03b05163          	blez	s11,ffffffffc0201606 <vprintfmt+0x34c>
ffffffffc02015e8:	02d00693          	li	a3,45
ffffffffc02015ec:	f6d79de3          	bne	a5,a3,ffffffffc0201566 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02015f0:	00000417          	auipc	s0,0x0
ffffffffc02015f4:	7c840413          	addi	s0,s0,1992 # ffffffffc0201db8 <best_fit_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015f8:	02800793          	li	a5,40
ffffffffc02015fc:	02800513          	li	a0,40
ffffffffc0201600:	00140a13          	addi	s4,s0,1
ffffffffc0201604:	bd6d                	j	ffffffffc02014be <vprintfmt+0x204>
ffffffffc0201606:	00000a17          	auipc	s4,0x0
ffffffffc020160a:	7b3a0a13          	addi	s4,s4,1971 # ffffffffc0201db9 <best_fit_pmm_manager+0x51>
ffffffffc020160e:	02800513          	li	a0,40
ffffffffc0201612:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201616:	05e00413          	li	s0,94
ffffffffc020161a:	b565                	j	ffffffffc02014c2 <vprintfmt+0x208>

ffffffffc020161c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020161c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020161e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201622:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201624:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201626:	ec06                	sd	ra,24(sp)
ffffffffc0201628:	f83a                	sd	a4,48(sp)
ffffffffc020162a:	fc3e                	sd	a5,56(sp)
ffffffffc020162c:	e0c2                	sd	a6,64(sp)
ffffffffc020162e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201630:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201632:	c89ff0ef          	jal	ra,ffffffffc02012ba <vprintfmt>
}
ffffffffc0201636:	60e2                	ld	ra,24(sp)
ffffffffc0201638:	6161                	addi	sp,sp,80
ffffffffc020163a:	8082                	ret

ffffffffc020163c <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020163c:	4781                	li	a5,0
ffffffffc020163e:	00004717          	auipc	a4,0x4
ffffffffc0201642:	9d273703          	ld	a4,-1582(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201646:	88ba                	mv	a7,a4
ffffffffc0201648:	852a                	mv	a0,a0
ffffffffc020164a:	85be                	mv	a1,a5
ffffffffc020164c:	863e                	mv	a2,a5
ffffffffc020164e:	00000073          	ecall
ffffffffc0201652:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201654:	8082                	ret
