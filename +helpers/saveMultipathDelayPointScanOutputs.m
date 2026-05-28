function results = saveMultipathDelayPointScanOutputs(results, outDir, saveResults)
%SAVEMULTIPATHDELAYPOINTSCANOUTPUTS
% helpers 层：负责保存多径延迟点扫描的数值结果与图像文件。
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

    if ~isfield(results, 'figureFiles') || ~isstruct(results.figureFiles)
        results.figureFiles = struct();
    end

    if ~saveResults
        return;
    end

    if nargin < 2 || isempty(outDir)
        error('helpers.saveMultipathDelayPointScanOutputs: outDir 不能为空。');
    end

    ensureDir(outDir);

    if ~isfield(results, 'timestamp') || isempty(results.timestamp)
        error('helpers.saveMultipathDelayPointScanOutputs: results.timestamp 缺失。');
    end

    %% 1) 文件名
    matFile = fullfile(outDir, ['multipath_delay_point_scan_' results.timestamp '.mat']);

    fig1png = fullfile(outDir, ['tracking_error_vs_specified_delay_' results.timestamp '.png']);
    fig1fig = fullfile(outDir, ['tracking_error_vs_specified_delay_' results.timestamp '.fig']);

    fig2png = fullfile(outDir, ['abs_tracking_error_vs_specified_delay_' results.timestamp '.png']);
    fig2fig = fullfile(outDir, ['abs_tracking_error_vs_specified_delay_' results.timestamp '.fig']);

    %% 2) 确保有可用图窗句柄；若无则自动重建
    results = ensureValidFigureHandles(results);

    %% 3) 保存图像
    saveFigureSafe(results.figureHandles, 'trackingError', fig1png, fig1fig);
    saveFigureSafe(results.figureHandles, 'absTrackingError', fig2png, fig2fig);

    %% 4) 回填图像路径
    results.figureFiles.trackingErrorPng = fig1png;
    results.figureFiles.trackingErrorFig = fig1fig;
    results.figureFiles.absTrackingErrorPng = fig2png;
    results.figureFiles.absTrackingErrorFig = fig2fig;

    %% 5) 保存 MAT 时去掉图窗句柄
    resultsToSave = results;
    if isfield(resultsToSave, 'figureHandles')
        resultsToSave.figureHandles = struct();
    end

    save(matFile, 'resultsToSave');

    %% 6) 回填 MAT 路径
    results.dataFile = matFile;
end

%% ========================= Local Functions =========================
function results = ensureValidFigureHandles(results)
    needReplot = false;

    if ~isfield(results, 'figureHandles') || ~isstruct(results.figureHandles)
        needReplot = true;
    else
        requiredFields = {'trackingError', 'absTrackingError'};
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
        results.figureHandles = analysis.plotMultipathDelayPointScanResults(results);
    end
end

function saveFigureSafe(figHandles, fieldName, pngFile, figFile)
    if ~isfield(figHandles, fieldName)
        warning('helpers.saveMultipathDelayPointScanOutputs: 缺少图窗字段 %s，跳过保存。', fieldName);
        return;
    end

    figHandle = figHandles.(fieldName);

    if isempty(figHandle) || ~isgraphics(figHandle)
        warning('helpers.saveMultipathDelayPointScanOutputs: 图窗句柄仍无效，跳过保存 %s。', pngFile);
        return;
    end

    try
        saveas(figHandle, pngFile);
        savefig(figHandle, figFile);
    catch ME
        warning('helpers.saveMultipathDelayPointScanOutputs: 保存失败 %s\n%s', pngFile, ME.message);
    end
end

function ensureDir(folderPath)
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
end