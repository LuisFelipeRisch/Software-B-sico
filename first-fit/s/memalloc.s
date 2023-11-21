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

# Try to find a free block in the current state of the heap
# Returns null if not find. Otherwise, returns the initial position of the free block
# void *find_free_block(unsigned long int bytes)
find_free_block:
	pushq	%rbp
	movq	%rsp, %rbp
	subq $40, %rsp							# making 40 bytes space in the stack
	movq	%rdi, -40(%rbp)				# (%rbp - 40) = %rdi
	movq	$0, -32(%rbp)					# (%rbp - 32) = 0	-> free_block
	movq	init_heap(%rip), %rax
	movq	%rax, -24(%rbp)				# current_block
	jmp	while_conditional
inside_while:
	movq	-24(%rbp), %rax							 # %rax = current_block
	movq	%rax, -16(%rbp)							 # (%rbp - 16) = %rax
	addq	$8, %rax										 # %rax += 8
	movq	%rax, -8(%rbp)							 # (%rbp - 8) = %rax -> stores de bytes_qnt of the block
	movq	-16(%rbp), %rax							 # %rax = (%rbp - 16)
	movq	(%rax), %rax								 # setting the value indicated by the memory location of %rax in %rax
	testq	%rax, %rax									 # %rax AND %rax
	jne	block_busy_or_not_enough_space # jumps to block_busy_or_not_enough_space if block is busy
	movq	-8(%rbp), %rax							 # %rax = (%rbp - 8)
	movq	(%rax), %rax								 # setting the value indicated by the memory location of %rax in %rax
	cmpq	%rax, -40(%rbp)							 # %rax - bytes
	ja	block_busy_or_not_enough_space # jumps to block_busy_or_not_enough_space if free_block dont have enough space
	movq	-16(%rbp), %rax							 # %rax = (%rbp - 16)
	movq	$1, (%rax)									 # set the free block to busy
	movq	-24(%rbp), %rax							 # %rax = current_block
	movq	%rax, -32(%rbp)							 # (%rbp - 32) = %rax -> free_block
block_busy_or_not_enough_space:
	movq	-8(%rbp), %rax							 # %rax = current_block.bytes_qnt
	movq	(%rax), %rax								 # setting the value indicated by the memory location of %rax in %rax
	addq	$16, %rax										 # %rax += 16 -> 16 bytes of control information
 	addq	%rax, -24(%rbp)							 # current_block += %rax
while_conditional:
	movq	top_heap(%rip), %rax 	# %rax = top_heap
	cmpq	%rax, -24(%rbp)				# current_block - top_heap
	jnb	end_while								# jumps to end_while if memory position of top_heap is not below current_block
	cmpq	$0, -32(%rbp)					# 0 - free_block
	je	inside_while						# jump into the loop if haven't found a free block yet
end_while:
	movq	-32(%rbp), %rax
	addq $40, %rsp				# freeing up stack 40 bytes space
	popq	%rbp
	ret

# Creates a new block. Returns the initial position of the created block
# void *create_new_block(unsigned long int bytes)
create_new_block:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$32, %rsp							# making 32 bytes space in the stack
	movq	%rdi, -32(%rbp)				# (%rbp  - 32) = %rdi -> bytes
	movq	-32(%rbp), %rax				# %rax = (%rbp  - 32)
	addq	$16, %rax							# %rax += 16 -> displacement
	movq	%rax, -24(%rbp)				# (%rbp  - 24) = %rax
	movq	top_heap(%rip), %rax	# %rax = top_heap
	movq	%rax, -16(%rbp)				# (%rbp  - 16) = top_heap
	addq	$8, %rax							# %rax += 8	-> block.bytes_qnt
	movq	%rax, -8(%rbp)				# (%rbp  - 8) = block.bytes_qnt
	movq	top_heap(%rip), %rax	# %rax = top_heap
	movq	$1, (%rax)						# setting created block to busy
	movq	-8(%rbp), %rax				# %rax = block.bytes_qnt
	movq	-32(%rbp), %rdx				# %rdx = bytes
	movq	%rdx, (%rax)					# setting the value indicated by the memory location of %rax with %rdx
	movq	top_heap(%rip), %rdx	# %rdx = top_heap
	movq	-24(%rbp), %rax				# %rax = displacement
	addq	%rdx, %rax						# %rax += %rdx
	movq	%rax, top_heap(%rip)	# top_heap = %rax
	movq	-16(%rbp), %rax				# getting the initial position of the created block
	addq $32, %rsp							# freeing up stack 32 bytes space
	popq	%rbp
	ret

