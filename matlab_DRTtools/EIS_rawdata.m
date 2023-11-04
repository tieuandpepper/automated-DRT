clc
clear
close

for k = 1:2% change the 10 to the number of files you have
    name = "JZ" + string(k) + ".txt"; %Change name here
    Z= readmatrix(name);
    [row,col] = size(Z);
    j=1;
    for i = 1:row 
        if Z(i,3) < 0
            A(j,:) = Z(i,:);
            j = j+1;
        end
    end
    name = "JZ" + string(k) + "_EIS.txt";
    save(name,'A','-ascii')
    fprintf("raw data " + string(k) + "\n")
end


