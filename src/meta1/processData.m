function processed_data = processData(data,n,l)
% main funcao para processar os dados, ponto 4 da ficha

treshold_clean = 0.05;


processed_data = data;

for i = 1:n

    processed_data.signal{i} = removeInitialSilence(data.signal{i}, data.taxaAmostragem(i),treshold_clean);
    processed_data.signal{i} = normalize(processed_data.signal{i},'range',[-1,1]); 

end

processed_data = equalizeLenght(processed_data,n,l);