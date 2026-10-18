.model small
.stack 100h

.code
main proc
    xor cx, cx          ; cx 用来累积输入的数值，初始为 0，后续就作为循环计数器

read_loop:
    mov ah, 01h         ; 从键盘读一个字符并回显
    int 21h
    cmp al, 0Dh         ; 遇到回车（CR）就结束输入
    je  read_done
    cmp al, '0'
    jb  read_loop       ; 非数字字符，忽略
    cmp al, '9'
    ja  read_loop
    sub al, '0'         ; 转成数值 0~9
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
    xor ax, ax          ; 累加器清零
    xor bx, bx          ; 加数从零开始，避免输入零时出错
    inc cx              ; 相应地，循环次数加一

sum_loop:
    add ax, bx
    inc bx
    loop sum_loop

    mov bx, 10
    xor cx, cx

div_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz div_loop

print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_loop

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