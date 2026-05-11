%% Teste de Combinações de Features (3 a 7 features)
% Testa todas as combinações de 3, 4, 5, 6, e 7 features com STFT otimizado
% Usa 5-fold cross-validation com classificador Minimum Distance

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

%% Extrair features STFT com parâmetros otimizados (w=256, overlap=50%, nfft=256)
fs = data.taxaAmostragem(1);
w = 256;
ov = 0.5;
nfft = 256;
noverlap = floor(w * ov);

numSamples = height(data);

% Features espectrais
energySpec = zeros(numSamples, 1);
peakFreq = zeros(numSamples, 1);
specCentroid = zeros(numSamples, 1);
specBW = zeros(numSamples, 1);
specEntropy = zeros(numSamples, 1);

fprintf('Extraindo features com STFT otimizado (w=%d, overlap=%.0f%%, nfft=%d)...\n', w, ov*100, nfft);

for i = 1:numSamples
    if mod(i, 100) == 0, fprintf('  %d/%d\n', i, numSamples); end
    x = data.signal{i};
    x = x / max(abs(x));

    [S_stft, F, T, P] = spectrogram(x, w, noverlap, nfft, fs);

    meanSpectrum = mean(P, 2);
    totalPower = sum(meanSpectrum);

    energySpec(i) = sum(P, 'all');
    [~, idxPeak] = max(meanSpectrum);
    peakFreq(i) = F(idxPeak);
    specCentroid(i) = sum(F .* meanSpectrum) / totalPower;
    specBW(i) = sqrt(sum(((F - specCentroid(i)).^2) .* meanSpectrum) / totalPower);

    P_norm = meanSpectrum / sum(meanSpectrum);
    specEntropy(i) = -sum(P_norm .* log2(P_norm + eps));
end

% Features temporais (Meta 1)
energy_intervalos = reshape(cell2mat(data.energy), 3, [])';
amplitudeMax = cellfun(@mean, data.amplitudeMax);
energiaTotal = data.energiaTotal;

%% Preparar todas as features candidatas
allFeatures = {
    {'specCentroid', specCentroid}, ...
    {'specEntropy', specEntropy}, ...
    {'energySpec', energySpec}, ...
    {'peakFreq', peakFreq}, ...
    {'specBW', specBW}, ...
    {'energy_int1', energy_intervalos(:, 1)}, ...
    {'energy_int2', energy_intervalos(:, 2)}, ...
    {'energy_int3', energy_intervalos(:, 3)}, ...
    {'amplitudeMax', amplitudeMax}, ...
    {'energiaTotal', energiaTotal}
};

Y = data.digit;
numFeats = length(allFeatures);

fprintf('\nTestando combinações de 3 a 7 features...\n');
fprintf('Isto pode levar vários minutos...\n\n');

results = []; % [accuracy, num_features, feature_indices (up to 7)...]

%% Testar 3 features
fprintf('Testando 3 features...\n');
for i = 1:numFeats
    for j = i+1:numFeats
        for k = j+1:numFeats
            X = [allFeatures{i}{2}, allFeatures{j}{2}, allFeatures{k}{2}];
            X = zscore(X);
            accuracy = evaluateWithCrossVal(X, Y);
            results = [results; accuracy, 3, i, j, k, 0, 0, 0, 0];
        end
    end
end

%% Testar 4 features
fprintf('Testando 4 features...\n');
for i = 1:numFeats
    for j = i+1:numFeats
        for k = j+1:numFeats
            for m = k+1:numFeats
                X = [allFeatures{i}{2}, allFeatures{j}{2}, allFeatures{k}{2}, allFeatures{m}{2}];
                X = zscore(X);
                accuracy = evaluateWithCrossVal(X, Y);
                results = [results; accuracy, 4, i, j, k, m, 0, 0, 0];
            end
        end
    end
end

%% Testar 5 features
fprintf('Testando 5 features...\n');
for i = 1:numFeats
    for j = i+1:numFeats
        for k = j+1:numFeats
            for m = k+1:numFeats
                for n = m+1:numFeats
                    X = [allFeatures{i}{2}, allFeatures{j}{2}, allFeatures{k}{2}, allFeatures{m}{2}, allFeatures{n}{2}];
                    X = zscore(X);
                    accuracy = evaluateWithCrossVal(X, Y);
                    results = [results; accuracy, 5, i, j, k, m, n, 0, 0];
                end
            end
        end
    end
end

