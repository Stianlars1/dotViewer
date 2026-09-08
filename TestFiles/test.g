# GAP source: groups, functions and Unicode strings
G := Group((1, 2, 3), (1, 2));;
DescribeGroup := function(group)
    local size;
    size := Size(group);
    if size = 6 then
        Print("S3 — ÆØÅ\n");
    fi;
    return size;
end;
DescribeGroup(G);
