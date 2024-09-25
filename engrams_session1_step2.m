% Load the data from session1_a_06.mat
load('session1_a_06.mat');  % This will load the 'neuron_network_imaging' variable

% Define parameters
[num_timepoints, num_neurons] = size(neuron_network_imaging);
time_points = linspace(1, 1000, num_timepoints);  % Adjust time_points to match num_timepoints

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

% Create filtered firing matrix
filtered_firing_matrix = firing_matrix(:, filtered_neurons);

% Initialize a matrix to store all time points for all neurons (1 for firing, 0 for no firing)
complete_timepoint_matrix = zeros(num_neurons, num_timepoints);

% Populate the matrix with values (1 for firing, 0 for no firing)
for neuron_idx = 1:length(filtered_neurons)
    neuron = filtered_neurons(neuron_idx);
    for t = 1:num_timepoints
        complete_timepoint_matrix(neuron, t) = filtered_firing_matrix(t, neuron_idx);  % 1 if fired, 0 otherwise
    end
end

% Now, complete_timepoint_matrix holds all neurons and time points
% with 1s for firings and 0s for no firings

% Collect firing events in a list to sort by neuron number
firing_events = [];
for neuron_idx = 1:length(filtered_neurons)
    neuron = filtered_neurons(neuron_idx);
    for t = 1:num_timepoints
        if filtered_firing_matrix(t, neuron_idx) == 1
            firing_events = [firing_events; neuron, time_points(t)];  % Store neuron and corresponding time point
        end
    end
end

% Sort firing events by neuron number (first column)
firing_events = sortrows(firing_events, 1);

% Print the sorted firing events
fprintf('Firing events (N(timepoint, neuron)):\n');
for i = 1:size(firing_events, 1)
    fprintf('N(%.2f, %d) = 1\n', firing_events(i, 2), firing_events(i, 1));
end