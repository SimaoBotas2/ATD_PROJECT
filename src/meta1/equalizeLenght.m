function processed_data = equalizeLenght(data,numFiles,len)
%coloca todos os sinais com mesma lenght, indicada por len, em segundos

if any(data.taxaAmostragem ~= data.taxaAmostragem(1))
    error('As taxas de amostragem não são todas iguais. Equalização por duração assume Fs constante.');
end

target = max(1, round(len * data.taxaAmostragem(1))); %todas sao iguais

processed_data = data;

for i=1:numFiles

    atual_len = length(processed_data.signal{i});

     if(atual_len<target)
         processed_data.signal{i} = [data.signal{i};zeros(target - atual_len,1)];
     else
         processed_data.signal{i} = data.signal{i}(1:target);
     end
end