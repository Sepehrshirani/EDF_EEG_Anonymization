function processEEGData(main_folder)
% PROCESSEDGDATA - Anonymizes and processes EEG data from EDF files
%
% Inputs:
%   main_folder - Path to directory containing EDF files
%
% Outputs:
%   Saves anonymized EDF files and processing logs in original folders
%
% Example:
%   processEEGData('C:/EEG_Data/')

%% Initialization
clc; close all; clearvars -except main_folder;

% Verify EEGLAB is in path
if ~exist('eeglab.m', 'file')
    error('EEGLAB not found in MATLAB path. Please add EEGLAB first.');
end

% Start EEGLAB (without GUI)
[ALLEEG, EEG, CURRENTSET] = eeglab;

%% File Processing
edf_files = dir(fullfile(main_folder, '**', '*.edf'));  % Recursive search

for i = 1:length(edf_files)
    try
        %% File Handling
        current_file = edf_files(i);
        [filepath, name, ~] = fileparts(current_file.name);
        [~, folder_name] = fileparts(current_file.folder);
        
        fprintf('\nProcessing: %s\n', fullfile(current_file.folder, current_file.name));
        
        %% Load Data
        EEG = pop_biosig(fullfile(current_file.folder, current_file.name));
        EEG.setname = sprintf('%s_%s', folder_name, name);
        
        %% Metadata Handling
        % Create metadata structure
        metadata = struct(...
            'original_file', current_file.name, ...
            'processing_date', datestr(now), ...
            'eeglab_version', eeg_getversion());
        
        % Save original channel info
        metadata.original_channels = struct(...
            'labels', {EEG.chanlocs.labels}, ...
            'types', {EEG.chanlocs.type});
        
        %% Anonymization
        EEG.subject = 'Anonymous';
        EEG.comments = 'Anonymized data';
        EEG.history = [];
        
        %% Channel Processing
        eeg_channel_patterns = {'EEG','Fp','Fz','Cz','Pz','Oz','T','O','C','P','F','A'};
        
        for chan = 1:EEG.nbchan
            chan_label = EEG.chanlocs(chan).labels;
            
            % Determine channel type
            if any(contains(chan_label, eeg_channel_patterns, 'IgnoreCase', true))
                chan_type = 'EEG';
            elseif contains(chan_label, {'ECG','EKG'}, 'IgnoreCase', true)
                chan_type = 'ECG';
            elseif contains(chan_label, {'EMG'}, 'IgnoreCase', true)
                chan_type = 'EMG';
            elseif contains(chan_label, {'EOG'}, 'IgnoreCase', true)
                chan_type = 'EOG';
            elseif contains(chan_label, {'PPG','Pulse'}, 'IgnoreCase', true)
                chan_type = 'PPG';
            else
                chan_type = 'OTHER';
            end
            
            % Update channel info
            EEG.chanlocs(chan).type = chan_type;
            EEG.chanlocs(chan).labels = sprintf('%s_%s', chan_type, chan_label);
        end
        
        %% Save Results
        output_basename = fullfile(current_file.folder, [folder_name '_' name]);
        
        % 1. Save processed EDF
        pop_writeeeg(EEG, [output_basename '_processed.edf'], 'TYPE', 'EDF');
        
        % 2. Save metadata as JSON
        metadata.processed_channels = struct(...
            'labels', {EEG.chanlocs.labels}, ...
            'types', {EEG.chanlocs.type});
        
        json_text = jsonencode(metadata, 'PrettyPrint', true);
        fid = fopen([output_basename '_metadata.json'], 'w');
        fprintf(fid, '%s', json_text);
        fclose(fid);
        
        % 3. Save processing report
        createProcessingReport(EEG, output_basename);
        
        fprintf('Successfully processed: %s\n', current_file.name);
        
    catch ME
        warning('Failed to process %s: %s', current_file.name, ME.message);
        logError(current_file.folder, current_file.name, ME);
    end
end

fprintf('\nProcessing complete for %d files.\n', length(edf_files));
end

%% Helper Functions
function createProcessingReport(EEG, basepath)
% Creates a human-readable processing report
report = {
    'EEG Data Processing Report'
    '========================='
    sprintf('File: %s', EEG.setname)
    sprintf('Date: %s', datestr(now))
    sprintf('Channels: %d', EEG.nbchan)
    ''
    'Channel Information:'
    '-------------------'
    };

for i = 1:EEG.nbchan
    report{end+1} = sprintf('%02d: %-10s (%-5s)', i, ...
        EEG.chanlocs(i).labels, EEG.chanlocs(i).type);
end

% Write to file
fid = fopen([basepath '_report.txt'], 'w');
fprintf(fid, '%s\n', report{:});
fclose(fid);
end

function logError(folder, filename, error_obj)
% Logs processing errors
logfile = fullfile(folder, 'processing_errors.log');
fid = fopen(logfile, 'a');
fprintf(fid, '[%s] Error processing %s:\n%s\n\n', ...
    datestr(now), filename, error_obj.message);
fclose(fid);
end
