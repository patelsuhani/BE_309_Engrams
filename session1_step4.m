% Load two neuron mappings (e.g., mapping1 and mapping2) from datasets
% These mappings are binary matrices (time steps x neurons)
load('session1_training_chars_06.mat'); % Load the appropriate dataset

% Example: Assuming you have two mappings for comparison (e.g., for two characters)
mapping1 = neuron_network_imaging(:, :, 1);  % Mapping for the first character
mapping2 = neuron_network_imaging(:, :, 2);  % Mapping for the second character

% Convert these mappings to binary matrices based on a threshold
activation_threshold = 0.5;
binary_mapping1 = mapping1 > activation_threshold;
binary_mapping2 = mapping2 > activation_threshold;

% Ensure the mappings are of the same size
[num_time_steps_1, num_neurons_1] = size(binary_mapping1);
[num_time_steps_2, num_neurons_2] = size(binary_mapping2);

% Check that both mappings are the same size
if num_time_steps_1 ~= num_time_steps_2 || num_neurons_1 ~= num_neurons_2
    error('The two mappings must have the same dimensions.');
end

% Calculate the similarity score using the overlap of neuron activations
% We compute the intersection over the union of the two mappings
intersection = sum(sum(binary_mapping1 & binary_mapping2));  % Common activations
union = sum(sum(binary_mapping1 | binary_mapping2));         % Total activations

% Similarity score is the ratio of the intersection over the union
similarity_score = intersection / union;

% Display the similarity score
fprintf('Similarity Score between the two neuron mappings: %.2f\n', similarity_score);