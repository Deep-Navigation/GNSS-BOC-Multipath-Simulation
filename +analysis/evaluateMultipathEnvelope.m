function [delayAxis, envelope] = evaluateMultipathEnvelope(txSig, cfg, signalType)
%EVALUATEMULTIPATHENVELOPE 兼容适配 utils.computeMultipathEnvelope 的外层封装
%
%   [delayAxis, envelope] = analysis.evaluateMultipathEnvelope(txSig, cfg, signalType)
%
%   输入:
%       txSig      - 预生成发射信号（若底层不需要也可被忽略）
%       cfg        - 配置结构体
%       signalType - 信号类型字符串，可为空
%
%   输出:
%       delayAxis  - 延迟轴（chip）
%       envelope   - 误差包络

    if nargin < 3
        signalType = '';
    end

    attempts = {};
    errors   = {};

    attempts{end+1} = '[delayAxis, envelope] = utils.computeMultipathEnvelope(txSig, cfg)';
    try
        [delayAxis, envelope] = utils.computeMultipathEnvelope(txSig, cfg);
        envelope = forceNumericEnvelope(envelope);
        delayAxis = normalizeDelayAxis(delayAxis, envelope);
        return;
    catch ME
        errors{end+1} = ME.message;
    end

    attempts{end+1} = 'out = utils.computeMultipathEnvelope(txSig, cfg)';
    try
        out = utils.computeMultipathEnvelope(txSig, cfg);
        [delayAxis, envelope] = parseEnvelopeOutput(out);
        return;
    catch ME
        errors{end+1} = ME.message;
    end

    attempts{end+1} = '[delayAxis, envelope] = utils.computeMultipathEnvelope(cfg, txSig)';
    try
        [delayAxis, envelope] = utils.computeMultipathEnvelope(cfg, txSig);
        envelope = forceNumericEnvelope(envelope);
        delayAxis = normalizeDelayAxis(delayAxis, envelope);
        return;
    catch ME
        errors{end+1} = ME.message;
    end

    attempts{end+1} = 'out = utils.computeMultipathEnvelope(cfg, txSig)';
    try
        out = utils.computeMultipathEnvelope(cfg, txSig);
        [delayAxis, envelope] = parseEnvelopeOutput(out);
        return;
    catch ME
        errors{end+1} = ME.message;
    end

    attempts{end+1} = '[delayAxis, envelope] = utils.computeMultipathEnvelope(txSig, cfg, signalType)';
    try
        [delayAxis, envelope] = utils.computeMultipathEnvelope(txSig, cfg, signalType);
        envelope = forceNumericEnvelope(envelope);
        delayAxis = normalizeDelayAxis(delayAxis, envelope);
        return;
    catch ME
        errors{end+1} = ME.message;
    end

    attempts{end+1} = 'out = utils.computeMultipathEnvelope(txSig, cfg, signalType)';
    try
        out = utils.computeMultipathEnvelope(txSig, cfg, signalType);
        [delayAxis, envelope] = parseEnvelopeOutput(out);
        return;
    catch ME
        errors{end+1} = ME.message;
    end

    attempts{end+1} = '[delayAxis, envelope] = utils.computeMultipathEnvelope(cfg)';
    try
        [delayAxis, envelope] = utils.computeMultipathEnvelope(cfg);
        envelope = forceNumericEnvelope(envelope);
        delayAxis = normalizeDelayAxis(delayAxis, envelope);
        return;
    catch ME
        errors{end+1} = ME.message;
    end

    attempts{end+1} = 'out = utils.computeMultipathEnvelope(cfg)';
    try
        out = utils.computeMultipathEnvelope(cfg);
        [delayAxis, envelope] = parseEnvelopeOutput(out);
        return;
    catch ME
        errors{end+1} = ME.message;
    end

    errText = sprintf('analysis.evaluateMultipathEnvelope: 无法匹配 utils.computeMultipathEnvelope 的签名。\n\n');
    for i = 1:numel(attempts)
        errText = [errText, sprintf('尝试 %d:\n%s\n原始报错:\n%s\n\n', ...
            i, attempts{i}, errors{i})]; %#ok<AGROW>
    end

    error(errText);
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