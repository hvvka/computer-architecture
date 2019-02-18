.data
control_word:   .short 0      #2 bajty (16 bitów)
# Precision Control: bity 8 i 9 w control word
single_precision: .short 0x0000
clear_precision:  .short 0xFCFF
double_precision: .short 0x0200
double_extended:  .short 0x0300

.text

.global ustaw,   sprawdz
.type   ustaw,   @function
.type   sprawdz, @function

#   sprawdz ();
#   %rax
sprawdz:
pushq   %rbp
movq    %rsp, %rbp

# Pobranie słowa kontrolnego FPU do rejestru %ax
movq    $0, %rax
fstcw   control_word        #zapisanie zawartości słowa kontrolnego do pamięci
fwait                       #wait for FPU/check for and handle pending unmasked x87 FPU exceptions
                            #synchronization instruction
movw    control_word, %ax   #przeniesienie do rejestru ogólnego przeznaczenia

# Wyzerowanie pozostałych bitów poza bitami kontroli precyzji
# i przesunięcie wygenerowanych bitów w prawo na koniec
andw    $0x300, %ax # 0000 0011 0000 0000
shrw    $8, %ax
# Wartość zwracana znajduje się już w EAX. Przyjmuje wartości:
# 0 dla single, 2 dla double i 3 dla extended

movq    %rbp, %rsp
popq    %rbp
ret


#   ustaw (prezycja_obliczen);
#   %rax    %rdi
ustaw:
    pushq   %rbp
    movq    %rsp, %rbp      #standardowe operacje na stosie

    # if(precyzja_obliczen == 0) single
    # if(precyzja_obliczen == 2) double
    # if(precyzja_obliczen == 3) extended double

    # Pobranie zawartości rejestru kontrolnego do rejestru AX
    # przez komórkę w pamięci

    movq    $0, %rax
    fstcw   control_word
    fwait
    movw    control_word, %ax

#Tryb pracy jednostki ustawia się za pomocą 16-bitowego słowa sterującego FPU (FPU Control Word), za precyzję odpowiadają bity 8 i 9, za zaokrąglanie 10 i 11 - dokładnie jest to opisane w instrukcji Intela.

    # wyzerowanie bitów kontroli prezycji
    andw    $0xFCFF, %ax     #w tym momencie bity precyzji to 00 (single precision)

    cmp     $2, %rdi
    jl      end
    je      set_double

    #jg
    set_extended:
    xorw    $double_extended, %ax
    jmp     koniec

    set_double:
    xorw    $double_precision, %ax

    end:
    movw    %ax, control_word
    fldcw   control_word

    movq    %rbp, %rsp
    popq    %rbp
    ret
