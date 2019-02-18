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

movq    %rax, %r10      # file descriptor dla multiplicand.txt

# Odczyt z pliku do bufora
movq    $SYSREAD, %rax
movq    %r10, %rdi
movq    $mnozna, %rsi
movq    $BUF_LEN, %rdx
syscall

movq    %rax, %r11       # Zapisanie liczby odczytanych bajtów do rejestru R8

# sprawdzanie czy udał się odczyt pliku
cmpq    $END_OF_FILE, %rax
jle     end     # skok jeśli nastąpił błąd odczytu, czyli
# liczba ujemna w %rax lub koniec pliku ($0)

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

movq    %rax, %r10      # file descriptor dla multiplier.txt

# Odczyt z pliku do bufora
movq    $SYSREAD, %rax
movq    %r10, %rdi
movq    $mnoznik, %rsi
movq    $BUF_LEN, %rdx
syscall

movq    %rax, %r12       # Zapisanie liczby odczytanych bajtów do rejestru R12

# sprawdzanie czy udał się odczyt pliku
cmpq    $END_OF_FILE, %rax
jle     end       # skok jeśli nastąpił błąd odczytu, czyli
# liczba ujemna w %rax lub koniec pliku ($0)

# Zamknięcie pliku
movq    $SYSCLOSE, %rax
movq    %r10, %rdi
syscall


# -----------------------------------------
# -------- PRZEPISANIE DO BUFORÓW ---------
# -----------------------------------------
# R11 - liczba wczytanych bajtów z mnożnej
# R12 - liczba wczytanych bajtów z mnożnika
# -----------------------------------------
trap:
movq  $BUF_LEN, %r10  # w %rax indeks ostatniego "klocka"
movq  %rax, %r10

movq  %r11, %rdi      # licznik mnozna
movq  %r12, %rsi      # licznik mnoznik

przepisanie_mnozna:
decq  %rdi            # licznik mnozna
decq  %r10            # licznik first

xorq  %rbx, %rbx      # dolne 4 bity
xorq  %rcx, %rcx      # górne 4 bity
movb  mnozna(,%rdi,1), %bl  # przepisanie mnożnej

# ascii -> wartość
cmpq  $9, %bl
jg    litera_1_mnozna
# konwersja z liczby
subb  $'0', %bl
jmp   next_4bits_mnozna
litera_1_mnozna:
subb  $55, %bl
jmp   next_4bits_mnozna

next_4bits_mnozna:
cmpq  $0, %rdi
jle   wpisz_do_first
decq  %rdi
movb  mnozna(,%rdi,1), %cl

cmpq  $9, %cl
jg    litera_2_mnozna
# konwersja z liczby
subb  $'0', %cl
jmp   shift
litera_2_mnozna:
subb  $55, %cl

shift_mnozna:
shlb  $4, %cl
orb   %cl, %bl

wpisz_do_first:
movb  %bl, first(,%r10,1)
cmpq  $0, %rdi
jle   przepisanie_mnoznik
jmp   przepisanie_mnozna

# ####################################

przepisanie_mnoznik:
# do napisania
decq  %rsi            # licznik mnoznik
decq  %rax            # licznik second

xorq  %rbx, %rbx      # dolne 4 bity
xorq  %rcx, %rcx      # górne 4 bity
movb  mnozna(,%rsi,1), %bl  # przepisanie mnożnika

# ascii -> wartość
cmpq  $9, %bl
jg    litera_1_mnoznik
# konwersja z liczby
subb  $'0', %bl
jmp   next_4bits_mnoznik
litera_1_mnoznik:
subb  $55, %bl
jmp   next_4bits_mnoznik

next_4bits_mnoznik:
cmpq  $0, %rsi
jle   wpisz_do_first
decq  %rsi
movb  mnozna(,%rsi,1), %cl

cmpq  $9, %cl
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
cmpq  $0, %rsi
jle   przepisanie_mnoznik
jmp   przepisanie_mnozna


# ####################################

# --------------------------------------
# ---------------- MAIN ----------------
# --------------------------------------
.type main_function
main_function:
# przepisanie
leaq    multiplicand, %rbx
leaq    multiplier, %r8
call    iloczyn

