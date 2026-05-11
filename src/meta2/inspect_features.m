%% Inspecionar cálculo de features detalhadamente

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

%% Selecionar uma amostra de cada dígito
fprintf('INSPEÇÃO DE FEATURES - Uma amostra por dígito\n');
fprintf(repmat('=', 1, 80) + "\n\n");

fs = data.taxaAmostragem(1);
w = 512;
ov = 0.5;
nfft = 512;
noverlap = floor(w * ov);

for digit = 0:9
    idx = find(data.digit == digit, 1);
    if isempty(idx)
        continue;
    end

    fprintf('DÍGITO %d (amostra %d):\n', digit, idx);

    x = data.signal{idx};
    originalLength = length(x);
    maxVal = max(abs(x));

    fprintf('  Sinal: %d amostras, max amplitude = %.6f\n', originalLength, maxVal);

    x = x / maxVal;

    % STFT
    [S_stft, F, T, P] = spectrogram(x, w, noverlap, nfft, fs);

    fprintf('  STFT shape: %d frequências × %d tempo-frames\n', size(P, 1), size(P, 2));
    fprintf('  Freq range: %.2f - %.2f Hz\n', F(1), F(end));
    fprintf('  Time range: %.4f - %.4f s\n', T(1), T(end));

    % Média espectral
    meanSpectrum = mean(P, 2);
    fprintf('  Mean spectrum: min=%.6f, max=%.6f, mean=%.6f\n', ...
        min(meanSpectrum), max(meanSpectrum), mean(meanSpectrum));

    % Features calculadas
    totalPower = sum(meanSpectrum);
    centroid = sum(F .* meanSpectrum) / totalPower;
    bw = sqrt(sum(((F - centroid).^2) .* meanSpectrum) / totalPower);
    energy = sum(P, 'all');  % FIXED: sum all power values, not just averaged
    [~, idxPeak] = max(meanSpectrum);
    peakFreq = F(idxPeak);

    P_norm = meanSpectrum / sum(meanSpectrum);
    entropy = -sum(P_norm .* log2(P_norm + eps));

    fprintf('  Features:\n');
    fprintf('    Centroid: %.4f Hz\n', centroid);
    fprintf('    Bandwidth: %.4f Hz\n', bw);
    fprintf('    Energy: %.8f\n', energy);
    fprintf('    Peak Freq: %.4f Hz\n', peakFreq);
    fprintf('    Entropy: %.6f\n', entropy);

    % Temporal divisions
    numTimeFrames = length(T);
    frameSize = floor(numTimeFrames / 3);
    fprintf('  Divisão temporal: %d frames total, %d frames/região\n', numTimeFrames, frameSize);

    for region = 1:3
        if region == 1
            idxRegion = 1:frameSize;
        elseif region == 2
            idxRegion = frameSize+1:2*frameSize;
        else
            idxRegion = 2*frameSize+1:numTimeFrames;
        end

        P_region = P(:, idxRegion);
        meanSpecRegion = mean(P_region, 2);
        energyRegion = sum(meanSpecRegion);

        fprintf('    Região %d (%d frames): energy = %.8f\n', region, length(idxRegion), energyRegion);
    end

    fprintf('\n');
end

fprintf(repmat('=', 1, 80) + "\n");
fprintf('VERIFICAÇÃO:\n');
fprintf('- As features fazem sentido? (centroid em Hz, entropy entre 0-max, etc.)\n');
fprintf('- Há valores NaN ou Inf?\n');
fprintf('- Os valores de energia são extremamente pequenos?\n');
fprintf('- A divisão temporal cobre todo o sinal?\n');
fprintf(repmat('=', 1, 80) + "\n");
