
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

inputf: .ascii  "input.txt"
outputf: .ascii "output.txt"

.bss
.comm   textin,  512      #przechowuje wczytane dane
.comm   tmp,     512
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

movq    $inputf, ST_ARGV_1(%rbp)
movq    $outputf, ST_ARGV_2(%rbp)

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
dec     %rax
movq	$0, %rdi	#licznik pobranych znaków z textin

ascii_to_dec:
movq	$0, %rcx                #czyszczenie rejestru do odczytu kolejnych bajtów z textin
cmp     %rax, %rdi              #porównanie liczby znaków w %rax z licznikiem %rdi
jge     next_loop               #skok, jeśli %rdi (licznik) >= liczba wczytanych znaków z textin
movb	textin(,%rdi,1), %cl    #wczytanie jednego bajtu do %cl

cmp     $'0', %cl
jl      ascii_to_dec
cmp     $'3', %cl
jg      ascii_to_dec    #pominięcie wszystkich znaków, które nie są w [0;3]

sub     $'0', %cl
movb    %cl, tmp(,%rdi,1)
inc     %rdi
jmp     ascii_to_dec

next_loop:
movq	$0, %rcx        #przechowuje do 4 bitów
movq	$0, %rdx        #nieużywane
movq    $0, %r9         #licznik cyfr binarych (max 2)
movq    $0, %r12        #licznik do textout
jmp     convert_from_4

convert_from_4:
cmp     $0, %rdi
jle     write               #wypisanie
shlb    $2, %cl
movb    tmp(,%rdi,1), %cl
andb    $0xff, %cl          #wyzerowanie wyższych częśći rejestru
dec     %rdi
inc     %r9
cmp     $2, %r9
jle     convert_from_4

convert_to_hex:
movq    $0, %r9
cmp     $9, %cl
jle      to_number

to_hex:
addb    $55, %cl            #konwersja [10;15] na ascii w [A;F]
jmp     write

to_number:
addb    $'0', %cl
jmp     write

write:
movb    textout(,%r12,1), %cl
inc     %r12
movq    $0, %rcx
###########################


#zapis bufora textout do pliku OUTPUT
movq	%rax, %rdi              #było movq	%rax, %rdx
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
