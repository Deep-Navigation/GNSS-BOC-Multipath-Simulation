function results = run_multipath_delay_point_scan(cfg, multipathDelaysChip, saveResults)
%RUN_MULTIPATH_DELAY_POINT_SCAN
% 根目录主入口：负责调用 analysis 层计算、绘图与 helpers 层保存。
%
% 使用方式：
%   results = run_multipath_delay_point_scan();
%   results = run_multipath_delay_point_scan(cfg);
%   results = run_multipath_delay_point_scan(cfg, delaysChip);
%   results = run_multipath_delay_point_scan(cfg, delaysChip, false);
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

    if nargin < 2 || isempty(multipathDelaysChip)
        multipathDelaysChip = [0.05, 0.10, 0.20, 0.30, 0.50];
    end

    if nargin < 3 || isempty(saveResults)
        saveResults = true;
    end

    cfg.tracking.earlyLateSpacing = 0.04;
    cfg.scurve.earlyLateSpacing   = cfg.tracking.earlyLateSpacing;

    outDir = cfg.path.exp.multipathDelayPoint;
    ensureDir(outDir);

    %% 2) 终端输出
    fprintf('====================================\n');
    fprintf('Running multipath delay point scan...\n');
    fprintf('====================================\n');
    fprintf('[1/4] Computing scan results...\n');

    %% 3) 调用计算层（analysis）
    results = analysis.runMultipathDelayPointScan(cfg, multipathDelaysChip);
    results.outputDir = outDir;
    results.dataFile = '';
    results.figureFiles = struct();
    results.figureHandles = struct();

    %% 4) 调用绘图层（analysis）
    fprintf('[2/4] Plotting figures...\n');
    results.figureHandles = analysis.plotMultipathDelayPointScanResults(results);

    %% 5) 调用保存层（helpers）
    fprintf('[3/4] Saving outputs...\n');
    results = helpers.saveMultipathDelayPointScanOutputs(results, outDir, saveResults);

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
    fprintf('Fixed multipath phase: %.6f rad\n', results.fixedMultipathPhase);
    fprintf('Results saved to: %s\n', results.outputDir);
    fprintf('\nDelay(chip)    Err BPSK        Err BOC\n');
    fprintf('--------------------------------------\n');

    for k = 1:numel(results.multipathDelaysChip)
        fprintf('%10.3f    %12.6g    %12.6g\n', ...
            results.multipathDelaysChip(k), ...
            results.errorPointBPSK(k), ...
            results.errorPointBOC(k));
    end

    fprintf('--------------------------------------\n');
    fprintf('Best delay for BPSK (min |err|): %.3f chip\n', results.summary.bestDelayChipBPSK);
    fprintf('Best delay for BOC  (min |err|): %.3f chip\n', results.summary.bestDelayChipBOC);
    fprintf('======================================\n');
end