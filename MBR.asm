
; http://wiki.osdev.org/Entering_Long_Mode_Directly
; Entering Long Mode Directly
; From OSDev Wiki
; Jump to: navigation, search
; Demo Code
;
; The following NASM code demonstrates how to boot into 64 bit mode without entering protected mode:
; It works fine for BIOS forth debug engine prototype 64bits-MBR-1kf or UTS AH7139_01#04   hcchen5600 2011/06/13 20:55:00

; hcchen5600 2011/07/17 14:01:06 我終於想明白了，eforth64 should be org 0x100000 
; but MBR should be org 0x7c00 , due to that I'll use NASM without LINKer so they 
; must be separaged two .asm files.So now I have two source files,
; "c:\Users\8304018.WKSCN\Documents\My Dropbox\learnings\BIOS DEBUGGER FORTH ENGIN\eforth64\eforth64MBR.asm"
; "c:\Users\8304018.WKSCN\Documents\My Dropbox\learnings\BIOS DEBUGGER FORTH ENGIN\eforth64\eforth64.asm"

; hcchen5600 2011/08/10 08:30:19 
; 之前的 64-bits MBR 只抓 2 tracks 2 * 9 = 18 k, 抓多一點吧！ eforth64_r5 $eval 寫好以後，帶
; forth source 空間需求不再微小。 ===> 多抓兩個 track 共 4 * 9 = 36K

TOTAL512K  EQU   1                   ; was 36k, final version 512K. Binary code + forth code total size read from floppy.

        ORG 0x00007C00
        BITS 16
        
FORTH_ENTRY equ 0x100000             ; eforth64 is at 2nd 1M memory
        
boot_loader:

        ;Parameter from BIOS: dl = boot drive
        ;Set default state
                                    
        cli                         
        xor bx,bx                   
        mov es,bx                   
        mov fs,bx                   
        mov gs,bx                   
        mov ds,bx                   
        mov ss,bx                   
        mov sp,0x7C00               
        sti                         
        jmp 0:readsource

offsett  dw  0
segmentt dw  0
cylinder db  0
head     db  0
sector   db  0

readsource:
%if TOTAL512K
        ; Load kernel from floppy disk
        ; eforth64 binary code and source code stored at cylinder 0 head 1 sector 1 total 512k
        ; buffer is at 1000:0~8000:0, will be moved to target position after switched to long mode.

        mov cx,1024
.next   call getdestination
        call getcylinder
        call getheadsector
        call readsector
        loop .next 
        jmp  enablea20
        
getdestination:
        mov ax,1024
        sub ax,cx    ; ax=block
        mov bx,512
        xor dx,dx
        mul bx
        mov [offsett],ax
        shl dx,12         ; turn number of 64k into segment
        add dx,1000h      ; buffer base address
        mov [segmentt],dx
        ret
        
getcylinder:
        mov ax,1024
        sub ax,cx    ; ax=block
        add ax,18
        mov bl,36
        div bl
        mov [cylinder],al
        ret

getheadsector:
        mov ax,1024
        sub ax,cx    ; ax=block
        add ax,18    ; this is must, or head will be wrong
        mov bl,18
        div bl
        and al,1     
        mov [head],al
        add ah,1
        mov [sector],ah
        ret

readsector:
        push cx
        mov  ax,[segmentt]
        mov  es,ax
        mov  bx,[offsett]
        mov  ax,0201h
        mov  ch,[cylinder]
        mov  cl,[sector]
        mov  dh,[head]
        mov  dl,0
        int  13h
        pop  cx
        ret

