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

files_info = dir(fullfile(dirs.eeg,'*_raw.set'));

%Head locations
head_locs = fullfile(dirs.misc,'bio_semi_64.ced');

%Non EEG channels
rmCh_labels = {...
    'Trig1','EX1','EX2','EX3','EX4','EX5','EX6','EX7','EX8', ...
    'AUX1','AUX2','AUX3','AUX4','AUX5','AUX6','AUX7','AUX8', ...
    'AUX9','AUX10','AUX11','AUX12','AUX13','AUX14','AUX15','AUX16'};

% Filter Inputs
filter_input_HP = { %highpass
    'locutoff',1,'hicutoff',0, ...
    'filtorder',1690,'revfilt',0, ...
    'usefft',[],'plotfreqz',0};

filter_input_LP = { %low pass
    'locutoff',0,'hicutoff',100, ...
    'filtorder',1690,'revfilt',0, ...
    'usefft',[],'plotfreqz',0};

filter_input_notch = { %notch at 60Hz
    'locutoff',59,'hicutoff',61, ...
    'revfilt',1, ...
    'usefft',[],'plotfreqz',0};

%Clean Raw Data Parameters
cleanRawData_inputs = {
    'FlatlineCriterion',5, ...
    'ChannelCriterion',0.8, ...
    'LineNoiseCriterion','off', ...
    'Highpass','off', ...
    'BurstCriterion', 15, ... %ASR Threshold
    'WindowCriterion','off', ...
    'BurstRejection','off', ... %perform ASR interpolation
    'Distance','Euclidian'}; %no necessary 

%Artifact Probability Thresholds
thresh_artifacts = [
    NaN, NaN; % Brain
    0.7, 1.0; % Muscle
    0.7, 1.0; % Eye
    0.7, 1.0; % Heart
    0.7, 1.0; % Line Noise
    0.7, 1.0; % Channel Noise
    NaN, NaN]; % Other


%% Preprocessing each file

for i = 11:length(files_info)
    filename = files_info(i).name;
    filepath = fullfile(dirs.eeg,filename);

    %load in EEG
    EEG = pop_loadset(filepath);

    %Removing non-eeg chans and loading chan locations
    EEG = pop_select(EEG,'nochannel',rmCh_labels);
    EEG = pop_chanedit(EEG,'load',head_locs);

    %Filtering data
    EEG = pop_eegfiltnew(EEG, filter_input_HP{:}); %highpass @ 1Hz
    EEG = pop_eegfiltnew(EEG, filter_input_LP{:}); %lowpass @ 100Hz
    EEG = pop_eegfiltnew(EEG, filter_input_notch{:}); %notch at 60Hz

    %Resample to 256
    EEG = pop_resample(EEG,256);

    %Clean raw data with ASR
    originalEEG = EEG;

    %Removing C6 FOR THIS PILOT DATASET
    EEG = pop_select(EEG,'nochannel',{'C6'});

    %Removing bad channels and using ASR:
    EEG = pop_clean_rawdata(EEG, cleanRawData_inputs{:});

    %Storing channels that were removed in field (bad channels)
    original_labels = {EEG.chanlocs.labels};
    all_labels = {originalEEG.chanlocs.labels};
    [~,ia,~] = intersect(all_labels,original_labels,'stable');
    removed_channels = all_labels;
    removed_channels(ia) = [];
    EEG.bad_channels = removed_channels;

    % ICA
    EEG = pop_runica( ...
        EEG, ...
        'icatype', 'runica', ...
        'extended',1);

    %identifying artifacts in ICs
    EEG = iclabel(EEG,'default');
    EEG = pop_icflag(EEG,thresh_artifacts);

    %Removing Artifact Components
    EEG = pop_subcomp(EEG,find(EEG.reject.gcompreject));

    %Spherical Spline channel interpolation
    EEG = pop_interp(EEG, originalEEG.chanlocs);

    %Full Rank Average rereference
    EEG = fullRankAveRef(EEG);

    %Saving Data
    EEG = pop_saveset( ...
        EEG, ...
        fullfile(dirs.eeg,[filename(1:end-8),'_clean.set']));

end





