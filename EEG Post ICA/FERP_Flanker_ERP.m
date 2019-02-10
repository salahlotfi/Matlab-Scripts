% Clear memory and the command window

%%%%%%%#######^^^^^^^^THINGS to Check before running the script:
%%%%%%%%%%%% 1) The name of the ERPsets inputs and outputs.
%%%%%%%%%%%% 2) THe home_path...
clear
clc

% Initialize the ALLERP structure and CURRENTERP
ALLERP = buildERPstruct([]);
CURRENTERP = 0;

%Very clean data....
%subject_list = {'141'}%'109' '113' '115' '123' '126' '127' '131' '133' '135' '136' '142' '143' '145' '146' '147' '148' '149' '150' '151'}
%folder_list =  {'141'}%'109' '113' '115' '123' '126' '127' '131' '133' '135' '136' '142' '143' '145' '146' '147' '148' '149' '150' '151'}

% This defines the set of subjects
subject_list = {'104' '105' '106' '107' '108' '109' '110' '111' '113' '115' '121' ...
'122' '123' '125' '126' '127' '128' '129' '130' '131' '133' '134' '135' ...
'136' '137' '139' '140' '142' '143' '144' '145' '146' '147' '148' '149' '150' '151'...
'114' '118' '119' '153' '154' '156' '157'} 
folder_list =  {'104' '105' '106' '107' '108' '109' '110' '111' '113' '115' '121' ...
'122' '123' '125' '126' '127' '128' '129' '130' '131' '133' '134' '135' ...
'136' '137' '139' '140' '142' '143' '144' '145' '146' '147' '148' '149' '150' '151'...
'114' '118' '119' '153' '154' '156' '157'} 


% Needs to be run:'109' '113' '115' '123' '126' '127' '131'

% Already ran:


nsubj = length(subject_list); % number of subjects
home_path  = 'C:\Users\PSY-LEELAB-VA\Desktop\FERP\Data\1200ms\';

for s=1:nsubj
    data_path  = [home_path folder_list{s} '\'];
    ERP = pop_loaderp( 'filename', [subject_list{s} '_CorrERPs.erp'], 'filepath', data_path);

    ERP = pop_erpchanoperator( ERP, {  'ch33 = (ch6 + ch5 + ch7)/3 label AveF3_4_Z',  'ch34 = (ch16 + ch15 + ch14)/3 label AveC3_4_Z',...
            'ch35 = (ch24 + ch25 + ch23)/3 label AveP3_4_Z',  'ch36 = (ch28 + ch29 + ch30)/3 label AveO1_2_Z'} , 'ErrorMsg', 'popup', 'KeepLocations',...
             0, 'Warning', 'on' ); 
    
    
    ERP = pop_binoperator( ERP, {'nbin1 = bin1 label AbsPure', 'nbin2 = bin2 label Abs20', 'nbin3 = bin3 label Con20', 'nbin4 = bin4 label Incon20',...
                                 'nbin5 = bin5 label Abs60', 'nbin6 = bin6 label Con60', 'nbin7 = bin7 label Incon60',...
                                'nbin8 = bin4 - bin3 label 20%ConflictCost', 'nbin9 = bin7 - bin6 label 60%ConflictCost', ...
                                'nbin10 = bin2 - bin1 label 20%FilteringCost', 'nbin11 = bin5 - bin1 label 60%FilteringCost'});
                      
                            
    ERP = pop_savemyerp(ERP,...
     'erpname', [subject_list{s} '_ERPs'], 'filename', [subject_list{s} '_ERPs_ChaBinCosts.erp'], 'filepath', data_path,...
     'Warning', 'on'); 
 
     end

fprintf('\n\n\n**** FINISHED ****\n\n\n');

%%%######To get the average btw two time windows, for all data sets
%%%generated in a text file separated by individual data sets. This can
%%%also easy be done through Measurement Tools GUI...Read the list, run it,
%%%but average channels and new bins should be already generated. 

%ALLERP = pop_geterpvalues( 'C:\Users\PSY-LEELAB-VA\Desktop\FERP\MainScripts\FERP stuff\Ready to Use Flanker Scripts\Flanker\ERPaveLists\Ave1200ms_ChaBinCosts.txt',...
% [ 300 400],  1:11,  35 , 'Baseline', 'pre', 'Binlabel', 'on', 'FileFormat', 'long', 'Filename',...
% 'C:\Users\PSY-LEELAB-VA\Desktop\FERP\MainScripts\FERP stuff\Ready to Use Flanker Scripts\Flanker\ERPoutputs\P3_Z_300_400ms.xls', 'Fracreplace', 'NaN', 'InterpFactor',...
%  1, 'Measure', 'meanbl', 'PeakOnset',  1, 'Resolution',  3 );
