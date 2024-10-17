% Load the data from session2_a_misfire_06.mat
load('session2_training_chars_misfire_06.mat');  % This will load the 'neuron_network_imaging' variable

% Define parameters
[num_timepoints, num_neurons] = size(neuron_network_imaging);

% Toal data for each character is 1 second, which is 1000 milliseconds
cycle_length_ms = 100;  % 0.1 seconds in milliseconds
num_cycles = 10;    % Total number of cycles
points_per_cycle = num_timepoints / num_cycles;  % Assuming evenly distributed points per cycle

% Specify the neuron you want to plot (for example, neuron 33)
neuron_index = 42;  % Change this to plot a different neuron

% Extract the fluorescence data for the specified neuron
neuron_signal = neuron_network_imaging(:, neuron_index);

% Loop over each cycle and plot
for cycle_num = 1:num_cycles
    % Get the start and end indices for the current cycle
    start_idx = (cycle_num - 1) * points_per_cycle + 1;
    end_idx = cycle_num * points_per_cycle;
    
    % Extract the signal for the current cycle
    cycle_signal = neuron_signal(start_idx:end_idx);
    
    % Create the time vector for the current cycle in milliseconds
    T_cycle = linspace((cycle_num-1) * cycle_length_ms, cycle_num * cycle_length_ms, points_per_cycle);
    
    % Plot the signal for the current cycle
    figure;
    plot(T_cycle, cycle_signal, 'b-', 'LineWidth', 1.5);
    xlabel('Time (milliseconds)');
    ylabel('Fluorescence Intensity');
    title(['Fluorescence of Neuron ' num2str(neuron_index) ' - Cycle ' num2str(cycle_num)]);
    xlim([(cycle_num-1)*cycle_length_ms cycle_num*cycle_length_ms]);  % Set x-axis limits for each cycle in milliseconds
    grid on;
end
