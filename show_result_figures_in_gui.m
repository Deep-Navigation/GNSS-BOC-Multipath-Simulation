function show_result_figures_in_gui(app, results)
%SHOW_RESULT_FIGURES_IN_GUI
% 将 results.figureHandles 显示到 GUI 中。
%
% 支持：
%   - 单 UIAxes 显示（覆盖式）
%   - 自动识别多个图（按顺序显示）
%
% 要求 app 中存在：
%   app.UIAxes   （推荐）
%
% 可扩展：
%   未来可支持多个 axes / tab

    if nargin < 2 || ~isstruct(results)
        error('show_result_figures_in_gui: results 必须是结构体。');
    end

    if ~isfield(results, 'figureHandles') || isempty(results.figureHandles)
        return;
    end

    figHandles = results.figureHandles;

    % 获取所有图句柄字段
    fn = fieldnames(figHandles);
    if isempty(fn)
        return;
    end

    % 找 UIAxes
    if ~isprop(app, 'UIAxes')
        warning('GUI中未找到 UIAxes，无法显示图像。');
        return;
    end

    ax = app.UIAxes;

    % 清空旧内容
    cla(ax);
    hold(ax, 'off');

    % === 当前策略：只显示第一个图 ===
    % （后面可以扩展为多tab/切换）
    firstFig = figHandles.(fn{1});

    if isempty(firstFig) || ~isgraphics(firstFig)
        warning('figure handle 无效，无法显示。');
        return;
    end

    % 找原figure里的axes
    srcAxes = findobj(firstFig, 'Type', 'axes');

    if isempty(srcAxes)
        warning('未找到源图中的 axes。');
        return;
    end

    % 只取第一个主axes（避免legend/辅助轴干扰）
    srcAxes = srcAxes(1);

    % 复制图内容到 UIAxes
    copyobj(allchild(srcAxes), ax);

    % 同步坐标轴属性
    set(ax, ...
        'XLim', get(srcAxes, 'XLim'), ...
        'YLim', get(srcAxes, 'YLim'), ...
        'XLabel', get(srcAxes, 'XLabel'), ...
        'YLabel', get(srcAxes, 'YLabel'), ...
        'Title', get(srcAxes, 'Title'));

    grid(ax, 'on');
    box(ax, 'on');

    hold(ax, 'off');
end