function [sig, t, subcarrier] = bocModulate(prn, cfg)
%BOCMODULATE 生成 BOC 基带调制信号
%   [sig, t, subcarrier] = core.bocModulate(prn, cfg)
%   [sig, t, subcarrier] = core.bocModulate(prn)
%   [sig, t, subcarrier] = core.bocModulate()
%
%   输入:
%       prn - PRN伪码序列，推荐为 ±1 双极性行向量
%       cfg - 配置结构体（可选）。若省略，则自动调用 config_default()
%
%   输出:
%       sig        - BOC 基带信号
%       t          - 时间轴
%       subcarrier - 子载波序列
%
%   当前版本功能:
%       1. 支持 BOCsin(m,n)
%       2. 根据采样率和仿真时长自动生成对应长度信号
%       3. 若输入 PRN 长度不足，则自动循环补齐
%       4. 支持可选归一化
%
%   说明:
%       当前版本优先保证与你现有平台结构兼容，便于后续
%       多径、相关函数、S曲线分析模块直接调用。
%
%   注意:
%       1. 当前默认只实现 'sin' 型 BOC
%       2. 要求 samplesPerChip / (2*m/n) 最好为整数，这样子载波翻转更规整
%       3. 若不是整数，本版本仍可运行，但严格波形边界会受采样近似影响

    %% 1. 处理输入参数
    if nargin < 2 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 1 || isempty(prn)
        prn = core.generatePRN(cfg);
    end

    if ~isstruct(cfg)
        error('bocModulate:InvalidInput', '输入参数 cfg 必须为结构体。');
    end

    %% 2. 检查必要字段
    requiredTopFields = {'time', 'code', 'signal'};
    for i = 1:numel(requiredTopFields)
        if ~isfield(cfg, requiredTopFields{i})
            error('bocModulate:MissingField', ...
                'cfg 中缺少字段: %s。', requiredTopFields{i});
        end
    end

    requiredTimeFields = {'fs', 'simDuration'};
    for i = 1:numel(requiredTimeFields)
        if ~isfield(cfg.time, requiredTimeFields{i})
            error('bocModulate:MissingField', ...
                'cfg.time 中缺少字段: %s。', requiredTimeFields{i});
        end
    end

    requiredCodeFields = {'chipRate', 'samplesPerChip'};
    for i = 1:numel(requiredCodeFields)
        if ~isfield(cfg.code, requiredCodeFields{i})
            error('bocModulate:MissingField', ...
                'cfg.code 中缺少字段: %s。', requiredCodeFields{i});
        end
    end

    if ~isfield(cfg.signal, 'boc')
        error('bocModulate:MissingField', 'cfg.signal 中缺少 boc 字段。');
    end

    requiredBOCFields = {'m', 'n', 'type'};
    for i = 1:numel(requiredBOCFields)
        if ~isfield(cfg.signal.boc, requiredBOCFields{i})
            error('bocModulate:MissingField', ...
                'cfg.signal.boc 中缺少字段: %s。', requiredBOCFields{i});
        end
    end

    if ~isfield(cfg.signal, 'normalize')
        error('bocModulate:MissingField', ...
            'cfg.signal 中缺少 normalize 字段。');
    end

    %% 3. 读取参数
    fs             = cfg.time.fs;
    simDuration    = cfg.time.simDuration;
    chipRate       = cfg.code.chipRate;
    samplesPerChip = cfg.code.samplesPerChip;
    normalizeFlag  = cfg.signal.normalize;

    m              = cfg.signal.boc.m;
    n              = cfg.signal.boc.n;
    bocType        = lower(cfg.signal.boc.type);

    if ~isvector(prn) || isempty(prn)
        error('bocModulate:InvalidPRN', '输入 prn 必须为非空向量。');
    end
    prn = prn(:).';

    if fs <= 0 || simDuration <= 0 || chipRate <= 0
        error('bocModulate:InvalidParameter', ...
            '采样率、仿真时长和码率必须为正数。');
    end

    if samplesPerChip <= 0 || floor(samplesPerChip) ~= samplesPerChip
        error('bocModulate:InvalidSamplesPerChip', ...
            'cfg.code.samplesPerChip 必须为正整数。');
    end

    if m <= 0 || n <= 0 || floor(m) ~= m || floor(n) ~= n
        error('bocModulate:InvalidBOCParameter', ...
            'BOC 参数 m 和 n 必须为正整数。');
    end

    if ~strcmp(bocType, 'sin')
        error('bocModulate:UnsupportedType', ...
            '当前版本仅支持 BOCsin(m,n)。请将 cfg.signal.boc.type 设为 ''sin''。');
    end

    %% 4. 计算所需码片数
    requiredNumChips = ceil(simDuration * chipRate);

    if length(prn) < requiredNumChips
        repeatTimes = ceil(requiredNumChips / length(prn));
        prnUsed = repmat(prn, 1, repeatTimes);
        prnUsed = prnUsed(1:requiredNumChips);
    else
        prnUsed = prn(1:requiredNumChips);
    end

    %% 5. 先生成扩展后的码序列（矩形码片）
    codeSamples = repelem(prnUsed, samplesPerChip);

    %% 6. 生成子载波
    % 对于 BOC(m,n)，每个码片内的半子载波数为 2m/n
    %
    % 例如:
    %   BOC(1,1): 每码片内有2个半周期 -> [+1... -1...]
    %   BOC(5,2): 每码片内有5个半周期
    %
    % 半子载波段数:
    halfSubcarrierPerChip = 2 * m / n;

    if halfSubcarrierPerChip <= 0
        error('bocModulate:InvalidSubcarrierSetting', ...
            '每码片内半子载波段数必须为正。');
    end

    % 每个半子载波段对应的采样点数（近似）
    samplesPerHalfSub = samplesPerChip / halfSubcarrierPerChip;

    % 为稳健起见，这里采用“按采样点时刻直接生成符号函数”的方式，
    % 避免简单 round 后导致总长度不匹配。
    totalCodeSamples = length(codeSamples);
    t = (0:totalCodeSamples-1) / fs;

    % 子载波频率：f_sc = m * 1.023 MHz
    % 由于当前 chipRate 一般也设置为 n * 1.023 MHz 的形式，
    % 更通用写法为:
    fsc = (m / n) * chipRate;

    switch bocType
        case 'sin'
            subcarrier = sign(sin(2*pi*fsc*t));

            % 避免 sign(0)=0 导致出现 0 值
            zeroIdx = (subcarrier == 0);
            subcarrier(zeroIdx) = 1;
    end

    %% 7. BOC 调制：扩频码 × 子载波
    sig = codeSamples .* subcarrier;

    %% 8. 截取到精确仿真时长对应的采样点数
    targetNumSamples = round(simDuration * fs);

    if length(sig) < targetNumSamples
        padNum = targetNumSamples - length(sig);
        sig = [sig, repmat(sig(end), 1, padNum)];
        subcarrier = [subcarrier, repmat(subcarrier(end), 1, padNum)];
    else
        sig = sig(1:targetNumSamples);
        subcarrier = subcarrier(1:targetNumSamples);
    end

    %% 9. 幅度归一化（可选）
    if normalizeFlag
        maxAbsVal = max(abs(sig));
        if maxAbsVal > 0
            sig = sig / maxAbsVal;
        end
    end

    %% 10. 更新时间轴
    t = (0:length(sig)-1) / fs;

    %% 11. 保证输出为行向量
    sig        = sig(:).';
    t          = t(:).';
    subcarrier = subcarrier(:).';
end