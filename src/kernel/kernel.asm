
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8d070713          	addi	a4,a4,-1840 # 80008920 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	26e78793          	addi	a5,a5,622 # 800062d0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffbb857>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	fa478793          	addi	a5,a5,-92 # 80001050 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	692080e7          	jalr	1682(ra) # 800027bc <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8d650513          	addi	a0,a0,-1834 # 80010a60 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	c1c080e7          	jalr	-996(ra) # 80000dae <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8c648493          	addi	s1,s1,-1850 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	95690913          	addi	s2,s2,-1706 # 80010af8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	a92080e7          	jalr	-1390(ra) # 80001c52 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	43e080e7          	jalr	1086(ra) # 80002606 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	17c080e7          	jalr	380(ra) # 80002352 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	554080e7          	jalr	1364(ra) # 80002766 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	83a50513          	addi	a0,a0,-1990 # 80010a60 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	c34080e7          	jalr	-972(ra) # 80000e62 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	82450513          	addi	a0,a0,-2012 # 80010a60 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	c1e080e7          	jalr	-994(ra) # 80000e62 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	88f72323          	sw	a5,-1914(a4) # 80010af8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	79450513          	addi	a0,a0,1940 # 80010a60 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	ada080e7          	jalr	-1318(ra) # 80000dae <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	520080e7          	jalr	1312(ra) # 80002812 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	76650513          	addi	a0,a0,1894 # 80010a60 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	b60080e7          	jalr	-1184(ra) # 80000e62 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	74270713          	addi	a4,a4,1858 # 80010a60 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	71878793          	addi	a5,a5,1816 # 80010a60 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7827a783          	lw	a5,1922(a5) # 80010af8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6d670713          	addi	a4,a4,1750 # 80010a60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6c648493          	addi	s1,s1,1734 # 80010a60 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	68a70713          	addi	a4,a4,1674 # 80010a60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72a23          	sw	a5,1812(a4) # 80010b00 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	64e78793          	addi	a5,a5,1614 # 80010a60 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6cc7a323          	sw	a2,1734(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ba50513          	addi	a0,a0,1722 # 80010af8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f70080e7          	jalr	-144(ra) # 800023b6 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	60050513          	addi	a0,a0,1536 # 80010a60 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	8b6080e7          	jalr	-1866(ra) # 80000d1e <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00042797          	auipc	a5,0x42
    8000047c:	99878793          	addi	a5,a5,-1640 # 80041e10 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07aa23          	sw	zero,1492(a5) # 80010b20 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b6a50513          	addi	a0,a0,-1174 # 800080d8 <digits+0x98>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	36f72023          	sw	a5,864(a4) # 800088e0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	564dad83          	lw	s11,1380(s11) # 80010b20 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	50e50513          	addi	a0,a0,1294 # 80010b08 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	7ac080e7          	jalr	1964(ra) # 80000dae <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3b050513          	addi	a0,a0,944 # 80010b08 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	702080e7          	jalr	1794(ra) # 80000e62 <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	39448493          	addi	s1,s1,916 # 80010b08 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	598080e7          	jalr	1432(ra) # 80000d1e <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	35450513          	addi	a0,a0,852 # 80010b28 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	542080e7          	jalr	1346(ra) # 80000d1e <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	56a080e7          	jalr	1386(ra) # 80000d62 <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0e07a783          	lw	a5,224(a5) # 800088e0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	5dc080e7          	jalr	1500(ra) # 80000e02 <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0b07b783          	ld	a5,176(a5) # 800088e8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0b073703          	ld	a4,176(a4) # 800088f0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2c6a0a13          	addi	s4,s4,710 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	07e48493          	addi	s1,s1,126 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	07e98993          	addi	s3,s3,126 # 800088f0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	b22080e7          	jalr	-1246(ra) # 800023b6 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	25850513          	addi	a0,a0,600 # 80010b28 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	4d6080e7          	jalr	1238(ra) # 80000dae <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0007a783          	lw	a5,0(a5) # 800088e0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	00673703          	ld	a4,6(a4) # 800088f0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	ff67b783          	ld	a5,-10(a5) # 800088e8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	22a98993          	addi	s3,s3,554 # 80010b28 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fe248493          	addi	s1,s1,-30 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fe290913          	addi	s2,s2,-30 # 800088f0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	a34080e7          	jalr	-1484(ra) # 80002352 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1f448493          	addi	s1,s1,500 # 80010b28 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fae7b423          	sd	a4,-88(a5) # 800088f0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	508080e7          	jalr	1288(ra) # 80000e62 <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	16e48493          	addi	s1,s1,366 # 80010b28 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	3ea080e7          	jalr	1002(ra) # 80000dae <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	48c080e7          	jalr	1164(ra) # 80000e62 <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    800009f4:	00010517          	auipc	a0,0x10
    800009f8:	16c50513          	addi	a0,a0,364 # 80010b60 <kmem>
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	3b2080e7          	jalr	946(ra) # 80000dae <acquire>
  r = kmem.freelist;
    80000a04:	00010497          	auipc	s1,0x10
    80000a08:	1744b483          	ld	s1,372(s1) # 80010b78 <kmem+0x18>
  if(r)
    80000a0c:	c4b5                	beqz	s1,80000a78 <kalloc+0x90>
    kmem.freelist = r->next;
    80000a0e:	609c                	ld	a5,0(s1)
    80000a10:	00010917          	auipc	s2,0x10
    80000a14:	15090913          	addi	s2,s2,336 # 80010b60 <kmem>
    80000a18:	00f93c23          	sd	a5,24(s2)
  release(&kmem.lock);
    80000a1c:	854a                	mv	a0,s2
    80000a1e:	00000097          	auipc	ra,0x0
    80000a22:	444080e7          	jalr	1092(ra) # 80000e62 <release>

  if(r){
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4595                	li	a1,5
    80000a2a:	8526                	mv	a0,s1
    80000a2c:	00000097          	auipc	ra,0x0
    80000a30:	47e080e7          	jalr	1150(ra) # 80000eaa <memset>

    acquire(&kmem.lock_count);
    80000a34:	00030517          	auipc	a0,0x30
    80000a38:	14c50513          	addi	a0,a0,332 # 80030b80 <kmem+0x20020>
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	372080e7          	jalr	882(ra) # 80000dae <acquire>

}

int get_ind(void* pa){

  return ((uint64)pa-KERNBASE)/PGSIZE;
    80000a44:	800007b7          	lui	a5,0x80000
    80000a48:	97a6                	add	a5,a5,s1
    80000a4a:	83b1                	srli	a5,a5,0xc
    kmem.total_count[get_ind(r)]=1;
    80000a4c:	2781                	sext.w	a5,a5
    80000a4e:	07a1                	addi	a5,a5,8 # ffffffff80000008 <end+0xfffffffefffbd060>
    80000a50:	078a                	slli	a5,a5,0x2
    80000a52:	993e                	add	s2,s2,a5
    80000a54:	4785                	li	a5,1
    80000a56:	00f92023          	sw	a5,0(s2)
    release(&kmem.lock_count);}
    80000a5a:	00030517          	auipc	a0,0x30
    80000a5e:	12650513          	addi	a0,a0,294 # 80030b80 <kmem+0x20020>
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	400080e7          	jalr	1024(ra) # 80000e62 <release>
}
    80000a6a:	8526                	mv	a0,s1
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6902                	ld	s2,0(sp)
    80000a74:	6105                	addi	sp,sp,32
    80000a76:	8082                	ret
  release(&kmem.lock);
    80000a78:	00010517          	auipc	a0,0x10
    80000a7c:	0e850513          	addi	a0,a0,232 # 80010b60 <kmem>
    80000a80:	00000097          	auipc	ra,0x0
    80000a84:	3e2080e7          	jalr	994(ra) # 80000e62 <release>
  if(r){
    80000a88:	b7cd                	j	80000a6a <kalloc+0x82>

0000000080000a8a <inc_count>:
void inc_count(void* pa){
    80000a8a:	1101                	addi	sp,sp,-32
    80000a8c:	ec06                	sd	ra,24(sp)
    80000a8e:	e822                	sd	s0,16(sp)
    80000a90:	e426                	sd	s1,8(sp)
    80000a92:	1000                	addi	s0,sp,32
    80000a94:	84aa                	mv	s1,a0
  acquire(&kmem.lock_count);
    80000a96:	00030517          	auipc	a0,0x30
    80000a9a:	0ea50513          	addi	a0,a0,234 # 80030b80 <kmem+0x20020>
    80000a9e:	00000097          	auipc	ra,0x0
    80000aa2:	310080e7          	jalr	784(ra) # 80000dae <acquire>
  return ((uint64)pa-KERNBASE)/PGSIZE;
    80000aa6:	800007b7          	lui	a5,0x80000
    80000aaa:	97a6                	add	a5,a5,s1
    80000aac:	83b1                	srli	a5,a5,0xc
    80000aae:	2781                	sext.w	a5,a5
  kmem.total_count[get_ind(pa)]++;
    80000ab0:	07a1                	addi	a5,a5,8 # ffffffff80000008 <end+0xfffffffefffbd060>
    80000ab2:	078a                	slli	a5,a5,0x2
    80000ab4:	00010717          	auipc	a4,0x10
    80000ab8:	0ac70713          	addi	a4,a4,172 # 80010b60 <kmem>
    80000abc:	97ba                	add	a5,a5,a4
    80000abe:	4398                	lw	a4,0(a5)
    80000ac0:	2705                	addiw	a4,a4,1
    80000ac2:	c398                	sw	a4,0(a5)
  release(&kmem.lock_count);
    80000ac4:	00030517          	auipc	a0,0x30
    80000ac8:	0bc50513          	addi	a0,a0,188 # 80030b80 <kmem+0x20020>
    80000acc:	00000097          	auipc	ra,0x0
    80000ad0:	396080e7          	jalr	918(ra) # 80000e62 <release>
}
    80000ad4:	60e2                	ld	ra,24(sp)
    80000ad6:	6442                	ld	s0,16(sp)
    80000ad8:	64a2                	ld	s1,8(sp)
    80000ada:	6105                	addi	sp,sp,32
    80000adc:	8082                	ret

0000000080000ade <dec_count>:
void dec_count(void* pa){
    80000ade:	1101                	addi	sp,sp,-32
    80000ae0:	ec06                	sd	ra,24(sp)
    80000ae2:	e822                	sd	s0,16(sp)
    80000ae4:	e426                	sd	s1,8(sp)
    80000ae6:	1000                	addi	s0,sp,32
    80000ae8:	84aa                	mv	s1,a0
  acquire(&kmem.lock_count);
    80000aea:	00030517          	auipc	a0,0x30
    80000aee:	09650513          	addi	a0,a0,150 # 80030b80 <kmem+0x20020>
    80000af2:	00000097          	auipc	ra,0x0
    80000af6:	2bc080e7          	jalr	700(ra) # 80000dae <acquire>
  return ((uint64)pa-KERNBASE)/PGSIZE;
    80000afa:	800007b7          	lui	a5,0x80000
    80000afe:	97a6                	add	a5,a5,s1
    80000b00:	83b1                	srli	a5,a5,0xc
    80000b02:	2781                	sext.w	a5,a5
  kmem.total_count[get_ind(pa)]--;
    80000b04:	07a1                	addi	a5,a5,8 # ffffffff80000008 <end+0xfffffffefffbd060>
    80000b06:	078a                	slli	a5,a5,0x2
    80000b08:	00010717          	auipc	a4,0x10
    80000b0c:	05870713          	addi	a4,a4,88 # 80010b60 <kmem>
    80000b10:	97ba                	add	a5,a5,a4
    80000b12:	4398                	lw	a4,0(a5)
    80000b14:	377d                	addiw	a4,a4,-1
    80000b16:	c398                	sw	a4,0(a5)
  release(&kmem.lock_count);
    80000b18:	00030517          	auipc	a0,0x30
    80000b1c:	06850513          	addi	a0,a0,104 # 80030b80 <kmem+0x20020>
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	342080e7          	jalr	834(ra) # 80000e62 <release>
}
    80000b28:	60e2                	ld	ra,24(sp)
    80000b2a:	6442                	ld	s0,16(sp)
    80000b2c:	64a2                	ld	s1,8(sp)
    80000b2e:	6105                	addi	sp,sp,32
    80000b30:	8082                	ret

0000000080000b32 <get_count>:
int get_count(void* pa){
    80000b32:	1101                	addi	sp,sp,-32
    80000b34:	ec06                	sd	ra,24(sp)
    80000b36:	e822                	sd	s0,16(sp)
    80000b38:	e426                	sd	s1,8(sp)
    80000b3a:	1000                	addi	s0,sp,32
    80000b3c:	84aa                	mv	s1,a0
  acquire(&kmem.lock_count);
    80000b3e:	00030517          	auipc	a0,0x30
    80000b42:	04250513          	addi	a0,a0,66 # 80030b80 <kmem+0x20020>
    80000b46:	00000097          	auipc	ra,0x0
    80000b4a:	268080e7          	jalr	616(ra) # 80000dae <acquire>
  return ((uint64)pa-KERNBASE)/PGSIZE;
    80000b4e:	800007b7          	lui	a5,0x80000
    80000b52:	97a6                	add	a5,a5,s1
    80000b54:	83b1                	srli	a5,a5,0xc
  count = kmem.total_count[get_ind(pa)];
    80000b56:	2781                	sext.w	a5,a5
    80000b58:	07a1                	addi	a5,a5,8 # ffffffff80000008 <end+0xfffffffefffbd060>
    80000b5a:	078a                	slli	a5,a5,0x2
    80000b5c:	00010717          	auipc	a4,0x10
    80000b60:	00470713          	addi	a4,a4,4 # 80010b60 <kmem>
    80000b64:	97ba                	add	a5,a5,a4
    80000b66:	4384                	lw	s1,0(a5)
  release(&kmem.lock_count);
    80000b68:	00030517          	auipc	a0,0x30
    80000b6c:	01850513          	addi	a0,a0,24 # 80030b80 <kmem+0x20020>
    80000b70:	00000097          	auipc	ra,0x0
    80000b74:	2f2080e7          	jalr	754(ra) # 80000e62 <release>
}
    80000b78:	8526                	mv	a0,s1
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <kfree>:
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000b8e:	03451793          	slli	a5,a0,0x34
    80000b92:	e3b9                	bnez	a5,80000bd8 <kfree+0x54>
    80000b94:	84aa                	mv	s1,a0
    80000b96:	00042797          	auipc	a5,0x42
    80000b9a:	41278793          	addi	a5,a5,1042 # 80042fa8 <end>
    80000b9e:	02f56d63          	bltu	a0,a5,80000bd8 <kfree+0x54>
    80000ba2:	47c5                	li	a5,17
    80000ba4:	07ee                	slli	a5,a5,0x1b
    80000ba6:	02f57963          	bgeu	a0,a5,80000bd8 <kfree+0x54>
  int x=get_count(pa);
    80000baa:	00000097          	auipc	ra,0x0
    80000bae:	f88080e7          	jalr	-120(ra) # 80000b32 <get_count>
  if(x<=0)panic("kfree");
    80000bb2:	02a05b63          	blez	a0,80000be8 <kfree+0x64>
  dec_count(pa);
    80000bb6:	8526                	mv	a0,s1
    80000bb8:	00000097          	auipc	ra,0x0
    80000bbc:	f26080e7          	jalr	-218(ra) # 80000ade <dec_count>
  x=get_count(pa);
    80000bc0:	8526                	mv	a0,s1
    80000bc2:	00000097          	auipc	ra,0x0
    80000bc6:	f70080e7          	jalr	-144(ra) # 80000b32 <get_count>
  if(x<=0){
    80000bca:	02a05763          	blez	a0,80000bf8 <kfree+0x74>
}
    80000bce:	60e2                	ld	ra,24(sp)
    80000bd0:	6442                	ld	s0,16(sp)
    80000bd2:	64a2                	ld	s1,8(sp)
    80000bd4:	6105                	addi	sp,sp,32
    80000bd6:	8082                	ret
    panic("kfree");
    80000bd8:	00007517          	auipc	a0,0x7
    80000bdc:	48850513          	addi	a0,a0,1160 # 80008060 <digits+0x20>
    80000be0:	00000097          	auipc	ra,0x0
    80000be4:	960080e7          	jalr	-1696(ra) # 80000540 <panic>
  if(x<=0)panic("kfree");
    80000be8:	00007517          	auipc	a0,0x7
    80000bec:	47850513          	addi	a0,a0,1144 # 80008060 <digits+0x20>
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	950080e7          	jalr	-1712(ra) # 80000540 <panic>
  memset(pa, 1, PGSIZE);
    80000bf8:	6605                	lui	a2,0x1
    80000bfa:	4585                	li	a1,1
    80000bfc:	8526                	mv	a0,s1
    80000bfe:	00000097          	auipc	ra,0x0
    80000c02:	2ac080e7          	jalr	684(ra) # 80000eaa <memset>
  acquire(&kmem.lock);
    80000c06:	00010517          	auipc	a0,0x10
    80000c0a:	f5a50513          	addi	a0,a0,-166 # 80010b60 <kmem>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	1a0080e7          	jalr	416(ra) # 80000dae <acquire>
  r->next = kmem.freelist;
    80000c16:	00010517          	auipc	a0,0x10
    80000c1a:	f4a50513          	addi	a0,a0,-182 # 80010b60 <kmem>
    80000c1e:	6d1c                	ld	a5,24(a0)
    80000c20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000c22:	ed04                	sd	s1,24(a0)
  release(&kmem.lock);}
    80000c24:	00000097          	auipc	ra,0x0
    80000c28:	23e080e7          	jalr	574(ra) # 80000e62 <release>
  return;
    80000c2c:	b74d                	j	80000bce <kfree+0x4a>

0000000080000c2e <freerange>:
{
    80000c2e:	7179                	addi	sp,sp,-48
    80000c30:	f406                	sd	ra,40(sp)
    80000c32:	f022                	sd	s0,32(sp)
    80000c34:	ec26                	sd	s1,24(sp)
    80000c36:	e84a                	sd	s2,16(sp)
    80000c38:	e44e                	sd	s3,8(sp)
    80000c3a:	e052                	sd	s4,0(sp)
    80000c3c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000c3e:	6785                	lui	a5,0x1
    80000c40:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000c44:	00e504b3          	add	s1,a0,a4
    80000c48:	777d                	lui	a4,0xfffff
    80000c4a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000c4c:	94be                	add	s1,s1,a5
    80000c4e:	0095ee63          	bltu	a1,s1,80000c6a <freerange+0x3c>
    80000c52:	892e                	mv	s2,a1
    kfree(p);
    80000c54:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000c56:	6985                	lui	s3,0x1
    kfree(p);
    80000c58:	01448533          	add	a0,s1,s4
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	f28080e7          	jalr	-216(ra) # 80000b84 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000c64:	94ce                	add	s1,s1,s3
    80000c66:	fe9979e3          	bgeu	s2,s1,80000c58 <freerange+0x2a>
}
    80000c6a:	70a2                	ld	ra,40(sp)
    80000c6c:	7402                	ld	s0,32(sp)
    80000c6e:	64e2                	ld	s1,24(sp)
    80000c70:	6942                	ld	s2,16(sp)
    80000c72:	69a2                	ld	s3,8(sp)
    80000c74:	6a02                	ld	s4,0(sp)
    80000c76:	6145                	addi	sp,sp,48
    80000c78:	8082                	ret

0000000080000c7a <kinit>:
{
    80000c7a:	1141                	addi	sp,sp,-16
    80000c7c:	e406                	sd	ra,8(sp)
    80000c7e:	e022                	sd	s0,0(sp)
    80000c80:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000c82:	00007597          	auipc	a1,0x7
    80000c86:	3e658593          	addi	a1,a1,998 # 80008068 <digits+0x28>
    80000c8a:	00010517          	auipc	a0,0x10
    80000c8e:	ed650513          	addi	a0,a0,-298 # 80010b60 <kmem>
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	08c080e7          	jalr	140(ra) # 80000d1e <initlock>
  initlock(&kmem.lock_count, "kmem_count");
    80000c9a:	00007597          	auipc	a1,0x7
    80000c9e:	3d658593          	addi	a1,a1,982 # 80008070 <digits+0x30>
    80000ca2:	00030517          	auipc	a0,0x30
    80000ca6:	ede50513          	addi	a0,a0,-290 # 80030b80 <kmem+0x20020>
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	074080e7          	jalr	116(ra) # 80000d1e <initlock>
  acquire(&kmem.lock_count);
    80000cb2:	00030517          	auipc	a0,0x30
    80000cb6:	ece50513          	addi	a0,a0,-306 # 80030b80 <kmem+0x20020>
    80000cba:	00000097          	auipc	ra,0x0
    80000cbe:	0f4080e7          	jalr	244(ra) # 80000dae <acquire>
  for(int i = 0; i < (PGROUNDUP(PHYSTOP) - KERNBASE)/PGSIZE; ++i) {
    80000cc2:	00010797          	auipc	a5,0x10
    80000cc6:	ebe78793          	addi	a5,a5,-322 # 80010b80 <kmem+0x20>
    80000cca:	00030697          	auipc	a3,0x30
    80000cce:	eb668693          	addi	a3,a3,-330 # 80030b80 <kmem+0x20020>
      kmem.total_count[i] = 1;
    80000cd2:	4705                	li	a4,1
    80000cd4:	c398                	sw	a4,0(a5)
  for(int i = 0; i < (PGROUNDUP(PHYSTOP) - KERNBASE)/PGSIZE; ++i) {
    80000cd6:	0791                	addi	a5,a5,4
    80000cd8:	fed79ee3          	bne	a5,a3,80000cd4 <kinit+0x5a>
  release(&kmem.lock_count);
    80000cdc:	00030517          	auipc	a0,0x30
    80000ce0:	ea450513          	addi	a0,a0,-348 # 80030b80 <kmem+0x20020>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	17e080e7          	jalr	382(ra) # 80000e62 <release>
  freerange(end, (void*)PHYSTOP);
    80000cec:	45c5                	li	a1,17
    80000cee:	05ee                	slli	a1,a1,0x1b
    80000cf0:	00042517          	auipc	a0,0x42
    80000cf4:	2b850513          	addi	a0,a0,696 # 80042fa8 <end>
    80000cf8:	00000097          	auipc	ra,0x0
    80000cfc:	f36080e7          	jalr	-202(ra) # 80000c2e <freerange>
}
    80000d00:	60a2                	ld	ra,8(sp)
    80000d02:	6402                	ld	s0,0(sp)
    80000d04:	0141                	addi	sp,sp,16
    80000d06:	8082                	ret

0000000080000d08 <get_ind>:
int get_ind(void* pa){
    80000d08:	1141                	addi	sp,sp,-16
    80000d0a:	e422                	sd	s0,8(sp)
    80000d0c:	0800                	addi	s0,sp,16
  return ((uint64)pa-KERNBASE)/PGSIZE;
    80000d0e:	800007b7          	lui	a5,0x80000
    80000d12:	953e                	add	a0,a0,a5
    80000d14:	8131                	srli	a0,a0,0xc

    80000d16:	2501                	sext.w	a0,a0
    80000d18:	6422                	ld	s0,8(sp)
    80000d1a:	0141                	addi	sp,sp,16
    80000d1c:	8082                	ret

0000000080000d1e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000d1e:	1141                	addi	sp,sp,-16
    80000d20:	e422                	sd	s0,8(sp)
    80000d22:	0800                	addi	s0,sp,16
  lk->name = name;
    80000d24:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000d26:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000d2a:	00053823          	sd	zero,16(a0)
}
    80000d2e:	6422                	ld	s0,8(sp)
    80000d30:	0141                	addi	sp,sp,16
    80000d32:	8082                	ret

0000000080000d34 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d34:	411c                	lw	a5,0(a0)
    80000d36:	e399                	bnez	a5,80000d3c <holding+0x8>
    80000d38:	4501                	li	a0,0
  return r;
}
    80000d3a:	8082                	ret
{
    80000d3c:	1101                	addi	sp,sp,-32
    80000d3e:	ec06                	sd	ra,24(sp)
    80000d40:	e822                	sd	s0,16(sp)
    80000d42:	e426                	sd	s1,8(sp)
    80000d44:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d46:	6904                	ld	s1,16(a0)
    80000d48:	00001097          	auipc	ra,0x1
    80000d4c:	eee080e7          	jalr	-274(ra) # 80001c36 <mycpu>
    80000d50:	40a48533          	sub	a0,s1,a0
    80000d54:	00153513          	seqz	a0,a0
}
    80000d58:	60e2                	ld	ra,24(sp)
    80000d5a:	6442                	ld	s0,16(sp)
    80000d5c:	64a2                	ld	s1,8(sp)
    80000d5e:	6105                	addi	sp,sp,32
    80000d60:	8082                	ret

0000000080000d62 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d62:	1101                	addi	sp,sp,-32
    80000d64:	ec06                	sd	ra,24(sp)
    80000d66:	e822                	sd	s0,16(sp)
    80000d68:	e426                	sd	s1,8(sp)
    80000d6a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d6c:	100024f3          	csrr	s1,sstatus
    80000d70:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d74:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d76:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d7a:	00001097          	auipc	ra,0x1
    80000d7e:	ebc080e7          	jalr	-324(ra) # 80001c36 <mycpu>
    80000d82:	5d3c                	lw	a5,120(a0)
    80000d84:	cf89                	beqz	a5,80000d9e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d86:	00001097          	auipc	ra,0x1
    80000d8a:	eb0080e7          	jalr	-336(ra) # 80001c36 <mycpu>
    80000d8e:	5d3c                	lw	a5,120(a0)
    80000d90:	2785                	addiw	a5,a5,1 # ffffffff80000001 <end+0xfffffffefffbd059>
    80000d92:	dd3c                	sw	a5,120(a0)
}
    80000d94:	60e2                	ld	ra,24(sp)
    80000d96:	6442                	ld	s0,16(sp)
    80000d98:	64a2                	ld	s1,8(sp)
    80000d9a:	6105                	addi	sp,sp,32
    80000d9c:	8082                	ret
    mycpu()->intena = old;
    80000d9e:	00001097          	auipc	ra,0x1
    80000da2:	e98080e7          	jalr	-360(ra) # 80001c36 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000da6:	8085                	srli	s1,s1,0x1
    80000da8:	8885                	andi	s1,s1,1
    80000daa:	dd64                	sw	s1,124(a0)
    80000dac:	bfe9                	j	80000d86 <push_off+0x24>

0000000080000dae <acquire>:
{
    80000dae:	1101                	addi	sp,sp,-32
    80000db0:	ec06                	sd	ra,24(sp)
    80000db2:	e822                	sd	s0,16(sp)
    80000db4:	e426                	sd	s1,8(sp)
    80000db6:	1000                	addi	s0,sp,32
    80000db8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000dba:	00000097          	auipc	ra,0x0
    80000dbe:	fa8080e7          	jalr	-88(ra) # 80000d62 <push_off>
  if(holding(lk))
    80000dc2:	8526                	mv	a0,s1
    80000dc4:	00000097          	auipc	ra,0x0
    80000dc8:	f70080e7          	jalr	-144(ra) # 80000d34 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000dcc:	4705                	li	a4,1
  if(holding(lk))
    80000dce:	e115                	bnez	a0,80000df2 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000dd0:	87ba                	mv	a5,a4
    80000dd2:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000dd6:	2781                	sext.w	a5,a5
    80000dd8:	ffe5                	bnez	a5,80000dd0 <acquire+0x22>
  __sync_synchronize();
    80000dda:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000dde:	00001097          	auipc	ra,0x1
    80000de2:	e58080e7          	jalr	-424(ra) # 80001c36 <mycpu>
    80000de6:	e888                	sd	a0,16(s1)
}
    80000de8:	60e2                	ld	ra,24(sp)
    80000dea:	6442                	ld	s0,16(sp)
    80000dec:	64a2                	ld	s1,8(sp)
    80000dee:	6105                	addi	sp,sp,32
    80000df0:	8082                	ret
    panic("acquire");
    80000df2:	00007517          	auipc	a0,0x7
    80000df6:	28e50513          	addi	a0,a0,654 # 80008080 <digits+0x40>
    80000dfa:	fffff097          	auipc	ra,0xfffff
    80000dfe:	746080e7          	jalr	1862(ra) # 80000540 <panic>

0000000080000e02 <pop_off>:

void
pop_off(void)
{
    80000e02:	1141                	addi	sp,sp,-16
    80000e04:	e406                	sd	ra,8(sp)
    80000e06:	e022                	sd	s0,0(sp)
    80000e08:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000e0a:	00001097          	auipc	ra,0x1
    80000e0e:	e2c080e7          	jalr	-468(ra) # 80001c36 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e12:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000e16:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000e18:	e78d                	bnez	a5,80000e42 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000e1a:	5d3c                	lw	a5,120(a0)
    80000e1c:	02f05b63          	blez	a5,80000e52 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000e20:	37fd                	addiw	a5,a5,-1
    80000e22:	0007871b          	sext.w	a4,a5
    80000e26:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000e28:	eb09                	bnez	a4,80000e3a <pop_off+0x38>
    80000e2a:	5d7c                	lw	a5,124(a0)
    80000e2c:	c799                	beqz	a5,80000e3a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e2e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e32:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e36:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e3a:	60a2                	ld	ra,8(sp)
    80000e3c:	6402                	ld	s0,0(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret
    panic("pop_off - interruptible");
    80000e42:	00007517          	auipc	a0,0x7
    80000e46:	24650513          	addi	a0,a0,582 # 80008088 <digits+0x48>
    80000e4a:	fffff097          	auipc	ra,0xfffff
    80000e4e:	6f6080e7          	jalr	1782(ra) # 80000540 <panic>
    panic("pop_off");
    80000e52:	00007517          	auipc	a0,0x7
    80000e56:	24e50513          	addi	a0,a0,590 # 800080a0 <digits+0x60>
    80000e5a:	fffff097          	auipc	ra,0xfffff
    80000e5e:	6e6080e7          	jalr	1766(ra) # 80000540 <panic>

0000000080000e62 <release>:
{
    80000e62:	1101                	addi	sp,sp,-32
    80000e64:	ec06                	sd	ra,24(sp)
    80000e66:	e822                	sd	s0,16(sp)
    80000e68:	e426                	sd	s1,8(sp)
    80000e6a:	1000                	addi	s0,sp,32
    80000e6c:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e6e:	00000097          	auipc	ra,0x0
    80000e72:	ec6080e7          	jalr	-314(ra) # 80000d34 <holding>
    80000e76:	c115                	beqz	a0,80000e9a <release+0x38>
  lk->cpu = 0;
    80000e78:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e7c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e80:	0f50000f          	fence	iorw,ow
    80000e84:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e88:	00000097          	auipc	ra,0x0
    80000e8c:	f7a080e7          	jalr	-134(ra) # 80000e02 <pop_off>
}
    80000e90:	60e2                	ld	ra,24(sp)
    80000e92:	6442                	ld	s0,16(sp)
    80000e94:	64a2                	ld	s1,8(sp)
    80000e96:	6105                	addi	sp,sp,32
    80000e98:	8082                	ret
    panic("release");
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	20e50513          	addi	a0,a0,526 # 800080a8 <digits+0x68>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	69e080e7          	jalr	1694(ra) # 80000540 <panic>

0000000080000eaa <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000eaa:	1141                	addi	sp,sp,-16
    80000eac:	e422                	sd	s0,8(sp)
    80000eae:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000eb0:	ca19                	beqz	a2,80000ec6 <memset+0x1c>
    80000eb2:	87aa                	mv	a5,a0
    80000eb4:	1602                	slli	a2,a2,0x20
    80000eb6:	9201                	srli	a2,a2,0x20
    80000eb8:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ebc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ec0:	0785                	addi	a5,a5,1
    80000ec2:	fee79de3          	bne	a5,a4,80000ebc <memset+0x12>
  }
  return dst;
}
    80000ec6:	6422                	ld	s0,8(sp)
    80000ec8:	0141                	addi	sp,sp,16
    80000eca:	8082                	ret

0000000080000ecc <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ecc:	1141                	addi	sp,sp,-16
    80000ece:	e422                	sd	s0,8(sp)
    80000ed0:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ed2:	ca05                	beqz	a2,80000f02 <memcmp+0x36>
    80000ed4:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000ed8:	1682                	slli	a3,a3,0x20
    80000eda:	9281                	srli	a3,a3,0x20
    80000edc:	0685                	addi	a3,a3,1
    80000ede:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000ee0:	00054783          	lbu	a5,0(a0)
    80000ee4:	0005c703          	lbu	a4,0(a1)
    80000ee8:	00e79863          	bne	a5,a4,80000ef8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000eec:	0505                	addi	a0,a0,1
    80000eee:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ef0:	fed518e3          	bne	a0,a3,80000ee0 <memcmp+0x14>
  }

  return 0;
    80000ef4:	4501                	li	a0,0
    80000ef6:	a019                	j	80000efc <memcmp+0x30>
      return *s1 - *s2;
    80000ef8:	40e7853b          	subw	a0,a5,a4
}
    80000efc:	6422                	ld	s0,8(sp)
    80000efe:	0141                	addi	sp,sp,16
    80000f00:	8082                	ret
  return 0;
    80000f02:	4501                	li	a0,0
    80000f04:	bfe5                	j	80000efc <memcmp+0x30>

0000000080000f06 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000f06:	1141                	addi	sp,sp,-16
    80000f08:	e422                	sd	s0,8(sp)
    80000f0a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000f0c:	c205                	beqz	a2,80000f2c <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000f0e:	02a5e263          	bltu	a1,a0,80000f32 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000f12:	1602                	slli	a2,a2,0x20
    80000f14:	9201                	srli	a2,a2,0x20
    80000f16:	00c587b3          	add	a5,a1,a2
{
    80000f1a:	872a                	mv	a4,a0
      *d++ = *s++;
    80000f1c:	0585                	addi	a1,a1,1
    80000f1e:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffbc059>
    80000f20:	fff5c683          	lbu	a3,-1(a1)
    80000f24:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000f28:	fef59ae3          	bne	a1,a5,80000f1c <memmove+0x16>

  return dst;
}
    80000f2c:	6422                	ld	s0,8(sp)
    80000f2e:	0141                	addi	sp,sp,16
    80000f30:	8082                	ret
  if(s < d && s + n > d){
    80000f32:	02061693          	slli	a3,a2,0x20
    80000f36:	9281                	srli	a3,a3,0x20
    80000f38:	00d58733          	add	a4,a1,a3
    80000f3c:	fce57be3          	bgeu	a0,a4,80000f12 <memmove+0xc>
    d += n;
    80000f40:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000f42:	fff6079b          	addiw	a5,a2,-1
    80000f46:	1782                	slli	a5,a5,0x20
    80000f48:	9381                	srli	a5,a5,0x20
    80000f4a:	fff7c793          	not	a5,a5
    80000f4e:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000f50:	177d                	addi	a4,a4,-1
    80000f52:	16fd                	addi	a3,a3,-1
    80000f54:	00074603          	lbu	a2,0(a4)
    80000f58:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f5c:	fee79ae3          	bne	a5,a4,80000f50 <memmove+0x4a>
    80000f60:	b7f1                	j	80000f2c <memmove+0x26>

0000000080000f62 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f62:	1141                	addi	sp,sp,-16
    80000f64:	e406                	sd	ra,8(sp)
    80000f66:	e022                	sd	s0,0(sp)
    80000f68:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f6a:	00000097          	auipc	ra,0x0
    80000f6e:	f9c080e7          	jalr	-100(ra) # 80000f06 <memmove>
}
    80000f72:	60a2                	ld	ra,8(sp)
    80000f74:	6402                	ld	s0,0(sp)
    80000f76:	0141                	addi	sp,sp,16
    80000f78:	8082                	ret

0000000080000f7a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f7a:	1141                	addi	sp,sp,-16
    80000f7c:	e422                	sd	s0,8(sp)
    80000f7e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f80:	ce11                	beqz	a2,80000f9c <strncmp+0x22>
    80000f82:	00054783          	lbu	a5,0(a0)
    80000f86:	cf89                	beqz	a5,80000fa0 <strncmp+0x26>
    80000f88:	0005c703          	lbu	a4,0(a1)
    80000f8c:	00f71a63          	bne	a4,a5,80000fa0 <strncmp+0x26>
    n--, p++, q++;
    80000f90:	367d                	addiw	a2,a2,-1
    80000f92:	0505                	addi	a0,a0,1
    80000f94:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f96:	f675                	bnez	a2,80000f82 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f98:	4501                	li	a0,0
    80000f9a:	a809                	j	80000fac <strncmp+0x32>
    80000f9c:	4501                	li	a0,0
    80000f9e:	a039                	j	80000fac <strncmp+0x32>
  if(n == 0)
    80000fa0:	ca09                	beqz	a2,80000fb2 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000fa2:	00054503          	lbu	a0,0(a0)
    80000fa6:	0005c783          	lbu	a5,0(a1)
    80000faa:	9d1d                	subw	a0,a0,a5
}
    80000fac:	6422                	ld	s0,8(sp)
    80000fae:	0141                	addi	sp,sp,16
    80000fb0:	8082                	ret
    return 0;
    80000fb2:	4501                	li	a0,0
    80000fb4:	bfe5                	j	80000fac <strncmp+0x32>

0000000080000fb6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000fb6:	1141                	addi	sp,sp,-16
    80000fb8:	e422                	sd	s0,8(sp)
    80000fba:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000fbc:	872a                	mv	a4,a0
    80000fbe:	8832                	mv	a6,a2
    80000fc0:	367d                	addiw	a2,a2,-1
    80000fc2:	01005963          	blez	a6,80000fd4 <strncpy+0x1e>
    80000fc6:	0705                	addi	a4,a4,1
    80000fc8:	0005c783          	lbu	a5,0(a1)
    80000fcc:	fef70fa3          	sb	a5,-1(a4)
    80000fd0:	0585                	addi	a1,a1,1
    80000fd2:	f7f5                	bnez	a5,80000fbe <strncpy+0x8>
    ;
  while(n-- > 0)
    80000fd4:	86ba                	mv	a3,a4
    80000fd6:	00c05c63          	blez	a2,80000fee <strncpy+0x38>
    *s++ = 0;
    80000fda:	0685                	addi	a3,a3,1
    80000fdc:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000fe0:	40d707bb          	subw	a5,a4,a3
    80000fe4:	37fd                	addiw	a5,a5,-1
    80000fe6:	010787bb          	addw	a5,a5,a6
    80000fea:	fef048e3          	bgtz	a5,80000fda <strncpy+0x24>
  return os;
}
    80000fee:	6422                	ld	s0,8(sp)
    80000ff0:	0141                	addi	sp,sp,16
    80000ff2:	8082                	ret

0000000080000ff4 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ff4:	1141                	addi	sp,sp,-16
    80000ff6:	e422                	sd	s0,8(sp)
    80000ff8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ffa:	02c05363          	blez	a2,80001020 <safestrcpy+0x2c>
    80000ffe:	fff6069b          	addiw	a3,a2,-1
    80001002:	1682                	slli	a3,a3,0x20
    80001004:	9281                	srli	a3,a3,0x20
    80001006:	96ae                	add	a3,a3,a1
    80001008:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    8000100a:	00d58963          	beq	a1,a3,8000101c <safestrcpy+0x28>
    8000100e:	0585                	addi	a1,a1,1
    80001010:	0785                	addi	a5,a5,1
    80001012:	fff5c703          	lbu	a4,-1(a1)
    80001016:	fee78fa3          	sb	a4,-1(a5)
    8000101a:	fb65                	bnez	a4,8000100a <safestrcpy+0x16>
    ;
  *s = 0;
    8000101c:	00078023          	sb	zero,0(a5)
  return os;
}
    80001020:	6422                	ld	s0,8(sp)
    80001022:	0141                	addi	sp,sp,16
    80001024:	8082                	ret

0000000080001026 <strlen>:

int
strlen(const char *s)
{
    80001026:	1141                	addi	sp,sp,-16
    80001028:	e422                	sd	s0,8(sp)
    8000102a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    8000102c:	00054783          	lbu	a5,0(a0)
    80001030:	cf91                	beqz	a5,8000104c <strlen+0x26>
    80001032:	0505                	addi	a0,a0,1
    80001034:	87aa                	mv	a5,a0
    80001036:	4685                	li	a3,1
    80001038:	9e89                	subw	a3,a3,a0
    8000103a:	00f6853b          	addw	a0,a3,a5
    8000103e:	0785                	addi	a5,a5,1
    80001040:	fff7c703          	lbu	a4,-1(a5)
    80001044:	fb7d                	bnez	a4,8000103a <strlen+0x14>
    ;
  return n;
}
    80001046:	6422                	ld	s0,8(sp)
    80001048:	0141                	addi	sp,sp,16
    8000104a:	8082                	ret
  for(n = 0; s[n]; n++)
    8000104c:	4501                	li	a0,0
    8000104e:	bfe5                	j	80001046 <strlen+0x20>

0000000080001050 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001050:	1141                	addi	sp,sp,-16
    80001052:	e406                	sd	ra,8(sp)
    80001054:	e022                	sd	s0,0(sp)
    80001056:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001058:	00001097          	auipc	ra,0x1
    8000105c:	bce080e7          	jalr	-1074(ra) # 80001c26 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001060:	00008717          	auipc	a4,0x8
    80001064:	89870713          	addi	a4,a4,-1896 # 800088f8 <started>
  if(cpuid() == 0){
    80001068:	c139                	beqz	a0,800010ae <main+0x5e>
    while(started == 0)
    8000106a:	431c                	lw	a5,0(a4)
    8000106c:	2781                	sext.w	a5,a5
    8000106e:	dff5                	beqz	a5,8000106a <main+0x1a>
      ;
    __sync_synchronize();
    80001070:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001074:	00001097          	auipc	ra,0x1
    80001078:	bb2080e7          	jalr	-1102(ra) # 80001c26 <cpuid>
    8000107c:	85aa                	mv	a1,a0
    8000107e:	00007517          	auipc	a0,0x7
    80001082:	04a50513          	addi	a0,a0,74 # 800080c8 <digits+0x88>
    80001086:	fffff097          	auipc	ra,0xfffff
    8000108a:	504080e7          	jalr	1284(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	0d8080e7          	jalr	216(ra) # 80001166 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001096:	00002097          	auipc	ra,0x2
    8000109a:	a7c080e7          	jalr	-1412(ra) # 80002b12 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000109e:	00005097          	auipc	ra,0x5
    800010a2:	272080e7          	jalr	626(ra) # 80006310 <plicinithart>
  }

  // printf("hi\n");
  scheduler();        
    800010a6:	00001097          	auipc	ra,0x1
    800010aa:	0fa080e7          	jalr	250(ra) # 800021a0 <scheduler>
    consoleinit();
    800010ae:	fffff097          	auipc	ra,0xfffff
    800010b2:	3a2080e7          	jalr	930(ra) # 80000450 <consoleinit>
    printfinit();
    800010b6:	fffff097          	auipc	ra,0xfffff
    800010ba:	6b4080e7          	jalr	1716(ra) # 8000076a <printfinit>
    printf("\n");
    800010be:	00007517          	auipc	a0,0x7
    800010c2:	01a50513          	addi	a0,a0,26 # 800080d8 <digits+0x98>
    800010c6:	fffff097          	auipc	ra,0xfffff
    800010ca:	4c4080e7          	jalr	1220(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    800010ce:	00007517          	auipc	a0,0x7
    800010d2:	fe250513          	addi	a0,a0,-30 # 800080b0 <digits+0x70>
    800010d6:	fffff097          	auipc	ra,0xfffff
    800010da:	4b4080e7          	jalr	1204(ra) # 8000058a <printf>
    printf("\n");
    800010de:	00007517          	auipc	a0,0x7
    800010e2:	ffa50513          	addi	a0,a0,-6 # 800080d8 <digits+0x98>
    800010e6:	fffff097          	auipc	ra,0xfffff
    800010ea:	4a4080e7          	jalr	1188(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    800010ee:	00000097          	auipc	ra,0x0
    800010f2:	b8c080e7          	jalr	-1140(ra) # 80000c7a <kinit>
    kvminit();       // create kernel page table
    800010f6:	00000097          	auipc	ra,0x0
    800010fa:	326080e7          	jalr	806(ra) # 8000141c <kvminit>
    kvminithart();   // turn on paging
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	068080e7          	jalr	104(ra) # 80001166 <kvminithart>
    procinit();      // process table
    80001106:	00001097          	auipc	ra,0x1
    8000110a:	a6c080e7          	jalr	-1428(ra) # 80001b72 <procinit>
    trapinit();      // trap vectors
    8000110e:	00002097          	auipc	ra,0x2
    80001112:	9dc080e7          	jalr	-1572(ra) # 80002aea <trapinit>
    trapinithart();  // install kernel trap vector
    80001116:	00002097          	auipc	ra,0x2
    8000111a:	9fc080e7          	jalr	-1540(ra) # 80002b12 <trapinithart>
    plicinit();      // set up interrupt controller
    8000111e:	00005097          	auipc	ra,0x5
    80001122:	1dc080e7          	jalr	476(ra) # 800062fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001126:	00005097          	auipc	ra,0x5
    8000112a:	1ea080e7          	jalr	490(ra) # 80006310 <plicinithart>
    binit();         // buffer cache
    8000112e:	00002097          	auipc	ra,0x2
    80001132:	384080e7          	jalr	900(ra) # 800034b2 <binit>
    iinit();         // inode table
    80001136:	00003097          	auipc	ra,0x3
    8000113a:	a24080e7          	jalr	-1500(ra) # 80003b5a <iinit>
    fileinit();      // file table
    8000113e:	00004097          	auipc	ra,0x4
    80001142:	9ca080e7          	jalr	-1590(ra) # 80004b08 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001146:	00005097          	auipc	ra,0x5
    8000114a:	2d2080e7          	jalr	722(ra) # 80006418 <virtio_disk_init>
    userinit();      // first user process
    8000114e:	00001097          	auipc	ra,0x1
    80001152:	e20080e7          	jalr	-480(ra) # 80001f6e <userinit>
    __sync_synchronize();
    80001156:	0ff0000f          	fence
    started = 1;
    8000115a:	4785                	li	a5,1
    8000115c:	00007717          	auipc	a4,0x7
    80001160:	78f72e23          	sw	a5,1948(a4) # 800088f8 <started>
    80001164:	b789                	j	800010a6 <main+0x56>

0000000080001166 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001166:	1141                	addi	sp,sp,-16
    80001168:	e422                	sd	s0,8(sp)
    8000116a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000116c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001170:	00007797          	auipc	a5,0x7
    80001174:	7907b783          	ld	a5,1936(a5) # 80008900 <kernel_pagetable>
    80001178:	83b1                	srli	a5,a5,0xc
    8000117a:	577d                	li	a4,-1
    8000117c:	177e                	slli	a4,a4,0x3f
    8000117e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001180:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001184:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001188:	6422                	ld	s0,8(sp)
    8000118a:	0141                	addi	sp,sp,16
    8000118c:	8082                	ret

000000008000118e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000118e:	7139                	addi	sp,sp,-64
    80001190:	fc06                	sd	ra,56(sp)
    80001192:	f822                	sd	s0,48(sp)
    80001194:	f426                	sd	s1,40(sp)
    80001196:	f04a                	sd	s2,32(sp)
    80001198:	ec4e                	sd	s3,24(sp)
    8000119a:	e852                	sd	s4,16(sp)
    8000119c:	e456                	sd	s5,8(sp)
    8000119e:	e05a                	sd	s6,0(sp)
    800011a0:	0080                	addi	s0,sp,64
    800011a2:	84aa                	mv	s1,a0
    800011a4:	89ae                	mv	s3,a1
    800011a6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800011a8:	57fd                	li	a5,-1
    800011aa:	83e9                	srli	a5,a5,0x1a
    800011ac:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800011ae:	4b31                	li	s6,12
  if(va >= MAXVA)
    800011b0:	04b7f263          	bgeu	a5,a1,800011f4 <walk+0x66>
    panic("walk");
    800011b4:	00007517          	auipc	a0,0x7
    800011b8:	f2c50513          	addi	a0,a0,-212 # 800080e0 <digits+0xa0>
    800011bc:	fffff097          	auipc	ra,0xfffff
    800011c0:	384080e7          	jalr	900(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800011c4:	060a8663          	beqz	s5,80001230 <walk+0xa2>
    800011c8:	00000097          	auipc	ra,0x0
    800011cc:	820080e7          	jalr	-2016(ra) # 800009e8 <kalloc>
    800011d0:	84aa                	mv	s1,a0
    800011d2:	c529                	beqz	a0,8000121c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011d4:	6605                	lui	a2,0x1
    800011d6:	4581                	li	a1,0
    800011d8:	00000097          	auipc	ra,0x0
    800011dc:	cd2080e7          	jalr	-814(ra) # 80000eaa <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800011e0:	00c4d793          	srli	a5,s1,0xc
    800011e4:	07aa                	slli	a5,a5,0xa
    800011e6:	0017e793          	ori	a5,a5,1
    800011ea:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800011ee:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffbc04f>
    800011f0:	036a0063          	beq	s4,s6,80001210 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011f4:	0149d933          	srl	s2,s3,s4
    800011f8:	1ff97913          	andi	s2,s2,511
    800011fc:	090e                	slli	s2,s2,0x3
    800011fe:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001200:	00093483          	ld	s1,0(s2)
    80001204:	0014f793          	andi	a5,s1,1
    80001208:	dfd5                	beqz	a5,800011c4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000120a:	80a9                	srli	s1,s1,0xa
    8000120c:	04b2                	slli	s1,s1,0xc
    8000120e:	b7c5                	j	800011ee <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001210:	00c9d513          	srli	a0,s3,0xc
    80001214:	1ff57513          	andi	a0,a0,511
    80001218:	050e                	slli	a0,a0,0x3
    8000121a:	9526                	add	a0,a0,s1
}
    8000121c:	70e2                	ld	ra,56(sp)
    8000121e:	7442                	ld	s0,48(sp)
    80001220:	74a2                	ld	s1,40(sp)
    80001222:	7902                	ld	s2,32(sp)
    80001224:	69e2                	ld	s3,24(sp)
    80001226:	6a42                	ld	s4,16(sp)
    80001228:	6aa2                	ld	s5,8(sp)
    8000122a:	6b02                	ld	s6,0(sp)
    8000122c:	6121                	addi	sp,sp,64
    8000122e:	8082                	ret
        return 0;
    80001230:	4501                	li	a0,0
    80001232:	b7ed                	j	8000121c <walk+0x8e>

0000000080001234 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001234:	57fd                	li	a5,-1
    80001236:	83e9                	srli	a5,a5,0x1a
    80001238:	00b7f463          	bgeu	a5,a1,80001240 <walkaddr+0xc>
    return 0;
    8000123c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000123e:	8082                	ret
{
    80001240:	1141                	addi	sp,sp,-16
    80001242:	e406                	sd	ra,8(sp)
    80001244:	e022                	sd	s0,0(sp)
    80001246:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001248:	4601                	li	a2,0
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	f44080e7          	jalr	-188(ra) # 8000118e <walk>
  if(pte == 0)
    80001252:	c105                	beqz	a0,80001272 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001254:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001256:	0117f693          	andi	a3,a5,17
    8000125a:	4745                	li	a4,17
    return 0;
    8000125c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000125e:	00e68663          	beq	a3,a4,8000126a <walkaddr+0x36>
}
    80001262:	60a2                	ld	ra,8(sp)
    80001264:	6402                	ld	s0,0(sp)
    80001266:	0141                	addi	sp,sp,16
    80001268:	8082                	ret
  pa = PTE2PA(*pte);
    8000126a:	83a9                	srli	a5,a5,0xa
    8000126c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001270:	bfcd                	j	80001262 <walkaddr+0x2e>
    return 0;
    80001272:	4501                	li	a0,0
    80001274:	b7fd                	j	80001262 <walkaddr+0x2e>

0000000080001276 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000128c:	c639                	beqz	a2,800012da <mappages+0x64>
    8000128e:	8aaa                	mv	s5,a0
    80001290:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001292:	777d                	lui	a4,0xfffff
    80001294:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001298:	fff58993          	addi	s3,a1,-1
    8000129c:	99b2                	add	s3,s3,a2
    8000129e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800012a2:	893e                	mv	s2,a5
    800012a4:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800012a8:	6b85                	lui	s7,0x1
    800012aa:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012ae:	4605                	li	a2,1
    800012b0:	85ca                	mv	a1,s2
    800012b2:	8556                	mv	a0,s5
    800012b4:	00000097          	auipc	ra,0x0
    800012b8:	eda080e7          	jalr	-294(ra) # 8000118e <walk>
    800012bc:	cd1d                	beqz	a0,800012fa <mappages+0x84>
    if(*pte & PTE_V)
    800012be:	611c                	ld	a5,0(a0)
    800012c0:	8b85                	andi	a5,a5,1
    800012c2:	e785                	bnez	a5,800012ea <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800012c4:	80b1                	srli	s1,s1,0xc
    800012c6:	04aa                	slli	s1,s1,0xa
    800012c8:	0164e4b3          	or	s1,s1,s6
    800012cc:	0014e493          	ori	s1,s1,1
    800012d0:	e104                	sd	s1,0(a0)
    if(a == last)
    800012d2:	05390063          	beq	s2,s3,80001312 <mappages+0x9c>
    a += PGSIZE;
    800012d6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800012d8:	bfc9                	j	800012aa <mappages+0x34>
    panic("mappages: size");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e0e50513          	addi	a0,a0,-498 # 800080e8 <digits+0xa8>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
      panic("mappages: remap");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e0e50513          	addi	a0,a0,-498 # 800080f8 <digits+0xb8>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	24e080e7          	jalr	590(ra) # 80000540 <panic>
      return -1;
    800012fa:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012fc:	60a6                	ld	ra,72(sp)
    800012fe:	6406                	ld	s0,64(sp)
    80001300:	74e2                	ld	s1,56(sp)
    80001302:	7942                	ld	s2,48(sp)
    80001304:	79a2                	ld	s3,40(sp)
    80001306:	7a02                	ld	s4,32(sp)
    80001308:	6ae2                	ld	s5,24(sp)
    8000130a:	6b42                	ld	s6,16(sp)
    8000130c:	6ba2                	ld	s7,8(sp)
    8000130e:	6161                	addi	sp,sp,80
    80001310:	8082                	ret
  return 0;
    80001312:	4501                	li	a0,0
    80001314:	b7e5                	j	800012fc <mappages+0x86>

0000000080001316 <kvmmap>:
{
    80001316:	1141                	addi	sp,sp,-16
    80001318:	e406                	sd	ra,8(sp)
    8000131a:	e022                	sd	s0,0(sp)
    8000131c:	0800                	addi	s0,sp,16
    8000131e:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001320:	86b2                	mv	a3,a2
    80001322:	863e                	mv	a2,a5
    80001324:	00000097          	auipc	ra,0x0
    80001328:	f52080e7          	jalr	-174(ra) # 80001276 <mappages>
    8000132c:	e509                	bnez	a0,80001336 <kvmmap+0x20>
}
    8000132e:	60a2                	ld	ra,8(sp)
    80001330:	6402                	ld	s0,0(sp)
    80001332:	0141                	addi	sp,sp,16
    80001334:	8082                	ret
    panic("kvmmap");
    80001336:	00007517          	auipc	a0,0x7
    8000133a:	dd250513          	addi	a0,a0,-558 # 80008108 <digits+0xc8>
    8000133e:	fffff097          	auipc	ra,0xfffff
    80001342:	202080e7          	jalr	514(ra) # 80000540 <panic>

0000000080001346 <kvmmake>:
{
    80001346:	1101                	addi	sp,sp,-32
    80001348:	ec06                	sd	ra,24(sp)
    8000134a:	e822                	sd	s0,16(sp)
    8000134c:	e426                	sd	s1,8(sp)
    8000134e:	e04a                	sd	s2,0(sp)
    80001350:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	696080e7          	jalr	1686(ra) # 800009e8 <kalloc>
    8000135a:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000135c:	6605                	lui	a2,0x1
    8000135e:	4581                	li	a1,0
    80001360:	00000097          	auipc	ra,0x0
    80001364:	b4a080e7          	jalr	-1206(ra) # 80000eaa <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001368:	4719                	li	a4,6
    8000136a:	6685                	lui	a3,0x1
    8000136c:	10000637          	lui	a2,0x10000
    80001370:	100005b7          	lui	a1,0x10000
    80001374:	8526                	mv	a0,s1
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	fa0080e7          	jalr	-96(ra) # 80001316 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000137e:	4719                	li	a4,6
    80001380:	6685                	lui	a3,0x1
    80001382:	10001637          	lui	a2,0x10001
    80001386:	100015b7          	lui	a1,0x10001
    8000138a:	8526                	mv	a0,s1
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	f8a080e7          	jalr	-118(ra) # 80001316 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001394:	4719                	li	a4,6
    80001396:	004006b7          	lui	a3,0x400
    8000139a:	0c000637          	lui	a2,0xc000
    8000139e:	0c0005b7          	lui	a1,0xc000
    800013a2:	8526                	mv	a0,s1
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	f72080e7          	jalr	-142(ra) # 80001316 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800013ac:	00007917          	auipc	s2,0x7
    800013b0:	c5490913          	addi	s2,s2,-940 # 80008000 <etext>
    800013b4:	4729                	li	a4,10
    800013b6:	80007697          	auipc	a3,0x80007
    800013ba:	c4a68693          	addi	a3,a3,-950 # 8000 <_entry-0x7fff8000>
    800013be:	4605                	li	a2,1
    800013c0:	067e                	slli	a2,a2,0x1f
    800013c2:	85b2                	mv	a1,a2
    800013c4:	8526                	mv	a0,s1
    800013c6:	00000097          	auipc	ra,0x0
    800013ca:	f50080e7          	jalr	-176(ra) # 80001316 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800013ce:	4719                	li	a4,6
    800013d0:	46c5                	li	a3,17
    800013d2:	06ee                	slli	a3,a3,0x1b
    800013d4:	412686b3          	sub	a3,a3,s2
    800013d8:	864a                	mv	a2,s2
    800013da:	85ca                	mv	a1,s2
    800013dc:	8526                	mv	a0,s1
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	f38080e7          	jalr	-200(ra) # 80001316 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013e6:	4729                	li	a4,10
    800013e8:	6685                	lui	a3,0x1
    800013ea:	00006617          	auipc	a2,0x6
    800013ee:	c1660613          	addi	a2,a2,-1002 # 80007000 <_trampoline>
    800013f2:	040005b7          	lui	a1,0x4000
    800013f6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800013f8:	05b2                	slli	a1,a1,0xc
    800013fa:	8526                	mv	a0,s1
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	f1a080e7          	jalr	-230(ra) # 80001316 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001404:	8526                	mv	a0,s1
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	6d6080e7          	jalr	1750(ra) # 80001adc <proc_mapstacks>
}
    8000140e:	8526                	mv	a0,s1
    80001410:	60e2                	ld	ra,24(sp)
    80001412:	6442                	ld	s0,16(sp)
    80001414:	64a2                	ld	s1,8(sp)
    80001416:	6902                	ld	s2,0(sp)
    80001418:	6105                	addi	sp,sp,32
    8000141a:	8082                	ret

000000008000141c <kvminit>:
{
    8000141c:	1141                	addi	sp,sp,-16
    8000141e:	e406                	sd	ra,8(sp)
    80001420:	e022                	sd	s0,0(sp)
    80001422:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001424:	00000097          	auipc	ra,0x0
    80001428:	f22080e7          	jalr	-222(ra) # 80001346 <kvmmake>
    8000142c:	00007797          	auipc	a5,0x7
    80001430:	4ca7ba23          	sd	a0,1236(a5) # 80008900 <kernel_pagetable>
}
    80001434:	60a2                	ld	ra,8(sp)
    80001436:	6402                	ld	s0,0(sp)
    80001438:	0141                	addi	sp,sp,16
    8000143a:	8082                	ret

000000008000143c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000143c:	715d                	addi	sp,sp,-80
    8000143e:	e486                	sd	ra,72(sp)
    80001440:	e0a2                	sd	s0,64(sp)
    80001442:	fc26                	sd	s1,56(sp)
    80001444:	f84a                	sd	s2,48(sp)
    80001446:	f44e                	sd	s3,40(sp)
    80001448:	f052                	sd	s4,32(sp)
    8000144a:	ec56                	sd	s5,24(sp)
    8000144c:	e85a                	sd	s6,16(sp)
    8000144e:	e45e                	sd	s7,8(sp)
    80001450:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001452:	03459793          	slli	a5,a1,0x34
    80001456:	e795                	bnez	a5,80001482 <uvmunmap+0x46>
    80001458:	8a2a                	mv	s4,a0
    8000145a:	892e                	mv	s2,a1
    8000145c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000145e:	0632                	slli	a2,a2,0xc
    80001460:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001464:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001466:	6b05                	lui	s6,0x1
    80001468:	0735e263          	bltu	a1,s3,800014cc <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000146c:	60a6                	ld	ra,72(sp)
    8000146e:	6406                	ld	s0,64(sp)
    80001470:	74e2                	ld	s1,56(sp)
    80001472:	7942                	ld	s2,48(sp)
    80001474:	79a2                	ld	s3,40(sp)
    80001476:	7a02                	ld	s4,32(sp)
    80001478:	6ae2                	ld	s5,24(sp)
    8000147a:	6b42                	ld	s6,16(sp)
    8000147c:	6ba2                	ld	s7,8(sp)
    8000147e:	6161                	addi	sp,sp,80
    80001480:	8082                	ret
    panic("uvmunmap: not aligned");
    80001482:	00007517          	auipc	a0,0x7
    80001486:	c8e50513          	addi	a0,a0,-882 # 80008110 <digits+0xd0>
    8000148a:	fffff097          	auipc	ra,0xfffff
    8000148e:	0b6080e7          	jalr	182(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001492:	00007517          	auipc	a0,0x7
    80001496:	c9650513          	addi	a0,a0,-874 # 80008128 <digits+0xe8>
    8000149a:	fffff097          	auipc	ra,0xfffff
    8000149e:	0a6080e7          	jalr	166(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800014a2:	00007517          	auipc	a0,0x7
    800014a6:	c9650513          	addi	a0,a0,-874 # 80008138 <digits+0xf8>
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	096080e7          	jalr	150(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800014b2:	00007517          	auipc	a0,0x7
    800014b6:	c9e50513          	addi	a0,a0,-866 # 80008150 <digits+0x110>
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	086080e7          	jalr	134(ra) # 80000540 <panic>
    *pte = 0;
    800014c2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014c6:	995a                	add	s2,s2,s6
    800014c8:	fb3972e3          	bgeu	s2,s3,8000146c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800014cc:	4601                	li	a2,0
    800014ce:	85ca                	mv	a1,s2
    800014d0:	8552                	mv	a0,s4
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	cbc080e7          	jalr	-836(ra) # 8000118e <walk>
    800014da:	84aa                	mv	s1,a0
    800014dc:	d95d                	beqz	a0,80001492 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014de:	6108                	ld	a0,0(a0)
    800014e0:	00157793          	andi	a5,a0,1
    800014e4:	dfdd                	beqz	a5,800014a2 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014e6:	3ff57793          	andi	a5,a0,1023
    800014ea:	fd7784e3          	beq	a5,s7,800014b2 <uvmunmap+0x76>
    if(do_free){
    800014ee:	fc0a8ae3          	beqz	s5,800014c2 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800014f2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014f4:	0532                	slli	a0,a0,0xc
    800014f6:	fffff097          	auipc	ra,0xfffff
    800014fa:	68e080e7          	jalr	1678(ra) # 80000b84 <kfree>
    800014fe:	b7d1                	j	800014c2 <uvmunmap+0x86>

0000000080001500 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001500:	1101                	addi	sp,sp,-32
    80001502:	ec06                	sd	ra,24(sp)
    80001504:	e822                	sd	s0,16(sp)
    80001506:	e426                	sd	s1,8(sp)
    80001508:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	4de080e7          	jalr	1246(ra) # 800009e8 <kalloc>
    80001512:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001514:	c519                	beqz	a0,80001522 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001516:	6605                	lui	a2,0x1
    80001518:	4581                	li	a1,0
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	990080e7          	jalr	-1648(ra) # 80000eaa <memset>
  return pagetable;
}
    80001522:	8526                	mv	a0,s1
    80001524:	60e2                	ld	ra,24(sp)
    80001526:	6442                	ld	s0,16(sp)
    80001528:	64a2                	ld	s1,8(sp)
    8000152a:	6105                	addi	sp,sp,32
    8000152c:	8082                	ret

000000008000152e <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000152e:	7179                	addi	sp,sp,-48
    80001530:	f406                	sd	ra,40(sp)
    80001532:	f022                	sd	s0,32(sp)
    80001534:	ec26                	sd	s1,24(sp)
    80001536:	e84a                	sd	s2,16(sp)
    80001538:	e44e                	sd	s3,8(sp)
    8000153a:	e052                	sd	s4,0(sp)
    8000153c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000153e:	6785                	lui	a5,0x1
    80001540:	04f67863          	bgeu	a2,a5,80001590 <uvmfirst+0x62>
    80001544:	8a2a                	mv	s4,a0
    80001546:	89ae                	mv	s3,a1
    80001548:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000154a:	fffff097          	auipc	ra,0xfffff
    8000154e:	49e080e7          	jalr	1182(ra) # 800009e8 <kalloc>
    80001552:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001554:	6605                	lui	a2,0x1
    80001556:	4581                	li	a1,0
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	952080e7          	jalr	-1710(ra) # 80000eaa <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001560:	4779                	li	a4,30
    80001562:	86ca                	mv	a3,s2
    80001564:	6605                	lui	a2,0x1
    80001566:	4581                	li	a1,0
    80001568:	8552                	mv	a0,s4
    8000156a:	00000097          	auipc	ra,0x0
    8000156e:	d0c080e7          	jalr	-756(ra) # 80001276 <mappages>
  memmove(mem, src, sz);
    80001572:	8626                	mv	a2,s1
    80001574:	85ce                	mv	a1,s3
    80001576:	854a                	mv	a0,s2
    80001578:	00000097          	auipc	ra,0x0
    8000157c:	98e080e7          	jalr	-1650(ra) # 80000f06 <memmove>
}
    80001580:	70a2                	ld	ra,40(sp)
    80001582:	7402                	ld	s0,32(sp)
    80001584:	64e2                	ld	s1,24(sp)
    80001586:	6942                	ld	s2,16(sp)
    80001588:	69a2                	ld	s3,8(sp)
    8000158a:	6a02                	ld	s4,0(sp)
    8000158c:	6145                	addi	sp,sp,48
    8000158e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001590:	00007517          	auipc	a0,0x7
    80001594:	bd850513          	addi	a0,a0,-1064 # 80008168 <digits+0x128>
    80001598:	fffff097          	auipc	ra,0xfffff
    8000159c:	fa8080e7          	jalr	-88(ra) # 80000540 <panic>

00000000800015a0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800015a0:	1101                	addi	sp,sp,-32
    800015a2:	ec06                	sd	ra,24(sp)
    800015a4:	e822                	sd	s0,16(sp)
    800015a6:	e426                	sd	s1,8(sp)
    800015a8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800015aa:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800015ac:	00b67d63          	bgeu	a2,a1,800015c6 <uvmdealloc+0x26>
    800015b0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800015b2:	6785                	lui	a5,0x1
    800015b4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015b6:	00f60733          	add	a4,a2,a5
    800015ba:	76fd                	lui	a3,0xfffff
    800015bc:	8f75                	and	a4,a4,a3
    800015be:	97ae                	add	a5,a5,a1
    800015c0:	8ff5                	and	a5,a5,a3
    800015c2:	00f76863          	bltu	a4,a5,800015d2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800015c6:	8526                	mv	a0,s1
    800015c8:	60e2                	ld	ra,24(sp)
    800015ca:	6442                	ld	s0,16(sp)
    800015cc:	64a2                	ld	s1,8(sp)
    800015ce:	6105                	addi	sp,sp,32
    800015d0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015d2:	8f99                	sub	a5,a5,a4
    800015d4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015d6:	4685                	li	a3,1
    800015d8:	0007861b          	sext.w	a2,a5
    800015dc:	85ba                	mv	a1,a4
    800015de:	00000097          	auipc	ra,0x0
    800015e2:	e5e080e7          	jalr	-418(ra) # 8000143c <uvmunmap>
    800015e6:	b7c5                	j	800015c6 <uvmdealloc+0x26>

00000000800015e8 <uvmalloc>:
  if(newsz < oldsz)
    800015e8:	0ab66563          	bltu	a2,a1,80001692 <uvmalloc+0xaa>
{
    800015ec:	7139                	addi	sp,sp,-64
    800015ee:	fc06                	sd	ra,56(sp)
    800015f0:	f822                	sd	s0,48(sp)
    800015f2:	f426                	sd	s1,40(sp)
    800015f4:	f04a                	sd	s2,32(sp)
    800015f6:	ec4e                	sd	s3,24(sp)
    800015f8:	e852                	sd	s4,16(sp)
    800015fa:	e456                	sd	s5,8(sp)
    800015fc:	e05a                	sd	s6,0(sp)
    800015fe:	0080                	addi	s0,sp,64
    80001600:	8aaa                	mv	s5,a0
    80001602:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001604:	6785                	lui	a5,0x1
    80001606:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001608:	95be                	add	a1,a1,a5
    8000160a:	77fd                	lui	a5,0xfffff
    8000160c:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001610:	08c9f363          	bgeu	s3,a2,80001696 <uvmalloc+0xae>
    80001614:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001616:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000161a:	fffff097          	auipc	ra,0xfffff
    8000161e:	3ce080e7          	jalr	974(ra) # 800009e8 <kalloc>
    80001622:	84aa                	mv	s1,a0
    if(mem == 0){
    80001624:	c51d                	beqz	a0,80001652 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001626:	6605                	lui	a2,0x1
    80001628:	4581                	li	a1,0
    8000162a:	00000097          	auipc	ra,0x0
    8000162e:	880080e7          	jalr	-1920(ra) # 80000eaa <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001632:	875a                	mv	a4,s6
    80001634:	86a6                	mv	a3,s1
    80001636:	6605                	lui	a2,0x1
    80001638:	85ca                	mv	a1,s2
    8000163a:	8556                	mv	a0,s5
    8000163c:	00000097          	auipc	ra,0x0
    80001640:	c3a080e7          	jalr	-966(ra) # 80001276 <mappages>
    80001644:	e90d                	bnez	a0,80001676 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001646:	6785                	lui	a5,0x1
    80001648:	993e                	add	s2,s2,a5
    8000164a:	fd4968e3          	bltu	s2,s4,8000161a <uvmalloc+0x32>
  return newsz;
    8000164e:	8552                	mv	a0,s4
    80001650:	a809                	j	80001662 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001652:	864e                	mv	a2,s3
    80001654:	85ca                	mv	a1,s2
    80001656:	8556                	mv	a0,s5
    80001658:	00000097          	auipc	ra,0x0
    8000165c:	f48080e7          	jalr	-184(ra) # 800015a0 <uvmdealloc>
      return 0;
    80001660:	4501                	li	a0,0
}
    80001662:	70e2                	ld	ra,56(sp)
    80001664:	7442                	ld	s0,48(sp)
    80001666:	74a2                	ld	s1,40(sp)
    80001668:	7902                	ld	s2,32(sp)
    8000166a:	69e2                	ld	s3,24(sp)
    8000166c:	6a42                	ld	s4,16(sp)
    8000166e:	6aa2                	ld	s5,8(sp)
    80001670:	6b02                	ld	s6,0(sp)
    80001672:	6121                	addi	sp,sp,64
    80001674:	8082                	ret
      kfree(mem);
    80001676:	8526                	mv	a0,s1
    80001678:	fffff097          	auipc	ra,0xfffff
    8000167c:	50c080e7          	jalr	1292(ra) # 80000b84 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001680:	864e                	mv	a2,s3
    80001682:	85ca                	mv	a1,s2
    80001684:	8556                	mv	a0,s5
    80001686:	00000097          	auipc	ra,0x0
    8000168a:	f1a080e7          	jalr	-230(ra) # 800015a0 <uvmdealloc>
      return 0;
    8000168e:	4501                	li	a0,0
    80001690:	bfc9                	j	80001662 <uvmalloc+0x7a>
    return oldsz;
    80001692:	852e                	mv	a0,a1
}
    80001694:	8082                	ret
  return newsz;
    80001696:	8532                	mv	a0,a2
    80001698:	b7e9                	j	80001662 <uvmalloc+0x7a>

000000008000169a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000169a:	7179                	addi	sp,sp,-48
    8000169c:	f406                	sd	ra,40(sp)
    8000169e:	f022                	sd	s0,32(sp)
    800016a0:	ec26                	sd	s1,24(sp)
    800016a2:	e84a                	sd	s2,16(sp)
    800016a4:	e44e                	sd	s3,8(sp)
    800016a6:	e052                	sd	s4,0(sp)
    800016a8:	1800                	addi	s0,sp,48
    800016aa:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800016ac:	84aa                	mv	s1,a0
    800016ae:	6905                	lui	s2,0x1
    800016b0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016b2:	4985                	li	s3,1
    800016b4:	a829                	j	800016ce <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800016b6:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800016b8:	00c79513          	slli	a0,a5,0xc
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	fde080e7          	jalr	-34(ra) # 8000169a <freewalk>
      pagetable[i] = 0;
    800016c4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016c8:	04a1                	addi	s1,s1,8
    800016ca:	03248163          	beq	s1,s2,800016ec <freewalk+0x52>
    pte_t pte = pagetable[i];
    800016ce:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016d0:	00f7f713          	andi	a4,a5,15
    800016d4:	ff3701e3          	beq	a4,s3,800016b6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016d8:	8b85                	andi	a5,a5,1
    800016da:	d7fd                	beqz	a5,800016c8 <freewalk+0x2e>
      panic("freewalk: leaf");
    800016dc:	00007517          	auipc	a0,0x7
    800016e0:	aac50513          	addi	a0,a0,-1364 # 80008188 <digits+0x148>
    800016e4:	fffff097          	auipc	ra,0xfffff
    800016e8:	e5c080e7          	jalr	-420(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    800016ec:	8552                	mv	a0,s4
    800016ee:	fffff097          	auipc	ra,0xfffff
    800016f2:	496080e7          	jalr	1174(ra) # 80000b84 <kfree>
}
    800016f6:	70a2                	ld	ra,40(sp)
    800016f8:	7402                	ld	s0,32(sp)
    800016fa:	64e2                	ld	s1,24(sp)
    800016fc:	6942                	ld	s2,16(sp)
    800016fe:	69a2                	ld	s3,8(sp)
    80001700:	6a02                	ld	s4,0(sp)
    80001702:	6145                	addi	sp,sp,48
    80001704:	8082                	ret

0000000080001706 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001706:	1101                	addi	sp,sp,-32
    80001708:	ec06                	sd	ra,24(sp)
    8000170a:	e822                	sd	s0,16(sp)
    8000170c:	e426                	sd	s1,8(sp)
    8000170e:	1000                	addi	s0,sp,32
    80001710:	84aa                	mv	s1,a0
  if(sz > 0)
    80001712:	e999                	bnez	a1,80001728 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001714:	8526                	mv	a0,s1
    80001716:	00000097          	auipc	ra,0x0
    8000171a:	f84080e7          	jalr	-124(ra) # 8000169a <freewalk>
}
    8000171e:	60e2                	ld	ra,24(sp)
    80001720:	6442                	ld	s0,16(sp)
    80001722:	64a2                	ld	s1,8(sp)
    80001724:	6105                	addi	sp,sp,32
    80001726:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001728:	6785                	lui	a5,0x1
    8000172a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000172c:	95be                	add	a1,a1,a5
    8000172e:	4685                	li	a3,1
    80001730:	00c5d613          	srli	a2,a1,0xc
    80001734:	4581                	li	a1,0
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	d06080e7          	jalr	-762(ra) # 8000143c <uvmunmap>
    8000173e:	bfd9                	j	80001714 <uvmfree+0xe>

0000000080001740 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    80001740:	7139                	addi	sp,sp,-64
    80001742:	fc06                	sd	ra,56(sp)
    80001744:	f822                	sd	s0,48(sp)
    80001746:	f426                	sd	s1,40(sp)
    80001748:	f04a                	sd	s2,32(sp)
    8000174a:	ec4e                	sd	s3,24(sp)
    8000174c:	e852                	sd	s4,16(sp)
    8000174e:	e456                	sd	s5,8(sp)
    80001750:	e05a                	sd	s6,0(sp)
    80001752:	0080                	addi	s0,sp,64
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  // char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001754:	ce45                	beqz	a2,8000180c <uvmcopy+0xcc>
    80001756:	8b2a                	mv	s6,a0
    80001758:	8aae                	mv	s5,a1
    8000175a:	8a32                	mv	s4,a2
    8000175c:	4481                	li	s1,0
    8000175e:	a0a1                	j	800017a6 <uvmcopy+0x66>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    80001760:	00007517          	auipc	a0,0x7
    80001764:	a3850513          	addi	a0,a0,-1480 # 80008198 <digits+0x158>
    80001768:	fffff097          	auipc	ra,0xfffff
    8000176c:	dd8080e7          	jalr	-552(ra) # 80000540 <panic>
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    80001770:	00007517          	auipc	a0,0x7
    80001774:	a4850513          	addi	a0,a0,-1464 # 800081b8 <digits+0x178>
    80001778:	fffff097          	auipc	ra,0xfffff
    8000177c:	dc8080e7          	jalr	-568(ra) # 80000540 <panic>
      flags = (flags & (~PTE_W)) | PTE_CWR;
      *pte = (*pte & (~PTE_W)) | PTE_CWR;
      }

  }  
    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    80001780:	86ca                	mv	a3,s2
    80001782:	6605                	lui	a2,0x1
    80001784:	85a6                	mv	a1,s1
    80001786:	8556                	mv	a0,s5
    80001788:	00000097          	auipc	ra,0x0
    8000178c:	aee080e7          	jalr	-1298(ra) # 80001276 <mappages>
    80001790:	89aa                	mv	s3,a0
    80001792:	e921                	bnez	a0,800017e2 <uvmcopy+0xa2>
      goto err;
    }
    inc_count((void*)pa);
    80001794:	854a                	mv	a0,s2
    80001796:	fffff097          	auipc	ra,0xfffff
    8000179a:	2f4080e7          	jalr	756(ra) # 80000a8a <inc_count>
  for(i = 0; i < sz; i += PGSIZE){
    8000179e:	6785                	lui	a5,0x1
    800017a0:	94be                	add	s1,s1,a5
    800017a2:	0544fa63          	bgeu	s1,s4,800017f6 <uvmcopy+0xb6>
    if((pte = walk(old, i, 0)) == 0)
    800017a6:	4601                	li	a2,0
    800017a8:	85a6                	mv	a1,s1
    800017aa:	855a                	mv	a0,s6
    800017ac:	00000097          	auipc	ra,0x0
    800017b0:	9e2080e7          	jalr	-1566(ra) # 8000118e <walk>
    800017b4:	d555                	beqz	a0,80001760 <uvmcopy+0x20>
    if((*pte & PTE_V) == 0)
    800017b6:	611c                	ld	a5,0(a0)
    800017b8:	0017f713          	andi	a4,a5,1
    800017bc:	db55                	beqz	a4,80001770 <uvmcopy+0x30>
    pa = PTE2PA(*pte);
    800017be:	00a7d913          	srli	s2,a5,0xa
    800017c2:	0932                	slli	s2,s2,0xc
    flags = PTE_FLAGS(*pte);
    800017c4:	3ff7f713          	andi	a4,a5,1023
    if(flags & PTE_W){
    800017c8:	0047f693          	andi	a3,a5,4
    800017cc:	dad5                	beqz	a3,80001780 <uvmcopy+0x40>
      flags = (flags & (~PTE_W)) | PTE_CWR;
    800017ce:	fdb77713          	andi	a4,a4,-37
    800017d2:	02076713          	ori	a4,a4,32
      *pte = (*pte & (~PTE_W)) | PTE_CWR;
    800017d6:	fdb7f793          	andi	a5,a5,-37
    800017da:	0207e793          	ori	a5,a5,32
    800017de:	e11c                	sd	a5,0(a0)
    800017e0:	b745                	j	80001780 <uvmcopy+0x40>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017e2:	4685                	li	a3,1
    800017e4:	00c4d613          	srli	a2,s1,0xc
    800017e8:	4581                	li	a1,0
    800017ea:	8556                	mv	a0,s5
    800017ec:	00000097          	auipc	ra,0x0
    800017f0:	c50080e7          	jalr	-944(ra) # 8000143c <uvmunmap>
  return -1;
    800017f4:	59fd                	li	s3,-1
}
    800017f6:	854e                	mv	a0,s3
    800017f8:	70e2                	ld	ra,56(sp)
    800017fa:	7442                	ld	s0,48(sp)
    800017fc:	74a2                	ld	s1,40(sp)
    800017fe:	7902                	ld	s2,32(sp)
    80001800:	69e2                	ld	s3,24(sp)
    80001802:	6a42                	ld	s4,16(sp)
    80001804:	6aa2                	ld	s5,8(sp)
    80001806:	6b02                	ld	s6,0(sp)
    80001808:	6121                	addi	sp,sp,64
    8000180a:	8082                	ret
  return 0;
    8000180c:	4981                	li	s3,0
    8000180e:	b7e5                	j	800017f6 <uvmcopy+0xb6>

0000000080001810 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001810:	1141                	addi	sp,sp,-16
    80001812:	e406                	sd	ra,8(sp)
    80001814:	e022                	sd	s0,0(sp)
    80001816:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001818:	4601                	li	a2,0
    8000181a:	00000097          	auipc	ra,0x0
    8000181e:	974080e7          	jalr	-1676(ra) # 8000118e <walk>
  if(pte == 0)
    80001822:	c901                	beqz	a0,80001832 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001824:	611c                	ld	a5,0(a0)
    80001826:	9bbd                	andi	a5,a5,-17
    80001828:	e11c                	sd	a5,0(a0)
}
    8000182a:	60a2                	ld	ra,8(sp)
    8000182c:	6402                	ld	s0,0(sp)
    8000182e:	0141                	addi	sp,sp,16
    80001830:	8082                	ret
    panic("uvmclear");
    80001832:	00007517          	auipc	a0,0x7
    80001836:	9a650513          	addi	a0,a0,-1626 # 800081d8 <digits+0x198>
    8000183a:	fffff097          	auipc	ra,0xfffff
    8000183e:	d06080e7          	jalr	-762(ra) # 80000540 <panic>

0000000080001842 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001842:	caa5                	beqz	a3,800018b2 <copyin+0x70>
{
    80001844:	715d                	addi	sp,sp,-80
    80001846:	e486                	sd	ra,72(sp)
    80001848:	e0a2                	sd	s0,64(sp)
    8000184a:	fc26                	sd	s1,56(sp)
    8000184c:	f84a                	sd	s2,48(sp)
    8000184e:	f44e                	sd	s3,40(sp)
    80001850:	f052                	sd	s4,32(sp)
    80001852:	ec56                	sd	s5,24(sp)
    80001854:	e85a                	sd	s6,16(sp)
    80001856:	e45e                	sd	s7,8(sp)
    80001858:	e062                	sd	s8,0(sp)
    8000185a:	0880                	addi	s0,sp,80
    8000185c:	8b2a                	mv	s6,a0
    8000185e:	8a2e                	mv	s4,a1
    80001860:	8c32                	mv	s8,a2
    80001862:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001864:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001866:	6a85                	lui	s5,0x1
    80001868:	a01d                	j	8000188e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000186a:	018505b3          	add	a1,a0,s8
    8000186e:	0004861b          	sext.w	a2,s1
    80001872:	412585b3          	sub	a1,a1,s2
    80001876:	8552                	mv	a0,s4
    80001878:	fffff097          	auipc	ra,0xfffff
    8000187c:	68e080e7          	jalr	1678(ra) # 80000f06 <memmove>

    len -= n;
    80001880:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001884:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001886:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000188a:	02098263          	beqz	s3,800018ae <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000188e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001892:	85ca                	mv	a1,s2
    80001894:	855a                	mv	a0,s6
    80001896:	00000097          	auipc	ra,0x0
    8000189a:	99e080e7          	jalr	-1634(ra) # 80001234 <walkaddr>
    if(pa0 == 0)
    8000189e:	cd01                	beqz	a0,800018b6 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018a0:	418904b3          	sub	s1,s2,s8
    800018a4:	94d6                	add	s1,s1,s5
    800018a6:	fc99f2e3          	bgeu	s3,s1,8000186a <copyin+0x28>
    800018aa:	84ce                	mv	s1,s3
    800018ac:	bf7d                	j	8000186a <copyin+0x28>
  }
  return 0;
    800018ae:	4501                	li	a0,0
    800018b0:	a021                	j	800018b8 <copyin+0x76>
    800018b2:	4501                	li	a0,0
}
    800018b4:	8082                	ret
      return -1;
    800018b6:	557d                	li	a0,-1
}
    800018b8:	60a6                	ld	ra,72(sp)
    800018ba:	6406                	ld	s0,64(sp)
    800018bc:	74e2                	ld	s1,56(sp)
    800018be:	7942                	ld	s2,48(sp)
    800018c0:	79a2                	ld	s3,40(sp)
    800018c2:	7a02                	ld	s4,32(sp)
    800018c4:	6ae2                	ld	s5,24(sp)
    800018c6:	6b42                	ld	s6,16(sp)
    800018c8:	6ba2                	ld	s7,8(sp)
    800018ca:	6c02                	ld	s8,0(sp)
    800018cc:	6161                	addi	sp,sp,80
    800018ce:	8082                	ret

00000000800018d0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018d0:	c2dd                	beqz	a3,80001976 <copyinstr+0xa6>
{
    800018d2:	715d                	addi	sp,sp,-80
    800018d4:	e486                	sd	ra,72(sp)
    800018d6:	e0a2                	sd	s0,64(sp)
    800018d8:	fc26                	sd	s1,56(sp)
    800018da:	f84a                	sd	s2,48(sp)
    800018dc:	f44e                	sd	s3,40(sp)
    800018de:	f052                	sd	s4,32(sp)
    800018e0:	ec56                	sd	s5,24(sp)
    800018e2:	e85a                	sd	s6,16(sp)
    800018e4:	e45e                	sd	s7,8(sp)
    800018e6:	0880                	addi	s0,sp,80
    800018e8:	8a2a                	mv	s4,a0
    800018ea:	8b2e                	mv	s6,a1
    800018ec:	8bb2                	mv	s7,a2
    800018ee:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018f0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018f2:	6985                	lui	s3,0x1
    800018f4:	a02d                	j	8000191e <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018f6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018fa:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018fc:	37fd                	addiw	a5,a5,-1
    800018fe:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001902:	60a6                	ld	ra,72(sp)
    80001904:	6406                	ld	s0,64(sp)
    80001906:	74e2                	ld	s1,56(sp)
    80001908:	7942                	ld	s2,48(sp)
    8000190a:	79a2                	ld	s3,40(sp)
    8000190c:	7a02                	ld	s4,32(sp)
    8000190e:	6ae2                	ld	s5,24(sp)
    80001910:	6b42                	ld	s6,16(sp)
    80001912:	6ba2                	ld	s7,8(sp)
    80001914:	6161                	addi	sp,sp,80
    80001916:	8082                	ret
    srcva = va0 + PGSIZE;
    80001918:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000191c:	c8a9                	beqz	s1,8000196e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000191e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001922:	85ca                	mv	a1,s2
    80001924:	8552                	mv	a0,s4
    80001926:	00000097          	auipc	ra,0x0
    8000192a:	90e080e7          	jalr	-1778(ra) # 80001234 <walkaddr>
    if(pa0 == 0)
    8000192e:	c131                	beqz	a0,80001972 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001930:	417906b3          	sub	a3,s2,s7
    80001934:	96ce                	add	a3,a3,s3
    80001936:	00d4f363          	bgeu	s1,a3,8000193c <copyinstr+0x6c>
    8000193a:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000193c:	955e                	add	a0,a0,s7
    8000193e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001942:	daf9                	beqz	a3,80001918 <copyinstr+0x48>
    80001944:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001946:	41650633          	sub	a2,a0,s6
    8000194a:	fff48593          	addi	a1,s1,-1
    8000194e:	95da                	add	a1,a1,s6
    while(n > 0){
    80001950:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001952:	00f60733          	add	a4,a2,a5
    80001956:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffbc058>
    8000195a:	df51                	beqz	a4,800018f6 <copyinstr+0x26>
        *dst = *p;
    8000195c:	00e78023          	sb	a4,0(a5)
      --max;
    80001960:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001964:	0785                	addi	a5,a5,1
    while(n > 0){
    80001966:	fed796e3          	bne	a5,a3,80001952 <copyinstr+0x82>
      dst++;
    8000196a:	8b3e                	mv	s6,a5
    8000196c:	b775                	j	80001918 <copyinstr+0x48>
    8000196e:	4781                	li	a5,0
    80001970:	b771                	j	800018fc <copyinstr+0x2c>
      return -1;
    80001972:	557d                	li	a0,-1
    80001974:	b779                	j	80001902 <copyinstr+0x32>
  int got_null = 0;
    80001976:	4781                	li	a5,0
  if(got_null){
    80001978:	37fd                	addiw	a5,a5,-1
    8000197a:	0007851b          	sext.w	a0,a5
}
    8000197e:	8082                	ret

0000000080001980 <COW>:

int COW(pagetable_t pagetable,uint64 va){


  if((va%PGSIZE)>0 || va>=MAXVA){
    80001980:	03459793          	slli	a5,a1,0x34
    80001984:	e3d5                	bnez	a5,80001a28 <COW+0xa8>
int COW(pagetable_t pagetable,uint64 va){
    80001986:	7139                	addi	sp,sp,-64
    80001988:	fc06                	sd	ra,56(sp)
    8000198a:	f822                	sd	s0,48(sp)
    8000198c:	f426                	sd	s1,40(sp)
    8000198e:	f04a                	sd	s2,32(sp)
    80001990:	ec4e                	sd	s3,24(sp)
    80001992:	e852                	sd	s4,16(sp)
    80001994:	e456                	sd	s5,8(sp)
    80001996:	0080                	addi	s0,sp,64
    80001998:	8a2a                	mv	s4,a0
    8000199a:	84ae                	mv	s1,a1
  if((va%PGSIZE)>0 || va>=MAXVA){
    8000199c:	57fd                	li	a5,-1
    8000199e:	83e9                	srli	a5,a5,0x1a
    800019a0:	08b7e663          	bltu	a5,a1,80001a2c <COW+0xac>

  }
 
  
  pte_t *pte;
  pte=walk(pagetable,va,0);
    800019a4:	4601                	li	a2,0
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	7e8080e7          	jalr	2024(ra) # 8000118e <walk>

  if(pte){
    800019ae:	c149                	beqz	a0,80001a30 <COW+0xb0>

    uint64 phy_addr=PTE2PA(*pte);
    800019b0:	6118                	ld	a4,0(a0)
    800019b2:	00a75593          	srli	a1,a4,0xa
    800019b6:	00c59a93          	slli	s5,a1,0xc

    if(*pte!=0 && PTE_CWR){
    800019ba:	cf2d                	beqz	a4,80001a34 <COW+0xb4>

      //set Write flag here since page fault has been raised now!
      uint flags=PTE_FLAGS(*pte);
      flags=(flags & (~PTE_CWR)) | PTE_W;
    800019bc:	3db77713          	andi	a4,a4,987
    800019c0:	00476913          	ori	s2,a4,4

      char* np; //make a new page
      np=kalloc();
    800019c4:	fffff097          	auipc	ra,0xfffff
    800019c8:	024080e7          	jalr	36(ra) # 800009e8 <kalloc>
    800019cc:	89aa                	mv	s3,a0
      if(!np)return -1;
    800019ce:	c52d                	beqz	a0,80001a38 <COW+0xb8>
      
      memset((void*)np,0,sizeof(np));
    800019d0:	4621                	li	a2,8
    800019d2:	4581                	li	a1,0
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	4d6080e7          	jalr	1238(ra) # 80000eaa <memset>

      memmove(np,(char*)phy_addr,PGSIZE); //copy the content of old page to new page
    800019dc:	6605                	lui	a2,0x1
    800019de:	85d6                	mv	a1,s5
    800019e0:	854e                	mv	a0,s3
    800019e2:	fffff097          	auipc	ra,0xfffff
    800019e6:	524080e7          	jalr	1316(ra) # 80000f06 <memmove>

      uvmunmap(pagetable,PGROUNDUP(va),1,1); //unmap the old page
    800019ea:	6785                	lui	a5,0x1
    800019ec:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800019ee:	97a6                	add	a5,a5,s1
    800019f0:	4685                	li	a3,1
    800019f2:	4605                	li	a2,1
    800019f4:	75fd                	lui	a1,0xfffff
    800019f6:	8dfd                	and	a1,a1,a5
    800019f8:	8552                	mv	a0,s4
    800019fa:	00000097          	auipc	ra,0x0
    800019fe:	a42080e7          	jalr	-1470(ra) # 8000143c <uvmunmap>
      mappages(pagetable,va,PGSIZE,(uint64)np,flags); //map the new page
    80001a02:	874a                	mv	a4,s2
    80001a04:	86ce                	mv	a3,s3
    80001a06:	6605                	lui	a2,0x1
    80001a08:	85a6                	mv	a1,s1
    80001a0a:	8552                	mv	a0,s4
    80001a0c:	00000097          	auipc	ra,0x0
    80001a10:	86a080e7          	jalr	-1942(ra) # 80001276 <mappages>
    else return -1;
  }
    else return -1;
    
    
    return 0;
    80001a14:	4501                	li	a0,0


  }
    80001a16:	70e2                	ld	ra,56(sp)
    80001a18:	7442                	ld	s0,48(sp)
    80001a1a:	74a2                	ld	s1,40(sp)
    80001a1c:	7902                	ld	s2,32(sp)
    80001a1e:	69e2                	ld	s3,24(sp)
    80001a20:	6a42                	ld	s4,16(sp)
    80001a22:	6aa2                	ld	s5,8(sp)
    80001a24:	6121                	addi	sp,sp,64
    80001a26:	8082                	ret
      return -1;
    80001a28:	557d                	li	a0,-1
  }
    80001a2a:	8082                	ret
      return -1;
    80001a2c:	557d                	li	a0,-1
    80001a2e:	b7e5                	j	80001a16 <COW+0x96>
    else return -1;
    80001a30:	557d                	li	a0,-1
    80001a32:	b7d5                	j	80001a16 <COW+0x96>
    else return -1;
    80001a34:	557d                	li	a0,-1
    80001a36:	b7c5                	j	80001a16 <COW+0x96>
      if(!np)return -1;
    80001a38:	557d                	li	a0,-1
    80001a3a:	bff1                	j	80001a16 <COW+0x96>

0000000080001a3c <copyout>:
  while(len > 0){
    80001a3c:	cebd                	beqz	a3,80001aba <copyout+0x7e>
{
    80001a3e:	715d                	addi	sp,sp,-80
    80001a40:	e486                	sd	ra,72(sp)
    80001a42:	e0a2                	sd	s0,64(sp)
    80001a44:	fc26                	sd	s1,56(sp)
    80001a46:	f84a                	sd	s2,48(sp)
    80001a48:	f44e                	sd	s3,40(sp)
    80001a4a:	f052                	sd	s4,32(sp)
    80001a4c:	ec56                	sd	s5,24(sp)
    80001a4e:	e85a                	sd	s6,16(sp)
    80001a50:	e45e                	sd	s7,8(sp)
    80001a52:	e062                	sd	s8,0(sp)
    80001a54:	0880                	addi	s0,sp,80
    80001a56:	8b2a                	mv	s6,a0
    80001a58:	892e                	mv	s2,a1
    80001a5a:	8ab2                	mv	s5,a2
    80001a5c:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001a5e:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (dstva - va0);
    80001a60:	6b85                	lui	s7,0x1
    80001a62:	a015                	j	80001a86 <copyout+0x4a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a64:	41390933          	sub	s2,s2,s3
    80001a68:	0004861b          	sext.w	a2,s1
    80001a6c:	85d6                	mv	a1,s5
    80001a6e:	954a                	add	a0,a0,s2
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	496080e7          	jalr	1174(ra) # 80000f06 <memmove>
    len -= n;
    80001a78:	409a0a33          	sub	s4,s4,s1
    src += n;
    80001a7c:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    80001a7e:	01798933          	add	s2,s3,s7
  while(len > 0){
    80001a82:	020a0a63          	beqz	s4,80001ab6 <copyout+0x7a>
    va0 = PGROUNDDOWN(dstva);
    80001a86:	018979b3          	and	s3,s2,s8
    int x=COW(pagetable,va0);
    80001a8a:	85ce                	mv	a1,s3
    80001a8c:	855a                	mv	a0,s6
    80001a8e:	00000097          	auipc	ra,0x0
    80001a92:	ef2080e7          	jalr	-270(ra) # 80001980 <COW>
    if(x<0)return -1;
    80001a96:	02054463          	bltz	a0,80001abe <copyout+0x82>
    pa0 = walkaddr(pagetable, va0);
    80001a9a:	85ce                	mv	a1,s3
    80001a9c:	855a                	mv	a0,s6
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	796080e7          	jalr	1942(ra) # 80001234 <walkaddr>
    if(pa0 == 0)
    80001aa6:	c90d                	beqz	a0,80001ad8 <copyout+0x9c>
    n = PGSIZE - (dstva - va0);
    80001aa8:	412984b3          	sub	s1,s3,s2
    80001aac:	94de                	add	s1,s1,s7
    80001aae:	fa9a7be3          	bgeu	s4,s1,80001a64 <copyout+0x28>
    80001ab2:	84d2                	mv	s1,s4
    80001ab4:	bf45                	j	80001a64 <copyout+0x28>
  return 0;
    80001ab6:	4501                	li	a0,0
    80001ab8:	a021                	j	80001ac0 <copyout+0x84>
    80001aba:	4501                	li	a0,0
}
    80001abc:	8082                	ret
    if(x<0)return -1;
    80001abe:	557d                	li	a0,-1
}
    80001ac0:	60a6                	ld	ra,72(sp)
    80001ac2:	6406                	ld	s0,64(sp)
    80001ac4:	74e2                	ld	s1,56(sp)
    80001ac6:	7942                	ld	s2,48(sp)
    80001ac8:	79a2                	ld	s3,40(sp)
    80001aca:	7a02                	ld	s4,32(sp)
    80001acc:	6ae2                	ld	s5,24(sp)
    80001ace:	6b42                	ld	s6,16(sp)
    80001ad0:	6ba2                	ld	s7,8(sp)
    80001ad2:	6c02                	ld	s8,0(sp)
    80001ad4:	6161                	addi	sp,sp,80
    80001ad6:	8082                	ret
      return -1;
    80001ad8:	557d                	li	a0,-1
    80001ada:	b7dd                	j	80001ac0 <copyout+0x84>

0000000080001adc <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001adc:	7139                	addi	sp,sp,-64
    80001ade:	fc06                	sd	ra,56(sp)
    80001ae0:	f822                	sd	s0,48(sp)
    80001ae2:	f426                	sd	s1,40(sp)
    80001ae4:	f04a                	sd	s2,32(sp)
    80001ae6:	ec4e                	sd	s3,24(sp)
    80001ae8:	e852                	sd	s4,16(sp)
    80001aea:	e456                	sd	s5,8(sp)
    80001aec:	e05a                	sd	s6,0(sp)
    80001aee:	0080                	addi	s0,sp,64
    80001af0:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001af2:	0002f497          	auipc	s1,0x2f
    80001af6:	4d648493          	addi	s1,s1,1238 # 80030fc8 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001afa:	8b26                	mv	s6,s1
    80001afc:	00006a97          	auipc	s5,0x6
    80001b00:	504a8a93          	addi	s5,s5,1284 # 80008000 <etext>
    80001b04:	04000937          	lui	s2,0x4000
    80001b08:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b0a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b0c:	00036a17          	auipc	s4,0x36
    80001b10:	0bca0a13          	addi	s4,s4,188 # 80037bc8 <tickslock>
    char *pa = kalloc();
    80001b14:	fffff097          	auipc	ra,0xfffff
    80001b18:	ed4080e7          	jalr	-300(ra) # 800009e8 <kalloc>
    80001b1c:	862a                	mv	a2,a0
    if (pa == 0)
    80001b1e:	c131                	beqz	a0,80001b62 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001b20:	416485b3          	sub	a1,s1,s6
    80001b24:	8591                	srai	a1,a1,0x4
    80001b26:	000ab783          	ld	a5,0(s5)
    80001b2a:	02f585b3          	mul	a1,a1,a5
    80001b2e:	2585                	addiw	a1,a1,1 # fffffffffffff001 <end+0xffffffff7ffbc059>
    80001b30:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b34:	4719                	li	a4,6
    80001b36:	6685                	lui	a3,0x1
    80001b38:	40b905b3          	sub	a1,s2,a1
    80001b3c:	854e                	mv	a0,s3
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	7d8080e7          	jalr	2008(ra) # 80001316 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001b46:	1b048493          	addi	s1,s1,432
    80001b4a:	fd4495e3          	bne	s1,s4,80001b14 <proc_mapstacks+0x38>
  }
}
    80001b4e:	70e2                	ld	ra,56(sp)
    80001b50:	7442                	ld	s0,48(sp)
    80001b52:	74a2                	ld	s1,40(sp)
    80001b54:	7902                	ld	s2,32(sp)
    80001b56:	69e2                	ld	s3,24(sp)
    80001b58:	6a42                	ld	s4,16(sp)
    80001b5a:	6aa2                	ld	s5,8(sp)
    80001b5c:	6b02                	ld	s6,0(sp)
    80001b5e:	6121                	addi	sp,sp,64
    80001b60:	8082                	ret
      panic("kalloc");
    80001b62:	00006517          	auipc	a0,0x6
    80001b66:	68650513          	addi	a0,a0,1670 # 800081e8 <digits+0x1a8>
    80001b6a:	fffff097          	auipc	ra,0xfffff
    80001b6e:	9d6080e7          	jalr	-1578(ra) # 80000540 <panic>

0000000080001b72 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001b72:	7139                	addi	sp,sp,-64
    80001b74:	fc06                	sd	ra,56(sp)
    80001b76:	f822                	sd	s0,48(sp)
    80001b78:	f426                	sd	s1,40(sp)
    80001b7a:	f04a                	sd	s2,32(sp)
    80001b7c:	ec4e                	sd	s3,24(sp)
    80001b7e:	e852                	sd	s4,16(sp)
    80001b80:	e456                	sd	s5,8(sp)
    80001b82:	e05a                	sd	s6,0(sp)
    80001b84:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001b86:	00006597          	auipc	a1,0x6
    80001b8a:	66a58593          	addi	a1,a1,1642 # 800081f0 <digits+0x1b0>
    80001b8e:	0002f517          	auipc	a0,0x2f
    80001b92:	00a50513          	addi	a0,a0,10 # 80030b98 <pid_lock>
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	188080e7          	jalr	392(ra) # 80000d1e <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b9e:	00006597          	auipc	a1,0x6
    80001ba2:	65a58593          	addi	a1,a1,1626 # 800081f8 <digits+0x1b8>
    80001ba6:	0002f517          	auipc	a0,0x2f
    80001baa:	00a50513          	addi	a0,a0,10 # 80030bb0 <wait_lock>
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	170080e7          	jalr	368(ra) # 80000d1e <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bb6:	0002f497          	auipc	s1,0x2f
    80001bba:	41248493          	addi	s1,s1,1042 # 80030fc8 <proc>
  {
    initlock(&p->lock, "proc");
    80001bbe:	00006b17          	auipc	s6,0x6
    80001bc2:	64ab0b13          	addi	s6,s6,1610 # 80008208 <digits+0x1c8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001bc6:	8aa6                	mv	s5,s1
    80001bc8:	00006a17          	auipc	s4,0x6
    80001bcc:	438a0a13          	addi	s4,s4,1080 # 80008000 <etext>
    80001bd0:	04000937          	lui	s2,0x4000
    80001bd4:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001bd6:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001bd8:	00036997          	auipc	s3,0x36
    80001bdc:	ff098993          	addi	s3,s3,-16 # 80037bc8 <tickslock>
    initlock(&p->lock, "proc");
    80001be0:	85da                	mv	a1,s6
    80001be2:	8526                	mv	a0,s1
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	13a080e7          	jalr	314(ra) # 80000d1e <initlock>
    p->state = UNUSED;
    80001bec:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001bf0:	415487b3          	sub	a5,s1,s5
    80001bf4:	8791                	srai	a5,a5,0x4
    80001bf6:	000a3703          	ld	a4,0(s4)
    80001bfa:	02e787b3          	mul	a5,a5,a4
    80001bfe:	2785                	addiw	a5,a5,1
    80001c00:	00d7979b          	slliw	a5,a5,0xd
    80001c04:	40f907b3          	sub	a5,s2,a5
    80001c08:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001c0a:	1b048493          	addi	s1,s1,432
    80001c0e:	fd3499e3          	bne	s1,s3,80001be0 <procinit+0x6e>
  }
}
    80001c12:	70e2                	ld	ra,56(sp)
    80001c14:	7442                	ld	s0,48(sp)
    80001c16:	74a2                	ld	s1,40(sp)
    80001c18:	7902                	ld	s2,32(sp)
    80001c1a:	69e2                	ld	s3,24(sp)
    80001c1c:	6a42                	ld	s4,16(sp)
    80001c1e:	6aa2                	ld	s5,8(sp)
    80001c20:	6b02                	ld	s6,0(sp)
    80001c22:	6121                	addi	sp,sp,64
    80001c24:	8082                	ret

0000000080001c26 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001c26:	1141                	addi	sp,sp,-16
    80001c28:	e422                	sd	s0,8(sp)
    80001c2a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c2c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001c2e:	2501                	sext.w	a0,a0
    80001c30:	6422                	ld	s0,8(sp)
    80001c32:	0141                	addi	sp,sp,16
    80001c34:	8082                	ret

0000000080001c36 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001c36:	1141                	addi	sp,sp,-16
    80001c38:	e422                	sd	s0,8(sp)
    80001c3a:	0800                	addi	s0,sp,16
    80001c3c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c3e:	2781                	sext.w	a5,a5
    80001c40:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c42:	0002f517          	auipc	a0,0x2f
    80001c46:	f8650513          	addi	a0,a0,-122 # 80030bc8 <cpus>
    80001c4a:	953e                	add	a0,a0,a5
    80001c4c:	6422                	ld	s0,8(sp)
    80001c4e:	0141                	addi	sp,sp,16
    80001c50:	8082                	ret

0000000080001c52 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001c52:	1101                	addi	sp,sp,-32
    80001c54:	ec06                	sd	ra,24(sp)
    80001c56:	e822                	sd	s0,16(sp)
    80001c58:	e426                	sd	s1,8(sp)
    80001c5a:	1000                	addi	s0,sp,32
  push_off();
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	106080e7          	jalr	262(ra) # 80000d62 <push_off>
    80001c64:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c66:	2781                	sext.w	a5,a5
    80001c68:	079e                	slli	a5,a5,0x7
    80001c6a:	0002f717          	auipc	a4,0x2f
    80001c6e:	f2e70713          	addi	a4,a4,-210 # 80030b98 <pid_lock>
    80001c72:	97ba                	add	a5,a5,a4
    80001c74:	7b84                	ld	s1,48(a5)
  pop_off();
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	18c080e7          	jalr	396(ra) # 80000e02 <pop_off>
  return p;
}
    80001c7e:	8526                	mv	a0,s1
    80001c80:	60e2                	ld	ra,24(sp)
    80001c82:	6442                	ld	s0,16(sp)
    80001c84:	64a2                	ld	s1,8(sp)
    80001c86:	6105                	addi	sp,sp,32
    80001c88:	8082                	ret

0000000080001c8a <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001c8a:	1141                	addi	sp,sp,-16
    80001c8c:	e406                	sd	ra,8(sp)
    80001c8e:	e022                	sd	s0,0(sp)
    80001c90:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	fc0080e7          	jalr	-64(ra) # 80001c52 <myproc>
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	1c8080e7          	jalr	456(ra) # 80000e62 <release>

  if (first)
    80001ca2:	00007797          	auipc	a5,0x7
    80001ca6:	bce7a783          	lw	a5,-1074(a5) # 80008870 <first.1>
    80001caa:	eb89                	bnez	a5,80001cbc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001cac:	00001097          	auipc	ra,0x1
    80001cb0:	e7e080e7          	jalr	-386(ra) # 80002b2a <usertrapret>
}
    80001cb4:	60a2                	ld	ra,8(sp)
    80001cb6:	6402                	ld	s0,0(sp)
    80001cb8:	0141                	addi	sp,sp,16
    80001cba:	8082                	ret
    first = 0;
    80001cbc:	00007797          	auipc	a5,0x7
    80001cc0:	ba07aa23          	sw	zero,-1100(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001cc4:	4505                	li	a0,1
    80001cc6:	00002097          	auipc	ra,0x2
    80001cca:	e14080e7          	jalr	-492(ra) # 80003ada <fsinit>
    80001cce:	bff9                	j	80001cac <forkret+0x22>

0000000080001cd0 <allocpid>:
{
    80001cd0:	1101                	addi	sp,sp,-32
    80001cd2:	ec06                	sd	ra,24(sp)
    80001cd4:	e822                	sd	s0,16(sp)
    80001cd6:	e426                	sd	s1,8(sp)
    80001cd8:	e04a                	sd	s2,0(sp)
    80001cda:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001cdc:	0002f917          	auipc	s2,0x2f
    80001ce0:	ebc90913          	addi	s2,s2,-324 # 80030b98 <pid_lock>
    80001ce4:	854a                	mv	a0,s2
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	0c8080e7          	jalr	200(ra) # 80000dae <acquire>
  pid = nextpid;
    80001cee:	00007797          	auipc	a5,0x7
    80001cf2:	b8678793          	addi	a5,a5,-1146 # 80008874 <nextpid>
    80001cf6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001cf8:	0014871b          	addiw	a4,s1,1
    80001cfc:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001cfe:	854a                	mv	a0,s2
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	162080e7          	jalr	354(ra) # 80000e62 <release>
}
    80001d08:	8526                	mv	a0,s1
    80001d0a:	60e2                	ld	ra,24(sp)
    80001d0c:	6442                	ld	s0,16(sp)
    80001d0e:	64a2                	ld	s1,8(sp)
    80001d10:	6902                	ld	s2,0(sp)
    80001d12:	6105                	addi	sp,sp,32
    80001d14:	8082                	ret

0000000080001d16 <proc_pagetable>:
{
    80001d16:	1101                	addi	sp,sp,-32
    80001d18:	ec06                	sd	ra,24(sp)
    80001d1a:	e822                	sd	s0,16(sp)
    80001d1c:	e426                	sd	s1,8(sp)
    80001d1e:	e04a                	sd	s2,0(sp)
    80001d20:	1000                	addi	s0,sp,32
    80001d22:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	7dc080e7          	jalr	2012(ra) # 80001500 <uvmcreate>
    80001d2c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001d2e:	c121                	beqz	a0,80001d6e <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d30:	4729                	li	a4,10
    80001d32:	00005697          	auipc	a3,0x5
    80001d36:	2ce68693          	addi	a3,a3,718 # 80007000 <_trampoline>
    80001d3a:	6605                	lui	a2,0x1
    80001d3c:	040005b7          	lui	a1,0x4000
    80001d40:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d42:	05b2                	slli	a1,a1,0xc
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	532080e7          	jalr	1330(ra) # 80001276 <mappages>
    80001d4c:	02054863          	bltz	a0,80001d7c <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d50:	4719                	li	a4,6
    80001d52:	05893683          	ld	a3,88(s2)
    80001d56:	6605                	lui	a2,0x1
    80001d58:	020005b7          	lui	a1,0x2000
    80001d5c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d5e:	05b6                	slli	a1,a1,0xd
    80001d60:	8526                	mv	a0,s1
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	514080e7          	jalr	1300(ra) # 80001276 <mappages>
    80001d6a:	02054163          	bltz	a0,80001d8c <proc_pagetable+0x76>
}
    80001d6e:	8526                	mv	a0,s1
    80001d70:	60e2                	ld	ra,24(sp)
    80001d72:	6442                	ld	s0,16(sp)
    80001d74:	64a2                	ld	s1,8(sp)
    80001d76:	6902                	ld	s2,0(sp)
    80001d78:	6105                	addi	sp,sp,32
    80001d7a:	8082                	ret
    uvmfree(pagetable, 0);
    80001d7c:	4581                	li	a1,0
    80001d7e:	8526                	mv	a0,s1
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	986080e7          	jalr	-1658(ra) # 80001706 <uvmfree>
    return 0;
    80001d88:	4481                	li	s1,0
    80001d8a:	b7d5                	j	80001d6e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d8c:	4681                	li	a3,0
    80001d8e:	4605                	li	a2,1
    80001d90:	040005b7          	lui	a1,0x4000
    80001d94:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d96:	05b2                	slli	a1,a1,0xc
    80001d98:	8526                	mv	a0,s1
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	6a2080e7          	jalr	1698(ra) # 8000143c <uvmunmap>
    uvmfree(pagetable, 0);
    80001da2:	4581                	li	a1,0
    80001da4:	8526                	mv	a0,s1
    80001da6:	00000097          	auipc	ra,0x0
    80001daa:	960080e7          	jalr	-1696(ra) # 80001706 <uvmfree>
    return 0;
    80001dae:	4481                	li	s1,0
    80001db0:	bf7d                	j	80001d6e <proc_pagetable+0x58>

0000000080001db2 <proc_freepagetable>:
{
    80001db2:	1101                	addi	sp,sp,-32
    80001db4:	ec06                	sd	ra,24(sp)
    80001db6:	e822                	sd	s0,16(sp)
    80001db8:	e426                	sd	s1,8(sp)
    80001dba:	e04a                	sd	s2,0(sp)
    80001dbc:	1000                	addi	s0,sp,32
    80001dbe:	84aa                	mv	s1,a0
    80001dc0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dc2:	4681                	li	a3,0
    80001dc4:	4605                	li	a2,1
    80001dc6:	040005b7          	lui	a1,0x4000
    80001dca:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001dcc:	05b2                	slli	a1,a1,0xc
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	66e080e7          	jalr	1646(ra) # 8000143c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001dd6:	4681                	li	a3,0
    80001dd8:	4605                	li	a2,1
    80001dda:	020005b7          	lui	a1,0x2000
    80001dde:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001de0:	05b6                	slli	a1,a1,0xd
    80001de2:	8526                	mv	a0,s1
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	658080e7          	jalr	1624(ra) # 8000143c <uvmunmap>
  uvmfree(pagetable, sz);
    80001dec:	85ca                	mv	a1,s2
    80001dee:	8526                	mv	a0,s1
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	916080e7          	jalr	-1770(ra) # 80001706 <uvmfree>
}
    80001df8:	60e2                	ld	ra,24(sp)
    80001dfa:	6442                	ld	s0,16(sp)
    80001dfc:	64a2                	ld	s1,8(sp)
    80001dfe:	6902                	ld	s2,0(sp)
    80001e00:	6105                	addi	sp,sp,32
    80001e02:	8082                	ret

0000000080001e04 <freeproc>:
{
    80001e04:	1101                	addi	sp,sp,-32
    80001e06:	ec06                	sd	ra,24(sp)
    80001e08:	e822                	sd	s0,16(sp)
    80001e0a:	e426                	sd	s1,8(sp)
    80001e0c:	1000                	addi	s0,sp,32
    80001e0e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001e10:	6d28                	ld	a0,88(a0)
    80001e12:	c509                	beqz	a0,80001e1c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	d70080e7          	jalr	-656(ra) # 80000b84 <kfree>
  p->trapframe = 0;
    80001e1c:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001e20:	68a8                	ld	a0,80(s1)
    80001e22:	c511                	beqz	a0,80001e2e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e24:	64ac                	ld	a1,72(s1)
    80001e26:	00000097          	auipc	ra,0x0
    80001e2a:	f8c080e7          	jalr	-116(ra) # 80001db2 <proc_freepagetable>
  p->pagetable = 0;
    80001e2e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001e32:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001e36:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001e3a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001e3e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e42:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e46:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e4a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e4e:	0004ac23          	sw	zero,24(s1)
}
    80001e52:	60e2                	ld	ra,24(sp)
    80001e54:	6442                	ld	s0,16(sp)
    80001e56:	64a2                	ld	s1,8(sp)
    80001e58:	6105                	addi	sp,sp,32
    80001e5a:	8082                	ret

0000000080001e5c <allocproc>:
{
    80001e5c:	1101                	addi	sp,sp,-32
    80001e5e:	ec06                	sd	ra,24(sp)
    80001e60:	e822                	sd	s0,16(sp)
    80001e62:	e426                	sd	s1,8(sp)
    80001e64:	e04a                	sd	s2,0(sp)
    80001e66:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001e68:	0002f497          	auipc	s1,0x2f
    80001e6c:	16048493          	addi	s1,s1,352 # 80030fc8 <proc>
    80001e70:	00036917          	auipc	s2,0x36
    80001e74:	d5890913          	addi	s2,s2,-680 # 80037bc8 <tickslock>
    acquire(&p->lock);
    80001e78:	8526                	mv	a0,s1
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	f34080e7          	jalr	-204(ra) # 80000dae <acquire>
    if (p->state == UNUSED)
    80001e82:	4c9c                	lw	a5,24(s1)
    80001e84:	cf81                	beqz	a5,80001e9c <allocproc+0x40>
      release(&p->lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	fda080e7          	jalr	-38(ra) # 80000e62 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001e90:	1b048493          	addi	s1,s1,432
    80001e94:	ff2492e3          	bne	s1,s2,80001e78 <allocproc+0x1c>
  return 0;
    80001e98:	4481                	li	s1,0
    80001e9a:	a859                	j	80001f30 <allocproc+0xd4>
  p->pid = allocpid();
    80001e9c:	00000097          	auipc	ra,0x0
    80001ea0:	e34080e7          	jalr	-460(ra) # 80001cd0 <allocpid>
    80001ea4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ea6:	4785                	li	a5,1
    80001ea8:	cc9c                	sw	a5,24(s1)
  p->readcount=0;
    80001eaa:	1604aa23          	sw	zero,372(s1)
  p->clockticks=0;
    80001eae:	1604ac23          	sw	zero,376(s1)
  p->alarm_state=0;
    80001eb2:	1604ae23          	sw	zero,380(s1)
  p->currentticks=0;
    80001eb6:	1804aa23          	sw	zero,404(s1)
  p->is_alarm=0;
    80001eba:	1804a823          	sw	zero,400(s1)
  p->entered_queue=0;
    80001ebe:	1804ae23          	sw	zero,412(s1)
  p->queue_no=0;
    80001ec2:	1804ac23          	sw	zero,408(s1)
  p->intime=ticks;
    80001ec6:	00007797          	auipc	a5,0x7
    80001eca:	a4a7a783          	lw	a5,-1462(a5) # 80008910 <ticks>
    80001ece:	1af4a223          	sw	a5,420(s1)
  p->ticks_used=0;
    80001ed2:	1a04a023          	sw	zero,416(s1)
  p->waittime=0;
    80001ed6:	1a04a423          	sw	zero,424(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	b0e080e7          	jalr	-1266(ra) # 800009e8 <kalloc>
    80001ee2:	892a                	mv	s2,a0
    80001ee4:	eca8                	sd	a0,88(s1)
    80001ee6:	cd21                	beqz	a0,80001f3e <allocproc+0xe2>
  p->pagetable = proc_pagetable(p);
    80001ee8:	8526                	mv	a0,s1
    80001eea:	00000097          	auipc	ra,0x0
    80001eee:	e2c080e7          	jalr	-468(ra) # 80001d16 <proc_pagetable>
    80001ef2:	892a                	mv	s2,a0
    80001ef4:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001ef6:	c125                	beqz	a0,80001f56 <allocproc+0xfa>
  memset(&p->context, 0, sizeof(p->context));
    80001ef8:	07000613          	li	a2,112
    80001efc:	4581                	li	a1,0
    80001efe:	06048513          	addi	a0,s1,96
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	fa8080e7          	jalr	-88(ra) # 80000eaa <memset>
  p->context.ra = (uint64)forkret;
    80001f0a:	00000797          	auipc	a5,0x0
    80001f0e:	d8078793          	addi	a5,a5,-640 # 80001c8a <forkret>
    80001f12:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f14:	60bc                	ld	a5,64(s1)
    80001f16:	6705                	lui	a4,0x1
    80001f18:	97ba                	add	a5,a5,a4
    80001f1a:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001f1c:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001f20:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001f24:	00007797          	auipc	a5,0x7
    80001f28:	9ec7a783          	lw	a5,-1556(a5) # 80008910 <ticks>
    80001f2c:	16f4a623          	sw	a5,364(s1)
}
    80001f30:	8526                	mv	a0,s1
    80001f32:	60e2                	ld	ra,24(sp)
    80001f34:	6442                	ld	s0,16(sp)
    80001f36:	64a2                	ld	s1,8(sp)
    80001f38:	6902                	ld	s2,0(sp)
    80001f3a:	6105                	addi	sp,sp,32
    80001f3c:	8082                	ret
    freeproc(p);
    80001f3e:	8526                	mv	a0,s1
    80001f40:	00000097          	auipc	ra,0x0
    80001f44:	ec4080e7          	jalr	-316(ra) # 80001e04 <freeproc>
    release(&p->lock);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	f18080e7          	jalr	-232(ra) # 80000e62 <release>
    return 0;
    80001f52:	84ca                	mv	s1,s2
    80001f54:	bff1                	j	80001f30 <allocproc+0xd4>
    freeproc(p);
    80001f56:	8526                	mv	a0,s1
    80001f58:	00000097          	auipc	ra,0x0
    80001f5c:	eac080e7          	jalr	-340(ra) # 80001e04 <freeproc>
    release(&p->lock);
    80001f60:	8526                	mv	a0,s1
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	f00080e7          	jalr	-256(ra) # 80000e62 <release>
    return 0;
    80001f6a:	84ca                	mv	s1,s2
    80001f6c:	b7d1                	j	80001f30 <allocproc+0xd4>

0000000080001f6e <userinit>:
{
    80001f6e:	1101                	addi	sp,sp,-32
    80001f70:	ec06                	sd	ra,24(sp)
    80001f72:	e822                	sd	s0,16(sp)
    80001f74:	e426                	sd	s1,8(sp)
    80001f76:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f78:	00000097          	auipc	ra,0x0
    80001f7c:	ee4080e7          	jalr	-284(ra) # 80001e5c <allocproc>
    80001f80:	84aa                	mv	s1,a0
  initproc = p;
    80001f82:	00007797          	auipc	a5,0x7
    80001f86:	98a7b323          	sd	a0,-1658(a5) # 80008908 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f8a:	03400613          	li	a2,52
    80001f8e:	00007597          	auipc	a1,0x7
    80001f92:	8f258593          	addi	a1,a1,-1806 # 80008880 <initcode>
    80001f96:	6928                	ld	a0,80(a0)
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	596080e7          	jalr	1430(ra) # 8000152e <uvmfirst>
  p->sz = PGSIZE;
    80001fa0:	6785                	lui	a5,0x1
    80001fa2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001fa4:	6cb8                	ld	a4,88(s1)
    80001fa6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001faa:	6cb8                	ld	a4,88(s1)
    80001fac:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fae:	4641                	li	a2,16
    80001fb0:	00006597          	auipc	a1,0x6
    80001fb4:	26058593          	addi	a1,a1,608 # 80008210 <digits+0x1d0>
    80001fb8:	15848513          	addi	a0,s1,344
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	038080e7          	jalr	56(ra) # 80000ff4 <safestrcpy>
  p->cwd = namei("/");
    80001fc4:	00006517          	auipc	a0,0x6
    80001fc8:	25c50513          	addi	a0,a0,604 # 80008220 <digits+0x1e0>
    80001fcc:	00002097          	auipc	ra,0x2
    80001fd0:	538080e7          	jalr	1336(ra) # 80004504 <namei>
    80001fd4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001fd8:	478d                	li	a5,3
    80001fda:	cc9c                	sw	a5,24(s1)
  p->queue_no=0;
    80001fdc:	1804ac23          	sw	zero,408(s1)
  p->intime=ticks;
    80001fe0:	00007797          	auipc	a5,0x7
    80001fe4:	9307a783          	lw	a5,-1744(a5) # 80008910 <ticks>
    80001fe8:	1af4a223          	sw	a5,420(s1)
  p->ticks_used=0;
    80001fec:	1a04a023          	sw	zero,416(s1)
  release(&p->lock);
    80001ff0:	8526                	mv	a0,s1
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	e70080e7          	jalr	-400(ra) # 80000e62 <release>
}
    80001ffa:	60e2                	ld	ra,24(sp)
    80001ffc:	6442                	ld	s0,16(sp)
    80001ffe:	64a2                	ld	s1,8(sp)
    80002000:	6105                	addi	sp,sp,32
    80002002:	8082                	ret

0000000080002004 <growproc>:
{
    80002004:	1101                	addi	sp,sp,-32
    80002006:	ec06                	sd	ra,24(sp)
    80002008:	e822                	sd	s0,16(sp)
    8000200a:	e426                	sd	s1,8(sp)
    8000200c:	e04a                	sd	s2,0(sp)
    8000200e:	1000                	addi	s0,sp,32
    80002010:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002012:	00000097          	auipc	ra,0x0
    80002016:	c40080e7          	jalr	-960(ra) # 80001c52 <myproc>
    8000201a:	84aa                	mv	s1,a0
  sz = p->sz;
    8000201c:	652c                	ld	a1,72(a0)
  if (n > 0)
    8000201e:	01204c63          	bgtz	s2,80002036 <growproc+0x32>
  else if (n < 0)
    80002022:	02094663          	bltz	s2,8000204e <growproc+0x4a>
  p->sz = sz;
    80002026:	e4ac                	sd	a1,72(s1)
  return 0;
    80002028:	4501                	li	a0,0
}
    8000202a:	60e2                	ld	ra,24(sp)
    8000202c:	6442                	ld	s0,16(sp)
    8000202e:	64a2                	ld	s1,8(sp)
    80002030:	6902                	ld	s2,0(sp)
    80002032:	6105                	addi	sp,sp,32
    80002034:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80002036:	4691                	li	a3,4
    80002038:	00b90633          	add	a2,s2,a1
    8000203c:	6928                	ld	a0,80(a0)
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	5aa080e7          	jalr	1450(ra) # 800015e8 <uvmalloc>
    80002046:	85aa                	mv	a1,a0
    80002048:	fd79                	bnez	a0,80002026 <growproc+0x22>
      return -1;
    8000204a:	557d                	li	a0,-1
    8000204c:	bff9                	j	8000202a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000204e:	00b90633          	add	a2,s2,a1
    80002052:	6928                	ld	a0,80(a0)
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	54c080e7          	jalr	1356(ra) # 800015a0 <uvmdealloc>
    8000205c:	85aa                	mv	a1,a0
    8000205e:	b7e1                	j	80002026 <growproc+0x22>

0000000080002060 <fork>:
{
    80002060:	7139                	addi	sp,sp,-64
    80002062:	fc06                	sd	ra,56(sp)
    80002064:	f822                	sd	s0,48(sp)
    80002066:	f426                	sd	s1,40(sp)
    80002068:	f04a                	sd	s2,32(sp)
    8000206a:	ec4e                	sd	s3,24(sp)
    8000206c:	e852                	sd	s4,16(sp)
    8000206e:	e456                	sd	s5,8(sp)
    80002070:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002072:	00000097          	auipc	ra,0x0
    80002076:	be0080e7          	jalr	-1056(ra) # 80001c52 <myproc>
    8000207a:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	de0080e7          	jalr	-544(ra) # 80001e5c <allocproc>
    80002084:	10050c63          	beqz	a0,8000219c <fork+0x13c>
    80002088:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    8000208a:	048ab603          	ld	a2,72(s5)
    8000208e:	692c                	ld	a1,80(a0)
    80002090:	050ab503          	ld	a0,80(s5)
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	6ac080e7          	jalr	1708(ra) # 80001740 <uvmcopy>
    8000209c:	04054863          	bltz	a0,800020ec <fork+0x8c>
  np->sz = p->sz;
    800020a0:	048ab783          	ld	a5,72(s5)
    800020a4:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    800020a8:	058ab683          	ld	a3,88(s5)
    800020ac:	87b6                	mv	a5,a3
    800020ae:	058a3703          	ld	a4,88(s4)
    800020b2:	12068693          	addi	a3,a3,288
    800020b6:	0007b803          	ld	a6,0(a5)
    800020ba:	6788                	ld	a0,8(a5)
    800020bc:	6b8c                	ld	a1,16(a5)
    800020be:	6f90                	ld	a2,24(a5)
    800020c0:	01073023          	sd	a6,0(a4)
    800020c4:	e708                	sd	a0,8(a4)
    800020c6:	eb0c                	sd	a1,16(a4)
    800020c8:	ef10                	sd	a2,24(a4)
    800020ca:	02078793          	addi	a5,a5,32
    800020ce:	02070713          	addi	a4,a4,32
    800020d2:	fed792e3          	bne	a5,a3,800020b6 <fork+0x56>
  np->trapframe->a0 = 0;
    800020d6:	058a3783          	ld	a5,88(s4)
    800020da:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    800020de:	0d0a8493          	addi	s1,s5,208
    800020e2:	0d0a0913          	addi	s2,s4,208
    800020e6:	150a8993          	addi	s3,s5,336
    800020ea:	a00d                	j	8000210c <fork+0xac>
    freeproc(np);
    800020ec:	8552                	mv	a0,s4
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	d16080e7          	jalr	-746(ra) # 80001e04 <freeproc>
    release(&np->lock);
    800020f6:	8552                	mv	a0,s4
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	d6a080e7          	jalr	-662(ra) # 80000e62 <release>
    return -1;
    80002100:	597d                	li	s2,-1
    80002102:	a059                	j	80002188 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80002104:	04a1                	addi	s1,s1,8
    80002106:	0921                	addi	s2,s2,8
    80002108:	01348b63          	beq	s1,s3,8000211e <fork+0xbe>
    if (p->ofile[i])
    8000210c:	6088                	ld	a0,0(s1)
    8000210e:	d97d                	beqz	a0,80002104 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002110:	00003097          	auipc	ra,0x3
    80002114:	a8a080e7          	jalr	-1398(ra) # 80004b9a <filedup>
    80002118:	00a93023          	sd	a0,0(s2)
    8000211c:	b7e5                	j	80002104 <fork+0xa4>
  np->cwd = idup(p->cwd);
    8000211e:	150ab503          	ld	a0,336(s5)
    80002122:	00002097          	auipc	ra,0x2
    80002126:	bf8080e7          	jalr	-1032(ra) # 80003d1a <idup>
    8000212a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000212e:	4641                	li	a2,16
    80002130:	158a8593          	addi	a1,s5,344
    80002134:	158a0513          	addi	a0,s4,344
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	ebc080e7          	jalr	-324(ra) # 80000ff4 <safestrcpy>
  pid = np->pid;
    80002140:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80002144:	8552                	mv	a0,s4
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	d1c080e7          	jalr	-740(ra) # 80000e62 <release>
  acquire(&wait_lock);
    8000214e:	0002f497          	auipc	s1,0x2f
    80002152:	a6248493          	addi	s1,s1,-1438 # 80030bb0 <wait_lock>
    80002156:	8526                	mv	a0,s1
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	c56080e7          	jalr	-938(ra) # 80000dae <acquire>
  np->parent = p;
    80002160:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80002164:	8526                	mv	a0,s1
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	cfc080e7          	jalr	-772(ra) # 80000e62 <release>
  acquire(&np->lock);
    8000216e:	8552                	mv	a0,s4
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	c3e080e7          	jalr	-962(ra) # 80000dae <acquire>
  np->state = RUNNABLE;
    80002178:	478d                	li	a5,3
    8000217a:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    8000217e:	8552                	mv	a0,s4
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	ce2080e7          	jalr	-798(ra) # 80000e62 <release>
}
    80002188:	854a                	mv	a0,s2
    8000218a:	70e2                	ld	ra,56(sp)
    8000218c:	7442                	ld	s0,48(sp)
    8000218e:	74a2                	ld	s1,40(sp)
    80002190:	7902                	ld	s2,32(sp)
    80002192:	69e2                	ld	s3,24(sp)
    80002194:	6a42                	ld	s4,16(sp)
    80002196:	6aa2                	ld	s5,8(sp)
    80002198:	6121                	addi	sp,sp,64
    8000219a:	8082                	ret
    return -1;
    8000219c:	597d                	li	s2,-1
    8000219e:	b7ed                	j	80002188 <fork+0x128>

00000000800021a0 <scheduler>:
{
    800021a0:	7139                	addi	sp,sp,-64
    800021a2:	fc06                	sd	ra,56(sp)
    800021a4:	f822                	sd	s0,48(sp)
    800021a6:	f426                	sd	s1,40(sp)
    800021a8:	f04a                	sd	s2,32(sp)
    800021aa:	ec4e                	sd	s3,24(sp)
    800021ac:	e852                	sd	s4,16(sp)
    800021ae:	e456                	sd	s5,8(sp)
    800021b0:	e05a                	sd	s6,0(sp)
    800021b2:	0080                	addi	s0,sp,64
    800021b4:	8792                	mv	a5,tp
  int id = r_tp();
    800021b6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021b8:	00779a93          	slli	s5,a5,0x7
    800021bc:	0002f717          	auipc	a4,0x2f
    800021c0:	9dc70713          	addi	a4,a4,-1572 # 80030b98 <pid_lock>
    800021c4:	9756                	add	a4,a4,s5
    800021c6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800021ca:	0002f717          	auipc	a4,0x2f
    800021ce:	a0670713          	addi	a4,a4,-1530 # 80030bd0 <cpus+0x8>
    800021d2:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    800021d4:	498d                	li	s3,3
        p->state = RUNNING;
    800021d6:	4b11                	li	s6,4
        c->proc = p;
    800021d8:	079e                	slli	a5,a5,0x7
    800021da:	0002fa17          	auipc	s4,0x2f
    800021de:	9bea0a13          	addi	s4,s4,-1602 # 80030b98 <pid_lock>
    800021e2:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800021e4:	00036917          	auipc	s2,0x36
    800021e8:	9e490913          	addi	s2,s2,-1564 # 80037bc8 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021ec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021f0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021f4:	10079073          	csrw	sstatus,a5
    800021f8:	0002f497          	auipc	s1,0x2f
    800021fc:	dd048493          	addi	s1,s1,-560 # 80030fc8 <proc>
    80002200:	a811                	j	80002214 <scheduler+0x74>
      release(&p->lock);
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	c5e080e7          	jalr	-930(ra) # 80000e62 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000220c:	1b048493          	addi	s1,s1,432
    80002210:	fd248ee3          	beq	s1,s2,800021ec <scheduler+0x4c>
      acquire(&p->lock);
    80002214:	8526                	mv	a0,s1
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	b98080e7          	jalr	-1128(ra) # 80000dae <acquire>
      if (p->state == RUNNABLE)
    8000221e:	4c9c                	lw	a5,24(s1)
    80002220:	ff3791e3          	bne	a5,s3,80002202 <scheduler+0x62>
        p->state = RUNNING;
    80002224:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002228:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000222c:	06048593          	addi	a1,s1,96
    80002230:	8556                	mv	a0,s5
    80002232:	00001097          	auipc	ra,0x1
    80002236:	84e080e7          	jalr	-1970(ra) # 80002a80 <swtch>
        c->proc = 0;
    8000223a:	020a3823          	sd	zero,48(s4)
    8000223e:	b7d1                	j	80002202 <scheduler+0x62>

0000000080002240 <sched>:
{
    80002240:	7179                	addi	sp,sp,-48
    80002242:	f406                	sd	ra,40(sp)
    80002244:	f022                	sd	s0,32(sp)
    80002246:	ec26                	sd	s1,24(sp)
    80002248:	e84a                	sd	s2,16(sp)
    8000224a:	e44e                	sd	s3,8(sp)
    8000224c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	a04080e7          	jalr	-1532(ra) # 80001c52 <myproc>
    80002256:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	adc080e7          	jalr	-1316(ra) # 80000d34 <holding>
    80002260:	c93d                	beqz	a0,800022d6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002262:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002264:	2781                	sext.w	a5,a5
    80002266:	079e                	slli	a5,a5,0x7
    80002268:	0002f717          	auipc	a4,0x2f
    8000226c:	93070713          	addi	a4,a4,-1744 # 80030b98 <pid_lock>
    80002270:	97ba                	add	a5,a5,a4
    80002272:	0a87a703          	lw	a4,168(a5)
    80002276:	4785                	li	a5,1
    80002278:	06f71763          	bne	a4,a5,800022e6 <sched+0xa6>
  if (p->state == RUNNING)
    8000227c:	4c98                	lw	a4,24(s1)
    8000227e:	4791                	li	a5,4
    80002280:	06f70b63          	beq	a4,a5,800022f6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002284:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002288:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000228a:	efb5                	bnez	a5,80002306 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000228c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000228e:	0002f917          	auipc	s2,0x2f
    80002292:	90a90913          	addi	s2,s2,-1782 # 80030b98 <pid_lock>
    80002296:	2781                	sext.w	a5,a5
    80002298:	079e                	slli	a5,a5,0x7
    8000229a:	97ca                	add	a5,a5,s2
    8000229c:	0ac7a983          	lw	s3,172(a5)
    800022a0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022a2:	2781                	sext.w	a5,a5
    800022a4:	079e                	slli	a5,a5,0x7
    800022a6:	0002f597          	auipc	a1,0x2f
    800022aa:	92a58593          	addi	a1,a1,-1750 # 80030bd0 <cpus+0x8>
    800022ae:	95be                	add	a1,a1,a5
    800022b0:	06048513          	addi	a0,s1,96
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	7cc080e7          	jalr	1996(ra) # 80002a80 <swtch>
    800022bc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022be:	2781                	sext.w	a5,a5
    800022c0:	079e                	slli	a5,a5,0x7
    800022c2:	993e                	add	s2,s2,a5
    800022c4:	0b392623          	sw	s3,172(s2)
}
    800022c8:	70a2                	ld	ra,40(sp)
    800022ca:	7402                	ld	s0,32(sp)
    800022cc:	64e2                	ld	s1,24(sp)
    800022ce:	6942                	ld	s2,16(sp)
    800022d0:	69a2                	ld	s3,8(sp)
    800022d2:	6145                	addi	sp,sp,48
    800022d4:	8082                	ret
    panic("sched p->lock");
    800022d6:	00006517          	auipc	a0,0x6
    800022da:	f5250513          	addi	a0,a0,-174 # 80008228 <digits+0x1e8>
    800022de:	ffffe097          	auipc	ra,0xffffe
    800022e2:	262080e7          	jalr	610(ra) # 80000540 <panic>
    panic("sched locks");
    800022e6:	00006517          	auipc	a0,0x6
    800022ea:	f5250513          	addi	a0,a0,-174 # 80008238 <digits+0x1f8>
    800022ee:	ffffe097          	auipc	ra,0xffffe
    800022f2:	252080e7          	jalr	594(ra) # 80000540 <panic>
    panic("sched running");
    800022f6:	00006517          	auipc	a0,0x6
    800022fa:	f5250513          	addi	a0,a0,-174 # 80008248 <digits+0x208>
    800022fe:	ffffe097          	auipc	ra,0xffffe
    80002302:	242080e7          	jalr	578(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002306:	00006517          	auipc	a0,0x6
    8000230a:	f5250513          	addi	a0,a0,-174 # 80008258 <digits+0x218>
    8000230e:	ffffe097          	auipc	ra,0xffffe
    80002312:	232080e7          	jalr	562(ra) # 80000540 <panic>

0000000080002316 <yield>:
{
    80002316:	1101                	addi	sp,sp,-32
    80002318:	ec06                	sd	ra,24(sp)
    8000231a:	e822                	sd	s0,16(sp)
    8000231c:	e426                	sd	s1,8(sp)
    8000231e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002320:	00000097          	auipc	ra,0x0
    80002324:	932080e7          	jalr	-1742(ra) # 80001c52 <myproc>
    80002328:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	a84080e7          	jalr	-1404(ra) # 80000dae <acquire>
  p->state = RUNNABLE;
    80002332:	478d                	li	a5,3
    80002334:	cc9c                	sw	a5,24(s1)
  sched();
    80002336:	00000097          	auipc	ra,0x0
    8000233a:	f0a080e7          	jalr	-246(ra) # 80002240 <sched>
  release(&p->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	b22080e7          	jalr	-1246(ra) # 80000e62 <release>
}
    80002348:	60e2                	ld	ra,24(sp)
    8000234a:	6442                	ld	s0,16(sp)
    8000234c:	64a2                	ld	s1,8(sp)
    8000234e:	6105                	addi	sp,sp,32
    80002350:	8082                	ret

0000000080002352 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002352:	7179                	addi	sp,sp,-48
    80002354:	f406                	sd	ra,40(sp)
    80002356:	f022                	sd	s0,32(sp)
    80002358:	ec26                	sd	s1,24(sp)
    8000235a:	e84a                	sd	s2,16(sp)
    8000235c:	e44e                	sd	s3,8(sp)
    8000235e:	1800                	addi	s0,sp,48
    80002360:	89aa                	mv	s3,a0
    80002362:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002364:	00000097          	auipc	ra,0x0
    80002368:	8ee080e7          	jalr	-1810(ra) # 80001c52 <myproc>
    8000236c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	a40080e7          	jalr	-1472(ra) # 80000dae <acquire>
  release(lk);
    80002376:	854a                	mv	a0,s2
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	aea080e7          	jalr	-1302(ra) # 80000e62 <release>

  // Go to sleep.
  p->chan = chan;
    80002380:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002384:	4789                	li	a5,2
    80002386:	cc9c                	sw	a5,24(s1)

  sched();
    80002388:	00000097          	auipc	ra,0x0
    8000238c:	eb8080e7          	jalr	-328(ra) # 80002240 <sched>

  // Tidy up.
  p->chan = 0;
    80002390:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002394:	8526                	mv	a0,s1
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	acc080e7          	jalr	-1332(ra) # 80000e62 <release>
  acquire(lk);
    8000239e:	854a                	mv	a0,s2
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	a0e080e7          	jalr	-1522(ra) # 80000dae <acquire>
}
    800023a8:	70a2                	ld	ra,40(sp)
    800023aa:	7402                	ld	s0,32(sp)
    800023ac:	64e2                	ld	s1,24(sp)
    800023ae:	6942                	ld	s2,16(sp)
    800023b0:	69a2                	ld	s3,8(sp)
    800023b2:	6145                	addi	sp,sp,48
    800023b4:	8082                	ret

00000000800023b6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800023b6:	7139                	addi	sp,sp,-64
    800023b8:	fc06                	sd	ra,56(sp)
    800023ba:	f822                	sd	s0,48(sp)
    800023bc:	f426                	sd	s1,40(sp)
    800023be:	f04a                	sd	s2,32(sp)
    800023c0:	ec4e                	sd	s3,24(sp)
    800023c2:	e852                	sd	s4,16(sp)
    800023c4:	e456                	sd	s5,8(sp)
    800023c6:	0080                	addi	s0,sp,64
    800023c8:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023ca:	0002f497          	auipc	s1,0x2f
    800023ce:	bfe48493          	addi	s1,s1,-1026 # 80030fc8 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800023d2:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800023d4:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800023d6:	00035917          	auipc	s2,0x35
    800023da:	7f290913          	addi	s2,s2,2034 # 80037bc8 <tickslock>
    800023de:	a811                	j	800023f2 <wakeup+0x3c>
       

      }
      release(&p->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	a80080e7          	jalr	-1408(ra) # 80000e62 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800023ea:	1b048493          	addi	s1,s1,432
    800023ee:	03248663          	beq	s1,s2,8000241a <wakeup+0x64>
    if (p != myproc())
    800023f2:	00000097          	auipc	ra,0x0
    800023f6:	860080e7          	jalr	-1952(ra) # 80001c52 <myproc>
    800023fa:	fea488e3          	beq	s1,a0,800023ea <wakeup+0x34>
      acquire(&p->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	9ae080e7          	jalr	-1618(ra) # 80000dae <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002408:	4c9c                	lw	a5,24(s1)
    8000240a:	fd379be3          	bne	a5,s3,800023e0 <wakeup+0x2a>
    8000240e:	709c                	ld	a5,32(s1)
    80002410:	fd4798e3          	bne	a5,s4,800023e0 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002414:	0154ac23          	sw	s5,24(s1)
    80002418:	b7e1                	j	800023e0 <wakeup+0x2a>
    }
  }
}
    8000241a:	70e2                	ld	ra,56(sp)
    8000241c:	7442                	ld	s0,48(sp)
    8000241e:	74a2                	ld	s1,40(sp)
    80002420:	7902                	ld	s2,32(sp)
    80002422:	69e2                	ld	s3,24(sp)
    80002424:	6a42                	ld	s4,16(sp)
    80002426:	6aa2                	ld	s5,8(sp)
    80002428:	6121                	addi	sp,sp,64
    8000242a:	8082                	ret

000000008000242c <reparent>:
{
    8000242c:	7179                	addi	sp,sp,-48
    8000242e:	f406                	sd	ra,40(sp)
    80002430:	f022                	sd	s0,32(sp)
    80002432:	ec26                	sd	s1,24(sp)
    80002434:	e84a                	sd	s2,16(sp)
    80002436:	e44e                	sd	s3,8(sp)
    80002438:	e052                	sd	s4,0(sp)
    8000243a:	1800                	addi	s0,sp,48
    8000243c:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000243e:	0002f497          	auipc	s1,0x2f
    80002442:	b8a48493          	addi	s1,s1,-1142 # 80030fc8 <proc>
      pp->parent = initproc;
    80002446:	00006a17          	auipc	s4,0x6
    8000244a:	4c2a0a13          	addi	s4,s4,1218 # 80008908 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000244e:	00035997          	auipc	s3,0x35
    80002452:	77a98993          	addi	s3,s3,1914 # 80037bc8 <tickslock>
    80002456:	a029                	j	80002460 <reparent+0x34>
    80002458:	1b048493          	addi	s1,s1,432
    8000245c:	01348d63          	beq	s1,s3,80002476 <reparent+0x4a>
    if (pp->parent == p)
    80002460:	7c9c                	ld	a5,56(s1)
    80002462:	ff279be3          	bne	a5,s2,80002458 <reparent+0x2c>
      pp->parent = initproc;
    80002466:	000a3503          	ld	a0,0(s4)
    8000246a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000246c:	00000097          	auipc	ra,0x0
    80002470:	f4a080e7          	jalr	-182(ra) # 800023b6 <wakeup>
    80002474:	b7d5                	j	80002458 <reparent+0x2c>
}
    80002476:	70a2                	ld	ra,40(sp)
    80002478:	7402                	ld	s0,32(sp)
    8000247a:	64e2                	ld	s1,24(sp)
    8000247c:	6942                	ld	s2,16(sp)
    8000247e:	69a2                	ld	s3,8(sp)
    80002480:	6a02                	ld	s4,0(sp)
    80002482:	6145                	addi	sp,sp,48
    80002484:	8082                	ret

0000000080002486 <exit>:
{
    80002486:	7179                	addi	sp,sp,-48
    80002488:	f406                	sd	ra,40(sp)
    8000248a:	f022                	sd	s0,32(sp)
    8000248c:	ec26                	sd	s1,24(sp)
    8000248e:	e84a                	sd	s2,16(sp)
    80002490:	e44e                	sd	s3,8(sp)
    80002492:	e052                	sd	s4,0(sp)
    80002494:	1800                	addi	s0,sp,48
    80002496:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	7ba080e7          	jalr	1978(ra) # 80001c52 <myproc>
    800024a0:	89aa                	mv	s3,a0
  if (p == initproc)
    800024a2:	00006797          	auipc	a5,0x6
    800024a6:	4667b783          	ld	a5,1126(a5) # 80008908 <initproc>
    800024aa:	0d050493          	addi	s1,a0,208
    800024ae:	15050913          	addi	s2,a0,336
    800024b2:	02a79363          	bne	a5,a0,800024d8 <exit+0x52>
    panic("init exiting");
    800024b6:	00006517          	auipc	a0,0x6
    800024ba:	dba50513          	addi	a0,a0,-582 # 80008270 <digits+0x230>
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	082080e7          	jalr	130(ra) # 80000540 <panic>
      fileclose(f);
    800024c6:	00002097          	auipc	ra,0x2
    800024ca:	726080e7          	jalr	1830(ra) # 80004bec <fileclose>
      p->ofile[fd] = 0;
    800024ce:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800024d2:	04a1                	addi	s1,s1,8
    800024d4:	01248563          	beq	s1,s2,800024de <exit+0x58>
    if (p->ofile[fd])
    800024d8:	6088                	ld	a0,0(s1)
    800024da:	f575                	bnez	a0,800024c6 <exit+0x40>
    800024dc:	bfdd                	j	800024d2 <exit+0x4c>
  begin_op();
    800024de:	00002097          	auipc	ra,0x2
    800024e2:	246080e7          	jalr	582(ra) # 80004724 <begin_op>
  iput(p->cwd);
    800024e6:	1509b503          	ld	a0,336(s3)
    800024ea:	00002097          	auipc	ra,0x2
    800024ee:	a28080e7          	jalr	-1496(ra) # 80003f12 <iput>
  end_op();
    800024f2:	00002097          	auipc	ra,0x2
    800024f6:	2b0080e7          	jalr	688(ra) # 800047a2 <end_op>
  p->cwd = 0;
    800024fa:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024fe:	0002e497          	auipc	s1,0x2e
    80002502:	6b248493          	addi	s1,s1,1714 # 80030bb0 <wait_lock>
    80002506:	8526                	mv	a0,s1
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	8a6080e7          	jalr	-1882(ra) # 80000dae <acquire>
  reparent(p);
    80002510:	854e                	mv	a0,s3
    80002512:	00000097          	auipc	ra,0x0
    80002516:	f1a080e7          	jalr	-230(ra) # 8000242c <reparent>
  wakeup(p->parent);
    8000251a:	0389b503          	ld	a0,56(s3)
    8000251e:	00000097          	auipc	ra,0x0
    80002522:	e98080e7          	jalr	-360(ra) # 800023b6 <wakeup>
  acquire(&p->lock);
    80002526:	854e                	mv	a0,s3
    80002528:	fffff097          	auipc	ra,0xfffff
    8000252c:	886080e7          	jalr	-1914(ra) # 80000dae <acquire>
  p->xstate = status;
    80002530:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002534:	4795                	li	a5,5
    80002536:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000253a:	00006797          	auipc	a5,0x6
    8000253e:	3d67a783          	lw	a5,982(a5) # 80008910 <ticks>
    80002542:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002546:	8526                	mv	a0,s1
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	91a080e7          	jalr	-1766(ra) # 80000e62 <release>
  sched();
    80002550:	00000097          	auipc	ra,0x0
    80002554:	cf0080e7          	jalr	-784(ra) # 80002240 <sched>
  panic("zombie exit");
    80002558:	00006517          	auipc	a0,0x6
    8000255c:	d2850513          	addi	a0,a0,-728 # 80008280 <digits+0x240>
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	fe0080e7          	jalr	-32(ra) # 80000540 <panic>

0000000080002568 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002568:	7179                	addi	sp,sp,-48
    8000256a:	f406                	sd	ra,40(sp)
    8000256c:	f022                	sd	s0,32(sp)
    8000256e:	ec26                	sd	s1,24(sp)
    80002570:	e84a                	sd	s2,16(sp)
    80002572:	e44e                	sd	s3,8(sp)
    80002574:	1800                	addi	s0,sp,48
    80002576:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002578:	0002f497          	auipc	s1,0x2f
    8000257c:	a5048493          	addi	s1,s1,-1456 # 80030fc8 <proc>
    80002580:	00035997          	auipc	s3,0x35
    80002584:	64898993          	addi	s3,s3,1608 # 80037bc8 <tickslock>
  {
    acquire(&p->lock);
    80002588:	8526                	mv	a0,s1
    8000258a:	fffff097          	auipc	ra,0xfffff
    8000258e:	824080e7          	jalr	-2012(ra) # 80000dae <acquire>
    if (p->pid == pid)
    80002592:	589c                	lw	a5,48(s1)
    80002594:	01278d63          	beq	a5,s2,800025ae <kill+0x46>
        
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	fffff097          	auipc	ra,0xfffff
    8000259e:	8c8080e7          	jalr	-1848(ra) # 80000e62 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025a2:	1b048493          	addi	s1,s1,432
    800025a6:	ff3491e3          	bne	s1,s3,80002588 <kill+0x20>
  }
  return -1;
    800025aa:	557d                	li	a0,-1
    800025ac:	a829                	j	800025c6 <kill+0x5e>
      p->killed = 1;
    800025ae:	4785                	li	a5,1
    800025b0:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800025b2:	4c98                	lw	a4,24(s1)
    800025b4:	4789                	li	a5,2
    800025b6:	00f70f63          	beq	a4,a5,800025d4 <kill+0x6c>
      release(&p->lock);
    800025ba:	8526                	mv	a0,s1
    800025bc:	fffff097          	auipc	ra,0xfffff
    800025c0:	8a6080e7          	jalr	-1882(ra) # 80000e62 <release>
      return 0;
    800025c4:	4501                	li	a0,0
}
    800025c6:	70a2                	ld	ra,40(sp)
    800025c8:	7402                	ld	s0,32(sp)
    800025ca:	64e2                	ld	s1,24(sp)
    800025cc:	6942                	ld	s2,16(sp)
    800025ce:	69a2                	ld	s3,8(sp)
    800025d0:	6145                	addi	sp,sp,48
    800025d2:	8082                	ret
        p->state = RUNNABLE;
    800025d4:	478d                	li	a5,3
    800025d6:	cc9c                	sw	a5,24(s1)
    800025d8:	b7cd                	j	800025ba <kill+0x52>

00000000800025da <setkilled>:

void setkilled(struct proc *p)
{
    800025da:	1101                	addi	sp,sp,-32
    800025dc:	ec06                	sd	ra,24(sp)
    800025de:	e822                	sd	s0,16(sp)
    800025e0:	e426                	sd	s1,8(sp)
    800025e2:	1000                	addi	s0,sp,32
    800025e4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	7c8080e7          	jalr	1992(ra) # 80000dae <acquire>
  p->killed = 1;
    800025ee:	4785                	li	a5,1
    800025f0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800025f2:	8526                	mv	a0,s1
    800025f4:	fffff097          	auipc	ra,0xfffff
    800025f8:	86e080e7          	jalr	-1938(ra) # 80000e62 <release>
}
    800025fc:	60e2                	ld	ra,24(sp)
    800025fe:	6442                	ld	s0,16(sp)
    80002600:	64a2                	ld	s1,8(sp)
    80002602:	6105                	addi	sp,sp,32
    80002604:	8082                	ret

0000000080002606 <killed>:

int killed(struct proc *p)
{
    80002606:	1101                	addi	sp,sp,-32
    80002608:	ec06                	sd	ra,24(sp)
    8000260a:	e822                	sd	s0,16(sp)
    8000260c:	e426                	sd	s1,8(sp)
    8000260e:	e04a                	sd	s2,0(sp)
    80002610:	1000                	addi	s0,sp,32
    80002612:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	79a080e7          	jalr	1946(ra) # 80000dae <acquire>
  k = p->killed;
    8000261c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002620:	8526                	mv	a0,s1
    80002622:	fffff097          	auipc	ra,0xfffff
    80002626:	840080e7          	jalr	-1984(ra) # 80000e62 <release>
  return k;
}
    8000262a:	854a                	mv	a0,s2
    8000262c:	60e2                	ld	ra,24(sp)
    8000262e:	6442                	ld	s0,16(sp)
    80002630:	64a2                	ld	s1,8(sp)
    80002632:	6902                	ld	s2,0(sp)
    80002634:	6105                	addi	sp,sp,32
    80002636:	8082                	ret

0000000080002638 <wait>:
{
    80002638:	715d                	addi	sp,sp,-80
    8000263a:	e486                	sd	ra,72(sp)
    8000263c:	e0a2                	sd	s0,64(sp)
    8000263e:	fc26                	sd	s1,56(sp)
    80002640:	f84a                	sd	s2,48(sp)
    80002642:	f44e                	sd	s3,40(sp)
    80002644:	f052                	sd	s4,32(sp)
    80002646:	ec56                	sd	s5,24(sp)
    80002648:	e85a                	sd	s6,16(sp)
    8000264a:	e45e                	sd	s7,8(sp)
    8000264c:	e062                	sd	s8,0(sp)
    8000264e:	0880                	addi	s0,sp,80
    80002650:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002652:	fffff097          	auipc	ra,0xfffff
    80002656:	600080e7          	jalr	1536(ra) # 80001c52 <myproc>
    8000265a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000265c:	0002e517          	auipc	a0,0x2e
    80002660:	55450513          	addi	a0,a0,1364 # 80030bb0 <wait_lock>
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	74a080e7          	jalr	1866(ra) # 80000dae <acquire>
    havekids = 0;
    8000266c:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000266e:	4a15                	li	s4,5
        havekids = 1;
    80002670:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002672:	00035997          	auipc	s3,0x35
    80002676:	55698993          	addi	s3,s3,1366 # 80037bc8 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000267a:	0002ec17          	auipc	s8,0x2e
    8000267e:	536c0c13          	addi	s8,s8,1334 # 80030bb0 <wait_lock>
    havekids = 0;
    80002682:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002684:	0002f497          	auipc	s1,0x2f
    80002688:	94448493          	addi	s1,s1,-1724 # 80030fc8 <proc>
    8000268c:	a0bd                	j	800026fa <wait+0xc2>
          pid = pp->pid;
    8000268e:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002692:	000b0e63          	beqz	s6,800026ae <wait+0x76>
    80002696:	4691                	li	a3,4
    80002698:	02c48613          	addi	a2,s1,44
    8000269c:	85da                	mv	a1,s6
    8000269e:	05093503          	ld	a0,80(s2)
    800026a2:	fffff097          	auipc	ra,0xfffff
    800026a6:	39a080e7          	jalr	922(ra) # 80001a3c <copyout>
    800026aa:	02054563          	bltz	a0,800026d4 <wait+0x9c>
          freeproc(pp);
    800026ae:	8526                	mv	a0,s1
    800026b0:	fffff097          	auipc	ra,0xfffff
    800026b4:	754080e7          	jalr	1876(ra) # 80001e04 <freeproc>
          release(&pp->lock);
    800026b8:	8526                	mv	a0,s1
    800026ba:	ffffe097          	auipc	ra,0xffffe
    800026be:	7a8080e7          	jalr	1960(ra) # 80000e62 <release>
          release(&wait_lock);
    800026c2:	0002e517          	auipc	a0,0x2e
    800026c6:	4ee50513          	addi	a0,a0,1262 # 80030bb0 <wait_lock>
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	798080e7          	jalr	1944(ra) # 80000e62 <release>
          return pid;
    800026d2:	a0b5                	j	8000273e <wait+0x106>
            release(&pp->lock);
    800026d4:	8526                	mv	a0,s1
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	78c080e7          	jalr	1932(ra) # 80000e62 <release>
            release(&wait_lock);
    800026de:	0002e517          	auipc	a0,0x2e
    800026e2:	4d250513          	addi	a0,a0,1234 # 80030bb0 <wait_lock>
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	77c080e7          	jalr	1916(ra) # 80000e62 <release>
            return -1;
    800026ee:	59fd                	li	s3,-1
    800026f0:	a0b9                	j	8000273e <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026f2:	1b048493          	addi	s1,s1,432
    800026f6:	03348463          	beq	s1,s3,8000271e <wait+0xe6>
      if (pp->parent == p)
    800026fa:	7c9c                	ld	a5,56(s1)
    800026fc:	ff279be3          	bne	a5,s2,800026f2 <wait+0xba>
        acquire(&pp->lock);
    80002700:	8526                	mv	a0,s1
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	6ac080e7          	jalr	1708(ra) # 80000dae <acquire>
        if (pp->state == ZOMBIE)
    8000270a:	4c9c                	lw	a5,24(s1)
    8000270c:	f94781e3          	beq	a5,s4,8000268e <wait+0x56>
        release(&pp->lock);
    80002710:	8526                	mv	a0,s1
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	750080e7          	jalr	1872(ra) # 80000e62 <release>
        havekids = 1;
    8000271a:	8756                	mv	a4,s5
    8000271c:	bfd9                	j	800026f2 <wait+0xba>
    if (!havekids || killed(p))
    8000271e:	c719                	beqz	a4,8000272c <wait+0xf4>
    80002720:	854a                	mv	a0,s2
    80002722:	00000097          	auipc	ra,0x0
    80002726:	ee4080e7          	jalr	-284(ra) # 80002606 <killed>
    8000272a:	c51d                	beqz	a0,80002758 <wait+0x120>
      release(&wait_lock);
    8000272c:	0002e517          	auipc	a0,0x2e
    80002730:	48450513          	addi	a0,a0,1156 # 80030bb0 <wait_lock>
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	72e080e7          	jalr	1838(ra) # 80000e62 <release>
      return -1;
    8000273c:	59fd                	li	s3,-1
}
    8000273e:	854e                	mv	a0,s3
    80002740:	60a6                	ld	ra,72(sp)
    80002742:	6406                	ld	s0,64(sp)
    80002744:	74e2                	ld	s1,56(sp)
    80002746:	7942                	ld	s2,48(sp)
    80002748:	79a2                	ld	s3,40(sp)
    8000274a:	7a02                	ld	s4,32(sp)
    8000274c:	6ae2                	ld	s5,24(sp)
    8000274e:	6b42                	ld	s6,16(sp)
    80002750:	6ba2                	ld	s7,8(sp)
    80002752:	6c02                	ld	s8,0(sp)
    80002754:	6161                	addi	sp,sp,80
    80002756:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002758:	85e2                	mv	a1,s8
    8000275a:	854a                	mv	a0,s2
    8000275c:	00000097          	auipc	ra,0x0
    80002760:	bf6080e7          	jalr	-1034(ra) # 80002352 <sleep>
    havekids = 0;
    80002764:	bf39                	j	80002682 <wait+0x4a>

0000000080002766 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002766:	7179                	addi	sp,sp,-48
    80002768:	f406                	sd	ra,40(sp)
    8000276a:	f022                	sd	s0,32(sp)
    8000276c:	ec26                	sd	s1,24(sp)
    8000276e:	e84a                	sd	s2,16(sp)
    80002770:	e44e                	sd	s3,8(sp)
    80002772:	e052                	sd	s4,0(sp)
    80002774:	1800                	addi	s0,sp,48
    80002776:	84aa                	mv	s1,a0
    80002778:	892e                	mv	s2,a1
    8000277a:	89b2                	mv	s3,a2
    8000277c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000277e:	fffff097          	auipc	ra,0xfffff
    80002782:	4d4080e7          	jalr	1236(ra) # 80001c52 <myproc>
  if (user_dst)
    80002786:	c08d                	beqz	s1,800027a8 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002788:	86d2                	mv	a3,s4
    8000278a:	864e                	mv	a2,s3
    8000278c:	85ca                	mv	a1,s2
    8000278e:	6928                	ld	a0,80(a0)
    80002790:	fffff097          	auipc	ra,0xfffff
    80002794:	2ac080e7          	jalr	684(ra) # 80001a3c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002798:	70a2                	ld	ra,40(sp)
    8000279a:	7402                	ld	s0,32(sp)
    8000279c:	64e2                	ld	s1,24(sp)
    8000279e:	6942                	ld	s2,16(sp)
    800027a0:	69a2                	ld	s3,8(sp)
    800027a2:	6a02                	ld	s4,0(sp)
    800027a4:	6145                	addi	sp,sp,48
    800027a6:	8082                	ret
    memmove((char *)dst, src, len);
    800027a8:	000a061b          	sext.w	a2,s4
    800027ac:	85ce                	mv	a1,s3
    800027ae:	854a                	mv	a0,s2
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	756080e7          	jalr	1878(ra) # 80000f06 <memmove>
    return 0;
    800027b8:	8526                	mv	a0,s1
    800027ba:	bff9                	j	80002798 <either_copyout+0x32>

00000000800027bc <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027bc:	7179                	addi	sp,sp,-48
    800027be:	f406                	sd	ra,40(sp)
    800027c0:	f022                	sd	s0,32(sp)
    800027c2:	ec26                	sd	s1,24(sp)
    800027c4:	e84a                	sd	s2,16(sp)
    800027c6:	e44e                	sd	s3,8(sp)
    800027c8:	e052                	sd	s4,0(sp)
    800027ca:	1800                	addi	s0,sp,48
    800027cc:	892a                	mv	s2,a0
    800027ce:	84ae                	mv	s1,a1
    800027d0:	89b2                	mv	s3,a2
    800027d2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027d4:	fffff097          	auipc	ra,0xfffff
    800027d8:	47e080e7          	jalr	1150(ra) # 80001c52 <myproc>
  if (user_src)
    800027dc:	c08d                	beqz	s1,800027fe <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800027de:	86d2                	mv	a3,s4
    800027e0:	864e                	mv	a2,s3
    800027e2:	85ca                	mv	a1,s2
    800027e4:	6928                	ld	a0,80(a0)
    800027e6:	fffff097          	auipc	ra,0xfffff
    800027ea:	05c080e7          	jalr	92(ra) # 80001842 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800027ee:	70a2                	ld	ra,40(sp)
    800027f0:	7402                	ld	s0,32(sp)
    800027f2:	64e2                	ld	s1,24(sp)
    800027f4:	6942                	ld	s2,16(sp)
    800027f6:	69a2                	ld	s3,8(sp)
    800027f8:	6a02                	ld	s4,0(sp)
    800027fa:	6145                	addi	sp,sp,48
    800027fc:	8082                	ret
    memmove(dst, (char *)src, len);
    800027fe:	000a061b          	sext.w	a2,s4
    80002802:	85ce                	mv	a1,s3
    80002804:	854a                	mv	a0,s2
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	700080e7          	jalr	1792(ra) # 80000f06 <memmove>
    return 0;
    8000280e:	8526                	mv	a0,s1
    80002810:	bff9                	j	800027ee <either_copyin+0x32>

0000000080002812 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002812:	715d                	addi	sp,sp,-80
    80002814:	e486                	sd	ra,72(sp)
    80002816:	e0a2                	sd	s0,64(sp)
    80002818:	fc26                	sd	s1,56(sp)
    8000281a:	f84a                	sd	s2,48(sp)
    8000281c:	f44e                	sd	s3,40(sp)
    8000281e:	f052                	sd	s4,32(sp)
    80002820:	ec56                	sd	s5,24(sp)
    80002822:	e85a                	sd	s6,16(sp)
    80002824:	e45e                	sd	s7,8(sp)
    80002826:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002828:	00006517          	auipc	a0,0x6
    8000282c:	8b050513          	addi	a0,a0,-1872 # 800080d8 <digits+0x98>
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	d5a080e7          	jalr	-678(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002838:	0002f497          	auipc	s1,0x2f
    8000283c:	8e848493          	addi	s1,s1,-1816 # 80031120 <proc+0x158>
    80002840:	00035917          	auipc	s2,0x35
    80002844:	4e090913          	addi	s2,s2,1248 # 80037d20 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002848:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000284a:	00006997          	auipc	s3,0x6
    8000284e:	a4698993          	addi	s3,s3,-1466 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    80002852:	00006a97          	auipc	s5,0x6
    80002856:	a46a8a93          	addi	s5,s5,-1466 # 80008298 <digits+0x258>
    printf("\n");
    8000285a:	00006a17          	auipc	s4,0x6
    8000285e:	87ea0a13          	addi	s4,s4,-1922 # 800080d8 <digits+0x98>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002862:	00006b97          	auipc	s7,0x6
    80002866:	a76b8b93          	addi	s7,s7,-1418 # 800082d8 <states.0>
    8000286a:	a00d                	j	8000288c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000286c:	ed86a583          	lw	a1,-296(a3)
    80002870:	8556                	mv	a0,s5
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	d18080e7          	jalr	-744(ra) # 8000058a <printf>
    printf("\n");
    8000287a:	8552                	mv	a0,s4
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	d0e080e7          	jalr	-754(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002884:	1b048493          	addi	s1,s1,432
    80002888:	03248263          	beq	s1,s2,800028ac <procdump+0x9a>
    if (p->state == UNUSED)
    8000288c:	86a6                	mv	a3,s1
    8000288e:	ec04a783          	lw	a5,-320(s1)
    80002892:	dbed                	beqz	a5,80002884 <procdump+0x72>
      state = "???";
    80002894:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002896:	fcfb6be3          	bltu	s6,a5,8000286c <procdump+0x5a>
    8000289a:	02079713          	slli	a4,a5,0x20
    8000289e:	01d75793          	srli	a5,a4,0x1d
    800028a2:	97de                	add	a5,a5,s7
    800028a4:	6390                	ld	a2,0(a5)
    800028a6:	f279                	bnez	a2,8000286c <procdump+0x5a>
      state = "???";
    800028a8:	864e                	mv	a2,s3
    800028aa:	b7c9                	j	8000286c <procdump+0x5a>
  }
}
    800028ac:	60a6                	ld	ra,72(sp)
    800028ae:	6406                	ld	s0,64(sp)
    800028b0:	74e2                	ld	s1,56(sp)
    800028b2:	7942                	ld	s2,48(sp)
    800028b4:	79a2                	ld	s3,40(sp)
    800028b6:	7a02                	ld	s4,32(sp)
    800028b8:	6ae2                	ld	s5,24(sp)
    800028ba:	6b42                	ld	s6,16(sp)
    800028bc:	6ba2                	ld	s7,8(sp)
    800028be:	6161                	addi	sp,sp,80
    800028c0:	8082                	ret

00000000800028c2 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800028c2:	711d                	addi	sp,sp,-96
    800028c4:	ec86                	sd	ra,88(sp)
    800028c6:	e8a2                	sd	s0,80(sp)
    800028c8:	e4a6                	sd	s1,72(sp)
    800028ca:	e0ca                	sd	s2,64(sp)
    800028cc:	fc4e                	sd	s3,56(sp)
    800028ce:	f852                	sd	s4,48(sp)
    800028d0:	f456                	sd	s5,40(sp)
    800028d2:	f05a                	sd	s6,32(sp)
    800028d4:	ec5e                	sd	s7,24(sp)
    800028d6:	e862                	sd	s8,16(sp)
    800028d8:	e466                	sd	s9,8(sp)
    800028da:	e06a                	sd	s10,0(sp)
    800028dc:	1080                	addi	s0,sp,96
    800028de:	8b2a                	mv	s6,a0
    800028e0:	8bae                	mv	s7,a1
    800028e2:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800028e4:	fffff097          	auipc	ra,0xfffff
    800028e8:	36e080e7          	jalr	878(ra) # 80001c52 <myproc>
    800028ec:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800028ee:	0002e517          	auipc	a0,0x2e
    800028f2:	2c250513          	addi	a0,a0,706 # 80030bb0 <wait_lock>
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	4b8080e7          	jalr	1208(ra) # 80000dae <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800028fe:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002900:	4a15                	li	s4,5
        havekids = 1;
    80002902:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002904:	00035997          	auipc	s3,0x35
    80002908:	2c498993          	addi	s3,s3,708 # 80037bc8 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000290c:	0002ed17          	auipc	s10,0x2e
    80002910:	2a4d0d13          	addi	s10,s10,676 # 80030bb0 <wait_lock>
    havekids = 0;
    80002914:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002916:	0002e497          	auipc	s1,0x2e
    8000291a:	6b248493          	addi	s1,s1,1714 # 80030fc8 <proc>
    8000291e:	a059                	j	800029a4 <waitx+0xe2>
          pid = np->pid;
    80002920:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002924:	1684a783          	lw	a5,360(s1)
    80002928:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000292c:	16c4a703          	lw	a4,364(s1)
    80002930:	9f3d                	addw	a4,a4,a5
    80002932:	1704a783          	lw	a5,368(s1)
    80002936:	9f99                	subw	a5,a5,a4
    80002938:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000293c:	000b0e63          	beqz	s6,80002958 <waitx+0x96>
    80002940:	4691                	li	a3,4
    80002942:	02c48613          	addi	a2,s1,44
    80002946:	85da                	mv	a1,s6
    80002948:	05093503          	ld	a0,80(s2)
    8000294c:	fffff097          	auipc	ra,0xfffff
    80002950:	0f0080e7          	jalr	240(ra) # 80001a3c <copyout>
    80002954:	02054563          	bltz	a0,8000297e <waitx+0xbc>
          freeproc(np);
    80002958:	8526                	mv	a0,s1
    8000295a:	fffff097          	auipc	ra,0xfffff
    8000295e:	4aa080e7          	jalr	1194(ra) # 80001e04 <freeproc>
          release(&np->lock);
    80002962:	8526                	mv	a0,s1
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	4fe080e7          	jalr	1278(ra) # 80000e62 <release>
          release(&wait_lock);
    8000296c:	0002e517          	auipc	a0,0x2e
    80002970:	24450513          	addi	a0,a0,580 # 80030bb0 <wait_lock>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	4ee080e7          	jalr	1262(ra) # 80000e62 <release>
          return pid;
    8000297c:	a09d                	j	800029e2 <waitx+0x120>
            release(&np->lock);
    8000297e:	8526                	mv	a0,s1
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	4e2080e7          	jalr	1250(ra) # 80000e62 <release>
            release(&wait_lock);
    80002988:	0002e517          	auipc	a0,0x2e
    8000298c:	22850513          	addi	a0,a0,552 # 80030bb0 <wait_lock>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	4d2080e7          	jalr	1234(ra) # 80000e62 <release>
            return -1;
    80002998:	59fd                	li	s3,-1
    8000299a:	a0a1                	j	800029e2 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    8000299c:	1b048493          	addi	s1,s1,432
    800029a0:	03348463          	beq	s1,s3,800029c8 <waitx+0x106>
      if (np->parent == p)
    800029a4:	7c9c                	ld	a5,56(s1)
    800029a6:	ff279be3          	bne	a5,s2,8000299c <waitx+0xda>
        acquire(&np->lock);
    800029aa:	8526                	mv	a0,s1
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	402080e7          	jalr	1026(ra) # 80000dae <acquire>
        if (np->state == ZOMBIE)
    800029b4:	4c9c                	lw	a5,24(s1)
    800029b6:	f74785e3          	beq	a5,s4,80002920 <waitx+0x5e>
        release(&np->lock);
    800029ba:	8526                	mv	a0,s1
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	4a6080e7          	jalr	1190(ra) # 80000e62 <release>
        havekids = 1;
    800029c4:	8756                	mv	a4,s5
    800029c6:	bfd9                	j	8000299c <waitx+0xda>
    if (!havekids || p->killed)
    800029c8:	c701                	beqz	a4,800029d0 <waitx+0x10e>
    800029ca:	02892783          	lw	a5,40(s2)
    800029ce:	cb8d                	beqz	a5,80002a00 <waitx+0x13e>
      release(&wait_lock);
    800029d0:	0002e517          	auipc	a0,0x2e
    800029d4:	1e050513          	addi	a0,a0,480 # 80030bb0 <wait_lock>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	48a080e7          	jalr	1162(ra) # 80000e62 <release>
      return -1;
    800029e0:	59fd                	li	s3,-1
  }
}
    800029e2:	854e                	mv	a0,s3
    800029e4:	60e6                	ld	ra,88(sp)
    800029e6:	6446                	ld	s0,80(sp)
    800029e8:	64a6                	ld	s1,72(sp)
    800029ea:	6906                	ld	s2,64(sp)
    800029ec:	79e2                	ld	s3,56(sp)
    800029ee:	7a42                	ld	s4,48(sp)
    800029f0:	7aa2                	ld	s5,40(sp)
    800029f2:	7b02                	ld	s6,32(sp)
    800029f4:	6be2                	ld	s7,24(sp)
    800029f6:	6c42                	ld	s8,16(sp)
    800029f8:	6ca2                	ld	s9,8(sp)
    800029fa:	6d02                	ld	s10,0(sp)
    800029fc:	6125                	addi	sp,sp,96
    800029fe:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a00:	85ea                	mv	a1,s10
    80002a02:	854a                	mv	a0,s2
    80002a04:	00000097          	auipc	ra,0x0
    80002a08:	94e080e7          	jalr	-1714(ra) # 80002352 <sleep>
    havekids = 0;
    80002a0c:	b721                	j	80002914 <waitx+0x52>

0000000080002a0e <update_time>:

void update_time()
{
    80002a0e:	7179                	addi	sp,sp,-48
    80002a10:	f406                	sd	ra,40(sp)
    80002a12:	f022                	sd	s0,32(sp)
    80002a14:	ec26                	sd	s1,24(sp)
    80002a16:	e84a                	sd	s2,16(sp)
    80002a18:	e44e                	sd	s3,8(sp)
    80002a1a:	e052                	sd	s4,0(sp)
    80002a1c:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002a1e:	0002e497          	auipc	s1,0x2e
    80002a22:	5aa48493          	addi	s1,s1,1450 # 80030fc8 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002a26:	4991                	li	s3,4
    {
      p->rtime++;
      // p->ticks_used++;
    }
    else if(p->state==RUNNABLE){
    80002a28:	4a0d                	li	s4,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002a2a:	00035917          	auipc	s2,0x35
    80002a2e:	19e90913          	addi	s2,s2,414 # 80037bc8 <tickslock>
    80002a32:	a839                	j	80002a50 <update_time+0x42>
      p->rtime++;
    80002a34:	1684a783          	lw	a5,360(s1)
    80002a38:	2785                	addiw	a5,a5,1
    80002a3a:	16f4a423          	sw	a5,360(s1)
      p->waittime++;
    }
    release(&p->lock);
    80002a3e:	8526                	mv	a0,s1
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	422080e7          	jalr	1058(ra) # 80000e62 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a48:	1b048493          	addi	s1,s1,432
    80002a4c:	03248263          	beq	s1,s2,80002a70 <update_time+0x62>
    acquire(&p->lock);
    80002a50:	8526                	mv	a0,s1
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	35c080e7          	jalr	860(ra) # 80000dae <acquire>
    if (p->state == RUNNING)
    80002a5a:	4c9c                	lw	a5,24(s1)
    80002a5c:	fd378ce3          	beq	a5,s3,80002a34 <update_time+0x26>
    else if(p->state==RUNNABLE){
    80002a60:	fd479fe3          	bne	a5,s4,80002a3e <update_time+0x30>
      p->waittime++;
    80002a64:	1a84a783          	lw	a5,424(s1)
    80002a68:	2785                	addiw	a5,a5,1
    80002a6a:	1af4a423          	sw	a5,424(s1)
    80002a6e:	bfc1                	j	80002a3e <update_time+0x30>
		}
	}
#endif


    80002a70:	70a2                	ld	ra,40(sp)
    80002a72:	7402                	ld	s0,32(sp)
    80002a74:	64e2                	ld	s1,24(sp)
    80002a76:	6942                	ld	s2,16(sp)
    80002a78:	69a2                	ld	s3,8(sp)
    80002a7a:	6a02                	ld	s4,0(sp)
    80002a7c:	6145                	addi	sp,sp,48
    80002a7e:	8082                	ret

0000000080002a80 <swtch>:
    80002a80:	00153023          	sd	ra,0(a0)
    80002a84:	00253423          	sd	sp,8(a0)
    80002a88:	e900                	sd	s0,16(a0)
    80002a8a:	ed04                	sd	s1,24(a0)
    80002a8c:	03253023          	sd	s2,32(a0)
    80002a90:	03353423          	sd	s3,40(a0)
    80002a94:	03453823          	sd	s4,48(a0)
    80002a98:	03553c23          	sd	s5,56(a0)
    80002a9c:	05653023          	sd	s6,64(a0)
    80002aa0:	05753423          	sd	s7,72(a0)
    80002aa4:	05853823          	sd	s8,80(a0)
    80002aa8:	05953c23          	sd	s9,88(a0)
    80002aac:	07a53023          	sd	s10,96(a0)
    80002ab0:	07b53423          	sd	s11,104(a0)
    80002ab4:	0005b083          	ld	ra,0(a1)
    80002ab8:	0085b103          	ld	sp,8(a1)
    80002abc:	6980                	ld	s0,16(a1)
    80002abe:	6d84                	ld	s1,24(a1)
    80002ac0:	0205b903          	ld	s2,32(a1)
    80002ac4:	0285b983          	ld	s3,40(a1)
    80002ac8:	0305ba03          	ld	s4,48(a1)
    80002acc:	0385ba83          	ld	s5,56(a1)
    80002ad0:	0405bb03          	ld	s6,64(a1)
    80002ad4:	0485bb83          	ld	s7,72(a1)
    80002ad8:	0505bc03          	ld	s8,80(a1)
    80002adc:	0585bc83          	ld	s9,88(a1)
    80002ae0:	0605bd03          	ld	s10,96(a1)
    80002ae4:	0685bd83          	ld	s11,104(a1)
    80002ae8:	8082                	ret

0000000080002aea <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002aea:	1141                	addi	sp,sp,-16
    80002aec:	e406                	sd	ra,8(sp)
    80002aee:	e022                	sd	s0,0(sp)
    80002af0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002af2:	00006597          	auipc	a1,0x6
    80002af6:	81658593          	addi	a1,a1,-2026 # 80008308 <states.0+0x30>
    80002afa:	00035517          	auipc	a0,0x35
    80002afe:	0ce50513          	addi	a0,a0,206 # 80037bc8 <tickslock>
    80002b02:	ffffe097          	auipc	ra,0xffffe
    80002b06:	21c080e7          	jalr	540(ra) # 80000d1e <initlock>
}
    80002b0a:	60a2                	ld	ra,8(sp)
    80002b0c:	6402                	ld	s0,0(sp)
    80002b0e:	0141                	addi	sp,sp,16
    80002b10:	8082                	ret

0000000080002b12 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002b12:	1141                	addi	sp,sp,-16
    80002b14:	e422                	sd	s0,8(sp)
    80002b16:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b18:	00003797          	auipc	a5,0x3
    80002b1c:	72878793          	addi	a5,a5,1832 # 80006240 <kernelvec>
    80002b20:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b24:	6422                	ld	s0,8(sp)
    80002b26:	0141                	addi	sp,sp,16
    80002b28:	8082                	ret

0000000080002b2a <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002b2a:	1141                	addi	sp,sp,-16
    80002b2c:	e406                	sd	ra,8(sp)
    80002b2e:	e022                	sd	s0,0(sp)
    80002b30:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b32:	fffff097          	auipc	ra,0xfffff
    80002b36:	120080e7          	jalr	288(ra) # 80001c52 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b3e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b40:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b44:	00004697          	auipc	a3,0x4
    80002b48:	4bc68693          	addi	a3,a3,1212 # 80007000 <_trampoline>
    80002b4c:	00004717          	auipc	a4,0x4
    80002b50:	4b470713          	addi	a4,a4,1204 # 80007000 <_trampoline>
    80002b54:	8f15                	sub	a4,a4,a3
    80002b56:	040007b7          	lui	a5,0x4000
    80002b5a:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002b5c:	07b2                	slli	a5,a5,0xc
    80002b5e:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b60:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b64:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b66:	18002673          	csrr	a2,satp
    80002b6a:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b6c:	6d30                	ld	a2,88(a0)
    80002b6e:	6138                	ld	a4,64(a0)
    80002b70:	6585                	lui	a1,0x1
    80002b72:	972e                	add	a4,a4,a1
    80002b74:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b76:	6d38                	ld	a4,88(a0)
    80002b78:	00000617          	auipc	a2,0x0
    80002b7c:	13e60613          	addi	a2,a2,318 # 80002cb6 <usertrap>
    80002b80:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002b82:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b84:	8612                	mv	a2,tp
    80002b86:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b88:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b8c:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b90:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b94:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b98:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b9a:	6f18                	ld	a4,24(a4)
    80002b9c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ba0:	6928                	ld	a0,80(a0)
    80002ba2:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002ba4:	00004717          	auipc	a4,0x4
    80002ba8:	4f870713          	addi	a4,a4,1272 # 8000709c <userret>
    80002bac:	8f15                	sub	a4,a4,a3
    80002bae:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002bb0:	577d                	li	a4,-1
    80002bb2:	177e                	slli	a4,a4,0x3f
    80002bb4:	8d59                	or	a0,a0,a4
    80002bb6:	9782                	jalr	a5
}
    80002bb8:	60a2                	ld	ra,8(sp)
    80002bba:	6402                	ld	s0,0(sp)
    80002bbc:	0141                	addi	sp,sp,16
    80002bbe:	8082                	ret

0000000080002bc0 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002bc0:	1101                	addi	sp,sp,-32
    80002bc2:	ec06                	sd	ra,24(sp)
    80002bc4:	e822                	sd	s0,16(sp)
    80002bc6:	e426                	sd	s1,8(sp)
    80002bc8:	e04a                	sd	s2,0(sp)
    80002bca:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002bcc:	00035917          	auipc	s2,0x35
    80002bd0:	ffc90913          	addi	s2,s2,-4 # 80037bc8 <tickslock>
    80002bd4:	854a                	mv	a0,s2
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	1d8080e7          	jalr	472(ra) # 80000dae <acquire>
  ticks++;
    80002bde:	00006497          	auipc	s1,0x6
    80002be2:	d3248493          	addi	s1,s1,-718 # 80008910 <ticks>
    80002be6:	409c                	lw	a5,0(s1)
    80002be8:	2785                	addiw	a5,a5,1
    80002bea:	c09c                	sw	a5,0(s1)
  update_time();
    80002bec:	00000097          	auipc	ra,0x0
    80002bf0:	e22080e7          	jalr	-478(ra) # 80002a0e <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002bf4:	8526                	mv	a0,s1
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	7c0080e7          	jalr	1984(ra) # 800023b6 <wakeup>
  release(&tickslock);
    80002bfe:	854a                	mv	a0,s2
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	262080e7          	jalr	610(ra) # 80000e62 <release>
}
    80002c08:	60e2                	ld	ra,24(sp)
    80002c0a:	6442                	ld	s0,16(sp)
    80002c0c:	64a2                	ld	s1,8(sp)
    80002c0e:	6902                	ld	s2,0(sp)
    80002c10:	6105                	addi	sp,sp,32
    80002c12:	8082                	ret

0000000080002c14 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002c14:	1101                	addi	sp,sp,-32
    80002c16:	ec06                	sd	ra,24(sp)
    80002c18:	e822                	sd	s0,16(sp)
    80002c1a:	e426                	sd	s1,8(sp)
    80002c1c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c1e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002c22:	00074d63          	bltz	a4,80002c3c <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002c26:	57fd                	li	a5,-1
    80002c28:	17fe                	slli	a5,a5,0x3f
    80002c2a:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002c2c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002c2e:	06f70363          	beq	a4,a5,80002c94 <devintr+0x80>
  }
}
    80002c32:	60e2                	ld	ra,24(sp)
    80002c34:	6442                	ld	s0,16(sp)
    80002c36:	64a2                	ld	s1,8(sp)
    80002c38:	6105                	addi	sp,sp,32
    80002c3a:	8082                	ret
      (scause & 0xff) == 9)
    80002c3c:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002c40:	46a5                	li	a3,9
    80002c42:	fed792e3          	bne	a5,a3,80002c26 <devintr+0x12>
    int irq = plic_claim();
    80002c46:	00003097          	auipc	ra,0x3
    80002c4a:	702080e7          	jalr	1794(ra) # 80006348 <plic_claim>
    80002c4e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002c50:	47a9                	li	a5,10
    80002c52:	02f50763          	beq	a0,a5,80002c80 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002c56:	4785                	li	a5,1
    80002c58:	02f50963          	beq	a0,a5,80002c8a <devintr+0x76>
    return 1;
    80002c5c:	4505                	li	a0,1
    else if (irq)
    80002c5e:	d8f1                	beqz	s1,80002c32 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c60:	85a6                	mv	a1,s1
    80002c62:	00005517          	auipc	a0,0x5
    80002c66:	6ae50513          	addi	a0,a0,1710 # 80008310 <states.0+0x38>
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	920080e7          	jalr	-1760(ra) # 8000058a <printf>
      plic_complete(irq);
    80002c72:	8526                	mv	a0,s1
    80002c74:	00003097          	auipc	ra,0x3
    80002c78:	6f8080e7          	jalr	1784(ra) # 8000636c <plic_complete>
    return 1;
    80002c7c:	4505                	li	a0,1
    80002c7e:	bf55                	j	80002c32 <devintr+0x1e>
      uartintr();
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	d18080e7          	jalr	-744(ra) # 80000998 <uartintr>
    80002c88:	b7ed                	j	80002c72 <devintr+0x5e>
      virtio_disk_intr();
    80002c8a:	00004097          	auipc	ra,0x4
    80002c8e:	baa080e7          	jalr	-1110(ra) # 80006834 <virtio_disk_intr>
    80002c92:	b7c5                	j	80002c72 <devintr+0x5e>
    if (cpuid() == 0)
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	f92080e7          	jalr	-110(ra) # 80001c26 <cpuid>
    80002c9c:	c901                	beqz	a0,80002cac <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c9e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ca2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ca4:	14479073          	csrw	sip,a5
    return 2;
    80002ca8:	4509                	li	a0,2
    80002caa:	b761                	j	80002c32 <devintr+0x1e>
      clockintr();
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	f14080e7          	jalr	-236(ra) # 80002bc0 <clockintr>
    80002cb4:	b7ed                	j	80002c9e <devintr+0x8a>

0000000080002cb6 <usertrap>:
{
    80002cb6:	1101                	addi	sp,sp,-32
    80002cb8:	ec06                	sd	ra,24(sp)
    80002cba:	e822                	sd	s0,16(sp)
    80002cbc:	e426                	sd	s1,8(sp)
    80002cbe:	e04a                	sd	s2,0(sp)
    80002cc0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc2:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002cc6:	1007f793          	andi	a5,a5,256
    80002cca:	eba1                	bnez	a5,80002d1a <usertrap+0x64>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ccc:	00003797          	auipc	a5,0x3
    80002cd0:	57478793          	addi	a5,a5,1396 # 80006240 <kernelvec>
    80002cd4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	f7a080e7          	jalr	-134(ra) # 80001c52 <myproc>
    80002ce0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ce2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ce4:	14102773          	csrr	a4,sepc
    80002ce8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cea:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002cee:	47a1                	li	a5,8
    80002cf0:	02f70d63          	beq	a4,a5,80002d2a <usertrap+0x74>
    80002cf4:	14202773          	csrr	a4,scause
  else if(r_scause() == 15) {
    80002cf8:	47bd                	li	a5,15
    80002cfa:	0af71e63          	bne	a4,a5,80002db6 <usertrap+0x100>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cfe:	143027f3          	csrr	a5,stval
    if(va==0)p->killed=1;
    80002d02:	efb9                	bnez	a5,80002d60 <usertrap+0xaa>
    80002d04:	4705                	li	a4,1
    80002d06:	d518                	sw	a4,40(a0)
    uint64 val = PGROUNDDOWN(p->trapframe->sp);
    80002d08:	6d38                	ld	a4,88(a0)
    80002d0a:	7b14                	ld	a3,48(a4)
    80002d0c:	777d                	lui	a4,0xfffff
    80002d0e:	8f75                	and	a4,a4,a3
    if ((uint64)va >= MAXVA || ((uint64)va <= val && (uint64)va >= val - PGSIZE))
    80002d10:	76fd                	lui	a3,0xfffff
    80002d12:	9736                	add	a4,a4,a3
    80002d14:	04e7ee63          	bltu	a5,a4,80002d70 <usertrap+0xba>
    80002d18:	a891                	j	80002d6c <usertrap+0xb6>
    panic("usertrap: not from user mode");
    80002d1a:	00005517          	auipc	a0,0x5
    80002d1e:	61650513          	addi	a0,a0,1558 # 80008330 <states.0+0x58>
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	81e080e7          	jalr	-2018(ra) # 80000540 <panic>
    if (killed(p))
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	8dc080e7          	jalr	-1828(ra) # 80002606 <killed>
    80002d32:	e10d                	bnez	a0,80002d54 <usertrap+0x9e>
    p->trapframe->epc += 4;
    80002d34:	6cb8                	ld	a4,88(s1)
    80002d36:	6f1c                	ld	a5,24(a4)
    80002d38:	0791                	addi	a5,a5,4
    80002d3a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d3c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d40:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d44:	10079073          	csrw	sstatus,a5
    syscall();
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	396080e7          	jalr	918(ra) # 800030de <syscall>
  int which_dev = 0;
    80002d50:	4901                	li	s2,0
    80002d52:	a815                	j	80002d86 <usertrap+0xd0>
      exit(-1);
    80002d54:	557d                	li	a0,-1
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	730080e7          	jalr	1840(ra) # 80002486 <exit>
    80002d5e:	bfd9                	j	80002d34 <usertrap+0x7e>
    uint64 val = PGROUNDDOWN(p->trapframe->sp);
    80002d60:	6d38                	ld	a4,88(a0)
    80002d62:	7b18                	ld	a4,48(a4)
    if ((uint64)va >= MAXVA || ((uint64)va <= val && (uint64)va >= val - PGSIZE))
    80002d64:	56fd                	li	a3,-1
    80002d66:	82e9                	srli	a3,a3,0x1a
    80002d68:	02f6ff63          	bgeu	a3,a5,80002da6 <usertrap+0xf0>
    p->killed=1;
    80002d6c:	4705                	li	a4,1
    80002d6e:	d498                	sw	a4,40(s1)
    int x=COW(p->pagetable,PGROUNDDOWN(va));
    80002d70:	75fd                	lui	a1,0xfffff
    80002d72:	8dfd                	and	a1,a1,a5
    80002d74:	68a8                	ld	a0,80(s1)
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	c0a080e7          	jalr	-1014(ra) # 80001980 <COW>
    if(x==-1)p->killed=1;
    80002d7e:	57fd                	li	a5,-1
  int which_dev = 0;
    80002d80:	4901                	li	s2,0
    if(x==-1)p->killed=1;
    80002d82:	02f50763          	beq	a0,a5,80002db0 <usertrap+0xfa>
  if (killed(p))
    80002d86:	8526                	mv	a0,s1
    80002d88:	00000097          	auipc	ra,0x0
    80002d8c:	87e080e7          	jalr	-1922(ra) # 80002606 <killed>
    80002d90:	e56d                	bnez	a0,80002e7a <usertrap+0x1c4>
  usertrapret();
    80002d92:	00000097          	auipc	ra,0x0
    80002d96:	d98080e7          	jalr	-616(ra) # 80002b2a <usertrapret>
}
    80002d9a:	60e2                	ld	ra,24(sp)
    80002d9c:	6442                	ld	s0,16(sp)
    80002d9e:	64a2                	ld	s1,8(sp)
    80002da0:	6902                	ld	s2,0(sp)
    80002da2:	6105                	addi	sp,sp,32
    80002da4:	8082                	ret
    uint64 val = PGROUNDDOWN(p->trapframe->sp);
    80002da6:	76fd                	lui	a3,0xfffff
    80002da8:	8f75                	and	a4,a4,a3
    if ((uint64)va >= MAXVA || ((uint64)va <= val && (uint64)va >= val - PGSIZE))
    80002daa:	fcf763e3          	bltu	a4,a5,80002d70 <usertrap+0xba>
    80002dae:	b78d                	j	80002d10 <usertrap+0x5a>
    if(x==-1)p->killed=1;
    80002db0:	4785                	li	a5,1
    80002db2:	d49c                	sw	a5,40(s1)
    80002db4:	bfc9                	j	80002d86 <usertrap+0xd0>
  else if ((which_dev = devintr()) != 0)
    80002db6:	00000097          	auipc	ra,0x0
    80002dba:	e5e080e7          	jalr	-418(ra) # 80002c14 <devintr>
    80002dbe:	892a                	mv	s2,a0
    80002dc0:	c141                	beqz	a0,80002e40 <usertrap+0x18a>
    if(which_dev == 2 && p->alarm_state==1){
    80002dc2:	4789                	li	a5,2
    80002dc4:	fcf511e3          	bne	a0,a5,80002d86 <usertrap+0xd0>
    80002dc8:	17c4a703          	lw	a4,380(s1)
    80002dcc:	4785                	li	a5,1
    80002dce:	00f70e63          	beq	a4,a5,80002dea <usertrap+0x134>
  if (killed(p))
    80002dd2:	8526                	mv	a0,s1
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	832080e7          	jalr	-1998(ra) # 80002606 <killed>
    80002ddc:	c55d                	beqz	a0,80002e8a <usertrap+0x1d4>
    exit(-1);
    80002dde:	557d                	li	a0,-1
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	6a6080e7          	jalr	1702(ra) # 80002486 <exit>
  if (which_dev == 2){
    80002de8:	a04d                	j	80002e8a <usertrap+0x1d4>
      p->currentticks++;
    80002dea:	1944a783          	lw	a5,404(s1)
    80002dee:	2785                	addiw	a5,a5,1
    80002df0:	18f4aa23          	sw	a5,404(s1)
    if(myproc()->alarm_state==1){
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	e5e080e7          	jalr	-418(ra) # 80001c52 <myproc>
    80002dfc:	17c52703          	lw	a4,380(a0)
    80002e00:	4785                	li	a5,1
    80002e02:	fcf718e3          	bne	a4,a5,80002dd2 <usertrap+0x11c>
      struct trapframe* tf=kalloc();
    80002e06:	ffffe097          	auipc	ra,0xffffe
    80002e0a:	be2080e7          	jalr	-1054(ra) # 800009e8 <kalloc>
    80002e0e:	892a                	mv	s2,a0
      memmove(tf,myproc()->trapframe,PGSIZE);
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	e42080e7          	jalr	-446(ra) # 80001c52 <myproc>
    80002e18:	6605                	lui	a2,0x1
    80002e1a:	6d2c                	ld	a1,88(a0)
    80002e1c:	854a                	mv	a0,s2
    80002e1e:	ffffe097          	auipc	ra,0xffffe
    80002e22:	0e8080e7          	jalr	232(ra) # 80000f06 <memmove>
      p->alarm_frame=tf;
    80002e26:	1924b423          	sd	s2,392(s1)
      if(p->currentticks>=p->clockticks){
    80002e2a:	1944a703          	lw	a4,404(s1)
    80002e2e:	1784a783          	lw	a5,376(s1)
    80002e32:	faf740e3          	blt	a4,a5,80002dd2 <usertrap+0x11c>
        p->trapframe->epc=p->handler;
    80002e36:	6cbc                	ld	a5,88(s1)
    80002e38:	1804b703          	ld	a4,384(s1)
    80002e3c:	ef98                	sd	a4,24(a5)
    80002e3e:	bf51                	j	80002dd2 <usertrap+0x11c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e40:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e44:	5890                	lw	a2,48(s1)
    80002e46:	00005517          	auipc	a0,0x5
    80002e4a:	50a50513          	addi	a0,a0,1290 # 80008350 <states.0+0x78>
    80002e4e:	ffffd097          	auipc	ra,0xffffd
    80002e52:	73c080e7          	jalr	1852(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e56:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e5a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e5e:	00005517          	auipc	a0,0x5
    80002e62:	52250513          	addi	a0,a0,1314 # 80008380 <states.0+0xa8>
    80002e66:	ffffd097          	auipc	ra,0xffffd
    80002e6a:	724080e7          	jalr	1828(ra) # 8000058a <printf>
    setkilled(p);
    80002e6e:	8526                	mv	a0,s1
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	76a080e7          	jalr	1898(ra) # 800025da <setkilled>
    80002e78:	b739                	j	80002d86 <usertrap+0xd0>
    exit(-1);
    80002e7a:	557d                	li	a0,-1
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	60a080e7          	jalr	1546(ra) # 80002486 <exit>
  if (which_dev == 2){
    80002e84:	4789                	li	a5,2
    80002e86:	f0f916e3          	bne	s2,a5,80002d92 <usertrap+0xdc>
    yield();
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	48c080e7          	jalr	1164(ra) # 80002316 <yield>
    80002e92:	b701                	j	80002d92 <usertrap+0xdc>

0000000080002e94 <kerneltrap>:
{
    80002e94:	7179                	addi	sp,sp,-48
    80002e96:	f406                	sd	ra,40(sp)
    80002e98:	f022                	sd	s0,32(sp)
    80002e9a:	ec26                	sd	s1,24(sp)
    80002e9c:	e84a                	sd	s2,16(sp)
    80002e9e:	e44e                	sd	s3,8(sp)
    80002ea0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ea2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ea6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eaa:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002eae:	1004f793          	andi	a5,s1,256
    80002eb2:	cb85                	beqz	a5,80002ee2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eb4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002eb8:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002eba:	ef85                	bnez	a5,80002ef2 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002ebc:	00000097          	auipc	ra,0x0
    80002ec0:	d58080e7          	jalr	-680(ra) # 80002c14 <devintr>
    80002ec4:	cd1d                	beqz	a0,80002f02 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002ec6:	4789                	li	a5,2
    80002ec8:	06f50a63          	beq	a0,a5,80002f3c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ecc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ed0:	10049073          	csrw	sstatus,s1
}
    80002ed4:	70a2                	ld	ra,40(sp)
    80002ed6:	7402                	ld	s0,32(sp)
    80002ed8:	64e2                	ld	s1,24(sp)
    80002eda:	6942                	ld	s2,16(sp)
    80002edc:	69a2                	ld	s3,8(sp)
    80002ede:	6145                	addi	sp,sp,48
    80002ee0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ee2:	00005517          	auipc	a0,0x5
    80002ee6:	4be50513          	addi	a0,a0,1214 # 800083a0 <states.0+0xc8>
    80002eea:	ffffd097          	auipc	ra,0xffffd
    80002eee:	656080e7          	jalr	1622(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002ef2:	00005517          	auipc	a0,0x5
    80002ef6:	4d650513          	addi	a0,a0,1238 # 800083c8 <states.0+0xf0>
    80002efa:	ffffd097          	auipc	ra,0xffffd
    80002efe:	646080e7          	jalr	1606(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002f02:	85ce                	mv	a1,s3
    80002f04:	00005517          	auipc	a0,0x5
    80002f08:	4e450513          	addi	a0,a0,1252 # 800083e8 <states.0+0x110>
    80002f0c:	ffffd097          	auipc	ra,0xffffd
    80002f10:	67e080e7          	jalr	1662(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f14:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f18:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f1c:	00005517          	auipc	a0,0x5
    80002f20:	4dc50513          	addi	a0,a0,1244 # 800083f8 <states.0+0x120>
    80002f24:	ffffd097          	auipc	ra,0xffffd
    80002f28:	666080e7          	jalr	1638(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002f2c:	00005517          	auipc	a0,0x5
    80002f30:	4e450513          	addi	a0,a0,1252 # 80008410 <states.0+0x138>
    80002f34:	ffffd097          	auipc	ra,0xffffd
    80002f38:	60c080e7          	jalr	1548(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	d16080e7          	jalr	-746(ra) # 80001c52 <myproc>
    80002f44:	d541                	beqz	a0,80002ecc <kerneltrap+0x38>
    80002f46:	fffff097          	auipc	ra,0xfffff
    80002f4a:	d0c080e7          	jalr	-756(ra) # 80001c52 <myproc>
    80002f4e:	4d18                	lw	a4,24(a0)
    80002f50:	4791                	li	a5,4
    80002f52:	f6f71de3          	bne	a4,a5,80002ecc <kerneltrap+0x38>
    yield();
    80002f56:	fffff097          	auipc	ra,0xfffff
    80002f5a:	3c0080e7          	jalr	960(ra) # 80002316 <yield>
    80002f5e:	b7bd                	j	80002ecc <kerneltrap+0x38>

0000000080002f60 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f60:	1101                	addi	sp,sp,-32
    80002f62:	ec06                	sd	ra,24(sp)
    80002f64:	e822                	sd	s0,16(sp)
    80002f66:	e426                	sd	s1,8(sp)
    80002f68:	1000                	addi	s0,sp,32
    80002f6a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f6c:	fffff097          	auipc	ra,0xfffff
    80002f70:	ce6080e7          	jalr	-794(ra) # 80001c52 <myproc>
  switch (n) {
    80002f74:	4795                	li	a5,5
    80002f76:	0497e163          	bltu	a5,s1,80002fb8 <argraw+0x58>
    80002f7a:	048a                	slli	s1,s1,0x2
    80002f7c:	00005717          	auipc	a4,0x5
    80002f80:	4cc70713          	addi	a4,a4,1228 # 80008448 <states.0+0x170>
    80002f84:	94ba                	add	s1,s1,a4
    80002f86:	409c                	lw	a5,0(s1)
    80002f88:	97ba                	add	a5,a5,a4
    80002f8a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f8c:	6d3c                	ld	a5,88(a0)
    80002f8e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f90:	60e2                	ld	ra,24(sp)
    80002f92:	6442                	ld	s0,16(sp)
    80002f94:	64a2                	ld	s1,8(sp)
    80002f96:	6105                	addi	sp,sp,32
    80002f98:	8082                	ret
    return p->trapframe->a1;
    80002f9a:	6d3c                	ld	a5,88(a0)
    80002f9c:	7fa8                	ld	a0,120(a5)
    80002f9e:	bfcd                	j	80002f90 <argraw+0x30>
    return p->trapframe->a2;
    80002fa0:	6d3c                	ld	a5,88(a0)
    80002fa2:	63c8                	ld	a0,128(a5)
    80002fa4:	b7f5                	j	80002f90 <argraw+0x30>
    return p->trapframe->a3;
    80002fa6:	6d3c                	ld	a5,88(a0)
    80002fa8:	67c8                	ld	a0,136(a5)
    80002faa:	b7dd                	j	80002f90 <argraw+0x30>
    return p->trapframe->a4;
    80002fac:	6d3c                	ld	a5,88(a0)
    80002fae:	6bc8                	ld	a0,144(a5)
    80002fb0:	b7c5                	j	80002f90 <argraw+0x30>
    return p->trapframe->a5;
    80002fb2:	6d3c                	ld	a5,88(a0)
    80002fb4:	6fc8                	ld	a0,152(a5)
    80002fb6:	bfe9                	j	80002f90 <argraw+0x30>
  panic("argraw");
    80002fb8:	00005517          	auipc	a0,0x5
    80002fbc:	46850513          	addi	a0,a0,1128 # 80008420 <states.0+0x148>
    80002fc0:	ffffd097          	auipc	ra,0xffffd
    80002fc4:	580080e7          	jalr	1408(ra) # 80000540 <panic>

0000000080002fc8 <fetchaddr>:
{
    80002fc8:	1101                	addi	sp,sp,-32
    80002fca:	ec06                	sd	ra,24(sp)
    80002fcc:	e822                	sd	s0,16(sp)
    80002fce:	e426                	sd	s1,8(sp)
    80002fd0:	e04a                	sd	s2,0(sp)
    80002fd2:	1000                	addi	s0,sp,32
    80002fd4:	84aa                	mv	s1,a0
    80002fd6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002fd8:	fffff097          	auipc	ra,0xfffff
    80002fdc:	c7a080e7          	jalr	-902(ra) # 80001c52 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002fe0:	653c                	ld	a5,72(a0)
    80002fe2:	02f4f863          	bgeu	s1,a5,80003012 <fetchaddr+0x4a>
    80002fe6:	00848713          	addi	a4,s1,8
    80002fea:	02e7e663          	bltu	a5,a4,80003016 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fee:	46a1                	li	a3,8
    80002ff0:	8626                	mv	a2,s1
    80002ff2:	85ca                	mv	a1,s2
    80002ff4:	6928                	ld	a0,80(a0)
    80002ff6:	fffff097          	auipc	ra,0xfffff
    80002ffa:	84c080e7          	jalr	-1972(ra) # 80001842 <copyin>
    80002ffe:	00a03533          	snez	a0,a0
    80003002:	40a00533          	neg	a0,a0
}
    80003006:	60e2                	ld	ra,24(sp)
    80003008:	6442                	ld	s0,16(sp)
    8000300a:	64a2                	ld	s1,8(sp)
    8000300c:	6902                	ld	s2,0(sp)
    8000300e:	6105                	addi	sp,sp,32
    80003010:	8082                	ret
    return -1;
    80003012:	557d                	li	a0,-1
    80003014:	bfcd                	j	80003006 <fetchaddr+0x3e>
    80003016:	557d                	li	a0,-1
    80003018:	b7fd                	j	80003006 <fetchaddr+0x3e>

000000008000301a <fetchstr>:
{
    8000301a:	7179                	addi	sp,sp,-48
    8000301c:	f406                	sd	ra,40(sp)
    8000301e:	f022                	sd	s0,32(sp)
    80003020:	ec26                	sd	s1,24(sp)
    80003022:	e84a                	sd	s2,16(sp)
    80003024:	e44e                	sd	s3,8(sp)
    80003026:	1800                	addi	s0,sp,48
    80003028:	892a                	mv	s2,a0
    8000302a:	84ae                	mv	s1,a1
    8000302c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	c24080e7          	jalr	-988(ra) # 80001c52 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003036:	86ce                	mv	a3,s3
    80003038:	864a                	mv	a2,s2
    8000303a:	85a6                	mv	a1,s1
    8000303c:	6928                	ld	a0,80(a0)
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	892080e7          	jalr	-1902(ra) # 800018d0 <copyinstr>
    80003046:	00054e63          	bltz	a0,80003062 <fetchstr+0x48>
  return strlen(buf);
    8000304a:	8526                	mv	a0,s1
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	fda080e7          	jalr	-38(ra) # 80001026 <strlen>
}
    80003054:	70a2                	ld	ra,40(sp)
    80003056:	7402                	ld	s0,32(sp)
    80003058:	64e2                	ld	s1,24(sp)
    8000305a:	6942                	ld	s2,16(sp)
    8000305c:	69a2                	ld	s3,8(sp)
    8000305e:	6145                	addi	sp,sp,48
    80003060:	8082                	ret
    return -1;
    80003062:	557d                	li	a0,-1
    80003064:	bfc5                	j	80003054 <fetchstr+0x3a>

0000000080003066 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003066:	1101                	addi	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	e426                	sd	s1,8(sp)
    8000306e:	1000                	addi	s0,sp,32
    80003070:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003072:	00000097          	auipc	ra,0x0
    80003076:	eee080e7          	jalr	-274(ra) # 80002f60 <argraw>
    8000307a:	c088                	sw	a0,0(s1)
}
    8000307c:	60e2                	ld	ra,24(sp)
    8000307e:	6442                	ld	s0,16(sp)
    80003080:	64a2                	ld	s1,8(sp)
    80003082:	6105                	addi	sp,sp,32
    80003084:	8082                	ret

0000000080003086 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003086:	1101                	addi	sp,sp,-32
    80003088:	ec06                	sd	ra,24(sp)
    8000308a:	e822                	sd	s0,16(sp)
    8000308c:	e426                	sd	s1,8(sp)
    8000308e:	1000                	addi	s0,sp,32
    80003090:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003092:	00000097          	auipc	ra,0x0
    80003096:	ece080e7          	jalr	-306(ra) # 80002f60 <argraw>
    8000309a:	e088                	sd	a0,0(s1)
}
    8000309c:	60e2                	ld	ra,24(sp)
    8000309e:	6442                	ld	s0,16(sp)
    800030a0:	64a2                	ld	s1,8(sp)
    800030a2:	6105                	addi	sp,sp,32
    800030a4:	8082                	ret

00000000800030a6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030a6:	7179                	addi	sp,sp,-48
    800030a8:	f406                	sd	ra,40(sp)
    800030aa:	f022                	sd	s0,32(sp)
    800030ac:	ec26                	sd	s1,24(sp)
    800030ae:	e84a                	sd	s2,16(sp)
    800030b0:	1800                	addi	s0,sp,48
    800030b2:	84ae                	mv	s1,a1
    800030b4:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800030b6:	fd840593          	addi	a1,s0,-40
    800030ba:	00000097          	auipc	ra,0x0
    800030be:	fcc080e7          	jalr	-52(ra) # 80003086 <argaddr>
  return fetchstr(addr, buf, max);
    800030c2:	864a                	mv	a2,s2
    800030c4:	85a6                	mv	a1,s1
    800030c6:	fd843503          	ld	a0,-40(s0)
    800030ca:	00000097          	auipc	ra,0x0
    800030ce:	f50080e7          	jalr	-176(ra) # 8000301a <fetchstr>
}
    800030d2:	70a2                	ld	ra,40(sp)
    800030d4:	7402                	ld	s0,32(sp)
    800030d6:	64e2                	ld	s1,24(sp)
    800030d8:	6942                	ld	s2,16(sp)
    800030da:	6145                	addi	sp,sp,48
    800030dc:	8082                	ret

00000000800030de <syscall>:
[SYS_sigreturn] sys_sigreturn
};

void
syscall(void)
{
    800030de:	1101                	addi	sp,sp,-32
    800030e0:	ec06                	sd	ra,24(sp)
    800030e2:	e822                	sd	s0,16(sp)
    800030e4:	e426                	sd	s1,8(sp)
    800030e6:	e04a                	sd	s2,0(sp)
    800030e8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800030ea:	fffff097          	auipc	ra,0xfffff
    800030ee:	b68080e7          	jalr	-1176(ra) # 80001c52 <myproc>
    800030f2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800030f4:	05853903          	ld	s2,88(a0)
    800030f8:	0a893783          	ld	a5,168(s2)
    800030fc:	0007869b          	sext.w	a3,a5
  if(num==SYS_read){
    80003100:	4715                	li	a4,5
    80003102:	02e68363          	beq	a3,a4,80003128 <syscall+0x4a>
    p->readcount=p->readcount+1;
  }
  
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003106:	37fd                	addiw	a5,a5,-1
    80003108:	4761                	li	a4,24
    8000310a:	02f76c63          	bltu	a4,a5,80003142 <syscall+0x64>
    8000310e:	00369713          	slli	a4,a3,0x3
    80003112:	00005797          	auipc	a5,0x5
    80003116:	34e78793          	addi	a5,a5,846 # 80008460 <syscalls>
    8000311a:	97ba                	add	a5,a5,a4
    8000311c:	6398                	ld	a4,0(a5)
    8000311e:	c315                	beqz	a4,80003142 <syscall+0x64>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

    p->trapframe->a0 = syscalls[num]();
    80003120:	9702                	jalr	a4
    80003122:	06a93823          	sd	a0,112(s2)
    80003126:	a825                	j	8000315e <syscall+0x80>
    p->readcount=p->readcount+1;
    80003128:	17452703          	lw	a4,372(a0)
    8000312c:	2705                	addiw	a4,a4,1
    8000312e:	16e52a23          	sw	a4,372(a0)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003132:	37fd                	addiw	a5,a5,-1
    80003134:	4661                	li	a2,24
    80003136:	00002717          	auipc	a4,0x2
    8000313a:	76c70713          	addi	a4,a4,1900 # 800058a2 <sys_read>
    8000313e:	fef671e3          	bgeu	a2,a5,80003120 <syscall+0x42>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003142:	15848613          	addi	a2,s1,344
    80003146:	588c                	lw	a1,48(s1)
    80003148:	00005517          	auipc	a0,0x5
    8000314c:	2e050513          	addi	a0,a0,736 # 80008428 <states.0+0x150>
    80003150:	ffffd097          	auipc	ra,0xffffd
    80003154:	43a080e7          	jalr	1082(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003158:	6cbc                	ld	a5,88(s1)
    8000315a:	577d                	li	a4,-1
    8000315c:	fbb8                	sd	a4,112(a5)
  }
}
    8000315e:	60e2                	ld	ra,24(sp)
    80003160:	6442                	ld	s0,16(sp)
    80003162:	64a2                	ld	s1,8(sp)
    80003164:	6902                	ld	s2,0(sp)
    80003166:	6105                	addi	sp,sp,32
    80003168:	8082                	ret

000000008000316a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000316a:	1101                	addi	sp,sp,-32
    8000316c:	ec06                	sd	ra,24(sp)
    8000316e:	e822                	sd	s0,16(sp)
    80003170:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003172:	fec40593          	addi	a1,s0,-20
    80003176:	4501                	li	a0,0
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	eee080e7          	jalr	-274(ra) # 80003066 <argint>
  exit(n);
    80003180:	fec42503          	lw	a0,-20(s0)
    80003184:	fffff097          	auipc	ra,0xfffff
    80003188:	302080e7          	jalr	770(ra) # 80002486 <exit>
  return 0; // not reached
}
    8000318c:	4501                	li	a0,0
    8000318e:	60e2                	ld	ra,24(sp)
    80003190:	6442                	ld	s0,16(sp)
    80003192:	6105                	addi	sp,sp,32
    80003194:	8082                	ret

0000000080003196 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003196:	1141                	addi	sp,sp,-16
    80003198:	e406                	sd	ra,8(sp)
    8000319a:	e022                	sd	s0,0(sp)
    8000319c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000319e:	fffff097          	auipc	ra,0xfffff
    800031a2:	ab4080e7          	jalr	-1356(ra) # 80001c52 <myproc>
}
    800031a6:	5908                	lw	a0,48(a0)
    800031a8:	60a2                	ld	ra,8(sp)
    800031aa:	6402                	ld	s0,0(sp)
    800031ac:	0141                	addi	sp,sp,16
    800031ae:	8082                	ret

00000000800031b0 <sys_fork>:

uint64
sys_fork(void)
{
    800031b0:	1141                	addi	sp,sp,-16
    800031b2:	e406                	sd	ra,8(sp)
    800031b4:	e022                	sd	s0,0(sp)
    800031b6:	0800                	addi	s0,sp,16
  return fork();
    800031b8:	fffff097          	auipc	ra,0xfffff
    800031bc:	ea8080e7          	jalr	-344(ra) # 80002060 <fork>
}
    800031c0:	60a2                	ld	ra,8(sp)
    800031c2:	6402                	ld	s0,0(sp)
    800031c4:	0141                	addi	sp,sp,16
    800031c6:	8082                	ret

00000000800031c8 <sys_wait>:

uint64
sys_wait(void)
{
    800031c8:	1101                	addi	sp,sp,-32
    800031ca:	ec06                	sd	ra,24(sp)
    800031cc:	e822                	sd	s0,16(sp)
    800031ce:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800031d0:	fe840593          	addi	a1,s0,-24
    800031d4:	4501                	li	a0,0
    800031d6:	00000097          	auipc	ra,0x0
    800031da:	eb0080e7          	jalr	-336(ra) # 80003086 <argaddr>
  return wait(p);
    800031de:	fe843503          	ld	a0,-24(s0)
    800031e2:	fffff097          	auipc	ra,0xfffff
    800031e6:	456080e7          	jalr	1110(ra) # 80002638 <wait>
}
    800031ea:	60e2                	ld	ra,24(sp)
    800031ec:	6442                	ld	s0,16(sp)
    800031ee:	6105                	addi	sp,sp,32
    800031f0:	8082                	ret

00000000800031f2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031f2:	7179                	addi	sp,sp,-48
    800031f4:	f406                	sd	ra,40(sp)
    800031f6:	f022                	sd	s0,32(sp)
    800031f8:	ec26                	sd	s1,24(sp)
    800031fa:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800031fc:	fdc40593          	addi	a1,s0,-36
    80003200:	4501                	li	a0,0
    80003202:	00000097          	auipc	ra,0x0
    80003206:	e64080e7          	jalr	-412(ra) # 80003066 <argint>
  addr = myproc()->sz;
    8000320a:	fffff097          	auipc	ra,0xfffff
    8000320e:	a48080e7          	jalr	-1464(ra) # 80001c52 <myproc>
    80003212:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003214:	fdc42503          	lw	a0,-36(s0)
    80003218:	fffff097          	auipc	ra,0xfffff
    8000321c:	dec080e7          	jalr	-532(ra) # 80002004 <growproc>
    80003220:	00054863          	bltz	a0,80003230 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003224:	8526                	mv	a0,s1
    80003226:	70a2                	ld	ra,40(sp)
    80003228:	7402                	ld	s0,32(sp)
    8000322a:	64e2                	ld	s1,24(sp)
    8000322c:	6145                	addi	sp,sp,48
    8000322e:	8082                	ret
    return -1;
    80003230:	54fd                	li	s1,-1
    80003232:	bfcd                	j	80003224 <sys_sbrk+0x32>

0000000080003234 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003234:	7139                	addi	sp,sp,-64
    80003236:	fc06                	sd	ra,56(sp)
    80003238:	f822                	sd	s0,48(sp)
    8000323a:	f426                	sd	s1,40(sp)
    8000323c:	f04a                	sd	s2,32(sp)
    8000323e:	ec4e                	sd	s3,24(sp)
    80003240:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003242:	fcc40593          	addi	a1,s0,-52
    80003246:	4501                	li	a0,0
    80003248:	00000097          	auipc	ra,0x0
    8000324c:	e1e080e7          	jalr	-482(ra) # 80003066 <argint>
  acquire(&tickslock);
    80003250:	00035517          	auipc	a0,0x35
    80003254:	97850513          	addi	a0,a0,-1672 # 80037bc8 <tickslock>
    80003258:	ffffe097          	auipc	ra,0xffffe
    8000325c:	b56080e7          	jalr	-1194(ra) # 80000dae <acquire>
  ticks0 = ticks;
    80003260:	00005917          	auipc	s2,0x5
    80003264:	6b092903          	lw	s2,1712(s2) # 80008910 <ticks>
  while (ticks - ticks0 < n)
    80003268:	fcc42783          	lw	a5,-52(s0)
    8000326c:	cf9d                	beqz	a5,800032aa <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000326e:	00035997          	auipc	s3,0x35
    80003272:	95a98993          	addi	s3,s3,-1702 # 80037bc8 <tickslock>
    80003276:	00005497          	auipc	s1,0x5
    8000327a:	69a48493          	addi	s1,s1,1690 # 80008910 <ticks>
    if (killed(myproc()))
    8000327e:	fffff097          	auipc	ra,0xfffff
    80003282:	9d4080e7          	jalr	-1580(ra) # 80001c52 <myproc>
    80003286:	fffff097          	auipc	ra,0xfffff
    8000328a:	380080e7          	jalr	896(ra) # 80002606 <killed>
    8000328e:	ed15                	bnez	a0,800032ca <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003290:	85ce                	mv	a1,s3
    80003292:	8526                	mv	a0,s1
    80003294:	fffff097          	auipc	ra,0xfffff
    80003298:	0be080e7          	jalr	190(ra) # 80002352 <sleep>
  while (ticks - ticks0 < n)
    8000329c:	409c                	lw	a5,0(s1)
    8000329e:	412787bb          	subw	a5,a5,s2
    800032a2:	fcc42703          	lw	a4,-52(s0)
    800032a6:	fce7ece3          	bltu	a5,a4,8000327e <sys_sleep+0x4a>
  }
  release(&tickslock);
    800032aa:	00035517          	auipc	a0,0x35
    800032ae:	91e50513          	addi	a0,a0,-1762 # 80037bc8 <tickslock>
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	bb0080e7          	jalr	-1104(ra) # 80000e62 <release>
  return 0;
    800032ba:	4501                	li	a0,0
}
    800032bc:	70e2                	ld	ra,56(sp)
    800032be:	7442                	ld	s0,48(sp)
    800032c0:	74a2                	ld	s1,40(sp)
    800032c2:	7902                	ld	s2,32(sp)
    800032c4:	69e2                	ld	s3,24(sp)
    800032c6:	6121                	addi	sp,sp,64
    800032c8:	8082                	ret
      release(&tickslock);
    800032ca:	00035517          	auipc	a0,0x35
    800032ce:	8fe50513          	addi	a0,a0,-1794 # 80037bc8 <tickslock>
    800032d2:	ffffe097          	auipc	ra,0xffffe
    800032d6:	b90080e7          	jalr	-1136(ra) # 80000e62 <release>
      return -1;
    800032da:	557d                	li	a0,-1
    800032dc:	b7c5                	j	800032bc <sys_sleep+0x88>

00000000800032de <sys_kill>:

uint64
sys_kill(void)
{
    800032de:	1101                	addi	sp,sp,-32
    800032e0:	ec06                	sd	ra,24(sp)
    800032e2:	e822                	sd	s0,16(sp)
    800032e4:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800032e6:	fec40593          	addi	a1,s0,-20
    800032ea:	4501                	li	a0,0
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	d7a080e7          	jalr	-646(ra) # 80003066 <argint>
  return kill(pid);
    800032f4:	fec42503          	lw	a0,-20(s0)
    800032f8:	fffff097          	auipc	ra,0xfffff
    800032fc:	270080e7          	jalr	624(ra) # 80002568 <kill>
}
    80003300:	60e2                	ld	ra,24(sp)
    80003302:	6442                	ld	s0,16(sp)
    80003304:	6105                	addi	sp,sp,32
    80003306:	8082                	ret

0000000080003308 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003308:	1101                	addi	sp,sp,-32
    8000330a:	ec06                	sd	ra,24(sp)
    8000330c:	e822                	sd	s0,16(sp)
    8000330e:	e426                	sd	s1,8(sp)
    80003310:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003312:	00035517          	auipc	a0,0x35
    80003316:	8b650513          	addi	a0,a0,-1866 # 80037bc8 <tickslock>
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	a94080e7          	jalr	-1388(ra) # 80000dae <acquire>
  xticks = ticks;
    80003322:	00005497          	auipc	s1,0x5
    80003326:	5ee4a483          	lw	s1,1518(s1) # 80008910 <ticks>
  release(&tickslock);
    8000332a:	00035517          	auipc	a0,0x35
    8000332e:	89e50513          	addi	a0,a0,-1890 # 80037bc8 <tickslock>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	b30080e7          	jalr	-1232(ra) # 80000e62 <release>
  return xticks;
}
    8000333a:	02049513          	slli	a0,s1,0x20
    8000333e:	9101                	srli	a0,a0,0x20
    80003340:	60e2                	ld	ra,24(sp)
    80003342:	6442                	ld	s0,16(sp)
    80003344:	64a2                	ld	s1,8(sp)
    80003346:	6105                	addi	sp,sp,32
    80003348:	8082                	ret

000000008000334a <sys_waitx>:

uint64
sys_waitx(void)
{
    8000334a:	7139                	addi	sp,sp,-64
    8000334c:	fc06                	sd	ra,56(sp)
    8000334e:	f822                	sd	s0,48(sp)
    80003350:	f426                	sd	s1,40(sp)
    80003352:	f04a                	sd	s2,32(sp)
    80003354:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003356:	fd840593          	addi	a1,s0,-40
    8000335a:	4501                	li	a0,0
    8000335c:	00000097          	auipc	ra,0x0
    80003360:	d2a080e7          	jalr	-726(ra) # 80003086 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003364:	fd040593          	addi	a1,s0,-48
    80003368:	4505                	li	a0,1
    8000336a:	00000097          	auipc	ra,0x0
    8000336e:	d1c080e7          	jalr	-740(ra) # 80003086 <argaddr>
  argaddr(2, &addr2);
    80003372:	fc840593          	addi	a1,s0,-56
    80003376:	4509                	li	a0,2
    80003378:	00000097          	auipc	ra,0x0
    8000337c:	d0e080e7          	jalr	-754(ra) # 80003086 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003380:	fc040613          	addi	a2,s0,-64
    80003384:	fc440593          	addi	a1,s0,-60
    80003388:	fd843503          	ld	a0,-40(s0)
    8000338c:	fffff097          	auipc	ra,0xfffff
    80003390:	536080e7          	jalr	1334(ra) # 800028c2 <waitx>
    80003394:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003396:	fffff097          	auipc	ra,0xfffff
    8000339a:	8bc080e7          	jalr	-1860(ra) # 80001c52 <myproc>
    8000339e:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800033a0:	4691                	li	a3,4
    800033a2:	fc440613          	addi	a2,s0,-60
    800033a6:	fd043583          	ld	a1,-48(s0)
    800033aa:	6928                	ld	a0,80(a0)
    800033ac:	ffffe097          	auipc	ra,0xffffe
    800033b0:	690080e7          	jalr	1680(ra) # 80001a3c <copyout>
    return -1;
    800033b4:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800033b6:	00054f63          	bltz	a0,800033d4 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800033ba:	4691                	li	a3,4
    800033bc:	fc040613          	addi	a2,s0,-64
    800033c0:	fc843583          	ld	a1,-56(s0)
    800033c4:	68a8                	ld	a0,80(s1)
    800033c6:	ffffe097          	auipc	ra,0xffffe
    800033ca:	676080e7          	jalr	1654(ra) # 80001a3c <copyout>
    800033ce:	00054a63          	bltz	a0,800033e2 <sys_waitx+0x98>
    return -1;
  return ret;
    800033d2:	87ca                	mv	a5,s2
}
    800033d4:	853e                	mv	a0,a5
    800033d6:	70e2                	ld	ra,56(sp)
    800033d8:	7442                	ld	s0,48(sp)
    800033da:	74a2                	ld	s1,40(sp)
    800033dc:	7902                	ld	s2,32(sp)
    800033de:	6121                	addi	sp,sp,64
    800033e0:	8082                	ret
    return -1;
    800033e2:	57fd                	li	a5,-1
    800033e4:	bfc5                	j	800033d4 <sys_waitx+0x8a>

00000000800033e6 <sys_getreadcount>:

int sys_getreadcount(void){
    800033e6:	1141                	addi	sp,sp,-16
    800033e8:	e406                	sd	ra,8(sp)
    800033ea:	e022                	sd	s0,0(sp)
    800033ec:	0800                	addi	s0,sp,16

  return myproc()->readcount;
    800033ee:	fffff097          	auipc	ra,0xfffff
    800033f2:	864080e7          	jalr	-1948(ra) # 80001c52 <myproc>

}
    800033f6:	17452503          	lw	a0,372(a0)
    800033fa:	60a2                	ld	ra,8(sp)
    800033fc:	6402                	ld	s0,0(sp)
    800033fe:	0141                	addi	sp,sp,16
    80003400:	8082                	ret

0000000080003402 <sys_sigalarm>:

int sys_sigalarm(void){
    80003402:	1101                	addi	sp,sp,-32
    80003404:	ec06                	sd	ra,24(sp)
    80003406:	e822                	sd	s0,16(sp)
    80003408:	1000                	addi	s0,sp,32

  
  // myproc()->is_alarm=1;
  uint64 handler;
  int ticks;
  argint(0,&ticks);
    8000340a:	fe440593          	addi	a1,s0,-28
    8000340e:	4501                	li	a0,0
    80003410:	00000097          	auipc	ra,0x0
    80003414:	c56080e7          	jalr	-938(ra) # 80003066 <argint>
  argaddr(1,&handler);
    80003418:	fe840593          	addi	a1,s0,-24
    8000341c:	4505                	li	a0,1
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	c68080e7          	jalr	-920(ra) # 80003086 <argaddr>

  
  myproc()->alarm_state=1;
    80003426:	fffff097          	auipc	ra,0xfffff
    8000342a:	82c080e7          	jalr	-2004(ra) # 80001c52 <myproc>
    8000342e:	4785                	li	a5,1
    80003430:	16f52e23          	sw	a5,380(a0)
  
  
  myproc()->handler=handler;
    80003434:	fffff097          	auipc	ra,0xfffff
    80003438:	81e080e7          	jalr	-2018(ra) # 80001c52 <myproc>
    8000343c:	fe843783          	ld	a5,-24(s0)
    80003440:	18f53023          	sd	a5,384(a0)
  myproc()->clockticks=ticks;
    80003444:	fffff097          	auipc	ra,0xfffff
    80003448:	80e080e7          	jalr	-2034(ra) # 80001c52 <myproc>
    8000344c:	fe442783          	lw	a5,-28(s0)
    80003450:	16f52c23          	sw	a5,376(a0)
  
  return 0;
}
    80003454:	4501                	li	a0,0
    80003456:	60e2                	ld	ra,24(sp)
    80003458:	6442                	ld	s0,16(sp)
    8000345a:	6105                	addi	sp,sp,32
    8000345c:	8082                	ret

000000008000345e <sys_sigreturn>:

int sys_sigreturn(void){
    8000345e:	1101                	addi	sp,sp,-32
    80003460:	ec06                	sd	ra,24(sp)
    80003462:	e822                	sd	s0,16(sp)
    80003464:	e426                	sd	s1,8(sp)
    80003466:	1000                	addi	s0,sp,32

  struct proc* p = myproc();
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	7ea080e7          	jalr	2026(ra) # 80001c52 <myproc>
    80003470:	84aa                	mv	s1,a0
  

  memmove(p->trapframe,p->alarm_frame,PGSIZE);
    80003472:	6605                	lui	a2,0x1
    80003474:	18853583          	ld	a1,392(a0)
    80003478:	6d28                	ld	a0,88(a0)
    8000347a:	ffffe097          	auipc	ra,0xffffe
    8000347e:	a8c080e7          	jalr	-1396(ra) # 80000f06 <memmove>
  kfree(p->alarm_frame);
    80003482:	1884b503          	ld	a0,392(s1)
    80003486:	ffffd097          	auipc	ra,0xffffd
    8000348a:	6fe080e7          	jalr	1790(ra) # 80000b84 <kfree>
  p->currentticks=0;
    8000348e:	1804aa23          	sw	zero,404(s1)
  p->alarm_state=0;
    80003492:	1604ae23          	sw	zero,380(s1)
  p->clockticks=0;
    80003496:	1604ac23          	sw	zero,376(s1)
  p->is_alarm=0;
    8000349a:	1804a823          	sw	zero,400(s1)
  usertrapret();
    8000349e:	fffff097          	auipc	ra,0xfffff
    800034a2:	68c080e7          	jalr	1676(ra) # 80002b2a <usertrapret>

  return 0;

    800034a6:	4501                	li	a0,0
    800034a8:	60e2                	ld	ra,24(sp)
    800034aa:	6442                	ld	s0,16(sp)
    800034ac:	64a2                	ld	s1,8(sp)
    800034ae:	6105                	addi	sp,sp,32
    800034b0:	8082                	ret

00000000800034b2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800034b2:	7179                	addi	sp,sp,-48
    800034b4:	f406                	sd	ra,40(sp)
    800034b6:	f022                	sd	s0,32(sp)
    800034b8:	ec26                	sd	s1,24(sp)
    800034ba:	e84a                	sd	s2,16(sp)
    800034bc:	e44e                	sd	s3,8(sp)
    800034be:	e052                	sd	s4,0(sp)
    800034c0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034c2:	00005597          	auipc	a1,0x5
    800034c6:	06e58593          	addi	a1,a1,110 # 80008530 <syscalls+0xd0>
    800034ca:	00034517          	auipc	a0,0x34
    800034ce:	71650513          	addi	a0,a0,1814 # 80037be0 <bcache>
    800034d2:	ffffe097          	auipc	ra,0xffffe
    800034d6:	84c080e7          	jalr	-1972(ra) # 80000d1e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034da:	0003c797          	auipc	a5,0x3c
    800034de:	70678793          	addi	a5,a5,1798 # 8003fbe0 <bcache+0x8000>
    800034e2:	0003d717          	auipc	a4,0x3d
    800034e6:	96670713          	addi	a4,a4,-1690 # 8003fe48 <bcache+0x8268>
    800034ea:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034ee:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034f2:	00034497          	auipc	s1,0x34
    800034f6:	70648493          	addi	s1,s1,1798 # 80037bf8 <bcache+0x18>
    b->next = bcache.head.next;
    800034fa:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034fc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034fe:	00005a17          	auipc	s4,0x5
    80003502:	03aa0a13          	addi	s4,s4,58 # 80008538 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003506:	2b893783          	ld	a5,696(s2)
    8000350a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000350c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003510:	85d2                	mv	a1,s4
    80003512:	01048513          	addi	a0,s1,16
    80003516:	00001097          	auipc	ra,0x1
    8000351a:	4c8080e7          	jalr	1224(ra) # 800049de <initsleeplock>
    bcache.head.next->prev = b;
    8000351e:	2b893783          	ld	a5,696(s2)
    80003522:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003524:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003528:	45848493          	addi	s1,s1,1112
    8000352c:	fd349de3          	bne	s1,s3,80003506 <binit+0x54>
  }
}
    80003530:	70a2                	ld	ra,40(sp)
    80003532:	7402                	ld	s0,32(sp)
    80003534:	64e2                	ld	s1,24(sp)
    80003536:	6942                	ld	s2,16(sp)
    80003538:	69a2                	ld	s3,8(sp)
    8000353a:	6a02                	ld	s4,0(sp)
    8000353c:	6145                	addi	sp,sp,48
    8000353e:	8082                	ret

0000000080003540 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003540:	7179                	addi	sp,sp,-48
    80003542:	f406                	sd	ra,40(sp)
    80003544:	f022                	sd	s0,32(sp)
    80003546:	ec26                	sd	s1,24(sp)
    80003548:	e84a                	sd	s2,16(sp)
    8000354a:	e44e                	sd	s3,8(sp)
    8000354c:	1800                	addi	s0,sp,48
    8000354e:	892a                	mv	s2,a0
    80003550:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003552:	00034517          	auipc	a0,0x34
    80003556:	68e50513          	addi	a0,a0,1678 # 80037be0 <bcache>
    8000355a:	ffffe097          	auipc	ra,0xffffe
    8000355e:	854080e7          	jalr	-1964(ra) # 80000dae <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003562:	0003d497          	auipc	s1,0x3d
    80003566:	9364b483          	ld	s1,-1738(s1) # 8003fe98 <bcache+0x82b8>
    8000356a:	0003d797          	auipc	a5,0x3d
    8000356e:	8de78793          	addi	a5,a5,-1826 # 8003fe48 <bcache+0x8268>
    80003572:	02f48f63          	beq	s1,a5,800035b0 <bread+0x70>
    80003576:	873e                	mv	a4,a5
    80003578:	a021                	j	80003580 <bread+0x40>
    8000357a:	68a4                	ld	s1,80(s1)
    8000357c:	02e48a63          	beq	s1,a4,800035b0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003580:	449c                	lw	a5,8(s1)
    80003582:	ff279ce3          	bne	a5,s2,8000357a <bread+0x3a>
    80003586:	44dc                	lw	a5,12(s1)
    80003588:	ff3799e3          	bne	a5,s3,8000357a <bread+0x3a>
      b->refcnt++;
    8000358c:	40bc                	lw	a5,64(s1)
    8000358e:	2785                	addiw	a5,a5,1
    80003590:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003592:	00034517          	auipc	a0,0x34
    80003596:	64e50513          	addi	a0,a0,1614 # 80037be0 <bcache>
    8000359a:	ffffe097          	auipc	ra,0xffffe
    8000359e:	8c8080e7          	jalr	-1848(ra) # 80000e62 <release>
      acquiresleep(&b->lock);
    800035a2:	01048513          	addi	a0,s1,16
    800035a6:	00001097          	auipc	ra,0x1
    800035aa:	472080e7          	jalr	1138(ra) # 80004a18 <acquiresleep>
      return b;
    800035ae:	a8b9                	j	8000360c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035b0:	0003d497          	auipc	s1,0x3d
    800035b4:	8e04b483          	ld	s1,-1824(s1) # 8003fe90 <bcache+0x82b0>
    800035b8:	0003d797          	auipc	a5,0x3d
    800035bc:	89078793          	addi	a5,a5,-1904 # 8003fe48 <bcache+0x8268>
    800035c0:	00f48863          	beq	s1,a5,800035d0 <bread+0x90>
    800035c4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035c6:	40bc                	lw	a5,64(s1)
    800035c8:	cf81                	beqz	a5,800035e0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035ca:	64a4                	ld	s1,72(s1)
    800035cc:	fee49de3          	bne	s1,a4,800035c6 <bread+0x86>
  panic("bget: no buffers");
    800035d0:	00005517          	auipc	a0,0x5
    800035d4:	f7050513          	addi	a0,a0,-144 # 80008540 <syscalls+0xe0>
    800035d8:	ffffd097          	auipc	ra,0xffffd
    800035dc:	f68080e7          	jalr	-152(ra) # 80000540 <panic>
      b->dev = dev;
    800035e0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800035e4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800035e8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035ec:	4785                	li	a5,1
    800035ee:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035f0:	00034517          	auipc	a0,0x34
    800035f4:	5f050513          	addi	a0,a0,1520 # 80037be0 <bcache>
    800035f8:	ffffe097          	auipc	ra,0xffffe
    800035fc:	86a080e7          	jalr	-1942(ra) # 80000e62 <release>
      acquiresleep(&b->lock);
    80003600:	01048513          	addi	a0,s1,16
    80003604:	00001097          	auipc	ra,0x1
    80003608:	414080e7          	jalr	1044(ra) # 80004a18 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000360c:	409c                	lw	a5,0(s1)
    8000360e:	cb89                	beqz	a5,80003620 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003610:	8526                	mv	a0,s1
    80003612:	70a2                	ld	ra,40(sp)
    80003614:	7402                	ld	s0,32(sp)
    80003616:	64e2                	ld	s1,24(sp)
    80003618:	6942                	ld	s2,16(sp)
    8000361a:	69a2                	ld	s3,8(sp)
    8000361c:	6145                	addi	sp,sp,48
    8000361e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003620:	4581                	li	a1,0
    80003622:	8526                	mv	a0,s1
    80003624:	00003097          	auipc	ra,0x3
    80003628:	fde080e7          	jalr	-34(ra) # 80006602 <virtio_disk_rw>
    b->valid = 1;
    8000362c:	4785                	li	a5,1
    8000362e:	c09c                	sw	a5,0(s1)
  return b;
    80003630:	b7c5                	j	80003610 <bread+0xd0>

0000000080003632 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003632:	1101                	addi	sp,sp,-32
    80003634:	ec06                	sd	ra,24(sp)
    80003636:	e822                	sd	s0,16(sp)
    80003638:	e426                	sd	s1,8(sp)
    8000363a:	1000                	addi	s0,sp,32
    8000363c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000363e:	0541                	addi	a0,a0,16
    80003640:	00001097          	auipc	ra,0x1
    80003644:	472080e7          	jalr	1138(ra) # 80004ab2 <holdingsleep>
    80003648:	cd01                	beqz	a0,80003660 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000364a:	4585                	li	a1,1
    8000364c:	8526                	mv	a0,s1
    8000364e:	00003097          	auipc	ra,0x3
    80003652:	fb4080e7          	jalr	-76(ra) # 80006602 <virtio_disk_rw>
}
    80003656:	60e2                	ld	ra,24(sp)
    80003658:	6442                	ld	s0,16(sp)
    8000365a:	64a2                	ld	s1,8(sp)
    8000365c:	6105                	addi	sp,sp,32
    8000365e:	8082                	ret
    panic("bwrite");
    80003660:	00005517          	auipc	a0,0x5
    80003664:	ef850513          	addi	a0,a0,-264 # 80008558 <syscalls+0xf8>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	ed8080e7          	jalr	-296(ra) # 80000540 <panic>

0000000080003670 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003670:	1101                	addi	sp,sp,-32
    80003672:	ec06                	sd	ra,24(sp)
    80003674:	e822                	sd	s0,16(sp)
    80003676:	e426                	sd	s1,8(sp)
    80003678:	e04a                	sd	s2,0(sp)
    8000367a:	1000                	addi	s0,sp,32
    8000367c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000367e:	01050913          	addi	s2,a0,16
    80003682:	854a                	mv	a0,s2
    80003684:	00001097          	auipc	ra,0x1
    80003688:	42e080e7          	jalr	1070(ra) # 80004ab2 <holdingsleep>
    8000368c:	c92d                	beqz	a0,800036fe <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000368e:	854a                	mv	a0,s2
    80003690:	00001097          	auipc	ra,0x1
    80003694:	3de080e7          	jalr	990(ra) # 80004a6e <releasesleep>

  acquire(&bcache.lock);
    80003698:	00034517          	auipc	a0,0x34
    8000369c:	54850513          	addi	a0,a0,1352 # 80037be0 <bcache>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	70e080e7          	jalr	1806(ra) # 80000dae <acquire>
  b->refcnt--;
    800036a8:	40bc                	lw	a5,64(s1)
    800036aa:	37fd                	addiw	a5,a5,-1
    800036ac:	0007871b          	sext.w	a4,a5
    800036b0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800036b2:	eb05                	bnez	a4,800036e2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036b4:	68bc                	ld	a5,80(s1)
    800036b6:	64b8                	ld	a4,72(s1)
    800036b8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800036ba:	64bc                	ld	a5,72(s1)
    800036bc:	68b8                	ld	a4,80(s1)
    800036be:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036c0:	0003c797          	auipc	a5,0x3c
    800036c4:	52078793          	addi	a5,a5,1312 # 8003fbe0 <bcache+0x8000>
    800036c8:	2b87b703          	ld	a4,696(a5)
    800036cc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036ce:	0003c717          	auipc	a4,0x3c
    800036d2:	77a70713          	addi	a4,a4,1914 # 8003fe48 <bcache+0x8268>
    800036d6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036d8:	2b87b703          	ld	a4,696(a5)
    800036dc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036de:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036e2:	00034517          	auipc	a0,0x34
    800036e6:	4fe50513          	addi	a0,a0,1278 # 80037be0 <bcache>
    800036ea:	ffffd097          	auipc	ra,0xffffd
    800036ee:	778080e7          	jalr	1912(ra) # 80000e62 <release>
}
    800036f2:	60e2                	ld	ra,24(sp)
    800036f4:	6442                	ld	s0,16(sp)
    800036f6:	64a2                	ld	s1,8(sp)
    800036f8:	6902                	ld	s2,0(sp)
    800036fa:	6105                	addi	sp,sp,32
    800036fc:	8082                	ret
    panic("brelse");
    800036fe:	00005517          	auipc	a0,0x5
    80003702:	e6250513          	addi	a0,a0,-414 # 80008560 <syscalls+0x100>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	e3a080e7          	jalr	-454(ra) # 80000540 <panic>

000000008000370e <bpin>:

void
bpin(struct buf *b) {
    8000370e:	1101                	addi	sp,sp,-32
    80003710:	ec06                	sd	ra,24(sp)
    80003712:	e822                	sd	s0,16(sp)
    80003714:	e426                	sd	s1,8(sp)
    80003716:	1000                	addi	s0,sp,32
    80003718:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000371a:	00034517          	auipc	a0,0x34
    8000371e:	4c650513          	addi	a0,a0,1222 # 80037be0 <bcache>
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	68c080e7          	jalr	1676(ra) # 80000dae <acquire>
  b->refcnt++;
    8000372a:	40bc                	lw	a5,64(s1)
    8000372c:	2785                	addiw	a5,a5,1
    8000372e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003730:	00034517          	auipc	a0,0x34
    80003734:	4b050513          	addi	a0,a0,1200 # 80037be0 <bcache>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	72a080e7          	jalr	1834(ra) # 80000e62 <release>
}
    80003740:	60e2                	ld	ra,24(sp)
    80003742:	6442                	ld	s0,16(sp)
    80003744:	64a2                	ld	s1,8(sp)
    80003746:	6105                	addi	sp,sp,32
    80003748:	8082                	ret

000000008000374a <bunpin>:

void
bunpin(struct buf *b) {
    8000374a:	1101                	addi	sp,sp,-32
    8000374c:	ec06                	sd	ra,24(sp)
    8000374e:	e822                	sd	s0,16(sp)
    80003750:	e426                	sd	s1,8(sp)
    80003752:	1000                	addi	s0,sp,32
    80003754:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003756:	00034517          	auipc	a0,0x34
    8000375a:	48a50513          	addi	a0,a0,1162 # 80037be0 <bcache>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	650080e7          	jalr	1616(ra) # 80000dae <acquire>
  b->refcnt--;
    80003766:	40bc                	lw	a5,64(s1)
    80003768:	37fd                	addiw	a5,a5,-1
    8000376a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000376c:	00034517          	auipc	a0,0x34
    80003770:	47450513          	addi	a0,a0,1140 # 80037be0 <bcache>
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	6ee080e7          	jalr	1774(ra) # 80000e62 <release>
}
    8000377c:	60e2                	ld	ra,24(sp)
    8000377e:	6442                	ld	s0,16(sp)
    80003780:	64a2                	ld	s1,8(sp)
    80003782:	6105                	addi	sp,sp,32
    80003784:	8082                	ret

0000000080003786 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003786:	1101                	addi	sp,sp,-32
    80003788:	ec06                	sd	ra,24(sp)
    8000378a:	e822                	sd	s0,16(sp)
    8000378c:	e426                	sd	s1,8(sp)
    8000378e:	e04a                	sd	s2,0(sp)
    80003790:	1000                	addi	s0,sp,32
    80003792:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003794:	00d5d59b          	srliw	a1,a1,0xd
    80003798:	0003d797          	auipc	a5,0x3d
    8000379c:	b247a783          	lw	a5,-1244(a5) # 800402bc <sb+0x1c>
    800037a0:	9dbd                	addw	a1,a1,a5
    800037a2:	00000097          	auipc	ra,0x0
    800037a6:	d9e080e7          	jalr	-610(ra) # 80003540 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800037aa:	0074f713          	andi	a4,s1,7
    800037ae:	4785                	li	a5,1
    800037b0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037b4:	14ce                	slli	s1,s1,0x33
    800037b6:	90d9                	srli	s1,s1,0x36
    800037b8:	00950733          	add	a4,a0,s1
    800037bc:	05874703          	lbu	a4,88(a4)
    800037c0:	00e7f6b3          	and	a3,a5,a4
    800037c4:	c69d                	beqz	a3,800037f2 <bfree+0x6c>
    800037c6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037c8:	94aa                	add	s1,s1,a0
    800037ca:	fff7c793          	not	a5,a5
    800037ce:	8f7d                	and	a4,a4,a5
    800037d0:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800037d4:	00001097          	auipc	ra,0x1
    800037d8:	126080e7          	jalr	294(ra) # 800048fa <log_write>
  brelse(bp);
    800037dc:	854a                	mv	a0,s2
    800037de:	00000097          	auipc	ra,0x0
    800037e2:	e92080e7          	jalr	-366(ra) # 80003670 <brelse>
}
    800037e6:	60e2                	ld	ra,24(sp)
    800037e8:	6442                	ld	s0,16(sp)
    800037ea:	64a2                	ld	s1,8(sp)
    800037ec:	6902                	ld	s2,0(sp)
    800037ee:	6105                	addi	sp,sp,32
    800037f0:	8082                	ret
    panic("freeing free block");
    800037f2:	00005517          	auipc	a0,0x5
    800037f6:	d7650513          	addi	a0,a0,-650 # 80008568 <syscalls+0x108>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	d46080e7          	jalr	-698(ra) # 80000540 <panic>

0000000080003802 <balloc>:
{
    80003802:	711d                	addi	sp,sp,-96
    80003804:	ec86                	sd	ra,88(sp)
    80003806:	e8a2                	sd	s0,80(sp)
    80003808:	e4a6                	sd	s1,72(sp)
    8000380a:	e0ca                	sd	s2,64(sp)
    8000380c:	fc4e                	sd	s3,56(sp)
    8000380e:	f852                	sd	s4,48(sp)
    80003810:	f456                	sd	s5,40(sp)
    80003812:	f05a                	sd	s6,32(sp)
    80003814:	ec5e                	sd	s7,24(sp)
    80003816:	e862                	sd	s8,16(sp)
    80003818:	e466                	sd	s9,8(sp)
    8000381a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000381c:	0003d797          	auipc	a5,0x3d
    80003820:	a887a783          	lw	a5,-1400(a5) # 800402a4 <sb+0x4>
    80003824:	cff5                	beqz	a5,80003920 <balloc+0x11e>
    80003826:	8baa                	mv	s7,a0
    80003828:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000382a:	0003db17          	auipc	s6,0x3d
    8000382e:	a76b0b13          	addi	s6,s6,-1418 # 800402a0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003832:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003834:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003836:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003838:	6c89                	lui	s9,0x2
    8000383a:	a061                	j	800038c2 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000383c:	97ca                	add	a5,a5,s2
    8000383e:	8e55                	or	a2,a2,a3
    80003840:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003844:	854a                	mv	a0,s2
    80003846:	00001097          	auipc	ra,0x1
    8000384a:	0b4080e7          	jalr	180(ra) # 800048fa <log_write>
        brelse(bp);
    8000384e:	854a                	mv	a0,s2
    80003850:	00000097          	auipc	ra,0x0
    80003854:	e20080e7          	jalr	-480(ra) # 80003670 <brelse>
  bp = bread(dev, bno);
    80003858:	85a6                	mv	a1,s1
    8000385a:	855e                	mv	a0,s7
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	ce4080e7          	jalr	-796(ra) # 80003540 <bread>
    80003864:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003866:	40000613          	li	a2,1024
    8000386a:	4581                	li	a1,0
    8000386c:	05850513          	addi	a0,a0,88
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	63a080e7          	jalr	1594(ra) # 80000eaa <memset>
  log_write(bp);
    80003878:	854a                	mv	a0,s2
    8000387a:	00001097          	auipc	ra,0x1
    8000387e:	080080e7          	jalr	128(ra) # 800048fa <log_write>
  brelse(bp);
    80003882:	854a                	mv	a0,s2
    80003884:	00000097          	auipc	ra,0x0
    80003888:	dec080e7          	jalr	-532(ra) # 80003670 <brelse>
}
    8000388c:	8526                	mv	a0,s1
    8000388e:	60e6                	ld	ra,88(sp)
    80003890:	6446                	ld	s0,80(sp)
    80003892:	64a6                	ld	s1,72(sp)
    80003894:	6906                	ld	s2,64(sp)
    80003896:	79e2                	ld	s3,56(sp)
    80003898:	7a42                	ld	s4,48(sp)
    8000389a:	7aa2                	ld	s5,40(sp)
    8000389c:	7b02                	ld	s6,32(sp)
    8000389e:	6be2                	ld	s7,24(sp)
    800038a0:	6c42                	ld	s8,16(sp)
    800038a2:	6ca2                	ld	s9,8(sp)
    800038a4:	6125                	addi	sp,sp,96
    800038a6:	8082                	ret
    brelse(bp);
    800038a8:	854a                	mv	a0,s2
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	dc6080e7          	jalr	-570(ra) # 80003670 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038b2:	015c87bb          	addw	a5,s9,s5
    800038b6:	00078a9b          	sext.w	s5,a5
    800038ba:	004b2703          	lw	a4,4(s6)
    800038be:	06eaf163          	bgeu	s5,a4,80003920 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800038c2:	41fad79b          	sraiw	a5,s5,0x1f
    800038c6:	0137d79b          	srliw	a5,a5,0x13
    800038ca:	015787bb          	addw	a5,a5,s5
    800038ce:	40d7d79b          	sraiw	a5,a5,0xd
    800038d2:	01cb2583          	lw	a1,28(s6)
    800038d6:	9dbd                	addw	a1,a1,a5
    800038d8:	855e                	mv	a0,s7
    800038da:	00000097          	auipc	ra,0x0
    800038de:	c66080e7          	jalr	-922(ra) # 80003540 <bread>
    800038e2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038e4:	004b2503          	lw	a0,4(s6)
    800038e8:	000a849b          	sext.w	s1,s5
    800038ec:	8762                	mv	a4,s8
    800038ee:	faa4fde3          	bgeu	s1,a0,800038a8 <balloc+0xa6>
      m = 1 << (bi % 8);
    800038f2:	00777693          	andi	a3,a4,7
    800038f6:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800038fa:	41f7579b          	sraiw	a5,a4,0x1f
    800038fe:	01d7d79b          	srliw	a5,a5,0x1d
    80003902:	9fb9                	addw	a5,a5,a4
    80003904:	4037d79b          	sraiw	a5,a5,0x3
    80003908:	00f90633          	add	a2,s2,a5
    8000390c:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003910:	00c6f5b3          	and	a1,a3,a2
    80003914:	d585                	beqz	a1,8000383c <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003916:	2705                	addiw	a4,a4,1
    80003918:	2485                	addiw	s1,s1,1
    8000391a:	fd471ae3          	bne	a4,s4,800038ee <balloc+0xec>
    8000391e:	b769                	j	800038a8 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003920:	00005517          	auipc	a0,0x5
    80003924:	c6050513          	addi	a0,a0,-928 # 80008580 <syscalls+0x120>
    80003928:	ffffd097          	auipc	ra,0xffffd
    8000392c:	c62080e7          	jalr	-926(ra) # 8000058a <printf>
  return 0;
    80003930:	4481                	li	s1,0
    80003932:	bfa9                	j	8000388c <balloc+0x8a>

0000000080003934 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003934:	7179                	addi	sp,sp,-48
    80003936:	f406                	sd	ra,40(sp)
    80003938:	f022                	sd	s0,32(sp)
    8000393a:	ec26                	sd	s1,24(sp)
    8000393c:	e84a                	sd	s2,16(sp)
    8000393e:	e44e                	sd	s3,8(sp)
    80003940:	e052                	sd	s4,0(sp)
    80003942:	1800                	addi	s0,sp,48
    80003944:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003946:	47ad                	li	a5,11
    80003948:	02b7e863          	bltu	a5,a1,80003978 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000394c:	02059793          	slli	a5,a1,0x20
    80003950:	01e7d593          	srli	a1,a5,0x1e
    80003954:	00b504b3          	add	s1,a0,a1
    80003958:	0504a903          	lw	s2,80(s1)
    8000395c:	06091e63          	bnez	s2,800039d8 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003960:	4108                	lw	a0,0(a0)
    80003962:	00000097          	auipc	ra,0x0
    80003966:	ea0080e7          	jalr	-352(ra) # 80003802 <balloc>
    8000396a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000396e:	06090563          	beqz	s2,800039d8 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003972:	0524a823          	sw	s2,80(s1)
    80003976:	a08d                	j	800039d8 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003978:	ff45849b          	addiw	s1,a1,-12
    8000397c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003980:	0ff00793          	li	a5,255
    80003984:	08e7e563          	bltu	a5,a4,80003a0e <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003988:	08052903          	lw	s2,128(a0)
    8000398c:	00091d63          	bnez	s2,800039a6 <bmap+0x72>
      addr = balloc(ip->dev);
    80003990:	4108                	lw	a0,0(a0)
    80003992:	00000097          	auipc	ra,0x0
    80003996:	e70080e7          	jalr	-400(ra) # 80003802 <balloc>
    8000399a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000399e:	02090d63          	beqz	s2,800039d8 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800039a2:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800039a6:	85ca                	mv	a1,s2
    800039a8:	0009a503          	lw	a0,0(s3)
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	b94080e7          	jalr	-1132(ra) # 80003540 <bread>
    800039b4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800039b6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800039ba:	02049713          	slli	a4,s1,0x20
    800039be:	01e75593          	srli	a1,a4,0x1e
    800039c2:	00b784b3          	add	s1,a5,a1
    800039c6:	0004a903          	lw	s2,0(s1)
    800039ca:	02090063          	beqz	s2,800039ea <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800039ce:	8552                	mv	a0,s4
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	ca0080e7          	jalr	-864(ra) # 80003670 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800039d8:	854a                	mv	a0,s2
    800039da:	70a2                	ld	ra,40(sp)
    800039dc:	7402                	ld	s0,32(sp)
    800039de:	64e2                	ld	s1,24(sp)
    800039e0:	6942                	ld	s2,16(sp)
    800039e2:	69a2                	ld	s3,8(sp)
    800039e4:	6a02                	ld	s4,0(sp)
    800039e6:	6145                	addi	sp,sp,48
    800039e8:	8082                	ret
      addr = balloc(ip->dev);
    800039ea:	0009a503          	lw	a0,0(s3)
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	e14080e7          	jalr	-492(ra) # 80003802 <balloc>
    800039f6:	0005091b          	sext.w	s2,a0
      if(addr){
    800039fa:	fc090ae3          	beqz	s2,800039ce <bmap+0x9a>
        a[bn] = addr;
    800039fe:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a02:	8552                	mv	a0,s4
    80003a04:	00001097          	auipc	ra,0x1
    80003a08:	ef6080e7          	jalr	-266(ra) # 800048fa <log_write>
    80003a0c:	b7c9                	j	800039ce <bmap+0x9a>
  panic("bmap: out of range");
    80003a0e:	00005517          	auipc	a0,0x5
    80003a12:	b8a50513          	addi	a0,a0,-1142 # 80008598 <syscalls+0x138>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	b2a080e7          	jalr	-1238(ra) # 80000540 <panic>

0000000080003a1e <iget>:
{
    80003a1e:	7179                	addi	sp,sp,-48
    80003a20:	f406                	sd	ra,40(sp)
    80003a22:	f022                	sd	s0,32(sp)
    80003a24:	ec26                	sd	s1,24(sp)
    80003a26:	e84a                	sd	s2,16(sp)
    80003a28:	e44e                	sd	s3,8(sp)
    80003a2a:	e052                	sd	s4,0(sp)
    80003a2c:	1800                	addi	s0,sp,48
    80003a2e:	89aa                	mv	s3,a0
    80003a30:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a32:	0003d517          	auipc	a0,0x3d
    80003a36:	88e50513          	addi	a0,a0,-1906 # 800402c0 <itable>
    80003a3a:	ffffd097          	auipc	ra,0xffffd
    80003a3e:	374080e7          	jalr	884(ra) # 80000dae <acquire>
  empty = 0;
    80003a42:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a44:	0003d497          	auipc	s1,0x3d
    80003a48:	89448493          	addi	s1,s1,-1900 # 800402d8 <itable+0x18>
    80003a4c:	0003e697          	auipc	a3,0x3e
    80003a50:	31c68693          	addi	a3,a3,796 # 80041d68 <log>
    80003a54:	a039                	j	80003a62 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a56:	02090b63          	beqz	s2,80003a8c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a5a:	08848493          	addi	s1,s1,136
    80003a5e:	02d48a63          	beq	s1,a3,80003a92 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a62:	449c                	lw	a5,8(s1)
    80003a64:	fef059e3          	blez	a5,80003a56 <iget+0x38>
    80003a68:	4098                	lw	a4,0(s1)
    80003a6a:	ff3716e3          	bne	a4,s3,80003a56 <iget+0x38>
    80003a6e:	40d8                	lw	a4,4(s1)
    80003a70:	ff4713e3          	bne	a4,s4,80003a56 <iget+0x38>
      ip->ref++;
    80003a74:	2785                	addiw	a5,a5,1
    80003a76:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a78:	0003d517          	auipc	a0,0x3d
    80003a7c:	84850513          	addi	a0,a0,-1976 # 800402c0 <itable>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	3e2080e7          	jalr	994(ra) # 80000e62 <release>
      return ip;
    80003a88:	8926                	mv	s2,s1
    80003a8a:	a03d                	j	80003ab8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a8c:	f7f9                	bnez	a5,80003a5a <iget+0x3c>
    80003a8e:	8926                	mv	s2,s1
    80003a90:	b7e9                	j	80003a5a <iget+0x3c>
  if(empty == 0)
    80003a92:	02090c63          	beqz	s2,80003aca <iget+0xac>
  ip->dev = dev;
    80003a96:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a9a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a9e:	4785                	li	a5,1
    80003aa0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003aa4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003aa8:	0003d517          	auipc	a0,0x3d
    80003aac:	81850513          	addi	a0,a0,-2024 # 800402c0 <itable>
    80003ab0:	ffffd097          	auipc	ra,0xffffd
    80003ab4:	3b2080e7          	jalr	946(ra) # 80000e62 <release>
}
    80003ab8:	854a                	mv	a0,s2
    80003aba:	70a2                	ld	ra,40(sp)
    80003abc:	7402                	ld	s0,32(sp)
    80003abe:	64e2                	ld	s1,24(sp)
    80003ac0:	6942                	ld	s2,16(sp)
    80003ac2:	69a2                	ld	s3,8(sp)
    80003ac4:	6a02                	ld	s4,0(sp)
    80003ac6:	6145                	addi	sp,sp,48
    80003ac8:	8082                	ret
    panic("iget: no inodes");
    80003aca:	00005517          	auipc	a0,0x5
    80003ace:	ae650513          	addi	a0,a0,-1306 # 800085b0 <syscalls+0x150>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	a6e080e7          	jalr	-1426(ra) # 80000540 <panic>

0000000080003ada <fsinit>:
fsinit(int dev) {
    80003ada:	7179                	addi	sp,sp,-48
    80003adc:	f406                	sd	ra,40(sp)
    80003ade:	f022                	sd	s0,32(sp)
    80003ae0:	ec26                	sd	s1,24(sp)
    80003ae2:	e84a                	sd	s2,16(sp)
    80003ae4:	e44e                	sd	s3,8(sp)
    80003ae6:	1800                	addi	s0,sp,48
    80003ae8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003aea:	4585                	li	a1,1
    80003aec:	00000097          	auipc	ra,0x0
    80003af0:	a54080e7          	jalr	-1452(ra) # 80003540 <bread>
    80003af4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003af6:	0003c997          	auipc	s3,0x3c
    80003afa:	7aa98993          	addi	s3,s3,1962 # 800402a0 <sb>
    80003afe:	02000613          	li	a2,32
    80003b02:	05850593          	addi	a1,a0,88
    80003b06:	854e                	mv	a0,s3
    80003b08:	ffffd097          	auipc	ra,0xffffd
    80003b0c:	3fe080e7          	jalr	1022(ra) # 80000f06 <memmove>
  brelse(bp);
    80003b10:	8526                	mv	a0,s1
    80003b12:	00000097          	auipc	ra,0x0
    80003b16:	b5e080e7          	jalr	-1186(ra) # 80003670 <brelse>
  if(sb.magic != FSMAGIC)
    80003b1a:	0009a703          	lw	a4,0(s3)
    80003b1e:	102037b7          	lui	a5,0x10203
    80003b22:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b26:	02f71263          	bne	a4,a5,80003b4a <fsinit+0x70>
  initlog(dev, &sb);
    80003b2a:	0003c597          	auipc	a1,0x3c
    80003b2e:	77658593          	addi	a1,a1,1910 # 800402a0 <sb>
    80003b32:	854a                	mv	a0,s2
    80003b34:	00001097          	auipc	ra,0x1
    80003b38:	b4a080e7          	jalr	-1206(ra) # 8000467e <initlog>
}
    80003b3c:	70a2                	ld	ra,40(sp)
    80003b3e:	7402                	ld	s0,32(sp)
    80003b40:	64e2                	ld	s1,24(sp)
    80003b42:	6942                	ld	s2,16(sp)
    80003b44:	69a2                	ld	s3,8(sp)
    80003b46:	6145                	addi	sp,sp,48
    80003b48:	8082                	ret
    panic("invalid file system");
    80003b4a:	00005517          	auipc	a0,0x5
    80003b4e:	a7650513          	addi	a0,a0,-1418 # 800085c0 <syscalls+0x160>
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	9ee080e7          	jalr	-1554(ra) # 80000540 <panic>

0000000080003b5a <iinit>:
{
    80003b5a:	7179                	addi	sp,sp,-48
    80003b5c:	f406                	sd	ra,40(sp)
    80003b5e:	f022                	sd	s0,32(sp)
    80003b60:	ec26                	sd	s1,24(sp)
    80003b62:	e84a                	sd	s2,16(sp)
    80003b64:	e44e                	sd	s3,8(sp)
    80003b66:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b68:	00005597          	auipc	a1,0x5
    80003b6c:	a7058593          	addi	a1,a1,-1424 # 800085d8 <syscalls+0x178>
    80003b70:	0003c517          	auipc	a0,0x3c
    80003b74:	75050513          	addi	a0,a0,1872 # 800402c0 <itable>
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	1a6080e7          	jalr	422(ra) # 80000d1e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b80:	0003c497          	auipc	s1,0x3c
    80003b84:	76848493          	addi	s1,s1,1896 # 800402e8 <itable+0x28>
    80003b88:	0003e997          	auipc	s3,0x3e
    80003b8c:	1f098993          	addi	s3,s3,496 # 80041d78 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b90:	00005917          	auipc	s2,0x5
    80003b94:	a5090913          	addi	s2,s2,-1456 # 800085e0 <syscalls+0x180>
    80003b98:	85ca                	mv	a1,s2
    80003b9a:	8526                	mv	a0,s1
    80003b9c:	00001097          	auipc	ra,0x1
    80003ba0:	e42080e7          	jalr	-446(ra) # 800049de <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ba4:	08848493          	addi	s1,s1,136
    80003ba8:	ff3498e3          	bne	s1,s3,80003b98 <iinit+0x3e>
}
    80003bac:	70a2                	ld	ra,40(sp)
    80003bae:	7402                	ld	s0,32(sp)
    80003bb0:	64e2                	ld	s1,24(sp)
    80003bb2:	6942                	ld	s2,16(sp)
    80003bb4:	69a2                	ld	s3,8(sp)
    80003bb6:	6145                	addi	sp,sp,48
    80003bb8:	8082                	ret

0000000080003bba <ialloc>:
{
    80003bba:	715d                	addi	sp,sp,-80
    80003bbc:	e486                	sd	ra,72(sp)
    80003bbe:	e0a2                	sd	s0,64(sp)
    80003bc0:	fc26                	sd	s1,56(sp)
    80003bc2:	f84a                	sd	s2,48(sp)
    80003bc4:	f44e                	sd	s3,40(sp)
    80003bc6:	f052                	sd	s4,32(sp)
    80003bc8:	ec56                	sd	s5,24(sp)
    80003bca:	e85a                	sd	s6,16(sp)
    80003bcc:	e45e                	sd	s7,8(sp)
    80003bce:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bd0:	0003c717          	auipc	a4,0x3c
    80003bd4:	6dc72703          	lw	a4,1756(a4) # 800402ac <sb+0xc>
    80003bd8:	4785                	li	a5,1
    80003bda:	04e7fa63          	bgeu	a5,a4,80003c2e <ialloc+0x74>
    80003bde:	8aaa                	mv	s5,a0
    80003be0:	8bae                	mv	s7,a1
    80003be2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003be4:	0003ca17          	auipc	s4,0x3c
    80003be8:	6bca0a13          	addi	s4,s4,1724 # 800402a0 <sb>
    80003bec:	00048b1b          	sext.w	s6,s1
    80003bf0:	0044d593          	srli	a1,s1,0x4
    80003bf4:	018a2783          	lw	a5,24(s4)
    80003bf8:	9dbd                	addw	a1,a1,a5
    80003bfa:	8556                	mv	a0,s5
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	944080e7          	jalr	-1724(ra) # 80003540 <bread>
    80003c04:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c06:	05850993          	addi	s3,a0,88
    80003c0a:	00f4f793          	andi	a5,s1,15
    80003c0e:	079a                	slli	a5,a5,0x6
    80003c10:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c12:	00099783          	lh	a5,0(s3)
    80003c16:	c3a1                	beqz	a5,80003c56 <ialloc+0x9c>
    brelse(bp);
    80003c18:	00000097          	auipc	ra,0x0
    80003c1c:	a58080e7          	jalr	-1448(ra) # 80003670 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c20:	0485                	addi	s1,s1,1
    80003c22:	00ca2703          	lw	a4,12(s4)
    80003c26:	0004879b          	sext.w	a5,s1
    80003c2a:	fce7e1e3          	bltu	a5,a4,80003bec <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003c2e:	00005517          	auipc	a0,0x5
    80003c32:	9ba50513          	addi	a0,a0,-1606 # 800085e8 <syscalls+0x188>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	954080e7          	jalr	-1708(ra) # 8000058a <printf>
  return 0;
    80003c3e:	4501                	li	a0,0
}
    80003c40:	60a6                	ld	ra,72(sp)
    80003c42:	6406                	ld	s0,64(sp)
    80003c44:	74e2                	ld	s1,56(sp)
    80003c46:	7942                	ld	s2,48(sp)
    80003c48:	79a2                	ld	s3,40(sp)
    80003c4a:	7a02                	ld	s4,32(sp)
    80003c4c:	6ae2                	ld	s5,24(sp)
    80003c4e:	6b42                	ld	s6,16(sp)
    80003c50:	6ba2                	ld	s7,8(sp)
    80003c52:	6161                	addi	sp,sp,80
    80003c54:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003c56:	04000613          	li	a2,64
    80003c5a:	4581                	li	a1,0
    80003c5c:	854e                	mv	a0,s3
    80003c5e:	ffffd097          	auipc	ra,0xffffd
    80003c62:	24c080e7          	jalr	588(ra) # 80000eaa <memset>
      dip->type = type;
    80003c66:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c6a:	854a                	mv	a0,s2
    80003c6c:	00001097          	auipc	ra,0x1
    80003c70:	c8e080e7          	jalr	-882(ra) # 800048fa <log_write>
      brelse(bp);
    80003c74:	854a                	mv	a0,s2
    80003c76:	00000097          	auipc	ra,0x0
    80003c7a:	9fa080e7          	jalr	-1542(ra) # 80003670 <brelse>
      return iget(dev, inum);
    80003c7e:	85da                	mv	a1,s6
    80003c80:	8556                	mv	a0,s5
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	d9c080e7          	jalr	-612(ra) # 80003a1e <iget>
    80003c8a:	bf5d                	j	80003c40 <ialloc+0x86>

0000000080003c8c <iupdate>:
{
    80003c8c:	1101                	addi	sp,sp,-32
    80003c8e:	ec06                	sd	ra,24(sp)
    80003c90:	e822                	sd	s0,16(sp)
    80003c92:	e426                	sd	s1,8(sp)
    80003c94:	e04a                	sd	s2,0(sp)
    80003c96:	1000                	addi	s0,sp,32
    80003c98:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c9a:	415c                	lw	a5,4(a0)
    80003c9c:	0047d79b          	srliw	a5,a5,0x4
    80003ca0:	0003c597          	auipc	a1,0x3c
    80003ca4:	6185a583          	lw	a1,1560(a1) # 800402b8 <sb+0x18>
    80003ca8:	9dbd                	addw	a1,a1,a5
    80003caa:	4108                	lw	a0,0(a0)
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	894080e7          	jalr	-1900(ra) # 80003540 <bread>
    80003cb4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cb6:	05850793          	addi	a5,a0,88
    80003cba:	40d8                	lw	a4,4(s1)
    80003cbc:	8b3d                	andi	a4,a4,15
    80003cbe:	071a                	slli	a4,a4,0x6
    80003cc0:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003cc2:	04449703          	lh	a4,68(s1)
    80003cc6:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003cca:	04649703          	lh	a4,70(s1)
    80003cce:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003cd2:	04849703          	lh	a4,72(s1)
    80003cd6:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003cda:	04a49703          	lh	a4,74(s1)
    80003cde:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003ce2:	44f8                	lw	a4,76(s1)
    80003ce4:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ce6:	03400613          	li	a2,52
    80003cea:	05048593          	addi	a1,s1,80
    80003cee:	00c78513          	addi	a0,a5,12
    80003cf2:	ffffd097          	auipc	ra,0xffffd
    80003cf6:	214080e7          	jalr	532(ra) # 80000f06 <memmove>
  log_write(bp);
    80003cfa:	854a                	mv	a0,s2
    80003cfc:	00001097          	auipc	ra,0x1
    80003d00:	bfe080e7          	jalr	-1026(ra) # 800048fa <log_write>
  brelse(bp);
    80003d04:	854a                	mv	a0,s2
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	96a080e7          	jalr	-1686(ra) # 80003670 <brelse>
}
    80003d0e:	60e2                	ld	ra,24(sp)
    80003d10:	6442                	ld	s0,16(sp)
    80003d12:	64a2                	ld	s1,8(sp)
    80003d14:	6902                	ld	s2,0(sp)
    80003d16:	6105                	addi	sp,sp,32
    80003d18:	8082                	ret

0000000080003d1a <idup>:
{
    80003d1a:	1101                	addi	sp,sp,-32
    80003d1c:	ec06                	sd	ra,24(sp)
    80003d1e:	e822                	sd	s0,16(sp)
    80003d20:	e426                	sd	s1,8(sp)
    80003d22:	1000                	addi	s0,sp,32
    80003d24:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d26:	0003c517          	auipc	a0,0x3c
    80003d2a:	59a50513          	addi	a0,a0,1434 # 800402c0 <itable>
    80003d2e:	ffffd097          	auipc	ra,0xffffd
    80003d32:	080080e7          	jalr	128(ra) # 80000dae <acquire>
  ip->ref++;
    80003d36:	449c                	lw	a5,8(s1)
    80003d38:	2785                	addiw	a5,a5,1
    80003d3a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d3c:	0003c517          	auipc	a0,0x3c
    80003d40:	58450513          	addi	a0,a0,1412 # 800402c0 <itable>
    80003d44:	ffffd097          	auipc	ra,0xffffd
    80003d48:	11e080e7          	jalr	286(ra) # 80000e62 <release>
}
    80003d4c:	8526                	mv	a0,s1
    80003d4e:	60e2                	ld	ra,24(sp)
    80003d50:	6442                	ld	s0,16(sp)
    80003d52:	64a2                	ld	s1,8(sp)
    80003d54:	6105                	addi	sp,sp,32
    80003d56:	8082                	ret

0000000080003d58 <ilock>:
{
    80003d58:	1101                	addi	sp,sp,-32
    80003d5a:	ec06                	sd	ra,24(sp)
    80003d5c:	e822                	sd	s0,16(sp)
    80003d5e:	e426                	sd	s1,8(sp)
    80003d60:	e04a                	sd	s2,0(sp)
    80003d62:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d64:	c115                	beqz	a0,80003d88 <ilock+0x30>
    80003d66:	84aa                	mv	s1,a0
    80003d68:	451c                	lw	a5,8(a0)
    80003d6a:	00f05f63          	blez	a5,80003d88 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d6e:	0541                	addi	a0,a0,16
    80003d70:	00001097          	auipc	ra,0x1
    80003d74:	ca8080e7          	jalr	-856(ra) # 80004a18 <acquiresleep>
  if(ip->valid == 0){
    80003d78:	40bc                	lw	a5,64(s1)
    80003d7a:	cf99                	beqz	a5,80003d98 <ilock+0x40>
}
    80003d7c:	60e2                	ld	ra,24(sp)
    80003d7e:	6442                	ld	s0,16(sp)
    80003d80:	64a2                	ld	s1,8(sp)
    80003d82:	6902                	ld	s2,0(sp)
    80003d84:	6105                	addi	sp,sp,32
    80003d86:	8082                	ret
    panic("ilock");
    80003d88:	00005517          	auipc	a0,0x5
    80003d8c:	87850513          	addi	a0,a0,-1928 # 80008600 <syscalls+0x1a0>
    80003d90:	ffffc097          	auipc	ra,0xffffc
    80003d94:	7b0080e7          	jalr	1968(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d98:	40dc                	lw	a5,4(s1)
    80003d9a:	0047d79b          	srliw	a5,a5,0x4
    80003d9e:	0003c597          	auipc	a1,0x3c
    80003da2:	51a5a583          	lw	a1,1306(a1) # 800402b8 <sb+0x18>
    80003da6:	9dbd                	addw	a1,a1,a5
    80003da8:	4088                	lw	a0,0(s1)
    80003daa:	fffff097          	auipc	ra,0xfffff
    80003dae:	796080e7          	jalr	1942(ra) # 80003540 <bread>
    80003db2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003db4:	05850593          	addi	a1,a0,88
    80003db8:	40dc                	lw	a5,4(s1)
    80003dba:	8bbd                	andi	a5,a5,15
    80003dbc:	079a                	slli	a5,a5,0x6
    80003dbe:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003dc0:	00059783          	lh	a5,0(a1)
    80003dc4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003dc8:	00259783          	lh	a5,2(a1)
    80003dcc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003dd0:	00459783          	lh	a5,4(a1)
    80003dd4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003dd8:	00659783          	lh	a5,6(a1)
    80003ddc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003de0:	459c                	lw	a5,8(a1)
    80003de2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003de4:	03400613          	li	a2,52
    80003de8:	05b1                	addi	a1,a1,12
    80003dea:	05048513          	addi	a0,s1,80
    80003dee:	ffffd097          	auipc	ra,0xffffd
    80003df2:	118080e7          	jalr	280(ra) # 80000f06 <memmove>
    brelse(bp);
    80003df6:	854a                	mv	a0,s2
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	878080e7          	jalr	-1928(ra) # 80003670 <brelse>
    ip->valid = 1;
    80003e00:	4785                	li	a5,1
    80003e02:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e04:	04449783          	lh	a5,68(s1)
    80003e08:	fbb5                	bnez	a5,80003d7c <ilock+0x24>
      panic("ilock: no type");
    80003e0a:	00004517          	auipc	a0,0x4
    80003e0e:	7fe50513          	addi	a0,a0,2046 # 80008608 <syscalls+0x1a8>
    80003e12:	ffffc097          	auipc	ra,0xffffc
    80003e16:	72e080e7          	jalr	1838(ra) # 80000540 <panic>

0000000080003e1a <iunlock>:
{
    80003e1a:	1101                	addi	sp,sp,-32
    80003e1c:	ec06                	sd	ra,24(sp)
    80003e1e:	e822                	sd	s0,16(sp)
    80003e20:	e426                	sd	s1,8(sp)
    80003e22:	e04a                	sd	s2,0(sp)
    80003e24:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e26:	c905                	beqz	a0,80003e56 <iunlock+0x3c>
    80003e28:	84aa                	mv	s1,a0
    80003e2a:	01050913          	addi	s2,a0,16
    80003e2e:	854a                	mv	a0,s2
    80003e30:	00001097          	auipc	ra,0x1
    80003e34:	c82080e7          	jalr	-894(ra) # 80004ab2 <holdingsleep>
    80003e38:	cd19                	beqz	a0,80003e56 <iunlock+0x3c>
    80003e3a:	449c                	lw	a5,8(s1)
    80003e3c:	00f05d63          	blez	a5,80003e56 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e40:	854a                	mv	a0,s2
    80003e42:	00001097          	auipc	ra,0x1
    80003e46:	c2c080e7          	jalr	-980(ra) # 80004a6e <releasesleep>
}
    80003e4a:	60e2                	ld	ra,24(sp)
    80003e4c:	6442                	ld	s0,16(sp)
    80003e4e:	64a2                	ld	s1,8(sp)
    80003e50:	6902                	ld	s2,0(sp)
    80003e52:	6105                	addi	sp,sp,32
    80003e54:	8082                	ret
    panic("iunlock");
    80003e56:	00004517          	auipc	a0,0x4
    80003e5a:	7c250513          	addi	a0,a0,1986 # 80008618 <syscalls+0x1b8>
    80003e5e:	ffffc097          	auipc	ra,0xffffc
    80003e62:	6e2080e7          	jalr	1762(ra) # 80000540 <panic>

0000000080003e66 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e66:	7179                	addi	sp,sp,-48
    80003e68:	f406                	sd	ra,40(sp)
    80003e6a:	f022                	sd	s0,32(sp)
    80003e6c:	ec26                	sd	s1,24(sp)
    80003e6e:	e84a                	sd	s2,16(sp)
    80003e70:	e44e                	sd	s3,8(sp)
    80003e72:	e052                	sd	s4,0(sp)
    80003e74:	1800                	addi	s0,sp,48
    80003e76:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e78:	05050493          	addi	s1,a0,80
    80003e7c:	08050913          	addi	s2,a0,128
    80003e80:	a021                	j	80003e88 <itrunc+0x22>
    80003e82:	0491                	addi	s1,s1,4
    80003e84:	01248d63          	beq	s1,s2,80003e9e <itrunc+0x38>
    if(ip->addrs[i]){
    80003e88:	408c                	lw	a1,0(s1)
    80003e8a:	dde5                	beqz	a1,80003e82 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e8c:	0009a503          	lw	a0,0(s3)
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	8f6080e7          	jalr	-1802(ra) # 80003786 <bfree>
      ip->addrs[i] = 0;
    80003e98:	0004a023          	sw	zero,0(s1)
    80003e9c:	b7dd                	j	80003e82 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e9e:	0809a583          	lw	a1,128(s3)
    80003ea2:	e185                	bnez	a1,80003ec2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ea4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ea8:	854e                	mv	a0,s3
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	de2080e7          	jalr	-542(ra) # 80003c8c <iupdate>
}
    80003eb2:	70a2                	ld	ra,40(sp)
    80003eb4:	7402                	ld	s0,32(sp)
    80003eb6:	64e2                	ld	s1,24(sp)
    80003eb8:	6942                	ld	s2,16(sp)
    80003eba:	69a2                	ld	s3,8(sp)
    80003ebc:	6a02                	ld	s4,0(sp)
    80003ebe:	6145                	addi	sp,sp,48
    80003ec0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ec2:	0009a503          	lw	a0,0(s3)
    80003ec6:	fffff097          	auipc	ra,0xfffff
    80003eca:	67a080e7          	jalr	1658(ra) # 80003540 <bread>
    80003ece:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ed0:	05850493          	addi	s1,a0,88
    80003ed4:	45850913          	addi	s2,a0,1112
    80003ed8:	a021                	j	80003ee0 <itrunc+0x7a>
    80003eda:	0491                	addi	s1,s1,4
    80003edc:	01248b63          	beq	s1,s2,80003ef2 <itrunc+0x8c>
      if(a[j])
    80003ee0:	408c                	lw	a1,0(s1)
    80003ee2:	dde5                	beqz	a1,80003eda <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003ee4:	0009a503          	lw	a0,0(s3)
    80003ee8:	00000097          	auipc	ra,0x0
    80003eec:	89e080e7          	jalr	-1890(ra) # 80003786 <bfree>
    80003ef0:	b7ed                	j	80003eda <itrunc+0x74>
    brelse(bp);
    80003ef2:	8552                	mv	a0,s4
    80003ef4:	fffff097          	auipc	ra,0xfffff
    80003ef8:	77c080e7          	jalr	1916(ra) # 80003670 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003efc:	0809a583          	lw	a1,128(s3)
    80003f00:	0009a503          	lw	a0,0(s3)
    80003f04:	00000097          	auipc	ra,0x0
    80003f08:	882080e7          	jalr	-1918(ra) # 80003786 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f0c:	0809a023          	sw	zero,128(s3)
    80003f10:	bf51                	j	80003ea4 <itrunc+0x3e>

0000000080003f12 <iput>:
{
    80003f12:	1101                	addi	sp,sp,-32
    80003f14:	ec06                	sd	ra,24(sp)
    80003f16:	e822                	sd	s0,16(sp)
    80003f18:	e426                	sd	s1,8(sp)
    80003f1a:	e04a                	sd	s2,0(sp)
    80003f1c:	1000                	addi	s0,sp,32
    80003f1e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f20:	0003c517          	auipc	a0,0x3c
    80003f24:	3a050513          	addi	a0,a0,928 # 800402c0 <itable>
    80003f28:	ffffd097          	auipc	ra,0xffffd
    80003f2c:	e86080e7          	jalr	-378(ra) # 80000dae <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f30:	4498                	lw	a4,8(s1)
    80003f32:	4785                	li	a5,1
    80003f34:	02f70363          	beq	a4,a5,80003f5a <iput+0x48>
  ip->ref--;
    80003f38:	449c                	lw	a5,8(s1)
    80003f3a:	37fd                	addiw	a5,a5,-1
    80003f3c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f3e:	0003c517          	auipc	a0,0x3c
    80003f42:	38250513          	addi	a0,a0,898 # 800402c0 <itable>
    80003f46:	ffffd097          	auipc	ra,0xffffd
    80003f4a:	f1c080e7          	jalr	-228(ra) # 80000e62 <release>
}
    80003f4e:	60e2                	ld	ra,24(sp)
    80003f50:	6442                	ld	s0,16(sp)
    80003f52:	64a2                	ld	s1,8(sp)
    80003f54:	6902                	ld	s2,0(sp)
    80003f56:	6105                	addi	sp,sp,32
    80003f58:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f5a:	40bc                	lw	a5,64(s1)
    80003f5c:	dff1                	beqz	a5,80003f38 <iput+0x26>
    80003f5e:	04a49783          	lh	a5,74(s1)
    80003f62:	fbf9                	bnez	a5,80003f38 <iput+0x26>
    acquiresleep(&ip->lock);
    80003f64:	01048913          	addi	s2,s1,16
    80003f68:	854a                	mv	a0,s2
    80003f6a:	00001097          	auipc	ra,0x1
    80003f6e:	aae080e7          	jalr	-1362(ra) # 80004a18 <acquiresleep>
    release(&itable.lock);
    80003f72:	0003c517          	auipc	a0,0x3c
    80003f76:	34e50513          	addi	a0,a0,846 # 800402c0 <itable>
    80003f7a:	ffffd097          	auipc	ra,0xffffd
    80003f7e:	ee8080e7          	jalr	-280(ra) # 80000e62 <release>
    itrunc(ip);
    80003f82:	8526                	mv	a0,s1
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	ee2080e7          	jalr	-286(ra) # 80003e66 <itrunc>
    ip->type = 0;
    80003f8c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f90:	8526                	mv	a0,s1
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	cfa080e7          	jalr	-774(ra) # 80003c8c <iupdate>
    ip->valid = 0;
    80003f9a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f9e:	854a                	mv	a0,s2
    80003fa0:	00001097          	auipc	ra,0x1
    80003fa4:	ace080e7          	jalr	-1330(ra) # 80004a6e <releasesleep>
    acquire(&itable.lock);
    80003fa8:	0003c517          	auipc	a0,0x3c
    80003fac:	31850513          	addi	a0,a0,792 # 800402c0 <itable>
    80003fb0:	ffffd097          	auipc	ra,0xffffd
    80003fb4:	dfe080e7          	jalr	-514(ra) # 80000dae <acquire>
    80003fb8:	b741                	j	80003f38 <iput+0x26>

0000000080003fba <iunlockput>:
{
    80003fba:	1101                	addi	sp,sp,-32
    80003fbc:	ec06                	sd	ra,24(sp)
    80003fbe:	e822                	sd	s0,16(sp)
    80003fc0:	e426                	sd	s1,8(sp)
    80003fc2:	1000                	addi	s0,sp,32
    80003fc4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	e54080e7          	jalr	-428(ra) # 80003e1a <iunlock>
  iput(ip);
    80003fce:	8526                	mv	a0,s1
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	f42080e7          	jalr	-190(ra) # 80003f12 <iput>
}
    80003fd8:	60e2                	ld	ra,24(sp)
    80003fda:	6442                	ld	s0,16(sp)
    80003fdc:	64a2                	ld	s1,8(sp)
    80003fde:	6105                	addi	sp,sp,32
    80003fe0:	8082                	ret

0000000080003fe2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fe2:	1141                	addi	sp,sp,-16
    80003fe4:	e422                	sd	s0,8(sp)
    80003fe6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fe8:	411c                	lw	a5,0(a0)
    80003fea:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fec:	415c                	lw	a5,4(a0)
    80003fee:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ff0:	04451783          	lh	a5,68(a0)
    80003ff4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ff8:	04a51783          	lh	a5,74(a0)
    80003ffc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004000:	04c56783          	lwu	a5,76(a0)
    80004004:	e99c                	sd	a5,16(a1)
}
    80004006:	6422                	ld	s0,8(sp)
    80004008:	0141                	addi	sp,sp,16
    8000400a:	8082                	ret

000000008000400c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000400c:	457c                	lw	a5,76(a0)
    8000400e:	0ed7e963          	bltu	a5,a3,80004100 <readi+0xf4>
{
    80004012:	7159                	addi	sp,sp,-112
    80004014:	f486                	sd	ra,104(sp)
    80004016:	f0a2                	sd	s0,96(sp)
    80004018:	eca6                	sd	s1,88(sp)
    8000401a:	e8ca                	sd	s2,80(sp)
    8000401c:	e4ce                	sd	s3,72(sp)
    8000401e:	e0d2                	sd	s4,64(sp)
    80004020:	fc56                	sd	s5,56(sp)
    80004022:	f85a                	sd	s6,48(sp)
    80004024:	f45e                	sd	s7,40(sp)
    80004026:	f062                	sd	s8,32(sp)
    80004028:	ec66                	sd	s9,24(sp)
    8000402a:	e86a                	sd	s10,16(sp)
    8000402c:	e46e                	sd	s11,8(sp)
    8000402e:	1880                	addi	s0,sp,112
    80004030:	8b2a                	mv	s6,a0
    80004032:	8bae                	mv	s7,a1
    80004034:	8a32                	mv	s4,a2
    80004036:	84b6                	mv	s1,a3
    80004038:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000403a:	9f35                	addw	a4,a4,a3
    return 0;
    8000403c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000403e:	0ad76063          	bltu	a4,a3,800040de <readi+0xd2>
  if(off + n > ip->size)
    80004042:	00e7f463          	bgeu	a5,a4,8000404a <readi+0x3e>
    n = ip->size - off;
    80004046:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000404a:	0a0a8963          	beqz	s5,800040fc <readi+0xf0>
    8000404e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004050:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004054:	5c7d                	li	s8,-1
    80004056:	a82d                	j	80004090 <readi+0x84>
    80004058:	020d1d93          	slli	s11,s10,0x20
    8000405c:	020ddd93          	srli	s11,s11,0x20
    80004060:	05890613          	addi	a2,s2,88
    80004064:	86ee                	mv	a3,s11
    80004066:	963a                	add	a2,a2,a4
    80004068:	85d2                	mv	a1,s4
    8000406a:	855e                	mv	a0,s7
    8000406c:	ffffe097          	auipc	ra,0xffffe
    80004070:	6fa080e7          	jalr	1786(ra) # 80002766 <either_copyout>
    80004074:	05850d63          	beq	a0,s8,800040ce <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004078:	854a                	mv	a0,s2
    8000407a:	fffff097          	auipc	ra,0xfffff
    8000407e:	5f6080e7          	jalr	1526(ra) # 80003670 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004082:	013d09bb          	addw	s3,s10,s3
    80004086:	009d04bb          	addw	s1,s10,s1
    8000408a:	9a6e                	add	s4,s4,s11
    8000408c:	0559f763          	bgeu	s3,s5,800040da <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004090:	00a4d59b          	srliw	a1,s1,0xa
    80004094:	855a                	mv	a0,s6
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	89e080e7          	jalr	-1890(ra) # 80003934 <bmap>
    8000409e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040a2:	cd85                	beqz	a1,800040da <readi+0xce>
    bp = bread(ip->dev, addr);
    800040a4:	000b2503          	lw	a0,0(s6)
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	498080e7          	jalr	1176(ra) # 80003540 <bread>
    800040b0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040b2:	3ff4f713          	andi	a4,s1,1023
    800040b6:	40ec87bb          	subw	a5,s9,a4
    800040ba:	413a86bb          	subw	a3,s5,s3
    800040be:	8d3e                	mv	s10,a5
    800040c0:	2781                	sext.w	a5,a5
    800040c2:	0006861b          	sext.w	a2,a3
    800040c6:	f8f679e3          	bgeu	a2,a5,80004058 <readi+0x4c>
    800040ca:	8d36                	mv	s10,a3
    800040cc:	b771                	j	80004058 <readi+0x4c>
      brelse(bp);
    800040ce:	854a                	mv	a0,s2
    800040d0:	fffff097          	auipc	ra,0xfffff
    800040d4:	5a0080e7          	jalr	1440(ra) # 80003670 <brelse>
      tot = -1;
    800040d8:	59fd                	li	s3,-1
  }
  return tot;
    800040da:	0009851b          	sext.w	a0,s3
}
    800040de:	70a6                	ld	ra,104(sp)
    800040e0:	7406                	ld	s0,96(sp)
    800040e2:	64e6                	ld	s1,88(sp)
    800040e4:	6946                	ld	s2,80(sp)
    800040e6:	69a6                	ld	s3,72(sp)
    800040e8:	6a06                	ld	s4,64(sp)
    800040ea:	7ae2                	ld	s5,56(sp)
    800040ec:	7b42                	ld	s6,48(sp)
    800040ee:	7ba2                	ld	s7,40(sp)
    800040f0:	7c02                	ld	s8,32(sp)
    800040f2:	6ce2                	ld	s9,24(sp)
    800040f4:	6d42                	ld	s10,16(sp)
    800040f6:	6da2                	ld	s11,8(sp)
    800040f8:	6165                	addi	sp,sp,112
    800040fa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040fc:	89d6                	mv	s3,s5
    800040fe:	bff1                	j	800040da <readi+0xce>
    return 0;
    80004100:	4501                	li	a0,0
}
    80004102:	8082                	ret

0000000080004104 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004104:	457c                	lw	a5,76(a0)
    80004106:	10d7e863          	bltu	a5,a3,80004216 <writei+0x112>
{
    8000410a:	7159                	addi	sp,sp,-112
    8000410c:	f486                	sd	ra,104(sp)
    8000410e:	f0a2                	sd	s0,96(sp)
    80004110:	eca6                	sd	s1,88(sp)
    80004112:	e8ca                	sd	s2,80(sp)
    80004114:	e4ce                	sd	s3,72(sp)
    80004116:	e0d2                	sd	s4,64(sp)
    80004118:	fc56                	sd	s5,56(sp)
    8000411a:	f85a                	sd	s6,48(sp)
    8000411c:	f45e                	sd	s7,40(sp)
    8000411e:	f062                	sd	s8,32(sp)
    80004120:	ec66                	sd	s9,24(sp)
    80004122:	e86a                	sd	s10,16(sp)
    80004124:	e46e                	sd	s11,8(sp)
    80004126:	1880                	addi	s0,sp,112
    80004128:	8aaa                	mv	s5,a0
    8000412a:	8bae                	mv	s7,a1
    8000412c:	8a32                	mv	s4,a2
    8000412e:	8936                	mv	s2,a3
    80004130:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004132:	00e687bb          	addw	a5,a3,a4
    80004136:	0ed7e263          	bltu	a5,a3,8000421a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000413a:	00043737          	lui	a4,0x43
    8000413e:	0ef76063          	bltu	a4,a5,8000421e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004142:	0c0b0863          	beqz	s6,80004212 <writei+0x10e>
    80004146:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004148:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000414c:	5c7d                	li	s8,-1
    8000414e:	a091                	j	80004192 <writei+0x8e>
    80004150:	020d1d93          	slli	s11,s10,0x20
    80004154:	020ddd93          	srli	s11,s11,0x20
    80004158:	05848513          	addi	a0,s1,88
    8000415c:	86ee                	mv	a3,s11
    8000415e:	8652                	mv	a2,s4
    80004160:	85de                	mv	a1,s7
    80004162:	953a                	add	a0,a0,a4
    80004164:	ffffe097          	auipc	ra,0xffffe
    80004168:	658080e7          	jalr	1624(ra) # 800027bc <either_copyin>
    8000416c:	07850263          	beq	a0,s8,800041d0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004170:	8526                	mv	a0,s1
    80004172:	00000097          	auipc	ra,0x0
    80004176:	788080e7          	jalr	1928(ra) # 800048fa <log_write>
    brelse(bp);
    8000417a:	8526                	mv	a0,s1
    8000417c:	fffff097          	auipc	ra,0xfffff
    80004180:	4f4080e7          	jalr	1268(ra) # 80003670 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004184:	013d09bb          	addw	s3,s10,s3
    80004188:	012d093b          	addw	s2,s10,s2
    8000418c:	9a6e                	add	s4,s4,s11
    8000418e:	0569f663          	bgeu	s3,s6,800041da <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004192:	00a9559b          	srliw	a1,s2,0xa
    80004196:	8556                	mv	a0,s5
    80004198:	fffff097          	auipc	ra,0xfffff
    8000419c:	79c080e7          	jalr	1948(ra) # 80003934 <bmap>
    800041a0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800041a4:	c99d                	beqz	a1,800041da <writei+0xd6>
    bp = bread(ip->dev, addr);
    800041a6:	000aa503          	lw	a0,0(s5)
    800041aa:	fffff097          	auipc	ra,0xfffff
    800041ae:	396080e7          	jalr	918(ra) # 80003540 <bread>
    800041b2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041b4:	3ff97713          	andi	a4,s2,1023
    800041b8:	40ec87bb          	subw	a5,s9,a4
    800041bc:	413b06bb          	subw	a3,s6,s3
    800041c0:	8d3e                	mv	s10,a5
    800041c2:	2781                	sext.w	a5,a5
    800041c4:	0006861b          	sext.w	a2,a3
    800041c8:	f8f674e3          	bgeu	a2,a5,80004150 <writei+0x4c>
    800041cc:	8d36                	mv	s10,a3
    800041ce:	b749                	j	80004150 <writei+0x4c>
      brelse(bp);
    800041d0:	8526                	mv	a0,s1
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	49e080e7          	jalr	1182(ra) # 80003670 <brelse>
  }

  if(off > ip->size)
    800041da:	04caa783          	lw	a5,76(s5)
    800041de:	0127f463          	bgeu	a5,s2,800041e6 <writei+0xe2>
    ip->size = off;
    800041e2:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041e6:	8556                	mv	a0,s5
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	aa4080e7          	jalr	-1372(ra) # 80003c8c <iupdate>

  return tot;
    800041f0:	0009851b          	sext.w	a0,s3
}
    800041f4:	70a6                	ld	ra,104(sp)
    800041f6:	7406                	ld	s0,96(sp)
    800041f8:	64e6                	ld	s1,88(sp)
    800041fa:	6946                	ld	s2,80(sp)
    800041fc:	69a6                	ld	s3,72(sp)
    800041fe:	6a06                	ld	s4,64(sp)
    80004200:	7ae2                	ld	s5,56(sp)
    80004202:	7b42                	ld	s6,48(sp)
    80004204:	7ba2                	ld	s7,40(sp)
    80004206:	7c02                	ld	s8,32(sp)
    80004208:	6ce2                	ld	s9,24(sp)
    8000420a:	6d42                	ld	s10,16(sp)
    8000420c:	6da2                	ld	s11,8(sp)
    8000420e:	6165                	addi	sp,sp,112
    80004210:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004212:	89da                	mv	s3,s6
    80004214:	bfc9                	j	800041e6 <writei+0xe2>
    return -1;
    80004216:	557d                	li	a0,-1
}
    80004218:	8082                	ret
    return -1;
    8000421a:	557d                	li	a0,-1
    8000421c:	bfe1                	j	800041f4 <writei+0xf0>
    return -1;
    8000421e:	557d                	li	a0,-1
    80004220:	bfd1                	j	800041f4 <writei+0xf0>

0000000080004222 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004222:	1141                	addi	sp,sp,-16
    80004224:	e406                	sd	ra,8(sp)
    80004226:	e022                	sd	s0,0(sp)
    80004228:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000422a:	4639                	li	a2,14
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	d4e080e7          	jalr	-690(ra) # 80000f7a <strncmp>
}
    80004234:	60a2                	ld	ra,8(sp)
    80004236:	6402                	ld	s0,0(sp)
    80004238:	0141                	addi	sp,sp,16
    8000423a:	8082                	ret

000000008000423c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000423c:	7139                	addi	sp,sp,-64
    8000423e:	fc06                	sd	ra,56(sp)
    80004240:	f822                	sd	s0,48(sp)
    80004242:	f426                	sd	s1,40(sp)
    80004244:	f04a                	sd	s2,32(sp)
    80004246:	ec4e                	sd	s3,24(sp)
    80004248:	e852                	sd	s4,16(sp)
    8000424a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000424c:	04451703          	lh	a4,68(a0)
    80004250:	4785                	li	a5,1
    80004252:	00f71a63          	bne	a4,a5,80004266 <dirlookup+0x2a>
    80004256:	892a                	mv	s2,a0
    80004258:	89ae                	mv	s3,a1
    8000425a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000425c:	457c                	lw	a5,76(a0)
    8000425e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004260:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004262:	e79d                	bnez	a5,80004290 <dirlookup+0x54>
    80004264:	a8a5                	j	800042dc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004266:	00004517          	auipc	a0,0x4
    8000426a:	3ba50513          	addi	a0,a0,954 # 80008620 <syscalls+0x1c0>
    8000426e:	ffffc097          	auipc	ra,0xffffc
    80004272:	2d2080e7          	jalr	722(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004276:	00004517          	auipc	a0,0x4
    8000427a:	3c250513          	addi	a0,a0,962 # 80008638 <syscalls+0x1d8>
    8000427e:	ffffc097          	auipc	ra,0xffffc
    80004282:	2c2080e7          	jalr	706(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004286:	24c1                	addiw	s1,s1,16
    80004288:	04c92783          	lw	a5,76(s2)
    8000428c:	04f4f763          	bgeu	s1,a5,800042da <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004290:	4741                	li	a4,16
    80004292:	86a6                	mv	a3,s1
    80004294:	fc040613          	addi	a2,s0,-64
    80004298:	4581                	li	a1,0
    8000429a:	854a                	mv	a0,s2
    8000429c:	00000097          	auipc	ra,0x0
    800042a0:	d70080e7          	jalr	-656(ra) # 8000400c <readi>
    800042a4:	47c1                	li	a5,16
    800042a6:	fcf518e3          	bne	a0,a5,80004276 <dirlookup+0x3a>
    if(de.inum == 0)
    800042aa:	fc045783          	lhu	a5,-64(s0)
    800042ae:	dfe1                	beqz	a5,80004286 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800042b0:	fc240593          	addi	a1,s0,-62
    800042b4:	854e                	mv	a0,s3
    800042b6:	00000097          	auipc	ra,0x0
    800042ba:	f6c080e7          	jalr	-148(ra) # 80004222 <namecmp>
    800042be:	f561                	bnez	a0,80004286 <dirlookup+0x4a>
      if(poff)
    800042c0:	000a0463          	beqz	s4,800042c8 <dirlookup+0x8c>
        *poff = off;
    800042c4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800042c8:	fc045583          	lhu	a1,-64(s0)
    800042cc:	00092503          	lw	a0,0(s2)
    800042d0:	fffff097          	auipc	ra,0xfffff
    800042d4:	74e080e7          	jalr	1870(ra) # 80003a1e <iget>
    800042d8:	a011                	j	800042dc <dirlookup+0xa0>
  return 0;
    800042da:	4501                	li	a0,0
}
    800042dc:	70e2                	ld	ra,56(sp)
    800042de:	7442                	ld	s0,48(sp)
    800042e0:	74a2                	ld	s1,40(sp)
    800042e2:	7902                	ld	s2,32(sp)
    800042e4:	69e2                	ld	s3,24(sp)
    800042e6:	6a42                	ld	s4,16(sp)
    800042e8:	6121                	addi	sp,sp,64
    800042ea:	8082                	ret

00000000800042ec <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042ec:	711d                	addi	sp,sp,-96
    800042ee:	ec86                	sd	ra,88(sp)
    800042f0:	e8a2                	sd	s0,80(sp)
    800042f2:	e4a6                	sd	s1,72(sp)
    800042f4:	e0ca                	sd	s2,64(sp)
    800042f6:	fc4e                	sd	s3,56(sp)
    800042f8:	f852                	sd	s4,48(sp)
    800042fa:	f456                	sd	s5,40(sp)
    800042fc:	f05a                	sd	s6,32(sp)
    800042fe:	ec5e                	sd	s7,24(sp)
    80004300:	e862                	sd	s8,16(sp)
    80004302:	e466                	sd	s9,8(sp)
    80004304:	e06a                	sd	s10,0(sp)
    80004306:	1080                	addi	s0,sp,96
    80004308:	84aa                	mv	s1,a0
    8000430a:	8b2e                	mv	s6,a1
    8000430c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000430e:	00054703          	lbu	a4,0(a0)
    80004312:	02f00793          	li	a5,47
    80004316:	02f70363          	beq	a4,a5,8000433c <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000431a:	ffffe097          	auipc	ra,0xffffe
    8000431e:	938080e7          	jalr	-1736(ra) # 80001c52 <myproc>
    80004322:	15053503          	ld	a0,336(a0)
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	9f4080e7          	jalr	-1548(ra) # 80003d1a <idup>
    8000432e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004330:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004334:	4cb5                	li	s9,13
  len = path - s;
    80004336:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004338:	4c05                	li	s8,1
    8000433a:	a87d                	j	800043f8 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    8000433c:	4585                	li	a1,1
    8000433e:	4505                	li	a0,1
    80004340:	fffff097          	auipc	ra,0xfffff
    80004344:	6de080e7          	jalr	1758(ra) # 80003a1e <iget>
    80004348:	8a2a                	mv	s4,a0
    8000434a:	b7dd                	j	80004330 <namex+0x44>
      iunlockput(ip);
    8000434c:	8552                	mv	a0,s4
    8000434e:	00000097          	auipc	ra,0x0
    80004352:	c6c080e7          	jalr	-916(ra) # 80003fba <iunlockput>
      return 0;
    80004356:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004358:	8552                	mv	a0,s4
    8000435a:	60e6                	ld	ra,88(sp)
    8000435c:	6446                	ld	s0,80(sp)
    8000435e:	64a6                	ld	s1,72(sp)
    80004360:	6906                	ld	s2,64(sp)
    80004362:	79e2                	ld	s3,56(sp)
    80004364:	7a42                	ld	s4,48(sp)
    80004366:	7aa2                	ld	s5,40(sp)
    80004368:	7b02                	ld	s6,32(sp)
    8000436a:	6be2                	ld	s7,24(sp)
    8000436c:	6c42                	ld	s8,16(sp)
    8000436e:	6ca2                	ld	s9,8(sp)
    80004370:	6d02                	ld	s10,0(sp)
    80004372:	6125                	addi	sp,sp,96
    80004374:	8082                	ret
      iunlock(ip);
    80004376:	8552                	mv	a0,s4
    80004378:	00000097          	auipc	ra,0x0
    8000437c:	aa2080e7          	jalr	-1374(ra) # 80003e1a <iunlock>
      return ip;
    80004380:	bfe1                	j	80004358 <namex+0x6c>
      iunlockput(ip);
    80004382:	8552                	mv	a0,s4
    80004384:	00000097          	auipc	ra,0x0
    80004388:	c36080e7          	jalr	-970(ra) # 80003fba <iunlockput>
      return 0;
    8000438c:	8a4e                	mv	s4,s3
    8000438e:	b7e9                	j	80004358 <namex+0x6c>
  len = path - s;
    80004390:	40998633          	sub	a2,s3,s1
    80004394:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004398:	09acd863          	bge	s9,s10,80004428 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000439c:	4639                	li	a2,14
    8000439e:	85a6                	mv	a1,s1
    800043a0:	8556                	mv	a0,s5
    800043a2:	ffffd097          	auipc	ra,0xffffd
    800043a6:	b64080e7          	jalr	-1180(ra) # 80000f06 <memmove>
    800043aa:	84ce                	mv	s1,s3
  while(*path == '/')
    800043ac:	0004c783          	lbu	a5,0(s1)
    800043b0:	01279763          	bne	a5,s2,800043be <namex+0xd2>
    path++;
    800043b4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043b6:	0004c783          	lbu	a5,0(s1)
    800043ba:	ff278de3          	beq	a5,s2,800043b4 <namex+0xc8>
    ilock(ip);
    800043be:	8552                	mv	a0,s4
    800043c0:	00000097          	auipc	ra,0x0
    800043c4:	998080e7          	jalr	-1640(ra) # 80003d58 <ilock>
    if(ip->type != T_DIR){
    800043c8:	044a1783          	lh	a5,68(s4)
    800043cc:	f98790e3          	bne	a5,s8,8000434c <namex+0x60>
    if(nameiparent && *path == '\0'){
    800043d0:	000b0563          	beqz	s6,800043da <namex+0xee>
    800043d4:	0004c783          	lbu	a5,0(s1)
    800043d8:	dfd9                	beqz	a5,80004376 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043da:	865e                	mv	a2,s7
    800043dc:	85d6                	mv	a1,s5
    800043de:	8552                	mv	a0,s4
    800043e0:	00000097          	auipc	ra,0x0
    800043e4:	e5c080e7          	jalr	-420(ra) # 8000423c <dirlookup>
    800043e8:	89aa                	mv	s3,a0
    800043ea:	dd41                	beqz	a0,80004382 <namex+0x96>
    iunlockput(ip);
    800043ec:	8552                	mv	a0,s4
    800043ee:	00000097          	auipc	ra,0x0
    800043f2:	bcc080e7          	jalr	-1076(ra) # 80003fba <iunlockput>
    ip = next;
    800043f6:	8a4e                	mv	s4,s3
  while(*path == '/')
    800043f8:	0004c783          	lbu	a5,0(s1)
    800043fc:	01279763          	bne	a5,s2,8000440a <namex+0x11e>
    path++;
    80004400:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004402:	0004c783          	lbu	a5,0(s1)
    80004406:	ff278de3          	beq	a5,s2,80004400 <namex+0x114>
  if(*path == 0)
    8000440a:	cb9d                	beqz	a5,80004440 <namex+0x154>
  while(*path != '/' && *path != 0)
    8000440c:	0004c783          	lbu	a5,0(s1)
    80004410:	89a6                	mv	s3,s1
  len = path - s;
    80004412:	8d5e                	mv	s10,s7
    80004414:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004416:	01278963          	beq	a5,s2,80004428 <namex+0x13c>
    8000441a:	dbbd                	beqz	a5,80004390 <namex+0xa4>
    path++;
    8000441c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000441e:	0009c783          	lbu	a5,0(s3)
    80004422:	ff279ce3          	bne	a5,s2,8000441a <namex+0x12e>
    80004426:	b7ad                	j	80004390 <namex+0xa4>
    memmove(name, s, len);
    80004428:	2601                	sext.w	a2,a2
    8000442a:	85a6                	mv	a1,s1
    8000442c:	8556                	mv	a0,s5
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	ad8080e7          	jalr	-1320(ra) # 80000f06 <memmove>
    name[len] = 0;
    80004436:	9d56                	add	s10,s10,s5
    80004438:	000d0023          	sb	zero,0(s10)
    8000443c:	84ce                	mv	s1,s3
    8000443e:	b7bd                	j	800043ac <namex+0xc0>
  if(nameiparent){
    80004440:	f00b0ce3          	beqz	s6,80004358 <namex+0x6c>
    iput(ip);
    80004444:	8552                	mv	a0,s4
    80004446:	00000097          	auipc	ra,0x0
    8000444a:	acc080e7          	jalr	-1332(ra) # 80003f12 <iput>
    return 0;
    8000444e:	4a01                	li	s4,0
    80004450:	b721                	j	80004358 <namex+0x6c>

0000000080004452 <dirlink>:
{
    80004452:	7139                	addi	sp,sp,-64
    80004454:	fc06                	sd	ra,56(sp)
    80004456:	f822                	sd	s0,48(sp)
    80004458:	f426                	sd	s1,40(sp)
    8000445a:	f04a                	sd	s2,32(sp)
    8000445c:	ec4e                	sd	s3,24(sp)
    8000445e:	e852                	sd	s4,16(sp)
    80004460:	0080                	addi	s0,sp,64
    80004462:	892a                	mv	s2,a0
    80004464:	8a2e                	mv	s4,a1
    80004466:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004468:	4601                	li	a2,0
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	dd2080e7          	jalr	-558(ra) # 8000423c <dirlookup>
    80004472:	e93d                	bnez	a0,800044e8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004474:	04c92483          	lw	s1,76(s2)
    80004478:	c49d                	beqz	s1,800044a6 <dirlink+0x54>
    8000447a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000447c:	4741                	li	a4,16
    8000447e:	86a6                	mv	a3,s1
    80004480:	fc040613          	addi	a2,s0,-64
    80004484:	4581                	li	a1,0
    80004486:	854a                	mv	a0,s2
    80004488:	00000097          	auipc	ra,0x0
    8000448c:	b84080e7          	jalr	-1148(ra) # 8000400c <readi>
    80004490:	47c1                	li	a5,16
    80004492:	06f51163          	bne	a0,a5,800044f4 <dirlink+0xa2>
    if(de.inum == 0)
    80004496:	fc045783          	lhu	a5,-64(s0)
    8000449a:	c791                	beqz	a5,800044a6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000449c:	24c1                	addiw	s1,s1,16
    8000449e:	04c92783          	lw	a5,76(s2)
    800044a2:	fcf4ede3          	bltu	s1,a5,8000447c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800044a6:	4639                	li	a2,14
    800044a8:	85d2                	mv	a1,s4
    800044aa:	fc240513          	addi	a0,s0,-62
    800044ae:	ffffd097          	auipc	ra,0xffffd
    800044b2:	b08080e7          	jalr	-1272(ra) # 80000fb6 <strncpy>
  de.inum = inum;
    800044b6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044ba:	4741                	li	a4,16
    800044bc:	86a6                	mv	a3,s1
    800044be:	fc040613          	addi	a2,s0,-64
    800044c2:	4581                	li	a1,0
    800044c4:	854a                	mv	a0,s2
    800044c6:	00000097          	auipc	ra,0x0
    800044ca:	c3e080e7          	jalr	-962(ra) # 80004104 <writei>
    800044ce:	1541                	addi	a0,a0,-16
    800044d0:	00a03533          	snez	a0,a0
    800044d4:	40a00533          	neg	a0,a0
}
    800044d8:	70e2                	ld	ra,56(sp)
    800044da:	7442                	ld	s0,48(sp)
    800044dc:	74a2                	ld	s1,40(sp)
    800044de:	7902                	ld	s2,32(sp)
    800044e0:	69e2                	ld	s3,24(sp)
    800044e2:	6a42                	ld	s4,16(sp)
    800044e4:	6121                	addi	sp,sp,64
    800044e6:	8082                	ret
    iput(ip);
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	a2a080e7          	jalr	-1494(ra) # 80003f12 <iput>
    return -1;
    800044f0:	557d                	li	a0,-1
    800044f2:	b7dd                	j	800044d8 <dirlink+0x86>
      panic("dirlink read");
    800044f4:	00004517          	auipc	a0,0x4
    800044f8:	15450513          	addi	a0,a0,340 # 80008648 <syscalls+0x1e8>
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	044080e7          	jalr	68(ra) # 80000540 <panic>

0000000080004504 <namei>:

struct inode*
namei(char *path)
{
    80004504:	1101                	addi	sp,sp,-32
    80004506:	ec06                	sd	ra,24(sp)
    80004508:	e822                	sd	s0,16(sp)
    8000450a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000450c:	fe040613          	addi	a2,s0,-32
    80004510:	4581                	li	a1,0
    80004512:	00000097          	auipc	ra,0x0
    80004516:	dda080e7          	jalr	-550(ra) # 800042ec <namex>
}
    8000451a:	60e2                	ld	ra,24(sp)
    8000451c:	6442                	ld	s0,16(sp)
    8000451e:	6105                	addi	sp,sp,32
    80004520:	8082                	ret

0000000080004522 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004522:	1141                	addi	sp,sp,-16
    80004524:	e406                	sd	ra,8(sp)
    80004526:	e022                	sd	s0,0(sp)
    80004528:	0800                	addi	s0,sp,16
    8000452a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000452c:	4585                	li	a1,1
    8000452e:	00000097          	auipc	ra,0x0
    80004532:	dbe080e7          	jalr	-578(ra) # 800042ec <namex>
}
    80004536:	60a2                	ld	ra,8(sp)
    80004538:	6402                	ld	s0,0(sp)
    8000453a:	0141                	addi	sp,sp,16
    8000453c:	8082                	ret

000000008000453e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000453e:	1101                	addi	sp,sp,-32
    80004540:	ec06                	sd	ra,24(sp)
    80004542:	e822                	sd	s0,16(sp)
    80004544:	e426                	sd	s1,8(sp)
    80004546:	e04a                	sd	s2,0(sp)
    80004548:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000454a:	0003e917          	auipc	s2,0x3e
    8000454e:	81e90913          	addi	s2,s2,-2018 # 80041d68 <log>
    80004552:	01892583          	lw	a1,24(s2)
    80004556:	02892503          	lw	a0,40(s2)
    8000455a:	fffff097          	auipc	ra,0xfffff
    8000455e:	fe6080e7          	jalr	-26(ra) # 80003540 <bread>
    80004562:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004564:	02c92683          	lw	a3,44(s2)
    80004568:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000456a:	02d05863          	blez	a3,8000459a <write_head+0x5c>
    8000456e:	0003e797          	auipc	a5,0x3e
    80004572:	82a78793          	addi	a5,a5,-2006 # 80041d98 <log+0x30>
    80004576:	05c50713          	addi	a4,a0,92
    8000457a:	36fd                	addiw	a3,a3,-1
    8000457c:	02069613          	slli	a2,a3,0x20
    80004580:	01e65693          	srli	a3,a2,0x1e
    80004584:	0003e617          	auipc	a2,0x3e
    80004588:	81860613          	addi	a2,a2,-2024 # 80041d9c <log+0x34>
    8000458c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000458e:	4390                	lw	a2,0(a5)
    80004590:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004592:	0791                	addi	a5,a5,4
    80004594:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004596:	fed79ce3          	bne	a5,a3,8000458e <write_head+0x50>
  }
  bwrite(buf);
    8000459a:	8526                	mv	a0,s1
    8000459c:	fffff097          	auipc	ra,0xfffff
    800045a0:	096080e7          	jalr	150(ra) # 80003632 <bwrite>
  brelse(buf);
    800045a4:	8526                	mv	a0,s1
    800045a6:	fffff097          	auipc	ra,0xfffff
    800045aa:	0ca080e7          	jalr	202(ra) # 80003670 <brelse>
}
    800045ae:	60e2                	ld	ra,24(sp)
    800045b0:	6442                	ld	s0,16(sp)
    800045b2:	64a2                	ld	s1,8(sp)
    800045b4:	6902                	ld	s2,0(sp)
    800045b6:	6105                	addi	sp,sp,32
    800045b8:	8082                	ret

00000000800045ba <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ba:	0003d797          	auipc	a5,0x3d
    800045be:	7da7a783          	lw	a5,2010(a5) # 80041d94 <log+0x2c>
    800045c2:	0af05d63          	blez	a5,8000467c <install_trans+0xc2>
{
    800045c6:	7139                	addi	sp,sp,-64
    800045c8:	fc06                	sd	ra,56(sp)
    800045ca:	f822                	sd	s0,48(sp)
    800045cc:	f426                	sd	s1,40(sp)
    800045ce:	f04a                	sd	s2,32(sp)
    800045d0:	ec4e                	sd	s3,24(sp)
    800045d2:	e852                	sd	s4,16(sp)
    800045d4:	e456                	sd	s5,8(sp)
    800045d6:	e05a                	sd	s6,0(sp)
    800045d8:	0080                	addi	s0,sp,64
    800045da:	8b2a                	mv	s6,a0
    800045dc:	0003da97          	auipc	s5,0x3d
    800045e0:	7bca8a93          	addi	s5,s5,1980 # 80041d98 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045e4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045e6:	0003d997          	auipc	s3,0x3d
    800045ea:	78298993          	addi	s3,s3,1922 # 80041d68 <log>
    800045ee:	a00d                	j	80004610 <install_trans+0x56>
    brelse(lbuf);
    800045f0:	854a                	mv	a0,s2
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	07e080e7          	jalr	126(ra) # 80003670 <brelse>
    brelse(dbuf);
    800045fa:	8526                	mv	a0,s1
    800045fc:	fffff097          	auipc	ra,0xfffff
    80004600:	074080e7          	jalr	116(ra) # 80003670 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004604:	2a05                	addiw	s4,s4,1
    80004606:	0a91                	addi	s5,s5,4
    80004608:	02c9a783          	lw	a5,44(s3)
    8000460c:	04fa5e63          	bge	s4,a5,80004668 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004610:	0189a583          	lw	a1,24(s3)
    80004614:	014585bb          	addw	a1,a1,s4
    80004618:	2585                	addiw	a1,a1,1
    8000461a:	0289a503          	lw	a0,40(s3)
    8000461e:	fffff097          	auipc	ra,0xfffff
    80004622:	f22080e7          	jalr	-222(ra) # 80003540 <bread>
    80004626:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004628:	000aa583          	lw	a1,0(s5)
    8000462c:	0289a503          	lw	a0,40(s3)
    80004630:	fffff097          	auipc	ra,0xfffff
    80004634:	f10080e7          	jalr	-240(ra) # 80003540 <bread>
    80004638:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000463a:	40000613          	li	a2,1024
    8000463e:	05890593          	addi	a1,s2,88
    80004642:	05850513          	addi	a0,a0,88
    80004646:	ffffd097          	auipc	ra,0xffffd
    8000464a:	8c0080e7          	jalr	-1856(ra) # 80000f06 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000464e:	8526                	mv	a0,s1
    80004650:	fffff097          	auipc	ra,0xfffff
    80004654:	fe2080e7          	jalr	-30(ra) # 80003632 <bwrite>
    if(recovering == 0)
    80004658:	f80b1ce3          	bnez	s6,800045f0 <install_trans+0x36>
      bunpin(dbuf);
    8000465c:	8526                	mv	a0,s1
    8000465e:	fffff097          	auipc	ra,0xfffff
    80004662:	0ec080e7          	jalr	236(ra) # 8000374a <bunpin>
    80004666:	b769                	j	800045f0 <install_trans+0x36>
}
    80004668:	70e2                	ld	ra,56(sp)
    8000466a:	7442                	ld	s0,48(sp)
    8000466c:	74a2                	ld	s1,40(sp)
    8000466e:	7902                	ld	s2,32(sp)
    80004670:	69e2                	ld	s3,24(sp)
    80004672:	6a42                	ld	s4,16(sp)
    80004674:	6aa2                	ld	s5,8(sp)
    80004676:	6b02                	ld	s6,0(sp)
    80004678:	6121                	addi	sp,sp,64
    8000467a:	8082                	ret
    8000467c:	8082                	ret

000000008000467e <initlog>:
{
    8000467e:	7179                	addi	sp,sp,-48
    80004680:	f406                	sd	ra,40(sp)
    80004682:	f022                	sd	s0,32(sp)
    80004684:	ec26                	sd	s1,24(sp)
    80004686:	e84a                	sd	s2,16(sp)
    80004688:	e44e                	sd	s3,8(sp)
    8000468a:	1800                	addi	s0,sp,48
    8000468c:	892a                	mv	s2,a0
    8000468e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004690:	0003d497          	auipc	s1,0x3d
    80004694:	6d848493          	addi	s1,s1,1752 # 80041d68 <log>
    80004698:	00004597          	auipc	a1,0x4
    8000469c:	fc058593          	addi	a1,a1,-64 # 80008658 <syscalls+0x1f8>
    800046a0:	8526                	mv	a0,s1
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	67c080e7          	jalr	1660(ra) # 80000d1e <initlock>
  log.start = sb->logstart;
    800046aa:	0149a583          	lw	a1,20(s3)
    800046ae:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800046b0:	0109a783          	lw	a5,16(s3)
    800046b4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046b6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046ba:	854a                	mv	a0,s2
    800046bc:	fffff097          	auipc	ra,0xfffff
    800046c0:	e84080e7          	jalr	-380(ra) # 80003540 <bread>
  log.lh.n = lh->n;
    800046c4:	4d34                	lw	a3,88(a0)
    800046c6:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046c8:	02d05663          	blez	a3,800046f4 <initlog+0x76>
    800046cc:	05c50793          	addi	a5,a0,92
    800046d0:	0003d717          	auipc	a4,0x3d
    800046d4:	6c870713          	addi	a4,a4,1736 # 80041d98 <log+0x30>
    800046d8:	36fd                	addiw	a3,a3,-1
    800046da:	02069613          	slli	a2,a3,0x20
    800046de:	01e65693          	srli	a3,a2,0x1e
    800046e2:	06050613          	addi	a2,a0,96
    800046e6:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800046e8:	4390                	lw	a2,0(a5)
    800046ea:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046ec:	0791                	addi	a5,a5,4
    800046ee:	0711                	addi	a4,a4,4
    800046f0:	fed79ce3          	bne	a5,a3,800046e8 <initlog+0x6a>
  brelse(buf);
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	f7c080e7          	jalr	-132(ra) # 80003670 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046fc:	4505                	li	a0,1
    800046fe:	00000097          	auipc	ra,0x0
    80004702:	ebc080e7          	jalr	-324(ra) # 800045ba <install_trans>
  log.lh.n = 0;
    80004706:	0003d797          	auipc	a5,0x3d
    8000470a:	6807a723          	sw	zero,1678(a5) # 80041d94 <log+0x2c>
  write_head(); // clear the log
    8000470e:	00000097          	auipc	ra,0x0
    80004712:	e30080e7          	jalr	-464(ra) # 8000453e <write_head>
}
    80004716:	70a2                	ld	ra,40(sp)
    80004718:	7402                	ld	s0,32(sp)
    8000471a:	64e2                	ld	s1,24(sp)
    8000471c:	6942                	ld	s2,16(sp)
    8000471e:	69a2                	ld	s3,8(sp)
    80004720:	6145                	addi	sp,sp,48
    80004722:	8082                	ret

0000000080004724 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004724:	1101                	addi	sp,sp,-32
    80004726:	ec06                	sd	ra,24(sp)
    80004728:	e822                	sd	s0,16(sp)
    8000472a:	e426                	sd	s1,8(sp)
    8000472c:	e04a                	sd	s2,0(sp)
    8000472e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004730:	0003d517          	auipc	a0,0x3d
    80004734:	63850513          	addi	a0,a0,1592 # 80041d68 <log>
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	676080e7          	jalr	1654(ra) # 80000dae <acquire>
  while(1){
    if(log.committing){
    80004740:	0003d497          	auipc	s1,0x3d
    80004744:	62848493          	addi	s1,s1,1576 # 80041d68 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004748:	4979                	li	s2,30
    8000474a:	a039                	j	80004758 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000474c:	85a6                	mv	a1,s1
    8000474e:	8526                	mv	a0,s1
    80004750:	ffffe097          	auipc	ra,0xffffe
    80004754:	c02080e7          	jalr	-1022(ra) # 80002352 <sleep>
    if(log.committing){
    80004758:	50dc                	lw	a5,36(s1)
    8000475a:	fbed                	bnez	a5,8000474c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000475c:	5098                	lw	a4,32(s1)
    8000475e:	2705                	addiw	a4,a4,1
    80004760:	0007069b          	sext.w	a3,a4
    80004764:	0027179b          	slliw	a5,a4,0x2
    80004768:	9fb9                	addw	a5,a5,a4
    8000476a:	0017979b          	slliw	a5,a5,0x1
    8000476e:	54d8                	lw	a4,44(s1)
    80004770:	9fb9                	addw	a5,a5,a4
    80004772:	00f95963          	bge	s2,a5,80004784 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004776:	85a6                	mv	a1,s1
    80004778:	8526                	mv	a0,s1
    8000477a:	ffffe097          	auipc	ra,0xffffe
    8000477e:	bd8080e7          	jalr	-1064(ra) # 80002352 <sleep>
    80004782:	bfd9                	j	80004758 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004784:	0003d517          	auipc	a0,0x3d
    80004788:	5e450513          	addi	a0,a0,1508 # 80041d68 <log>
    8000478c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	6d4080e7          	jalr	1748(ra) # 80000e62 <release>
      break;
    }
  }
}
    80004796:	60e2                	ld	ra,24(sp)
    80004798:	6442                	ld	s0,16(sp)
    8000479a:	64a2                	ld	s1,8(sp)
    8000479c:	6902                	ld	s2,0(sp)
    8000479e:	6105                	addi	sp,sp,32
    800047a0:	8082                	ret

00000000800047a2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800047a2:	7139                	addi	sp,sp,-64
    800047a4:	fc06                	sd	ra,56(sp)
    800047a6:	f822                	sd	s0,48(sp)
    800047a8:	f426                	sd	s1,40(sp)
    800047aa:	f04a                	sd	s2,32(sp)
    800047ac:	ec4e                	sd	s3,24(sp)
    800047ae:	e852                	sd	s4,16(sp)
    800047b0:	e456                	sd	s5,8(sp)
    800047b2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047b4:	0003d497          	auipc	s1,0x3d
    800047b8:	5b448493          	addi	s1,s1,1460 # 80041d68 <log>
    800047bc:	8526                	mv	a0,s1
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	5f0080e7          	jalr	1520(ra) # 80000dae <acquire>
  log.outstanding -= 1;
    800047c6:	509c                	lw	a5,32(s1)
    800047c8:	37fd                	addiw	a5,a5,-1
    800047ca:	0007891b          	sext.w	s2,a5
    800047ce:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047d0:	50dc                	lw	a5,36(s1)
    800047d2:	e7b9                	bnez	a5,80004820 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800047d4:	04091e63          	bnez	s2,80004830 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800047d8:	0003d497          	auipc	s1,0x3d
    800047dc:	59048493          	addi	s1,s1,1424 # 80041d68 <log>
    800047e0:	4785                	li	a5,1
    800047e2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047e4:	8526                	mv	a0,s1
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	67c080e7          	jalr	1660(ra) # 80000e62 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047ee:	54dc                	lw	a5,44(s1)
    800047f0:	06f04763          	bgtz	a5,8000485e <end_op+0xbc>
    acquire(&log.lock);
    800047f4:	0003d497          	auipc	s1,0x3d
    800047f8:	57448493          	addi	s1,s1,1396 # 80041d68 <log>
    800047fc:	8526                	mv	a0,s1
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	5b0080e7          	jalr	1456(ra) # 80000dae <acquire>
    log.committing = 0;
    80004806:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000480a:	8526                	mv	a0,s1
    8000480c:	ffffe097          	auipc	ra,0xffffe
    80004810:	baa080e7          	jalr	-1110(ra) # 800023b6 <wakeup>
    release(&log.lock);
    80004814:	8526                	mv	a0,s1
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	64c080e7          	jalr	1612(ra) # 80000e62 <release>
}
    8000481e:	a03d                	j	8000484c <end_op+0xaa>
    panic("log.committing");
    80004820:	00004517          	auipc	a0,0x4
    80004824:	e4050513          	addi	a0,a0,-448 # 80008660 <syscalls+0x200>
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	d18080e7          	jalr	-744(ra) # 80000540 <panic>
    wakeup(&log);
    80004830:	0003d497          	auipc	s1,0x3d
    80004834:	53848493          	addi	s1,s1,1336 # 80041d68 <log>
    80004838:	8526                	mv	a0,s1
    8000483a:	ffffe097          	auipc	ra,0xffffe
    8000483e:	b7c080e7          	jalr	-1156(ra) # 800023b6 <wakeup>
  release(&log.lock);
    80004842:	8526                	mv	a0,s1
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	61e080e7          	jalr	1566(ra) # 80000e62 <release>
}
    8000484c:	70e2                	ld	ra,56(sp)
    8000484e:	7442                	ld	s0,48(sp)
    80004850:	74a2                	ld	s1,40(sp)
    80004852:	7902                	ld	s2,32(sp)
    80004854:	69e2                	ld	s3,24(sp)
    80004856:	6a42                	ld	s4,16(sp)
    80004858:	6aa2                	ld	s5,8(sp)
    8000485a:	6121                	addi	sp,sp,64
    8000485c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000485e:	0003da97          	auipc	s5,0x3d
    80004862:	53aa8a93          	addi	s5,s5,1338 # 80041d98 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004866:	0003da17          	auipc	s4,0x3d
    8000486a:	502a0a13          	addi	s4,s4,1282 # 80041d68 <log>
    8000486e:	018a2583          	lw	a1,24(s4)
    80004872:	012585bb          	addw	a1,a1,s2
    80004876:	2585                	addiw	a1,a1,1
    80004878:	028a2503          	lw	a0,40(s4)
    8000487c:	fffff097          	auipc	ra,0xfffff
    80004880:	cc4080e7          	jalr	-828(ra) # 80003540 <bread>
    80004884:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004886:	000aa583          	lw	a1,0(s5)
    8000488a:	028a2503          	lw	a0,40(s4)
    8000488e:	fffff097          	auipc	ra,0xfffff
    80004892:	cb2080e7          	jalr	-846(ra) # 80003540 <bread>
    80004896:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004898:	40000613          	li	a2,1024
    8000489c:	05850593          	addi	a1,a0,88
    800048a0:	05848513          	addi	a0,s1,88
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	662080e7          	jalr	1634(ra) # 80000f06 <memmove>
    bwrite(to);  // write the log
    800048ac:	8526                	mv	a0,s1
    800048ae:	fffff097          	auipc	ra,0xfffff
    800048b2:	d84080e7          	jalr	-636(ra) # 80003632 <bwrite>
    brelse(from);
    800048b6:	854e                	mv	a0,s3
    800048b8:	fffff097          	auipc	ra,0xfffff
    800048bc:	db8080e7          	jalr	-584(ra) # 80003670 <brelse>
    brelse(to);
    800048c0:	8526                	mv	a0,s1
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	dae080e7          	jalr	-594(ra) # 80003670 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048ca:	2905                	addiw	s2,s2,1
    800048cc:	0a91                	addi	s5,s5,4
    800048ce:	02ca2783          	lw	a5,44(s4)
    800048d2:	f8f94ee3          	blt	s2,a5,8000486e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048d6:	00000097          	auipc	ra,0x0
    800048da:	c68080e7          	jalr	-920(ra) # 8000453e <write_head>
    install_trans(0); // Now install writes to home locations
    800048de:	4501                	li	a0,0
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	cda080e7          	jalr	-806(ra) # 800045ba <install_trans>
    log.lh.n = 0;
    800048e8:	0003d797          	auipc	a5,0x3d
    800048ec:	4a07a623          	sw	zero,1196(a5) # 80041d94 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048f0:	00000097          	auipc	ra,0x0
    800048f4:	c4e080e7          	jalr	-946(ra) # 8000453e <write_head>
    800048f8:	bdf5                	j	800047f4 <end_op+0x52>

00000000800048fa <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048fa:	1101                	addi	sp,sp,-32
    800048fc:	ec06                	sd	ra,24(sp)
    800048fe:	e822                	sd	s0,16(sp)
    80004900:	e426                	sd	s1,8(sp)
    80004902:	e04a                	sd	s2,0(sp)
    80004904:	1000                	addi	s0,sp,32
    80004906:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004908:	0003d917          	auipc	s2,0x3d
    8000490c:	46090913          	addi	s2,s2,1120 # 80041d68 <log>
    80004910:	854a                	mv	a0,s2
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	49c080e7          	jalr	1180(ra) # 80000dae <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000491a:	02c92603          	lw	a2,44(s2)
    8000491e:	47f5                	li	a5,29
    80004920:	06c7c563          	blt	a5,a2,8000498a <log_write+0x90>
    80004924:	0003d797          	auipc	a5,0x3d
    80004928:	4607a783          	lw	a5,1120(a5) # 80041d84 <log+0x1c>
    8000492c:	37fd                	addiw	a5,a5,-1
    8000492e:	04f65e63          	bge	a2,a5,8000498a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004932:	0003d797          	auipc	a5,0x3d
    80004936:	4567a783          	lw	a5,1110(a5) # 80041d88 <log+0x20>
    8000493a:	06f05063          	blez	a5,8000499a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000493e:	4781                	li	a5,0
    80004940:	06c05563          	blez	a2,800049aa <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004944:	44cc                	lw	a1,12(s1)
    80004946:	0003d717          	auipc	a4,0x3d
    8000494a:	45270713          	addi	a4,a4,1106 # 80041d98 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000494e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004950:	4314                	lw	a3,0(a4)
    80004952:	04b68c63          	beq	a3,a1,800049aa <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004956:	2785                	addiw	a5,a5,1
    80004958:	0711                	addi	a4,a4,4
    8000495a:	fef61be3          	bne	a2,a5,80004950 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000495e:	0621                	addi	a2,a2,8
    80004960:	060a                	slli	a2,a2,0x2
    80004962:	0003d797          	auipc	a5,0x3d
    80004966:	40678793          	addi	a5,a5,1030 # 80041d68 <log>
    8000496a:	97b2                	add	a5,a5,a2
    8000496c:	44d8                	lw	a4,12(s1)
    8000496e:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004970:	8526                	mv	a0,s1
    80004972:	fffff097          	auipc	ra,0xfffff
    80004976:	d9c080e7          	jalr	-612(ra) # 8000370e <bpin>
    log.lh.n++;
    8000497a:	0003d717          	auipc	a4,0x3d
    8000497e:	3ee70713          	addi	a4,a4,1006 # 80041d68 <log>
    80004982:	575c                	lw	a5,44(a4)
    80004984:	2785                	addiw	a5,a5,1
    80004986:	d75c                	sw	a5,44(a4)
    80004988:	a82d                	j	800049c2 <log_write+0xc8>
    panic("too big a transaction");
    8000498a:	00004517          	auipc	a0,0x4
    8000498e:	ce650513          	addi	a0,a0,-794 # 80008670 <syscalls+0x210>
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	bae080e7          	jalr	-1106(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000499a:	00004517          	auipc	a0,0x4
    8000499e:	cee50513          	addi	a0,a0,-786 # 80008688 <syscalls+0x228>
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	b9e080e7          	jalr	-1122(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800049aa:	00878693          	addi	a3,a5,8
    800049ae:	068a                	slli	a3,a3,0x2
    800049b0:	0003d717          	auipc	a4,0x3d
    800049b4:	3b870713          	addi	a4,a4,952 # 80041d68 <log>
    800049b8:	9736                	add	a4,a4,a3
    800049ba:	44d4                	lw	a3,12(s1)
    800049bc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049be:	faf609e3          	beq	a2,a5,80004970 <log_write+0x76>
  }
  release(&log.lock);
    800049c2:	0003d517          	auipc	a0,0x3d
    800049c6:	3a650513          	addi	a0,a0,934 # 80041d68 <log>
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	498080e7          	jalr	1176(ra) # 80000e62 <release>
}
    800049d2:	60e2                	ld	ra,24(sp)
    800049d4:	6442                	ld	s0,16(sp)
    800049d6:	64a2                	ld	s1,8(sp)
    800049d8:	6902                	ld	s2,0(sp)
    800049da:	6105                	addi	sp,sp,32
    800049dc:	8082                	ret

00000000800049de <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049de:	1101                	addi	sp,sp,-32
    800049e0:	ec06                	sd	ra,24(sp)
    800049e2:	e822                	sd	s0,16(sp)
    800049e4:	e426                	sd	s1,8(sp)
    800049e6:	e04a                	sd	s2,0(sp)
    800049e8:	1000                	addi	s0,sp,32
    800049ea:	84aa                	mv	s1,a0
    800049ec:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049ee:	00004597          	auipc	a1,0x4
    800049f2:	cba58593          	addi	a1,a1,-838 # 800086a8 <syscalls+0x248>
    800049f6:	0521                	addi	a0,a0,8
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	326080e7          	jalr	806(ra) # 80000d1e <initlock>
  lk->name = name;
    80004a00:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a04:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a08:	0204a423          	sw	zero,40(s1)
}
    80004a0c:	60e2                	ld	ra,24(sp)
    80004a0e:	6442                	ld	s0,16(sp)
    80004a10:	64a2                	ld	s1,8(sp)
    80004a12:	6902                	ld	s2,0(sp)
    80004a14:	6105                	addi	sp,sp,32
    80004a16:	8082                	ret

0000000080004a18 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a18:	1101                	addi	sp,sp,-32
    80004a1a:	ec06                	sd	ra,24(sp)
    80004a1c:	e822                	sd	s0,16(sp)
    80004a1e:	e426                	sd	s1,8(sp)
    80004a20:	e04a                	sd	s2,0(sp)
    80004a22:	1000                	addi	s0,sp,32
    80004a24:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a26:	00850913          	addi	s2,a0,8
    80004a2a:	854a                	mv	a0,s2
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	382080e7          	jalr	898(ra) # 80000dae <acquire>
  while (lk->locked) {
    80004a34:	409c                	lw	a5,0(s1)
    80004a36:	cb89                	beqz	a5,80004a48 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a38:	85ca                	mv	a1,s2
    80004a3a:	8526                	mv	a0,s1
    80004a3c:	ffffe097          	auipc	ra,0xffffe
    80004a40:	916080e7          	jalr	-1770(ra) # 80002352 <sleep>
  while (lk->locked) {
    80004a44:	409c                	lw	a5,0(s1)
    80004a46:	fbed                	bnez	a5,80004a38 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a48:	4785                	li	a5,1
    80004a4a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a4c:	ffffd097          	auipc	ra,0xffffd
    80004a50:	206080e7          	jalr	518(ra) # 80001c52 <myproc>
    80004a54:	591c                	lw	a5,48(a0)
    80004a56:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a58:	854a                	mv	a0,s2
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	408080e7          	jalr	1032(ra) # 80000e62 <release>
}
    80004a62:	60e2                	ld	ra,24(sp)
    80004a64:	6442                	ld	s0,16(sp)
    80004a66:	64a2                	ld	s1,8(sp)
    80004a68:	6902                	ld	s2,0(sp)
    80004a6a:	6105                	addi	sp,sp,32
    80004a6c:	8082                	ret

0000000080004a6e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a6e:	1101                	addi	sp,sp,-32
    80004a70:	ec06                	sd	ra,24(sp)
    80004a72:	e822                	sd	s0,16(sp)
    80004a74:	e426                	sd	s1,8(sp)
    80004a76:	e04a                	sd	s2,0(sp)
    80004a78:	1000                	addi	s0,sp,32
    80004a7a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a7c:	00850913          	addi	s2,a0,8
    80004a80:	854a                	mv	a0,s2
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	32c080e7          	jalr	812(ra) # 80000dae <acquire>
  lk->locked = 0;
    80004a8a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a8e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a92:	8526                	mv	a0,s1
    80004a94:	ffffe097          	auipc	ra,0xffffe
    80004a98:	922080e7          	jalr	-1758(ra) # 800023b6 <wakeup>
  release(&lk->lk);
    80004a9c:	854a                	mv	a0,s2
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	3c4080e7          	jalr	964(ra) # 80000e62 <release>
}
    80004aa6:	60e2                	ld	ra,24(sp)
    80004aa8:	6442                	ld	s0,16(sp)
    80004aaa:	64a2                	ld	s1,8(sp)
    80004aac:	6902                	ld	s2,0(sp)
    80004aae:	6105                	addi	sp,sp,32
    80004ab0:	8082                	ret

0000000080004ab2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ab2:	7179                	addi	sp,sp,-48
    80004ab4:	f406                	sd	ra,40(sp)
    80004ab6:	f022                	sd	s0,32(sp)
    80004ab8:	ec26                	sd	s1,24(sp)
    80004aba:	e84a                	sd	s2,16(sp)
    80004abc:	e44e                	sd	s3,8(sp)
    80004abe:	1800                	addi	s0,sp,48
    80004ac0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004ac2:	00850913          	addi	s2,a0,8
    80004ac6:	854a                	mv	a0,s2
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	2e6080e7          	jalr	742(ra) # 80000dae <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ad0:	409c                	lw	a5,0(s1)
    80004ad2:	ef99                	bnez	a5,80004af0 <holdingsleep+0x3e>
    80004ad4:	4481                	li	s1,0
  release(&lk->lk);
    80004ad6:	854a                	mv	a0,s2
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	38a080e7          	jalr	906(ra) # 80000e62 <release>
  return r;
}
    80004ae0:	8526                	mv	a0,s1
    80004ae2:	70a2                	ld	ra,40(sp)
    80004ae4:	7402                	ld	s0,32(sp)
    80004ae6:	64e2                	ld	s1,24(sp)
    80004ae8:	6942                	ld	s2,16(sp)
    80004aea:	69a2                	ld	s3,8(sp)
    80004aec:	6145                	addi	sp,sp,48
    80004aee:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004af0:	0284a983          	lw	s3,40(s1)
    80004af4:	ffffd097          	auipc	ra,0xffffd
    80004af8:	15e080e7          	jalr	350(ra) # 80001c52 <myproc>
    80004afc:	5904                	lw	s1,48(a0)
    80004afe:	413484b3          	sub	s1,s1,s3
    80004b02:	0014b493          	seqz	s1,s1
    80004b06:	bfc1                	j	80004ad6 <holdingsleep+0x24>

0000000080004b08 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b08:	1141                	addi	sp,sp,-16
    80004b0a:	e406                	sd	ra,8(sp)
    80004b0c:	e022                	sd	s0,0(sp)
    80004b0e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b10:	00004597          	auipc	a1,0x4
    80004b14:	ba858593          	addi	a1,a1,-1112 # 800086b8 <syscalls+0x258>
    80004b18:	0003d517          	auipc	a0,0x3d
    80004b1c:	39850513          	addi	a0,a0,920 # 80041eb0 <ftable>
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	1fe080e7          	jalr	510(ra) # 80000d1e <initlock>
}
    80004b28:	60a2                	ld	ra,8(sp)
    80004b2a:	6402                	ld	s0,0(sp)
    80004b2c:	0141                	addi	sp,sp,16
    80004b2e:	8082                	ret

0000000080004b30 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b30:	1101                	addi	sp,sp,-32
    80004b32:	ec06                	sd	ra,24(sp)
    80004b34:	e822                	sd	s0,16(sp)
    80004b36:	e426                	sd	s1,8(sp)
    80004b38:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b3a:	0003d517          	auipc	a0,0x3d
    80004b3e:	37650513          	addi	a0,a0,886 # 80041eb0 <ftable>
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	26c080e7          	jalr	620(ra) # 80000dae <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b4a:	0003d497          	auipc	s1,0x3d
    80004b4e:	37e48493          	addi	s1,s1,894 # 80041ec8 <ftable+0x18>
    80004b52:	0003e717          	auipc	a4,0x3e
    80004b56:	31670713          	addi	a4,a4,790 # 80042e68 <disk>
    if(f->ref == 0){
    80004b5a:	40dc                	lw	a5,4(s1)
    80004b5c:	cf99                	beqz	a5,80004b7a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b5e:	02848493          	addi	s1,s1,40
    80004b62:	fee49ce3          	bne	s1,a4,80004b5a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b66:	0003d517          	auipc	a0,0x3d
    80004b6a:	34a50513          	addi	a0,a0,842 # 80041eb0 <ftable>
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	2f4080e7          	jalr	756(ra) # 80000e62 <release>
  return 0;
    80004b76:	4481                	li	s1,0
    80004b78:	a819                	j	80004b8e <filealloc+0x5e>
      f->ref = 1;
    80004b7a:	4785                	li	a5,1
    80004b7c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b7e:	0003d517          	auipc	a0,0x3d
    80004b82:	33250513          	addi	a0,a0,818 # 80041eb0 <ftable>
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	2dc080e7          	jalr	732(ra) # 80000e62 <release>
}
    80004b8e:	8526                	mv	a0,s1
    80004b90:	60e2                	ld	ra,24(sp)
    80004b92:	6442                	ld	s0,16(sp)
    80004b94:	64a2                	ld	s1,8(sp)
    80004b96:	6105                	addi	sp,sp,32
    80004b98:	8082                	ret

0000000080004b9a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b9a:	1101                	addi	sp,sp,-32
    80004b9c:	ec06                	sd	ra,24(sp)
    80004b9e:	e822                	sd	s0,16(sp)
    80004ba0:	e426                	sd	s1,8(sp)
    80004ba2:	1000                	addi	s0,sp,32
    80004ba4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ba6:	0003d517          	auipc	a0,0x3d
    80004baa:	30a50513          	addi	a0,a0,778 # 80041eb0 <ftable>
    80004bae:	ffffc097          	auipc	ra,0xffffc
    80004bb2:	200080e7          	jalr	512(ra) # 80000dae <acquire>
  if(f->ref < 1)
    80004bb6:	40dc                	lw	a5,4(s1)
    80004bb8:	02f05263          	blez	a5,80004bdc <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004bbc:	2785                	addiw	a5,a5,1
    80004bbe:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bc0:	0003d517          	auipc	a0,0x3d
    80004bc4:	2f050513          	addi	a0,a0,752 # 80041eb0 <ftable>
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	29a080e7          	jalr	666(ra) # 80000e62 <release>
  return f;
}
    80004bd0:	8526                	mv	a0,s1
    80004bd2:	60e2                	ld	ra,24(sp)
    80004bd4:	6442                	ld	s0,16(sp)
    80004bd6:	64a2                	ld	s1,8(sp)
    80004bd8:	6105                	addi	sp,sp,32
    80004bda:	8082                	ret
    panic("filedup");
    80004bdc:	00004517          	auipc	a0,0x4
    80004be0:	ae450513          	addi	a0,a0,-1308 # 800086c0 <syscalls+0x260>
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	95c080e7          	jalr	-1700(ra) # 80000540 <panic>

0000000080004bec <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bec:	7139                	addi	sp,sp,-64
    80004bee:	fc06                	sd	ra,56(sp)
    80004bf0:	f822                	sd	s0,48(sp)
    80004bf2:	f426                	sd	s1,40(sp)
    80004bf4:	f04a                	sd	s2,32(sp)
    80004bf6:	ec4e                	sd	s3,24(sp)
    80004bf8:	e852                	sd	s4,16(sp)
    80004bfa:	e456                	sd	s5,8(sp)
    80004bfc:	0080                	addi	s0,sp,64
    80004bfe:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c00:	0003d517          	auipc	a0,0x3d
    80004c04:	2b050513          	addi	a0,a0,688 # 80041eb0 <ftable>
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	1a6080e7          	jalr	422(ra) # 80000dae <acquire>
  if(f->ref < 1)
    80004c10:	40dc                	lw	a5,4(s1)
    80004c12:	06f05163          	blez	a5,80004c74 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c16:	37fd                	addiw	a5,a5,-1
    80004c18:	0007871b          	sext.w	a4,a5
    80004c1c:	c0dc                	sw	a5,4(s1)
    80004c1e:	06e04363          	bgtz	a4,80004c84 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c22:	0004a903          	lw	s2,0(s1)
    80004c26:	0094ca83          	lbu	s5,9(s1)
    80004c2a:	0104ba03          	ld	s4,16(s1)
    80004c2e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c32:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c36:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c3a:	0003d517          	auipc	a0,0x3d
    80004c3e:	27650513          	addi	a0,a0,630 # 80041eb0 <ftable>
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	220080e7          	jalr	544(ra) # 80000e62 <release>

  if(ff.type == FD_PIPE){
    80004c4a:	4785                	li	a5,1
    80004c4c:	04f90d63          	beq	s2,a5,80004ca6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c50:	3979                	addiw	s2,s2,-2
    80004c52:	4785                	li	a5,1
    80004c54:	0527e063          	bltu	a5,s2,80004c94 <fileclose+0xa8>
    begin_op();
    80004c58:	00000097          	auipc	ra,0x0
    80004c5c:	acc080e7          	jalr	-1332(ra) # 80004724 <begin_op>
    iput(ff.ip);
    80004c60:	854e                	mv	a0,s3
    80004c62:	fffff097          	auipc	ra,0xfffff
    80004c66:	2b0080e7          	jalr	688(ra) # 80003f12 <iput>
    end_op();
    80004c6a:	00000097          	auipc	ra,0x0
    80004c6e:	b38080e7          	jalr	-1224(ra) # 800047a2 <end_op>
    80004c72:	a00d                	j	80004c94 <fileclose+0xa8>
    panic("fileclose");
    80004c74:	00004517          	auipc	a0,0x4
    80004c78:	a5450513          	addi	a0,a0,-1452 # 800086c8 <syscalls+0x268>
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	8c4080e7          	jalr	-1852(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004c84:	0003d517          	auipc	a0,0x3d
    80004c88:	22c50513          	addi	a0,a0,556 # 80041eb0 <ftable>
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	1d6080e7          	jalr	470(ra) # 80000e62 <release>
  }
}
    80004c94:	70e2                	ld	ra,56(sp)
    80004c96:	7442                	ld	s0,48(sp)
    80004c98:	74a2                	ld	s1,40(sp)
    80004c9a:	7902                	ld	s2,32(sp)
    80004c9c:	69e2                	ld	s3,24(sp)
    80004c9e:	6a42                	ld	s4,16(sp)
    80004ca0:	6aa2                	ld	s5,8(sp)
    80004ca2:	6121                	addi	sp,sp,64
    80004ca4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ca6:	85d6                	mv	a1,s5
    80004ca8:	8552                	mv	a0,s4
    80004caa:	00000097          	auipc	ra,0x0
    80004cae:	34c080e7          	jalr	844(ra) # 80004ff6 <pipeclose>
    80004cb2:	b7cd                	j	80004c94 <fileclose+0xa8>

0000000080004cb4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004cb4:	715d                	addi	sp,sp,-80
    80004cb6:	e486                	sd	ra,72(sp)
    80004cb8:	e0a2                	sd	s0,64(sp)
    80004cba:	fc26                	sd	s1,56(sp)
    80004cbc:	f84a                	sd	s2,48(sp)
    80004cbe:	f44e                	sd	s3,40(sp)
    80004cc0:	0880                	addi	s0,sp,80
    80004cc2:	84aa                	mv	s1,a0
    80004cc4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	f8c080e7          	jalr	-116(ra) # 80001c52 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004cce:	409c                	lw	a5,0(s1)
    80004cd0:	37f9                	addiw	a5,a5,-2
    80004cd2:	4705                	li	a4,1
    80004cd4:	04f76763          	bltu	a4,a5,80004d22 <filestat+0x6e>
    80004cd8:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cda:	6c88                	ld	a0,24(s1)
    80004cdc:	fffff097          	auipc	ra,0xfffff
    80004ce0:	07c080e7          	jalr	124(ra) # 80003d58 <ilock>
    stati(f->ip, &st);
    80004ce4:	fb840593          	addi	a1,s0,-72
    80004ce8:	6c88                	ld	a0,24(s1)
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	2f8080e7          	jalr	760(ra) # 80003fe2 <stati>
    iunlock(f->ip);
    80004cf2:	6c88                	ld	a0,24(s1)
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	126080e7          	jalr	294(ra) # 80003e1a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cfc:	46e1                	li	a3,24
    80004cfe:	fb840613          	addi	a2,s0,-72
    80004d02:	85ce                	mv	a1,s3
    80004d04:	05093503          	ld	a0,80(s2)
    80004d08:	ffffd097          	auipc	ra,0xffffd
    80004d0c:	d34080e7          	jalr	-716(ra) # 80001a3c <copyout>
    80004d10:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d14:	60a6                	ld	ra,72(sp)
    80004d16:	6406                	ld	s0,64(sp)
    80004d18:	74e2                	ld	s1,56(sp)
    80004d1a:	7942                	ld	s2,48(sp)
    80004d1c:	79a2                	ld	s3,40(sp)
    80004d1e:	6161                	addi	sp,sp,80
    80004d20:	8082                	ret
  return -1;
    80004d22:	557d                	li	a0,-1
    80004d24:	bfc5                	j	80004d14 <filestat+0x60>

0000000080004d26 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d26:	7179                	addi	sp,sp,-48
    80004d28:	f406                	sd	ra,40(sp)
    80004d2a:	f022                	sd	s0,32(sp)
    80004d2c:	ec26                	sd	s1,24(sp)
    80004d2e:	e84a                	sd	s2,16(sp)
    80004d30:	e44e                	sd	s3,8(sp)
    80004d32:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d34:	00854783          	lbu	a5,8(a0)
    80004d38:	c3d5                	beqz	a5,80004ddc <fileread+0xb6>
    80004d3a:	84aa                	mv	s1,a0
    80004d3c:	89ae                	mv	s3,a1
    80004d3e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d40:	411c                	lw	a5,0(a0)
    80004d42:	4705                	li	a4,1
    80004d44:	04e78963          	beq	a5,a4,80004d96 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d48:	470d                	li	a4,3
    80004d4a:	04e78d63          	beq	a5,a4,80004da4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d4e:	4709                	li	a4,2
    80004d50:	06e79e63          	bne	a5,a4,80004dcc <fileread+0xa6>
    ilock(f->ip);
    80004d54:	6d08                	ld	a0,24(a0)
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	002080e7          	jalr	2(ra) # 80003d58 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d5e:	874a                	mv	a4,s2
    80004d60:	5094                	lw	a3,32(s1)
    80004d62:	864e                	mv	a2,s3
    80004d64:	4585                	li	a1,1
    80004d66:	6c88                	ld	a0,24(s1)
    80004d68:	fffff097          	auipc	ra,0xfffff
    80004d6c:	2a4080e7          	jalr	676(ra) # 8000400c <readi>
    80004d70:	892a                	mv	s2,a0
    80004d72:	00a05563          	blez	a0,80004d7c <fileread+0x56>
      f->off += r;
    80004d76:	509c                	lw	a5,32(s1)
    80004d78:	9fa9                	addw	a5,a5,a0
    80004d7a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d7c:	6c88                	ld	a0,24(s1)
    80004d7e:	fffff097          	auipc	ra,0xfffff
    80004d82:	09c080e7          	jalr	156(ra) # 80003e1a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d86:	854a                	mv	a0,s2
    80004d88:	70a2                	ld	ra,40(sp)
    80004d8a:	7402                	ld	s0,32(sp)
    80004d8c:	64e2                	ld	s1,24(sp)
    80004d8e:	6942                	ld	s2,16(sp)
    80004d90:	69a2                	ld	s3,8(sp)
    80004d92:	6145                	addi	sp,sp,48
    80004d94:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d96:	6908                	ld	a0,16(a0)
    80004d98:	00000097          	auipc	ra,0x0
    80004d9c:	3c6080e7          	jalr	966(ra) # 8000515e <piperead>
    80004da0:	892a                	mv	s2,a0
    80004da2:	b7d5                	j	80004d86 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004da4:	02451783          	lh	a5,36(a0)
    80004da8:	03079693          	slli	a3,a5,0x30
    80004dac:	92c1                	srli	a3,a3,0x30
    80004dae:	4725                	li	a4,9
    80004db0:	02d76863          	bltu	a4,a3,80004de0 <fileread+0xba>
    80004db4:	0792                	slli	a5,a5,0x4
    80004db6:	0003d717          	auipc	a4,0x3d
    80004dba:	05a70713          	addi	a4,a4,90 # 80041e10 <devsw>
    80004dbe:	97ba                	add	a5,a5,a4
    80004dc0:	639c                	ld	a5,0(a5)
    80004dc2:	c38d                	beqz	a5,80004de4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004dc4:	4505                	li	a0,1
    80004dc6:	9782                	jalr	a5
    80004dc8:	892a                	mv	s2,a0
    80004dca:	bf75                	j	80004d86 <fileread+0x60>
    panic("fileread");
    80004dcc:	00004517          	auipc	a0,0x4
    80004dd0:	90c50513          	addi	a0,a0,-1780 # 800086d8 <syscalls+0x278>
    80004dd4:	ffffb097          	auipc	ra,0xffffb
    80004dd8:	76c080e7          	jalr	1900(ra) # 80000540 <panic>
    return -1;
    80004ddc:	597d                	li	s2,-1
    80004dde:	b765                	j	80004d86 <fileread+0x60>
      return -1;
    80004de0:	597d                	li	s2,-1
    80004de2:	b755                	j	80004d86 <fileread+0x60>
    80004de4:	597d                	li	s2,-1
    80004de6:	b745                	j	80004d86 <fileread+0x60>

0000000080004de8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004de8:	715d                	addi	sp,sp,-80
    80004dea:	e486                	sd	ra,72(sp)
    80004dec:	e0a2                	sd	s0,64(sp)
    80004dee:	fc26                	sd	s1,56(sp)
    80004df0:	f84a                	sd	s2,48(sp)
    80004df2:	f44e                	sd	s3,40(sp)
    80004df4:	f052                	sd	s4,32(sp)
    80004df6:	ec56                	sd	s5,24(sp)
    80004df8:	e85a                	sd	s6,16(sp)
    80004dfa:	e45e                	sd	s7,8(sp)
    80004dfc:	e062                	sd	s8,0(sp)
    80004dfe:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e00:	00954783          	lbu	a5,9(a0)
    80004e04:	10078663          	beqz	a5,80004f10 <filewrite+0x128>
    80004e08:	892a                	mv	s2,a0
    80004e0a:	8b2e                	mv	s6,a1
    80004e0c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e0e:	411c                	lw	a5,0(a0)
    80004e10:	4705                	li	a4,1
    80004e12:	02e78263          	beq	a5,a4,80004e36 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e16:	470d                	li	a4,3
    80004e18:	02e78663          	beq	a5,a4,80004e44 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e1c:	4709                	li	a4,2
    80004e1e:	0ee79163          	bne	a5,a4,80004f00 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e22:	0ac05d63          	blez	a2,80004edc <filewrite+0xf4>
    int i = 0;
    80004e26:	4981                	li	s3,0
    80004e28:	6b85                	lui	s7,0x1
    80004e2a:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004e2e:	6c05                	lui	s8,0x1
    80004e30:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004e34:	a861                	j	80004ecc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e36:	6908                	ld	a0,16(a0)
    80004e38:	00000097          	auipc	ra,0x0
    80004e3c:	22e080e7          	jalr	558(ra) # 80005066 <pipewrite>
    80004e40:	8a2a                	mv	s4,a0
    80004e42:	a045                	j	80004ee2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e44:	02451783          	lh	a5,36(a0)
    80004e48:	03079693          	slli	a3,a5,0x30
    80004e4c:	92c1                	srli	a3,a3,0x30
    80004e4e:	4725                	li	a4,9
    80004e50:	0cd76263          	bltu	a4,a3,80004f14 <filewrite+0x12c>
    80004e54:	0792                	slli	a5,a5,0x4
    80004e56:	0003d717          	auipc	a4,0x3d
    80004e5a:	fba70713          	addi	a4,a4,-70 # 80041e10 <devsw>
    80004e5e:	97ba                	add	a5,a5,a4
    80004e60:	679c                	ld	a5,8(a5)
    80004e62:	cbdd                	beqz	a5,80004f18 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e64:	4505                	li	a0,1
    80004e66:	9782                	jalr	a5
    80004e68:	8a2a                	mv	s4,a0
    80004e6a:	a8a5                	j	80004ee2 <filewrite+0xfa>
    80004e6c:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e70:	00000097          	auipc	ra,0x0
    80004e74:	8b4080e7          	jalr	-1868(ra) # 80004724 <begin_op>
      ilock(f->ip);
    80004e78:	01893503          	ld	a0,24(s2)
    80004e7c:	fffff097          	auipc	ra,0xfffff
    80004e80:	edc080e7          	jalr	-292(ra) # 80003d58 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e84:	8756                	mv	a4,s5
    80004e86:	02092683          	lw	a3,32(s2)
    80004e8a:	01698633          	add	a2,s3,s6
    80004e8e:	4585                	li	a1,1
    80004e90:	01893503          	ld	a0,24(s2)
    80004e94:	fffff097          	auipc	ra,0xfffff
    80004e98:	270080e7          	jalr	624(ra) # 80004104 <writei>
    80004e9c:	84aa                	mv	s1,a0
    80004e9e:	00a05763          	blez	a0,80004eac <filewrite+0xc4>
        f->off += r;
    80004ea2:	02092783          	lw	a5,32(s2)
    80004ea6:	9fa9                	addw	a5,a5,a0
    80004ea8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004eac:	01893503          	ld	a0,24(s2)
    80004eb0:	fffff097          	auipc	ra,0xfffff
    80004eb4:	f6a080e7          	jalr	-150(ra) # 80003e1a <iunlock>
      end_op();
    80004eb8:	00000097          	auipc	ra,0x0
    80004ebc:	8ea080e7          	jalr	-1814(ra) # 800047a2 <end_op>

      if(r != n1){
    80004ec0:	009a9f63          	bne	s5,s1,80004ede <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ec4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ec8:	0149db63          	bge	s3,s4,80004ede <filewrite+0xf6>
      int n1 = n - i;
    80004ecc:	413a04bb          	subw	s1,s4,s3
    80004ed0:	0004879b          	sext.w	a5,s1
    80004ed4:	f8fbdce3          	bge	s7,a5,80004e6c <filewrite+0x84>
    80004ed8:	84e2                	mv	s1,s8
    80004eda:	bf49                	j	80004e6c <filewrite+0x84>
    int i = 0;
    80004edc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ede:	013a1f63          	bne	s4,s3,80004efc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ee2:	8552                	mv	a0,s4
    80004ee4:	60a6                	ld	ra,72(sp)
    80004ee6:	6406                	ld	s0,64(sp)
    80004ee8:	74e2                	ld	s1,56(sp)
    80004eea:	7942                	ld	s2,48(sp)
    80004eec:	79a2                	ld	s3,40(sp)
    80004eee:	7a02                	ld	s4,32(sp)
    80004ef0:	6ae2                	ld	s5,24(sp)
    80004ef2:	6b42                	ld	s6,16(sp)
    80004ef4:	6ba2                	ld	s7,8(sp)
    80004ef6:	6c02                	ld	s8,0(sp)
    80004ef8:	6161                	addi	sp,sp,80
    80004efa:	8082                	ret
    ret = (i == n ? n : -1);
    80004efc:	5a7d                	li	s4,-1
    80004efe:	b7d5                	j	80004ee2 <filewrite+0xfa>
    panic("filewrite");
    80004f00:	00003517          	auipc	a0,0x3
    80004f04:	7e850513          	addi	a0,a0,2024 # 800086e8 <syscalls+0x288>
    80004f08:	ffffb097          	auipc	ra,0xffffb
    80004f0c:	638080e7          	jalr	1592(ra) # 80000540 <panic>
    return -1;
    80004f10:	5a7d                	li	s4,-1
    80004f12:	bfc1                	j	80004ee2 <filewrite+0xfa>
      return -1;
    80004f14:	5a7d                	li	s4,-1
    80004f16:	b7f1                	j	80004ee2 <filewrite+0xfa>
    80004f18:	5a7d                	li	s4,-1
    80004f1a:	b7e1                	j	80004ee2 <filewrite+0xfa>

0000000080004f1c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f1c:	7179                	addi	sp,sp,-48
    80004f1e:	f406                	sd	ra,40(sp)
    80004f20:	f022                	sd	s0,32(sp)
    80004f22:	ec26                	sd	s1,24(sp)
    80004f24:	e84a                	sd	s2,16(sp)
    80004f26:	e44e                	sd	s3,8(sp)
    80004f28:	e052                	sd	s4,0(sp)
    80004f2a:	1800                	addi	s0,sp,48
    80004f2c:	84aa                	mv	s1,a0
    80004f2e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f30:	0005b023          	sd	zero,0(a1)
    80004f34:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f38:	00000097          	auipc	ra,0x0
    80004f3c:	bf8080e7          	jalr	-1032(ra) # 80004b30 <filealloc>
    80004f40:	e088                	sd	a0,0(s1)
    80004f42:	c551                	beqz	a0,80004fce <pipealloc+0xb2>
    80004f44:	00000097          	auipc	ra,0x0
    80004f48:	bec080e7          	jalr	-1044(ra) # 80004b30 <filealloc>
    80004f4c:	00aa3023          	sd	a0,0(s4)
    80004f50:	c92d                	beqz	a0,80004fc2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	a96080e7          	jalr	-1386(ra) # 800009e8 <kalloc>
    80004f5a:	892a                	mv	s2,a0
    80004f5c:	c125                	beqz	a0,80004fbc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f5e:	4985                	li	s3,1
    80004f60:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f64:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f68:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f6c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f70:	00003597          	auipc	a1,0x3
    80004f74:	78858593          	addi	a1,a1,1928 # 800086f8 <syscalls+0x298>
    80004f78:	ffffc097          	auipc	ra,0xffffc
    80004f7c:	da6080e7          	jalr	-602(ra) # 80000d1e <initlock>
  (*f0)->type = FD_PIPE;
    80004f80:	609c                	ld	a5,0(s1)
    80004f82:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f86:	609c                	ld	a5,0(s1)
    80004f88:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f8c:	609c                	ld	a5,0(s1)
    80004f8e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f92:	609c                	ld	a5,0(s1)
    80004f94:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f98:	000a3783          	ld	a5,0(s4)
    80004f9c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004fa0:	000a3783          	ld	a5,0(s4)
    80004fa4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004fa8:	000a3783          	ld	a5,0(s4)
    80004fac:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004fb0:	000a3783          	ld	a5,0(s4)
    80004fb4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004fb8:	4501                	li	a0,0
    80004fba:	a025                	j	80004fe2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004fbc:	6088                	ld	a0,0(s1)
    80004fbe:	e501                	bnez	a0,80004fc6 <pipealloc+0xaa>
    80004fc0:	a039                	j	80004fce <pipealloc+0xb2>
    80004fc2:	6088                	ld	a0,0(s1)
    80004fc4:	c51d                	beqz	a0,80004ff2 <pipealloc+0xd6>
    fileclose(*f0);
    80004fc6:	00000097          	auipc	ra,0x0
    80004fca:	c26080e7          	jalr	-986(ra) # 80004bec <fileclose>
  if(*f1)
    80004fce:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004fd2:	557d                	li	a0,-1
  if(*f1)
    80004fd4:	c799                	beqz	a5,80004fe2 <pipealloc+0xc6>
    fileclose(*f1);
    80004fd6:	853e                	mv	a0,a5
    80004fd8:	00000097          	auipc	ra,0x0
    80004fdc:	c14080e7          	jalr	-1004(ra) # 80004bec <fileclose>
  return -1;
    80004fe0:	557d                	li	a0,-1
}
    80004fe2:	70a2                	ld	ra,40(sp)
    80004fe4:	7402                	ld	s0,32(sp)
    80004fe6:	64e2                	ld	s1,24(sp)
    80004fe8:	6942                	ld	s2,16(sp)
    80004fea:	69a2                	ld	s3,8(sp)
    80004fec:	6a02                	ld	s4,0(sp)
    80004fee:	6145                	addi	sp,sp,48
    80004ff0:	8082                	ret
  return -1;
    80004ff2:	557d                	li	a0,-1
    80004ff4:	b7fd                	j	80004fe2 <pipealloc+0xc6>

0000000080004ff6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ff6:	1101                	addi	sp,sp,-32
    80004ff8:	ec06                	sd	ra,24(sp)
    80004ffa:	e822                	sd	s0,16(sp)
    80004ffc:	e426                	sd	s1,8(sp)
    80004ffe:	e04a                	sd	s2,0(sp)
    80005000:	1000                	addi	s0,sp,32
    80005002:	84aa                	mv	s1,a0
    80005004:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	da8080e7          	jalr	-600(ra) # 80000dae <acquire>
  if(writable){
    8000500e:	02090d63          	beqz	s2,80005048 <pipeclose+0x52>
    pi->writeopen = 0;
    80005012:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005016:	21848513          	addi	a0,s1,536
    8000501a:	ffffd097          	auipc	ra,0xffffd
    8000501e:	39c080e7          	jalr	924(ra) # 800023b6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005022:	2204b783          	ld	a5,544(s1)
    80005026:	eb95                	bnez	a5,8000505a <pipeclose+0x64>
    release(&pi->lock);
    80005028:	8526                	mv	a0,s1
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	e38080e7          	jalr	-456(ra) # 80000e62 <release>
    kfree((char*)pi);
    80005032:	8526                	mv	a0,s1
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	b50080e7          	jalr	-1200(ra) # 80000b84 <kfree>
  } else
    release(&pi->lock);
}
    8000503c:	60e2                	ld	ra,24(sp)
    8000503e:	6442                	ld	s0,16(sp)
    80005040:	64a2                	ld	s1,8(sp)
    80005042:	6902                	ld	s2,0(sp)
    80005044:	6105                	addi	sp,sp,32
    80005046:	8082                	ret
    pi->readopen = 0;
    80005048:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000504c:	21c48513          	addi	a0,s1,540
    80005050:	ffffd097          	auipc	ra,0xffffd
    80005054:	366080e7          	jalr	870(ra) # 800023b6 <wakeup>
    80005058:	b7e9                	j	80005022 <pipeclose+0x2c>
    release(&pi->lock);
    8000505a:	8526                	mv	a0,s1
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	e06080e7          	jalr	-506(ra) # 80000e62 <release>
}
    80005064:	bfe1                	j	8000503c <pipeclose+0x46>

0000000080005066 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005066:	711d                	addi	sp,sp,-96
    80005068:	ec86                	sd	ra,88(sp)
    8000506a:	e8a2                	sd	s0,80(sp)
    8000506c:	e4a6                	sd	s1,72(sp)
    8000506e:	e0ca                	sd	s2,64(sp)
    80005070:	fc4e                	sd	s3,56(sp)
    80005072:	f852                	sd	s4,48(sp)
    80005074:	f456                	sd	s5,40(sp)
    80005076:	f05a                	sd	s6,32(sp)
    80005078:	ec5e                	sd	s7,24(sp)
    8000507a:	e862                	sd	s8,16(sp)
    8000507c:	1080                	addi	s0,sp,96
    8000507e:	84aa                	mv	s1,a0
    80005080:	8aae                	mv	s5,a1
    80005082:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	bce080e7          	jalr	-1074(ra) # 80001c52 <myproc>
    8000508c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000508e:	8526                	mv	a0,s1
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	d1e080e7          	jalr	-738(ra) # 80000dae <acquire>
  while(i < n){
    80005098:	0b405663          	blez	s4,80005144 <pipewrite+0xde>
  int i = 0;
    8000509c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000509e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800050a0:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800050a4:	21c48b93          	addi	s7,s1,540
    800050a8:	a089                	j	800050ea <pipewrite+0x84>
      release(&pi->lock);
    800050aa:	8526                	mv	a0,s1
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	db6080e7          	jalr	-586(ra) # 80000e62 <release>
      return -1;
    800050b4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800050b6:	854a                	mv	a0,s2
    800050b8:	60e6                	ld	ra,88(sp)
    800050ba:	6446                	ld	s0,80(sp)
    800050bc:	64a6                	ld	s1,72(sp)
    800050be:	6906                	ld	s2,64(sp)
    800050c0:	79e2                	ld	s3,56(sp)
    800050c2:	7a42                	ld	s4,48(sp)
    800050c4:	7aa2                	ld	s5,40(sp)
    800050c6:	7b02                	ld	s6,32(sp)
    800050c8:	6be2                	ld	s7,24(sp)
    800050ca:	6c42                	ld	s8,16(sp)
    800050cc:	6125                	addi	sp,sp,96
    800050ce:	8082                	ret
      wakeup(&pi->nread);
    800050d0:	8562                	mv	a0,s8
    800050d2:	ffffd097          	auipc	ra,0xffffd
    800050d6:	2e4080e7          	jalr	740(ra) # 800023b6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050da:	85a6                	mv	a1,s1
    800050dc:	855e                	mv	a0,s7
    800050de:	ffffd097          	auipc	ra,0xffffd
    800050e2:	274080e7          	jalr	628(ra) # 80002352 <sleep>
  while(i < n){
    800050e6:	07495063          	bge	s2,s4,80005146 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800050ea:	2204a783          	lw	a5,544(s1)
    800050ee:	dfd5                	beqz	a5,800050aa <pipewrite+0x44>
    800050f0:	854e                	mv	a0,s3
    800050f2:	ffffd097          	auipc	ra,0xffffd
    800050f6:	514080e7          	jalr	1300(ra) # 80002606 <killed>
    800050fa:	f945                	bnez	a0,800050aa <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050fc:	2184a783          	lw	a5,536(s1)
    80005100:	21c4a703          	lw	a4,540(s1)
    80005104:	2007879b          	addiw	a5,a5,512
    80005108:	fcf704e3          	beq	a4,a5,800050d0 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000510c:	4685                	li	a3,1
    8000510e:	01590633          	add	a2,s2,s5
    80005112:	faf40593          	addi	a1,s0,-81
    80005116:	0509b503          	ld	a0,80(s3)
    8000511a:	ffffc097          	auipc	ra,0xffffc
    8000511e:	728080e7          	jalr	1832(ra) # 80001842 <copyin>
    80005122:	03650263          	beq	a0,s6,80005146 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005126:	21c4a783          	lw	a5,540(s1)
    8000512a:	0017871b          	addiw	a4,a5,1
    8000512e:	20e4ae23          	sw	a4,540(s1)
    80005132:	1ff7f793          	andi	a5,a5,511
    80005136:	97a6                	add	a5,a5,s1
    80005138:	faf44703          	lbu	a4,-81(s0)
    8000513c:	00e78c23          	sb	a4,24(a5)
      i++;
    80005140:	2905                	addiw	s2,s2,1
    80005142:	b755                	j	800050e6 <pipewrite+0x80>
  int i = 0;
    80005144:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005146:	21848513          	addi	a0,s1,536
    8000514a:	ffffd097          	auipc	ra,0xffffd
    8000514e:	26c080e7          	jalr	620(ra) # 800023b6 <wakeup>
  release(&pi->lock);
    80005152:	8526                	mv	a0,s1
    80005154:	ffffc097          	auipc	ra,0xffffc
    80005158:	d0e080e7          	jalr	-754(ra) # 80000e62 <release>
  return i;
    8000515c:	bfa9                	j	800050b6 <pipewrite+0x50>

000000008000515e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000515e:	715d                	addi	sp,sp,-80
    80005160:	e486                	sd	ra,72(sp)
    80005162:	e0a2                	sd	s0,64(sp)
    80005164:	fc26                	sd	s1,56(sp)
    80005166:	f84a                	sd	s2,48(sp)
    80005168:	f44e                	sd	s3,40(sp)
    8000516a:	f052                	sd	s4,32(sp)
    8000516c:	ec56                	sd	s5,24(sp)
    8000516e:	e85a                	sd	s6,16(sp)
    80005170:	0880                	addi	s0,sp,80
    80005172:	84aa                	mv	s1,a0
    80005174:	892e                	mv	s2,a1
    80005176:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005178:	ffffd097          	auipc	ra,0xffffd
    8000517c:	ada080e7          	jalr	-1318(ra) # 80001c52 <myproc>
    80005180:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005182:	8526                	mv	a0,s1
    80005184:	ffffc097          	auipc	ra,0xffffc
    80005188:	c2a080e7          	jalr	-982(ra) # 80000dae <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000518c:	2184a703          	lw	a4,536(s1)
    80005190:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005194:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005198:	02f71763          	bne	a4,a5,800051c6 <piperead+0x68>
    8000519c:	2244a783          	lw	a5,548(s1)
    800051a0:	c39d                	beqz	a5,800051c6 <piperead+0x68>
    if(killed(pr)){
    800051a2:	8552                	mv	a0,s4
    800051a4:	ffffd097          	auipc	ra,0xffffd
    800051a8:	462080e7          	jalr	1122(ra) # 80002606 <killed>
    800051ac:	e949                	bnez	a0,8000523e <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051ae:	85a6                	mv	a1,s1
    800051b0:	854e                	mv	a0,s3
    800051b2:	ffffd097          	auipc	ra,0xffffd
    800051b6:	1a0080e7          	jalr	416(ra) # 80002352 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051ba:	2184a703          	lw	a4,536(s1)
    800051be:	21c4a783          	lw	a5,540(s1)
    800051c2:	fcf70de3          	beq	a4,a5,8000519c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051c6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051c8:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051ca:	05505463          	blez	s5,80005212 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800051ce:	2184a783          	lw	a5,536(s1)
    800051d2:	21c4a703          	lw	a4,540(s1)
    800051d6:	02f70e63          	beq	a4,a5,80005212 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051da:	0017871b          	addiw	a4,a5,1
    800051de:	20e4ac23          	sw	a4,536(s1)
    800051e2:	1ff7f793          	andi	a5,a5,511
    800051e6:	97a6                	add	a5,a5,s1
    800051e8:	0187c783          	lbu	a5,24(a5)
    800051ec:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051f0:	4685                	li	a3,1
    800051f2:	fbf40613          	addi	a2,s0,-65
    800051f6:	85ca                	mv	a1,s2
    800051f8:	050a3503          	ld	a0,80(s4)
    800051fc:	ffffd097          	auipc	ra,0xffffd
    80005200:	840080e7          	jalr	-1984(ra) # 80001a3c <copyout>
    80005204:	01650763          	beq	a0,s6,80005212 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005208:	2985                	addiw	s3,s3,1
    8000520a:	0905                	addi	s2,s2,1
    8000520c:	fd3a91e3          	bne	s5,s3,800051ce <piperead+0x70>
    80005210:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005212:	21c48513          	addi	a0,s1,540
    80005216:	ffffd097          	auipc	ra,0xffffd
    8000521a:	1a0080e7          	jalr	416(ra) # 800023b6 <wakeup>
  release(&pi->lock);
    8000521e:	8526                	mv	a0,s1
    80005220:	ffffc097          	auipc	ra,0xffffc
    80005224:	c42080e7          	jalr	-958(ra) # 80000e62 <release>
  return i;
}
    80005228:	854e                	mv	a0,s3
    8000522a:	60a6                	ld	ra,72(sp)
    8000522c:	6406                	ld	s0,64(sp)
    8000522e:	74e2                	ld	s1,56(sp)
    80005230:	7942                	ld	s2,48(sp)
    80005232:	79a2                	ld	s3,40(sp)
    80005234:	7a02                	ld	s4,32(sp)
    80005236:	6ae2                	ld	s5,24(sp)
    80005238:	6b42                	ld	s6,16(sp)
    8000523a:	6161                	addi	sp,sp,80
    8000523c:	8082                	ret
      release(&pi->lock);
    8000523e:	8526                	mv	a0,s1
    80005240:	ffffc097          	auipc	ra,0xffffc
    80005244:	c22080e7          	jalr	-990(ra) # 80000e62 <release>
      return -1;
    80005248:	59fd                	li	s3,-1
    8000524a:	bff9                	j	80005228 <piperead+0xca>

000000008000524c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000524c:	1141                	addi	sp,sp,-16
    8000524e:	e422                	sd	s0,8(sp)
    80005250:	0800                	addi	s0,sp,16
    80005252:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005254:	8905                	andi	a0,a0,1
    80005256:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005258:	8b89                	andi	a5,a5,2
    8000525a:	c399                	beqz	a5,80005260 <flags2perm+0x14>
      perm |= PTE_W;
    8000525c:	00456513          	ori	a0,a0,4
    return perm;
}
    80005260:	6422                	ld	s0,8(sp)
    80005262:	0141                	addi	sp,sp,16
    80005264:	8082                	ret

0000000080005266 <exec>:

int
exec(char *path, char **argv)
{
    80005266:	de010113          	addi	sp,sp,-544
    8000526a:	20113c23          	sd	ra,536(sp)
    8000526e:	20813823          	sd	s0,528(sp)
    80005272:	20913423          	sd	s1,520(sp)
    80005276:	21213023          	sd	s2,512(sp)
    8000527a:	ffce                	sd	s3,504(sp)
    8000527c:	fbd2                	sd	s4,496(sp)
    8000527e:	f7d6                	sd	s5,488(sp)
    80005280:	f3da                	sd	s6,480(sp)
    80005282:	efde                	sd	s7,472(sp)
    80005284:	ebe2                	sd	s8,464(sp)
    80005286:	e7e6                	sd	s9,456(sp)
    80005288:	e3ea                	sd	s10,448(sp)
    8000528a:	ff6e                	sd	s11,440(sp)
    8000528c:	1400                	addi	s0,sp,544
    8000528e:	892a                	mv	s2,a0
    80005290:	dea43423          	sd	a0,-536(s0)
    80005294:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005298:	ffffd097          	auipc	ra,0xffffd
    8000529c:	9ba080e7          	jalr	-1606(ra) # 80001c52 <myproc>
    800052a0:	84aa                	mv	s1,a0

  begin_op();
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	482080e7          	jalr	1154(ra) # 80004724 <begin_op>

  if((ip = namei(path)) == 0){
    800052aa:	854a                	mv	a0,s2
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	258080e7          	jalr	600(ra) # 80004504 <namei>
    800052b4:	c93d                	beqz	a0,8000532a <exec+0xc4>
    800052b6:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	aa0080e7          	jalr	-1376(ra) # 80003d58 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800052c0:	04000713          	li	a4,64
    800052c4:	4681                	li	a3,0
    800052c6:	e5040613          	addi	a2,s0,-432
    800052ca:	4581                	li	a1,0
    800052cc:	8556                	mv	a0,s5
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	d3e080e7          	jalr	-706(ra) # 8000400c <readi>
    800052d6:	04000793          	li	a5,64
    800052da:	00f51a63          	bne	a0,a5,800052ee <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800052de:	e5042703          	lw	a4,-432(s0)
    800052e2:	464c47b7          	lui	a5,0x464c4
    800052e6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052ea:	04f70663          	beq	a4,a5,80005336 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052ee:	8556                	mv	a0,s5
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	cca080e7          	jalr	-822(ra) # 80003fba <iunlockput>
    end_op();
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	4aa080e7          	jalr	1194(ra) # 800047a2 <end_op>
  }
  return -1;
    80005300:	557d                	li	a0,-1
}
    80005302:	21813083          	ld	ra,536(sp)
    80005306:	21013403          	ld	s0,528(sp)
    8000530a:	20813483          	ld	s1,520(sp)
    8000530e:	20013903          	ld	s2,512(sp)
    80005312:	79fe                	ld	s3,504(sp)
    80005314:	7a5e                	ld	s4,496(sp)
    80005316:	7abe                	ld	s5,488(sp)
    80005318:	7b1e                	ld	s6,480(sp)
    8000531a:	6bfe                	ld	s7,472(sp)
    8000531c:	6c5e                	ld	s8,464(sp)
    8000531e:	6cbe                	ld	s9,456(sp)
    80005320:	6d1e                	ld	s10,448(sp)
    80005322:	7dfa                	ld	s11,440(sp)
    80005324:	22010113          	addi	sp,sp,544
    80005328:	8082                	ret
    end_op();
    8000532a:	fffff097          	auipc	ra,0xfffff
    8000532e:	478080e7          	jalr	1144(ra) # 800047a2 <end_op>
    return -1;
    80005332:	557d                	li	a0,-1
    80005334:	b7f9                	j	80005302 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005336:	8526                	mv	a0,s1
    80005338:	ffffd097          	auipc	ra,0xffffd
    8000533c:	9de080e7          	jalr	-1570(ra) # 80001d16 <proc_pagetable>
    80005340:	8b2a                	mv	s6,a0
    80005342:	d555                	beqz	a0,800052ee <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005344:	e7042783          	lw	a5,-400(s0)
    80005348:	e8845703          	lhu	a4,-376(s0)
    8000534c:	c735                	beqz	a4,800053b8 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000534e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005350:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005354:	6a05                	lui	s4,0x1
    80005356:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000535a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000535e:	6d85                	lui	s11,0x1
    80005360:	7d7d                	lui	s10,0xfffff
    80005362:	ac3d                	j	800055a0 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005364:	00003517          	auipc	a0,0x3
    80005368:	39c50513          	addi	a0,a0,924 # 80008700 <syscalls+0x2a0>
    8000536c:	ffffb097          	auipc	ra,0xffffb
    80005370:	1d4080e7          	jalr	468(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005374:	874a                	mv	a4,s2
    80005376:	009c86bb          	addw	a3,s9,s1
    8000537a:	4581                	li	a1,0
    8000537c:	8556                	mv	a0,s5
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	c8e080e7          	jalr	-882(ra) # 8000400c <readi>
    80005386:	2501                	sext.w	a0,a0
    80005388:	1aa91963          	bne	s2,a0,8000553a <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    8000538c:	009d84bb          	addw	s1,s11,s1
    80005390:	013d09bb          	addw	s3,s10,s3
    80005394:	1f74f663          	bgeu	s1,s7,80005580 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005398:	02049593          	slli	a1,s1,0x20
    8000539c:	9181                	srli	a1,a1,0x20
    8000539e:	95e2                	add	a1,a1,s8
    800053a0:	855a                	mv	a0,s6
    800053a2:	ffffc097          	auipc	ra,0xffffc
    800053a6:	e92080e7          	jalr	-366(ra) # 80001234 <walkaddr>
    800053aa:	862a                	mv	a2,a0
    if(pa == 0)
    800053ac:	dd45                	beqz	a0,80005364 <exec+0xfe>
      n = PGSIZE;
    800053ae:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800053b0:	fd49f2e3          	bgeu	s3,s4,80005374 <exec+0x10e>
      n = sz - i;
    800053b4:	894e                	mv	s2,s3
    800053b6:	bf7d                	j	80005374 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053b8:	4901                	li	s2,0
  iunlockput(ip);
    800053ba:	8556                	mv	a0,s5
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	bfe080e7          	jalr	-1026(ra) # 80003fba <iunlockput>
  end_op();
    800053c4:	fffff097          	auipc	ra,0xfffff
    800053c8:	3de080e7          	jalr	990(ra) # 800047a2 <end_op>
  p = myproc();
    800053cc:	ffffd097          	auipc	ra,0xffffd
    800053d0:	886080e7          	jalr	-1914(ra) # 80001c52 <myproc>
    800053d4:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800053d6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800053da:	6785                	lui	a5,0x1
    800053dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800053de:	97ca                	add	a5,a5,s2
    800053e0:	777d                	lui	a4,0xfffff
    800053e2:	8ff9                	and	a5,a5,a4
    800053e4:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053e8:	4691                	li	a3,4
    800053ea:	6609                	lui	a2,0x2
    800053ec:	963e                	add	a2,a2,a5
    800053ee:	85be                	mv	a1,a5
    800053f0:	855a                	mv	a0,s6
    800053f2:	ffffc097          	auipc	ra,0xffffc
    800053f6:	1f6080e7          	jalr	502(ra) # 800015e8 <uvmalloc>
    800053fa:	8c2a                	mv	s8,a0
  ip = 0;
    800053fc:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053fe:	12050e63          	beqz	a0,8000553a <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005402:	75f9                	lui	a1,0xffffe
    80005404:	95aa                	add	a1,a1,a0
    80005406:	855a                	mv	a0,s6
    80005408:	ffffc097          	auipc	ra,0xffffc
    8000540c:	408080e7          	jalr	1032(ra) # 80001810 <uvmclear>
  stackbase = sp - PGSIZE;
    80005410:	7afd                	lui	s5,0xfffff
    80005412:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005414:	df043783          	ld	a5,-528(s0)
    80005418:	6388                	ld	a0,0(a5)
    8000541a:	c925                	beqz	a0,8000548a <exec+0x224>
    8000541c:	e9040993          	addi	s3,s0,-368
    80005420:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005424:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005426:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005428:	ffffc097          	auipc	ra,0xffffc
    8000542c:	bfe080e7          	jalr	-1026(ra) # 80001026 <strlen>
    80005430:	0015079b          	addiw	a5,a0,1
    80005434:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005438:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000543c:	13596663          	bltu	s2,s5,80005568 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005440:	df043d83          	ld	s11,-528(s0)
    80005444:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005448:	8552                	mv	a0,s4
    8000544a:	ffffc097          	auipc	ra,0xffffc
    8000544e:	bdc080e7          	jalr	-1060(ra) # 80001026 <strlen>
    80005452:	0015069b          	addiw	a3,a0,1
    80005456:	8652                	mv	a2,s4
    80005458:	85ca                	mv	a1,s2
    8000545a:	855a                	mv	a0,s6
    8000545c:	ffffc097          	auipc	ra,0xffffc
    80005460:	5e0080e7          	jalr	1504(ra) # 80001a3c <copyout>
    80005464:	10054663          	bltz	a0,80005570 <exec+0x30a>
    ustack[argc] = sp;
    80005468:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000546c:	0485                	addi	s1,s1,1
    8000546e:	008d8793          	addi	a5,s11,8
    80005472:	def43823          	sd	a5,-528(s0)
    80005476:	008db503          	ld	a0,8(s11)
    8000547a:	c911                	beqz	a0,8000548e <exec+0x228>
    if(argc >= MAXARG)
    8000547c:	09a1                	addi	s3,s3,8
    8000547e:	fb3c95e3          	bne	s9,s3,80005428 <exec+0x1c2>
  sz = sz1;
    80005482:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005486:	4a81                	li	s5,0
    80005488:	a84d                	j	8000553a <exec+0x2d4>
  sp = sz;
    8000548a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000548c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000548e:	00349793          	slli	a5,s1,0x3
    80005492:	f9078793          	addi	a5,a5,-112
    80005496:	97a2                	add	a5,a5,s0
    80005498:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000549c:	00148693          	addi	a3,s1,1
    800054a0:	068e                	slli	a3,a3,0x3
    800054a2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800054a6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800054aa:	01597663          	bgeu	s2,s5,800054b6 <exec+0x250>
  sz = sz1;
    800054ae:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054b2:	4a81                	li	s5,0
    800054b4:	a059                	j	8000553a <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800054b6:	e9040613          	addi	a2,s0,-368
    800054ba:	85ca                	mv	a1,s2
    800054bc:	855a                	mv	a0,s6
    800054be:	ffffc097          	auipc	ra,0xffffc
    800054c2:	57e080e7          	jalr	1406(ra) # 80001a3c <copyout>
    800054c6:	0a054963          	bltz	a0,80005578 <exec+0x312>
  p->trapframe->a1 = sp;
    800054ca:	058bb783          	ld	a5,88(s7)
    800054ce:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800054d2:	de843783          	ld	a5,-536(s0)
    800054d6:	0007c703          	lbu	a4,0(a5)
    800054da:	cf11                	beqz	a4,800054f6 <exec+0x290>
    800054dc:	0785                	addi	a5,a5,1
    if(*s == '/')
    800054de:	02f00693          	li	a3,47
    800054e2:	a039                	j	800054f0 <exec+0x28a>
      last = s+1;
    800054e4:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800054e8:	0785                	addi	a5,a5,1
    800054ea:	fff7c703          	lbu	a4,-1(a5)
    800054ee:	c701                	beqz	a4,800054f6 <exec+0x290>
    if(*s == '/')
    800054f0:	fed71ce3          	bne	a4,a3,800054e8 <exec+0x282>
    800054f4:	bfc5                	j	800054e4 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800054f6:	4641                	li	a2,16
    800054f8:	de843583          	ld	a1,-536(s0)
    800054fc:	158b8513          	addi	a0,s7,344
    80005500:	ffffc097          	auipc	ra,0xffffc
    80005504:	af4080e7          	jalr	-1292(ra) # 80000ff4 <safestrcpy>
  oldpagetable = p->pagetable;
    80005508:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000550c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005510:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005514:	058bb783          	ld	a5,88(s7)
    80005518:	e6843703          	ld	a4,-408(s0)
    8000551c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000551e:	058bb783          	ld	a5,88(s7)
    80005522:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005526:	85ea                	mv	a1,s10
    80005528:	ffffd097          	auipc	ra,0xffffd
    8000552c:	88a080e7          	jalr	-1910(ra) # 80001db2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005530:	0004851b          	sext.w	a0,s1
    80005534:	b3f9                	j	80005302 <exec+0x9c>
    80005536:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000553a:	df843583          	ld	a1,-520(s0)
    8000553e:	855a                	mv	a0,s6
    80005540:	ffffd097          	auipc	ra,0xffffd
    80005544:	872080e7          	jalr	-1934(ra) # 80001db2 <proc_freepagetable>
  if(ip){
    80005548:	da0a93e3          	bnez	s5,800052ee <exec+0x88>
  return -1;
    8000554c:	557d                	li	a0,-1
    8000554e:	bb55                	j	80005302 <exec+0x9c>
    80005550:	df243c23          	sd	s2,-520(s0)
    80005554:	b7dd                	j	8000553a <exec+0x2d4>
    80005556:	df243c23          	sd	s2,-520(s0)
    8000555a:	b7c5                	j	8000553a <exec+0x2d4>
    8000555c:	df243c23          	sd	s2,-520(s0)
    80005560:	bfe9                	j	8000553a <exec+0x2d4>
    80005562:	df243c23          	sd	s2,-520(s0)
    80005566:	bfd1                	j	8000553a <exec+0x2d4>
  sz = sz1;
    80005568:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000556c:	4a81                	li	s5,0
    8000556e:	b7f1                	j	8000553a <exec+0x2d4>
  sz = sz1;
    80005570:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005574:	4a81                	li	s5,0
    80005576:	b7d1                	j	8000553a <exec+0x2d4>
  sz = sz1;
    80005578:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000557c:	4a81                	li	s5,0
    8000557e:	bf75                	j	8000553a <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005580:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005584:	e0843783          	ld	a5,-504(s0)
    80005588:	0017869b          	addiw	a3,a5,1
    8000558c:	e0d43423          	sd	a3,-504(s0)
    80005590:	e0043783          	ld	a5,-512(s0)
    80005594:	0387879b          	addiw	a5,a5,56
    80005598:	e8845703          	lhu	a4,-376(s0)
    8000559c:	e0e6dfe3          	bge	a3,a4,800053ba <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055a0:	2781                	sext.w	a5,a5
    800055a2:	e0f43023          	sd	a5,-512(s0)
    800055a6:	03800713          	li	a4,56
    800055aa:	86be                	mv	a3,a5
    800055ac:	e1840613          	addi	a2,s0,-488
    800055b0:	4581                	li	a1,0
    800055b2:	8556                	mv	a0,s5
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	a58080e7          	jalr	-1448(ra) # 8000400c <readi>
    800055bc:	03800793          	li	a5,56
    800055c0:	f6f51be3          	bne	a0,a5,80005536 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800055c4:	e1842783          	lw	a5,-488(s0)
    800055c8:	4705                	li	a4,1
    800055ca:	fae79de3          	bne	a5,a4,80005584 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    800055ce:	e4043483          	ld	s1,-448(s0)
    800055d2:	e3843783          	ld	a5,-456(s0)
    800055d6:	f6f4ede3          	bltu	s1,a5,80005550 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800055da:	e2843783          	ld	a5,-472(s0)
    800055de:	94be                	add	s1,s1,a5
    800055e0:	f6f4ebe3          	bltu	s1,a5,80005556 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800055e4:	de043703          	ld	a4,-544(s0)
    800055e8:	8ff9                	and	a5,a5,a4
    800055ea:	fbad                	bnez	a5,8000555c <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055ec:	e1c42503          	lw	a0,-484(s0)
    800055f0:	00000097          	auipc	ra,0x0
    800055f4:	c5c080e7          	jalr	-932(ra) # 8000524c <flags2perm>
    800055f8:	86aa                	mv	a3,a0
    800055fa:	8626                	mv	a2,s1
    800055fc:	85ca                	mv	a1,s2
    800055fe:	855a                	mv	a0,s6
    80005600:	ffffc097          	auipc	ra,0xffffc
    80005604:	fe8080e7          	jalr	-24(ra) # 800015e8 <uvmalloc>
    80005608:	dea43c23          	sd	a0,-520(s0)
    8000560c:	d939                	beqz	a0,80005562 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000560e:	e2843c03          	ld	s8,-472(s0)
    80005612:	e2042c83          	lw	s9,-480(s0)
    80005616:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000561a:	f60b83e3          	beqz	s7,80005580 <exec+0x31a>
    8000561e:	89de                	mv	s3,s7
    80005620:	4481                	li	s1,0
    80005622:	bb9d                	j	80005398 <exec+0x132>

0000000080005624 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005624:	7179                	addi	sp,sp,-48
    80005626:	f406                	sd	ra,40(sp)
    80005628:	f022                	sd	s0,32(sp)
    8000562a:	ec26                	sd	s1,24(sp)
    8000562c:	e84a                	sd	s2,16(sp)
    8000562e:	1800                	addi	s0,sp,48
    80005630:	892e                	mv	s2,a1
    80005632:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005634:	fdc40593          	addi	a1,s0,-36
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	a2e080e7          	jalr	-1490(ra) # 80003066 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005640:	fdc42703          	lw	a4,-36(s0)
    80005644:	47bd                	li	a5,15
    80005646:	02e7eb63          	bltu	a5,a4,8000567c <argfd+0x58>
    8000564a:	ffffc097          	auipc	ra,0xffffc
    8000564e:	608080e7          	jalr	1544(ra) # 80001c52 <myproc>
    80005652:	fdc42703          	lw	a4,-36(s0)
    80005656:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffbc072>
    8000565a:	078e                	slli	a5,a5,0x3
    8000565c:	953e                	add	a0,a0,a5
    8000565e:	611c                	ld	a5,0(a0)
    80005660:	c385                	beqz	a5,80005680 <argfd+0x5c>
    return -1;
  if(pfd)
    80005662:	00090463          	beqz	s2,8000566a <argfd+0x46>
    *pfd = fd;
    80005666:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000566a:	4501                	li	a0,0
  if(pf)
    8000566c:	c091                	beqz	s1,80005670 <argfd+0x4c>
    *pf = f;
    8000566e:	e09c                	sd	a5,0(s1)
}
    80005670:	70a2                	ld	ra,40(sp)
    80005672:	7402                	ld	s0,32(sp)
    80005674:	64e2                	ld	s1,24(sp)
    80005676:	6942                	ld	s2,16(sp)
    80005678:	6145                	addi	sp,sp,48
    8000567a:	8082                	ret
    return -1;
    8000567c:	557d                	li	a0,-1
    8000567e:	bfcd                	j	80005670 <argfd+0x4c>
    80005680:	557d                	li	a0,-1
    80005682:	b7fd                	j	80005670 <argfd+0x4c>

0000000080005684 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005684:	1101                	addi	sp,sp,-32
    80005686:	ec06                	sd	ra,24(sp)
    80005688:	e822                	sd	s0,16(sp)
    8000568a:	e426                	sd	s1,8(sp)
    8000568c:	1000                	addi	s0,sp,32
    8000568e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005690:	ffffc097          	auipc	ra,0xffffc
    80005694:	5c2080e7          	jalr	1474(ra) # 80001c52 <myproc>
    80005698:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000569a:	0d050793          	addi	a5,a0,208
    8000569e:	4501                	li	a0,0
    800056a0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056a2:	6398                	ld	a4,0(a5)
    800056a4:	cb19                	beqz	a4,800056ba <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056a6:	2505                	addiw	a0,a0,1
    800056a8:	07a1                	addi	a5,a5,8
    800056aa:	fed51ce3          	bne	a0,a3,800056a2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056ae:	557d                	li	a0,-1
}
    800056b0:	60e2                	ld	ra,24(sp)
    800056b2:	6442                	ld	s0,16(sp)
    800056b4:	64a2                	ld	s1,8(sp)
    800056b6:	6105                	addi	sp,sp,32
    800056b8:	8082                	ret
      p->ofile[fd] = f;
    800056ba:	01a50793          	addi	a5,a0,26
    800056be:	078e                	slli	a5,a5,0x3
    800056c0:	963e                	add	a2,a2,a5
    800056c2:	e204                	sd	s1,0(a2)
      return fd;
    800056c4:	b7f5                	j	800056b0 <fdalloc+0x2c>

00000000800056c6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800056c6:	715d                	addi	sp,sp,-80
    800056c8:	e486                	sd	ra,72(sp)
    800056ca:	e0a2                	sd	s0,64(sp)
    800056cc:	fc26                	sd	s1,56(sp)
    800056ce:	f84a                	sd	s2,48(sp)
    800056d0:	f44e                	sd	s3,40(sp)
    800056d2:	f052                	sd	s4,32(sp)
    800056d4:	ec56                	sd	s5,24(sp)
    800056d6:	e85a                	sd	s6,16(sp)
    800056d8:	0880                	addi	s0,sp,80
    800056da:	8b2e                	mv	s6,a1
    800056dc:	89b2                	mv	s3,a2
    800056de:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800056e0:	fb040593          	addi	a1,s0,-80
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	e3e080e7          	jalr	-450(ra) # 80004522 <nameiparent>
    800056ec:	84aa                	mv	s1,a0
    800056ee:	14050f63          	beqz	a0,8000584c <create+0x186>
    return 0;

  ilock(dp);
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	666080e7          	jalr	1638(ra) # 80003d58 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800056fa:	4601                	li	a2,0
    800056fc:	fb040593          	addi	a1,s0,-80
    80005700:	8526                	mv	a0,s1
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	b3a080e7          	jalr	-1222(ra) # 8000423c <dirlookup>
    8000570a:	8aaa                	mv	s5,a0
    8000570c:	c931                	beqz	a0,80005760 <create+0x9a>
    iunlockput(dp);
    8000570e:	8526                	mv	a0,s1
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	8aa080e7          	jalr	-1878(ra) # 80003fba <iunlockput>
    ilock(ip);
    80005718:	8556                	mv	a0,s5
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	63e080e7          	jalr	1598(ra) # 80003d58 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005722:	000b059b          	sext.w	a1,s6
    80005726:	4789                	li	a5,2
    80005728:	02f59563          	bne	a1,a5,80005752 <create+0x8c>
    8000572c:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffbc09c>
    80005730:	37f9                	addiw	a5,a5,-2
    80005732:	17c2                	slli	a5,a5,0x30
    80005734:	93c1                	srli	a5,a5,0x30
    80005736:	4705                	li	a4,1
    80005738:	00f76d63          	bltu	a4,a5,80005752 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000573c:	8556                	mv	a0,s5
    8000573e:	60a6                	ld	ra,72(sp)
    80005740:	6406                	ld	s0,64(sp)
    80005742:	74e2                	ld	s1,56(sp)
    80005744:	7942                	ld	s2,48(sp)
    80005746:	79a2                	ld	s3,40(sp)
    80005748:	7a02                	ld	s4,32(sp)
    8000574a:	6ae2                	ld	s5,24(sp)
    8000574c:	6b42                	ld	s6,16(sp)
    8000574e:	6161                	addi	sp,sp,80
    80005750:	8082                	ret
    iunlockput(ip);
    80005752:	8556                	mv	a0,s5
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	866080e7          	jalr	-1946(ra) # 80003fba <iunlockput>
    return 0;
    8000575c:	4a81                	li	s5,0
    8000575e:	bff9                	j	8000573c <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005760:	85da                	mv	a1,s6
    80005762:	4088                	lw	a0,0(s1)
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	456080e7          	jalr	1110(ra) # 80003bba <ialloc>
    8000576c:	8a2a                	mv	s4,a0
    8000576e:	c539                	beqz	a0,800057bc <create+0xf6>
  ilock(ip);
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	5e8080e7          	jalr	1512(ra) # 80003d58 <ilock>
  ip->major = major;
    80005778:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000577c:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005780:	4905                	li	s2,1
    80005782:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005786:	8552                	mv	a0,s4
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	504080e7          	jalr	1284(ra) # 80003c8c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005790:	000b059b          	sext.w	a1,s6
    80005794:	03258b63          	beq	a1,s2,800057ca <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005798:	004a2603          	lw	a2,4(s4)
    8000579c:	fb040593          	addi	a1,s0,-80
    800057a0:	8526                	mv	a0,s1
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	cb0080e7          	jalr	-848(ra) # 80004452 <dirlink>
    800057aa:	06054f63          	bltz	a0,80005828 <create+0x162>
  iunlockput(dp);
    800057ae:	8526                	mv	a0,s1
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	80a080e7          	jalr	-2038(ra) # 80003fba <iunlockput>
  return ip;
    800057b8:	8ad2                	mv	s5,s4
    800057ba:	b749                	j	8000573c <create+0x76>
    iunlockput(dp);
    800057bc:	8526                	mv	a0,s1
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	7fc080e7          	jalr	2044(ra) # 80003fba <iunlockput>
    return 0;
    800057c6:	8ad2                	mv	s5,s4
    800057c8:	bf95                	j	8000573c <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800057ca:	004a2603          	lw	a2,4(s4)
    800057ce:	00003597          	auipc	a1,0x3
    800057d2:	f5258593          	addi	a1,a1,-174 # 80008720 <syscalls+0x2c0>
    800057d6:	8552                	mv	a0,s4
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	c7a080e7          	jalr	-902(ra) # 80004452 <dirlink>
    800057e0:	04054463          	bltz	a0,80005828 <create+0x162>
    800057e4:	40d0                	lw	a2,4(s1)
    800057e6:	00003597          	auipc	a1,0x3
    800057ea:	f4258593          	addi	a1,a1,-190 # 80008728 <syscalls+0x2c8>
    800057ee:	8552                	mv	a0,s4
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	c62080e7          	jalr	-926(ra) # 80004452 <dirlink>
    800057f8:	02054863          	bltz	a0,80005828 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800057fc:	004a2603          	lw	a2,4(s4)
    80005800:	fb040593          	addi	a1,s0,-80
    80005804:	8526                	mv	a0,s1
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	c4c080e7          	jalr	-948(ra) # 80004452 <dirlink>
    8000580e:	00054d63          	bltz	a0,80005828 <create+0x162>
    dp->nlink++;  // for ".."
    80005812:	04a4d783          	lhu	a5,74(s1)
    80005816:	2785                	addiw	a5,a5,1
    80005818:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000581c:	8526                	mv	a0,s1
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	46e080e7          	jalr	1134(ra) # 80003c8c <iupdate>
    80005826:	b761                	j	800057ae <create+0xe8>
  ip->nlink = 0;
    80005828:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000582c:	8552                	mv	a0,s4
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	45e080e7          	jalr	1118(ra) # 80003c8c <iupdate>
  iunlockput(ip);
    80005836:	8552                	mv	a0,s4
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	782080e7          	jalr	1922(ra) # 80003fba <iunlockput>
  iunlockput(dp);
    80005840:	8526                	mv	a0,s1
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	778080e7          	jalr	1912(ra) # 80003fba <iunlockput>
  return 0;
    8000584a:	bdcd                	j	8000573c <create+0x76>
    return 0;
    8000584c:	8aaa                	mv	s5,a0
    8000584e:	b5fd                	j	8000573c <create+0x76>

0000000080005850 <sys_dup>:
{
    80005850:	7179                	addi	sp,sp,-48
    80005852:	f406                	sd	ra,40(sp)
    80005854:	f022                	sd	s0,32(sp)
    80005856:	ec26                	sd	s1,24(sp)
    80005858:	e84a                	sd	s2,16(sp)
    8000585a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000585c:	fd840613          	addi	a2,s0,-40
    80005860:	4581                	li	a1,0
    80005862:	4501                	li	a0,0
    80005864:	00000097          	auipc	ra,0x0
    80005868:	dc0080e7          	jalr	-576(ra) # 80005624 <argfd>
    return -1;
    8000586c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000586e:	02054363          	bltz	a0,80005894 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005872:	fd843903          	ld	s2,-40(s0)
    80005876:	854a                	mv	a0,s2
    80005878:	00000097          	auipc	ra,0x0
    8000587c:	e0c080e7          	jalr	-500(ra) # 80005684 <fdalloc>
    80005880:	84aa                	mv	s1,a0
    return -1;
    80005882:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005884:	00054863          	bltz	a0,80005894 <sys_dup+0x44>
  filedup(f);
    80005888:	854a                	mv	a0,s2
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	310080e7          	jalr	784(ra) # 80004b9a <filedup>
  return fd;
    80005892:	87a6                	mv	a5,s1
}
    80005894:	853e                	mv	a0,a5
    80005896:	70a2                	ld	ra,40(sp)
    80005898:	7402                	ld	s0,32(sp)
    8000589a:	64e2                	ld	s1,24(sp)
    8000589c:	6942                	ld	s2,16(sp)
    8000589e:	6145                	addi	sp,sp,48
    800058a0:	8082                	ret

00000000800058a2 <sys_read>:
{
    800058a2:	7179                	addi	sp,sp,-48
    800058a4:	f406                	sd	ra,40(sp)
    800058a6:	f022                	sd	s0,32(sp)
    800058a8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800058aa:	fd840593          	addi	a1,s0,-40
    800058ae:	4505                	li	a0,1
    800058b0:	ffffd097          	auipc	ra,0xffffd
    800058b4:	7d6080e7          	jalr	2006(ra) # 80003086 <argaddr>
  argint(2, &n);
    800058b8:	fe440593          	addi	a1,s0,-28
    800058bc:	4509                	li	a0,2
    800058be:	ffffd097          	auipc	ra,0xffffd
    800058c2:	7a8080e7          	jalr	1960(ra) # 80003066 <argint>
  if(argfd(0, 0, &f) < 0)
    800058c6:	fe840613          	addi	a2,s0,-24
    800058ca:	4581                	li	a1,0
    800058cc:	4501                	li	a0,0
    800058ce:	00000097          	auipc	ra,0x0
    800058d2:	d56080e7          	jalr	-682(ra) # 80005624 <argfd>
    800058d6:	87aa                	mv	a5,a0
    return -1;
    800058d8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058da:	0007cc63          	bltz	a5,800058f2 <sys_read+0x50>
  return fileread(f, p, n);
    800058de:	fe442603          	lw	a2,-28(s0)
    800058e2:	fd843583          	ld	a1,-40(s0)
    800058e6:	fe843503          	ld	a0,-24(s0)
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	43c080e7          	jalr	1084(ra) # 80004d26 <fileread>
}
    800058f2:	70a2                	ld	ra,40(sp)
    800058f4:	7402                	ld	s0,32(sp)
    800058f6:	6145                	addi	sp,sp,48
    800058f8:	8082                	ret

00000000800058fa <sys_write>:
{
    800058fa:	7179                	addi	sp,sp,-48
    800058fc:	f406                	sd	ra,40(sp)
    800058fe:	f022                	sd	s0,32(sp)
    80005900:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005902:	fd840593          	addi	a1,s0,-40
    80005906:	4505                	li	a0,1
    80005908:	ffffd097          	auipc	ra,0xffffd
    8000590c:	77e080e7          	jalr	1918(ra) # 80003086 <argaddr>
  argint(2, &n);
    80005910:	fe440593          	addi	a1,s0,-28
    80005914:	4509                	li	a0,2
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	750080e7          	jalr	1872(ra) # 80003066 <argint>
  if(argfd(0, 0, &f) < 0)
    8000591e:	fe840613          	addi	a2,s0,-24
    80005922:	4581                	li	a1,0
    80005924:	4501                	li	a0,0
    80005926:	00000097          	auipc	ra,0x0
    8000592a:	cfe080e7          	jalr	-770(ra) # 80005624 <argfd>
    8000592e:	87aa                	mv	a5,a0
    return -1;
    80005930:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005932:	0007cc63          	bltz	a5,8000594a <sys_write+0x50>
  return filewrite(f, p, n);
    80005936:	fe442603          	lw	a2,-28(s0)
    8000593a:	fd843583          	ld	a1,-40(s0)
    8000593e:	fe843503          	ld	a0,-24(s0)
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	4a6080e7          	jalr	1190(ra) # 80004de8 <filewrite>
}
    8000594a:	70a2                	ld	ra,40(sp)
    8000594c:	7402                	ld	s0,32(sp)
    8000594e:	6145                	addi	sp,sp,48
    80005950:	8082                	ret

0000000080005952 <sys_close>:
{
    80005952:	1101                	addi	sp,sp,-32
    80005954:	ec06                	sd	ra,24(sp)
    80005956:	e822                	sd	s0,16(sp)
    80005958:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000595a:	fe040613          	addi	a2,s0,-32
    8000595e:	fec40593          	addi	a1,s0,-20
    80005962:	4501                	li	a0,0
    80005964:	00000097          	auipc	ra,0x0
    80005968:	cc0080e7          	jalr	-832(ra) # 80005624 <argfd>
    return -1;
    8000596c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000596e:	02054463          	bltz	a0,80005996 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005972:	ffffc097          	auipc	ra,0xffffc
    80005976:	2e0080e7          	jalr	736(ra) # 80001c52 <myproc>
    8000597a:	fec42783          	lw	a5,-20(s0)
    8000597e:	07e9                	addi	a5,a5,26
    80005980:	078e                	slli	a5,a5,0x3
    80005982:	953e                	add	a0,a0,a5
    80005984:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005988:	fe043503          	ld	a0,-32(s0)
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	260080e7          	jalr	608(ra) # 80004bec <fileclose>
  return 0;
    80005994:	4781                	li	a5,0
}
    80005996:	853e                	mv	a0,a5
    80005998:	60e2                	ld	ra,24(sp)
    8000599a:	6442                	ld	s0,16(sp)
    8000599c:	6105                	addi	sp,sp,32
    8000599e:	8082                	ret

00000000800059a0 <sys_fstat>:
{
    800059a0:	1101                	addi	sp,sp,-32
    800059a2:	ec06                	sd	ra,24(sp)
    800059a4:	e822                	sd	s0,16(sp)
    800059a6:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800059a8:	fe040593          	addi	a1,s0,-32
    800059ac:	4505                	li	a0,1
    800059ae:	ffffd097          	auipc	ra,0xffffd
    800059b2:	6d8080e7          	jalr	1752(ra) # 80003086 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800059b6:	fe840613          	addi	a2,s0,-24
    800059ba:	4581                	li	a1,0
    800059bc:	4501                	li	a0,0
    800059be:	00000097          	auipc	ra,0x0
    800059c2:	c66080e7          	jalr	-922(ra) # 80005624 <argfd>
    800059c6:	87aa                	mv	a5,a0
    return -1;
    800059c8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059ca:	0007ca63          	bltz	a5,800059de <sys_fstat+0x3e>
  return filestat(f, st);
    800059ce:	fe043583          	ld	a1,-32(s0)
    800059d2:	fe843503          	ld	a0,-24(s0)
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	2de080e7          	jalr	734(ra) # 80004cb4 <filestat>
}
    800059de:	60e2                	ld	ra,24(sp)
    800059e0:	6442                	ld	s0,16(sp)
    800059e2:	6105                	addi	sp,sp,32
    800059e4:	8082                	ret

00000000800059e6 <sys_link>:
{
    800059e6:	7169                	addi	sp,sp,-304
    800059e8:	f606                	sd	ra,296(sp)
    800059ea:	f222                	sd	s0,288(sp)
    800059ec:	ee26                	sd	s1,280(sp)
    800059ee:	ea4a                	sd	s2,272(sp)
    800059f0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059f2:	08000613          	li	a2,128
    800059f6:	ed040593          	addi	a1,s0,-304
    800059fa:	4501                	li	a0,0
    800059fc:	ffffd097          	auipc	ra,0xffffd
    80005a00:	6aa080e7          	jalr	1706(ra) # 800030a6 <argstr>
    return -1;
    80005a04:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a06:	10054e63          	bltz	a0,80005b22 <sys_link+0x13c>
    80005a0a:	08000613          	li	a2,128
    80005a0e:	f5040593          	addi	a1,s0,-176
    80005a12:	4505                	li	a0,1
    80005a14:	ffffd097          	auipc	ra,0xffffd
    80005a18:	692080e7          	jalr	1682(ra) # 800030a6 <argstr>
    return -1;
    80005a1c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a1e:	10054263          	bltz	a0,80005b22 <sys_link+0x13c>
  begin_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	d02080e7          	jalr	-766(ra) # 80004724 <begin_op>
  if((ip = namei(old)) == 0){
    80005a2a:	ed040513          	addi	a0,s0,-304
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	ad6080e7          	jalr	-1322(ra) # 80004504 <namei>
    80005a36:	84aa                	mv	s1,a0
    80005a38:	c551                	beqz	a0,80005ac4 <sys_link+0xde>
  ilock(ip);
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	31e080e7          	jalr	798(ra) # 80003d58 <ilock>
  if(ip->type == T_DIR){
    80005a42:	04449703          	lh	a4,68(s1)
    80005a46:	4785                	li	a5,1
    80005a48:	08f70463          	beq	a4,a5,80005ad0 <sys_link+0xea>
  ip->nlink++;
    80005a4c:	04a4d783          	lhu	a5,74(s1)
    80005a50:	2785                	addiw	a5,a5,1
    80005a52:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a56:	8526                	mv	a0,s1
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	234080e7          	jalr	564(ra) # 80003c8c <iupdate>
  iunlock(ip);
    80005a60:	8526                	mv	a0,s1
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	3b8080e7          	jalr	952(ra) # 80003e1a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a6a:	fd040593          	addi	a1,s0,-48
    80005a6e:	f5040513          	addi	a0,s0,-176
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	ab0080e7          	jalr	-1360(ra) # 80004522 <nameiparent>
    80005a7a:	892a                	mv	s2,a0
    80005a7c:	c935                	beqz	a0,80005af0 <sys_link+0x10a>
  ilock(dp);
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	2da080e7          	jalr	730(ra) # 80003d58 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a86:	00092703          	lw	a4,0(s2)
    80005a8a:	409c                	lw	a5,0(s1)
    80005a8c:	04f71d63          	bne	a4,a5,80005ae6 <sys_link+0x100>
    80005a90:	40d0                	lw	a2,4(s1)
    80005a92:	fd040593          	addi	a1,s0,-48
    80005a96:	854a                	mv	a0,s2
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	9ba080e7          	jalr	-1606(ra) # 80004452 <dirlink>
    80005aa0:	04054363          	bltz	a0,80005ae6 <sys_link+0x100>
  iunlockput(dp);
    80005aa4:	854a                	mv	a0,s2
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	514080e7          	jalr	1300(ra) # 80003fba <iunlockput>
  iput(ip);
    80005aae:	8526                	mv	a0,s1
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	462080e7          	jalr	1122(ra) # 80003f12 <iput>
  end_op();
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	cea080e7          	jalr	-790(ra) # 800047a2 <end_op>
  return 0;
    80005ac0:	4781                	li	a5,0
    80005ac2:	a085                	j	80005b22 <sys_link+0x13c>
    end_op();
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	cde080e7          	jalr	-802(ra) # 800047a2 <end_op>
    return -1;
    80005acc:	57fd                	li	a5,-1
    80005ace:	a891                	j	80005b22 <sys_link+0x13c>
    iunlockput(ip);
    80005ad0:	8526                	mv	a0,s1
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	4e8080e7          	jalr	1256(ra) # 80003fba <iunlockput>
    end_op();
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	cc8080e7          	jalr	-824(ra) # 800047a2 <end_op>
    return -1;
    80005ae2:	57fd                	li	a5,-1
    80005ae4:	a83d                	j	80005b22 <sys_link+0x13c>
    iunlockput(dp);
    80005ae6:	854a                	mv	a0,s2
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	4d2080e7          	jalr	1234(ra) # 80003fba <iunlockput>
  ilock(ip);
    80005af0:	8526                	mv	a0,s1
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	266080e7          	jalr	614(ra) # 80003d58 <ilock>
  ip->nlink--;
    80005afa:	04a4d783          	lhu	a5,74(s1)
    80005afe:	37fd                	addiw	a5,a5,-1
    80005b00:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b04:	8526                	mv	a0,s1
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	186080e7          	jalr	390(ra) # 80003c8c <iupdate>
  iunlockput(ip);
    80005b0e:	8526                	mv	a0,s1
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	4aa080e7          	jalr	1194(ra) # 80003fba <iunlockput>
  end_op();
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	c8a080e7          	jalr	-886(ra) # 800047a2 <end_op>
  return -1;
    80005b20:	57fd                	li	a5,-1
}
    80005b22:	853e                	mv	a0,a5
    80005b24:	70b2                	ld	ra,296(sp)
    80005b26:	7412                	ld	s0,288(sp)
    80005b28:	64f2                	ld	s1,280(sp)
    80005b2a:	6952                	ld	s2,272(sp)
    80005b2c:	6155                	addi	sp,sp,304
    80005b2e:	8082                	ret

0000000080005b30 <sys_unlink>:
{
    80005b30:	7151                	addi	sp,sp,-240
    80005b32:	f586                	sd	ra,232(sp)
    80005b34:	f1a2                	sd	s0,224(sp)
    80005b36:	eda6                	sd	s1,216(sp)
    80005b38:	e9ca                	sd	s2,208(sp)
    80005b3a:	e5ce                	sd	s3,200(sp)
    80005b3c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b3e:	08000613          	li	a2,128
    80005b42:	f3040593          	addi	a1,s0,-208
    80005b46:	4501                	li	a0,0
    80005b48:	ffffd097          	auipc	ra,0xffffd
    80005b4c:	55e080e7          	jalr	1374(ra) # 800030a6 <argstr>
    80005b50:	18054163          	bltz	a0,80005cd2 <sys_unlink+0x1a2>
  begin_op();
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	bd0080e7          	jalr	-1072(ra) # 80004724 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b5c:	fb040593          	addi	a1,s0,-80
    80005b60:	f3040513          	addi	a0,s0,-208
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	9be080e7          	jalr	-1602(ra) # 80004522 <nameiparent>
    80005b6c:	84aa                	mv	s1,a0
    80005b6e:	c979                	beqz	a0,80005c44 <sys_unlink+0x114>
  ilock(dp);
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	1e8080e7          	jalr	488(ra) # 80003d58 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b78:	00003597          	auipc	a1,0x3
    80005b7c:	ba858593          	addi	a1,a1,-1112 # 80008720 <syscalls+0x2c0>
    80005b80:	fb040513          	addi	a0,s0,-80
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	69e080e7          	jalr	1694(ra) # 80004222 <namecmp>
    80005b8c:	14050a63          	beqz	a0,80005ce0 <sys_unlink+0x1b0>
    80005b90:	00003597          	auipc	a1,0x3
    80005b94:	b9858593          	addi	a1,a1,-1128 # 80008728 <syscalls+0x2c8>
    80005b98:	fb040513          	addi	a0,s0,-80
    80005b9c:	ffffe097          	auipc	ra,0xffffe
    80005ba0:	686080e7          	jalr	1670(ra) # 80004222 <namecmp>
    80005ba4:	12050e63          	beqz	a0,80005ce0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005ba8:	f2c40613          	addi	a2,s0,-212
    80005bac:	fb040593          	addi	a1,s0,-80
    80005bb0:	8526                	mv	a0,s1
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	68a080e7          	jalr	1674(ra) # 8000423c <dirlookup>
    80005bba:	892a                	mv	s2,a0
    80005bbc:	12050263          	beqz	a0,80005ce0 <sys_unlink+0x1b0>
  ilock(ip);
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	198080e7          	jalr	408(ra) # 80003d58 <ilock>
  if(ip->nlink < 1)
    80005bc8:	04a91783          	lh	a5,74(s2)
    80005bcc:	08f05263          	blez	a5,80005c50 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005bd0:	04491703          	lh	a4,68(s2)
    80005bd4:	4785                	li	a5,1
    80005bd6:	08f70563          	beq	a4,a5,80005c60 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005bda:	4641                	li	a2,16
    80005bdc:	4581                	li	a1,0
    80005bde:	fc040513          	addi	a0,s0,-64
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	2c8080e7          	jalr	712(ra) # 80000eaa <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bea:	4741                	li	a4,16
    80005bec:	f2c42683          	lw	a3,-212(s0)
    80005bf0:	fc040613          	addi	a2,s0,-64
    80005bf4:	4581                	li	a1,0
    80005bf6:	8526                	mv	a0,s1
    80005bf8:	ffffe097          	auipc	ra,0xffffe
    80005bfc:	50c080e7          	jalr	1292(ra) # 80004104 <writei>
    80005c00:	47c1                	li	a5,16
    80005c02:	0af51563          	bne	a0,a5,80005cac <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c06:	04491703          	lh	a4,68(s2)
    80005c0a:	4785                	li	a5,1
    80005c0c:	0af70863          	beq	a4,a5,80005cbc <sys_unlink+0x18c>
  iunlockput(dp);
    80005c10:	8526                	mv	a0,s1
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	3a8080e7          	jalr	936(ra) # 80003fba <iunlockput>
  ip->nlink--;
    80005c1a:	04a95783          	lhu	a5,74(s2)
    80005c1e:	37fd                	addiw	a5,a5,-1
    80005c20:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c24:	854a                	mv	a0,s2
    80005c26:	ffffe097          	auipc	ra,0xffffe
    80005c2a:	066080e7          	jalr	102(ra) # 80003c8c <iupdate>
  iunlockput(ip);
    80005c2e:	854a                	mv	a0,s2
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	38a080e7          	jalr	906(ra) # 80003fba <iunlockput>
  end_op();
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	b6a080e7          	jalr	-1174(ra) # 800047a2 <end_op>
  return 0;
    80005c40:	4501                	li	a0,0
    80005c42:	a84d                	j	80005cf4 <sys_unlink+0x1c4>
    end_op();
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	b5e080e7          	jalr	-1186(ra) # 800047a2 <end_op>
    return -1;
    80005c4c:	557d                	li	a0,-1
    80005c4e:	a05d                	j	80005cf4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c50:	00003517          	auipc	a0,0x3
    80005c54:	ae050513          	addi	a0,a0,-1312 # 80008730 <syscalls+0x2d0>
    80005c58:	ffffb097          	auipc	ra,0xffffb
    80005c5c:	8e8080e7          	jalr	-1816(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c60:	04c92703          	lw	a4,76(s2)
    80005c64:	02000793          	li	a5,32
    80005c68:	f6e7f9e3          	bgeu	a5,a4,80005bda <sys_unlink+0xaa>
    80005c6c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c70:	4741                	li	a4,16
    80005c72:	86ce                	mv	a3,s3
    80005c74:	f1840613          	addi	a2,s0,-232
    80005c78:	4581                	li	a1,0
    80005c7a:	854a                	mv	a0,s2
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	390080e7          	jalr	912(ra) # 8000400c <readi>
    80005c84:	47c1                	li	a5,16
    80005c86:	00f51b63          	bne	a0,a5,80005c9c <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c8a:	f1845783          	lhu	a5,-232(s0)
    80005c8e:	e7a1                	bnez	a5,80005cd6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c90:	29c1                	addiw	s3,s3,16
    80005c92:	04c92783          	lw	a5,76(s2)
    80005c96:	fcf9ede3          	bltu	s3,a5,80005c70 <sys_unlink+0x140>
    80005c9a:	b781                	j	80005bda <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c9c:	00003517          	auipc	a0,0x3
    80005ca0:	aac50513          	addi	a0,a0,-1364 # 80008748 <syscalls+0x2e8>
    80005ca4:	ffffb097          	auipc	ra,0xffffb
    80005ca8:	89c080e7          	jalr	-1892(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005cac:	00003517          	auipc	a0,0x3
    80005cb0:	ab450513          	addi	a0,a0,-1356 # 80008760 <syscalls+0x300>
    80005cb4:	ffffb097          	auipc	ra,0xffffb
    80005cb8:	88c080e7          	jalr	-1908(ra) # 80000540 <panic>
    dp->nlink--;
    80005cbc:	04a4d783          	lhu	a5,74(s1)
    80005cc0:	37fd                	addiw	a5,a5,-1
    80005cc2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005cc6:	8526                	mv	a0,s1
    80005cc8:	ffffe097          	auipc	ra,0xffffe
    80005ccc:	fc4080e7          	jalr	-60(ra) # 80003c8c <iupdate>
    80005cd0:	b781                	j	80005c10 <sys_unlink+0xe0>
    return -1;
    80005cd2:	557d                	li	a0,-1
    80005cd4:	a005                	j	80005cf4 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005cd6:	854a                	mv	a0,s2
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	2e2080e7          	jalr	738(ra) # 80003fba <iunlockput>
  iunlockput(dp);
    80005ce0:	8526                	mv	a0,s1
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	2d8080e7          	jalr	728(ra) # 80003fba <iunlockput>
  end_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	ab8080e7          	jalr	-1352(ra) # 800047a2 <end_op>
  return -1;
    80005cf2:	557d                	li	a0,-1
}
    80005cf4:	70ae                	ld	ra,232(sp)
    80005cf6:	740e                	ld	s0,224(sp)
    80005cf8:	64ee                	ld	s1,216(sp)
    80005cfa:	694e                	ld	s2,208(sp)
    80005cfc:	69ae                	ld	s3,200(sp)
    80005cfe:	616d                	addi	sp,sp,240
    80005d00:	8082                	ret

0000000080005d02 <sys_open>:

uint64
sys_open(void)
{
    80005d02:	7131                	addi	sp,sp,-192
    80005d04:	fd06                	sd	ra,184(sp)
    80005d06:	f922                	sd	s0,176(sp)
    80005d08:	f526                	sd	s1,168(sp)
    80005d0a:	f14a                	sd	s2,160(sp)
    80005d0c:	ed4e                	sd	s3,152(sp)
    80005d0e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005d10:	f4c40593          	addi	a1,s0,-180
    80005d14:	4505                	li	a0,1
    80005d16:	ffffd097          	auipc	ra,0xffffd
    80005d1a:	350080e7          	jalr	848(ra) # 80003066 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d1e:	08000613          	li	a2,128
    80005d22:	f5040593          	addi	a1,s0,-176
    80005d26:	4501                	li	a0,0
    80005d28:	ffffd097          	auipc	ra,0xffffd
    80005d2c:	37e080e7          	jalr	894(ra) # 800030a6 <argstr>
    80005d30:	87aa                	mv	a5,a0
    return -1;
    80005d32:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d34:	0a07c963          	bltz	a5,80005de6 <sys_open+0xe4>

  begin_op();
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	9ec080e7          	jalr	-1556(ra) # 80004724 <begin_op>

  if(omode & O_CREATE){
    80005d40:	f4c42783          	lw	a5,-180(s0)
    80005d44:	2007f793          	andi	a5,a5,512
    80005d48:	cfc5                	beqz	a5,80005e00 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d4a:	4681                	li	a3,0
    80005d4c:	4601                	li	a2,0
    80005d4e:	4589                	li	a1,2
    80005d50:	f5040513          	addi	a0,s0,-176
    80005d54:	00000097          	auipc	ra,0x0
    80005d58:	972080e7          	jalr	-1678(ra) # 800056c6 <create>
    80005d5c:	84aa                	mv	s1,a0
    if(ip == 0){
    80005d5e:	c959                	beqz	a0,80005df4 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d60:	04449703          	lh	a4,68(s1)
    80005d64:	478d                	li	a5,3
    80005d66:	00f71763          	bne	a4,a5,80005d74 <sys_open+0x72>
    80005d6a:	0464d703          	lhu	a4,70(s1)
    80005d6e:	47a5                	li	a5,9
    80005d70:	0ce7ed63          	bltu	a5,a4,80005e4a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	dbc080e7          	jalr	-580(ra) # 80004b30 <filealloc>
    80005d7c:	89aa                	mv	s3,a0
    80005d7e:	10050363          	beqz	a0,80005e84 <sys_open+0x182>
    80005d82:	00000097          	auipc	ra,0x0
    80005d86:	902080e7          	jalr	-1790(ra) # 80005684 <fdalloc>
    80005d8a:	892a                	mv	s2,a0
    80005d8c:	0e054763          	bltz	a0,80005e7a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d90:	04449703          	lh	a4,68(s1)
    80005d94:	478d                	li	a5,3
    80005d96:	0cf70563          	beq	a4,a5,80005e60 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d9a:	4789                	li	a5,2
    80005d9c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005da0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005da4:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005da8:	f4c42783          	lw	a5,-180(s0)
    80005dac:	0017c713          	xori	a4,a5,1
    80005db0:	8b05                	andi	a4,a4,1
    80005db2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005db6:	0037f713          	andi	a4,a5,3
    80005dba:	00e03733          	snez	a4,a4
    80005dbe:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005dc2:	4007f793          	andi	a5,a5,1024
    80005dc6:	c791                	beqz	a5,80005dd2 <sys_open+0xd0>
    80005dc8:	04449703          	lh	a4,68(s1)
    80005dcc:	4789                	li	a5,2
    80005dce:	0af70063          	beq	a4,a5,80005e6e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005dd2:	8526                	mv	a0,s1
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	046080e7          	jalr	70(ra) # 80003e1a <iunlock>
  end_op();
    80005ddc:	fffff097          	auipc	ra,0xfffff
    80005de0:	9c6080e7          	jalr	-1594(ra) # 800047a2 <end_op>

  return fd;
    80005de4:	854a                	mv	a0,s2
}
    80005de6:	70ea                	ld	ra,184(sp)
    80005de8:	744a                	ld	s0,176(sp)
    80005dea:	74aa                	ld	s1,168(sp)
    80005dec:	790a                	ld	s2,160(sp)
    80005dee:	69ea                	ld	s3,152(sp)
    80005df0:	6129                	addi	sp,sp,192
    80005df2:	8082                	ret
      end_op();
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	9ae080e7          	jalr	-1618(ra) # 800047a2 <end_op>
      return -1;
    80005dfc:	557d                	li	a0,-1
    80005dfe:	b7e5                	j	80005de6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e00:	f5040513          	addi	a0,s0,-176
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	700080e7          	jalr	1792(ra) # 80004504 <namei>
    80005e0c:	84aa                	mv	s1,a0
    80005e0e:	c905                	beqz	a0,80005e3e <sys_open+0x13c>
    ilock(ip);
    80005e10:	ffffe097          	auipc	ra,0xffffe
    80005e14:	f48080e7          	jalr	-184(ra) # 80003d58 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e18:	04449703          	lh	a4,68(s1)
    80005e1c:	4785                	li	a5,1
    80005e1e:	f4f711e3          	bne	a4,a5,80005d60 <sys_open+0x5e>
    80005e22:	f4c42783          	lw	a5,-180(s0)
    80005e26:	d7b9                	beqz	a5,80005d74 <sys_open+0x72>
      iunlockput(ip);
    80005e28:	8526                	mv	a0,s1
    80005e2a:	ffffe097          	auipc	ra,0xffffe
    80005e2e:	190080e7          	jalr	400(ra) # 80003fba <iunlockput>
      end_op();
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	970080e7          	jalr	-1680(ra) # 800047a2 <end_op>
      return -1;
    80005e3a:	557d                	li	a0,-1
    80005e3c:	b76d                	j	80005de6 <sys_open+0xe4>
      end_op();
    80005e3e:	fffff097          	auipc	ra,0xfffff
    80005e42:	964080e7          	jalr	-1692(ra) # 800047a2 <end_op>
      return -1;
    80005e46:	557d                	li	a0,-1
    80005e48:	bf79                	j	80005de6 <sys_open+0xe4>
    iunlockput(ip);
    80005e4a:	8526                	mv	a0,s1
    80005e4c:	ffffe097          	auipc	ra,0xffffe
    80005e50:	16e080e7          	jalr	366(ra) # 80003fba <iunlockput>
    end_op();
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	94e080e7          	jalr	-1714(ra) # 800047a2 <end_op>
    return -1;
    80005e5c:	557d                	li	a0,-1
    80005e5e:	b761                	j	80005de6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e60:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e64:	04649783          	lh	a5,70(s1)
    80005e68:	02f99223          	sh	a5,36(s3)
    80005e6c:	bf25                	j	80005da4 <sys_open+0xa2>
    itrunc(ip);
    80005e6e:	8526                	mv	a0,s1
    80005e70:	ffffe097          	auipc	ra,0xffffe
    80005e74:	ff6080e7          	jalr	-10(ra) # 80003e66 <itrunc>
    80005e78:	bfa9                	j	80005dd2 <sys_open+0xd0>
      fileclose(f);
    80005e7a:	854e                	mv	a0,s3
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	d70080e7          	jalr	-656(ra) # 80004bec <fileclose>
    iunlockput(ip);
    80005e84:	8526                	mv	a0,s1
    80005e86:	ffffe097          	auipc	ra,0xffffe
    80005e8a:	134080e7          	jalr	308(ra) # 80003fba <iunlockput>
    end_op();
    80005e8e:	fffff097          	auipc	ra,0xfffff
    80005e92:	914080e7          	jalr	-1772(ra) # 800047a2 <end_op>
    return -1;
    80005e96:	557d                	li	a0,-1
    80005e98:	b7b9                	j	80005de6 <sys_open+0xe4>

0000000080005e9a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e9a:	7175                	addi	sp,sp,-144
    80005e9c:	e506                	sd	ra,136(sp)
    80005e9e:	e122                	sd	s0,128(sp)
    80005ea0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ea2:	fffff097          	auipc	ra,0xfffff
    80005ea6:	882080e7          	jalr	-1918(ra) # 80004724 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005eaa:	08000613          	li	a2,128
    80005eae:	f7040593          	addi	a1,s0,-144
    80005eb2:	4501                	li	a0,0
    80005eb4:	ffffd097          	auipc	ra,0xffffd
    80005eb8:	1f2080e7          	jalr	498(ra) # 800030a6 <argstr>
    80005ebc:	02054963          	bltz	a0,80005eee <sys_mkdir+0x54>
    80005ec0:	4681                	li	a3,0
    80005ec2:	4601                	li	a2,0
    80005ec4:	4585                	li	a1,1
    80005ec6:	f7040513          	addi	a0,s0,-144
    80005eca:	fffff097          	auipc	ra,0xfffff
    80005ece:	7fc080e7          	jalr	2044(ra) # 800056c6 <create>
    80005ed2:	cd11                	beqz	a0,80005eee <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ed4:	ffffe097          	auipc	ra,0xffffe
    80005ed8:	0e6080e7          	jalr	230(ra) # 80003fba <iunlockput>
  end_op();
    80005edc:	fffff097          	auipc	ra,0xfffff
    80005ee0:	8c6080e7          	jalr	-1850(ra) # 800047a2 <end_op>
  return 0;
    80005ee4:	4501                	li	a0,0
}
    80005ee6:	60aa                	ld	ra,136(sp)
    80005ee8:	640a                	ld	s0,128(sp)
    80005eea:	6149                	addi	sp,sp,144
    80005eec:	8082                	ret
    end_op();
    80005eee:	fffff097          	auipc	ra,0xfffff
    80005ef2:	8b4080e7          	jalr	-1868(ra) # 800047a2 <end_op>
    return -1;
    80005ef6:	557d                	li	a0,-1
    80005ef8:	b7fd                	j	80005ee6 <sys_mkdir+0x4c>

0000000080005efa <sys_mknod>:

uint64
sys_mknod(void)
{
    80005efa:	7135                	addi	sp,sp,-160
    80005efc:	ed06                	sd	ra,152(sp)
    80005efe:	e922                	sd	s0,144(sp)
    80005f00:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	822080e7          	jalr	-2014(ra) # 80004724 <begin_op>
  argint(1, &major);
    80005f0a:	f6c40593          	addi	a1,s0,-148
    80005f0e:	4505                	li	a0,1
    80005f10:	ffffd097          	auipc	ra,0xffffd
    80005f14:	156080e7          	jalr	342(ra) # 80003066 <argint>
  argint(2, &minor);
    80005f18:	f6840593          	addi	a1,s0,-152
    80005f1c:	4509                	li	a0,2
    80005f1e:	ffffd097          	auipc	ra,0xffffd
    80005f22:	148080e7          	jalr	328(ra) # 80003066 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f26:	08000613          	li	a2,128
    80005f2a:	f7040593          	addi	a1,s0,-144
    80005f2e:	4501                	li	a0,0
    80005f30:	ffffd097          	auipc	ra,0xffffd
    80005f34:	176080e7          	jalr	374(ra) # 800030a6 <argstr>
    80005f38:	02054b63          	bltz	a0,80005f6e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f3c:	f6841683          	lh	a3,-152(s0)
    80005f40:	f6c41603          	lh	a2,-148(s0)
    80005f44:	458d                	li	a1,3
    80005f46:	f7040513          	addi	a0,s0,-144
    80005f4a:	fffff097          	auipc	ra,0xfffff
    80005f4e:	77c080e7          	jalr	1916(ra) # 800056c6 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f52:	cd11                	beqz	a0,80005f6e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	066080e7          	jalr	102(ra) # 80003fba <iunlockput>
  end_op();
    80005f5c:	fffff097          	auipc	ra,0xfffff
    80005f60:	846080e7          	jalr	-1978(ra) # 800047a2 <end_op>
  return 0;
    80005f64:	4501                	li	a0,0
}
    80005f66:	60ea                	ld	ra,152(sp)
    80005f68:	644a                	ld	s0,144(sp)
    80005f6a:	610d                	addi	sp,sp,160
    80005f6c:	8082                	ret
    end_op();
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	834080e7          	jalr	-1996(ra) # 800047a2 <end_op>
    return -1;
    80005f76:	557d                	li	a0,-1
    80005f78:	b7fd                	j	80005f66 <sys_mknod+0x6c>

0000000080005f7a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f7a:	7135                	addi	sp,sp,-160
    80005f7c:	ed06                	sd	ra,152(sp)
    80005f7e:	e922                	sd	s0,144(sp)
    80005f80:	e526                	sd	s1,136(sp)
    80005f82:	e14a                	sd	s2,128(sp)
    80005f84:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f86:	ffffc097          	auipc	ra,0xffffc
    80005f8a:	ccc080e7          	jalr	-820(ra) # 80001c52 <myproc>
    80005f8e:	892a                	mv	s2,a0
  
  begin_op();
    80005f90:	ffffe097          	auipc	ra,0xffffe
    80005f94:	794080e7          	jalr	1940(ra) # 80004724 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f98:	08000613          	li	a2,128
    80005f9c:	f6040593          	addi	a1,s0,-160
    80005fa0:	4501                	li	a0,0
    80005fa2:	ffffd097          	auipc	ra,0xffffd
    80005fa6:	104080e7          	jalr	260(ra) # 800030a6 <argstr>
    80005faa:	04054b63          	bltz	a0,80006000 <sys_chdir+0x86>
    80005fae:	f6040513          	addi	a0,s0,-160
    80005fb2:	ffffe097          	auipc	ra,0xffffe
    80005fb6:	552080e7          	jalr	1362(ra) # 80004504 <namei>
    80005fba:	84aa                	mv	s1,a0
    80005fbc:	c131                	beqz	a0,80006000 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005fbe:	ffffe097          	auipc	ra,0xffffe
    80005fc2:	d9a080e7          	jalr	-614(ra) # 80003d58 <ilock>
  if(ip->type != T_DIR){
    80005fc6:	04449703          	lh	a4,68(s1)
    80005fca:	4785                	li	a5,1
    80005fcc:	04f71063          	bne	a4,a5,8000600c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005fd0:	8526                	mv	a0,s1
    80005fd2:	ffffe097          	auipc	ra,0xffffe
    80005fd6:	e48080e7          	jalr	-440(ra) # 80003e1a <iunlock>
  iput(p->cwd);
    80005fda:	15093503          	ld	a0,336(s2)
    80005fde:	ffffe097          	auipc	ra,0xffffe
    80005fe2:	f34080e7          	jalr	-204(ra) # 80003f12 <iput>
  end_op();
    80005fe6:	ffffe097          	auipc	ra,0xffffe
    80005fea:	7bc080e7          	jalr	1980(ra) # 800047a2 <end_op>
  p->cwd = ip;
    80005fee:	14993823          	sd	s1,336(s2)
  return 0;
    80005ff2:	4501                	li	a0,0
}
    80005ff4:	60ea                	ld	ra,152(sp)
    80005ff6:	644a                	ld	s0,144(sp)
    80005ff8:	64aa                	ld	s1,136(sp)
    80005ffa:	690a                	ld	s2,128(sp)
    80005ffc:	610d                	addi	sp,sp,160
    80005ffe:	8082                	ret
    end_op();
    80006000:	ffffe097          	auipc	ra,0xffffe
    80006004:	7a2080e7          	jalr	1954(ra) # 800047a2 <end_op>
    return -1;
    80006008:	557d                	li	a0,-1
    8000600a:	b7ed                	j	80005ff4 <sys_chdir+0x7a>
    iunlockput(ip);
    8000600c:	8526                	mv	a0,s1
    8000600e:	ffffe097          	auipc	ra,0xffffe
    80006012:	fac080e7          	jalr	-84(ra) # 80003fba <iunlockput>
    end_op();
    80006016:	ffffe097          	auipc	ra,0xffffe
    8000601a:	78c080e7          	jalr	1932(ra) # 800047a2 <end_op>
    return -1;
    8000601e:	557d                	li	a0,-1
    80006020:	bfd1                	j	80005ff4 <sys_chdir+0x7a>

0000000080006022 <sys_exec>:

uint64
sys_exec(void)
{
    80006022:	7145                	addi	sp,sp,-464
    80006024:	e786                	sd	ra,456(sp)
    80006026:	e3a2                	sd	s0,448(sp)
    80006028:	ff26                	sd	s1,440(sp)
    8000602a:	fb4a                	sd	s2,432(sp)
    8000602c:	f74e                	sd	s3,424(sp)
    8000602e:	f352                	sd	s4,416(sp)
    80006030:	ef56                	sd	s5,408(sp)
    80006032:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006034:	e3840593          	addi	a1,s0,-456
    80006038:	4505                	li	a0,1
    8000603a:	ffffd097          	auipc	ra,0xffffd
    8000603e:	04c080e7          	jalr	76(ra) # 80003086 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006042:	08000613          	li	a2,128
    80006046:	f4040593          	addi	a1,s0,-192
    8000604a:	4501                	li	a0,0
    8000604c:	ffffd097          	auipc	ra,0xffffd
    80006050:	05a080e7          	jalr	90(ra) # 800030a6 <argstr>
    80006054:	87aa                	mv	a5,a0
    return -1;
    80006056:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006058:	0c07c363          	bltz	a5,8000611e <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    8000605c:	10000613          	li	a2,256
    80006060:	4581                	li	a1,0
    80006062:	e4040513          	addi	a0,s0,-448
    80006066:	ffffb097          	auipc	ra,0xffffb
    8000606a:	e44080e7          	jalr	-444(ra) # 80000eaa <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000606e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006072:	89a6                	mv	s3,s1
    80006074:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006076:	02000a13          	li	s4,32
    8000607a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000607e:	00391513          	slli	a0,s2,0x3
    80006082:	e3040593          	addi	a1,s0,-464
    80006086:	e3843783          	ld	a5,-456(s0)
    8000608a:	953e                	add	a0,a0,a5
    8000608c:	ffffd097          	auipc	ra,0xffffd
    80006090:	f3c080e7          	jalr	-196(ra) # 80002fc8 <fetchaddr>
    80006094:	02054a63          	bltz	a0,800060c8 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006098:	e3043783          	ld	a5,-464(s0)
    8000609c:	c3b9                	beqz	a5,800060e2 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000609e:	ffffb097          	auipc	ra,0xffffb
    800060a2:	94a080e7          	jalr	-1718(ra) # 800009e8 <kalloc>
    800060a6:	85aa                	mv	a1,a0
    800060a8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800060ac:	cd11                	beqz	a0,800060c8 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800060ae:	6605                	lui	a2,0x1
    800060b0:	e3043503          	ld	a0,-464(s0)
    800060b4:	ffffd097          	auipc	ra,0xffffd
    800060b8:	f66080e7          	jalr	-154(ra) # 8000301a <fetchstr>
    800060bc:	00054663          	bltz	a0,800060c8 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800060c0:	0905                	addi	s2,s2,1
    800060c2:	09a1                	addi	s3,s3,8
    800060c4:	fb491be3          	bne	s2,s4,8000607a <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060c8:	f4040913          	addi	s2,s0,-192
    800060cc:	6088                	ld	a0,0(s1)
    800060ce:	c539                	beqz	a0,8000611c <sys_exec+0xfa>
    kfree(argv[i]);
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	ab4080e7          	jalr	-1356(ra) # 80000b84 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060d8:	04a1                	addi	s1,s1,8
    800060da:	ff2499e3          	bne	s1,s2,800060cc <sys_exec+0xaa>
  return -1;
    800060de:	557d                	li	a0,-1
    800060e0:	a83d                	j	8000611e <sys_exec+0xfc>
      argv[i] = 0;
    800060e2:	0a8e                	slli	s5,s5,0x3
    800060e4:	fc0a8793          	addi	a5,s5,-64
    800060e8:	00878ab3          	add	s5,a5,s0
    800060ec:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800060f0:	e4040593          	addi	a1,s0,-448
    800060f4:	f4040513          	addi	a0,s0,-192
    800060f8:	fffff097          	auipc	ra,0xfffff
    800060fc:	16e080e7          	jalr	366(ra) # 80005266 <exec>
    80006100:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006102:	f4040993          	addi	s3,s0,-192
    80006106:	6088                	ld	a0,0(s1)
    80006108:	c901                	beqz	a0,80006118 <sys_exec+0xf6>
    kfree(argv[i]);
    8000610a:	ffffb097          	auipc	ra,0xffffb
    8000610e:	a7a080e7          	jalr	-1414(ra) # 80000b84 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006112:	04a1                	addi	s1,s1,8
    80006114:	ff3499e3          	bne	s1,s3,80006106 <sys_exec+0xe4>
  return ret;
    80006118:	854a                	mv	a0,s2
    8000611a:	a011                	j	8000611e <sys_exec+0xfc>
  return -1;
    8000611c:	557d                	li	a0,-1
}
    8000611e:	60be                	ld	ra,456(sp)
    80006120:	641e                	ld	s0,448(sp)
    80006122:	74fa                	ld	s1,440(sp)
    80006124:	795a                	ld	s2,432(sp)
    80006126:	79ba                	ld	s3,424(sp)
    80006128:	7a1a                	ld	s4,416(sp)
    8000612a:	6afa                	ld	s5,408(sp)
    8000612c:	6179                	addi	sp,sp,464
    8000612e:	8082                	ret

0000000080006130 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006130:	7139                	addi	sp,sp,-64
    80006132:	fc06                	sd	ra,56(sp)
    80006134:	f822                	sd	s0,48(sp)
    80006136:	f426                	sd	s1,40(sp)
    80006138:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000613a:	ffffc097          	auipc	ra,0xffffc
    8000613e:	b18080e7          	jalr	-1256(ra) # 80001c52 <myproc>
    80006142:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006144:	fd840593          	addi	a1,s0,-40
    80006148:	4501                	li	a0,0
    8000614a:	ffffd097          	auipc	ra,0xffffd
    8000614e:	f3c080e7          	jalr	-196(ra) # 80003086 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006152:	fc840593          	addi	a1,s0,-56
    80006156:	fd040513          	addi	a0,s0,-48
    8000615a:	fffff097          	auipc	ra,0xfffff
    8000615e:	dc2080e7          	jalr	-574(ra) # 80004f1c <pipealloc>
    return -1;
    80006162:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006164:	0c054463          	bltz	a0,8000622c <sys_pipe+0xfc>
  fd0 = -1;
    80006168:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000616c:	fd043503          	ld	a0,-48(s0)
    80006170:	fffff097          	auipc	ra,0xfffff
    80006174:	514080e7          	jalr	1300(ra) # 80005684 <fdalloc>
    80006178:	fca42223          	sw	a0,-60(s0)
    8000617c:	08054b63          	bltz	a0,80006212 <sys_pipe+0xe2>
    80006180:	fc843503          	ld	a0,-56(s0)
    80006184:	fffff097          	auipc	ra,0xfffff
    80006188:	500080e7          	jalr	1280(ra) # 80005684 <fdalloc>
    8000618c:	fca42023          	sw	a0,-64(s0)
    80006190:	06054863          	bltz	a0,80006200 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006194:	4691                	li	a3,4
    80006196:	fc440613          	addi	a2,s0,-60
    8000619a:	fd843583          	ld	a1,-40(s0)
    8000619e:	68a8                	ld	a0,80(s1)
    800061a0:	ffffc097          	auipc	ra,0xffffc
    800061a4:	89c080e7          	jalr	-1892(ra) # 80001a3c <copyout>
    800061a8:	02054063          	bltz	a0,800061c8 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800061ac:	4691                	li	a3,4
    800061ae:	fc040613          	addi	a2,s0,-64
    800061b2:	fd843583          	ld	a1,-40(s0)
    800061b6:	0591                	addi	a1,a1,4
    800061b8:	68a8                	ld	a0,80(s1)
    800061ba:	ffffc097          	auipc	ra,0xffffc
    800061be:	882080e7          	jalr	-1918(ra) # 80001a3c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800061c2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061c4:	06055463          	bgez	a0,8000622c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800061c8:	fc442783          	lw	a5,-60(s0)
    800061cc:	07e9                	addi	a5,a5,26
    800061ce:	078e                	slli	a5,a5,0x3
    800061d0:	97a6                	add	a5,a5,s1
    800061d2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800061d6:	fc042783          	lw	a5,-64(s0)
    800061da:	07e9                	addi	a5,a5,26
    800061dc:	078e                	slli	a5,a5,0x3
    800061de:	94be                	add	s1,s1,a5
    800061e0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800061e4:	fd043503          	ld	a0,-48(s0)
    800061e8:	fffff097          	auipc	ra,0xfffff
    800061ec:	a04080e7          	jalr	-1532(ra) # 80004bec <fileclose>
    fileclose(wf);
    800061f0:	fc843503          	ld	a0,-56(s0)
    800061f4:	fffff097          	auipc	ra,0xfffff
    800061f8:	9f8080e7          	jalr	-1544(ra) # 80004bec <fileclose>
    return -1;
    800061fc:	57fd                	li	a5,-1
    800061fe:	a03d                	j	8000622c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006200:	fc442783          	lw	a5,-60(s0)
    80006204:	0007c763          	bltz	a5,80006212 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006208:	07e9                	addi	a5,a5,26
    8000620a:	078e                	slli	a5,a5,0x3
    8000620c:	97a6                	add	a5,a5,s1
    8000620e:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006212:	fd043503          	ld	a0,-48(s0)
    80006216:	fffff097          	auipc	ra,0xfffff
    8000621a:	9d6080e7          	jalr	-1578(ra) # 80004bec <fileclose>
    fileclose(wf);
    8000621e:	fc843503          	ld	a0,-56(s0)
    80006222:	fffff097          	auipc	ra,0xfffff
    80006226:	9ca080e7          	jalr	-1590(ra) # 80004bec <fileclose>
    return -1;
    8000622a:	57fd                	li	a5,-1
}
    8000622c:	853e                	mv	a0,a5
    8000622e:	70e2                	ld	ra,56(sp)
    80006230:	7442                	ld	s0,48(sp)
    80006232:	74a2                	ld	s1,40(sp)
    80006234:	6121                	addi	sp,sp,64
    80006236:	8082                	ret
	...

0000000080006240 <kernelvec>:
    80006240:	7111                	addi	sp,sp,-256
    80006242:	e006                	sd	ra,0(sp)
    80006244:	e40a                	sd	sp,8(sp)
    80006246:	e80e                	sd	gp,16(sp)
    80006248:	ec12                	sd	tp,24(sp)
    8000624a:	f016                	sd	t0,32(sp)
    8000624c:	f41a                	sd	t1,40(sp)
    8000624e:	f81e                	sd	t2,48(sp)
    80006250:	fc22                	sd	s0,56(sp)
    80006252:	e0a6                	sd	s1,64(sp)
    80006254:	e4aa                	sd	a0,72(sp)
    80006256:	e8ae                	sd	a1,80(sp)
    80006258:	ecb2                	sd	a2,88(sp)
    8000625a:	f0b6                	sd	a3,96(sp)
    8000625c:	f4ba                	sd	a4,104(sp)
    8000625e:	f8be                	sd	a5,112(sp)
    80006260:	fcc2                	sd	a6,120(sp)
    80006262:	e146                	sd	a7,128(sp)
    80006264:	e54a                	sd	s2,136(sp)
    80006266:	e94e                	sd	s3,144(sp)
    80006268:	ed52                	sd	s4,152(sp)
    8000626a:	f156                	sd	s5,160(sp)
    8000626c:	f55a                	sd	s6,168(sp)
    8000626e:	f95e                	sd	s7,176(sp)
    80006270:	fd62                	sd	s8,184(sp)
    80006272:	e1e6                	sd	s9,192(sp)
    80006274:	e5ea                	sd	s10,200(sp)
    80006276:	e9ee                	sd	s11,208(sp)
    80006278:	edf2                	sd	t3,216(sp)
    8000627a:	f1f6                	sd	t4,224(sp)
    8000627c:	f5fa                	sd	t5,232(sp)
    8000627e:	f9fe                	sd	t6,240(sp)
    80006280:	c15fc0ef          	jal	ra,80002e94 <kerneltrap>
    80006284:	6082                	ld	ra,0(sp)
    80006286:	6122                	ld	sp,8(sp)
    80006288:	61c2                	ld	gp,16(sp)
    8000628a:	7282                	ld	t0,32(sp)
    8000628c:	7322                	ld	t1,40(sp)
    8000628e:	73c2                	ld	t2,48(sp)
    80006290:	7462                	ld	s0,56(sp)
    80006292:	6486                	ld	s1,64(sp)
    80006294:	6526                	ld	a0,72(sp)
    80006296:	65c6                	ld	a1,80(sp)
    80006298:	6666                	ld	a2,88(sp)
    8000629a:	7686                	ld	a3,96(sp)
    8000629c:	7726                	ld	a4,104(sp)
    8000629e:	77c6                	ld	a5,112(sp)
    800062a0:	7866                	ld	a6,120(sp)
    800062a2:	688a                	ld	a7,128(sp)
    800062a4:	692a                	ld	s2,136(sp)
    800062a6:	69ca                	ld	s3,144(sp)
    800062a8:	6a6a                	ld	s4,152(sp)
    800062aa:	7a8a                	ld	s5,160(sp)
    800062ac:	7b2a                	ld	s6,168(sp)
    800062ae:	7bca                	ld	s7,176(sp)
    800062b0:	7c6a                	ld	s8,184(sp)
    800062b2:	6c8e                	ld	s9,192(sp)
    800062b4:	6d2e                	ld	s10,200(sp)
    800062b6:	6dce                	ld	s11,208(sp)
    800062b8:	6e6e                	ld	t3,216(sp)
    800062ba:	7e8e                	ld	t4,224(sp)
    800062bc:	7f2e                	ld	t5,232(sp)
    800062be:	7fce                	ld	t6,240(sp)
    800062c0:	6111                	addi	sp,sp,256
    800062c2:	10200073          	sret
    800062c6:	00000013          	nop
    800062ca:	00000013          	nop
    800062ce:	0001                	nop

00000000800062d0 <timervec>:
    800062d0:	34051573          	csrrw	a0,mscratch,a0
    800062d4:	e10c                	sd	a1,0(a0)
    800062d6:	e510                	sd	a2,8(a0)
    800062d8:	e914                	sd	a3,16(a0)
    800062da:	6d0c                	ld	a1,24(a0)
    800062dc:	7110                	ld	a2,32(a0)
    800062de:	6194                	ld	a3,0(a1)
    800062e0:	96b2                	add	a3,a3,a2
    800062e2:	e194                	sd	a3,0(a1)
    800062e4:	4589                	li	a1,2
    800062e6:	14459073          	csrw	sip,a1
    800062ea:	6914                	ld	a3,16(a0)
    800062ec:	6510                	ld	a2,8(a0)
    800062ee:	610c                	ld	a1,0(a0)
    800062f0:	34051573          	csrrw	a0,mscratch,a0
    800062f4:	30200073          	mret
	...

00000000800062fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062fa:	1141                	addi	sp,sp,-16
    800062fc:	e422                	sd	s0,8(sp)
    800062fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006300:	0c0007b7          	lui	a5,0xc000
    80006304:	4705                	li	a4,1
    80006306:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006308:	c3d8                	sw	a4,4(a5)
}
    8000630a:	6422                	ld	s0,8(sp)
    8000630c:	0141                	addi	sp,sp,16
    8000630e:	8082                	ret

0000000080006310 <plicinithart>:

void
plicinithart(void)
{
    80006310:	1141                	addi	sp,sp,-16
    80006312:	e406                	sd	ra,8(sp)
    80006314:	e022                	sd	s0,0(sp)
    80006316:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006318:	ffffc097          	auipc	ra,0xffffc
    8000631c:	90e080e7          	jalr	-1778(ra) # 80001c26 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006320:	0085171b          	slliw	a4,a0,0x8
    80006324:	0c0027b7          	lui	a5,0xc002
    80006328:	97ba                	add	a5,a5,a4
    8000632a:	40200713          	li	a4,1026
    8000632e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006332:	00d5151b          	slliw	a0,a0,0xd
    80006336:	0c2017b7          	lui	a5,0xc201
    8000633a:	97aa                	add	a5,a5,a0
    8000633c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006340:	60a2                	ld	ra,8(sp)
    80006342:	6402                	ld	s0,0(sp)
    80006344:	0141                	addi	sp,sp,16
    80006346:	8082                	ret

0000000080006348 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006348:	1141                	addi	sp,sp,-16
    8000634a:	e406                	sd	ra,8(sp)
    8000634c:	e022                	sd	s0,0(sp)
    8000634e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006350:	ffffc097          	auipc	ra,0xffffc
    80006354:	8d6080e7          	jalr	-1834(ra) # 80001c26 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006358:	00d5151b          	slliw	a0,a0,0xd
    8000635c:	0c2017b7          	lui	a5,0xc201
    80006360:	97aa                	add	a5,a5,a0
  return irq;
}
    80006362:	43c8                	lw	a0,4(a5)
    80006364:	60a2                	ld	ra,8(sp)
    80006366:	6402                	ld	s0,0(sp)
    80006368:	0141                	addi	sp,sp,16
    8000636a:	8082                	ret

000000008000636c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000636c:	1101                	addi	sp,sp,-32
    8000636e:	ec06                	sd	ra,24(sp)
    80006370:	e822                	sd	s0,16(sp)
    80006372:	e426                	sd	s1,8(sp)
    80006374:	1000                	addi	s0,sp,32
    80006376:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006378:	ffffc097          	auipc	ra,0xffffc
    8000637c:	8ae080e7          	jalr	-1874(ra) # 80001c26 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006380:	00d5151b          	slliw	a0,a0,0xd
    80006384:	0c2017b7          	lui	a5,0xc201
    80006388:	97aa                	add	a5,a5,a0
    8000638a:	c3c4                	sw	s1,4(a5)
}
    8000638c:	60e2                	ld	ra,24(sp)
    8000638e:	6442                	ld	s0,16(sp)
    80006390:	64a2                	ld	s1,8(sp)
    80006392:	6105                	addi	sp,sp,32
    80006394:	8082                	ret

0000000080006396 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006396:	1141                	addi	sp,sp,-16
    80006398:	e406                	sd	ra,8(sp)
    8000639a:	e022                	sd	s0,0(sp)
    8000639c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000639e:	479d                	li	a5,7
    800063a0:	04a7cc63          	blt	a5,a0,800063f8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800063a4:	0003d797          	auipc	a5,0x3d
    800063a8:	ac478793          	addi	a5,a5,-1340 # 80042e68 <disk>
    800063ac:	97aa                	add	a5,a5,a0
    800063ae:	0187c783          	lbu	a5,24(a5)
    800063b2:	ebb9                	bnez	a5,80006408 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800063b4:	00451693          	slli	a3,a0,0x4
    800063b8:	0003d797          	auipc	a5,0x3d
    800063bc:	ab078793          	addi	a5,a5,-1360 # 80042e68 <disk>
    800063c0:	6398                	ld	a4,0(a5)
    800063c2:	9736                	add	a4,a4,a3
    800063c4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800063c8:	6398                	ld	a4,0(a5)
    800063ca:	9736                	add	a4,a4,a3
    800063cc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800063d0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800063d4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800063d8:	97aa                	add	a5,a5,a0
    800063da:	4705                	li	a4,1
    800063dc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800063e0:	0003d517          	auipc	a0,0x3d
    800063e4:	aa050513          	addi	a0,a0,-1376 # 80042e80 <disk+0x18>
    800063e8:	ffffc097          	auipc	ra,0xffffc
    800063ec:	fce080e7          	jalr	-50(ra) # 800023b6 <wakeup>
}
    800063f0:	60a2                	ld	ra,8(sp)
    800063f2:	6402                	ld	s0,0(sp)
    800063f4:	0141                	addi	sp,sp,16
    800063f6:	8082                	ret
    panic("free_desc 1");
    800063f8:	00002517          	auipc	a0,0x2
    800063fc:	37850513          	addi	a0,a0,888 # 80008770 <syscalls+0x310>
    80006400:	ffffa097          	auipc	ra,0xffffa
    80006404:	140080e7          	jalr	320(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006408:	00002517          	auipc	a0,0x2
    8000640c:	37850513          	addi	a0,a0,888 # 80008780 <syscalls+0x320>
    80006410:	ffffa097          	auipc	ra,0xffffa
    80006414:	130080e7          	jalr	304(ra) # 80000540 <panic>

0000000080006418 <virtio_disk_init>:
{
    80006418:	1101                	addi	sp,sp,-32
    8000641a:	ec06                	sd	ra,24(sp)
    8000641c:	e822                	sd	s0,16(sp)
    8000641e:	e426                	sd	s1,8(sp)
    80006420:	e04a                	sd	s2,0(sp)
    80006422:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006424:	00002597          	auipc	a1,0x2
    80006428:	36c58593          	addi	a1,a1,876 # 80008790 <syscalls+0x330>
    8000642c:	0003d517          	auipc	a0,0x3d
    80006430:	b6450513          	addi	a0,a0,-1180 # 80042f90 <disk+0x128>
    80006434:	ffffb097          	auipc	ra,0xffffb
    80006438:	8ea080e7          	jalr	-1814(ra) # 80000d1e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000643c:	100017b7          	lui	a5,0x10001
    80006440:	4398                	lw	a4,0(a5)
    80006442:	2701                	sext.w	a4,a4
    80006444:	747277b7          	lui	a5,0x74727
    80006448:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000644c:	14f71b63          	bne	a4,a5,800065a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006450:	100017b7          	lui	a5,0x10001
    80006454:	43dc                	lw	a5,4(a5)
    80006456:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006458:	4709                	li	a4,2
    8000645a:	14e79463          	bne	a5,a4,800065a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000645e:	100017b7          	lui	a5,0x10001
    80006462:	479c                	lw	a5,8(a5)
    80006464:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006466:	12e79e63          	bne	a5,a4,800065a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000646a:	100017b7          	lui	a5,0x10001
    8000646e:	47d8                	lw	a4,12(a5)
    80006470:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006472:	554d47b7          	lui	a5,0x554d4
    80006476:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000647a:	12f71463          	bne	a4,a5,800065a2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000647e:	100017b7          	lui	a5,0x10001
    80006482:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006486:	4705                	li	a4,1
    80006488:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000648a:	470d                	li	a4,3
    8000648c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000648e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006490:	c7ffe6b7          	lui	a3,0xc7ffe
    80006494:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fbb7b7>
    80006498:	8f75                	and	a4,a4,a3
    8000649a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000649c:	472d                	li	a4,11
    8000649e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800064a0:	5bbc                	lw	a5,112(a5)
    800064a2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800064a6:	8ba1                	andi	a5,a5,8
    800064a8:	10078563          	beqz	a5,800065b2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800064ac:	100017b7          	lui	a5,0x10001
    800064b0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800064b4:	43fc                	lw	a5,68(a5)
    800064b6:	2781                	sext.w	a5,a5
    800064b8:	10079563          	bnez	a5,800065c2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800064bc:	100017b7          	lui	a5,0x10001
    800064c0:	5bdc                	lw	a5,52(a5)
    800064c2:	2781                	sext.w	a5,a5
  if(max == 0)
    800064c4:	10078763          	beqz	a5,800065d2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800064c8:	471d                	li	a4,7
    800064ca:	10f77c63          	bgeu	a4,a5,800065e2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800064ce:	ffffa097          	auipc	ra,0xffffa
    800064d2:	51a080e7          	jalr	1306(ra) # 800009e8 <kalloc>
    800064d6:	0003d497          	auipc	s1,0x3d
    800064da:	99248493          	addi	s1,s1,-1646 # 80042e68 <disk>
    800064de:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800064e0:	ffffa097          	auipc	ra,0xffffa
    800064e4:	508080e7          	jalr	1288(ra) # 800009e8 <kalloc>
    800064e8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	4fe080e7          	jalr	1278(ra) # 800009e8 <kalloc>
    800064f2:	87aa                	mv	a5,a0
    800064f4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800064f6:	6088                	ld	a0,0(s1)
    800064f8:	cd6d                	beqz	a0,800065f2 <virtio_disk_init+0x1da>
    800064fa:	0003d717          	auipc	a4,0x3d
    800064fe:	97673703          	ld	a4,-1674(a4) # 80042e70 <disk+0x8>
    80006502:	cb65                	beqz	a4,800065f2 <virtio_disk_init+0x1da>
    80006504:	c7fd                	beqz	a5,800065f2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006506:	6605                	lui	a2,0x1
    80006508:	4581                	li	a1,0
    8000650a:	ffffb097          	auipc	ra,0xffffb
    8000650e:	9a0080e7          	jalr	-1632(ra) # 80000eaa <memset>
  memset(disk.avail, 0, PGSIZE);
    80006512:	0003d497          	auipc	s1,0x3d
    80006516:	95648493          	addi	s1,s1,-1706 # 80042e68 <disk>
    8000651a:	6605                	lui	a2,0x1
    8000651c:	4581                	li	a1,0
    8000651e:	6488                	ld	a0,8(s1)
    80006520:	ffffb097          	auipc	ra,0xffffb
    80006524:	98a080e7          	jalr	-1654(ra) # 80000eaa <memset>
  memset(disk.used, 0, PGSIZE);
    80006528:	6605                	lui	a2,0x1
    8000652a:	4581                	li	a1,0
    8000652c:	6888                	ld	a0,16(s1)
    8000652e:	ffffb097          	auipc	ra,0xffffb
    80006532:	97c080e7          	jalr	-1668(ra) # 80000eaa <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006536:	100017b7          	lui	a5,0x10001
    8000653a:	4721                	li	a4,8
    8000653c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000653e:	4098                	lw	a4,0(s1)
    80006540:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006544:	40d8                	lw	a4,4(s1)
    80006546:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000654a:	6498                	ld	a4,8(s1)
    8000654c:	0007069b          	sext.w	a3,a4
    80006550:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006554:	9701                	srai	a4,a4,0x20
    80006556:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000655a:	6898                	ld	a4,16(s1)
    8000655c:	0007069b          	sext.w	a3,a4
    80006560:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006564:	9701                	srai	a4,a4,0x20
    80006566:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000656a:	4705                	li	a4,1
    8000656c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000656e:	00e48c23          	sb	a4,24(s1)
    80006572:	00e48ca3          	sb	a4,25(s1)
    80006576:	00e48d23          	sb	a4,26(s1)
    8000657a:	00e48da3          	sb	a4,27(s1)
    8000657e:	00e48e23          	sb	a4,28(s1)
    80006582:	00e48ea3          	sb	a4,29(s1)
    80006586:	00e48f23          	sb	a4,30(s1)
    8000658a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000658e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006592:	0727a823          	sw	s2,112(a5)
}
    80006596:	60e2                	ld	ra,24(sp)
    80006598:	6442                	ld	s0,16(sp)
    8000659a:	64a2                	ld	s1,8(sp)
    8000659c:	6902                	ld	s2,0(sp)
    8000659e:	6105                	addi	sp,sp,32
    800065a0:	8082                	ret
    panic("could not find virtio disk");
    800065a2:	00002517          	auipc	a0,0x2
    800065a6:	1fe50513          	addi	a0,a0,510 # 800087a0 <syscalls+0x340>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	f96080e7          	jalr	-106(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    800065b2:	00002517          	auipc	a0,0x2
    800065b6:	20e50513          	addi	a0,a0,526 # 800087c0 <syscalls+0x360>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	f86080e7          	jalr	-122(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800065c2:	00002517          	auipc	a0,0x2
    800065c6:	21e50513          	addi	a0,a0,542 # 800087e0 <syscalls+0x380>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	f76080e7          	jalr	-138(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800065d2:	00002517          	auipc	a0,0x2
    800065d6:	22e50513          	addi	a0,a0,558 # 80008800 <syscalls+0x3a0>
    800065da:	ffffa097          	auipc	ra,0xffffa
    800065de:	f66080e7          	jalr	-154(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800065e2:	00002517          	auipc	a0,0x2
    800065e6:	23e50513          	addi	a0,a0,574 # 80008820 <syscalls+0x3c0>
    800065ea:	ffffa097          	auipc	ra,0xffffa
    800065ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800065f2:	00002517          	auipc	a0,0x2
    800065f6:	24e50513          	addi	a0,a0,590 # 80008840 <syscalls+0x3e0>
    800065fa:	ffffa097          	auipc	ra,0xffffa
    800065fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>

0000000080006602 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006602:	7119                	addi	sp,sp,-128
    80006604:	fc86                	sd	ra,120(sp)
    80006606:	f8a2                	sd	s0,112(sp)
    80006608:	f4a6                	sd	s1,104(sp)
    8000660a:	f0ca                	sd	s2,96(sp)
    8000660c:	ecce                	sd	s3,88(sp)
    8000660e:	e8d2                	sd	s4,80(sp)
    80006610:	e4d6                	sd	s5,72(sp)
    80006612:	e0da                	sd	s6,64(sp)
    80006614:	fc5e                	sd	s7,56(sp)
    80006616:	f862                	sd	s8,48(sp)
    80006618:	f466                	sd	s9,40(sp)
    8000661a:	f06a                	sd	s10,32(sp)
    8000661c:	ec6e                	sd	s11,24(sp)
    8000661e:	0100                	addi	s0,sp,128
    80006620:	8aaa                	mv	s5,a0
    80006622:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006624:	00c52d03          	lw	s10,12(a0)
    80006628:	001d1d1b          	slliw	s10,s10,0x1
    8000662c:	1d02                	slli	s10,s10,0x20
    8000662e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006632:	0003d517          	auipc	a0,0x3d
    80006636:	95e50513          	addi	a0,a0,-1698 # 80042f90 <disk+0x128>
    8000663a:	ffffa097          	auipc	ra,0xffffa
    8000663e:	774080e7          	jalr	1908(ra) # 80000dae <acquire>
  for(int i = 0; i < 3; i++){
    80006642:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006644:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006646:	0003db97          	auipc	s7,0x3d
    8000664a:	822b8b93          	addi	s7,s7,-2014 # 80042e68 <disk>
  for(int i = 0; i < 3; i++){
    8000664e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006650:	0003dc97          	auipc	s9,0x3d
    80006654:	940c8c93          	addi	s9,s9,-1728 # 80042f90 <disk+0x128>
    80006658:	a08d                	j	800066ba <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000665a:	00fb8733          	add	a4,s7,a5
    8000665e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006662:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006664:	0207c563          	bltz	a5,8000668e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006668:	2905                	addiw	s2,s2,1
    8000666a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000666c:	05690c63          	beq	s2,s6,800066c4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006670:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006672:	0003c717          	auipc	a4,0x3c
    80006676:	7f670713          	addi	a4,a4,2038 # 80042e68 <disk>
    8000667a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000667c:	01874683          	lbu	a3,24(a4)
    80006680:	fee9                	bnez	a3,8000665a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006682:	2785                	addiw	a5,a5,1
    80006684:	0705                	addi	a4,a4,1
    80006686:	fe979be3          	bne	a5,s1,8000667c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000668a:	57fd                	li	a5,-1
    8000668c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000668e:	01205d63          	blez	s2,800066a8 <virtio_disk_rw+0xa6>
    80006692:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006694:	000a2503          	lw	a0,0(s4)
    80006698:	00000097          	auipc	ra,0x0
    8000669c:	cfe080e7          	jalr	-770(ra) # 80006396 <free_desc>
      for(int j = 0; j < i; j++)
    800066a0:	2d85                	addiw	s11,s11,1
    800066a2:	0a11                	addi	s4,s4,4
    800066a4:	ff2d98e3          	bne	s11,s2,80006694 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066a8:	85e6                	mv	a1,s9
    800066aa:	0003c517          	auipc	a0,0x3c
    800066ae:	7d650513          	addi	a0,a0,2006 # 80042e80 <disk+0x18>
    800066b2:	ffffc097          	auipc	ra,0xffffc
    800066b6:	ca0080e7          	jalr	-864(ra) # 80002352 <sleep>
  for(int i = 0; i < 3; i++){
    800066ba:	f8040a13          	addi	s4,s0,-128
{
    800066be:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800066c0:	894e                	mv	s2,s3
    800066c2:	b77d                	j	80006670 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066c4:	f8042503          	lw	a0,-128(s0)
    800066c8:	00a50713          	addi	a4,a0,10
    800066cc:	0712                	slli	a4,a4,0x4

  if(write)
    800066ce:	0003c797          	auipc	a5,0x3c
    800066d2:	79a78793          	addi	a5,a5,1946 # 80042e68 <disk>
    800066d6:	00e786b3          	add	a3,a5,a4
    800066da:	01803633          	snez	a2,s8
    800066de:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066e0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800066e4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066e8:	f6070613          	addi	a2,a4,-160
    800066ec:	6394                	ld	a3,0(a5)
    800066ee:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066f0:	00870593          	addi	a1,a4,8
    800066f4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800066f6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066f8:	0007b803          	ld	a6,0(a5)
    800066fc:	9642                	add	a2,a2,a6
    800066fe:	46c1                	li	a3,16
    80006700:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006702:	4585                	li	a1,1
    80006704:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006708:	f8442683          	lw	a3,-124(s0)
    8000670c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006710:	0692                	slli	a3,a3,0x4
    80006712:	9836                	add	a6,a6,a3
    80006714:	058a8613          	addi	a2,s5,88
    80006718:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000671c:	0007b803          	ld	a6,0(a5)
    80006720:	96c2                	add	a3,a3,a6
    80006722:	40000613          	li	a2,1024
    80006726:	c690                	sw	a2,8(a3)
  if(write)
    80006728:	001c3613          	seqz	a2,s8
    8000672c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006730:	00166613          	ori	a2,a2,1
    80006734:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006738:	f8842603          	lw	a2,-120(s0)
    8000673c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006740:	00250693          	addi	a3,a0,2
    80006744:	0692                	slli	a3,a3,0x4
    80006746:	96be                	add	a3,a3,a5
    80006748:	58fd                	li	a7,-1
    8000674a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000674e:	0612                	slli	a2,a2,0x4
    80006750:	9832                	add	a6,a6,a2
    80006752:	f9070713          	addi	a4,a4,-112
    80006756:	973e                	add	a4,a4,a5
    80006758:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000675c:	6398                	ld	a4,0(a5)
    8000675e:	9732                	add	a4,a4,a2
    80006760:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006762:	4609                	li	a2,2
    80006764:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006768:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000676c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006770:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006774:	6794                	ld	a3,8(a5)
    80006776:	0026d703          	lhu	a4,2(a3)
    8000677a:	8b1d                	andi	a4,a4,7
    8000677c:	0706                	slli	a4,a4,0x1
    8000677e:	96ba                	add	a3,a3,a4
    80006780:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006784:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006788:	6798                	ld	a4,8(a5)
    8000678a:	00275783          	lhu	a5,2(a4)
    8000678e:	2785                	addiw	a5,a5,1
    80006790:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006794:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006798:	100017b7          	lui	a5,0x10001
    8000679c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067a0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800067a4:	0003c917          	auipc	s2,0x3c
    800067a8:	7ec90913          	addi	s2,s2,2028 # 80042f90 <disk+0x128>
  while(b->disk == 1) {
    800067ac:	4485                	li	s1,1
    800067ae:	00b79c63          	bne	a5,a1,800067c6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800067b2:	85ca                	mv	a1,s2
    800067b4:	8556                	mv	a0,s5
    800067b6:	ffffc097          	auipc	ra,0xffffc
    800067ba:	b9c080e7          	jalr	-1124(ra) # 80002352 <sleep>
  while(b->disk == 1) {
    800067be:	004aa783          	lw	a5,4(s5)
    800067c2:	fe9788e3          	beq	a5,s1,800067b2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800067c6:	f8042903          	lw	s2,-128(s0)
    800067ca:	00290713          	addi	a4,s2,2
    800067ce:	0712                	slli	a4,a4,0x4
    800067d0:	0003c797          	auipc	a5,0x3c
    800067d4:	69878793          	addi	a5,a5,1688 # 80042e68 <disk>
    800067d8:	97ba                	add	a5,a5,a4
    800067da:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800067de:	0003c997          	auipc	s3,0x3c
    800067e2:	68a98993          	addi	s3,s3,1674 # 80042e68 <disk>
    800067e6:	00491713          	slli	a4,s2,0x4
    800067ea:	0009b783          	ld	a5,0(s3)
    800067ee:	97ba                	add	a5,a5,a4
    800067f0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800067f4:	854a                	mv	a0,s2
    800067f6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800067fa:	00000097          	auipc	ra,0x0
    800067fe:	b9c080e7          	jalr	-1124(ra) # 80006396 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006802:	8885                	andi	s1,s1,1
    80006804:	f0ed                	bnez	s1,800067e6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006806:	0003c517          	auipc	a0,0x3c
    8000680a:	78a50513          	addi	a0,a0,1930 # 80042f90 <disk+0x128>
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	654080e7          	jalr	1620(ra) # 80000e62 <release>
}
    80006816:	70e6                	ld	ra,120(sp)
    80006818:	7446                	ld	s0,112(sp)
    8000681a:	74a6                	ld	s1,104(sp)
    8000681c:	7906                	ld	s2,96(sp)
    8000681e:	69e6                	ld	s3,88(sp)
    80006820:	6a46                	ld	s4,80(sp)
    80006822:	6aa6                	ld	s5,72(sp)
    80006824:	6b06                	ld	s6,64(sp)
    80006826:	7be2                	ld	s7,56(sp)
    80006828:	7c42                	ld	s8,48(sp)
    8000682a:	7ca2                	ld	s9,40(sp)
    8000682c:	7d02                	ld	s10,32(sp)
    8000682e:	6de2                	ld	s11,24(sp)
    80006830:	6109                	addi	sp,sp,128
    80006832:	8082                	ret

0000000080006834 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006834:	1101                	addi	sp,sp,-32
    80006836:	ec06                	sd	ra,24(sp)
    80006838:	e822                	sd	s0,16(sp)
    8000683a:	e426                	sd	s1,8(sp)
    8000683c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000683e:	0003c497          	auipc	s1,0x3c
    80006842:	62a48493          	addi	s1,s1,1578 # 80042e68 <disk>
    80006846:	0003c517          	auipc	a0,0x3c
    8000684a:	74a50513          	addi	a0,a0,1866 # 80042f90 <disk+0x128>
    8000684e:	ffffa097          	auipc	ra,0xffffa
    80006852:	560080e7          	jalr	1376(ra) # 80000dae <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006856:	10001737          	lui	a4,0x10001
    8000685a:	533c                	lw	a5,96(a4)
    8000685c:	8b8d                	andi	a5,a5,3
    8000685e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006860:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006864:	689c                	ld	a5,16(s1)
    80006866:	0204d703          	lhu	a4,32(s1)
    8000686a:	0027d783          	lhu	a5,2(a5)
    8000686e:	04f70863          	beq	a4,a5,800068be <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006872:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006876:	6898                	ld	a4,16(s1)
    80006878:	0204d783          	lhu	a5,32(s1)
    8000687c:	8b9d                	andi	a5,a5,7
    8000687e:	078e                	slli	a5,a5,0x3
    80006880:	97ba                	add	a5,a5,a4
    80006882:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006884:	00278713          	addi	a4,a5,2
    80006888:	0712                	slli	a4,a4,0x4
    8000688a:	9726                	add	a4,a4,s1
    8000688c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006890:	e721                	bnez	a4,800068d8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006892:	0789                	addi	a5,a5,2
    80006894:	0792                	slli	a5,a5,0x4
    80006896:	97a6                	add	a5,a5,s1
    80006898:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000689a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000689e:	ffffc097          	auipc	ra,0xffffc
    800068a2:	b18080e7          	jalr	-1256(ra) # 800023b6 <wakeup>

    disk.used_idx += 1;
    800068a6:	0204d783          	lhu	a5,32(s1)
    800068aa:	2785                	addiw	a5,a5,1
    800068ac:	17c2                	slli	a5,a5,0x30
    800068ae:	93c1                	srli	a5,a5,0x30
    800068b0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068b4:	6898                	ld	a4,16(s1)
    800068b6:	00275703          	lhu	a4,2(a4)
    800068ba:	faf71ce3          	bne	a4,a5,80006872 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800068be:	0003c517          	auipc	a0,0x3c
    800068c2:	6d250513          	addi	a0,a0,1746 # 80042f90 <disk+0x128>
    800068c6:	ffffa097          	auipc	ra,0xffffa
    800068ca:	59c080e7          	jalr	1436(ra) # 80000e62 <release>
}
    800068ce:	60e2                	ld	ra,24(sp)
    800068d0:	6442                	ld	s0,16(sp)
    800068d2:	64a2                	ld	s1,8(sp)
    800068d4:	6105                	addi	sp,sp,32
    800068d6:	8082                	ret
      panic("virtio_disk_intr status");
    800068d8:	00002517          	auipc	a0,0x2
    800068dc:	f8050513          	addi	a0,a0,-128 # 80008858 <syscalls+0x3f8>
    800068e0:	ffffa097          	auipc	ra,0xffffa
    800068e4:	c60080e7          	jalr	-928(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
