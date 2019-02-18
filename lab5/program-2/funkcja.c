#include <stdio.h>

extern double taylor(double, int);

int main()
{
    int liczba_wyrazow;
    double kat_rad;
    
    printf("\nKat w radianach: ");
    scanf("%lf", &kat_rad);
    
    printf("Liczba krokow: ");
    scanf("%d", &liczba_wyrazow);
    
    printf("\nWynik: %lf\n\n", taylor(kat_rad, liczba_wyrazow));
    
    return 0;
}
