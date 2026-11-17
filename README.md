```markdown
# PPG-Based Heart Rate Estimation Using TROIKA-Inspired Signal Processing

## 1. Project Overview
This project implements and evaluates a Photoplethysmography (PPG)-based heart rate estimation pipeline inspired by the TROIKA algorithm proposed by Zhang et al. (2015).
The project investigates signal filtering, Singular Spectrum Analysis (SSA), sparse signal reconstruction using M-FOCUSS, and spectral peak selection for estimating heart rate from wrist-type PPG signals.
Two PPG channels are processed independently. The proposed methods are compared against a conventional FFT-based baseline using reference heart rate labels.
**Objective:** To investigate whether SSA-based preprocessing and sparse spectral reconstruction improve heart rate estimation compared with conventional FFT-based estimation.

*Implementation note: This is a TROIKA-inspired implementation, not an exact reproduction of the original TROIKA algorithm. The current version does not implement the complete temporal spectral peak tracking and verification mechanism.*


## 2. Dataset
This project uses the publicly available IEEEPPG Dataset, derived from the IEEE Signal Processing Cup 2015 heart rate monitoring dataset.

**Dataset download**
Official dataset repository:
IEEEPPG Dataset – Zenodo
Download the following two files:
* IEEEPPG_TRAIN.ts
* IEEEPPG_TEST.ts

The dataset contains two wrist-based PPG signals and three-axis accelerometer signals. Reference heart rate values are provided as regression targets.

**Dataset specifications**

| Parameter | Value |
| :--- | :--- |
| Sampling frequency | 125 Hz |
| Samples per record | 1000 |
| Duration per record | 8 seconds |
| TRAIN records | 1768 |
| TEST records | 1328 |
| PPG channels | 2 |
| Accelerometer channels | 3 |
| Target | Heart rate (BPM) |

The dataset uses an 8-second window with 6 seconds of overlap, corresponding to a 2-second step between consecutive windows in the original data construction.

**Dataset citation**
Tan, C. W., Bergmeir, C., Petitjean, F., and Webb, G. I. (2020). IEEEPPG Dataset. Zenodo.
Dataset DOI: 10.5281/zenodo.3902710


## 3. Project Structure
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
│
├── phase3_ssa_preprocessing_all_records.m
├── phase3A_validate_ssa_results.m
├── phase3A_diagnose_hr_errors.m
│
├── phase4_mfocuss_reconstruction.m
├── phase5_spectral_peak_tracking.m
│
├── phase6_performance_evaluation.m
├── phase6A_hr_estimation_diagnosis.m
│
├── phase7_baseline_channel_comparison.m
├── phase8_final_evaluation.m
├── phase9_generate_final_report.m
│
├── Phase3_SSA_Preprocessing_Results.mat
├── Phase4_MFOCUSS_Results.mat
├── Phase5_HR_Estimation_Results.mat
├── Phase6A_HR_Diagnosis_Results.mat
├── Phase7_Comparison_Results.mat
├── Phase7_Comparison_Results.csv
│
└── README.md

```

Generated result files are created when the corresponding MATLAB scripts are executed. They do not need to be downloaded separately.

## 4. Methodology

The project consists of the following processing stages.

**Phase 1: Dataset Loading**
The TRAIN and TEST datasets are loaded separately.
The following signals are extracted:

* PPG Channel 1
* PPG Channel 2
* Accelerometer X-axis
* Accelerometer Y-axis
* Accelerometer Z-axis
* Reference heart rate

Each record contains 1000 samples.

**Phase 2: Signal Filtering**
Butterworth bandpass filtering is applied to reduce baseline variations and unwanted frequency components.
The filtered PPG signals are used as inputs to the subsequent preprocessing stages.

**Phase 3: SSA-Based Signal Preprocessing**
Singular Spectrum Analysis (SSA) is used to decompose and reconstruct the PPG signals.
The implemented procedure includes:

* Construction of a trajectory matrix.
* Singular Value Decomposition (SVD).
* Approximate grouping of components based on adjacent frequency characteristics.
* Signal reconstruction.
* Acceleration-frequency-based component removal.
* Second-order differencing.

