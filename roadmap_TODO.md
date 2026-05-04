# 📊 Projeto ATD – Roadmap de Melhoria

## 🎯 Objetivo

Melhorar a taxa de acerto (accuracy) do classificador de dígitos a partir de sinais de áudio, tornando as features mais discriminativas e o modelo mais robusto.

---

## 🚨 Problema Atual

* Features demasiado **globais (média do espectro)**
* Perda de **informação temporal**
* Algumas features **pouco úteis ou instáveis** (ex: peakFreq)
* Classificador ok, mas limitado pelas features

---

## 🧱 Fase 1 – Limpeza e Correção (OBRIGATÓRIO)

### 1. Remover features fracas

* ❌ Remover `peakFreq`
* ❌ Evitar features quase constantes

### 2. Garantir consistência

* Confirmar que `X` usa **as features mais recentes**
* Confirmar `zscore` aplicado corretamente

---

## ⚡ Fase 2 – Melhorar Features (MAIS IMPORTANTE)

### 3. Introduzir estrutura temporal na STFT

* Dividir espectrograma em:

  * início
  * meio
  * fim
* Calcular por região:

  * centroide espectral
  * entropia espectral
  * energia

👉 Resultado: múltiplas features por áudio (não só 1 valor)

---

### 4. Usar features já existentes (Meta 1)

* `energy_intervalos` (MUITO IMPORTANTE)
* características temporais já calculadas

👉 Estas já têm informação temporal → usar SEMPRE

---

### 5. Integrar Wavelet (DWT)

* Usar:

  * `AproxEnergy`
  * `DetailEnergy`

👉 Acrescenta informação multi-resolução

---

## 🧠 Fase 3 – Construção do Feature Set

### 6. Combinar features

Exemplo recomendado:

```matlab
X = [
    energy_intervalos, ...
    specCentroid_dividido, ...
    specEntropy_dividido, ...
    AproxEnergy, ...
    DetailEnergy
];
```

👉 Objetivo: combinar

* tempo
* frequência
* tempo-frequência

---

## 🤖 Fase 4 – Classificação

### 7. Manter Minimum Distance (base)

* Já suficiente para boa nota

### 8. (Opcional) Testar outros modelos

* k-NN
* Decision Tree

👉 Só se quiseres melhorar resultados finais

---

## 📊 Fase 5 – Avaliação

### 9. Analisar resultados

* Accuracy global
* Confusion patterns (quais dígitos falham mais)

### 10. Validar features

* Boxplots
* Scatter plots (2D/3D)

👉 Escolher features com melhor separação

---

## 🧪 Fase 6 – Ajustes Finais

* Ajustar:

  * tamanho da janela STFT
  * overlap
  * nfft

👉 Pequenos ganhos de performance

---

## 🎯 Objetivo Final

| Nível     | Accuracy |
| --------- | -------- |
| Básico    | 60–70%   |
| Bom       | 75–85%   |
| Muito bom | 85–90%   |

---

## 💡 Prioridade (se tiver pouco tempo)

1. ✅ Usar `energy_intervalos`
2. ✅ Dividir STFT no tempo
3. ✅ Remover `peakFreq`
4. ✅ Combinar features

👉 Só isto já melhora MUITO

---

## 🧠 Nota Final

O problema não está no classificador —
está na qualidade das features.

Melhores features = melhor accuracy.

---
