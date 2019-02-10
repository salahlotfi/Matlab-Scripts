% ICA Script
% Clear memory and the command window
clear
clc

% Initialize the ALLERP structure and CURRENTERP
ALLERP = buildERPstruct([]);
CURRENTERP = 0;


% This defines the set of subjects

subject_list = {'120' '121'} '103' '105' '106' '107' '108' } 
folder_list = {'120' '121'} '103' '105' '106' '107' '108'}

%Needs to be run: 
%  

% Recently Run:
% '140_1' '141_1' '141_2' '141_3' '142_1' '142_2' '142_3' '143_1' 
% Sala 11/30  131_1' '131_2' '131_3' '132_1' '133_1' '133_3' '134_2'
% Sala 12/1 '107_2' '108_1' '110_1' '112_2' '113_1' '113_2' '113_3'
% Sala 12/1-1 '106_3' '119_1' '119_3' '121_3' '123_2' '129_3' '130_1' '130_2' '132_2' '133_2' '134_3' '135_1' '135_2' '135_3'

nsubj = length(subject_list); % number of subjects

home_path  = 'C:\Users\....\';

% Set the save_everything variable to 1 to save all of the intermediate files to the hard drive
% Set to 0 to save only the initial and final dataset and ERPset for each subject
save_everything  = 0;

% Set the plot_PDFs variable to 1 to create PDF files with the waveforms
% for each subject (set to 0 if you don't want to create the PDF files).
plot_PDFs = 1;

% Loop through all subjects
for s=1:nsubj

    fprintf('\n******\nProcessing subject %s\n******\n\n', subject_list{s});
    % Path to the folder containing the current subject's data
    data_path  = [home_path folder_list{s} '/'];
    % Check to make sure the dataset file exists
    % Initial filename = path plus Subject# plus _preICA.set
    sname = [data_path subject_list{s} '_preICA.set'];
    if exist(sname, 'file')<=0
            fprintf('\n *** WARNING: %s does not exist *** \n', sname);
            fprintf('\n *** Skip all processing for this subject *** \n\n');
    else
        %
        % Load original dataset
        %
        fprintf('\n\n\n**** %s: Loading dataset ****\n\n\n', subject_list{s});
        EEG = pop_loadset('filename', [subject_list{s} '_preICA.set'], 'filepath', data_path);

        %
        % Populate channel locations
        %
        % **Only need this if don't manually populate channels**
        %
        fprintf('\n\n\n**** %s: Adding channel location info ****\n\n\n', subject_list{s});
        %EEG = pop_chanedit(EEG, 'load',{'/media/2_larson_buffalo/data/NewSystemTest/CDAChrisAnt/emoregelc.elc' 'filetype' 'autodetect'});        
        EEG = pop_chanedit(EEG, 'lookup','FERPelc.elc');
        % Save dataset with _chan suffix instead of _EEG
        EEG.setname = [subject_list{s} '_chan']; % name for the dataset menu
        if (save_everything)
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path);
        end
       
         
        
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %This pop_select GSR is part of the Band-pass filtering, which picks up
   %the correct channel to do the filtering. Putting GSR and others in the
   %curly brakets will remove them from the filtering...
	    % **Don't need this because don't have Corrugators**
	 %  So, the channels "1:34" are all being filtered, except GSR1, but I am
     %still not convinced why all the channels including EOGs are getting
     %filered too. All the previous scripts (Walker's) did the same thing.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
        % Band-pass filter the EEG
        %Exclude Corr and GSR
        EEG = pop_select( EEG,'nochannel',{'GSR1'});		
	
        fprintf('\n\n\n**** %s: High-pass filtering EEG at 0.01 Hz ****\n\n\n', subject_list{s});              
	EEG  = pop_basicfilter( EEG,  1:32 , 'Boundary', 'boundary', 'Cutoff', [ 0.1 30], 'Design', 'butter', 'Filter', 'bandpass', 'Order',  2, 'RemoveDC', 'on' );
        EEG.setname = [EEG.setname '_hpfilt'];

        if (save_everything)
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path);              
        end
%
	 %  % Rereferencing channels excluding
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % SALAHADIN'S NOTES; Here is the first time we reference to the M1.
     % Because we are rerefrenceing, what happens is it removes M1 and put
     % it at the end of the channels, so after this step, 35 is M1. While
     % rerefrecing, we exlude M2 (19) VEOG (33) and HEOG (34), because we
     % want to retain their values as we use their original values to
     % remove blinks and other stuff. 
     
     % At this point, the original channel setup hasn't changed, put M1 as
     % the last channel. But, after this step, files with the path of
     % _avref are rearranged channels (i.e. Veog=32, Heog=33, and GSR1=34).
     %NOTE: If you don't remove GSR1 at the _preICA step, you should
     %include that in the pop_reref exclude as well, otherwise, GSR will be
     %also referenced here, although it has no value (all blank, we don't
     %collect GSR). But, upon checking now, I notice it still has no value
     %in the plot, so you can ignore it. But, it is better to remove it.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % 
	   fprintf('\n\n\n**** %s: Rereferencing ****\n\n\n', subject_list{s}); 
		EEG = pop_reref( EEG, [13], 'exclude',[19 33 34] ); 
		% Save dataset with _avref suffix
		EEG.setname = [subject_list{s} '_avref']; % name for the dataset menu 
        EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path); 
   

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % If you are rereferecing to M2 and removing M1 or vise versa, ICA channel setup should be modifed too.
        % If referecing to M2, set up is [1:12 14:31].
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% BINICA
        %
	fprintf('\n\n\n**** %s: Running BINICA ****\n\n\n', subject_list{s});				 
	EEG = pop_runica(EEG, 'extended',1,'interupt','on','chanind', [1:17 19:31]); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Very important to get these "chnind" correct. I got this wrong for ANT 3 data, but it is fine.Sala. I put [1:12 14:18 19:32] based on the original channel location/order of the channels.
    %But remember, after rerefrecing, the order of channels are channed as
    %M1 is move down as the last channel. So, no, 18 is M2 after rerefrecing and you don't want to include that along with V&H EOGs. So, 1:17 and 19:31.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	EEG.setname = [EEG.setname '_ica']; 
	EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path);				 
	
    end % end of the "if/else" statement that makes sure the file exists

end % end of looping through all subjects

fprintf('\n\n\n**** FINISHED ****\n\n\n');
