function dirs = setpaths()
% SETPATHS specifies data paths, output paths, etc.
% Edit the paths in this function before running the analysis code on a new machine.
% Usually it is sufficient to adjust the parent directory

% Input/output folder paths
% dirs.home = 'C:\Users\llange\Arbeit\Projects\Human AI Teaming\SpaceTransitWithEEG\'; % parent directory
% dirs.home = fullfile('..');

dirs.scripts = fullfile('..','01_scripts');
dirs.rawData = fullfile('..','02_raw_data');
dirs.processedData = fullfile('..','03_processed_data');
dirs.eeg = fullfile(dirs.processedData, 'eeg');
dirs.ecg = fullfile(dirs.processedData, 'ecg');
dirs.audio = fullfile(dirs.processedData,'audio');
dirs.behavioral = fullfile(dirs.processedData,'behavioral');
dirs.figures = fullfile('..','04_figures');
dirs.results = fullfile('..','05_results');
dirs.misc = fullfile('..','00_misc');
dirs.dep = 'dependencies';

% Create directories if they don't already exist
warning('off', 'MATLAB:MKDIR:DirectoryExists');
fn = fieldnames(dirs);
for i = 1:length(fn)
    status = mkdir(dirs.(fn{i}));
end

disp('Successfully set paths. Check the dirs variable.');

end