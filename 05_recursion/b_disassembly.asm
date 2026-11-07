"fib(int)":
        push    rbp                     ; 保存调用者的帧指针（建立新栈帧）
        mov     rbp, rsp                ; rbp = 当前栈顶，作为本函数的帧基址
        push    rbx                     ; 保存 rbx（被调用者保存寄存器，后面会借用它存中间结果）
        sub     rsp, 24                 ; 在栈上分配 24 字节局部空间（对齐 + 存放参数 n）
        mov     DWORD PTR [rbp-20], edi ; 把第一个参数 n（edi）存到局部变量 [rbp-20]
        cmp     DWORD PTR [rbp-20], 0   ; 比较 n 与 0
        je      .L2                     ; if (n == 0) 跳转到 .L2（返回 n）
        cmp     DWORD PTR [rbp-20], 1   ; 比较 n 与 1
        jne     .L3                     ; if (n != 1) 跳转到 .L3（递归分支）
.L2:                                    ; 进入条件：n == 0 或 n == 1
        mov     eax, DWORD PTR [rbp-20] ; eax = n（返回值就是 n 本身）
        jmp     .L4                     ; 跳过递归分支，前往函数收尾
.L3:                                    ; 递归分支：return fib(n-1) + fib(n-2)
        mov     eax, DWORD PTR [rbp-20] ; eax = n
        sub     eax, 1                  ; eax = n - 1
        mov     edi, eax                ; 第一个参数 edi = n - 1
        call    "fib(int)"              ; 调用 fib(n-1)，返回值在 eax
        mov     ebx, eax                ; 把 fib(n-1) 暂存到 ebx
        mov     eax, DWORD PTR [rbp-20] ; eax = n
        sub     eax, 2                  ; eax = n - 2
        mov     edi, eax                ; 第一个参数 edi = n - 2
        call    "fib(int)"              ; 调用 fib(n-2)，返回值在 eax
        add     eax, ebx                ; eax = fib(n-2) + fib(n-1)，即最终返回值
.L4:                                    ; 函数收尾（返回 eax 中的值）
        mov     rbx, QWORD PTR [rbp-8]  ; 恢复 rbx（与前面 push rbx 对应）
        leave                           ; 等价于 mov rsp, rbp; pop rbp，销毁栈帧
        ret                             ; 返回调用者
.LC0:
        .string "%d"                    ; scanf 的格式串
.LC1:
        .string "%d\n"                  ; printf 的格式串
"main":
        push    rbp                     ; 保存调用者的帧指针
        mov     rbp, rsp                ; 建立 main 的栈帧
        sub     rsp, 16                 ; 分配 16 字节局部空间（存放局部变量 n）
        lea     rax, [rbp-4]            ; rax = &n（n 位于 [rbp-4]）
        mov     rsi, rax                ; scanf 第二个参数：&n
        mov     edi, OFFSET FLAT:.LC0   ; scanf 第一个参数：格式串 "%d"
        mov     eax, 0                  ; 可变参数函数调用约定：eax = 0（无向量参数）
        call    __isoc23_scanf          ; 调用 scanf("%d", &n)
        mov     eax, DWORD PTR [rbp-4]  ; eax = n（读取输入的 n）
        mov     edi, eax                ; 第一个参数 edi = n
        call    "fib(int)"              ; 调用 fib(n)，返回值在 eax
        mov     esi, eax                ; printf 第二个参数：fib(n) 的结果
        mov     edi, OFFSET FLAT:.LC1   ; printf 第一个参数：格式串 "%d\n"
        mov     eax, 0                  ; 可变参数函数调用约定：eax = 0
        call    "printf"                ; 调用 printf("%d\n", fib(n))
        mov     eax, 0                  ; main 返回 0
        leave                           ; 销毁 main 的栈帧
        ret                             ; 返回调用者