check:
movq    $EXIT, %rax
movq    $EXIT_SUCCESS, %rdi
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

leaq    first, %rdi
movq    %rbx, %rsi
movq    %rax, %rcx
rep     movsq

# zaokrąglanie mnoznika
xorq    %rdx, %rdx
movq    %r12, %rax
movq    $8, %rcx
idiv    %rcx
movq    %rax, %r10

leaq    second, %rdi
movq    %r8, %rsi
movq    %rax, %rcx
rep 	  movsq

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

# --------------------------------------
# ----- KONWERSJA partial -> ASCII -----
# --------------------------------------

# KONWERSJA NA SYSTEM ÓSEMKOWY I ZAPIS DO ASCII
movq    $BUFLEN, %r8  # Licznik bajtów z bufora partial
movq    $BUFLEN, %r9 # Licznik znaków ósemkowych z bufora out
shlq    $2, %r9

przepisanie_partial:
# Odczyt kolejnych bajtów i przesunięcia bitowe,
# aby pobrać z bufora value, do rejestru RAX
# 3 kolejne bajty we właściwej kolejności.
mov $0, %rax
sub $2, %r8
mov partial(, %r8, 1), %al
shl $8, %rax
inc %r8
mov partial(, %r8, 1), %al
shl $8, %rax
inc %r8
mov partial(, %r8, 1), %al
sub $3, %r8

mov $8, %r10 # Licznik dla zagnieżdżonej pętli w której nastąpi
             # odczyt 8 znaków ósemkowych z 3 bajtowej liczby.

petla4:
mov %al, %bl  # Skopiowanie pierwszego bajtu liczby do rejestru BL
and $0xf, %bl   # Usunięcie wszystkich bitów poza 4 najmniej znaczącymi
add $'0', %bl # Dodanie kodu znaku ASCII '0' do wyniku maskowania
mov %bl, out(, %r9, 1) # Zapis znaku ASCII do bufora wyjściowego

shr $3, %rax # Przesunięcie bitowe dotychczasowej liczby o 3 bity w prawo,
             # tak aby pozbyć się już zdekodowanych 3 bitów.
dec %r9      # Zmniejszenie liczników pętli
dec %r10
cmp $0, %r10 # Skok na początek zagnieżdżonej pętli,
             # jeśli pozostały jeszcze bity liczby do zdekodowania
jg petla4

cmp $0, %r8  # Skok na początek petla3, aby pobrać kolejne
jg petla3    # 3 bajty cyfry do dekodowania.

# ------------------------------
przepisanie_partial:
decq  %rdi            # licznik partial
decq  %r10            # licznik result

xorq  %rbx, %rbx      # dolne 4 bity
xorq  %rcx, %rcx      # górne 4 bity
movb  partial(,%rdi,1), %bl  # przepisanie wyniku

# ascii -> wartość
cmpq  $9, %bl
jg    litera_1_partial
# konwersja z liczby
subb  $'0', %bl
jmp   next_4bits_partial
litera_1_partial:
subb  $55, %bl
jmp   next_4bits_partial

next_4bits_partial:
cmpq  $0, %rdi
jle   wpisz_do_result
decq  %rdi
movb  partial(,%rdi,1), %cl

cmpq  $9, %cl
jg    litera_2_partial
# konwersja z liczby
subb  $'0', %cl
jmp   shift_partial
litera_2_partial:
subb  $55, %cl

shift_partial:
shlb  $4, %cl
orb   %cl, %bl

wpisz_do_result:
movb  %bl, result(,%r10,1)
cmpq  $0, %rdi
jle   end
jmp   przepisanie_partial


# ####################################

end:

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
movq  $partial, %rsi
movq  $BUF_LEN, %rdx
syscall

# Zamknięcie pliku
movq  $SYSCLOSE, %rax
movq  %r10, %rdi
syscall

# ZWROT WARTOŚCI EXIT_SUCCESS
movq  $SYSEXIT, %rax
movq  $EXIT_SUCCESS, %rdi
syscall
