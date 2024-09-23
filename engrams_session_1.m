% Load the data from session1.mat
load('session1.mat');  % This will load the 'neuron_network_imaging' variable

% Define parameters
[num_neurons, num_timepoints] = size(neuron_network_imaging);
time_vector = (0:num_timepoints-1) / 100;  % 100 frames per second

% Initialize an empty matrix to store binarized event data for each neuron
binarized_events = zeros(num_neurons, num_timepoints);

% Binarize the data for each neuron using the imbinarize function
for neuron = 1:num_neurons
    % Binarize the fluorescence signal
    binarized_events(neuron, :) = imbinarize(neuron_network_imaging(neuron, :));
end

% Create a raster plot
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

% Display the plot
set(gca, 'YDir', 'reverse');  % Optional: reverse the Y-axis so neuron 1 is at the top
grid on;