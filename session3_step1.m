%% Load the Dataset
% Replace 'session3_a_xx.mat' with your actual file name
% Example: 'session3_a_06.mat' if your group number is 06
dataFile = 'session3_a_06.mat';  % Replace 'xx' with your group number, e.g., '06'
if ~isfile(dataFile)
    error('Data file %s does not exist. Please check the file name and path.', dataFile);
end
load(dataFile);  % This should load 'neuron_network_imaging'

% Verify that 'neuron_network_imaging' exists and is a cell array
if ~exist('neuron_network_imaging', 'var')
    error('Variable "neuron_network_imaging" not found in %s.', dataFile);
end
if ~iscell(neuron_network_imaging)
    error('Variable "neuron_network_imaging" is not a cell array.');
end

%% Define General Parameters
threshold = 250;      % Threshold for detecting peaks (neuron firing)
min_neurons = 10;     % Minimum number of neurons for engram
max_neurons = 25;     % Maximum number of neurons for engram
min_factor = 50;      % Minimum recall duration (50 time points = 0.50 seconds)
max_factor = 250;     % Maximum recall duration (250 time points = 2.50 seconds)

%% Get the Number of Recalls
num_recalls = size(neuron_network_imaging, 1);
fprintf('Total number of recalls: %d\n', num_recalls);

%% Initialize Variables to Store Valid Engram Candidates
valid_engram_candidates = {};    % To store valid engram binary matrices
valid_recall_durations = [];     % To store corresponding recall durations

%% Iterate Through Each Recall and Process
for k = 1:num_recalls
    % Extract the data for recall k
    current_data = neuron_network_imaging{k, 1};
    
    [num_timepoints, num_neurons] = size(current_data);
    
    fprintf('\nProcessing Recall %d: %d time points, %d neurons\n', k, num_timepoints, num_neurons);
    
    % Step 1: Find All Divisors (Factors) of the Total Number of Timepoints
    possible_recall_durations = divisors(num_timepoints);
    
    % Step 2: Filter Factors to Only Those Between min_factor and max_factor
    valid_factors = possible_recall_durations(possible_recall_durations >= min_factor & possible_recall_durations <= max_factor);
    
    % Display Valid Recall Durations with Spaces
    if isempty(valid_factors)
        fprintf('No valid recall durations found for Recall %d.\n', k);
    else
        valid_factors_str = strjoin(string(valid_factors), ' ');
        fprintf('Valid recall durations for Recall %d: %s\n', k, valid_factors_str);
    end
    
    % Step 3: Loop Through Each Valid Recall Duration
    for i = 1:length(valid_factors)
        recall_duration = valid_factors(i);
        
        % Calculate the number of segments for this recall_duration
        num_segments = num_timepoints / recall_duration;
        
        % Ensure that recall_duration divides num_timepoints evenly
        if mod(num_timepoints, recall_duration) ~= 0
            fprintf('Skipping recall_duration %d for Recall %d due to non-even division.\n', recall_duration, k);
            continue;
        end
        
        fprintf('Analyzing Recall Duration: %d time points (%.2f seconds)\n', recall_duration, recall_duration * 0.01);
        
        % Initialize Binary Matrix: (time points x neurons x segments)
        % Ensure that recall_duration is an integer
        if ~isscalar(recall_duration) || recall_duration ~= floor(recall_duration)
            fprintf('Invalid recall_duration %d. Skipping.\n', recall_duration);
            continue;
        end
        
        binary_matrices = zeros(recall_duration, num_neurons, num_segments);  % 3D matrix for binary firing data
        
        % Process Each Segment
        for seg = 1:num_segments
            % Define Start and End Rows for the Current Segment
            start_row = (seg - 1) * recall_duration + 1;
            end_row = seg * recall_duration;
            
            % Extract the Segment Data
            recall_segment = current_data(start_row:end_row, :);
            
            % Detect Peaks for Each Neuron in the Segment
            for neuron = 1:num_neurons
                signal = recall_segment(:, neuron);
                
                % Dynamically Adjust MinPeakDistance Based on Recall Duration
                min_peak_distance = max(1, floor(recall_duration / 10));  % 10% of recall duration
                
                % Suppress Specific Warnings Temporarily
                warning('off', 'signal:findpeaks:largeMinPeakHeight');
                
                try
                    % Detect Peaks Using findpeaks
                    [~, locs] = findpeaks(signal, 'MinPeakHeight', threshold, ...
                                          'MinPeakDistance', min_peak_distance);
                    
                    % Ensure locs are within the valid range
                    locs = locs(locs <= recall_duration);
                    
                    % Mark the Locations of the Peaks (Neuron Fired)
                    binary_matrices(locs, neuron, seg) = 1;
                catch ME
                    fprintf('Error detecting peaks for Neuron %d in Segment %d of Recall %d: %s\n', neuron, seg, k, ME.message);
                end
                
                % Re-enable Warnings
                warning('on', 'signal:findpeaks:largeMinPeakHeight');
            end
        end
        
        % Step 4: Check Neuron Firing Consistency Across Segments
        neuron_firing_consistency = mean(binary_matrices, 3);  % Average across segments
        
        % Identify Neurons that Fired in at Least 50% of Segments
        engram_neurons = find(max(neuron_firing_consistency, [], 1) >= 0.5);
        
        fprintf('Number of neurons firing in >=50%% of segments: %d\n', length(engram_neurons));
        
        % Check if the Number of Neurons in the Engram is Within the Specified Range
        if length(engram_neurons) >= min_neurons && length(engram_neurons) <= max_neurons
            % Store the Valid Engram Candidate
            valid_engram_candidates{end+1} = binary_matrices;  %#ok<AGROW>
            valid_recall_durations(end+1) = recall_duration;   %#ok<AGROW>
            fprintf('Engram candidate added for Recall %d with duration %d.\n', k, recall_duration);
        else
            fprintf('Engram candidate rejected for Recall %d with duration %d.\n', k, recall_duration);
        end
    end
