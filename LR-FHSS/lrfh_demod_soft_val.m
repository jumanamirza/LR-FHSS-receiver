function [k, b] = lrfh_demod_soft_val(insig, W)
    A = size(insig,1);
    N = size(insig,2);
    kcoef = sum(W)*(N*(N+1)*(2*N+1)/6 - N*(N+1)*(N+1)/4);
    mulhere = repmat([1:N],A,1);
    winsig = zeros(A,N);
    for a=1:A
        winsig(a,:) = insig(a,:)*W(a);
    end
    tempp1 = sum(sum(winsig.*mulhere));
    tempp2 = sum(sum(winsig))*(N+1)/2;
    k = (tempp1-tempp2)/kcoef;
    for a=1:A
        b(a) = mean(insig(a,:)) - (N+1)/2*k;
    end