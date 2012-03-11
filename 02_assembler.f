 
.(  including 02_assembler.f ) cr

assembler definitions

// tiny assembly (Thanks to Luke Chang figTAIWAN)

                   : over8bits?  ( n -- )   \ abort if the related address is over 8 bits range ( -128 ~ 127 )
                       -128 127 within
                       if else abort" relative address over 8 bits range" then
                   ;

                   : over16bits? ( n -- )   \ abort if the related address is over 16 bits range ( -32768 ~ 32767 )
                       -32768 32767 within
                       if else abort" relative address over 16 bits range" then
                   ;

                   : over32bits? ( n -- )   \ abort if the related address is over 32 bits range ( $80000000 ~ $7fffffff )
                       $80000000 $7fffffff within
                       if else abort" relative address over 32 bits range" then
                   ;

                   \ 整理以下 assembly instructions，按照 op-code 的組成分 class。最簡單的指令，例如 INC BP， 單
                   \ 一 byte 的 op-code，這類命名為 8c: 表示為 8 bits 的 Code。又例如 call 1234h 屬於 8c16r:
                   \ 因為他有一個 Byte 的 code 跟著 16 bits 的相對位址。如此以往，所有的 CPU Instructions 都
                   \ 各有各的屬類。8c: 8c16r: 這類東西是 tforth 的 CPU instruction mnemonic 產生器。它們本
                   \ 身是 Object Oriented programming 裡的 classes。 這些 classes 所定義出來的 objects 是 CPU
                   \ instruction mnemonics.

