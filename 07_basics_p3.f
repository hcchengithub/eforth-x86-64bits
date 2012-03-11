
.(  including 07_basics_p3.f ) cr

console definitions

// Basics part III
// These words rely on the readiness of Interrupts.

\ GreenWaitOBF     ( -- )
\                  節能省電的關鍵點是 WaitOBF。 This word is used by waitkscan.

                   : GreenWaitOBF  \ wait until obf raised
                         begin
                           hlt     \ Stop CPU until next interrupt. 節能省電。
                           kbcobf
                         until
                   ;

                   ' GreenWaitOBF 'waitOBF ! \ 開始可以每逢等 keyboard 時都進省電了！

// TSC , CPU Time-Stamp Counter

mywords definitions

\  rdtsc           ( -- tsc )
\                  CPU instruction RDTSC read 64 bits TSC.

                   : rdtsc
                       rax=0 rdx=0
                       <rdtsc>
                       [ 32 ] shl.rdx.n8 or.rax,rdx
                       $PUSH_RBX rbx=rax
                   ;

                   : (tsc-one-tick)       \ raw data
                     \ $Fe $21 iob! sti   \ enable IRQ0
                       $46c @             \ tick0
                       begin              \ tick0
                         dup $46c @       \ tick0 tick0 tick'
                       - -1 <= until
                       rdtsc >r           \                    [tsc1]
                       begin              \ tick0
                         dup $46c @       \ tick0 tick0 tick'
                       - -2 <= until
                       drop               \ empty
                       rdtsc r> -         \ tsc2-tsc1
                     \ $FF $21 iob!       \ disable IRQ0, to avoid all CPU time of VM works on it.
                   ;

                   : sort3  ( a b c -- a' b' c' )  \ sorted a>b>c
                       2dup < if swap then >r      \ a b' [c]
                       2dup < if swap then r>      \ a' b' c'
                       2dup < if swap then         \ a' b' c'
                   ;

                   : tsc-one-tick
                       (tsc-one-tick) (tsc-one-tick) (tsc-one-tick) sort3 drop swap drop
                       (tsc-one-tick) (tsc-one-tick) (tsc-one-tick) sort3 drop swap drop
                       (tsc-one-tick) (tsc-one-tick) (tsc-one-tick) sort3 drop swap drop
                       sort3 drop swap drop \ 這裡用 mid sort 比 average 更穩定得多。
                   ;

\  tsc/ms          ( -- addr )
\                  Variable of 這顆 CPU 每 mS 的 TSC 次數。
\                  必須動態 load 進來，以便適應不同的機器狀態。

                   variable tsc/ms
                   $Fe $21 iob!                          \ enable IRQ0
                   {sti}
                   tsc-one-tick 182 * 10000 / tsc/ms !   \ get TSC count in 1 mS

\  sleep           ( n -- )
\                  Sleep n mS

                   : sleep
                       tsc/ms @ * rdtsc + \ targetTSC
                       begin
                         dup              \ targetTSC targetTSC
                       rdtsc <= until     \ targetTSC targetTSC<=tsc
                       drop
                   ;

console definitions

                   : ClearKB ( -- ) \ clear keyboard buffer
                       begin
                         $60 iob@ drop \ drop all KBC data
                         5 sleep       \ delay 5 mS for KBC internal latency
                         kbcobf 0=     \ OBF all cleared
                       until
                   ;

                   ClearKB

// Scroll buffer
//                 這個是 display buffer 擴展。 讓螢幕上已經 scroll 出去了的部分還可以 scroll 回來看。
//                 照理應該用 Scroll Lock 鍵來切換 normal/scroll mode, 因為 Windows 下 VM 可能收不到
//                 Scroll Lock key, 所以改用 Ctrl Key 來切換。切成 Scroll mode 之後，Cursor 就消失了，
//                 由此看出進了 Scroll mode, 此時有 Up, Down, PageUp, PageDown, Home, End 等 key 可用
//                 來上下滾動 display buffer。 這個功能只在 local 機器上有用，remote control 無效，因
//                 為其效果要依賴 $B8000 display memory map 的特性。

                   400 constant scrollbuffersize ( lines )
                   create scrollbuffer 80 2 * scrollbuffersize * dup allot scrollbuffer swap erase

                   : >scrollbuffer  ( -- )
                     scrollbuffer dup           \ buffer buffer
                     80 2 * + swap              \ buffer+(80*2) buffer ( from to )
                     scrollbuffersize 26 -      \ buffer+(80*2) buffer scrollbuffersize-26
                     80 * 2 *                   \ from to (scrollbuffersize-26)*80*2
                     cmove                      \ empty
                     $b8000                     \ $b8000 (from)
                     scrollbuffer               \ $b8000 buffer
                     scrollbuffersize 26 - 80 * 2 * + \ $b8000 buffer+(scrollbuffersize-26)*80*2
                     80 2 *                     \ from to length
                     cmove                      \ empty
                   ;

                   : newscroll  ( -- )
                     >scrollbuffer
                     $b8000 dup 80 2 * + swap 80 24 * 2 * cmove
                     80 24 * p2scr 80 2 * 0 fill
                   ;

                   : #screen    ( line# -- )  \ show screen start from line#
                     80 * 2 * scrollbuffer +  \ from
                     $b8000                   \ to
                     80 25 2 * *              \ length
                     cmove
                   ;

                   : ScrollLock
                     $b8000
                     scrollbuffer scrollbuffersize 25 - 80 * 2 * +
                     80 25 2 * *
                     cmove
                     scrollbuffersize 25 - >r      \ #line
                     begin
                       waitkscan  \ scan
                       dup 72 = if    \ up
                         r> 1- 0 max >r
                       then
                       dup 80 = if    \ down
                         r> 1+ scrollbuffersize 25 - min >r
                       then
                       dup 73 = if    \ page up
                         r> 25 - 0 max >r
                       then
                       dup 81 = if    \ page down
                         r> 25 + scrollbuffersize 25 - min >r
                       then
                       dup 71 = if    \ home
                         r> drop 0 >r
                       then
                       dup 79 = if    \ end
                         r> drop scrollbuffersize 25 - >r
                       then
                       r@ #screen
                     dup 29 = swap 28 = or until       \ Ctrl or Enter
                     r> drop
                     scrollbuffersize 25 - #screen
                   ;

                   ' newscroll 'scroll !  \ 把原來的 scroll 功能換掉成新功能

// 省電版的 ?rx , QEMU 模擬時也非常省 CPU。加上用 Ctrl key 來 scroll 螢幕，更好用了。

\  green?rx        ( -- F | ascii T )
\                  wait for a key press and then return ASCII code

                   : green?rx
                       position @ p2scr w@ if
                         hidecursor
                       else
                         showcursor
                       then
                       hlt \ CPU halt until next time tick. console?rx 本身無法省電，必須外加。
                       console?rx dup if
                         hidecursor
                         over 01 = if   \ I make Ctrl keys' ASCII code be 01 for ScrollLock control
                           ScrollLock   \ Press Crtl to enter ScrollLock mode
                           drop drop 0  \ drop
                         then
                       then
                   ;

                   ' green?rx '?key !   \ 畫龍

debug definitions
                   ' *debug* alias *bp*
forth definitions
                   ' <=      alias =<
                   ' >=      alias =>
                   ' <>      alias !=

