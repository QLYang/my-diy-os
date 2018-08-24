%include "include/sconst.inc"

;extern func
extern cstart
extern	exception_handler
extern	spurious_irq
extern	kernel_main
extern  disp_str
extern  delay
extern	clock_handler

;extern var
extern gdt_ptr
extern idt_ptr
extern	p_proc_ready
extern	tss
extern	kernel_reenter
extern irq_table
extern	sys_call_table

;exception
global	divide_error
global	single_step_exception
global	nmi
global	breakpoint_exception
global	overflow
global	bounds_check
global	inval_opcode
global	copr_not_available
global	double_fault
global	copr_seg_overrun
global	inval_tss
global	segment_not_present
global	stack_exception
global	general_protection
global	page_fault
global	copr_error

global  hwint00
global  hwint01
global  hwint02
global  hwint03
global  hwint04
global  hwint05
global  hwint06
global  hwint07
global  hwint08
global  hwint09
global  hwint10
global  hwint11
global  hwint12
global  hwint13
global  hwint14
global  hwint15

;global func
global restart
global _start
global sys_call

[section .bss]
StackSpace		resb	2 * 1024
StackTop:

[section .data]
clock_init_msg  db "^",0

[section .text]

_start:	; 跳到这里来的时候，假设 gs 指向显存
	mov esp,StackTop	;mov stackPointer to .bss

	sgdt	[gdt_ptr]
	call	cstart
	lgdt	[gdt_ptr]
	lidt	[idt_ptr]


	jmp	SELECTOR_KERNEL_CS:csinit

csinit:
	;sti
	;ud2			;error
	;jmp 0x40:0 ;Page Fault
	;push	0
	;popfd		;Change EFlag

	xor	eax, eax
	mov	ax, SELECTOR_TSS
	ltr	ax

	jmp kernel_main

;======================================
; 中断和异常 -- 异常
;======================================
divide_error:
	push	0xFFFFFFFF	; no err code
	push	0		; vector_no	= 0
	jmp	exception
single_step_exception:
	push	0xFFFFFFFF	; no err code
	push	1		; vector_no	= 1
	jmp	exception
nmi:
	push	0xFFFFFFFF	; no err code
	push	2		; vector_no	= 2
	jmp	exception
breakpoint_exception:
	push	0xFFFFFFFF	; no err code
	push	3		; vector_no	= 3
	jmp	exception
overflow:
	push	0xFFFFFFFF	; no err code
	push	4		; vector_no	= 4
	jmp	exception
bounds_check:
	push	0xFFFFFFFF	; no err code
	push	5		; vector_no	= 5
	jmp	exception
inval_opcode:
	push	0xFFFFFFFF	; no err code
	push	6		; vector_no	= 6
	jmp	exception
copr_not_available:
	push	0xFFFFFFFF	; no err code
	push	7		; vector_no	= 7
	jmp	exception
double_fault:
	push	8		; vector_no	= 8
	jmp	exception
copr_seg_overrun:
	push	0xFFFFFFFF	; no err code
	push	9		; vector_no	= 9
	jmp	exception
inval_tss:
	push	10		; vector_no	= A
	jmp	exception
segment_not_present:
	push	11		; vector_no	= B
	jmp	exception
stack_exception:
	push	12		; vector_no	= C
	jmp	exception
general_protection:
	push	13		; vector_no	= D
	jmp	exception
page_fault:
	push	14		; vector_no	= E
	jmp	exception
copr_error:
	push	0xFFFFFFFF	; no err code
	push	16		; vector_no	= 10h
	jmp	exception

exception:
	call	exception_handler
	add	esp, 4*2	; 让栈顶指向 EIP，堆栈中从顶向下依次是：EIP、CS、EFLAGS
	hlt