\ This section is an example how to use 'disassembler-generator' in a assember class.
\ 
                   : 8c:     ( 8c -- ) \ op-code
                       create                            
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         1 ,  \ op-code size
                         ( pfa[3] )    ( 8c ) ,  \ 8c op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>  ( -- )
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         c,                         \ op-code
                   ;

                   $FC 8c: cld        immediate \ bits_16 CLD       bits_64 cld
                 \ $AD 8c: lodsw      immediate \ bits_16 LODSW     bits_64 lodsd eax,ds:[rsi]
                   $5A 8c: pop.rdx    immediate \ bits_16 POP   DX  bits_64 pop   rdx
                   $5E 8c: pop.rsi    immediate \ bits_16 POP   SI  bits_64 pop   rsi
                   $51 8c: push.rcx   immediate \ bits_16 PUSH  CX  bits_64 push  rcx
                   $57 8c: push.rdi   immediate \ bits_16 PUSH  DI  bits_64 push  rdi
                   $52 8c: push.rdx   immediate \ bits_16 PUSH  DX  bits_64 push  rdx
                   $56 8c: push.rsi   immediate \ bits_16 PUSH  SI  bits_64 push  rsi
                   $c3 8c: exit       immediate \ bits_16 RET       bits_64 ret
                   ' exit alias ret
                   $fa 8c: cli        immediate \ cli            bits_64
                   $f4 8c: hlt        immediate \ hlt            bits_64
                   $EC 8c: in.al,dx   immediate \ in    al,dx    bits_64
                   $ED 8c: in.eax,dx  immediate \ in    eax,dx   bits_64
                   $cc 8c: int3       immediate \ int3           bits_64
                   $90 8c: nop        immediate \ nop            bits_64
                   $EF 8c: out.dx,eax immediate \ out   dx,eax   bits_64
                   $5D 8c: pop.rbp    immediate \ pop   rbp      bits_64
                   $55 8c: push.rbp   immediate \ push  rbp      bits_64
                   $9C 8c: pushf      immediate \ pushf          bits_64
                   $F2 8c: repnz      immediate \ repnz          bits_64
                   $AF 8c: scasd      immediate \ scasd          bits_64
                   $fb 8c: sti        immediate \ sti            bits_64

                 \ : 16c:     ( 16c -- )     \ op-code
                 \     create
                 \       ,                   \ 16c
                 \     does>  ( -- )
                 \       r> @
                 \       $100 /mod $100 /mod      \ op-code 從 assembler .lst 而來 LSB 在前。
                 \       drop c, c,
                 \ ;

                   : 16c:     ( 16c -- )     \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         2 ,  \ op-code size
                         ( pfa[3] )   ( 16c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>  ( -- )
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         $100 /mod $100 /mod      \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c,
                   ;

                   \ 注意 high byte, low byte 的順序。照 assembler (NASM,MASM）的 listing 檔格式直接剪貼過來。
                   \ .-------------- Low byte
                   \ | .------------ High byte
                   \ | |
                 \ $01D8 16c: ax+bx     immediate  \ bits_16 ADD   AX,BX  bits_64 add  eax,ebx
                 \ $31C0 16c: ax=0      immediate  \ bits_16 XOR   AX,AX  bits_64 xor  eax,eax
                   $8CC8 16c: ax=cs     immediate  \ bits_16 MOV   AX,CS  bits_64 mov  ax,cs
                 \ $87EC 16c: bp<=>sp   immediate  \ bits_16 XCHG  BP,SP  bits_64 xchg esp,ebp
                 \ $89E3 16c: bx=sp     immediate  \ bits_16 MOV   BX,SP  bits_64 mov  ebx,esp
                 \ $31C9 16c: cx=0      immediate  \ bits_16 XOR   CX,CX  bits_64 xor  ecx,ecx
                   $8ED8 16c: ds=ax     immediate  \ bits_16 MOV   DS,AX  bits_64 mov  ds,ax
                 \ $D1D1 16c: RCL.cx    immediate  \ bits_16 RCL   CX,1   bits_64 rcl  ecx,1
                   $8ED0 16c: ss=ax     immediate  \ bits_16 MOV   SS,AX  bits_64 mov  ss,ax

                   $FFD0 16c: call.rax  immediate  \ call    rax       bits_64   call rax                  ; ffd0
                   $0FA2 16c: <cpuid>   immediate  \ cpuid             bits_64   cpuid                     ; 0fa2
                   $66ED 16c: in.ax,dx  immediate  \ in      ax,dx     bits_64   in ax, dx                 ; 66ed
                   $48CF 16c: iretq     immediate  \ iretq             bits_64   iretq                     ; 48cf
                   $8C0B 16c: [rbx]=cs  immediate  \ mov     [rbx],cs  bits_64   mov word ptr ds:[rbx], cs ; 8c0b
                   $8C1B 16c: [rbx]=ds  immediate  \ mov     [rbx],ds  bits_64   mov word ptr ds:[rbx], ds ; 8c1b
                   $8C03 16c: [rbx]=es  immediate  \ mov     [rbx],es  bits_64   mov word ptr ds:[rbx], es ; 8c03
                   $8C13 16c: [rbx]=ss  immediate  \ mov     [rbx],ss  bits_64   mov word ptr ds:[rbx], ss ; 8c13
                   $66EF 16c: out.dx,ax immediate  \ out     dx,ax     bits_64   out dx, ax                ; 66ef
                   $4158 16c: pop.r8    immediate  \ pop     r8        bits_64   pop r8                    ; 4158
                   $4159 16c: pop.r9    immediate  \ pop     r9        bits_64   pop r9                    ; 4159
                   $4150 16c: push.r8   immediate  \ push    r8        bits_64   push r8                   ; 4150
                   $4151 16c: push.r9   immediate  \ push    r9        bits_64   push r9                   ; 4151
                   $0F32 16c: <rdmsr>   immediate  \ rdmsr             bits_64   rdmsr                     ; 0f32
                   $0F31 16c: <rdtsc>   immediate  \ rdtsc             bits_64   rdtsc                     ; 0f31
                   $0F30 16c: <wrmsr>   immediate  \ wrmsr             bits_64   wrmsr                     ; 0f30

                 \ : 24c:     ( n24 -- )     \ op-code
                 \     create
                 \       ,                   \ 24c
                 \     does>  ( -- )
                 \       r> @
                 \       $100 /mod $100 /mod $100 /mod    \ op-code 從 assembler .lst 而來 LSB 在前。
                 \       drop c, c, c,
                 \ ;

                   : 24c:     ( n24 -- )     \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         3 ,  \ op-code size
                         ( pfa[3] )   ( 24c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>  ( -- )
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         $100 /mod $100 /mod $100 /mod    \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c, c,
                   ;

                   \ 注意 high byte, low byte 的順序。照 assembler (NASM,MASM）的 listing 檔格式直接剪貼過來。
                   \ .-------------- Low byte
                   \ |   .---------- High byte
                   \ |   |
                   $48F7F3 24c: div.rbx    immediate    \ div  rbx        bits_64  div rax, rbx              ; 48f7f3
                   $41FFE0 24c: jmp.r8     immediate    \ jmp  r8         bits_64  jmp r8                    ; 41ffe0
                   $0F011B 24c: lidt[rbx]  immediate    \ lidt [rbx]      bits_64  lidt ds:[rbx]             ; 0f011b
                   $4C8913 24c: [rbx]=r10  immediate    \ mov  [rbx],r10  bits_64  mov qword ptr ds:[rbx], r10 ; 4c8913
                   $4C891B 24c: [rbx]=r11  immediate    \ mov  [rbx],r11  bits_64  mov qword ptr ds:[rbx], r11 ; 4c891b
                   $4C8923 24c: [rbx]=r12  immediate    \ mov  [rbx],r12  bits_64  mov qword ptr ds:[rbx], r12 ; 4c8923
                   $4C892B 24c: [rbx]=r13  immediate    \ mov  [rbx],r13  bits_64  mov qword ptr ds:[rbx], r13 ; 4c892b
                   $4C8933 24c: [rbx]=r14  immediate    \ mov  [rbx],r14  bits_64  mov qword ptr ds:[rbx], r14 ; 4c8933
                   $4C893B 24c: [rbx]=r15  immediate    \ mov  [rbx],r15  bits_64  mov qword ptr ds:[rbx], r15 ; 4c893b
                   $4C8903 24c: [rbx]=r8   immediate    \ mov  [rbx],r8   bits_64  mov qword ptr ds:[rbx], r8 ; 4c8903
                   $4C890B 24c: [rbx]=r9   immediate    \ mov  [rbx],r9   bits_64  mov qword ptr ds:[rbx], r9 ; 4c890b
                   $488903 24c: [rbx]=rax  immediate    \ mov  [rbx],rax  bits_64  mov qword ptr ds:[rbx], rax ; 488903
                   $0F22C0 24c: cr0=rax    immediate    \ mov  cr0,rax    bits_64  mov cr0, rax              ; 0f22c0
                   $0F22d0 24c: cr2=rax    immediate    \ mov  cr2,rax    bits_64  mov cr2, rax              ; 0f22d0
                   $0F22d8 24c: cr3=rax    immediate    \ mov  cr3,rax    bits_64  mov cr3, rax              ; 0f22d8
                   $0F22e0 24c: cr4=rax    immediate    \ mov  cr4,rax    bits_64  mov cr4, rax              ; 0f22e0
                   $4989E1 24c: r9=rsp     immediate    \ mov  r9,rsp     bits_64  mov r9, rsp               ; 4989e1
                   $0F20C0 24c: rax=cr0    immediate    \ mov  rax,cr0    bits_64  mov rax, cr0              ; 0f20c0
                   $0F20d0 24c: rax=cr2    immediate    \ mov  rax,cr2    bits_64  mov rax, cr2              ; 0f20d0
                   $0F20d8 24c: rax=cr3    immediate    \ mov  rax,cr3    bits_64  mov rax, cr3              ; 0f20d8
                   $0F20e0 24c: rax=cr4    immediate    \ mov  rax,cr4    bits_64  mov rax, cr4              ; 0f20e0
                   $4C89C8 24c: rax=r9     immediate    \ mov  rax,r9     bits_64  mov rax, r9               ; 4c89c8
                   $4889F0 24c: rax=rsi    immediate    \ mov  rax,rsi    bits_64  mov rax, rsi              ; 4889f0
                   $4889D3 24c: rbx=rdx    immediate    \ mov  rbx,rdx    bits_64  mov rbx, rdx              ; 4889d3
                   $4889D9 24c: rcx=rbx    immediate    \ mov  rcx,rbx    bits_64  mov rcx, rbx              ; 4889d9
                   $4809D0 24c: or.rax,rdx immediate    \ or   rax,rdx    bits_64  or rax, rdx               ; 4809d0
                   $4809D0 24c: rax|rdx    immediate    \ or   rax,rdx    bits_64  or rax, rdx               ; 4809d0
                   $0F010B 24c: sidt[rbx]  immediate    \ sidt [rbx]      bits_64  sidt ds:[rbx]             ; 0f010b
                   $4831C0 24c: rax=0      immediate    \ xor  rax,rax    bits_64  xor rax, rax              ; 4831c0
                   $4831D2 24c: rdx=0      immediate    \ xor  rdx,rdx    bits_64  xor rdx, rdx              ; 4831d2
                   $4863DB 24c: movsx.rbx,ebx immediate \ movsx rbx,ebx

                 \ : 32c:     ( 32c -- )     \ op-code
                 \     create
                 \       ,                   \ 32c
                 \     does>  ( -- )
                 \       r> @
                 \       $100 /mod $100 /mod $100 /mod $100 /mod  \ op-code 從 assembler .lst 而來 LSB 在前。
                 \       drop c, c, c, c,
                 \ ;

                   : 32c:     ( 32c -- )     \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         4 ,  \ op-code size
                         ( pfa[3] )   ( 32c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>  ( -- )
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         $100 /mod $100 /mod $100 /mod $100 /mod  \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c, c, c,
                   ;

                   \ 注意 high byte, low byte 的順序。照 assembler (NASM,MASM）的 listing 檔格式直接剪貼過來。
                   \ .-------------- Low byte
                   \ |     .------------ High byte
                   \ |     |
                   $480F03c3 32c: lsl.rax,bx    immediate \ lsl   rax,bx ; 480f03c3
                   $480FBEDB 32c: movsx.rbx,bl  immediate \ movsx rbx,bl ; 480FBEDB                    
                   $480FBFDB 32c: movsx.rbx,bx  immediate \ movsx rbx,bx

                   : 16c16#: ( 16c -- )  \ op-code     assembly instruction class
                       create
                         ,               \ 16c
                       does> ( 16# -- )  \ 16 bits data
                         r> @
                         $100 /mod $100 /mod           \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c,
                         w,              \ 16#         \ data 從 fcode source 而來，正常 Intel 順序。
                   ;
                   \ long mode 下我沒用到這種指令。

                   : 16c8#16#: ( n16 -- )  \ op-code    assembly instruction class
                       create
                         ,                 \ 16c
                       does>   ( 8# 16# -- )
                         r> @
                         $100 /mod $100 /mod           \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c,
                         swap c, w,            \ n8 n16  data 來自 fcode source, 正常 Intel 順序。
                   ;
                   \ long mode 下我沒用到這種指令。

                   : 16c8#8#: ( n -- )     \ op-code    assembly instruction class
                       create
                         ,                 \ 16c
                       does>  ( n8 n8 -- )
                         r> @
                         $100 /mod $100 /mod           \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c,
                         swap c, c,            \ n8 n8   data 來自 fcode source, 正常 Intel 順序。
                   ;
                   \ long mode 下我沒用到這種指令。

                   : 24c8#8#: ( 24c -- )     \ op-code    assembly instruction class
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         3 ,  \ op-code size
                         ( pfa[3] )   ( 24c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         1 ,  \ parameter section, 1 menas 8#
                         ( pfa[7] )         1 ,  \ parameter section, 1 menas 8#
                         ( pfa[8] )         0 ,  \ parameter section, 0 menas end of parameters
                         0 disassembler-generator
                       does>  ( n8 n8 -- )
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         $100 /mod $100 /mod $100 /mod     \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c, c,
                         swap c, c,                        \ n8 n8   data 來自 fcode source, 正常 Intel 順序。
                   ;

                   : 32c8#8#: ( 32c -- )     \ op-code    assembly instruction class
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         4 ,  \ op-code size, 4 means 32c
                         ( pfa[3] )   ( 32c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         1 ,  \ parameter section, 1 menas 8#
                         ( pfa[7] )         1 ,  \ parameter section, 1 menas 8#
                         ( pfa[8] )         0 ,  \ parameter section, 0 menas end of parameters
                         0 disassembler-generator
                       does>  ( n8 n8 -- )
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         $100 /mod $100 /mod $100 /mod $100 /mod  \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c, c, c,
                         swap c, c,   \ n8 n8   data 來自 fcode source, 正常 Intel 順序。
                   ;

                   : 16c8#: ( n16 -- )     \ op-code    assembly instruction class
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         2 ,  \ op-code size
                         ( pfa[3] )   ( 16c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         1 ,  \ parameter section  1 menas 8#
                         ( pfa[7] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>  ( n8 -- )    \
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         $100 /mod $100 /mod           \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c,
                         c,
                   ;

                   \ 注意 high byte, low byte 的順序。照 assembler (NASM,MASM）的 listing 檔格式直接剪貼過來。
                   \ .-------------- Low byte
                   \ | .------------ High byte
                   \ | |
                 \ $83C5 16c8#: bp+n8         immediate \ bits_16 ADD  BP,n8        bits_64 add ebp, 0xffffffab       ; 83c5ab
                 \ $83ED 16c8#: bp-n8         immediate \ bits_16 SUB  BP,n8        bits_64 sub ebp, 0xffffffab       ; 83edab
                 \ $80FA 16c8#: dl:n8         immediate \ bits_16 CMP  DL,n8        bits_64 cmp dl, 0xab              ; 80faab
                 \ $83C4 16c8#: sp+n8         immediate \ bits_16 ADD  SP,+02       bits_64 add esp, 0xffffffab       ; 83c4ab

                   : 8c16#:   ( 8c -- )      \ op-code
                       create
                         ,                   \ 8c
                       does>  ( n16 -- )
                         r> @
                         c,                  \ op-code
                         w,                  \ operand
                   ;
                   \ long mode 下我沒用到這種指令。

                   : 8c16r:     ( 8c -- )  \ op-code    這個 word 在 long mode 沒有用。 Long mode 只有 8 bits 32 bits 兩種相對地址。
                       create
                         ,                   \ 8c
                       does>  ( destination -- )
                         r> @
                         c,                 \ op-code
                         here 2 + -
                         dup over16bits?    \ check relative address' range
                         w,                 \ target relative address
                   ;
                   \ long mode 下我沒用到這種指令。

                   : 8c8#:     ( 8c -- )     \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         1 ,  \ op-code size
                         ( pfa[3] )    ( 8c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         1 ,  \ parameter section  1 menas 8#
                         ( pfa[7] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>   ( 8# -- )     \ parameter operand
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         c,                  \ op-code
                         c,                  \ 8#
                   ;

                   $6A 8c8#: push64.n8 immediate  \ push64 n8     bits_64 push 0xffffffffffffffab   ; 6aab
                 \ $B4 8c8#: ah=n8     immediate  \ MOV    AH,n8  bits_64 mov ah, 0xab              ; b4ab
                 \ $B2 8c8#: dl=n8     immediate  \ MOV    DL,n8  bits_64 mov dl, 0xab              ; b2ab
                   $CD 8c8#: int.n8    immediate  \ INT    n8     bits_64 int 0xab                  ; cdab

                 \ : 8c32#:   ( n8 -- )      \ op-code
                 \     create
                 \       ,                   \ 8c
                 \     does>  ( n32 -- )     \ parameter 32#
                 \       r> @
                 \       c,                  \ op-code
                 \       d,                  \ 32# operand
                 \ ;

                   : 8c32#:   ( n8 -- )      \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         1 ,  \ op-code size
                         ( pfa[3] )    ( 8c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         4 ,  \ parameter section  4 menas 32#
                         ( pfa[7] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>  ( n32 -- )     \ parameter 32#
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         c,                  \ op-code
                         d,                  \ 32# operand
                   ;

                 \ $25 8c32#:  eax&n32 immediate \ and eax, 0x34b81234
                 \ $B8 8c32#:  eax=n32 immediate \ dito 32bits
                 \ $BD 8c32#:  ebp=n32 immediate \ dito 32bits
                 \ $BC 8c32#:  esp=n32 immediate \ dito 32bits
                   $68 8c32#: push.n32 immediate \ push  n32

                   : 16c32#:   ( 16c -- )    \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         2 ,  \ op-code size
                         ( pfa[3] )   ( 16c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         4 ,  \ parameter section  4 menas 32#
                         ( pfa[7] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>   ( 32# -- )    \ parameter 32#
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         $100 /mod $100 /mod \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c,
                         d,                  \ 32# operand data 來自 fcode source, 正常 Intel 順序。
                   ;

                   \ 注意 high byte, low byte 的順序。照 assembler (NASM,MASM）的 listing 檔格式直接剪貼過來。
                   \ .-------------- Low byte
                   \ | .------------ High byte
                   \ | |
                   $8C9B 16c32#: [rbx+n32]=ds immediate  \ mov [rbx+n32],ds  \ mov word ptr ds:[rbx+287454020], ds ; 8c9b44332211
                   $8C83 16c32#: [rbx+n32]=es immediate  \ mov [rbx+n32],es  \ mov word ptr ds:[rbx+287454020], es ; 8c8344332211
                   $8E9B 16c32#: ds=[rbx+n32] immediate  \ mov ds,[rbx+n32]  \ mov ds, word ptr ds:[rbx+287454020] ; 8e9b44332211
                   $8E83 16c32#: es=[rbx+n32] immediate  \ mov es,[rbx+n32]  \ mov es, word ptr ds:[rbx+287454020] ; 8e8344332211
                 \ $81C3 16c32#: ebx+n32 immediate       \ add ebx,n32

                   : 16c64#:   ( 16c -- )    \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         2 ,  \ op-code size
                         ( pfa[3] )   ( 16c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         8 ,  \ parameter section  8 menas 64#
                         ( pfa[7] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>   ( 64# -- )    \ parameter 64#
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         $100 /mod $100 /mod \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c,
                         ,                   \ 64# operand data 來自 fcode source, 正常 Intel 順序。
                   ;

                   \ 注意 high byte, low byte 的順序。照 assembler (NASM,MASM）的 listing 檔格式直接剪貼過來。
                   \ .-------------- Low byte
                   \ | .------------ High byte
                   \ | |
                   $48BB 16c64#: rbx=n64  immediate \ mov  rbx,n64  ok

                   : 24c8#:    ( 24c -- )    \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         3 ,  \ op-code size
                         ( pfa[3] )   ( 24c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         1 ,  \ parameter section  8 menas 64#
                         ( pfa[7] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>   ( 8# --  )    \ parameter 8#
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         $100 /mod $100 /mod $100 /mod \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c, c,
                         c,                  \ 8# operand data 來自 fcode source, 正常 Intel 順序。
                   ;

                   \ 注意 high byte, low byte 的順序。照 assembler (NASM,MASM）的 listing 檔格式直接剪貼過來。
                   \ .-------------- Low byte
                   \ |   .------------ High byte
                   \ |   |
                   $498941 24c8#: [r9+n8]=rax      immediate  \ mov  [r9+n8],rax       mov qword ptr ds:[r9-85], rax ; 498941ab
                   $488945 24c8#: [rbp+n8]=rax     immediate  \ mov  [rbp+n8],rax      mov qword ptr ss:[rbp-85], rax ; 488945ab
                   $48895D 24c8#: [rbp+n8]=rbx     immediate  \ mov  [rbp+n8],rbx      mov qword ptr ss:[rbp-85], rbx ; 48895dab
                   $48894D 24c8#: [rbp+n8]=rcx     immediate  \ mov  [rbp+n8],rcx      mov qword ptr ss:[rbp-85], rcx ; 48894dab
                   $488955 24c8#: [rbp+n8]=rdx     immediate  \ mov  [rbp+n8],rdx      mov qword ptr ss:[rbp-85], rdx ; 488955ab
                   $41FF71 24c8#: push64[r9+n8]    immediate  \ push qword [r9+8*1]    push qword ptr ds:[r9-85] ; 41ff71ab
                   $4C8B53 24c8#: r10=[rbx+n8]     immediate  \ mov  r10,[rbx+n8]      mov r10, qword ptr ds:[rbx-85] ; 4c8b53ab
                   $4C8B5B 24c8#: r11=[rbx+n8]     immediate  \ mov  r11,[rbx+n8]      mov r11, qword ptr ds:[rbx-85] ; 4c8b5bab
                   $4C8B63 24c8#: r12=[rbx+n8]     immediate  \ mov  r12,[rbx+n8]      mov r12, qword ptr ds:[rbx-85] ; 4c8b63ab
                   $4C8B6B 24c8#: r13=[rbx+n8]     immediate  \ mov  r13,[rbx+n8]      mov r13, qword ptr ds:[rbx-85] ; 4c8b6bab
                   $4C8B73 24c8#: r14=[rbx+n8]     immediate  \ mov  r14,[rbx+n8]      mov r14, qword ptr ds:[rbx-85] ; 4c8b73ab
                   $4C8B7B 24c8#: r15=[rbx+n8]     immediate  \ mov  r15,[rbx+n8]      mov r15, qword ptr ds:[rbx-85] ; 4c8b7bab
                   $4883C0 24c8#: rax+n8           immediate  \ add  rax,n8            add rax, 0xffffffffffffffab ; 4883c0ab
                   $498B41 24c8#: rax=[r9+n8]      immediate  \ mov  rax,[r9+n8]       mov rax, qword ptr ds:[r9-85] ; 498b41ab
                   $488B43 24c8#: rax=[rbx+n8]     immediate  \ mov  rax,[rbx+n8]      mov rax, qword ptr ds:[rbx-85] ; 488b43ab
                   $4883C3 24c8#: rbx+n8           immediate  \ add  rbx,n8            add rbx, 0xffffffffffffffab ; 4883c3ab
                   $488B5D 24c8#: rbx=[rbp+n8]     immediate  \ mov  rbx,[rbp+n8]      mov rbx, qword ptr ss:[rbp-85] ; 488b5dab
                   $488B4D 24c8#: rcx=[rbp+n8]     immediate  \ mov  rcx,[rbp+n8]      mov rcx, qword ptr ss:[rbp-85] ; 488b4dab
                   $488B55 24c8#: rdx=[rbp+n8]     immediate  \ mov  rdx,[rbp+n8]      mov rdx, qword ptr ss:[rbp-85] ; 488b55ab
                   $4883C4 24c8#: rsp+n8           immediate  \ add  rsp,8             add rsp, 0xffffffffffffffab ; 4883c4ab
                   $4883C4 24c8#: rsp+n8           immediate  \ add  rsp,n8            add rsp, 0xffffffffffffffab ; 4883c4ab
                   $48C1E2 24c8#: shl.rdx.n8       immediate  \ shl  rdx,32            shl rdx, 0xab             ; 48c1e2ab
                   $4883C5 24c8#: rbp+n8           immediate 
                   $48335D 24c8#: rbx^[rbp+n8]     immediate  \ xor  rbx,[rbp+n8]
                   $4883E3 24c8#: rbx&n8           immediate  \ and  rbx,n8
                   $48C1FB 24c8#: sar.rbx,n8       immediate  \ sar r bx,63
                   

                   : 24c32#:    ( 24c -- )   \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         3 ,  \ op-code size
                         ( pfa[3] )   ( 24c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         4 ,  \ parameter section  4 menas 32#
                         ( pfa[7] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>   ( 32# --  )    \ parameter 32#
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         $100 /mod $100 /mod $100 /mod \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c, c,
                         d,                  \ 32# operand data 來自 fcode source, 正常 Intel 順序。
                   ;
                         

                   \ 注意 high byte, low byte 的順序。照 assembler (NASM,MASM）的 listing 檔格式直接剪貼過來。
                   \ .-------------- Low byte
                   \ |   .------------ High byte
                   \ |   |
                   $4C8993 24c32#: [rbx+n32]=r10 immediate  \ mov [rbx+n32],r10  mov qword ptr ds:[rbx+287454020], r10 ; 4c899344332211
                   $4C899B 24c32#: [rbx+n32]=r11 immediate  \ mov [rbx+n32],r11  mov qword ptr ds:[rbx+287454020], r11 ; 4c899b44332211
                   $4C89A3 24c32#: [rbx+n32]=r12 immediate  \ mov [rbx+n32],r12  mov qword ptr ds:[rbx+287454020], r12 ; 4c89a344332211
                   $4C89AB 24c32#: [rbx+n32]=r13 immediate  \ mov [rbx+n32],r13  mov qword ptr ds:[rbx+287454020], r13 ; 4c89ab44332211
                   $4C89B3 24c32#: [rbx+n32]=r14 immediate  \ mov [rbx+n32],r14  mov qword ptr ds:[rbx+287454020], r14 ; 4c89b344332211
                   $4C89BB 24c32#: [rbx+n32]=r15 immediate  \ mov [rbx+n32],r15  mov qword ptr ds:[rbx+287454020], r15 ; 4c89bb44332211
                   $488983 24c32#: [rbx+n32]=rax immediate  \ mov [rbx+n32],rax  mov qword ptr ds:[rbx+287454020], rax ; 48898344332211
                   $488B83 24c32#: rax=[rbx+n32] immediate  \ mov rax,[rbx+n32]  mov rax, qword ptr ds:[rbx+287454020] ; 488b8344332211

                   : 32c8#:    ( 32c -- )    \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         4 ,  \ op-code size
                         ( pfa[3] )   ( 32c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         1 ,  \ parameter section  1 menas 8#
                         ( pfa[7] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>   ( 8# --  )    \ parameter 8#
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         $100 /mod $100 /mod $100 /mod $100 /mod \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c, c, c,
                         c,                  \ 8# operand data 來自 fcode source, 正常 Intel 順序。
                   ;

                   : 32c32#:    ( 32c -- )   \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         4 ,  \ op-code size
                         ( pfa[3] )   ( 32c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         4 ,  \ parameter section  1 menas 32#
                         ( pfa[7] )         0 ,  \ parameter section  0 menas end of parameters
                         0 disassembler-generator
                       does>   ( 32# --  )    \ parameter 32#
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         $100 /mod $100 /mod $100 /mod $100 /mod \ op-code 從 assembler .lst 而來 LSB 在前。
                         drop c, c, c, c,
                         d,                  \ 32# operand data 來自 fcode source, 正常 Intel 順序。
                   ;

                   $0F010425 32c32#: sgdt[n32] immediate \ SGDT [buffer]  Store global descriptor table         sgdt ds:0x0000000011223344 ; 0f01042544332211
                   $0F010C25 32c32#: sidt[n32] immediate \ SIDT [buffer]  Store interrupt descriptor table      sidt ds:0x0000000011223344 ; 0f010c2544332211
                   $0F000425 32c32#: sldt[n32] immediate \ SLDT [buffer]  Store local descriptor table          sldt word ptr ds:0x0000000011223344 ; 0f00042544332211
                   $0F012425 32c32#: smsw[n32] immediate \ SMSW [buffer]  Store machine status word             smsw word ptr ds:0x0000000011223344 ; 0f01242544332211

                   : 8c8r:     ( n8 -- )  \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         1 ,  \ op-code size
                         ( pfa[3] )   (  8c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         1 ,  \ parameter section  1 menas 8rel
                         ( pfa[7] )         0 ,  \ parameter section  0 menas end of parameters
                         8 disassembler-generator
                       does>     ( address -- )  \ destination linear address ( for 16 32 and 64 bits mode )
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         c,                 \ op-code
                         here 1+ -          \ target relative address
                         dup over8bits?     \ check relative address' range
                         c,                 \ adjust to only 8bits
                   ;
                   
                   $eb 8c8r: jmp.rel8 immediate  \ jmp rel8 
                   $72 8c8r: jb.rel8  immediate  \ JB  rel8 
                   $75 8c8r: jnz.rel8 immediate  \ JNZ rel8 
                   ' jb.rel8 alias jc.rel8       \ JC  rel8 
                   $73 8c8r: jnc.rel8 immediate  \ jnc rel8
                   $74 8c8r: jz.rel8  immediate  \ jz  rel8

                   : 8c32r:     ( n8 -- )  \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         1 ,  \ op-code size
                         ( pfa[3] )   (  8c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         4 ,  \ parameter section  1 menas 32rel
                         ( pfa[7] )         0 ,  \ parameter section  0 menas end of parameters
                         32 disassembler-generator
                       does>  ( address -- ) \ target 64bits address
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         c,                  \ op-code
                         here 4 + -          \ relative address
                         dup over32bits?     \ check relative address' range
                         d,                  \ adjust to only 32bits
                   ;

                   $E8 8c32r: call.r32 immediate \  bits_16 CALL r16  bits_64 call .+887689780          ; e83412e934 <=====
                   $E9 8c32r: jmp.r32  immediate \  bits_16 JMP  r16  bits_64 jmp .-1419111884          ; e934126aab <=====

                   : 16c32r:     ( 16c -- )  \ op-code
                       create
                         ( pfa[0] )         0 ,  \ linkage
                         ( pfa[1] )         0 ,  \ disassembler entry point, 0 is dummy
                         ( pfa[2] )         2 ,  \ op-code size
                         ( pfa[3] )   ( 16c ) ,  \ op-code, given from outside  
                         ( pfa[4] )    last @ ,  \ mnemonic name.
                         ( pfa[5] )         0 ,  \ count
                         ( pfa[6] )         4 ,  \ parameter section  1 menas 32rel
                         ( pfa[7] )         0 ,  \ parameter section  0 menas end of parameters
                         32 disassembler-generator
                       does>  ( address -- ) \ target 64bits address
                         r> 5 cells + inc[rbx] 2 cells - @ \ PFA[5]+=1 PFA[3]
                         c,                  \ op-code
                         here 4 + -          \ relative address
                         dup over32bits?     \ check relative address' range
                         d,                  \ adjust to only 32bits
                   ;

// Assembly Macros

\  $POP_RBX        ( ... x1 x2 x3 -- ... x1 x2 )

                   : $POP_RBX
                       $" 0 rbx=[rbp+n8]     " $iEval
                       $" 8 rbp+n8           " $iEval
                   ; immediate

\  $PUSH_RBX       ( ... x1 x2 -- ... x1 x2 x2 )

                   : $PUSH_RBX
                       $" -8 rbp+n8          " $iEval
                       $"  0 [rbp+n8]=rbx    " $iEval
                   ; immediate

// Example of assembly usages. 指令、macro 都是 immediate, 數字也要這樣 [ 框成 ] immediate.

                   : -2  $PUSH_RBX [ -2 ] rbx=n64 ; \ fast literals
                   :  4  $PUSH_RBX [  4 ] rbx=n64 ; \ fast literals
                   : -4  $PUSH_RBX [ -4 ] rbx=n64 ; \ fast literals
                   :  8  $PUSH_RBX [  8 ] rbx=n64 ; \ fast literals
                   : -8  $PUSH_RBX [ -8 ] rbx=n64 ; \ fast literals

\ CPU instructions used in eforth64.r18 

 $0F82      16c32r:    jb.r32           immediate 
 $0F83      16c32r:    jnc.r32          immediate 
 $0F84      16c32r:    jz.r32           immediate 
 $0F85      16c32r:    jne.r32          immediate 
 $48BC      16c64#:    rsp=n64          immediate 
 $48BE      16c64#:    rsi=n64          immediate 
 $48B9      16c64#:    rcx=n64          immediate 
 $48BD      16c64#:    rbp=n64          immediate 
 $48B8      16c64#:    rax=n64          immediate 
 $48BF      16c64#:    rdi=n64          immediate 
 $48A5      16c:       movsq            immediate 
 $8803      16c:       [rbx]=al         immediate 
 $8903      16c:       [rbx]=eax        immediate 
 $8A03      16c:       al=[rbx]         immediate 
 $8B03      16c:       eax=[rbx]        immediate 
 $FF27      16c:       jmp.[rdi]        immediate 
 $FFE0      16c:       jmp.rax          immediate 
 $488345    24c8#8#:   [rbp+n8]+n8      immediate  \ bits_64
 $480B5D    24c8#:     rbx|[rbp+n8]     immediate 
 $48035D    24c8#:     rbx+[rbp+n8]     immediate 
 $48235D    24c8#:     rbx&[rbp+n9]     immediate 
 $488D6D    24c8#:     lea.rbp,[rbp+n8] immediate 
 $488B45    24c8#:     rax=[rbp+n8]     immediate 
 $488D47    24c8#:     lea.rax,[rdi+n8] immediate 
 $4883C0    24c8#:     rax+n8           immediate 
 $48FF45    24c8#:     inc[rbp+n8]      immediate  \ bits_64
 $48FF43    24c8#:     inc[rbx+n8]      immediate  \ bits_64
 $48FF4D    24c8#:     dec[rbp+n8]      immediate  \ bits_64
 $48FF4B    24c8#:     dec[rbx+n8]      immediate  \ bits_64
 $4809DB    24c:       rbx|rbx          immediate 
 $4809C0    24c:       rax|rax          immediate 
 $4831C0    24c:       rax^rax          immediate 
 $4889C3    24c:       rbx=rax          immediate 
 $4889DD    24c:       rbp=rbx          immediate 
 $488B18    24c:       rbx=[rax]        immediate 
 $488B1B    24c:       rbx=[rbx]        immediate 
 $4889E3    24c:       rbx=rsp          immediate 
 $4889D8    24c:       rax=rbx          immediate 
 $4889EB    24c:       rbx=rbp          immediate 
 $4889DA    24c:       rdx=rbx          immediate 
 $4889DC    24c:       rsp=rbx          immediate 
 $48D1E3    24c:       shl.rbx,1        immediate 
 $48D1D0    24c:       rcl.rax,1        immediate 
 $48FF03    24c:       inc[rbx]         immediate  \ bits_64
 $48F7D3    24c:       ~rbx             immediate 
 $48FF0B    24c:       dec[rbx]         immediate  \ bits_64
 $668903    24c:       [rbx]=ax         immediate 
 $668B03    24c:       ax=[rbx]         immediate 
 $48890425  32c32#:    [n32]=rax        immediate 
 $48834424  32c8#8#:   [rsp+n8]+n8      immediate  \ bits_64
 $488B5C24  32c8#:     rbx=[rsp+n8]     immediate 
 $48832C24  32c8#:     qword[rsp]-n8    immediate 
 $48895C24  32c8#:     [rsp+n8]=rbx     immediate  
 $48FF4424  32c8#:     inc[rsp+n8]      immediate  \ bits_64
 $48FF4C24  32c8#:     dec[rsp+n8]      immediate  \ bits_64
 $50        8c:        push.rax         immediate 
 $53        8c:        push.rbx         immediate 
 $58        8c:        pop.rax          immediate 
 $59        8c:        pop.rcx          immediate 
 $5B        8c:        pop.rbx          immediate 
 $5F        8c:        pop.rdi          immediate 
 $EE        8c:        out.dx,al        immediate 
 $F3        8c:        repz             immediate 

// debug registers

   $0F21C0 24c: rax=dr0 immediate
   $0F21C8 24c: rax=dr1 immediate
   $0F21D0 24c: rax=dr2 immediate
   $0F21D8 24c: rax=dr3 immediate
   $0F21F0 24c: rax=dr6 immediate
   $0F21F8 24c: rax=dr7 immediate

   $0F23C0 24c: dr0=rax immediate
   $0F23C8 24c: dr1=rax immediate
   $0F23D0 24c: dr2=rax immediate
   $0F23D8 24c: dr3=rax immediate
   $0F23F0 24c: dr6=rax immediate
   $0F23F8 24c: dr7=rax immediate

   $0F21C3 24c: rbx=dr0 immediate
   $0F21CB 24c: rbx=dr1 immediate
   $0F21D3 24c: rbx=dr2 immediate
   $0F21DB 24c: rbx=dr3 immediate
   $0F21F3 24c: rbx=dr6 immediate
   $0F21FB 24c: rbx=dr7 immediate

   $0F23C3 24c: dr0=rbx immediate
   $0F23CB 24c: dr1=rbx immediate
   $0F23D3 24c: dr2=rbx immediate
   $0F23DB 24c: dr3=rbx immediate
   $0F23F3 24c: dr6=rbx immediate
   $0F23FB 24c: dr7=rbx immediate

