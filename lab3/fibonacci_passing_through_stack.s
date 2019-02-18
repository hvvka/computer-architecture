
.data
STDIN   = 0
STDOUT  = 1
SYSWRITE= 1
SYSREAD = 0
SYSEXIT = 60
EXIT_SUCCESS = 0
BUFLEN  = 128

msg_key: .ascii "Podaj numer wyrazu ciagu Fibonacciego do wyswietlenia: "
msg_key_len = .-msg_key

msg_error: .ascii "Wpisany wyraz nie jest liczbą."
msg_error_len = .-msg_error

key_maxlen = 8

.bss
.comm keyin,    8
.comm tmp,      128
.comm textout,  128

.text
.globl _start

_start:
#wypisanie prośby o numer elementu z ciagu Fibonacciego (indeksowanie od 0)
#indeks:    0   1   2   3   4   5   6   7   8   9   10  11  12      13      14      15      16      17      18      19
#wyraz:     0   1   1   2   3   5   8   13  21  34  55  89  144     233     377     610     987     1597    2584    4181
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
                                #długość wczytanego numeru w rax

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
pushq   $0

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
################
popq    %rax
addq    $8, %rsp                #scrubs the parameter that was pushed on the stack; move the stack pointer back; remove value from stack

#przepisanie na ascii#
movq    $10, %r10               #dzielnik
movq    $0, %rdi                #wyzerowanie licznika do tmp
ascii_loop:
movq    $0, %rdx                #wyzerowanie rejestru na resztę
cmpq    $0, %rax
jle     end_ascii
idiv    %r10, %rax              #wynik w rax, reszta w rdx
                                #reszta nie może być większa od 10, więc mieści się na 1 bajcie
addb    $'0', %dl               #przepisanie na ascii
movb    %dl, tmp(,%rdi,1)       #znaki będą wpisywane od najmłodszego (na odwrót)
incq    %rdi
jmp     ascii_loop

end_ascii:
movq    $0, %rsi                #licznik do textout
decq    %rdi                    #cofnięcie ostatniej inkrementacji, by wrócić do indeksu ostatnio wpisanego znaku
tmp_to_textout_loop:            #przepisanie tmp do textout w odwrotnej kolejności
movb    tmp(,%rdi,1), %cl
movb    %cl, textout(,%rsi,1)
decq    %rdi
incq    %rsi
cmpq    $0, %rdi
jl      end_tmp_to_textout
jmp     tmp_to_textout_loop

end_tmp_to_textout:
movb    $'\n', textout(,%rsi,1)
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
#
# fibonacci(int nr) {
#   if(nr == 1 || nr == 2)
#       return 1;
#   else
#       return fibonacci(nr - 1) + fibonacci(nr - 2);
# }
#
#################

fibonacci:
pushq   %rbp
movq    %rsp, %rbp
movq    24(%rbp), %rax         #pobranie arg1 ze stosu (numer wyrazu z ciągu do wypisania)

cmp     $2, %rax        #if(nr == 2)
je      return1         #goto return1
cmp     $1, %rax        #if(nr == 1)
je      return1         #goto return1

decq    %rax            #nr - 1
pushq   %rax            #<--- -8(%rbp)
pushq   $0
call    fibonacci       #fibonacci(nr - 1)      1ST CALL

subq    $16, %rsp       #w sumie nie wiem czy to potrzebne - chyba nie, bo i tak odnoszę się do rbp
                        #rezerwacja miejsca na stosie na argumenty do wywołania 2nd call (nr-2 i wynik)
movq    -8(%rbp), %rax  #nr z 1st call
movq    %rax, -24(%rbp) #nr dla 2nd call
movq    $0, -32(%rbp)   #wynik 2nd call

#przywrocenie stosu do takiego, jaki był przed wywołaniem funckji
decq    -24(%rbp)       #nr - 2
call    fibonacci       #fibonacci(nr - 2)      2ND CALL
movq    -16(%rbp), %rax #wynik z 1st call
addq    -32(%rbp), %rax #wynik z 2nd call
addq    $16, %rsp       #usuwa dwie wartości ze szczytu stosu, przez przesunięcie wskaźnika
movq    %rax, 16(%rbp)  #wsadzenie policzonego wyniku dwóch calli w miejsce na wynik na stosie
jmp     end_fibonacci

return1:
movq    $1, 16(%rbp)    #wsunięcie zwracanej wartości w 'szufladkę' na wynik na stosie

end_fibonacci:
movq    %rbp, %rsp
popq    %rbp
ret

####################################
# mała ilustracja stosu dla nr = 4 #
####################################
#
#   arg1 (nr)           <--- 24(%rbp)               4
#   wynik (0)           <--- 16(%rbp)               0
#
#   adres powrotny      <--- 8(%rbp)
#   save rbp            <--- (%rbp) i (%rsp)
#
#   push rax (nr-1)     <--- -8(%rbp)               3
#   pushq   $0          <--- -16(%rbp)              0
#
# 1st call
#
#   arg1 (nr-1)         <--- 24(%rbp)               3
#   wynik (0)           <--- 16(%rbp)               0
#
#   adres powrotny      <--- 8(%rbp)
#   save rbp            <--- (%rbp) i (%rsp)
#
#   push rax (nr-2)     <--- -8(%rbp)               2                                           decq    -8(%rbp)    (nr - 3)        1
#   pushq   $0          <--- -16(%rbp)              0       ret 1;      <--- -16(%rbp)
#
# 1st call
#
#   arg1 (nr-2)         <--- 24(%rbp)               2
#   wynik (0)           <--- 16(%rbp)               0       ret 1;      movq    $1, 16(%rbp)        1
#
#   adres powrotny      <--- 8(%rbp)
#   save rbp            <--- (%rbp) i (%rsp)
#
#
#
#
# 2nd call
#
#   arg1 (nr-1)         <--- 24(%rbp)               3
#   wynik (0)           <--- 16(%rbp)               0
#
#   adres powrotny      <--- 8(%rbp)
#   save rbp            <--- (%rbp) i (%rsp)
#
#   push rax (nr-3)     <--- -8(%rbp)               1                                           decq    -8(%rbp)    (nr - 2)        1
#   pushq   $0          <--- -16(%rbp)              1       ret 1;      <--- -16(%rbp)
#
#   arg1 (nr-3)         <--- 24(%rbp)               1
#   wynik (0)           <--- 16(%rbp)               1       ret 1;      movq    $1, 16(%rbp)        1
#
#   adres powrotny      <--- 8(%rbp)
#   save rbp            <--- (%rbp) i (%rsp)
#
####################################
