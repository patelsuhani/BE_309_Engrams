% Load the dataset
load('session2_training_chars_misfire_06.mat');  % Loads 'neuron_network_imaging' for multiple characters

% Load the characters from the text file
fileID = fopen('char_train.txt', 'r');
char_sequence = fgetl(fileID);  % Read the single line from the file
fclose(fileID);

% Define parameters
[num_timepoints, num_neurons, num_characters] = size(neuron_network_imaging);  % Adjusted for multiple characters
num_recalls = 10;  % Number of recalls per character
recall_duration = floor(num_timepoints / (num_recalls * num_characters));  % Ensure it's an integer
threshold = 250;  % Threshold for detecting peaks (neuron firing)

% Loop through each character in the char_sequence
for char_idx = 1:length(char_sequence)
    current_char = char_sequence(char_idx);  % Get the current character
    fprintf('\nProcessing character: %s\n', current_char);
    
    % Initialize a 3D matrix to store binary firing events for each recall of the current character
    binary_matrices = zeros(recall_duration, num_neurons, num_recalls);  % Adjusted for each character
    
    % Loop through each recall for the current character
    for recall = 1:num_recalls
        % Define the start and end rows for the current recall
        start_row = (char_idx - 1) * num_recalls * recall_duration + (recall - 1) * recall_duration + 1;
        end_row = start_row + recall_duration - 1;
        
        % For each neuron, detect peaks using findpeaks
        for neuron = 1:num_neurons
            signal = recall_segment(:, neuron);  % Get the fluorescence signal for the current neuron
            
            disp(recall_segment(:, neuron));  % Display signal for a neuron

            % Only proceed if the signal has at least 3 points
            if length(signal) >= 3
                % Detect peaks using findpeaks with a threshold for peak height
                [pks, locs] = findpeaks(signal, 'MinPeakHeight', threshold, 'MinPeakProminence', 50, 'MinPeakDistance', 10);
                
                % Mark the locations of the peaks (where the neuron fired) with 1
                binary_matrices(locs, neuron, recall) = 1;
            end
        end
    end
    
    %disp(binary_matrices);  % Print the binary firing matrix after peak detection

    % Now, calculate the average of the binary matrices across the 10 recalls
    average_binary_matrix = mean(binary_matrices, 3);  % Take the mean across the 3rd dimension (10 recalls)
    
    % Identify the neurons that are part of the engram based on the average matrix
    engram_neurons = find(max(average_binary_matrix, [], 1) >= 0.5);  % Neurons with average >= 0.5
    
    % Display the engram neurons and their firing times based on the average matrix
    fprintf('Engram neurons for character %s (based on consistency across recalls):\n', current_char);
    for neuron_idx = 1:length(engram_neurons)
        neuron = engram_neurons(neuron_idx);
        
        % Find time points where this neuron fires consistently (value >= 0.5 in averaged matrix)
        firing_times = find(average_binary_matrix(:, neuron) >= 0.5);
        
        % Ensure that firing times exist; otherwise, handle the empty case
        if isempty(firing_times)
            fprintf('Neuron %d fires at times: No consistent firing times detected.\n', neuron);
        else
            % Output the firing times
            fprintf('Neuron %d fires at times: ', neuron);
            fprintf('%d ms ', firing_times);
            fprintf('\n');
        end
    end
end
