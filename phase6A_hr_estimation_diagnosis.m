
clc;
clear;
close all;

%% =========================================================
% PHASE 6A: HR ESTIMATION DIAGNOSIS
% Reuses Phase 4 and Phase 5 results
%% =========================================================

baseFolder = 'E:\AP Learn\Sem 5\dsp lab\PROJECT\PPG_PROJECT';

%% 1. Load reference HR labels FIRST
run(fullfile(baseFolder,'step1_load_dataset.m'));

%% 2. Load Phase 4 and Phase 5 results
S4 = load(fullfile(baseFolder, ...
    'Phase4_MFOCUSS_Results.mat'));

S5 = load(fullfile(baseFolder, ...
    'Phase5_HR_Estimation_Results.mat'));

%% 3. Recover frequency information

if isfield(S4,'frequencySelected')
    frequencySelected = S4.frequencySelected;

elseif isfield(S4,'frequency')
    frequencySelected = S4.frequency(S4.dictionaryIdx);

else
    error('Frequency information not found in Phase 4.');
end

frequencySelected = frequencySelected(:)';

%% 4. Extract spectral data

spectra = {
    S4.spectrum_train_ch1
    S4.spectrum_train_ch2
    S4.spectrum_test_ch1
    S4.spectrum_test_ch2
};

estimates = {
    S5.estimatedHR_train_ch1(:)
    S5.estimatedHR_train_ch2(:)
    S5.estimatedHR_test_ch1(:)
    S5.estimatedHR_test_ch2(:)
};

references = {
    HR_train(:)
    HR_train(:)
    HR_test(:)
    HR_test(:)
};

groupNames = {
    'TRAIN Channel 1'
    'TRAIN Channel 2'
    'TEST Channel 1'
    'TEST Channel 2'
};

%% 5. Select positive frequencies

positiveMask = frequencySelected >= 0.4 & ...
               frequencySelected <= 5;

positiveFrequency = frequencySelected(positiveMask);

[positiveFrequency,sortIdx] = sort(positiveFrequency);

hrMask = positiveFrequency >= 0.7 & ...
         positiveFrequency <= 3.5;

hrFrequency = positiveFrequency(hrMask);

if isempty(hrFrequency)
    error('No frequencies found in the HR search range.');
end

%% 6. Check dimensions

for g = 1:4

    if size(spectra{g},2) ~= length(frequencySelected)
        error('Spectrum and frequency dimensions do not match.');
    end

    if size(spectra{g},1) ~= length(references{g})
        error('Spectrum and reference HR record counts do not match.');
    end

end

%% 7. Diagnose spectral peaks

dominantPeakHR = cell(4,1);
harmonicRatio = cell(4,1);
subharmonicRatio = cell(4,1);
absoluteError = cell(4,1);
relativeError = cell(4,1);

summary = zeros(4,8);
worstRecords = cell(4,1);

fprintf('\n============================================\n');
fprintf('PHASE 6A: HR ESTIMATION DIAGNOSIS\n');
fprintf('============================================\n');

for g = 1:4

    fprintf('\nDiagnosing %s...\n',groupNames{g});

    % Load spectrum
    currentSpectrum = double(spectra{g});

    currentSpectrum = currentSpectrum(:,positiveMask);
    currentSpectrum = currentSpectrum(:,sortIdx);

    % Use squared magnitude as spectral power
    currentPower = abs(currentSpectrum).^2;

    numRecords = size(currentPower,1);

    peakHR = zeros(numRecords,1);
    secondHarmonicRatio = zeros(numRecords,1);
    halfFrequencyRatio = zeros(numRecords,1);

    estimated = estimates{g};
    reference = references{g};

    %% Examine every record

    for r = 1:numRecords

        p = currentPower(r,:);

        % Find strongest peak inside HR frequency range
        validIndices = find(hrMask);

        [~,localIdx] = max(p(validIndices));

        peakIdx = validIndices(localIdx);

        f0 = positiveFrequency(peakIdx);

        peakHR(r) = f0*60;

        % Power at the dominant frequency
        fundamentalPower = p(peakIdx);

        % Power near twice the dominant frequency
        [~,harmonicIdx] = min(abs( ...
            positiveFrequency - 2*f0));

        harmonicPower = p(harmonicIdx);

        % Power near half the dominant frequency
        [~,subIdx] = min(abs( ...
            positiveFrequency - f0/2));

        subPower = p(subIdx);

        secondHarmonicRatio(r) = ...
            harmonicPower/(fundamentalPower + eps);

        halfFrequencyRatio(r) = ...
            subPower/(fundamentalPower + eps);

    end

    %% Calculate errors

    err = estimated-reference;

    absErr = abs(err);

    relErr = absErr./max(abs(reference),eps)*100;

    dominantPeakHR{g} = peakHR;
    harmonicRatio{g} = secondHarmonicRatio;
    subharmonicRatio{g} = halfFrequencyRatio;
    absoluteError{g} = absErr;
    relativeError{g} = relErr;

    %% Calculate correlation

    valid = isfinite(estimated) & isfinite(reference);

    C = corrcoef(estimated(valid),reference(valid));

    if numel(C) >= 4
        correlation = C(1,2);
    else
        correlation = NaN;
    end

    %% Calculate harmonic-related indicators

    harmonicCount = sum( ...
        estimated(valid) >= 1.7*reference(valid) & ...
        estimated(valid) <= 2.3*reference(valid));

    overestimateCount = sum( ...
        estimated(valid) > reference(valid) + 20);

    %% Summary statistics

    summary(g,:) = [
        mean(estimated,'omitnan'), ...
        mean(reference,'omitnan'), ...
        mean(absErr,'omitnan'), ...
        sqrt(mean(err.^2,'omitnan')), ...
        mean(err,'omitnan'), ...
        correlation, ...
        harmonicCount, ...
        overestimateCount
    ];

    %% Identify worst records

    [sortedErrors,sortErrorIdx] = sort(absErr,'descend');

    nWorst = min(10,numRecords);

    worstRecords{g} = table( ...
        sortErrorIdx(1:nWorst), ...
        reference(sortErrorIdx(1:nWorst)), ...
        estimated(sortErrorIdx(1:nWorst)), ...
        peakHR(sortErrorIdx(1:nWorst)), ...
        sortedErrors(1:nWorst), ...
        'VariableNames', ...
        {'Record','ReferenceHR','EstimatedHR', ...
         'DominantPeakHR','AbsoluteError'});

    fprintf('Mean estimated HR: %.2f BPM\n', ...
        mean(estimated,'omitnan'));

    fprintf('Mean dominant peak HR: %.2f BPM\n', ...
        mean(peakHR,'omitnan'));

    fprintf('Mean reference HR: %.2f BPM\n', ...
        mean(reference,'omitnan'));

    fprintf('Records with error > 20 BPM: %d\n', ...
        sum(absErr > 20));

    fprintf('Records with possible 2x overestimation: %d\n', ...
        harmonicCount);

