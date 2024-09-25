% Load the data from session1_a_06.mat
load('session1_a_06.mat');  % This will load the 'neuron_network_imaging' variable

% Define parameters
[num_timepoints, num_neurons] = size(neuron_network_imaging);
time_points = 0:0.01:1;  % Time points from 0 to 1 second with 10 ms interval

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

% Filter to keep only neurons firing in 10-25 neurons range (logic here)
% Assuming you want to analyze patterns and reduce to significant neurons.

% Print the N(timepoint, neuron) values where the binary matrix has a 1
fprintf('Firing events (N(timepoint, neuron)):\n');
for t = 1:num_timepoints
    for neuron = 1:num_neurons
        if firing_matrix(t, neuron) == 1
            fprintf('N(%.2f, %d) = 1\n', time_points(t), neuron);
        end
    end
end