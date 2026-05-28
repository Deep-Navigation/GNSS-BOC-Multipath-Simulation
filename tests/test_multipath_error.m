function test_multipath_error()
%TEST_MULTIPATH_ERROR 测试多径误差计算模块
%   用于验证 utils.computeMultipathError() 的基本功能是否正常。
%
%   测试内容：
%       1. 默认调用是否正常
%       2. BPSK 多径误差输出长度是否正确
%       3. BOC 多径误差输出长度是否正确
%       4. 小延迟处误差是否接近 0
%       5. BPSK 与 BOC 多径误差结果是否存在差异
%
%   运行方式：
%       test_multipath_error

    clc;
    fprintf('==============================\n');
    fprintf('开始测试 utils.computeMultipathError()\n');
    fprintf('==============================\n\n');

    %% 1. 默认调用测试
    fprintf('【测试1】默认调用测试...\n');
    [d0, e0, z0] = utils.computeMultipathError();

    assert(isvector(d0), '默认调用输出 delayChips 不是向量。');
    assert(isvector(e0), '默认调用输出 trackingErrorChips 不是向量。');
    assert(isvector(z0), '默认调用输出 zeroCrossings 不是向量。');

    assert(length(d0) == length(e0), '默认调用下 delayChips 与 trackingErrorChips 长度不一致。');
    assert(length(d0) == length(z0), '默认调用下 delayChips 与 zeroCrossings 长度不一致。');

    fprintf('通过：默认调用正常。\n\n');

    %% 公共参数
    expectedLen = 101;   % 默认 numDelayPoints

    %% 2. BPSK 多径误差测试
    fprintf('【测试2】BPSK 多径误差测试...\n');

    cfg_bpsk = config_default();
    cfg_bpsk.signal.modType = 'BPSK';
    cfg_bpsk.noise.enable = false;

    [delayB, errB, zcB] = utils.computeMultipathError(cfg_bpsk);

    assert(length(delayB) == expectedLen, ...
        'BPSK delayChips 长度错误，应为 %d，实际为 %d。', expectedLen, length(delayB));
    assert(length(errB) == expectedLen, ...
        'BPSK trackingErrorChips 长度错误，应为 %d，实际为 %d。', expectedLen, length(errB));
    assert(length(zcB) == expectedLen, ...
        'BPSK zeroCrossings 长度错误，应为 %d，实际为 %d。', expectedLen, length(zcB));

    fprintf('通过：BPSK 多径误差输出长度正确。\n\n');

    %% 3. BOC 多径误差测试
    fprintf('【测试3】BOC 多径误差测试...\n');

    cfg_boc = config_default();
    cfg_boc.signal.modType = 'BOC';
    cfg_boc.noise.enable = false;

    [delayC, errC, zcC] = utils.computeMultipathError(cfg_boc);

    assert(length(delayC) == expectedLen, ...
        'BOC delayChips 长度错误，应为 %d，实际为 %d。', expectedLen, length(delayC));
    assert(length(errC) == expectedLen, ...
        'BOC trackingErrorChips 长度错误，应为 %d，实际为 %d。', expectedLen, length(errC));
    assert(length(zcC) == expectedLen, ...
        'BOC zeroCrossings 长度错误，应为 %d，实际为 %d。', expectedLen, length(zcC));

    fprintf('通过：BOC 多径误差输出长度正确。\n\n');

    %% 4. 小延迟处误差检查
    fprintf('【测试4】小延迟处误差检查...\n');

    assert(abs(errB(1)) < 1e-12, ...
        'BPSK 在 0 延迟处误差应接近 0，实际为 %.3e。', errB(1));
    assert(abs(errC(1)) < 1e-12, ...
        'BOC 在 0 延迟处误差应接近 0，实际为 %.3e。', errC(1));

    fprintf('通过：0 延迟处误差接近 0。\n\n');

    %% 5. BPSK 与 BOC 差异测试
    fprintf('【测试5】BPSK 与 BOC 多径误差差异测试...\n');

    assert(~isequal(errB, errC), ...
        'BPSK 与 BOC 多径误差结果完全相同，不符合预期。');

    diffCount = sum(abs(errB - errC) > 1e-12);
    assert(diffCount > 0, ...
        'BPSK 与 BOC 多径误差结果没有有效差异。');

    fprintf('通过：BPSK 与 BOC 多径误差结果存在差异。\n');
    fprintf('差异点数：%d\n\n', diffCount);

    %% 6. 有限值检查
    fprintf('【测试6】有限值检查...\n');

    assert(all(isfinite(delayB)), 'BPSK delayChips 中存在非有限值。');
    assert(all(isfinite(delayC)), 'BOC delayChips 中存在非有限值。');
    assert(all(isfinite(errB)), 'BPSK trackingErrorChips 中存在非有限值。');
    assert(all(isfinite(errC)), 'BOC trackingErrorChips 中存在非有限值。');

    fprintf('通过：输出均为有限值。\n\n');

    %% 7. 结果预览
    fprintf('【结果预览】\n');
    fprintf('BPSK 输出长度: %d\n', length(errB));
    fprintf('BOC  输出长度: %d\n', length(errC));
    fprintf('BPSK 与 BOC 差异点数: %d\n', diffCount);
    fprintf('BPSK 最大绝对误差: %.6f chips\n', max(abs(errB)));
    fprintf('BOC  最大绝对误差: %.6f chips\n', max(abs(errC)));

    fprintf('\n==============================\n');
    fprintf('test_multipath_error.m 全部测试通过！\n');
    fprintf('==============================\n');
end