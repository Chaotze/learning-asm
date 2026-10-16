; 在 Compiler Explorer (by Matt Godbolt) 上
; 使用 x86-64 gcc 16.2 编译以下 C 语言代码：
;
;     #include <stdio.h>
;     int main() {
;         for (char c = 'a'; c <= 'z'; c++) {
;             putchar(c);
;             ((c - 'a' + 1) % 13 == 0) && puts("");
;         }
;         return 0;
;     }
;
; 得到的 x86-64 汇编代码即为本文件，详见：
;     https://godbolt.org/#g:!((g:!((g:!((h:codeEditor,i:(filename:'1',fontScale:14,fontUsePx:'0',j:1,lang:c%2B%2B,selection:(endColumn:1,endLineNumber:9,positionColumn:1,positionLineNumber:9,selectionStartColumn:1,selectionStartLineNumber:9,startColumn:1,startLineNumber:9),source:'%23include+%3Cstdio.h%3E%0Aint+main()+%7B%0A++++for+(char+c+%3D+!'a!'%3B+c+%3C%3D+!'z!'%3B+c%2B%2B)+%7B%0A++++++++putchar(c)%3B%0A++++++++((c+-+!'a!'+%2B+1)+%25+13+%3D%3D+0)+%26%26+puts(%22%22)%3B%0A++++%7D%0A++++return+0%3B%0A%7D%0A'),l:'5',n:'0',o:'C%2B%2B+source+%231',t:'0')),k:50,l:'4',n:'0',o:'',s:0,t:'0'),(g:!((h:compiler,i:(compiler:g162,filters:(b:'0',binary:'1',binaryObject:'1',commentOnly:'0',debugCalls:'1',demangle:'0',directives:'0',execute:'1',intel:'0',libraryCode:'0',trim:'1',verboseDemangling:'0'),flagsViewOpen:'1',fontScale:14,fontUsePx:'0',j:1,lang:c%2B%2B,libs:!(),options:'',overrides:!(),selection:(endColumn:1,endLineNumber:1,positionColumn:1,positionLineNumber:1,selectionStartColumn:1,selectionStartLineNumber:1,startColumn:1,startLineNumber:1),source:1),l:'5',n:'0',o:'+x86-64+gcc+16.2+(Editor+%231)',t:'0')),k:50,l:'4',n:'0',o:'',s:0,t:'0')),l:'2',n:'0',o:'',t:'0')),version:4
; 或
;     https://godbolt.org/z/bc8zbn4YG

.LC0:
    .string ""
"main":
    push    rbp
    mov     rbp, rsp
    sub     rsp, 16
    mov     BYTE PTR [rbp-1], 97
    jmp     .L2
.L5:
    movsx   eax, BYTE PTR [rbp-1]
    mov     edi, eax
    call    "putchar"
    movsx   eax, BYTE PTR [rbp-1]
    lea     ecx, [rax-96]
    movsxd  rax, ecx
    imul    rax, rax, 1321528399
    shr     rax, 32
    mov     edx, eax
    sar     edx, 2
    mov     eax, ecx
    sar     eax, 31
    sub     edx, eax
    mov     eax, edx
    add     eax, eax
    add     eax, edx
    sal     eax, 2
    add     eax, edx
    sub     ecx, eax
    mov     edx, ecx
    test    edx, edx
    jne     .L4
    mov     edi, OFFSET FLAT:.LC0
    call    "puts"
    test    eax, eax
.L4:
    movzx   eax, BYTE PTR [rbp-1]
    add     eax, 1
    mov     BYTE PTR [rbp-1], al
.L2:
    cmp     BYTE PTR [rbp-1], 122
    jle     .L5
    mov     eax, 0
    leave
    ret