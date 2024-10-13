% Load the dataset (for letter "b" variable length encoding)
load('session2_b_variable_length_06.mat');  % Replace XX with your group number
% Define general parameters
threshold = 250;  % Threshold for detecting peaks (neuron firing)
min_neurons = 10;  % Minimum number of neurons for engram
max_neurons = 25;  % Maximum number of neurons for engram
min_factor = 50;  % Minimum recall duration (50 time points)
max_factor = 250; % Maximum recall duration (250 time points)
% Get the number of recalls (different recall lengths are stored in the cell array)
num_recalls = size(neuron_network_imaging, 1);
% Initialize variables to store valid recall durations and similarity scores
valid_engram_candidates = {};  % To store valid engram results
valid_recall_durations = [];  % To store valid recall durations
% Iterate through each recall (k) and process
for k = 1:num_recalls
    [num_timepoints, num_neurons] = size(neuron_network_imaging{k, 1});  % Get size from recall k data
    % Step 1: Find all divisors (factors) of the total number of timepoints
    possible_recall_durations = divisors(num_timepoints);  % Find all divisors of num_timepoints
    % Step 2: Filter factors to only those between 50 and 250
    valid_factors = possible_recall_durations(possible_recall_durations >= min_factor & possible_recall_durations <= max_factor);
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
            recall_segment = neuron_network_imaging{k, 1}(start_row:end_row, :);
            
            % For each neuron, detect peaks using findpeaks
            for neuron = 1:num_neurons
                signal = recall_segment(:, neuron);  % Get the fluorescence signal for the current neuron
                
                % Dynamically adjust MinPeakDistance based on recall duration
                min_peak_distance = max(1, floor(recall_duration / 10));  % 10% of recall duration
                % Try detecting peaks, and catch any errors without skipping the neuron
                try
                    [~, locs] = findpeaks(signal, 'MinPeakHeight', threshold, ...
                                          'MinPeakDistance', min_peak_distance);
                    % Mark the locations of the peaks (where the neuron fired)
                    binary_matrices(locs, neuron, recall) = 1;
                catch
                    fprintf('Error detecting peaks for Neuron %d in recall %d.\n', neuron, recall);
                end
            end
        end
        
        % Step 4: Check neuron firing consistency across recalls
        neuron_firing_consistency = mean(binary_matrices, 3);  % Averaged across all recalls
        engram_neurons = find(max(neuron_firing_consistency, [], 1) >= 0.5);  % Neurons that fired at least 50% of the time
        
        % Check if the number of neurons in the engram is between 10 and 25
        if length(engram_neurons) >= min_neurons && length(engram_neurons) <= max_neurons
            % Step 5: Store valid engram candidates for this recall duration
            valid_engram_candidates{end+1} = binary_matrices;  % Add valid binary matrix to list
            valid_recall_durations(end+1) = recall_duration;  % Store valid recall duration
        end
    end
end
% Step 6: If there is more than one valid engram candidate, compute similarity score
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
% Step 7: Output the best recall division and similarity score
if ~isempty(best_engram)
    fprintf('Best recall duration: %d rows per recall\n', best_recall_duration);
    if ~isnan(best_similarity_score)
        fprintf('Highest similarity score: %.2f\n', best_similarity_score);
    end
    
    % Step 8: Display the engram neurons for the best recall division
    engram_neurons = find(max(mean(best_engram, 3), [], 1) >= 0.5);
    fprintf('Engram neurons (10-25 neurons):\n');
    for neuron_idx = 1:length(engram_neurons)
        neuron = engram_neurons(neuron_idx);
        firing_times = find(mean(best_engram(:, neuron, :), 3) >= 0.5);
        fprintf('Neuron %d fires at times: ', neuron);
        fprintf('%d ms ', firing_times);
        fprintf('\n');
    end
else
    fprintf('No valid engram sequences found based on the criteria.\n');
end
