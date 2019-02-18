.data
SYSREAD		= 0
SYSWRITE	= 1
SYSOPEN		= 2
SYSCLOSE	= 3
SYSEXIT		= 60
EXIT_SUCCESS	= 0

O_RDONLY	= 0
O_CREAT_WRONLY_TRUNC = 03101

STDIN	= 0
STDOUT	= 1
STDERR	= 2

END_OF_FILE	= 0

NUMBER_ARGUMENTS = 2

BUF_LEN = 512

.bss
.comm textin, 512
.comm textout, 512	############

.text

#stack positions
ST_SIZE_RESERVE = 16
ST_FD_IN 	= -8	#file descriptor (input)
ST_FD_OUT 	= -16	#file descriptor (output)
ST_ARGC		= 0	#liczba argumentów (3)
ST_ARGV_0	= 8	#nazwa pliku (argument 0.)
ST_ARGV_1	= 16	#input (argument 1.)
ST_ARGV_2	= 24	#output (argument 2.)


.globl _start
_start:

movq	%rsp, %rbp		#%rbp wskazuje na 0
subq	$ST_SIZE_RESERVE, %rsp	#%rsp wskazuje na -16

#otwarcie pliku (INPUT)
movq	$SYSOPEN, %rax
movq	ST_ARGV_1(%rbp), %rdi
movq	$O_RDONLY, %rsi
movq	$0666, %rdx
syscall

#file desciptor zwracany w %rax
movq	%rax, ST_FD_IN(%rbp)	#zapisanie FD_IN na stosie

#otwarcie pliku (OUTPUT)
movq	$SYSOPEN, %rax
movq	ST_ARGV_2(%rbp), %rdi
movq	$O_CREAT_WRONLY_TRUNC, %rsi
movq	$0666, %rdx
syscall

movq	%rax, ST_FD_OUT(%rbp)	#zapisanie FD_OUT na stosie

read_loop:
movq	$SYSREAD, %rax
movq	ST_FD_IN(%rbp), %rdi	#strumień wejściowy to FD pliku input
movq	$textin, %rsi
movq	$BUF_LEN, %rdx
syscall

#w %rax zwracana jest liczba wczytanych znaków

#sprawdzanie czy udał się odczyt pliku
cmpq	$END_OF_FILE, %rax
jle	end_loop	#błąd odczytu - liczba ujemna w %rax lub koniec pliku ($0)

############################
#tu będzie algorytm zamiany#
############################
movq	$0, %rdi	#licznik textin
movq	$0, %r9		#licznik textout
movq	$0, %r8		#licznik dwójek
movq	$0, %r10	#rejestr do przepisania kolejnych bajtów

convert_loop:
movq	$0, %rcx	#czyszczenie rejestru do odczytu kolejnych bajtów z textin
cmp	%rax, %rdi	
jge	read_loop	#skok, jeśli %rdi (licznik) >= liczba wczytanych znaków z BUF
movb	textin(,%rdi,1), %cl

#cmp     $'0', %cl
#jl      end_loop
#cmp     $'3', %cl
#jg      end_loop

subb	$'0', %cl
addb	%cl, %dl
shlb	$2, %dl
inc	%rdi
inc	%r8
cmp	$2, %r8
jge	convert_loop

do_hex:
movq	$0, %r8

cmp     $9, %dl
jl      do_litery

#bez skoku jest cyfra
addb	$'0', %dl
jmp wpisz

do_litery:
addb	$'A', %dl

wpisz:
movb	%dl, textout(,%r9,1)
inc	%r9
movq	$0, %rdx	#czyszczenie rejestru
jmp	convert_loop

#addq	%rcx, %r10
#incq    %rdi              #zwiększenie licznika
#cmp     %rax, %rdi        # ? licznik==długość klucza z textin
#jl      wczytaj_klucz     #skok, jeśli %rdi < %rax
#jmp dalej
#addq	%cl, %dl
#inc	%rdi
#cmp	$4, %rdi
#jl	wpisz
#shlq	$4, %rdx
#jmp	convert_loop
#wpisz:
#movq	$0, %rdi
#dec	%r10
#movw	%dx, textout()
#cmp	$0, %r10
############################

#zapis bufora do pliku OUTPUT
movq	%rax, %rdi		#######było movq	%rax, %rdx
movq	$SYSWRITE, %rax
movq	ST_FD_OUT(%rbp), %rdi
movq	$textout, %rsi		#######było $textin
syscall

#jmp	read_loop

end_loop:
#zamknięcie plik OUTPUT
movq	$SYSCLOSE, %rax
movq	ST_FD_OUT(%rbp), %rdi
syscall

#zamknięcie plik INPUT
movq	$SYSCLOSE, %rax
movq	ST_FD_IN(%rbp), %rdi
syscall

#wyjście z programu
movq	$SYSEXIT, %rax
movq	$EXIT_SUCCESS, %rdi
syscall
