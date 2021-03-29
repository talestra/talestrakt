@echo off
pushd ..\..\lib
call talesinclib.bat
popd
call prepare.bat
set path=%path%;..\..\patcher
dmd %TALESINCLIB% -run width.d %*
