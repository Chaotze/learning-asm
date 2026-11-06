; 在 Compiler Explorer (by Matt Godbolt) 上
; 使用 x86-64 gcc 16.2 编译以下 C 语言代码：
;
;     #include <stdio.h>
;     int main() {
;         for (int i = 9; i; --i) {
;             for (int j = 1; j <= i; ++j) printf("%d*%d=%d ", i, j, i * j);
;             puts("");
;         }
;         return 0;
;     }
;
; 得到的 x86-64 反汇编代码即为本文件

.LC0:
        .string "%d*%d=%d "
.LC1:
        .string ""
"main":
        push    rbp
        mov     rbp, rsp
        sub     rsp, 16
        mov     DWORD PTR [rbp-4], 9
        jmp     .L2
.L5:
        mov     DWORD PTR [rbp-8], 1
        jmp     .L3
.L4:
        mov     eax, DWORD PTR [rbp-4]
        imul    eax, DWORD PTR [rbp-8]
        mov     ecx, eax
        mov     edx, DWORD PTR [rbp-8]
        mov     eax, DWORD PTR [rbp-4]
        mov     esi, eax
        mov     edi, OFFSET FLAT:.LC0
        mov     eax, 0
        call    "printf"
        add     DWORD PTR [rbp-8], 1
.L3:
        mov     eax, DWORD PTR [rbp-8]
        cmp     eax, DWORD PTR [rbp-4]
        jle     .L4
        mov     edi, OFFSET FLAT:.LC1
        call    "puts"
        sub     DWORD PTR [rbp-4], 1
.L2:
        cmp     DWORD PTR [rbp-4], 0
        jne     .L5
        mov     eax, 0
        leave
        ret