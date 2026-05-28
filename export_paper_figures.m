function export_paper_figures(saveDir)
%EXPORT_PAPER_FIGURES 统一生成并导出论文/答辩用图表
%
%   export_paper_figures()
%   export_paper_figures(saveDir)
%
%   功能：
%       1. 导出三张核心基础图
%       2. 导出多径幅度扫描结果
%       3. 导出多径延迟点扫描结果
%       4. 导出多径相位点扫描结果
%       5. 导出 spacing 三维稳定性结果
%
%   当前统一接口说明：
%       - 默认输出到项目根目录下 results/paper_figures
%       - 使用公共 helper:
%           helpers.ensureDir
%           helpers.safeSaveFigure
%           helpers.writeTextFile

    clc;
    close all;

    %% 1) 配置与输出目录
    cfg = config_default();

    if nargin < 1 || isempty(saveDir)
        saveDir = fullfile(cfg.path.results, 'paper_figures');
    end

    helpers.ensureDir(saveDir);

    coreDir       = fullfile(saveDir, 'core_figures');
    ampDir        = fullfile(saveDir, 'multipath_amplitude_scan');
    delayPointDir = fullfile(saveDir, 'multipath_delay_point_scan');
    phasePointDir = fullfile(saveDir, 'multipath_phase_point_scan');
    spacing3dDir  = fullfile(saveDir, 'spacing_stability_3d_scan');

    helpers.ensureDir(coreDir);
    helpers.ensureDir(ampDir);
    helpers.ensureDir(delayPointDir);
    helpers.ensureDir(phasePointDir);
    helpers.ensureDir(spacing3dDir);

    fprintf('========================================\n');
    fprintf('开始统一导出论文版图表\n');
    fprintf('总保存目录: %s\n', saveDir);
    fprintf('========================================\n\n');

    %% 2) 统一配置
    cfg.noise.enable = false;
    cfg.tracking.interpMethod = 'linear';
    cfg.tracking.earlyLateSpacing = 0.04;
    cfg.scurve.earlyLateSpacing   = cfg.tracking.earlyLateSpacing;

    %% =========================
    % 图1：S 曲线对比
    % =========================
    fprintf('【图1】生成并导出 S 曲线对比图...\n');

    cfg1 = cfg;
    cfg1.multipath.enable = false;

    cfg1.signal.modType = 'BPSK';
    [Sb, xb] = utils.computeSCurve([], [], cfg1);

    cfg1.signal.modType = 'BOC';
    [Sc, xc] = utils.computeSCurve([], [], cfg1);

    h1 = figure('Name', 'Figure1_SCurve_Compare', 'Color', 'w');
    plot(xb, Sb, 'LineWidth', 1.8);
    hold on;
    plot(xc, Sc, 'LineWidth', 1.8);
    grid on;
    box on;
    yline(0, '--');
    xline(0, '--');
    legend('BPSK', 'BOC', 'Location', 'best');
    xlabel('Code Phase Offset / chip', 'FontSize', 12);
    ylabel('Discriminator Output', 'FontSize', 12);
    title('S-Curve Comparison Between BPSK and BOC', 'FontSize', 13);
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);

    helpers.safeSaveFigure(h1, fullfile(coreDir, 'figure1_scurve_compare'));
    fprintf('完成：图1 已导出。\n\n');

    %% =========================
    % 图2：多径跟踪误差对比
    % =========================
    fprintf('【图2】生成并导出多径跟踪误差对比图...\n');

    cfg2 = cfg;

    cfg2.signal.modType = 'BPSK';
    [dB_err, eB] = utils.computeMultipathError(cfg2);

    cfg2.signal.modType = 'BOC';
    [dC_err, eC] = utils.computeMultipathError(cfg2);

    h2 = figure('Name', 'Figure2_Multipath_Error_Compare', 'Color', 'w');
    plot(dB_err, eB, 'LineWidth', 1.8);
    hold on;
    plot(dC_err, eC, 'LineWidth', 1.8);
    grid on;
    box on;
    yline(0, '--');
    xline(0, '--');
    legend('BPSK', 'BOC', 'Location', 'best');
    xlabel('Multipath Delay / chip', 'FontSize', 12);
    ylabel('Code Tracking Error / chip', 'FontSize', 12);
    title('Multipath Tracking Error Comparison Between BPSK and BOC', 'FontSize', 13);
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);

    helpers.safeSaveFigure(h2, fullfile(coreDir, 'figure2_multipath_error_compare'));
    fprintf('完成：图2 已导出。\n\n');

    %% =========================
    % 图3：多径误差包络对比
    % =========================
    fprintf('【图3】生成并导出多径误差包络对比图...\n');

    cfg3 = cfg;

    cfg3.signal.modType = 'BPSK';
    [dB_env, upB, lowB] = utils.computeMultipathEnvelope(cfg3);

    cfg3.signal.modType = 'BOC';
    [dC_env, upC, lowC] = utils.computeMultipathEnvelope(cfg3);

    h3 = figure('Name', 'Figure3_Multipath_Envelope_Compare', 'Color', 'w');
    plot(dB_env, upB, 'LineWidth', 1.8);
    hold on;
    plot(dB_env, lowB, 'LineWidth', 1.8);
    plot(dC_env, upC, 'LineWidth', 1.8);
    plot(dC_env, lowC, 'LineWidth', 1.8);
    grid on;
    box on;
    yline(0, '--');
    xline(0, '--');
    legend('BPSK Upper Envelope', 'BPSK Lower Envelope', ...
           'BOC Upper Envelope', 'BOC Lower Envelope', ...
           'Location', 'best');
    xlabel('Multipath Delay / chip', 'FontSize', 12);
    ylabel('Code Tracking Error Envelope / chip', 'FontSize', 12);
    title('Multipath Error Envelope Comparison Between BPSK and BOC', 'FontSize', 13);
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);

    helpers.safeSaveFigure(h3, fullfile(coreDir, 'figure3_multipath_envelope_compare'));
    fprintf('完成：图3 已导出。\n\n');

    %% 4) 幅度扫描
    fprintf('【附加导出】检查多径幅度扫描结果...\n');
    exportMultipathAmplitudeSet(cfg, ampDir);
    fprintf('完成：多径幅度扫描结果导出检查结束。\n\n');

    %% 5) 延迟点扫描
    fprintf('【附加导出】检查多径延迟点扫描结果...\n');
    exportMultipathDelayPointSet(cfg, delayPointDir);
    fprintf('完成：多径延迟点扫描结果导出检查结束。\n\n');

    %% 6) 相位点扫描
    fprintf('【附加导出】检查多径相位点扫描结果...\n');
    exportMultipathPhasePointSet(cfg, phasePointDir);
    fprintf('完成：多径相位点扫描结果导出检查结束。\n\n');

    %% 7) spacing 三维稳定性
    fprintf('【附加导出】检查 spacing 三维稳定性结果...\n');
    exportSpacingStability3DSet(cfg, spacing3dDir);
    fprintf('完成：spacing 三维稳定性结果导出检查结束。\n\n');

    fprintf('========================================\n');
    fprintf('全部论文图导出完成！\n');
    fprintf('核心图目录: %s\n', coreDir);
    fprintf('幅度扫描目录: %s\n', ampDir);
    fprintf('延迟点扫描目录: %s\n', delayPointDir);
    fprintf('相位点扫描目录: %s\n', phasePointDir);
    fprintf('spacing三维稳定性目录: %s\n', spacing3dDir);
    fprintf('========================================\n');
