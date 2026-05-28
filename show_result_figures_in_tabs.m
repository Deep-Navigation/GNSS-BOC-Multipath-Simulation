function show_result_figures_in_tabs(tabGroup, results)
%SHOW_RESULT_FIGURES_IN_TABS
% 将 results 中的图像显示到 TabGroup 中，每个图一个 Tab。
%
% 放置位置：
%   根目录
%
% 正确使用方式：
%   show_result_figures_in_tabs(tabGroup, results)
%
% 说明：
%   1. 本函数不是独立运行入口，不能直接只输入函数名运行
%   2. 它需要两个输入：
%      - tabGroup : GUI里的 uitabgroup 对象
%      - results  : 实验结果结构体
%   3. 显示优先级：
%      - 优先使用 results.figureHandles 中的有效 figure handle
%      - 若无有效 handle，则回退使用 results.figureFiles 中已保存的 PNG 文件
%      - 若两者都不可用，则显示提示信息 Tab

    %% 0) 友好处理：若用户直接在命令行输入函数名，则提示正确用法
    if nargin == 0
        fprintf('\nshow_result_figures_in_tabs 不是独立运行入口。\n');
        fprintf('正确用法：show_result_figures_in_tabs(tabGroup, results)\n');
        fprintf('请通过 run_gui_app 运行 GUI，再由 GUI 内部自动调用本函数。\n\n');
        return;
    end

    if nargin < 2
        error('show_result_figures_in_tabs: 需要两个输入参数：tabGroup 和 results。');
    end

    if ~isa(tabGroup, 'matlab.ui.container.TabGroup')
        error('show_result_figures_in_tabs: 第一个输入必须是 uitabgroup。');
    end

    if ~isstruct(results)
        error('show_result_figures_in_tabs: 第二个输入 results 必须是结构体。');
    end

    %% 1) 清空旧 tab
    oldTabs = tabGroup.Children;
    for i = 1:numel(oldTabs)
        delete(oldTabs(i));
    end

    %% 2) 先尝试用 figureHandles
    nTabsCreated = 0;

    if isfield(results, 'figureHandles') && isstruct(results.figureHandles)
        figHandles = results.figureHandles;
        names = fieldnames(figHandles);

        for i = 1:numel(names)
            fieldName = names{i};
            figHandle = figHandles.(fieldName);

            if isempty(figHandle) || ~isgraphics(figHandle)
                continue;
            end

            ok = createFigureHandleTab(tabGroup, fieldName, figHandle);
            if ok
                nTabsCreated = nTabsCreated + 1;
            end
        end
    end

    %% 3) 如果没有有效 figure handle，则回退到 figureFiles PNG
    if nTabsCreated == 0
        if isfield(results, 'figureFiles') && isstruct(results.figureFiles)
            figureFiles = results.figureFiles;
            fileFields = fieldnames(figureFiles);

            for i = 1:numel(fileFields)
                fieldName = fileFields{i};
                filePath = figureFiles.(fieldName);

                if ~ischar(filePath) && ~isstring(filePath)
                    continue;
                end

                filePath = char(string(filePath));

                if isempty(filePath)
                    continue;
                end

                if ~endsWith(lower(filePath), '.png')
                    continue;
                end

                if ~exist(filePath, 'file')
                    continue;
                end

                ok = createImageTab(tabGroup, fieldName, filePath);
                if ok
                    nTabsCreated = nTabsCreated + 1;
                end
            end
        end
    end

    %% 4) 如果仍然没有图，就显示提示信息
    if nTabsCreated == 0
        messageText = buildNoFigureMessage(results);
        createMessageTab(tabGroup, 'No Figures', messageText);
    end
end

