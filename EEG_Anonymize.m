clear all
close all
clc

% Make sure EEGLAB is installed and added to your MATLAB path
eeglab; % Start EEGLAB

% Define the main folder path
main_folder = 'C:/Users/...'; % Main directory with EDF+ files

% Get a list of all .edf and .EDF files in the main folder and its subfolders
edf_files = dir(fullfile(main_folder, '**', '*.edf'));

% Loop through each EDF file found
for i = 1:length(edf_files)
    % Get the folder path where the current EDF file is located
    file_folder = edf_files(i).folder;
    % Get the full path of the current EDF file
    input_file = fullfile(file_folder, edf_files(i).name);
    
    % Extract the file name without the extension for later use
    [~, name, ~] = fileparts(edf_files(i).name);
    
    % Extract the folder name from the file path
    [~, folder_name] = fileparts(file_folder);
    
    % Load the EDF file using EEGLAB's biosig function
    EEG = pop_biosig(input_file);
    
    % Get the number of channels and channel labels/types before processing
    num_channels_before = EEG.nbchan;
    channel_labels_before = {EEG.chanlocs.labels};
    channel_types_before = {EEG.chanlocs.type}; % Some may be empty initially

    % Save the information before processing in a .txt file
    info_file_txt_before = fullfile(file_folder, [folder_name '_' name '_before_processing_info.txt']);
    fileID = fopen(info_file_txt_before, 'w');
    fprintf(fileID, 'Number of channels (before processing): %d\n', num_channels_before);
    fprintf(fileID, 'Channel labels and types (before processing):\n');
    for j = 1:num_channels_before
        if isempty(channel_types_before{j})
            channel_types_before{j} = 'Unknown'; % Assign 'Unknown' if no type is present
        end
        fprintf(fileID, 'Channel %d: %s - %s\n', j, channel_labels_before{j}, channel_types_before{j});
    end
    fclose(fileID);
    % 
    % Modify the header to remove personal information (anonymize)
    EEG.subject = 'Anonymous';         % Replace subject name
    EEG.comments = 'Anonymized data';  % Optional: add comments
    EEG.history = [];                  % Remove history if any (optional)
    
    % Iterate over each channel and set its type based on the label
    for chan = 1:EEG.nbchan
        % Retrieve the current channel label
        chan_label = EEG.chanlocs(chan).labels;
        
        % Determine the channel type based on the label
        if contains(chan_label, {'EEG', 'Fp', 'Fz', 'Cz', 'Pz', 'Oz', 'T7', 'T9', 'T8', 'T10','T3','T5','T4','T6', 'O1','O2', 'F10','F3','F4','F7','F9','F8','C3','C4','P3','P4','P8','P10','P7','P9','A1','A2'}, 'IgnoreCase', true)
            channel_type = 'EEG';
        elseif contains(chan_label, {'ECG', 'EKG'}, 'IgnoreCase', true)
            channel_type = 'ECG';
        elseif contains(chan_label, {'PPG', 'Pulse'}, 'IgnoreCase', true)
            channel_type = 'PPG';
        elseif contains(chan_label, {'EMG'}, 'IgnoreCase', true)
            channel_type = 'EMG';
        elseif contains(chan_label, {'EOG'}, 'IgnoreCase', true)
            channel_type = 'EOG';
        else
            % If the label does not match known types, set it as 'Unknown'
            channel_type = 'Unknown';
        end

        % Assign the determined type to the channel
        EEG.chanlocs(chan).type = channel_type;

        % Update the label to include the type
        EEG.chanlocs(chan).labels = sprintf('%s %s', channel_type, chan_label);
    end
    
    % Define the new file name with "_anonymized" suffix and include folder name
    output_file = fullfile(file_folder, [folder_name '_' name '.edf']);
    
    % Save the anonymized EDF file in the same folder as the original
    pop_writeeeg(EEG, output_file, 'TYPE', 'EDF');
    
    % Get the number of channels and channel labels/types after processing
    num_channels_after = EEG.nbchan;
    channel_labels_after = {EEG.chanlocs.labels};
    channel_types_after = {EEG.chanlocs.type};
    
    Save the information after processing in a .txt file
    info_file_txt_after = fullfile(file_folder, [folder_name '_' name '_after_processing_info.txt']);
    fileID = fopen(info_file_txt_after, 'w');
    fprintf(fileID, 'Number of channels (after processing): %d\n', num_channels_after);
    fprintf(fileID, 'Channel labels and types (after processing):\n');
    for j = 1:num_channels_after
        fprintf(fileID, 'Channel %d: %s - %s\n', j, channel_labels_after{j}, channel_types_after{j});
    end
    fclose(fileID);

    fprintf('Anonymized and saved: %s\n', output_file);
    fprintf('Channel info saved in .txt files: %s, %s\n', info_file_txt_before, info_file_txt_after);
end

fprintf('All files processed and anonymized.\n');
