# PPG-Based Heart Rate Estimation Using TROIKA-Inspired Signal Processing

## Overview

This project implements and evaluates a Photoplethysmography (PPG)-based heart rate estimation pipeline inspired by the TROIKA algorithm proposed by Zhang et al. (2015).

The project investigates signal preprocessing, Singular Spectrum Analysis (SSA), sparse signal reconstruction using M-FOCUSS, and spectral peak selection for estimating heart rate from PPG signals.

Two PPG channels are evaluated independently, and the performance of the proposed processing pipeline is compared against a conventional FFT-based baseline.

The primary objective is to understand how signal decomposition and sparse reconstruction affect heart rate estimation under motion-corrupted PPG signals.

> **Note:** This is a TROIKA-inspired implementation, not an exact reproduction of the original algorithm. In particular, the current implementation does not include the complete temporal spectral peak tracking and verification mechanism.

---

## Dataset

The project uses a PPG dataset containing two PPG channels, three-axis accelerometer measurements, and reference heart rate values.

| Parameter | Value |
|---|---|
| Sampling frequency | 125 Hz |
| Samples per record | 1000 |
| Duration per record | 8 seconds |
| TRAIN records | 1768 |
| TEST records | 1328 |
| PPG channels | 2 |
| Accelerometer channels | 3 |
| Reference output | Heart rate (BPM) |

### Dataset organization

```text
PPG_PROJECT/
│
├── TRAIN/
│   └── IEEEPPG_TRAIN.ts
│
├── TEST/
│   └── IEEEPPG_TEST.ts
│
├── step1_load_dataset.m
├── step2_filtering.m
├── phase3_ssa_preprocessing_all_records.m
├── phase3A_validate_ssa_results.m
├── phase3A_diagnose_hr_errors.m
├── phase4_mfocuss_reconstruction.m
├── phase5_spectral_peak_tracking.m
├── phase6_performance_evaluation.m
├── phase6A_hr_estimation_diagnosis.m
├── phase7_baseline_channel_comparison.m
├── phase8_final_evaluation.m
└── phase9_generate_final_report.m
```

The dataset files are expected to be available locally. They are not necessarily included in this repository.

---

## Methodology

The implemented pipeline consists of the following stages.

### 1. Dataset Loading

The TRAIN and TEST datasets are loaded separately.

The following signals are extracted:

- PPG Channel 1
- PPG Channel 2
- Accelerometer X-axis
- Accelerometer Y-axis
- Accelerometer Z-axis
- Reference heart rate

Each record contains 1000 samples, corresponding to an 8-second PPG window.

### 2. Signal Filtering

Butterworth bandpass filtering is applied to reduce unwanted low-frequency baseline variations and high-frequency noise.

The filtering stage prepares the PPG signals for subsequent decomposition and spectral analysis.

### 3. SSA-Based Signal Preprocessing

Singular Spectrum Analysis (SSA) is used as a signal decomposition and preprocessing technique.

The implemented procedure includes:

1. Constructing a trajectory matrix.
2. Performing singular value decomposition.
3. Grouping components using approximate adjacent-frequency grouping.
4. Reconstructing the processed PPG signal.
5. Applying acceleration-frequency-based component removal.
6. Applying second-order differencing.

The resulting signals are stored for subsequent reconstruction and heart rate estimation.

**Important:** The current SSA grouping is an approximate implementation and has not been verified as identical to the original TROIKA singular-value grouping procedure.

### 4. M-FOCUSS Sparse Signal Reconstruction

A Fourier dictionary is constructed over the selected frequency range.

M-FOCUSS-inspired iterative sparse reconstruction is applied to the preprocessed PPG signals.

The implementation uses:

- Fourier dictionary representation
- Iterative coefficient weighting
- Regularized matrix updates
- Sparse spectral reconstruction

The reconstructed spectra are used for subsequent heart rate estimation.

