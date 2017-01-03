@echo off
cls

php make_bin.php

SET OUTPUT=ymk_es

REM make.bat            -- debugging
REM make.bat release    -- release
REM make.bat fast       -- No zip building

del %OUTPUT%.exe 2> NUL

SET PARAMS=

SET MAIN=src\com.talestra.criminalgirls.main

SET PARAMS=%PARAMS% src\locale
SET PARAMS=%PARAMS% src\patch
SET PARAMS=%PARAMS% src\script
SET PARAMS=%PARAMS% src\arc
SET PARAMS=%PARAMS% src\si_wip

SET PARAMS=%PARAMS% src\lzma\lzma
SET PARAMS=%PARAMS% src\lzma\LzmaDec.obj
SET PARAMS=%PARAMS% src\sfs\sfs
SET PARAMS=%PARAMS% src\sfs\sfs_zip
SET PARAMS=%PARAMS% src\si\si
SET PARAMS=%PARAMS% src\sstring\sstring

SET PARAMS=%PARAMS% res\patcher.res
SET PARAMS=%PARAMS% %MAIN%

IF /I "%1" EQU "fast" GOTO debug

pushd res\data
del ..\archive.zip 2> NUL

echo Building ZIP
IF /I "%1" EQU "release" (
	..\..\util\7za a -tzip ..\archive.zip . -xr!.svn -mx=9 -mm=lzma
) ELSE (
	..\..\util\7za a -tzip ..\archive.zip . -xr!.svn -mx=0 > NUL
)
popd

RCC -32 res\patcher.rc -ores\patcher.res

IF /I "%1" EQU "release" GOTO release

:debug
dfl -debug -Jres %PARAMS% -of%OUTPUT%
GOTO continue

:release
dfl -release -gui -O -inline -Jres %PARAMS% -of%OUTPUT%
upx %OUTPUT%.exe
GOTO continue

:continue
del %OUTPUT%.map 2> NUL
del %OUTPUT%.obj 2> NUL
IF NOT EXIST %OUTPUT%.exe GOTO end
%OUTPUT%.exe
:end