/*
 * lab1_prob3.s
 *
 * author: Alican Bayındır
 * 200102002087 - ELEC335 - LAB 1
 * Gebze Technical University - Electronics Engineering - Microprocessors labratory class
 * Description: turning on and off the 4 external LED connected to the G031K8 Nucleo board.
 */


.syntax unified
.cpu cortex-m0plus
.fpu softvfp
.thumb


/* make linker see this */
.global Reset_Handler

/* get these from linker script */
.word _sdata
.word _edata
.word _sbss
.word _ebss


/* define peripheral addresses from RM0444 page 57, Tables 3-4 */
.equ RCC_BASE,         (0x40021000)          // RCC base address
.equ RCC_IOPENR,       (RCC_BASE   + (0x34)) // RCC IOPENR register offset

.equ GPIOB_BASE,		(0x50000400)          // GPIOB base address
.equ GPIOB_MODER,		(GPIOB_BASE + (0x00)) // GPIOB MODER register offset
.equ GPIOB_ODR,			(GPIOB_BASE + (0x14)) // GPIOB ODR register offset
.equ GPUOB_IDR,			(GPIOB_BASE + (0X10)) // GPIOB IDR offset

/* vector table, +1 thumb mode */
.section .vectors
vector_table:
	.word _estack             /*     Stack pointer */
	.word Reset_Handler +1    /*     Reset handler */
	.word Default_Handler +1  /*       NMI handler */
	.word Default_Handler +1  /* HardFault handler */
	/* add rest of them here if needed */


/* reset handler */
.section .text
Reset_Handler:
	/* set stack pointer */
	ldr r0, =_estack
	mov sp, r0

	/* initialize data and bss 
	 * not necessary for rom only code 
	 * */
	bl init_data
	/* call main */
	bl main
	/* trap if returned */
	b .


/* initialize data and bss sections */
.section .text
init_data:

	/* copy rom to ram */
	ldr r0, =_sdata
	ldr r1, =_edata
	ldr r2, =_sidata
	movs r3, #0
	b LoopCopyDataInit

	CopyDataInit:
		ldr r4, [r2, r3]
		str r4, [r0, r3]
		adds r3, r3, #4

	LoopCopyDataInit:
		adds r4, r0, r3
		cmp r4, r1
		bcc CopyDataInit

	/* zero bss */
	ldr r2, =_sbss
	ldr r4, =_ebss
	movs r3, #0
	b LoopFillZerobss

	FillZerobss:
		str  r3, [r2]
		adds r2, r2, #4

	LoopFillZerobss:
		cmp r2, r4
		bcc FillZerobss

	bx lr


/* default handler */
.section .text
Default_Handler:
	b Default_Handler


/* main function */
.section .text
main:
	push {lr}
	/* enabling GPIO-B clock because the external LEDs is connected to it (PB1),
	giving 1 to bit 2 on IOPENR is enough for it because its GPIO-A's related bit*/
	ldr r6, = RCC_IOPENR
	ldr r5, [r6]
	// The value of 0x40021000 (GPIOB_BASE) + 0x34 is inside the register 5
	// so we can now acces to port B
	/* giving xxxx0010 to r4 register to enable GPIO-B port*/
	movs r4, 0x2
	// or-ing r5 with r4 to write 0010 to its LSBs
	orrs r5, r5, r4
	// have to store it to make it usable
	str r5, [r6]

	/* setting up B1 for led 01 for bits 2-3 in MODER */
	ldr r6, = GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	movs r4, 0x8	// xxxxx1000
	bics r5, r5, r4		// !!-WARNING-!! this line might not work
	str r5, [r6]

loop:
	/* turn on led connected to B1 in ODR */
	ldr r6, = GPIOB_ODR
	ldr r5, [r6]
	movs r4, #1
	lsls r4, r4, #1 // giving xxx00000001 to register 4
	orrs r5, r5, r4	// because we need to active 1st pin of A port
	str r5, [r6]	// when this line is processed the LED should be on because;
	// we now write 1 to the related register of PB1

	ldr r1, = #2000000
	bl delay

	ldr r6, = GPIOB_ODR
	ldr r5, [r6]
	movs r4, #1
	lsls r4, r4, #1 // giving xxx00000001 to register 4
	bics r5, r5, r4	// because we need to deactivate 1st pin of A port
	str r5, [r6]	// when this line is processed the LED should be on because;
	// we now write 0 to the related register of PB1

	ldr r1, =#2000000
	bl delay

	b loop
	pop {pc}

delay:
	subs r1, r1, #1
	bne delay
	bx lr
