READ = 0
WRITE = 1
STDIN = 0
STDOUT = 1
EXIT = 60
.data

# Oznaczenia:
# D - dzielna (dividend)
# X - dzielnik (divisor)

D: .quad 0x7FFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF  #dzielna
X: .quad 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x4000000000000000, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0    #dzielnik

test: .quad 0

.bss

# Q - iloraz (quotient)
# R - reszta (reminder)
# P - zmienna pomocnicza
# D_shift - 2. zmienna pomocnicza dla dzielnika

.comm Q, 128		 		# czesc calkowita z dzielenia = wynik
.comm R, 128
.comm P, 128
.comm D_shift, 128
.text

.globl main
main:

leaq 	D, %rbx
leaq 	X, %rdx
leaq 	Q, %rdi
leaq 	R, %rsi
call 	div1024

check:
movq 	$EXIT, %rax
movq 	$0, %rdi
syscall

# 1 arg - %r8  -> liczba od ktorej odejmujemy
# 2 arg - %r9  -> liczba odejmowana
# 3 arg - %r10 -> wynik
.type sub1024, @function
sub1024:
pushq 	%rbp
movq 	%rsp, %rbp

pushq 	%rcx											# zachowanie poprzedniego stanu rejestru rcx
movq 	$16, %rcx									  # inicjacja licznika
movq 	-0x8(%r8,%rcx,8), %rax			# wrzucenie 1 arg do %rax
subq 	-0x8(%r9,%rcx,8), %rax			# odjecie 2 arg od 1 arg i zapisanie w rax
movq 	%rax, -0x8(%r10, %rcx, 8) 	# przenesienie wyniku do zmiennej
pushf					                    # zachowanie rejestru flagowego
decq 	%rcx

sub1024_loop:
popf					                    # przywrocenie rejestru falgowego
movq 	-0x8(%r8,%rcx,8), %rax	    # odejmowanie kolejnych 8 bajtow w petli z przenesieniem
sbbq 	-0x8(%r9,%rcx,8), %rax
movq 	%rax, -0x8(%r10, %rcx, 8)
pushf
decq 	%rcx
jnz 	sub1024_loop		            # warunek konczacy petle
popf
popq	%rcx			                  # przywrocenie poprzedniej wartosci rcx

movq	%rbp, %rsp
popq 	%rbp
ret


# 1 arg - %r8
.type shl1024, @function
shl1024:
pushq %rbp
movq 	%rsp, %rbp

pushq %rcx
movq 	$16, %rcx
salq 	$1, -0x8(%r8,%rcx,8)	     # przesuniecie 1 arg o 1 bit w lewo (najstarszy bit do cf,
pushf						                 # a na najmlodszy laduje 0)
decq 	%rcx

shl1024_loop:
popf
rclq 	$1, -0x8(%r8, %rcx, 8)	   # przeusniecie o 1 bit w lewo (najstarszy do cf, na najmlodszy cf)
pushf
decq 	%rcx
jnz 	shl1024_loop
popf
popq	%rcx

movq 	%rbp, %rsp
popq 	%rbp
ret

# 1 arg - %rbx -> dzielna
# 2 arg - %rdx -> dzielnik
# 3 arg - %rdi -> wynik
# 4 arg - %rsi -> reszta
.type div1024, @function
div1024:
pushq %rbp
movq 	%rsp, %rbp

pushq %rsi            # zapisanie adresów reszty
pushq %rdi            # oraz wyniku

movq 	%rbx, %rsi
leaq 	D_shift, %rdi
movq 	$16, %rcx       # licznik
rep 	movsq				    # skopiowanie dzielnej do zmiennej pomocniczej
movq 	$1024, %rcx

popq 	%rdi
popq 	%rsi

div1024_loop:
# shl1024(&rsi->reszta);
movq 	%rsi, %r8
call 	shl1024         # przesunięcie bitowe R w lewo o 1 bit
# shl1024(&D_shift)
leaq	D_shift, %r8
call 	shl1024
jnc 	div1024_1			  # po przesunieciu nie ma przenesienia => przejdź dalej
bts 	$0, 120(%rsi)	  # ustawia najmniej znaczacy bit reszty na 1
                      # jesli wystąpiło przeniesienie
			                # R(0) := D(i)

div1024_1:
# shl1024(&rdi-wynik) # Q << 1, w celu pozniejszego ustawienia bitu na i-tej pozycji
movq 	%rdi, %r8		    # Q(i) := 1
call	shl1024

# sub1024(&reszta, &dzielnik, &P)
movq 	%rsi, %r8
movq 	%rdx, %r9
leaq 	P, %r10
call 	sub1024
jb 		div1024_2			  # porownanie dzielnika i reszty, if R >= X then ...
                      # ,else skacz do div1024_2

# sub1024(&reszta, &dzielnik, &reszta)
movq 	%rsi, %r8
movq 	%rdx, %r9
movq 	%rsi, %r10
call 	sub1024			    # odjecie dzielnika od reszty, R := R - X
bts 	$0, 120(%rdi)  	# ustawienie najmniej znaczacego bitu na wartosc cf, Q(i) := 1

div1024_2:
decq 	%rcx
jnz 	div1024_loop

movq 	%rbp, %rsp
popq 	%rbp
ret
