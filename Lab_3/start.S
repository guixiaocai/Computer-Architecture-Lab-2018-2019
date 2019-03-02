#include <asm.h>
#include <regdef.h>
#include <ucas_cde.h>

#define TEST_NUM 68
#define	Time_1	25000000
#define	Time_2	3000000

#define lab2_1  1
#define lab2_2  1
#define lab2_3  1

##s0, number
##s1, number adress 
##s2, exception use
##s3, score
##s4, exception pc
	.set	noreorder
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:

	b	locate
	nop

##avoid "j locate" not taken
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
    nop

##avoid cpu run error
.org 0x0ec
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
.org 0x100
test_finish:
    addiu t0, t0, 1
    li t1, 0xff
    LI (t2, UART_ADDR)
    sw t1, 0x0(t2)
    b test_finish
    nop
##avoid cpu run error
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
/*
 *  exception handle
 */
 
   # CP0_COUNT   $9
   # CP0_COMPARE $11
   # CP0_STATUS  $12
   # CP0_CAUSE   $13
   # CP0_EPC     $14
.org 0x380
    mfc0  k1, $12
    mfc0  k0, $13
    and   k1, k0, k1
    or    k0, k1, zero
    andi  k0, 0x8000
    bne   k0, zero, int_timer  # Clock Interrupt
    nop
    or    k0, k1, zero
    andi  k0, 0x4000
    bne   k0, zero, set_time   # enter setting mode
    nop
    or    k0, k1, zero
    andi  k0, 0x800
    bne   k0, zero, set_hour   # set hour
    nop
    or    k0, k1, zero
    andi  k0, 0x1000
    bne   k0, zero, set_minute # set minute
    nop
    or    k0, k1, zero
    andi  k0, 0x2000
    bne   k0, zero, set_second # set second
    nop
    li    k0, 0
    mtc0  k0, $9
    nop	
    j     ret
    nop

locate:
    .set noreorder

    LI (a0, LED_RG1_ADDR)
    LI (a1, LED_RG0_ADDR)
    LI (a2, LED_ADDR)
    LI (s1, NUM_ADDR)

    LI (t1, 0x0002)
    LI (t2, 0x0001)
    LI (t3, 0x0000ffff)
    lui s3, 0

    li  t5, 2          # hour  | minute | second
    li  t4, 3          # t5 t4 | t3 t2  | t1 t0
    li  t3, 5
    li  t2, 9
    li  t1, 5
    li  t0, 5
    li  s0, 0          # indentify the mode: 0 for timer mode; 1 for setting mode
  	
    li    k0, Time_1   # initialize CP0_STATUS
    mtc0  k0, $11
    nop

    li    k0, 0
    mtc0  k0, $9
    nop

    mfc0  k0, $12      # initialize CP0_STATUS
    ori   k0, 0xf807
    xori  k0, 0x6
    mtc0  k0, $12
    nop

    jal   display_time
    nop
1:
    j     1b
    nop

display_time:
    move  k0, t0
 
    move  k1, t1
    sll   k1, 4
    addu  k0, k1

    move  k1, t2
    sll   k1, 8
    addu  k0, k1
    
    move  k1, t3
    sll   k1, 12
    addu  k0, k1
    
    move  k1, t4
    sll   k1, 16
    addu  k0, k1
    
    move  k1, t5
    sll   k1, 20
    addu  k0, k1
    
    li    k1, NUM_ADDR
    sw    k0, 0(k1)

    jr    ra
    nop
    
int_timer:
    li	  k0, Time_1
    mtc0  k0, $11
    nop

    li    s1, 9        # set t0
    bne   t0, s1, 2f
    nop
    li    t0, 0

    li    s1, 5        # set t1
    bne   t1, s1, 3f
    nop
    li    t1, 0
    
    li    s1, 9        # set t2
    bne   t2, s1, 4f
    nop
    li    t2, 0
    
    li    s1, 5        # set t3
    bne   t3, s1, 5f
    nop
    li    t3, 0
    
    li    s1, 2
    beq   t5, s1, 6f
    nop

    li    s1, 9
    bne   t4, s1, 7f
    nop
    li    t4, 0
    addiu t5, t5, 1

    j     1f
    nop

2:
    addiu t0, t0, 1
    j     1f
    nop

3:
    addiu t1, t1, 1
    j     1f
    nop
    
4:
    addiu t2, t2, 1
    j     1f
    nop
    
5:
    addiu t3, t3, 1
    j     1f
    nop
    
6:
    li    s1, 3
    bne   t4, s1, 7f
    nop
    
    li    t4, 0
    li    t5, 0
    j     1f
    nop

7:
    addiu t4, t4, 1
    j     1f
    nop
1:
    li		k0, 0
    mtc0	k0, $9
    nop
    jal   display_time
    nop
    j     ret
    nop
    
set_time:              # enter setting mode
    mfc0  k0, $12      
    xori  k0, 0x8000   # disable Clock Interruption
    mtc0  k0, $12
    nop

    xori  s0, 1        # change the mode
1:
    mfc0  k0, $13
    andi  k0, 0x4000
    bne   k0, zero, 1b
    nop

    li    k0, 0
    mtc0  k0, $9
    nop	
    j     ret
    nop

set_hour:              # set hour
    beq   s0, zero, 1f
    nop
    li    k0, Time_2
0:
    addiu k0, k0, -1
    bne		k0, zero, 0b
    nop

    li    s1, 2
    beq   t5, s1, 6f
    nop

    li    s1, 9
    bne   t4, s1, 7f
    nop
    li    t4, 0
    addiu t5, t5, 1
    j     2f
    nop
6:
    li    s1, 3
    bne   t4, s1, 7f
    nop
    li    t4, 0
    li    t5, 0
    j     2f
    nop
7:
    addiu t4, t4, 1
    j     2f
    nop
2:
    jal   display_time
    nop
    mfc0  k0, $13
    andi  k0, 0x800
    bne   k0, zero, set_hour
    nop
1:
    j     ret
    nop
    
set_minute:            # set minute
    beq   s0, zero, 1f
    nop
    li    k0, Time_2
0:
    addiu k0, k0, -1
    bne		k0, zero, 0b
    nop
    
    li    s1, 9        # set t2
    bne   t2, s1, 4f
    nop
    li    t2, 0
    
    li    s1, 5        # set t3
    bne   t3, s1, 5f
    nop
    li    t3, 0
    j     2f
    nop
4:
    addiu t2, t2, 1
    j     2f
    nop 
5:
    addiu t3, t3, 1
    j     2f
    nop
2:
    jal   display_time
    nop
    mfc0  k0, $13
    andi  k0, 0x1000
    bne   k0, zero, set_minute
    nop
1:
    j     ret
    nop

set_second:            # set second
    beq   s0, zero, 1f
    nop
    li    k0, Time_2
0:
    addiu k0, k0, -1
    bne		k0, zero, 0b
    nop
    
    li    s1, 9        # set t0
    bne   t0, s1, 4f
    nop
    li    t0, 0
    
    li    s1, 5        # set t1
    bne   t1, s1, 5f
    nop
    li    t1, 0
    j     2f
    nop
4:
    addiu t0, t0, 1
    j     2f
    nop 
5:
    addiu t1, t1, 1
    j     2f
    nop
2:
    jal   display_time
    nop
    mfc0  k0, $13
    andi  k0, 0x2000
    bne   k0, zero, set_second
    nop
1:
    j     ret
    nop

ret:
   eret
	 nop