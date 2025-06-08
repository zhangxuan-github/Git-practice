function res = isMemberCell(x,y)
    res = false;
    for i=1:length(y)
        if x == y{i}
            res = true;
            break
        end
    end
end