
.(  including 05_basics_p2.f ) cr

forth definitions

// Tools           console needs to be ready ASAP so these words are not to be in basics_01.f

\  hi              ( -- )
\                  Greeting message at system cold start.
\                  Show not only eforth64.asm's *version* but also eforth64.f's *revision*.

                   : HI
                      cr ." eforth64 v" version <# # #> type ." ." <# # # #> type ."   forth source code r" revision <# #s #> type cr
                         ." '$300000 d' to see messages before console ready. d again for more." cr 
                         ." Press Crtl key toggle scroll mode. PgUp PdDn Home End and Arrows to scroll." cr
                   ;

                   ' HI 'boot !  \ replace greeting message.


\  .s              ( -- )
\                  豪華版的 .s

                   : .s
                       base @ >r decimal
                       cr ."  Index         Decimal              Hexdecimal" cr
                       depth dup swap
                       for aft               \ depth [depth]
                         r@ 6 .r             \ depth         print index
                         dup r@ -            \ depth depth-index
                         pick                \ depth Xu
                         dup                 \ depth Xu Xu
                         3 spaces 20 .r      \ depth Xu
                         4 spaces .q cr      \ depth
                         nuf?                \ depth stop?        user control
                         if
                           r> drop 0 >r
                         then
                       then next             \ depth
                       drop
                       ."          98765432109876543210     7 6 5 4 3 2 1 0" cr
                       ."                   1         0" cr cr
                       r> base !
                   ;

mywords definitions

\ I/O Reads        ( ioaddress -- data)

                   : iow@                \ IO in word
                       rdx=rbx
                       rax=0
                       in.ax,dx
                       rbx=rax
                   ;

                   : iod@                \ IO in Dword
                       rdx=rbx
                       rax=0
                       in.eax,dx
                       rbx=rax
                   ;

\ I/O Writes       ( data ioaddress --)

                   : iow!                \ IO out word
                       rax=0
                       rdx=rbx
                       $POP_RBX rax=rbx
                       out.dx,ax
                   ;

                   : iod!                \ IO out Dword
                       rax=0
                       rdx=rbx
                       $POP_RBX rax=rbx
                       out.dx,eax
                   ;

\ PCI reads        ( reg bus device func --- data)

                   : pcird                                 \ Read_PCI_Dword
                       $100  * swap   $800  *   +  swap  $10000  *   +   + $80000000 +
                       $0cf8 iod!
                       $0cfc iod@
                   ;
                   : pcirw                                \ Read_PCI_Word
                       $100 * swap $800 * + swap $10000 * +  +  $80000000 +
                       $0cf8 iod!
                       $0cfc iow@
                   ;
                   : pcirb                               \ Read_PCI_Dwor
                       $100 * swap $800 * + swap $10000 * +  + $80000000 +
                       $0cf8 iod!
                       $0cfc iob@
                   ;

\ PCI writes       ( data reg  bus device func --- )
                   : pciwd                                 \ Write_PCI_Dword
                       $100  * swap   $800  *   +  swap  $10000  *   +   + $80000000 +
                       $0cf8 iod!
                       $0cfc iod!
                   ;
                   : pciww                                \ Write_PCI_Word
                       $100 * swap $800 * + swap $10000 * +  +  $80000000 +
                       $0cf8 iod!
                       $0cfc iow!
                   ;
                   : pciwb                               \ Write_PCI_Dwor
                       $100 * swap $800 * + swap $10000 * +  + $80000000 +
                       $0cf8 iod!
                       $0cfc iob!
                   ;

                   : reset $fe $64 iob! ;

\  words           ( -- )
\                  Display the names i the context vocabulary.
\  words(vocs)     Display the words' names in the orderred vocabularies.

forth definitions

                   defer words
                   
                   : <words>  ( wordlist -- )
                       cr
                       begin @ ?dup
                       while dup space .id cell- nuf?
                       until drop then
                   ;
                  
