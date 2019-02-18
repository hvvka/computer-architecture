#include <stdio.h>
#include <math.h>

extern double cosinus(double, int);

double taylor(double, int);

int main()
{
    int liczba_wyrazow;
    double kat_rad;
    
    int wybor = 0;
    printf("\nKat bedzie podany w:\n1. Radianach\n2. Stopniach\n>");
    scanf("%d", &wybor);
    switch(wybor) {
        case 1:
            printf("\nKat w radianach: ");
            scanf("%lf", &kat_rad);
            break;
        case 2:
            printf("\nKat w stopniach: ");
            scanf("%lf", &kat_rad);
            kat_rad = kat_rad * M_PI / 180;
            break;
    }
    
    printf("Liczba krokow: ");
    scanf("%d", &liczba_wyrazow);
    
    printf("\nWynik cosinus(asm): %lf\n", cosinus(kat_rad, liczba_wyrazow));
    
    printf("Wynik taylor(C): %lf\n\n", taylor(kat_rad, liczba_wyrazow));
    
    return 0;
}


double taylor(double x, int liczba_wyrazow) {
    double wyraz = 1, kwadrat = x*x, suma = 1;
    int n = 1;
    
    while(n < liczba_wyrazow)
    {
        wyraz *= -kwadrat/((2*n - 1) * 2*n);
        n++;
        suma += wyraz;
    }
    return suma;
}
