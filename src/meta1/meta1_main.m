function meta1_main(varargin)


opts = parseOpts(varargin);
[~, outDir] = getProjectDirs();

mat_preprocessed = 'meta1_preprocessed_signals.mat';
mat_fourier_features = 'meta1_fourier_and_spectral_features.mat';
mat_features_only = 'meta1_features_no_signals.mat';

%% 1-2: Estrutura + importação
[data_raw, numFiles] = getDataFromFiles();

%% 4: Pré-processamento (silêncio inicial + normalização + duração fixa)
data_proc = processData(data_raw, numFiles, opts.SignalLengthSec);

%% 3 e 5: Exemplos (raw e processado)
if opts.PlotTemporal
    plotRepetitionAcrossDigits(data_raw, opts.RepetitionToPlot, 'Raw');
    plotRepetitionAcrossDigits(data_proc, opts.RepetitionToPlot, 'Pré-processado');
end

%% 7-8: Features temporais + gráficos
if opts.ComputeTemporalFeatures
    data_proc = compareDigitsFeatures(data_proc, opts.Divisions);
end

%% Guardar estrutura intermédia (com sinais)
meta1_preprocessed = data_proc;
save(fullfile(outDir, mat_preprocessed), 'meta1_preprocessed');

%% 9-12: Fourier + estatísticas do espectro + features espectrais
if opts.ComputeSpectral
    data_full = addFourierCoeffs(data_proc);

    if opts.PlotSpectral
        plotSpectralQuartiles(data_full, opts.MaxFreqPlotHz, opts.SpectralYMax);
    end

    if opts.ComputeSpectralFeatures
        data_full = getSpectralFeatures(data_full, height(data_full));
    end

    meta1_fourier_features = data_full;
    save(fullfile(outDir, mat_fourier_features), 'meta1_fourier_features');
else
    data_full = data_proc;
end

%% 13: remover sinais e guardar .mat para carregar rápido
if ismember('signal', data_full.Properties.VariableNames)
    data_features = removevars(data_full, 'signal');
else
    data_features = data_full;
end
if ismember('FourierCoeffs', data_features.Properties.VariableNames)
    data_features = removevars(data_features, 'FourierCoeffs');
end
meta1_features = data_features;
save(fullfile(outDir, mat_features_only), 'meta1_features');

fprintf('Meta 1 concluída. Outputs em: %s\n', outDir);
fprintf(' - %s\n', mat_preprocessed);
if opts.ComputeSpectral
    fprintf(' - %s\n', mat_fourier_features);
end
fprintf(' - %s\n', mat_features_only);


