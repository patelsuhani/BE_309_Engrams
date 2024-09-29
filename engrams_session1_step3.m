% Load the data from session1_a_06.mat
load('session1_training_chars_06.mat');  % This will load the 'neuron_network_imaging' variable

% Define parameters
[num_timepoints, num_neurons] = size(neuron_network_imaging);
time_points = linspace(1, 1000, num_timepoints);  % Adjust time_points to be in milliseconds (0 to 1000 ms)
% Set threshold for peak detection
threshold = 250;
% Initialize binary matrix for firing events
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

% Filter neurons firing between 10 and 25 times across all time points
filtered_neurons = [];
for neuron = 1:num_neurons
    num_firing_events = sum(firing_matrix(:, neuron));  % Count firing events for each neuron
    if num_firing_events >= 10 && num_firing_events <= 25
        filtered_neurons = [filtered_neurons, neuron];  % Keep neurons within the firing range
    end
end