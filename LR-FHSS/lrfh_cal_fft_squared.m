function res = lrfh_cal_fft_squared(thissig)
    res = zeros(1,size(thissig,2));
    for ant=1:size(thissig,1)
        DemodSig = thissig(ant,:);
        fftDemodSig = (fft(DemodSig));
        res = res + abs(fftDemodSig).*abs(fftDemodSig);
    end
