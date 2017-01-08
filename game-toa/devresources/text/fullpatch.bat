@echo off
pushd ..\lib
call talesinclib.bat
call talesincex.bat
popd
dmd %TALESINCLIB% -run fullpatch.d %*
