Project Overview

The BOC GNSS Simulator is a MATLAB simulation software for GNSS baseband signal generation, signal modulation, multipath propagation, noise interference, correlation detection, and code tracking error analysis. The project focuses primarily on Binary Offset Carrier (BOC) signals, while also covering typical navigation signal formats such as BPSK, QPSK, and B1C/MBOC. It establishes a complete simulation chain that includes pseudo‑random code generation, baseband signal modulation, channel effect modeling, tracking error calculation, and visualisation of experimental results.

In real‑world environments, GNSS receivers are affected by multipath propagation, thermal noise, and different correlator settings, which can cause correlation function distortion, discriminator zero‑crossing offsets, and code tracking errors. In particular, BOC‑type navigation signals with complex subcarrier structures typically exhibit pronounced multi‑peak correlation functions, making it difficult to directly apply traditional BPSK analysis methods to characterise their tracking performance. Therefore, unified modelling and quantitative analysis of tracking error characteristics under multipath for different navigation signal schemes are of great significance for signal design, receiver tracking algorithm development, and anti‑multipath performance evaluation.

To address these issues, this project adopts a unified configuration parameter set and a modular software architecture. It organises functions such as signal generation, channel modelling, correlation processing, code tracking error calculation, parameter sweeping, Monte Carlo statistical analysis, result saving, and visualisation into layered modules. The system can perform both single‑condition signal and tracking performance analyses, as well as batch sweeping experiments over key parameters (e.g., multipath amplitude, multipath delay, multipath phase, and Early‑Late spacing) to reveal how tracking errors vary under different conditions.

Main Research Contents

The core research contents of the project include the following aspects.

First, navigation signal generation: a unified interface for pseudo‑random code generation and baseband modulation is established. The PRN code generation module produces navigation spreading codes of specified lengths, and further constructs baseband signals for BPSK, BOC, QPSK, and B1C/MBOC formats according to different signal schemes. BOC signals support configurable subcarrier types and related parameters; QPSK signals are represented in complex baseband form; B1C/MBOC is modelled by a representative combination of BOC(1,1) and BOC(6,1) components, enabling performance comparisons among different navigation signal schemes.

Second, channel environment modelling: multipath propagation and additive white Gaussian noise models are built. The multipath model allows independent setting of amplitude, propagation delay, and phase. To address the common issue of non‑integer sampling delays in GNSS simulations, a fractional delay processing method is incorporated, improving the accuracy of multipath delay modelling. The noise module generates random noise based on the input signal power and a specified signal‑to‑noise ratio, and supports controllable random seeds to ensure reproducibility in Monte Carlo simulations.

Third, correlation detection and code tracking error analysis: a three‑branch (Early, Prompt, Late) correlation processing flow is implemented, and the Normalised Early‑minus‑Late Power (NELP) discriminator is used to compute code tracking errors. By calculating correlation outputs under different code phase offsets, the corresponding S‑curve is obtained, and the code tracking bias under multipath is determined by finding the zero‑crossing point. This method links the signal waveform, channel propagation characteristics, and receiver correlation processing, providing a unified basis for subsequent multipath error analysis.

Fourth, experimental analysis: the system provides multiple parameter‑sweeping and statistical analysis methods. One‑dimensional or two‑dimensional sweeps can be performed over multipath amplitude, delay, phase, and Early‑Late spacing, yielding tracking errors, maximum absolute errors, mean absolute errors, and error envelopes under different conditions. For scenarios with random noise, Monte Carlo simulations are run repeatedly to compute tracking errors, and statistical metrics such as mean, standard deviation, variance, root‑mean‑square error (RMSE), median, maximum, peak‑to‑peak value, and confidence intervals are calculated to evaluate tracking stability from a statistical perspective for different signal schemes.

Software Architecture

To improve modularity and maintainability, the project adopts a layered architecture for its MATLAB source code. The system consists of root‑level application layer, core algorithm layer, analysis layer, utility layer, helper layer, test layer, and experiment layer.

The core algorithm layer (core) is responsible for low‑level signal processing and physical model implementations, including PRN code generation, BPSK/BOC/QPSK modulation, B1C/MBOC signal construction, carrier modulation, fractional delay, multipath channel, noise model, and NELP discriminator. This layer keeps functions as independent as possible, allowing low‑level algorithms to be reused by different experimental modules.

The analysis layer (analysis) sits above the core layer and combines multiple low‑level algorithms into complete research analysis workflows. It includes functions for baseband signal construction, single‑condition tracking error calculation, multipath error analysis, multipath error envelope computation, multi‑parameter sweeping, and Monte Carlo simulations. The analysis layer produces structured experimental results that provide a unified data interface for subsequent visualisation, data saving, and statistical analysis.

