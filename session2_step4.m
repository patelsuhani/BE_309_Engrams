% Load the dataset and character mapping
load('session2_training_chars_variable_length_06.mat');  % Replace with your actual file
fileID = fopen('char_train.txt', 'r');
char_train = fscanf(fileID, '%c');  % Read all characters as a single string
fclose(fileID);

% Convert the character string into a cell array of individual characters
char_train = cellstr(char_train(:));  % Convert the string into a cell array of characters

% Define general parameters
threshold = 250;  % Threshold for detecting peaks (neuron firing)
min_neurons = 10;  % Minimum number of neurons for engram
max_neurons = 25;  % Maximum number of neurons for engram
min_factor = 50;  % Minimum recall duration (50 time points)
max_factor = 250; % Maximum recall duration (250 time points)

% Get the number of characters (different recall lengths are stored for each character)
num_characters = size(neuron_network_imaging, 1);

% Initialize list to store engrams for all characters
engram_list = {};

% Iterate through each character in the training set and process
for char_idx = 1:num_characters
    [num_timepoints, num_neurons] = size(neuron_network_imaging{char_idx, 1});  % Get size from character data
    char_name = char_train{char_idx};  % Character name
    
    fprintf('Processing character: %s\n', char_name);
    
    % Step 1: Find all divisors (factors) of the total number of timepoints
    possible_recall_durations = divisors(num_timepoints);  % Find all divisors of num_timepoints
    
    % Step 2: Filter factors to only those between 50 and 250
    valid_factors = possible_recall_durations(possible_recall_durations >= min_factor & possible_recall_durations <= max_factor);
    
    % Initialize variables to store valid recall durations and engram candidates
    valid_engram_candidates = {};  % To store valid engram results
    valid_recall_durations = [];  % To store valid recall durations
    
    % Step 3: Loop through each valid recall duration (filtered divisors)
    for recall_duration = valid_factors
        num_recalls_within_k = num_timepoints / recall_duration;  % Calculate number of recalls for this duration
        
        if mod(num_timepoints, recall_duration) ~= 0
            % If the recall duration doesn't divide evenly, skip this duration
            continue;
        end
        
        binary_matrices = zeros(recall_duration, num_neurons, num_recalls_within_k);  % 3D matrix for binary firing data
        
        % Process each recall segment to detect peaks and create binary matrices
        for recall = 1:num_recalls_within_k
            start_row = (recall - 1) * recall_duration + 1;
            end_row = recall * recall_duration;
            
            % Extract the segment of the data corresponding to this recall
            recall_segment = neuron_network_imaging{char_idx, 1}(start_row:end_row, :);
            
            % For each neuron, detect peaks using findpeaks
            for neuron = 1:num_neurons
                signal = recall_segment(:, neuron);  % Get the fluorescence signal for the current neuron
                
                % Dynamically adjust MinPeakDistance based on recall duration
                min_peak_distance = max(1, floor(recall_duration / 10));  % 10% of recall duration
                % Suppress warnings and detect peaks
                warning('off', 'signal:findpeaks:largeMinPeakHeight');  % Suppress specific findpeaks warnings
                try
                    [~, locs] = findpeaks(signal, 'MinPeakHeight', threshold, ...
                                          'MinPeakDistance', min_peak_distance);
                    % Mark the locations of the peaks (where the neuron fired)
                    binary_matrices(locs, neuron, recall) = 1;
                catch
                    fprintf('Error detecting peaks for Neuron %d in recall %d.\n', neuron, recall);
                end
                warning('on', 'signal:findpeaks:largeMinPeakHeight');  % Re-enable warnings
            end
        end
        
        % Step 4: Check neuron firing consistency across recalls
        neuron_firing_consistency = mean(binary_matrices, 3);  % Averaged across all recalls
        engram_neurons = find(max(neuron_firing_consistency, [], 1) >= 0.5);  % Neurons that fired at least 50% of the time
        
        % Check if the number of neurons in the engram is between 10 and 25
        if length(engram_neurons) >= min_neurons && length(engram_neurons) <= max_neurons
            % Store valid engram candidates for this recall duration
            valid_engram_candidates{end+1} = binary_matrices;  % Add valid binary matrix to list
            valid_recall_durations(end+1) = recall_duration;  % Store valid recall duration
        end
    end
    
    % Step 5: If there is more than one valid engram candidate, compute similarity score
    if length(valid_engram_candidates) > 1
        % Initialize variables to store the best similarity score
        best_similarity_score = 0;
        best_engram = [];
        best_recall_duration = 0;
    
        % Compare similarity between first and second recalls for all valid candidates
        for i = 1:length(valid_engram_candidates)
            binary_matrices = valid_engram_candidates{i};  % Get the binary matrix for this candidate
            recall_duration = valid_recall_durations(i);   % Get corresponding recall duration
            
            % Compute similarity score between the first and second recalls
            if size(binary_matrices, 3) >= 2
                binary_mapping1 = binary_matrices(:, :, 1);  % First recall
                binary_mapping2 = binary_matrices(:, :, 2);  % Second recall
                
                % Compute Jaccard similarity score
                intersection = sum(sum(binary_mapping1 & binary_mapping2));
                union = sum(sum(binary_mapping1 | binary_mapping2));
                similarity_score = intersection / union;
                
                % Update if this is the best similarity score
                if similarity_score > best_similarity_score
                    best_similarity_score = similarity_score;
                    best_engram = binary_matrices;
                    best_recall_duration = recall_duration;
                end
            end
        end
    else
        
        % If only one valid candidate exists, choose that one
        if ~isempty(valid_engram_candidates)
            best_engram = valid_engram_candidates{1};
            best_recall_duration = valid_recall_durations(1);
            best_similarity_score = NaN;  % No need for similarity score when only one candidate
        end
    end
    
    % Step 6: Output the engram neuron sequence for the best recall division
    if ~isempty(best_engram)
        engram_sequence = sprintf('Character "%s":\nNeuron firing sequence: ', char_name);
        
        % Step 7: Display the neuron sequence for the best recall division (just neuron order)
        engram_neurons = find(max(mean(best_engram, 3), [], 1) >= 0.5);
        engram_sequence = strcat(engram_sequence, sprintf('%d ', engram_neurons));
        engram_sequence = strcat(engram_sequence, '\n');
        
        % Store the engram sequence in the list
        engram_list{end+1} = engram_sequence;
    else
        engram_list{end+1} = sprintf('Character "%s": No valid engram sequences found.\n', char_name);
    end
end

% Display all engrams at the end
for i = 1:length(engram_list)
    fprintf('%s\n', engram_list{i});
end
