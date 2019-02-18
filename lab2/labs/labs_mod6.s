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

textout:  .space 512, 0

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


###########################
##algorytm zamiany na hex##
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

cmp     $32, %cl        #space
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
movq    %r9, %rax

go_on:
movq    $0, %rcx
movq    $0, %rdx        #rejestr do pomocy
movq    $0, %r10        #wewnętrzy licznik pack_4bits (zlicza do 2)

pack_2bits:
movq    $0, %rcx
movb    tmp(,%r9,1), %dl
cmp     $' ', %dl
je      switch_numbers
addb    %dl, %cl
andb    $0x3, %cl
decq    %r9

pack_4bits:
movb    tmp(,%r9,1), %dl
cmp     $' ', %dl
je      switch_numbers
andb    $0x3, %dl
shlb    $2, %dl
addb    %dl, %cl
andb    $0xf, %cl
decq    %r9

to_ascii_hex:
cmp     $9, %cl
jg      to_letter

to_number:
addb    $'0', %cl
jmp     to_textout

to_letter:
addb    $55, %cl        #konwersja [10;15] na ascii w [A;F]
jmp     to_textout

switch_numbers:
movq    $1, %r11
decq    %r9
jmp     pack_2bits

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
cmpq    $-1, %r9
jl      go_on

############################

xor     %rax, %rax
xor     %rbx, %rbx
xor     %rdx, %rdx
xor     %rsi, %rsi

cmp     %r9, %r8
jl      iterate_by_r9

iterate_by_r8:
movq    %r8, %rcx
jmp     next_step

iterate_by_r9:
movq    %r9, %rcx       #iteracja po dłuższej liczbie

next_step:
dec     %rcx            #ostatnie sumowane jest ręczne, iterujemy długość-1 razy
clc                     #czyszczenie flagi przeniesienia po to, by jej nie dodać do wyniku na początku działania pętli

petla:
movb    liczba1(,%rsi,1), %bl 	#bl = liczba1[esi];
movb    liczba2(,%rsi,1), %al	#sumujemy po bajtach

#przywrócenie poprzedniej flagi przeniesienia, obecnie w %dl
cmpb    $0, %dl
jne     ustawiamy_flage_cf
clc                             #if(dl == 0) => flagi nie ustawiamy (zerujemy)

jmp     dalej
ustawiamy_flage_cf:
stc                             #ustawia CF na 1

dalej:
adc     %bl, %al                #al = al + bl + cf;
movb    %al, textout(,%rsi,1)	#przenienienie wyniku dodawania do bufora
setc    %dl                     #zachowanie flagi przeniesienia w DL, setcb
inc     %rsi                    #zwiększenie indeksu tablicy, inc nie zmienia flagi CF
loop    petla                   #dekrementacja ecx, przyrównanie go do 0 i skok jeśli !=0

movb    %dl, textout(,%rsi,1)   #po zsumowaniu każdej pary bajtów przeniesienie CF do ostatniego bajta wyniku

############################

#zapis bufora do pliku OUTPUT
movq	%rsi, %rdx
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
