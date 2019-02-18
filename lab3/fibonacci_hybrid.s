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
.global main
main:
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
movb	$'\n', textout(,%rsi,1)
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
########################################################################
# w wersji tej sam wynik operacji jest przekazywany przez rejestr rax, #
# ale argument do wywołania funkcji (nr) jest przekazywany przez stos  #
########################################################################

fibonacci:
pushq   %rbp
movq    %rsp, %rbp
subq    $8, %rsp               #rezerwacja miejsca na stosie
movq    16(%rbp), %rax         #pobranie arg1 ze stosu (numer wyrazu z ciągu do wypisania)

cmp     $2, %rax               #if(nr == 2)
je      return1                #goto return1
cmp     $1, %rax               #if(nr == 1)
je      return1                #goto return1

decq    %rax                   #nr - 1
pushq   %rax                   #<--- -8(%rbp)
call    fibonacci              #fibonacci(nr - 1)
movq    %rax, -8(%rbp)         #wynik (wyraz nr - 1) zapisany na szczycie stosu, zachowywany w %rax

decq    (%rsp)                 #nr - 2
call    fibonacci              #fibonacci(nr - 2)
addq    $8, %rsp               #"ominięcie" zwracanego wyniku powyższej operacji
addq    -8(%rbp), %rax         #fibonacci(nr - 1) + fibonacci(nr - 2)
jmp     end_fibonacci

return1:
movq    $1, %rax               #return 1;
#decq    %rax

end_fibonacci:
movq    %rbp, %rsp
popq    %rbp
ret
