%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MIT License
%
% Copyright (c) 2020 ciuccislab
%
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = DRTtools(varargin)
% Begin initialization code - DO NOT EDIT

    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @import1_OpeningFcn, ...
                       'gui_OutputFcn',  @import1_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
        
end
% End initialization code - DO NOT EDIT


% --- Executes just before import1 is made visible.
function import1_OpeningFcn(hObject, eventdata, handles, varargin)
%   check if optimzation toolbox is available
    if ~license('test', 'Optimization_Toolbox')

        error('***Optimization Toolbox licence is missing, DRTtools terminated***')
        close(DRTtools)

    end
    
%   Add path for the src folder
    startingFolder = pwd;
    fun_path = strcat(startingFolder,'\src');
    addpath(fun_path,'-end');
    p = mfilename('fullpath');  % get the path of the current script
    fp = genpath(fileparts(p));    % get all the subdirectories in this folder
    addpath(fp);    % add all subfolders to current path      

%   Set up inital value
    handles.output = hObject;
    set(handles.dis_button,'Value',1)
    set(handles.plot_pop,'Value',1)
    set(handles.derivative,'Value',1)
    set(handles.shape,'Value',1)
    set(handles.value,'String','1E-3')
    set(handles.coef,'String','0.5')
    set(handles.inductance,'Value',1)
    set(handles.panel_drt, 'Visible', 'on');
    set(handles.running_signal, 'Visible', 'off');

    handles.rbf_type = 'Gaussian';
    handles.data_used = 'Combined Re-Im Data';
    handles.lambda = 1e-3;
    handles.coeff = 0.5;
    handles.shape_control = 'FWHM Coefficient';
    handles.der_used = '1st-order';    
%   method_tag: 'none': havnt done any computation, 'simple': simple DRT,
%               'credit': Bayesian run, 'BHT': Bayesian Hibert run
    handles.method_tag = 'none'; 
    handles.data_exist = false;
    
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = import1_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;


% --- Import data button.
function import_button_Callback(hObject, eventdata, handles)

%     startingFolder = 'C:\*';
%     if ~exist(startingFolder, 'dir')
% %       if that folder doesn't exist, just start in the current folder.
%         startingFolder = pwd;
%     end
% 
%     [baseFileName, folder] = uigetfile({ '*.mat; *.txt; *.csv*','Data files (*.mat, *.txt,*.csv)'}, 'Select a file');
% 
%     fullFileName = fullfile(folder, baseFileName);
% 
%     [folder,baseFileName,ext] = fileparts(fullFileName);

%%
startingFolder = 'C:\*';
if ~exist(startingFolder, 'dir')
%       if that folder doesn't exist, just start in the current folder.
    startingFolder = pwd;
end
directory = uigetdir;
cd(directory);
d = dir('*.txt');
% 
for indexx = 1: length(d)


    fullFileName = string(d(indexx).folder) + "\" + string(d(indexx).name);

    [folder,baseFileName,ext] = fileparts(fullFileName);



%% 
%     if ~baseFileName
% %       User clicked the Cancel button.
%         return;
%     end

    switch ext
        case '.mat' % User selects Mat files.
            storedStructure = load(fullFileName);
            A = [storedStructure.freq,storedStructure.Z_prime,storedStructure.Z_double_prime];
            
            handles.data_exist = true;

        case '.txt' % User selects Txt files.
        %   change comma to dot if necessary
            fid  = fopen(fullFileName,'r');
            f1 = fread(fid,'*char')';
            fclose(fid);

            baseFileName = strrep(f1,',','.');
            fid  = fopen(fullFileName,'w');
            fprintf(fid,'%s',baseFileName);
            fclose(fid);

            A = dlmread(fullFileName);
            
        %   change back dot to comma if necessary    
            fid  = fopen(fullFileName,'w');
            fprintf(fid,'%s',f1);
            fclose(fid);
            
            handles.data_exist = true;

        case '.csv' % User selects csv.
            A = csvread(fullFileName);
            
            handles.data_exist = true;

        otherwise
            warning('Invalid file type')
            handles.data_exist = false;
    end

%   find incorrect rows with zero frequency
    index = find(A(:,1)==0); 
    A(index,:)=[];
    
