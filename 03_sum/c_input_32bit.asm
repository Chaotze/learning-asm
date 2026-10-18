.model small
.stack 100h

.code
main proc
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
    push ax
    mov ax, cx
    mov dx, 10
    mul dx
    mov cx, ax
    pop ax
    add cx, ax
    jmp read_loop

read_done:
    xor ax, ax
    xor dx, dx
    xor bx, bx
    inc cx

sum_loop32:
    add ax, bx
    adc dx, 0               ; dx 存高位
    inc bx
    loop sum_loop32

    ; 反复做 (dx:ax) / 10，商回存 dx:ax，余数压栈；
    ; 32bit / 16bit，div bx 要求被除数为 dx:ax，
    ; 每轮开始时 dx 必须是上一轮的余数（初始为 0），
    ; 所以不能像 16 位版本那样每轮清 dx，而是要让上一轮余数接力
    mov bx, 10
    xor cx, cx

div_loop32:                 ; 这是一种对被除数先除高 16 位，再除低 16 位的做法
    mov si, ax              ; 保存低 16 位
    mov ax, dx              ; ax 放入高 16 位
    xor dx, dx
    div bx                  ; ax = Q1, dx = R1
    mov di, ax              ; di = Q1
    mov ax, si              ; ax = 原低 16 位
    div bx                  ; dx:ax / 10 ( dx = R1), ax = Q2, dx = R2
    push dx                 ; 本轮余数 R2 才是我们要模出的那一位
    inc cx
    mov dx, di              ; 新商 =  di:ax
    mov si, ax
    or  si, dx
    jnz div_loop32

print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_loop

print_newline:
    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov dl, 0Ah
    mov ah, 02h
    int 21h

    mov ah, 4Ch
    int 21h
main endp
end main