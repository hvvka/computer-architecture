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

# mozna i mnoznik powinny być 2x większe
BUF_LEN = 1024
first:    .fill 512       #mnożna
mnozna:   .fill 1024      #mnożna odczytana z pliku
tmp_mnozna:.fill 512
second:   .fill 512       #mnożnik
mnoznik:  .fill 1024      #mnożnik odczytany z pliku
tmp_mnozna:.fill 512
partial:  .fill 512       #suma cząstkowa

.bss
.comm in, 1024   # Bufor zawierający znaki (cyfry hex) odczytane z pliku
.comm value, 528 # Bufor zawierający wartości kolejnych bajtów odczytanej
# liczby. Jego rozmiar jest spowodowany konwersji systemów
# korzystając z właściwości baz skojarzonych. Wspólną
# wielokrotnością 4 (ilość bitów które koduje jedna
# cyfra heksadecymalna) i 3 (-||- w systemie ósemkowym).
.comm out, 1409  # Bufor wyjściowy zawierający znaki ósemkowe po konwersji.
# Rozmiar jest większy o jeden z uwagi na znak końca linii.

.text
.globl _start # Dla debugowania

_start:
# WCZYTANIE PIERWSZEGO CIĄGU
# Otwarcie pliku $multiplicand_in do odczytu
movq    $SYSOPEN, %rax
movq    $multiplicand_in, %rdi
movq    $FREAD, %rsi
movq    $END_OF_FILE, %rdx
syscall

movq    %rax, %r10      #file descriptor dla multiplicand.txt

# Odczyt z pliku do bufora
movq    $SYSREAD, %rax
movq    %r10, %rdi
movq    $mnozna, %rsi
movq    $BUF_LEN, %rdx
syscall

movq    %rax, %r11       # Zapisanie liczby odczytanych bajtów do rejestru R8

#sprawdzanie czy udał się odczyt pliku
cmpq    $END_OF_FILE, %rax
jle     end     #skok jeśli nastąpił błąd odczytu, czyli
                #liczba ujemna w %rax lub koniec pliku ($0)

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

movq    %rax, %r10      #file descriptor dla multiplier.txt

# Odczyt z pliku do bufora
movq    $SYSREAD, %rax
movq    %r10, %rdi
movq    $mnoznik, %rsi
movq    $BUF_LEN, %rdx
syscall

movq    %rax, %r12       # Zapisanie liczby odczytanych bajtów do rejestru R12

#sprawdzanie czy udał się odczyt pliku
cmpq    $END_OF_FILE, %rax
jle     end       #skok jeśli nastąpił błąd odczytu, czyli
                  #liczba ujemna w %rax lub koniec pliku ($0)

# Zamknięcie pliku
movq    $SYSCLOSE, %rax
movq    %r10, %rdi
syscall


# #########
# MNOŻENIE
# #########


# ##########################################
# -> PRZEPISANIE mnozna DO first
# R11 - liczba wczytanych bajtów z mnożnej
# R12 - liczba wczytanych bajtów z mnożnika
# ##########################################
trap:
decq    %r11    # usunięcie znaku nowej linii
decq    %r12    # usunięcie znaku nowej linii

# obliczenie ostatniego indeksu do buforów first i second
# zakładając przesuwanie się po 8 bajtów
movq  $BUF_LEN, %rax
movq  $8, %rdi
xorq  %rdx, %rdx
idiv  %rax        # $BUF_LEN/8
decq  %rax
# w %rax indeks ostatniego "klocka"


# przepisanie mnozna do first
# z konwersją ascii -> wartość
# przepisanie z dosunięciem "do prawej" (do końca bufora first)
movq  %r11, %rdi      # licznik mnozna
decq  %rdi
movq  %rax, %rsi      # licznik first
decq  %rsi
przepisanie_mnozna:
xorq  %rbx, %rbx      # rejestr-pośrednik na dolne 4 bity
xorq  %rcx, %rcx      # rejestr-pośrednik na górne 4 bity
cmpq  $0, %rdi        # czy dojechaliśmy do końca? (kopiowanie mnożnej)
jge   przepisanie_mnoznik
movb  mnozna(,%rdi,1), %bl  # przepisanie mnożnej
decq  %rdi            # zmniejszenie licznika

# ascii -> wartość
cmpq  $9, %bl
jg    litera_1
subb  $'0', %bl       # konwersja z liczby
jmp   next_4bits
litera_1:
subb  $55, %bl        # konwersja z litery
jmp   next_4bits

next_4bits:
cmpq  $0, %rdi
jge   wpisz_do_first
movb  mnozna(,%rdi,1), %cl
decq  %rdi

cmpq  $9, %cl
jg    litera_2
subb  $'0', %cl       # konwersja z liczby
jmp   shift
litera_2:
subb  $55, %cl        # konwersja z litery

# sklejenie bajtów i włożenie ich na koniec first
shift:
shlb  $4, %bl
orb   %bl, %cl
wpisz_do_fir:
movb  %cl, tmp_mnozna(,%rsi,1)
decq  %rsi
jmp   przepisanie_mnozna  # zapętlenie operacji

# ##########################################
# -> PRZEPISANIE mnoznik DO second
# ##########################################
przepisanie_mnoznik:
# do napisania




# Przepisanie mnożnej do first w odwrotnej kolejności klocków
movb  mnozna(,), %bl
movb  %, first()


sss:
cmpq    %r11, %rdi
jge     next

# przepisanie bufora first do partial
movb    first(,%rdi,1), %bl
movb    %bl, partial(,%rdi,1)

incq    %rdi
jmp     sss

next:
movq    %rdi, %rcx
xorq    %rdi, %rdi      # licznik
xorq    %rbx, %rbx      # rejestr-pośrednik

aaa:
cmpq    %r12, %rdi
jge     end

# przepisanie bufora first do partial
movb    second(,%rdi,1), %bl
movb    %bl, partial(,%rcx,1)

incq    %rdi
incq    %rcx
jmp     aaa


# ##################
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
movq    $SYSWRITE, %rax
movq    %r10, %rdi
movq    $partial, %rsi
movq    $BUF_LEN, %rdx
syscall

# Zamknięcie pliku
movq    $SYSCLOSE, %rax
movq    %r10, %rdi
syscall

# ZWROT WARTOŚCI EXIT_SUCCESS
mov $SYSEXIT, %rax
mov $EXIT_SUCCESS, %rdi
syscall
