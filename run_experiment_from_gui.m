function results = run_experiment_from_gui(selection, cfg, scanAxisInput, saveResults)
%RUN_EXPERIMENT_FROM_GUI
% GUI 适配层：接受下拉框选择值和界面输入，调用统一调度入口。
%
% 放置位置：
%   根目录
%
% 使用方式：
%   results = run_experiment_from_gui(selection, cfg, scanAxisInput, saveResults)
%
% 输入：
%   selection     : 可为标准 key，例如：
%                   'amplitude'
%                   'delay_point'
%                   'phase_point'
%                   'spacing_stability_3d'
%
%                   也可为常见显示名，例如：
%                   'Multipath Amplitude Scan'
%                   'Multipath Delay Point Scan'
%                   'Multipath Phase Point Scan'
%                   'Spacing Stability 3D Scan'
%
%   cfg           : 配置结构体；为空时自动使用 config_default()
%   scanAxisInput : 扫描轴输入，可为：
%                   - 数值向量
%                   - 字符串，例如：
%                     '[0.2 0.4 0.6]'
%                     '0:0.1:1'
%                     'linspace(0,pi,5)'
%                   - 空
%   saveResults   : 是否保存
%
% 输出：
%   results

    %% 1) 输入处理
    if nargin < 2 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 3
        scanAxisInput = [];
    end

    if nargin < 4 || isempty(saveResults)
        saveResults = true;
    end

    %% 2) 解析实验类型
    experimentType = resolve_gui_selection(selection);

    %% 3) 解析扫描轴输入
    scanAxis = parse_scan_axis_input(scanAxisInput);

    %% 4) 调统一入口
    results = run_experiment(experimentType, cfg, scanAxis, saveResults);

    %% 5) 回填 GUI 调用信息
    if ~isstruct(results)
        error('run_experiment_from_gui: run_experiment 未返回结构体 results。');
    end

    results.gui = struct();
    results.gui.selection = selection;
    results.gui.parsedScanAxis = scanAxis;
end

%% =========================================================================
function experimentType = resolve_gui_selection(selection)
% 将 GUI 下拉框的值统一映射为 run_experiment 可接受的标准类型

    if nargin < 1 || isempty(selection)
        error('run_experiment_from_gui: selection 不能为空。');
    end

    if ~(ischar(selection) || isstring(selection))
        error('run_experiment_from_gui: selection 必须是字符串或字符向量。');
    end

    sel = strtrim(char(selection));

    switch lower(sel)
        case {'amplitude', 'multipath amplitude scan'}
            experimentType = 'amplitude';

        case {'delay_point', 'multipath delay point scan'}
            experimentType = 'delay_point';

        case {'phase_point', 'multipath phase point scan'}
            experimentType = 'phase_point';

        case {'spacing_stability_3d', 'spacing stability 3d scan'}
            experimentType = 'spacing_stability_3d';

        otherwise
            % 兜底：如果已经是 run_experiment 能识别的别名，直接放过去
            experimentType = sel;
    end
end

%% =========================================================================
function scanAxis = parse_scan_axis_input(scanAxisInput)
% 将 GUI 输入框内容解析成数值向量

    if isempty(scanAxisInput)
        scanAxis = [];
        return;
    end

    if isnumeric(scanAxisInput)
        scanAxis = scanAxisInput;
        return;
    end

    if isstring(scanAxisInput)
        scanAxisInput = char(scanAxisInput);
    end

    if ~ischar(scanAxisInput)
        error('run_experiment_from_gui: scanAxisInput 必须是数值、字符串或空。');
    end

    expr = strtrim(scanAxisInput);

    if isempty(expr)
        scanAxis = [];
        return;
    end

    try
        scanAxis = eval(expr);
    catch ME
        error('run_experiment_from_gui: 无法解析扫描轴输入 "%s"。原因为：%s', expr, ME.message);
    end

    if ~isnumeric(scanAxis) || ~isvector(scanAxis) || ~isreal(scanAxis)
        error('run_experiment_from_gui: 解析后的扫描轴必须是实数向量。');
    end

    if any(~isfinite(scanAxis))
        error('run_experiment_from_gui: 扫描轴不能包含 NaN 或 Inf。');
    end

    scanAxis = scanAxis(:).';
end