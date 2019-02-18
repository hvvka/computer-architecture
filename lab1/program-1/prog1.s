#LABORATORIUM 1
#Program 1

.data
STDIN = 0
STDOUT = 1
SYSWRITE = 1
SYSREAD = 0
SYSEXIT = 60
EXIT_SUCCESS = 0
BUFLEN = 512

.bss
.comm textin, 512
.comm textout, 512

.text
.globl _start

_start:
movq $SYSREAD, %rax
movq $STDIN, %rdi
movq $textin, %rsi
movq $BUFLEN, %rdx
syscall

dec %rax		#'\n' <- nie wiem jak to działa
movl $0, %edi		#licznik


funkcja_ktora_nie_dziala:
movb textin(, %edi, 1), %bl	#wprowadza jeden znak (bajt) do rejestru bl

movb $'A', %bh          #powinno wprowadzić kod ascii litery 'A' do bh
cmp  %bh, %bl		#sprawdzanie czy to wielka litera
jl   czy_to_cyfra	#skok, jeśli mniejsza niż (dec)65 w ascii

movb $'Z', %bh		#powinno wprowadzić kod ascii litery 'Z' do bh
cmp  %bh, %bl
jg   wypisz		#skok, jeśli większa niż (dec)90 w ascii

add $3, %bl		#dodanie stałej wartości 3 do bl
jmp wypisz


czy_to_cyfra:
movb $'0', %bh		#wprowadza kod znaku '0' z ascii do bh
cmp  %bh, %bl		#sprawdzanie czy to cyfra
jl   wypisz		#skok, jeśli mniejsza niż (dec)48 w ascii

movb $'9', %bh		#wprowadza kod znaku '9' z ascii do bh
cmp  %bh, %bl
jg   wypisz		#skok, jeśli większa niż (dec)57 w ascii

add $5, %bl		#dodanie stałej wartości 5 do bl

wypisz:
movb %bl, textout(, %edi, 1)
inc %edi		#przejście do następnego znaku z bufora
cmp %eax, %edi		#chyba sprawdza czy to '\n' <- nie wiem
jl funkcja_ktora_nie_dziala 	#pobranie kolejnego znaku

movb $'\n', textout(, %edi, 1)

movq $SYSWRITE, %rax
movq $STDOUT, %rdi
movq $textout, %rsi
movq $BUFLEN, %rdx
syscall

movq $SYSEXIT, %rax
movq $EXIT_SUCCESS, %rdi
syscall


####ASCII####
#A = 65
#Z = 90
#a = 97
#z = 122
#0 = 48
#9 = 57
