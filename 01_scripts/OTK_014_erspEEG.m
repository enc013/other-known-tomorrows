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

files_info2 = dir(fullfile(dirs.eeg,'*_5000_60000.set'));

files_info3 = dir(fullfile(dirs.eeg,'*_1000_10000.set'));

%% Extracting epochs from 1 to 10 seconds
epochs_memory = [];
epochs_future = [];

i_m = 1;
i_f = 1;

for i = 1:length(files_info3)
    filename = files_info3(i).name;
    filepath = fullfile(dirs.eeg,filename);

    EEG = pop_loadset(filepath);

    idx = find(EEG.times == 0);

    if contains(filename,'memory')
        for j = 1:size(EEG.data,3)
            epochs_memory(:,:,i_m) = EEG.data(:,idx:end,j);
            i_m = i_m + 1;
        end

    else
        for j = 1:size(EEG.data,3)
            epochs_future(:,:,i_f) = EEG.data(:,idx:end,j);
            i_f = i_f + 1;
        end
    end
end

%% Calculating Event-related spectral perturbations

%Baseline for Retrospective
idxf = 256*175; %We use only 175 seconds of corresponding baseline

files_info_base = dir(fullfile(dirs.eeg,'*_base_memory_clean.set'));

base_memory = zeros(64,idxf,length(files_info_base));

for i = 1:length(files_info_base)

    filename = files_info_base(i).name;
    filepath = fullfile(dirs.eeg,filename);

    EEG = pop_loadset(filepath);

    d = EEG.data(:,1:idxf);

    base_memory(:,:,i) = d;

end

%Baseline for Future
files_info_base = dir(fullfile(dirs.eeg,'*_base_future_clean.set'));

base_future = zeros(64,idxf,length(files_info_base));

for i = 1:length(files_info_base)

    filename = files_info_base(i).name;
    filepath = fullfile(dirs.eeg,filename);

    EEG = pop_loadset(filepath);

    d = EEG.data(:,1:idxf);

    base_future(:,:,i) = d;

end

%%
%Channels of interest:
chan_names = {'O1','O2','Oz','C3','C4','Cz','F1','F2','F3','F4'};
idxs = find(ismember({EEG.chanlocs.labels},chan_names));

%NewimeF parameters
maxfreq = 40;
cycles = linspace(1,8,maxfreq+5);
freqlim = exp(linspace(log(1.5),log(maxfreq),maxfreq));

%Interpolation to smooth out heatmap
newIndX = linspace(1,200,400);
newIndY = linspace(1,40,120);
[X,Y] = meshgrid(newIndX,newIndY);

%Limits of Color bar
%It's a little annoying, but we have different limits for each plot because
%each channel
lims_array = [
    -7,7; ...
    -8,8;
    -8,8;
    -5,15;
    -5,15;
    -7,7;
    -7,7;
    -6,6;
    -7,7;
    -2,15];

lims_array_diff = [
    -7,7; ...
    -8,8;
    -8,8;
    -8,8;
    -8,8;
    -7,7;
    -7,7;
    -6,6;
    -10,10;
    -7,7];


