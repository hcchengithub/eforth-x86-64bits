@echo off
rem This program boots up eforth64 floppy image floppy.img on a virtual machine simulated by QEMU 64bits mode
rem The same floppy image works fine on Bochs virtual machine too. It's good for debugging.
rem hcchen5600 2011/08/14 08:54:59 

if not exist qemu-system-x86_64.exe echo qemu-system-x86_64.exe not found && goto :abort
if not exist fmod.dll echo fmod.dll not found, QEMU needs it. && goto :abort
if not exist SDL.dll echo SDL.dll not found, QEMU needs it. && goto :abort
if not exist bios.bin echo bios.bin not found, QEMU needs it. && goto :abort
if not exist pxe-e1000.bin echo pxe-e1000.bin not found, QEMU needs it. && goto :abort
if not exist vgabios-cirrus.bin echo vgabios-cirrus.bin not found, QEMU needs it. && goto :abort

qemu-system-x86_64.exe -M pc -boot a -L . -m 32 -localtime -fda floppy.img
goto :bye

:abort
echo .
echo .
echo    !!!!! A B O R T E D !!!!!!!!
echo QEMU virtual machine needs below files,
echo     qemu-system-x86_64.exe 
echo     fmod.dll 
echo     SDL.dll 
echo     bios.bin 
echo     pxe-e1000.bin 
echo     vgabios-cirrus.bin 
echo .
echo .

:bye
