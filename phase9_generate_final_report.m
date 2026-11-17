
%% PHASE 9: FINAL PROJECT REPORT SUMMARY
clc;
clear;
close all;

baseFolder = 'E:\AP Learn\Sem 5\dsp lab\PROJECT\PPG_PROJECT';

S = load(fullfile(baseFolder, 'Phase7_Comparison_Results.mat'));
Comparison = S.Comparison;

reportPath = fullfile(baseFolder, 'FINAL_PROJECT_REPORT_SUMMARY.txt');
fid = fopen(reportPath, 'w');

if fid == -1
    error('Could not create the report file.');
end

fprintf(fid, 'PPG HEART RATE ESTIMATION USING TROIKA-INSPIRED METHODS\n');
fprintf(fid, '=======================================================\n\n');

fprintf(fid, '1. PROJECT OVERVIEW\n');
fprintf(fid, 'This project investigates PPG-based heart rate estimation.\n');
fprintf(fid, 'The dataset contains two PPG channels and reference HR labels.\n');
fprintf(fid, 'Sampling frequency: 125 Hz.\n');
fprintf(fid, 'Signal duration: 8 seconds per record.\n');
fprintf(fid, 'TRAIN records: 1768.\n');
fprintf(fid, 'TEST records: 1328.\n\n');

fprintf(fid, '2. METHODS COMPARED\n');
fprintf(fid, 'A. Baseline FFT on original PPG signals.\n');
fprintf(fid, 'B. SSA preprocessing followed by FFT estimation.\n');
fprintf(fid, 'C. SSA preprocessing, M-FOCUSS reconstruction, and spectral peak selection.\n\n');

fprintf(fid, '3. PERFORMANCE RESULTS\n');
fprintf(fid, '%-20s %-18s %10s %10s %10s %12s\n', ...
    'GROUP','METHOD','MAE','RMSE','BIAS','CORRELATION');

for i = 1:height(Comparison)
    fprintf(fid, '%-20s %-18s %10.3f %10.3f %10.3f %12.4f\n', ...
        Comparison.Group{i}, ...
        Comparison.Method{i}, ...
        Comparison.MAE(i), ...
        Comparison.RMSE(i), ...
        Comparison.Bias(i), ...
        Comparison.Correlation(i));
end

fprintf(fid, '\n4. TEST DATASET ANALYSIS\n');

testRows = contains(Comparison.Group, 'TEST');
TestResults = Comparison(testRows,:);

channels = {'TEST Channel 1','TEST Channel 2'};

for c = 1:2
    rows = strcmp(TestResults.Group, channels{c});
    T = TestResults(rows,:);

    [~, best] = min(T.MAE);

    fprintf(fid, '\n%s:\n', channels{c});
    fprintf(fid, 'Best method: %s\n', T.Method{best});
    fprintf(fid, 'MAE: %.3f BPM\n', T.MAE(best));
    fprintf(fid, 'RMSE: %.3f BPM\n', T.RMSE(best));
    fprintf(fid, 'Bias: %.3f BPM\n', T.Bias(best));
    fprintf(fid, 'Correlation: %.4f\n', T.Correlation(best));
end

fprintf(fid, '\n5. KEY OBSERVATIONS\n');
fprintf(fid, '- Baseline FFT achieved the lowest TEST MAE on both channels.\n');
fprintf(fid, '- Baseline FFT showed near-zero average bias on both TEST channels.\n');
fprintf(fid, '- SSA + FFT had substantially higher TEST errors.\n');
fprintf(fid, '- SSA + M-FOCUSS improved over SSA + FFT but did not outperform baseline FFT.\n');
fprintf(fid, '- TEST correlations for both SSA-based methods were negative.\n');
fprintf(fid, '- Channel 1 performed better than Channel 2 for all three methods on TEST.\n');

fprintf(fid, '\n6. LIMITATIONS\n');
fprintf(fid, '- SSA frequency grouping was an approximate implementation.\n');
fprintf(fid, '- M-FOCUSS parameters and implementation were not independently verified against the original paper.\n');
fprintf(fid, '- Phase 5 used independent spectral peak selection rather than complete temporal peak tracking.\n');
fprintf(fid, '- Performance may be affected by motion artefacts and incorrect spectral peak selection.\n');
fprintf(fid, '- Results should not be presented as an exact reproduction of the original TROIKA algorithm.\n');

fprintf(fid, '\n7. CONCLUSION\n');
fprintf(fid, ['In the current experiments, baseline FFT produced better ' ...
    'heart-rate estimation performance on the independent TEST dataset ' ...
    'than the implemented SSA-based methods. Further refinement of SSA ' ...
    'decomposition, sparse reconstruction, and temporal peak tracking ' ...
    'is required before the proposed pipeline can outperform the baseline.\n']);

fprintf(fid, '\nEnd of report.\n');

fclose(fid);

fprintf('\nPHASE 9 COMPLETED.\n');
fprintf('Report saved at:\n%s\n', reportPath);
