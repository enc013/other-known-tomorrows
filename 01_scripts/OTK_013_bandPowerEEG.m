%{
This script does the following:

1. Calculate Band Power for the several channels and visualizes them

%}

%% Initialize EEGlab
clear;
eeglab;
close all;
clc;

%% Defining paths and key variables

dirs = setpaths(); %see function in

files_info = dir(fullfile(dirs.eeg,'*_1000_10000.set'));

files_info2 = dir(fullfile(dirs.eeg,'*_500_60000.set'));

chan_interest = {'F1','F2','C1','C2'};

%% Extracting all epochs from -200 to 1000 ms

epochs_memory = [];
epochs_future = [];

i_m = 1;
i_f = 1;

for i = 1:length(files_info)
    filename = files_info(i).name;
    filepath = fullfile(dirs.eeg,filename);

    EEG = pop_loadset(filepath);

    ba_chan = ismember({EEG.chanlocs.labels},chan_interest);

    if contains(filename,'memory')
        for j = 1:size(EEG.data,3)
            epochs_memory(:,:,i_m) = EEG.data(ba_chan,:,j);
            i_m = i_m + 1;
        end

    else
        for j = 1:size(EEG.data,3)
            epochs_future(:,:,i_f) = EEG.data(ba_chan,:,j);
            i_f = i_f + 1;
        end
    end

end

%REmoving baseline
t = EEG.times;
ba = (t<=0);

mean_baseF = nanmean(epochs_future(:,ba,:),[2,3]);
mean_baseM = nanmean(epochs_memory(:,ba,:),[2,3]);


%% Ploting Grand Averages for epochs
t = EEG.times;
u_memory = mean(epochs_memory,3) - mean_baseM;
u_future = mean(epochs_future,3) - mean_baseF;

fig = figure('Units','normalized','position',[0,0,0.35,0.5]);

xtlabs = {'-3','-2','-1','0','1','2','$\mu$V'};
xt = -3:3;

for i = 1:size(u_memory,1)

    subplot(2,2,i);
    y1 = movmean(u_memory(i,:),5);
    y2 = movmean(u_future(i,:),5);
    plot(t,y1,'Color','red', 'LineWidth',2, 'DisplayName','Retrospective'); hold on;
    plot(t,y2, 'Color','blue', 'LineWidth',2, 'DisplayName','Future');
    xline(0, 'LineWidth',2, 'Color','black', 'HandleVisibility','off');
    yline(0, 'LineWidth',2, 'Color','black', 'HandleVisibility','off');

    ylim([-3,3]);
    xlim([-200,1000])
    xticks(-200:100:1000)

    ylabel(chan_interest{i},'FontSize',14,'FontWeight','bold', 'Rotation',0)

    ax = gca;
    set(ax, 'TickLabelInterpreter','latex')
    ax.YAxis.FontSize = 10;

    ax.XGrid = 'on';
    ax.GridLineStyle = '-';
    
    yticks(xt);
    yticklabels(xtlabs);

    if i == size(u_memory,1)
        legend('Location','northeast', 'FontSize',16)
    end

end

%Saving Figure
exportgraphics( ...
    gcf, ...
    fullfile(dirs.figures,'line_epoch_200_800_gradAvg_F1F2C1C2.jpeg'), ...
    'Resolution',200);


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

%% Extracting Average Band Power

power_memory = db2pow(spectra_memory);
power_future = db2pow(spectra_future);

%Delta Power
ba = (freqs >= 1) & (freqs <= 4);
delta_memory = pow2db(mean(power_memory(:,ba),2));
delta_future = pow2db(mean(power_future(:,ba),2));

%Theta Power
ba = (freqs >= 4) & (freqs <= 7);
theta_memory = pow2db(mean(power_memory(:,ba),2));
theta_future = pow2db(mean(power_future(:,ba),2));

%Alpha Power
ba = (freqs >= 8) & (freqs <= 12);
alpha_memory = pow2db(mean(power_memory(:,ba),2));
alpha_future = pow2db(mean(power_future(:,ba),2));

%Beta Power
ba = (freqs >= 13) & (freqs <= 30);
beta_memory = pow2db(mean(power_memory(:,ba),2));
beta_future = pow2db(mean(power_future(:,ba),2));

%Gamma (Lower) Power
ba = (freqs >= 30) & (freqs <= 50);
gammaL_memory = pow2db(mean(power_memory(:,ba),2));
gammaL_future = pow2db(mean(power_future(:,ba),2));