for i = 1%:length(idxs)
    j = idxs(i);

    chan = chan_names{i};

    %Baseline EEG
    data_retro = squeeze(base_memory(j,:,:));
    data_future = squeeze(base_future(j,:,:));

    %Number of frames and time limit
    frames = size(data_future,1);
    tlimits = [0, 1000*frames/256];

    %Baseline Retrospective ERSP
    [ersp_b,itc_b,powbase_retro,times_b,freqs_b] = newtimef( ...
        data_retro,frames,tlimits,256,cycles, ...
        'freqs',[1,40], ...
        'nfreqs',40, ...
        'plotersp','off', 'plotitc','off');

    %Baseline Future ERSP
    [ersp_b,itc_b,powbase_future,times_b,freqs_b] = newtimef( ...
        data_future,frames,tlimits,256,cycles, ...
        'freqs',[1,40], ...
        'nfreqs',40, ...
        'plotersp','off', 'plotitc','off');

    %ERSP for Retrospective
    d = squeeze(epochs_memory(j,:,:));
    frames = size(d,1);
    tlimits = [0, 1000*frames/256];
    [ersp_retro,itc_retro,powbase_retro,times_retro,freqs_retro] = newtimef( ...
        d, frames, tlimits, 256, cycles, ...
        'powbase',powbase_retro, ...
        'freqs',[1,40], ...
        'nfreqs',40, ...
        'plotersp','off', 'plotitc','off');

    %ERSP for Future
    d = squeeze(epochs_future(j,:,:));
    frames = size(d,1);
    tlimits = [0, 1000*frames/256];
    [ersp_future,itc_future,powbase_future,times_future,freqs_future] = newtimef( ...
        d, frames, tlimits, 256, cycles, ...
        'powbase',powbase_future, ...
        'freqs',[1,40], ...
        'nfreqs',40, ...
        'plotersp','off', 'plotitc','off');
    %Timestamps for x axis
    x = [0,2,4,6,8,10];
    % x = 0:5:60;
    x_idx = [];
    for k = 1:length(x)
        [m,indx] = min(abs(times_future/1000 - x(k)));
        x_idx = [x_idx,indx];
    end
    xtickLabs = {'0','2','4','6','8','10'};
    % xtickLabs = {'0','5','10','15','20','25','30','35','40','45','50','55','60'};

    %PLOTTING
    fig = figure( ...
        'units','normalized', ...
        'outerposition',[0 0 0.4 0.70]);

    %RETROSPECTIVE
    subplot(3,5,1:5);

    ersp_retro2 = interp2(ersp_retro,X,Y);

    img = imagesc(ersp_retro2,lims_array(i,:)); colormap jet;
    set(gca,'YDir','normal');

    xline( ...
        x_idx(2:end-1)*2, ...
        'LineWidth',1.25, ...
        'Color','black', ...
        'alpha',1)

    yline( ...
        [4,8,13,30]*3,'--', ...
        {'Delta','Theta','Alpha','Beta'}, ...
        'LabelVerticalAlignment','Middle', ...
        'LabelHorizontalAlignment','Right', ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'LineWidth',1.5)
    ylabel('Frequency (Hz)','FontSize',14);

    title( ...
        sprintf('ERSP for Retrospective (%s)',chan), ...
        'FontSize',16)

    xticks(x_idx*2);
    xticklabels('');

    yticks([5:5:40]*3);
    yticklabels({'5','10','15','20','25','30','35','40'})

    ax = gca;
    ax.YAxis.FontSize = 10;

    ylabel('Frequency (Hz)','FontSize',14);
    title( ...
        sprintf('ERSP for Retrospective (%s)',chan), ...
        'FontSize',16)

    colorbar;

    %FUTURE
    subplot(3,5,6:10);

    ersp_future2 = interp2(ersp_future,X,Y);

    img = imagesc(ersp_future2,lims_array(i,:)); colormap jet;
    set(gca,'YDir','normal');

    xline( ...
        x_idx(2:end-1)*2, ...
        'LineWidth',1.25, ...
        'Color','black', ...
        'alpha',1)


    yline( ...
        [4,8,13,30]*3,'--', ...
        {'Delta','Theta','Alpha','Beta'}, ...
        'LabelVerticalAlignment','Middle', ...
        'LabelHorizontalAlignment','Right', ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'LineWidth',1.5)

    xticks(x_idx*2);
    xticklabels('');

    ax = gca;
    ax.YAxis.FontSize = 10;

    yticks([5:5:40]*3);
    yticklabels({'5','10','15','20','25','30','35','40'})

    ylabel('Frequency (Hz)','FontSize',14);

    title( ...
        sprintf('ERSP for Future (%s)',chan), ...
        'FontSize',16)

    colorbar;

    %RETRO - FUTURE
    subplot(3,5,11:15);
    img = imagesc(ersp_retro2-ersp_future2,lims_array_diff(i,:)); colormap jet;
    set(gca,'YDir','normal');

    xline( ...
        x_idx(2:end-1)*2, ...
        'LineWidth',1.25, ...
        'Color','black', ...
        'alpha',1)

    yline( ...
        [4,8,13,30]*3,'--', ...
        {'Delta','Theta','Alpha','Beta'}, ...
        'LabelVerticalAlignment','Middle', ...
        'LabelHorizontalAlignment','Right', ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'LineWidth',1.5)

    xticks(x_idx*2);
    xticklabels(xtickLabs);

    yticks([5:5:40]*3);
    yticklabels({'5','10','15','20','25','30','35','40'})

    ax = gca;
    ax.XAxis.FontSize = 12;
    ax.YAxis.FontSize = 10;

    xlabel('Time (seconds)','FontSize',16)
    ylabel('Frequency (Hz)','FontSize',14);
    title( ...
        sprintf('ERSP for Retrospective - Future (%s)',chan), ...
        'FontSize',16)

    colorbar;

    %Saving plots
    % exportgraphics(...
    %     gcf, ...
    %     fullfile(dirs.figures,sprintf('ERSP_%s_retroFutureDiff_10sec.jpeg',chan)), ...
    %     'Resolution', 200);

    % close;


end


%%

%Channels of interest:
chan_names = {'O1','O2','Oz','C3','C4','Cz','F1','F2','F3','F4'};
idxs = find(ismember({EEG.chanlocs.labels},chan_names));

freqs_limits = [1,4;4,8;8,12;13,20;20,30];
bandName = {'delta','theta','alpha','beta1','beta2'};

