READ = 0
WRITE = 1
STDIN = 0
STDOUT = 1
EXIT = 60

.data
mnozna:  .quad 0x7FFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF

mnoznik: .quad 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA

.bss
.comm wynik,256
.comm shift1,256
.comm shift2,256
.comm P, 256
.text

.global _start
_start:


leaq mnozna, %rbx
leaq mnoznik, %rdx
leaq wynik, %rdi
call mul1024
D3:

movq $EXIT, %rax
movq $0, %rdi
syscall


#1 arg - %r8
.type shl1024, @function
shl1024:
pushq %rbp
movq %rsp, %rbp

pushq %rcx
movq $32, %rcx
salq $1, -0x8(%r8,%rcx,8)	#przesuniecie 1 arg o 1 bit w lewo (najstarszy bit do cf,
pushf				#a na najmlodszy laduje 0)
decq %rcx

shl1024_loop:
popf
rclq $1, -0x8(%r8, %rcx, 8)	#przeusniecie o 1 bit w lewo (najstarszy do cf, na najmlodszy cf)
pushf
decq %rcx
jnz shl1024_loop
popf
pop %rcx

movq %rbp, %rsp
popq %rbp
ret

#1 arg - %r8
.type shr1024, @function
shr1024:
pushq %rbp
movq %rsp, %rbp

pushq %rcx
movq $32, %rcx
sarq $1, 0x0(%r8)	#przesuniecie 1 arg o 1 bit w prawo
pushf
decq %rcx

shr1024_loop:
addq $8, %r8
popf
rcrq $1, 0x0(%r8)	#przeusniecie o 1 bit w prawo
pushf
decq %rcx
jnz shr1024_loop
popf
pop %rcx

movq %rbp, %rsp
popq %rbp
ret

#1 arg - %r8  -> liczba do ktorej dodajemy
#2 arg - %r9  -> liczba dodawana
#3 arg - %r10 -> wynik
.type add1024, @function
add1024:
pushq %rbp
movq %rsp, %rbp

pushq %rcx			#zachowanie poprzedniego stanu rejestru rcx
movq $32, %rcx			#inicjacja licznika
movq -0x8(%r8,%rcx,8), %rax	#wrzucenie 1 arg do %rax
addq -0x8(%r9,%rcx,8), %rax	#odjecie 2 arg od 1 arg i zapisanie w rax
movq %rax, -0x8(%r10, %rcx, 8)	#przenesienie wyniku do zmiennej
pushf				#zachowanie rejestru flagowego
decq %rcx

add1024_loop:
popf				#przywrocenie rejestru falgowego
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

#1 arg - %rbx -> mnozna
#2 arg - %rdx -> mnoznik
#3 arg - %rdi -> wynik
.type mul1024, @function
mul1024:
pushq %rbp
movq %rsp, %rbp

pushq %rdi
xorq %rax, %rax
leaq shift1, %rdi
movq $16, %rcx
rep stosq		#zerowanie najstarszych 1024 bitow shift1

movq %rbx, %rsi
movq $16, %rcx
rep movsq		#zapisanie mnoznej w 1024 najmlodsze bity shift1

leaq shift2, %rdi	#analogicznie jak przy shift2
movq $16, %rcx
rep stosq

movq %rdx, %rsi
movq $16, %rcx
rep movsq

popq %rdi

movq $1024, %rcx
clc 			#czyszczenie flagi przeniesienia
pushf


##### TU TRZEBA NAPRAWIĆ #####

mul1024_loop:
popf                #ściągnięce flagi z poprzedniego przeniesienia - powinien być to rejestr 64b
leaq shift2, %r8    #mnożnik w r8
call shr1024        #przesunięcie mnożnika w prawo o 1 bit
jnc mul1024_next	#jesli po przesunieciu w prawo zostal ustawiony bit cf
#to przechodzimy do dodawania
leaq shift1, %r8
leaq P, %r9
leaq P, %r10
call add1024


mul1024_next:
leaq shift1, %r8
call shl1024
pushf
decq %rcx
jnz mul1024_loop

popf
leaq P, %rsi
movq $32, %rcx
rep movsq 		#zapis wyniku do zmiennej wynik (adres jest juz w %rdi)

movq %rbp, %rsp
pop %rbp
ret


