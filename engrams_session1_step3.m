% Load the data from the session1_training_chars_xx.mat file
load('session1_training_chars_06.mat');  % Replace xx with your group number

% Truncate dataset to match the number of characters in char_mapping
neuron_network_imaging = neuron_network_imaging(:, :, 1:96);  % Adjust this based on what you find is the extra character
num_characters = 96;

% Read the character mapping file as a single string
fileID = fopen('char_train.txt', 'r');
char_data = fscanf(fileID, '%c');  % Read the entire content as characters
fclose(fileID);

% Split the string into individual characters
char_mapping = cellstr(char_data(:));  % Convert string to a cell array of characters

% Determine the size of the dataset
[num_timepoints, num_neurons, num_characters] = size(neuron_network_imaging);

% Check if char_mapping matches num_characters
if length(char_mapping) ~= num_characters
    error('Mismatch between number of characters in char_mapping (%d) and dataset dimensions (%d).', length(char_mapping), num_characters);
end

% Generate time points in milliseconds (assuming 1000 ms total)
time_points = linspace(1, 1000, num_timepoints);  

% Set threshold for peak detection
threshold = 250;

% Initialize firing matrices for each character
firing_matrices = cell(1, num_characters);  % To hold matrices for each character

% Loop over each character (k)
for k = 1:num_characters
    % Initialize binary matrix for firing events for character k
    firing_matrix = zeros(num_timepoints, num_neurons);
    
    % Loop over each neuron (j) for this character
    for neuron = 1:num_neurons
        signal = neuron_network_imaging(:, neuron, k);  % Extract signal for neuron j, character k
        
        % Detect peaks above the threshold
        [pks, locs] = findpeaks(signal, 'MinPeakHeight', threshold);
        
        % Mark firing events in the binary matrix
        for loc = locs
            firing_matrix(loc, neuron) = 1;  % Set N(timepoint, neuron) = 1 for firing events
        end
    end
    
    % Store the firing matrix for this character
    firing_matrices{k} = firing_matrix;
end

% Initialize a cell array to store filtered neurons for each character
filtered_neurons_by_char = cell(1, num_characters);

% Loop over each character
for k = 1:num_characters
    firing_matrix = firing_matrices{k};  % Get the firing matrix for character k
    filtered_neurons = [];
    
    % Filter neurons firing between 10 and 25 times
    for neuron = 1:num_neurons
        num_firing_events = sum(firing_matrix(:, neuron));
        if num_firing_events >= 10 && num_firing_events <= 25
            filtered_neurons = [filtered_neurons, neuron];
        end
    end
    
    % Debugging check: print out the size of filtered_neurons before proceeding
    fprintf('Character %s: %d neurons filtered\n', char_mapping{k}, length(filtered_neurons));
    
    % Check if neurons were filtered, and display a message if none were found
    if isempty(filtered_neurons)
        fprintf('No neurons fired within the set threshold for character %s\n', char_mapping{k});
    end
    
    % Store filtered neurons for this character (store it as an array)
    filtered_neurons_by_char{k} = filtered_neurons;  % Save as an array, not as cell content
end

% Initialize cell array to store firing events for each character
firing_events_by_char = cell(1, num_characters);

% Loop over each character
for k = 1:num_characters
    firing_matrix = firing_matrices{k};
    filtered_neurons = filtered_neurons_by_char{k};  % Get filtered neurons for character k
    
    % Skip if there are no filtered neurons for this character
    if isempty(filtered_neurons)
        fprintf('Skipping character %s due to no valid neurons\n', char_mapping{k});
        continue;  % Skip this character and move to the next one
    end
    
    % Debugging: Ensure filtered_neurons is not exceeding bounds
    fprintf('Processing %d filtered neurons for character %s\n', length(filtered_neurons), char_mapping{k});
    
    % Initialize list to store firing events for this character
    firing_events = [];
    
    % Loop over the filtered neurons (check the array size properly)
    for neuron_idx = 1:length(filtered_neurons)
        neuron = filtered_neurons(neuron_idx);  % Correctly index the array
        
        % Loop over time points and collect firing events
        for t = 1:num_timepoints
            if firing_matrix(t, neuron) == 1
                firing_events = [firing_events; neuron, time_points(t)];
            end
        end
    end
    
    % Sort the firing events by neuron number
    if ~isempty(firing_events)
        firing_events = sortrows(firing_events, 1);
    end
    
    % Store firing events for this character
    firing_events_by_char{k} = firing_events;
end
% Print firing events for each character
for k = 1:num_characters
    fprintf('Firing events for character %s (time <= 100 ms):\n', char_mapping{k});
    firing_events = firing_events_by_char{k};
    
    % Check if there are firing events to print
    if isempty(firing_events)
        fprintf('No firing events detected for character %s within 100 ms.\n', char_mapping{k});
        continue;  % Skip if no events are found for this character
    end
    
    % Loop through the firing events and print only those within 100 ms
    for i = 1:size(firing_events, 1)
        if firing_events(i, 2) <= 100  % Only print events where time is <= 100 ms
            fprintf('N(%.2f ms, Neuron %d) = 1\n', firing_events(i, 2), firing_events(i, 1));
        end
    end
    fprintf('\n');  % Add a new line for better readability
end