**Important:** The implemented regularized FOCUSS variant has not been independently verified against every mathematical detail of the original TROIKA formulation.

### 5. Spectral Peak Selection and HR Estimation

The reconstructed spectrum is analyzed within the physiological heart rate search range.

The search range is:

\[
42 \leq HR \leq 210 \text{ BPM}
\]

Equivalent frequency range:

\[
0.7 \leq f \leq 3.5 \text{ Hz}
\]

The current implementation selects candidate peaks using spectral power and fundamental/harmonic scoring.

The selected frequency is converted into heart rate:

\[
HR = 60f
\]

The current version estimates each record independently. It does not implement the complete temporal peak tracking and verification stage of the original TROIKA algorithm.

### 6. Performance Evaluation

Estimated heart rates are compared with reference heart rate labels using:

**Mean Absolute Error (MAE)**

\[
MAE = \frac{1}{N}\sum_{i=1}^{N}|HR_i-\widehat{HR}_i|
\]

**Root Mean Square Error (RMSE)**

\[
RMSE = \sqrt{\frac{1}{N}\sum_{i=1}^{N}(HR_i-\widehat{HR}_i)^2}
\]

**Bias**

\[
Bias = \frac{1}{N}\sum_{i=1}^{N}(\widehat{HR}_i-HR_i)
\]

**Pearson Correlation**

Measures the linear relationship between reference and estimated heart rate.

Lower MAE and RMSE indicate better estimation performance. Bias closer to zero indicates lower average systematic error.

---

## Experimental Results

Three methods were evaluated:

1. **Baseline FFT:** Conventional FFT-based heart rate estimation using the original PPG signals.
2. **SSA + FFT:** SSA-preprocessed signals followed by FFT-based estimation.
3. **SSA + M-FOCUSS:** SSA preprocessing followed by sparse reconstruction and spectral peak selection.

### TRAIN Results

| Group | Method | MAE (BPM) | RMSE (BPM) | Bias (BPM) | Correlation |
|---|---|---:|---:|---:|---:|
| Channel 1 | Baseline FFT | 15.478 | 29.398 | -1.270 | 0.4803 |
| Channel 1 | SSA + FFT | 20.024 | 37.154 | 19.309 | 0.0297 |
| Channel 1 | SSA + M-FOCUSS | 18.715 | 32.336 | 13.080 | 0.0755 |
| Channel 2 | Baseline FFT | 22.833 | 33.507 | 1.492 | 0.3944 |
| Channel 2 | SSA + FFT | 24.550 | 37.840 | 23.836 | 0.0787 |
| Channel 2 | SSA + M-FOCUSS | 21.754 | 32.884 | 14.962 | 0.0380 |

### TEST Results

| Group | Method | MAE (BPM) | RMSE (BPM) | Bias (BPM) | Correlation |
|---|---|---:|---:|---:|---:|
| Channel 1 | Baseline FFT | **21.909** | **37.415** | **0.287** | **0.5147** |
| Channel 1 | SSA + FFT | 51.425 | 67.554 | 49.012 | -0.1613 |
| Channel 1 | SSA + M-FOCUSS | 42.776 | 57.842 | 37.783 | -0.1542 |
| Channel 2 | Baseline FFT | **26.075** | **38.925** | **-3.947** | **0.4764** |
| Channel 2 | SSA + FFT | 52.832 | 67.518 | 49.057 | -0.1156 |
| Channel 2 | SSA + M-FOCUSS | 42.583 | 57.067 | 37.692 | -0.1274 |

---

## Performance Comparison

### TEST MAE Comparison

| Method | Channel 1 | Channel 2 |
|---|---:|---:|
| Baseline FFT | **21.909** | **26.075** |
| SSA + FFT | 51.425 | 52.832 |
| SSA + M-FOCUSS | 42.776 | 42.583 |

The conventional FFT baseline achieved the lowest MAE on both TEST channels.

