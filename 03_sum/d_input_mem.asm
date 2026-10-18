.model small
.stack 100h

.data
    sum       dd 0

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
    push ax
    mov ax, cx
    mov dx, 10
    mul dx
    mov cx, ax
    pop ax
    add cx, ax
    jmp read_loop

read_done:
    xor bx, bx
    inc cx

sum_loop32:
    add WORD PTR sum, bx
    adc WORD PTR sum+2, 0
    inc bx
    loop sum_loop32

    mov bx, 10
    xor cx, cx

div_loop32:
    mov ax, WORD PTR sum+2
    xor dx, dx
    div bx
    mov WORD PTR sum+2, ax
    mov ax, WORD PTR sum
    div bx
    mov WORD PTR sum, ax
    push dx
    inc cx
    or  ax, WORD PTR sum+2
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