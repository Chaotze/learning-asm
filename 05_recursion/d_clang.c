#include <stdio.h>
__int128 fib[2];
int main() {
    int n;
    fib[1] = 1;
    scanf("%d", &n);
    for (int i = 2; i <= n; ++i) fib[i & 1] = fib[0] + fib[1];
    printf("%d\n", fib[n & 1]);
    return 0;
}