### Best Performing Method

**TEST Channel 1**

- Best method: Baseline FFT
- MAE: 21.909 BPM
- RMSE: 37.415 BPM
- Bias: +0.287 BPM
- Correlation: 0.5147

**TEST Channel 2**

- Best method: Baseline FFT
- MAE: 26.075 BPM
- RMSE: 38.925 BPM
- Bias: -3.947 BPM
- Correlation: 0.4764

### Key Observations

1. Baseline FFT outperformed both SSA-based methods on the independent TEST dataset.
2. Baseline FFT demonstrated near-zero average bias on both TEST channels.
3. SSA + M-FOCUSS improved upon SSA + FFT in terms of MAE and RMSE on both TEST channels.
4. Both SSA-based methods showed substantial positive bias and negative correlation on the TEST dataset.
5. Channel 1 achieved better baseline performance than Channel 2 on TEST.
6. The current SSA and sparse reconstruction stages did not provide an improvement over conventional FFT estimation.

These results suggest that the current preprocessing and reconstruction implementation may be removing useful pulse information or retaining misleading spectral components.

---

## Implementation Limitations

The current implementation has several limitations that should be considered when interpreting the results.

### 1. Approximate SSA Grouping

The SSA grouping procedure is an approximate implementation and may not reproduce the original TROIKA decomposition and grouping strategy exactly.

### 2. M-FOCUSS Formulation

The regularized FOCUSS implementation has not been independently verified against the exact equations and parameter choices in the original paper.

### 3. Missing Temporal Peak Tracking

The current spectral peak selection operates independently on each record.

The original TROIKA algorithm uses temporal information to track heart rate across consecutive windows and verify selected spectral peaks.

This is an important missing component.

### 4. Motion Artefact Handling

Although accelerometer information is used during preprocessing, the complete motion artefact suppression mechanism has not been verified as equivalent to the original TROIKA implementation.

### 5. Estimation Accuracy

The SSA-based methods show high positive bias and poor TEST correlations. Further improvements are required before the proposed pipeline can outperform the baseline.

### 6. Dataset Sequence Information

The continuity and subject boundaries of the records have not been established. Therefore, temporal tracking should not be applied across adjacent rows without first identifying valid consecutive windows and sequence boundaries.

---

## Future Improvements

The following improvements are planned:

- Implement mathematically faithful SSA decomposition and singular-value grouping.
- Verify and refine the M-FOCUSS formulation against the original paper.
- Implement temporal spectral peak tracking.
- Add peak verification and recovery mechanisms.
- Improve accelerometer-assisted motion artefact suppression.
- Establish valid record sequences and subject boundaries before temporal tracking.
- Evaluate the improved pipeline on the independent TEST dataset.
- Compare results with the conventional FFT baseline.

---

## References

Zhang, Z., Pi, Z., and Liu, B. (2015).

**TROIKA: A General Framework for Heart Rate Monitoring Using Wrist-Type Photoplethysmographic Signals During Intensive Physical Exercise.**

IEEE Transactions on Biomedical Engineering.

DOI: [10.1109/TBME.2014.2359372](https://doi.org/10.1109/TBME.2014.2359372)

---

## Conclusion

This project implements a TROIKA-inspired PPG heart rate estimation pipeline incorporating signal filtering, SSA-based preprocessing, M-FOCUSS-inspired sparse reconstruction, and spectral peak selection.

Three estimation approaches were experimentally compared using TRAIN and independent TEST records.

The results show that conventional FFT-based estimation achieved better performance than the current SSA-based implementations on the TEST dataset.

Although the implemented pipeline does not yet reproduce the complete TROIKA algorithm, it provides a foundation for investigating signal decomposition, sparse reconstruction, motion artefact suppression, and temporal heart rate tracking.

The next major development step is implementing temporal spectral peak tracking and verification to bring the system closer to the original TROIKA framework.
