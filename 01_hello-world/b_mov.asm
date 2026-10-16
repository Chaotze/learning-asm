.model small

.data
    hello db 'Hello, world!', 0Dh, 0Ah, '$'

.code
start:
    mov ax, @data
    mov ds, ax
    mov dx, offset hello
    mov ah, 9
    int 21h

    mov ax, 4C00h
    int 21h
end start