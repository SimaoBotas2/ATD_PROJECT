clc;
clear;

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
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

print_stft = true; % Set to true to visualize STFT features


%% 14
S = load(fullfile(outDir, 'meta1_fourier_and_spectral_features.mat'));
data = S.meta1_fourier_features;


%% 15
fs = data.taxaAmostragem(1);

% Configurações otimizadas para STFT (identificadas por teste de parâmetros)
w = 256;      % Window size otimizado
ov = 0.5;     % Overlap otimizado
nfft = 256;   % NFFT otimizado
noverlap = floor(w * ov);

figure('Name', 'Spectrogramas dos Dígitos 0 a 9');


numSamples = height(data);

% Features divididos em 3 regiões de tempo (início, meio, fim)
specCentroid_start = zeros(numSamples, 1);
specCentroid_mid = zeros(numSamples, 1);
specCentroid_end = zeros(numSamples, 1);

specEntropy_start = zeros(numSamples, 1);
specEntropy_mid = zeros(numSamples, 1);
specEntropy_end = zeros(numSamples, 1);

energySpec_start = zeros(numSamples, 1);
energySpec_mid = zeros(numSamples, 1);
energySpec_end = zeros(numSamples, 1);

% Features globais (para visualização)
energySpec = zeros(numSamples,1);
peakFreq = zeros(numSamples,1);
specCentroid = zeros(numSamples,1);
specBW = zeros(numSamples,1);
specEntropy = zeros(numSamples,1);

for d = 0:9
    digitIndices = find(data.digit == d);
    if isempty(digitIndices)
        continue;
    end

    % Usar a primeira amostra do digito
    x = data.signal{digitIndices(1)};
    x = x / max(abs(x)); % Normaliza

    % Calculo STFT
    [S, F, T, P] = spectrogram(x, w, noverlap, nfft, fs);

    subplot(5, 2, d + 1);
    surf(T, F, 10*log10(P), 'EdgeColor', 'none');
    axis tight;
    view(0, 90);
    colormap jet;
    title(sprintf('Dígito %d', d));
    xlabel('Tempo (s)');
    ylabel('Frequência (Hz)');


    % Média espectral ao longo do tempo
    meanSpectrum = mean(P, 2);
    totalPower = sum(meanSpectrum);
end

sgtitle(sprintf('Espectrogramas - Win=%d | Overlap=%.0f%% | NFFT=%d', w, ov*100, nfft));



%% 16 e 17: Extração de características tempo-frequência

for i = 1:numSamples
    x = data.signal{i};
    x = x / max(abs(x)); % Normalizar

    % STFT para extração de características
    [S, F, T, P] = spectrogram(x, w, noverlap, nfft, fs);

    % Dividir em 3 regiões de tempo
    numTimeFrames = length(T);
    frameSize = floor(numTimeFrames / 3);

    regions = {
        1 : frameSize,                          % Início
        frameSize+1 : 2*frameSize,              % Meio
        2*frameSize+1 : numTimeFrames           % Fim
    };

    regionLabels = {'start', 'mid', 'end'};

    for r = 1:3
        idxRegion = regions{r};
        P_region = P(:, idxRegion);

        % Média espectral da região
        meanSpectrumRegion = mean(P_region, 2);
        totalPowerRegion = sum(meanSpectrumRegion);

        % Centroide espectral
        centroidRegion = sum(F .* meanSpectrumRegion) / (totalPowerRegion + eps);

        % Entropia espectral
        P_norm = meanSpectrumRegion / (sum(meanSpectrumRegion) + eps);
        entropyRegion = -sum(P_norm .* log2(P_norm + eps));

        % Energia (sum of all power values in region, not averaged)
        energyRegion = sum(P_region, 'all');

        % Armazenar por região
        if r == 1
            specCentroid_start(i) = centroidRegion;
            specEntropy_start(i) = entropyRegion;
            energySpec_start(i) = energyRegion;
        elseif r == 2
            specCentroid_mid(i) = centroidRegion;
            specEntropy_mid(i) = entropyRegion;
            energySpec_mid(i) = energyRegion;
        else
            specCentroid_end(i) = centroidRegion;
            specEntropy_end(i) = entropyRegion;
            energySpec_end(i) = energyRegion;
        end
    end

    % Features globais (para visualização)
    meanSpectrum = mean(P, 2);
    totalPower = sum(meanSpectrum);

    energySpec(i) = sum(P, 'all');  % Sum all power values, not averaged
    [~, idxPeak] = max(meanSpectrum);
    peakFreq(i) = F(idxPeak);
    specCentroid(i) = sum(F .* meanSpectrum) / totalPower;
    specBW(i) = sqrt(sum(((F - specCentroid(i)).^2) .* meanSpectrum) / totalPower);
    P_norm = meanSpectrum / sum(meanSpectrum);
    specEntropy(i) = -sum(P_norm .* log2(P_norm + eps));
end



if(print_stft)

    figure;
    hold on;
for d = 0:9
    idx = data.digit == d;
    values = energySpec(idx);
    x = d * ones(size(values));  
    plot(x, values, 'o');        
end

xlabel('Dígito');
ylabel('Energia Espectral Média');
title('Distribuição da Energia Espectral Média por Dígito');
xticks(0:9);  % mostra os dígitos no eixo x
grid on;
hold off;


    figure;
    hold on;
for d = 0:9
    idx = data.digit == d;
    values = peakFreq(idx);
    x = d * ones(size(values));  
    plot(x, values, 'o');        
end

xlabel('Dígito');
ylabel('Pico de Frequência');
title('Pico de Frequência por Dígito');
xticks(0:9);  
grid on;
hold off;

    figure;
    hold on;
