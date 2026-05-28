function [R, lags, lagTime] = computeCorrelation(x, y, cfg)
%COMPUTECORRELATION 计算自相关或互相关
%   [R, lags, lagTime] = utils.computeCorrelation(x, y, cfg)
%   [R, lags, lagTime] = utils.computeCorrelation(x, y)
%   [R, lags, lagTime] = utils.computeCorrelation(x)
%   [R, lags, lagTime] = utils.computeCorrelation()
%
%   输入:
%       x   - 输入信号 x（可选）
%       y   - 输入信号 y（可选）
%       cfg - 配置结构体（可选）
%
%   输出:
%       R       - 相关函数值
%       lags    - 延迟点数
%       lagTime - 延迟时间轴（单位：秒）
%
%   功能:
%       1. 若只输入 x，则计算 x 的自相关
%       2. 若同时输入 x 和 y，则计算 x 与 y 的互相关
%       3. 支持根据 cfg.corr.normalize 进行归一化
%       4. 支持根据 cfg.corr.maxLagSamples 限制最大延迟范围
%       5. 支持无输入参数时自动生成默认信号进行演示
%
%   默认行为:
%       - 若无输入，则自动生成默认 BOC 信号并计算自相关
%
%   说明:
%       当前版本基于 MATLAB 内置 xcorr 实现，适合作为
%       后续多径分析和 S 曲线计算的基础工具函数。

    %% 1. 处理 cfg
    if nargin < 3 || isempty(cfg)
        cfg = config_default();
    end

    if ~isstruct(cfg)
        error('computeCorrelation:InvalidInput', '输入参数 cfg 必须为结构体。');
    end

    %% 2. 默认信号处理
    if nargin < 1 || isempty(x)
        prn = core.generatePRN(cfg);

        if isfield(cfg, 'signal') && isfield(cfg.signal, 'modType')
            modType = upper(cfg.signal.modType);
        else
            modType = 'BOC';
        end

        switch modType
            case 'BPSK'
                [x, ~] = core.bpskModulate(prn, cfg);
            case 'BOC'
                [x, ~, ~] = core.bocModulate(prn, cfg);
            otherwise
                error('computeCorrelation:InvalidModType', ...
                    'cfg.signal.modType 只能为 ''BPSK'' 或 ''BOC''。');
        end
    end

    if nargin < 2 || isempty(y)
        y = x;
    end

    %% 3. 检查必要字段
    if ~isfield(cfg, 'time') || ~isfield(cfg.time, 'fs')
        error('computeCorrelation:MissingField', 'cfg.time.fs 不存在。');
    end

    if ~isfield(cfg, 'corr')
        error('computeCorrelation:MissingField', 'cfg.corr 不存在。');
    end

    requiredCorrFields = {'maxLagSamples', 'normalize'};
    for i = 1:numel(requiredCorrFields)
        if ~isfield(cfg.corr, requiredCorrFields{i})
            error('computeCorrelation:MissingField', ...
                'cfg.corr 中缺少字段: %s。', requiredCorrFields{i});
        end
    end

    %% 4. 信号检查
    if ~isvector(x) || isempty(x)
        error('computeCorrelation:InvalidSignal', '输入信号 x 必须为非空向量。');
    end

    if ~isvector(y) || isempty(y)
        error('computeCorrelation:InvalidSignal', '输入信号 y 必须为非空向量。');
    end

    x = x(:);
    y = y(:);

    maxLag     = cfg.corr.maxLagSamples;
    normalize  = cfg.corr.normalize;
    fs         = cfg.time.fs;

    if ~isscalar(maxLag) || maxLag < 0 || floor(maxLag) ~= maxLag
        error('computeCorrelation:InvalidMaxLag', ...
            'cfg.corr.maxLagSamples 必须为非负整数。');
    end

    %% 5. 计算相关函数
    if normalize
        [R, lags] = xcorr(x, y, maxLag, 'coeff');
    else
        [R, lags] = xcorr(x, y, maxLag);
    end

    %% 6. 构造延迟时间轴
    lagTime = lags / fs;

    %% 7. 保证输出为列向量
    R       = R(:);
    lags    = lags(:);
    lagTime = lagTime(:);
end