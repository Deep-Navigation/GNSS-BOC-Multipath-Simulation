function show_results_in_gui(app, results)
%SHOW_RESULTS_IN_GUI
% 将 results 显示到 GUI 中。
%
% 当前功能：
%   1. 更新文本摘要
%   2. 缓存 LastResults
%   3. 尝试显示数据文件路径
%
% 兼容思路：
%   若 app 中存在以下属性，则自动写入：
%   - SummaryTextArea
%   - SummaryEditField
%   - OutputPathEditField
%   - LastResults
%
% 使用方式：
%   show_results_in_gui(app, results)

    if nargin < 2 || ~isstruct(results)
        error('show_results_in_gui: results 必须是结构体。');
    end

    summaryText = build_results_summary_text(results);

    %% 1) 缓存结果
    if isprop(app, 'LastResults')
        app.LastResults = results;
    end

    %% 2) 显示摘要
    if isprop(app, 'SummaryTextArea')
        try
            if iscell(app.SummaryTextArea.Value)
                app.SummaryTextArea.Value = splitlines(summaryText);
            else
                app.SummaryTextArea.Value = summaryText;
            end
        catch
            try
                app.SummaryTextArea.Value = splitlines(summaryText);
            catch
            end
        end
    elseif isprop(app, 'SummaryEditField')
        try
            app.SummaryEditField.Value = summaryText;
        catch
        end
    end

    %% 3) 显示输出路径
    outputText = '';
    if isfield(results, 'dataFile') && ~isempty(results.dataFile)
        outputText = results.dataFile;
    elseif isfield(results, 'outputDir') && ~isempty(results.outputDir)
        outputText = results.outputDir;
    end

    if ~isempty(outputText)
        if isprop(app, 'OutputPathEditField')
            try
                app.OutputPathEditField.Value = outputText;
            catch
            end
        end
    end
end