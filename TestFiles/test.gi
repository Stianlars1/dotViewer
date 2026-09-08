# GAP implementation
InstallGlobalFunction(ReviewGroup, function(n)
    local group;
    group := SymmetricGroup(n);
    return Size(group);
end);
