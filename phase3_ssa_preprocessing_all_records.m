
%% PHASE 3: SSA PREPROCESSING AND SECOND-ORDER DIFFERENCE
% Processes all TRAIN and TEST records, both PPG channels.
%
% Based on the preprocessing and SSA stages of TROIKA.
%
% IMPORTANT:
% 1. SSA grouping below is provisional frequency-based grouping.
% 2. HR initialization is performed independently per record.
% 3. The original TROIKA uses previous-window HR information.
% 4. Second-order difference is retained as specified in TROIKA.
%
% This script is not yet a complete TROIKA reproduction.

clc;
clear;
close all;

%% STEP 1: PROJECT PATH AND LOAD DATA

baseFolder = 'E:\AP Learn\Sem 5\dsp lab\PROJECT\PPG_PROJECT';

fprintf('\nLoading dataset...\n');

run(fullfile(baseFolder,'step1_load_dataset.m'));

%% STEP 2: PARAMETERS

fs = 125;
nfft = 4096;
L = 400;
delta = 10;

frequencyTolerance = delta*fs/nfft;

lowFreq = 0.4;
highFreq = 5;

[b,a] = butter(3,[lowFreq highFreq]/(fs/2),'bandpass');

numTrain = size(PPG1_train,1);
numTest = size(PPG1_test,1);

N = size(PPG1_train,2);

if size(PPG1_test,2) ~= N
    error('TRAIN and TEST records have different lengths.');
end

if L >= N/2
    error('SSA parameter L must be less than half the record length.');
end

%% STEP 3: PREALLOCATE OUTPUTS

cleanPPG1_train = zeros(numTrain,N,'single');
cleanPPG2_train = zeros(numTrain,N,'single');

cleanPPG1_test = zeros(numTest,N,'single');
cleanPPG2_test = zeros(numTest,N,'single');

% Second-order difference has N-2 samples.

diffPPG1_train = zeros(numTrain,N-2,'single');
diffPPG2_train = zeros(numTrain,N-2,'single');

diffPPG1_test = zeros(numTest,N-2,'single');
diffPPG2_test = zeros(numTest,N-2,'single');

removedGroups_train = zeros(numTrain,2);
removedGroups_test = zeros(numTest,2);

initialHR_Hz_train = zeros(numTrain,2);
initialHR_Hz_test = zeros(numTest,2);

initialHR_BPM_train = zeros(numTrain,2);
initialHR_BPM_test = zeros(numTest,2);

%% STEP 4: PROCESS TRAIN CHANNEL 1

fprintf('\nProcessing TRAIN Channel 1...\n');

for i = 1:numTrain

    [cleaned,difference,removed,hrHz] = ...
        processRecord(PPG1_train(i,:), ...
        ACCX_train(i,:),ACCY_train(i,:),ACCZ_train(i,:), ...
        b,a,fs,L,nfft,frequencyTolerance);

    cleanPPG1_train(i,:) = single(cleaned);
    diffPPG1_train(i,:) = single(difference);

    removedGroups_train(i,1) = removed;

    initialHR_Hz_train(i,1) = hrHz;
    initialHR_BPM_train(i,1) = hrHz*60;

    if mod(i,25)==0 || i==numTrain
        fprintf('TRAIN Ch1: %d/%d\n',i,numTrain);
    end
end

%% STEP 5: PROCESS TRAIN CHANNEL 2

fprintf('\nProcessing TRAIN Channel 2...\n');

for i = 1:numTrain

    [cleaned,difference,removed,hrHz] = ...
        processRecord(PPG2_train(i,:), ...
        ACCX_train(i,:),ACCY_train(i,:),ACCZ_train(i,:), ...
        b,a,fs,L,nfft,frequencyTolerance);

    cleanPPG2_train(i,:) = single(cleaned);
    diffPPG2_train(i,:) = single(difference);

    removedGroups_train(i,2) = removed;

    initialHR_Hz_train(i,2) = hrHz;
    initialHR_BPM_train(i,2) = hrHz*60;

    if mod(i,25)==0 || i==numTrain
        fprintf('TRAIN Ch2: %d/%d\n',i,numTrain);
    end
end

%% STEP 6: PROCESS TEST CHANNEL 1

fprintf('\nProcessing TEST Channel 1...\n');

for i = 1:numTest

    [cleaned,difference,removed,hrHz] = ...
        processRecord(PPG1_test(i,:), ...
        ACCX_test(i,:),ACCY_test(i,:),ACCZ_test(i,:), ...
        b,a,fs,L,nfft,frequencyTolerance);

    cleanPPG1_test(i,:) = single(cleaned);
    diffPPG1_test(i,:) = single(difference);

    removedGroups_test(i,1) = removed;

    initialHR_Hz_test(i,1) = hrHz;
    initialHR_BPM_test(i,1) = hrHz*60;

    if mod(i,25)==0 || i==numTest
        fprintf('TEST Ch1: %d/%d\n',i,numTest);
    end
end

%% STEP 7: PROCESS TEST CHANNEL 2