hidden definitions
                   : words(vocs)
                       get-order    \ widn ... wid2 wid1 n
                       begin        \ widn ... wid2 wid1 n
                          ?dup      \ widn ... wid2 wid1 n n
                       while        \ widn ... wid2 wid1 n
                          swap      \ widn ... wid2 n wid1
                        \ ------- 對所有 wordlist in the order 都做一遍 ---------
                          cr ." ---------- " dup .wid ."  ----------"
                          <words> space
                        \ -------------------------------------------------------
                          1 -       \ widn ... wid2 n-1
                       repeat       \ empty
                   ;

                   : words(v3)
                       bl word         \ str
                       dup count nip   \ str length
                       if              \ str
                         name?         \ ca na | a F
                         if            \ ca   \ the given string is a word's name
                           dup         \ ca ca
                           >xt         \ ca xt0
                           ['] forth >xt      \ ca xt0 forth.xt
                           = if               \ ca  the given string is a vocabulary name
                             callsize+ @      \ wordlist
                             <words>
                             exit
                           then        \ ca the given string is not a vocabulary name
                         then          \ list all words with the given string in the name
                         ." Sorry under constructing.  List all word names that contain the given string."  cr
                       else            \ no given string, do the normal job
                         drop words(vocs)
                       then
                   ; 
                   
                   ' words(v3) is words

//  Debug features

debug definitions

                   create debugTIB 128 allot   \ Debug console Terminal Input Buffer.

\  pause           ( n -- )
\                  Pause if pausemode is TRUE, press any key to continue. Press ESC to clear pausemode.
\                  Don't forget to give it a pause ID n that it shows to you so you know which pause point happened.
\                  Press ESC will clear pausemode, so you need to turn it back on manually before you can pause again
\                  next time.

                   : pause
                       pausemode @ 0= if drop exit then
                       base @ swap decimal cr ."  %%%%% Pause" . ."  %%%%% " base !
                       .s
                       ."  Press any key to continue, ESC to skip all following pauses . . . "
                       key 27 = if
                         0 pausemode !
                         cr ."  ESC has turned off pausemode." cr
                         ."  '1 pausemode !' to turn it back on manually." cr
                         ."  Press any key to continue . . . "
                         key drop cr
                       then
                   ;

\  *debug*            ( n -- )
\                  Breakpoint, enter debug mode console.
\                  Breakpoint ID n shows you which breakpoint is happening.

                   : *debug*
                       debugmode @ 2 = if drop exit then
                       1 debugmode !
                       base @ swap decimal cr ."  %%%%% Breakpoint" . ."  %%%%% " cr base !
                       ."  '0 debugmode !' to continue." cr
                       ."  '2 debugmode !' to disable all following *debug*, '0 debugmode !' to re-enable."
                       begin
                         cr ." Debug> "
                         debugTIB 128                 \ tib 128
                         accept                       \ tib length
                         $eval                        \ ...          depends
                       debugmode @ 0 = debugmode @ 2 = or until
                   ;

hidden definitions 

\  newer-next-LFA  ( cfa -- lfa T|F )
\                  Get lfa of the newer next word.
\                  後一個較新的 word 之 LFA 就是本 word 的終點. Kernel 裡的 none-vocs words 可以這樣看。
\                  切入 vocabulary 之後就不能這樣看了，要改用 EFA。

                   : newer-next-LFA     \ was nextword 改用更平凡的 name
                       >r               \ empty [cfa0]    \ lfa  = Newer next word's beginning field.
                       vocs.threshold   \ head of LFAs    \ nfa  = lfa@ , this word's NFA.
                       begin            \ lfa'            \ cfa  = nfa+length+1  nfa>cfa , this word's CFA.
                         dup            \ lfa lfa         \ lfa' = (nfa-cell) next LFA, it points to older previous word's NFA.
                         @              \ lfa nfa
                         name>          \ lfa cfa
                         r@ <>          \ lfa cfa<>cfa0
                       while            \ lfa             \ if cfa==cfa0 the word has found then jump to after the 'then'.
                         @              \ nfa
                         cell-          \ nfa-cell=lfa'
                         dup            \ lfa' lfa'
                         @              \ lfa' nfa'
                         0=             \ lfa' EOL?
                       until            \ lfa'
                         @              \ 0               \ the given cfa is unknown!
                       then             \ lfa|0           \ If the given word is at the last position so the newer word is vocs.threshold itself.
                       ?dup             \ lfa T|F         \ If the given word is vocs.threshold itself what happened?
                       r> drop                            \ vocs.threshold 猶如 newer next word's LFA. 因此它自己的 newer-next-LFA 就是自己的 PFA。
                   ;                                      \ 這樣對 decompiler 沒問題，我的 withData? 處理方式照樣會把 PFA 印出來。

\  >EFA            ( cfa -- EFA@ )
\                  Get the address right after this word.

                   : >efa
                       dup                  \ cfa cfa
                       vocs.threshold <=    \ cfa oldword?     vocs.threshold itself and old word (or kernel word, pre-vocs word)
                       if                   \ cfa
                         newer-next-LFA     \ (lfa T)|F        false means unknown word
                         if else here then  \ lfa              unknown words 隨便給個 here 算了
                       else                 \ cfa              vocs word
                         >name              \ nfa
                         2 cells - @        \ efa@             [vfa][efa][lfa][nfa][cfa][body]
                       then
                   ;

\  SEE             ( -- ; <string> )
\                  Decompiler

hidden definitions

                   : call.what? ( cfa -- nfa T|F )    \ if is a call then return the target address and true. Otherwise false.
                       dup isCall?       \ cfa isCall?
                       if                \ addr
                         >xt        \ xt
                         >name -1        \ (nfa T)
                       else              \ cfa
                         drop 0          \ F
                       then              \ (nfa T)|F
                   ;

                   : isString?  ( cfa -- Yes )   \ is it a string command?
                       >xt >r       \ empty [ xt ]
                       r@ ['] ."|    = if r> drop -1 exit then   \ is ."|
                       r@ ['] $"|    = if r> drop -1 exit then   \ is $"|
                       r@ ['] abort" = if r> drop -1 exit then   \ is abort"
                     \ r@ ['] $,"    = if r> drop -1 exit then   \ is $,"
                       r> drop 0                                  \ is not string
                   ;

                   : withData?  ( cfa -- Yes )   \ is this word has a data after it?
                       >r                   \ empty [cfa]
                       r@ >xt ['] dolit    = if r> drop -1 exit then
                       r@ >xt ['] branch   = if r> drop -1 exit then
                       r@ >xt ['] ?branch  = if r> drop -1 exit then
                       r@ >xt ['] donext   = if r> drop -1 exit then
                       r@ >xt ['] dovar    = if r> drop -1 exit then
                       r@ >xt ['] douser   = if r> drop -1 exit then
                       r> drop 0
                   ;

                   : .cfa>name  ( cfa -- cfa' ) \ decompile the given CFA
                       dup call.what? \ cfa (nfa T|F)
                       if             \ cfa nfa
                         space .id    \ cfa              if is name print name
                         dup withData? if \ cfa
                           callsize+      \ pData
                           space dup @ .q \ pData
                           cell+          \ cfa'
                           exit
                         then             \ cfa
                         dup isString? if   \ cfa
                           callsize+ dup    \ cfa' cfa'
                           space $22 emit space
                           count type       \ cfa'
                           $22 emit
                           dup c@           \ cfa' (cfa')
                           + 1+             \ cfa''
                           exit
                         then
                         callsize+          \ cfa'
                         exit
                       else
                         space
                         disasm1instruction \ cfa' flag ( addr -- addr' flag )
                         -1 = if            \ cfa'      if is unknown then print binary
                           space            \ cfa
                           dup c@ .b        \ cfa
                           1+               \ cfa'
                         then               \ cfa'
                       then
                   ;

forth definitions

                   : (ssee)   ( cfa -- )   \ simplified version 不印每個 word 的地址
                       base @ >r hex   \ [base]
                       dup >efa        \ cfa EFA           EFA is this word's ending address. We should stop there.
                       >r              \ cfa [base EFA]    we should stop on this word's EFA
                       dup cr u. [char] : emit cr \ print cfa:
                       begin           \ cfa
                         dup r@ <      \ cfa cfa<efa
                       while           \ cfa
                         .cfa>name
                         nuf? space    \ cfa' stop?        user control
                       until           \ cfa'
                       then
                       drop            \ empty [base efa]
                       r> drop         \       [base]
                       r> base !       \ empty [empty]
                   ;

                   : ssee ( -- )       \ see simplified version
                       '               \ cfa               cfa is a call dolst usually.
                       (ssee)
                   ;

                   : (see) ( cfa -- )  \ see full version 印出所有 words 的地址
                       base @ >r hex   \ [base]
                       dup >efa        \ cfa EFA           EFA is this word's ending address. We should stop there.
                       >r              \ cfa [base efa]    we should stop at this word's EFA
                       begin           \ cfa
                         dup r@ <      \ cfa cfa<efa
                       while           \ cfa
                         dup cr u. $3A emit
                         .cfa>name
                         nuf? space    \ cfa' stop?        user control
                       until           \ cfa'
                       then
                       drop            \ empty [base efa]
                       r> drop         \       [base]
                       r> base !       \ empty [empty]
                       cr cr ."  Simplified version 'ssee', FYI." cr
                   ;

                   : see ( -- )        \ see full version 印出所有 words 的地址
                       '               \ cfa               cfa is a call dolst usually.
                       (see)
                   ;

\ Memory dump

hidden definitions

                   : dump.type    ( b u -- ) \ print string b length u bytes. Replace none-printable characters with '_'. Subroutine of 'dump'
                       for aft               \ b
                           dup               \ b b
                           c@ >char emit     \ b
                           1+                \ b'
                       then next             \ b'
                       drop
                   ;
                   : dump.PreSpace           ( a -- n ) \ bytes before first character
                     dup                     \ a a
                     $F not and -            \ a-a^fff0
                   ;
                   : dump.LineCount          ( a -- n ) \ bytes of this line
                     $10 swap                \ $10 a
                     $F and -                \ $10-a^0F
                   ;
                   : dump.LeadingSpaces      ( a n -- ) \ according to the starting address print leading spaces
                     >r                      \ a        \ n can be 3 for binary or 1 for character section.
                     dump.PreSpace           \ n
                     for aft
                       rp@ cell+ @ spaces
                     then next
                     r> drop
                   ;
                   : dump.OneLine           ( a -- a' ) \ dump one line
                     dup                    \ a a
                     8 u.r                  \ a
                     space
                     dup                    \ a a
                     3 dump.LeadingSpaces   \ a
                     dup dup dump.LineCount \ a a n
                     for aft                \ a a
                       dup                  \ a a a
                       space c@ .b          \ a a
                       1+                   \ a a'
                     then next              \ a a'
                     swap                   \ a' a
                     2 spaces
                     dup                    \ a' a a
                     1 dump.LeadingSpaces   \ a' a
                     dup dump.LineCount     \ a' a n
                     dump.type              \ a'
                     cr
                   ;

\  dump            ( a u -- )
\                  dump memory from a for u bytes up to the next 16 bytes boundary after a+u.

forth definitions

                   : dump                   \ a u
                       base @ >r hex        \ a u [base]
                       cr ."           00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF" cr
                       over                 \ a u a
                       + >r                 \ a [base a+u]

                       begin                \ a
                         nuf? 0 =           \ a' break?
                       while                \ a'
                         dump.OneLine       \ a'
                         dup r@ >=          \ a' a'>=a+u
                       until                \ a'
                       then                 \ a'

                       drop                 \ empty
                       r> drop              \ empty [base]
                       r> base !            \ empty [empty]
                   ;

\  d               ( a -- a+80 )
\                  dump memory $80 bytes up to the given address's 16 bytes boundary.

                   : d                ( a -- a+$80) \ memory dump
                     dup              \ a a
                     dump.LineCount   \ a cnt
                     2dup             \ a cnt a cnt
                     $70 + dump       \ a cnt a cnt+$70
                     + $70 +          \ a+cnt+$70
                   ;

\  cls             ( -- )
\                  clear screen

                   : cls
                     0 position !         \ move cursor to upper left corner
                     753664 4000 0 fill   \ B8000 80*25*2 erase entire video buffer
                   ;

mywords definitions

\  RDMSR           ( rcx -- rdx rax )
\                  Used CPU instruction RDMSR to read MSR

                   : rdmsr
                     rcx=rbx $POP_RBX
                     <rdmsr>
                     $PUSH_RBX rbx=rdx
                     $PUSH_RBX rbx=rax
                   ;

                   \ Want to try RDMSR ?
                   \ 27  rdmsr .s
                   \ 254 rdmsr .s
                   \ 379 rdmsr .s
                   \ 377 rdmsr .s

\  WRMSR           ( rcx rdx rax -- )
\                  Used CPU instruction WRMSR to write MSR

                   : wrmsr
                       rax=rbx $POP_RBX
                       rdx=rbx $POP_RBX
                       rcx=rbx $POP_RBX
                       <wrmsr>
                   ;

\  cr0!            ( data -- )
\  cr2!            Write data to CR0
\  cr3!            Also cr1! cr2! cr3! cr4!
\  cr4!

                   : cr0!   ( data -- )   \ write data to CR0
                       rax=rbx $POP_RBX
                       cr0=rax
                   ;

                   : cr2!   ( data -- )   \ write data to CR2
                       rax=rbx $POP_RBX
                       cr2=rax
                   ;

                   : cr3!   ( data -- )   \ write data to CR3
                       rax=rbx $POP_RBX
                       cr3=rax
                   ;

                   : cr4!   ( data -- )   \ write data to CR4
                       rax=rbx $POP_RBX
                       cr4=rax
                   ;

\  cr0@            ( -- cr0 )
\  cr2@            Read CR0
\  cr3@            Also cr1@ cr2@ cr3@ cr4@
\  cr4@

                   : cr0@   ( -- cr0 )  \ read CR0
                       rax=0 rax=cr0
                       $PUSH_RBX rbx=rax
                   ;

                   : cr2@   ( -- cr2 )  \ read CR2
                       rax=0 rax=cr2
                       $PUSH_RBX rbx=rax
                   ;

                   : cr3@   ( -- cr3 )  \ read CR3
                       rax=0 rax=cr3
                       $PUSH_RBX rbx=rax
                   ;

                   : cr4@   ( -- cr4 )  \ read CR4
                       rax=0 rax=cr4
                       $PUSH_RBX rbx=rax
                   ;

