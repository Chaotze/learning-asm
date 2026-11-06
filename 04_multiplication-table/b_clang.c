#include <stdio.h>
int main() {
    for (int i = 9; i; --i) {
        for (int j = 1; j <= i; ++j) printf("%d*%d=%d ", i, j, i * j);
        puts("");
    }
    return 0;
}
