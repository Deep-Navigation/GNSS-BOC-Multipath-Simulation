function h = plotMultipathError(delayChips, trackingErrorChips, cfg, plotTitle)
%PLOTMULTIPATHERROR 绘制多径跟踪误差曲线
%   h = utils.plotMultipathError(delayChips, trackingErrorChips, cfg, plotTitle)
%   h = utils.plotMultipathError(delayChips, trackingErrorChips, cfg)
%   h = utils.plotMultipathError(delayChips, trackingErrorChips)
%   h = utils.plotMultipathError()
%
%   输入:
%       delayChips         - 多径延迟轴（单位：chips，码片）（可选）
%       trackingErrorChips - 跟踪误差轴（单位：chips，码片）（可选）
%       cfg                - 配置结构体（可选）
%       plotTitle          - 图标题（可选）
%
%   输出:
%       h                  - 图窗句柄
%
%   功能:
%       1. 绘制单条多径跟踪误差曲线
%       2. 支持无输入时自动计算默认多径误差并绘制
%       3. 自动标出零点参考线
%       4. 保持与当前工程风格一致

    %% 1. 处理输入参数
    if nargin < 3 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 4 || isempty(plotTitle)
        if isfield(cfg, 'signal') && isfield(cfg.signal, 'modType')
            plotTitle = sprintf('%s Multipath Tracking Error', upper(cfg.signal.modType));
        else
            plotTitle = 'Multipath Tracking Error';
        end
    end

    if nargin < 1 || isempty(delayChips) || nargin < 2 || isempty(trackingErrorChips)
        [delayChips, trackingErrorChips] = utils.computeMultipathError(cfg);
    end

    %% 2. 输入检查
    if ~isvector(delayChips) || isempty(delayChips)
        error('plotMultipathError:InvalidInput', ...
            '输入 delayChips 必须为非空向量。');
    end

    if ~isvector(trackingErrorChips) || isempty(trackingErrorChips)
        error('plotMultipathError:InvalidInput', ...
            '输入 trackingErrorChips 必须为非空向量。');
    end

    delayChips = delayChips(:).';
    trackingErrorChips = trackingErrorChips(:).';

    if length(delayChips) ~= length(trackingErrorChips)
        error('plotMultipathError:LengthMismatch', ...
            'delayChips 与 trackingErrorChips 长度必须一致。');
    end

    %% 3. 绘图
    h = figure;
    plot(delayChips, trackingErrorChips, 'LineWidth', 1.5);
    grid on;
    hold on;

    yline(0, '--');
    xline(0, '--');

    xlabel('Multipath Delay (chips)');
    ylabel('Tracking Error (chips)');
    title(plotTitle);

    hold off;
end