The resulting preprocessed signals are saved for further processing.
*Note: The current SSA grouping is an approximate implementation and has not been verified as identical to the singular-value grouping procedure in the original TROIKA paper.*

**Phase 4: M-FOCUSS Sparse Reconstruction**
A Fourier dictionary is constructed over the selected frequency range.
A regularized FOCUSS-inspired iterative reconstruction method is used to obtain sparse spectral representations of the preprocessed PPG signals.
The reconstructed spectra are passed to the heart rate estimation stage.
*Note: The current M-FOCUSS implementation is a regularized variant and has not been independently verified against the complete mathematical formulation of the original TROIKA algorithm.*

**Phase 5: Spectral Peak Selection and Heart Rate Estimation**
The reconstructed spectrum is used to estimate the dominant heart rate frequency.
The physiological heart rate search range is:
Heart rate range:


$$42 \leq HR \leq 210 \text{ BPM}$$


Equivalent frequency range:


$$0.7 \leq f \leq 3.5 \text{ Hz}$$


The frequency range is obtained using:


$$f = \frac{HR}{60}$$


Within this frequency range, candidate spectral peaks are identified and evaluated using spectral power and fundamental/harmonic scoring.
The candidate with the highest score is selected as the estimated heart rate frequency.
The selected frequency is converted into BPM using:


$$\widehat{HR} = 60f_{\text{selected}}$$


where:

* $\widehat{HR}$ is the estimated heart rate in BPM.
* $f_{\text{selected}}$ is the selected spectral frequency in Hz.

The current implementation performs spectral peak selection independently for each record.
*Important: This stage does not implement the complete temporal peak tracking, peak verification, or recovery procedure of the original TROIKA algorithm. The filename is retained for consistency with the project scripts, but the implemented operation is independent spectral peak selection rather than complete temporal tracking.*

**Phase 6: Performance Evaluation**
The estimated heart rates are compared with the corresponding reference heart rate labels.
Evaluation is performed separately for:

* TRAIN Channel 1
* TRAIN Channel 2
* TEST Channel 1
* TEST Channel 2

The following metrics are calculated.

**Mean Absolute Error (MAE)**
MAE measures the average absolute difference between estimated and reference heart rates.


$$MAE = \frac{1}{N}\sum_{i=1}^{N} \left\vert{}HR_i-\widehat{HR}_i\right\vert{}$$

**Root Mean Square Error (RMSE)**
RMSE measures the square root of the average squared estimation error.


$$RMSE = \sqrt{ \frac{1}{N}\sum_{i=1}^{N} (HR_i-\widehat{HR}_i)^2 }$$

**Bias**
Bias measures the average signed estimation error.


$$Bias = \frac{1}{N}\sum_{i=1}^{N} (\widehat{HR}_i-HR_i)$$


A positive bias indicates overestimation, while a negative bias indicates underestimation.

**Pearson Correlation**
Pearson correlation measures the linear relationship between reference and estimated heart rates.


$$r = \frac{\operatorname{cov}(HR,\widehat{HR})} {\sigma_{HR}\sigma_{\widehat{HR}}}$$


where $\sigma$ represents standard deviation.
Lower MAE and RMSE indicate better estimation accuracy. Bias closer to zero indicates lower average systematic error. A higher positive correlation indicates a stronger positive linear relationship.

## 5. Experimental Results

Three methods are compared:

* **Baseline FFT:** Conventional FFT-based heart rate estimation using the original PPG signals.
* **SSA + FFT:** FFT-based estimation using SSA-preprocessed, second-differenced PPG signals.
* **SSA + M-FOCUSS:** Sparse spectral reconstruction followed by spectral peak selection using the SSA-preprocessed signals.

### 5.1 TRAIN Results

