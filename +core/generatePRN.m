function prn = generatePRN(cfg)
%GENERATEPRN 生成GNSS仿真所需的PRN伪随机码
%   prn = core.generatePRN(cfg)
%   prn = core.generatePRN()
%
%   输入:
%       cfg - 配置结构体（可选）。若省略，则自动调用 config_default()
%
%   输出:
%       prn - 1×N 伪随机码序列
%
%   当前版本功能:
%       1. 支持 m序列（mseq）生成
%       2. 支持指定码长 cfg.prn.codeLength
%       3. 支持输出格式:
%            - bipolar: ±1
%            - binary : 0/1
%
%   说明:
%       当前版本优先保证结构清晰与调用稳定。
%       后续可扩展 Gold 码与 PRN 编号选择等功能。

    %% 1. 处理输入参数
    if nargin < 1 || isempty(cfg)
        cfg = config_default();
    end

    if ~isstruct(cfg)
        error('generatePRN:InvalidInput', '输入参数 cfg 必须为结构体。');
    end

    if ~isfield(cfg, 'prn')
        error('generatePRN:MissingField', 'cfg 中缺少 prn 字段。');
    end

    requiredFields = {'codeType', 'codeLength', 'initState', 'outputFormat'};
    for i = 1:numel(requiredFields)
        if ~isfield(cfg.prn, requiredFields{i})
            error('generatePRN:MissingField', ...
                'cfg.prn 中缺少字段: %s。', requiredFields{i});
        end
    end

    %% 2. 读取参数
    codeType     = lower(cfg.prn.codeType);
    codeLength   = cfg.prn.codeLength;
    initState    = cfg.prn.initState(:).';   % 转为行向量
    outputFormat = lower(cfg.prn.outputFormat);

    %% 3. 基本合法性检查
    if ~isscalar(codeLength) || codeLength <= 0 || floor(codeLength) ~= codeLength
        error('generatePRN:InvalidCodeLength', ...
            'cfg.prn.codeLength 必须为正整数。');
    end

    %% 4. 生成伪码
    switch codeType
        case 'mseq'
            prnBinary = generateMSeq(codeLength, initState);

        case 'gold'
            error('generatePRN:UnsupportedType', ...
                '当前版本暂未实现 Gold 码，请先使用 mseq。');

        otherwise
            error('generatePRN:InvalidCodeType', ...
                '不支持的伪码类型: %s。当前仅支持 mseq。', cfg.prn.codeType);
    end

    %% 5. 输出格式转换
    switch outputFormat
        case 'binary'
            prn = prnBinary;

        case 'bipolar'
            % 0 -> -1, 1 -> +1
            prn = 2 * prnBinary - 1;

        otherwise
            error('generatePRN:InvalidOutputFormat', ...
                '不支持的输出格式: %s。请使用 ''binary'' 或 ''bipolar''。', ...
                cfg.prn.outputFormat);
    end

    %% 6. 保证输出为行向量
    prn = prn(:).';
end


%% =========================
%  子函数：生成 m 序列
%  =========================
function seq = generateMSeq(codeLength, initState)
%GENERATEMSEQ 使用线性反馈移位寄存器生成 m 序列
%
%   输入:
%       codeLength - 输出序列长度
%       initState  - 初始寄存器状态，例如 [1 1 1 1 1 1 1 1 1 1]
%
%   输出:
%       seq        - 0/1 二进制 m 序列
%
%   说明:
%       当前默认采用 10 级寄存器，对应本原多项式：
%           x^10 + x^3 + 1
%       即反馈抽头取第 10 位和第 3 位。

    n = length(initState);

    if n ~= 10
        error('generatePRN:UnsupportedRegisterLength', ...
            '当前版本仅支持 10 级寄存器，cfg.prn.initState 必须为 10 位。');
    end

    initState = double(initState ~= 0);

    if all(initState == 0)
        error('generatePRN:InvalidInitState', ...
            'LFSR 初始状态不能全为 0。');
    end

    % 反馈抽头：x^10 + x^3 + 1
    tap1 = 10;
    tap2 = 3;

    reg = initState;
    seq = zeros(1, codeLength);

    for k = 1:codeLength
        % 输出取寄存器最后一位
        seq(k) = reg(end);

        % 反馈值
        feedback = xor(reg(tap1), reg(tap2));

        % 寄存器右移
        reg(2:end) = reg(1:end-1);
        reg(1) = feedback;
    end
end