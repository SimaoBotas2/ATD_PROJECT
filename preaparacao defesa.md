## 🎓 Meta 1 — explicação mais aprofundada para defesa

A **Meta 1** não foi apenas “tratar áudio”: foi uma etapa de **extração de informação**. O objetivo principal foi transformar sinais de voz brutos em **características quantitativas** que permitam comparar os dígitos de forma consistente e justificar, do ponto de vista analítico, que há estrutura nos dados.

---

## 1️⃣ Objetivo técnico da Meta 1

Quando trabalhamos com gravações de voz, o sinal bruto contém muita variabilidade que **não interessa diretamente** para a análise:

- tempo morto no início;
- amplitudes diferentes entre gravações;
- durações diferentes da mesma palavra;
- pequenas flutuações naturais de pronúncia.

Por isso, a Meta 1 foi importante para responder a esta pergunta:

> **Que características do sinal ajudam realmente a distinguir os dígitos pronunciados?**

---

## 2️⃣ Pré-processamento: porque foi necessário

Antes de extrair características, os sinais foram ajustados para garantir comparabilidade.

### Remoção do silêncio inicial
O silêncio inicial não contém informação sobre o dígito, mas altera o alinhamento temporal.  
Ao removê-lo, ficamos com sinais mais centrados na parte relevante da fala.

### Normalização da amplitude
Diferentes gravações podem ter volumes diferentes.  
Se isso não for corrigido, medidas como energia ou amplitude máxima podem refletir apenas intensidade de gravação e não diferenças reais entre dígitos.

### Equalização da duração
Os dígitos não são pronunciados todos com a mesma duração.  
Ao uniformizar o comprimento dos sinais, tornou-se possível:
- dividir o sinal em partes equivalentes;
- comparar a mesma “zona temporal” entre repetições;
- construir features consistentes.

---

## 3️⃣ Características temporais

As **features temporais** olham para o sinal no domínio do tempo, ou seja, para a evolução da amplitude ao longo da fala.

### 3.1 Amplitude máxima por divisão
O sinal foi dividido em várias partes, e em cada uma foi calculada a **amplitude máxima**.

### O que esta feature mede?
Mede o ponto de maior intensidade local em cada segmento temporal.

### Porque é útil?
Nem todos os dígitos concentram a sua intensidade na mesma zona da pronúncia.  
Há dígitos que têm um ataque inicial mais forte, outros distribuem melhor a energia ao longo do tempo.

### Interpretação para defesa
Esta feature ajuda a perceber a **estrutura temporal interna** de cada dígito:
- onde a pronúncia é mais forte;
- se a intensidade se concentra no início, meio ou fim;
- se existe consistência entre repetições.

### Limitação
A amplitude máxima é sensível a picos isolados.  
Por isso, ela é útil, mas não deve ser usada sozinha.

---

### 3.2 Energia total
A energia total foi calculada como a soma do quadrado das amplitudes do sinal.

$$
E = \sum_{n=1}^{N} x(n)^2
$$

### O que mede?
Mede a “quantidade total de sinal” ao longo da gravação.

### Porque é relevante?
Dígitos diferentes podem ter:
- durações efetivas diferentes;
- intensidade articulatória diferente;
- distribuição energética distinta.

### Interpretação
Um dígito com maior energia total tende a corresponder a uma pronúncia mais marcada ou mais prolongada.  
Isto permite comparar a “força global” da produção vocal.

---

### 3.3 Energia por divisões
Em vez de olhar apenas para a energia global, também foi calculada a energia em cada parte do sinal.

### Vantagem desta abordagem
Enquanto a energia total resume tudo num único número, a energia por divisões mostra **como essa energia está distribuída no tempo**.

### Exemplo de leitura
- se a maior parte da energia estiver no início, o dígito tem um ataque mais concentrado;
- se estiver espalhada, a pronúncia é mais sustentada.

### Para a defesa
Esta é uma feature forte porque representa melhor a dinâmica do sinal do que apenas um valor total.

---

### 3.4 Desvio-padrão das features temporais
Foi também analisada a variabilidade das medidas dentro de cada dígito.

