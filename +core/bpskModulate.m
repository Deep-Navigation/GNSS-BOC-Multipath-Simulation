function [sig, t] = bpskModulate(prn, cfg)
%BPSKMODULATE 生成BPSK基带信号
%   [sig, t] = core.bpskModulate(prn, cfg)
%   [sig, t] = core.bpskModulate(prn)
%   [sig, t] = core.bpskModulate()
%
%   输入:
%       prn - PRN伪码序列，推荐为 ±1 双极性行向量
%       cfg - 配置结构体（可选）。若省略，则自动调用 config_default()
%
%   输出:
%       sig - BPSK 基带信号
%       t   - 对应时间轴
%
%   功能说明:
%       1. 将输入 PRN 码按每码片采样点数进行扩展
%       2. 构成 BPSK 基带矩形码片波形
%       3. 支持按配置中的 signal.normalize 进行归一化
%
%   说明:
%       当前版本生成的是基带实信号，不包含载波调制。
%       后续若需要中频/射频信号，可再调用 core.addCarrier()。

    %% 1. 处理输入参数
    if nargin < 2 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 1 || isempty(prn)
        prn = core.generatePRN(cfg);
    end

    if ~isstruct(cfg)
        error('bpskModulate:InvalidInput', '输入参数 cfg 必须为结构体。');
    end

    %% 2. 检查必要字段
    requiredTopFields = {'time', 'code', 'signal'};
    for i = 1:numel(requiredTopFields)
        if ~isfield(cfg, requiredTopFields{i})
            error('bpskModulate:MissingField', ...
                'cfg 中缺少字段: %s。', requiredTopFields{i});
        end
    end

    if ~isfield(cfg.time, 'simDuration') || ~isfield(cfg.time, 'fs')
        error('bpskModulate:MissingField', ...
            'cfg.time 中缺少 simDuration 或 fs 字段。');
    end

    if ~isfield(cfg.code, 'chipRate') || ~isfield(cfg.code, 'samplesPerChip')
        error('bpskModulate:MissingField', ...
            'cfg.code 中缺少 chipRate 或 samplesPerChip 字段。');
    end

    if ~isfield(cfg.signal, 'normalize')
        error('bpskModulate:MissingField', ...
            'cfg.signal 中缺少 normalize 字段。');
    end

    %% 3. 基本参数
    fs             = cfg.time.fs;
    simDuration    = cfg.time.simDuration;
    chipRate       = cfg.code.chipRate;
    samplesPerChip = cfg.code.samplesPerChip;
    normalizeFlag  = cfg.signal.normalize;

    if ~isvector(prn) || isempty(prn)
        error('bpskModulate:InvalidPRN', '输入 prn 必须为非空向量。');
    end

    prn = prn(:).';  % 转为行向量

    if samplesPerChip <= 0 || floor(samplesPerChip) ~= samplesPerChip
        error('bpskModulate:InvalidSamplesPerChip', ...
            'cfg.code.samplesPerChip 必须为正整数。');
    end

    if fs <= 0 || chipRate <= 0 || simDuration <= 0
        error('bpskModulate:InvalidParameter', ...
            '采样率、码率和仿真时长必须为正数。');
    end

    %% 4. 计算所需码片数
    requiredNumChips = ceil(simDuration * chipRate);

    % 若输入PRN长度不足，则循环补齐
    if length(prn) < requiredNumChips
        repeatTimes = ceil(requiredNumChips / length(prn));
        prnUsed = repmat(prn, 1, repeatTimes);
        prnUsed = prnUsed(1:requiredNumChips);
    else
        prnUsed = prn(1:requiredNumChips);
    end

    %% 5. 将每个码片扩展为 samplesPerChip 个采样点
    sig = repelem(prnUsed, samplesPerChip);

    %% 6. 截取到精确仿真时长对应的采样点数
    targetNumSamples = round(simDuration * fs);

    if length(sig) < targetNumSamples
        % 理论上一般不会发生，但为稳健性保留
        padNum = targetNumSamples - length(sig);
        sig = [sig, repmat(sig(end), 1, padNum)];
    else
        sig = sig(1:targetNumSamples);
    end

    %% 7. 幅度归一化（可选）
    if normalizeFlag
        maxAbsVal = max(abs(sig));
        if maxAbsVal > 0
            sig = sig / maxAbsVal;
        end
    end

    %% 8. 生成时间轴
    t = (0:length(sig)-1) / fs;

    %% 9. 保证输出为行向量
    sig = sig(:).';
    t   = t(:).';
end