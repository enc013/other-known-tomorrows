%{
This script does the following:

1. Calculate event related spectral perturbations and visualize them

%}

%% Initialize EEGlab
clear;
eeglab;
close all;
clc;

%% Defining paths and key variables

dirs = setpaths(); %see function in

files_info = dir(fullfile(dirs.eeg,'*_200_1000.set'));

files_info2 = dir(fullfile(dirs.eeg,'*_1000_10000.set'));

%% Extracting all epochs from 0 to 60000 ms

epochs_memory = [];
epochs_future = [];

i_m = 1;
i_f = 1;


for i = 1:length(files_info2)
    filename = files_info2(i).name;
    filepath = fullfile(dirs.eeg,filename);

    EEG = pop_loadset(filepath);

    idx = find(EEG.times == 0);

    if contains(filename,'memory')
        for j = 1:size(EEG.data,3)
            epochs_memory(:,:,i_m) = EEG.data(:,:,j);
            i_m = i_m + 1;
        end

    else
        for j = 1:size(EEG.data,3)
            epochs_future(:,:,i_f) = EEG.data(:,:,j);
            i_f = i_f + 1;
        end
    end

end

%% Calculating Power spectrum density

[spectra_memory, freqs] = spectopo( ...
    epochs_memory,0,EEG.srate, ...
    'overlap',128, 'plot','off');

[spectra_future, freqs] = spectopo( ...
    epochs_future,0,EEG.srate, ...
    'overlap',128, 'plot','off');

%% Calculating Frontal Alpha Asymmetry

%Power 
power_memory = db2pow(spectra_memory);
power_future = db2pow(spectra_future);

%Alpha Power
ba = (freqs >= 8) & (freqs <= 12);
alpha_memory = log(mean(power_memory(:,ba),2));
alpha_future = log(mean(power_future(:,ba),2));

ba = ismember({EEG.chanlocs.labels},'F4');
f4_memory = alpha_memory(ba,:);

ba = ismember({EEG.chanlocs.labels},'F3');
f3_memory = alpha_memory(ba,:);

ba = ismember({EEG.chanlocs.labels},'F4');
f4_future = alpha_future(ba,:);

ba = ismember({EEG.chanlocs.labels},'F3');
f3_future = alpha_future(ba,:);

faa_memory = f4_memory - f3_memory;
faa_future = f4_future - f3_future;




