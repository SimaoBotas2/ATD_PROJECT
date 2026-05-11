%% Setup e Carregamento de Dados

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

data = load(fullfile(outDir, 'meta2_windowing_comparison.mat'));
data = data.data;

print_stft = true; %apenas para retirar o spam de plots, colocar a true para ver todos


%% STFT: Espectrogramas dos Dígitos
fs = data.taxaAmostragem(1);

% Configurações para STFT
w = 512    ;
ov = 0.5;
nfft = 512;
noverlap = floor(w * ov);

figure('Name', 'Spectrogramas dos Dígitos 0 a 9');


numSamples = height(data);
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



%% Extração de Características Tempo-Frequência (STFT)
for i = 1:numSamples
    x = data.signal{i};
    x = x / max(abs(x)); % Normalizar

    % STFT (usei na run section e esqueci-me de retirar)
    [S, F, T, P] = spectrogram(x, w, noverlap, nfft, fs);
    P_log = 10*log10(P + eps); % evitar log(0)
    
    % Média espectral ao longo do tempo
    meanSpectrum = mean(P, 2);
    totalPower = sum(meanSpectrum);

    % 1. Energia média espectral
    energySpec(i) = mean(meanSpectrum);

    % 2. Pico de frequência (frequência com maior energia média)
    [~, idxPeak] = max(meanSpectrum);
    peakFreq(i) = F(idxPeak);

    % 3. Centroide espectral
    specCentroid(i) = sum(F .* meanSpectrum) / totalPower;

    % 4. Largura de banda espectral
    specBW(i) = sqrt(sum(((F - specCentroid(i)).^2) .* meanSpectrum) / totalPower);

    % 5. Entropia espectral (distribuição de energia)
    P_norm = meanSpectrum / sum(meanSpectrum);
    specEntropy(i) = -sum(P_norm .* log2(P_norm + eps));
end


%% Visualização das Características Extraídas

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

data.energySpec = energySpec; % Average a distinguir digitos
data.peakFreq = peakFreq; % Não muito boa para distinguir digitos 
data.specCentroid = specCentroid; % Boa
data.specBW = specBW;
data.specEntropy = specEntropy;%Average 


% Ou seja as melhores são
% Centroide, Entropia e Energia

%% Transformada de Wavelet Discreta (DWT)

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

%% Guardar Dados

save(fullfile(outDir, 'meta2_time_frequency_features.mat'), "data");


%% Comparação de Janelas (Arquivo)
% Comparação de diferentes tipos de janelas para análise FFT
% Mantido para referência mas não utilizado na classificação final

signal = data.signal{1};
Fs = data.taxaAmostragem(1);
n = length(signal);
f = (0:n-1)*(Fs/n);
f = f(1:floor(n/2)+1);

sig_rect = signal .* ones(n,1);
sig_hamming = signal .* hamming(n);
sig_blackman = signal .* blackman(n);

Y_rect = abs(fft(sig_rect))/n;
Y_hamming = abs(fft(sig_hamming))/n;
Y_black = abs(fft(sig_blackman))/n;

Y_rect = Y_rect(1:floor(n/2)+1);
Y_hamming = Y_hamming(1:floor(n/2)+1);
Y_black = Y_black(1:floor(n/2)+1);

figure;

subplot(3,1,1);
plot(f, Y_rect, 'r', 'LineWidth', 1.5);
ylim([0 0.03]);
xlim([0 3500]);
title('Janela Retangular');
xlabel('Frequência (Hz)');
ylabel('Magnitude');
grid on;

subplot(3,1,2);
plot(f, Y_hamming, 'b', 'LineWidth', 1.5);
ylim([0 0.015]);
xlim([0 3500]);
title('Janela de Hamming');
xlabel('Frequência (Hz)');
ylabel('Magnitude');
grid on;

subplot(3,1,3);
plot(f, Y_black, 'k', 'LineWidth', 1.5);
ylim([0 0.015]);
xlim([0 3500]);
title('Janela de BlackMan');
xlabel('Frequência (Hz)');
ylabel('Magnitude');
grid on;
