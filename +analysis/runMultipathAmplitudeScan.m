function results = runMultipathAmplitudeScan(cfg, multipathAmplitudes)
%RUNMULTIPATHAMPLITUDESCAN
% analysis 层：只负责多径幅度扫描计算，不负责绘图与保存。
%
% 使用方式：
%   results = analysis.runMultipathAmplitudeScan(cfg)
%   results = analysis.runMultipathAmplitudeScan(cfg, multipathAmplitudes)
%
% 说明：
%   - 本函数是给主入口脚本与后续 GUI 调用的计算后端
%   - 只计算并返回 results
%   - 不进行 save / figure export / close all / clc

    if nargin < 1 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 2 || isempty(multipathAmplitudes)
        if isfield(cfg, 'experiment') && isfield(cfg.experiment, 'attenuationSweep')
            multipathAmplitudes = cfg.experiment.attenuationSweep;
        else
            multipathAmplitudes = [0.2, 0.4, 0.6, 0.8];
        end
    end

    % 保持 tracking / scurve spacing 一致
    cfg.tracking.earlyLateSpacing = 0.04;
    cfg.scurve.earlyLateSpacing   = cfg.tracking.earlyLateSpacing;

    %% 1) 一次性生成 PRN、BPSK、BOC 信号
    prn = buildPRN(cfg);
    txSigBPSK = buildBPSKSignal(prn, cfg);
    txSigBOC  = buildBOCSignal(prn, cfg);

    %% 2) 结果预分配
    nAmp = numel(multipathAmplitudes);

    results = struct();
    results.cfgBase = cfg;
    results.timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    results.spacing = cfg.tracking.earlyLateSpacing;
    results.multipathAmplitudes = multipathAmplitudes(:).';

    results.delayAxisBPSK = cell(1, nAmp);
    results.delayAxisBOC  = cell(1, nAmp);
    results.envelopeBPSK  = cell(1, nAmp);
    results.envelopeBOC   = cell(1, nAmp);

    results.maxAbsErrorBPSK = zeros(1, nAmp);
    results.maxAbsErrorBOC  = zeros(1, nAmp);

    %% 3) 多径幅度扫描计算
    for k = 1:nAmp
        amp = multipathAmplitudes(k);

        cfgAmp = cfg;
        cfgAmp.multipath.paths(1).amplitude = amp;

        % ---------- BPSK ----------
        cfgAmp.signal.modType = 'BPSK';
        [delayAxisBPSK, envelopeBPSK] = computeEnvelopeWithAdapter(txSigBPSK, cfgAmp);
        results.delayAxisBPSK{k} = delayAxisBPSK;
        results.envelopeBPSK{k}  = envelopeBPSK;
        results.maxAbsErrorBPSK(k) = max(abs(envelopeBPSK(:)));

        % ---------- BOC ----------
        cfgAmp.signal.modType = 'BOC';
        [delayAxisBOC, envelopeBOC] = computeEnvelopeWithAdapter(txSigBOC, cfgAmp);
        results.delayAxisBOC{k} = delayAxisBOC;
        results.envelopeBOC{k}  = envelopeBOC;
        results.maxAbsErrorBOC(k) = max(abs(envelopeBOC(:)));
    end
end

%% ========================= Local Functions =========================
function prn = buildPRN(cfg)
    try
        prn = core.generatePRN(cfg);
        return;
    catch
    end
    try
        prn = core.generatePRN(cfg.prn.prnId, cfg);
        return;
    catch
    end
    try
        prn = core.generatePRN(cfg.prn);
        return;
    catch
    end
    error('analysis.runMultipathAmplitudeScan/buildPRN: 无法匹配 core.generatePRN 的函数签名。');
end

function sig = buildBPSKSignal(prn, cfg)
    try
        [sig, ~] = core.bpskModulate(prn, cfg);
        return;
    catch
    end
    try
        sig = core.bpskModulate(prn, cfg);
        return;
    catch
    end
    try
        [sig, ~] = core.bpskModulate(cfg, prn);
        return;
    catch
    end
    try
        sig = core.bpskModulate(cfg, prn);
        return;
    catch
    end
    try
        [sig, ~] = core.bpskModulate(prn);
        return;
    catch
    end
    try
        sig = core.bpskModulate(prn);
        return;
    catch
    end
    error('analysis.runMultipathAmplitudeScan/buildBPSKSignal: 无法匹配 core.bpskModulate 的函数签名。');
