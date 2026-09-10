# test.gp — sample gnuplot script for dotViewer preview
#
# Trigger: issue #29 (add support for source files of gnuplot).
# Extensions covered by the same registry entry: gp, gnuplot, gnu, gpi,
# plt, plot, dem. Filenames covered: gnuplotrc, .gnuplot, .gnuplot_history.

reset
set terminal pngcairo size 800,600 enhanced font "Helvetica,10"
set output "sine.png"

set title "Sine wave — Quick Look preview sample"
set xlabel "x (rad)"
set ylabel "sin(x)"
set grid
set xrange [-2*pi:2*pi]
set yrange [-1.2:1.2]

plot sin(x) with lines linewidth 2 title "sin(x)", \
     cos(x) with lines linewidth 2 dashtype 2 title "cos(x)"

# Loop example (gnuplot 5+)
do for [i=1:3] {
    print sprintf("iteration %d: sin(%d) = %.3f", i, i, sin(i))
}
