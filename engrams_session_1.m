% Load the data from session1.mat
load('session1.mat');  % This will load the 'neuron_network_imaging' variable

% Define parameters
[num_neurons, num_timepoints] = size(neuron_network_imaging);
time_vector = (0:num_timepoints-1) / 100;  % 100 frames per second

% Initialize an empty matrix to store event (spike) times for each neuron
events = cell(num_neurons, 1);

% Set a threshold for peak detection - will adjust this value based on our dataset
threshold = 0.5;  % Example threshold

% Detect peaks for each neuron using MATLAB's findpeaks function
for neuron = 1:num_neurons
    signal = neuron_network_imaging(neuron, :);
    
    % Use the 'findpeaks' function to detect peaks above the threshold
    [pks, locs] = findpeaks(signal, 'MinPeakHeight', threshold);
    
    % Store the time points of the peaks (events) in the cell array
    events{neuron} = time_vector(locs);
end

% Plot the raster plot
figure;
hold on;
for neuron = 1:num_neurons
    % Plot a dot for each event (peak) detected for the neuron
    plot(events{neuron}, neuron * ones(size(events{neuron})), 'k.', 'MarkerSize', 10);
end
hold off;

% Label the axes
xlabel('Time (seconds)');
ylabel('Neuron Number');
title('Raster Plot of Neuron Activity');
xlim([0 max(time_vector)]);
ylim([1 num_neurons]);