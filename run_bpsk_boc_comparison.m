function run_bpsk_boc_comparison()
%RUN_BPSK_BOC_COMPARISON 一键生成 BPSK 与 BOC 的核心对比图
%
%   生成内容：
%       1. 理想 S 曲线对比
%       2. 多径跟踪误差对比
%       3. 多径误差包络对比
%
%   运行方式：
%       run_bpsk_boc_comparison

    clc;
    close all;

    fprintf('========================================\n');
    fprintf('开始运行 BPSK vs BOC 对比实验\n');
    fprintf('========================================\n\n');

    %% 公共配置
    cfg = config_default();
    cfg.noise.enable = false;
    cfg.multipath.enable = false;
    cfg.tracking.interpMethod = 'linear';

    %% =========================
    % 1. 理想 S 曲线对比
    % =========================
    fprintf('【1】绘制理想 S 曲线对比...\n');

    cfg.signal.modType = 'BPSK';
    [Sb, xb] = utils.computeSCurve([], [], cfg);

    cfg.signal.modType = 'BOC';
    [Sc, xc] = utils.computeSCurve([], [], cfg);

    figure;
    plot(xb, Sb, 'LineWidth', 1.5);
    hold on;
    plot(xc, Sc, 'LineWidth', 1.5);
    grid on;
    yline(0, '--');
    xline(0, '--');
    legend('BPSK', 'BOC');
    xlabel('Code Offset (chips)');
    ylabel('Discriminator Output');
    title('BPSK vs BOC S-Curve');

    fprintf('完成：理想 S 曲线对比图已生成。\n\n');

    %% =========================
    % 2. 多径跟踪误差对比
    % =========================
    fprintf('【2】绘制多径跟踪误差对比...\n');

    cfg2 = config_default();
    cfg2.noise.enable = false;

    cfg2.signal.modType = 'BPSK';
    [d1, e1] = utils.computeMultipathError(cfg2);

    cfg2.signal.modType = 'BOC';
    [d2, e2] = utils.computeMultipathError(cfg2);

    figure;
    plot(d1, e1, 'LineWidth', 1.5);
    hold on;
    plot(d2, e2, 'LineWidth', 1.5);
    grid on;
    yline(0, '--');
    xline(0, '--');
    legend('BPSK', 'BOC');
    xlabel('Multipath Delay (chips)');
    ylabel('Tracking Error (chips)');
    title('BPSK vs BOC Multipath Tracking Error');

    fprintf('完成：多径跟踪误差对比图已生成。\n\n');

    %% =========================
    % 3. 多径误差包络对比
    % =========================
    fprintf('【3】绘制多径误差包络对比...\n');

    cfg3 = config_default();
    cfg3.noise.enable = false;

    cfg3.signal.modType = 'BPSK';
    [dB, upB, lowB] = utils.computeMultipathEnvelope(cfg3);

    cfg3.signal.modType = 'BOC';
    [dC, upC, lowC] = utils.computeMultipathEnvelope(cfg3);

    figure;
    plot(dB, upB, 'LineWidth', 1.5);
    hold on;
    plot(dB, lowB, 'LineWidth', 1.5);
    plot(dC, upC, 'LineWidth', 1.5);
    plot(dC, lowC, 'LineWidth', 1.5);
    grid on;
    yline(0, '--');
    xline(0, '--');
    legend('BPSK Upper', 'BPSK Lower', 'BOC Upper', 'BOC Lower');
    xlabel('Multipath Delay (chips)');
    ylabel('Tracking Error Envelope (chips)');
    title('BPSK vs BOC Multipath Error Envelope');

    fprintf('完成：多径误差包络对比图已生成。\n\n');

    fprintf('========================================\n');
    fprintf('BPSK vs BOC 对比实验运行完成！\n');
    fprintf('========================================\n');
end