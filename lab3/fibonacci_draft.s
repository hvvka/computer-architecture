
.data
STDIN   = 0
STDOUT  = 1
SYSWRITE= 1
SYSREAD = 0
SYSEXIT = 60
EXIT_SUCCESS = 0
BUFLEN  = 128

baza0   = 1             #pierwsze dwa wyrazy ciagu Fibonacciego są zahardcodowane
baza1   = 1

msg_key: .ascii "Podaj numer wyrazu ciagu Fibonacciego do wyswietlenia: "
msg_key_len = .-msg_key

msg_error: .ascii "Wpisany wyraz nie jest liczbą."
msg_error_len = .-msg_error

key_maxlen = 8

.bss
.comm keyin,    8
.comm textout,  128

.text
.globl _start

_start:
#wypisanie prośby o numer elementu z ciagu Fibonacciego (indeksowanie od 0)
#indeks:    0   1   2   3   4   5   6   7   8   9   10
#wyraz:     1   1   2   3   5   8   13  21  34  55  89
movq    $SYSWRITE, %rax
movq    $STDOUT, %rdi
movq    $msg_key, %rsi
movq    $msg_key_len, %rdx
syscall

#wczytanie numeru wyrazu
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

pushq   %r10                    #arg1 - numer wyrazu

jmp dalej

wypisz_blad:
movq    $SYSWRITE, %rax
movq    $STDOUT, %rdi
movq    $msg_error, %rsi
movq    $msg_error_len, %rdx
syscall
jmp koniec

dalej:
#################
call    fibonacci
#################
addq    $8, %rsp                #scrubs the parameter that was pushed on the stack

movq    $0, %r14                #do indeksowania textout (wpisanie jednego znaku)
movq    %rax, textout(,%r14,1)

movq    $SYSWRITE, %rax
movq    $STDOUT, %rdi
movq    $textout, %rsi
movq    $BUFLEN, %rdx
syscall

koniec:
movq    $SYSEXIT, %rax
movq    $EXIT_SUCCESS, %rdi
syscall

#################
fibonacci:
pushq   %rbp
movq    %rsp, %rbp
subq    $8, %rsp               #rezerwacja miejsca na stosie

movq    16(%rbp), %rax         #pobranie arg1 ze stosu (numer wyrazu z ciągu do wypisania)

cmp     $0, %rax               #sprawdzenie czy to prośba o $baza0
je      end_fibonacci

cmp     $1, %rax               #sprawdzenie czy to prośba o $baza1
je      end_fibonacci

decq    %rax
pushq   %rax                    #<--- -8(%rbp)
call    fibonacci
movq    16(%rbp), %rbx

addq    %rbx, %rax


end_fibonacci:
movq    %rbp, %rsp
popq    %rbp
ret

########

pushq   %rcx                    #<--- -8(%rbp)
decq    %rcx

call    fibonacci
addq    $8, %rbp                #przesunięcie wskaźnika stosu, bo został poprzednio wrzucony zdekremenetowany %rcx

popq    %rcx


end_fibonacci:
movq    -8(%rbp), %rax              #wynik działania funkcji zwracany jest w %rax

movq    %rbp, %rsp
popq    %rbp
ret


##################
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





