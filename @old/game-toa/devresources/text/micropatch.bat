@echo off
pushd ..\lib
call talesinclib.bat
popd

dmd %TALESINCLIB% -run micropatch.d %*
