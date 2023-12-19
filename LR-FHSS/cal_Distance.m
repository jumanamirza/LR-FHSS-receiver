function d = cal_Distance(x,y, usesoft)
    if usesoft
        x(x==0) = -1;
        tempp = x(1:length(y))-y;
        d = sum(tempp.*tempp);
    else    
        y(y < 0) = 0;
        y(y > 0) = 1;
        d = sum(xor(x,y));
    end    
end
