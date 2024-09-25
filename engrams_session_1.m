% Load the data from session1.mat
load('session1.mat');  % This will load the 'neuron_network_imaging' variable

% Define parameters
[num_timepoints, num_neurons] = size(neuron_network_imaging);

% Create a custom time vector for the full cycle length (10 seconds)
cycle_length = 100;
length = 1000;
T = (1/cycle_length: 1/cycle_length: length/cycle_length);

% Initialize an empty matrix to store event (spike) times for each neuron
events = cell(num_neurons, 1);

% Set a threshold for peak detection - will adjust this value based on our dataset
threshold = 250;  % Example threshold

% Detect peaks for each neuron using MATLAB's findpeaks function
for neuron = 1:num_neurons
    signal = neuron_network_imaging(:, neuron);

    % Use the 'findpeaks' function to detect peaks above the threshold
    [pks, locs] = findpeaks(signal, 'MinPeakHeight', threshold);

    % Store the time points of the peaks (events) in the cell array
    events{neuron} = T(locs);
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
xlim([0 max(T)]);
ylim([1 num_neurons]);
ylim([1 num_neurons]);
% Display the plot
grid on;