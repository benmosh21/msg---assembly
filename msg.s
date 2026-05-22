.intel_syntax noprefix

# CONSTANTS
.equ SYS_READ, 0
.equ SYS_WRITE, 1
.equ SYS_EXIT, 60
.equ STDIN, 0
.equ STDOUT, 1
.equ BUFFER_SIZE, 100

.section .data
exit_msg:	.ascii "exit\n"
upper_msg:	.ascii "UPPER\n"
lower_msg:	.ascii "lower\n"
prompt:		.ascii "> "

# Fixed variable size: 1 byte is correct for states 0, 1, or 2
type_val:	.byte 0

.section .bss
msg: .skip BUFFER_SIZE

.section .text
.global _start

_start:

loop:
	# PRINT PROMPT
	mov rdi, OFFSET prompt
	mov rsi, 2
	call puts

	# READ INPUT
	mov rax, SYS_READ
	mov rdi, STDIN
	mov rsi, OFFSET msg
	mov rdx, BUFFER_SIZE
	syscall

	# CHECK FOR EOF OR ERROR
	cmp rax, 0
	jle do_exit

	# CHECK LENGTH FOR "exit\n" (5 bytes)
	cmp rax, 5
	jne check_len_6

	mov rcx, 5
	mov rsi, OFFSET msg
	mov rdi, OFFSET exit_msg
	repe cmpsb
	je do_exit

check_len_6:
	# CHECK LENGTH FOR "UPPER\n" OR "lower\n" (6 bytes)
	cmp rax, 6
	jne process_text

	# Check UPPER
	mov rcx, 6
	mov rsi, OFFSET msg
	mov rdi, OFFSET upper_msg
	repe cmpsb
	je make_upper

	# Check lower (MUST reset rcx, rsi, and rdi!)
	mov rcx, 6
	mov rsi, OFFSET msg
	mov rdi, OFFSET lower_msg
	repe cmpsb
	je make_lower

	# If length was 6 but it wasn't a command, fall through to process text

process_text:
	# Check our saved state directly in memory
	# We do NOT use 'al' because it corrupts 'rax' (which holds our string length!)
	cmp byte ptr [type_val], 1
	je apply_lower
	cmp byte ptr [type_val], 2
	je apply_upper

	# If type_val is 0, skip modification and print exactly as typed
	jmp print_input

# COMMAND HANDLERS
make_upper:
	mov byte ptr [type_val], 2
	jmp apply_upper

make_lower:
	mov byte ptr [type_val], 1
	jmp apply_lower

# TEXT MODIFICATION LOOPS
apply_upper:
	mov rcx, rax		# Set loop counter to bytes read
	mov rbx, OFFSET msg	# Set pointer to the start of the buffer
upper_loop:
	cmp byte ptr [rbx], 'a'	# Ignore if less than 'a'
	jl skip_u
	cmp byte ptr [rbx], 'z'	# Ignore if greater than 'z'
	jg skip_u
	and byte ptr [rbx], 0xDF	# Clear 5th bit to make uppercase
skip_u:
	inc rbx
	loop upper_loop
	jmp print_input

apply_lower:
	mov rcx, rax		# Set loop counter to bytes read
	mov rbx, OFFSET msg	# Set pointer to the start of the buffer
lower_loop:
	cmp byte ptr [rbx], 'A'	# Ignore if less than 'A'
	jl skip_l
	cmp byte ptr [rbx], 'Z'	# Ignore if greater than 'Z'
	jg skip_l
	or byte ptr [rbx], 0x20	# Set 5th bit to make lowercase
skip_l:
	inc rbx
	loop lower_loop
	jmp print_input

# OUTPUT
print_input:
	mov rdi, OFFSET msg
	mov rsi, rax		# rax still holds the bytes read
	call puts
	jmp loop

do_exit:
	mov rdi, OFFSET msg
	mov rsi, rax
	call puts
	mov rax, SYS_EXIT
	mov rdi, 0
	syscall

# FUNCTIONS
puts:
	mov rdx, rsi		# length
	mov rsi, rdi		# buffer
	mov rdi, STDOUT		# file descriptor
	mov rax, SYS_WRITE	# syscall number
	syscall
	ret
