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
.comm   textin,  512
.comm   tmp,     512
.comm   textout, 512

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
jle     end_loop	#błąd odczytu - liczba ujemna w %rax lub koniec pliku ($0)


############################

movq    $0, %rdi        #licznik dla textin
movq    $0, %r8         #licznik dla textout
movq    $0, %r9         #licznik dla tmp
movq    $0, %rcx        #zerowanie bufora do pobierania znaków

read_textin:
cmpq    %rax, %rdi
jge     continue
movb    textin(,%rdi,1), %cl
incq    %rdi

cmp     $'0', %cl
jl      read_textin
cmp     $'3', %cl
jg      read_textin     #pominięcie wszystkich znaków, które nie są w [0;3]

subb    $'0', %cl
movb    %cl, tmp(,%r9,1)
incq    %r9
jmp     read_textin

continue:
movq    %r9, %rax
movq    $0, %r9

go_on:
movq    $0, %rcx
movq    $0, %rdx        #rejestr do pomocy
movq    $0, %r10        #wewnętrzy licznik pack_4bits (zlicza do 2)

pack_4bits:
shlb    $2, %cl
movb    tmp(,%r9,1), %dl
andb    $0x3, %dl
addb    %dl, %cl
andb    $0xf, %cl
incq    %r9
incq    %r10
cmp     $2, %r10
jl      pack_4bits

to_ascii_hex:
cmp     $9, %cl
jg      to_letter

to_number:
addb    $'0', %cl
jmp     to_textout

to_letter:
addb    $55, %cl        #konwersja [10;15] na ascii w [A;F]
jmp     to_textout

to_textout:
movb    %cl, textout(,%r8,1)
incq    %r8
cmpq    %rax, %r9
jl      go_on

############################


#zapis bufora do pliku OUTPUT
movq	%r8, %rdx
movq	$SYSWRITE, %rax
movq	ST_FD_OUT(%rbp), %rdi
movq	$textout, %rsi
syscall

jmp     read_loop

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
