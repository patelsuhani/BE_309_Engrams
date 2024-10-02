% Load the dataset (replace 'session2_a_misfire_xx.mat' with the actual file)
load('session2_a_misfire_06.mat');  % This will load 'neuron_network_imaging' for the letter "a"

% Define parameters
[num_timepoints, num_neurons] = size(neuron_network_imaging);
time_points = linspace(1, 1000, num_timepoints);  % Time points in milliseconds (0 to 1000 ms)

% Number of recall events (10 times for letter "a")
num_recalls = 10;
recall_duration = num_timepoints / num_recalls;  % Time points for each recall event

% Set threshold for peak detection (adjust based on data)
threshold = 250;

% Initialize binary matrix for firing events (time points by neurons)
firing_matrix = zeros(num_timepoints, num_neurons);

% Detect firing sequences for each neuron
for neuron = 1:num_neurons
    signal = neuron_network_imaging(:, neuron);
    
    % Use findpeaks to detect peaks above the threshold
    [pks, locs] = findpeaks(signal, 'MinPeakHeight', threshold);
    
    % Mark firing events in the binary matrix
    for loc = locs
        firing_matrix(loc, neuron) = 1;  % Set N(timepoint, neuron) = 1 for firing events
    end
end

% Analyze consistency of neuron firing across 10 recalls
recall_firing_counts = zeros(num_recalls, num_neurons);

% Loop through each recall event and count firing per neuron
for recall = 1:num_recalls
    start_time = (recall - 1) * recall_duration + 1;
    end_time = recall * recall_duration;
    
    % Sum the number of firings for each neuron within this recall event
    recall_firing_counts(recall, :) = sum(firing_matrix(start_time:end_time, :));
end

% Analyze consistency: determine neurons firing frequently across recalls
consistent_firing_neurons = sum(recall_firing_counts > 0) >= 8;  % Neurons firing in at least 8 out of 10 recalls

% Filter for engram neurons (likely those with consistent firing)
engram_neurons = find(consistent_firing_neurons);  % Index of neurons that are part of the engram

% Create filtered firing matrix for engram neurons
engram_firing_matrix = firing_matrix(:, engram_neurons);

% Output the engram neurons and their firing times for time <= 100 ms
fprintf('Engram neurons firing within the first 100 ms:\n');
for neuron_idx = 1:length(engram_neurons)
    neuron = engram_neurons(neuron_idx);
    
    % Find firing times for this neuron
    firing_times = find(engram_firing_matrix(:, neuron_idx));
    
    % Only consider times <= 100 ms
    valid_times = time_points(firing_times(firing_times <= 100));
    
    % Print only if there are valid times within 100 ms
    if ~isempty(valid_times)
        fprintf('Neuron %d fires at times: ', neuron);
        fprintf('%.2f ms ', valid_times);
        fprintf('\n');
    end
end
