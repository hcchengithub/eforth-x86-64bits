
.(  including 06_ISR.f ) cr 

isr definitions

// Interrupt service routines
//                 64 bits new IDTR definitions see http://wiki.osdev.org/Interrupt_Descriptor_Table#IDT_in_IA-32e_Mode_.2864-bit_IDT.29

\  idtr            ( -- [16 bits limit, 64 bits base address, 48 bits 0] )
\                  read IDTR

                   : idtr
                       $1111 $2222    \ reserve two cells for return data. 1111 and 2222 are dummy values
                       sp@            \ 1111 2222 addr    addr points to 2222 which is the TOS
                                      \                   2222 will be written with 16 bits limit. IDTR base address will be 1111[15:0]2222[63:16]
                       sidt[rbx]      \                   save IDTR to the given address
                       $POP_RBX       \ [16 bits limit, 64 bits base address, 48 bits 0]
                   ;

\  idtr!           ( idt -- )
\                  write IDTR
\                  where IDT is address of [16 bits limit][64 bits base address]

                   : idtr!
                         lidt[rbx]
                         $POP_RBX
                   ;

                   \ demo idtr! and idtr (QEMU ok, Bochs will reboot because values are strange)
                   \ hex 1122334455667788 aabbccddeeffabcd sp@ idtr! idtr .s
                   \ 1122334455667788 aabbccddeeffabcd 7788 AABBCCDDEEFFABCD <sp ok  where ABCD is limit, 7788AABBCCDDEEFF is base address
                   \ After reboot, idtr .s 0 3FF <sp

