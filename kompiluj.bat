del temtris.dbg
del temtris.o
del temtris.nes
ca65 temtris.asm -o temtris.o --debug-info
ld65 temtris.o -o temtris.nes -t nes --dbgfile temtris.dbg
temtris.nes
IF EXIST "temtris.nes" GOTO dziala
pause
:dziala