%Gamma (higher) Power
ba = (freqs >= 50) & (freqs <= 80);
gammaH_memory = pow2db(mean(power_memory(:,ba),2));
gammaH_future = pow2db(mean(power_future(:,ba),2));

%Concatenating all data
pow_memory = [delta_memory,theta_memory,alpha_memory,beta_memory,gammaL_memory,gammaH_memory];
pow_future = [delta_future,theta_future,alpha_future,beta_future,gammaL_future,gammaH_future];

%% Topoplots between memory and future for all frequency bands

fig = figure('Units','normalized','position',[0,0,0.55,0.5]);

climits = [-12,12; -12,12; -10,5; -15,2;-18,2; -20,2];
t = {{'Delta' '(1-4Hz)'}, {'Theta' '(4-7Hz)'}, {'Alpha' '(8-12Hz)'}, ...
    {'Beta' '(13-30Hz)'}, {'Lower Gamma' '(30-50Hz)'}, {'Higher Gamma' '(50-80Hz)'}};

for i = 1:6
    subplot(3,6,i);
    topoplot( ...
        pow_memory(:,i), ...
        EEG.chanlocs, ...
        'electrodes', 'on', ...
        'emarker',{'.','k',10,1}, ...
        'maplimits',climits(i,:));
    colorbar();

    if i == 1
        ylabel('Retrospective','FontSize',16,'FontWeight','bold')
        ax = gca;
        ax.YAxis.Label.Visible = 'on';
    end

    title(t{i}, 'FontSize',16,'FontWeight','bold');
end

for i = 1:6
    subplot(3,6,i+6);
    topoplot( ...
        pow_future(:,i), ...
        EEG.chanlocs, ...
        'electrodes', 'on', ...
        'emarker',{'.','k',10,1}, ...
        'maplimits',climits(i,:));
    colorbar();

    if i == 1
        ylabel('Future','FontSize',16,'FontWeight','bold')
        ax = gca;
        ax.YAxis.Label.Visible = 'on';
    end
end

for i = 1:6
    subplot(3,6,i+12);
    topoplot( ...
        pow_memory(:,i) - pow_future(:,i), ...
        EEG.chanlocs, ...
        'electrodes', 'on', ...
        'emarker',{'.','k',10,1});
    colorbar();

    if i == 1
        ylabel('Difference','FontSize',16,'FontWeight','bold')
        ax = gca;
        ax.YAxis.Label.Visible = 'on';
    end
end


%Saving Figure
exportgraphics( ...
    gcf, ...
    fullfile(dirs.figures,'topoplot_0_60s.jpeg'), ...
    'Resolution',200);

%% ERPIMAGE to Baseline for retrospective and future conditions

% ersp_array = zeros(70,200,64,2);

idxf = 256*175;

files_info_base = dir(fullfile(dirs.eeg,'*_base_memory_clean.set'));

data = zeros(64,idxf,length(files_info_base));

for i = 1:length(files_info_base)

    filename = files_info_base(i).name;
    filepath = fullfile(dirs.eeg,filename);

    EEG = pop_loadset(filepath);

    d = EEG.data(:,1:idxf);

    data(:,:,i) = d;

end

%Channels of interest: 
chan_names = {'O1','O2','Oz',};

%Calculating Baseline for each channel
for i = 27

    d = squeeze(data(i,:,:));

    frames = size(d,1);
    tlimits = [0, 1000*frames/EEG.srate];
    maxfreq = 70;
    cycles = linspace(1,8,maxfreq+5);
    freqlim = exp(linspace(log(1.5),log(maxfreq),maxfreq));


    [ersp,itc,powbase_retro,times,freqs] = newtimef( ...
        d, frames, tlimits, EEG.srate, cycles, ...
        'freqs',[1,70], ...
        'nfreqs',70, ...
        'plotersp','off', 'plotitc','off');

    d_exp = squeeze(epochs_memory(i,1:60*EEG.srate,:));
    frames = size(d_exp,1);
    tlimits = [0, 1000*frames/EEG.srate];
    maxfreq = 70;
    cycles = linspace(1,8,maxfreq+5);
    freqlim = exp(linspace(log(1.5),log(maxfreq),maxfreq));

    [ersp_retro,itc,powbase,times,freqs] = newtimef( ...
        d_exp, frames, tlimits, EEG.srate, cycles, ...
        'freqs',[1,70], ...
        'nfreqs',70, ...
        'powbase',powbase_retro, ...
        'plotersp','on', 'plotitc','off');


    % ersp_array(:,:,i,1) = ersp_retro;
    
end




