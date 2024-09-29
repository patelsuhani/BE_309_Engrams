% Load the data from session1_a_06.mat
load('session1_training_chars_06.mat');  % This will load the 'neuron_network_imaging' variable

% Define parameters
[num_timepoints, num_neurons] = size(neuron_network_imaging);
time_points = linspace(1, 1000, num_timepoints);  % Adjust time_points to be in milliseconds (0 to 1000 ms)
% Set threshold for peak detection
threshold = 250;
% Initialize binary matrix for firing events
firing_matrix = zeros(num_timepoints, num_neurons);