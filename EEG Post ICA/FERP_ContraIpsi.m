% Clear memory and the command window
clear
clc

% Initialize the ALLERP structure and CURRENTERP
ALLERP = buildERPstruct([]);
CURRENTERP = 0;

subject_list = { '123' '126'}%'120' '121' '124' '122' '123' '126' '125'}
folder_list = {'123' '126' }


nsubj = length(subject_list); % number of subjects
home_path  = 'C:\Users\PSY-LEELAB-VA\Desktop\FERP\Data\CDA\';



for s=1:nsubj
    data_path  = [home_path folder_list{s} '/'];
    ERP = pop_loaderp( 'filename', [subject_list{s} '_ERPs.erp'], 'filepath', data_path);
    
    %Equivalent command:
ERP = pop_binoperator( ERP, {  'prepareContraIpsi',  'Lch = [22 23 28 18]',  'Rch = [26 25 30 21]',  'nbin1 = 0.5*bin1@Rch + 0.5*bin2@Lch label ND Contra',...
  'nbin2 = 0.5*bin1@Lch + 0.5*bin2@Rch label ND Ipsi',  'nbin3 = 0.5*bin3@Rch + 0.5*bin4@Lch label NT2 Contra',...
  'nbin4 = 0.5*bin3@Lch + 0.5*bin4@Rch label NT2 Ipsi',  'nbin5 = 0.5*bin5@Rch + 0.5*bin6@Lch label NT4 Contra',  'nbin6 = 0.5*bin5@Lch + 0.5*bin6@Rch label NT4 Ipsi',...
  '# For creating contra-minus-ipsi waveforms from the bins above,',...
  '# run (only) the formulas described here below in a second call',  '# of "ERP binoperator" (remove the # symbol before run them)',...
  '#bin11 = bin1 - bin2 label ND Contra-Ipsi',  '#bin12 = bin3 - bin4 label NT2 Contra-Ipsi',  '#bin13 = bin5 - bin6 label NT4 Contra-Ipsi'});
    
ERP = pop_savemyerp(ERP,...
     'erpname', [subject_list{s} '_ERPs'], 'filename', [subject_list{s} '_ERPs_contra_ipsi_all.erp'], 'filepath', data_path,...
     'Warning', 'on');

    %Equivalent command:
    ERP = pop_loaderp( 'filename', [subject_list{s} '_ERPs_contra_ipsi_all.erp'], 'filepath', data_path);
    ERP = pop_binoperator( ERP, {  'nbin1 = bin1 - bin2 label ND Contra-Ipsi',  'nbin2 = bin3 - bin4 label NT2 Contra-Ipsi',...
      'nbin3 = bin5 - bin6 label NT4 Contra-Ipsi'});
   ERP = pop_savemyerp(ERP,...
     'erpname', [subject_list{s} '_ERPs'], 'filename', [subject_list{s} '_ERPs_contra-ipsi.erp'], 'filepath', data_path,...
     'Warning', 'on');
     
     end

fprintf('\n\n\n**** FINISHED ****\n\n\n');