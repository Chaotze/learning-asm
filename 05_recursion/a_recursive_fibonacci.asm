.model small
.stack 400h             ; 栈空间估算：计算 Fibonacci(100)，即递归深度 100 层
                        ; 每次 push 一个字需要 2 字节，每层 push 三五个寄存器
                        ; 则 2 * 5 * 100 = 1000，预留 1024 字节

.data
    hint db 'The input number n is too large. Only numbers n less than 20 are supported.', 0Dh, 0Ah, '$'

.code
main proc
    mov ax, @data
    mov ds, ax
    xor cx, cx

read_loop:
    mov ah, 01h
    int 21h
    cmp al, 0Dh
    je  read_done
    cmp al, '0'
    jb  read_loop
    cmp al, '9'
    ja  read_loop
    sub al, '0'
    xor ah, ah
    mov bx, ax          ; 暂存当前数字
    mov ax, cx
    mov dx, 10
    mul dx              ; dx:ax = cx * 10
    add ax, bx          ; ax += digit
    mov cx, ax          ; 存回去，供下一个数字使用
    jmp read_loop

read_done:
    mov ax, cx
    call fib            ; 结果在 ax
    call print

    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov dl, 0Ah
    mov ah, 02h
    int 21h

    mov ah, 4Ch
    int 21h
main endp

fib proc                ; 输入 ax = n，输出 ax = fib(n)
    cmp ax, 0
    je  fib_zero
    cmp ax, 1
    je  fib_one
    cmp ax, 20
    jg  fib_unsupported

    push bx
    push cx

    mov bx, ax
    dec ax              ; ax = n-1
    call fib
    mov cx, ax          ; cx = fib(n-1)

    mov ax, bx
    sub ax, 2           ; ax = n-2
    call fib
    add ax, cx          ; ax = fib(n-2) + fib(n-1)

    pop cx
    pop bx
    ret

fib_zero:
    xor ax, ax
    ret

fib_one:
    mov ax, 1
    ret

fib_unsupported:
    lea dx, hint
    mov ah, 09h
    int 21h
    mov ah, 4Ch
    int 21h
fib endp

print proc
    push ax
    push bx
    push cx
    push dx

    mov bx, 10
    xor cx, cx          ; 位数计数

div_loop:
    xor dx, dx          ; 清空 dx，准备 dx:ax / bx
    div bx              ; ax = 商，dx = 余数
    push dx             ; 余数压栈
    inc cx
    test ax, ax
    jnz div_loop

print_loop:
    pop dx
    add dl, '0'         ; 余数转 ASCII
    mov ah, 02h
    int 21h
    loop print_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret
print endp

end main