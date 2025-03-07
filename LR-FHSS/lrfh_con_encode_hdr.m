function [data_out, state]= lrfh_con_encode_hdr(state,data,myTrellis,knowinitstate_flag)
    if knowinitstate_flag
        runnum = 1;
    else
        runnum = 2;
    end
    for count=1:runnum
        data_out=[];
        for idx=1:length(data)
            data_out=[data_out de2bi( myTrellis.outputs(state+1,data(idx)+1) ,2,'left-msb')];
            state= mod( state*2 + data(idx) , 16); 
        end
    end
end
