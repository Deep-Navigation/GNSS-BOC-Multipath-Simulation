function results = runMultipathPhasePointScan(cfg, multipathPhases)
%RUNMULTIPATHPHASEPOINTSCAN
% analysis 层：只负责多径相位点扫描计算，不负责绘图与保存。
%
% 使用方式：
%   results = analysis.runMultipathPhasePointScan(cfg)
%   results = analysis.runMultipathPhasePointScan(cfg, multipathPhases)

    if nargin < 1 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 2 || isempty(multipathPhases)
        multipathPhases = linspace(0, 2*pi, 9);
    end

    cfg.tracking.earlyLateSpacing = 0.04;
    cfg.scurve.earlyLateSpacing   = cfg.tracking.earlyLateSpacing;

    multipathPhases = multipathPhases(:).';

    fixedMultipathAmplitude = cfg.multipath.paths(1).amplitude;
    fixedMultipathDelaySec  = cfg.multipath.paths(1).delay;
    fixedMultipathDelayChip = fixedMultipathDelaySec * cfg.code.chipRate;

    nPhase = numel(multipathPhases);

    results = struct();
    results.scanType = 'multipath_phase_point_scan';
    results.timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    results.cfgBase = cfg;
    results.spacing = cfg.tracking.earlyLateSpacing;

    results.fixedMultipathAmplitude = fixedMultipathAmplitude;
    results.fixedMultipathDelaySec  = fixedMultipathDelaySec;
    results.fixedMultipathDelayChip = fixedMultipathDelayChip;
    results.multipathPhases         = multipathPhases;

    results.errorPointBPSK = zeros(1, nPhase);
    results.errorPointBOC  = zeros(1, nPhase);

    for k = 1:nPhase
        phaseRad = multipathPhases(k);

        cfgPhase = cfg;
        cfgPhase.multipath.paths(1).delay     = fixedMultipathDelaySec;
        cfgPhase.multipath.paths(1).amplitude = fixedMultipathAmplitude;
        cfgPhase.multipath.paths(1).phase     = phaseRad;

        cfgPhase.signal.modType = 'BPSK';
        results.errorPointBPSK(k) = analysis.evaluateSingleTrackingError(cfgPhase);

        cfgPhase.signal.modType = 'BOC';
        results.errorPointBOC(k) = analysis.evaluateSingleTrackingError(cfgPhase);
    end

    results.summary = buildSummary(results);
end

%% ========================= Local Functions =========================
function summary = buildSummary(results)
    summary = struct();
    summary.title = 'Multipath Phase Point Scan Summary';
    summary.spacing = results.spacing;
    summary.numPoints = numel(results.multipathPhases);
    summary.scanAxisName = 'multipathPhases';

    [summary.minAbsErrorBPSK, idxB] = min(abs(results.errorPointBPSK));
    [summary.minAbsErrorBOC,  idxC] = min(abs(results.errorPointBOC));

    summary.bestPhaseBPSK = results.multipathPhases(idxB);
    summary.bestPhaseBOC  = results.multipathPhases(idxC);

    summary.maxAbsErrorBPSK = max(abs(results.errorPointBPSK));
    summary.maxAbsErrorBOC  = max(abs(results.errorPointBOC));

    summary.meanAbsErrorBPSK = mean(abs(results.errorPointBPSK));
    summary.meanAbsErrorBOC  = mean(abs(results.errorPointBOC));
end