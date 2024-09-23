% Load the data from session1.mat
load('session1.mat');  % This will load the 'neuron_network_imaging' variable

% Define parameters
[num_timepoints, num_neurons] = size(neuron_network_imaging);

% Create a custom time vector for the full cycle length (10 seconds)
cycle_length = 100;
length = 1000;
T = (1/cycle_length: 1/cycle_length: length/cycle_length);

% Specify the neuron you want to plot (for example, neuron 1)
neuron_index = 70;  % Change this to plot a different neuron

% Extract the fluorescence data for the specified neuron
neuron_signal = neuron_network_imaging(:, neuron_index);

% Plot the fluorescence data for the selected neuron
figure;
plot(T, neuron_signal, 'b-', 'LineWidth', 1.5);
xlabel('Time (seconds)');
ylabel('Fluorescence Intensity');
title(['Fluorescence of Neuron ' num2str(neuron_index) ' Over 10 Seconds']);
xlim([0 max(T)]);  % Set the x-axis limits to match the full cycle length (10s)
grid on;
