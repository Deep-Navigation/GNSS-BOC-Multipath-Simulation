function results = runMultipathDelayPointScan(cfg, multipathDelaysChip)
%RUNMULTIPATHDELAYPOINTSCAN
% analysis 层：只负责多径延迟点扫描计算，不负责绘图与保存。
%
% 使用方式：
%   results = analysis.runMultipathDelayPointScan(cfg)
%   results = analysis.runMultipathDelayPointScan(cfg, multipathDelaysChip)

    if nargin < 1 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 2 || isempty(multipathDelaysChip)
        multipathDelaysChip = [0.05, 0.10, 0.20, 0.30, 0.50];
    end

    cfg.tracking.earlyLateSpacing = 0.04;
    cfg.scurve.earlyLateSpacing   = cfg.tracking.earlyLateSpacing;

    multipathDelaysChip = multipathDelaysChip(:).';
    multipathDelaysSec  = multipathDelaysChip / cfg.code.chipRate;

    fixedMultipathAmplitude = cfg.multipath.paths(1).amplitude;
    fixedMultipathPhase     = cfg.multipath.paths(1).phase;

    nDelay = numel(multipathDelaysChip);

    results = struct();
    results.scanType = 'multipath_delay_point_scan';
    results.timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    results.cfgBase = cfg;
    results.spacing = cfg.tracking.earlyLateSpacing;

    results.fixedMultipathAmplitude = fixedMultipathAmplitude;
    results.fixedMultipathPhase     = fixedMultipathPhase;
    results.multipathDelaysChip     = multipathDelaysChip;
    results.multipathDelaysSec      = multipathDelaysSec;

    results.errorPointBPSK = zeros(1, nDelay);
    results.errorPointBOC  = zeros(1, nDelay);

    for k = 1:nDelay
        delaySec = multipathDelaysSec(k);

        cfgDelay = cfg;
        cfgDelay.multipath.paths(1).delay     = delaySec;
        cfgDelay.multipath.paths(1).amplitude = fixedMultipathAmplitude;
        cfgDelay.multipath.paths(1).phase     = fixedMultipathPhase;

        cfgDelay.signal.modType = 'BPSK';
        results.errorPointBPSK(k) = analysis.evaluateSingleTrackingError(cfgDelay);

        cfgDelay.signal.modType = 'BOC';
        results.errorPointBOC(k) = analysis.evaluateSingleTrackingError(cfgDelay);
    end

    results.summary = buildSummary(results);
end

%% ========================= Local Functions =========================
function summary = buildSummary(results)
    summary = struct();
    summary.title = 'Multipath Delay Point Scan Summary';
    summary.spacing = results.spacing;
    summary.numPoints = numel(results.multipathDelaysChip);
    summary.scanAxisName = 'multipathDelaysChip';

    [summary.minAbsErrorBPSK, idxB] = min(abs(results.errorPointBPSK));
    [summary.minAbsErrorBOC,  idxC] = min(abs(results.errorPointBOC));

    summary.bestDelayChipBPSK = results.multipathDelaysChip(idxB);
    summary.bestDelayChipBOC  = results.multipathDelaysChip(idxC);

    summary.maxAbsErrorBPSK = max(abs(results.errorPointBPSK));
    summary.maxAbsErrorBOC  = max(abs(results.errorPointBOC));

    summary.meanAbsErrorBPSK = mean(abs(results.errorPointBPSK));
    summary.meanAbsErrorBOC  = mean(abs(results.errorPointBOC));
end