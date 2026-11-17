
clc;
clear;
close all;

%% 1. Set project folder
baseFolder = 'E:\AP Learn\Sem 5\dsp lab\PROJECT\PPG_PROJECT';

%% 2. Load Phase 3 results
resultFile = fullfile(baseFolder, ...
    'Phase3_SSA_Preprocessing_Results.mat');

load(resultFile);

%% 3. Compare provisional HR with reference HR
% TRAIN Channel 1
error_train_ch1 = initialHR_BPM_train(:,1) - HR_train(:);

% TRAIN Channel 2
error_train_ch2 = initialHR_BPM_train(:,2) - HR_train(:);

% TEST Channel 1
error_test_ch1 = initialHR_BPM_test(:,1) - HR_test(:);

% TEST Channel 2
error_test_ch2 = initialHR_BPM_test(:,2) - HR_test(:);

%% 4. Calculate performance metrics
MAE = @(e) mean(abs(e), 'omitnan');
RMSE = @(e) sqrt(mean(e.^2, 'omitnan'));
BIAS = @(e) mean(e, 'omitnan');

fprintf('\n====================================\n');
fprintf('PHASE 3A: PROVISIONAL HR VALIDATION\n');
fprintf('====================================\n');

fprintf('\nTRAIN CHANNEL 1\n');
fprintf('MAE  = %.2f BPM\n', MAE(error_train_ch1));
fprintf('RMSE = %.2f BPM\n', RMSE(error_train_ch1));
fprintf('Bias = %.2f BPM\n', BIAS(error_train_ch1));

fprintf('\nTRAIN CHANNEL 2\n');
fprintf('MAE  = %.2f BPM\n', MAE(error_train_ch2));
fprintf('RMSE = %.2f BPM\n', RMSE(error_train_ch2));
fprintf('Bias = %.2f BPM\n', BIAS(error_train_ch2));

fprintf('\nTEST CHANNEL 1\n');
fprintf('MAE  = %.2f BPM\n', MAE(error_test_ch1));
fprintf('RMSE = %.2f BPM\n', RMSE(error_test_ch1));
fprintf('Bias = %.2f BPM\n', BIAS(error_test_ch1));

fprintf('\nTEST CHANNEL 2\n');
fprintf('MAE  = %.2f BPM\n', MAE(error_test_ch2));
fprintf('RMSE = %.2f BPM\n', RMSE(error_test_ch2));
fprintf('Bias = %.2f BPM\n', BIAS(error_test_ch2));

%% 5. Plot reference vs provisional HR
figure;

subplot(2,1,1);
plot(HR_train, 'k');
hold on;
plot(initialHR_BPM_train(:,1), 'b');
plot(initialHR_BPM_train(:,2), 'r');
title('TRAIN: Reference vs Provisional HR');
xlabel('Record');
ylabel('Heart Rate (BPM)');
legend('Reference', 'Channel 1', 'Channel 2');
grid on;

subplot(2,1,2);
plot(HR_test, 'k');
hold on;
plot(initialHR_BPM_test(:,1), 'b');
plot(initialHR_BPM_test(:,2), 'r');
title('TEST: Reference vs Provisional HR');
xlabel('Record');
ylabel('Heart Rate (BPM)');
legend('Reference', 'Channel 1', 'Channel 2');
grid on;

%% 6. Save validation results
save(fullfile(baseFolder, ...
    'Phase3A_SSA_Validation_Results.mat'), ...
    'error_train_ch1', 'error_train_ch2', ...
    'error_test_ch1', 'error_test_ch2');

fprintf('\nPhase 3A validation completed.\n');
