function results = run_multipath_amplitude_scan(cfg, multipathAmplitudes, saveResults)
%RUN_MULTIPATH_AMPLITUDE_SCAN
% 根目录主入口：负责调用 analysis 层计算、绘图与 helpers 层保存。
%
% 使用方式：
%   results = run_multipath_amplitude_scan();
%   results = run_multipath_amplitude_scan(cfg);
%   results = run_multipath_amplitude_scan(cfg, amps);
%   results = run_multipath_amplitude_scan(cfg, amps, false);
%
% 设计原则：
%   - 保持当前命令行主入口体验
%   - 计算逻辑下沉到 analysis 层
%   - 绘图逻辑下沉到 analysis 层
%   - 保存逻辑下沉到 helpers 层
%   - 本文件逐步收敛为“薄主入口”

    %% =========================
    % 1. 输入处理
    % =========================
    if nargin < 1 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 2 || isempty(multipathAmplitudes)
        if isfield(cfg, 'experiment') && isfield(cfg.experiment, 'attenuationSweep')
            multipathAmplitudes = cfg.experiment.attenuationSweep;
        else
            multipathAmplitudes = [0.2, 0.4, 0.6, 0.8];
        end
    end

    if nargin < 3 || isempty(saveResults)
        saveResults = true;
    end

    cfg.tracking.earlyLateSpacing = 0.04;
    cfg.scurve.earlyLateSpacing   = cfg.tracking.earlyLateSpacing;

    outDir = cfg.path.exp.multipathAmplitude;
    ensureDir(outDir);

    %% =========================
    % 2. 命令行输出
    % =========================
    fprintf('==============================\n');
    fprintf('Running multipath amplitude scan...\n');
    fprintf('==============================\n');
    fprintf('[1/4] Computing scan results...\n');

    %% =========================
    % 3. 调用计算层（analysis）
    % =========================
    results = analysis.runMultipathAmplitudeScan(cfg, multipathAmplitudes);
    results.outputDir = outDir;
    results.dataFile = '';
    results.figureFiles = struct();
    results.figureHandles = struct();

    %% =========================
    % 4. 调用绘图层（analysis）
    % =========================
    fprintf('[2/4] Plotting figures...\n');

    figHandles = analysis.plotMultipathAmplitudeScanResults(results);
    results.figureHandles = figHandles;

    %% =========================
    % 5. 调用保存层（helpers）
    % =========================
    fprintf('[3/4] Saving outputs...\n');

    results = helpers.saveMultipathAmplitudeScanOutputs(results, outDir, saveResults);

    %% =========================
    % 6. 打印摘要
    % =========================
    fprintf('[4/4] Printing summary...\n');
    printSummary(results);
end

%% ========================= Local Functions =========================
function ensureDir(folderPath)
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
end

function printSummary(results)
    nAmp = numel(results.multipathAmplitudes);

    fprintf('\n========== Scan Summary ==========\n');
    fprintf('Fixed Early-Late spacing: %.3f chip\n', results.spacing);
    fprintf('Results saved to: %s\n', results.outputDir);
    fprintf('\nAmplitude    Max|Err| BPSK    Max|Err| BOC\n');
    fprintf('------------------------------------------\n');
    for k = 1:nAmp
        fprintf('%8.3f    %14.6g    %13.6g\n', ...
            results.multipathAmplitudes(k), ...
            results.maxAbsErrorBPSK(k), ...
            results.maxAbsErrorBOC(k));
    end
    fprintf('==========================================\n');
end