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

    mov cx, 26
    mov bl, 'a'
    mov bh, 13

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
    loop next_char

    mov ah, 4Ch
    int 21h
main endp
end main