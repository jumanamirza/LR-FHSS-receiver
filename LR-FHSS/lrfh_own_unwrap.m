function outp = lrfh_own_unwrap(inp, maxdiff)
    outp = inp;
    consts2pi = 2*pi*[-1,0,1];
    for ant=1:size(outp,1)
        lastvalid = 1;
        for h=2:size(outp,2)
            options = outp(ant, h) + consts2pi;
            [a,b] = min(abs(options - outp(ant, lastvalid)));
            if a < maxdiff*(h-lastvalid)
                thisadj = consts2pi(b); 
                outp(ant, h:end) = outp(ant, h:end) + thisadj;
                if lastvalid < h-1
                    thisdelta = (outp(ant,h) - outp(ant,lastvalid))/(h-lastvalid);
                    outp(ant, lastvalid+1:h-1) = outp(ant,lastvalid) + thisdelta*[1:h-lastvalid-1];
                end
                lastvalid = h;
            else
                AAA = 0;
            end
        end
    end