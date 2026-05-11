%% Otimizar parâmetros STFT para melhorar acurácia

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

%% Carregar
S = load(fullfile(outDir, 'meta1_fourier_and_spectral_features.mat'));
data = S.meta1_fourier_features;

fs = data.taxaAmostragem(1);
Y = data.digit;
energy_intervalos = reshape(cell2mat(data.energy), 3, [])';

%% Testar diferentes parâmetros STFT
fprintf('Otimizando parâmetros STFT...\n\n');

% Parâmetros para testar
windowSizes = [256, 512, 1024, 2048];
overlaps = [0.25, 0.5, 0.75];
nffts = [256, 512, 1024, 2048];

results = [];

for w = windowSizes
    for ov = overlaps
        for nfft = nffts
            if w > nfft
                continue;  % Window size não pode ser maior que NFFT
            end

            fprintf('Testando: w=%d, overlap=%.0f%%, nfft=%d... ', w, ov*100, nfft);

            noverlap = floor(w * ov);
            numSamples = height(data);

            % Extrair features com esses parâmetros
            specCentroid = zeros(numSamples, 1);
            specEntropy = zeros(numSamples, 1);
            peakFreq = zeros(numSamples, 1);
            specBW = zeros(numSamples, 1);

            for i = 1:numSamples
                x = data.signal{i};
                x = x / max(abs(x));

                [S_stft, F, T, P] = spectrogram(x, w, noverlap, nfft, fs);

                meanSpectrum = mean(P, 2);
                totalPower = sum(meanSpectrum);

                specCentroid(i) = sum(F .* meanSpectrum) / totalPower;
                specBW(i) = sqrt(sum(((F - specCentroid(i)).^2) .* meanSpectrum) / totalPower);
                [~, idxPeak] = max(meanSpectrum);
                peakFreq(i) = F(idxPeak);

                P_norm = meanSpectrum / sum(meanSpectrum);
                specEntropy(i) = -sum(P_norm .* log2(P_norm + eps));
            end

            % Classificar com melhores 5 features
            X = [specEntropy, peakFreq, specBW, energy_intervalos(:, 1), energy_intervalos(:, 2)];
            X = zscore(X);

            % 5-fold cross-validation
            cv = cvpartition(Y, 'KFold', 5);
            accuracies = zeros(5, 1);

            for fold = 1:5
                Xtreino = X(training(cv, fold), :);
                Ytreino = Y(training(cv, fold));
                Xteste = X(test(cv, fold), :);
                Yteste = Y(test(cv, fold));

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

            meanAccuracy = mean(accuracies);
            fprintf('%.2f%%\n', meanAccuracy);

            results = [results; meanAccuracy, w, ov, nfft];
        end
    end
end

%% Mostrar melhores resultados
fprintf('\n');
fprintf(repmat('=', 1, 80));
fprintf('\nTOP 10 MELHORES CONFIGURAÇÕES STFT\n');
fprintf(repmat('=', 1, 80));
fprintf('\n\n');

[~, sortIdx] = sort(results(:, 1), 'descend');
topResults = results(sortIdx(1:min(10, size(results, 1))), :);

for idx = 1:size(topResults, 1)
    acc = topResults(idx, 1);
    w = topResults(idx, 2);
    ov = topResults(idx, 3);
    nfft = topResults(idx, 4);

    fprintf('%2d. Accuracy: %.2f%%  |  w=%d, overlap=%.0f%%, nfft=%d\n', ...
        idx, acc, w, ov*100, nfft);
end

% Melhor
bestIdx = sortIdx(1);
bestAcc = results(bestIdx, 1);
bestW = results(bestIdx, 2);
bestOv = results(bestIdx, 3);
bestNfft = results(bestIdx, 4);

fprintf('\n');
fprintf(repmat('=', 1, 80));
fprintf('\n✓ MELHOR CONFIGURAÇÃO: %.2f%% de Accuracy\n', bestAcc);
fprintf('  Window size: %d\n', bestW);
fprintf('  Overlap: %.0f%%\n', bestOv*100);
fprintf('  NFFT: %d\n', bestNfft);
fprintf(repmat('=', 1, 80));
fprintf('\n');
