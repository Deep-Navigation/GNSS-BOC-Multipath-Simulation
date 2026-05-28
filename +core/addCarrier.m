function [sigOut, t, carrier] = addCarrier(sigIn, cfg)
%ADDCARRIER 对基带信号进行载波调制
%   [sigOut, t, carrier] = core.addCarrier(sigIn, cfg)
%   [sigOut, t, carrier] = core.addCarrier(sigIn)
%   [sigOut, t, carrier] = core.addCarrier()
%
%   输入:
%       sigIn - 输入基带信号（可选）
%       cfg   - 配置结构体（可选）。若省略，则自动调用 config_default()
%
%   输出:
%       sigOut  - 调制后的载波信号
%       t       - 时间轴
%       carrier - 载波序列
%
%   功能:
%       1. 将输入基带信号调制到 cfg.carrier.freq 指定频率
%       2. 支持实信号调制与复信号调制
%       3. 若未输入 sigIn，则根据 cfg.signal.modType 自动生成默认基带信号
%
%   说明:
%       - 当 cfg.carrier.type = 'real' 或 'IF' 时:
%           sigOut = A * sigIn .* cos(2*pi*fc*t + phi)
%       - 当 cfg.carrier.type = 'complex' 时:
%           sigOut = A * sigIn .* exp(1j*(2*pi*fc*t + phi))
%
%       当前版本优先保证与现有平台兼容，便于后续多径与噪声模块调用。

    %% 1. 处理 cfg
    if nargin < 2 || isempty(cfg)
        cfg = config_default();
    end

    if ~isstruct(cfg)
        error('addCarrier:InvalidInput', '输入参数 cfg 必须为结构体。');
    end

    %% 2. 检查必要字段
    if ~isfield(cfg, 'time') || ~isfield(cfg.time, 'fs')
        error('addCarrier:MissingField', 'cfg.time.fs 不存在。');
    end

    if ~isfield(cfg, 'carrier')
        error('addCarrier:MissingField', 'cfg.carrier 不存在。');
    end

    requiredCarrierFields = {'type', 'freq', 'phase', 'amplitude'};
    for i = 1:numel(requiredCarrierFields)
        if ~isfield(cfg.carrier, requiredCarrierFields{i})
            error('addCarrier:MissingField', ...
                'cfg.carrier 中缺少字段: %s。', requiredCarrierFields{i});
        end
    end

    %% 3. 若未输入基带信号，则自动生成
    if nargin < 1 || isempty(sigIn)
        prn = core.generatePRN(cfg);

        if isfield(cfg, 'signal') && isfield(cfg.signal, 'modType')
            modType = upper(cfg.signal.modType);
        else
            modType = 'BOC';
        end

        switch modType
            case 'BPSK'
                [sigIn, ~] = core.bpskModulate(prn, cfg);

            case 'BOC'
                [sigIn, ~, ~] = core.bocModulate(prn, cfg);

            otherwise
                error('addCarrier:InvalidModType', ...
                    'cfg.signal.modType 只能为 ''BPSK'' 或 ''BOC''。');
        end
    end

    %% 4. 输入信号检查
    if ~isvector(sigIn) || isempty(sigIn)
        error('addCarrier:InvalidSignal', '输入信号 sigIn 必须为非空向量。');
    end

    sigIn = sigIn(:).';  % 转为行向量

    %% 5. 读取参数
    fs   = cfg.time.fs;
    fc   = cfg.carrier.freq;
    phi  = cfg.carrier.phase;
    A    = cfg.carrier.amplitude;
    ctype = lower(cfg.carrier.type);

    if ~isscalar(fs) || fs <= 0
        error('addCarrier:InvalidFS', 'cfg.time.fs 必须为正数。');
    end

    if ~isscalar(fc) || fc < 0
        error('addCarrier:InvalidCarrierFreq', 'cfg.carrier.freq 必须为非负数。');
    end

    if ~isscalar(phi)
        error('addCarrier:InvalidCarrierPhase', 'cfg.carrier.phase 必须为标量。');
    end

    if ~isscalar(A) || A <= 0
        error('addCarrier:InvalidCarrierAmplitude', 'cfg.carrier.amplitude 必须为正数。');
    end

    %% 6. 生成时间轴
    N = length(sigIn);
    t = (0:N-1) / fs;

    %% 7. 生成载波并调制
    switch ctype
        case {'real', 'if', 'rf'}
            carrier = A * cos(2*pi*fc*t + phi);
            sigOut = sigIn .* carrier;

        case 'complex'
            carrier = A * exp(1j * (2*pi*fc*t + phi));
            sigOut = sigIn .* carrier;

        otherwise
            error('addCarrier:InvalidCarrierType', ...
                'cfg.carrier.type 只能为 ''real''、''IF''、''RF'' 或 ''complex''。');
    end

    %% 8. 保证输出向量形状
    sigOut  = sigOut(:).';
    t       = t(:).';
    carrier = carrier(:).';
end