;======================================
; 中断和异常 -- 硬件中断
;======================================
%macro	hwint_master	1
	call	save

	in	al, INT_M_CTLMASK			;
	or	al, (1 << %1)				;屏蔽当前中断
	out	INT_M_CTLMASK, al			;

	mov	al, EOI						;置EOI位
	out	INT_M_CTL, al				;

	sti								; CPU在响应中断的过程中会自动关中断，这句之后就允许响应新的中断
	push	%1						;
	call	[irq_table + 4 * %1]	; 中断处理程序
	pop	ecx							;
	cli

	in	al, INT_M_CTLMASK			;
	and	al, ~(1 << %1)				;恢复接受当前中断
	out	INT_M_CTLMASK, al			;
	ret
%endmacro
; -------------------------------------

ALIGN   16
hwint00:                ; Interrupt routine for irq 0 (the clock).
		hwint_master    0
ALIGN   16
hwint01:                ; Interrupt routine for irq 1 (keyboard)
        hwint_master    1

ALIGN   16
hwint02:                ; Interrupt routine for irq 2 (cascade!)
        hwint_master    2

ALIGN   16
hwint03:                ; Interrupt routine for irq 3 (second serial)
        hwint_master    3

ALIGN   16
hwint04:                ; Interrupt routine for irq 4 (first serial)
        hwint_master    4

ALIGN   16
hwint05:                ; Interrupt routine for irq 5 (XT winchester)
        hwint_master    5

ALIGN   16
hwint06:                ; Interrupt routine for irq 6 (floppy)
        hwint_master    6

ALIGN   16
hwint07:                ; Interrupt routine for irq 7 (printer)
        hwint_master    7

; -------------------------------------
%macro  hwint_slave     1
        push    %1
        call    spurious_irq
        add     esp, 4
        hlt
%endmacro
; -------------------------------------

ALIGN   16
hwint08:                ; Interrupt routine for irq 8 (realtime clock).
        hwint_slave     8

ALIGN   16
hwint09:                ; Interrupt routine for irq 9 (irq 2 redirected)
        hwint_slave     9

ALIGN   16
hwint10:                ; Interrupt routine for irq 10
        hwint_slave     10

ALIGN   16
hwint11:                ; Interrupt routine for irq 11
        hwint_slave     11

ALIGN   16
hwint12:                ; Interrupt routine for irq 12
        hwint_slave     12

ALIGN   16
hwint13:                ; Interrupt routine for irq 13 (FPU exception)
        hwint_slave     13

ALIGN   16
hwint14:                ; Interrupt routine for irq 14 (AT winchester)
        hwint_slave     14

ALIGN   16
hwint15:                ; Interrupt routine for irq 15
        hwint_slave     15
; =====================================
;             save
; =====================================
save:
        pushad          ; `.
        push    ds      ;  |
        push    es      ;  | 保存原寄存器值
        push    fs      ;  |
        push    gs      ; /
        mov     dx, ss
        mov     ds, dx
        mov     es, dx

        mov     esi, esp                    ;eax = 进程表起始地址

        inc     dword [kernel_reenter]           ;k_reenter++;
        cmp     dword [kernel_reenter], 0        ;if(k_reenter ==0)
        jne     .1                          ;{
        mov     esp, StackTop               ;  mov esp, StackTop <--切换到内核栈
        push    restart                     ;  push restart
        jmp     [esi + RETADR];  return;
.1:                                         ;} else {
        push    restart_reenter             ;  push restart_reenter
        jmp     [esi + RETADR ]				;  return;
                                            ;}
; =====================================
;         restart
; =====================================
restart:
	mov	esp, [p_proc_ready]
	lldt	[esp + P_LDT_SEL]
	lea	eax, [esp + P_STACKTOP]
	mov	dword [tss + TSS3_S_SP0], eax
restart_reenter:
	dec	dword [kernel_reenter]
	pop	gs
	pop	fs
	pop	es
	pop	ds
	popad
	add	esp, 4
	iretd

;======================================
;			sys_call
;======================================
sys_call:
    call    save
	push	dword [p_proc_ready]
    sti

	push	ecx
	push	ebx
    call    [sys_call_table + eax * 4]
	add	esp, 4 * 3

    mov     [esi + EAXREG ], eax
    cli
    ret