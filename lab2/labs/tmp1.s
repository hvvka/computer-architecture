.data
SYSREAD		= 0
SYSWRITE	= 1
SYSOPEN		= 2
SYSCLOSE	= 3
SYSEXIT		= 60
EXIT_SUCCESS = 0

O_RDONLY	= 0
O_CREAT_WRONLY_TRUNC = 03101

STDIN	= 0
STDOUT	= 1
STDERR	= 2

END_OF_FILE      = 0
NUMBER_ARGUMENTS = 2      #w sumie chyba niepotrzebne
BUF_LEN          = 512

.bss
.comm   textin,  512      #przechowuje wczytane dane
.comm   tmp,     512
.comm   liczba1, 512
.comm   liczba2, 512
.comm   textout, 512      #będzie służył do przechowywania hex

.text

#stack positions
ST_SIZE_RESERVE = 16
ST_FD_IN 	= -8	#file descriptor (input)
ST_FD_OUT 	= -16	#file descriptor (output)
ST_ARGC		= 0     #liczba argumentów (3)
ST_ARGV_0	= 8     #nazwa pliku (argument 0.)
ST_ARGV_1	= 16	#input (argument 1.)
ST_ARGV_2	= 24	#output (argument 2.)


.globl _start
_start:

movq	%rsp, %rbp              #%rbp wskazuje na 0 (zachowanie wskaźnika stosu)
subq	$ST_SIZE_RESERVE, %rsp	#%rsp wskazuje na -16

#otwarcie pliku (INPUT)
movq	$SYSOPEN, %rax
movq	ST_ARGV_1(%rbp), %rdi
movq	$O_RDONLY, %rsi         #tryb odczytu
movq	$0666, %rdx
syscall

#file desciptor zwracany w %rax
movq	%rax, ST_FD_IN(%rbp)	#zapisanie FD_IN na stosie

#otwarcie pliku (OUTPUT)
movq	$SYSOPEN, %rax
movq	ST_ARGV_2(%rbp), %rdi
movq	$O_CREAT_WRONLY_TRUNC, %rsi #utwórz plik, jeśli nie istnieje
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

#sprawdzanie czy udał się odczyt pliku lub czy to już koniec pliku
cmpq	$END_OF_FILE, %rax
jle     end_loop                #błąd odczytu - liczba ujemna w %rax lub koniec pliku ($0)

###########################
##algorytm zamiany na hex##
###########################
movq	$0, %rdi	#licznik pobranych znaków z textin

ascii_to_dec:
#movq	$0, %rcx                #czyszczenie rejestru do odczytu kolejnych bajtów z textin
cmp     %rax, %rdi              #porównanie liczby znaków w %rax z licznikiem %rdi
jge     read_loop               #skok, jeśli %rdi (licznik) >= liczba wczytanych znaków z textin
movb	textin(,%rdi,1), %cl    #wczytanie jednego bajtu do %cl

addb    $1, %cl

movb    %cl, textout(,%rdi,1)
inc     %rdi
jmp     ascii_to_dec
###########################



#zapis bufora textout do pliku OUTPUT
movq	%rdi, %rdx              #było movq	%rax, %rdx
movq	$SYSWRITE, %rax
movq	ST_FD_OUT(%rbp), %rdi
movq	$textout, %rsi          #było movq	$textin, %rsi
syscall

jmp     read_loop               #wczytanie kolejnej linii tekst z pliku (?)

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
