
.(  including 01_basics_p1.f ) cr

// Assembler 完成以前就要先用到的 CPU instructions

                   : exit          $c3 c,                      ; immediate
                   : inc[rbx]      $48 c, $FF c, $03 c,        ; immediate \ inc   qword [rbx]
                   : dec[rbx]      $48 c, $FF c, $0B c,        ; immediate \ dec   qword [rbx]
                   : movsx.rbx,bl  $48 c, $0F c, $BE c, $DB c, ; immediate \ movsx rbx,bl
                   : movsx.rbx,bx  $48 c, $0F c, $BF c, $DB c, ; immediate \ movsx rbx,bx
                   : movsx.rbx,ebx $48 c, $63 c, $DB c,        ; immediate \ movsx rbx,ebx
                   : rbx+n8        $48 c, $83 c, $C3 c, c,     ; immediate \ add   rbx,n8
                   : rbx&n8        $48 c, $83 c, $E3 c, c,     ; immediate \ and   rbx,n8
                   : rbp+n8        $48 c, $83 c, $C5 c, c,     ; immediate \ add   rbp,n8

// 原版欠缺的基本功能  ANS Words

\  compile-only    ( -- )
\                  Make the last compiled word an compile-only word.
\                  Refer to eforth86.asm also weforth(fsharp)\F#221\HF0META.F
                   : compile-only
                     COMPO last @ @ or last @ ! ;  \ 不管 1 byte 8 bytes 效果一樣

\ char             ( -<char>- -- char )
\                  Interprete state. Get TIB next word's first char's ASCII

                   : char    bl word 1+ c@ ;

\ [char]           ( -<char>- -- char )
\                  Compile state. Get TIB next word's first char's ASCII

                   : [char]  char  [compile] literal ; immediate

