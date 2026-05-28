function results = saveSpacingStability3DScanOutputs(results, outDir, saveResults)
%SAVESPACINGSTABILITY3DSCANOUTPUTS
% helpers 层：负责保存 spacing stability 3D scan 的数值结果、图像与文本摘要。
%
% 设计原则：
%   1. MAT 文件只保存纯数据，不保存图窗句柄
%   2. 图窗句柄仅用于当前会话导出 PNG / FIG
%   3. 若图窗句柄失效，则基于 results 自动重建图后保存
%   4. saveResults = false 时直接返回，不做保存

    if nargin < 3 || isempty(saveResults)
        saveResults = true;
    end

    if ~isfield(results, 'dataFile') || isempty(results.dataFile)
        results.dataFile = '';
    end

    if ~isfield(results, 'summaryTextFile') || isempty(results.summaryTextFile)
        results.summaryTextFile = '';
    end

    if ~isfield(results, 'figureFiles') || ~isstruct(results.figureFiles)
        results.figureFiles = struct();
    end

    if ~saveResults
        return;
    end

    if nargin < 2 || isempty(outDir)
        error('helpers.saveSpacingStability3DScanOutputs: outDir 不能为空。');
    end

    ensureDir(outDir);

    if ~isfield(results, 'timestamp') || isempty(results.timestamp)
        error('helpers.saveSpacingStability3DScanOutputs: results.timestamp 缺失。');
    end

    %% 文件名
    matFile = fullfile(outDir, ['spacing_stability_3d_scan_' results.timestamp '.mat']);
    txtFile = fullfile(outDir, ['spacing_stability_3d_summary_' results.timestamp '.txt']);

    fig1png = fullfile(outDir, ['overall_worst_abs_error_vs_spacing_' results.timestamp '.png']);
    fig1fig = fullfile(outDir, ['overall_worst_abs_error_vs_spacing_' results.timestamp '.fig']);

    fig2png = fullfile(outDir, ['bpsk_dimension_worst_abs_error_vs_spacing_' results.timestamp '.png']);
    fig2fig = fullfile(outDir, ['bpsk_dimension_worst_abs_error_vs_spacing_' results.timestamp '.fig']);

    fig3png = fullfile(outDir, ['boc_dimension_worst_abs_error_vs_spacing_' results.timestamp '.png']);
    fig3fig = fullfile(outDir, ['boc_dimension_worst_abs_error_vs_spacing_' results.timestamp '.fig']);

    fig4png = fullfile(outDir, ['overall_mean_abs_error_vs_spacing_' results.timestamp '.png']);
    fig4fig = fullfile(outDir, ['overall_mean_abs_error_vs_spacing_' results.timestamp '.fig']);

    %% 确保图窗有效；无效则重绘
    results = ensureValidFigureHandles(results);

    %% 保存图像
    saveFigureSafe(results.figureHandles, 'overallWorst', fig1png, fig1fig);
    saveFigureSafe(results.figureHandles, 'bpskDimensionWorst', fig2png, fig2fig);
    saveFigureSafe(results.figureHandles, 'bocDimensionWorst', fig3png, fig3fig);
    saveFigureSafe(results.figureHandles, 'overallMean', fig4png, fig4fig);

    %% 回填图像路径
    results.figureFiles.overallWorstPng = fig1png;
    results.figureFiles.overallWorstFig = fig1fig;
    results.figureFiles.bpskDimensionWorstPng = fig2png;
    results.figureFiles.bpskDimensionWorstFig = fig2fig;
    results.figureFiles.bocDimensionWorstPng = fig3png;
    results.figureFiles.bocDimensionWorstFig = fig3fig;
    results.figureFiles.overallMeanPng = fig4png;
    results.figureFiles.overallMeanFig = fig4fig;

    %% 写文本摘要
    summaryLines = buildSummaryLines(results);
    writeTextFile(txtFile, summaryLines);
    results.summaryTextFile = txtFile;

    %% 保存 MAT（去掉图窗句柄）
    resultsToSave = results;
    if isfield(resultsToSave, 'figureHandles')
        resultsToSave.figureHandles = struct();
    end

    save(matFile, 'resultsToSave');
    results.dataFile = matFile;
