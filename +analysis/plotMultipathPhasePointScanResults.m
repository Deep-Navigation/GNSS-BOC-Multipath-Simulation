function figHandles = plotMultipathPhasePointScanResults(results)
%PLOTMULTIPATHPHASEPOINTSCANRESULTS
% analysis 层：根据多径相位点扫描 results 绘图，不负责重新计算，不负责保存。
%
% 输出：
%   figHandles.trackingError
%   figHandles.absTrackingError

    %% 输入检查
    requiredFields = { ...
        'spacing', ...
        'fixedMultipathAmplitude', ...
        'fixedMultipathDelayChip', ...
        'multipathPhases', ...
        'errorPointBPSK', ...
        'errorPointBOC'};

    for i = 1:numel(requiredFields)
        if ~isfield(results, requiredFields{i})
            error('analysis.plotMultipathPhasePointScanResults: results 中缺少字段 %s。', requiredFields{i});
        end
    end

    phases = results.multipathPhases(:).';

    if numel(phases) ~= numel(results.errorPointBPSK) || ...
       numel(phases) ~= numel(results.errorPointBOC)
        error('analysis.plotMultipathPhasePointScanResults: 数据长度不一致。');
    end

    figHandles = struct();

    %% Figure 1: 跟踪误差 vs 相位
    fig1 = figure( ...
        'Name', 'Tracking Error vs Multipath Phase', ...
        'Color', 'w', ...
        'NumberTitle', 'off');
    set(fig1, 'HandleVisibility', 'on');

    ax1 = axes(fig1);
    hold(ax1, 'on');
    grid(ax1, 'on');
    box(ax1, 'on');

    plot(ax1, phases, results.errorPointBPSK, '-o', ...
        'LineWidth', 1.8, ...
        'MarkerSize', 6, ...
        'DisplayName', 'BPSK');

    plot(ax1, phases, results.errorPointBOC, '-s', ...
        'LineWidth', 1.8, ...
        'MarkerSize', 6, ...
        'DisplayName', 'BOC');

    yline(ax1, 0, '--', 'HandleVisibility', 'off');

    xlabel(ax1, 'Multipath Phase / rad');
    ylabel(ax1, 'Tracking Error / chip');

    title(ax1, sprintf( ...
        'Tracking Error vs Multipath Phase\nSpacing = %.3f chip, A = %.2f, Delay = %.3f chip', ...
        results.spacing, results.fixedMultipathAmplitude, results.fixedMultipathDelayChip));

    legend(ax1, 'Location', 'best');
    drawnow;

    figHandles.trackingError = fig1;

    %% Figure 2: 绝对跟踪误差 vs 相位
    fig2 = figure( ...
        'Name', 'Absolute Tracking Error vs Multipath Phase', ...
        'Color', 'w', ...
        'NumberTitle', 'off');
    set(fig2, 'HandleVisibility', 'on');

    ax2 = axes(fig2);
    hold(ax2, 'on');
    grid(ax2, 'on');
    box(ax2, 'on');

    plot(ax2, phases, abs(results.errorPointBPSK), '-o', ...
        'LineWidth', 1.8, ...
        'MarkerSize', 6, ...
        'DisplayName', '|BPSK|');

    plot(ax2, phases, abs(results.errorPointBOC), '-s', ...
        'LineWidth', 1.8, ...
        'MarkerSize', 6, ...
        'DisplayName', '|BOC|');

    xlabel(ax2, 'Multipath Phase / rad');
    ylabel(ax2, 'Absolute Tracking Error / chip');

    title(ax2, sprintf( ...
        'Absolute Tracking Error vs Multipath Phase\nSpacing = %.3f chip, A = %.2f, Delay = %.3f chip', ...
        results.spacing, results.fixedMultipathAmplitude, results.fixedMultipathDelayChip));

    legend(ax2, 'Location', 'best');
    drawnow;

    figHandles.absTrackingError = fig2;
end