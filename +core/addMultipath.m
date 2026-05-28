function [sigOut, t, pathSignals] = addMultipath(sigIn, cfg)
%ADDMULTIPATH 为输入信号叠加多径分量
%   [sigOut, t, pathSignals] = core.addMultipath(sigIn, cfg)
%   [sigOut, t, pathSignals] = core.addMultipath(sigIn)
%   [sigOut, t, pathSignals] = core.addMultipath()
%
%   输入:
%       sigIn - 输入信号（可选），可为基带或载波调制后的信号
%       cfg   - 配置结构体（可选）。若省略，则自动调用 config_default()
%
%   输出:
%       sigOut      - 叠加多径后的输出信号
%       t           - 时间轴
%       pathSignals - 各路径单独分量，大小为 numPathsTotal × N
%
%   功能:
%       1. 根据 cfg.multipath 参数构造主路径及多径分量
%       2. 支持整数采样点延迟
%       3. 支持每条路径独立幅度、延迟和相位
%       4. 支持实信号与复信号输入
%
%   当前版本说明:
%       - 默认优先支持 cfg.multipath.delayMode = 'integer'
%       - 若 delayMode = 'fractional'，当前会报错提示暂未实现
%
%   多径模型:
%       sigOut(t) = sum_k a_k * sigIn(t - tau_k) * exp(j*phi_k)
%
%       对实信号输入，仅取实部相位旋转等效形式:
%           a_k * delayedSig * cos(phi_k)
%
%       对复信号输入:
%           a_k * delayedSig * exp(1j*phi_k)

    %% 1. 处理输入参数
    if nargin < 2 || isempty(cfg)
        cfg = config_default();
    end

    if ~isstruct(cfg)
        error('addMultipath:InvalidInput', '输入参数 cfg 必须为结构体。');
    end

    %% 2. 检查必要字段
    if ~isfield(cfg, 'time') || ~isfield(cfg.time, 'fs')
        error('addMultipath:MissingField', 'cfg.time.fs 不存在。');
    end

    if ~isfield(cfg, 'multipath')
        error('addMultipath:MissingField', 'cfg.multipath 不存在。');
    end

    requiredMPFields = {'enable', 'numPaths', 'main', 'paths', 'delayMode'};
    for i = 1:numel(requiredMPFields)
        if ~isfield(cfg.multipath, requiredMPFields{i})
            error('addMultipath:MissingField', ...
                'cfg.multipath 中缺少字段: %s。', requiredMPFields{i});
        end
    end

    %% 3. 若未输入信号，则自动生成默认信号
    if nargin < 1 || isempty(sigIn)
        prn = core.generatePRN(cfg);

        if isfield(cfg, 'signal') && isfield(cfg.signal, 'modType')
            modType = upper(cfg.signal.modType);
        else
            modType = 'BOC';
        end

        switch modType
            case 'BPSK'
                [sigBase, ~] = core.bpskModulate(prn, cfg);
            case 'BOC'
                [sigBase, ~, ~] = core.bocModulate(prn, cfg);
            otherwise
                error('addMultipath:InvalidModType', ...
                    'cfg.signal.modType 只能为 ''BPSK'' 或 ''BOC''。');
        end

        % 若载波模块启用，则先加载波
        if isfield(cfg, 'carrier') && isfield(cfg.carrier, 'enable') && cfg.carrier.enable
            [sigIn, ~, ~] = core.addCarrier(sigBase, cfg);
        else
            sigIn = sigBase;
        end
    end

    %% 4. 输入信号检查
    if ~isvector(sigIn) || isempty(sigIn)
        error('addMultipath:InvalidSignal', '输入信号 sigIn 必须为非空向量。');
    end

    sigIn = sigIn(:).';   % 行向量
    N = length(sigIn);

    fs = cfg.time.fs;
    if ~isscalar(fs) || fs <= 0
        error('addMultipath:InvalidFS', 'cfg.time.fs 必须为正数。');
    end

    t = (0:N-1) / fs;

    %% 5. 若未启用多径，直接返回
    if ~cfg.multipath.enable
        sigOut = sigIn;
        pathSignals = sigIn;
        return;
    end

    %% 6. 读取多径参数
    numExtraPaths = cfg.multipath.numPaths;
    delayMode = lower(cfg.multipath.delayMode);

    if ~isscalar(numExtraPaths) || numExtraPaths < 0 || floor(numExtraPaths) ~= numExtraPaths
        error('addMultipath:InvalidNumPaths', ...
            'cfg.multipath.numPaths 必须为非负整数。');
    end

    % 主路径参数
    requiredMainFields = {'amplitude', 'delay', 'phase'};
    for i = 1:numel(requiredMainFields)
        if ~isfield(cfg.multipath.main, requiredMainFields{i})
            error('addMultipath:MissingField', ...
                'cfg.multipath.main 中缺少字段: %s。', requiredMainFields{i});
        end
    end

    % 检查 paths 结构体数组长度
    if numExtraPaths > 0
        if ~isstruct(cfg.multipath.paths)
            error('addMultipath:InvalidPaths', ...
                'cfg.multipath.paths 必须为结构体数组。');
        end
        if length(cfg.multipath.paths) < numExtraPaths
            error('addMultipath:InvalidPaths', ...
                'cfg.multipath.paths 的长度小于 cfg.multipath.numPaths。');
        end
    end

    numTotalPaths = 1 + numExtraPaths;
    pathSignals = zeros(numTotalPaths, N);

    isComplexInput = ~isreal(sigIn);

    %% 7. 处理主路径
    mainAmp   = cfg.multipath.main.amplitude;
    mainDelay = cfg.multipath.main.delay;
    mainPhase = cfg.multipath.main.phase;

    delayedMain = applyDelay(sigIn, mainDelay, fs, delayMode);

    if isComplexInput
        pathSignals(1, :) = mainAmp * delayedMain .* exp(1j * mainPhase);
    else
        pathSignals(1, :) = mainAmp * delayedMain * cos(mainPhase);
    end

    %% 8. 处理附加多径
    for k = 1:numExtraPaths
        pathk = cfg.multipath.paths(k);

        requiredPathFields = {'amplitude', 'delay', 'phase'};
        for ii = 1:numel(requiredPathFields)
            if ~isfield(pathk, requiredPathFields{ii})
                error('addMultipath:MissingField', ...
                    'cfg.multipath.paths(%d) 中缺少字段: %s。', ...
                    k, requiredPathFields{ii});
            end
        end

        ampK   = pathk.amplitude;
        delayK = pathk.delay;
        phaseK = pathk.phase;

        delayedSig = applyDelay(sigIn, delayK, fs, delayMode);

        if isComplexInput
            pathSignals(k+1, :) = ampK * delayedSig .* exp(1j * phaseK);
        else
            pathSignals(k+1, :) = ampK * delayedSig * cos(phaseK);
        end
    end

    %% 9. 多径叠加
    sigOut = sum(pathSignals, 1);

    %% 10. 保证输出为行向量
    sigOut = sigOut(:).';
    t = t(:).';
end


%% =========================
% 子函数：延迟实现
% =========================
function delayedSig = applyDelay(sig, delaySec, fs, delayMode)
%APPLYDELAY 对输入信号施加延迟
%
%   当前支持:
%       delayMode = 'integer'
%
%   延迟规则:
%       正延迟表示信号向右移动，前面补零

    sig = sig(:).';
    N = length(sig);

    if ~isscalar(delaySec) || delaySec < 0
        error('addMultipath:InvalidDelay', '路径延迟必须为非负标量。');
    end

    switch delayMode
        case 'integer'
            delaySamples = round(delaySec * fs);

            if delaySamples >= N
                delayedSig = zeros(size(sig));
            else
                delayedSig = [zeros(1, delaySamples), sig(1:N-delaySamples)];
            end

        case 'fractional'
            error('addMultipath:FractionalDelayNotImplemented', ...
                '当前版本暂未实现 fractional 小数延迟，请先使用 integer 模式。');

        otherwise
            error('addMultipath:InvalidDelayMode', ...
                'cfg.multipath.delayMode 只能为 ''integer'' 或 ''fractional''。');
    end
end