| Group | Method | MAE (BPM) | RMSE (BPM) | Bias (BPM) | Correlation |
| --- | --- | --- | --- | --- | --- |
| Channel 1 | Baseline FFT | 15.478 | 29.398 | -1.270 | 0.4803 |
| Channel 1 | SSA + FFT | 20.024 | 37.154 | 19.309 | 0.0297 |
| Channel 1 | SSA + M-FOCUSS | 18.715 | 32.336 | 13.080 | 0.0755 |
| Channel 2 | Baseline FFT | 22.833 | 33.507 | 1.492 | 0.3944 |
| Channel 2 | SSA + FFT | 24.550 | 37.840 | 23.836 | 0.0787 |
| Channel 2 | SSA + M-FOCUSS | 21.754 | 32.884 | 14.962 | 0.0380 |

### 5.2 TEST Results

| Group | Method | MAE (BPM) | RMSE (BPM) | Bias (BPM) | Correlation |
| --- | --- | --- | --- | --- | --- |
| Channel 1 | Baseline FFT | 21.909 | 37.415 | 0.287 | 0.5147 |
| Channel 1 | SSA + FFT | 51.425 | 67.554 | 49.012 | -0.1613 |
| Channel 1 | SSA + M-FOCUSS | 42.776 | 57.842 | 37.783 | -0.1542 |
| Channel 2 | Baseline FFT | 26.075 | 38.925 | -3.947 | 0.4764 |
| Channel 2 | SSA + FFT | 52.832 | 67.518 | 49.057 | -0.1156 |
| Channel 2 | SSA + M-FOCUSS | 42.583 | 57.067 | 37.692 | -0.1274 |

### 5.3 TEST Performance Comparison

| Method | Channel 1 MAE | Channel 2 MAE |
| --- | --- | --- |
| Baseline FFT | 21.909 | 26.075 |
| SSA + FFT | 51.425 | 52.832 |
| SSA + M-FOCUSS | 42.776 | 42.583 |

The conventional FFT baseline achieved the lowest MAE on both TEST channels.

### 5.4 Key Observations

* Baseline FFT achieved the best TEST performance for both PPG channels.
* Baseline FFT showed near-zero average bias on both TEST channels.
* SSA + M-FOCUSS improved upon SSA + FFT in terms of MAE and RMSE on both TEST channels.
* Both SSA-based methods showed substantial positive bias and negative correlation on the TEST dataset.
* Channel 1 performed better than Channel 2 for all three methods on TEST.
* The current SSA-based preprocessing and sparse reconstruction pipeline did not outperform conventional FFT estimation.

These results indicate that the implemented SSA-based processing requires further refinement before it can provide a reliable improvement over the baseline.

## 6. How to Reproduce the Results

### 6.1 Requirements

* MATLAB
* IEEEPPG TRAIN and TEST dataset files
* MATLAB toolboxes required by the functions used in the scripts, including Signal Processing Toolbox if required by your MATLAB implementation.

### 6.2 Download the Dataset

Download the dataset from:
https://zenodo.org/records/3902710
Place the downloaded files in the project directory as follows:

```text
PPG_PROJECT/
│
├── TRAIN/
│   └── IEEEPPG_TRAIN.ts
│
└── TEST/
    └── IEEEPPG_TEST.ts

```

### 6.3 Configure the Project Path

Open the MATLAB scripts and set the project directory:
`baseFolder = 'YOUR_PATH/PPG_PROJECT';`
Use `fullfile` to construct file paths so the scripts can be run from different computers after updating the project directory.

### 6.4 Execute the MATLAB Scripts

Run the scripts in the following order.

| Order | MATLAB script | Purpose |
| --- | --- | --- |
| 1 | step1_load_dataset.m | Load TRAIN and TEST data |
| 2 | step2_filtering.m | Filter PPG signals |
| 3 | phase3_ssa_preprocessing_all_records.m | SSA preprocessing |
| 4 | phase3A_validate_ssa_results.m | Validate provisional SSA estimates |
| 5 | phase3A_diagnose_hr_errors.m | Diagnose SSA estimation errors |
| 6 | phase4_mfocuss_reconstruction.m | Sparse spectral reconstruction |
| 7 | phase5_spectral_peak_tracking.m | Independent spectral peak selection and HR estimation |
| 8 | phase6_performance_evaluation.m | Calculate HR estimation metrics |
| 9 | phase6A_hr_estimation_diagnosis.m | Diagnose estimation errors |
| 10 | phase7_baseline_channel_comparison.m | Compare baseline and SSA-based methods |
| 11 | phase8_final_evaluation.m | Evaluate final TEST performance |
| 12 | phase9_generate_final_report.m | Generate the final report summary |

