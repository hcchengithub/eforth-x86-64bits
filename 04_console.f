
.(  including 04_console.f ) cr

console definitions

// Console I/O

\ ************ 8042 direct access **********************************************************************
create SCAN2ASCII                            \ == scan code ==
  $00 c,                                     \ db 0                                     ; 0
  $1B c,                                     \ db 01bh            ;esc                  ; 1
  $31 c, $32 c, $33 c, $34 c, $35 c, $36 c,  \ db '1234567890-='                        ; 2-13
  $37 c, $38 c, $39 c, $30 c, $2D c, $3D c,
  $08 c, $09 c,                              \ db 08h,09h         ;backspace, tab       ; 14,15
  $71 c, $77 c, $65 c, $72 c, $74 c, $79 c,  \ db 'qwertyuiop[]'                        ; 16-27
  $75 c, $69 c, $6F c, $70 c, $5B c, $5D c,
  $0D c, $01 c,                              \ db 00dh,000h       ;enter, left control  ; 28,29 ScrolLock 收不到，改用 Ctrol
  $61 c, $73 c, $64 c, $66 c, $67 c, $68 c,  \ db 'asdfghjkl;',027h,'`'                 ; 30-41
  $6A c, $6B c, $6C c, $3B c, $27 c, $60 c,
  $00 c,                                     \ db 000h            ;left shift           ; 42
  $5C c,                                     \ db '\'                                   ; 43
  $7A c, $78 c, $63 c, $76 c, $62 c, $6E c,  \ db 'zxcvbnm,./'                          ; 44-53
  $6D c, $2C c, $2E c, $2F c,
  $00 c,                                     \ db 000h            ;right shift          ; 54
  $2A c,                                     \ db '*'             ;* in keypad          ; 55
  $00 c,                                     \ db 000h            ;left alt             ; 56
  $20 c,                                     \ db ' '             ;space                ; 57
  $00 c,                                     \ db 000h            ;capslock             ; 58
  $00 c, $00 c, $0000000000000000 ,          \ times 10 db 000h   ;f1-f10               ; 59-68
  $00 c, $00 c,                              \ db 000h,000h       ;numlock, scroll lock ; 69-70
  $2D000000 d, $2B000000 d,                  \ db 0,0,0,'-',0,0,0,'+',0,0,0,0,0 ;keys in keypad  ; 71-83
  $00 c, $00 c, $00 c, $00 c, $00 c,
  $00 c, $00 c,                              \ db 000h,000h       ;f11, f12             ; 84,85

\ Shift按下時的ScanCode到ASCII碼的轉換錶，若無對應ASCII碼，則值為0
create SCAN2ASCSHIFT
  $00 c,                                    \ DB 0               0
  $1B c,                                    \ DB 01BH            1     ;ESC
  $21 c, $40 c, $23 c, $24 c, $25 c, $5E c, \ DB '!@#$%^&*()_+'  2-13
  $26 c, $2A c, $28 c, $29 c, $5F c, $2B c,
  $08 c, $09 c,                             \ DB 08H,09H         14,15 ;BACKSPACE, TAB
  $51 c, $57 c, $45 c, $52 c, $54 c, $59 c, \ DB 'QWERTYUIOP{}'  16-27
  $55 c, $49 c, $4F c, $50 c, $7B c, $7D c,
  $0D c, $01 c,                             \ DB 00DH,000H       28,29 ;ENTER, LEFT CONTROL
  $41 c, $53 c, $44 c, $46 c, $47 c, $48 c, \ DB 'ASDFGHJKL:"~'  30-41
  $4A c, $4B c, $4C c, $3A c, $22 c, $7E c,
  $00 c,                                    \ DB 000H            42    ;LEFT SHIFT
  $7C c,                                    \ DB '|'             43
  $5A c, $58 c, $43 c, $56 c, $42 c, $4E c, \ DB 'ZXCVBNM<>?'    44-53
  $4D c, $3C c, $3E c, $3F c,
  $00 c,                                    \ DB 000H            54    ;RIGHT SHIFT
  $2A c,                                    \ DB '*'             55    ;* in KEYPAD
  $00 c,                                    \ DB 000H            56    ;LEFT ALT
  $20 c,                                    \ DB ' '             57
  $00 c,                                    \ DB 000H            58    ;CAPSLOCK
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c, \ DB 000H X 10       59-68 ;F1-F10
  $00 c, $00 c, $00 c, $00 c, $00 c, $00 c, \ DB 000H,000H       69-70 ;NUMLOCK, SCROLL LOCK
  $37 c, $38 c, $39 c, $2D c, $34 c, $35 c, \ DB '789-456+1230.' 71-83 ;KEYPAD When NUMLOCK is on
  $36 c, $2B c, $31 c, $32 c, $33 c, $30 c,
  $2E c,
  $00 c, $00 c,                             \ DB 000H,000H       84,85 ;F11, F12

