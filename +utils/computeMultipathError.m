function [delayChips, trackingError] = computeMultipathError(cfg)
%COMPUTEMULTIPATHERROR 计算多径码跟踪误差曲线
%
%   [delayChips, trackingError] = utils.computeMultipathError(cfg)
%   [delayChips, trackingError] = utils.computeMultipathError()
%
%   输出:
%       delayChips    - 多径延迟扫描轴（单位：chip）
%       trackingError - 对应的码跟踪误差（单位：chip）
%
%   说明:
%       1. 固定主径参数
%       2. 固定附加多径幅度与相位
%       3. 扫描多径延迟
%       4. 对每个延迟计算 S 曲线零交叉点偏移，作为码跟踪误差
%
%   当前版本特点:
%       - 不调用 addMultipath
%       - 预计算所有 delayed signal bank
%       - 直接矩阵方式计算 Prompt/Early/Late 相关输出
%       - 与 computeMultipathEnvelope 的建模方式保持一致

    %% 1. 输入处理
    if nargin < 1 || isempty(cfg)
        cfg = config_default();
    end

    if ~isstruct(cfg)
        error('computeMultipathError:InvalidInput', '输入参数 cfg 必须为结构体。');
    end

    %% 2. 补全 multipathScan 默认字段
    if ~isfield(cfg, 'multipathScan') || isempty(cfg.multipathScan)
        cfg.multipathScan = struct();
    end
    if ~isfield(cfg.multipathScan, 'maxDelayChips') || isempty(cfg.multipathScan.maxDelayChips)
        cfg.multipathScan.maxDelayChips = 1.5;
    end
    if ~isfield(cfg.multipathScan, 'numDelayPoints') || isempty(cfg.multipathScan.numDelayPoints)
        cfg.multipathScan.numDelayPoints = 101;
    end

    %% 3. 补全 tracking 默认字段
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

    %% 4. 基础字段检查
    if ~isfield(cfg, 'time') || ~isfield(cfg.time, 'fs') || isempty(cfg.time.fs)
        error('computeMultipathError:MissingField', 'cfg.time.fs 不存在。');
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

    if ~isfield(cfg, 'multipath') || isempty(cfg.multipath)
        error('computeMultipathError:MissingField', 'cfg.multipath 不存在。');
    end
    if ~isfield(cfg.multipath, 'main') || isempty(cfg.multipath.main)
        error('computeMultipathError:MissingField', 'cfg.multipath.main 不存在。');
    end
    if ~isfield(cfg.multipath, 'paths') || isempty(cfg.multipath.paths)
        error('computeMultipathError:MissingField', 'cfg.multipath.paths 不存在。');
    end

    fs = cfg.time.fs;
    chipRate = cfg.signal.chipRate;
    samplesPerChip = fs / chipRate;

    maxDelayChips = cfg.multipathScan.maxDelayChips;
    numDelayPoints = cfg.multipathScan.numDelayPoints;

    spacingChips = cfg.tracking.earlyLateSpacing;
    discriminatorType = upper(cfg.tracking.discriminator);
    maxOffsetChips = cfg.tracking.maxOffsetChips;
    numOffsetPoints = cfg.tracking.numOffsetPoints;
    interpMethod = lower(cfg.tracking.interpMethod);
    normalizeSCurve = cfg.tracking.normalizeSCurve;

    %% 5. 构造理想本地参考信号
    cfg_ref = cfg;
    cfg_ref.multipath.enable = false;
    cfg_ref.noise.enable = false;

    prn = core.generatePRN(cfg_ref);

    switch upper(cfg_ref.signal.modType)
        case 'BPSK'
            [localSig, ~] = core.bpskModulate(prn, cfg_ref);
        case 'BOC'
            [localSig, ~, ~] = core.bocModulate(prn, cfg_ref);
        otherwise
            error('computeMultipathError:InvalidModType', ...
                'cfg.signal.modType 只能为 ''BPSK'' 或 ''BOC''。');
    end

    localSig = localSig(:).';
    N = length(localSig);
    isComplexSig = ~isreal(localSig);

    %% 6. 路径参数
    mainAmp   = cfg.multipath.main.amplitude;
    mainPhase = cfg.multipath.main.phase;
    mpAmp     = cfg.multipath.paths(1).amplitude;
    mpPhase   = cfg.multipath.paths(1).phase;

    if isComplexSig
        mainSig = mainAmp * localSig .* exp(1j * mainPhase);
        mpPhaseFactor = exp(1j * mpPhase);
    else
        mainSig = mainAmp * localSig * cos(mainPhase);
        mpPhaseFactor = cos(mpPhase);
    end

    %% 7. 误差扫描轴
    delayChips = linspace(0, maxDelayChips, numDelayPoints);
    trackingError = nan(1, numDelayPoints);

    %% 8. 构建本地参考移位库
    codeOffsets = linspace(-maxOffsetChips, maxOffsetChips, numOffsetPoints);
    halfSpacing = spacingChips / 2;

    promptShiftSamples = codeOffsets * samplesPerChip;
    earlyShiftSamples  = (codeOffsets - halfSpacing) * samplesPerChip;
    lateShiftSamples   = (codeOffsets + halfSpacing) * samplesPerChip;

    promptBank = buildShiftBank(localSig, promptShiftSamples, interpMethod);
    earlyBank  = buildShiftBank(localSig, earlyShiftSamples,  interpMethod);
    lateBank   = buildShiftBank(localSig, lateShiftSamples,   interpMethod);

    conjPromptBank = conj(promptBank);
    conjEarlyBank  = conj(earlyBank);
    conjLateBank   = conj(lateBank);

    %% 9. 预计算 delay bank
    delaySamples = delayChips * samplesPerChip;
    delayedBank = buildShiftBank(localSig, delaySamples, interpMethod);

    %% 10. 主循环：每个 delay 求一个误差点
    for id = 1:numDelayPoints
        delayedSig = delayedBank(:, id).';
        rxSig = mainSig + mpAmp * mpPhaseFactor * delayedSig;

        P = rxSig * conjPromptBank;
        E = rxSig * conjEarlyBank;
        L = rxSig * conjLateBank;

        switch discriminatorType
            case 'NELP'
                S = abs(E).^2 - abs(L).^2;
            case 'NEML'
                S = abs(E) - abs(L);
            case 'CELP'
                S = real(E - L);
            otherwise
                error('computeMultipathError:UnsupportedDiscriminator', ...
                    '当前支持的鉴别器类型为 ''NELP''、''NEML''、''CELP''。');
        end

        if normalizeSCurve
            maxAbsS = max(abs(S));
            if maxAbsS > 0
                S = S / maxAbsS;
            end
        end

        trackingError(id) = findNearestZeroCrossingFast(codeOffsets, S);
    end

    %% 11. 输出形状
    delayChips = delayChips(:).';
    trackingError = trackingError(:).';

end

function bank = buildShiftBank(x, shiftSamplesList, interpMethod)
% 输出 bank 大小: N × M

    x = x(:).';
    N = length(x);
    M = length(shiftSamplesList);

    if isreal(x)
        bank = zeros(N, M);
    else
        bank = complex(zeros(N, M));
    end

    for k = 1:M
        bank(:, k) = localShiftInterpPeriodic(x, shiftSamplesList(k), interpMethod).';
    end
end

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