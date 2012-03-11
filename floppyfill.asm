filesize  equ  217528
disksize  equ  80*2*18*512    ; 1474560 bytes diskette size
times disksize-filesize db 0
