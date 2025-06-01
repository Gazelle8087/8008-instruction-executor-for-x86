ml /Fl 8008em.asm 
if errorlevel 1 goto exit
copy 8008em.exe 8008em.bin
symdeb 8008em.bin < 8008EM.pat
:exit