end

%% ========================= Local Export Functions =========================

function exportMultipathAmplitudeSet(cfg, outDir)

    scanDir = fullfile(cfg.path.results, 'multipath_amplitude_scan');
    helpers.ensureDir(outDir);

    matFiles = dir(fullfile(scanDir, 'multipath_amplitude_scan_*.mat'));
    if isempty(matFiles)
        fprintf('未找到多径幅度扫描 MAT 结果，跳过该部分导出。\n');
        fprintf('如需导出，请先运行：run_multipath_amplitude_scan\n');
        return;
    end

    [~, idxLatest] = max([matFiles.datenum]);
    latestMatFile = fullfile(matFiles(idxLatest).folder, matFiles(idxLatest).name);

    S = load(latestMatFile);
    if ~isfield(S, 'results')
        warning('结果文件中未找到 results 变量，跳过幅度扫描导出：%s', latestMatFile);
        return;
    end

    results = S.results;
    timestampStr = datestr(now, 'yyyymmdd_HHMMSS');

    requiredFields = { ...
        'spacing', ...
        'multipathAmplitudes', ...
        'maxAbsErrorBPSK', ...
        'maxAbsErrorBOC', ...
        'delayAxisBPSK', ...
        'delayAxisBOC', ...
        'envelopeBPSK', ...
        'envelopeBOC'};

    for i = 1:numel(requiredFields)
        if ~isfield(results, requiredFields{i})
            warning('results 中缺少字段 %s，跳过幅度扫描导出。', requiredFields{i});
            return;
        end
    end

    amps = results.multipathAmplitudes(:);
    maxErrBPSK = results.maxAbsErrorBPSK(:);
    maxErrBOC  = results.maxAbsErrorBOC(:);

    errDiff = maxErrBPSK - maxErrBOC;
    relImprovePct = 100 * errDiff ./ maxErrBPSK;

    T = table(amps,maxErrBPSK,maxErrBOC,errDiff,relImprovePct, ...
        'VariableNames', {'MultipathAmplitude','MaxAbsError_BPSK','MaxAbsError_BOC','AbsoluteImprovement_BOC_vs_BPSK','RelativeImprovementPercent_BOC_vs_BPSK'});

    csvFile = fullfile(outDir, ['multipath_amplitude_summary_' timestampStr '.csv']);
    writetable(T, csvFile);

    h4 = figure('Name', 'Figure4_MaxAbsError_vs_Amplitude', 'Color', 'w');
    hold on; grid on; box on;
    plot(amps, maxErrBPSK, '-o', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', 'BPSK');
    plot(amps, maxErrBOC,  '-s', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', 'BOC');
    xlabel('Multipath Amplitude', 'FontSize', 12);
    ylabel('Max Absolute Tracking Error', 'FontSize', 12);
    title(sprintf('Max Absolute Tracking Error vs Multipath Amplitude (Spacing = %.3f chip)', results.spacing), 'FontSize', 13);
    legend('Location', 'northwest');
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);
    helpers.safeSaveFigure(h4, fullfile(outDir, ['paper_max_abs_error_vs_amplitude_' timestampStr]));

    h5 = figure('Name', 'Figure5_BPSK_Envelope_vs_Amplitude', 'Color', 'w');
    hold on; grid on; box on;
    nAmp = numel(amps);
    for k = 1:nAmp
        plot(results.delayAxisBPSK{k}, results.envelopeBPSK{k}, 'LineWidth', 1.8, 'DisplayName', sprintf('A = %.1f', amps(k)));
    end
    xlabel('Multipath Delay / chip', 'FontSize', 12);
    ylabel('Tracking Error', 'FontSize', 12);
    title(sprintf('BPSK Multipath Error Envelope (Spacing = %.3f chip)', results.spacing), 'FontSize', 13);
    legend('Location', 'northeast');
    xlim([0, 1.5]);
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);
    helpers.safeSaveFigure(h5, fullfile(outDir, ['paper_bpsk_envelope_vs_amplitude_' timestampStr]));

    h6 = figure('Name', 'Figure6_BOC_Envelope_vs_Amplitude', 'Color', 'w');
    hold on; grid on; box on;
    for k = 1:nAmp
        plot(results.delayAxisBOC{k}, results.envelopeBOC{k}, 'LineWidth', 1.8, 'DisplayName', sprintf('A = %.1f', amps(k)));
    end
    xlabel('Multipath Delay / chip', 'FontSize', 12);
    ylabel('Tracking Error', 'FontSize', 12);
    title(sprintf('BOC Multipath Error Envelope (Spacing = %.3f chip)', results.spacing), 'FontSize', 13);
    legend('Location', 'northeast');
    xlim([0, 1.5]);
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);
    helpers.safeSaveFigure(h6, fullfile(outDir, ['paper_boc_envelope_vs_amplitude_' timestampStr]));

    allPositive = all(errDiff > 0);
    meanImprovePct = mean(relImprovePct);

    summaryLines = {};
    summaryLines{end+1} = 'GNSS_Simulator Multipath Amplitude Scan Summary';
    summaryLines{end+1} = '================================================';
    summaryLines{end+1} = sprintf('Source MAT file: %s', latestMatFile);
    summaryLines{end+1} = sprintf('Export time: %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    summaryLines{end+1} = sprintf('Fixed Early-Late spacing: %.3f chip', results.spacing);
    summaryLines{end+1} = ' ';
    summaryLines{end+1} = 'Amplitude    Max|Err| BPSK    Max|Err| BOC    Improve(%)';
    summaryLines{end+1} = '--------------------------------------------------------';
    for k = 1:nAmp
        summaryLines{end+1} = sprintf('%8.3f    %14.6g    %13.6g    %10.4f', amps(k), maxErrBPSK(k), maxErrBOC(k), relImprovePct(k));
    end
    summaryLines{end+1} = ' ';
    if allPositive
        summaryLines{end+1} = 'Conclusion: BOC remains slightly better than BPSK over the full scanned amplitude range.';
    else
        summaryLines{end+1} = 'Conclusion: BOC is not better than BPSK at every scanned amplitude.';
    end
    summaryLines{end+1} = sprintf('Mean relative improvement of BOC vs BPSK: %.4f%%', meanImprovePct);

    txtFile = fullfile(outDir, ['paper_summary_' timestampStr '.txt']);
    helpers.writeTextFile(txtFile, summaryLines);

    paperExport = struct();
    paperExport.sourceMatFile = latestMatFile;
    paperExport.exportTime = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    paperExport.spacing = results.spacing;
    paperExport.amplitudes = amps;
    paperExport.maxAbsErrorBPSK = maxErrBPSK;
    paperExport.maxAbsErrorBOC = maxErrBOC;
    paperExport.absoluteImprovement = errDiff;
    paperExport.relativeImprovementPercent = relImprovePct;
    paperExport.meanImprovePercent = meanImprovePct;
    paperExport.allBOCBetterThanBPSK = allPositive;

    save(fullfile(outDir, ['paper_export_summary_' timestampStr '.mat']), 'paperExport', 'T');

    fprintf('已导出多径幅度扫描论文图表。\n');
    fprintf('源结果文件: %s\n', latestMatFile);
    fprintf('输出目录: %s\n', outDir);
end

function exportMultipathDelayPointSet(cfg, outDir)

    scanDir = fullfile(cfg.path.results, 'multipath_delay_point_scan');
    helpers.ensureDir(outDir);

    matFiles = dir(fullfile(scanDir, 'multipath_delay_point_scan_*.mat'));
    if isempty(matFiles)
        fprintf('未找到多径延迟点扫描 MAT 结果，跳过该部分导出。\n');
        fprintf('如需导出，请先运行：run_multipath_delay_point_scan\n');
        return;
    end

    [~, idxLatest] = max([matFiles.datenum]);
    latestMatFile = fullfile(matFiles(idxLatest).folder, matFiles(idxLatest).name);

    S = load(latestMatFile);
    if ~isfield(S, 'results')
        warning('结果文件中未找到 results 变量，跳过延迟点扫描导出：%s', latestMatFile);
        return;
    end

    results = S.results;
    timestampStr = datestr(now, 'yyyymmdd_HHMMSS');

    requiredFields = {'spacing','fixedMultipathAmplitude','fixedMultipathPhase','multipathDelaysChip','errorPointBPSK','errorPointBOC'};
    for i = 1:numel(requiredFields)
        if ~isfield(results, requiredFields{i})
            warning('results 中缺少字段 %s，跳过延迟点扫描导出。', requiredFields{i});
            return;
        end
    end

    delaysChip = results.multipathDelaysChip(:);
    errBPSK    = results.errorPointBPSK(:);
    errBOC     = results.errorPointBOC(:);

    absErrBPSK = abs(errBPSK);
    absErrBOC  = abs(errBOC);

    absDiff = absErrBPSK - absErrBOC;
    relImprovePct = 100 * absDiff ./ absErrBPSK;

    T = table(delaysChip,errBPSK,errBOC,absErrBPSK,absErrBOC,absDiff,relImprovePct, ...
        'VariableNames', {'MultipathDelayChip','TrackingError_BPSK','TrackingError_BOC','AbsTrackingError_BPSK','AbsTrackingError_BOC','AbsImprovement_BOC_vs_BPSK','RelativeImprovementPercent_BOC_vs_BPSK'});

    csvFile = fullfile(outDir, ['multipath_delay_point_summary_' timestampStr '.csv']);
    writetable(T, csvFile);

    h7 = figure('Name', 'Figure7_TrackingError_vs_SpecifiedDelay', 'Color', 'w');
    hold on; grid on; box on;
    plot(delaysChip, errBPSK, '-o', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', 'BPSK');
    plot(delaysChip, errBOC,  '-s', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', 'BOC');
    yline(0, '--');
    xlabel('Specified Multipath Delay / chip', 'FontSize', 12);
    ylabel('Tracking Error / chip', 'FontSize', 12);
    title(sprintf('Tracking Error vs Specified Multipath Delay (Spacing = %.3f chip, A = %.2f)', ...
        results.spacing, results.fixedMultipathAmplitude), 'FontSize', 13);
    legend('Location', 'best');
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);
    helpers.safeSaveFigure(h7, fullfile(outDir, ['paper_tracking_error_vs_specified_delay_' timestampStr]));

    h8 = figure('Name', 'Figure8_AbsTrackingError_vs_SpecifiedDelay', 'Color', 'w');
    hold on; grid on; box on;
    plot(delaysChip, absErrBPSK, '-o', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', '|BPSK|');
    plot(delaysChip, absErrBOC,  '-s', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', '|BOC|');
    xlabel('Specified Multipath Delay / chip', 'FontSize', 12);
    ylabel('Absolute Tracking Error / chip', 'FontSize', 12);
    title(sprintf('Absolute Tracking Error vs Specified Multipath Delay (Spacing = %.3f chip, A = %.2f)', ...
        results.spacing, results.fixedMultipathAmplitude), 'FontSize', 13);
    legend('Location', 'best');
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);
    helpers.safeSaveFigure(h8, fullfile(outDir, ['paper_abs_tracking_error_vs_specified_delay_' timestampStr]));

    allPositive = all(absDiff > 0);
    meanImprovePct = mean(relImprovePct(~isnan(relImprovePct) & ~isinf(relImprovePct)));

    summaryLines = {};
    summaryLines{end+1} = 'GNSS_Simulator Multipath Delay Point Scan Summary';
    summaryLines{end+1} = '=================================================';
    summaryLines{end+1} = sprintf('Source MAT file: %s', latestMatFile);
    summaryLines{end+1} = sprintf('Export time: %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    summaryLines{end+1} = sprintf('Fixed Early-Late spacing: %.3f chip', results.spacing);
    summaryLines{end+1} = sprintf('Fixed multipath amplitude: %.3f', results.fixedMultipathAmplitude);
    summaryLines{end+1} = sprintf('Fixed multipath phase: %.6f rad', results.fixedMultipathPhase);
    summaryLines{end+1} = ' ';
    summaryLines{end+1} = 'Delay(chip)    Err BPSK        Err BOC        |BPSK|          |BOC|       Improve(%)';
    summaryLines{end+1} = '--------------------------------------------------------------------------------------';
    for k = 1:numel(delaysChip)
        summaryLines{end+1} = sprintf('%10.3f    %12.6g    %12.6g    %12.6g    %12.6g    %10.4f', ...
            delaysChip(k), errBPSK(k), errBOC(k), absErrBPSK(k), absErrBOC(k), relImprovePct(k));
    end
    summaryLines{end+1} = ' ';
    if allPositive
        summaryLines{end+1} = 'Conclusion: BOC remains better than BPSK at all scanned specified delays in terms of absolute tracking error.';
    else
        summaryLines{end+1} = 'Conclusion: BOC is not better than BPSK at every scanned specified delay in terms of absolute tracking error.';
    end
    summaryLines{end+1} = sprintf('Mean relative improvement of BOC vs BPSK: %.4f%%', meanImprovePct);

    txtFile = fullfile(outDir, ['paper_summary_' timestampStr '.txt']);
    helpers.writeTextFile(txtFile, summaryLines);

    paperExport = struct();
    paperExport.sourceMatFile = latestMatFile;
    paperExport.exportTime = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    paperExport.spacing = results.spacing;
    paperExport.fixedMultipathAmplitude = results.fixedMultipathAmplitude;
    paperExport.fixedMultipathPhase = results.fixedMultipathPhase;
    paperExport.multipathDelaysChip = delaysChip;
    paperExport.errorPointBPSK = errBPSK;
    paperExport.errorPointBOC = errBOC;
    paperExport.absErrorBPSK = absErrBPSK;
    paperExport.absErrorBOC = absErrBOC;
    paperExport.absImprovement = absDiff;
    paperExport.relativeImprovementPercent = relImprovePct;
    paperExport.meanImprovePercent = meanImprovePct;
    paperExport.allBOCBetterThanBPSK = allPositive;

    save(fullfile(outDir, ['paper_export_summary_' timestampStr '.mat']), 'paperExport', 'T');

    fprintf('已导出多径延迟点扫描论文图表。\n');
    fprintf('源结果文件: %s\n', latestMatFile);
    fprintf('输出目录: %s\n', outDir);
end

function exportMultipathPhasePointSet(cfg, outDir)

    scanDir = fullfile(cfg.path.results, 'multipath_phase_point_scan');
    helpers.ensureDir(outDir);

    matFiles = dir(fullfile(scanDir, 'multipath_phase_point_scan_*.mat'));
    if isempty(matFiles)
        fprintf('未找到多径相位点扫描 MAT 结果，跳过该部分导出。\n');
        fprintf('如需导出，请先运行：run_multipath_phase_point_scan\n');
        return;
    end

    [~, idxLatest] = max([matFiles.datenum]);
    latestMatFile = fullfile(matFiles(idxLatest).folder, matFiles(idxLatest).name);

    S = load(latestMatFile);
    if ~isfield(S, 'results')
        warning('结果文件中未找到 results 变量，跳过相位点扫描导出：%s', latestMatFile);
        return;
    end

    results = S.results;
    timestampStr = datestr(now, 'yyyymmdd_HHMMSS');

    requiredFields = {'spacing','fixedMultipathAmplitude','fixedMultipathDelaySec','fixedMultipathDelayChip','multipathPhases','errorPointBPSK','errorPointBOC'};
    for i = 1:numel(requiredFields)
        if ~isfield(results, requiredFields{i})
            warning('results 中缺少字段 %s，跳过相位点扫描导出。', requiredFields{i});
            return;
        end
    end

    phases  = results.multipathPhases(:);
    errBPSK = results.errorPointBPSK(:);
    errBOC  = results.errorPointBOC(:);

    absErrBPSK = abs(errBPSK);
    absErrBOC  = abs(errBOC);

    absDiff = absErrBPSK - absErrBOC;
    relImprovePct = 100 * absDiff ./ absErrBPSK;

    T = table(phases,errBPSK,errBOC,absErrBPSK,absErrBOC,absDiff,relImprovePct, ...
        'VariableNames', {'MultipathPhaseRad','TrackingError_BPSK','TrackingError_BOC','AbsTrackingError_BPSK','AbsTrackingError_BOC','AbsImprovement_BOC_vs_BPSK','RelativeImprovementPercent_BOC_vs_BPSK'});

    csvFile = fullfile(outDir, ['multipath_phase_point_summary_' timestampStr '.csv']);
    writetable(T, csvFile);

    h9 = figure('Name', 'Figure9_TrackingError_vs_SpecifiedPhase', 'Color', 'w');
    hold on; grid on; box on;
    plot(phases, errBPSK, '-o', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', 'BPSK');
    plot(phases, errBOC,  '-s', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', 'BOC');
    yline(0, '--');
    xlabel('Specified Multipath Phase / rad', 'FontSize', 12);
    ylabel('Tracking Error / chip', 'FontSize', 12);
    title(sprintf('Tracking Error vs Specified Multipath Phase (Spacing = %.3f chip, A = %.2f, Delay = %.3f chip)', ...
        results.spacing, results.fixedMultipathAmplitude, results.fixedMultipathDelayChip), 'FontSize', 13);
    legend('Location', 'best');
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);
    helpers.safeSaveFigure(h9, fullfile(outDir, ['paper_tracking_error_vs_specified_phase_' timestampStr]));

    h10 = figure('Name', 'Figure10_AbsTrackingError_vs_SpecifiedPhase', 'Color', 'w');
    hold on; grid on; box on;
    plot(phases, absErrBPSK, '-o', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', '|BPSK|');
    plot(phases, absErrBOC,  '-s', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', '|BOC|');
    xlabel('Specified Multipath Phase / rad', 'FontSize', 12);
    ylabel('Absolute Tracking Error / chip', 'FontSize', 12);
    title(sprintf('Absolute Tracking Error vs Specified Multipath Phase (Spacing = %.3f chip, A = %.2f, Delay = %.3f chip)', ...
        results.spacing, results.fixedMultipathAmplitude, results.fixedMultipathDelayChip), 'FontSize', 13);
    legend('Location', 'best');
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);
    helpers.safeSaveFigure(h10, fullfile(outDir, ['paper_abs_tracking_error_vs_specified_phase_' timestampStr]));

    allPositive = all(absDiff > 0);
    meanImprovePct = mean(relImprovePct(~isnan(relImprovePct) & ~isinf(relImprovePct)));

    summaryLines = {};
    summaryLines{end+1} = 'GNSS_Simulator Multipath Phase Point Scan Summary';
    summaryLines{end+1} = '=================================================';
    summaryLines{end+1} = sprintf('Source MAT file: %s', latestMatFile);
    summaryLines{end+1} = sprintf('Export time: %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    summaryLines{end+1} = sprintf('Fixed Early-Late spacing: %.3f chip', results.spacing);
    summaryLines{end+1} = sprintf('Fixed multipath amplitude: %.3f', results.fixedMultipathAmplitude);
    summaryLines{end+1} = sprintf('Fixed multipath delay: %.6e s (%.3f chip)', results.fixedMultipathDelaySec, results.fixedMultipathDelayChip);
    summaryLines{end+1} = ' ';
    summaryLines{end+1} = 'Phase(rad)     Err BPSK        Err BOC        |BPSK|          |BOC|       Improve(%)';
    summaryLines{end+1} = '--------------------------------------------------------------------------------------';
    for k = 1:numel(phases)
        summaryLines{end+1} = sprintf('%10.6f    %12.6g    %12.6g    %12.6g    %12.6g    %10.4f', ...
            phases(k), errBPSK(k), errBOC(k), absErrBPSK(k), absErrBOC(k), relImprovePct(k));
    end
    summaryLines{end+1} = ' ';
    if allPositive
        summaryLines{end+1} = 'Conclusion: BOC remains better than BPSK at all scanned specified phases in terms of absolute tracking error.';
    else
        summaryLines{end+1} = 'Conclusion: BOC is not better than BPSK at every scanned specified phase in terms of absolute tracking error.';
    end
    summaryLines{end+1} = sprintf('Mean relative improvement of BOC vs BPSK: %.4f%%', meanImprovePct);

    txtFile = fullfile(outDir, ['paper_summary_' timestampStr '.txt']);
    helpers.writeTextFile(txtFile, summaryLines);

    paperExport = struct();
    paperExport.sourceMatFile = latestMatFile;
    paperExport.exportTime = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    paperExport.spacing = results.spacing;
    paperExport.fixedMultipathAmplitude = results.fixedMultipathAmplitude;
    paperExport.fixedMultipathDelaySec = results.fixedMultipathDelaySec;
    paperExport.fixedMultipathDelayChip = results.fixedMultipathDelayChip;
    paperExport.multipathPhases = phases;
    paperExport.errorPointBPSK = errBPSK;
    paperExport.errorPointBOC = errBOC;
    paperExport.absErrorBPSK = absErrBPSK;
    paperExport.absErrorBOC = absErrBOC;
    paperExport.absImprovement = absDiff;
    paperExport.relativeImprovementPercent = relImprovePct;
    paperExport.meanImprovePercent = meanImprovePct;
    paperExport.allBOCBetterThanBPSK = allPositive;

    save(fullfile(outDir, ['paper_export_summary_' timestampStr '.mat']), 'paperExport', 'T');

    fprintf('已导出多径相位点扫描论文图表。\n');
    fprintf('源结果文件: %s\n', latestMatFile);
    fprintf('输出目录: %s\n', outDir);
end

function exportSpacingStability3DSet(cfg, outDir)

    scanDir = fullfile(cfg.path.results, 'spacing_stability_3d_scan');
    helpers.ensureDir(outDir);

    matFiles = dir(fullfile(scanDir, 'spacing_stability_3d_scan_*.mat'));
    if isempty(matFiles)
        fprintf('未找到 spacing 三维稳定性 MAT 结果，跳过该部分导出。\n');
        fprintf('如需导出，请先运行：run_spacing_stability_3d_scan\n');
        return;
    end

    [~, idxLatest] = max([matFiles.datenum]);
    latestMatFile = fullfile(matFiles(idxLatest).folder, matFiles(idxLatest).name);

    S = load(latestMatFile);
    if ~isfield(S, 'results')
        warning('结果文件中未找到 results 变量，跳过 spacing 三维稳定性导出：%s', latestMatFile);
        return;
    end

    results = S.results;
    timestampStr = datestr(now, 'yyyymmdd_HHMMSS');

    requiredFields = {'spacingList','ampWorstAbsBPSK','ampWorstAbsBOC','delayWorstAbsBPSK','delayWorstAbsBOC', ...
        'phaseWorstAbsBPSK','phaseWorstAbsBOC','overallWorstAbsBPSK','overallWorstAbsBOC', ...
        'overallMeanAbsBPSK','overallMeanAbsBOC','bestSpacingWorstBPSK','bestSpacingWorstBOC', ...
        'bestSpacingMeanBPSK','bestSpacingMeanBOC'};

    for i = 1:numel(requiredFields)
        if ~isfield(results, requiredFields{i})
            warning('results 中缺少字段 %s，跳过 spacing 三维稳定性导出。', requiredFields{i});
            return;
        end
    end

    spacingList = results.spacingList(:);

    T = table( ...
        spacingList, ...
        results.ampWorstAbsBPSK(:), ...
        results.ampWorstAbsBOC(:), ...
        results.delayWorstAbsBPSK(:), ...
        results.delayWorstAbsBOC(:), ...
        results.phaseWorstAbsBPSK(:), ...
        results.phaseWorstAbsBOC(:), ...
        results.overallWorstAbsBPSK(:), ...
        results.overallWorstAbsBOC(:), ...
        results.overallMeanAbsBPSK(:), ...
        results.overallMeanAbsBOC(:), ...
        'VariableNames', { ...
        'SpacingChip', ...
        'AmpWorstAbs_BPSK', ...
        'AmpWorstAbs_BOC', ...
        'DelayWorstAbs_BPSK', ...
        'DelayWorstAbs_BOC', ...
        'PhaseWorstAbs_BPSK', ...
        'PhaseWorstAbs_BOC', ...
        'OverallWorstAbs_BPSK', ...
        'OverallWorstAbs_BOC', ...
        'OverallMeanAbs_BPSK', ...
        'OverallMeanAbs_BOC'});

    csvFile = fullfile(outDir, ['spacing_stability_3d_summary_' timestampStr '.csv']);
    writetable(T, csvFile);

    h11 = figure('Name', 'Figure11_OverallWorstAbsError_vs_Spacing', 'Color', 'w');
    hold on; grid on; box on;
    plot(spacingList, results.overallWorstAbsBPSK, '-o', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', 'BPSK');
    plot(spacingList, results.overallWorstAbsBOC,  '-s', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', 'BOC');
    xlabel('Early-Late Spacing / chip', 'FontSize', 12);
    ylabel('Overall Worst Absolute Tracking Error', 'FontSize', 12);
    title('Overall Worst Absolute Error vs Early-Late Spacing', 'FontSize', 13);
    legend('Location', 'best');
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);
    helpers.safeSaveFigure(h11, fullfile(outDir, ['paper_overall_worst_abs_error_vs_spacing_' timestampStr]));

    h12 = figure('Name', 'Figure12_BPSK_3DWorst_vs_Spacing', 'Color', 'w');
    hold on; grid on; box on;
    plot(spacingList, results.ampWorstAbsBPSK,   '-o', 'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'Amplitude');
    plot(spacingList, results.delayWorstAbsBPSK, '-s', 'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'Delay');
    plot(spacingList, results.phaseWorstAbsBPSK, '-d', 'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'Phase');
    xlabel('Early-Late Spacing / chip', 'FontSize', 12);
    ylabel('Worst Absolute Tracking Error', 'FontSize', 12);
    title('BPSK Worst Absolute Error in Three Dimensions', 'FontSize', 13);
    legend('Location', 'best');
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);
    helpers.safeSaveFigure(h12, fullfile(outDir, ['paper_bpsk_3d_worst_abs_error_vs_spacing_' timestampStr]));

    h13 = figure('Name', 'Figure13_BOC_3DWorst_vs_Spacing', 'Color', 'w');
    hold on; grid on; box on;
    plot(spacingList, results.ampWorstAbsBOC,   '-o', 'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'Amplitude');
    plot(spacingList, results.delayWorstAbsBOC, '-s', 'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'Delay');
    plot(spacingList, results.phaseWorstAbsBOC, '-d', 'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'Phase');
    xlabel('Early-Late Spacing / chip', 'FontSize', 12);
    ylabel('Worst Absolute Tracking Error', 'FontSize', 12);
    title('BOC Worst Absolute Error in Three Dimensions', 'FontSize', 13);
    legend('Location', 'best');
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);
    helpers.safeSaveFigure(h13, fullfile(outDir, ['paper_boc_3d_worst_abs_error_vs_spacing_' timestampStr]));

    h14 = figure('Name', 'Figure14_OverallMeanAbsError_vs_Spacing', 'Color', 'w');
    hold on; grid on; box on;
    plot(spacingList, results.overallMeanAbsBPSK, '-o', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', 'BPSK');
    plot(spacingList, results.overallMeanAbsBOC,  '-s', 'LineWidth', 2.0, 'MarkerSize', 7, 'DisplayName', 'BOC');
    xlabel('Early-Late Spacing / chip', 'FontSize', 12);
    ylabel('Overall Mean Absolute Tracking Error', 'FontSize', 12);
    title('Overall Mean Absolute Error vs Early-Late Spacing', 'FontSize', 13);
    legend('Location', 'best');
    set(gca, 'FontSize', 11, 'LineWidth', 1.0);
    helpers.safeSaveFigure(h14, fullfile(outDir, ['paper_overall_mean_abs_error_vs_spacing_' timestampStr]));

    summaryLines = {};
    summaryLines{end+1} = 'GNSS_Simulator Spacing Stability 3D Scan Summary';
    summaryLines{end+1} = '================================================';
    summaryLines{end+1} = sprintf('Source MAT file: %s', latestMatFile);
    summaryLines{end+1} = sprintf('Export time: %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    summaryLines{end+1} = ' ';
    summaryLines{end+1} = 'Spacing   Worst(BPSK)   Worst(BOC)   Mean(BPSK)   Mean(BOC)';
    summaryLines{end+1} = '------------------------------------------------------------';

    for i = 1:numel(spacingList)
        summaryLines{end+1} = sprintf('%7.3f   %11.6g   %10.6g   %10.6g   %9.6g', ...
            spacingList(i), ...
            results.overallWorstAbsBPSK(i), ...
            results.overallWorstAbsBOC(i), ...
            results.overallMeanAbsBPSK(i), ...
            results.overallMeanAbsBOC(i));
    end

    summaryLines{end+1} = ' ';
    summaryLines{end+1} = sprintf('Best spacing by overall worst-case error (BPSK): %.3f chip', results.bestSpacingWorstBPSK);
    summaryLines{end+1} = sprintf('Best spacing by overall worst-case error (BOC): %.3f chip', results.bestSpacingWorstBOC);
    summaryLines{end+1} = sprintf('Best spacing by overall mean absolute error (BPSK): %.3f chip', results.bestSpacingMeanBPSK);
    summaryLines{end+1} = sprintf('Best spacing by overall mean absolute error (BOC): %.3f chip', results.bestSpacingMeanBOC);

    txtFile = fullfile(outDir, ['paper_summary_' timestampStr '.txt']);
    helpers.writeTextFile(txtFile, summaryLines);

    paperExport = struct();
    paperExport.sourceMatFile = latestMatFile;
    paperExport.exportTime = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    paperExport.spacingList = spacingList;
    paperExport.overallWorstAbsBPSK = results.overallWorstAbsBPSK(:);
    paperExport.overallWorstAbsBOC  = results.overallWorstAbsBOC(:);
    paperExport.overallMeanAbsBPSK  = results.overallMeanAbsBPSK(:);
    paperExport.overallMeanAbsBOC   = results.overallMeanAbsBOC(:);
    paperExport.bestSpacingWorstBPSK = results.bestSpacingWorstBPSK;
    paperExport.bestSpacingWorstBOC  = results.bestSpacingWorstBOC;
    paperExport.bestSpacingMeanBPSK  = results.bestSpacingMeanBPSK;
    paperExport.bestSpacingMeanBOC   = results.bestSpacingMeanBOC;

    save(fullfile(outDir, ['paper_export_summary_' timestampStr '.mat']), 'paperExport', 'T');

    fprintf('已导出 spacing 三维稳定性论文图表。\n');
    fprintf('源结果文件: %s\n', latestMatFile);
    fprintf('输出目录: %s\n', outDir);
end