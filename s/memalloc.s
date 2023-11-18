.section .data
.globl	init_heap
.globl	top_heap

init_heap:
	.zero	8

top_heap:
	.zero	8

.equ BRK_SERVICE, 12

.section .text
.globl 	setup_brk
.globl 	dismiss_brk
.globl	memory_alloc
.globl	memory_free

# call brk service and store the current value of brk into
# memory location specified by (init_heap + %rip) and (top_heap + %rip)
setup_brk:
	pushq	%rbp
	movq	%rsp, %rbp
  movq $BRK_SERVICE, %rax			# set service to brk
  syscall											# call os
	movq	%rax, init_heap(%rip)	# (init_heap + %rip) = brk(0)
	movq	%rax, top_heap(%rip) 	# (top_heap + %rip) = brk(0)
	popq	%rbp
	ret

# restores the brk to its original value
dismiss_brk:
	pushq	%rbp
	movq	%rsp, %rbp
	movq	init_heap(%rip), %rdi # rdi = (init_heap + %rip)
	movq $BRK_SERVICE, %rax			# set service to brk
  syscall											# call os
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

# Allocates n bytes of memory in heap and returns the memory address
# void *memory_alloc(long int bytes);
memory_alloc:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$40, %rsp								# making 40 bytes space in the stack
	movq	%rdi, -40(%rbp)					# (%rbp - 40) = bytes
	call	find_free_block					# find_free_block(bytes)
	movq	%rax, -16(%rbp)					# (%rbp - 16) = %rax
	cmpq	$0, -16(%rbp)						# (%rbp - 16) == 0 -> did not find a free block
	je	no_free_block_found				# creates a new block
	nop														# free block found
	movq	-40(%rbp), %rsi					# %rsi = (%rbp - 40) -> orginal value of rdi(bytes)
	movq	-16(%rbp), %rdi					# %rdi = (%rbp - 16) -> mem addres of free block
	call	try_to_alloc_new_block	# try_to_alloc_new_block(free_block, bytes)
	movq	-16(%rbp), %rax					# %rax = (%rbp - 16)
	addq	$16, %rax								# %rax += 16 -> pointing to real data address
	jmp	mem_alloc_end
no_free_block_found:
	movq	-40(%rbp), %rdi					# %rdi = (%rbp - 40) -> orginal value of rdi(bytes)
	call	create_new_block				# create_new_block(bytes)
	addq	$16, %rax
mem_alloc_end:
	addq $40, %rsp								# freeing up stack 40 bytes space
	movq %rbp, %rsp
	popq %rbp
	ret

memory_free:
	pushq	%rbp
	movq	%rsp, %rbp
	movq	%rdi, %rax # %rax = %rdi
	subq	$16, %rax	 # %rax -= 16 -> pointing to the state of the block
	movq	$0, (%rax) # (%rax) = 0 -> setting block to free
	movq	$0, %rax	 # %rax = 0
	popq	%rbp
	ret