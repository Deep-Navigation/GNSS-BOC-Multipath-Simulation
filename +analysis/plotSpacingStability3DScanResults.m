function figHandles = plotSpacingStability3DScanResults(results)
%PLOTSPACINGSTABILITY3DSCANRESULTS
% analysis 层：根据 spacing stability 3D scan results 绘图，不负责计算与保存。

    requiredFields = { ...
        'spacingList', ...
        'overallWorstAbsBPSK', ...
        'overallWorstAbsBOC', ...
        'ampWorstAbsBPSK', ...
        'ampWorstAbsBOC', ...
        'delayWorstAbsBPSK', ...
        'delayWorstAbsBOC', ...
        'phaseWorstAbsBPSK', ...
        'phaseWorstAbsBOC', ...
        'overallMeanAbsBPSK', ...
        'overallMeanAbsBOC'};

    for i = 1:numel(requiredFields)
        if ~isfield(results, requiredFields{i})
            error('analysis.plotSpacingStability3DScanResults: results 中缺少字段 %s。', requiredFields{i});
        end
    end

    spacingList = results.spacingList(:).';
    figHandles = struct();

    %% Figure 1
    fig1 = figure( ...
        'Name', 'Overall Worst Abs Error vs Spacing', ...
        'Color', 'w', ...
        'NumberTitle', 'off');
    set(fig1, 'HandleVisibility', 'on');

    ax1 = axes(fig1);
    hold(ax1, 'on'); grid(ax1, 'on'); box(ax1, 'on');
    plot(ax1, spacingList, results.overallWorstAbsBPSK, '-o', ...
        'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'BPSK');
    plot(ax1, spacingList, results.overallWorstAbsBOC, '-s', ...
        'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'BOC');
    xlabel(ax1, 'Early-Late Spacing / chip');
    ylabel(ax1, 'Overall Worst Absolute Tracking Error');
    title(ax1, 'Overall Worst Absolute Error vs Early-Late Spacing');
    legend(ax1, 'Location', 'best');
    drawnow;
    figHandles.overallWorst = fig1;

    %% Figure 2
    fig2 = figure( ...
        'Name', 'BPSK Dimension Worst Abs Error vs Spacing', ...
        'Color', 'w', ...
        'NumberTitle', 'off');
    set(fig2, 'HandleVisibility', 'on');

    ax2 = axes(fig2);
    hold(ax2, 'on'); grid(ax2, 'on'); box(ax2, 'on');
    plot(ax2, spacingList, results.ampWorstAbsBPSK, '-o', ...
        'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'Amplitude');
    plot(ax2, spacingList, results.delayWorstAbsBPSK, '-s', ...
        'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'Delay');
    plot(ax2, spacingList, results.phaseWorstAbsBPSK, '-d', ...
        'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'Phase');
    xlabel(ax2, 'Early-Late Spacing / chip');
    ylabel(ax2, 'Worst Absolute Tracking Error');
    title(ax2, 'BPSK Worst Absolute Error in Three Dimensions');
    legend(ax2, 'Location', 'best');
    drawnow;
    figHandles.bpskDimensionWorst = fig2;

    %% Figure 3
    fig3 = figure( ...
        'Name', 'BOC Dimension Worst Abs Error vs Spacing', ...
        'Color', 'w', ...
        'NumberTitle', 'off');
    set(fig3, 'HandleVisibility', 'on');

    ax3 = axes(fig3);
    hold(ax3, 'on'); grid(ax3, 'on'); box(ax3, 'on');
    plot(ax3, spacingList, results.ampWorstAbsBOC, '-o', ...
        'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'Amplitude');
    plot(ax3, spacingList, results.delayWorstAbsBOC, '-s', ...
        'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'Delay');
    plot(ax3, spacingList, results.phaseWorstAbsBOC, '-d', ...
        'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'Phase');
    xlabel(ax3, 'Early-Late Spacing / chip');
    ylabel(ax3, 'Worst Absolute Tracking Error');
    title(ax3, 'BOC Worst Absolute Error in Three Dimensions');
    legend(ax3, 'Location', 'best');
    drawnow;
    figHandles.bocDimensionWorst = fig3;

    %% Figure 4
    fig4 = figure( ...
        'Name', 'Overall Mean Abs Error vs Spacing', ...
        'Color', 'w', ...
        'NumberTitle', 'off');
    set(fig4, 'HandleVisibility', 'on');

    ax4 = axes(fig4);
    hold(ax4, 'on'); grid(ax4, 'on'); box(ax4, 'on');
    plot(ax4, spacingList, results.overallMeanAbsBPSK, '-o', ...
        'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'BPSK');
    plot(ax4, spacingList, results.overallMeanAbsBOC, '-s', ...
        'LineWidth', 1.8, 'MarkerSize', 6, 'DisplayName', 'BOC');
    xlabel(ax4, 'Early-Late Spacing / chip');
    ylabel(ax4, 'Overall Mean Absolute Tracking Error');
    title(ax4, 'Overall Mean Absolute Error vs Early-Late Spacing');
    legend(ax4, 'Location', 'best');
    drawnow;
    figHandles.overallMean = fig4;
end