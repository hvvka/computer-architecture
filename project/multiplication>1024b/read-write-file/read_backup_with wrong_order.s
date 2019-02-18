.data
STDIN = 0
STDOUT = 1
SYSREAD = 0
SYSWRITE = 1
SYSOPEN = 2
SYSCLOSE = 3
FREAD = 0
FWRITE = 03101
SYSEXIT = 60
EXIT_SUCCESS = 0
END_OF_FILE = 0

multiplicand_in: .ascii "multiplicand.txt\0"
multiplier_in:   .ascii "multiplier.txt\0"
result_out:      .ascii "result.txt\0" # Plik do którego zostanie zapisany wynik
mnozna_len: .quad 0
mnoznik_len: .quad 0

# mnozna i mnoznik powinny być 2x większe
BUF_LEN = 1024
first:    .fill 512       # mnożna
mnozna:   .fill 1024       # mnożna odczytana z pliku
second:   .fill 512       # mnożnik
mnoznik:  .fill 1024       # mnożnik odczytany z pliku
partial:  .fill 1024      # suma cząstkowa
result:   .fill 2048      # wynik do zapisu do pliku

.bss

.text
.globl main # Dla debugowania

main:
# WCZYTANIE PIERWSZEGO CIĄGU
# Otwarcie pliku $multiplicand_in do odczytu
movq    $SYSOPEN, %rax
movq    $multiplicand_in, %rdi
movq    $FREAD, %rsi
movq    $END_OF_FILE, %rdx
syscall

pushq   %rax        # file descriptor dla multiplicand.txt w rax

# Odczyt z pliku do bufora
movq    %rax, %rdi
movq    $SYSREAD, %rax
movq    $mnozna, %rsi
movq    $BUF_LEN, %rdx
syscall

# sprawdzanie czy udał się odczyt pliku
cmpq    $END_OF_FILE, %rax
jle     end     # skok jeśli nastąpił błąd odczytu, czyli
# liczba ujemna w %rax lub koniec pliku ($0)

popq    %r10       # ściągniecie file descriptora
pushq   %rax       # Zapisanie liczby odczytanych bajtów

# Zamknięcie pliku
movq    $SYSCLOSE, %rax
movq    %r10, %rdi
syscall

# WCZYTANIE DRUGIEGO CIĄGU
# Otwarcie pliku $multiplier_in do odczytu
movq    $SYSOPEN, %rax
movq    $multiplier_in, %rdi
movq    $FREAD, %rsi
movq    $END_OF_FILE, %rdx
syscall

pushq   %rax      # file descriptor dla multiplier.txt

# Odczyt z pliku do bufora
movq    %rax, %rdi
movq    $SYSREAD, %rax
movq    $mnoznik, %rsi
movq    $BUF_LEN, %rdx
syscall

# sprawdzanie czy udał się odczyt pliku
cmpq    $END_OF_FILE, %rax
jle     end       # skok jeśli nastąpił błąd odczytu, czyli
# liczba ujemna w %rax lub koniec pliku ($0)

popq    %r10
pushq   %rax       # Zapisanie liczby odczytanych bajtów do rejestru R12

# Zamknięcie pliku
movq    $SYSCLOSE, %rax
movq    %r10, %rdi
syscall

popq    %r12
popq    %r11

decq    %r12
decq    %r11

xorq    %r10, %r10
movq    %r11, mnozna_len(%r10)
movq    %r12, mnoznik_len(%r10)

# -----------------------------------------
# -------- PRZEPISANIE DO BUFORÓW ---------
# -----------------------------------------
# R11 - liczba wczytanych bajtów z mnożnej
# R12 - liczba wczytanych bajtów z mnożnika
# -----------------------------------------
trap:
xorq  %r10, %r10      # licznik mnozna
xorq  %rdi, %rdi      # licznik mnoznik

