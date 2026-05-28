function run_gui_app()
%RUN_GUI_APP
% 自动创建 GUI（无需 App Designer）
%
% 功能：
%   - 实验选择
%   - 参数输入
%   - 多图 Tab 显示
%   - 一键导出当前图像
%
% 放置位置：
%   根目录
%
% 使用方式：
%   run_gui_app

    %% 创建主窗口
    fig = uifigure('Name', 'GNSS Simulator', 'Position', [100 100 1100 650]);

    %% 实验类型
    displayNames = { ...
        'Multipath Amplitude Scan', ...
        'Multipath Delay Point Scan', ...
        'Multipath Phase Point Scan', ...
        'Spacing Stability 3D Scan'};

    itemKeys = { ...
        'amplitude', ...
        'delay_point', ...
        'phase_point', ...
        'spacing_stability_3d'};

    %% 左侧控件
    uilabel(fig, 'Position', [20 600 100 22], 'Text', 'Experiment');
    dd = uidropdown(fig, ...
        'Position', [120 600 260 22], ...
        'Items', displayNames, ...
        'ItemsData', itemKeys, ...
        'Value', itemKeys{1});

    uilabel(fig, 'Position', [20 560 100 22], 'Text', 'Scan Axis');
    editAxis = uieditfield(fig, 'text', ...
        'Position', [120 560 260 22], ...
        'Value', '');

    cbSave = uicheckbox(fig, ...
        'Text', 'Save Results', ...
        'Position', [20 520 120 22], ...
        'Value', true);

    %% 按钮
    btnRun = uibutton(fig, ...
        'Text', 'Run', ...
        'Position', [160 515 100 30]);

    btnExport = uibutton(fig, ...
        'Text', 'Export Current Figure', ...
        'Position', [280 515 180 30]);

    %% 输出路径
    uilabel(fig, 'Position', [20 480 100 22], 'Text', 'Output');
    txtPath = uieditfield(fig, 'text', ...
        'Position', [120 480 260 22], ...
        'Value', '');

    %% Summary
    uilabel(fig, 'Position', [20 450 100 22], 'Text', 'Summary');
    txtSummary = uitextarea(fig, ...
        'Position', [20 20 400 420], ...
        'Value', {'Ready.'});

    %% 右侧 TabGroup
    tabGroup = uitabgroup(fig, ...
        'Position', [450 20 620 600]);

    welcomeTab = uitab(tabGroup, 'Title', 'Welcome');
    uitextarea(welcomeTab, ...
        'Position', [20 20 560 520], ...
        'Editable', 'off', ...
        'Value', { ...
            'GNSS Simulator GUI is ready.', ...
            'Select an experiment, then click Run.'});

    %% 回调绑定
    btnRun.ButtonPushedFcn = @(src, event) runCallback(src, event, dd, editAxis, cbSave, txtSummary, txtPath, tabGroup, fig);
    btnExport.ButtonPushedFcn = @(~,~) export_current_tab_figure(tabGroup);

end

%% ================= Run 回调 =================
function runCallback(~, ~, dd, editAxis, cbSave, txtSummary, txtPath, tabGroup, fig)

    cfg = config_default();

    selection = dd.Value;
    scanAxisInput = editAxis.Value;
    saveResults = cbSave.Value;

    try
        results = run_experiment_from_gui(selection, cfg, scanAxisInput, saveResults);

        % Summary
        summaryText = build_results_summary_text(results);
        txtSummary.Value = splitlines(summaryText);

        % 输出路径
        if isfield(results, 'dataFile') && ~isempty(results.dataFile)
            txtPath.Value = results.dataFile;
        elseif isfield(results, 'outputDir') && ~isempty(results.outputDir)
            txtPath.Value = results.outputDir;
        else
            txtPath.Value = '';
        end

        % 图像显示（多 Tab）
        show_result_figures_in_tabs(tabGroup, results);

    catch ME
        uialert(fig, ME.message, 'Error');
    end

end

%% ================= 导出函数 =================
function export_current_tab_figure(tabGroup)

    if ~isa(tabGroup, 'matlab.ui.container.TabGroup')
        error('输入必须是 TabGroup');
    end

    currentTab = tabGroup.SelectedTab;

    if isempty(currentTab)
        return;
    end

    ax = findobj(currentTab, 'Type', 'axes');

    if isempty(ax)
        uialert(tabGroup.Parent, '当前 Tab 没有图像可导出', 'Error');
        return;
    end

    ax = ax(1);

    % 创建临时 figure
    f = figure('Visible', 'off');
    newAx = axes(f);

    copyobj(allchild(ax), newAx);

    newAx.XLim = ax.XLim;
    newAx.YLim = ax.YLim;
    xlabel(newAx, ax.XLabel.String);
    ylabel(newAx, ax.YLabel.String);
    title(newAx, ax.Title.String);

    [file, path] = uiputfile('*.png', 'Save Current Figure');

    if isequal(file, 0)
        close(f);
        return;
    end

    saveas(f, fullfile(path, file));
    close(f);

    uialert(tabGroup.Parent, '图像已成功保存', 'Success');
end