end

function sig = buildBOCSignal(prn, cfg)
    try
        [sig, ~, ~] = core.bocModulate(prn, cfg);
        return;
    catch
    end
    try
        sig = core.bocModulate(prn, cfg);
        return;
    catch
    end
    try
        [sig, ~, ~] = core.bocModulate(cfg, prn);
        return;
    catch
    end
    try
        sig = core.bocModulate(cfg, prn);
        return;
    catch
    end
    try
        [sig, ~, ~] = core.bocModulate(prn);
        return;
    catch
    end
    try
        sig = core.bocModulate(prn);
        return;
    catch
    end
    error('analysis.runMultipathAmplitudeScan/buildBOCSignal: 无法匹配 core.bocModulate 的函数签名。');
end

function [delayAxis, envelope] = computeEnvelopeWithAdapter(txSig, cfg)
    try
        [delayAxis, envelope] = utils.computeMultipathEnvelope(txSig, cfg);
        envelope = forceNumericEnvelope(envelope);
        delayAxis = normalizeDelayAxis(delayAxis, envelope);
        return;
    catch
    end

    try
        out = utils.computeMultipathEnvelope(txSig, cfg);
        [delayAxis, envelope] = parseEnvelopeOutput(out);
        return;
    catch
    end

    try
        [delayAxis, envelope] = utils.computeMultipathEnvelope(cfg, txSig);
        envelope = forceNumericEnvelope(envelope);
        delayAxis = normalizeDelayAxis(delayAxis, envelope);
        return;
    catch
    end

    try
        out = utils.computeMultipathEnvelope(cfg, txSig);
        [delayAxis, envelope] = parseEnvelopeOutput(out);
        return;
    catch
    end

    try
        [delayAxis, envelope] = utils.computeMultipathEnvelope(cfg);
        envelope = forceNumericEnvelope(envelope);
        delayAxis = normalizeDelayAxis(delayAxis, envelope);
        return;
    catch
    end

    error(['analysis.runMultipathAmplitudeScan/computeEnvelopeWithAdapter: 无法匹配 ', ...
           'utils.computeMultipathEnvelope 的签名。']);
end

function [delayAxis, envelope] = parseEnvelopeOutput(out)
    if isnumeric(out)
        envelope = forceNumericEnvelope(out);
        delayAxis = (1:numel(envelope)).';
        return;
    end

    if isstruct(out)
        envelope = [];
        delayAxis = [];

        envelopeFields = { ...
            'envelope', ...
            'errorEnvelope', ...
            'mpEnvelope', ...
            'multipathEnvelope', ...
            'trackingErrorEnvelope', ...
            'errEnv', ...
            'y'};

        for i = 1:numel(envelopeFields)
            fn = envelopeFields{i};
            if isfield(out, fn)
                envelope = forceNumericEnvelope(out.(fn));
                break;
            end
        end

        delayFields = { ...
            'delayAxis', ...
            'delays', ...
            'delayChips', ...
            'tau', ...
            'tauAxis', ...
            'x'};

        for i = 1:numel(delayFields)
            fn = delayFields{i};
            if isfield(out, fn)
                delayAxis = out.(fn);
                break;
            end
        end

        if isempty(envelope)
            error('parseEnvelopeOutput: struct 输出中未找到误差包络字段。');
        end

        delayAxis = normalizeDelayAxis(delayAxis, envelope);
        return;
    end

    error('parseEnvelopeOutput: 无法解析 computeMultipathEnvelope 的输出形式。');
end

function envelope = forceNumericEnvelope(envelopeIn)
    if ~isnumeric(envelopeIn)
        error('forceNumericEnvelope: envelope 必须是 numeric。');
    end
    envelope = envelopeIn;
end

function delayAxis = normalizeDelayAxis(delayAxisIn, envelope)
    if isempty(delayAxisIn)
        if isvector(envelope)
            delayAxis = (1:numel(envelope)).';
        else
            delayAxis = (1:size(envelope, 1)).';
        end
        return;
    end

    delayAxis = delayAxisIn(:);

    if isvector(envelope)
        if numel(delayAxis) ~= numel(envelope)
            delayAxis = (1:numel(envelope)).';
        end
    else
        if numel(delayAxis) ~= size(envelope, 1)
            delayAxis = (1:size(envelope, 1)).';
        end
    end
end