### Porque isto é importante?
Não basta uma feature separar bem médias entre dígitos; também interessa saber se ela é:
- **estável** entre repetições;
- ou muito variável dentro do mesmo grupo.

### Leitura estatística
- **baixo desvio-padrão** → maior consistência intra-dígito;
- **alto desvio-padrão** → mais variabilidade na pronúncia.

Isto é muito útil numa defesa porque mostra preocupação não só com separação, mas também com **robustez**.

---

## 4️⃣ Características espectrais

Depois da análise temporal, passou-se ao domínio da frequência com a **Transformada de Fourier (FFT)**.

### Ideia central
O sinal de voz não é apenas "como varia no tempo"; também interessa saber **que frequências o compõem**.

A FFT decompõe o sinal numa soma de componentes sinusoidais, cada uma com uma frequência e uma amplitude. O resultado é o **espetro de amplitudes**, que revela quais as frequências com maior presença no sinal.

A análise espectral é especialmente importante em voz, porque fonemas diferentes ativam ressonâncias vocais distintas — por exemplo, o dígito "zero" e o dígito "cinco" têm articulações completamente diferentes que se manifestam no espetro.

### Como foi calculado na prática
O espetro foi obtido a partir dos coeficientes da FFT, normalizado pelo número de amostras $n$ e truncado às frequências positivas (metade do espetro, por simetria):

$$
A_k = \frac{|X_k|}{n}, \quad k = 0, 1, \ldots, \lfloor n/2 \rfloor
$$

onde $X_k$ são os coeficientes complexos da FFT. As frequências correspondentes são $f_k = k \cdot \frac{F_s}{n}$, sendo $F_s$ a taxa de amostragem.

---

### 4.1 Frequência de pico
É a frequência $f^*$ onde o espetro de amplitudes atinge o seu valor máximo:

$$
f^* = f_k \quad \text{tal que} \quad A_k = \max_j A_j
$$

### O que indica?
Identifica a componente sinusoidal dominante do sinal — aquela que contribui mais para a sua forma geral.

### Relevância para os dígitos
Sons vocálicos (como o "a" em "quatro") tendem a ter picos em frequências mais baixas, ligadas ao primeiro formante vocal. Sons fricativos (como o "s" em "seis") concentram energia em frequências mais altas. Esta feature é uma primeira aproximação à estrutura fonética do dígito.

### Limitação
O pico pode ser instável se o espetro for muito irregular — dois sinais semelhantes podem ter picos em frequências ligeiramente diferentes. Por isso funciona melhor em conjunto com outras métricas.

---

### 4.2 Amplitude do pico
É o valor $A^* = \max_k A_k$, ou seja, a amplitude correspondente à frequência dominante.

### Interpretação
Indica a intensidade da componente principal do sinal. Não diz onde está o pico (isso é a frequência de pico), mas quão pronunciado ele é.

### Utilidade conjunta
Frequência de pico e amplitude do pico formam um par complementar: dois sinais podem ter o pico na mesma frequência, mas com amplitudes muito diferentes, o que os torna ainda assim distinguíveis. Usar apenas uma das duas seria perder informação.

---

### 4.3 Spectral Edge Frequency (SEF 95%)
É a frequência $f_{\text{edge}}$ abaixo da qual se encontra 95% da **potência** espectral total.

A potência em cada bin é $P_k = A_k^2$. A SEF é calculada pela potência acumulada:

$$
f_{\text{edge}} = \min \left\{ f_j \;:\; \frac{\displaystyle\sum_{k=0}^{j} P_k}{\displaystyle\sum_{k=0}^{N} P_k} \geq 0.95 \right\}
$$

### O que mede?
Delimita a "banda efetiva" do sinal — a zona espectral que contém quase toda a informação energética.

### Interpretação
- **SEF baixa** → energia concentrada em baixas frequências; sinal com carácter mais grave ou vocálico;
- **SEF alta** → energia espalhada até frequências mais altas; sinal com componentes fricativas ou ruidosas.

