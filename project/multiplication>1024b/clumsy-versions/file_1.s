.data
multiplicand:	.quad 0xABC	#mnożna
multiplier:     .quad 0xDEF	#mnożnik

first:    .fill 512       #mnożna
second:   .fill 512       #mnożnik
partial:  .fill 512       #suma cząstkowa
result:   .fill 512       #wynik działania


.text

.global _start
_start:

leaq    multiplicand, %rbx
leaq 	multiplier, %rdx
leaq    result, %rdi
call    iloczyn


end:    #D3
movq    $EXIT, %rax
movq    $0, %rdi
syscall




#1 arg - %r8
.type shl1024, @function
shl1024:
pushq   %rbp
movq    %rsp, %rbp

pushq   %rcx
movq    $32, %rcx
movq    $0, %r12

shl1024_loop:
movq    -0x8(%r8,%rcx,8), %r11   #od first
movq    %r12, -0x8(%r8,%rcx,8)
decq    %rcx
movq    -0x8(%r8,%rcx,8), %r12
movq    %r11, -0x8(%r8,%rcx,8)
decq    %rcx
jnz     shl1024_loop

popq    %rcx

movq %rbp, %rsp
popq %rbp
ret

#1 arg - %r8
.type shr1024, @function
shr1024:
pushq   %rbp
movq    %rsp, %rbp

pushq   %rcx
movq    $32, %rcx
movq    $0, %r12

shr1024_loop:
movq    0x0(%r8), %r11   #od first
movq    %r12, 0x0(%r8)
decq    %rcx
addq    $8, %r8
movq    0x0(%r8), %r12
movq    %r11, 0x0(%r8)
decq    %rcx
addq    $8, %r8
jnz     shr1024_loop

popq    %rcx

movq %rbp, %rsp
popq %rbp
ret

#1 arg - %r8  -> liczba do ktorej dodajemy - first
#2 arg - %r9  -> liczba dodawana           - partial
#3 arg - %r10 -> wynik                     - partial
.type add1024, @function
add1024:
pushq   %rbp
movq    %rsp, %rbp

#popq    %rax        #low
#popq    %rdx        #high
#popq    %rdi       #licznik zew
#popq    %rcx       #licznik wew
#sprawdzić sub
subq    %rdi, %rcx          #różnica liczników obu pętli (wew i zew)
cmpq    $0, %rcx
jge     continue

mulq    $-1, %rcx

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

######################


movq    $32, %rcx			#inicjacja licznika
movq    -0x8(%r8,%rcx,8), %rax	#wrzucenie 1 arg do %rax
addq -0x8(%r9,%rcx,8), %rax	#dodanie 2 arg od 1 arg i zapisanie w rax
movq %rax, -0x8(%r10, %rcx, 8)	#przenesienie wyniku do zmiennej
pushf				#zachowanie rejestru flagowego
decq %rcx

add1024_loop:
popf				#przywrocenie rejestru flagowego
movq -0x8(%r8,%rcx,8), %rax	#dodawanie kolejnych 8 bajtow w petli z przenesieniem
adcq -0x8(%r9,%rcx,8), %rax
movq %rax, -0x8(%r10, %rcx, 8)
pushf
decq %rcx
jnz add1024_loop		#warunek konczacy petle
popf
pop %rcx			#przywrocenie poprzedniej wartosci rcx

movq %rbp, %rsp
popq %rbp
ret






.type iloczyn, @function
iloczyn:
pushq   %rbp
movq    %rsp, %rbp

# mnożenie: rax * rdx = rdx | rax
leaq    first, %r8
leaq    second, %r9
leaq    partial, %r10
movq    $32, %rcx       #licznik pętli wewnętrznej
movq    $32, %rdi       #licznik pętli zewnętrznej

outer_loop:
movq    -0x8(%r9,%rdi,8), %r13      #D

inner_loop:
# D x A
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


#################
#pop
call    shr1024         #przesunięcie second o 64b w prawo

#mnożenie
movq    first(,%rcx,8), %rdx
movq    second(,%rcx,8), %rax
mulq    %rdx            #wynik mnożenia w rdx|rax

addq    %rdx, partial(,%rcx,8)
call    shl1024         #przesunięcie partial o 64b w lewo
addq    %rax, partial(,%rcx,8)

leaq    first, %r8
leaq    partial, %r10
call    add1024

#push - odłożenie rejestru na stos lub do r15 itp.
decq    %rcx



movq    %rbp, %rsp
popq    %rbp
ret
