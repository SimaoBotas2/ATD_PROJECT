%% Test temporal spectral features to distinguish problem digits
% Teste se features temporais (espectrais divididas em 3 regiões) ajudam

clc; clear;

thisDir = fileparts(mfilename('fullpath'));
rootDir = thisDir;
while ~exist(fullfile(rootDir, 'data_processed'), 'dir')
    parent = fileparts(rootDir);
    if strcmp(parent, rootDir)
        error('Não foi possível encontrar a pasta data_processed a partir de: %s', thisDir);
    end
    rootDir = parent;
end
outDir = fullfile(rootDir, 'data_processed');

%% Carregar dados
S = load(fullfile(outDir, 'meta1_fourier_and_spectral_features.mat'));
data = S.meta1_fourier_features;

%% Extrair features com STFT otimizado - incluindo divisão temporal
fs = data.taxaAmostragem(1);
w = 256;
ov = 0.5;
nfft = 256;
noverlap = floor(w * ov);

numSamples = height(data);

% Features globais
specCentroid = zeros(numSamples, 1);
specEntropy = zeros(numSamples, 1);
specBW = zeros(numSamples, 1);
peakFreq = zeros(numSamples, 1);

% Features temporais (3 regiões)
specCentroid_start = zeros(numSamples, 1);
specCentroid_mid = zeros(numSamples, 1);
specCentroid_end = zeros(numSamples, 1);

specEntropy_start = zeros(numSamples, 1);
specEntropy_mid = zeros(numSamples, 1);
specEntropy_end = zeros(numSamples, 1);

fprintf('Extraindo features com divisão temporal...\n');

for i = 1:numSamples
    if mod(i, 100) == 0, fprintf('  %d/%d\n', i, numSamples); end
    x = data.signal{i};
    x = x / max(abs(x));

    [S_stft, F, T, P] = spectrogram(x, w, noverlap, nfft, fs);

    % Globais
    meanSpectrum = mean(P, 2);
    totalPower = sum(meanSpectrum);

    specCentroid(i) = sum(F .* meanSpectrum) / totalPower;
    specBW(i) = sqrt(sum(((F - specCentroid(i)).^2) .* meanSpectrum) / totalPower);
    [~, idxPeak] = max(meanSpectrum);
    peakFreq(i) = F(idxPeak);

    P_norm = meanSpectrum / sum(meanSpectrum);
    specEntropy(i) = -sum(P_norm .* log2(P_norm + eps));

    % Temporais - dividir em 3 regiões
    numTimeFrames = length(T);
    frameSize = floor(numTimeFrames / 3);

    regions = {
        1 : frameSize,                 % Início
        frameSize+1 : 2*frameSize,     % Meio
        2*frameSize+1 : numTimeFrames  % Fim
    };

    for r = 1:3
        idxRegion = regions{r};
        P_region = P(:, idxRegion);
        meanSpecRegion = mean(P_region, 2);
        totalPowerRegion = sum(meanSpecRegion);

        centroidRegion = sum(F .* meanSpecRegion) / (totalPowerRegion + eps);
        P_norm_region = meanSpecRegion / (sum(meanSpecRegion) + eps);
        entropyRegion = -sum(P_norm_region .* log2(P_norm_region + eps));

        if r == 1
            specCentroid_start(i) = centroidRegion;
            specEntropy_start(i) = entropyRegion;
        elseif r == 2
            specCentroid_mid(i) = centroidRegion;
            specEntropy_mid(i) = entropyRegion;
        else
            specCentroid_end(i) = centroidRegion;
            specEntropy_end(i) = entropyRegion;
        end
    end
end

energy_intervalos = reshape(cell2mat(data.energy), 3, [])';

%% Comparar diferentes combinações de features
fprintf('\n');
fprintf(repmat('=', 1, 100));
fprintf('\nTESTAR DIFERENTES COMBINAÇÕES DE FEATURES PARA DÍGITOS 0 E 7\n');
fprintf(repmat('=', 1, 100));
fprintf('\n');

Y = data.digit;

% Focamos em 0 e 7 para diagnóstico
idx_0_7 = (Y == 0) | (Y == 7);
Y_subset = Y(idx_0_7);

