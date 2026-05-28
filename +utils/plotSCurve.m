function h = plotSCurve(S, codeOffsets, cfg, plotTitle)
%PLOTSCURVE 绘制 S 曲线
%   h = utils.plotSCurve(S, codeOffsets, cfg, plotTitle)
%   h = utils.plotSCurve(S, codeOffsets, cfg)
%   h = utils.plotSCurve(S, codeOffsets)
%   h = utils.plotSCurve()
%
%   输入:
%       S           - S曲线数据（可选）
%       codeOffsets - 横轴码相位偏移（单位：chips，码片）（可选）
%       cfg         - 配置结构体（可选）
%       plotTitle   - 图标题（可选）
%
%   输出:
%       h           - 图窗句柄
%
%   功能:
%       1. 绘制单条 S 曲线
%       2. 支持无输入时自动计算默认 S 曲线并绘制
%       3. 自动标出零点参考线
%       4. 保持与当前工程风格一致

    %% 1. 处理输入参数
    if nargin < 3 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 4 || isempty(plotTitle)
        if isfield(cfg, 'signal') && isfield(cfg.signal, 'modType')
            plotTitle = sprintf('%s S-Curve', upper(cfg.signal.modType));
        else
            plotTitle = 'S-Curve';
        end
    end

    if nargin < 1 || isempty(S) || nargin < 2 || isempty(codeOffsets)
        [S, codeOffsets] = utils.computeSCurve([], [], cfg);
    end

    %% 2. 输入检查
    if ~isvector(S) || isempty(S)
        error('plotSCurve:InvalidInput', '输入 S 必须为非空向量。');
    end

    if ~isvector(codeOffsets) || isempty(codeOffsets)
        error('plotSCurve:InvalidInput', '输入 codeOffsets 必须为非空向量。');
    end

    S = S(:).';
    codeOffsets = codeOffsets(:).';

    if length(S) ~= length(codeOffsets)
        error('plotSCurve:LengthMismatch', ...
            'S 与 codeOffsets 长度必须一致。');
    end

    %% 3. 绘图
    h = figure;
    plot(codeOffsets, S, 'LineWidth', 1.5);
    grid on;
    hold on;

    % 零点参考线
    yline(0, '--');
    xline(0, '--');

    xlabel('Code Offset (chips)');
    ylabel('Discriminator Output');
    title(plotTitle);

    hold off;
end