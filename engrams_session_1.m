% Load the data from session1.mat
load('session1.mat');  % This will load the 'neuron_network_imaging' variable

% Define parameters
[num_neurons, num_timepoints] = size(neuron_network_imaging);
time_vector = (0:num_timepoints-1) / 100;  % 100 frames per second
