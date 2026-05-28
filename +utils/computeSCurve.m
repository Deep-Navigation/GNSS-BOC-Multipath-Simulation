function [S, codeOffsets, E, L, P] = computeSCurve(rxSig, localSig, cfg)
%COMPUTESCURVE 计算 Early-Late 码鉴别器 S 曲线
%   [S, codeOffsets, E, L, P] = utils.computeSCurve(rxSig, localSig, cfg)
%   [S, codeOffsets, E, L, P] = utils.computeSCurve(rxSig, localSig)
%   [S, codeOffsets, E, L, P] = utils.computeSCurve(rxSig)
%   [S, codeOffsets, E, L, P] = utils.computeSCurve()
%
%   输入:
%       rxSig     - 接收信号（可选）
%       localSig  - 本地参考信号（可选）
%       cfg       - 配置结构体（可选）
%
%   输出:
%       S           - S曲线鉴别器输出
%       codeOffsets - 码相位偏移轴（单位：chips，码片）
%       E           - Early 分支相关输出
%       L           - Late 分支相关输出
%       P           - Prompt 分支相关输出
%
%   当前支持鉴别器:
%       'NELP'  - Non-coherent Early-Late Power（非相干功率差）
%       'NEML'  - Non-coherent Early-Minus-Late（非相干幅度差）
%       'CELP'  - Coherent Early-Late（相干差）

    %% 1. 处理 cfg
    if nargin < 3 || isempty(cfg)
        cfg = config_default();
    end

    if ~isstruct(cfg)
        error('computeSCurve:InvalidInput', '输入参数 cfg 必须为结构体。');
    end

    %% 2. 补全 tracking 默认字段
    if ~isfield(cfg, 'tracking') || isempty(cfg.tracking)
        cfg.tracking = struct();
    end

    if ~isfield(cfg.tracking, 'earlyLateSpacing') || isempty(cfg.tracking.earlyLateSpacing)
        cfg.tracking.earlyLateSpacing = 0.5;
    end

    if ~isfield(cfg.tracking, 'discriminator') || isempty(cfg.tracking.discriminator)
        cfg.tracking.discriminator = 'NELP';
    end

    if ~isfield(cfg.tracking, 'maxOffsetChips') || isempty(cfg.tracking.maxOffsetChips)
        cfg.tracking.maxOffsetChips = 2;
    end

    if ~isfield(cfg.tracking, 'numOffsetPoints') || isempty(cfg.tracking.numOffsetPoints)
        cfg.tracking.numOffsetPoints = 201;
    end

    if ~isfield(cfg.tracking, 'interpMethod') || isempty(cfg.tracking.interpMethod)
        cfg.tracking.interpMethod = 'linear';
    end

    if ~isfield(cfg.tracking, 'normalizeSCurve') || isempty(cfg.tracking.normalizeSCurve)
        cfg.tracking.normalizeSCurve = true;
    end

    %% 3. 检查基础字段
    if ~isfield(cfg, 'time') || ~isfield(cfg.time, 'fs') || isempty(cfg.time.fs)
        error('computeSCurve:MissingField', 'cfg.time.fs 不存在。');
    end

    if ~isfield(cfg, 'signal') || isempty(cfg.signal)
        cfg.signal = struct();
    end

    if ~isfield(cfg.signal, 'chipRate') || isempty(cfg.signal.chipRate)
        cfg.signal.chipRate = 1.023e6;
    end

    if ~isfield(cfg.signal, 'modType') || isempty(cfg.signal.modType)
        cfg.signal.modType = 'BOC';
    end

    fs = cfg.time.fs;
    chipRate = cfg.signal.chipRate;
    samplesPerChip = fs / chipRate;

    if ~isscalar(fs) || fs <= 0
        error('computeSCurve:InvalidFS', 'cfg.time.fs 必须为正标量。');
    end

    if ~isscalar(chipRate) || chipRate <= 0
        error('computeSCurve:InvalidChipRate', 'cfg.signal.chipRate 必须为正标量。');
    end

    if samplesPerChip <= 0
        error('computeSCurve:InvalidSamplesPerChip', ...
            'samplesPerChip 必须大于 0。');
    end

    %% 4. 若未输入信号，则自动生成默认分析信号
    if nargin < 1 || isempty(rxSig) || nargin < 2 || isempty(localSig)
        prn = core.generatePRN(cfg);

        modType = upper(cfg.signal.modType);

        switch modType
            case 'BPSK'
                [baseSig, ~] = core.bpskModulate(prn, cfg);
            case 'BOC'
                [baseSig, ~, ~] = core.bocModulate(prn, cfg);
            otherwise
                error('computeSCurve:InvalidModType', ...
                    'cfg.signal.modType 只能为 ''BPSK'' 或 ''BOC''。');
        end

        localSig = baseSig;
        rxSig = baseSig;

        if isfield(cfg, 'multipath') && isfield(cfg.multipath, 'enable') && cfg.multipath.enable
            [rxSig, ~, ~] = core.addMultipath(rxSig, cfg);
        end

        if isfield(cfg, 'noise') && isfield(cfg.noise, 'enable') && cfg.noise.enable
            [rxSig, ~, ~] = core.addNoise(rxSig, cfg);
        end
    end

    %% 5. 输入检查
    if ~isvector(rxSig) || isempty(rxSig)
        error('computeSCurve:InvalidSignal', 'rxSig 必须为非空向量。');
    end

    if ~isvector(localSig) || isempty(localSig)
        error('computeSCurve:InvalidSignal', 'localSig 必须为非空向量。');
    end

    rxSig = rxSig(:).';
    localSig = localSig(:).';

    N = min(length(rxSig), length(localSig));
    rxSig = rxSig(1:N);
    localSig = localSig(1:N);

    %% 6. 构造码相位偏移轴
    maxOffsetChips = cfg.tracking.maxOffsetChips;
    numOffsetPoints = cfg.tracking.numOffsetPoints;
    spacingChips = cfg.tracking.earlyLateSpacing;
    discriminatorType = upper(cfg.tracking.discriminator);
    interpMethod = lower(cfg.tracking.interpMethod);

    if ~isscalar(maxOffsetChips) || maxOffsetChips <= 0
        error('computeSCurve:InvalidMaxOffset', ...
            'cfg.tracking.maxOffsetChips 必须为正标量。');
    end

    if ~isscalar(numOffsetPoints) || numOffsetPoints < 3 || floor(numOffsetPoints) ~= numOffsetPoints
        error('computeSCurve:InvalidNumOffsetPoints', ...
            'cfg.tracking.numOffsetPoints 必须为不小于 3 的整数。');
    end

    if ~isscalar(spacingChips) || spacingChips <= 0
        error('computeSCurve:InvalidSpacing', ...
            'cfg.tracking.earlyLateSpacing 必须为正标量。');
    end

    validMethods = {'linear', 'nearest', 'pchip', 'spline'};
    if ~ismember(interpMethod, validMethods)
        error('computeSCurve:InvalidInterpMethod', ...
            'cfg.tracking.interpMethod 必须为 linear / nearest / pchip / spline。');
    end

    codeOffsets = linspace(-maxOffsetChips, maxOffsetChips, numOffsetPoints);

    E = zeros(1, length(codeOffsets));
    L = zeros(1, length(codeOffsets));
    P = zeros(1, length(codeOffsets));

    %% 7. 逐点计算 Early / Prompt / Late
    halfSpacing = spacingChips / 2;

    for k = 1:length(codeOffsets)
        tau = codeOffsets(k);

        % 这里不再 round，而是保留小数移位
        promptShiftSamples = tau * samplesPerChip;
        earlyShiftSamples  = (tau - halfSpacing) * samplesPerChip;
        lateShiftSamples   = (tau + halfSpacing) * samplesPerChip;

       localPrompt = localShiftInterpPeriodic(localSig, promptShiftSamples, interpMethod);
       localEarly  = localShiftInterpPeriodic(localSig, earlyShiftSamples, interpMethod);
       localLate   = localShiftInterpPeriodic(localSig, lateShiftSamples, interpMethod);

        % 点积相关（dot-product correlation，点积相关）
        P(k) = sum(rxSig .* conj(localPrompt));
        E(k) = sum(rxSig .* conj(localEarly));
        L(k) = sum(rxSig .* conj(localLate));
    end

    %% 8. 计算鉴别器输出
    switch discriminatorType
        case 'NELP'
            S = abs(E).^2 - abs(L).^2;

        case 'NEML'
            S = abs(E) - abs(L);

        case 'CELP'
            S = real(E - L);

        otherwise
            error('computeSCurve:UnsupportedDiscriminator', ...
                '当前支持的鉴别器类型为 ''NELP''、''NEML''、''CELP''。');
    end

    %% 9. 归一化
    if cfg.tracking.normalizeSCurve
        maxAbsS = max(abs(S));
        if maxAbsS > 0
            S = S / maxAbsS;
        end

        maxAbsE = max(abs(E));
        maxAbsL = max(abs(L));
        maxAbsP = max(abs(P));

        if maxAbsE > 0
            E = E / maxAbsE;
        end
        if maxAbsL > 0
            L = L / maxAbsL;
        end
        if maxAbsP > 0
            P = P / maxAbsP;
        end
    end

    %% 10. 输出形状
    S = S(:).';
    codeOffsets = codeOffsets(:).';
    E = E(:).';
    L = L(:).';
    P = P(:).';
end


function y = localShiftInterpPeriodic(x, shiftSamples, interpMethod)
%LOCALSHIFTINTERPPERIODIC 使用周期插值实现本地参考信号的小数延迟移位
%
%   对 PRN 码更适合，因为本地码通常按周期信号处理。
%   不再使用零填充，而是循环延拓。

    x = x(:).';
    N = length(x);

    % 原始索引
    n = 1:N;

    % 查询点：y(n) = x(n - shiftSamples)
    queryPoints = n - shiftSamples;

    % 周期映射到 [1, N+1)
    queryWrapped = mod(queryPoints - 1, N) + 1;

    % 为了支持跨边界插值，补一个首样本到末尾
    xExt = [x, x(1)];
    nExt = 1:(N+1);

    y = interp1(nExt, xExt, queryWrapped, interpMethod);

    y = y(:).';
end