%elif
        ; Load kernel from floppy disk
        ; eforth64 binary code and source code stored at cylinder 1 head 0 sector 1 total 36k
        ; buffer is at 6000:0, will be moved to target position after switched to long mode.

        ; read 18 sectors, 9k , from cylinder 1 head 0 sector 1
        mov ax,0x6000
        mov es,ax
        mov ax,0x0212               ;ah = Function 0x02 read, al = Number of sectors
        xor bx,bx                   ;es:bx = Destination
        mov cx,0x0101               ;cx = Cylinder and sector
        xor dx,dx                   ;dx = Head and drive number
        int 0x13                    ;Int 0x13 Function 0x02 (Load sectors)

        ; read 18 sectors, 9k,  from cylinder 1 head 1 sector 1
        mov ax,0x0212               ;ah = Function 0x02 read, al = Number of sectors
        mov bx,512*18*1             ;es:bx = Destination
        mov cx,0x0101               ;cx = Cylinder and sector
        mov dx,0x0100               ;dx = Head and drive number
        int 0x13                    ;Int 0x13 Function 0x02 (Load sectors)

        ; read 18 sectors, 9k,  from cylinder 2 head 0 sector 1
        mov ax,0x0212               ;ah = Function 0x02 read, al = Number of sectors
        mov bx,512*18*2             ;es:bx = Destination
        mov cx,0x0201               ;cx = Cylinder and sector
        mov dx,0x0000               ;dx = Head and drive number
        int 0x13                    ;Int 0x13 Function 0x02 (Load sectors)

        ; read 18 sectors, 9k,  from cylinder 2 head 1 sector 1
        mov ax,0x0212               ;ah = Function 0x02 read, al = Number of sectors
        mov bx,512*18*3             ;es:bx = Destination
        mov cx,0x0201               ;cx = Cylinder and sector
        mov dx,0x0100               ;dx = Head and drive number
        int 0x13                    ;Int 0x13 Function 0x02 (Load sectors)
%endif        

enablea20:

        ;Enable A20 via port 92h

        in al,92h
        or al,02h
        out 92h,al


;Build page tables
;The page tables will look like this:
;PML4:
;dq 0x000000000000b00f = 00000000 00000000 00000000 00000000 00000000 00000000 10110000 00001111
;times 511 dq 0x0000000000000000

;PDP:
;dq 0x000000000000c00f = 00000000 00000000 00000000 00000000 00000000 00000000 11000000 00001111
;times 511 dq 0x0000000000000000

;PD:
;dq 0x000000000000018f = 00000000 00000000 00000000 00000000 00000000 00000000 00000001 10001111
;times 511 dq 0x0000000000000000

;This defines one 2MB page at the start of memory, so we can access the first 2MBs as if paging was disabled

        xor bx,bx
        mov es,bx
        cld
        mov di,0xa000

        mov ax,0xb00f
        stosw

        xor ax,ax
        mov cx,0x07ff
        rep stosw

        mov ax,0xc00f
        stosw

        xor ax,ax
        mov cx,0x07ff
        rep stosw

        mov ax,0x018f
        stosw

        xor ax,ax
        mov cx,0x07ff
        rep stosw


;Enter long mode

; 這段 CPU mode 的變化情形，進入本程式之前是 real mode
; <bochs:10> c
; (0) Caught mode switch breakpoint switching to 'real mode' Next at t=1851871
; (0) [0x00000000000fb67d] 0020:b67d (unk. ctxt): jmp far f000:b682         ; ea82b600f0
; <bochs:11> creg
; CR0=0x60000010: pg CD NW ac wp ne ET ts em mp pe
; CR2=page fault laddr=0x0000000000000000
; CR3=0x0000000000000000
;     PCD=page-level cache disable=0
;     PWT=page-level write-through=0
; CR4=0x00000000: osxsave pcid fsgsbase smx vmx osxmmexcpt osfxsr pce pge mce pae pse de tsd pvi vme
; EFER=0x00000000: ffxsr nxe lma lme sce

        mov eax,10100000b               ;Set PAE and PGE
        mov cr4,eax

        mov edx, 0x0000a000             ;Point CR3 at PML4
        mov cr3,edx

        mov ecx,0xC0000080              ;Specify EFER MSR

        rdmsr                           ;Enable Long Mode
        or eax,0x00000100
        wrmsr

        mov ebx,cr0                     ;Activate long mode
        or ebx,0x80000001               ;by enabling paging and protection simultaneously
        mov cr0,ebx                     ;skipping protected mode entirely

