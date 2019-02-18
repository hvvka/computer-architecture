.text
.globl my_rdtsc
.type my_rdtsc, @function

my_rdtsc:
# my_rdtsc(int *val);
# %rax     %rdi
pushq  %rbp
movq   %rsp, %rbp

#movq   16(%rbp),%rax    # pobranie drugiego parametru ze stosu
movq  %rdi, %rsi	 # przekazanie wskaźnika do rsi, używany jako baza

rdtsc                    # włączenie timera

# wynik działa timera zapisywany jest w EDX:EAX
shlq   $32, %rdx	# przesunięcie górnej połowy wyniku
orq    %rdx, %rax	# wynik dzialania w całości w rax
xorq   %rdi, %rdi       # zerowanie rdi do indeksowania

movq   %rax, (%rsi,%rdi,8)	# włożenie wyniku w odpowiednie miejsce w pamięci (przez przekazany wskaźnik)


movq   %rbp, %rsp
popq   %rbp
ret