%% =========================================================================
function ok = createFigureHandleTab(tabGroup, fieldName, figHandle)
% 用有效 figure handle 创建一个 tab

    ok = false;

    try
        srcAxesAll = findobj(figHandle, 'Type', 'axes');
        if isempty(srcAxesAll)
            return;
        end

        srcAxes = pickMainAxes(srcAxesAll);
        if isempty(srcAxes) || ~isgraphics(srcAxes)
            return;
        end

        tabTitle = makeTabTitle(fieldName);
        tab = uitab(tabGroup, 'Title', tabTitle);

        ax = uiaxes(tab, 'Position', [20 20 560 520]);
        cla(ax);

        copyobj(allchild(srcAxes), ax);

        try
            ax.XLim = srcAxes.XLim;
        catch
        end

        try
            ax.YLim = srcAxes.YLim;
        catch
        end

        try
            ax.XScale = srcAxes.XScale;
        catch
        end

        try
            ax.YScale = srcAxes.YScale;
        catch
        end

        try
            ax.XGrid = srcAxes.XGrid;
            ax.YGrid = srcAxes.YGrid;
        catch
        end

        try
            ax.Box = srcAxes.Box;
        catch
        end

        try
            xlabel(ax, srcAxes.XLabel.String);
        catch
        end

        try
            ylabel(ax, srcAxes.YLabel.String);
        catch
        end

        try
            title(ax, srcAxes.Title.String);
        catch
            title(ax, tabTitle);
        end

        try
            legend(ax, 'off');
            srcLegend = findobj(figHandle, 'Type', 'legend');
            if ~isempty(srcLegend)
                labels = srcLegend(1).String;
                if ~isempty(labels)
                    legend(ax, labels, 'Location', srcLegend(1).Location);
                end
            end
        catch
        end

        grid(ax, 'on');
        box(ax, 'on');

        ok = true;

    catch
        ok = false;
    end
end

%% =========================================================================
function ok = createImageTab(tabGroup, fieldName, filePath)
% 用 PNG 文件创建一个 tab

    ok = false;

    try
        img = imread(filePath);

        tabTitle = makeTabTitle(fieldName);
        tab = uitab(tabGroup, 'Title', tabTitle);

        uiimage(tab, ...
            'Position', [20 20 560 520], ...
            'ImageSource', img, ...
            'ScaleMethod', 'fit');

        ok = true;

    catch
        ok = false;
    end
end

%% =========================================================================
function srcAxes = pickMainAxes(allAxes)
% 尽量选主 axes，排除 legend / colorbar 等干扰项

    srcAxes = [];

    for k = 1:numel(allAxes)
        ax = allAxes(k);

        try
            tag = get(ax, 'Tag');
        catch
            tag = '';
        end

        if strcmpi(tag, 'legend') || strcmpi(tag, 'Colorbar')
            continue;
        end

        srcAxes = ax;
        return;
    end

    if isempty(srcAxes) && ~isempty(allAxes)
        srcAxes = allAxes(1);
    end
end

%% =========================================================================
function createMessageTab(tabGroup, titleStr, messageStr)
% 创建一个仅显示文字信息的 tab

    tab = uitab(tabGroup, 'Title', titleStr);

    uitextarea(tab, ...
        'Position', [20 20 560 520], ...
        'Editable', 'off', ...
        'Value', splitlines(messageStr));
end

%% =========================================================================
function titleStr = makeTabTitle(fieldName)
% 把字段名转换成可读 tab 名称

    titleStr = regexprep(fieldName, '([a-z])([A-Z])', '$1 $2');
    titleStr = strrep(titleStr, '_', ' ');
    titleStr = strtrim(titleStr);

    if ~isempty(titleStr)
        titleStr(1) = upper(titleStr(1));
    else
        titleStr = 'Figure';
    end
end

%% =========================================================================
function messageText = buildNoFigureMessage(results)
% 构造没有图时的提示信息

    lines = {};
    lines{end+1} = '没有有效的 figure handle。';
    lines{end+1} = '已自动尝试回退到已保存的 PNG 文件。';
    lines{end+1} = '但当前 results 中仍未找到可显示图像。';

    if isfield(results, 'scanType')
        lines{end+1} = sprintf('scanType: %s', results.scanType);
    end

    if isfield(results, 'dataFile') && ~isempty(results.dataFile)
        lines{end+1} = sprintf('dataFile: %s', results.dataFile);
    end

    if isfield(results, 'outputDir') && ~isempty(results.outputDir)
        lines{end+1} = sprintf('outputDir: %s', results.outputDir);
    end

    messageText = strjoin(lines, newline);
end