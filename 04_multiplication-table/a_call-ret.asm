.model small
.stack 100h

.code
main proc
    mov cx, 9

table_loop:
    call check_row
    loop table_loop

    mov ah, 4Ch
    int 21h
main endp

check_row proc
    push ax
    push bx
    push cx
    push dx
    push di

    mov di, 1

row_loop:
    mov ax, cx
    mul di
    mov bx, ax
    call throw_exp
    inc di
    loop row_loop

    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov dl, 0Ah
    mov ah, 02h
    int 21h

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
check_row endp

throw_exp proc
    push ax
    push dx

    mov ax, cx
    call print_num

    mov dl, '*'
    mov ah, 02h
    int 21h

    mov ax, di
    call print_num

    mov dl, '='
    mov ah, 02h
    int 21h

    mov ax, bx
    call print_num

    mov dl, ' '
    mov ah, 02h
    int 21h

    pop dx
    pop ax
    ret
throw_exp endp

print_num proc
    push ax
    push bx
    push cx
    push dx

    mov bx, 10
    xor cx, cx

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
print_num endp

end main