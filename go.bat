@echo off
prompt $n$g
if exist project1.exe goto continue
echo.
echo file PROJECT1.EXE not found
echo.
pause
exit
:continue
if exist *.~* del *.~*
if exist "HC-12 config.exe" del "HC-12 config.exe"
rename project1.exe "HC-12 config.exe"
..\upx "HC-12 config.exe"
echo.
pause
