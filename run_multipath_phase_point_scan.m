function results = run_multipath_phase_point_scan(cfg, multipathPhases, saveResults)
%RUN_MULTIPATH_PHASE_POINT_SCAN
% 根目录主入口：负责调用 analysis 层计算、绘图与 helpers 层保存。
%
% 使用方式：
%   results = run_multipath_phase_point_scan();
%   results = run_multipath_phase_point_scan(cfg);
%   results = run_multipath_phase_point_scan(cfg, phases);
%   results = run_multipath_phase_point_scan(cfg, phases, false);
%
% 设计原则：
%   - 保持当前命令行主入口体验
%   - 计算逻辑下沉到 analysis 层
%   - 绘图逻辑下沉到 analysis 层
%   - 保存逻辑下沉到 helpers 层
%   - 本文件逐步收敛为“薄主入口”

    %% 1) 输入处理
    if nargin < 1 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 2 || isempty(multipathPhases)
        multipathPhases = linspace(0, 2*pi, 9);   % 0, pi/4, ..., 2pi
    end

    if nargin < 3 || isempty(saveResults)
        saveResults = true;
    end

    cfg.tracking.earlyLateSpacing = 0.04;
    cfg.scurve.earlyLateSpacing   = cfg.tracking.earlyLateSpacing;

    outDir = cfg.path.exp.multipathPhasePoint;
    ensureDir(outDir);

    %% 2) 终端输出
    fprintf('====================================\n');
    fprintf('Running multipath phase point scan...\n');
    fprintf('====================================\n');
    fprintf('[1/4] Computing scan results...\n');

    %% 3) 调用计算层（analysis）
    results = analysis.runMultipathPhasePointScan(cfg, multipathPhases);
    results.outputDir = outDir;
    results.dataFile = '';
    results.figureFiles = struct();
    results.figureHandles = struct();

    %% 4) 调用绘图层（analysis）
    fprintf('[2/4] Plotting figures...\n');
    results.figureHandles = analysis.plotMultipathPhasePointScanResults(results);

    %% 5) 调用保存层（helpers）
    fprintf('[3/4] Saving outputs...\n');
    results = helpers.saveMultipathPhasePointScanOutputs(results, outDir, saveResults);

    %% 6) 打印摘要
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
    fprintf('\n========== Scan Summary ==========\n');
    fprintf('Fixed Early-Late spacing: %.3f chip\n', results.spacing);
    fprintf('Fixed multipath amplitude: %.3f\n', results.fixedMultipathAmplitude);
    fprintf('Fixed multipath delay: %.6g s (%.3f chip)\n', ...
        results.fixedMultipathDelaySec, results.fixedMultipathDelayChip);
    fprintf('Results saved to: %s\n', results.outputDir);
    fprintf('\nPhase(rad)     Err BPSK        Err BOC\n');
    fprintf('--------------------------------------\n');

    for k = 1:numel(results.multipathPhases)
        fprintf('%10.6f    %12.6g    %12.6g\n', ...
            results.multipathPhases(k), ...
            results.errorPointBPSK(k), ...
            results.errorPointBOC(k));
    end

    fprintf('--------------------------------------\n');
    fprintf('Best phase for BPSK (min |err|): %.6f rad\n', results.summary.bestPhaseBPSK);
    fprintf('Best phase for BOC  (min |err|): %.6f rad\n', results.summary.bestPhaseBOC);
    fprintf('======================================\n');
end