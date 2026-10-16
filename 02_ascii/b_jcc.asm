.model small
.stack 100h

.data
    count   db 26
    perline db 13
    newline db 0Dh, 0Ah, '$'

.code
main proc
    mov ax, @data
    mov ds, ax

    mov cx, 26          ; 剩余字符数
    mov bl, 'a'         ; 当前字符
    mov bh, 13          ; 本行剩余字符数

next_char:
    mov dl, bl
    mov ah, 02h
    int 21h

    mov dl, ' '
    mov ah, 02h
    int 21h

    inc bl
    dec bh

    cmp bh, 0
    jne skip_newline

    mov dl, 0Dh
    mov ah, 02h
    int 21h
    mov dl, 0Ah
    mov ah, 02h
    int 21h

    mov bh, 13

skip_newline:
    dec cx              ; 总剩余数减 1
    cmp cx, 0
    jne next_char       ; 还有字符，继续循环

    mov ah, 4Ch
    int 21h
main endp
end main