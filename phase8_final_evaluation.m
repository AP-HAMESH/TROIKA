
%% PHASE 8: FINAL EVALUATION
clc;
close all;

baseFolder = 'E:\AP Learn\Sem 5\dsp lab\PROJECT\PPG_PROJECT';

S = load(fullfile(baseFolder, 'Phase7_Comparison_Results.mat'));
results = S.results;
Comparison = S.Comparison;

% Extract TEST results only
testRows = contains(Comparison.Group, 'TEST');
TestComparison = Comparison(testRows,:);

disp('===== TEST PERFORMANCE =====');
disp(TestComparison);

% Find best method separately for each test channel
channels = {'TEST Channel 1','TEST Channel 2'};

fprintf('\n===== BEST METHOD PER CHANNEL =====\n');

for c = 1:2

    rows = strcmp(TestComparison.Group, channels{c});
    channelResults = TestComparison(rows,:);

    [bestMAE, idx] = min(channelResults.MAE);

    fprintf('\n%s\n', channels{c});
    fprintf('Best method: %s\n', channelResults.Method{idx});
    fprintf('MAE: %.3f BPM\n', bestMAE);
    fprintf('RMSE: %.3f BPM\n', channelResults.RMSE(idx));
    fprintf('Bias: %.3f BPM\n', channelResults.Bias(idx));
    fprintf('Correlation: %.4f\n', channelResults.Correlation(idx));
end

% Compare all methods on TEST data
figure('Name','Final TEST MAE');
bar(reshape(TestComparison.MAE,3,2)');
set(gca,'XTickLabel',channels);
ylabel('MAE (BPM)');
title('Final TEST MAE Comparison');
legend('Baseline FFT','SSA + FFT','SSA + MFOCUSS', ...
    'Location','northwest');
grid on;

saveas(gcf, fullfile(baseFolder,'Phase8_Final_TEST_MAE.png'));

% Reference versus estimated HR plots for each test channel
for g = 3:4

    figure('Name',results(g).group);

    ref = results(g).reference;

    plot(ref,'k','LineWidth',1.2);
    hold on;
    plot(results(g).baselineFFT,'b');
    plot(results(g).ssaFFT,'r');
    plot(results(g).ssaMFOCUSS,'g');

    xlabel('Record Number');
    ylabel('Heart Rate (BPM)');
    title(['Reference vs Estimated HR - ',results(g).group]);

    legend('Reference','Baseline FFT','SSA + FFT', ...
        'SSA + MFOCUSS','Location','best');

    grid on;

    filename = sprintf('Phase8_%s.png', ...
        strrep(results(g).group,' ','_'));

    saveas(gcf,fullfile(baseFolder,filename));
end

% Save final evaluation
save(fullfile(baseFolder,'Phase8_Final_Evaluation.mat'), ...
    'TestComparison');

writetable(TestComparison, ...
    fullfile(baseFolder,'Phase8_Final_Evaluation.csv'));

fprintf('\nPHASE 8 COMPLETED.\n');