**Execution notes:**

* Run the scripts in the listed order because later phases depend on saved outputs from earlier phases.
* Run `step1_load_dataset.m` before loading other MAT files when a later script needs the original reference labels. This is important because the dataset-loading script may clear existing workspace variables.
* Check that each phase has generated its required MAT file before proceeding to the next phase.
* Update `baseFolder` to match the local project directory on your computer.
* The final results are calculated using the supplied reference labels; do not tune the method using TEST labels.

### 6.5 Expected Outputs

The project generates intermediate and final MATLAB result files, including:

* Phase3_SSA_Preprocessing_Results.mat
* Phase4_MFOCUSS_Results.mat
* Phase5_HR_Estimation_Results.mat
* Phase6A_HR_Diagnosis_Results.mat
* Phase7_Comparison_Results.mat
* Phase7_Comparison_Results.csv
* Phase8_Final_Evaluation.mat
* Phase8_Final_Evaluation.csv
* Phase9_Final_Report_Summary.txt

The Phase 7 comparison also generates:

* Phase7_MAE_Comparison.png
* Phase7_RMSE_Comparison.png

The exact files generated depend on the save commands in the individual MATLAB scripts.

## 7. Limitations

* **Approximate SSA grouping:** The implemented grouping procedure has not been verified as mathematically identical to the original TROIKA approach.
* **M-FOCUSS formulation:** The regularized sparse reconstruction implementation requires further verification against the original mathematical formulation.
* **Independent spectral selection:** The current Phase 5 implementation does not include complete temporal peak tracking and verification.
* **Motion artefact suppression:** Accelerometer-assisted processing has not been established as equivalent to the original TROIKA motion artefact suppression method.
* **Estimation accuracy:** The current SSA-based methods show high positive bias and poor TEST correlation.
* **Sequence continuity:** Temporal tracking requires valid sequence and subject boundaries. Adjacent dataset rows should not automatically be assumed to represent consecutive windows.

## 8. Future Improvements

* Implement the original SSA grouping and reconstruction procedure more faithfully.
* Verify the M-FOCUSS equations, dictionary construction and regularization parameters.
* Implement temporal spectral peak tracking.
* Add peak verification and recovery mechanisms.
* Improve accelerometer-assisted motion artefact suppression.
* Establish valid record sequences and subject boundaries before temporal tracking.
* Evaluate the improved implementation using the independent TEST dataset.
* Compare the improved pipeline against the conventional FFT baseline.

## 9. References

**Original TROIKA Paper**
Zhang, Z., Pi, Z., and Liu, B. (2015).
TROIKA: A General Framework for Heart Rate Monitoring Using Wrist-Type Photoplethysmographic Signals During Intensive Physical Exercise.
IEEE Transactions on Biomedical Engineering, 62(2), 522–531.
DOI: 10.1109/TBME.2014.2359372

**Dataset**
Tan, C. W., Bergmeir, C., Petitjean, F., and Webb, G. I. (2020).
IEEEPPG Dataset.
Zenodo.
https://doi.org/10.5281/zenodo.3902710

## 10. Conclusion

This project investigates PPG-based heart rate estimation using a TROIKA-inspired signal processing pipeline.
The implemented system includes Butterworth filtering, SSA-based preprocessing, regularized M-FOCUSS-inspired sparse reconstruction, spectral peak selection, and performance evaluation.
Three approaches were compared using TRAIN and independent TEST records.
The experimental results show that conventional FFT-based estimation achieved better TEST performance than the current SSA-based implementations.
Although the current pipeline does not reproduce every stage of the original TROIKA algorithm, it provides a foundation for investigating signal decomposition, sparse reconstruction, motion artefact suppression, and temporal heart rate tracking.
The next major development step is implementing temporal spectral peak tracking and verification to bring the proposed system closer to the original TROIKA framework.

```

```