# If the free block have enough data space to create new block, it will create.
# void try_to_alloc_new_block(void *block, unsigned long int bytes)
try_to_alloc_new_block:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$48, %rsp									# making 48 bytes space in the stack
	movq	%rdi, -40(%rbp)						# (%rbp - 40) = %rdi
	movq	%rsi, -48(%rbp) 					# (%rbp - 48) = %rsi
	movq	-40(%rbp), %rax						# %rax = (%rbp - 40)
	addq	$8, %rax									# %rax += 8
	movq	%rax, -32(%rbp) 					# (%rbp - 32) = %rax
	movq	(%rax), %rax							# setting the value indicated by the memory location of %rax in %rax
	subq	-48(%rbp), %rax 					# %rax -= (%rbp - 48)
	cmpq	$16, %rax									# 16 - %rax
	jbe	try_to_alloc_new_block_end	# Jump to L11 if %rax is below or equal to 16
	movq	-40(%rbp), %rax						# %rax = (%rbp - 40)
	addq	$16, %rax									# %rax += 16
	movq	%rax, -24(%rbp)						# (%rbp - 24) = %rax
	movq	-24(%rbp), %rdx						# %rdx = (%rbp - 24)
	movq	-48(%rbp), %rax						# %rax = (%rbp - 48)
	addq	%rdx, %rax								# %rax += %rdx
	movq	%rax, -16(%rbp)						# (%rbp - 16) = %rax
	movq	-48(%rbp), %rax						# %rax = (%rbp - 48)
	leaq	8(%rax), %rdx							# %rdx = (%rax + 8)
	movq	-24(%rbp), %rax						# %rax = (%rbp - 24)
	addq	%rdx, %rax								# %rax += %rdx
	movq	%rax, -8(%rbp)						# (%rbp - 8) = %rax
	movq	-16(%rbp), %rax						# (%rbp - 16) = %rax
	movq	$0, (%rax)								# %rax = 0 -> setting block to free
	movq	-32(%rbp), %rax						# %rax = (%rbp - 32)
	movq	(%rax), %rax							# setting the value indicated by the memory location of %rax in %rax
	subq	-48(%rbp), %rax						# %rax -= (%rbp - 48)
	leaq	-16(%rax), %rdx						# %rdx = (%rax - 16)
	movq	-8(%rbp), %rax						# %rax = (%rbp - 8)
	movq	%rdx, (%rax)							# setting the value indicated by the memory location of %rax with %rdx
	movq	-32(%rbp), %rax						# %rax = (%rbp - 32)
	movq	-48(%rbp), %rdx						# %rdx = (%rbp - 48)
	movq	%rdx, (%rax)							# setting the value indicated by the memory location of %rax with %rdx
try_to_alloc_new_block_end:
	addq	$48, %rsp									# freeing up stack 32 bytes space
	popq	%rbp
	ret

# Allocates n bytes of memory in heap and returns the memory address
# void *memory_alloc(long int bytes);
memory_alloc:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$16, %rsp								# making 16 bytes space in the stack
	movq	%rdi, -16(%rbp)					# (%rbp - 16) = bytes
	call	find_free_block					# find_free_block(bytes)
	movq	%rax, -8(%rbp)					# (%rbp - 8) = %rax
	cmpq	$0, -8(%rbp)						# (%rbp - 8) == 0 -> did not find a free block
	je	no_free_block_found				# creates a new block
	nop														# free block found
	movq	-16(%rbp), %rsi					# %rsi = (%rbp - 16) -> orginal value of rdi(bytes)
	movq	-8(%rbp), %rdi					# %rdi = (%rbp - 8) -> mem addres of free block
	call	try_to_alloc_new_block	# try_to_alloc_new_block(free_block, bytes)
	movq	-8(%rbp), %rax					# %rax = (%rbp - 8)
	addq	$16, %rax								# %rax += 16 -> pointing to real data address
	jmp	mem_alloc_end
no_free_block_found:
	movq	-16(%rbp), %rdi					# %rdi = (%rbp - 16) -> orginal value of rdi(bytes)
	call	create_new_block				# create_new_block(bytes)
	addq	$16, %rax
mem_alloc_end:
	addq $16, %rsp								# freeing up stack 16 bytes space
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