function [delayChips, upperEnvelope, lowerEnvelope, phaseGrid, errorMatrix] = computeMultipathEnvelope(cfg)
%COMPUTEMULTIPATHENVELOPE 计算多径误差包络（深度优化版）
%
%   输出:
%       delayChips    - 多径延迟扫描轴（单位：chips）
%       upperEnvelope - 正误差包络（单位：chips）
%       lowerEnvelope - 负误差包络（单位：chips）
%       phaseGrid     - 多径相位扫描轴（单位：rad）
%       errorMatrix   - 误差矩阵，大小为 numPhasePoints × numDelayPoints
%
%   优化要点：
%       1. 不再在循环里调用 computeSCurve()
%       2. 预计算 Prompt/Early/Late 本地参考库
%       3. 预计算所有 delay 对应的 delayed signal bank
%       4. 每个 phase 下用矩阵乘法同时计算所有 delay 的 S 曲线

    %% 1. 处理 cfg
    if nargin < 1 || isempty(cfg)
        cfg = config_default();
    end

    if ~isstruct(cfg)
        error('computeMultipathEnvelope:InvalidInput', ...
            '输入参数 cfg 必须为结构体。');
    end

    %% 2. 补全 multipathEnvelope 默认字段
    if ~isfield(cfg, 'multipathEnvelope') || isempty(cfg.multipathEnvelope)
        cfg.multipathEnvelope = struct();
    end
    if ~isfield(cfg.multipathEnvelope, 'maxDelayChips') || isempty(cfg.multipathEnvelope.maxDelayChips)
        cfg.multipathEnvelope.maxDelayChips = 1.5;
    end
    if ~isfield(cfg.multipathEnvelope, 'numDelayPoints') || isempty(cfg.multipathEnvelope.numDelayPoints)
        cfg.multipathEnvelope.numDelayPoints = 101;
    end
    if ~isfield(cfg.multipathEnvelope, 'numPhasePoints') || isempty(cfg.multipathEnvelope.numPhasePoints)
        cfg.multipathEnvelope.numPhasePoints = 73;
    end
    if ~isfield(cfg.multipathEnvelope, 'phaseRange') || isempty(cfg.multipathEnvelope.phaseRange)
        cfg.multipathEnvelope.phaseRange = [0, 2*pi];
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

    %% 4. 基础字段检查
    if ~isfield(cfg, 'time') || ~isfield(cfg.time, 'fs') || isempty(cfg.time.fs)
        error('computeMultipathEnvelope:MissingField', 'cfg.time.fs 不存在。');
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
        error('computeMultipathEnvelope:MissingField', 'cfg.multipath 不存在。');
    end
    if ~isfield(cfg.multipath, 'main') || isempty(cfg.multipath.main)
        error('computeMultipathEnvelope:MissingField', 'cfg.multipath.main 不存在。');
    end
    if ~isfield(cfg.multipath, 'paths') || isempty(cfg.multipath.paths)
        error('computeMultipathEnvelope:MissingField', 'cfg.multipath.paths 不存在。');
    end

    fs = cfg.time.fs;
    chipRate = cfg.signal.chipRate;
    samplesPerChip = fs / chipRate;

    maxDelayChips = cfg.multipathEnvelope.maxDelayChips;
    numDelayPoints = cfg.multipathEnvelope.numDelayPoints;
    numPhasePoints = cfg.multipathEnvelope.numPhasePoints;
    phaseRange = cfg.multipathEnvelope.phaseRange;

    spacingChips = cfg.tracking.earlyLateSpacing;
    discriminatorType = upper(cfg.tracking.discriminator);
    maxOffsetChips = cfg.tracking.maxOffsetChips;
    numOffsetPoints = cfg.tracking.numOffsetPoints;
    interpMethod = lower(cfg.tracking.interpMethod);

    %% 5. 构造理想本地参考
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
            error('computeMultipathEnvelope:InvalidModType', ...
                'cfg.signal.modType 只能为 ''BPSK'' 或 ''BOC''。');
    end

    localSig = localSig(:).';
    N = length(localSig);

    %% 6. 路径参数
    mainAmp   = cfg.multipath.main.amplitude;
    mainPhase = cfg.multipath.main.phase;
    mpAmp     = cfg.multipath.paths(1).amplitude;

    isComplexSig = ~isreal(localSig);

    if isComplexSig
        mainSigCol = (mainAmp * localSig .* exp(1j * mainPhase)).';
    else
        mainSigCol = (mainAmp * localSig * cos(mainPhase)).';
    end

    %% 7. 扫描轴
    delayChips = linspace(0, maxDelayChips, numDelayPoints);
    phaseGrid = linspace(phaseRange(1), phaseRange(2), numPhasePoints);
    codeOffsets = linspace(-maxOffsetChips, maxOffsetChips, numOffsetPoints);

    errorMatrix = nan(numPhasePoints, numDelayPoints);

    %% 8. 预计算本地参考库（N × M）
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

    %% 9. 预计算 delay bank（N × D）
    delaySamples = delayChips * samplesPerChip;
    delayedBank = buildShiftBank(localSig, delaySamples, interpMethod);

    %% 10. 相位扫描：每个 phase 一次性算出所有 delay 的 S 曲线
    for ip = 1:numPhasePoints
        phaseVal = phaseGrid(ip);

        if isComplexSig
            phaseFactor = exp(1j * phaseVal);
        else
            phaseFactor = cos(phaseVal);
        end

        % rxMatrix: N × D，每一列对应一个 delay 下的接收信号
        rxMatrix = mainSigCol + mpAmp * phaseFactor * delayedBank;

        % 相关输出：D × M
        Pmat = rxMatrix' * conjPromptBank;
        Emat = rxMatrix' * conjEarlyBank;
        Lmat = rxMatrix' * conjLateBank;

        % 鉴别器输出：D × M
        switch discriminatorType
            case 'NELP'
                Smat = abs(Emat).^2 - abs(Lmat).^2;
            case 'NEML'
                Smat = abs(Emat) - abs(Lmat);
            case 'CELP'
                Smat = real(Emat - Lmat);
            otherwise
                error('computeMultipathEnvelope:UnsupportedDiscriminator', ...
                    '当前支持的鉴别器类型为 ''NELP''、''NEML''、''CELP''。');
        end

        % 逐个 delay 提取最靠近 0 的零交叉点
        for id = 1:numDelayPoints
            errorMatrix(ip, id) = findNearestZeroCrossingFast(codeOffsets, Smat(id, :));
        end
    end

    %% 11. 提取上下包络
    upperEnvelope = max(errorMatrix, [], 1);
    lowerEnvelope = min(errorMatrix, [], 1);

    %% 12. 输出形状
    delayChips = delayChips(:).';
    upperEnvelope = upperEnvelope(:).';
    lowerEnvelope = lowerEnvelope(:).';
    phaseGrid = phaseGrid(:).';
end


function bank = buildShiftBank(x, shiftSamplesList, interpMethod)
%BUILDSHIFTBANK 构造周期插值移位库
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
%LOCALSHIFTINTERPPERIODIC 使用周期插值实现小数延迟移位

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
%FINDNEARESTZEROCROSSINGFAST 查找最接近 0 的零交叉点

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