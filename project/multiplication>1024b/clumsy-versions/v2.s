.data
EXIT = 60
EXIT_SUCCESS = 0
multiplicand:	.quad 0xABC	#mnożna
multiplier:     .quad 0xDEF	#mnożnik

first:    .fill 256         #mnożna
second:   .fill 256         #mnożnik
partial:  .fill 256         #suma cząstkowa
#result:   .fill 512       #wynik działania

.text

.global main
main:

#przepisanie
leaq    multiplicand, %rbx
leaq    multiplier, %rdx
call    iloczyn

check:
movq    $EXIT, %rax
movq    $EXIT_SUCCESS, %rdi
syscall


.type add1024, @function
add1024:
pushq   %rbp
movq    %rsp, %rbp

#sprawdzić sub
subq    %rdi, %rcx          #różnica liczników obu pętli (wew i zew)
cmpq    $0, %rcx
jge     continue

pushq	%rax
movq	%rcx, %rax
movq	$-1, %r15
mulq    %r15
movq	%rax, %rcx
popq	%rax

continue:
movq    $32, %rsi
subq    %rcx, %rsi          # |$32 - różnica liczników|

addq    -0x8(%r10,%rsi,8), %rax
movq    %rax, -0x8(%r10,%rsi,8)
decq    %rsi
adcq    -0x8(%r10,%rsi,8), %rdx
movq    %rdx, -0x8(%r10,%rsi,8)     #CF?
jnc     end

flag_loop:
movq    $0, %rax
decq    %rsi
adcq    -0x8(%r10,%rsi,8), %rax
movq    %rax, -0x8(%r10,%rsi,8)
jc      flag_loop

end:
movq %rbp, %rsp
popq %rbp
ret



.type iloczyn, @function
iloczyn:
pushq   %rbp
movq    %rsp, %rbp

leaq    first, %rdi
movq    %rbx, %rsi
movq    $16, %rcx
rep     movsq

leaq    second, %rdi
movq    %rdx, %rsi
movq    $16, %rcx
rep 	movsq

# mnożenie: rax * rdx = rdx | rax
leaq    first, %r8
leaq    second, %r9
leaq    partial, %r10
movq    $16, %rcx       #licznik pętli wewnętrznej
movq    $16, %rdi       #licznik pętli zewnętrznej

outer_loop:
movq    -0x8(%r9,%rdi,8), %r13      #D

inner_loop:
# D x A
movq    %r13, %rdx
movq    -0x8(%r8,%rcx,8), %rax      #A
mulq    %rdx
# rdx | rax
pushq   %rcx
pushq   %rdi
call    add1024
popq    %rdi
popq    %rcx
decq    %rcx
jnz     inner_loop

decq    %rdi
cmpq    $0, %rdi
jle     outer_loop

movq    %rbp, %rsp
popq    %rbp
ret
