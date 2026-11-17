
clc;
close all;

%% STEP 1: Check whether Step 1 has been executed

if ~exist('PPG1_train', 'var')
    error('Run step1_load_dataset.m first!');
end

%% STEP 2: Set sampling frequency

fs = 125;

%% STEP 3: Design Butterworth Bandpass Filter

% Heartbeat frequency range: 0.5 Hz to 4 Hz
% This corresponds to approximately 30 to 240 BPM.

low_cutoff = 0.5;
high_cutoff = 4.0;

filter_order = 3;

[b, a] = butter(filter_order, ...
    [low_cutoff high_cutoff]/(fs/2), 'bandpass');

%% STEP 4: Filter TRAIN PPG signals

fprintf('Filtering TRAIN signals...\n');

PPG1_train_filtered = zeros(size(PPG1_train));
PPG2_train_filtered = zeros(size(PPG2_train));

for i = 1:size(PPG1_train,1)

    PPG1_train_filtered(i,:) = ...
        filtfilt(b, a, PPG1_train(i,:));

    PPG2_train_filtered(i,:) = ...
        filtfilt(b, a, PPG2_train(i,:));

end

%% STEP 5: Filter TEST PPG signals

fprintf('Filtering TEST signals...\n');

PPG1_test_filtered = zeros(size(PPG1_test));
PPG2_test_filtered = zeros(size(PPG2_test));

for i = 1:size(PPG1_test,1)

    PPG1_test_filtered(i,:) = ...
        filtfilt(b, a, PPG1_test(i,:));

    PPG2_test_filtered(i,:) = ...
        filtfilt(b, a, PPG2_test(i,:));

end

fprintf('Filtering completed successfully!\n');

%% STEP 6: Plot original and filtered PPG Channel 1

t = (0:999)/fs;

figure;

subplot(2,1,1);

plot(t, PPG1_train(1,:));

title('Original PPG Signal - Channel 1');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(2,1,2);

plot(t, PPG1_train_filtered(1,:));

title('Filtered PPG Signal - Channel 1');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

%% STEP 7: Plot original and filtered PPG Channel 2

figure;

subplot(2,1,1);

plot(t, PPG2_train(1,:));

title('Original PPG Signal - Channel 2');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(2,1,2);

plot(t, PPG2_train_filtered(1,:));

title('Filtered PPG Signal - Channel 2');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

%% STEP 8: Display dimensions

fprintf('\nFiltered TRAIN dimensions:\n');

fprintf('PPG1: %d x %d\n', ...
    size(PPG1_train_filtered));

fprintf('PPG2: %d x %d\n', ...
    size(PPG2_train_filtered));

fprintf('\nFiltered TEST dimensions:\n');

fprintf('PPG1: %d x %d\n', ...
    size(PPG1_test_filtered));

fprintf('PPG2: %d x %d\n', ...
    size(PPG2_test_filtered));
