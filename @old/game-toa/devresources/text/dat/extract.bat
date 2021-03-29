@echo off
call prepare.bat
dmd %TALESINCLIB% -run extract.d %*
