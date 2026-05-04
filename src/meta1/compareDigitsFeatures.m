    function processed_data = compareDigitsFeatures(processed_data, divisions)
    figure;
    colors = lines(10);

    numFiles = length(processed_data.fileName);
    processed_data.amplitudeMax = cell(numFiles,1);
    processed_data.energiaTotal = zeros(numFiles,1);
    processed_data.energy = cell(numFiles,1);

    %plot da amplitude maxima do sinal em diferentes partes, dada por
    %divisions , i.e, 3 divisions divide o sinal em 3, 4 em 4...
    %util para percebermos em que partes de cada digito tem mais amplitude
    %e, normalmente, mais energia
    %ter em conta que com mais divisoes, mais preciso é, e também que na
    %primeira divisão, muitos digitos chegam a amplitude maxima em varias
    %repeticoes
    for j = 1:divisions

        subplot(divisions, 1, j);
        hold on;
        for digitToCompare = 0:9
            indices = find(processed_data.digit == digitToCompare);
            numSignals = length(indices);

            amplitude_max = zeros(numSignals, 1);

            for i = 1:numSignals
                index = indices(i);
                signal = processed_data.signal{index};
                signal_length = length(signal);

                division_size = floor(signal_length / divisions);
                ti = (j-1) * division_size + 1;
                tf = min(j * division_size, signal_length); 
                
                amplitude_max(i) = max(abs(signal(ti:tf)));

                if isempty(processed_data.amplitudeMax{index}) 
                processed_data.amplitudeMax{index} = amplitude_max(i);
                else
                processed_data.amplitudeMax{index} = [processed_data.amplitudeMax{index}; amplitude_max(i)];
                end
            end

            plot(repmat(digitToCompare, numSignals, 1), amplitude_max, 'o', 'Color', colors(digitToCompare + 1, :), ...
                'MarkerSize', 8, 'LineWidth', 1.2);
        end
        xlabel('Dígito');
        title(['Comparação da Amplitude Máxima - Divisão ' num2str(j)]);
        grid on;
    end
    
    hold off;


    %plot da energia total de cada sinal, uma boa ferramenta para saber
    %quais digitos , por norma, têm mais energia
    figure;
    hold on;

    for digitToCompare = 0:9
        indices = find(processed_data.digit == digitToCompare);
        numSignals = length(indices);
        energia_total = zeros(numSignals, 1); 

        % Calcular a energia total de cada repetição
        for i = 1:numSignals
            index = indices(i);
            energia_total(i) = sum(processed_data.signal{index}.^2);
            processed_data.energiaTotal(index) = energia_total(i);
        end

        % energia total de cada repetição para o dígito
        plot(ones(numSignals, 1) * digitToCompare, energia_total, 'o', 'Color', colors(digitToCompare + 1, :), ...
            'MarkerSize', 8, 'LineWidth', 1.2);
    end

    xlabel('Dígito');
    ylabel('Energia Total');
    title('Energia Total de Cada Sinal');
    grid on;

    hold off;

    figure;


% Plot da energia de cada divisão, similar à da
% máxima amplitude por divisão, mas com valores mais corretos pois leva em 
% conta toda a divisão.

for j = 1:divisions
    subplot(divisions, 1, j);
    hold on;
   
    for digitToCompare = 0:9
        indices = find(processed_data.digit == digitToCompare);
        numSignals = length(indices);

        energy = zeros(numSignals, 1); 

        for i = 1:numSignals
            index = indices(i);
            signal = processed_data.signal{index};
            signal_length = length(signal);

            division_size = floor(signal_length / divisions);
            ti = (j-1) * division_size + 1;
            tf = min(j * division_size, signal_length); 

            energy(i) = sum(abs(signal(ti:tf)).^2); 

            if isempty(processed_data.energy{index}) 
                processed_data.energy{index} = energy(i);
            else
                processed_data.energy{index} = [processed_data.energy{index}; energy(i)];
            end
        end


        % Plota a energia como círculos
        plot(repmat(digitToCompare, numSignals, 1), energy, 'o', ...
            'Color', colors(digitToCompare + 1, :), 'MarkerSize', 8, 'LineWidth', 1.2);

    end

    xlabel('Dígito');
    title(['Comparação da Energia - Divisão ' num2str(j)]);
    grid on;
end

hold off;


%Plot do desvio padrao da amplitude maxima de cada digito
std_amplitudeMax = NaN(height(processed_data), 1);

for digitToCompare = 0:9

    indices = find(processed_data.digit == digitToCompare);
    numSignals = length(indices);

    amplitude_max_all_divisions = [];


    for i = 1:numSignals
        index = indices(i);
        amplitude_max_all_divisions = [amplitude_max_all_divisions; processed_data.amplitudeMax{index}];
    end
   
    digit_std = std(amplitude_max_all_divisions);

    for i = 1:numSignals
        std_amplitudeMax(indices(i)) = digit_std;
    end
end

processed_data.stdAmplitudeMax = std_amplitudeMax;


figure;
bar(0:9,std_amplitudeMax(1:50:500));
xlabel('Dígito');
ylabel('Desvio Padrão da Amplitude Máxima');
title('Desvio Padrão das Amplitudes Máximas para Cada Dígito');
grid on;




%Plot dos desvio padrao da energia total dos sinais de cada digito
std_energyTotal = NaN(height(processed_data), 1);

for digitToCompare = 0:9
    indices = find(processed_data.digit == digitToCompare);
    numSignals = length(indices);

    energy_all_divisions = [];

    for i = 1:numSignals
        index = indices(i);
        energy_all_divisions = [energy_all_divisions; processed_data.energiaTotal(index)];
    end

    digit_std_energy = std(energy_all_divisions);

    for i = 1:numSignals
        std_energyTotal(indices(i)) = digit_std_energy;
    end
end

processed_data.desvioEnergiaTotal = std_energyTotal;

figure;
bar(0:9,std_energyTotal(1:50:500),'FaceColor','yellow');
xlabel('Dígito');
ylabel('Desvio Padrão da Energia do Sinal');
title('Desvio Padrão das Energias Totais dos Sinais de Cada Dígito');
grid on;



figure;
hold on;


feature1 = cellfun(@mean, processed_data.amplitudeMax); 
feature2 = processed_data.energiaTotal;                 
feature3 = cellfun(@mean, processed_data.energy);      



colors = lines(10); 
for digit = 0:9
    idx = (processed_data.digit == digit);
    scatter3(feature1(idx), feature2(idx), feature3(idx), ...
            50, ...                          
            colors(digit+1,:), ...           
            'Marker', 'o', ...              
            'MarkerEdgeColor', colors(digit+1,:), ... 
            'MarkerFaceColor', 'none', ...  
            'LineWidth', 1.5, ...           
            'DisplayName', ['Digit ' num2str(digit)]);
end


xlabel('Amplitude Máxima Média');
ylabel('Energia total');
zlabel('Energia por divisao');
title('Comparação por digito');
legend('Location', 'bestoutside');
grid on;
view(-30, 15); 
rotate3d on;    
hold off;




end




