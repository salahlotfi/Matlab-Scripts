% This script is written by ANL at UWM and modified by Sala Lotfi at ADL, UWM.


% Clear memory and the command window
clear
clc

% Initialize the ALLERP structure and CURRENTERP
ALLERP = buildERPstruct([]);
CURRENTERP = 0;


% This defines the set of subjects
subject_list = {'120''121''122''123''126''124' '125'}  
folder_list = {'120''121''122''123''126''124' '125'} 





nsubj = length(subject_list); % number of subjects


% Path to the parent folder, which contains the data folders for all subjects
home_path  = 'C:\Users\Data\CDA\';

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
    data_path  = [home_path folder_list{s} '\'];
    % Check to make sure the dataset file exists
    % Initial filename = path plus Subject# plus _EEG.set
    sname = [data_path subject_list{s} '_pi.set'];
    if exist(sname, 'file')<=0
            fprintf('\n *** WARNING: %s does not exist *** \n', sname);
            fprintf('\n *** Skip all processing for this subject *** \n\n');
    else
        %
        % Load original dataset
        %
        fprintf('\n\n\n**** %s: Loading dataset ****\n\n\n', subject_list{s});
        EEG = pop_loadset('filename', [subject_list{s} '_pi.set'], 'filepath', data_path);
	EEG = pop_editset(EEG, 'setname', [subject_list{s} '_pi']);
	
%
 % Rereferencing
% Excludes EOGs (because they were getting in the way), rereferences to average, then rereferences to ave mastoid

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SALAHADIN NOTE's: 
%Apperantly, you rerefrence twice, once before ICA and once after ICA. And you should always have M1 as the online referencing while recoding {Set up the montage for the new EEG system}.
%And here is post ICA, so instead of one, now you have two rereference.
%Iguess it is recommended. %You are referencing to M1(35) & M2 (18) after the reordering of channel in the first rerefrecing.. You first exclude
%M2(18), and VEOG (32), HEOG (33) and GSR (34). After exclusion, it then
%references the all channels to 18 and 35.
%Another important thing: After this rereferencing, to both M1&M2, channel
%rearrangment changes, such that Veog is 31, Heog is 32, and GSR1 is 33,
%and M2 will NOT be threwn at as the last channel (will be removed).
% This new arrangment is very important in the "Artifact Detection and
% Rejection" below. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%EEG = pop_select( EEG );
fprintf('\n\n\n**** %s: Rereferencing to M1 & M2 ****\n\n\n', subject_list{s});
EEG = pop_reref( EEG, [],'refloc',struct('labels',{'M1'},'type',{''},'theta',{-112.4475},'radius',{0.69503},'X',{-37.1},'Y',{89.8},'Z',{-68.3}, ...
    'sph_theta',{112.4475},'sph_phi',{-35.1053},'sph_radius',{118.7659},'urchan',{13},'ref',{'M1'}),'exclude', [18 32 33]);
EEG = pop_reref( EEG, [18 34] );

%
 % Rereferencing (Again)
% Excludes EOGs and rereferences to average

% rereference avg of all channels exluding EOG1 and EOG2
%fprintf('\n\n\n**** %s: Rereferencing to average ****\n\n\n', subject_list{s});
%EEG = pop_reref( EEG, [], 'exclude',[1 2] );

%
%
       %add ac to name for average channels
       EEG.setname = [EEG.setname '_ac'];
      %Savefile so results of reref can be checked (ie to check if rereferencing to avg of channels made a mess of things)
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path); 
    
          %
        % Create EVENTLIST and save (pop_editeventlist adds _elist suffix)
        %
        fprintf('\n\n\n**** %s: Creating eventlist ****\n\n\n', subject_list{s}); 
        EEG.setname = [EEG.setname '_el']; % name for the dataset menu
        EEG = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'Eventlist', ['C:\Users\RejectionTables&OLD\rejectiontables\CDA\elist\',[subject_list{s} '.txt']], ...
            'Newboundary', { -99 }, 'Stringboundary', { 'boundary' }, 'Warning', 'on' ); 
         
        pop_squeezevents(EEG);
        if (save_everything) 
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path); 
        end
        
         
        %
        % Use Binlister to sort the bins and save with _bins suffix
        % 
        %
        fprintf('\n\n\n**** %s: Running BinLister ****\n\n\n', subject_list{s});		 
	EEG.setname = [EEG.setname '_bn']; 
