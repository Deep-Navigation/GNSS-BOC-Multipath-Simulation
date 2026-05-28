function results = run_spacing_stability_3d_scan(cfg, spacingList, saveResults)
%RUN_SPACING_STABILITY_3D_SCAN
% 根目录主入口：负责调用 analysis 层计算、绘图与 helpers 层保存。
%
% 使用方式：
%   results = run_spacing_stability_3d_scan();
%   results = run_spacing_stability_3d_scan(cfg);
%   results = run_spacing_stability_3d_scan(cfg, spacingList);
%   results = run_spacing_stability_3d_scan(cfg, spacingList, false);

    %% 1) 输入处理
    if nargin < 1 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 2 || isempty(spacingList)
        spacingList = [0.02, 0.03, 0.04, 0.05, 0.06, 0.08, 0.10];
    end

    if nargin < 3 || isempty(saveResults)
        saveResults = true;
    end

    amplitudeList = [0.2, 0.4, 0.6, 0.8, 1.0];
    delayListChip = [0.05, 0.10, 0.20, 0.30, 0.50];
    phaseList = [0, pi/6, pi/3, pi/2, 2*pi/3, 5*pi/6, pi, 4*pi/3, 3*pi/2, 5*pi/3];

    if isfield(cfg, 'path') && isfield(cfg.path, 'exp') && isfield(cfg.path.exp, 'spacingStability3D')
        outDir = cfg.path.exp.spacingStability3D;
    else
        outDir = fullfile(cfg.path.results, 'spacing_stability_3d_scan');
    end
    ensureDir(outDir);

    %% 2) 终端输出
    fprintf('=========================================\n');
    fprintf('Running spacing stability 3D scan...\n');
    fprintf('=========================================\n');
    fprintf('[1/4] Computing scan results...\n');

    %% 3) 调用计算层（analysis）
    results = analysis.runSpacingStability3DScan( ...
        cfg, spacingList, amplitudeList, delayListChip, phaseList);

    results.outputDir = outDir;
    results.dataFile = '';
    results.summaryTextFile = '';
    results.figureFiles = struct();
    results.figureHandles = struct();

    %% 4) 调用绘图层（analysis）
    fprintf('[2/4] Plotting figures...\n');
    results.figureHandles = analysis.plotSpacingStability3DScanResults(results);

    %% 5) 调用保存层（helpers）
    fprintf('[3/4] Saving outputs...\n');
    results = helpers.saveSpacingStability3DScanOutputs(results, outDir, saveResults);

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
    fprintf('\n========== 3D Stability Summary ==========\n');
    fprintf('Best spacing by overall worst-case error:\n');
    fprintf('  BPSK -> %.3f chip\n', results.bestSpacingWorstBPSK);
    fprintf('  BOC  -> %.3f chip\n', results.bestSpacingWorstBOC);
    fprintf('Best spacing by overall mean absolute error:\n');
    fprintf('  BPSK -> %.3f chip\n', results.bestSpacingMeanBPSK);
    fprintf('  BOC  -> %.3f chip\n', results.bestSpacingMeanBOC);

    if isfield(results, 'dataFile') && ~isempty(results.dataFile)
        fprintf('Results saved to: %s\n', results.outputDir);
    else
        fprintf('Results not saved to disk (saveResults = false)\n');
    end

    fprintf('==========================================\n');
end