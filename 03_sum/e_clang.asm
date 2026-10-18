; 在 Compiler Explorer (by Matt Godbolt) 上
; 使用 x86-64 gcc 16.2 编译以下 C 语言代码：
;
;     #include <stdio.h>
;     int main() {
;         int n, sum = 0;
;         scanf("%d", &n);
;         for (int i = 1; i <= n; ++i) sum += i;
;         printf("%d", sum);
;         return 0;
;     }
;
; 得到的 x86-64 反汇编代码即为本文件

.LC0:
    .string '%d'                    ; 定义格式字符串 "%d"，用于 scanf 和 printf
"main":                             ; main 函数入口
    push    rbp                     ; 保存调用者栈帧基址 rbp
    mov     rbp, rsp                ; 建立当前函数栈帧：rbp = rsp
    sub     rsp, 16                 ; 在栈上分配 16 字节局部变量空间
    mov     DWORD PTR [rbp-4], 0    ; sum = 0        （[rbp-4] 对应 sum）
    lea     rax, [rbp-12]           ; rax = &n       （[rbp-12] 对应 n）
    mov     rsi, rax                ; scanf 第 2 个参数：&n
    mov     edi, OFFSET FLAT:.LC0   ; scanf 第 1 个参数：格式串 "%d"
    mov     eax, 0                  ; 可变参数函数调用前 eax=0（无向量寄存器参数）
    call    __isoc23_scanf          ; 调用 scanf("%d", &n)
    mov     DWORD PTR [rbp-8], 1    ; i = 1          （[rbp-8] 对应 i）
    jmp     .L2                     ; 跳转到循环条件判断
.L3:                                ; 循环体开始
    mov     eax, DWORD PTR [rbp-8]  ; eax = i
    add     DWORD PTR [rbp-4], eax  ; sum += i
    add     DWORD PTR [rbp-8], 1    ; ++i
.L2:                                ; 循环条件判断
    mov     eax, DWORD PTR [rbp-12] ; eax = n
    cmp     DWORD PTR [rbp-8], eax  ; 比较 i 与 n
    jle     .L3                     ; 若 i <= n，跳转回循环体 .L3
    mov     eax, DWORD PTR [rbp-4]  ; eax = sum
    mov     esi, eax                ; printf 第 2 个参数：sum
    mov     edi, OFFSET FLAT:.LC0   ; printf 第 1 个参数：格式串 "%d"
    mov     eax, 0                  ; 可变参数函数调用前 eax=0
    call    __isoc23_printf         ; 调用 printf("%d", sum)
    mov     eax, 0                  ; 返回值 0
    leave                           ; 恢复栈帧：rsp = rbp，pop rbp
    ret                             ; 返回