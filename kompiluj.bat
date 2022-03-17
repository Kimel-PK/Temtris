del "Temtris (dev).dbg"
del "Temtris (dev).o"
del "Temtris (dev).nes"
ca65 "temtris.asm" -o "Temtris (dev).o" --debug-info
ld65 "Temtris (dev).o" -o "Temtris (dev).nes" -t nes --dbgfile "Temtris (dev).dbg"
"Temtris (dev)".nes