%% ===== Funções Auxiliares =====

    function tbl = addFourierCoeffs(tblIn)
        tbl = tblIn;
        n = height(tbl);
        tbl.FourierCoeffs = cell(n, 1);
        for k = 1:n
            x = tbl.signal{k};
            tbl.FourierCoeffs{k} = fft(x);
        end
    end

    function plotRepetitionAcrossDigits(tbl, repToPlot, subtitleText)
        repData = tbl(tbl.repnumber == repToPlot, :);
        if height(repData) < 10
            warning('Não existem 10 dígitos para repetição %d (encontrei %d).', repToPlot, height(repData));
        end

        screenSize = get(0,'ScreenSize');
        width = 1000;
        heightFig = 600;
        left = (screenSize(3) - width) / 2;
        bottom = (screenSize(4) - heightFig) / 2;
        figure('Position', [left, bottom, width, heightFig]);

        for d = 0:9
            idx = find(repData.digit == d, 1, 'first');
            if isempty(idx)
                continue;
            end
            subplot(5,2,d+1);
            x = repData.signal{idx};
            Fs = repData.taxaAmostragem(idx);
            t = (0:length(x)-1) / Fs;
            plot(t, x);
            grid on;
            title(sprintf('Dígito %d', d));
            xlabel('Tempo (s)');
            ylabel('Amplitude');
        end

        sgtitle(sprintf('Repetição %d — %s', repToPlot, subtitleText));
    end

    function plotSpectralQuartiles(tbl, maxFreq, yMax)
        Fs = tbl.taxaAmostragem(1);

        medianSpectra = cell(10, 1);
        q1Spectra = cell(10, 1);
        q3Spectra = cell(10, 1);
        freqAxes = cell(10, 1);

        for d = 1:10
            digitIndices = find(tbl.digit == d-1);
            if isempty(digitIndices)
                continue;
            end
            allSpectra = [];

            n = length(tbl.FourierCoeffs{digitIndices(1)});
            freq_pos = (0:floor(n/2)) * (Fs / n);
            freqAxes{d} = freq_pos;

            for ii = 1:length(digitIndices)
                idx = digitIndices(ii);
                coeffs = tbl.FourierCoeffs{idx};
                n = length(coeffs);
                amp = abs(coeffs) / n;
                posAmp = amp(1:floor(n/2)+1);
                allSpectra = [allSpectra; posAmp'];
            end

            medianSpectra{d} = median(allSpectra, 1);
            q1Spectra{d} = quantile(allSpectra, 0.25, 1);
            q3Spectra{d} = quantile(allSpectra, 0.75, 1);
        end

        figure;
        for d = 1:10
            subplot(5, 2, d);
            hold on;

            freq = freqAxes{d};
            if isempty(freq)
                continue;
            end
            mask = freq <= maxFreq;

            plot(freq(mask), medianSpectra{d}(mask), 'Color', 'r', 'LineWidth', 2);
            plot(freq(mask), q1Spectra{d}(mask), 'Color', 'b', 'LineWidth', 1.5);
            plot(freq(mask), q3Spectra{d}(mask), 'Color', 'y', 'LineWidth', 1.5);

            title(num2str(d-1));
            xlabel('Frequência (Hz)');
            ylabel('Amplitude');
            grid on;
            xlim([0, maxFreq]);
            ylim([0, yMax]);

            if d == 1
                legend('Mediana', 'Q1 (25%)', 'Q3 (75%)', 'Location', 'northeast');
            end
        end
        sgtitle(sprintf('Estatísticas do Espetro (0–%d Hz)', maxFreq));
    end

    function optsOut = parseOpts(vararginIn)
        p = inputParser;
        p.addParameter('SignalLengthSec', 0.5, @(x) isnumeric(x) && isscalar(x) && x > 0);
        p.addParameter('Divisions', 3, @(x) isnumeric(x) && isscalar(x) && x >= 1);
        p.addParameter('RepetitionToPlot', 5, @(x) isnumeric(x) && isscalar(x) && x >= 0);
        p.addParameter('PlotTemporal', true, @(x) islogical(x) && isscalar(x));
        p.addParameter('PlotSpectral', true, @(x) islogical(x) && isscalar(x));
        p.addParameter('ComputeTemporalFeatures', true, @(x) islogical(x) && isscalar(x));
        p.addParameter('ComputeSpectral', true, @(x) islogical(x) && isscalar(x));
        p.addParameter('ComputeSpectralFeatures', true, @(x) islogical(x) && isscalar(x));
        p.addParameter('MaxFreqPlotHz', 4000, @(x) isnumeric(x) && isscalar(x) && x > 0);
        p.addParameter('SpectralYMax', 0.010, @(x) isnumeric(x) && isscalar(x) && x > 0);
        p.parse(vararginIn{:});
        optsOut = p.Results;
    end

    function [rootDirOut, outDirOut] = getProjectDirs()
        thisDir2 = fileparts(mfilename('fullpath'));
        rootDirOut = thisDir2;
        while ~exist(fullfile(rootDirOut, 'data_raw'), 'dir') || ~exist(fullfile(rootDirOut, 'data_processed'), 'dir')
            parent = fileparts(rootDirOut);
            if strcmp(parent, rootDirOut)
                error('Não foi possível encontrar o root do projeto a partir de: %s', thisDir2);
            end
            rootDirOut = parent;
        end

        outDirOut = fullfile(rootDirOut, 'data_processed');
        if ~exist(outDirOut, 'dir')
            mkdir(outDirOut);
        end
    end

end
