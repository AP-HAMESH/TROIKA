
clc;
clear;
close all;

%% =========================================================
% PHASE 5: SPECTRAL PEAK SELECTION AND HR ESTIMATION
%% =========================================================

baseFolder = 'E:\AP Learn\Sem 5\dsp lab\PROJECT\PPG_PROJECT';

%% Load reference HR labels
run(fullfile(baseFolder,'step1_load_dataset.m'));
%% 1. Load Phase 4 results
inputFile = fullfile(baseFolder, ...
    'Phase4_MFOCUSS_Results.mat');

S = load(inputFile);


%% 2. Recover frequency information
if isfield(S,'frequencySelected')

    frequencySelected = S.frequencySelected;

elseif isfield(S,'frequency')

    frequencySelected = S.frequency(S.dictionaryIdx);

else

    error(['Frequency information is missing from Phase 4. ', ...
           'Check the saved MAT file.']);
end

%% 3. Load spectrum variables
spectrum_train_ch1 = S.spectrum_train_ch1;
spectrum_train_ch2 = S.spectrum_train_ch2;
spectrum_test_ch1 = S.spectrum_test_ch1;
spectrum_test_ch2 = S.spectrum_test_ch2;
%% 3. Set HR search range
minHR = 42;
maxHR = 210;

minFreq = minHR / 60;
maxFreq = maxHR / 60;

%% 4. Extract positive-frequency bins
positiveMask = frequencySelected >= 0.4 & ...
               frequencySelected <= 5;

positiveFrequency = frequencySelected(positiveMask);

[positiveFrequency,sortIdx] = sort(positiveFrequency);

%% 5. Process all four groups
spectra = {
    spectrum_train_ch1
    spectrum_train_ch2
    spectrum_test_ch1
    spectrum_test_ch2
};

groupNames = {
    'TRAIN Channel 1'
    'TRAIN Channel 2'
    'TEST Channel 1'
    'TEST Channel 2'
};

estimatedResults = cell(4,1);

fprintf('\n====================================\n');
fprintf('PHASE 5: HR ESTIMATION\n');
fprintf('====================================\n');

for group = 1:4

    currentSpectrum = double(spectra{group});

    % Retain positive-frequency columns
    currentSpectrum = currentSpectrum(:,positiveMask);

    % Sort columns according to frequency
    currentSpectrum = currentSpectrum(:,sortIdx);

    numRecords = size(currentSpectrum,1);

    estimatedHR = zeros(numRecords,1);

    fprintf('\nProcessing %s...\n',groupNames{group});

    for r = 1:numRecords

        powerSpectrum = currentSpectrum(r,:)';

        estimatedHR(r) = selectHeartRate( ...
            powerSpectrum,positiveFrequency, ...
            minFreq,maxFreq);

        if mod(r,200)==0 || r==numRecords
            fprintf('%s: %d/%d\n', ...
                groupNames{group},r,numRecords);
        end

    end

    estimatedResults{group} = estimatedHR;

end

%% 6. Store individual outputs
estimatedHR_train_ch1 = estimatedResults{1};
estimatedHR_train_ch2 = estimatedResults{2};

estimatedHR_test_ch1 = estimatedResults{3};
estimatedHR_test_ch2 = estimatedResults{4};

%% 7. Save Phase 5 results
save(fullfile(baseFolder, ...
    'Phase5_HR_Estimation_Results.mat'), ...
    'estimatedHR_train_ch1','estimatedHR_train_ch2', ...
    'estimatedHR_test_ch1','estimatedHR_test_ch2', ...
    'positiveFrequency','minHR','maxHR', ...
    '-v7.3');

%% 8. Plot TRAIN Channel 1
figure;

plot(HR_train,'k','LineWidth',1.2);
hold on;

plot(estimatedHR_train_ch1,'b');

xlabel('Record');
ylabel('Heart Rate (BPM)');
title('TRAIN: Reference vs M-FOCUSS HR');
legend('Reference HR','Estimated HR');
grid on;

%% 9. Plot TEST Channel 1
figure;

plot(HR_test,'k','LineWidth',1.2);
hold on;

plot(estimatedHR_test_ch1,'r');

xlabel('Record');
ylabel('Heart Rate (BPM)');
title('TEST: Reference vs M-FOCUSS HR');
legend('Reference HR','Estimated HR');
grid on;

%% 10. Display summary
fprintf('\n====================================\n');
fprintf('PHASE 5 COMPLETED\n');
fprintf('====================================\n');

fprintf('TRAIN Channel 1 mean HR: %.2f BPM\n', ...
    mean(estimatedHR_train_ch1,'omitnan'));

fprintf('TRAIN Channel 2 mean HR: %.2f BPM\n', ...
    mean(estimatedHR_train_ch2,'omitnan'));

fprintf('TEST Channel 1 mean HR: %.2f BPM\n', ...
    mean(estimatedHR_test_ch1,'omitnan'));

fprintf('TEST Channel 2 mean HR: %.2f BPM\n', ...
    mean(estimatedHR_test_ch2,'omitnan'));

fprintf('\nSaved: Phase5_HR_Estimation_Results.mat\n');

%% =========================================================
% LOCAL FUNCTION: FUNDAMENTAL AND HARMONIC PEAK SELECTION
%% =========================================================
function hr = selectHeartRate(powerSpectrum,frequency, ...
                              minFreq,maxFreq)

    df = median(diff(frequency));

    % Restrict to the allowed heart-rate frequency range
    valid = find(frequency >= minFreq & ...
                 frequency <= maxFreq);

    candidateIndices = [];

    % Identify local spectral maxima
    for k = 2:length(powerSpectrum)-1

        if powerSpectrum(k) >= powerSpectrum(k-1) && ...
           powerSpectrum(k) > powerSpectrum(k+1)

            if ismember(k,valid)
                candidateIndices(end+1) = k;
            end

        end
    end

    % Fallback if no local peak exists
    if isempty(candidateIndices)
        [~,idx] = max(powerSpectrum(valid));
        candidateIndices = valid(idx);
    end

    % Score each fundamental candidate
    scores = zeros(length(candidateIndices),1);

    for k = 1:length(candidateIndices)

        idx = candidateIndices(k);

        f0 = frequency(idx);

        % Fundamental power
        score = powerSpectrum(idx);

        % First harmonic power
        harmonicFrequency = 2*f0;

        if harmonicFrequency <= max(frequency)

            [~,harmonicIdx] = min( ...
                abs(frequency-harmonicFrequency));

            % Add weighted harmonic contribution
            score = score + ...
                0.5*powerSpectrum(harmonicIdx);

        end

        scores(k) = score;

    end

    % Select candidate with maximum score
    [~,bestIdx] = max(scores);

    selectedIdx = candidateIndices(bestIdx);

    hr = frequency(selectedIdx)*60;

end
