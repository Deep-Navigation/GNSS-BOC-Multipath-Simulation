function test_multipath_envelope()
%TEST_MULTIPATH_ENVELOPE 测试多径误差包络计算模块
%   用于验证 utils.computeMultipathEnvelope() 的基本功能是否正常。
%
%   测试内容：
%       1. 默认调用是否正常
%       2. BPSK 多径误差包络输出维度是否正确
%       3. BOC 多径误差包络输出维度是否正确
%       4. 上下包络关系是否正确
%       5. 0 延迟处包络是否接近 0
%       6. BPSK 与 BOC 包络结果是否存在差异
%       7. 输出是否均为有限值
%
%   运行方式：
%       test_multipath_envelope

    clc;
    fprintf('========================================\n');
    fprintf('开始测试 utils.computeMultipathEnvelope()\n');
    fprintf('========================================\n\n');

    %% 1. 默认调用测试
    fprintf('【测试1】默认调用测试...\n');
    [d0, up0, low0, ph0, emat0] = utils.computeMultipathEnvelope();

    assert(isvector(d0), '默认调用输出 delayChips 不是向量。');
    assert(isvector(up0), '默认调用输出 upperEnvelope 不是向量。');
    assert(isvector(low0), '默认调用输出 lowerEnvelope 不是向量。');
    assert(isvector(ph0), '默认调用输出 phaseGrid 不是向量。');
    assert(ismatrix(emat0), '默认调用输出 errorMatrix 不是矩阵。');

    assert(length(d0) == length(up0), ...
        '默认调用下 delayChips 与 upperEnvelope 长度不一致。');
    assert(length(d0) == length(low0), ...
        '默认调用下 delayChips 与 lowerEnvelope 长度不一致。');
    assert(size(emat0, 1) == length(ph0), ...
        '默认调用下 errorMatrix 行数与 phaseGrid 长度不一致。');
    assert(size(emat0, 2) == length(d0), ...
        '默认调用下 errorMatrix 列数与 delayChips 长度不一致。');

    fprintf('通过：默认调用正常。\n\n');

    %% 公共参数
    expectedDelayLen = 101;   % 默认 numDelayPoints
    expectedPhaseLen = 73;    % 默认 numPhasePoints

    %% 2. BPSK 多径误差包络测试
    fprintf('【测试2】BPSK 多径误差包络测试...\n');

    cfg_bpsk = config_default();
    cfg_bpsk.signal.modType = 'BPSK';
    cfg_bpsk.noise.enable = false;

    [delayB, upB, lowB, phB, ematB] = utils.computeMultipathEnvelope(cfg_bpsk);

    assert(length(delayB) == expectedDelayLen, ...
        'BPSK delayChips 长度错误，应为 %d，实际为 %d。', ...
        expectedDelayLen, length(delayB));
    assert(length(upB) == expectedDelayLen, ...
        'BPSK upperEnvelope 长度错误，应为 %d，实际为 %d。', ...
        expectedDelayLen, length(upB));
    assert(length(lowB) == expectedDelayLen, ...
        'BPSK lowerEnvelope 长度错误，应为 %d，实际为 %d。', ...
        expectedDelayLen, length(lowB));
    assert(length(phB) == expectedPhaseLen, ...
        'BPSK phaseGrid 长度错误，应为 %d，实际为 %d。', ...
        expectedPhaseLen, length(phB));
    assert(all(size(ematB) == [expectedPhaseLen, expectedDelayLen]), ...
        'BPSK errorMatrix 尺寸错误，应为 %d x %d，实际为 %d x %d。', ...
        expectedPhaseLen, expectedDelayLen, size(ematB,1), size(ematB,2));

    fprintf('通过：BPSK 多径误差包络输出维度正确。\n\n');

    %% 3. BOC 多径误差包络测试
    fprintf('【测试3】BOC 多径误差包络测试...\n');

    cfg_boc = config_default();
    cfg_boc.signal.modType = 'BOC';
    cfg_boc.noise.enable = false;

    [delayC, upC, lowC, phC, ematC] = utils.computeMultipathEnvelope(cfg_boc);

    assert(length(delayC) == expectedDelayLen, ...
        'BOC delayChips 长度错误，应为 %d，实际为 %d。', ...
        expectedDelayLen, length(delayC));
    assert(length(upC) == expectedDelayLen, ...
        'BOC upperEnvelope 长度错误，应为 %d，实际为 %d。', ...
        expectedDelayLen, length(upC));
    assert(length(lowC) == expectedDelayLen, ...
        'BOC lowerEnvelope 长度错误，应为 %d，实际为 %d。', ...
        expectedDelayLen, length(lowC));
    assert(length(phC) == expectedPhaseLen, ...
        'BOC phaseGrid 长度错误，应为 %d，实际为 %d。', ...
        expectedPhaseLen, length(phC));
    assert(all(size(ematC) == [expectedPhaseLen, expectedDelayLen]), ...
        'BOC errorMatrix 尺寸错误，应为 %d x %d，实际为 %d x %d。', ...
        expectedPhaseLen, expectedDelayLen, size(ematC,1), size(ematC,2));

    fprintf('通过：BOC 多径误差包络输出维度正确。\n\n');

    %% 4. 上下包络关系测试
    fprintf('【测试4】上下包络关系测试...\n');

    assert(all(upB >= lowB), 'BPSK 上包络存在小于下包络的点。');
    assert(all(upC >= lowC), 'BOC 上包络存在小于下包络的点。');

    fprintf('通过：上下包络关系正确。\n\n');

    %% 5. 0 延迟处包络检查
    fprintf('【测试5】0 延迟处包络检查...\n');

    assert(abs(upB(1)) < 1e-12, ...
        'BPSK 在 0 延迟处上包络应接近 0，实际为 %.3e。', upB(1));
    assert(abs(lowB(1)) < 1e-12, ...
        'BPSK 在 0 延迟处下包络应接近 0，实际为 %.3e。', lowB(1));

    assert(abs(upC(1)) < 1e-12, ...
        'BOC 在 0 延迟处上包络应接近 0，实际为 %.3e。', upC(1));
    assert(abs(lowC(1)) < 1e-12, ...
        'BOC 在 0 延迟处下包络应接近 0，实际为 %.3e。', lowC(1));

    fprintf('通过：0 延迟处包络接近 0。\n\n');

    %% 6. BPSK 与 BOC 包络差异测试
    fprintf('【测试6】BPSK 与 BOC 包络差异测试...\n');

    diffCountUpper = sum(abs(upB - upC) > 1e-12);
    diffCountLower = sum(abs(lowB - lowC) > 1e-12);

    assert(diffCountUpper > 0 || diffCountLower > 0, ...
        'BPSK 与 BOC 的包络结果没有有效差异。');

    fprintf('通过：BPSK 与 BOC 包络结果存在差异。\n');
    fprintf('上包络差异点数：%d\n', diffCountUpper);
    fprintf('下包络差异点数：%d\n\n', diffCountLower);

    %% 7. 有限值检查
    fprintf('【测试7】有限值检查...\n');

    assert(all(isfinite(delayB)), 'BPSK delayChips 中存在非有限值。');
    assert(all(isfinite(upB)), 'BPSK upperEnvelope 中存在非有限值。');
    assert(all(isfinite(lowB)), 'BPSK lowerEnvelope 中存在非有限值。');
    assert(all(isfinite(phB)), 'BPSK phaseGrid 中存在非有限值。');
    assert(all(isfinite(ematB(:))), 'BPSK errorMatrix 中存在非有限值。');

    assert(all(isfinite(delayC)), 'BOC delayChips 中存在非有限值。');
    assert(all(isfinite(upC)), 'BOC upperEnvelope 中存在非有限值。');
    assert(all(isfinite(lowC)), 'BOC lowerEnvelope 中存在非有限值。');
    assert(all(isfinite(phC)), 'BOC phaseGrid 中存在非有限值。');
    assert(all(isfinite(ematC(:))), 'BOC errorMatrix 中存在非有限值。');

    fprintf('通过：输出均为有限值。\n\n');

    %% 8. 结果预览
    fprintf('【结果预览】\n');
    fprintf('BPSK 包络长度: %d\n', length(upB));
    fprintf('BOC  包络长度: %d\n', length(upC));
    fprintf('BPSK 相位点数: %d\n', length(phB));
    fprintf('BOC  相位点数: %d\n', length(phC));
    fprintf('上包络差异点数: %d\n', diffCountUpper);
    fprintf('下包络差异点数: %d\n', diffCountLower);
    fprintf('BPSK 最大上包络: %.6f chips\n', max(upB));
    fprintf('BPSK 最小下包络: %.6f chips\n', min(lowB));
    fprintf('BOC  最大上包络: %.6f chips\n', max(upC));
    fprintf('BOC  最小下包络: %.6f chips\n', min(lowC));

    fprintf('\n========================================\n');
    fprintf('test_multipath_envelope.m 全部测试通过！\n');
    fprintf('========================================\n');
end