end
%% Step 5: Select the Best Engram Candidate Based on Similarity Scores
if length(valid_engram_candidates) > 1
    fprintf('\nMultiple engram candidates found. Computing similarity scores...\n');
    
    best_similarity_score = 0;
    best_engram = [];
    best_recall_duration = 0;
    
    for i = 1:length(valid_engram_candidates)
        current_engram = valid_engram_candidates{i};
        current_duration = valid_recall_durations(i);
        
        % Ensure there are at least two segments to compare
        if size(current_engram, 3) >= 2
            % Extract Binary Mappings for the First Two Segments
            mapping1 = current_engram(:, :, 1);
            mapping2 = current_engram(:, :, 2);
            
            % Compute Jaccard Similarity Score
            intersection = sum(mapping1(:) & mapping2(:));
            union_set = sum(mapping1(:) | mapping2(:));
            
            if union_set == 0
                similarity_score = 0;
            else
                similarity_score = intersection / union_set;
            end
            
            fprintf('Similarity Score for Candidate %d (Duration %d): %.2f\n', i, current_duration, similarity_score);
            
            % Update Best Engram if Current Similarity Score is Higher
            if similarity_score > best_similarity_score
                best_similarity_score = similarity_score;
                best_engram = current_engram;
                best_recall_duration = current_duration;
            end
        end
    end
    
    fprintf('\nBest Engram Candidate: Duration %d time points (%.2f seconds), Similarity Score %.2f\n', ...
        best_recall_duration, best_recall_duration * 0.01, best_similarity_score);
    
elseif length(valid_engram_candidates) == 1
    fprintf('\nOnly one valid engram candidate found.\n');
    best_engram = valid_engram_candidates{1};
    best_recall_duration = valid_recall_durations(1);
    best_similarity_score = NaN;  % Not applicable
    fprintf('Engram Candidate: Duration %d time points (%.2f seconds)\n', ...
        best_recall_duration, best_recall_duration * 0.01);
else
    fprintf('\nNo valid engram candidates found based on the specified criteria.\n');
end
%% Step 6: Output the Engram Neuron Sequence
if ~isempty(best_engram)
    fprintf('\nEngram Neurons (10-25 neurons):\n');
    
    % Compute Neuron Firing Consistency Again for Best Engram
    neuron_firing_consistency_best = mean(best_engram, 3);
    engram_neurons_best = find(max(neuron_firing_consistency_best, [], 1) >= 0.5);
    
    for idx = 1:length(engram_neurons_best)
        neuron = engram_neurons_best(idx);
        % Determine Firing Times Across All Segments
        firing_times = find(mean(best_engram(:, neuron, :), 3) >= 0.5);
        % Convert Time Points to Milliseconds (assuming 10 ms per time point)
        firing_times_ms = firing_times * 10;
        fprintf('Neuron %d fires at times: ', neuron);
        fprintf('%d ms ', firing_times_ms);
        fprintf('\n');
    end
else
    fprintf('Engram determination was unsuccessful. No valid engram sequences found.\n');
end
%% Optional: Display All Engram Neurons in a List
% Uncomment the following block if you wish to display all engram neurons in a list
% if ~isempty(best_engram)
%     fprintf('\nFinal Engram Neurons:\n');
%     fprintf('Neuron Numbers: %s\n', strjoin(string(engram_neurons_best'), ' '));
% else
%     fprintf('No engram neurons to display.\n');
% end
