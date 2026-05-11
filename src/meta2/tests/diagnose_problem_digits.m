%% Diagnóstico de dígitos problemáticos (0, 4, 7)
% Analisa por que o classificador confunde estes dígitos

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

%% Extrair features com STFT otimizado
fs = data.taxaAmostragem(1);
w = 256;
ov = 0.5;
nfft = 256;
noverlap = floor(w * ov);

numSamples = height(data);

energySpec = zeros(numSamples, 1);
peakFreq = zeros(numSamples, 1);
specCentroid = zeros(numSamples, 1);
specBW = zeros(numSamples, 1);
specEntropy = zeros(numSamples, 1);

fprintf('Extraindo features...\n');

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

energy_intervalos = reshape(cell2mat(data.energy), 3, [])';

%% Analisar dígitos 0, 4, 7
fprintf('\n');
fprintf(repmat('=', 1, 100));
fprintf('\nANÁLISE DOS DÍGITOS PROBLEMÁTICOS: 0, 4, 7\n');
fprintf(repmat('=', 1, 100));
fprintf('\n');

problemDigits = [0, 4, 7];

for digit = problemDigits
    idx = data.digit == digit;

    fprintf('\nDÍGITO %d (%d amostras):\n', digit, sum(idx));
    fprintf(repmat('-', 1, 100));
    fprintf('\n');

    % Features para este dígito
    feat_entropy = specEntropy(idx);
    feat_peakFreq = peakFreq(idx);
    feat_bw = specBW(idx);
    feat_ene1 = energy_intervalos(idx, 1);
    feat_ene2 = energy_intervalos(idx, 2);

    % Estatísticas
    fprintf('  specEntropy:   mean=%.4f, std=%.4f, min=%.4f, max=%.4f\n', ...
        mean(feat_entropy), std(feat_entropy), min(feat_entropy), max(feat_entropy));
    fprintf('  peakFreq:      mean=%.2f,  std=%.2f,  min=%.2f,  max=%.2f\n', ...
        mean(feat_peakFreq), std(feat_peakFreq), min(feat_peakFreq), max(feat_peakFreq));
    fprintf('  specBW:        mean=%.2f,  std=%.2f,  min=%.2f,  max=%.2f\n', ...
        mean(feat_bw), std(feat_bw), min(feat_bw), max(feat_bw));
    fprintf('  energy_int1:   mean=%.6f, std=%.6f, min=%.6f, max=%.6f\n', ...
        mean(feat_ene1), std(feat_ene1), min(feat_ene1), max(feat_ene1));
    fprintf('  energy_int2:   mean=%.6f, std=%.6f, min=%.6f, max=%.6f\n', ...
        mean(feat_ene2), std(feat_ene2), min(feat_ene2), max(feat_ene2));

end

%% Calcular centroides (como o classificador faz)
fprintf('\n');
fprintf(repmat('=', 1, 100));
fprintf('\nCENTROIDES CALCULADOS PELO CLASSIFICADOR\n');
fprintf(repmat('=', 1, 100));
fprintf('\n');

X = [specEntropy, peakFreq, specBW, energy_intervalos(:, 1), energy_intervalos(:, 2)];
X = zscore(X);

Y = data.digit;

% Calcular centroide para cada dígito
for digit = 0:9
    idx = Y == digit;
    if sum(idx) > 0
        centroid = mean(X(idx, :), 1);
        fprintf('Dígito %d centroid (normalizado): [%.4f, %.4f, %.4f, %.4f, %.4f]\n', ...
            digit, centroid(1), centroid(2), centroid(3), centroid(4), centroid(5));
    end
end

%% Calcular distâncias entre centros problemáticos
fprintf('\n');
fprintf(repmat('=', 1, 100));
fprintf('\nDISTÂNCIAS ENTRE CENTROS DE 0, 4, 7\n');
fprintf(repmat('=', 1, 100));
fprintf('\n');

centroids_all = [];
for digit = 0:9
    idx = Y == digit;
    if sum(idx) > 0
        centroids_all = [centroids_all; mean(X(idx, :), 1)];
    end
end

% Pega centroides de 0, 4, 7 (posições 1, 5, 8 na lista 0-9)
c0 = mean(X(Y == 0, :), 1);
c4 = mean(X(Y == 4, :), 1);
c7 = mean(X(Y == 7, :), 1);

dist_0_4 = sqrt(sum((c0 - c4).^2));
dist_0_7 = sqrt(sum((c0 - c7).^2));
dist_4_7 = sqrt(sum((c4 - c7).^2));

fprintf('Distância entre centros 0 e 4: %.6f\n', dist_0_4);
fprintf('Distância entre centros 0 e 7: %.6f\n', dist_0_7);
fprintf('Distância entre centros 4 e 7: %.6f\n', dist_4_7);

fprintf('\n');
fprintf('Comparação com outras distâncias:\n');
fprintf(repmat('-', 1, 100));

allDists = [];
for d1 = 0:9
    for d2 = d1+1:9
        idx1 = Y == d1;
        idx2 = Y == d2;
        if sum(idx1) > 0 && sum(idx2) > 0
            c1 = mean(X(idx1, :), 1);
            c2 = mean(X(idx2, :), 1);
            dist = sqrt(sum((c1 - c2).^2));
            allDists = [allDists; dist, d1, d2];
        end
    end
end

[~, sortIdx] = sort(allDists(:, 1));
fprintf('\nTop 10 pares MAIS PRÓXIMOS:\n');
for i = 1:min(10, size(allDists, 1))
    idx = sortIdx(i);
    dist = allDists(idx, 1);
    d1 = allDists(idx, 2);
    d2 = allDists(idx, 3);
    fprintf('  Dígitos %d-%d: distância = %.6f\n', d1, d2, dist);
end

fprintf('\nTop 10 pares MAIS DISTANTES:\n');
for i = 1:min(10, size(allDists, 1))
    idx = sortIdx(end - i + 1);
    dist = allDists(idx, 1);
    d1 = allDists(idx, 2);
    d2 = allDists(idx, 3);
    fprintf('  Dígitos %d-%d: distância = %.6f\n', d1, d2, dist);
end
