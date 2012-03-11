
: // 10 parse 2drop ; immediate   // 用 13 會有問題，後面直接 13 10 的情形會吃掉下一行！用 10 就好了。

' // '\ !  \ 把 back slash 的定義換掉，否則照原版 \ 一出現就停止 including source.

// 先把 display 輸出導向一塊 memory 以便看得見 error message.

\   auxtx!         ( c -- )
\                  putchar to stdout.
\                  This is an auxiliary to be used before real word will be ready.

                   \ eforth64.asm R18 之後已經在 cold 之前有多 map 到 2M new page space $200000~$3fffff
                   \ 拿其中 $300000 之後的地方來放 console ready 之前的 message. 用 bochsdbg.exe 就可以
                   \ 輕鬆看見。

                   create auxposition $300000 ,

                   : auxtx!  ( c -- )
                     auxposition @ c!
                     auxposition @ 1+ auxposition !
                   ;

                   ' auxtx! 'emit !   \ 點睛

\   .s(debug)      ( ... -- ... )
\                  Display the contents of the data stack. 簡便版的 .s debug 馬上要用了。
                   
                   : .s(debug)
                       cr depth                      \ stack depth
                       for aft                       \ start count down loop, skip first pass
                         r@ pick .                   \ index stack, display contents
                       then next                     \ loop till done
                       ."  <sp " 
                   ;

.(  including 00_constants.f ) cr

// 系統常數         constant 還未出現之前先這樣用，沒什麼不好。

: revision 560026 ; \ 用 tiny assembler - disassembler
: HIDE  $20 ;  \ lexicon hidden bit   Hide-Reveal is important for code end-code words
: COMPO $40 ;  \ lexicon compile only bit
: IMEDD $80 ;  \ lexicon immediate bit
: CALLL $E8 ;  \ call's op-code
: JMPP  $E9 ;  \ jmp.r32 op-code
: RETT  $C3 ;  \ ret op-code

// Debugger switchs

create int3mode  0 ,  \ 1=正在 int3 mode 中, 0=離開 int3 mode, 2=關掉 int3 mode 功能.
create debugmode 0 ,  \ 1=正在 debug mode 中, 0=離開 debug mode, 2=關掉 debug mode 功能.
create pausemode 1 ,  \ 1=正常使用 pause mode, 0=關掉 pause mode 功能.


