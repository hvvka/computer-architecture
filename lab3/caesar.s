
.data
STDIN   = 0
STDOUT  = 1
SYSWRITE= 1
SYSREAD = 0
SYSEXIT = 60
EXIT_SUCCESS = 0
BUFLEN  = 1

msg_key: .ascii "Podaj klucz: "
msg_key_len = .-msg_key

msg_error: .ascii "Wpisany klucz nie jest liczbą."
msg_error_len = .-msg_error

msg: .ascii "Wpisz znak do szyfrowania: "
msg_len = .-msg

key_maxlen = 8

.bss
.comm keyin,    8
.comm textin,   128
.comm textout,  128

.text
.globl _start

_start:
#wypisanie prośby o klucz
movq    $SYSWRITE, %rax
movq    $STDOUT, %rdi
movq    $msg_key, %rsi
movq    $msg_key_len, %rdx
syscall

#wczytanie klucza
movq    $SYSREAD, %rax
movq    $STDIN, %rdi
movq    $keyin, %rsi
movq    $key_maxlen, %rdx
syscall

dec     %rax                    #dekrementacja, bo licznik jest od 0
                                #długość wczytanego klucza w rax

movq    $0, %rdi                #licznik
movq    $0, %r10                #wartość klucza szyfrującego

wczytaj_klucz:
movq    $0, %rbx
imulq   $10, %r10
movb    keyin(, %rdi, 1), %bl
#sprawdzanie błędów
cmp     $'0', %bl
jl      wypisz_blad
cmp     $'9', %bl
jg      wypisz_blad

subb    $'0', %bl
addq    %rbx, %r10
incq    %rdi
cmp     %rax, %rdi
jl      wczytaj_klucz

pushq   %r10                    #arg1 - klucz

jmp dalej

wypisz_blad:
movq    $SYSWRITE, %rax
movq    $STDOUT, %rdi
movq    $msg_error, %rsi
movq    $msg_error_len, %rdx
syscall
jmp koniec

dalej:
#wypisanie prośby o znak do zaszyfrowania
movq    $SYSWRITE, %rax
movq    $STDOUT, %rdi
movq    $msg, %rsi
movq    $msg_len, %rdx
syscall

#wczytanie znaku
movq    $SYSREAD, %rax
movq    $STDIN, %rdi
movq    $textin, %rsi
movq    $2, %rdx
syscall

movq    $0, %r13                #wyzerowanie rejestru do pobrania znaku
movq    $0, %r14                #do indeksowania textin (pobranie jednego znaku)
movb    textin(,%r14,1), %r13b  #do pobrania znaku do zaszyfrowania
pushq   %r13                    #arg2 - znak

#################
call    cezar
#################

movq    $0, %r14                #do indeksowania textout (wpisanie jednego znaku)
movq    %rax, textout(,%r14,1)
incq    %r14
movq    $'\n', textout(,%r14,1)

movq    $SYSWRITE, %rax
movq    $STDOUT, %rdi
movq    $textout, %rsi
movq    $2, %rdx
syscall

koniec:
movq    $SYSEXIT, %rax
movq    $EXIT_SUCCESS, %rdi
syscall

#################
cezar:
pushq   %rbp
movq    %rsp, %rbp

movq    $0, %r8

movq    16(%rbp), %rbx         #pobranie znaku (arg2)
movq    24(%rbp), %r10         #pobranie klucza (arg1)

cmp     $'A', %bl
jl      czy_to_cyfra
cmp     $'Z', %bl
jg      wypisz
                                #kod od tego miejsca się wykona <=> duża litera w %bl
subb    $'A', %bl
addq    %r10, %rbx              #dodanie klucza
                                #liczenie mod26
movq    %rbx, %rax              #dzielna musi być w rax
movq    $0, %rdx
movq    $26, %r8
idiv    %r8, %rax               #wynik operacji dzielenia zapisywany jest rax, a reszta w rdx

movq    $0, %rbx
movb    %dl, %bl
add     $'A', %bl
jmp     wypisz

czy_to_cyfra:
cmp     $'0', %bl
jl      wypisz
cmp     $'9', %bl
jg      wypisz

subb    $'0', %bl
addq    %r10, %rbx              
                                #liczenie mod10
movq    %rbx, %rax
movq    $0, %rdx
movq    $10, %r8
idiv    %r8, %rax

movq    $0, %rbx
movb    %dl, %bl
addb    $'0', %bl

wypisz:
movq    %rbx, %rax              #wynik działania funkcji zwracany jest w %rax

movq    %rbp, %rsp
popq    %rbp
ret



