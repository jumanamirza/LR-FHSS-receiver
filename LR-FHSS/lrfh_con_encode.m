function [data_out,state]= lrfh_con_encode(state,data,myTrellis,CR)
data_out=[];
for idx=1:length(data)
    data_out=[data_out de2bi( myTrellis.outputs(state+1,data(idx)+1) ,3,'left-msb')];
    state= mod( state*2 + data(idx) , 64); 
end

data_out_cr=[];
idx=1;
if CR~=3
    matrix_ind=1;
    matrix=[1 1 0 0 1 0 1 0 0 0 1 0 1 0 0];
    switch CR
        case 0 %5/6
            matrix_len=15;
        case 1 %2/3
            matrix_len=6;
        case 2 %1/2
            matrix_len=3;
    end
    for j=1:length(data_out)
        if matrix(matrix_ind)
            data_out_cr(idx)=data_out(j);
            idx=idx+1;
        end
        matrix_ind=matrix_ind+1;
        if matrix_ind == matrix_len+1
            matrix_ind=1;
        end
    end
    data_out=data_out_cr;
end

end
