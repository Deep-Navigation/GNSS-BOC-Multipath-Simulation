function [pxx_dB, f] = plotSpectrum(sig, cfg, figTitle)
%PLOTSPECTRUM 绘制信号功率谱
%   [pxx_dB, f] = utils.plotSpectrum(sig, cfg)
%   [pxx_dB, f] = utils.plotSpectrum(sig, cfg, figTitle)
%   [pxx_dB, f] = utils.plotSpectrum(sig)
%   [pxx_dB, f] = utils.plotSpectrum()
%
%   输入:
%       sig      - 待分析信号（可选）。若省略，则自动生成默认测试信号
%       cfg      - 配置结构体（可选）。若省略，则自动调用 config_default()
%       figTitle - 图标题（可选）
%
%   输出:
%       pxx_dB   - 功率谱密度（dB）
%       f        - 频率轴（Hz）
%
%   功能:
%       1. 基于 pwelch 估计输入信号功率谱
%       2. 支持无输入参数时自动生成默认测试信号
%       3. 自动绘图并返回频谱数据
%
%   默认行为:
%       - 若 cfg.signal.modType = 'BPSK'，自动生成 BPSK 信号
%       - 否则默认生成 BOC 信号

    %% 1. 处理 cfg
    if nargin < 2 || isempty(cfg)
        cfg = config_default();
    end

    if ~isstruct(cfg)
        error('plotSpectrum:InvalidInput', '输入参数 cfg 必须为结构体。');
    end

    %% 2. 处理 sig
    if nargin < 1 || isempty(sig)
        prn = core.generatePRN(cfg);

        if isfield(cfg, 'signal') && isfield(cfg.signal, 'modType')
            modType = upper(cfg.signal.modType);
        else
            modType = 'BOC';
        end

        switch modType
            case 'BPSK'
                [sig, ~] = core.bpskModulate(prn, cfg);

            case 'BOC'
                [sig, ~, ~] = core.bocModulate(prn, cfg);

            otherwise
                error('plotSpectrum:InvalidModType', ...
                    'cfg.signal.modType 只能为 ''BPSK'' 或 ''BOC''。');
        end
    end

    if nargin < 3 || isempty(figTitle)
        if isfield(cfg, 'signal') && isfield(cfg.signal, 'modType')
            figTitle = [upper(cfg.signal.modType), ' Power Spectrum'];
        else
            figTitle = 'Power Spectrum';
        end
    end

    %% 3. 检查输入信号
    if ~isvector(sig) || isempty(sig)
        error('plotSpectrum:InvalidSignal', '输入信号 sig 必须为非空向量。');
    end

    sig = sig(:);  % 转为列向量

    %% 4. 检查配置字段
    if ~isfield(cfg, 'time') || ~isfield(cfg.time, 'fs')
        error('plotSpectrum:MissingField', 'cfg.time.fs 不存在。');
    end

    if ~isfield(cfg, 'plot')
        error('plotSpectrum:MissingField', 'cfg.plot 不存在。');
    end

    requiredPlotFields = {'spectrumNFFT', 'spectrumCenter', 'lineWidth', 'fontSize'};
    for i = 1:numel(requiredPlotFields)
        if ~isfield(cfg.plot, requiredPlotFields{i})
            error('plotSpectrum:MissingField', ...
                'cfg.plot 中缺少字段: %s。', requiredPlotFields{i});
        end
    end

    fs       = cfg.time.fs;
    nfft     = cfg.plot.spectrumNFFT;
    isCenter = cfg.plot.spectrumCenter;
    lw       = cfg.plot.lineWidth;
    fsz      = cfg.plot.fontSize;

    %% 5. Welch 参数设置
    winLen = min(1024, length(sig));
    if winLen < 8
        error('plotSpectrum:SignalTooShort', '输入信号长度过短，无法进行频谱估计。');
    end

    overlap = floor(winLen / 2);
    win = hamming(winLen);

    %% 6. 计算功率谱
    if isCenter
        [pxx, f] = pwelch(sig, win, overlap, nfft, fs, 'centered');
    else
        [pxx, f] = pwelch(sig, win, overlap, nfft, fs);
    end

    pxx_dB = 10 * log10(pxx + eps);

    %% 7. 绘图
    figure;
    plot(f, pxx_dB, 'LineWidth', lw);
    grid on;
    xlabel('Frequency (Hz)', 'FontSize', fsz);
    ylabel('PSD (dB/Hz)', 'FontSize', fsz);
    title(figTitle, 'FontSize', fsz);
    xlim([min(f), max(f)]);
end