%{
This script does the following:

1. Extracts data information (03_processed_data/file_info.xlsx)
2. Extracts eeg and saves as set files (03_processed_data/eeg/*_raw.set)
3. Extracts ecg (from eeg) and saves as csv files (03_processed_data/ecg/*_raw.csv)
4. Extracts audio and saves them as .wav files (03_processed_data/audio/*.wav)
5. Extracts all events from EEG (03_processed_data/events_info.xlsx)

%}

%% Initialize EEGlab
clear;
eeglab; 
close all; 
clc;

%% Defining paths and key variables
dirs = setpaths();

files_info = dir(fullfile(dirs.rawData,'*.xdf'));

%% Iterating through each file to extract any relevant infromation

cell_array = {};

for i = 1:length(files_info)
    
    file_name = files_info(i).name;
    file_path = fullfile(dirs.rawData,file_name);

    %Session, subject, exp_part, condition
    %(i.e. 2368_OKT_1418_base_memory.xdf)
    file_parts = split(file_name,'_');
    sess = file_parts{1};
    subject = file_parts{3};
    exp_part = file_parts{4};
    condition = file_parts{5}(1:end-4);

    %Loading EEG and any event markers
    EEG = pop_loadxdf(file_path);
    EEG.session = sess;
    EEG.subject = subject;
    EEG.exp_part = exp_part;
    EEG.condition = condition;

    %Getting rid of released events if available
    if contains(file_name,'scent')
        ba = contains({EEG.event.type},'pressed');
        EEG.event = EEG.event(ba);
    end

    if not(contains(file_name,'base'))
        %Loading in xdf to extract audio
        [streams, fileheader] = load_xdf(file_path);
        stream_audio = streams{cellfun(@(x) strcmp(x.info.name,'MyAudioStream'),streams)};
        srate_audio = round(stream_audio.info.effective_srate);
        dur_audio = stream_audio.time_stamps(end) - stream_audio.time_stamps(1);
        audio_signal = stream_audio.time_series;

        %Saving Audio
        audiowrite( ...
            fullfile(dirs.audio,[file_name(1:end-4),'.wav']), ...
            audio_signal, srate_audio);
    else
        srate_audio = 0;
        dur_audio = 0;
        audio_signal = 0;
    end

    %Collecting all data Information to save as a spreadsheet
    cell_row = {
        file_name, subject, exp_part, sess, condition, ...
        EEG.xmax, length(EEG.event), EEG.pnts, EEG.srate, ...
        srate_audio, dur_audio, length(audio_signal)};

    cell_array = [cell_array;cell_row];

    %Extracting raw ECG from EEG
    T_ecg = array2table( ...
        [(EEG.times/1000)', EEG.data(66:67,:)',zeros(size(EEG.times'))+EEG.srate], ...
        'VariableNames',{'timestamp','exg1','exg2','srate'});
    writetable(T_ecg, fullfile(dirs.ecg,[file_name(1:end-4),'_raw','.csv']))

    %Saving EEG data
    EEG = pop_saveset(EEG,fullfile(dirs.eeg, [file_name(1:end-4),'_raw','.set']));

end


%% Saving Data Information
varNames = {'filename','subject','exp_part','session','condition', ...
    'duration_eeg','nb_events', 'pnts_eeg','srate_eeg', ...
    'srate_audio','duration_audio', 'pnts_audio'};
T = cell2table(cell_array,'VariableNames',varNames);
writetable(T,fullfile(dirs.processedData,'file_info.xlsx'))


%% Extract Event types and Latencies

cell_array = {};

for i = 1:length(files_info)
    
    file_name = files_info(i).name;
    file_name = [file_name(1:end-4),'_raw.set'];
    file_path = fullfile(dirs.eeg,file_name);

    if contains(file_name,'base')
        continue
    end

    EEG = pop_loadset(file_path); 

    evs = {EEG.event.type}';

    evs_ts = num2cell([EEG.event.latency]/EEG.srate)';

    col_idx = num2cell(1:length(evs))';

    col_fileName = cell(size(evs));
    col_fileName(:) = {file_name};

    col_sub = cell(size(evs));
    col_sub(:) = {EEG.subject};

    col_sess = cell(size(evs));
    col_sess(:) = {EEG.session};

    col_cond = cell(size(evs));
    col_cond(:) = {EEG.condition};

    cell_array = [
        cell_array; ...
        col_fileName,col_sub,col_sess,col_cond,col_idx,evs, evs_ts];

end

%Saving Events information
varNames = {'filename','subject','session','condition','event_idx','event','timestamp'};
T_evs = cell2table(cell_array,'VariableNames',varNames);

if isfile(fullfile(dirs.processedData,'events_info.xlsx'))
    T_prev = readtable(fullfile(dirs.processedData,'events_info.xlsx'));
    T_evs = [T_prev;T_evs];
end



writetable(T_evs,fullfile(dirs.processedData,'events_info.xlsx'))