%NewimeF parameters
maxfreq = 40;
cycles = linspace(1,8,maxfreq+5);
freqlim = exp(linspace(log(1.5),log(maxfreq),maxfreq));

var_names = {'time'};

data_array = [];

for i = 1:length(idxs)
    j = idxs(i);

    chan = chan_names{i};

    %Baseline EEG
    data_retro = squeeze(base_memory(j,:,:));
    data_future = squeeze(base_future(j,:,:));

    %Number of frames and time limit
    frames = size(data_future,1);
    tlimits = [0, 1000*frames/256];

    %Baseline Retrospective ERSP
    [ersp_b,itc_b,powbase_retro,times_b,freqs_b] = newtimef( ...
        data_retro,frames,tlimits,256,cycles, ...
        'freqs',[1,40], ...
        'nfreqs',40, ...
        'plotersp','off', 'plotitc','off');

    %Baseline Future ERSP
    [ersp_b,itc_b,powbase_future,times_b,freqs_b] = newtimef( ...
        data_future,frames,tlimits,256,cycles, ...
        'freqs',[1,40], ...
        'nfreqs',40, ...
        'plotersp','off', 'plotitc','off');

    %ERSP for Retrospective
    d = squeeze(epochs_memory(j,:,:));
    frames = size(d,1);
    tlimits = [0, 1000*frames/256];
    [ersp_retro,itc_retro,powbase_retro,times_retro,freqs_retro] = newtimef( ...
        d, frames, tlimits, 256, cycles, ...
        'powbase',powbase_retro, ...
        'freqs',[1,40], ...
        'nfreqs',40, ...
        'plotersp','off', 'plotitc','off');

    %ERSP for Future
    d = squeeze(epochs_future(j,:,:));
    frames = size(d,1);
    tlimits = [0, 1000*frames/256];
    [ersp_future,itc_future,powbase_future,times_future,freqs_future] = newtimef( ...
        d, frames, tlimits, 256, cycles, ...
        'powbase',powbase_future, ...
        'freqs',[1,40], ...
        'nfreqs',40, ...
        'plotersp','off', 'plotitc','off');

    for k = 1:size(freqs_limits,1)
        ba = (freqs_retro >= freqs_limits(k,1)) & (freqs_retro >= freqs_limits(k,2));
        d1 = ersp_retro(ba,:);
        d1 = nanmean(d1,1);
        var_names = [var_names, sprintf('memory_%s_%s',chan,bandName{k})];
        data_array = [data_array,d1'];

        d1 = ersp_future(ba,:);
        d1 = nanmean(d1,1);
        var_names = [var_names, sprintf('future_%s_%s',chan,bandName{k})];
        data_array = [data_array,d1'];
    
    end

end

data_array = [times_future'/1000,data_array];

%% Saving Spreadsheet of ERSP data


T = array2table(data_array,'VariableNames',var_names);

writetable(T,fullfile(dirs.processedData,'ersp_averages.xlsx'));

    

%% Code for Interpolation

% newIndX = linspace(1,200,400);
% newIndY = linspace(1,40,120);
%
% [X,Y] = meshgrid(newIndX,newIndY);
%
% ersp_future2 = interp2(ersp_future,X,Y);
%
% figure;
% img = imagesc(ersp_future2,lims_array_diff(i,:)); colormap jet;
% set(gca,'YDir','normal');
%
% xticks(x_idx*2);
% xticklabels(xtickLabs);
%
% yticks([5:5:40]*3);
% yticklabels({'5','10','15','20','25','30','35','40'})


%% OLD CODE
%
% %% Extracting all epochs from 0 to 5000 ms
%
% epochs_memory = [];
% epochs_future = [];
%
% i_m = 1;
% i_f = 1;
%
%
% for i = 1:length(files_info2)
%     filename = files_info2(i).name;
%     filepath = fullfile(dirs.eeg,filename);
%
%     EEG = pop_loadset(filepath);
%
%     idx = find(EEG.times == 0);
%
%     if contains(filename,'memory')
%         for j = 1:size(EEG.data,3)
%             epochs_memory(:,:,i_m) = EEG.data(:,:,j);
%             i_m = i_m + 1;
%         end
%
%     else
%         for j = 1:size(EEG.data,3)
%             epochs_future(:,:,i_f) = EEG.data(:,:,j);
%             i_f = i_f + 1;
%         end
%     end
%
% end
%
%
% %% ERPIMAGE to Baseline for retrospective
%
% idxf = 256*175;
%
% files_info_base = dir(fullfile(dirs.eeg,'*_base_memory_clean.set'));
%
% data = zeros(64,idxf,length(files_info_base));
%
% for i = 1:length(files_info_base)
%
%     filename = files_info_base(i).name;
%     filepath = fullfile(dirs.eeg,filename);
%
%     EEG = pop_loadset(filepath);
%
%     d = EEG.data(:,1:idxf);
%
%     data(:,:,i) = d;
%
% end
%
% %Channels of interest:
% chan_names = {'O1','O2','Oz','C3','C4','Cz','F1','F2'};
% idxs = find(ismember({EEG.chanlocs.labels},chan_names));
%
% j = 1;
%
% %Calculating Baseline for each channel
% for i = idxs
%
%     chan = chan_names{j};
%     j = j + 1;
%
%     d = squeeze(data(i,:,:));
%
%     frames = size(d,1);
%     tlimits = [0, 1000*frames/EEG.srate];
%     maxfreq = 40;
%     cycles = linspace(1,8,maxfreq+5);
%     freqlim = exp(linspace(log(1.5),log(maxfreq),maxfreq));
%
%
%     [ersp,itc,powbase_retro,times,freqs] = newtimef( ...
%         d, frames, tlimits, EEG.srate, cycles, ...
%         'freqs',[1,40], ...
%         'nfreqs',40, ...
%         'plotersp','off', 'plotitc','off');
%
%     d_exp = squeeze(epochs_memory(i,1:60*EEG.srate,:));
%     frames = size(d_exp,1);
%     tlimits = [0, 1000*frames/EEG.srate];
%     maxfreq = 40;
%     cycles = linspace(1,8,maxfreq+5);
%     freqlim = exp(linspace(log(1.5),log(maxfreq),maxfreq));
%     fig = figure('Units','normalized','Position',[0,0,0.4,0.4]);
%     [ersp_retro,itc,powbase,times,freqs] = newtimef( ...
%         d_exp, frames, tlimits, EEG.srate, cycles, ...
%         'freqs',[1,40], ...
%         'nfreqs',40, ...
%         'powbase',powbase_retro, ...
%         'title',sprintf('Retrospective Trials: First 60 sec. for %s',chan), ...
%         'plotersp','on', 'plotitc','off');
%
%     %Saving Figure
%     exportgraphics( ...
%         gcf, ...
%         fullfile(dirs.figures,sprintf('ersp_%s_retrospective_60s.jpg',chan)), ...
%         'Resolution',200);
%
%     close;
%
% end
%
% %% ERPIMAGE to Baseline for Future condition
%
% idxf = 256*175;
%
% files_info_base = dir(fullfile(dirs.eeg,'*_base_future_clean.set'));
%
% data = zeros(64,idxf,length(files_info_base));
%
% for i = 1:length(files_info_base)
%
%     filename = files_info_base(i).name;
%     filepath = fullfile(dirs.eeg,filename);
%
%     EEG = pop_loadset(filepath);
%
%     d = EEG.data(:,1:idxf);
%
%     data(:,:,i) = d;
%
% end
%
% %Channels of interest:
% chan_names = {'O1','O2','Oz','C3','C4','Cz','F1','F2'};
% idxs = find(ismember({EEG.chanlocs.labels},chan_names));
%
% j = 1;
%
% %Calculating Baseline for each channel
% for i = idxs
%
%     chan = chan_names{j};
%     j = j + 1;
%
%     d = squeeze(data(i,:,:));
%
%     frames = size(d,1);
%     tlimits = [0, 1000*frames/EEG.srate];
%     maxfreq = 40;
%     cycles = linspace(1,8,maxfreq+5);
%     freqlim = exp(linspace(log(1.5),log(maxfreq),maxfreq));
%
%
%     [ersp,itc,powbase_retro,times,freqs] = newtimef( ...
%         d, frames, tlimits, EEG.srate, cycles, ...
%         'freqs',[1,40], ...
%         'nfreqs',40, ...
%         'plotersp','off', 'plotitc','off');
%
%     d_exp = squeeze(epochs_future(i,1:60*EEG.srate,:));
%     frames = size(d_exp,1);
%     tlimits = [0, 1000*frames/EEG.srate];
%     maxfreq = 40;
%     cycles = linspace(1,8,maxfreq+5);
%     freqlim = exp(linspace(log(1.5),log(maxfreq),maxfreq));
%     fig = figure('Units','normalized','Position',[0,0,0.4,0.4]);
%     [ersp_retro,itc,powbase,times,freqs] = newtimef( ...
%         d_exp, frames, tlimits, EEG.srate, cycles, ...
%         'freqs',[1,40], ...
%         'nfreqs',40, ...
%         'powbase',powbase_retro, ...
%         'title',sprintf('Retrospective Trials: First 60 sec. for %s',chan), ...
%         'plotersp','on', 'plotitc','off');
%
%     %Saving Figure
%     exportgraphics( ...
%         gcf, ...
%         fullfile(dirs.figures,sprintf('ersp_%s_future_60s.jpg',chan)), ...
%         'Resolution',200);
%
%     close;
%
% end
%
%
%