fprintf('\nProcessing TEST Channel 2...\n');

for i = 1:numTest

    [cleaned,difference,removed,hrHz] = ...
        processRecord(PPG2_test(i,:), ...
        ACCX_test(i,:),ACCY_test(i,:),ACCZ_test(i,:), ...
        b,a,fs,L,nfft,frequencyTolerance);

    cleanPPG2_test(i,:) = single(cleaned);
    diffPPG2_test(i,:) = single(difference);

    removedGroups_test(i,2) = removed;

    initialHR_Hz_test(i,2) = hrHz;
    initialHR_BPM_test(i,2) = hrHz*60;

    if mod(i,25)==0 || i==numTest
        fprintf('TEST Ch2: %d/%d\n',i,numTest);
    end
end

%% STEP 8: PROCESSING SUMMARY

fprintf('\n====================================\n');
fprintf('PHASE 3 PROCESSING SUMMARY\n');
fprintf('====================================\n');

fprintf('TRAIN records: %d\n',numTrain);
fprintf('TEST records: %d\n',numTest);

fprintf('Total processed signals: %d\n', ...
    2*(numTrain+numTest));

fprintf('\nAverage removed groups:\n');

fprintf('TRAIN Ch1: %.2f\n',mean(removedGroups_train(:,1)));
fprintf('TRAIN Ch2: %.2f\n',mean(removedGroups_train(:,2)));

fprintf('TEST Ch1: %.2f\n',mean(removedGroups_test(:,1)));
fprintf('TEST Ch2: %.2f\n',mean(removedGroups_test(:,2)));

fprintf('\nMean provisional HR estimates:\n');

fprintf('TRAIN Ch1: %.2f BPM\n',mean(initialHR_BPM_train(:,1)));
fprintf('TRAIN Ch2: %.2f BPM\n',mean(initialHR_BPM_train(:,2)));

fprintf('TEST Ch1: %.2f BPM\n',mean(initialHR_BPM_test(:,1)));
fprintf('TEST Ch2: %.2f BPM\n',mean(initialHR_BPM_test(:,2)));

%% STEP 9: SAVE RESULTS

outputFile = fullfile(baseFolder, ...
    'Phase3_SSA_Preprocessing_Results.mat');

save(outputFile, ...
    'cleanPPG1_train','cleanPPG2_train', ...
    'cleanPPG1_test','cleanPPG2_test', ...
    'diffPPG1_train','diffPPG2_train', ...
    'diffPPG1_test','diffPPG2_test', ...
    'removedGroups_train','removedGroups_test', ...
    'initialHR_Hz_train','initialHR_Hz_test', ...
    'initialHR_BPM_train','initialHR_BPM_test', ...
    'HR_train','HR_test', ...
    'fs','L','nfft','delta','frequencyTolerance', ...
    '-v7.3');

fprintf('\nResults saved successfully:\n%s\n',outputFile);

%% STEP 10: VALIDATION PLOTS

time = (0:N-1)/fs;
differenceTime = (0:N-3)/fs;

figure('Name','Phase 3 SSA Validation','Color','w');

subplot(4,1,1);

plot(time,double(PPG1_train(1,:)));
title('Original TRAIN PPG - Record 1');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(4,1,2);

plot(time,double(cleanPPG1_train(1,:)));
title('SSA Cleaned PPG - Record 1');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(4,1,3);

plot(differenceTime,double(diffPPG1_train(1,:)));
title('Second-Order Difference - Record 1');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(4,1,4);

plot(time,double(PPG1_train(1,:)), ...
    'DisplayName','Original');

hold on;

plot(time,double(cleanPPG1_train(1,:)), ...
    'DisplayName','Cleaned');

title('Original vs Cleaned PPG');
xlabel('Time (seconds)');
ylabel('Amplitude');
legend;
grid on;

fprintf('\nPHASE 3 COMPLETED.\n');

%% LOCAL FUNCTION: PROCESS ONE RECORD

