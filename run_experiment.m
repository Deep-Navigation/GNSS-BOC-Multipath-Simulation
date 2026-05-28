function results = run_experiment(experimentType, cfg, scanAxis, saveResults)
%RUN_EXPERIMENT
% 统一实验调度入口。
%
% 使用方式：
%   results = run_experiment(experimentType)
%   results = run_experiment(experimentType, cfg)
%   results = run_experiment(experimentType, cfg, scanAxis)
%   results = run_experiment(experimentType, cfg, scanAxis, saveResults)
%
% 支持的 experimentType（标准名与常用别名）：
%   amplitude:
%       'amplitude'
%       'multipath_amplitude'
%       'amplitude_scan'
%       'multipath_amplitude_scan'
%
%   delay_point:
%       'delay'
%       'multipath_delay'
%       'delay_point'
%       'delay_point_scan'
%       'multipath_delay_point_scan'
%
%   phase_point:
%       'phase'
%       'multipath_phase'
%       'phase_point'
%       'phase_point_scan'
%       'multipath_phase_point_scan'
%
%   spacing_stability_3d:
%       'spacing_3d'
%       'spacing_stability_3d'
%       'spacing_stability'
%       'spacing_stability_scan'
%
% 输入：
%   experimentType : 实验类型字符串
%   cfg            : 配置结构体；为空时自动使用 config_default()
%   scanAxis       : 扫描轴；为空时由对应主入口使用默认扫描轴
%   saveResults    : 是否保存；默认 true
%
% 输出：
%   results        : 对应主入口函数返回的结果结构体
%
% 附加返回字段：
%   results.dispatch.requestedType
%   results.dispatch.normalizedType
%   results.dispatch.runnerName
%   results.dispatch.scanAxisProvided
%   results.dispatch.saveResults

    %% =========================
    % 1) 输入处理
    % ==========================
    if nargin < 1 || isempty(experimentType)
        error('run_experiment: experimentType 不能为空。');
    end

    if nargin < 2 || isempty(cfg)
        cfg = config_default();
    end

    if nargin < 3
        scanAxis = [];
    end

    if nargin < 4 || isempty(saveResults)
        saveResults = true;
    end

    %% =========================
    % 2) 实验类型归一化
    % ==========================
    normalizedType = normalizeExperimentType(experimentType);

    %% =========================
    % 3) 扫描轴基本校验
    % ==========================
    scanAxis = validateScanAxis(normalizedType, scanAxis);

    %% =========================
    % 4) 调度执行
    % ==========================
    switch normalizedType
        case 'amplitude'
            runnerName = 'run_multipath_amplitude_scan';
            if isempty(scanAxis)
                results = run_multipath_amplitude_scan(cfg, [], saveResults);
            else
                results = run_multipath_amplitude_scan(cfg, scanAxis, saveResults);
            end

        case 'delay_point'
            runnerName = 'run_multipath_delay_point_scan';
            if isempty(scanAxis)
                results = run_multipath_delay_point_scan(cfg, [], saveResults);
            else
                results = run_multipath_delay_point_scan(cfg, scanAxis, saveResults);
            end

        case 'phase_point'
            runnerName = 'run_multipath_phase_point_scan';
            if isempty(scanAxis)
                results = run_multipath_phase_point_scan(cfg, [], saveResults);
            else
                results = run_multipath_phase_point_scan(cfg, scanAxis, saveResults);
            end

        case 'spacing_stability_3d'
            runnerName = 'run_spacing_stability_3d_scan';
            if isempty(scanAxis)
                results = run_spacing_stability_3d_scan(cfg, [], saveResults);
            else
                results = run_spacing_stability_3d_scan(cfg, scanAxis, saveResults);
            end

        otherwise
            error('run_experiment: 不支持的 normalizedType = %s', normalizedType);
    end

    %% =========================
    % 5) 回填调度信息
    % ==========================
    if ~isstruct(results)
        error('run_experiment: runner %s 未返回结构体 results。', runnerName);
    end

    results.dispatch = struct();
    results.dispatch.requestedType   = char(string(experimentType));
    results.dispatch.normalizedType  = normalizedType;
    results.dispatch.runnerName      = runnerName;
    results.dispatch.scanAxisProvided = ~isempty(scanAxis);
    results.dispatch.saveResults     = logical(saveResults);
end

%% =========================================================================
function normalizedType = normalizeExperimentType(experimentType)
% 将 experimentType 归一化为标准类型名

    if ~(ischar(experimentType) || isstring(experimentType))
        error('run_experiment: experimentType 必须是字符向量或字符串。');
    end

    typeStr = lower(strtrim(char(experimentType)));

    switch typeStr
        case {'amplitude', 'multipath_amplitude', 'amplitude_scan', ...
              'multipath_amplitude_scan'}
            normalizedType = 'amplitude';

        case {'delay', 'multipath_delay', 'delay_point', ...
              'delay_point_scan', 'multipath_delay_point_scan'}
            normalizedType = 'delay_point';

        case {'phase', 'multipath_phase', 'phase_point', ...
              'phase_point_scan', 'multipath_phase_point_scan'}
            normalizedType = 'phase_point';

        case {'spacing_3d', 'spacing_stability_3d', ...
              'spacing_stability', 'spacing_stability_scan'}
            normalizedType = 'spacing_stability_3d';

        otherwise
            error(['run_experiment: 无法识别 experimentType = %s。\n' ...
                   '支持类型：amplitude, delay_point, phase_point, spacing_stability_3d'], ...
                   typeStr);
    end
end

%% =========================================================================
function scanAxis = validateScanAxis(normalizedType, scanAxis)
% 对 scanAxis 做最基本的统一检查

    if isempty(scanAxis)
        return;
    end

    if ~isnumeric(scanAxis) || ~isvector(scanAxis) || ~isreal(scanAxis)
        error('run_experiment: scanAxis 必须是实数向量。');
    end

    if any(~isfinite(scanAxis))
        error('run_experiment: scanAxis 不能包含 NaN 或 Inf。');
    end

    scanAxis = scanAxis(:).';

    switch normalizedType
        case 'amplitude'
            if any(scanAxis < 0)
                error('run_experiment: amplitude 的 scanAxis 不能小于 0。');
            end

        case 'delay_point'
            if any(scanAxis < 0)
                error('run_experiment: delay_point 的 scanAxis 不能小于 0。');
            end

        case 'phase_point'
            % 相位允许任意实数，不额外限制

        case 'spacing_stability_3d'
            if any(scanAxis <= 0)
                error('run_experiment: spacing_stability_3d 的 scanAxis 必须大于 0。');
            end
    end
end