
clc;
clear;
close all;

%% 1. Project folder
baseFolder = 'E:\AP Learn\Sem 5\dsp lab\PROJECT\PPG_PROJECT';

%% 2. Load Phase 3 results
resultFile = fullfile(baseFolder, ...
    'Phase3_SSA_Preprocessing_Results.mat');

load(resultFile);

%% 3. Set error threshold
errorLimit = 20;  % BPM

%% 4. Calculate absolute errors
errTrain1 = abs(initialHR_BPM_train(:,1) - HR_train(:));
errTrain2 = abs(initialHR_BPM_train(:,2) - HR_train(:));

errTest1 = abs(initialHR_BPM_test(:,1) - HR_test(:));
errTest2 = abs(initialHR_BPM_test(:,2) - HR_test(:));

%% 5. Count large errors
fprintf('\n========== LARGE ERROR DIAGNOSTICS ==========\n');

fprintf('\nTRAIN Channel 1: %d records above 20 BPM\n', ...
    sum(errTrain1 > errorLimit));

fprintf('TRAIN Channel 2: %d records above 20 BPM\n', ...
    sum(errTrain2 > errorLimit));

fprintf('\nTEST Channel 1: %d records above 20 BPM\n', ...
    sum(errTest1 > errorLimit));

fprintf('TEST Channel 2: %d records above 20 BPM\n', ...
    sum(errTest2 > errorLimit));

%% 6. Display worst 15 records
[~, idx] = sort(errTrain1, 'descend');

fprintf('\nWorst 15 TRAIN Channel 1 records:\n');
disp(table(idx(1:15), HR_train(idx(1:15)), ...
    initialHR_BPM_train(idx(1:15),1), ...
    errTrain1(idx(1:15)), ...
    'VariableNames', ...
    {'Record','ReferenceHR','EstimatedHR','AbsoluteError'}));

%% 7. Check estimates near frequency search boundaries
% The provisional HR search range was 0.7 to 3.5 Hz.
% Convert these limits to BPM.

fprintf('\n========== FREQUENCY RANGE CHECK ==========\n');

fprintf('Lower frequency limit: %.1f BPM\n', 0.7*60);
fprintf('Upper frequency limit: %.1f BPM\n', 3.5*60);

nearLower = initialHR_BPM_train(:,1) < 50;
nearUpper = initialHR_BPM_train(:,1) > 195;

fprintf('\nTRAIN Ch1 estimates below 50 BPM: %d\n', ...
    sum(nearLower));

fprintf('TRAIN Ch1 estimates above 195 BPM: %d\n', ...
    sum(nearUpper));

%% 8. Plot absolute error distributions
figure;

subplot(2,2,1);
histogram(errTrain1);
title('TRAIN Channel 1 Absolute Error');
xlabel('Error (BPM)');
ylabel('Number of records');
grid on;

subplot(2,2,2);
histogram(errTrain2);
title('TRAIN Channel 2 Absolute Error');
xlabel('Error (BPM)');
ylabel('Number of records');
grid on;

subplot(2,2,3);
histogram(errTest1);
title('TEST Channel 1 Absolute Error');
xlabel('Error (BPM)');
ylabel('Number of records');
grid on;

subplot(2,2,4);
histogram(errTest2);
title('TEST Channel 2 Absolute Error');
xlabel('Error (BPM)');
ylabel('Number of records');
grid on;

%% 9. Save diagnostic output
save(fullfile(baseFolder, ...
    'Phase3A_HR_Diagnostic_Results.mat'), ...
    'errTrain1','errTrain2','errTest1','errTest2');

fprintf('\nDiagnostic analysis completed.\n');
