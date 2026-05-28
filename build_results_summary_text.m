function summaryText = build_results_summary_text(results)
%BUILD_RESULTS_SUMMARY_TEXT
% 将 results 结构体转换为 GUI/命令行可展示的摘要文本。
%
% 使用方式：
%   txt = build_results_summary_text(results)

    if nargin < 1 || ~isstruct(results)
        error('build_results_summary_text: 输入必须是 results 结构体。');
    end

    lines = {};

    %% 基本信息
    lines{end+1} = 'Experiment Summary';
    lines{end+1} = '==================';

    if isfield(results, 'scanType')
        lines{end+1} = sprintf('Scan type: %s', results.scanType);
    end

    if isfield(results, 'timestamp')
        lines{end+1} = sprintf('Timestamp: %s', results.timestamp);
    end

    if isfield(results, 'outputDir') && ~isempty(results.outputDir)
        lines{end+1} = sprintf('Output directory: %s', results.outputDir);
    end

    if isfield(results, 'dataFile') && ~isempty(results.dataFile)
        lines{end+1} = sprintf('Data file: %s', results.dataFile);
    else
        lines{end+1} = 'Data file: not saved';
    end

    if isfield(results, 'dispatch') && isstruct(results.dispatch)
        if isfield(results.dispatch, 'normalizedType')
            lines{end+1} = sprintf('Normalized type: %s', results.dispatch.normalizedType);
        end
        if isfield(results.dispatch, 'runnerName')
            lines{end+1} = sprintf('Runner: %s', results.dispatch.runnerName);
        end
        if isfield(results.dispatch, 'saveResults')
            lines{end+1} = sprintf('Save results: %d', logical(results.dispatch.saveResults));
        end
    end

    lines{end+1} = ' ';

    %% 针对不同实验类型补充摘要
    scanType = '';
    if isfield(results, 'scanType')
        scanType = lower(strtrim(char(results.scanType)));
    end

    switch scanType
        case 'multipath_amplitude_scan'
            lines = appendAmplitudeSummary(lines, results);

        case 'multipath_delay_point_scan'
            lines = appendDelaySummary(lines, results);

        case 'multipath_phase_point_scan'
            lines = appendPhaseSummary(lines, results);

        case 'spacing_stability_3d_scan'
            lines = appendSpacing3DSummary(lines, results);

        otherwise
            lines{end+1} = 'Summary details:';
            if isfield(results, 'summary') && isstruct(results.summary)
                lines = appendStructFields(lines, results.summary, '  ');
            else
                lines{end+1} = '  No structured summary available.';
            end
    end

    summaryText = strjoin(lines, newline);
end

%% ========================= Local Functions =========================
function lines = appendAmplitudeSummary(lines, results)
    lines{end+1} = 'Amplitude Scan Summary';
    lines{end+1} = '----------------------';

    if isfield(results, 'spacing')
        lines{end+1} = sprintf('Spacing: %.3f chip', results.spacing);
    end
    if isfield(results, 'fixedMultipathDelayChip')
        lines{end+1} = sprintf('Fixed delay: %.3f chip', results.fixedMultipathDelayChip);
    end
    if isfield(results, 'fixedMultipathPhase')
        lines{end+1} = sprintf('Fixed phase: %.6f rad', results.fixedMultipathPhase);
    end

    if isfield(results, 'summary') && isstruct(results.summary)
        if isfield(results.summary, 'bestAmplitudeBPSK')
            lines{end+1} = sprintf('Best amplitude BPSK: %.6g', results.summary.bestAmplitudeBPSK);
        end
        if isfield(results.summary, 'bestAmplitudeBOC')
            lines{end+1} = sprintf('Best amplitude BOC: %.6g', results.summary.bestAmplitudeBOC);
        end
        if isfield(results.summary, 'maxAbsErrorBPSK')
            lines{end+1} = sprintf('Max |error| BPSK: %.6g', results.summary.maxAbsErrorBPSK);
        end
        if isfield(results.summary, 'maxAbsErrorBOC')
            lines{end+1} = sprintf('Max |error| BOC: %.6g', results.summary.maxAbsErrorBOC);
        end
    end
end

