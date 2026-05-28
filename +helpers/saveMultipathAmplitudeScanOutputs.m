function results = saveMultipathAmplitudeScanOutputs(results, outDir, saveResults)
%SAVEMULTIPATHAMPLITUDESCANOUTPUTS
% 保存多径幅度扫描结果
%
% 设计原则：
%   1. MAT 文件只保存纯数据，不保存图窗句柄
%   2. 图窗句柄仅用于当前会话导出 PNG / FIG
%   3. saveResults = false 时直接返回，不做保存

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
        error('helpers.saveMultipathAmplitudeScanOutputs: outDir 不能为空。');
    end

    ensureDir(outDir);

    if ~isfield(results, 'timestamp') || isempty(results.timestamp)
        error('helpers.saveMultipathAmplitudeScanOutputs: results.timestamp 缺失。');
    end

    if ~isfield(results, 'figureHandles') || ~isstruct(results.figureHandles)
        error('helpers.saveMultipathAmplitudeScanOutputs: results.figureHandles 缺失。');
    end

    %% 1) 生成文件名
    matFile = fullfile(outDir, ['multipath_amplitude_scan_' results.timestamp '.mat']);

    fig1png = fullfile(outDir, ['bpsk_envelope_vs_amplitude_' results.timestamp '.png']);
    fig1fig = fullfile(outDir, ['bpsk_envelope_vs_amplitude_' results.timestamp '.fig']);

    fig2png = fullfile(outDir, ['boc_envelope_vs_amplitude_' results.timestamp '.png']);
    fig2fig = fullfile(outDir, ['boc_envelope_vs_amplitude_' results.timestamp '.fig']);

    fig3png = fullfile(outDir, ['max_abs_error_vs_amplitude_' results.timestamp '.png']);
    fig3fig = fullfile(outDir, ['max_abs_error_vs_amplitude_' results.timestamp '.fig']);

    %% 2) 先保存图像
    saveFigureSafe(results.figureHandles, 'bpskEnvelope', fig1png, fig1fig);
    saveFigureSafe(results.figureHandles, 'bocEnvelope',  fig2png, fig2fig);
    saveFigureSafe(results.figureHandles, 'maxAbsError',  fig3png, fig3fig);

    %% 3) 回填图像路径
    results.figureFiles.bpskEnvelopePng = fig1png;
    results.figureFiles.bpskEnvelopeFig = fig1fig;
    results.figureFiles.bocEnvelopePng  = fig2png;
    results.figureFiles.bocEnvelopeFig  = fig2fig;
    results.figureFiles.maxAbsPng       = fig3png;
    results.figureFiles.maxAbsFig       = fig3fig;

    %% 4) 保存 MAT 时去掉图窗句柄
    resultsToSave = results;
    if isfield(resultsToSave, 'figureHandles')
        resultsToSave.figureHandles = struct();
    end

    save(matFile, 'resultsToSave');

    %% 5) 回填 MAT 路径
    results.dataFile = matFile;
end

%% ========================= Local Functions =========================
function saveFigureSafe(figHandles, fieldName, pngFile, figFile)
    if ~isfield(figHandles, fieldName)
        warning('helpers.saveMultipathAmplitudeScanOutputs: 缺少图窗字段 %s，跳过保存。', fieldName);
        return;
    end

    figHandle = figHandles.(fieldName);

    if isempty(figHandle) || ~isgraphics(figHandle)
        warning('helpers.saveMultipathAmplitudeScanOutputs: 图窗句柄无效，跳过保存 %s。', pngFile);
        return;
    end

    try
        saveas(figHandle, pngFile);
        savefig(figHandle, figFile);
    catch ME
        warning('helpers.saveMultipathAmplitudeScanOutputs: 保存失败 %s\n%s', pngFile, ME.message);
    end
end

function ensureDir(folderPath)
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
end