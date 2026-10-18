.model small
.stack 100h

.code
main proc
    xor ax, ax          ; 清空累加器。清零用 xor 而不是 mov，代码更短，CPU 有专项优化
    mov cx, 100         ; 循环 100 次
    mov bx, 1           ; 当前加数

sum_loop:
    add ax, bx
    inc bx
    loop sum_loop

    mov bx, 10          ; 除数 10
    xor cx, cx          ; 清空 cx，用于记录位数，以便循环

div_loop:
    xor dx, dx          ; 清空 dx。因为下一行的 div 操作进行的是 dx:ax / bx
                        ; （也就是 ((dx << 16) + ax) / bx），所以必须清空，才能仅以 ax 为被除数
                        ; 而且每次除完 dx 里都会存余数，所以每次都要清空，清空要放在循环体里
    div bx              ; ax 从被除数变成商，dx 变成余数
    push dx             ; 余数压栈
    inc cx
    test ax, ax
    jnz div_loop

print_loop:
    pop dx
    add dl, '0'         ; dx 转换成 ASCII 字符
    mov ah, 02h
    int 21h
    loop print_loop     ; 该循环要执行的次数，上面 cx 已经算好了

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