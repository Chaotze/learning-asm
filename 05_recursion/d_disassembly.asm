"fib":                                  ; 全局数组 __int128 fib[2]，共 2 * 16 = 32 字节
        .zero   32                      ; 清零 32 字节（.bss 段，fib[0] = fib[1] = 0）
.LC0:
        .string "%d"                    ; scanf 格式串
.LC1:
        .string "%d\n"                  ; printf 格式串
"main":
        push    rbp                     ; 保存调用者的帧指针
        mov     rbp, rsp                ; 建立 main 的栈帧
        push    rbx                     ; 保存 rbx（被调用者保存寄存器，后面会用到）
        sub     rsp, 24                 ; 分配 24 字节局部空间（存放 n 和循环变量 i）
        mov     QWORD PTR "fib"[rip+16], 1  ; fib[1] 的低 64 位 = 1
        mov     QWORD PTR "fib"[rip+24], 0  ; fib[1] 的高 64 位 = 0
                                            ; 即 fib[1] = 1（__int128，两个 qword 组成）
        lea     rax, [rbp-24]           ; rax = &n（n 位于 [rbp-24]）
        mov     rsi, rax                ; scanf 第二个参数：&n
        mov     edi, OFFSET FLAT:.LC0   ; scanf 第一个参数：格式串 "%d"
        mov     eax, 0                  ; 可变参数函数调用约定：eax = 0
        call    __isoc23_scanf          ; 调用 scanf("%d", &n)
        mov     DWORD PTR [rbp-20], 2   ; 循环变量 i = 2（对应 for (int i = 2; ...)）
        jmp     .L2                     ; 跳到循环条件判断
.L3:                                    ; 循环体：fib[i & 1] = fib[0] + fib[1]
        mov     rcx, QWORD PTR "fib"[rip]       ; rcx = fib[0] 的低 64 位
        mov     rbx, QWORD PTR "fib"[rip+8]     ; rbx = fib[0] 的高 64 位
        mov     rax, QWORD PTR "fib"[rip+16]    ; rax = fib[1] 的低 64 位
        mov     rdx, QWORD PTR "fib"[rip+24]    ; rdx = fib[1] 的高 64 位
                                                ; 此时 (rdx:rax) = fib[1]，(rbx:rcx) = fib[0]
        mov     esi, DWORD PTR [rbp-20] ; esi = i
        and     esi, 1                  ; esi = i & 1（下标 0 或 1）
        add     rax, rcx                ; 低 64 位相加：rax = fib[1].lo + fib[0].lo
        adc     rdx, rbx                ; 高 64 位带进位相加：rdx = fib[1].hi + fib[0].hi + CF
                                        ; 至此 (rdx:rax) = fib[0] + fib[1]（128 位结果）
        movsxd  rcx, esi                ; rcx = (符号扩展)(i & 1)，即目标下标
        sal     rcx, 4                  ; rcx = 下标 * 16（__int128 每个元素 16 字节）
        add     rcx, OFFSET FLAT:"fib"  ; rcx = &fib[i & 1]
        mov     QWORD PTR [rcx], rax    ; 存低 64 位
        mov     QWORD PTR [rcx+8], rdx  ; 存高 64 位
                                        ; 完成 fib[i & 1] = fib[0] + fib[1]
        add     DWORD PTR [rbp-20], 1   ; ++i
.L2:                                    ; 循环条件判断
        mov     eax, DWORD PTR [rbp-24] ; eax = n
        cmp     DWORD PTR [rbp-20], eax ; 比较 i 与 n
        jle     .L3                     ; if (i <= n) 继续循环
        mov     eax, DWORD PTR [rbp-24] ; eax = n
        and     eax, 1                  ; eax = n & 1
        cdqe                            ; 符号扩展到 64 位
        sal     rax, 4                  ; rax = (n & 1) * 16
        add     rax, OFFSET FLAT:"fib"  ; rax = &fib[n & 1]
        mov     rdx, QWORD PTR [rax+8]  ; rdx = 结果的高 64 位
        mov     rax, QWORD PTR [rax]    ; rax = 结果的低 64 位
                                        ; 此时 (rdx:rax) = fib[n & 1]，即 __int128 返回值
        mov     rcx, rax                ; rcx = 低 64 位
        mov     rax, rdx                ; rax = 高 64 位
        mov     rsi, rcx                ; rsi = 低 64 位
        mov     rdx, rax                ; rdx = 高 64 位
                                        ; printf 传参：esi/edx 依次传 __int128 的低/高 64 位
        mov     edi, OFFSET FLAT:.LC1   ; printf 第一个参数：格式串 "%d\n"
        mov     eax, 0                  ; 可变参数函数调用约定：eax = 0
        call    "printf"                ; 调用 printf("%d\n", fib[n & 1])
        mov     eax, 0                  ; main 返回 0
        mov     rbx, QWORD PTR [rbp-8]  ; 恢复 rbx（与前面 push rbx 对应）
        leave                           ; 销毁 main 的栈帧
        ret                             ; 返回调用者