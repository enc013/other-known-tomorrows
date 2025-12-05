%{
This script does the following:

1. Preprocess EEG data and save them as set files (03_processed_data/eeg/*_clean.set)

%}

%% Initialize EEGlab
clear;
eeglab;
close all;
clc;

%% Defining paths and key variables

dirs = setpaths(); %see function in

files_info = dir(fullfile(dirs.eeg,'*_clean.set'));

%% Iterating through files to epoch data

for i = 1:length(files_info)
    filename = files_info(i).name;
    filepath = fullfile(dirs.eeg,filename);

    if contains(filename,'base')
        continue
    end

    %load in EEG
    EEG = pop_loadset(filepath);
    
    %%%%%%%%%%%%%%%%%% FUTURE EPOCHING %%%%%%%%%%%%%%%%%%
    %Some datasets have future exclusive events
    if any(contains({EEG.event.type},'F pressed'))
        %Epoched EEG (-5 to 60 sec)
        EEG_epoched = pop_epoch(EEG,{'F pressed'},[-5,60]);

        if contains(filename,'part')
            %Saving Data
            EEG_epoched = pop_saveset( ...
                EEG_epoched, ...
                fullfile(dirs.eeg,[filename(1:end-10),'_future_clean_epoched_5000_60000.set']));
        else
            %Saving Data
            EEG_epoched = pop_saveset( ...
                EEG_epoched, ...
                fullfile(dirs.eeg,[filename(1:end-4),'_epoched_5000_60000.set']));
        end


        %Epoched EEG (-0.2 to 1 sec)
        EEG_epoched = pop_epoch(EEG,{'F pressed'},[-0.2,1]);

        if contains(filename,'part')
            %Saving Data
            EEG_epoched = pop_saveset( ...
                EEG_epoched, ...
                fullfile(dirs.eeg,[filename(1:end-10),'_future_clean_epoched_200_1000.set']));
        else
            %Saving Data
            EEG_epoched = pop_saveset( ...
                EEG_epoched, ...
                fullfile(dirs.eeg,[filename(1:end-4),'_epoched_200_1000.set']));
        end


        %Epoched EEG (-1 to 10 sec)
        EEG_epoched = pop_epoch(EEG,{'F pressed'},[-1,10]);

        if contains(filename,'part')

            %Saving Data
            EEG_epoched = pop_saveset( ...
                EEG_epoched, ...
                fullfile(dirs.eeg,[filename(1:end-10),'_future_clean_epoched_1000_10000.set']));

        else

            %Saving Data
            EEG_epoched = pop_saveset( ...
                EEG_epoched, ...
                fullfile(dirs.eeg,[filename(1:end-4),'_epoched_1000_10000.set']));

        end

    end
    
    %%%%%%%%%%%%%%%%%% MEMORY EPOCHING %%%%%%%%%%%%%%%%%%

    if any(contains({EEG.event.type},'M pressed'))
        %Epoched EEG (-5 to 60 sec)
        EEG_epoched = pop_epoch(EEG,{'M pressed'},[-5,60]);

        if contains(filename,'part')
            %Saving Data
            EEG_epoched = pop_saveset( ...
                EEG_epoched, ...
                fullfile(dirs.eeg,[filename(1:end-10),'_memory_clean_epoched_5000_60000.set']));
        else
            %Saving Data
            EEG_epoched = pop_saveset( ...
                EEG_epoched, ...
                fullfile(dirs.eeg,[filename(1:end-4),'_epoched_5000_60000.set']));
        end

        %Epoched EEG (-0.2 to 1 sec)
        EEG_epoched = pop_epoch(EEG,{'M pressed'},[-0.2,1]);

        if contains(filename,'part')
            %Saving Data
            EEG_epoched = pop_saveset( ...
                EEG_epoched, ...
                fullfile(dirs.eeg,[filename(1:end-10),'_memory_clean_epoched_200_1000.set']));
        else
            %Saving Data
            EEG_epoched = pop_saveset( ...
                EEG_epoched, ...
                fullfile(dirs.eeg,[filename(1:end-4),'_epoched_200_1000.set']));

        end

        %Epoched EEG (-1 to 10 sec)
        EEG_epoched = pop_epoch(EEG,{'M pressed'},[-1,10]);

        if contains(filename,'part')
            %Saving Data
            EEG_epoched = pop_saveset( ...
                EEG_epoched, ...
                fullfile(dirs.eeg,[filename(1:end-10),'_memory_clean_epoched_1000_10000.set']));
        else
            %Saving Data
            EEG_epoched = pop_saveset( ...
                EEG_epoched, ...
                fullfile(dirs.eeg,[filename(1:end-4),'_epoched_1000_10000.set']));

        end

    end
end