The utility layer (utils) provides reusable numerical computation and plotting functions, such as S‑curve calculation, multipath tracking error computation, multipath error envelope generation, and spectrum/correlation plotting. This layer handles common computational tasks and offers optimised paths for computationally intensive experiments.

The helper layer (helpers) deals with result persistence and file system operations, including result directory creation, MAT file saving, figure saving, and text output. It distinguishes between figure handles and saved data during runtime, allowing results to be stored in a form suitable for post‑processing and long‑term preservation.

The root‑level application layer handles system configuration, experiment registration and scheduling, GUI interaction, and experiment entry points. The project maintains main simulation parameters through a unified configuration function and manages different experiment types via an experiment registry, so that both the GUI and command‑line interfaces can invoke the corresponding analysis algorithms through a unified scheduling interface.

The test layer (test) is used to verify the correctness of individual modules, including tests for PRN codes, BPSK/BOC/QPSK signal generation, carrier modulation, correlation computation, fractional delay, multipath model, noise model, NELP discriminator, S‑curve, and multipath error analysis. Integrated tests are also included for Monte Carlo simulations, parameter sweeps, and the complete signal processing chain to ensure that data passing and parameter propagation between modules behave as expected.

In addition, the project includes an independent experiments directory for storing experiment scripts targeted at paper research and specific performance comparisons. This part can set up dedicated signal models and experiment flows according to particular research questions, and generate result files such as CSV, PNG, and PDF, thus forming a relatively independent research environment separate from the general simulation framework.

Simulation and Data Processing Flow

A typical simulation flow of the system can be summarised as:

Configuration initialisation → PRN code generation → baseband signal modulation → multipath channel modelling → noise addition → Early/Late correlation processing → NELP discrimination → S‑curve calculation → zero‑crossing search → tracking error computation → parameter sweep or Monte Carlo statistics → result saving and visualisation.

In this flow, the configuration parameters act as a key information carrier among modules, describing sampling rate, simulation duration, signal scheme, BOC parameters, multipath parameters, noise parameters, tracking parameters, and experimental sweep ranges. After completing their own computations, modules organise results into structure arrays, reducing direct dependencies on variable names and execution order.

For multipath performance studies, the system can vary multipath amplitude, delay, phase, or Early‑Late spacing independently while keeping other parameters fixed, so as to analyse the effect of a single parameter on tracking errors. In multi‑parameter experiments, it can further obtain maximum errors, mean errors, and error envelopes under different parameter combinations, and use three‑dimensional stability analysis to find relatively suitable Early‑Late spacings.

For random noise environments, the system controls stochastic processes by using a fixed base random seed and assigning independent seeds to each Monte Carlo trial, ensuring that results are both random and repeatable under identical conditions. This design facilitates fair comparisons between different algorithms or parameter settings.

Software Features

From the perspectives of functionality and research utility, the project exhibits the following features:

(1) Modular design – separates low‑level signal processing, experiment workflows, data processing, result storage, and user interaction, facilitating independent testing and reuse.

(2) Multi‑signal support – handles BPSK, BOC, QPSK, and B1C/MBOC baseband signals within a unified framework, providing a foundation for performance comparisons among different navigation signal schemes.

(3) Configurable multipath parameters – allows independent control of multipath amplitude, delay, and phase, and supports fractional‑sample delays for more refined multipath propagation conditions.

(4) Quantitative tracking performance analysis – translates correlation function distortions caused by multipath into code tracking error metrics via S‑curves, NELP discriminators, and zero‑crossing searches.

(5) Support for deterministic and statistical experiments – performs both single‑condition deterministic calculations and large‑scale statistical experiments through parameter sweeps and Monte Carlo methods.

(6) Structured result saving – organises simulation results in a structured format and supports multiple output formats (MAT, CSV, TXT, PNG, FIG) for subsequent data analysis, plotting, and paper figure generation.

(7) Compatibility with graphical and programmatic operation – provides both command‑line operation and a MATLAB GUI, enabling algorithm validation, batch experiments, and interactive parameter analysis through the same experiment scheduling interface.

 Project Positioning

Overall, the BOC GNSS Simulator is not merely a MATLAB program for a single specific algorithm, but rather a modular simulation platform for GNSS signal and receiver tracking performance research. With BOC‑type navigation signals as the main research focus, it establishes unified signal models, channel models, correlation processing models, and error evaluation methods to systematically analyse tracking performance under different signal schemes and multipath conditions.

The system now forms a complete software chain from low‑level signal generation, channel modelling, and correlation detection up to high‑level parameter sweeping, Monte Carlo statistics, GUI operation, and paper‑ready result output. Its main applications include GNSS baseband signal simulation, BOC signal characterisation, multipath error analysis, code tracking performance evaluation, parameter sensitivity studies, and performance comparisons among navigation signal schemes. Future work may further refine standardised interfaces, experimental result data structures, software testing frameworks, and version management mechanisms, so as to enhance reproducibility, maintainability, and research value.

