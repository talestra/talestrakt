@..\tcc\tcc.exe complib.c comptoe.c -o ..\comptoe.exe
@upx.exe ..\comptoe.exe > NUL 2> NUL
@copy /Y ..\comptoe.exe c:\util\bin\comptoe.exe > NUL 2> NUL
