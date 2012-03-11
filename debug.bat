if not %COMPUTERNAME%==WKS-31EN5913 goto lt73
:tm4740
"%programfiles%\Bochs-2.4.6\bochsdbg.exe"  -q -f "64bits-MBR-TM4740.bxrc"      
goto end     

:lt73
"%programfiles%\Bochs-2.4.6\bochsdbg.exe"  -q -f "64bits-MBR.bxrc" 

:end