@echo off
dir /s /b *.d *.obj > lib.lst
dmd -c @lib.lst -Ltales.lib
del *.obj
del lib.lst