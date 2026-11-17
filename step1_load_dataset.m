
clc;
clear;
close all;

%% STEP 1: Dataset paths
baseFolder = 'E:\AP Learn\Sem 5\dsp lab\PROJECT\PPG_PROJECT';


trainFile = fullfile(baseFolder, 'TRAIN', 'IEEEPPG_TRAIN.ts');
testFile  = fullfile(baseFolder, 'TEST', 'IEEEPPG_TEST.ts');

fs = 125;

%% STEP 2: Read TRAIN dataset

fprintf('Loading TRAIN dataset...\n');

[PPG1_train, PPG2_train, ...
 ACCX_train, ACCY_train, ACCZ_train, HR_train] = readPPG(trainFile);

%% STEP 3: Read TEST dataset

fprintf('Loading TEST dataset...\n');

[PPG1_test, PPG2_test, ...
 ACCX_test, ACCY_test, ACCZ_test, HR_test] = readPPG(testFile);

%% STEP 4: Display dataset dimensions

fprintf('\nTRAIN DATASET\n');

fprintf('PPG1: %d x %d\n', size(PPG1_train));
fprintf('PPG2: %d x %d\n', size(PPG2_train));
fprintf('ACCX: %d x %d\n', size(ACCX_train));
fprintf('ACCY: %d x %d\n', size(ACCY_train));
fprintf('ACCZ: %d x %d\n', size(ACCZ_train));
fprintf('HR labels: %d\n', length(HR_train));

fprintf('\nTEST DATASET\n');
fprintf('PPG1: %d x %d\n', size(PPG1_test));
fprintf('PPG2: %d x %d\n', size(PPG2_test));
fprintf('HR labels: %d\n', length(HR_test));

%% STEP 5: Plot one PPG record

t = (0:999)/fs;

figure;

subplot(2,1,1);
plot(t, PPG1_train(1,:));
title('PPG Channel 1');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(2,1,2);
plot(t, PPG2_train(1,:));
title('PPG Channel 2');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

%% STEP 6: Plot accelerometer signals

figure;

plot(t, ACCX_train(1,:), 'DisplayName', 'X');
hold on;
plot(t, ACCY_train(1,:), 'DisplayName', 'Y');
plot(t, ACCZ_train(1,:), 'DisplayName', 'Z');

title('Three-axis Accelerometer Signals');
xlabel('Time (seconds)');
ylabel('Acceleration');
legend;
grid on;

%% STEP 7: Display reference HR

fprintf('\nFirst 10 TRAIN reference HR values:\n');
disp(HR_train(1:10));

fprintf('First 10 TEST reference HR values:\n');
disp(HR_test(1:10));


%% LOCAL FUNCTION: Read IEEE PPG .ts dataset

function [PPG1, PPG2, ACCX, ACCY, ACCZ, HR] = readPPG(filename)

    fid = fopen(filename, 'r');

    if fid == -1
        error('Cannot open file: %s', filename);
    end

    dataStarted = false;

    PPG1 = [];
    PPG2 = [];
    ACCX = [];
    ACCY = [];
    ACCZ = [];
    HR = [];

    while ~feof(fid)

        line = strtrim(fgetl(fid));

        if ~ischar(line)
            break;
        end

        if isempty(line)
            continue;
        end

        if strcmpi(line, '@data')
            dataStarted = true;
            continue;
        end

        if ~dataStarted
            continue;
        end

        parts = strsplit(line, ':');

        if numel(parts) ~= 6
            fclose(fid);
            error('Unexpected number of fields in dataset record.');
        end

        % Convert each signal field into numeric values

        signals = cell(1,5);

        for j = 1:5
            signals{j} = str2double(strsplit(parts{j}, ','));
        end

        % Check signal length

        if any(cellfun(@numel, signals) ~= 1000)
            fclose(fid);
            error('Unexpected signal length in dataset.');
        end

        % Store signals row by row

        PPG1(end+1,:) = signals{1};
        PPG2(end+1,:) = signals{2};

        ACCX(end+1,:) = signals{3};
        ACCY(end+1,:) = signals{4};
        ACCZ(end+1,:) = signals{5};

        % Sixth field contains reference HR

        HR(end+1,1) = str2double(parts{6});

    end

    fclose(fid);

end
