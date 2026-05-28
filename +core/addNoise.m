function [sigOut, noise, noisePower] = addNoise(sigIn, cfg)
%ADDNOISE 为输入信号加入噪声
%   [sigOut, noise, noisePower] = core.addNoise(sigIn, cfg)
%   [sigOut, noise, noisePower] = core.addNoise(sigIn)
%   [sigOut, noise, noisePower] = core.addNoise()
%
%   输入:
%       sigIn - 输入信号（可选）
%       cfg   - 配置结构体（可选）。若省略，则自动调用 config_default()
%
%   输出:
%       sigOut     - 加噪后的输出信号
%       noise      - 生成的噪声序列
%       noisePower - 噪声功率
%
%   功能:
%       1. 根据 cfg.noise 参数为输入信号加入噪声
%       2. 当前支持 AWGN
%       3. 支持实信号和复信号
%       4. 支持无输入默认调用
%       5. 若 cfg.noise 字段不完整，则自动补默认值
%
%   当前噪声模型:
%       - AWGN
%
%   说明:
%       若 cfg.noise.enable = false，则直接输出原信号，噪声为全零。

    %% 1. 处理 cfg
    if nargin < 2 || isempty(cfg)
        cfg = config_default();
    end

    if ~isstruct(cfg)
        error('addNoise:InvalidInput', '输入参数 cfg 必须为结构体。');
    end

    %% 2. 补全 noise 默认字段，避免缺字段时报错
    if ~isfield(cfg, 'noise') || isempty(cfg.noise)
        cfg.noise = struct();
    end

    if ~isfield(cfg.noise, 'enable') || isempty(cfg.noise.enable)
        cfg.noise.enable = true;
    end

    if ~isfield(cfg.noise, 'type') || isempty(cfg.noise.type)
        cfg.noise.type = 'awgn';
    end

    if ~isfield(cfg.noise, 'snr_dB') || isempty(cfg.noise.snr_dB)
        cfg.noise.snr_dB = 20;
    end

    if ~isfield(cfg.noise, 'seed')
        cfg.noise.seed = 2026;
    end

    %% 3. 若未输入信号，则自动生成默认接收链路信号
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
                error('addNoise:InvalidModType', ...
                    'cfg.signal.modType 只能为 ''BPSK'' 或 ''BOC''。');
        end

        sigChain = sigBase;

        if isfield(cfg, 'carrier') && isfield(cfg.carrier, 'enable') && cfg.carrier.enable
            [sigChain, ~, ~] = core.addCarrier(sigChain, cfg);
        end

        if isfield(cfg, 'multipath') && isfield(cfg.multipath, 'enable') && cfg.multipath.enable
            [sigChain, ~, ~] = core.addMultipath(sigChain, cfg);
        end

        sigIn = sigChain;
    end

    %% 4. 输入检查
    if ~isvector(sigIn) || isempty(sigIn)
        error('addNoise:InvalidSignal', '输入信号 sigIn 必须为非空向量。');
    end

    sigIn = sigIn(:).';

    %% 5. 如果未启用噪声，直接返回
    if ~cfg.noise.enable
        sigOut = sigIn;
        noise = zeros(size(sigIn));
        noisePower = 0;

        if ~isreal(sigIn)
            noise = complex(noise, noise);
        end
        return;
    end

    %% 6. 读取参数
    noiseType = lower(cfg.noise.type);
    snr_dB = cfg.noise.snr_dB;
    seed = cfg.noise.seed;

    if ~isscalar(snr_dB)
        error('addNoise:InvalidSNR', 'cfg.noise.snr_dB 必须为标量。');
    end

    if ~isempty(seed)
        rng(seed);
    end

    %% 7. 计算信号功率
    sigPower = mean(abs(sigIn).^2);

    if sigPower <= 0
        error('addNoise:InvalidSignalPower', '输入信号功率必须大于 0。');
    end

    noisePower = sigPower / (10^(snr_dB / 10));

    %% 8. 生成噪声
    switch noiseType
        case 'awgn'
            if isreal(sigIn)
                noise = sqrt(noisePower) * randn(size(sigIn));
            else
                noise = sqrt(noisePower / 2) * ...
                    (randn(size(sigIn)) + 1j * randn(size(sigIn)));
            end

        otherwise
            error('addNoise:UnsupportedNoiseType', ...
                '当前仅支持 ''awgn'' 噪声类型。');
    end

    %% 9. 加噪
    sigOut = sigIn + noise;

    %% 10. 保证输出为行向量
    sigOut = sigOut(:).';
    noise = noise(:).';
end