### Vantagem face ao pico
Enquanto a frequência de pico identifica apenas o máximo, a SEF resume a distribuição cumulativa de potência — é mais robusta a irregularidades no espetro.

### Para defesa
Dígitos com maior conteúdo fricativo (ex.: "seis", "sete") tendem a ter SEF mais alta do que dígitos mais vocálicos (ex.: "um", "oito"). Esta feature captura esse contraste de forma compacta.

---

### 4.4 Centroide espectral
O centroide espectral é o "centro de massa" da distribuição de potência em frequência — a frequência média ponderada pela potência em cada bin:

$$
C = \frac{\displaystyle\sum_{k} f_k \, P_k}{\displaystyle\sum_{k} P_k}
$$

onde $P_k = A_k^2$ é a potência na frequência $f_k$.

### Interpretação intuitiva
Imagina o espetro de potência como uma distribuição de pesos ao longo do eixo das frequências. O centroide é o ponto de equilíbrio dessa distribuição:
- **centroide baixo** → a "massa" energética está nas frequências graves; som mais escuro/grave;
- **centroide alto** → a "massa" está nas frequências agudas; som mais brilhante/agudo.

### Diferença face ao pico
A frequência de pico olha apenas para o máximo; o centroide considera todo o espetro. Se o sinal tiver energia distribuída por várias frequências, o centroide pode estar longe do pico.

### Importância
É uma das features mais usadas em análise de áudio. Resume de forma robusta a posição espectral global do sinal, sendo menos sensível a um único bin dominante.

---

### 4.5 Largura de banda espectral
Mede o **desvio padrão ponderado** das frequências em torno do centroide — o grau de dispersão da potência espectral:

$$
BW = \sqrt{\frac{\displaystyle\sum_{k} (f_k - C)^2 \, P_k}{\displaystyle\sum_{k} P_k}}
$$

### O que informa?
- **largura de banda baixa** → potência concentrada numa zona estreita perto do centroide; espetro "afiado";
- **largura de banda alta** → potência espalhada por uma gama larga de frequências; espetro "largo".

### Relação com o centroide
Centroide e largura de banda descrevem juntos a distribuição espectral de forma análoga à média e ao desvio padrão de uma distribuição estatística. Dois dígitos com centroide semelhante podem ter larguras de banda muito diferentes, tornando-os distinguíveis quando as duas features são usadas em conjunto.

### Exemplo intuitivo
Um som puro (como um assobio) tem espetro estreito → largura de banda baixa.  
Um som complexo ou ruidoso (como "sh") tem espetro largo → largura de banda alta.

---

### 4.6 Entropia espectral
A entropia espectral mede o **grau de uniformidade** da distribuição de potência ao longo do espetro, usando a entropia de Shannon:

$$
H = -\sum_{k} p_k \log_2(p_k), \quad \text{onde} \quad p_k = \frac{P_k}{\displaystyle\sum_j P_j}
$$

O vetor $p$ é a distribuição de probabilidade normalizada da potência espectral.

### Interpretação
- **$H$ baixa** → a potência está concentrada em poucos bins; espetro com picos dominantes bem definidos;
- **$H$ alta** → a potência está distribuída de forma mais uniforme por todos os bins; espetro "plano" ou difuso.

### Valor máximo teórico
Se a potência fosse distribuída igualmente por todos os $N$ bins, a entropia seria $\log_2(N)$ — o máximo possível. Quanto mais a entropia se aproxima desse valor, mais "difuso" é o espetro.

### Porque é interessante para dígitos?
Sons fricativos (espectralmente mais planos) têm alta entropia; sons vocálicos com formantes bem definidos têm baixa entropia. Esta feature captura uma dimensão que o centroide e a largura de banda não conseguem sozinhos.

---

### 4.7 Amplitude média do espetro
É a média das amplitudes ao longo de todos os bins de frequência positivos:

$$
\bar{A} = \frac{1}{N} \sum_{k=0}^{N} A_k
$$

### Interpretação
Reflete o nível médio de amplitude ao longo de todo o espetro. Está relacionada com a intensidade global do sinal após a FFT.

