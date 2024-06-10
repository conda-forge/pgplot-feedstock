#include <pgplot/cpgplot.h>

int
main(int argc, char **argv)
{
    if (cpgopen("/NULL") <= 0)
        return 1;
    cpgclos();
    return 0;
}