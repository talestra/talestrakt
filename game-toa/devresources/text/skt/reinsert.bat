@echo off
call prepare.bat
dmd %TALESINCLIB% -run reinsert.d %*