### Limitação e utilidade
Sozinha, é pouco discriminativa, porque não localiza onde está a energia. Contudo, quando combinada com features como o centroide ou a entropia, ajuda a contextualizar a escala dos valores espectrais e a diferenciar gravações com níveis energéticos globais distintos.

---

### Resumo comparativo das features espectrais

| Feature | O que mede | Sensível a |
|---|---|---|
| Frequência de pico | Localização do máximo espectral | Componente sinusoidal dominante |
| Amplitude do pico | Intensidade do máximo | Força da componente principal |
| SEF 95% | Largura espectral efetiva | Distribuição cumulativa de potência |
| Centroide | Centro de massa espectral | Posição global da energia |
| Largura de banda | Dispersão em torno do centroide | Concentração vs. espalhamento |
| Entropia | Uniformidade do espetro | Estrutura vs. difusidade |
| Amplitude média | Nível médio de amplitude | Intensidade global |

---

## 5️⃣ Porque usar várias características e não apenas uma

Este é um ponto muito importante para a defesa.

Nenhuma feature isolada consegue, em geral, separar perfeitamente todos os dígitos. Isso acontece porque a voz humana tem:
- variabilidade natural;
- semelhanças fonéticas entre certas palavras;
- sobreposição entre classes.

### A ideia correta é:
> **cada característica captura uma perspetiva diferente do sinal**.

- as temporais captam **dinâmica e intensidade ao longo do tempo**;
- as espectrais captam **composição em frequência**;
- as medidas de dispersão captam **estabilidade e variabilidade**.

Ou seja, o valor está na **combinação das features**, não numa feature única.

---

## 6️⃣ O que os gráficos mostram, em termos de interpretação

Pelo conjunto de gráficos produzidos, a leitura mais forte para a defesa é:

### Temporalmente
- alguns dígitos apresentam padrões energéticos mais concentrados;
- outros mostram maior dispersão;
- há diferenças visíveis entre grupos, embora com alguma sobreposição.

### Espectralmente
- certos dígitos tendem a ocupar regiões diferentes em frequência;
- o centroide, o spectral edge e a entropia ajudam a ver essas diferenças;
- essas features tornam a caracterização mais rica do que olhar só para a waveform.

### No gráfico 3D
Ao combinar múltiplas features, observa-se melhor a organização das amostras no espaço das características.  
Mesmo que não haja separação perfeita, já existe uma **estrutura mensurável**, o que é exatamente o objetivo desta meta.

---

## 7️⃣ Leitura crítica: o que correu bem e o que pode ser melhorado

### Pontos fortes
- pipeline completo e coerente;
- features temporais e espectrais relevantes;
- análise exploratória bem fundamentada;
- criação de base para classificação futura.

### Limitações
- algumas features mostram sobreposição entre dígitos;
- faltam métricas quantitativas de separação entre classes;
- a análise ainda é exploratória, não classificatória.

---

## 8️⃣ Como defender as escolhas metodológicas

Se te perguntarem **“porque escolheram estas características?”**, uma boa resposta é:

> “Escolhemos características com interpretação física e estatística clara. As temporais descrevem intensidade e evolução ao longo do sinal, enquanto as espectrais descrevem a distribuição da energia em frequência. Em conjunto, permitem caracterizar melhor cada dígito e reduzir a dependência de uma única medida.”

Se perguntarem **“qual foi a principal contribuição da Meta 1?”**, podes dizer:

> “A principal contribuição foi transformar gravações de voz em variáveis objetivas e comparáveis, mostrando que os dígitos têm assinaturas temporais e espectrais identificáveis.”

---

## 9️⃣ Conclusão forte para apresentação

> “A Meta 1 demonstrou que é possível representar cada gravação de voz através de um conjunto de características relevantes, tanto no domínio do tempo como no da frequência. Estas características não garantem separação perfeita individualmente, mas em conjunto revelam estrutura suficiente para suportar análises mais avançadas, como classificação ou redução de dimensionalidade.”

---

## 🧠 Frase final para soar bem na defesa
> “Mais do que observar sinais, nesta meta passámos a descrevê-los quantitativamente.”
