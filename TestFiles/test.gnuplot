# Gnuplot preview regression sample (not executed)
set title "Sine waves — ÆØÅ"
set lmargin at screen 0.1
set xrange [0:2*pi]
plot for [i=1:3] sin(i*x) with lines title sprintf("Wave %d", i)
splot sin(x*y)
pause 1
clear
reset
