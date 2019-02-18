#include <stdio.h>
#include <stdbool.h>

int fun(int x, float y, bool z) {
    if(z)
        return x*x*x + y*y*y;
    else
        return x*x + y*y;
}
