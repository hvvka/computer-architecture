.data
STDIN = 0
STDOUT = 1
SYSREAD = 0
SYSWRITE = 1
SYSOPEN = 2
SYSCLOSE = 3
FREAD = 0
FWRITE = 03101
EXIT = 60
EXIT_SUCCESS = 0
END_OF_FILE = 0


dividend_in:  .ascii "dividend.txt\0"
divisor_in:   .ascii "divisor.txt\0"
result_out:   .ascii "result.txt\0" # Plik do którego zostanie zapisany wynik
dividend_len: .quad 0
divisor_len:  .quad 0

BUF_LEN = 512
first:    .fill 256       # dzielna
dzielna:  .fill 512       # dzielna odczytana z pliku
second:   .fill 8         # dzielnik liczbowo
dzielnik: .fill 16        # dzilenik odczytany z pliku
quotient: .fill 128       # wynik dzielenia
quotient_buf_len = 128
result:   .fill 256       # wynik do zapisu do pliku

# --------------------------------------
# ---------------- MAIN ----------------
# --------------------------------------
.text
.global main
main:
# WCZYTANIE PIERWSZEGO CIĄGU
# Otwarcie pliku $multiplicand_in do odczytu
movq    $SYSOPEN, %rax
movq    $dividend_in, %rdi
movq    $FREAD, %rsi
movq    $END_OF_FILE, %rdx
syscall

pushq   %rax        # file descriptor dla multiplicand.txt w rax

# Odczyt z pliku do bufora
movq    %rax, %rdi
movq    $SYSREAD, %rax
movq    $dzielna, %rsi
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
movq    $divisor_in, %rdi
movq    $FREAD, %rsi
movq    $END_OF_FILE, %rdx
syscall

pushq   %rax      # file descriptor dla multiplier.txt

# Odczyt z pliku do bufora
movq    %rax, %rdi
movq    $SYSREAD, %rax
movq    $dzielnik, %rsi
movq    $17, %rdx
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

# -----------------------------------------
# -------- PRZEPISANIE DO BUFORÓW ---------
# -----------------------------------------
# R11 - liczba wczytanych bajtów z mnożnej
# R12 - liczba wczytanych bajtów z mnożnika
# -----------------------------------------
trap:
movq  %r11, %rdi      # licznik dzielna
xorq  %r10, %r10      # licznik first

przepisanie_dzielna:
decq  %rdi
cmpq  $0, %rdi
jl    przepisanie_dzielnik
xorq  %rbx, %rbx      # dolne 4 bity
xorq  %rcx, %rcx      # górne 4 bity
movb  dzielna(,%rdi,1), %bl  # przepisanie mnożnej

# ascii -> wartość
cmpb  $'9', %bl
jg    litera_1_dzielna
# konwersja z liczby
subb  $'0', %bl
jmp   next_4bits_dzielna
litera_1_dzielna:
subb  $55, %bl
jmp   next_4bits_dzielna

next_4bits_dzielna:
decq  %rdi
cmpq  $0, %rdi    # zmienione z %r11
jl    wpisz_do_first
movb  dzielna(,%rdi,1), %cl

cmpb  $'9', %cl
jg    litera_2_dzielna
# konwersja z liczby
subb  $'0', %cl
jmp   shift_dzielna
litera_2_dzielna:
subb  $55, %cl

shift_dzielna:
shlb  $4, %cl
orb   %cl, %bl

wpisz_do_first:
movb  %bl, first(,%r10,1)
incq  %r10
jmp   przepisanie_dzielna
# ----

# ####################################

przepisanie_dzielnik:
# do napisania
xorq  %r11, %r11
decq  %r10
movq  %r10, dividend_len(%r11)

movq  %r12, %rsi            # licznik dzielnik
xorq  %rax, %rax            # licznik second

przepisanie_dzielnik_loop:
decq  %rsi
cmpq  $0, %rsi
jl   main_function
xorq  %rbx, %rbx      # dolne 4 bity
xorq  %rcx, %rcx      # górne 4 bity
movb  dzielnik(,%rsi,1), %bl  # przepisanie mnożnika

# ascii -> wartość
cmpb  $'9', %bl
jg    litera_1_dzielnik
# konwersja z liczby
subb  $'0', %bl
jmp   next_4bits_dzielnik
litera_1_dzielnik:
subb  $55, %bl
jmp   next_4bits_dzielnik

next_4bits_dzielnik:
decq  %rsi
cmpq  $0, %rsi
jl   wpisz_do_second
movb  dzielnik(,%rsi,1), %cl

cmpb  $'9', %cl
jg    litera_2_dzielnik
# konwersja z liczby
subb  $'0', %cl
jmp   shift_dzielnik
litera_2_dzielnik:
subb  $55, %cl

shift_dzielnik:
shlb  $4, %cl
orb   %cl, %bl

wpisz_do_second:
movb  %bl, second(,%rax,1)
incq  %rax
jmp   przepisanie_dzielnik_loop

# ####################################

# --------------------------------------
# ---------------- MAIN ----------------
# --------------------------------------
.type main_function, @function
main_function:
call    iloraz

