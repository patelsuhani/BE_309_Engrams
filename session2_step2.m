% Load the dataset
data = load('prelab_session3_training_chars_misfires.mat');  % Replace with the actual file name
neuron_data = data.neuron_network_imaging;  % Assuming the data is stored in this variable

% Load the character mapping from char_train.txt
fileID = fopen('char_train.txt', 'r');
char_train = fscanf(fileID, '%c');  % Read all characters as a single string
fclose(fileID);

% Convert the string into a cell array of individual characters
char_train = cellstr(char_train(:));  % Convert the string into a cell array of characters

% Get the dimensions of the data
[time_steps, num_neurons, num_characters] = size(neuron_data);
fprintf('Data Dimensions - Time steps: %d, Neurons: %d, Characters: %d\n', time_steps, num_neurons, num_characters);

% Ensure the number of characters in char_train matches num_characters
if numel(char_train) ~= num_characters
    error('The number of characters in char_train.txt does not match the number of characters in the data.');
end

% Initialize a structure to store engrams for each character
engrams = struct();

% Smoothing parameters
window_size = 5;  % Adjust the window size as necessary
for k = 1:num_characters
    char = char_train{k};  % Get the character corresponding to index k
    character_data = neuron_data(:, :, k);  % Extract data for this character
    
    % Apply a moving average filter to smooth the data for each neuron
    smoothed_data = movmean(character_data, window_size, 1);
    
    % Calculate the mean activation over time for each neuron
    avg_activation = mean(smoothed_data, 1);
    
    % Dynamic threshold based on the mean and standard deviation
    threshold = mean(avg_activation) + 2 * std(avg_activation);
    
    % Find neurons whose average activation exceeds the dynamic threshold
    significant_neurons = find(avg_activation > threshold);
    
    % Use a shorter, index-based field name (char_ followed by character index)
    field_name = ['char_' num2str(k)];
    
    % Store the engram for the current character in the structure
    engrams.(field_name) = struct('char', char, 'neurons', significant_neurons);
end

% Display the engrams for each character with the count of neurons
fields = fieldnames(engrams);
for i = 1:numel(fields)
    field_name = fields{i};
    engram_neurons = engrams.(field_name).neurons;
    character = engrams.(field_name).char;
    
    % Improved output format with neuron count
    num_neurons_for_char = numel(engram_neurons);
    
    if isempty(engram_neurons)
        fprintf('Engram for character "%s" (field %s): No significant neurons\n', character, field_name);
    else
        % Print the number of neurons and the neuron list
        neuron_list = sprintf('%d, ', engram_neurons);
        neuron_list = neuron_list(1:end-2);  % Remove the trailing comma and space
        fprintf('Engram for character "%s" (field %s): %d neurons - [%s]\n', character, field_name, num_neurons_for_char, neuron_list);
    end
end