%% Testar 6 features
fprintf('Testando 6 features...\n');
for i = 1:numFeats
    for j = i+1:numFeats
        for k = j+1:numFeats
            for m = k+1:numFeats
                for n = m+1:numFeats
                    for p = n+1:numFeats
                        X = [allFeatures{i}{2}, allFeatures{j}{2}, allFeatures{k}{2}, ...
                             allFeatures{m}{2}, allFeatures{n}{2}, allFeatures{p}{2}];
                        X = zscore(X);
                        accuracy = evaluateWithCrossVal(X, Y);
                        results = [results; accuracy, 6, i, j, k, m, n, p, 0];
                    end
                end
            end
        end
    end
end

%% Testar 7 features (limitado a primeiras combinações para não demorar demais)
fprintf('Testando 7 features (amostra)...\n');
count = 0;
maxTests = 200; % Limitar testes de 7 features
for i = 1:numFeats
    for j = i+1:numFeats
        for k = j+1:numFeats
            for m = k+1:numFeats
                for n = m+1:numFeats
                    for p = n+1:numFeats
                        for q = p+1:numFeats
                            X = [allFeatures{i}{2}, allFeatures{j}{2}, allFeatures{k}{2}, ...
                                 allFeatures{m}{2}, allFeatures{n}{2}, allFeatures{p}{2}, ...
                                 allFeatures{q}{2}];
                            X = zscore(X);
                            accuracy = evaluateWithCrossVal(X, Y);
                            results = [results; accuracy, 7, i, j, k, m, n, p, q];
                            count = count + 1;
                            if count >= maxTests
                                break;
                            end
                        end
                        if count >= maxTests, break; end
                    end
                    if count >= maxTests, break; end
                end
                if count >= maxTests, break; end
            end
            if count >= maxTests, break; end
        end
        if count >= maxTests, break; end
    end
    if count >= maxTests, break; end
end

%% Ordenar e mostrar resultados
[~, sortIdx] = sort(results(:, 1), 'descend');

fprintf('\n');
fprintf(repmat('=', 1, 100));
fprintf('\nTOP 20 MELHORES COMBINAÇÕES (3-7 FEATURES)\n');
fprintf(repmat('=', 1, 100));
fprintf('\n\n');

topN = min(20, size(results, 1));
for idx = 1:topN
    acc = results(sortIdx(idx), 1);
    numFeatures = results(sortIdx(idx), 2);
    featureIndices = results(sortIdx(idx), 3:2+numFeatures);

    fprintf('%2d. [%d features] Accuracy: %.2f%%  |  ', idx, numFeatures, acc);
    for f = 1:numFeatures
        fIdx = featureIndices(f);
        if fIdx > 0
            fprintf('%s', allFeatures{fIdx}{1});
            if f < numFeatures
                fprintf(' + ');
            end
        end
    end
    fprintf('\n');
end

% Melhor resultado
bestIdx = sortIdx(1);
bestAcc = results(bestIdx, 1);
bestNumFeats = results(bestIdx, 2);
bestFeatureIndices = results(bestIdx, 3:2+bestNumFeats);

fprintf('\n');
fprintf(repmat('=', 1, 100));
fprintf('\n✓ MELHOR COMBINAÇÃO: %.2f%% de Accuracy (com 5-fold cross-validation)\n', bestAcc);
fprintf('Número de features: %d\n', bestNumFeats);
fprintf('Features: ');
for f = 1:bestNumFeats
    fIdx = bestFeatureIndices(f);
    if fIdx > 0
        fprintf('%s', allFeatures{fIdx}{1});
        if f < bestNumFeats
            fprintf(' + ');
        end
    end
end
fprintf('\n');
fprintf(repmat('=', 1, 100));
fprintf('\n');

%% Função auxiliar: Avaliação com cross-validation (5-fold)
function accuracy = evaluateWithCrossVal(X, Y)
    cv = cvpartition(Y, 'KFold', 5);
    accuracies = zeros(5, 1);

    for fold = 1:5
        Xtreino = X(training(cv, fold), :);
        Ytreino = Y(training(cv, fold));
        Xteste = X(test(cv, fold), :);
        Yteste = Y(test(cv, fold));

        % Classificador minimum distance
        [centroids, digitGroups] = grpstats(Xtreino, Ytreino, {'mean', 'gname'});
        digitGroups = str2double(digitGroups);

        predictedDigit = zeros(size(Yteste));
        for idx = 1:size(Xteste, 1)
            distances = sqrt(sum((Xteste(idx, :) - centroids).^2, 2));
            [~, minIdx] = min(distances);
            predictedDigit(idx) = digitGroups(minIdx);
        end

        accuracies(fold) = mean(predictedDigit == Yteste) * 100;
    end

    accuracy = mean(accuracies);
end
