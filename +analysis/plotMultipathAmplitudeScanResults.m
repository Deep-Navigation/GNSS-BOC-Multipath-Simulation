function figHandles = plotMultipathAmplitudeScanResults(results)
%PLOTMULTIPATHAMPLITUDESCANRESULTS
% 绘制多径幅度扫描结果（稳定句柄版本）

    % ===== 数据检查 =====
    requiredFields = {'multipathAmplitudes', 'maxAbsErrorBPSK', 'maxAbsErrorBOC'};
    for i = 1:numel(requiredFields)
        if ~isfield(results, requiredFields{i})
            error('plotMultipathAmplitudeScanResults: 缺少字段 %s', requiredFields{i});
        end
    end

    amps = results.multipathAmplitudes;

    %% =========================
    % 1. BPSK 包络图
    % =========================
    fig1 = figure('Name','BPSK Envelope','NumberTitle','off');
    plot(amps, results.maxAbsErrorBPSK, '-o', 'LineWidth', 1.5);
    grid on;
    xlabel('Multipath Amplitude');
    ylabel('Max Abs Error');
    title('BPSK Envelope Error');

    %% =========================
    % 2. BOC 包络图
    % =========================
    fig2 = figure('Name','BOC Envelope','NumberTitle','off');
    plot(amps, results.maxAbsErrorBOC, '-s', 'LineWidth', 1.5);
    grid on;
    xlabel('Multipath Amplitude');
    ylabel('Max Abs Error');
    title('BOC Envelope Error');

    %% =========================
    % 3. 对比图
    % =========================
    fig3 = figure('Name','Max Abs Error Comparison','NumberTitle','off');
    plot(amps, results.maxAbsErrorBPSK, '-o', 'LineWidth', 1.5); hold on;
    plot(amps, results.maxAbsErrorBOC, '-s', 'LineWidth', 1.5);
    grid on;
    xlabel('Multipath Amplitude');
    ylabel('Max Abs Error');
    legend('BPSK', 'BOC');
    title('Max Abs Error Comparison');

    %% 返回句柄（关键）
    figHandles.bpskEnvelope = fig1;
    figHandles.bocEnvelope  = fig2;
    figHandles.maxAbsError  = fig3;
end