for d = 0:9
    idx = data.digit == d;
    values = specEntropy(idx);
    x = d * ones(size(values));  
    plot(x, values, 'o');        
end

xlabel('Dígito');
ylabel('Entropia Espectral');
title('Entropia Espectral');
xticks(0:9); 
grid on;
hold off;


    figure;
    hold on;
for d = 0:9
    idx = data.digit == d;
    values = specCentroid(idx);
    x = d * ones(size(values));  
    plot(x, values, 'o');        
end

xlabel('Dígito');
ylabel('Centroide Espectral');
title('Centroide Espectral');
xticks(0:9);
grid on;
hold off;


    figure;
    hold on;
for d = 0:9
    idx = data.digit == d;
    values = specBW(idx);
    x = d * ones(size(values));  
    plot(x, values, 'o');        
end

xlabel('Dígito');
ylabel('Largura de Banda Espectral por dígito');
title('Largura de Banda Espectral');
xticks(0:9);
grid on;
hold off;
        
end

% Guardar features globais (para referência/visualização)
data.energySpec = energySpec;
data.peakFreq = peakFreq;
data.specCentroid = specCentroid;
data.specBW = specBW;
data.specEntropy = specEntropy;

% Guardar features divididas em tempo
data.specCentroid_start = specCentroid_start;
data.specCentroid_mid = specCentroid_mid;
data.specCentroid_end = specCentroid_end;

data.specEntropy_start = specEntropy_start;
data.specEntropy_mid = specEntropy_mid;
data.specEntropy_end = specEntropy_end;

data.energySpec_start = energySpec_start;
data.energySpec_mid = energySpec_mid;
data.energySpec_end = energySpec_end; 


% Melhores características: Centroide, Entropia e Energia


%% 18: Transformada de Wavelet Discreta (DWT)

wname = 'db4';   % tipo da wavelet
level = 1;       % nível de decomposição


aprox = zeros(length(data.signal), 1);
detalhe = zeros(length(data.signal), 1);

for i = 1:length(data.signal)
    x = data.signal{i};
    x = x / max(abs(x));

    [cA, cD] = dwt(x, wname);  

    aprox(i) = sum(cA.^2);
    detalhe(i) = sum(cD.^2);
end

figure;

subplot(1,2,1); hold on;
for d = 0:9
    idx = data.digit == d;
    x = d * ones(sum(idx), 1);
    y = aprox(idx);
    plot(x, y, 'bo');
end
title('Energia de Aproximação (DWT)');
xlabel('Dígito'); ylabel('Energia');
xlim([-1 10]);
grid on;

subplot(1,2,2); hold on;
for d = 0:9
    idx = data.digit == d;
    x = d * ones(sum(idx), 1);
    y = detalhe(idx);
    plot(x, y, 'ro');
end
title('Energia de Detalhe (DWT)');
xlabel('Dígito'); ylabel('Energia');
xlim([-1 10]);
grid on;


data.DetailEnergy = detalhe;
data.AproxEnergy = aprox;



%% KNN Classification

energy_intervalos = reshape(cell2mat(data.energy), 3, [])';

X = [data.specEntropy, data.specBW, ...
     energy_intervalos(:, 1), energy_intervalos(:, 2)];

Y = data.digit;

% Normalizar features
X = zscore(X);

% Separar treino (70%) e teste (30%)
cv = cvpartition(Y, 'HoldOut', 0.3);

idxTreino = training(cv);
idxTeste  = test(cv);

Xtreino = X(idxTreino, :);
Ytreino = Y(idxTreino);

Xteste = X(idxTeste, :);
Yteste = Y(idxTeste);

%% Criar modelo KNN
k = 4; % podes testar outros valores

modeloKNN = fitcknn( ...
    Xtreino, ...
    Ytreino, ...
    'NumNeighbors', k, ...
    'Distance', 'euclidean', ...
    'Standardize', false);

%% Fazer previsões
predictedDigit = predict(modeloKNN, Xteste);

%% Accuracy
accuracy = sum(predictedDigit == Yteste) / length(Yteste);

fprintf('Accuracy: %.2f%%\n', accuracy * 100);

%% Matriz de confusão
figure;
confusionchart(Yteste, predictedDigit);
title(sprintf('KNN Confusion Matrix (k = %d)', k));
%% 20: Análise de Resultados

% Mostrar amostras de previsão
T = table(Yteste, predictedDigit);
disp(T);

% Calcular % de acerto global
accuracy = mean(predictedDigit == Yteste) * 100;
fprintf('\nTaxa de acerto global: %.2f%%\n', accuracy);

% Confusion matrix
confMatrix = confusionmat(Yteste, predictedDigit);

figure('Name', 'Confusion Matrix');
imagesc(confMatrix);
colorbar;
xlabel('Dígito Predito');
ylabel('Dígito Real');
title('Matriz de Confusão - Classificador Minimum Distance');
xticks(1:10);
yticks(1:10);
xticklabels(0:9);
yticklabels(0:9);

% Adicionar números na matriz
for i = 1:10
    for j = 1:10
        text(j, i, num2str(confMatrix(i,j)), 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', 'Color', 'white', 'FontWeight', 'bold');
    end
end

% Acurácia por dígito
fprintf('\nAcuraccy por dígito:\n');
for d = 0:9
    idxDigit = Yteste == d;
    if sum(idxDigit) > 0
        accDigit = mean(predictedDigit(idxDigit) == Yteste(idxDigit)) * 100;
        fprintf('Dígito %d: %.2f%% (%d amostras)\n', d, accDigit, sum(idxDigit));
    end
end


%% 21

save(fullfile(outDir, 'meta2_windowing_comparison.mat'), "data");


