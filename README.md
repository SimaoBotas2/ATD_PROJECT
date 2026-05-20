# ATD Project — Spoken Digit Recognition

Author: Simão Tomás Botas Carvalho

Academic project for the **Análise e Transformação de Dados** (Data Analysis and Transformation) course, 3rd year / Bachelor's in Informatics.

The goal is to classify spoken digits (0–9) from audio recordings using signal processing and feature selection and machine learning techniques in MATLAB.

## Dataset

The project uses the **Audio MNIST** dataset — 30,000 `.wav` recordings of spoken digits (0–9) from 60 speakers, each repeating every digit 50 times, sampled at 48 kHz mono.

**Download:** https://www.kaggle.com/datasets/sripaadsrinivasan/audio-mnist/download?datasetVersionNumber=1

After downloading, extract the archive and place only the raw signal files (the `data/` subdirectories) into the `data_raw/` folder of this project. Additional references:
- GitHub: https://github.com/soerenab/AudioMNIST
- Kaggle: https://www.kaggle.com/datasets/sripaadsrinivasan/audio-mnist
- Paper: https://arxiv.org/abs/1807.03418

Files follow the naming pattern `<digit>_<speaker>_<repetition>.wav`. Processed outputs are written to `data_processed/`.

## Project Structure

```
src/
  meta1/          # Milestone 1 — preprocessing & feature extraction
  meta2/          # Milestone 2 — time-frequency analysis & classification
data_raw/         # Raw .wav recordings
data_processed/   # Generated .mat feature files (gitignored)
docs/             # Project specification PDF
```

## Milestones

### Meta 1 — Signal Preprocessing & Feature Extraction (`src/meta1/`)

Entry point: `meta1_main.m`

1. Load all `.wav` files into a structured table (`getDataFromFiles`)
2. Preprocess signals: remove leading silence, normalize to `[-1, 1]`, equalize to a fixed duration (`processData`)
3. Extract temporal features per signal segment (`compareDigitsFeatures`)
4. Compute FFT and spectral features: spectral centroid, bandwidth, entropy (`getSpectralFeatures`)
5. Save intermediate `.mat` files to `data_processed/`

### Meta 2 — Time-Frequency Analysis & Classification (`src/meta2/`)

Entry point: `main2_main.m`

1. Compute STFT spectrograms for each digit (window=256, 50% overlap)
2. Extract time-frequency features per temporal region (start / mid / end): spectral centroid, entropy, energy
3. Apply Discrete Wavelet Transform (DWT, `db4`, level 1) — approximate and detail energies
4. Classify digits using **k-NN** (k=4, Euclidean distance, 70/30 train-test split)
5. Evaluate with confusion matrix and per-digit accuracy

## Running

Open MATLAB and run from the project root:

```matlab
% Meta 1
addpath(genpath('src/meta1'))
meta1_main()

% Meta 2 (requires meta1 outputs)
cd src/meta2
main2_main
```

Key options for `meta1_main` (name-value pairs):

| Parameter | Default | Description |
|---|---|---|
| `SignalLengthSec` | `0.5` | Fixed signal duration after preprocessing |
| `Divisions` | `3` | Temporal segments for feature extraction |
| `PlotTemporal` | `true` | Plot raw vs processed waveforms |
| `PlotSpectral` | `true` | Plot spectral quartiles per digit |
| `ComputeSpectral` | `true` | Run FFT and spectral feature extraction |

## Requirements

- MATLAB R2021b or later
- Signal Processing Toolbox (for `spectrogram`, `dwt`)
- Wavelet Toolbox (for `dwt`)
- Statistics and Machine Learning Toolbox (for `fitcknn`, `cvpartition`)
