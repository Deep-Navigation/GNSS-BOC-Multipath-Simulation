function results = runSpacingStability3DScan(cfg, spacingList, amplitudeList, delayListChip, phaseList)
%RUNSPACINGSTABILITY3DSCAN
% analysis 层：只负责 spacing stability 3D 扫描计算，不负责绘图与保存。
%
% 使用方式：
%   results = analysis.runSpacingStability3DScan(cfg)
%   results = analysis.runSpacingStability3DScan(cfg, spacingList)
%   results = analysis.runSpacingStability3DScan(cfg, spacingList, amplitudeList, delayListChip, phaseList)

    %% 1) 输入处理
    if nargin < 1 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 2 || isempty(spacingList)
        spacingList = [0.02, 0.03, 0.04, 0.05, 0.06, 0.08, 0.10];
    end

    if nargin < 3 || isempty(amplitudeList)
        amplitudeList = [0.2, 0.4, 0.6, 0.8, 1.0];
    end

    if nargin < 4 || isempty(delayListChip)
        delayListChip = [0.05, 0.10, 0.20, 0.30, 0.50];
    end

    if nargin < 5 || isempty(phaseList)
        phaseList = [0, pi/6, pi/3, pi/2, 2*pi/3, 5*pi/6, pi, 4*pi/3, 3*pi/2, 5*pi/3];
    end

    spacingList = spacingList(:).';
    amplitudeList = amplitudeList(:).';
    delayListChip = delayListChip(:).';
    phaseList = phaseList(:).';
    delayListSec = delayListChip / cfg.code.chipRate;

    fixedAmpForDelayPhase   = cfg.multipath.paths(1).amplitude;
    fixedDelaySecForAmp     = cfg.multipath.paths(1).delay;
    fixedDelayChipForAmp    = fixedDelaySecForAmp * cfg.code.chipRate;
    fixedPhaseForAmpDelay   = cfg.multipath.paths(1).phase;

    nSpacing = numel(spacingList);

    %% 2) 结果预分配
    results = struct();
    results.scanType = 'spacing_stability_3d_scan';
    results.timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    results.cfgBase = cfg;
    results.spacing = NaN;

    results.spacingList = spacingList;
    results.amplitudeList = amplitudeList;
    results.delayListChip = delayListChip;
    results.delayListSec  = delayListSec;
    results.phaseList     = phaseList;

    results.fixedAmpForDelayPhase = fixedAmpForDelayPhase;
    results.fixedDelaySecForAmp   = fixedDelaySecForAmp;
    results.fixedDelayChipForAmp  = fixedDelayChipForAmp;
    results.fixedPhaseForAmpDelay = fixedPhaseForAmpDelay;

    results.amplitudeErrBPSK = cell(1, nSpacing);
    results.amplitudeErrBOC  = cell(1, nSpacing);
    results.delayErrBPSK     = cell(1, nSpacing);
    results.delayErrBOC      = cell(1, nSpacing);
    results.phaseErrBPSK     = cell(1, nSpacing);
    results.phaseErrBOC      = cell(1, nSpacing);

    results.ampWorstAbsBPSK   = zeros(1, nSpacing);
    results.ampWorstAbsBOC    = zeros(1, nSpacing);
    results.delayWorstAbsBPSK = zeros(1, nSpacing);
    results.delayWorstAbsBOC  = zeros(1, nSpacing);
    results.phaseWorstAbsBPSK = zeros(1, nSpacing);
    results.phaseWorstAbsBOC  = zeros(1, nSpacing);

    results.overallWorstAbsBPSK = zeros(1, nSpacing);
    results.overallWorstAbsBOC  = zeros(1, nSpacing);
    results.overallMeanAbsBPSK  = zeros(1, nSpacing);
    results.overallMeanAbsBOC   = zeros(1, nSpacing);

    %% 3) 主循环：扫描 spacing
    for i = 1:nSpacing
        spacing = spacingList(i);

        cfgSpacing = cfg;
        cfgSpacing.tracking.earlyLateSpacing = spacing;
        cfgSpacing.scurve.earlyLateSpacing   = cfgSpacing.tracking.earlyLateSpacing;

        %% ---------- 幅度维度 ----------
        ampErrBPSK = zeros(size(amplitudeList));
        ampErrBOC  = zeros(size(amplitudeList));

        for k = 1:numel(amplitudeList)
            amp = amplitudeList(k);

            cfgAmp = cfgSpacing;
            cfgAmp.multipath.paths(1).amplitude = amp;
            cfgAmp.multipath.paths(1).delay     = fixedDelaySecForAmp;
            cfgAmp.multipath.paths(1).phase     = fixedPhaseForAmpDelay;

            cfgAmp.signal.modType = 'BPSK';
            ampErrBPSK(k) = analysis.evaluateSingleTrackingError(cfgAmp);

            cfgAmp.signal.modType = 'BOC';
            ampErrBOC(k) = analysis.evaluateSingleTrackingError(cfgAmp);
        end

        %% ---------- 延迟维度 ----------
        delayErrBPSK = zeros(size(delayListChip));
        delayErrBOC  = zeros(size(delayListChip));

        for k = 1:numel(delayListSec)
            dsec = delayListSec(k);

            cfgDelay = cfgSpacing;
            cfgDelay.multipath.paths(1).amplitude = fixedAmpForDelayPhase;
            cfgDelay.multipath.paths(1).delay     = dsec;
            cfgDelay.multipath.paths(1).phase     = fixedPhaseForAmpDelay;

            cfgDelay.signal.modType = 'BPSK';
            delayErrBPSK(k) = analysis.evaluateSingleTrackingError(cfgDelay);

            cfgDelay.signal.modType = 'BOC';
            delayErrBOC(k) = analysis.evaluateSingleTrackingError(cfgDelay);
        end

        %% ---------- 相位维度 ----------
        phaseErrBPSK = zeros(size(phaseList));
        phaseErrBOC  = zeros(size(phaseList));

        for k = 1:numel(phaseList)
            ph = phaseList(k);

            cfgPhase = cfgSpacing;
            cfgPhase.multipath.paths(1).amplitude = fixedAmpForDelayPhase;
            cfgPhase.multipath.paths(1).delay     = fixedDelaySecForAmp;
            cfgPhase.multipath.paths(1).phase     = ph;

            cfgPhase.signal.modType = 'BPSK';
            phaseErrBPSK(k) = analysis.evaluateSingleTrackingError(cfgPhase);

            cfgPhase.signal.modType = 'BOC';
            phaseErrBOC(k) = analysis.evaluateSingleTrackingError(cfgPhase);
        end

        results.amplitudeErrBPSK{i} = ampErrBPSK;
        results.amplitudeErrBOC{i}  = ampErrBOC;
        results.delayErrBPSK{i}     = delayErrBPSK;
        results.delayErrBOC{i}      = delayErrBOC;
        results.phaseErrBPSK{i}     = phaseErrBPSK;
        results.phaseErrBOC{i}      = phaseErrBOC;

        results.ampWorstAbsBPSK(i)   = max(abs(ampErrBPSK));
        results.ampWorstAbsBOC(i)    = max(abs(ampErrBOC));
        results.delayWorstAbsBPSK(i) = max(abs(delayErrBPSK));
        results.delayWorstAbsBOC(i)  = max(abs(delayErrBOC));
        results.phaseWorstAbsBPSK(i) = max(abs(phaseErrBPSK));
        results.phaseWorstAbsBOC(i)  = max(abs(phaseErrBOC));

        results.overallWorstAbsBPSK(i) = max([ ...
            results.ampWorstAbsBPSK(i), ...
            results.delayWorstAbsBPSK(i), ...
            results.phaseWorstAbsBPSK(i)]);

        results.overallWorstAbsBOC(i) = max([ ...
            results.ampWorstAbsBOC(i), ...
            results.delayWorstAbsBOC(i), ...
            results.phaseWorstAbsBOC(i)]);

        allAbsBPSK = [abs(ampErrBPSK), abs(delayErrBPSK), abs(phaseErrBPSK)];
        allAbsBOC  = [abs(ampErrBOC),  abs(delayErrBOC),  abs(phaseErrBOC)];

        results.overallMeanAbsBPSK(i) = mean(allAbsBPSK);
        results.overallMeanAbsBOC(i)  = mean(allAbsBOC);
    end

    %% 4) 选择最优 spacing
    [results.bestOverallWorstBPSK, idxBestWorstBPSK] = min(results.overallWorstAbsBPSK);
    [results.bestOverallWorstBOC,  idxBestWorstBOC]  = min(results.overallWorstAbsBOC);

    [results.bestOverallMeanBPSK, idxBestMeanBPSK] = min(results.overallMeanAbsBPSK);
    [results.bestOverallMeanBOC,  idxBestMeanBOC]  = min(results.overallMeanAbsBOC);

    results.bestSpacingWorstBPSK = spacingList(idxBestWorstBPSK);
    results.bestSpacingWorstBOC  = spacingList(idxBestWorstBOC);
    results.bestSpacingMeanBPSK  = spacingList(idxBestMeanBPSK);
    results.bestSpacingMeanBOC   = spacingList(idxBestMeanBOC);

    results.summary = buildSummary(results);
end

%% ========================= Local Functions =========================
function summary = buildSummary(results)
    summary = struct();
    summary.title = 'Spacing Stability 3D Scan Summary';
    summary.spacing = NaN;
    summary.numPoints = numel(results.spacingList);
    summary.numSpacing = numel(results.spacingList);
    summary.scanAxisName = 'spacingList';

    summary.bestSpacingWorstBPSK = results.bestSpacingWorstBPSK;
    summary.bestSpacingWorstBOC  = results.bestSpacingWorstBOC;
    summary.bestSpacingMeanBPSK  = results.bestSpacingMeanBPSK;
    summary.bestSpacingMeanBOC   = results.bestSpacingMeanBOC;

    summary.bestOverallWorstBPSK = results.bestOverallWorstBPSK;
    summary.bestOverallWorstBOC  = results.bestOverallWorstBOC;
    summary.bestOverallMeanBPSK  = results.bestOverallMeanBPSK;
    summary.bestOverallMeanBOC   = results.bestOverallMeanBOC;
end