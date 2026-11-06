.model small
.stack 100h
.386

.data
    table   db 7,2,3,4,5,6,7,8,9
            db 2,4,7,8,10,12,14,16,18
            db 3,6,9,12,15,18,21,24,27
            db 4,8,12,16,7,24,28,32,36
            db 5,10,15,20,25,30,35,40,45
            db 6,12,18,24,30,7,42,48,54
            db 7,14,21,28,35,42,49,56,63
            db 8,16,24,32,40,48,56,7,72
            db 9,18,27,36,45,54,63,72,81
    pt0     db 'Expression ', '$'
    pt1     db ' error: expected ', '$'
    pt2     db ', found ', '$'
    pt3     db '!', 0Dh, 0Ah, '$'

.code
main proc
    mov ax, @data
    mov ds, ax

    mov cx, 1

table_loop:
    call check_row
    inc cx
    cmp cx, 9
    jle table_loop

    mov ah, 4Ch
    int 21h
main endp

check_row proc
    push ax
    push bx
    push di

    mov di, 1

row_loop:
    mov ax, cx
    mul di
    mov bx, ax
    call check_exp
    inc di
    cmp di, 9
    jle row_loop

    pop di
    pop bx
    pop ax
    ret
check_row endp

check_exp proc
    push ax
    push cx
    push di
    push si

    dec cx
    mov ax, cx
    shl ax, 3
    add ax, cx          ; 左移 3 位再加自身，即 * 9
    dec di
    add ax, di
    mov si, ax
    cmp bl, table[si]
    je done
    call throw_exp

done:
    pop si
    pop di
    pop cx
    pop ax
    ret
check_exp endp

throw_exp proc
    push ax
    push cx
    push dx
    push di

    lea dx, pt0
    mov ah, 09h
    int 21h

    inc cx
    mov ax, cx
    call print_num

    mov dl, '*'
    mov ah, 02h
    int 21h

    inc di
    mov ax, di
    call print_num

    lea dx, pt1
    mov ah, 09h
    int 21h

    mov ax, bx
    call print_num

    lea dx, pt2
    mov ah, 09h
    int 21h

    xor ax, ax
    mov al, table[si]
    call print_num

    lea dx, pt3
    mov ah, 09h
    int 21h

    pop di
    pop dx
    pop cx
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