przepisanie_mnozna:
cmpq  %r11, %rdi
jge   przepisanie_mnoznik
xorq  %rbx, %rbx      # dolne 4 bity
xorq  %rcx, %rcx      # górne 4 bity
movb  mnozna(,%rdi,1), %bl  # przepisanie mnożnej
incq  %rdi

# ascii -> wartość
cmpb  $'9', %bl
jg    litera_1_mnozna
# konwersja z liczby
subb  $'0', %bl
jmp   next_4bits_mnozna
litera_1_mnozna:
subb  $55, %bl
jmp   next_4bits_mnozna

next_4bits_mnozna:
cmpq  %r11, %rdi
jge   wpisz_do_first
movb  mnozna(,%rdi,1), %cl
incq  %rdi

cmpb  $'9', %cl
jg    litera_2_mnozna
# konwersja z liczby
subb  $'0', %cl
jmp   shift_mnozna
litera_2_mnozna:
subb  $55, %cl

shift_mnozna:
shlb  $4, %cl
orb   %cl, %bl

wpisz_do_first:
movb  %bl, first(,%r10,1)
incq  %r10
jmp   przepisanie_mnozna

# ####################################

przepisanie_mnoznik:
# do napisania
xorq  %rsi, %rsi            # licznik mnoznik
xorq  %rax, %rax            # licznik second

przepisanie_mnoznik_loop:
cmpq  %r12, %rsi
jge   main_function
xorq  %rbx, %rbx      # dolne 4 bity
xorq  %rcx, %rcx      # górne 4 bity
movb  mnoznik(,%rsi,1), %bl  # przepisanie mnożnika
incq  %rsi

# ascii -> wartość
cmpb  $'9', %bl
jg    litera_1_mnoznik
# konwersja z liczby
subb  $'0', %bl
jmp   next_4bits_mnoznik
litera_1_mnoznik:
subb  $55, %bl
jmp   next_4bits_mnoznik

next_4bits_mnoznik:
cmpq  %r12, %rsi
jge   wpisz_do_second
movb  mnoznik(,%rsi,1), %cl
incq  %rsi

cmpb  $'9', %cl
jg    litera_2_mnoznik
# konwersja z liczby
subb  $'0', %cl
jmp   shift_mnoznik
litera_2_mnoznik:
subb  $55, %cl

shift_mnoznik:
shlb  $4, %cl
orb   %cl, %bl

wpisz_do_second:
movb  %bl, second(,%rax,1)
incq  %rax
jmp   przepisanie_mnoznik_loop


# ####################################

# --------------------------------------
# ---------------- MAIN ----------------
# --------------------------------------
.type main_function, @function
main_function:
# przepisanie
call    iloczyn

# --------------------------------------
# ----- KONWERSJA partial -> ASCII -----
# --------------------------------------

przepisanie_partial:
# movq    $BUF_LEN, %rsi  # Licznik bajtów z bufora partial

xor     %r15, %r15
movq    mnozna_len(%r15), %r11
movq    mnoznik_len(%r15), %r12
cmpq    %r11, %r12
jg      wybierz_mnoznik
movq    %r11, %rsi       # wybor odpowiedniego licznika
jmp     increase_counter
wybierz_mnoznik:
movq    %r12, %rsi
increase_counter:
shlq    $2, %rsi

hex_loop:
cmp     $0, %rsi
jl      end_loop        # jle
xor     %rcx, %rcx
xor     %rdx, %rdx
movb    partial(,%rsi,1), %dl
movb    %dl, %cl
shrb    $4, %dl
andb    $0xf, %dl       # 4 górne bity
andb    $0xf, %cl       # 4 dolne bity
decq    %rsi

cmp     $9, %cl
jg      cl_to_letter

cl_to_number:
addb    $'0', %cl
jmp     dl_to_ascii

cl_to_letter:
addb    $55, %cl        # konwersja [10;15] na ascii w [A;F]
jmp     dl_to_ascii