%   flip freq, Z_prime and Z_double_prime so that data are in the desceding 
%   order of freq 
    if A(1,1) < A(end,1)
       A = fliplr(A')';
    end
    
    handles.freq = A(:,1);
    handles.Z_prime_mat = A(:,2);
    handles.Z_double_prime_mat = A(:,3);
    
%   save original freq, Z_prime and Z_double_prime
    handles.freq_0 = handles.freq;
    handles.Z_prime_mat_0 = handles.Z_prime_mat;
    handles.Z_double_prime_mat_0 = handles.Z_double_prime_mat;
    
    handles.Z_exp = handles.Z_prime_mat(:)+ 1i*handles.Z_double_prime_mat(:);
    
    handles.method_tag = 'none';
    
    inductance_Callback(hObject, eventdata, handles)
    EIS_data_Callback(hObject, eventdata, handles)

%%
    handles = regularization_button_Callback(hObject, eventdata, handles);
    Export_DRT_Data_Callback(hObject, eventdata, handles);
end
%%
guidata(hObject,handles)


% --- Selecting the type of discretization
function dis_button_Callback(hObject, eventdata, handles)

    str = get(handles.dis_button,'String');
    val = get(handles.dis_button,'Value');

    handles.rbf_type = str{val};

    if strcmp(handles.rbf_type,'Piecewise linear')
        set(handles.RBF_option, 'Visible', 'off');
    else
        set(handles.RBF_option, 'Visible', 'on');
    end

guidata(hObject,handles) 


% --- Selecting treatment to the inductance data
function inductance_Callback(hObject, eventdata, handles)

    if ~handles.data_exist
        return
    end

    switch get(handles.inductance,'Value')
        case 1 %keep data fitting without inductance
            handles.freq = handles.freq_0;
            handles.Z_prime_mat = handles.Z_prime_mat_0;
            handles.Z_double_prime_mat = handles.Z_double_prime_mat_0; 

            handles.Z_exp = handles.Z_prime_mat(:)+ i*handles.Z_double_prime_mat(:);

        case 2 %keep data fitting with inductance
            handles.freq = handles.freq_0;
            handles.Z_prime_mat = handles.Z_prime_mat_0;
            handles.Z_double_prime_mat = handles.Z_double_prime_mat_0; 

            handles.Z_exp = handles.Z_prime_mat(:)+ i*handles.Z_double_prime_mat(:);

        case 3 %discard data
            is_neg = -handles.Z_double_prime_mat(:)<0;
            index = find(is_neg==1);
            handles.Z_double_prime_mat(index) = [];
            handles.Z_prime_mat(index) = [];
            handles.freq(index) = [];

    end

    handles.Z_exp = handles.Z_prime_mat(:)+ i*handles.Z_double_prime_mat(:);
    handles.method_tag = 'none';
    EIS_data_Callback(hObject, eventdata, handles)

guidata(hObject,handles) 


% --- Selecting the order of derivative for regularization
function derivative_Callback(hObject, eventdata, handles)

    str = get(hObject,'String');
    val = get(hObject,'Value');

    handles.der_used = str{val};

guidata(hObject,handles) 


% --- Entering the regularization parameter
function value_Callback(hObject, eventdata, handles)

    handles.lambda = abs(str2num(get(handles.value,'String')));
 
 guidata(hObject,handles) 

 
% --- Selecting the kind of data used for fitting
function data_used_Callback(hObject, eventdata, handles)

    str = get(hObject,'String');
    val = get(hObject,'Value');

    handles.data_used = str{val};

guidata(hObject,handles) 


% --- RBF shape control option
function shape_Callback(hObject, eventdata, handles)

    str = get(hObject,'String');
    val = get(hObject,'Value');

    handles.shape_control = str{val};

guidata(hObject,handles) 


% --- Input to the RBF shape
function coef_Callback(hObject, eventdata, handles)

    handles.coeff = str2double(get(handles.coef,'String'));
 
 guidata(hObject,handles) 

 
% --- Simple regularization
function handles = regularization_button_Callback(hObject, eventdata, handles)

    if ~handles.data_exist
        return
    end

    set(handles.running_signal, 'Visible', 'on');

%   bounds ridge regression
    handles.lb = zeros(numel(handles.freq)+2,1);
    handles.ub = Inf*ones(numel(handles.freq)+2,1);
    handles.x_0 = ones(size(handles.lb));

    handles.options = optimset('algorithm','interior-point-convex','Display','off','TolFun',1e-15,'TolX',1e-10,'MaxFunEvals', 1E5);

    handles.b_re = real(handles.Z_exp);
    handles.b_im = imag(handles.Z_exp);

%   compute epsilon
    handles.epsilon = compute_epsilon(handles.freq, handles.coeff, handles.rbf_type, handles.shape_control);

%   calculate the A_matrix
    handles.A_re = assemble_A_re(handles.freq, handles.epsilon, handles.rbf_type);
    handles.A_im = assemble_A_im(handles.freq, handles.epsilon, handles.rbf_type);

%   adding the resistence column to the A_re_matrix
    handles.A_re(:,2) = 1;
    
%   adding the inductance column to the A_im_matrix if necessary
    if  get(handles.inductance,'Value')==2
        handles.A_im(:,1) = 2*pi*(handles.freq(:));
    end
    
%   calculate the M_matrix
    switch handles.der_used
        case '1st-order'
            handles.M = assemble_M_1(handles.freq, handles.epsilon, handles.rbf_type);
        case '2nd-order'
            handles.M = assemble_M_2(handles.freq, handles.epsilon, handles.rbf_type);
    end

%   Running ridge regression
    switch handles.data_used
        case 'Combined Re-Im Data'
            [H_combined,f_combined] = quad_format_combined(handles.A_re, handles.A_im, handles.b_re, handles.b_im, handles.M, handles.lambda);
            handles.x_ridge = quadprog(H_combined, f_combined, [], [], [], [], handles.lb, handles.ub, handles.x_0, handles.options);

            %prepare for HMC sampler
            handles.mu_Z_re = handles.A_re*handles.x_ridge;
            handles.mu_Z_im = handles.A_im*handles.x_ridge;

            handles.res_re = handles.mu_Z_re-handles.b_re;
            handles.res_im = handles.mu_Z_im-handles.b_im;

            sigma_re_im = std([handles.res_re;handles.res_im]);

            inv_V = 1/sigma_re_im^2*eye(numel(handles.freq));

            Sigma_inv = (handles.A_re'*inv_V*handles.A_re) + (handles.A_im'*inv_V*handles.A_im) + (handles.lambda/sigma_re_im^2)*handles.M;
            mu_numerator = handles.A_re'*inv_V*handles.b_re + handles.A_im'*inv_V*handles.b_im;
            
        case 'Im Data'
            [H_im,f_im] = quad_format(handles.A_im, handles.b_im, handles.M, handles.lambda);
            handles.x_ridge = quadprog(H_im, f_im, [], [], [], [], handles.lb, handles.ub, handles.x_0, handles.options);

            %prepare for HMC sampler
            handles.mu_Z_re = handles.A_re*handles.x_ridge;
            handles.mu_Z_im = handles.A_im*handles.x_ridge;

            handles.res_im = handles.mu_Z_im-handles.b_im;
            sigma_re_im = std(handles.res_im);

            inv_V = 1/sigma_re_im^2*eye(numel(handles.freq));

            Sigma_inv = (handles.A_im'*inv_V*handles.A_im) + (handles.lambda/sigma_re_im^2)*handles.M;
            mu_numerator = handles.A_im'*inv_V*handles.b_im;

        case 'Re Data'
            [H_re,f_re] = quad_format(handles.A_re, handles.b_re, handles.M, handles.lambda);
            handles.x_ridge = quadprog(H_re, f_re, [], [], [], [], handles.lb, handles.ub, handles.x_0, handles.options);

            %prepare for HMC sampler
            handles.mu_Z_re = handles.A_re*handles.x_ridge;
            handles.mu_Z_im = handles.A_im*handles.x_ridge;

            handles.res_re = handles.mu_Z_re-handles.b_re;
            sigma_re_im = std(handles.res_re);

            inv_V = 1/sigma_re_im^2*eye(numel(handles.freq));

            Sigma_inv = (handles.A_re'*inv_V*handles.A_re) + (handles.lambda/sigma_re_im^2)*handles.M;            
            mu_numerator = handles.A_re'*inv_V*handles.b_re;

    end
    
    warning('off','MATLAB:singularMatrix')
    handles.Sigma_inv = (Sigma_inv+Sigma_inv')/2;
    handles.mu = handles.Sigma_inv\mu_numerator; % linsolve
    
%   method_tag: 'none': havnt done any computation, 'simple': simple DRT,
%               'credit': Bayesian run, 'BHT': Bayesian Hilbert run
    handles.method_tag = 'simple'; 

    handles = deconvolved_DRT_Callback(hObject, eventdata, handles);
    set(handles.running_signal, 'Visible', 'off');

guidata(hObject,handles);


%%%--- Bayesian run
function bayesian_button_Callback(hObject, eventdata, handles)

    if ~handles.data_exist
        return
    end    

    handles = regularization_button_Callback(hObject, eventdata, handles);

    set(handles.running_signal, 'Visible', 'on');

%   Running HMC sampler
    handles.mu = handles.mu(3:end);
    handles.Sigma_inv = handles.Sigma_inv(3:end,3:end);
    handles.Sigma = inv(handles.Sigma_inv);

    F = eye(numel(handles.x_ridge(3:end)));
    g = eps*ones(size(handles.x_ridge(3:end)));
    initial_X = handles.x_ridge(3:end)+100*eps;
    sample = str2num(get(handles.sample_number,'String'));

    if sample>=1000
        handles.Xs = HMC_exact(F, g, handles.Sigma, handles.mu, true, sample, initial_X);
        % handles.lower_bound = quantile(handles.Xs(:,500:end),.005,2);
        % handles.upper_bound = quantile(handles.Xs(:,500:end),.995,2);
        handles.lower_bound = quantile_alter(handles.Xs(:,500:end),.005,2,'R-5');
        handles.upper_bound = quantile_alter(handles.Xs(:,500:end),.995,2,'R-5');
        handles.mean = mean(handles.Xs(:,500:end),2);

        set(handles.running_signal, 'Visible', 'off');
        handles.method_tag = 'credit'; 

    else
        set(handles.running_signal, 'Visible', 'off'); 
        error('***Sample number less than 1000, the HMC sampler would not start***')

    end

    handles = deconvolved_DRT_Callback(hObject, eventdata, handles);

guidata(hObject,handles)


%%%--- BHT run
function BHT_button_Callback(hObject, eventdata, handles)

    if ~handles.data_exist
        return
    end    

    set(handles.running_signal, 'Visible', 'on');
    
    omega_vec = 2*pi*handles.freq;
    N_freqs = numel(handles.freq);
    N_taus = numel(handles.freq);
    
%   Step 1 construct the A matrix, A_H_matrix
    handles.epsilon = compute_epsilon(handles.freq, handles.coeff, handles.rbf_type, handles.shape_control);

    A_re_0 = assemble_A_re(handles.freq, handles.epsilon, handles.rbf_type);
    A_im_0 = assemble_A_im(handles.freq, handles.epsilon, handles.rbf_type);

    handles.A_H_re = A_re_0(:,3:end);
    handles.A_H_im = A_im_0(:,3:end);

%   add resistence column and inductance column to A_re and A_im, remove
%   the unused zero column from A_re_0 and A_im_0
    handles.A_re = [ones(N_freqs,1),A_re_0(:,3:end)];
    handles.A_im = [omega_vec,A_im_0(:,3:end)];
    
    handles.b_re = real(handles.Z_exp);
    handles.b_im = imag(handles.Z_exp);

%   Step 2 construct L_matrix
    switch handles.der_used
        case '1st-order'
            handles.M = assemble_M_1(handles.freq, handles.epsilon, handles.rbf_type);
            
        case '2nd-order'
            handles.M = assemble_M_2(handles.freq, handles.epsilon, handles.rbf_type);
            
    end

    handles.M = handles.M(2:end,2:end);
    
%   Step 3 testing HT_single_est 
%   try until no error occur for the HT_single_est
    while true
        try
            % Randomly select three inital points between 10^4 to 10^-4 for optimization
            theta_0 = 10.^(8*rand(3,1)-4);
            out_dict_real = HT_single_est(theta_0, handles.b_re, handles.A_re, handles.A_H_im, handles.M, N_freqs, N_taus); % for v2 it input the  
            out_dict_imag = HT_single_est(out_dict_real.theta, handles.b_im, handles.A_im, handles.A_H_re, handles.M, N_freqs, N_taus);
            break
            
        catch
            disp('Error Occur, Try Another Inital Condition')
            
        end
    end
    
%   Step 4 testing EIS scoring
    N_MC_samples = 50000;

    handles.out_scores = EIS_score(theta_0, handles.freq, handles.Z_exp, out_dict_real, out_dict_imag, N_MC_samples);

%   Step 5 print out scores
    fprintf('The EIS scores are as follow:\n');
    fprintf('s_res_re = %f %f %f\n', handles.out_scores.s_res_re);
    fprintf('s_res_im = %f %f %f\n', handles.out_scores.s_res_im);
    fprintf('s_mu_re = %f \n', handles.out_scores.s_mu_re);
    fprintf('s_mu_im = %f \n', handles.out_scores.s_mu_im);
    fprintf('s_HD_re = %f \n', handles.out_scores.s_HD_re);
    fprintf('s_HD_im = %f \n', handles.out_scores.s_HD_im);
    fprintf('s_JSD_re = %f \n', handles.out_scores.s_JSD_re);
    fprintf('s_JSD_im = %f \n', handles.out_scores.s_JSD_im);
    fprintf('opt_theta_real = %f %f %f\n', out_dict_real.theta);
    fprintf('opt_theta_imag = %f %f %f\n', out_dict_imag.theta);

%   Step 6 shows the band and the hilbert fitting in the real part and the imag part
%   1. real data
%   1.1 Bayesian regression
    handles.mu_Z_re = out_dict_real.mu_Z;
    handles.cov_Z_re = diag(out_dict_real.Sigma_Z);

    handles.mu_R_inf = out_dict_real.mu_gamma(1);
    handles.cov_R_inf = diag(out_dict_real.Sigma_gamma);
    handles.cov_R_inf = handles.cov_R_inf(1);

%   1.2 DRT part
    handles.mu_Z_DRT_re = out_dict_real.mu_Z_DRT;
    handles.cov_Z_DRT_re = diag(out_dict_real.Sigma_Z_DRT);

%   1.3 HT prediction
    handles.mu_Z_H_im = out_dict_real.mu_Z_H;
    handles.cov_Z_H_im = diag(out_dict_real.Sigma_Z_H);

%   1.4 estimated sigma_n
    handles.sigma_n_re = out_dict_real.theta(1);

%   1.5 estimated mu_gamma
    handles.mu_gamma_re = out_dict_real.mu_gamma;

%   2. imaginary data
%   2.1 Bayesian regression
    handles.mu_Z_im = out_dict_imag.mu_Z;
    handles.cov_Z_im = diag(out_dict_imag.Sigma_Z);

    handles.mu_L_0 = out_dict_imag.mu_gamma(1);
    handles.cov_L_0 = diag(out_dict_imag.Sigma_gamma);
    handles.cov_L_0 = handles.cov_L_0(1);

%   2.2 DRT part
    handles.mu_Z_DRT_im = out_dict_imag.mu_Z_DRT;
    handles.cov_Z_DRT_im = diag(out_dict_imag.Sigma_Z_DRT);

%   2.3 HT prediction
    handles.mu_Z_H_re = out_dict_imag.mu_Z_H;
    handles.cov_Z_H_re = diag(out_dict_imag.Sigma_Z_H);

%   2.4 estimated sigma_n
    handles.sigma_n_im = out_dict_imag.theta(1);

%   2.5 estimated mu_gamma
    handles.mu_gamma_im = out_dict_imag.mu_gamma;

%   prepare for plotting the fit
    handles.mu_Z_H_re_agm = handles.mu_R_inf + handles.mu_Z_H_re;
    handles.band_re_agm = sqrt(handles.cov_R_inf + handles.cov_Z_H_re + handles.sigma_n_im^2);

    handles.mu_Z_H_im_agm = omega_vec*handles.mu_L_0 + handles.mu_Z_H_im;
    handles.band_im_agm = sqrt((omega_vec.^2)*handles.cov_L_0 + handles.cov_Z_H_im + handles.sigma_n_re^2);

%   residual of Hilbert DRT
    handles.res_H_re = handles.mu_Z_H_re_agm-handles.b_re;
    handles.res_H_im = handles.mu_Z_H_im_agm-handles.b_im;

%   change the method_tag that we have conducted bht run.
    handles.method_tag = 'BHT';

    handles = deconvolved_DRT_Callback(hObject, eventdata, handles);

    set(handles.running_signal, 'Visible', 'off');

guidata(hObject,handles)


% --- Plotting EIS curve and switching to the plot
function EIS_data_Callback(hObject, eventdata, handles)

    if ~handles.data_exist
        return
    end
    
    axes(handles.axes_panel_drt)
    
    if strcmp(handles.method_tag,'BHT') 
        plot(handles.mu_Z_re, -handles.mu_Z_im,'-k', 'LineWidth', 3);
        hold on
        plot(handles.mu_Z_H_re_agm, -handles.mu_Z_H_im_agm,'-b', 'LineWidth', 3);%% note that this is the Hilbert transformed real part
        plot(handles.Z_prime_mat,-handles.Z_double_prime_mat,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        
        h = legend('$Z_\mu$(Regressed)', '$Z_H$(Hilbert transform)', 'Location','NorthWest');
        set(h,'Interpreter', 'LaTex','Fontsize', 24)
        legend boxoff
        
    elseif ~strcmp(handles.method_tag,'none')
        plot(handles.mu_Z_re,-handles.mu_Z_im,'-k', 'LineWidth', 3);
        hold on
        plot(handles.Z_prime_mat,-handles.Z_double_prime_mat,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        
    else
        plot(handles.Z_prime_mat,-handles.Z_double_prime_mat,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        
    end

    xlabel(handles.axes_panel_drt,'$Z^{\prime}$', 'Interpreter', 'Latex','Fontsize',24);
    ylabel(handles.axes_panel_drt,'$-Z^{\prime\prime}$','Interpreter', 'Latex','Fontsize',24);
    set(gca,'FontSize',20,'TickLabelInterpreter','latex')
    axis equal
    hold off

guidata(hObject,handles)


% --- Plotting magnitude vs frequency plot
function Magnitude_Callback(hObject, eventdata, handles)

    if ~handles.data_exist
        return
    end
    
    axes(handles.axes_panel_drt)
    
    if strcmp(handles.method_tag,'BHT') 
        plot(handles.freq, abs(handles.mu_Z_re + handles.mu_Z_im*1i),'-k', 'LineWidth', 3);%% this is the Bayesian regressed result
        hold on
        plot(handles.freq, abs(handles.mu_Z_H_re_agm + handles.mu_Z_H_im_agm*1i),'-b', 'LineWidth', 3);%% note that this is the Hilbert transformed real part
        plot(handles.freq, abs(handles.Z_exp),'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r')
        
        h = legend('$Z_\mu$(Regressed)', '$Z_H$(Hilbert transform)', 'Location','NorthWest');
        set(h,'Interpreter', 'LaTex','Fontsize', 24)
        legend boxoff

    elseif ~strcmp(handles.method_tag,'none')
        plot(handles.freq, abs(handles.mu_Z_re + handles.mu_Z_im*1i),'-k', 'LineWidth', 3);
        hold on
        plot(handles.freq, abs(handles.Z_exp),'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r')
        
    else
        plot(handles.freq, abs(handles.Z_exp),'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r')
        
    end

    xlabel(handles.axes_panel_drt,'$f$/Hz', 'Interpreter', 'Latex','Fontsize',24);
    ylabel(handles.axes_panel_drt,'$|Z|$','Interpreter', 'Latex','Fontsize',24);
    
    set(gca,'FontSize',20)
    set(gca,'xscale','log','xlim',[min(handles.freq), max(handles.freq)],'Fontsize',20,'xtick',10.^[-10:2:10],'TickLabelInterpreter','latex')
    hold off
    % axis equal

guidata(hObject,handles)


% --- Plotting magnitude vs frequency plot
function Phase_Callback(hObject, eventdata, handles)

    if ~handles.data_exist
        return
    end
    
    axes(handles.axes_panel_drt)
    
    if strcmp(handles.method_tag,'BHT') 
        plot(handles.freq, rad2deg(angle(handles.mu_Z_re + handles.mu_Z_im*1i)),'-k', 'LineWidth', 3);%% note that this is the Hilbert transformed real part
        hold on
        plot(handles.freq, rad2deg(angle(handles.mu_Z_H_re_agm + handles.mu_Z_H_im_agm*1i)),'-b', 'LineWidth', 3);%% note that this is the Hilbert transformed real part
        plot(handles.freq, rad2deg(angle(handles.Z_exp)),'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        
        h = legend('$Z_\mu$(Regressed)', '$Z_H$(Hilbert transform)', 'Location','NorthWest');
        set(h,'Interpreter', 'LaTex','Fontsize', 24)
        legend boxoff
        
    elseif ~strcmp(handles.method_tag,'none')
        plot(handles.freq, rad2deg(angle(handles.mu_Z_re + handles.mu_Z_im*1i)),'-k', 'LineWidth', 3);
        hold on
        plot(handles.freq, rad2deg(angle(handles.Z_exp)),'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        
    else
        plot(handles.freq, rad2deg(angle(handles.Z_exp)),'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        
    end
    
    xlabel(handles.axes_panel_drt,'$f$/Hz', 'Interpreter', 'Latex','Fontsize',24);
    ylabel(handles.axes_panel_drt,'angle/$^{\circ}$','Interpreter', 'Latex','Fontsize',24);
    
    set(gca,'FontSize',20)
    set(gca,'xscale','log','xlim',[min(handles.freq), max(handles.freq)],'Fontsize',20,'xtick',10.^[-10:2:10],'TickLabelInterpreter','latex')
    
    hold off

guidata(hObject,handles)


% --- Plotting Re data curve and switching to the plot
function Re_data_Callback(hObject, eventdata, handles)

    if ~handles.data_exist
        return
    end

    axes(handles.axes_panel_drt)

    if strcmp(handles.method_tag,'BHT') 
        %%%% mu_Z_H_re
        ciplot(handles.mu_Z_H_re_agm-3*handles.band_re_agm, handles.mu_Z_H_re_agm+3*handles.band_re_agm, handles.freq, 0.7*[1 1 1]);
        hold on
        C1 = plot(handles.freq,handles.mu_Z_re,'-k', 'LineWidth', 3);
        C2 = plot(handles.freq,handles.mu_Z_H_re_agm,'-b', 'LineWidth', 3);
        plot(handles.freq, handles.Z_prime_mat,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        
        h = legend([C1,C2],{'$Z_\mu$(Regressed)', '$Z_H$(Hilbert transform)'}, 'Location','NorthWest');
        set(h,'Interpreter', 'LaTex','Fontsize', 24)
        legend boxoff
        
    elseif ~strcmp(handles.method_tag,'none')
        plot(handles.freq,handles.mu_Z_re,'-k', 'LineWidth', 3);
        hold on
        plot(handles.freq, handles.Z_prime_mat,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        
    else
        plot(handles.freq, handles.Z_prime_mat,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        
    end

    xlabel(handles.axes_panel_drt,'$f$/Hz', 'Interpreter', 'Latex','Fontsize',24);
    ylabel(handles.axes_panel_drt,'$Z^{\prime}$','Interpreter', 'Latex','Fontsize',24);
    set(gca,'xscale','log','xlim',[min(handles.freq), max(handles.freq)],'Fontsize',20,'xtick',10.^[-10:2:10],'TickLabelInterpreter','latex')
    hold off
    
guidata(hObject,handles)


% --- Plotting Im data curve and switching to the plot
function Im_data_Callback(hObject, eventdata, handles)

    if ~handles.data_exist
        return
    end

    axes(handles.axes_panel_drt)

    if strcmp(handles.method_tag,'BHT') 
        %%%% mu_Z_H_im
        ciplot(-handles.mu_Z_H_im_agm-3*handles.band_im_agm,-handles.mu_Z_H_im_agm+3*handles.band_im_agm, handles.freq, 0.7*[1 1 1]);
        hold on
        C1 = plot(handles.freq,-handles.mu_Z_im,'-k', 'LineWidth', 3);
        C2 = plot(handles.freq,-handles.mu_Z_H_im_agm,'-b', 'LineWidth', 3);
        plot(handles.freq,-handles.Z_double_prime_mat,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        
        h = legend([C1,C2],{'$Z_\mu$(Regressed)', '$Z_H$(Hilbert transform)'}, 'Location','NorthWest');
        set(h,'Interpreter', 'LaTex','Fontsize', 24)
        legend boxoff
        
    elseif ~strcmp(handles.method_tag,'none')
        plot(handles.freq,-handles.mu_Z_im,'-k', 'LineWidth', 3);
        hold on
        plot(handles.freq, -handles.Z_double_prime_mat,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
    
    else
        plot(handles.freq, -handles.Z_double_prime_mat,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');

    end

    xlabel(handles.axes_panel_drt,'$f$/Hz', 'Interpreter', 'Latex','Fontsize',24);
    ylabel(handles.axes_panel_drt,'$-Z^{\prime\prime}$','Interpreter', 'Latex','Fontsize',24);
    set(gca,'xscale','log','xlim',[min(handles.freq), max(handles.freq)],'Fontsize',20,'xtick',10.^[-10:2:10],'TickLabelInterpreter','latex')
    hold off
    
guidata(hObject,handles)


% --- Plotting Residual Re data
function Residual_Re_Callback(hObject, eventdata, handles)

    if ~handles.data_exist || strcmp(handles.method_tag, 'none') || strcmp(handles.data_used,'Im Data')
        return
    end

    axes(handles.axes_panel_drt)

    if strcmp(handles.method_tag,'BHT') 
%       Residual w.r.t. mu_Z_H_re
        ciplot(-3*handles.band_re_agm, 3*handles.band_re_agm, handles.freq, 0.7*[1 1 1]);
        hold on
        plot(handles.freq,handles.res_H_re,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        ylabel(handles.axes_panel_drt,'$R_{\infty}+Z^{\prime}_{\rm H}-Z^{\prime}_{\rm exp}$','Interpreter', 'Latex','Fontsize',24);
        
        y_max = max(3*handles.band_re_agm);

    else
        plot(handles.freq, handles.res_re,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        ylabel(handles.axes_panel_drt,'$Z^{\prime}_{\rm DRT}-Z^{\prime}_{\rm exp}$','Interpreter', 'Latex','Fontsize',24);
        
        y_max = max(abs(handles.res_re));
        
    end

    xlabel(handles.axes_panel_drt,'$f$/Hz', 'Interpreter', 'Latex','Fontsize',24);
    set(gca,'xscale','log','xlim',[min(handles.freq), max(handles.freq)],'Fontsize',20,'xtick',10.^[-10:2:10],'TickLabelInterpreter','latex')
%   Ensuring symmetric y_axis
    ylim([-1.1*y_max 1.1*y_max])
    hold off
    
guidata(hObject,handles)


% --- Plotting Residual Im data
function Residual_Im_Callback(hObject, eventdata, handles)

    if ~handles.data_exist || strcmp(handles.method_tag, 'none') || strcmp(handles.data_used,'Re Data') 
        return
    end

    axes(handles.axes_panel_drt)

    if strcmp(handles.method_tag,'BHT') 
        % Residual w.r.t. mu_Z_H_im
        ciplot(-3*handles.band_im_agm,3*handles.band_im_agm, handles.freq, 0.7*[1 1 1]);
        hold on
        plot(handles.freq,handles.res_H_im,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        ylabel(handles.axes_panel_drt,'$\omega L_0+Z^{\prime\prime}_{\rm H}-Z^{\prime\prime}_{\rm exp}$','Interpreter', 'Latex','Fontsize',24);
        
        y_max = max(3*handles.band_im_agm);

    else
        plot(handles.freq,handles.res_im,'or', 'MarkerSize', 4, 'MarkerFaceColor', 'r');
        hold on
        ylabel(handles.axes_panel_drt,'$Z^{\prime\prime}_{\rm DRT}-Z^{\prime\prime}_{\rm exp}$','Interpreter', 'Latex','Fontsize',24);

        y_max = max(abs(handles.res_im));
        
    end

    xlabel(handles.axes_panel_drt,'$f$/Hz', 'Interpreter', 'Latex','Fontsize',24);

    set(gca,'xscale','log','xlim',[min(handles.freq), max(handles.freq)],'Fontsize',20,'xtick',10.^[-10:2:10],'TickLabelInterpreter','latex')
%   Ensuring symmetric y_axis
    ylim([-1.1*y_max 1.1*y_max])
    hold off
    
guidata(hObject,handles)



% --- plotting the DRT
function handles = deconvolved_DRT_Callback(hObject, eventdata, handles)
%   Running ridge regression

    if strcmp(handles.method_tag,'none') % not plotting if user did not do any calculation 
        return 
    end

    taumax = ceil(max(log10(1./handles.freq)))+0.5;    
    taumin = floor(min(log10(1./handles.freq)))-0.5;
    handles.freq_fine = logspace(-taumin, -taumax, 10*numel(handles.freq));
  

    axes(handles.axes_panel_drt)
    
    switch handles.method_tag
        case 'simple'
            [handles.gamma_ridge_fine,handles.freq_fine] = map_array_to_gamma(handles.freq_fine, handles.freq, handles.x_ridge(3:end), handles.epsilon, handles.rbf_type);
            plot(1./handles.freq_fine, handles.gamma_ridge_fine, '-k', 'LineWidth', 3);

            y_min = 0; 
            y_max = max(handles.gamma_ridge_fine);

        case 'credit'
            [handles.gamma_mean_fine,handles.freq_fine] = map_array_to_gamma(handles.freq_fine, handles.freq, handles.mean, handles.epsilon, handles.rbf_type);
            [handles.lower_bound_fine,handles.freq_fine] = map_array_to_gamma(handles.freq_fine, handles.freq, handles.lower_bound, handles.epsilon, handles.rbf_type);
            [handles.upper_bound_fine,handles.freq_fine] = map_array_to_gamma(handles.freq_fine, handles.freq, handles.upper_bound, handles.epsilon, handles.rbf_type);
            [handles.gamma_ridge_fine,handles.freq_fine] = map_array_to_gamma(handles.freq_fine, handles.freq, handles.x_ridge(3:end), handles.epsilon, handles.rbf_type);

            ciplot(handles.lower_bound_fine, handles.upper_bound_fine, 1./handles.freq_fine, 0.7*[1 1 1]);%plot CI
            hold on
            plot(1./handles.freq_fine, handles.gamma_mean_fine, '-b', 'LineWidth', 3);
            plot(1./handles.freq_fine, handles.gamma_ridge_fine, '-k', 'LineWidth', 3);
            
%             my_str = sprintf('%g \% CI', 99);
            h = legend('99\% CI', 'Mean', 'MAP', 'Location','NorthWest');
            set(h,'Interpreter', 'LaTex','Fontsize', 24)
            legend boxoff

            y_min = 0; 
            y_max = max(handles.upper_bound_fine);

        case 'BHT'
            [handles.gamma_mean_fine_re,handles.freq_fine] = map_array_to_gamma(handles.freq_fine, handles.freq, handles.mu_gamma_re(2:end), handles.epsilon, handles.rbf_type);
            [handles.gamma_mean_fine_im,handles.freq_fine] = map_array_to_gamma(handles.freq_fine, handles.freq, handles.mu_gamma_im(2:end), handles.epsilon, handles.rbf_type);

            plot(1./handles.freq_fine, handles.gamma_mean_fine_re, '-b', 'LineWidth', 3);
            hold on
            plot(1./handles.freq_fine, handles.gamma_mean_fine_im, '-k', 'LineWidth', 3);

            h = legend('Mean Re', 'Mean Im', 'Location','NorthWest');
            set(h,'Interpreter', 'LaTex','Fontsize', 24)
            legend boxoff

            y_min = min([handles.gamma_mean_fine_re;handles.gamma_mean_fine_im]);
            y_max = max([handles.gamma_mean_fine_re;handles.gamma_mean_fine_im]);

    end

%   adding labels
    xlabel(handles.axes_panel_drt,'$\tau/s$', 'Interpreter', 'Latex','Fontsize',24)
    ylabel(handles.axes_panel_drt,'$\gamma(\tau)/\Omega$','Interpreter', 'Latex','Fontsize',24);
    set(gca,'xscale','log','xlim',[10^taumin, 10^taumax],'ylim',[y_min, 1.1*y_max],'Fontsize',20,'xtick',10.^[-10:2:10],'TickLabelInterpreter','latex')
    hold off
    
guidata(hObject,handles)


% --- Plotting EIS scores
function EIS_Scores_Callback(hObject, eventdata, handles)

    if ~handles.data_exist || ~strcmp(handles.method_tag,'BHT') 
        return
    end

    axes(handles.axes_panel_drt);
    
    X = [1,2,3,4,5,6];
    Y = [handles.out_scores.s_res_re(1), handles.out_scores.s_res_re(2), handles.out_scores.s_res_re(3), handles.out_scores.s_mu_re, handles.out_scores.s_HD_re, handles.out_scores.s_JSD_re;
         handles.out_scores.s_res_im(1), handles.out_scores.s_res_im(2), handles.out_scores.s_res_im(3), handles.out_scores.s_mu_im, handles.out_scores.s_HD_im, handles.out_scores.s_JSD_im]';
    
    b = bar(X,Y*100);
    b(1).FaceColor = [0 0 1];
    b(2).FaceColor = [0 0 0];
    
    hold on
    xlim = get(gca,'xlim');
    xlim = [xlim(1)-1, xlim(2)+1];
    plot(xlim,[100 100],'--k');

    h = legend('Real', 'Imaginary', 'Location','NorthWest');
    set(h,'Interpreter', 'LaTex','Fontsize', 24)
    legend boxoff

    ylabel(handles.axes_panel_drt,'Scores (\%)','Interpreter', 'LaTex','Fontsize',24)
    
    xticks([1,2,3,4,5,6])
    set(gca,'XTickLabel',{'$s_{1\sigma}$','$s_{2\sigma}$','$s_{3\sigma}$','$s_{\mu}$','$s_{\rm HD}$','$s_{\rm JSD}$'},'TickLabelInterpreter','latex');
    set(gca,'xlim',[0.5, 6.5],'ylim',[0, 125],'Fontsize',20,'ytick',[0,50,100])
    xtickangle(0)
    hold off
    
guidata(hObject,handles)


% --- Exporting the DRT data
function Export_DRT_Data_Callback(hObject, eventdata, handles)

    startingFolder = 'C:\*';
    if ~exist(startingFolder, 'dir')
        % If that folder doesn't exist, just start in the current folder.
        startingFolder = pwd;

    end

    [baseFileName, folder] = uiputfile({ '*.txt', 'txt files (*.txt)';'*.csv','csv files (*.csv)'}, 'Select a file');

    if ~baseFileName
        % User clicked the Cancel button.export
        return;
    end

    fullFileName = fullfile(folder, baseFileName);

    fid  = fopen(fullFileName,'wt');

    % switch handles.method_tag
    %     case 'simple'
            col_tau = 1./handles.freq_fine(:);
            col_gamma = handles.gamma_ridge_fine(:);
            fprintf(fid,'%s, %e \n','L',handles.x_ridge(1));
            fprintf(fid,'%s, %e \n','R',handles.x_ridge(2));
            fprintf(fid,'%s, %s \n','tau','gamma(tau)');
            fprintf(fid,'%e, %e \n', [col_tau(:), col_gamma(:)]');

    %     case 'credit'
    %         col_tau = 1./handles.freq_fine(:);
    %         col_gamma = handles.gamma_ridge_fine(:);
    %         col_mean = handles.gamma_mean_fine(:);
    %         col_upper = handles.upper_bound_fine(:);
    %         col_lower = handles.lower_bound_fine(:);
    %         fprintf(fid,'%s, %e \n','L',handles.x_ridge(1));
    %         fprintf(fid,'%s, %e \n','R',handles.x_ridge(2));
    %         fprintf(fid,'%s, %s, %s, %s, %s\n', 'tau', 'MAP', 'Mean', 'Upperbound', 'Lowerbound');
    %         fprintf(fid,'%e, %e, %e, %e, %e\n', [col_tau(:), col_gamma(:), col_mean(:), col_upper(:), col_lower(:)]');
    % 
    %     case 'BHT'
    %         col_tau = 1./handles.freq_fine(:);
    %         col_re = handles.gamma_mean_fine_re(:);
    %         col_im = handles.gamma_mean_fine_im(:);
    %         fprintf(fid,'%s, %e \n','L',handles.mu_L_0);
    %         fprintf(fid,'%s, %e \n','R',handles.mu_R_inf);
    %         fprintf(fid,'%s, %s, %s\n', 'tau', 'gamma_Re', 'gamma_Im');
    %         fprintf(fid,'%e, %e, %e\n', [col_tau(:), col_re(:), col_im(:)]');
    % 
    % end

    fclose(fid);

guidata(hObject,handles)


% --- Export the fitted curve
function Export_Fit_Data_Callback(hObject, eventdata, handles)

    startingFolder = 'C:\*';
    if ~exist(startingFolder, 'dir')
        % If that folder doesn't exist, just start in the current folder.
        startingFolder = pwd;

    end

    [baseFileName, folder] = uiputfile({ '*.txt', 'txt files (*.txt)';'*.csv','csv files (*.csv)'}, 'Select a file');

    if ~baseFileName
        % User clicked the Cancel button.
        return;
    end

    fullFileName = fullfile(folder, baseFileName);

    fid  = fopen(fullFileName,'wt');

    % two cases: BHT case, non-BHT case
    if strcmp(handles.method_tag,'BHT')
        % print EIS score
        fprintf(fid,'%s, %f, %f, %f\n','s_res_re',handles.out_scores.s_res_re);
        fprintf(fid,'%s, %f, %f, %f\n','s_res_im',handles.out_scores.s_res_im);
        fprintf(fid,'%s, %f \n','s_mu_re', handles.out_scores.s_mu_re);
        fprintf(fid,'%s, %f \n','s_mu_im', handles.out_scores.s_mu_im);
        fprintf(fid,'%s, %f \n','s_HD_re', handles.out_scores.s_HD_re);
        fprintf(fid,'%s, %f \n','s_HD_im', handles.out_scores.s_HD_im);
        fprintf(fid,'%s, %f \n','s_JSD_re', handles.out_scores.s_JSD_re);
        fprintf(fid,'%s, %f \n','s_JSD_im', handles.out_scores.s_JSD_im);

        fprintf(fid,'%s, %s, %s, %s, %s, %s, %s, %s, %s\n', 'freq', 'mu_Z_re', 'mu_Z_im', ...
                                                            'Z_H_re', 'Z_H_im',...
                                                            'Z_H_re_band', 'Z_H_im_band',...
                                                            'Z_H_re_res', 'Z_H_im_res');

        fprintf(fid,'%e, %e, %e, %e, %e, %e, %e, %e, %e\n',[handles.freq(:), handles.mu_Z_re(:), handles.mu_Z_im(:),...
                                                            handles.mu_Z_H_re_agm(:),handles.mu_Z_H_im_agm(:), ...
                                                            handles.band_re_agm(:),handles.band_im_agm(:), ...
                                                            handles.res_H_re(:), handles.res_H_im(:)]');

    elseif ~strcmp(handles.method_tag,'none') % for non BHT case, i.e., simple or credit case.
        fprintf(fid,'%s, %s, %s, %s, %s\n', 'freq', 'mu_Z_re', 'mu_Z_im',...
                                            'Z_re_res', 'Z_im_res');

        fprintf(fid,'%e, %e, %e, %e, %e\n', [handles.freq(:), handles.mu_Z_re(:),...
                                             handles.mu_Z_im(:), handles.res_re(:),...
                                             handles.res_im(:)]');

    else
        return;
    end

    fclose(fid);

guidata(hObject,handles)


% --- Export the figures
function Save_DRT_figure_Callback(hObject, eventdata, handles)

    startingFolder = 'C:\*';
    if ~exist(startingFolder, 'dir')
        % If that folder doesn't exist, just start in the current folder.
        startingFolder = pwd;
    end

    defaultFileName = fullfile(startingFolder, '*.fig');
    [baseFileName, folder] = uiputfile(defaultFileName, 'Name a file');

    if ~baseFileName
        % User clicked the Cancel button.
        return;
    end

    fullFileName = fullfile(folder, baseFileName);

    newfig_1 = figure(); %new figure
    copyobj([handles.axes_panel_drt legend(handles.axes_panel_drt)], newfig_1);
    set_size_fig
    saveas(gcf,fullFileName)
    close(gcf); 
    
 guidata(hObject,handles)
 