end

%% ========================= Local Functions =========================
function results = ensureValidFigureHandles(results)
    needReplot = false;

    if ~isfield(results, 'figureHandles') || ~isstruct(results.figureHandles)
        needReplot = true;
    else
        requiredFields = {'overallWorst', 'bpskDimensionWorst', 'bocDimensionWorst', 'overallMean'};
        for i = 1:numel(requiredFields)
            fn = requiredFields{i};
            if ~isfield(results.figureHandles, fn)
                needReplot = true;
                break;
            end
            if isempty(results.figureHandles.(fn)) || ~isgraphics(results.figureHandles.(fn))
                needReplot = true;
                break;
            end
        end
    end

    if needReplot
        results.figureHandles = analysis.plotSpacingStability3DScanResults(results);
    end
end

function saveFigureSafe(figHandles, fieldName, pngFile, figFile)
    if ~isfield(figHandles, fieldName)
        warning('helpers.saveSpacingStability3DScanOutputs: 缺少图窗字段 %s，跳过保存。', fieldName);
        return;
    end

    figHandle = figHandles.(fieldName);

    if isempty(figHandle) || ~isgraphics(figHandle)
        warning('helpers.saveSpacingStability3DScanOutputs: 图窗句柄仍无效，跳过保存 %s。', pngFile);
        return;
    end

    try
        saveas(figHandle, pngFile);
        savefig(figHandle, figFile);
    catch ME
        warning('helpers.saveSpacingStability3DScanOutputs: 保存失败 %s\n%s', pngFile, ME.message);
    end
end

function lines = buildSummaryLines(results)
    nSpacing = numel(results.spacingList);

    lines = {};
    lines{end+1} = 'GNSS_Simulator Spacing Stability 3D Scan Summary';
    lines{end+1} = '================================================';
    lines{end+1} = sprintf('Export time: %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    lines{end+1} = sprintf('Amplitude scan fixed delay: %.6e s (%.3f chip)', ...
        results.fixedDelaySecForAmp, results.fixedDelayChipForAmp);
    lines{end+1} = sprintf('Amplitude/Delay scan fixed phase: %.6f rad', ...
        results.fixedPhaseForAmpDelay);
    lines{end+1} = sprintf('Delay/Phase scan fixed amplitude: %.3f', ...
        results.fixedAmpForDelayPhase);
    lines{end+1} = ' ';
    lines{end+1} = 'Spacing   Worst(BPSK)   Worst(BOC)   Mean(BPSK)   Mean(BOC)';
    lines{end+1} = '------------------------------------------------------------';

    for i = 1:nSpacing
        lines{end+1} = sprintf('%7.3f   %11.6g   %10.6g   %10.6g   %9.6g', ...
            results.spacingList(i), ...
            results.overallWorstAbsBPSK(i), ...
            results.overallWorstAbsBOC(i), ...
            results.overallMeanAbsBPSK(i), ...
            results.overallMeanAbsBOC(i));
    end

    lines{end+1} = ' ';
    lines{end+1} = sprintf('Best spacing by overall worst-case error (BPSK): %.3f chip', ...
        results.bestSpacingWorstBPSK);
    lines{end+1} = sprintf('Best spacing by overall worst-case error (BOC): %.3f chip', ...
        results.bestSpacingWorstBOC);
    lines{end+1} = sprintf('Best spacing by overall mean absolute error (BPSK): %.3f chip', ...
        results.bestSpacingMeanBPSK);
    lines{end+1} = sprintf('Best spacing by overall mean absolute error (BOC): %.3f chip', ...
        results.bestSpacingMeanBOC);
end

function writeTextFile(filePath, lines)
    fid = fopen(filePath, 'w');
    if fid == -1
        error('helpers.saveSpacingStability3DScanOutputs: 无法写入文件 %s', filePath);
    end

    cleaner = onCleanup(@() fclose(fid));

    for i = 1:numel(lines)
        fprintf(fid, '%s\n', lines{i});
    end
end

function ensureDir(folderPath)
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
end