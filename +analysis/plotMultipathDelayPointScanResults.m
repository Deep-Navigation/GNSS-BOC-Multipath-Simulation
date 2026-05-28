function figHandles = plotMultipathDelayPointScanResults(results)

    requiredFields = { ...
        'spacing', ...
        'fixedMultipathAmplitude', ...
        'multipathDelaysChip', ...
        'errorPointBPSK', ...
        'errorPointBOC'};

    for i = 1:numel(requiredFields)
        if ~isfield(results, requiredFields{i})
            error('analysis.plotMultipathDelayPointScanResults: results 中缺少字段 %s。', requiredFields{i});
        end
    end

    delaysChip = results.multipathDelaysChip(:).';

    figHandles = struct();

    %% Figure 1
    fig1 = figure('Name', 'Tracking Error vs Specified Delay', 'Color', 'w');
    set(fig1, 'HandleVisibility', 'on');   % ⭐关键
    hold on; grid on; box on;

    plot(delaysChip, results.errorPointBPSK, '-o', ...
        'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'BPSK');
    plot(delaysChip, results.errorPointBOC, '-s', ...
        'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'BOC');

    yline(0, '--');
    xlabel('Specified Multipath Delay / chip');
    ylabel('Tracking Error / chip');
    title(sprintf('Tracking Error vs Specified Multipath Delay (Spacing = %.3f chip, A = %.2f)', ...
        results.spacing, results.fixedMultipathAmplitude));
    legend('Location', 'best');

    drawnow;  % ⭐确保渲染完成

    figHandles.trackingError = fig1;

    %% Figure 2
    fig2 = figure('Name', 'Absolute Tracking Error vs Specified Delay', 'Color', 'w');
    set(fig2, 'HandleVisibility', 'on');   % ⭐关键
    hold on; grid on; box on;

    plot(delaysChip, abs(results.errorPointBPSK), '-o', ...
        'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', '|BPSK|');
    plot(delaysChip, abs(results.errorPointBOC), '-s', ...
        'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', '|BOC|');

    xlabel('Specified Multipath Delay / chip');
    ylabel('Absolute Tracking Error / chip');
    title(sprintf('Absolute Tracking Error vs Specified Multipath Delay (Spacing = %.3f chip, A = %.2f)', ...
        results.spacing, results.fixedMultipathAmplitude));
    legend('Location', 'best');

    drawnow;  % ⭐关键

    figHandles.absTrackingError = fig2;
end