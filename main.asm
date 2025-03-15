%define SYS_EXIT 60
%define SYS_READ 0
%define SYS_WRITE 1
%define STDIN 0
%define STDOUT 1
%define STDERR 2
global _start
section .data
	start_msg db "Press enter x:",0
	error_msg db "Unexpected error",0
	result dw 0
	op dq 0
	op2 dq 2.0
	op4 dq 4.0
	op8 dq 8.0
	op1000 dq 1000.0
	opb1 dq -10.0
	opb2 dq -6.0
	opb3 dq -4.0
	opb4 dq 2.0
	opb5 dq 4.0
	op0 dq 0.0
	opm05 dq -0.5
	op3 dq 3.0
section .text


exit: 
	mov	rax, SYS_EXIT
	syscall
	
	
string_length:
	sub 	rsp, 8
	mov 	rcx, rdi
.string_cnt_loop:
	mov 	al, [rcx]
	test 	al, al
	jz 	.string_cnt_ret
	inc 	rcx
	jmp 	.string_cnt_loop
.string_cnt_ret:
	mov 	rax, rcx
	sub 	rax, rdi
	add 	rsp, 8
	ret
	
	
print_char:
	push 	rdi
	mov 	rdi, rsp
	call 	print_string
	add 	rsp, 8
	ret


print_newline:
	mov 	rdi, `\n`
 	jmp 	print_char 


print_string:
	push 	rdi
	call 	string_length
	mov 	rdx, rax
	pop 	rsi
	mov 	rdi, STDOUT
	mov 	rax, SYS_WRITE
	syscall
	ret
	
	
parse_uint:
	xor 	r8, r8
	xor 	rax, rax
	xor 	rcx, rcx
	mov 	rsi, 10
.parse_loop:
	mov 	cl, [rdi+r8]
	cmp	rcx, '0'
	jl 	.parse_end
	cmp 	rcx, '9'
	jg 	.parse_end
	inc 	r8
	mul 	rsi
	sub 	rcx, '0'
	add 	rax, rcx
	jmp 	.parse_loop
.parse_end:
	mov 	rdx, r8
	ret


parse_int:
	sub 	rsp, 8
	xor 	rcx, rcx
	mov 	cl, [rdi]
	cmp	rcx, `-`
	je 	.parse_neg
	call	parse_uint
	add 	rsp, 8
	ret
.parse_neg:
	inc 	rdi
	call	parse_uint
	neg 	rax
	inc 	rdx
	add 	rsp, 8
	ret 
	
	
read_char:
	sub 	rsp, 8
	mov 	rax, SYS_READ
	mov 	rdi, STDIN 
	mov 	rsi, rsp
	add	rsi, 7
	mov 	rdx, 1
    	syscall
	test 	rax, rax
	jz	.read_char_end
	mov 	rsi, rsp
	add	rsi, 7
	xor 	rax, rax
	mov 	al, [rsi]
.read_char_end:
	add 	rsp, 8
	ret 	
	
	
read_word:
	push 	rbx
	sub	rsp, 8
	xor 	rbx, rbx
	xor 	rdx, rdx
.read_loop:
	push 	rdi
	push 	rsi
	push 	rdx	
	call	read_char
	pop	rdx
	pop	rsi
	pop	rdi
	cmp 	rax, `\n`
	je 	.switcher
	cmp 	rax, `\t`
	je  	.switcher
	cmp 	rax, ` `
	je 	.switcher
	test	rax, rax
	je 	.read_ending
	mov 	rbx, 1
	add	rdx, 2
	cmp	rdx, rsi
	jg	.read_badending
	sub 	rdx, 2
	mov 	[rdi+rdx], rax
	inc 	rdx
	jmp	.read_loop
.switcher:
	cmp 	rbx, 1
	je 	.read_ending
	jmp 	.read_loop
.read_ending:	
	xor 	rbx, rbx
	mov 	[rdi+rdx], bl
	mov 	rax, rdi
	add		rsp, 8
	pop		rbx
	ret
.read_badending:
	add		rsp, 8
	pop 	rbx
	xor 	rax, rax
	ret


print_uint:
	enter 	32, 0
	mov 	rcx, rbp
	dec 	rcx
	mov 	byte [rcx], 0
	mov 	rax, rdi
	mov 	r8, 10
.div_loop:
	xor 	rdx, rdx
	div 	r8
	dec 	rcx
	add 	dl, `0`
	mov 	[rcx],dl
	test	rax, rax
	jne 	.div_loop
	mov 	rdi, rcx
	call 	print_string
	leave
	ret


print_int:
	test 	rdi, rdi
	jns 	print_uint
	push 	rdi
	mov 	rdi, `-`
	call 	print_char
	pop 	rdi
	neg 	rdi
	jmp 	print_uint
	
	
	
	
	
_start:
	mov rdi,start_msg
	call print_string
	call print_newline
	sub  rsp, 32
	mov rdi, rsp
	mov rsi, 32
	call read_word
	test rax,rax 
	je .err	
	mov rdi,rax
	call parse_int
	add	rsp, 32
	finit
	cvtsi2sd xmm0, rax
	movsd [op], xmm0 
	xor rax,rax
	;mov qword [op1000], 1000
	fld qword [op]
	fld qword [op1000]
	fdiv
	fld qword [opb1]
	fcomp	          
    fstsw ax       
    sahf            
    ja .ret0  
	fld qword [opb2]
	fcomp	          
    fstsw ax       
    sahf            
    ja .ret1 
	fld qword [opb3]
	fcomp	          
    fstsw ax       
    sahf            
    ja .ret2 
	fld qword [opb4]
	fcomp	          
    fstsw ax       
    sahf            
    ja .ret3 
	fld qword [opb5]
	fcomp	          
    fstsw ax       
    sahf            
    ja .ret4 
	jmp .ret0
.ret1:
	fld qword [op8]
	fadd
	fstp qword [op]
	fld qword [op4]
	fld qword [op]
	fld qword [op]
	fmul
	fsub
	fsqrt
	fchs
	fld qword [op2]
	fadd
	jmp .ret
.ret2:
	fld qword [op2]
	jmp .ret
.ret3:
	fld qword [opm05]
	fmul
	jmp .ret
.ret4:
	fld qword [op3]
	fsub
	jmp .ret
.ret0:
	fld qword [op0]
.ret:
	fld qword [op1000]
	fmul
	fstp qword [op]
	movsd xmm0, [op] 
	cvtsd2si rdi, xmm0
	call print_int
	call print_newline
	mov rdi, 0
	call exit
	ret
.err:
	mov rdi,error_msg
	call print_string
	call print_newline
	mov rdi, 2
	call exit
	ret