\  exc_has_error   ( -- addr )
\                  This table indicates which interrupt numbers have error code.
\                  see chapter 5 Table 5-1 "LT73 learnings\CPU\IA-32 Software Developer’s Manual Volume 3A System Programming 253668 2008.pdf" 64-bits covered , error code errcode explained there too.

                   create exc_has_error
                       $00 c, $00 c, $00 c, $00 c, \ DB      0,0,0,0,0,0,0,0, 1,0,1,1,1,1,1,0
                       $00 c, $00 c, $00 c, $00 c,
                       $01 c, $00 c, $01 c, $01 c,
                       $01 c, $01 c, $01 c, $00 c,
                       $00 c, $01 c, $00 c, $00 c, \ DB      0,1,0,0,0,0,0,0, 0,0,0,0,0,0,0,0

                   : .isr.msg ( return: int#, cs, ip, errcode, ret -- ) \ print messages when in ISR.
                       r> \ save return address
                       cr
                       r> ."  errcode : " .d cr
                       r> ."  rip     : " .q cr
                       r> ."  cs      : " .w cr
                       r> ."  int#    : " .w cr
                       >r \ restore return address
                   ;

// 後面這些是 ISR。

\ 每個 ISR 結構一樣，執行順序分成三段。

\ (首先)是 createISR 所 create 出來的一小段 ISR entry point. 這段 entry point 每個 ISR 各有一個，故
\ 從中可以區別不同 ISR 給予不同特性。例如部分 exception 有 errorcode，利用這段 code 替沒有 errorcode
\ 的 ISR 補上一個 0 頂替 errorcode 的位置，使所有的 stack frame 都一樣。 stack frame 裡有指定 fcode
\ 的進入點、INT# 等，故後續的工作可以正確銜接。

\ (第二段）是 commonISR assembly code. 真正的工作是第三段 fcode， commonISR 只做 call fcode 前後的
\ stack push - pop 工作，並且 iret 完成整個 ISR.

\ (第三段) fcode 是高階 forth code 寫成，每個 ISR 都各有一個，各自做自己的特殊工作。

\ 以上說明是按執行順序。以下程式撰寫則是 bottom up 後面的先寫，以供前面的參考所要 call 的位址。
\ 看程式要從最底下的 createISR 先看，然後 commonISR ， 最後才看 isr.fcode.xx，如此比較好懂。

\ 試驗 isrxx 時，記得！雖然 isrxx 是個 word 可以 call, 但是它們會用 iretq 結束而多吃掉一格 return
\ stack 這樣當然會當機。所以要用 int xx 去 call 它才對。

\ isr.fcode.nn     ( return: int#, cs, ip, errcode, ret -- )
\                  ISR high level portion. Called from commonISR, return to commonISR or abort.

\ INT3             以下大部分 ISR 都是 fault, trap, exceptions 等，需直接跳進 int3 debug console 
\                  讓 user 手動處理，所以 INT3 要第一個先定義好。
\
\                  在 assembly code 裡面，任何你想中斷的地方埋下 $cc c, 是即 INT 3h break point.
\                  程式就會跑到這裡來，此時你可以與 forth console 交談，進行 debug 工作。

\                  r 命令印出 breakpoint 當時的 registers。 類似 rax@ r15@ 的命令取得個別 registers 的值。
\                  類似 1234 rax! 的命令設定 register 之值回返後生效。

\                  離開 INT3 debug console 的方法是 0 int3mode ! 離開前留在 stack 裡的 data 只能比原來多
\                  不能比原來少; 因為本程式會自動剔除多出來的，然而若非仔細安排，少掉的可能是 return address
\                  那就無法讓程式恢復進行了。

                   create int3.r 30 8 * dup allot int3.r swap erase    \ int3.r buffer all 00's
                   \ rax    int3.r 00 8 * +  \ r10    int3.r 10 8 * +  \ es     int3.r 20 8 * +
                   \ rbx    int3.r 01 8 * +  \ r11    int3.r 11 8 * +  \ rsp'   int3.r 21 8 * +
                   \ rcx    int3.r 02 8 * +  \ r12    int3.r 12 8 * +  \ rbp'   int3.r 22 8 * +
                   \ rdx    int3.r 03 8 * +  \ r13    int3.r 13 8 * +  \ rip    int3.r 23 8 * +
                   \ rsi    int3.r 04 8 * +  \ r14    int3.r 14 8 * +  \
                   \ rdi    int3.r 05 8 * +  \ r15    int3.r 15 8 * +  \
                   \ rsp    int3.r 06 8 * +  \ eflag  int3.r 16 8 * +  \
                   \ rbp    int3.r 07 8 * +  \ cs     int3.r 17 8 * +  \
                   \ r8     int3.r 08 8 * +  \ ds     int3.r 18 8 * +  \
                   \ r9     int3.r 09 8 * +  \ ss     int3.r 19 8 * +  \

                   \ ss rsp eflag cs ip [errcode] rax 'fcode int# <r9> rbx rcx rdx rsi rdi r8 rbp
                   \ +9 +8  +7    +6 +5 +4        +3  +2     +1   +0   -1  -2  -3  -4  -5  -6 -7

                   : int3.r.init ( -- ) \ init int3.r registers
                      push.rbx
                      [ int3.r ] rbx=n64       \
                      [  3 8 * ] rax=[r9+n8]   \ get rax0
                      [  0 8 * ] [rbx+n32]=rax \
                      [ -1 8 * ] rax=[r9+n8]   \ get rbx0
                      [  1 8 * ] [rbx+n32]=rax \
                      [ -2 8 * ] rax=[r9+n8]   \ get rcx0
                      [  2 8 * ] [rbx+n32]=rax \
                      [ -3 8 * ] rax=[r9+n8]   \ get rdx0
                      [  3 8 * ] [rbx+n32]=rax \
                      [ -4 8 * ] rax=[r9+n8]   \ get rsi0
                      [  4 8 * ] [rbx+n32]=rax \
                      [ -5 8 * ] rax=[r9+n8]   \ get rdi0
                      [  5 8 * ] [rbx+n32]=rax \
                      [  8 8 * ] rax=[r9+n8]   \ get rsp0
                      [  6 8 * ] [rbx+n32]=rax \
                      [ -7 8 * ] rax=[r9+n8]   \ get rbp0
                      [  7 8 * ] [rbx+n32]=rax \
                      [ -6 8 * ] rax=[r9+n8]   \ get r80
                      [  8 8 * ] [rbx+n32]=rax \
                      [  0 8 * ] rax=[r9+n8]   \ get r90
                      [  9 8 * ] [rbx+n32]=rax \
                      [ 10 8 * ] [rbx+n32]=r10 \ get r100
                      [ 11 8 * ] [rbx+n32]=r11 \ get r110
                      [ 12 8 * ] [rbx+n32]=r12 \ get r120
                      [ 13 8 * ] [rbx+n32]=r13 \ get r130
                      [ 14 8 * ] [rbx+n32]=r14 \ get r140
                      [ 15 8 * ] [rbx+n32]=r15 \ get r150
                      [  7 8 * ] rax=[r9+n8]   \ get eflag
                      [ 16 8 * ] [rbx+n32]=rax \
                      [  6 8 * ] rax=[r9+n8]   \ get cs
                      [ 17 8 * ] [rbx+n32]=rax \
                      [ 18 8 * ] [rbx+n32]=ds  \ get ds
                      [  9 8 * ] rax=[r9+n8]   \ get ss
                      [ 19 8 * ] [rbx+n32]=rax \
                      [ 20 8 * ] [rbx+n32]=es  \ get es
                      [  5 8 * ] rax=[r9+n8]   \ get rip
                      [ 23 8 * ] [rbx+n32]=rax \
                      pop.rbx
                   ;

                   : int3.r.restore
                      push.rbx
                      [ int3.r ] rbx=n64       \
                      [  0 8 * ] rax=[rbx+n8]  \
                      [  3 8 * ] [r9+n8]=rax   \ restore rax0
                      [  1 8 * ] rax=[rbx+n8]  \
                      [ -1 8 * ] [r9+n8]=rax   \ restore rbx0
                      [  2 8 * ] rax=[rbx+n8]  \
                      [ -2 8 * ] [r9+n8]=rax   \ restore rcx0
                      [  3 8 * ] rax=[rbx+n8]  \
                      [ -3 8 * ] [r9+n8]=rax   \ restore rdx0
                      [  4 8 * ] rax=[rbx+n8]  \
                      [ -4 8 * ] [r9+n8]=rax   \ restore rsi0
                      [  5 8 * ] rax=[rbx+n8]  \
                      [ -5 8 * ] [r9+n8]=rax   \ restore rdi0
                      [  6 8 * ] rax=[rbx+n8]  \
                      [  8 8 * ] [r9+n8]=rax   \ restore rsp0
                      [  7 8 * ] rax=[rbx+n8]  \
                      [ -7 8 * ] [r9+n8]=rax   \ restore rbp0
                      [  8 8 * ] rax=[rbx+n8]  \
                      [ -6 8 * ] [r9+n8]=rax   \ restore r80
                      [  9 8 * ] rax=[rbx+n8]  \
                      [  0 8 * ] [r9+n8]=rax   \ restore r90
                      [ 10 8 * ] r10=[rbx+n8]  \ restore r100
                      [ 11 8 * ] r11=[rbx+n8]  \ restore r110
                      [ 12 8 * ] r12=[rbx+n8]  \ restore r120
                      [ 13 8 * ] r13=[rbx+n8]  \ restore r130
                      [ 14 8 * ] r14=[rbx+n8]  \ restore r140
                      [ 15 8 * ] r15=[rbx+n8]  \ restore r150
                      [ 16 8 * ] rax=[rbx+n32] \
                      [  7 8 * ] [r9+n8]=rax   \ restore eflag
                      [ 17 8 * ] rax=[rbx+n32] \
                      [  6 8 * ] [r9+n8]=rax   \ restore cs
                      [ 18 8 * ] ds=[rbx+n32]  \ restore ds
                      [ 19 8 * ] rax=[rbx+n32] \
                      [  9 8 * ] [r9+n8]=rax   \ restore ss
                      [ 20 8 * ] es=[rbx+n32]  \ restore es
                      [ 23 8 * ] rax=[rbx+n32] \
                      [  5 8 * ] [r9+n8]=rax   \ restore rip
                      pop.rbx
                   ;

\ rax@             ( -- data )
\ rbx@             Get register value at the moment breakpoint happened.
\ . . .            INT3 debug console command.

                   : rax@ int3.r 8 00 * + @ ;   : rbx@ int3.r 8 01 * + @ ; : rcx@   int3.r 8 02 * + @ ;
                   : rdx@ int3.r 8 03 * + @ ;   : rsi@ int3.r 8 04 * + @ ; : rdi@   int3.r 8 05 * + @ ;
                   : rsp@ int3.r 8 06 * + @ ;   : rbp@ int3.r 8 07 * + @ ; : r8@    int3.r 8 08 * + @ ;
                   : r9@  int3.r 8 09 * + @ ;   : r10@ int3.r 8 10 * + @ ; : r11@   int3.r 8 11 * + @ ;
                   : r12@ int3.r 8 12 * + @ ;   : r13@ int3.r 8 13 * + @ ; : r14@   int3.r 8 14 * + @ ;
                   : r15@ int3.r 8 15 * + @ ;   : cs@  int3.r 8 17 * + @ ; : ds@    int3.r 8 18 * + @ ;
                   : ss@  int3.r 8 19 * + @ ;   : es@  int3.r 8 20 * + @ ; : eflag@ int3.r 8 16 * + @ ;
                   : rsp' int3.r 8 21 * + ;     : rbp' int3.r 8 22 * + ;   : rip@   int3.r 8 23 * + @ ;

\ rax!             ( data -- )
\ rbx!             Write value to register value before return to the breakpoint.
\ . . .            INT3 debug console command.

                   : rax! int3.r 8 00 * + ! ;   : rbx! int3.r 8 01 * + ! ; : rcx!   int3.r 8 02 * + ! ;
                   : rdx! int3.r 8 03 * + ! ;   : rsi! int3.r 8 04 * + ! ; : rdi!   int3.r 8 05 * + ! ;
                   : rsp! int3.r 8 06 * + ! ;   : rbp! int3.r 8 07 * + ! ; : r8!    int3.r 8 08 * + ! ;
                   : r9!  int3.r 8 09 * + ! ;   : r10! int3.r 8 10 * + ! ; : r11!   int3.r 8 11 * + ! ;
                   : r12! int3.r 8 12 * + ! ;   : r13! int3.r 8 13 * + ! ; : r14!   int3.r 8 14 * + ! ;
                   : r15! int3.r 8 15 * + ! ;   : cs!  int3.r 8 17 * + ! ; : ds!    int3.r 8 18 * + ! ;
                   : ss!  int3.r 8 19 * + ! ;   : es!  int3.r 8 20 * + ! ; : eflag! int3.r 8 16 * + ! ;
                   : rip!   int3.r 8 23 * + ! ;

\  r               ( -- )
\                  Show registers values at the breakpoint.

                   : r ( --) \ dump int3.r
                       int3mode @ 0 = int3mode @ 2 = or if
                         cr ." Can't be used outside INT3 debug mode?" cr exit
                       then
                       cr
                        ."    rax="   rax@ .q ."  rbx=" rbx@ .q ."  rcx=" rcx@ .q cr
                        ."    rdx="   rdx@ .q ."  rsi=" rsi@ .q ."  rdi=" rdi@ .q cr
                        ."    rsp="   rsp@ .q ."  rbp=" rbp@ .q ."   r8="  r8@ .q cr
                        ."     r9="    r9@ .q ."  r10=" r10@ .q ."  r11=" r11@ .q cr
                        ."    r12="   r12@ .q ."  r13=" r13@ .q ."  r14=" r14@ .q cr
                        ."    r15="   r15@ .q ."   cs="  cs@ .w  ."  ds="  ds@ .w ."  ss=" ss@ .w ."  es=" es@ .w cr
                        ."  eflag=" eflag@ .q ."  rip=" rip@ .q cr
                   ;

                   : whereisit ( a -- )         \ Check which word is the given address in.
                       dup                      \ a a
                       begin                    \ a a'
                         dup >name              \ a a' nfa
                         ?dup if                \ a a' nfa
                           rot                  \ a' nfa a
                           space .q ."  is in " \ a' nfa
                           count type cr drop   \ empty
                           exit
                         then                   \ a a'
                         1- dup                 \ a a-- a--
                         ['] noop here within   \ a a-- [noop a-- here ]?  Note: noop is the first word of eforth64.
                       0= until
                       drop space .q ."  is out of the dictionary." cr
                   ;

                   : isr.fcode.03 ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       int3.r.init
                       r> r> drop r> drop r> drop r> drop >r        \ Drop input arguments. I don't need them.
                       int3mode @ 2 <> if
                         cr cr ."  %%%%% INT3 debug console %%%%%" cr cr
                         ."  '0 int3mode !' to continue. '2 int3mode !' to skip all following INT3." cr
                         ."  'r' to see registers. rax@ and rax! to read and write rax, ditto others." cr
                         ."  Extra data left in data stack will be ignored. Return stack must be balanced" cr
                         ."  before continue. Be aware that rbx is top of data stack. rbp is data stack" cr
                         ."  pointer, rsp is return stack pointer." cr

                         1 int3mode !
                         sp@ rsp' ! rp@ rbp' !          \ 進 int3 debug console 之前先把 stack pointers 保存起來

                         r   \ dump registers

                         cr ."  ----------- top of return stack -------------- " cr
                         space rsp@           @ .q cr 
                         space rsp@ 1 cells + @ .q cr 
                         space rsp@ 2 cells + @ .q cr 
                         space rsp@ 3 cells + @ .q cr 
                         space rsp@ 4 cells + @ .q cr 
                         space rsp@ 5 cells + @ .q cr 
                         space rsp@ 6 cells + @ .q cr 
                         space rsp@ 7 cells + @ .q cr 
                         space rsp@ 8 cells + @ .q cr 
                         
                         begin
                           cr ." INT3> "
                           debugTIB 128                 \ tib 128
                           sti accept                   \ tib length
                           $eval                        \ ...          depends
                         int3mode @ 0= int3mode @ 2 = or until
                         rsp' @ sp! rbp' @ rp!          \ 離開 int3 debug console 之後 restore stack pointers.
                         \ 因為 stack 已有套疊關係，想要故意多留或清掉幾格 stack 也不容易。乾脆還原回去比較保險。
                       then
                       int3.r.restore
                   ;
                       
                   : isr.fcode.00 ( return: int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, Divide Error!" cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort    \ Abort 之前不做 STI 就沒機會了。KB 收不了，變成當機。
                   ;

                   : isr.fcode.01 ( return: int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       ."  ************ CPU debug register triggered **************** "
                       [ ' isr.fcode.03 ] jmp.r32
                   ;

                   : isr.fcode.02 ( return: int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  NMI interrupt." cr
                       [ ' isr.fcode.03 ] jmp.r32
                   ;

                   : isr.fcode.04 ( int#, cs, ip, errcode -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Trap, INTO overflow." cr
                       [ ' isr.fcode.03 ] jmp.r32
                   ;
                   : isr.fcode.05 ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, BOUND Range Exceeded, BOUND instruction." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.06 ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, Invalid Opcode, UD2 instruction." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.07 ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, Device Not Available (No Math Coprocessor)." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.08 ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Abort, Double Fault." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.09 ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, Coprocessor Segment Overrun." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.0a ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, Invalid TSS." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.0b ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, Segment Not Present." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.0c ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, Stack-Segment Fault." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;

                 \ ' isr.fcode.03     
                   : isr.fcode.0d ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, General Protection Fault. " cr
                       ."  Illegal memory reference and other protection checks." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.0e ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, Page Fault." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.reserved ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Intel reserved. Do not use." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.10 ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, x87 FPU Floating-Point Error (Math Fault)." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.11 ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, Alignment Check Fault." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.12 ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Abort, Machine Check Abort." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.13 ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Fault, SIMD Floating-Point Exception. SSE/SSE2/SSE3 floating-point instructions." cr
                       [ ' isr.fcode.03 ] jmp.r32
                     \ sti abort
                   ;
                   : isr.fcode.normal ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> .isr.msg >r
                       ."  Normal Interrupt." cr
                   ;

\ int20h           IRQ0 interrupt service routine.
\                  IRQ0 is 8254 timer's periodical time tick.
\                  Modify 8259 ICW2 moves INT 00h to INT 20h because INT 00~1Fh are reserved by CPU.

                   : EOI ( -- )
                       cli              \ Trick, this is quality!
                       $20 $20 iob!     \ EOI
                       sti nop nop      \ Trick, this is quality!
                   ;

                   : isr.fcode.20  ( return: int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> r> drop r> drop r> drop r> drop >r
                       $46C @ 1+ $46C !                 \ 64-bits counter
                       EOI                              \ end of interrupt
                   ;

\ int21h           IRQ1 interrupt service routine.
\                  IRQ1 is KBC keyboard interrupt.
\                  Modify 8259 ICW2 moves INT 00h to INT 20h because INT 00~1Fh are reserved by CPU.

                   : isr.fcode.21  ( int#, cs, ip, errcode, ret -- ) \ high level portion of ISR routines
                       r> r> drop r> drop r> drop r> drop >r
                       EOI        \ end of interrupt.
                   ;

\  commonISR       ( retrun stack: [eflag] cs ip errcode rax 'fcode int# -- )
\                  ISR assembly code common portion.
\                  [eflag] exists when called by INT xx or IRQ.
\                  注意，這段是 jmp 進來的，不是 call 進來的，所以 stack 裡沒有多一個 return address.

                   :  commonISR                \ retrun stack:
                       push.r9                 \ [eflag] cs ip errcode rax 'fcode int# <r9>  now r9 is like bp
                       r9=rsp                  \
                       push.rbx                \ [eflag] cs ip errcode rax 'fcode int# <r9> ...
                       push.rcx                \
                       push.rdx                \
                       push.rsi                \
                       push.rdi                \
                       push.r8                 \
                       push.rbp                \
                       [ 1 8 * ] push64[r9+n8] \ ( *int#*, cs, ip, errcode, ret -- )
                       [ 6 8 * ] push64[r9+n8] \ ( int#, *cs*, ip, errcode, ret -- )
                       [ 5 8 * ] push64[r9+n8] \ ( int#, cs, *ip*, errcode, ret -- )
                       [ 4 8 * ] push64[r9+n8] \ ( int#, cs, ip, *errcode*, ret -- )
                       [ 2 8 * ] rax=[r9+n8]   \ get 'fcode
                       call.rax                \ ( int#, cs, ip, errcode, ret -- )
                       pop.rbp                 \
                       pop.r8                  \ restoring the regs
                       pop.rdi                 \
                       pop.rsi                 \
                       pop.rdx                 \
                       pop.rcx                 \
                       pop.rbx                 \
                       pop.r9                  \
                       pop.rax                 \ drop the int#
                       pop.rax                 \ drop the 'fcode
                       pop.rax                 \ restore rax
                       [ 8 ] rsp+n8            \ skip errcode
                       iretq                   \
                   ;

\ createISR        ( int# 'fcode -- )
\                  create ISR routine for the given INT#
\                  high level code 可以任意指定, stack protocal 要照 commonISR.

                   : createISR  ( int# 'fcode -- )
                       ['] commonISR       \ int# 'fcode 'commonISR
                       -rot                \ 'commonISR int# 'fcode
                       create              \ eflag cs ip [errcode]
                           here 0 callsize+ - cp !    \ adjust back 'here' pointer
                           over 19 min exc_has_error  \ 'commonISR int# 'fcode int# table
                           + c@            \ 'commonISR int# 'fcode table[int#]
                           if else         \ This interrupt has no errcode, need to push 0
                             $" 0 push64.n8" $iEval  \ eflag cs ip errcode
                           then
                           [compile] push.rax        \ eflag cs ip errcode rax
                           [compile] rax=n64         \ rax='fcode      [ ] 有必要這樣嗎？真的不能直接 push 'fcode 嗎？ 還是 NASM 的 bug?
                           [compile] push.rax        \ eflag cs ip errcode rax 'fcode
                           [compile] rax=n64         \ rax=int#
                           [compile] push.rax        \ eflag cs ip errcode rax 'fcode int#
                           [compile] rax=n64         \ eflag cs ip errcode rax 'fcode int#   now rax='commonISR
                           [compile] jmp.rax         \
                       ( end creating )
                   ;

\ isr              ( -- )
\                  Create ISR
\                  isrxx are unique assembly entry for each ISR. This entry leaves variant 'fcode
\                  and int# on stack then jump to commonISR. Because different 'fcode is given from
\                  stack, commonISR can call the correct fcode for different ISRxx.


                   $00 ' isr.fcode.00       createISR isr00
                   $01 ' isr.fcode.01       createISR isr01
                   $02 ' isr.fcode.02       createISR isr02
                   $03 ' isr.fcode.03       createISR isr03
                   $04 ' isr.fcode.04       createISR isr04
                   $05 ' isr.fcode.05       createISR isr05
                   $06 ' isr.fcode.06       createISR isr06
                   $07 ' isr.fcode.07       createISR isr07
                   $08 ' isr.fcode.08       createISR isr08
                   $09 ' isr.fcode.09       createISR isr09
                   $0A ' isr.fcode.0a       createISR isr0a
                   $0B ' isr.fcode.0b       createISR isr0b
                   $0C ' isr.fcode.0c       createISR isr0c
                   $0D ' isr.fcode.0d       createISR isr0d
                   $0E ' isr.fcode.0e       createISR isr0e
                   $0F ' isr.fcode.reserved createISR isr0f
                   $10 ' isr.fcode.10       createISR isr10
                   $11 ' isr.fcode.11       createISR isr11
                   $12 ' isr.fcode.12       createISR isr12
                   $13 ' isr.fcode.13       createISR isr13
                   $14 ' isr.fcode.reserved createISR isr14
                   $15 ' isr.fcode.reserved createISR isr15
                   $16 ' isr.fcode.reserved createISR isr16
                   $17 ' isr.fcode.reserved createISR isr17
                   $18 ' isr.fcode.reserved createISR isr18
                   $19 ' isr.fcode.reserved createISR isr19
                   $1A ' isr.fcode.reserved createISR isr1a
                   $1B ' isr.fcode.reserved createISR isr1b
                   $1C ' isr.fcode.reserved createISR isr1c
                   $1D ' isr.fcode.reserved createISR isr1d
                   $1E ' isr.fcode.reserved createISR isr1e
                   $1F ' isr.fcode.reserved createISR isr1f

                   $20 ' isr.fcode.20       createISR isr20
                   $21 ' isr.fcode.21       createISR isr21
                 \ $22 ' isr.fcode.normal   createISR isr22
                 \ $23 ' isr.fcode.normal   createISR isr23
                 \ $24 ' isr.fcode.normal   createISR isr24
                 \ $25 ' isr.fcode.normal   createISR isr25
                 \ $26 ' isr.fcode.normal   createISR isr26
                 \ $27 ' isr.fcode.normal   createISR isr27
                 \ $28 ' isr.fcode.normal   createISR isr28
                 \ $29 ' isr.fcode.normal   createISR isr29
                 \ $2a ' isr.fcode.normal   createISR isr2a
                 \ $2b ' isr.fcode.normal   createISR isr2b
                 \ $2c ' isr.fcode.normal   createISR isr2c
                 \ $2d ' isr.fcode.normal   createISR isr2d
                 \ $2e ' isr.fcode.normal   createISR isr2e
                 \ $2f ' isr.fcode.normal   createISR isr2f

                   \ ~~~~ Descripter (segment) definitions for protected mode programming ~~~~   from F55
                   \ #ACS_I_GATE16 $06 ; 16 bits interrupt gate
                   \ #ACS_I_GATE32 ##ACS_I_GATE16 $08 | ; 32 bits interrupt gate
                   \
                   \ #ATTR_GRANULARITY_BYTE $00 ;
                   \ #ATTR_GRANULARITY_4K   $80 ;
                   \ #ATTR_32BIT        $40 ;
                   \ #ATTR_16BIT        $00 ;
                   \
                   \ #ATTR_16bits_1Mmax  ##ATTR_GRANULARITY_BYTE ##ATTR_16BIT | ;
                   \ #ATTR_16bits_4Gmax  ##ATTR_GRANULARITY_4K   ##ATTR_16BIT | $f | ;
                   \ #ATTR_32bits_4Gmax  ##ATTR_GRANULARITY_4K   ##ATTR_32BIT | $f | ;
                   \
                   \ #ACS_PRESENT $80 ;  present segment
                   \ #ACS_CSEG    $18 ;  code segment
                   \ #ACS_DSEG    $10 ;  data segment
                   \ #ACS_CONFORM $04 ;  conforming segment
                   \ #ACS_READ    $02 ;  readable segment
                   \ #ACS_WRITE   $02 ;  writable segment
                   \ #ACS_RING0   $00 ;  ring 0
                   \ #ACS_RING1   $20 ;  ring 1
                   \ #ACS_RING2   $40 ;  ring 2
                   \ #ACS_RING3   $60 ;  ring 3
                   \
                   \ #ACS_CODE  ##ACS_PRESENT ##ACS_CSEG ##ACS_READ  ##ACS_RING0 | | | ;
                   \ #ACS_DATA  ##ACS_PRESENT ##ACS_DSEG ##ACS_WRITE ##ACS_RING0 | | | ;
                   \ #ACS_STACK ##ACS_PRESENT ##ACS_DSEG ##ACS_WRITE ##ACS_RING0 | | | ;

\ ##ACS_INT        ( -- ##ACS_INT )
\                  Compose the common ACCESS constant for interrupt gates

                   $80                                       \ ##ACS_PRESENT
                   $06 ( interrupt gate ) $08 ( 32 bits ) or \ ##ACS_I_GATE32
                   $00                                       \ ##ACS_RING0
                   or or constant ##ACS_INT

\ myIDT            ( -- addr )
\                  Compose my IDT in forth space.
\                  Later, copy this table to actual IDT table pointed by IDTR to avoid alignment problems.
\                  64 bits new IDTR definitions see http://wiki.osdev.org/Interrupt_Descriptor_Table#IDT_in_IA-32e_Mode_.2864-bit_IDT.29

                   create myIDT
                     \ Offset_0~15      Selector   param_cnt   access         Offset_16~31      8 0s and Offset_32~63
                     \ ==============   ========   =========   ============   ===============   ===============
                       ' isr00 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr01 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr02 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr03 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr04 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr05 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr06 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr07 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr08 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr09 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr0a dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr0b dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr0c dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr0d dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr0e dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr0f dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr10 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr11 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr12 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr13 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr14 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr15 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr16 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr17 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr18 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr19 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr1a dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr1b dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr1c dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr1d dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr1e dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr1f dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr20 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                       ' isr21 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr22 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr23 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr24 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr25 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr26 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr27 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr28 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr29 dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr2a dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr2b dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr2c dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr2d dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr2e dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,
                     \ ' isr2f dup w,   08 w,      0 c,        ##ACS_INT c,   dup $10000 / w,   $100000000 / ,

                   \ End of myIDT

\  myIDT.limit     ( -- limit )
\                  Limit of myIDT.

                   here ' myIDT - constant myIDT.limit

\ setup IDTR       ( -- )
\                  Copy myIDT to 0000:0000000000000000, initialize IDTR.

                   myIDT          \ from myIDT
                   0              \ to real IDT
                   myIDT.limit 1+ \ length
                   cmove          \ copy myIDT to real IDT

                   0 myIDT.limit  \ prepare IDTR base address and limit
                   sp@ idtr!      \ write to IDTR
                   drop drop      \ remove temp data

\ 8259 Interrupt controller tools

\ irr@             ( -- IRR )
\                  Read 16 bits Interrupt request registers. Low byte is the master.

                   : irr@
                     $0a $20 iob!  $20 iob@
                     $0a $A0 iob!  $A0 iob@  $100 * +
                   ;

\ isr@             ( -- ISR )
\                  Read 16 bits Interrupt servising registers. Low byte is the master.
\                  EOI ($20 $20 iob! $20 $A0 iob!) clears them one after one.

                   : isr@ ( -- IRR )
                     $0b $20 iob!  $20 iob@
                     $0b $A0 iob!  $A0 iob@  $100 * +

                   ;

\ imr@             ( -- IMR )
\                  Read 16 bits Interrupt mask registers. Low byte is the master.
\                  Bitwise value 1 is disabled.

                   : imr@ ( -- IMR )
                     $21 iob@
                     $A1 iob@  $100 * +
                   ;

\ initialize 8259  ( -- )
\                  Traditional Interrupt controller initialization, init8259.

                   \ Map IRQ0 to INT 20h, IRQ8 to INT 28h

                   $11 $20 iob! \ ICW1 p20 = 00010011b  decelare this 8259 is cascade.
                   $11 $A0 iob! \

                   $20 $21 iob! \ ICW2 p21 = 20h  IRQ0 map to INT 20h
                   $28 $A1 iob! \ ICW2 pA1 = 28h  IRQ8 map to INT 28h

                   $04 $21 iob! \ ICW3 Bitmask for cascade on IRQ 2
                   $02 $A1 iob! \ ICW3 Cascade on IRQ 2

                   $01 $21 iob! \ ICW4 p21 = 01h
                   $01 $A1 iob! \ ICW4 pa1 = 01h

                   \ Mask all IRQ first.

                   $FF $21 iob! \ IMR disable all IRQ
                   $FF $A1 iob! \

\
\  ISR 都準備好了，但是全部 mask 掉。留待後面適當時機開動，只需 unmask 某 bit 即可。
\


