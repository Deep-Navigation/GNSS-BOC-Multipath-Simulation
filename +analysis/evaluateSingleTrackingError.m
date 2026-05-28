function errChip = evaluateSingleTrackingError(cfg)
%EVALUATESINGLETRACKINGERROR
% 计算给定单组多径参数下的单点码跟踪误差
%
%   errChip = analysis.evaluateSingleTrackingError(cfg)
%
%   输入:
%       cfg - 配置结构体，要求至少包含：
%             cfg.time.fs
%             cfg.code.chipRate 或 cfg.signal.chipRate
%             cfg.tracking.*
%             cfg.multipath.*
%             cfg.signal.modType
%
%   输出:
%       errChip - 零交叉点对应的码跟踪误差（单位：chip）
%
%   说明：
%       1. 本函数用于“单点条件”下的 tracking error 评估
%       2. 不依赖 computeMultipathError / computeMultipathEnvelope 的内部扫描逻辑
%       3. 当前作为幅度/延迟/相位点扫描以及 spacing 稳定性扫描的公共底层评估器

    %% 1) 基础检查
    if nargin < 1 || isempty(cfg) || ~isstruct(cfg)
        error('analysis.evaluateSingleTrackingError:InvalidInput', ...
            '输入 cfg 必须为非空结构体。');
    end

    if ~isfield(cfg, 'time') || ~isfield(cfg.time, 'fs') || isempty(cfg.time.fs)
        error('analysis.evaluateSingleTrackingError:MissingField', ...
            'cfg.time.fs 不存在。');
    end

    fs = cfg.time.fs;

    if isfield(cfg, 'code') && isfield(cfg.code, 'chipRate') && ~isempty(cfg.code.chipRate)
        chipRate = cfg.code.chipRate;
    elseif isfield(cfg, 'signal') && isfield(cfg.signal, 'chipRate') && ~isempty(cfg.signal.chipRate)
        chipRate = cfg.signal.chipRate;
    else
        error('analysis.evaluateSingleTrackingError:MissingChipRate', ...
            '未找到 chipRate 字段。');
    end

    if ~isfield(cfg, 'tracking') || isempty(cfg.tracking)
        error('analysis.evaluateSingleTrackingError:MissingField', ...
            'cfg.tracking 不存在。');
    end

    requiredTrackingFields = { ...
        'earlyLateSpacing', ...
        'maxOffsetChips', ...
        'numOffsetPoints', ...
        'interpMethod', ...
        'discriminator'};

    for i = 1:numel(requiredTrackingFields)
        fn = requiredTrackingFields{i};
        if ~isfield(cfg.tracking, fn) || isempty(cfg.tracking.(fn))
            error('analysis.evaluateSingleTrackingError:MissingTrackingField', ...
                'cfg.tracking.%s 不存在或为空。', fn);
        end
    end

    if ~isfield(cfg, 'multipath') || isempty(cfg.multipath)
        error('analysis.evaluateSingleTrackingError:MissingField', ...
            'cfg.multipath 不存在。');
    end

    if ~isfield(cfg.multipath, 'main') || isempty(cfg.multipath.main)
        error('analysis.evaluateSingleTrackingError:MissingField', ...
            'cfg.multipath.main 不存在。');
    end

    if ~isfield(cfg.multipath, 'paths') || isempty(cfg.multipath.paths)
        error('analysis.evaluateSingleTrackingError:MissingField', ...
            'cfg.multipath.paths 不存在。');
    end

    if ~isfield(cfg, 'signal') || ~isfield(cfg.signal, 'modType') || isempty(cfg.signal.modType)
        error('analysis.evaluateSingleTrackingError:MissingField', ...
            'cfg.signal.modType 不存在。');
    end

    %% 2) 提取参数
    samplesPerChip = fs / chipRate;

    spacingChips      = cfg.tracking.earlyLateSpacing;
    halfSpacing       = spacingChips / 2;
    maxOffsetChips    = cfg.tracking.maxOffsetChips;
    numOffsetPoints   = cfg.tracking.numOffsetPoints;
    interpMethod      = lower(cfg.tracking.interpMethod);
    discriminatorType = upper(cfg.tracking.discriminator);

    normalizeSCurve = true;
    if isfield(cfg.tracking, 'normalizeSCurve')
        normalizeSCurve = cfg.tracking.normalizeSCurve;
    end

    codeOffsets = linspace(-maxOffsetChips, maxOffsetChips, numOffsetPoints);

    %% 3) 构造理想本地参考信号
    cfgRef = cfg;
    cfgRef.multipath.enable = false;
    cfgRef.noise.enable = false;

    prn = core.generatePRN(cfgRef);

    switch upper(cfgRef.signal.modType)
        case 'BPSK'
            [localSig, ~] = core.bpskModulate(prn, cfgRef);
        case 'BOC'
            [localSig, ~, ~] = core.bocModulate(prn, cfgRef);
        otherwise
            error('analysis.evaluateSingleTrackingError:InvalidModType', ...
                'cfg.signal.modType 只能为 ''BPSK'' 或 ''BOC''。');
    end

    localSig = localSig(:).';
    isComplexSig = ~isreal(localSig);

    %% 4) 构造主径与单条多径信号
    mainAmp   = cfg.multipath.main.amplitude;
    mainPhase = cfg.multipath.main.phase;
    mpAmp     = cfg.multipath.paths(1).amplitude;
    mpPhase   = cfg.multipath.paths(1).phase;
    mpDelay   = cfg.multipath.paths(1).delay;

    delaySamples = mpDelay * fs;
    delayedSig   = localShiftInterpPeriodic(localSig, delaySamples, interpMethod);

    if isComplexSig
        mainSig = mainAmp * localSig .* exp(1j * mainPhase);
        mpSig   = mpAmp * delayedSig .* exp(1j * mpPhase);
    else
        mainSig = mainAmp * localSig * cos(mainPhase);
        mpSig   = mpAmp * delayedSig * cos(mpPhase);
    end

    rxSig = mainSig + mpSig;

    %% 5) 计算 S 曲线
    S = zeros(1, numOffsetPoints);

    for k = 1:numOffsetPoints
        tau = codeOffsets(k);

        promptShift = tau * samplesPerChip;
        earlyShift  = (tau - halfSpacing) * samplesPerChip;
        lateShift   = (tau + halfSpacing) * samplesPerChip;

        promptRef = localShiftInterpPeriodic(localSig, promptShift, interpMethod);
        earlyRef  = localShiftInterpPeriodic(localSig, earlyShift,  interpMethod);
        lateRef   = localShiftInterpPeriodic(localSig, lateShift,   interpMethod);

        P = rxSig * conj(promptRef).'; %#ok<NASGU>
        E = rxSig * conj(earlyRef).';
        L = rxSig * conj(lateRef).';

        switch discriminatorType
            case 'NELP'
                S(k) = abs(E).^2 - abs(L).^2;
            case 'NEML'
                S(k) = abs(E) - abs(L);
            case 'CELP'
                S(k) = real(E - L);
            otherwise
                error('analysis.evaluateSingleTrackingError:UnsupportedDiscriminator', ...
                    '当前支持的鉴别器类型为 ''NELP''、''NEML''、''CELP''。');
        end
    end

    %% 6) 归一化
    if normalizeSCurve
        maxAbsS = max(abs(S));
        if maxAbsS > 0
            S = S / maxAbsS;
        end
    end

    %% 7) 提取零交叉点
    errChip = findNearestZeroCrossingFast(codeOffsets, S);

end

%% ========================= Local Helpers =========================

function y = localShiftInterpPeriodic(x, shiftSamples, interpMethod)
    x = x(:).';
    N = length(x);

    n = 1:N;
    queryPoints = n - shiftSamples;
    queryWrapped = mod(queryPoints - 1, N) + 1;

    xExt = [x, x(1)];
    nExt = 1:(N+1);

    y = interp1(nExt, xExt, queryWrapped, interpMethod);
    y = y(:).';
end

function zc = findNearestZeroCrossingFast(x, y)
    x = x(:).';
    y = y(:).';

    zcCandidates = [];
    N = length(x);

    for i = 1:(N-1)
        y1 = y(i);
        y2 = y(i+1);

        if y1 == 0
            zcCandidates(end+1) = x(i); %#ok<AGROW>
        elseif y1 * y2 < 0
            xi = x(i) - y1 * (x(i+1) - x(i)) / (y2 - y1);
            zcCandidates(end+1) = xi; %#ok<AGROW>
        end
    end

    if isempty(zcCandidates)
        zc = NaN;
    else
        [~, idx] = min(abs(zcCandidates));
        zc = zcCandidates(idx);
    end
end