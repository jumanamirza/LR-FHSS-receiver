function [deint_hdr]= lrfh_deinterleaving_hdr(header)
deinterleaver=[1, 23, 45, 63, 6, 28, 50, 68, 11, 33, 55, 73, 15, 37, 59, 77, 19, 41, 2, 24, 46, 64, 7, 29, 51, 69, 12, 34, 56, 74, 16, 38, 60, 78, 20, 42, 3, 25, 47,65, 8, 30, 52, 70, 13, 35, 57, 75, 17, 39, 61, 79, 21, 43, 4, 26, 48, 66, 9, 31, 53, 71, 14, 36, 58, 76, 18, 40, 62, 80, 22, 44, 5, 27, 49, 67, 10, 32, 54, 72 ];

temp=[header(2:41) header(74:end)];

deint_hdr=zeros(80,1)';
for idx=1:80
    deint_hdr(idx)=temp(deinterleaver(idx));
end
end