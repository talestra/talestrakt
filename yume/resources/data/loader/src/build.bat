@echo off
\dev\tcc\tcc -o../yumemiru_loader.dll -shared yumemiru_loader_dll.c
dmd procwin.d yumemiru_loader_exe.d -of"yumemiru_loader.exe" -L/exet:nt/su:windows:4.0
copy /y yumemiru_loader.exe ..\yumemiru_loader.exe
del yumemiru_loader.exe
del yumemiru_loader.map
del yumemiru_loader.obj