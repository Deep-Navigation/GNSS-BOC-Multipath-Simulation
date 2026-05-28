function h = plotMultipathEnvelope(delayChips, upperEnvelope, lowerEnvelope, cfg, plotTitle)
%PLOTMULTIPATHENVELOPE 绘制多径误差包络
%   h = utils.plotMultipathEnvelope(delayChips, upperEnvelope, lowerEnvelope, cfg, plotTitle)
%   h = utils.plotMultipathEnvelope(delayChips, upperEnvelope, lowerEnvelope, cfg)
%   h = utils.plotMultipathEnvelope(delayChips, upperEnvelope, lowerEnvelope)
%   h = utils.plotMultipathEnvelope()
%
%   输入:
%       delayChips    - 多径延迟轴（单位：chips，码片）（可选）
%       upperEnvelope - 上包络（单位：chips，码片）（可选）
%       lowerEnvelope - 下包络（单位：chips，码片）（可选）
%       cfg           - 配置结构体（可选）
%       plotTitle     - 图标题（可选）
%
%   输出:
%       h             - 图窗句柄
%
%   功能:
%       1. 绘制单组多径误差包络
%       2. 支持无输入时自动计算默认包络并绘制
%       3. 自动标出零点参考线
%       4. 保持与当前工程风格一致

    %% 1. 处理输入参数
    if nargin < 4 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 5 || isempty(plotTitle)
        if isfield(cfg, 'signal') && isfield(cfg.signal, 'modType')
            plotTitle = sprintf('%s Multipath Error Envelope', upper(cfg.signal.modType));
        else
            plotTitle = 'Multipath Error Envelope';
        end
    end

    if nargin < 1 || isempty(delayChips) || ...
       nargin < 2 || isempty(upperEnvelope) || ...
       nargin < 3 || isempty(lowerEnvelope)

        [delayChips, upperEnvelope, lowerEnvelope] = utils.computeMultipathEnvelope(cfg);
    end

    %% 2. 输入检查
    if ~isvector(delayChips) || isempty(delayChips)
        error('plotMultipathEnvelope:InvalidInput', ...
            '输入 delayChips 必须为非空向量。');
    end

    if ~isvector(upperEnvelope) || isempty(upperEnvelope)
        error('plotMultipathEnvelope:InvalidInput', ...
            '输入 upperEnvelope 必须为非空向量。');
    end

    if ~isvector(lowerEnvelope) || isempty(lowerEnvelope)
        error('plotMultipathEnvelope:InvalidInput', ...
            '输入 lowerEnvelope 必须为非空向量。');
    end

    delayChips = delayChips(:).';
    upperEnvelope = upperEnvelope(:).';
    lowerEnvelope = lowerEnvelope(:).';

    if length(delayChips) ~= length(upperEnvelope) || ...
       length(delayChips) ~= length(lowerEnvelope)
        error('plotMultipathEnvelope:LengthMismatch', ...
            'delayChips、upperEnvelope、lowerEnvelope 长度必须一致。');
    end

    %% 3. 绘图
    h = figure;
    plot(delayChips, upperEnvelope, 'LineWidth', 1.5);
    hold on;
    plot(delayChips, lowerEnvelope, 'LineWidth', 1.5);
    grid on;

    yline(0, '--');
    xline(0, '--');

    xlabel('Multipath Delay (chips)');
    ylabel('Tracking Error Envelope (chips)');
    legend('Upper Envelope', 'Lower Envelope');
    title(plotTitle);

    hold off;
end