# Quartz BOSL relative sensitivity of Tn signals

## Scope and intended use

This R script is intended for researchers working with quartz OSL data who wish to derive sensitivity-related parameters and investigate CW-OSL signal components for sediment provenance studies.
It is designed to reuse data acquired during OSL dating (stored in as .binx file) for sediment provenance analysis, potentially avoiding additional sampling or measurements when the required data are already available.

This code accompanies the paper:

> Souza, P.E., Pupim, F.N., Mazoca, C.E.M., del Río, I., Mineli, T.D., Rodrigues, F.C.G., Porat, N., Hartmann, G.A., Sawakuchi, A.O. (2023). Quartz OSL sensitivity from dating data for provenance analysis of Pleistocene and Holocene fluvial sediments from lowland Amazonia. *Quaternary Geochronology*, 74, 101422. https://doi.org/10.1016/j.quageo.2023.101422

## Methodology

The calculations implemented in this script follow the methodology described in Souza et al., 2023 (https://doi.org/10.1016/j.quageo.2023.101422):

- The BOSL signal analyzed is the signal from the first test dose in a SAR OSL dating sequence.
- %BOSL<sub>F</sub> is calculated as the ratio between the net signal integrated over the first second of BOSL stimulation and the net signal integrated over the full stimulation time.
- Net signals are calculated using a late-background subtraction, with the background estimated from the last 10 s of the BOSL signal.
- CW-OSL signal deconvolution is performed using the `fit_CWCurve()` function (Kreutzer, 2020), available in the `Luminescence` R package.

## What it does

- Reads quartz OSL signals from `.binx` files (Risø TL/OSL reader format)
- Calculates %BOSL<sub>F</sub> sensitivity (ratio of the fast OSL component to the total OSL signal), filtering out aliquots below a background threshold ("dim" aliquots)
- Deconvolutes the CW-OSL decay curve into fast, medium, and slow components using `Luminescence::fit_CWCurve()`
- Exports per-aliquot results (sensitivity values and component proportions) to Excel or CSV

## Requirements

- R (>= 4.0.0)
- Required packages:
  ```r
  install.packages(c("Luminescence", "openxlsx", "dplyr"))
  ```

## Installation

Clone this repository:

```bash
git clone https://github.com/priesouza/Calculating_BOSL_Relative_Sensitivity.git
cd Calculating_BOSL_Relative_Sensitivity
```

## Usage

This script is not organized as a callable function — it is meant to be edited and run as a whole.

1. Open `Tn_OSL_sensitivity.R` in RStudio.
2. Edit the parameters at the top of the script (lines 4–34) to match your data and settings:
   - `output_file`: name of the output file (without extension)
   - `exporting.format`: `"Excel"` or `"csv"`
   - `path`: folder containing the input `.binx` file; it can be selected by using either the RStudio function (line  11) or by specifying it manually (line 16)
   - `sample`: name of the `.binx` file to analyze; it can be selected by using either the RStudio function (line  13) or by specifying it manually (line 18)
   - `mode`: `"horizontally"` or `"vertically"`, depending on how the measurement sequence was run
   - `Tn_run` (and `Tn_set`, if `mode = "vertically"`): identifies which run/set to extract
   - `t.stim`, `tot.channels`, `sg1`, `sg2`, `bg1`, `bg2`: stimulation and channel/background integration settings
   - `sti.power`, `LED.wl`: reader stimulation power and LED wavelength
   - `components`: number of components assumed for signal deconvolution (1–4)
3. Select the entire script (Ctrl+A) and run it (Ctrl+Enter / Ctrl+R), as noted in the script's own comments.
4. The script reads the `.binx` file, calculates %BOSL<sub>F</sub> sensitivity, performs CW-OSL curve deconvolution (via the `Luminescence` package), and exports the results.

### Input

A single-aliquot regenerative-dose (SAR) `.binx` file (Risø reader format), read via `Luminescence::read_BIN2R()`.

### Output

An Excel (`.xlsx`) or CSV file containing, per aliquot:
- %BOSL<sub>F</sub> sensitivity values
- Relative proportions of fast/medium/slow decaying components (deconvolution)
- OSL signal (cts/1s) split by component

The file is under the name given in `output_file`.

## Example

This script ship with an example dataset. To test it, use the file `EXAMPLE_Quartz_OSL_dating.binx`

## Repository structure

```
.
├── Tn_OSL_sensitivity.R   # Main script
├── EXAMPLE_Quartz_OSL_dating.binx # Example file to test the script
├── README.md
├── CITATION.cff
└── LICENSE
```

## Citation

If you use this script in your research, please cite both the paper and the software itself (see `CITATION.cff`, or the "Cite this repository" button on GitHub).

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Contact

Priscila E. Souza
Departamento de Geografia Física, Faculdade de Filosofia, Letras e Ciências Humanas, Universidade de São Paulo
[pesouza@usp.br]
[https://orcid.org/0000-0001-9975-2074]