end

%% 8. Display summary table

diagnosisTable = array2table(summary, ...
    'VariableNames', {
    'MeanEstimatedHR'
    'MeanReferenceHR'
    'MAE'
    'RMSE'
    'Bias'
    'Correlation'
    'Possible2xCases'
    'OverestimateAbove20BPM'
    }, ...
    'RowNames',groupNames);

fprintf('\n============================================\n');
fprintf('PHASE 6A SUMMARY\n');
fprintf('============================================\n');

disp(diagnosisTable);

%% 9. Display worst records

for g = 1:4

    fprintf('\nWorst records: %s\n',groupNames{g});

    disp(worstRecords{g});

end

%% 10. Plot estimated HR vs reference HR

figure('Name','Estimated vs Reference HR');

for g = 1:4

    subplot(2,2,g);

    scatter(references{g},estimates{g},12,'filled');

    hold on;

    minValue = min([references{g};estimates{g}]);
    maxValue = max([references{g};estimates{g}]);

    plot([minValue maxValue], ...
         [minValue maxValue],'r--','LineWidth',1.5);

    xlabel('Reference HR (BPM)');
    ylabel('Estimated HR (BPM)');

    title(groupNames{g});
    grid on;

end

%% 11. Plot dominant spectral peak vs reference HR

figure('Name','Dominant Peak Diagnosis');

for g = 1:4

    subplot(2,2,g);

    scatter(references{g},dominantPeakHR{g},12,'filled');

    hold on;

    minValue = min([references{g};dominantPeakHR{g}]);
    maxValue = max([references{g};dominantPeakHR{g}]);

    plot([minValue maxValue], ...
         [minValue maxValue],'r--','LineWidth',1.5);

    xlabel('Reference HR (BPM)');
    ylabel('Dominant Peak HR (BPM)');

    title(groupNames{g});
    grid on;

end

%% 12. Plot error distribution

figure('Name','HR Estimation Error Distribution');

for g = 1:4

    subplot(2,2,g);

    histogram(absoluteError{g},30);

    xlabel('Absolute Error (BPM)');
    ylabel('Number of Records');

    title(groupNames{g});
    grid on;

end

%% 13. Plot harmonic power ratio

figure('Name','Harmonic Power Ratio');

for g = 1:4

    subplot(2,2,g);

    histogram(harmonicRatio{g},30);

    xlabel('Second Harmonic / Fundamental Power');
    ylabel('Number of Records');

    title(groupNames{g});
    grid on;

end

%% 14. Save diagnostic results

save(fullfile(baseFolder, ...
    'Phase6A_HR_Diagnosis_Results.mat'), ...
    'diagnosisTable', ...
    'dominantPeakHR', ...
    'harmonicRatio', ...
    'subharmonicRatio', ...
    'absoluteError', ...
    'relativeError', ...
    'worstRecords', ...
    'groupNames', ...
    '-v7.3');

fprintf('\n============================================\n');
fprintf('PHASE 6A COMPLETED\n');
fprintf('============================================\n');

fprintf('Saved: Phase6A_HR_Diagnosis_Results.mat\n');
