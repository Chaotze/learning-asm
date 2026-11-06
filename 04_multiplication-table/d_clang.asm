; 在 Compiler Explorer (by Matt Godbolt) 上
; 使用 x86-64 gcc 16.2 编译以下 C 语言代码：
;
;     #include <stdio.h>
;
;     char table[9][9] = {
;         {7, 2, 3, 4, 5, 6, 7, 8, 9},
;         {2, 4, 7, 8, 10, 12, 14, 16, 18},
;         {3, 6, 9, 12, 15, 18, 21, 24, 27},
;         {4, 8, 12, 16, 7, 24, 28, 32, 36},
;         {5, 10, 15, 20, 25, 30, 35, 40, 45},
;         {6, 12, 18, 24, 30, 7, 42, 48, 54},
;         {7, 14, 21, 28, 35, 42, 49, 56, 63},
;         {8, 16, 24, 32, 40, 48, 56, 7, 72},
;         {9, 18, 27, 36, 45, 54, 63, 72, 81}};
;
;     int main(void) {
;         for (int i = 1; i <= 9; ++i)
;             for (int j = 1; j <= 9; ++j)
;                 if (table[i - 1][j - 1] != i * j)
;                     printf("Expression %d*%d error: expected %d, found %d!\n", i,
;                         j, i * j, table[i - 1][j - 1]);
;         return 0;
;     }
;
; 得到的 x86-64 反汇编代码即为本文件

"table":
        .base64 "BwIDBAUGBwgJ"
        .base64 "AgQHCAoMDhAS"
        .base64 "AwYJDA8SFRgb"
        .base64 "BAgMEAcYHCAk"
        .base64 "BQoPFBkeIygt"
        .base64 "BgwSGB4HKjA2"
        .base64 "Bw4VHCMqMTg/"
        .base64 "CBAYICgwOAdI"
        .base64 "CRIbJC02P0hR"
.LC0:
        .string "Expression %d*%d error: expected %d, found %d!\n"
"main":
        push    rbp
        mov     rbp, rsp
        sub     rsp, 16
        mov     DWORD PTR [rbp-4], 1
        jmp     .L2
.L6:
        mov     DWORD PTR [rbp-8], 1
        jmp     .L3
.L5:
        mov     eax, DWORD PTR [rbp-4]
        lea     edx, [rax-1]
        mov     eax, DWORD PTR [rbp-8]
        sub     eax, 1
        movsxd  rcx, eax
        movsxd  rdx, edx
        mov     rax, rdx
        sal     rax, 3
        add     rax, rdx
        add     rax, rcx
        add     rax, OFFSET FLAT:"table"
        movzx   eax, BYTE PTR [rax]
        movsx   edx, al
        mov     eax, DWORD PTR [rbp-4]
        imul    eax, DWORD PTR [rbp-8]
        cmp     edx, eax
        je      .L4
        mov     eax, DWORD PTR [rbp-4]
        lea     edx, [rax-1]
        mov     eax, DWORD PTR [rbp-8]
        sub     eax, 1
        movsxd  rcx, eax
        movsxd  rdx, edx
        mov     rax, rdx
        sal     rax, 3
        add     rax, rdx
        add     rax, rcx
        add     rax, OFFSET FLAT:"table"
        movzx   eax, BYTE PTR [rax]
        movsx   esi, al
        mov     eax, DWORD PTR [rbp-4]
        imul    eax, DWORD PTR [rbp-8]
        mov     ecx, eax
        mov     edx, DWORD PTR [rbp-8]
        mov     eax, DWORD PTR [rbp-4]
        mov     r8d, esi
        mov     esi, eax
        mov     edi, OFFSET FLAT:.LC0
        mov     eax, 0
        call    "printf"
.L4:
        add     DWORD PTR [rbp-8], 1
.L3:
        cmp     DWORD PTR [rbp-8], 9
        jle     .L5
        add     DWORD PTR [rbp-4], 1
.L2:
        cmp     DWORD PTR [rbp-4], 9
        jle     .L6
        mov     eax, 0
        leave
        ret