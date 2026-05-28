function export_current_tab_figure(tabGroup)
%EXPORT_CURRENT_TAB_FIGURE
% 导出当前 Tab 中的图像为 PNG 文件
%
% 放置位置：
%   根目录
%
% 使用方式：
%   export_current_tab_figure(tabGroup)

    if ~isa(tabGroup, 'matlab.ui.container.TabGroup')
        error('输入必须是 TabGroup');
    end

    currentTab = tabGroup.SelectedTab;

    if isempty(currentTab)
        error('没有选中的 Tab');
    end

    ax = findobj(currentTab, 'Type', 'axes');

    if isempty(ax)
        uialert(currentTab.Parent, '当前 Tab 没有图像可导出', 'Error');
        return;
    end

    ax = ax(1);

    % 创建临时 figure
    f = figure('Visible', 'off');
    newAx = axes(f);

    copyobj(allchild(ax), newAx);

    % 同步属性
    newAx.XLim = ax.XLim;
    newAx.YLim = ax.YLim;
    xlabel(newAx, ax.XLabel.String);
    ylabel(newAx, ax.YLabel.String);
    title(newAx, ax.Title.String);
    grid(newAx, 'on');
    box(newAx, 'on');

    % 文件选择
    [file, path] = uiputfile('*.png', 'Save Current Figure');

    if isequal(file, 0)
        close(f);
        return;
    end

    savePath = fullfile(path, file);

    saveas(f, savePath);
    close(f);

    uialert(currentTab.Parent, ...
        sprintf('图像已保存:\n%s', savePath), ...
        'Success');
end