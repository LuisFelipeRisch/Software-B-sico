.section .data
.globl	init_heap
.globl	top_heap

init_heap:
	.zero	8

top_heap:
	.zero	8

.equ BRK_SERVICE, 12

.section .text
.globl setup_brk
.globl dismiss_brk
.globl	memory_alloc
.globl	memory_free

setup_brk:
	pushq	%rbp
	movq	%rsp, %rbp
  movq $BRK_SERVICE, %rax
  syscall
	movq	%rax, init_heap(%rip)
	movq	%rax, top_heap(%rip)
	popq	%rbp
	ret

dismiss_brk:
	pushq	%rbp
	movq	%rsp, %rbp
	movq	init_heap(%rip), %rax
	movq	%rax, %rdi
	movq $BRK_SERVICE, %rax
  syscall
	popq	%rbp
	ret

find_free_block:
	pushq	%rbp
	movq	%rsp, %rbp
	movq	%rdi, -40(%rbp)
	movq	$0, -32(%rbp)
	movq	init_heap(%rip), %rax
	movq	%rax, -24(%rbp)
	jmp	.L4
.L7:
	movq	-24(%rbp), %rax
	movq	%rax, -16(%rbp)
	movq	-24(%rbp), %rax
	addq	$8, %rax
	movq	%rax, -8(%rbp)
	movq	-16(%rbp), %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L5
	movq	-8(%rbp), %rax
	movq	(%rax), %rax
	cmpq	%rax, -40(%rbp)
	ja	.L5
	movq	-16(%rbp), %rax
	movq	$1, (%rax)
	movq	-24(%rbp), %rax
	movq	%rax, -32(%rbp)
.L5:
	movq	-8(%rbp), %rax
	movq	(%rax), %rax
	addq	$16, %rax
	addq	%rax, -24(%rbp)
.L4:
	movq	top_heap(%rip), %rax
	cmpq	%rax, -24(%rbp)
	jnb	.L6
	cmpq	$0, -32(%rbp)
	je	.L7
.L6:
	movq	-32(%rbp), %rax
	popq	%rbp
	ret

create_new_block:
	pushq	%rbp
	movq	%rsp, %rbp
	movq	%rdi, -40(%rbp)
	movq	-40(%rbp), %rax
	addq	$16, %rax
	movq	%rax, -32(%rbp)
	movq	top_heap(%rip), %rax
	movq	%rax, -24(%rbp)
	movq	top_heap(%rip), %rax
	addq	$8, %rax
	movq	%rax, -16(%rbp)
	movq	top_heap(%rip), %rax
	movq	%rax, -8(%rbp)
	movq	-24(%rbp), %rax
	movq	$1, (%rax)
	movq	-16(%rbp), %rax
	movq	-40(%rbp), %rdx
	movq	%rdx, (%rax)
	movq	top_heap(%rip), %rdx
	movq	-32(%rbp), %rax
	addq	%rdx, %rax
	movq	%rax, top_heap(%rip)
	movq	-8(%rbp), %rax
	popq	%rbp
	ret

try_to_alloc_new_block:
	pushq	%rbp
	movq	%rsp, %rbp
	movq	%rdi, -40(%rbp)
	movq	%rsi, -48(%rbp)
	movq	-40(%rbp), %rax
	addq	$8, %rax
	movq	%rax, -32(%rbp)
	movq	-32(%rbp), %rax
	movq	(%rax), %rax
	subq	-48(%rbp), %rax
	cmpq	$16, %rax
	jbe	.L14
	movq	-40(%rbp), %rax
	addq	$16, %rax
	movq	%rax, -24(%rbp)
	movq	-24(%rbp), %rdx
	movq	-48(%rbp), %rax
	addq	%rdx, %rax
	movq	%rax, -16(%rbp)
	movq	-48(%rbp), %rax
	leaq	8(%rax), %rdx
	movq	-24(%rbp), %rax
	addq	%rdx, %rax
	movq	%rax, -8(%rbp)
	movq	-16(%rbp), %rax
	movq	$0, (%rax)
	movq	-32(%rbp), %rax
	movq	(%rax), %rax
	subq	-48(%rbp), %rax
	leaq	-16(%rax), %rdx
	movq	-8(%rbp), %rax
	movq	%rdx, (%rax)
	movq	-32(%rbp), %rax
	movq	-48(%rbp), %rdx
	movq	%rdx, (%rax)
	jmp	.L11
.L14:
	nop
.L11:
	popq	%rbp
	ret

memory_alloc:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$40, %rsp
	movq	%rdi, -40(%rbp)
	movq	-40(%rbp), %rax
	movq	%rax, %rdi
	call	find_free_block
	movq	%rax, -16(%rbp)
	cmpq	$0, -16(%rbp)
	je	.L16
	movq	-40(%rbp), %rdx
	movq	-16(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	try_to_alloc_new_block
	movq	-16(%rbp), %rax
	addq	$16, %rax
	movq	%rax, -24(%rbp)
	jmp	.L17
.L16:
	movq	-40(%rbp), %rax
	movq	%rax, %rdi
	call	create_new_block
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	addq	$16, %rax
	movq	%rax, -24(%rbp)
.L17:
	movq	-24(%rbp), %rax
	movq %rbp, %rsp
	popq %rbp
	ret

memory_free:
	pushq	%rbp
	movq	%rsp, %rbp
	movq	%rdi, -24(%rbp)
	movq	-24(%rbp), %rax
	subq	$16, %rax
	movq	%rax, -8(%rbp)
	movq	-8(%rbp), %rax
	movq	$0, (%rax)
	movl	$0, %eax
	popq	%rbp
	ret