
@rem usage floppyfill.bat imagefile.bin
@echo off
set filesize=%~z1
echo filesize  equ  %filesize%
echo disksize  equ  80*2*18*512    ; 1474560 bytes diskette size
echo times disksize-filesize db 0
