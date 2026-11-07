.model small
.stack 100h
.386

.data
    fib0 dq 0,0,0,0,0,0,0,0 ; 64 字节滚动数组存迭代法斐波那契数列，最高支持第 739 项
    fib1 dq 1,0,0,0,0,0,0,0 ; 小端序：fib(1) = 1 应存在地址偏移量为 0 处
    hint db 'The input number n is too large. Only numbers n less than 739 are supported.', 0Dh, 0Ah, '$'

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
    call fib
    test cx, 1
    jnz print_odd

print_even:
    lea si, fib0
    jmp do_print

print_odd:
    lea si, fib1

do_print:
    call print_high_precision

    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov dl, 0Ah
    mov ah, 02h
    int 21h

    mov ah, 4Ch
    int 21h
main endp

fib proc                ; 输入 cx = n，输出在 fib0 和 fib1
    cmp cx, 1
    jle fib_definition
    cmp cx, 739
    jg  fib_unsupported

    push ax
    push cx
    push si
    push di

    mov ax, 2
    dec cx

fib_loop:
    test al, 1
    jnz fib_odd

fib_even:
    lea si, fib1
    lea di, fib0
    call add_high_precision
    jmp fib_next

fib_odd:
    lea si, fib0
    lea di, fib1
    call add_high_precision

fib_next:
    inc ax
    loop fib_loop

    pop di
    pop si
    pop cx
    pop ax

fib_definition:
    ret

fib_unsupported:
    lea dx, hint
    mov ah, 09h
    int 21h
    mov ah, 4Ch
    int 21h
fib endp

add_high_precision proc
    push eax
    push cx
    push si
    push di

    mov cx, 16
    clc                 ; 清除进位标志以备加法

add_loop:
    mov eax, [si]
    adc [di], eax       ; 利用并行性，每次加 32 位
    lea si, [si+4]      ; lea 不影响 CF
    lea di, [di+4]
    loop add_loop       ; loop 不影响 CF

    pop di
    pop si
    pop cx
    pop eax
    ret
add_high_precision endp

print_high_precision proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov bp, si          ; 保存数组首地址
    mov ebx, 10
    xor di, di          ; di = 当前累计的十进制位数计数

div_loop:
    mov si, bp
    add si, 60          ; 从最高位开始除
    mov cx, 16
    xor edx, edx        ; 清空 dx，初始余数 = 0，准备 dx:ax / bx

div_inner:
    mov eax, [si]
    div ebx             ; dx:ax / 10 -> ax = 商，dx = 余数
    mov [si], eax
    sub si, 4
    loop div_inner

    push dx             ; 保存本轮余数，压在栈里
    inc di              ; 位数 + 1
    mov si, bp
    mov cx, 16
    xor eax, eax

check_zero:             ; 检查商是否已经全零
    or eax, [si]
    add si, 4
    loop check_zero

    test eax, eax
    jnz div_loop        ; 商非零则继续

    mov cx, di
print_loop:
    pop dx
    add dl, '0'         ; 余数转 ASCII
    mov ah, 02h
    int 21h
    loop print_loop

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_high_precision endp

end main