; 切 CR0 後進入 compatibility mode，因為 EFER long mode 已經 enable 在先。
; <bochs:13> c
; (0) Caught mode switch breakpoint switching to 'compatibility mode'
; Next at t=14633426
; (0) [0x0000000000007c81] 0000:0000000000007c81 (unk. ctxt): lgdt ds:0x7ca3            ; 0f0116a37c
; <bochs:14> creg
; CR0=0xe0000011: PG CD NW ac wp ne ET ts em mp PE
; CR2=page fault laddr=0x0000000000000000
; CR3=0x000000000000a000
;     PCD=page-level cache disable=0
;     PWT=page-level write-through=0
; CR4=0x000000a0: osxsave pcid fsgsbase smx vmx osxmmexcpt osfxsr pce PGE mce PAE pse de tsd pvi vme
; EFER=0x00000500: ffxsr nxe LMA LME sce

        lgdt [gdt.pointer]              ; Bochs see actual instruction code is "LGDT ds:0x7ca3". 
                                        ; load 80-bit gdt.pointer which is defined right below.
                                        ; Bochs 模擬出來: gdtr:base=0x0000000000007c8b, limit=0x17  即
                                        ; 以下 gdt.pointer 所在的位置。
                                        ; LGDT instruction 參考 DS 而所有的 segment register 都是 0000
                                        ; 上面本 MBR 一上手即已備妥。 org 7c00h 也絕對重要。造就這裡 GDTR
                                        ; 正確地得值 7C8B 如上述。 

        CLI                             ;inhibit all interrupts. Should do this before entering long mode I think. hcchen5600 2011/07/17 12:06:40 
        jmp gdt.code:startLongMode      ; Load CS with 64 bit segment and flush the instruction cache
                                        ; Bochs see:  jmp far 0008:7e00 

startLongMode:

                BITS 64

; Move eforth code to forth space.
%if TOTAL512K   ; 512k final version
                mov  rcx,0x80000/4    ; length, move 512K from 0x10000 to 2nd 1M. Simple way.
                mov  rsi,0x10000      ; from
                mov  rdi,0x100000     ; to
                CLD                   ; SI gets incremented
                repz movsd
%elif ; 36K old version
                mov  rcx,0x10000/4    ; length, move 64K from 0x60000 to 2nd 1M. Simple way.
                mov  rsi,0x60000      ; from
                mov  rdi,0x100000     ; to
                CLD                   ; SI gets incremented
                repz movsd
%endif
                
; Now jump into eforth
              ; CLI                      ; inhibit all interrupts. This should be done 
                                         ; before entering long mode. This is a must. Or will be trap to reset f000:fff0 soon.
              ; MOV     AX,CS
              ; MOV     DS,AX            ;all in one segment
              ; MOV     SS,AX
                JMP     FORTH_ENTRY


; Jump 之後正式變成 long mode
; <bochs:15> c
; (0) Caught mode switch breakpoint switching to 'long mode'
; Next at t=14633428
; (0) [0x0000000000007e00] 0008:0000000000007e00 (unk. ctxt): cli                       ; fa
; <bochs:16> creg
; CR0=0xe0000011: PG CD NW ac wp ne ET ts em mp PE
; CR2=page fault laddr=0x0000000000000000
; CR3=0x000000000000a000
;     PCD=page-level cache disable=0
;     PWT=page-level write-through=0
; CR4=0x000000a0: osxsave pcid fsgsbase smx vmx osxmmexcpt osfxsr pce PGE mce PAE pse de tsd pvi vme
; EFER=0x00000500: ffxsr nxe LMA LME sce
; <bochs:17>


;Global Descriptor Table
gdt:
        dq 0x0000000000000000       ;Null Descriptor     第一個 GDT descriptor, 總是 null

.code   equ $ - gdt
        dq 0x0020980000000000       ;                    第二個 code segment

.data   equ $ - gdt
        dq 0x0000900000000000       ;                    第三個 data segment

.pointer:                           ;這是 load GDTR 時要準備好的東西。
        dw $-gdt-1                  ;16-bit Size (Limit)  這是 GDT 的 limit(長度-1)。以上共三個
        dq gdt                      ;64-bit Base Address  這是 GDT 的 base address, 64 bits
                                    ;Changed from "dd gdt"
                                    ;Ref: Intel System Programming Manual V1 - 2.1.1.1


times 510-($-$$) db 0               ;Fill boot sector
        dw 0xAA55                   ;Boot loader signature

        
