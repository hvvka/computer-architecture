
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

#arg1 w r10
movq    $2, %r15    #licznik
movq    $1, %r14    #a
movq    $1, %r13    #b

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
#addq    $8, %rsp                #scrubs the parameter that was pushed on the stack; move the stack pointer back; remove value from stack

movq    %r13, %rax              #zwracana wartość

#przepisanie na ascii#
movq    $10, %r11               #dzielnik
movq    $0, %rdi                #wyzerowanie licznika do tmp
ascii_loop:
movq    $0, %rdx                #wyzerowanie rejestru na resztę
cmpq    $0, %rax
jle     end_ascii
idiv    %r11, %rax              #wynik w rax, reszta w rdx
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
# REKURENCJA OGONOWA
#
# int fibonacci(int a, int b, int licznik)
# {
#    if(licznik < n)
#       return fibonacci(b, a + b, licznik + 1);
#    else return b;
# }
#
# wywołanie funkcji:    fibonacci(1,1,2)
#
# licznik - zmienna od 2 do n-1
# a - wyraz numer x
# b - wyraz numer x+1
# n - numer wyrazu (arg1)
#
#
# r15 - licznik; wartość początkowa: 2
# r14 - a;       wartość początkowa: 1
# r13 - b;       wartość początkowa: 1
# r10 - n;       wartość początkowa: podaje użytkownik (w funkcji const)
#
#
# wynik zwracany w r13 (b)
#
#################

fibonacci:
#pushq   %rbp
#movq    %rsp, %rbp

#wyjątki, których funkcja by nie policzyła
cmp     $2, %r10        # if(n == 2)
je      end_fibonacci
cmp     $1, %r10        # if(n == 1)
je      end_fibonacci

cmp     %r10, %r15      # if(licznik < n)
jge     end_fibonacci   # skok <=> licznik <= n

movq    %r14, %r12      # kopia zmiennej a (rejestru r14) w 12
movq    %r13, %r14      # a = b
addq    %r12, %r13      # b = b + a
incq    %r15            # licznik++

call    fibonacci       # return fibonacci(b, a + b, licznik + 1);

end_fibonacci:
#movq    %rbp, %rsp
#popq    %rbp
ret