EEG = pop_binlister( EEG , 'BDF', 'C:\Users\PSY-LEELAB-VA\Desktop\FERP\MainScripts\FERP stuff\Ready to Use Flanker Scripts\FERP_CDA_Bin.txt', ...
    'ExportEL', ['C:\Users\FERP\RejectionTables&OLD\rejectiontables\CDA\elist\',[subject_list{s} '.txt']], 'ImportEL', ...
['C:\Users\RejectionTables&OLD\rejectiontables\CDA\elist\',[subject_list{s} '.txt']], 'Saveas', 'on', 'SendEL2', 'EEG&Text', 'Warning', 'on' );
        %if (save_everything) 
		EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path); 
       % end  
       
       
     

        % **Need to determine the correct window for these data! 5.31.16**
        % Extracts bin-based epochs (200 ms pre-stim, 1200 ms post-stim. Baseline correction by pre-stim window[That is, 
        %the average voltage during the prestimulus period for a given trial is subtracted from every point in the epoch (separately for each channel). The prestimulus voltage doesn't provide any information, so better to remove it. 
        % Then save with _ep suffix
        % 'pre' means use the prestimulus period for baseline correction
    % Use 'post' to use the poststimulus period for baseline correction
    % Use 'all' to use the poststimulus period for baseline correction
    % Use two numbers in quotes (e.g., '-150 +50') to specify a custom interval for baseline correction
        %
        fprintf('\n\n\n**** %s: Bin-based epoching ****\n\n\n', subject_list{s});
        EEG = pop_epochbin( EEG , [ -200  1200],  '-200 0');
        EEG.setname = [EEG.setname '_ep'];
        if (save_everything)
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path);
        end

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %So, finding artifact given the values [-80 80] and remove them.
 %Steve Luck has explained this nicely in the website.. For my clean data
 %using ANT system, I had 460 trials out of 600 remained after all artifact
 %rejection. So, it is better to have a large nubmer of trials.
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
        % artifact detection, then export eventlist just for fun
        % Save the processed EEG to disk because the next step will be averaging
        
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
  %Going over this with Ken7.26.18: Picking up right channels are really crucial at this phase,   
  %After this rereferencing above to both M1&M2, channel
%rearrangment changes, such that Veog is 31, Heog is 32, and GSR1 is 33,
%and M2 will NOT be threwn at as the last channel (will be removed).
% This new arrangment is very important in the "Artifact Detection and
% Rejection" below. 
  %The channel after rearrangment changes, so if you lookup "urchanloc" under channel location, urchanloc shows the original channel
  %location and "channel number" shows the currect rearranged channel #. 
  %For, 3 new eeg cda data, I messed up because heog was rejecting artificant based on the exceeded amplitude on ch33 which is corrugate.
  %The other thing is, removing bins for heog with threshold over -40 40 might messed CDA, as that might indicated eye direction to the hemifield. Not
  %quite sure about this though.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   


        fprintf('\n\n\n**** %s: Artifact detection ****\n\n\n', subject_list{s});              
        %
        % Artifact detection simple threshold for all channels except EOGs, then just VEOG, then just HEOG. All run separately.
        % simple threshold
	EEG  = pop_artextval( EEG , 'Channel',  [25:30], 'Flag', [ 1 4], 'Review', 'off', 'Threshold', [ -80 80], 'Twindow', [ -50 900] );
        EEG.setname = [EEG.setname '_ar_chan'];
        
    EEG  = pop_artextval( EEG , 'Channel',  [31], 'Flag', [ 1 4], 'Review', 'off', 'Threshold', [ -80 80], 'Twindow', [ -50 150] );
        EEG.setname = [EEG.setname '_ar_veog'];
%        EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path);
%        EEG = pop_exporteegeventlist(EEG, [data_path subject_list{s} '_eventlist_ar_veog.txt']);

	EEG  = pop_artextval( EEG , 'Channel',  [32], 'Flag', [ 1 4], 'Review', 'off', 'Threshold', [ -40 40], 'Twindow', [ -50 150] );
        EEG.setname = [EEG.setname '_ar_heog'];
%        EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path);
%        EEG = pop_exporteegeventlist(EEG, [data_path subject_list{s} '_eventlist_ar_heog.txt']);


      %Artifact Rejection: Sample-to-Sample. Remove data that exceeds a given
    %threshold between two sampling points. Voltage step exceeding 50uV bet
    %contiguous sampling points.
    EEG  = pop_artdiff( EEG ,...
    'Channel',  1:30,...%Set of channels to be tested - all except corr
    'Flag', [ 1 3],...%Flag rejected trials onto the Event List
    'Threshold',  50,...%Threshold for rejection
    'Twindow', [ -199.2 896.9] );%Test window
    %    EEG.setname = [EEG.setname '_ar_50'];
    %    EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path);
    %    EEG = pop_exporteegeventlist(EEG, [data_path subject_list{s} '_eventlist_ar_50.txt']);     

    %Artifact Rejection: Flatline. Remove flatlined data. Max votage diff
    %of leass than 0.5uV within a trial.
    
    %Used from manual flatline. Worked manually but doesn't work in script.
    %Removed per ERPlab help. They said it wouldn't really matter.
    %Trying this again because the problem with all of these was actually
    %saving the dataset each time rather than just at the end.
    %EEG  = pop_artflatline( EEG , 'Channel',  3:16, 'Duration',  498, 'Flag',  [1 4], 'Threshold', [ -0.5 0.5], 'Twindow', [ -199.2 796.9] )
    
    EEG  = pop_artflatline( EEG ,...
    'Channel',  [1:30],...%Set of channels to be tested - all except corr or just interested channels? - Changed to 3:16 instead of 2:16 on 10.19.16.
    'Duration', 498,...%Duration of test window
    'Flag', [ 1 4],...%Flag rejected trials onto the Event List
    'Threshold', [ -0.5 0.5],...%Threshold for low amplitude rejection
    'Twindow', [ -49.2 896.9] );%Test window   
      % EEG.setname = [EEG.setname '_ar_5'];
       % EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path);
       % EEG = pop_exporteegeventlist(EEG, [data_path subject_list{s} '_eventlist_ar_5.txt']);
    
    %Artifact Rejection: Moving Window. Remove data that exceeds a given 
    %threshold as a moving window with a total amplitude, window size, 
    %and window step. Voltage diff of more than 200uV within trial. 
   EEG  = pop_artmwppth( EEG ,...
    'Channel',  1:30,...%Set of channels to be tested - all except corr or just interested channels? - Changed to 3:16 instead of 2:16 on 10.19.16.
    'Flag', [ 1 2],...%Flag rejected trials onto the Event List
    'Threshold',  200,...%Amplitude threshold for rejection
    'Twindow', [ -50 900],...%Test window
    'Windowsize',  200,...%Moving window size
    'Windowstep',  50 );%Moving window step
        EEG.setname = [EEG.setname '_ar'];
        EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path);
        EEG = pop_exporteegeventlist(EEG, [data_path subject_list{s} '_eventlist_ar.txt']);      
        
        
        % Save percentage of rejected trials to file (collapsed across all bins)
        %artifact_proportion = getardetection(EEG);
	%fprintf(fp, '%s: Percentage of rejected trials was %1.2f\n', subject_list{s}, artifact_proportion);
	%fclose(fp)
        EEG = pop_summary_AR_eeg_detection(EEG, ['C:\Users\FERP\RejectionTables&OLD\rejectiontables\CDA\rejection\',[subject_list{s} '.txt']])

        %
        % Averaging. Only good trials.  Include standard deviation.  Save to disk.
        %
        fprintf('\n\n\n**** %s: Averaging ****\n\n\n', subject_list{s});              
        ERP = pop_averager( EEG, 'Criterion', 'good', 'SEM', 'on');
        ERP.erpname = [subject_list{s} '_ERPs'];  % name for erpset menu
        pop_savemyerp(ERP, 'erpname', ERP.erpname, 'filename', [ERP.erpname '.erp'], 'filepath', data_path, 'warning', 'off');
      %
        % Save this final ERP in the ALLERP structure.  This is not
        % necessary unless you want to see the ERPs in the GUI or if you
        % want to access them with another function (e.g., pop_gaverager)
        CURRENTERP = CURRENTERP + 1;
        ALLERP(CURRENTERP) = ERP;
 
%        if (plot_PDFs)
 %           pop_ploterps(ERP, [1 2], 1:17, 'Style', 'ERP1');
  %          pop_fig2pdf([data_path subject_list{s} '.pdf']);
   %     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end % end of the "if/else" statement that makes sure the file exists

end % end of looping through all subjects



fprintf('\n\n\n**** FINISHED ****\n\n\n');
