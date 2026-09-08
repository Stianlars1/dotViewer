# GAP transcript: input is highlighted, expected output is preserved
#@local f
#@exec Print("Setup — ÆØÅ\n");
gap> Size(Group((1, 2, 3), (1, 2)));
6
gap> f := function(x)
> if x > 0 then
> return "ÆØÅ";
> fi;
> return "empty";
> end;
function( x ) ... end
gap> f(1);
"ÆØÅ"
gap> Print("if true then 42\n");
if true then 42
