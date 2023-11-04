function out_IP = inner_prod_rbf_1(freq_n, freq_m, epsilon, rbf_type)

%   this function output the inner product of the first derivative of the
%   rbf with respect to log(1/freq_n) and log(1/freq_m)

    a = epsilon*log(freq_n/freq_m);

%   choose among positive definite RBFs
%   choose a function from a switch
    switch rbf_type
        case 'Gaussian'
            out_IP = -epsilon*(-1+a^2)*exp(-(a^2/2))*sqrt(pi/2);
        case 'C0 Matern'
            out_IP = epsilon*(1-abs(a))*exp(-abs(a));
        case 'C2 Matern'
            out_IP = epsilon/6*(3+3*abs(a)-abs(a)^3)*exp(-abs(a));
        case 'C4 Matern'
            out_IP = epsilon/30*(105+105*abs(a)+30*abs(a)^2-5*abs(a)^3-5*abs(a)^4-abs(a)^5)*exp(-abs(a));
        case 'C6 Matern'
            out_IP = epsilon/140*(10395 +10395*abs(a)+3780*abs(a)^2+315*abs(a)^3-210*abs(a)^4-84*abs(a)^5-14*abs(a)^6-abs(a)^7)*exp(-abs(a));
        case 'Inverse quadratic'
            out_IP = 4*epsilon*(4-3*a^2)*pi/((4+a^2)^3);
        case 'Inverse quadric'
            y_n = -log(freq_n);
            y_m = -log(freq_m);
            % could only find numerical version
            rbf_n = @(y) 1./sqrt(1+(epsilon*(y-y_n)).^2);
            rbf_m = @(y) 1./sqrt(1+(epsilon*(y-y_m)).^2);
            % compute derivative
            delta = 1E-8;
            sqr_drbf_dy = @(y) 1/(2*delta).*(rbf_n(y+delta)-rbf_n(y-delta)).*1/(2*delta).*(rbf_m(y+delta)-rbf_m(y-delta));
            out_IP = integral(@(y) sqr_drbf_dy(y),-Inf,Inf);       
        case 'Cauchy'
            if a == 0
                out_IP = 2/3*epsilon;
            else
                num = abs(a)*(2+abs(a))*(4+3*abs(a)*(2+abs(a)))-2*(1+abs(a))^2*(4+abs(a)*(2+abs(a)))*log(1+abs(a));
                den = abs(a)^3*(1+abs(a))*(2+abs(a))^3;
                out_IP = 4*epsilon*num/den;
            end

        otherwise
            warning('Unexpected RBF input.');
    end
%   end switch
    
end

