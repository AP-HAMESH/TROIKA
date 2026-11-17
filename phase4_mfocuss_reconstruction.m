
clc;
clear;
close all;

%% PHASE 4: REGULARIZED M-FOCUSS
baseFolder = 'E:\AP Learn\Sem 5\dsp lab\PROJECT\PPG_PROJECT';

inputFile = fullfile(baseFolder, ...
    'Phase3_SSA_Preprocessing_Results.mat');

load(inputFile);

%% Parameters from TROIKA
fs = 125;
N = 4096;
p = 0.8;
lambda = 0.1;
iterations = 5;

%% Load four signal groups
signals = {
    double(diffPPG1_train)
    double(diffPPG2_train)
    double(diffPPG1_test)
    double(diffPPG2_test)
};

names = {
    'TRAIN Channel 1'
    'TRAIN Channel 2'
    'TEST Channel 1'
    'TEST Channel 2'
};

%% Create pruned Fourier dictionary
M = size(signals{1},2);

% Full Fourier frequency grid
frequency = (0:N-1)*fs/N;

% Positive and negative frequency bands
positiveIdx = find(frequency >= 0.4 & frequency <= 5);
negativeIdx = find(frequency >= fs-5 & frequency <= fs-0.4);

dictionaryIdx = [positiveIdx negativeIdx];

% Fourier dictionary
n = (0:M-1)';

Phi = exp(1i*2*pi*(n*dictionaryIdx)/N);

% Do not normalize columns: retain the Fourier dictionary scaling.
fprintf('Dictionary dimensions: %d x %d\n', ...
    size(Phi,1),size(Phi,2));

frequencySelected = frequency(dictionaryIdx);
numBins = length(dictionaryIdx);

%% Process all four groups
sparseResults = cell(4,1);

for group = 1:4

    currentSignals = signals{group};
    numRecords = size(currentSignals,1);

    spectra = zeros(numRecords,numBins,'single');

    fprintf('\nProcessing %s...\n',names{group});

    for r = 1:numRecords

        y = currentSignals(r,:)';
        y = y - mean(y);

        % Regularized M-FOCUSS
        x = mFocuss(y,Phi,p,lambda,iterations);

        % Sparse power spectrum
        spectra(r,:) = single(abs(x).^2);

        if mod(r,100)==0 || r==numRecords
            fprintf('%s: %d/%d\n', ...
                names{group},r,numRecords);
        end
    end

    sparseResults{group} = spectra;
end

%% Store outputs
spectrum_train_ch1 = sparseResults{1};
spectrum_train_ch2 = sparseResults{2};
spectrum_test_ch1 = sparseResults{3};
spectrum_test_ch2 = sparseResults{4};

save(fullfile(baseFolder, ...
    'Phase4_MFOCUSS_Results.mat'), ...
    'spectrum_train_ch1','spectrum_train_ch2', ...
    'spectrum_test_ch1','spectrum_test_ch2', ...
    'frequencySelected','dictionaryIdx', ...
    'fs','N','p','lambda','iterations', ...
    '-v7.3');

fprintf('\n====================================\n');
fprintf('PHASE 4 COMPLETED\n');
fprintf('====================================\n');

fprintf('Saved: Phase4_MFOCUSS_Results.mat\n');

%% Display example spectrum
figure;

plot(frequencySelected, ...
    double(spectrum_train_ch1(1,:)));

xlim([0 5]);
xlabel('Frequency (Hz)');
ylabel('Sparse spectral power');
title('M-FOCUSS Spectrum - TRAIN Record 1, Channel 1');
grid on;

%% =========================================================
% LOCAL FUNCTION: REGULARIZED FOCUSS
%% =========================================================
function x = mFocuss(y,Phi,p,lambda,iterations)

    epsilon = 1e-8;

    % Initial correlation estimate
    x = Phi' * y;

    % Precompute constant matrices
    gramMatrix = Phi' * Phi;
    correlation = Phi' * y;

    for k = 1:iterations

        % FOCUSS weights
        weights = (abs(x)+epsilon).^(1-p/2);

        % Regularized weighted least-squares update
        regularization = lambda * ...
            diag(1./(weights.^2));

        x = (gramMatrix + regularization) \ correlation;

    end
end
