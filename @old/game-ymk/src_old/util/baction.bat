@echo off
dmd util.d arc.d image.d script.d action.d -ofaction.exe
del action.obj
del action.map