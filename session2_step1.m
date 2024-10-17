% Load the dataset
load('session2_training_chars_misfire_06.mat');  % This will load 'neuron_network_imaging' for the letter "a"

% Define parameters
[num_timepoints, num_neurons] = size(neuron_network_imaging);  % 1000 rows (time points), 200 columns (neurons)
num_recalls = 10;  % 10 recalls/engrams
recall_duration = num_timepoints / num_recalls;  % 100 ms (100 rows) per recall
threshold = 250;  % Threshold for detecting peaks (neuron firing)

% Initialize a 3D matrix to store binary firing events for each recall
binary_matrices = zeros(recall_duration, num_neurons, num_recalls);  % 100x200x10

% Loop through each recall and generate the binary matrix
for recall = 1:num_recalls
    % Define the start and end rows for the current recall
    start_row = (recall - 1) * recall_duration + 1;
    end_row = recall * recall_duration;
    
    % Extract the current recall segment from the main data
    recall_segment = neuron_network_imaging(start_row:end_row, :);
    
    % For each neuron, detect peaks using findpeaks
    for neuron = 1:num_neurons
        signal = recall_segment(:, neuron);  % Get the fluorescence signal for the current neuron
        
        % Detect peaks using findpeaks with a threshold for peak height
        [pks, locs] = findpeaks(signal, 'MinPeakHeight', threshold, 'MinPeakProminence', 50, 'MinPeakDistance', 10);
        
        % Mark the locations of the peaks (where the neuron fired) with 1
        binary_matrices(locs, neuron, recall) = 1;
    end
end

% Now, calculate the average of the binary matrices across the 10 recalls
average_binary_matrix = mean(binary_matrices, 3);  % Take the mean across the 3rd dimension (10 recalls)

% Identify the neurons that are part of the engram based on the average matrix
engram_neurons = find(max(average_binary_matrix, [], 1) >= 0.5);  % Neurons with average >= 0.8 across any time point

% Display the engram neurons and their firing times based on the average matrix
fprintf('Engram neurons (based on consistency across recalls):\n');
for neuron_idx = 1:length(engram_neurons)
    neuron = engram_neurons(neuron_idx);
    
    % Find time points where this neuron fires consistently (value >= 0.5 in averaged matrix)
    firing_times = find(average_binary_matrix(:, neuron) >= 0.5);
    
    % Ensure that firing times exist; otherwise, handle the empty case
    if isempty(firing_times)
        fprintf('Neuron %d fires at times: No consistent firing times detected.\n', neuron);
    else
        % Output the firing times
        fprintf('Neuron %d fires at times: ', neuron);
        fprintf('%d ms ', firing_times);
        fprintf('\n');
    end
end