\  [']             ( -<name>- -- ca )
\                  Search context vocabularies for the next word in colon definition.
\                  為何 eforth86.asm 裡沒有 [']？ 因為在 .asm 裡 ['] something 寫成 DOLIT,something 即可。

                   : ['] ' [compile] literal ; immediate

\  <=              ( n1 n2 -- t )
\                  Signed compare of top two items. True if n1 <= n2

                   : <=
                     -         \ n1-n2   原版只有 < 可用
                     1 <       \ (n1-n2) < 1 表示負數或零 n1<=n2
                   ;

\  >               ( n1 n2 -- t )
\                  Signed compare of top two items. True if n1 > n2

                   : > <= not ;

\  >=              ( n1 n2 -- t )
\                  Signed compare of top two items. True if n1 >= n2

                   : >= < not ;

\  <>              ( n1 n2 -- t )
\                  Compare of top two items. True if n1 <> n2

                   : <> = not ;

\  0=              ( n -- t )
\                  Logical NOT, if n==0 then True(-1) else if n!=0 then False(0)
\                  小心！ 'not' 指令是 bitwise 的 1's complement, 相當於 C language 的 ~ operator.
\                  要做 boolean 的「是/非 顛倒」, 相當於 C Language 的 ！ operator, 請用 0= 。

                   : 0= 0 = ;

\  -rot            ( 1 2 3 -- 3 1 2 )
\                  Rotate 3 cells

                   : -rot rot rot ;

\  nip             ( 1 2 -- 2 )
\                  Drop the previous cell in data stack.

                   : nip   [ 8 ] rbp+n8 ;

\  VARIABLE        ( -- ; <string> )
\                  Compile a new variable initialized to 0.

                   : variable  create 0 , ;

\ end-word         ( -- )
\                  word 原本的 data structure 是 [LFA][NFA][CFA][BODY], 新增 [VFA] 指向所屬的 vocabulary wordlist,
\                  [EFA] 指向本 word 之後的位址，而成為 [VFA][EFA][LFA][NFA][CFA][BODY]。
\                  本來打算用 overt 來填寫 EFA VFA, 觀察原版 eforth86 裡只有三個人會用到 overt: COLD 是用 overt
\                  來給 context 的初值; Semicolon 與 colon 相對用來把新字串進 context; create 則是馬上把新 word
\                  串進 context, 其中只有 semicolon 的 overt 是填寫 EFA 的好時機。所以不用 overt 而另創新 word。
\                  平凡一點就叫 end-word， 有點 end-code 的聯想。
\                  last @ 1 cells -  LFA
\                  last @ 2 cells -  EFA  = here
\                  last @ 3 cells -  VFA  = current@

                   create 'end-word ' noop ,  \ 一開始 do nothing.
                   
                   : end-word 
                       'end-word @execute 
                   ;

\
\  does>           hcchen5600 2011/11/15 11:14:09 為 STC 寫的新版 DOES> 才四行就完成了，這應該算很好了。
\                  重點是把 create 產生的第一個 call doVAR 改成 call DOES> 後面的 words，如此而已。該 call 其實
\                  是 jump 連帶取得 PFA。
\                  筆記 see "2011/11/15 10:32  eforth64 STC Create - Does> design" or evernote:///view/2472143/s22/aa0f776e-7de5-4c88-9dff-66817c95ff0d/aa0f776e-7de5-4c88-9dff-66817c95ff0d/
\                  小心 PFA 要多用一個 r> 來取得，這是個缺點還是優點？我覺得是優點，較有彈性。

                   : does>
                       end-word          \ 幫 last word 建立 VFA EFA.
                       last @ name>      \ cfa
                       r>                \ cfa doesEntry   C time code entry point of the create-does class
                       over callsize+ -  \ cfa (doesEntry-(cfa+5))
                       swap 1+ d!        \ (doesEntry-(cfa+5)) cfa+1 => empty
                   ;

\  constant        ( -- )
\                  reate a constant.
\                  From Forth\eforth\weforth(fsharp)\weforth240\cmdline\0STDIO.F

                   : constant
                     create ,
                     does> r> @
                   ;

\  align           ( -- )
\                  Adjust here to next 8 bytes aligned address.

                   : aligned ( a -- a' ) ( 6.1.0706 ) \ align a to 8 bytes boundary a'
                       [  7 ] rbx+n8    \ a = a + (align distance - 1)  \ very good, copy from Win32Forth
                       [ -8 ] rbx&n8    \ a |= -(align distance)
                   ;

                   : align ( -- ) ( 6.1.0705 ) here aligned cp ! ;

\ recurse          ( -- )   6.1.2120
\                  Append the execution semantics of the current definition
\                  to the current definition.

                   : recurse  last @ name> call,  ; immediate

\ >xt              ( cfa -- xt )
\                  STC call or jump instructions are with a related target address.
\                  xt is an execution address, another CFA. When cfa points to a call 
\                  instruction, the related address needs translation.

                   : >xt   ( cfa -- xt )  
                         dup 1+          \ cfa addr+1
                         d@              \ cfa related_address_4bytes
                         movsx.rbx,ebx   \ cfa related_address            sign bit extension 成 64 bits
                         swap            \ related_address cfa
                         callsize+       \ related_address cfa+callsize
                         +               \ xt 
                   ;

\ hcchen5600 2011/12/26 00:36:51 [x] 利用 defer 來把 >name 做成 deferred word 吧！
\ 不行！ defer 會用到 >name. 算了。 >name 還不能用 defer。


\   >NAME          ( ca -- na | F )
\                  Convert code address to a name address.

                   variable '>name
                   : >name(orig)
                       context
                       begin
                         @ dup
                       while
                         2dup name> xor
                         if
                           cell-
                         else
                           swap drop
                           [ $c3 c, ]  \ ret instruction
                         then
                       repeat
                       2drop 0
                   ;
                   ' >name(orig) '>name !    \ 將來 vocabulary 版好了以後要換掉

                   : >name
                       '>name @execute
                   ;

\  defer           ( -- )
\                  defer is a class. Generate deferred word objects.
\                  Proptety is entry point. Method is to execute the entry point.

                   : >body ( cfa -- body )  callsize+ ; \ skip the call instruction at cfa to the next address which is the property of an object, for example.
                   : compiling ( -- yes ) 'eval @ ['] $interpret - ;  \ is compiling mode? Check whether if 'eval == $interpret.
                   : defer
                       create
                         ['] noop ,     \ 取得這個 property 位址的方法是 ' defer.word.name >body 即可。
                       does>
                         [ here ]
                         r> @execute
                   ;

                   constant dodefer     \ 記住 defer.method 的位址。
                   variable (is)
                   defer is immediate  \ is 一開始當然是 noop

                   \ 根據 defer 的定義，see is 看到的是：
                   \     call defer.does>
                   \     DQ noop
                   \ 下面解讀 _is_ 時要用到。hcchen5600 2011/12/17 18:14:26

                   : (_is_) ( n -- )  \ 我猜，這個是 is 的 compiling state 版
                       r>             \ n a         a 回返位址。
                       >body          \ n a+5       回返位址上是 call something, 再下一個位址...是什麼？。
                       dup            \ n a+5 a+5
                       >r ( n a )     \ n a+5 [a+5] 安排好新的 return address
                       dup            \ n a+5 a+5
                       @              \ n a+5 (a+5)
                       +              \ n a+5+(a+5)
                       cell+ ( n ca ) \ n a+5+(a+5)+cell
                       >body ( n pa ) \ n a+5+(a+5)+cell+cell
                       !              \ empty
                       ; \ refined later for more effesion

                   ' (_is_) (is) !    \ compiling state 版的 is 是可以抽換的

                   : _is_ ( interpret: ca <valuename> -- ) ( compiling: <valuename> -- )
                     '                  \ ( v ca )  tick 取得後面那個 deferred word 的 cfa , v is vector 即真正的進入點
                     dup >body          \ ( v ca pa ) 這個 pa 就是後面這個 deferred word 的 property
                     dup                \ ( v ca pa pa )
                     4 -                \ ( v ca pa pa-4 )本來寫成 cell- 這是壞習慣。但改成 4 - 還是不行，細看下去。 。 。
                     d@                 \ ( v ca pa d@(pa-4) )  唉呀 @ 也不對，要改成 d@ 這就不好責怪人了！
                     movsx.rbx,ebx      \ ( v ca pa d@(pa-4) )  這個更厲害 sign bit extension 前人絕對想不到。Bits 改變真是麻煩哪！
                     +                  \ ( v ca ca' )    把 call 的相對位址換算成 linear address
                     dodefer xor        \ ( v ca flag )  防呆檢查，確定 is 後面這個 word 是個 defrred word 的方法就是看它是否 call defer.does> 這點絕對沒錯。
                     over c@ $e8 xor or \ ( v ca flag' )
                     if                 \ ( v ca )
                       cr ." can't put ca into non-defer word "
                       >name count $1F and type
                       abort
                     then               ( v ca )
                     compiling if
                       (is) @ call, call,
                     else
                       >body !
                     then
                   ; immediate

                   ' _is_  _is_ is      \ is 馬上用在自己身上！

\  alias           ( CFA <name> -- )   [x] 改成 STC 之後，有點可疑，white box test needed.
\                  CFA 是 code field address, 即一 word 的進入點，用 tick ' 取得。
\                  例如： ' *debug* alias *bp* 就是產生一個名為 *bp* 的新 word 作用與 *debug* 相同。

                   : alias
                       bl word $,n overt
                       $e9 c, dup                 \ ca ca  where $e9 is "jmp a32"
                       here callsize+ 1- - d,     \ ca ca-(here+4)
                       >name c@ IMEDD and
                       if immediate
                       then
                   ;

                   ' \(orig) alias \s                 \ \s is the official stop compiling marker

\  ?exit           ( boolean -- )
\                  Exit this word. Make sure r@ is this word's return address in prior, that
\                  is to balance the return stack first.

                   : ?exit
                       if
                         r> drop  \ 這個 return address 是本 word 自己的，被丟掉以後
                       then       \ 本 word 的 exit 就變成去抓到 caller 的 return address.
                   ;              \ 因此產生結束該 word 的效果。顯然 return stack 要先 balance。

\  .q 64 bits      ( data -- )
\  .d 32 bits      Print given number in hexdecimal format with leading 0's
\  .w word
\  .b byte

                   : .b                     \ n
                       base @ >r hex        \ n [base]
                       <# # # #> type
                       r> base !            \ empty [empty]
                   ;
                   : .w                     \ n
                       base @ >r hex        \ n [base]
                       <# # # # # #> type
                       r> base !            \ empty [empty]
                   ;
                   : .d                     \ n
                       base @ >r hex        \ n [base]
                       <# # # # # # # # # #> type
                       r> base !            \ empty [empty]
                   ;
                   : .q                     \ n
                       base @ >r hex        \ n [base]
                       <# # # # # # # # # # # # # # # # # #> type
                       r> base !            \ empty [empty]
                   ;

// %%%%%%%%%%%%%%%%%%%% Vocbulary words from Bill Muench's bforth %%%%%%%%%%%%%%%%%%%%%%%%%%%%

\ 引進 vocabulary 之後， last 沒變，但是 context 的意義變了。本來與 last 性質相近，變成退後一階變成本來的 pointer。
\ Was   : Last @ == context @ == Address of last word's counted string name field [length]'name string' (NFA).
\ To be : Last @ == context @ @ == Forth.wordptr @ == NFA
\ context @ == forth.NFA <================ 所有用到 context 的地方都要改
\
\                 wid wordlist             wid wordlist                       wid wordlist
\   context @ --->.--------------.         .--------------.                   .--------------.
\   current @ --->| NFA          |--.  .-->| NFA          |--.  .--> . . . -->|  NULL        |
\   vocs-head --->'--------------'  |  |   '--------------'  |  |             '--------------'
\                 | linkage      |--|--'   | linkage      |--|--'             |  NULL        |
\                 '--------------'  |      '--------------'  |                '--------------'
\                 | nfa voc-name |  |      | nfa voc-name |--|-----.          |  NULL        |
\                 '--------------'  |      '--------------'  |     |          '--------------'
\                                   |                        |     |
\                 .--------------.  |      .--------------.  |     |      FORTH or Assembler one of other vocabularies
\             .---| linkage      |  |  .---| linkage      |  |     |      .--------------.
\             |   '--------------'  |  |   '--------------'  |     |      | LFA          |
\             |   | nfa          |<-'  |   | nfa          |<-'     |      .------.-------'--.
\             |   '--------------'     |   '--------------'        '----> |length| name     |
\             |   | cfa          |     |   | cfa          |               '------'----------'
\             |   '--------------'     |   '--------------'               | call >voc.does> |
\             |                        |                                  '-----------------'
\             |   .--------------.     |   .--------------.               | ptr to wordlist |-----> 上面 wid wordlist 中的一個。
\             |   | linkage      |--.  |   | linkage      |--.            '-----------------'
\             |   '--------------'  |  |   '--------------'  |
\             '-->| nfa          |  |  '-->| nfa          |  |
\                 '--------------'  |      '--------------'  |
\                 | cfa          |  |      | cfa          |  |
\                 '--------------'  |      '--------------'  |
\                                   .                        .
\                                   .                        .
\                                   .                        .
\                 .--------------.  |
\                 | NULL         |  |
\                 '--------------'  |
\                 | nfa          |<-'
\                 '--------------'
\                 | cfa          |
\                 '--------------'
\
\
\  vocs-search-list
\                 .--------------.--------------.          .--------------------------.
\                 | 'wid 0       | 'wid 1       | . . . .  | 'wid #vocs-order-list    |
\                 '--------------'--------------'          '--------------------------'
\
\
\  vocabulary Forth                         vocabulary assembler                     vocabulary ISR
\  ----------------                         --------------------                     --------------------
\
\  FORTH               上面 wid wordlist    Assembler           上面 wid wordlist    ISR                 上面 wid wordlist
\  .--------------.    中的一個。           .--------------.    中的一個。           .--------------.    中的一個。
\  | LFA          |        ^                | LFA          |        ^                | LFA          |        ^
\  .------.-------'--.     |                .------.-------'--.     |                .------.-------'--.     |
\  |length| name     |     |                |length| name     |     |                |length| name     |     |
\  '------'----------'     |                '------'----------'     |                '------'----------'     |
\  | call >voc.does> |     |                | call >voc.does> |     |                | call >voc.does> |     |
\  '-----------------'     |                '-----------------'     |                '-----------------'     |
\  | ptr to wordlist |-----'                | ptr to wordlist |-----'                | ptr to wordlist |-----'
\  '-----------------'                      '-----------------'                      '-----------------'
\
\  method >voc.does> is to re-arrange the order so as to add this wordlist to the top of the order.
\

\  .id             ( na -- )
\                  Display the name at address.

                   : .id
                       ?dup if
                         count $1F and
                         type exit
                       then
                       ." {noName}"
                   ;

    16 constant #vocs-order-list ( search order list )
    create vocs-order-list #vocs-order-list 1+ cells allot ( wids ) vocs-order-list here over - erase \ one more reservation for end of array ending NULL
    create forth-wordlist ( -- wid ) ( 16.6.1.1595 )  \ FORTH 的 instance 實體。
        0 , ( na, of last definition, linked )
        0 , ( wid|0, next or last wordlist in chain )
        0 , ( na, wordlist name pointer )

    create current   ( -- wid )
        forth-wordlist ,      \ new word add to this wordlist

    create vocs-head ( -- wid )
        forth-wordlist ,      \ head of chain 即所有 forth 的頭兒。

  \ create context(vocs) ( -- wid ) forth-wordlist ,   \ 直接用 context 變性，不需另外 create 新東西。
    : get-current ( -- wid ) ( 16.6.1.1643 ) current @ ;
    : set-current ( wid -- ) ( 16.6.1.2195 ) current ! ;
    : definitions ( -- ) ( 16.6.1.1180 ) context @ set-current ;

    : >wid ( wid -- ) cell+ ; \ next wid

    : .wid ( wid -- )       \ print wid name or address
        space               \ wid
        dup                 \ wid wid
        2 cells +           \ wid wid+2cells
        @                   \ wid (wid+2cells)
        ?dup                \ wid [(wid+2cells) (wid+2cells)|0]
        if                  \ wid (wid+2cells)
          .id               \ wid               print (wid+2cells)
          drop              \ empty
          exit              \
        then                \ wid
        0                   \ wid 0
        u.r                 \                   print wid if no name yet
    ;

    : !wid ( wid -- )       \ wid[2] = nfa of last word which is this wordlist's name
        2 cells +           \ wid[2]
        last @              \ wid[2] nfa
        swap                \ nfa wid[2]       wid+2cells = last word's nfa
        !                   \ empty
    ;

    : vocs ( -- ) ( list all wordlists )
        cr ." vocs:" vocs-head
        begin              \ a          head of chain
          @                \ wid
          ?dup             \ (wid wid)|0
        while              \ wid
          dup              \ wid wid
          .wid             \ wid        print wid or print .id(wid+2cells)
          >wid             \ wid+cell   所有的 wordlist 是串起來的，所以個數可以不定啊！#vocs 是個變數。
        repeat             \ a'
    ;

    : wordlist ( -- wid ) ( 16.6.1.2460 )   \ generate a wid structure  \ [ 0 , pointer to previous wid, 0 ]
        align               \ empty                                     \   ^
        here                \ a                                         \   |
        0 ,                 \ a                   compile 0             \   |
        dup                 \ a a                                       \   |
        vocs-head           \ a a (head of wordlist chain)              \   '---------- head of chain vocs-head
        dup                 \ a a chain chain
        @ ,                 \ a a chain           compile first wid of the chain
        !                   \ a                   assign this wid to head of chain
        0 , ;               \ a                   compile 0

    : order@ ( a -- u*wid u )       \ a is context or other forth-wordlist head
        dup                         \ a a
        @                           \ a nfa
        dup                         \ a nfa nfa
        if                          \ a nfa
          >r                        \ a       [nfa]
            cell+                   \ a+cell
            recurse                 \          run this word recursively
          r>                        \ 'nfa 'nfa@==0 head-nfa
          swap 1+                   \ 'nfa head-nfa 'nfa@==0
          exit
        then                        \ a nfa==0
        nip ;                       \

    : get-order ( -- u*wid u ) ( 16.6.1.1647 ) vocs-order-list ( context ) order@ ;
                ( -- widu ... wid2 wid1 u )

    defer sync-context
    : do-sync-context vocs-order-list @ context ! ; \ first item copy to context
    
    : set-order ( u*wid n -- ) ( 16.6.1.2197 )
        dup                         \ widu ... wid2 wid1 u u
        -1 = if                     \ -1
          drop                      \ empty
          forth-wordlist            \ forth           ( 16.6.1.1595 )
          1                         \ forth 1
        then ( default ? )          \ [widu ... wid2 wid1 u] or [forth 1]
        [ #vocs-order-list ]        \ [widu ... wid2 wid1 u] or [forth 1] #vocs=8  如果 #vocs 是個 constant 這兩行全等於簡單寫一個 #vocs [ ]試試看。
        literal                     \ [widu ... wid2 wid1 u] or [forth 1] 8    \ compile 8 into dictionary
        over                        \ widu ... wid2 wid1 u #vocs u
        u<                          \ widu ... wid2 wid1 u #vocs<u   防呆！重要。
        abort" Over size of #vocs-order-list"
        vocs-order-list             \ widu ... wid2 wid1 u VOL
        swap                        \ widu ... wid2 wid1 VOL u
        begin                       \ widu ... wid2 wid1 VOL u
          dup                       \ widu ... wid2 wid1 VOL u u
        while                       \ widu ... wid2 wid1 VOL u
          >r                        \ widu ... wid2 wid1 VOL         [ u ]
          swap                      \ widu ... wid2 VOL wid1
          over                      \ widu ... wid2 VOL wid1 VOL
          !                         \ widu ... wid2 VOL              VOL=wid1
          cell+                     \ widu ... wid2 VOL+cell
          r>                        \ widu ... wid2 VOL+cell n
          1-                        \ widu ... wid2 VOL+cell n-1
        repeat  ( 0 )               \ widu ... wid2 VOL+cell n-1
        swap !                      \ VOL+cell 0 ==>  0 VOL+cell ==> VOL+cell = null end of the list. 所以 #vocs 雖然是 8 allot 時要加一格。
        sync-context                \ first order item copy to context. 等一切布置妥當才開始做，故用 deferred word. 
    ;

    : order ( -- ) ( list search order )
        cr ." search:"
        get-order    \ widn ... wid2 wid1 n
        begin        \ widn ... wid2 wid1 n
           ?dup      \ widn ... wid2 wid1 n n
        while        \ widn ... wid2 wid1 n
           swap      \ widn ... wid2 n wid1
           .wid      \ widn ... wid2 n
           1 -       \ widn ... wid2 n-1
        repeat       \ empty
        cr ." define:"
        get-current  \ wid
        .wid ;       \ empty

    : only ( -- ) -1 set-order ;
    : also ( -- )    \ Also 就是 vocabulary array 的 dup
        get-order    \ widn ... wid2 wid1 n
        over         \ widn ... wid2 wid1 n wid1
        swap         \ widn ... wid2 wid1 wid1 n
        1 +          \ widn ... wid2 wid1 wid1 n+1
        set-order
    ;

    : previous ( -- )   \ previous 就是  vocabulary array 的 drop
        get-order    \ widn ... wid2 wid1 n
        swap         \ widn ... wid2 n wid1
        drop         \ widn ... wid2 n
        1 -          \ widn ... wid2 n-1
        set-order
    ;

    : >voc ( wid 'name' -- )  \ vocabulary-creater class. forth editor 等都是用這個 create 出來的。
        create
          dup      \ wid wid
          ,        \ wid
          !wid     \ wid[2]=the last word name
        does>
          r>
          @        \ wid
          >r          \ empty      [wid]
          get-order   \ widn ... wid2 wid1 n
          swap        \ widn ... wid2 n wid1
          drop        \ widn ... wid2 n
          r>          \ widn ... wid2 n wid [empty]
          swap        \ widn ... wid2 wid n
          set-order
    ;

    : vocabulary ( 'name' -- )
        wordlist \ generate a wid structure
        >voc     \ create a vocabulary name for the given wid structure
    ;

\ hcchen5600 2011/12/21 09:17:03 context 本來是指向 last @ 同樣的地方，最後一 word 的 NFA。現在
\ 要後退一步，改成指向某一個 wordlist, FORTH HIDDEN .. etc, 然後再由 wordlist 指向該 wordlist
\ 的最新 word's NFA。如此一來，所有用到 context 的人全都要改！過渡要得法，先改好所有用到 context
\ 的 words 他們全都改用 context(vocs). 因為 context(vocs) 和 context 最終一樣都是指向 wordlist
\ 所以只要把 vocabulary FORTH 安排好，就可以實驗這些新版 words, 都沒問題之後，讓原版的 words 以
\ 及 context 都變成新版的 alias 即可。

\ These words uses context : context >name words nextword $,n <overt> name?
\ Change them to (vocs) version : >name(vocs) words(vocs) nextword(vocs) $,n(vocs) <overt>(vocs) name?(vocs)
\ context 本身不用出新 word context(vocs) 只要沿用原 word 切換成帶 vocs 的新性質即可。

\ 改寫這些原來用 context 的 words 要把單一數值的 context 擴充成 get-order 所得到的數列。這個動作可以抄
\ order 裡的寫法。他用一個 begin-while-repeat 就解決了。

\   name?          ( a -- ca na | a F )
\   name?(vocs)    Search all context vocabularies for a string.

                   : name?(vocs)
                       >r           \ [ a ]
                       get-order    \ widn ... wid2 wid1 n
                       begin        \ widn ... wid2 wid1 n
                          ?dup      \ widn ... wid2 wid1 n n
                       while        \ widn ... wid2 wid1 n
                          swap      \ widn ... wid2 n wid1
                        \ ----------------------------------
                          r@ swap   \ ... a wid
                          find      \ ... (ca na)|(a F)
                          ?dup      \ ... (ca na na)|(a F)
                          if        \ ... (ca na)|(a)  \ found
                            >r >r   \ widn ... wid2 n [ca na a]
                            1- for aft drop then next  \ clear rest of the order-list
                            r> r> r> drop              \ ca na
                            exit                       \ ca na
                          else                         \ not found in this wordlist
                            drop    \ ...
                          then
                        \ ----------------------------------
                          1 -       \ widn ... wid2 n-1
                       repeat       \ empty
                       r> 0         \ a 0       balance return stack
                   ;

                   \ 成功了！ 實驗方法：先弄出個 counted string : name $" see" ; 正常用法 name name? 就可
                   \ 以傳回 see 的 cfa nfa. 現在把 name 餵給 name?(vocs) 也傳回正確值, Bingo! 多弄幾個
                   \ wordlist: vocabulary assembler vocabulary isr <=== 弄出兩個 wordlist
                   \ also assembler also isr <========= 串進 wordlist order list
                   \ name name?(vocs) 還是一樣正確傳回 see 的 cfa nfa .... 成功！

\ end-word         ( -- )
\                  word 原本的 data structure 是 [LFA][NFA][CFA][BODY], 新增 [VFA] 指向所屬的 vocabulary wordlist,
\                  [EFA] 指向本 word 之後的位址，而成為 [VFA][EFA][LFA][NFA][CFA][BODY]。
\                  本來打算用 overt 來填寫 EFA VFA, 觀察原版 eforth86 裡只有三個人會用到 overt: COLD 是用 overt 來給
\                  context 的初值; Semicolon 與 colon 相對用來把新字串進 context; create 則是馬上把新 word 串進 context,
\                  其中只有 semicolon 的 overt 是填寫 EFA 的好時機。所以不用 overt 而另創新 word。
\                  平凡一點就叫 end-word， 有點 end-code 的聯想。
\                  last @ 1 cells -  LFA
\                  last @ 2 cells -  EFA  = here
\                  last @ 3 cells -  VFA  = current@

                   : end-word(vocs) ( -- )    \ write here to EFA, current@ to VFA of the last word.
                       current @        \ current@       current active vocabulary
                       last @ 2 cells - \ current@ EFA
                       here over        \ current@ EFA here EFA
                       ! cell-          \ current@ VFA
                       !                \ empty
                   ;

\   <overt>        ( -- )
\   overt(vocs)    Default overt. Add new words to 'context' because there's no 'current' yet.
\                  Link a new word into the current vocabulary.
\                  Overt 的字意是「公開」。

                   : overt(vocs)
                       last @ current @ ! \ 本來是 context ! 改成 current @ ! 多間接一層。current@ 指向某個 wordlist. current@@ = wordlist[0] 才是 NFA。
                   ;

                   \ 實驗方法：弄個新 vocabulary aux，also aux definitions
                   \ 加新字之後 overt(vocs) 一下，沿 current trace 看看。
                   \ current = 11F2D4  這是 current 自己的 property 地址
                   \ current@ = 11F880 這是 wordlist 地址，一開始 current@@ = 11F880@ = NULL.
                   \ overt(vocs) 之後，果然 current@@ 指向了新 word 的 NFA 無誤。

\   ;              ( -- )
\                  Terminate a colon definition.
\   ;(vocs)        有了 end-word 之後， semicolon 也要出新版。

                   : ;(vocs)
                       RETT c, [compile] [ overt(vocs) end-word
                   ;  immediate compile-only

                   \ 原版 ; decompiled 出來看是:
                   \    call dolit
                   \    DQ C3
                   \    call c,
                   \    call [
                   \    jmp  overt
                   \ Its forth source should be ": ; $c3 c, [compile] [ overt ;". Where [ is immediate
                   \ therefore we need the leading [compile] to make it compiled here.


\ create           ( -- ; <string> )
\ create(vocs)     有了 end-word 之後， create 也要出新版。

                   : create(vocs)
                       create(orig)
                       end-word
                   ;    

\   $,n            ( na -- )
\   $,n(vocs)      Build a new dictionary name using the string at na.
\                  na is a structure of [link]"counted string", link the sructure into
\                  current vocabulary and adjust HERE.

                   : $,n(vocs)
                       dup               \ na na
                       c@                \ na len     ; ?null input
                       0= abort" name"   \ na
                       ?unique           \ na         ; ( a -- a ) ?redefinition  only display warning message
                       dup               \ na na
                       count             \ na na+1 len
                       +                 \ na na+1+len
                       cp                \ na na+1+len CP
                       !                 \ na             ;skip here to after the name
                       dup               \ na na
                       last              \ na na last
                       !                 \ na             ;save na for vocabulary link
                       cell-             \ na-cell        ;link address
                       current           \ na-cell current
                       @ @               \ na-cell current@@    ;get last word's NFA
                       swap              \ current@@ na-cell    ;this link points to last word's NFA
                       !                 \ empty          ;新 word 的 link 指向原 current
                   ;                     \ 那 current 怎麼不調整？哈！那是 overt 的工作。

                   \ How to test? $,n always works after 'token'. While 'token' returns a counted string
                   \ from user. The counted string is after a cell and the cell is at here. So 'token'
                   \ makes here a structure like this : [link]'word' and '$,n' links this new name to both
                   \ last and current@. Current@@ is still old value, it's adjusted by overt later.
                   \ So, test method is ... : test$,n(vocs) token $,n(vocs) overt(vocs) ; This is to create
                   \ a new name. The new name appears on current list. Check it out.

                   \ 實驗方法：弄個新 vocabulary aux，also aux definitions
                   \ 加新字之後 overt(vocs) 一下，沿 current trace 看看。
                   \ current = 11F2D4  這是 current 自己的 property 地址
                   \ current@ = 11F880 這是 wordlist 地址，一開始 current@@ = 11F880@ = NULL.
                   \ overt(vocs) 之後，果然 current@@ 指向了新 word 的 NFA 無誤。

                   \ vocabulary aux also aux definitions
                   \ : anw token $,n(vocs) overt(vocs) ; \ add new word , for test
                   \ anw new-word anw new1111 anw new22222
                   \ 此時 current @ @ d \ 果然就是 new-word 的 NFA.

\   >NAME          ( ca -- na | F )
\   >name(vocs)    Convert code address to a name address.
\                  要把 cfa 轉成 nfa 還不簡單？但是要確定這個 cfa 是否存在於目前 vocabulary list 裡就得從頭
\                  找一遍才能絕對確定。 即使這個 cfa 確實存在，當前 order 裡找不到也要回 false。

                   \ 原版去掉第一行即變成接受指定 wordlist (or vocabulary or wid all samething) 的基礎版
                   : (>name)  ( ca va -- na | F )
                       begin                 \ ca wid    va 即 wid 相當於 context, wid@ 相當 context@ 即第一個 LFA
                         @ dup               \ ca nfa' nfa'
                       while                 \ ca nfa'
                         2dup name> xor      \ ca nfa' ca^cfa'
                         if                  \ ca nfa'
                           cell-             \ ca nfa'-cell    that's lfa. If this LFA@ is NULL then while loop terminated
                         else                \ ca nfa'
                           nip               \ nfa'
                           exit              \ ret instruction
                         then                \ ca lfa
                       repeat                \ ca lfa
                       2drop 0               \ 0
                   ;

                   : >name(vocs) ( ca -- na | F )
                       >r           \ [ ca ]
                       get-order    \ widn ... wid2 wid1 n
                       begin        \ widn ... wid2 wid1 n
                          ?dup      \ widn ... wid2 wid1 n n
                       while        \ widn ... wid2 wid1 n
                          swap      \ widn ... wid2 n wid1
                        \ ----------------------------------
                          r@ swap   \ ... ca va
                          (>name)   \ ... (na | F)   如果有找到就可以結束，否則要試下一個 vocabulary
                          ?dup if   \ na
                            >r      \ widn ... wid2 n [ca na] 先保留成果，準備要把剩下來的 order list 全丟掉
                            1- for aft drop then next  \ clear rest of the order-list
                            r> r> drop                 \ na
                            exit
                          then
                        \ ----------------------------------
                          1-        \ widn ... wid2 n-1
                       repeat       \ empty
                       r> drop 0    \ Not found, return F.
                   ;

                   \ 測試： ' aux callsize+ @ @ d 即可看到 aux wordlist 底下的幾個 dummy words, which is started
                   \ from the last NFA. Right after the NFA is CFA. Feed the CFA to >name(vocs) got the NFA back
                   \ correctly. Bingo! Try again ' + >name(vocs) got its NFA correctly also. Double bingo!!

\ 引進 vocabulary 之後，新建一變數 vocs.threshold 記錄最後一個轉換前的 NFA，用來取代原本 nextword 裡所用的 context。
\ 此後也沒啥 nextword 可言了，根本不知道 nextword 在哪裡！ 新 words 只知道自己的 EFA 或沿 vocs.threshold 找舊 words
\ 的 newer next word's LFA. 統稱為 EFA 比較合理。

\ [x] forth-wordlist[0] should be pointing to the last word's NFA. But when to
\     do this? Should be when right before changing (orig) words to (vocs)
\     version.  做實驗前，也要隨便弄個值給 forth-wordlist[0] or the context wordlist.

                   forth-wordlist >voc forth
                   only forth \ 這個要先做，否則 get-order 只傳回 0, 不能玩別的 vocabulary words . . .

                   : enable-vocabulary
                       [']      name?(vocs) 'name?    !
                       [']          ;(vocs) ';        !
                       [']        $,n(vocs) '$,n      !
                       [']      >name(vocs) '>name    !
                       [']      overt(vocs) 'overt    !
                       [']     create(vocs) 'create   !
                       [']   end-word(vocs) 'end-word !
                       last @          forth-wordlist !
                       forth-wordlist  context        !
                   ;

                   enable-vocabulary
                   ' do-sync-context is sync-context \ set-order 開始 sync context
                   only forth definitions \ 用上了 definitions 這回連 current 都給定初值

\ vocs.threshold   ( -- a )
\                  equals to the recent context.
\                  vocs 切換前最後一個 none-vocs word 就是 vocs.threshold 自己。

                   here cell+ create vocs.threshold ,

                   \ 實驗： context @ 與 vocs.threshold @ 相等。
                   \ Variable vocs.threshold @ 指在自己的 name NFA 上。所以 vocs.threshold 猶如 newer next word's LFA.
                   \ vocs.threshold @ cell- 是 vocs.threshold 自己的 LFA, 指向前一 word 的 NFA.
                   \ vocs.threshold @ cell- @ d 看得到此處正是前一個 word 的 NFA.

\ hcchen5600 2011/12/23 20:43:03 Study 兩個用到 "token $,n" 之處，也就是 colon : 以及 create, 在 [link]'string'
\ 之前多塞幾個 field 變成 [VFA][EFA][LFA]'string'. 原版 eforth 的 word 功能的確比 Bill Muench 多 reserved
\ 了一個前導的 8 bytes 也就是那個 [LFA], Bee forth 沒有那個。eforth 的 word 比人家多保留一 cell 是有原因的，不
\ 這麼做真的不好改，這麼做也不算有問題，反而是最好的辦法。要改的是 word 裡面保留 cell 數要做成活的。

                   3 cells reserve-word-fields !
                   \ 從此每個 word 都多出兩 cells 於 LFA 之前。這要在 vocabulary.f 裡第一個做。

\ Allocate all official vocabularies 

                   vocabulary hidden
                   vocabulary disassembler
                   vocabulary assembler
                   vocabulary console
                   vocabulary debug
                   vocabulary isr
                   vocabulary mywords
                   
                   only forth 
                   also hidden 
                   also disassembler 
                   also assembler 
                   also isr 
                   also console 
                   also debug 
                   also mywords
                   also \ dummy slot for following definitions



