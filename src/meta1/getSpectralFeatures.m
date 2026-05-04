function output = getSpectralFeatures(data,numFiles)

% Calcula características espectrais (>=5) para cada áudio.

output = data;

% Pré-alocar espaço
output.PicoFreq = zeros(height(output), 1);
output.PicoAmp = zeros(height(output), 1);
output.SpectralEdge = zeros(height(output), 1);
output.MediaAmp = zeros(height(output), 1);
output.SpectralCentroid = zeros(height(output), 1);
output.SpectralBW = zeros(height(output), 1);
output.SpectralEntropy = zeros(height(output), 1);

percent = 0.95; % SEF_95

for i = 1:numFiles
    Fs = output.taxaAmostragem(i);

    if ismember('FourierCoeffs', output.Properties.VariableNames)
        coeffs = output.FourierCoeffs{i};
        n = length(coeffs);
        fullAmp = abs(coeffs) / n;
    else
        fullAmp = output.Fourier{i};
        n = length(fullAmp);
        fullAmp = abs(fullAmp) / n;
    end

    spectrum = fullAmp(1:floor(n/2)+1); % apenas frequências positivas (inclui DC)
    freq = (0:floor(n/2)) * (Fs / n);
    
    % Pico (frequência e amplitude)
    [max_val, max_idx] = max(spectrum);
    output.PicoFreq(i) = freq(max_idx);
    output.PicoAmp(i) = max_val;

    % Spectral Edge
    powerSpectrum = spectrum.^2;
    cumulativePower = cumsum(powerSpectrum);
    totalPower = cumulativePower(end);
    threshold = percent * totalPower;
    idxEdge = find(cumulativePower >= threshold, 1);
    output.SpectralEdge(i) = freq(idxEdge);
    
    % Amplitude média
    output.MediaAmp(i) = mean(spectrum);

    % Centroide espectral
    if totalPower > 0
        output.SpectralCentroid(i) = sum(freq(:) .* powerSpectrum(:)) / totalPower;
        output.SpectralBW(i) = sqrt(sum(((freq(:) - output.SpectralCentroid(i)).^2) .* powerSpectrum(:)) / totalPower);
    else
        output.SpectralCentroid(i) = 0;
        output.SpectralBW(i) = 0;
    end

    % Entropia espectral
    p = powerSpectrum / (sum(powerSpectrum) + eps);
    output.SpectralEntropy(i) = -sum(p .* log2(p + eps));
end

digits = unique(output.digit);
colors = lines(length(digits));

figure;

% Frequência do Pico
subplot(3,2,1);
hold on;
for d = 1:length(digits)
    idx = find(output.digit == digits(d));
    scatter(repmat(digits(d), length(idx), 1), output.PicoFreq(idx), 36, colors(d,:), 'filled');
end
title('Frequência do Pico por Amostra');
xlabel('Dígito');
ylabel('Frequência (Hz)');
grid on;
xticks(digits);

% Pico de amplitude
subplot(3,2,2);
hold on;
for d = 1:length(digits)
    idx = find(output.digit == digits(d));
    scatter(repmat(digits(d), length(idx), 1), output.PicoAmp(idx), 36, colors(d,:), 'filled');
end
title('Amplitude do Pico por Amostra');
xlabel('Dígito');
ylabel('Amplitude');
grid on;
xticks(digits);

% Spectral Edge
subplot(3,2,3);
hold on;
for d = 1:length(digits)
    idx = find(output.digit == digits(d));
    scatter(repmat(digits(d), length(idx), 1), output.SpectralEdge(idx), 36, colors(d,:), 'filled');
end
title('Spectral Edge (95%) por Amostra');
xlabel('Dígito');
ylabel('Frequência (Hz)');
grid on;
xticks(digits);

% Centroide
subplot(3,2,4);
hold on;
for d = 1:length(digits)
    idx = find(output.digit == digits(d));
    scatter(repmat(digits(d), length(idx), 1), output.SpectralCentroid(idx), 36, colors(d,:), 'filled');
end
title('Centroide Espectral por Amostra');
xlabel('Dígito');
ylabel('Frequência (Hz)');
grid on;
xticks(digits);

% Entropia
subplot(3,2,5);
hold on;
for d = 1:length(digits)
    idx = find(output.digit == digits(d));
    scatter(repmat(digits(d), length(idx), 1), output.SpectralEntropy(idx), 36, colors(d,:), 'filled');
end
title('Entropia Espectral por Amostra');
xlabel('Dígito');
ylabel('Entropia');
grid on;
xticks(digits);

% Amplitude Média
subplot(3,2,6);
hold on;
for d = 1:length(digits)
    idx = find(output.digit == digits(d));
    scatter(repmat(digits(d), length(idx), 1), output.MediaAmp(idx), 36, colors(d,:), 'filled');
end
title('Amplitude Média por Amostra');
xlabel('Dígito');
ylabel('Amplitude');
grid on;
xticks(digits);

sgtitle('Distribuição das Características Espectrais por Dígito (Todas as Amostras)');

end
