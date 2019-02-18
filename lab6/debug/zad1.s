.text

.globl my_rdtsc

.type my_rdtsc, @function



my_rdtsc:

# my_rdtsc(int *val);



pushq  %rbp

movq   %rsp, %rbp



#movq   16(%rbp),%rax    # pobranie drugiego parametru ze stosu

movq  %rdi, %rax



movq   %rax, %rsi

rdtsc                   # włączenie timera

movq   %rax, %rdx

movq   %rsi, %rax

xorq   %rdi, %rdi       # zerowanie rdi



movl   %edx, (%rax,%rdi,4)



movq   %rbp, %rsp

popq   %rbp

ret

