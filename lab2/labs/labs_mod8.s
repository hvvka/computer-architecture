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
.comm   liczba1, 512
.comm   liczba2, 512
.comm   wynik,   513
.comm   textout, 513

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

movq	%rsp, %rbp              #%rbp wskazuje na 0
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

###########################

movq    $0, %rdi        #licznik dla textin
movq    $0, %r8         #licznik do pierwszej liczby
movq    $0, %r9         #licznik dla tmp
movq    $0, %rcx        #zerowanie bufora do pobierania znaków
movq    $0, %r12        #licznik do drugiej liczby
movq    $0, %r11        #'0' dla wczytywania do liczba1, '1' do liczba2

read_textin:
cmpq    %rax, %rdi
jge     continue
movb    textin(,%rdi,1), %cl
incq    %rdi

cmp     $' ', %cl        #space $32
je      save_nl

cmp     $'0', %cl
jl      read_textin
cmp     $'3', %cl
jg      read_textin     #pominięcie wszystkich znaków, które nie są w [0;3] za wyjątkiem ' '

subb    $'0', %cl
save_nl:
movb    %cl, tmp(,%r9,1)
incq    %r9
jmp     read_textin

continue:
dec     %r9

go_on:
cmpq    $0, %r9
jl      compute
movq    $0, %rdx        #rejestr do pomocy

pack_2bits:
movq    $0, %rcx
movb    tmp(,%r9,1), %dl
cmp     $' ', %dl
je      switch_numbers
addb    %dl, %cl
decq    %r9
cmpq    $0, %r9
jl      to_textout

pack_4bits:
movb    tmp(,%r9,1), %dl
cmp     $' ', %dl
je      switch_numbers
shlb    $2, %dl
addb    %dl, %cl
decq    %r9
cmpq    $0, %r9
jl      to_textout

pack_6bits:
movb    tmp(,%r9,1), %dl
cmp     $' ', %dl
je      switch_numbers
shlb    $4, %dl
addb    %dl, %cl
decq    %r9
cmpq    $0, %r9
jl      to_textout

pack_8bits:
movb    tmp(,%r9,1), %dl
cmp     $' ', %dl
je      switch_numbers
shlb    $6, %dl
addb    %dl, %cl
decq    %r9
jmp     to_textout

switch_numbers:
movq    $1, %r11
decq    %r9
jmp     go_on

to_textout:
cmp     $1, %r11
je      liczb1

liczb2:
movb    %cl, liczba2(,%r12,1)
incq    %r12
jmp     go_on

liczb1:
movb    %cl, liczba1(,%r8,1)
incq    %r8
jmp     go_on

############################

compute:
xor     %rax, %rax
xor     %rbx, %rbx
xor     %rdx, %rdx
xor     %rsi, %rsi

cmp     %r12, %r8
jl      iterate_by_r12

iterate_by_r8:
movq    %r8, %rcx
jmp     begin

iterate_by_r12:
movq    %r12, %rcx       #iteracja po dłuższej liczbie

begin:
clc                      #czyszczenie flagi przeniesienia

add_loop:
movb    liczba1(,%rsi,1), %bl
movb    liczba2(,%rsi,1), %al

cmpb    $0, %dl
jne     cf_on
clc                             #if(dl == 0) => flagi nie ustawiamy (zerujemy)
jmp     add_continue

cf_on:
stc                             #ustawia CF na 1

add_continue:
adc     %bl, %al                #al = al + bl + cf;
movb    %al, wynik(,%rsi,1)     #przenienienie wyniku dodawania do bufora
setc    %dl                     #zachowanie flagi przeniesienia w DL, setcb
inc     %rsi                    #zwiększenie indeksu tablicy, inc nie zmienia flagi CF
loop    add_loop                #dekrementacja rcx, przyrównanie go do 0 i skok jeśli !=0

movb    %dl, wynik(,%rsi,1)     #po zsumowaniu każdej pary bajtów przeniesienie CF do ostatniego bajta wyniku

############################
############################
############################

xor     %r15, %r15

hex_loop:
xor     %rcx, %rcx
xor     %rdx, %rdx
cmp     $0, %rsi
jl      end_loop
movb    wynik(,%rsi,1), %dl
movb    %dl, %cl
shrb    $4, %dl
andb    $0xf, %dl       #4 górne bity
andb    $0xf, %cl       #4 dolne bity
decq    %rsi

cmp     $9, %cl
jg      cl_to_letter

cl_to_number:
addb    $'0', %cl
jmp     dl_to_ascii

cl_to_letter:
addb    $55, %cl        #konwersja [10;15] na ascii w [A;F]
jmp     dl_to_ascii

dl_to_ascii:
cmp     $9, %dl
jg      dl_to_letter

dl_to_number:
addb    $'0', %dl
jmp     go_textout

dl_to_letter:
addb    $55, %dl        #konwersja [10;15] na ascii w [A;F]
jmp     go_textout

go_textout:
movb    %dl, textout(,%r15,1)
incq    %r15
movb    %cl, textout(,%r15,1)
incq    %r15
jmp     hex_loop

############################
############################
############################

#zapis bufora do pliku OUTPUT
movq	%r15, %rdx
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
