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

%% 16
S = load(fullfile(outDir, 'meta1_fourier_and_spectral_features.mat'));
data = S.meta1_fourier_features;

%% 17
% Usar o algoritmo minimum distance

energy_intervalos = reshape(cell2mat(data.energy), 3, [])';

X = [energy_intervalos, data.PicoFreq(:), data.desvioEnergiaTotal(:)];
Y = data.digit;

X = zscore(X);

% Separar treino (70%) e teste (30%)
cv = cvpartition(Y, 'HoldOut', 0.3);

idxTreino = training(cv); % Logical array: 1 se é treino
idxTeste  = test(cv);      % Logical array: 1 se é teste

Xtreino = X(idxTreino, :);
Ytreino = Y(idxTreino);

Xteste = X(idxTeste, :);
Yteste = Y(idxTeste);

% Calcular a média das features no treino
[centroids, digitGroups] = grpstats(Xtreino, Ytreino, {'mean', 'gname'});
digitGroups = str2double(digitGroups);

% Classificar amostras de teste
predictedDigit = zeros(size(Yteste));
for i = 1:size(Xteste, 1)
    distances = sqrt(sum((Xteste(i,:) - centroids).^2, 2));
    [~, idx] = min(distances);
    predictedDigit(i) = digitGroups(idx);
end

%% 18 
% Mostrar dígito verdadeiro vs predicted
T = table(Yteste, predictedDigit);
disp(T);

% Calcular % de acerto
accuracy = mean(predictedDigit == Yteste) * 100;
fprintf('\nTaxa de acerto: %.2f%%\n', accuracy);

%% 19

% Selecionar uma amostra (ex: a primeira)
signal = data.signal{1};
Fs = data.taxaAmostragem(1);
n = length(signal);
f = (0:n-1)*(Fs/n);
f = f(1:floor(n/2)+1);


%Aplicar janelas
sig_rect = signal .* ones(n,1);
sig_hamming = signal .* hamming(n);
sig_blackman = signal .* blackman(n);

Y_rect = abs(fft(sig_rect))/n;
Y_hamming = abs(fft(sig_hamming))/n;
Y_black = abs(fft(sig_blackman))/n;

Y_rect = Y_rect(1:floor(n/2)+1);
Y_hamming = Y_hamming(1:floor(n/2)+1);
Y_black = Y_black(1:floor(n/2)+1);

% Plot
figure;

%Boa resolução do sinal, mas com muita leakage
subplot(3,1,1);
plot(f, Y_rect, 'r', 'LineWidth', 1.5);
ylim([0 0.03]);
xlim([0 3500]);
title('Janela Retangular');
xlabel('Frequência (Hz)');
ylabel('Magnitude');
grid on;

%Leakage menor em relação à retangular, bom equilibrio entre resolução e leakage  
subplot(3,1,2);
plot(f, Y_hamming, 'b', 'LineWidth', 1.5);
ylim([0 0.015]);
xlim([0 3500]);
title('Janela de Hamming');
xlabel('Frequência (Hz)');
ylabel('Magnitude');
grid on;


%Perda de alguma resolução, mas diminuição de leakage
subplot(3,1,3);
plot(f, Y_black, 'k', 'LineWidth', 1.5);
ylim([0 0.015]);
xlim([0 3500]);
title('Janela de BlackMan');
xlabel('Frequência (Hz)');
ylabel('Magnitude');
grid on;

%% 20

save(fullfile(outDir, 'meta2_windowing_comparison.mat'), "data");