\  scan2asc        ( scan_code table -- ASCII_code )
\                  Translate keyboard scan code from 8042 port 60h to ASCII code
\                  Given a normal table SCAN2ASCII or shifted table SCAN2ASCSHIFT.

                   : scan2asc
                     swap dup     \ t c c
                     85 >         \ t c c>85
                     if           \ t c         cmp     bl,85           ; 85 key only
                                  \             jbe     .be85           ; below or equal 85
                       drop 0     \ t 0         xor     rbx,rbx         ; ignore the scan code.
                     then         \ t c .be85:  xor     rax,rax
                                  \ t c         mov     al,[SCAN2ASCII + rbx]
                     +            \ &table[c]
                     c@           \ table[c]
                   ;              \           push    rax
                                  \           $NEXT

\  kbcobf          ( -- f )
\                  check KBC OBF

                   : kbcobf
                     $64 iob@
                     $01 and
                   ;

                   \ This word will need a green version
                   : <waitOBF>
                       begin
                         ( hlt 目前還不能用，待後面 Time tick 建設完畢以後再用新版的置換省電功能進來 )
                         kbcobf  ( wait until obf raised )
                       until
                   ;

                   create 'waitOBF ' <waitOBF> ,   \ make it a chang-able function for green version later

                   : waitOBF
                       'waitOBF @execute
                   ;

\  waitkscan       ( -- scancode )
\                  wait for a key press and then return scan code

                   : waitkscan
                       begin
                         waitOBF
                         $60 iob@           \ p60
                         dup                \ p60 p60
                         $80 and 0 =        \ p60 p60%80h==0?   Make code
                         if                 \ p60
                           1                \ p60 1   success it's a make code, done, return the make code.
                         else
                           drop 0           \ failed  it's a break code
                         then
                       until ;

\  p2scr           ( position -- addr )
\                  Translate cursor position to text video buffer address   hcchen5600 2011/08/07 16:46:22
\                  for eforth64 MBR floppy system only.

                   : p2scr
                     2 * $b8000 +
                   ;

\  <showcursor>    ( w -- )
\                  Show cursor, the given word is your cursor character and attribute.
\                  w=0x07DB to show cursor, w=0 to hide cursor.

                   : <showcursor>
                     position @ p2scr w!
                   ;

\  showcursor      ( -- )
\                  Show cursor   hcchen5600 2011/08/07 16:46:22
\                  for eforth64 MBR floppy system only.

                   : showcursor
                     $07DB <showcursor>
                   ;

\  hidecursor      ( -- )
\                  Hide cursor   hcchen5600 2011/08/07 16:46:22
\                  for eforth64 MBR floppy system only.

                   : hidecursor
                     0 <showcursor>
                   ;

\  ?rx             ( -- F | ascii T )
\                  wait for a key press and then return ASCII code

                   : console?rx
                     \ showcursor
                       kbcobf  if
                         $60 iob@ dup dup dup $80 and 0 =      \ p60 p60 p60 p60&80h==0?
                         if                                    \ p60 p60 p60 it's a make code
                           42 = if                             \ p60 p60 p60==42? Left Shift key's scan code
                             drop drop waitkscan
                             SCAN2ASCSHIFT scan2asc 1          \ 先按一下 shift 再按要 shift 的 key, 這是最簡單的辦法了。
                           else
                             54 = if
                               drop waitkscan
                               SCAN2ASCSHIFT scan2asc 1
                             else
                               SCAN2ASCII scan2asc 1
                             then
                           then
                         else
                           drop drop drop 0
                         then
                       else
                         0
                       then
                     \ hidecursor
                   ;

\  scroll          ( -- )
\                  text screen scroll up one line

                   : <scroll>
                     $b8000 dup 80 2 * + swap 80 24 * 2 * cmove
                     80 24 * p2scr 80 2 * 0 fill
                   ;

                   create 'scroll ' <scroll> ,

                   : scroll
                     'scroll @execute
                   ;

\  TX!             ( c -- )
\                  Send character c to the output device.

                   : consoletx!
                     dup 8 =                   \ c c=BackSpace?
                     if                        \ c
                       drop                    \ empty
                       position @ 1- 0 max
                       position !
                       exit
                     then                      \ c
                     dup 10 =                  \ c c=LineFeed
                     if                        \ c
                       drop
                       position @ 80 +         \ p+80 equals to a Line-Feed
                       2000 over               \ p+80 2000 p+80     80*25==2000
                       <= if                   \ p+80
                         scroll 80 -           \ p
                       then                    \ p+80
                       position !              \ empty
                       exit
                     then                      \ c
                     dup 13 =                  \ c c=CarriageReturn
                     if                        \ c
                       drop
                       position @ dup          \ p p
                       80 mod -                \ p-(p%80)
                       position !              \ empty
                       exit
                     then                      \ c
                     $0700 +                   \ $07cc
                     position @ p2scr w!       \ empty
                     position @ 1+ dup 2000 >= \ p' f
                     if                        \ p' empty
                       scroll
                       80 24 * p2scr 80 2 * 0 fill
                       80 -                    \ p'-80
                     then                      \ empty
                     position !
                   ;

80 18 * position !

' console?rx '?key !   \ 畫龍
' consoletx! 'emit !   \ 點睛

.( -------------------- eforth64 console ready -------------------- ) cr


