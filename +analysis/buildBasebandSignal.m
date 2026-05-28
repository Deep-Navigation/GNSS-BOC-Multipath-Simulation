function [sig, prn] = buildBasebandSignal(cfg, modType)
%BUILDBASEBANDSIGNAL 根据配置与调制类型生成基带信号
%
%   [sig, prn] = analysis.buildBasebandSignal(cfg, modType)
%
%   输入:
%       cfg     - 配置结构体
%       modType - 'BPSK' 或 'BOC'
%
%   输出:
%       sig - 基带信号
%       prn - PRN 码

    if nargin < 2 || isempty(modType)
        error('analysis.buildBasebandSignal:InvalidInput', ...
            'modType 不能为空。');
    end

    cfgLocal = cfg;
    cfgLocal.signal.modType = upper(char(modType));

    prn = core.generatePRN(cfgLocal);

    switch upper(cfgLocal.signal.modType)
        case 'BPSK'
            [sig, ~] = core.bpskModulate(prn, cfgLocal);
        case 'BOC'
            [sig, ~, ~] = core.bocModulate(prn, cfgLocal);
        otherwise
            error('analysis.buildBasebandSignal:InvalidModType', ...
                'modType 只能为 ''BPSK'' 或 ''BOC''。');
    end
end