testConfigs = {
    {'Base (5)', [specEntropy(idx_0_7), peakFreq(idx_0_7), specBW(idx_0_7), ...
                  energy_intervalos(idx_0_7, 1), energy_intervalos(idx_0_7, 2)]}, ...

    {'Base + 2 temporal entropy', [specEntropy(idx_0_7), peakFreq(idx_0_7), specBW(idx_0_7), ...
                                   energy_intervalos(idx_0_7, 1), energy_intervalos(idx_0_7, 2), ...
                                   specEntropy_start(idx_0_7), specEntropy_end(idx_0_7)]}, ...

    {'Base + 3 temporal entropy', [specEntropy(idx_0_7), peakFreq(idx_0_7), specBW(idx_0_7), ...
                                   energy_intervalos(idx_0_7, 1), energy_intervalos(idx_0_7, 2), ...
                                   specEntropy_start(idx_0_7), specEntropy_mid(idx_0_7), specEntropy_end(idx_0_7)]}, ...

    {'Base + 3 temporal centroid', [specEntropy(idx_0_7), peakFreq(idx_0_7), specBW(idx_0_7), ...
                                    energy_intervalos(idx_0_7, 1), energy_intervalos(idx_0_7, 2), ...
                                    specCentroid_start(idx_0_7), specCentroid_mid(idx_0_7), specCentroid_end(idx_0_7)]}, ...

    {'Base + all temporal', [specEntropy(idx_0_7), peakFreq(idx_0_7), specBW(idx_0_7), ...
                             energy_intervalos(idx_0_7, 1), energy_intervalos(idx_0_7, 2), ...
                             specEntropy_start(idx_0_7), specEntropy_mid(idx_0_7), specEntropy_end(idx_0_7), ...
                             specCentroid_start(idx_0_7), specCentroid_mid(idx_0_7), specCentroid_end(idx_0_7)]}
};

for cfg = 1:length(testConfigs)
    configName = testConfigs{cfg}{1};
    X = testConfigs{cfg}{2};
    X = zscore(X);

    % 5-fold cross-validation
    cv = cvpartition(Y_subset, 'KFold', 5);
    accuracies = zeros(5, 1);

    for fold = 1:5
        Xtrain = X(training(cv, fold), :);
        Ytrain = Y_subset(training(cv, fold));
        Xtest = X(test(cv, fold), :);
        Ytest = Y_subset(test(cv, fold));

        [centroids, groups] = grpstats(Xtrain, Ytrain, {'mean', 'gname'});
        groups = str2double(groups);

        predicted = zeros(size(Ytest));
        for i = 1:size(Xtest, 1)
            distances = sqrt(sum((Xtest(i, :) - centroids).^2, 2));
            [~, minIdx] = min(distances);
            predicted(i) = groups(minIdx);
        end

        accuracies(fold) = mean(predicted == Ytest) * 100;
    end

    meanAcc = mean(accuracies);
    fprintf('%2d. [%d features] %.2f%% accuracy (0 vs 7 only): %s\n', ...
        cfg, size(X, 2), meanAcc, configName);
end

%% Também testar em todos os dígitos para não overfittar em 0-7
fprintf('\n');
fprintf(repmat('=', 1, 100));
fprintf('\nVERIFICAR EM TODOS OS 10 DÍGITOS\n');
fprintf(repmat('=', 1, 100));
fprintf('\n');

for cfg = 1:length(testConfigs)
    configName = testConfigs{cfg}{1};
    X = testConfigs{cfg}{2};

    % Voltar aos 10 dígitos
    X_all = [specEntropy, peakFreq, specBW, energy_intervalos(:, 1), energy_intervalos(:, 2)];

    if cfg > 1
        % Adicionar features temporais
        if cfg == 2  % 2 temporal entropy
            X_all = [X_all, specEntropy_start, specEntropy_end];
        elseif cfg == 3  % 3 temporal entropy
            X_all = [X_all, specEntropy_start, specEntropy_mid, specEntropy_end];
        elseif cfg == 4  % 3 temporal centroid
            X_all = [X_all, specCentroid_start, specCentroid_mid, specCentroid_end];
        elseif cfg == 5  % all temporal
            X_all = [X_all, specEntropy_start, specEntropy_mid, specEntropy_end, ...
                     specCentroid_start, specCentroid_mid, specCentroid_end];
        end
    end

    X_all = zscore(X_all);

    % 5-fold cross-validation
    cv = cvpartition(Y, 'KFold', 5);
    accuracies = zeros(5, 1);

    for fold = 1:5
        Xtrain = X_all(training(cv, fold), :);
        Ytrain = Y(training(cv, fold));
        Xtest = X_all(test(cv, fold), :);
        Ytest = Y(test(cv, fold));

        [centroids, groups] = grpstats(Xtrain, Ytrain, {'mean', 'gname'});
        groups = str2double(groups);

        predicted = zeros(size(Ytest));
        for i = 1:size(Xtest, 1)
            distances = sqrt(sum((Xtest(i, :) - centroids).^2, 2));
            [~, minIdx] = min(distances);
            predicted(i) = groups(minIdx);
        end

        accuracies(fold) = mean(predicted == Ytest) * 100;
    end

    meanAcc = mean(accuracies);
    fprintf('%2d. [%d features] %.2f%% accuracy (all 10 digits): %s\n', ...
        cfg, size(X_all, 2), meanAcc, configName);
end