dl_to_ascii:
cmp     $9, %dl
jg      dl_to_letter

dl_to_number:
addb    $'0', %dl
jmp     go_textout

dl_to_letter:
addb    $55, %dl        # konwersja [10;15] na ascii w [A;F]
jmp     go_textout

go_textout:
movb    %dl, result(,%r15,1)
incq    %r15
movb    %cl, result(,%r15,1)
incq    %r15
jmp     hex_loop


# ####################################
end_loop:
movb    $'\n', result(,%r15,1)
incq    %r15

# Zapis bufora result_out do result.txt
# ZAPISANIE WYNIKU
# Otwarcie pliku $result.txt do zapisu.
# Jeśli plik nie istnieje, utworzenie go z prawami 666.
movq    $SYSOPEN, %rax
movq    $result_out, %rdi
movq    $FWRITE, %rsi
movq    $0666, %rdx
syscall

movq    %rax, %r10      # file descriptor dla result.txt

# Zapis bufora partial do pliku
movq  $SYSWRITE, %rax
movq  %r10, %rdi
movq  $result, %rsi
movq	%r15, %rdx
syscall

# Zamknięcie pliku
movq  $SYSCLOSE, %rax
movq  %r10, %rdi
syscall

# ZWROT WARTOŚCI EXIT_SUCCESS
movq  $SYSEXIT, %rax
movq  $EXIT_SUCCESS, %rdi
syscall


# --------------------------------------
# -------------- DODAWANIE -------------
# --------------------------------------
.type dodawanie, @function
dodawanie:
pushq   %rbp
movq    %rsp, %rbp
addq    %rbx, %rsi          # suma liczników obu pętli (wew i zew)


continue:
# wynik mnożenia w: rdx | rax
addq    (%r10,%rsi,8), %rax
movq    %rax, (%r10,%rsi,8)
incq    %rsi
adcq    (%r10,%rsi,8), %rdx
movq    %rdx, (%r10,%rsi,8) # CF?
jnc     end

flag_loop:
movq    $0, %rax
incq    %rsi
adcq    (%r10,%rsi,8), %rax
movq    %rax, (%r10,%rsi,8)
jc      flag_loop

end:
movq    %rbp, %rsp
popq    %rbp
ret

# --------------------------------------
# -------------- ILOCZYN ---------------
# --------------------------------------
.type iloczyn, @function
iloczyn:
pushq   %rbp
movq    %rsp, %rbp

decq    %r11
decq    %r12

# zaokrąglanie mnoznej
xorq    %rdx, %rdx
movq    %r11, %rax
movq    $8, %rcx
idiv    %rcx
movq    %rax, %r9

# zaokrąglanie mnoznika
xorq    %rdx, %rdx
movq    %r12, %rax
movq    $8, %rcx
idiv    %rcx
movq    %rax, %r10

# --------------------------------------
# mnożenie: rax * rdx = rdx | rax
movq    %r9, %rcx         # maksymalny indeks FIRST
movq    %r10, %rdi        # maksymalny indeks SECOND
leaq    first, %r8
leaq    second, %r9
leaq    partial, %r10
xorq    %rsi, %rsi        # licznik pętli wewnętrznej
xorq    %rbx, %rbx        # licznik pętli zewnętrznej

outer_loop:
movq    (%r9,%rbx,8), %r13      # D

inner_loop:
# D x A
movq	  %r13, %rdx
movq    (%r8,%rsi,8), %rax      # A
mulq    %rdx
# rdx | rax
pushq   %rsi
pushq   %rbx
call    dodawanie
popq    %rbx
popq    %rsi
incq    %rsi
cmpq    %rdi, %rsi
jle     inner_loop

xorq    %rsi, %rsi
incq    %rbx
cmpq    %rcx, %rbx
jle     outer_loop

movq    %rbp, %rsp
popq    %rbp
ret