function lines = appendDelaySummary(lines, results)
    lines{end+1} = 'Delay Point Scan Summary';
    lines{end+1} = '------------------------';

    if isfield(results, 'spacing')
        lines{end+1} = sprintf('Spacing: %.3f chip', results.spacing);
    end
    if isfield(results, 'fixedMultipathAmplitude')
        lines{end+1} = sprintf('Fixed amplitude: %.3f', results.fixedMultipathAmplitude);
    end

    if isfield(results, 'summary') && isstruct(results.summary)
        if isfield(results.summary, 'bestDelayBPSK')
            lines{end+1} = sprintf('Best delay BPSK: %.6g chip', results.summary.bestDelayBPSK);
        end
        if isfield(results.summary, 'bestDelayBOC')
            lines{end+1} = sprintf('Best delay BOC: %.6g chip', results.summary.bestDelayBOC);
        end
        if isfield(results.summary, 'maxAbsErrorBPSK')
            lines{end+1} = sprintf('Max |error| BPSK: %.6g', results.summary.maxAbsErrorBPSK);
        end
        if isfield(results.summary, 'maxAbsErrorBOC')
            lines{end+1} = sprintf('Max |error| BOC: %.6g', results.summary.maxAbsErrorBOC);
        end
    end
end

function lines = appendPhaseSummary(lines, results)
    lines{end+1} = 'Phase Point Scan Summary';
    lines{end+1} = '------------------------';

    if isfield(results, 'spacing')
        lines{end+1} = sprintf('Spacing: %.3f chip', results.spacing);
    end
    if isfield(results, 'fixedMultipathAmplitude')
        lines{end+1} = sprintf('Fixed amplitude: %.3f', results.fixedMultipathAmplitude);
    end
    if isfield(results, 'fixedMultipathDelayChip')
        lines{end+1} = sprintf('Fixed delay: %.3f chip', results.fixedMultipathDelayChip);
    end

    if isfield(results, 'summary') && isstruct(results.summary)
        if isfield(results.summary, 'bestPhaseBPSK')
            lines{end+1} = sprintf('Best phase BPSK: %.6f rad', results.summary.bestPhaseBPSK);
        end
        if isfield(results.summary, 'bestPhaseBOC')
            lines{end+1} = sprintf('Best phase BOC: %.6f rad', results.summary.bestPhaseBOC);
        end
        if isfield(results.summary, 'maxAbsErrorBPSK')
            lines{end+1} = sprintf('Max |error| BPSK: %.6g', results.summary.maxAbsErrorBPSK);
        end
        if isfield(results.summary, 'maxAbsErrorBOC')
            lines{end+1} = sprintf('Max |error| BOC: %.6g', results.summary.maxAbsErrorBOC);
        end
    end
end

function lines = appendSpacing3DSummary(lines, results)
    lines{end+1} = 'Spacing Stability 3D Summary';
    lines{end+1} = '----------------------------';

    if isfield(results, 'bestSpacingWorstBPSK')
        lines{end+1} = sprintf('Best spacing by worst-case BPSK: %.3f chip', results.bestSpacingWorstBPSK);
    end
    if isfield(results, 'bestSpacingWorstBOC')
        lines{end+1} = sprintf('Best spacing by worst-case BOC: %.3f chip', results.bestSpacingWorstBOC);
    end
    if isfield(results, 'bestSpacingMeanBPSK')
        lines{end+1} = sprintf('Best spacing by mean BPSK: %.3f chip', results.bestSpacingMeanBPSK);
    end
    if isfield(results, 'bestSpacingMeanBOC')
        lines{end+1} = sprintf('Best spacing by mean BOC: %.3f chip', results.bestSpacingMeanBOC);
    end
    if isfield(results, 'bestOverallWorstBPSK')
        lines{end+1} = sprintf('Best overall worst BPSK: %.6g', results.bestOverallWorstBPSK);
    end
    if isfield(results, 'bestOverallWorstBOC')
        lines{end+1} = sprintf('Best overall worst BOC: %.6g', results.bestOverallWorstBOC);
    end
    if isfield(results, 'bestOverallMeanBPSK')
        lines{end+1} = sprintf('Best overall mean BPSK: %.6g', results.bestOverallMeanBPSK);
    end
    if isfield(results, 'bestOverallMeanBOC')
        lines{end+1} = sprintf('Best overall mean BOC: %.6g', results.bestOverallMeanBOC);
    end
end

function lines = appendStructFields(lines, s, prefix)
    fns = fieldnames(s);
    for i = 1:numel(fns)
        fn = fns{i};
        value = s.(fn);

        if isnumeric(value) && isscalar(value)
            lines{end+1} = sprintf('%s%s: %.6g', prefix, fn, value);
        elseif ischar(value) || isstring(value)
            lines{end+1} = sprintf('%s%s: %s', prefix, fn, char(string(value)));
        end
    end
end