# Zapis bufora result_out do result.txt
# ZAPISANIE WYNIKU
# Otwarcie pliku $result.txt do zapisu.
# Jeśli plik nie istnieje, utworzenie go z prawami 666.
pushq   %rsi
movq    $SYSOPEN, %rax
movq    $result_out, %rdi
movq    $FWRITE, %rsi
movq    $0666, %rdx
syscall
# file descriptor dla result.txt
pushq   %rax

# Zapis bufora partial do pliku
movq  %rax, %rdi
movq  $SYSWRITE, %rax
movq  $result, %rsi
movq	8(%rsp), %rdx
syscall

popq  %r10
# Zamknięcie pliku
movq  $SYSCLOSE, %rax
movq  %r10, %rdi
syscall

check:
movq    $EXIT, %rax
movq    $EXIT_SUCCESS, %rdi
syscall


# --------------------------------------
# -------------- ILORAZ ----------------
# --------------------------------------
.type iloraz, @function
iloraz:
pushq   %rbp
movq    %rsp, %rbp

xorq    %r9, %r9                  # rejestr ideksujący
movq    second(,%r9,8), %r14      # R14 - dzielnik

# zaokrąglanie dzielnej do okrągłej liczyby 'quadów'
xorq    %rdx, %rdx                # czyszczenie przed operacją div
movq    dividend_len(,%r9,8), %rax # pobranie długości dzielnej
movq    $8, %rcx
idiv    %rcx                      # dividennd_len / 8
# wynik jest podłogą, bo później jest wykorzystywany jako rejestr ideksujący

# --------------------------------------
# dzielenie: rdx|rax : r14  = rax , rdx
movq    $quotient_buf_len, %r12   # licznik quotient w bajtach(!)
subq    $8, %r12           # cofnięcie się o 8 bajtów (quad)
movq    %rax, %rcx         # maksymalny indeks FIRST
leaq    first, %r8         # adres bufora FIRST
cmpq    $0, %rcx           # koniec dzielenia,
jl      end_iloraz         # gdy indeks FIRST jest ujemny
movq    (%r8,%rcx,8), %rax # pobranie pierwszego quada
decq    %rcx               # dekrementacje licznika quadów FIRST
cmpq    %r14, %rax         # porównanie dzielnika z 1. quadem dzielnej
jae     zacznij_wczesniej  # jge dla usigned liczb
movq    %rax, %rdx         # rdx|rax = 1.quad|2.quad (z bufora FIRST)
jmp     iloraz_loop
zacznij_wczesniej:         # gdy 1. quad FIRST >= dzielnik,
xorq    %rdx, %rdx         # dzielenie rdx|rax = 0|1.quad przez dzielnik
divq    %r14
movq    %rax, quotient(,%r12,)
subq    $8, %r12
# ---
iloraz_loop:
cmpq    $0, %rcx           # gdy dojdziemy do ujemnych indeksów FIRST,
jl      konwersja          # to koniec dzielenia, i konwersja na ASCII
movq    (%r8,%rcx,8), %rax
decq    %rcx
divq    %r14               # reszty z dzielenia rostają w rdx i dokładany jest
movq    %rax, quotient(,%r12,) # tylko następny quad z FIRST do rax
subq    $8, %r12           # po quotient przesuwamy się ciągle po 8 bajtów
jmp     iloraz_loop
# --------------------------------------
# konwersja wyniku liczba -> ASCII
# przepisanie od $quotient_buf_len(w rbx) do r12
# -------
konwersja:
addq    $8, %r12        # cofnięcie ostatniego odejmowania
xorq    %rsi, %rsi      # licznik bufora result
movq    $quotient_buf_len, %rbx
movq    %rbx, %r8       # do usunięcia początkowych zer w wyniku
subq    $8, %r8         # $r8 = 120
hex_loop:
decq    %rbx
cmpq    %r12, %rbx      # sprawdzenie czy dosunęliśmy się do indeksu w R12
jl      end_iloraz
xor     %rcx, %rcx
xor     %rdx, %rdx
movb    quotient(,%rbx,1), %dl # dekodowanie po bajcie
cmpq    %r8, %rbx       # jeśli to pierwszy quad wyniku, to warto
                        # pominąć początkowe zera
jl      just_continue
cmpb    $0, %dl
je      hex_loop        # jeśli to 0, to nie wpisuj
just_continue:
movb    %dl, %cl
shrb    $4, %dl
andb    $0xf, %dl       # 4 górne bity
andb    $0xf, %cl       # 4 dolne bity

cmpb    $9, %cl
jg      cl_to_letter
cl_to_number:
addb    $'0', %cl
jmp     dl_to_ascii
cl_to_letter:
addb    $55, %cl        # konwersja [10;15] na ascii w [A;F]
jmp     dl_to_ascii
dl_to_ascii:
cmpb    $9, %dl
jg      dl_to_letter
dl_to_number:
addb    $'0', %dl
jmp     go_textout
dl_to_letter:
addb    $55, %dl        # konwersja [10;15] na ascii w [A;F]
jmp     go_textout

go_textout:
movb    %dl, result(,%rsi,1)
incq    %rsi
movb    %cl, result(,%rsi,1)
incq    %rsi
jmp     hex_loop

# ####################################
end_iloraz:
movb    $'\n', result(,%rsi,1)
incq    %rsi
movq    %rbp, %rsp
popq    %rbp
ret
