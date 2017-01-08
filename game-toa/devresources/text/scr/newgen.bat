@echo off
call prepare.bat
dmd %TALESINCLIB% -run newgen.d %*
