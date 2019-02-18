#include <stdio.h>

extern int sprawdz();
extern void ustaw(int);
extern double f_fun(double);
extern double g_fun(double);

int main () {
    
    int precyzja_obliczen, wybor_akcji;
    double x = 0;
    
    do {
        printf("\n\tWybierz akcje.\n");
        printf("\t1. Sprawdz precyzje obliczen.\n");
        printf("\t2. Ustaw wybrana precyzje obliczen.\n");
        printf("\t3. Wywolaj f(x) i g(x).\n");
        printf("\t0. Zakoncz program\n");
        printf("\t>");
        
        scanf("%d", &wybor_akcji);
        
        switch(wybor_akcji) {
            case 1:     //sprawdz precyzje obliczen
                printf("\n\tPrecyzja obliczen: ");
                switch(sprawdz()) {
                    case 0:
                        printf("Single Precision.\n");
                        break;
                    case 2:
                        printf("Double Precision.\n");
                        break;
                    case 3:
                        printf("Double Extended Precison.\n");
                        break;
                }
                break;
            case 2:     //ustaw wybrana precyzje
                printf("\tPodaj precyzje obliczen (0, 2 lub 3): ");
                scanf("%d", &precyzja_obliczen);
                if (precyzja_obliczen != 0 && precyzja_obliczen != 2 && precyzja_obliczen != 3) {
                    printf("\n\tPodano zla precyzje!\n");
                }
                else ustaw(precyzja_obliczen);
                break;
            case 3:
                printf("\n\tPodaj arguemnt do funkcji: ");
                scanf("%lf", &x);
                printf("\tf(x): %.18lf\n", f_fun(x));       // f(x) = sqrt(x^2 + 1) - 1
                printf("\tg(x): %.18lf\n", g_fun(x));       // g(x) = x^2 / sqrt(x^2 + 1) + 1
                break;
        }
    } while (wybor_akcji != 0);
    
    printf("\n\nKoniec programu.\n\n");
    
    return 0;
}
