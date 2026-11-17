clc;
clear;
close all;

%% Set project folder
baseFolder = 'E:\AP Learn\Sem 5\dsp lab\PROJECT\PPG_PROJECT';

%% 1. Load reference HR labels FIRST
run(fullfile(baseFolder,'step1_load_dataset.m'));

%% 2. Load Phase 5 estimated HR results SECOND
inputFile = fullfile(baseFolder, ...
    'Phase5_HR_Estimation_Results.mat');

S = load(inputFile);

estimatedHR_train_ch1 = S.estimatedHR_train_ch1;
estimatedHR_train_ch2 = S.estimatedHR_train_ch2;

estimatedHR_test_ch1 = S.estimatedHR_test_ch1;
estimatedHR_test_ch2 = S.estimatedHR_test_ch2;

%% 3. Continue with your existing Phase 6 evaluation code
%% Reference values
reference = {
    HR_train(:)
    HR_train(:)
    HR_test(:)
    HR_test(:)
    };

estimates = {
    estimatedHR_train_ch1
    estimatedHR_train_ch2
    estimatedHR_test_ch1
    estimatedHR_test_ch2
    };

names = {
    'TRAIN Channel 1'
    'TRAIN Channel 2'
    'TEST Channel 1'
    'TEST Channel 2'
    };

%% Calculate metrics
results = zeros(4,5);

for k = 1:4

    actual = reference{k};
    predicted = estimates{k};

    valid = isfinite(actual) & isfinite(predicted);

    actual = actual(valid);
    predicted = predicted(valid);

    err = predicted-actual;

    MAE = mean(abs(err));
    RMSE = sqrt(mean(err.^2));
    Bias = mean(err);
    MAPE = mean(abs(err)./max(abs(actual),eps))*100;

    if numel(actual)>1 && std(actual)>0 && std(predicted)>0
        C = corrcoef(actual,predicted);
        correlation = C(1,2);
    else
        correlation = NaN;
    end

    results(k,:) = [MAE RMSE Bias correlation MAPE];

end

%% Display results
resultTable = array2table(results, ...
    'VariableNames', ...
    {'MAE_BPM','RMSE_BPM','Bias_BPM', ...
    'Correlation','MAPE_Percent'}, ...
    'RowNames',names);

fprintf('\n====================================\n');
fprintf('PHASE 6: FINAL PERFORMANCE RESULTS\n');
fprintf('====================================\n');

disp(resultTable);

%% Save results
save(fullfile(baseFolder, ...
    'Phase6_Performance_Evaluation.mat'), ...
    'resultTable','results');

writetable(resultTable, ...
    fullfile(baseFolder,'Phase6_Performance_Evaluation.csv'), ...
    'WriteRowNames',true);

fprintf('\nPhase 6 completed successfully.\n');