function [cleanedSignal,secondDifference, ...
    numberRemoved,initialHRFrequency] = ...
    processRecord(x,accX,accY,accZ,b,a,fs,L,nfft,tolerance)

    x = double(x(:));

    accX = double(accX(:));
    accY = double(accY(:));
    accZ = double(accZ(:));

    N = length(x);

    if any([length(accX),length(accY),length(accZ)] ~= N)
        error('PPG and acceleration signals must have equal lengths.');
    end

    if any(~isfinite(x)) || any(~isfinite(accX)) || ...
            any(~isfinite(accY)) || any(~isfinite(accZ))
        error('Input record contains NaN or Inf values.');
    end

    %% A. FILTER PPG AND ACCELERATION

    xFiltered = filtfilt(b,a,x);

    accSignals = {accX,accY,accZ};

    for axisNumber = 1:3
        accSignals{axisNumber} = ...
            filtfilt(b,a,accSignals{axisNumber});
    end

    %% B. ACCELERATION DOMINANT FREQUENCIES

    accFrequency = [];

    for axisNumber = 1:3

        aSignal = detrend(accSignals{axisNumber});

        [P,f] = periodogram(aSignal,hann(N),nfft,fs);

        valid = f >= 0.4 & f <= 5;

        Pvalid = P(valid);
        fvalid = f(valid);

        if isempty(Pvalid) || max(Pvalid)<=0
            continue;
        end

        [peakValues,peakLocations] = findpeaks(Pvalid);

        threshold = 0.5*max(Pvalid);

        selected = peakValues >= threshold;

        selectedFrequencies = ...
            fvalid(peakLocations(selected));

        accFrequency = [accFrequency; ...
            selectedFrequencies(:)];

    end

    accFrequency = unique(round(accFrequency,4));

    %% C. SSA EMBEDDING

    xDetrended = detrend(xFiltered);

    trajectoryMatrix = hankel( ...
        xDetrended(1:L),xDetrended(L:end));

    %% D. SINGULAR VALUE DECOMPOSITION

    [U,S,V] = svd(trajectoryMatrix,'econ');

    singularValues = diag(S);

    numComponents = length(singularValues);

    %% E. RECONSTRUCT ELEMENTARY COMPONENTS

    elementaryComponents = zeros(numComponents,N);

    componentFrequency = zeros(numComponents,1);

    for k = 1:numComponents

        elementaryMatrix = singularValues(k)* ...
            U(:,k)*V(:,k)';

        elementaryComponents(k,:) = ...
            diagonalAverage(elementaryMatrix)';

        z = elementaryComponents(k,:)';

        [Pz,fz] = periodogram(z,hann(N),nfft,fs);

        valid = fz >= 0.4 & fz <= 5;

        Psearch = Pz(valid);
        fsearch = fz(valid);

        [~,index] = max(Psearch);

        componentFrequency(k) = fsearch(index);

    end

    %% F. PROVISIONAL FREQUENCY-BASED GROUPING
    % This is not the exact automatic singular-value clustering
    % procedure referenced by the original TROIKA paper.

    groups = {};
    groupFrequencies = [];

    k = 1;
    groupNumber = 0;

    while k <= numComponents

        currentGroup = k;

        if k < numComponents

            frequencyDifference = abs( ...
                componentFrequency(k)-componentFrequency(k+1));

            if frequencyDifference <= tolerance

                currentGroup = [k k+1];

                k = k+1;

            end
        end

        groupNumber = groupNumber+1;

        groups{groupNumber} = currentGroup;

        groupedSignal = sum( ...
            elementaryComponents(currentGroup,:),1);

        [Pg,fg] = periodogram( ...
            groupedSignal(:),hann(N),nfft,fs);

        valid = fg >= 0.4 & fg <= 5;

        Psearch = Pg(valid);
        fsearch = fg(valid);

        [~,index] = max(Psearch);

        groupFrequencies(groupNumber,1) = fsearch(index);

        k = k+1;

    end

    %% G. PROVISIONAL HR INITIALIZATION
    % Uses the current record because sequence continuity and
    % previous-window HR information have not yet been established.

    [Pppg,fppg] = periodogram( ...
        detrend(xFiltered),hann(N),nfft,fs);

    validHR = fppg >= 0.7 & fppg <= 3.5;

    Phr = Pppg(validHR);
    fhr = fppg(validHR);

    [~,hrIndex] = max(Phr);

    initialHRFrequency = fhr(hrIndex);

    %% H. PROTECT HR FUNDAMENTAL AND HARMONICS

    refinedAccFrequency = accFrequency;

    for harmonic = 1:3

        protectedFrequency = ...
            harmonic*initialHRFrequency;

        keep = abs(refinedAccFrequency- ...
            protectedFrequency) > tolerance;

        refinedAccFrequency = ...
            refinedAccFrequency(keep);

    end

    %% I. REMOVE ACCELERATION-MATCHING GROUPS

    removedGroups = false(length(groups),1);

    for g = 1:length(groups)

        for j = 1:length(refinedAccFrequency)

            if abs(groupFrequencies(g)- ...
                    refinedAccFrequency(j)) <= tolerance

                removedGroups(g) = true;

                break;

            end
        end
    end

    %% J. RECONSTRUCT CLEANED PPG

    cleanedSignal = zeros(1,N);

    for g = 1:length(groups)

        if ~removedGroups(g)

            cleanedSignal = cleanedSignal + ...
                sum(elementaryComponents(groups{g},:),1);

        end
    end

    %% K. SECOND-ORDER TEMPORAL DIFFERENCE
    % Retained because TROIKA uses second-order difference
    % in its experiments.

    secondDifference = diff(cleanedSignal,2);

    numberRemoved = sum(removedGroups);

end

%% LOCAL FUNCTION: DIAGONAL AVERAGING

function y = diagonalAverage(X)

    [L,K] = size(X);

    N = L+K-1;

    y = zeros(N,1);

    counts = zeros(N,1);

    for i = 1:L

        for j = 1:K

            index = i+j-1;

            y(index) = y(index)+X(i,j);

            counts(index) = counts(index)+1;

        end
    end

    y = y./counts;

end
