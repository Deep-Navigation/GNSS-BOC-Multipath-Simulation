function test_correlation()
%TEST_CORRELATION 测试相关函数计算模块
%   用于验证 utils.computeCorrelation() 的基本功能是否正常。
%
%   测试内容：
%       1. 默认调用是否正常
%       2. BPSK 自相关输出长度是否正确
%       3. BOC 自相关输出长度是否正确
%       4. 自相关零延迟位置是否存在主峰
%       5. 归一化后零延迟主峰是否接近 1
%       6. BPSK 与 BOC 自相关结果是否存在差异
%       7. 互相关调用方式是否正常
%
%   运行方式：
%       test_correlation

    clc;
    fprintf('==============================\n');
    fprintf('开始测试 utils.computeCorrelation()\n');
    fprintf('==============================\n\n');

    %% 1. 默认调用测试
    fprintf('【测试1】默认调用测试...\n');
    [R0, lags0, lagTime0] = utils.computeCorrelation();

    assert(isvector(R0), '默认调用输出 R0 不是向量。');
    assert(isvector(lags0), '默认调用输出 lags0 不是向量。');
    assert(isvector(lagTime0), '默认调用输出 lagTime0 不是向量。');
    assert(length(R0) == length(lags0), '默认调用下 R0 与 lags0 长度不一致。');
    assert(length(R0) == length(lagTime0), '默认调用下 R0 与 lagTime0 长度不一致。');

    fprintf('通过：默认调用正常。\n\n');

    %% 2. 构造测试信号
    cfg = config_default();
    prn = core.generatePRN(cfg);

    [sig_bpsk, ~] = core.bpskModulate(prn, cfg);
    [sig_boc,  ~, ~] = core.bocModulate(prn, cfg);

    expectedLen = 2 * cfg.corr.maxLagSamples + 1;

    %% 3. BPSK 自相关测试
    fprintf('【测试2】BPSK 自相关长度与主峰测试...\n');
    [Rb, lagsb, lagTimeb] = utils.computeCorrelation(sig_bpsk, [], cfg);

    assert(length(Rb) == expectedLen, ...
        'BPSK 自相关输出长度不正确，应为 %d，实际为 %d。', expectedLen, length(Rb));
    assert(length(lagsb) == expectedLen, 'BPSK lags 长度不正确。');
    assert(length(lagTimeb) == expectedLen, 'BPSK lagTime 长度不正确。');

    zeroIdxB = find(lagsb == 0, 1);
    assert(~isempty(zeroIdxB), 'BPSK 自相关中未找到零延迟位置。');

    % 归一化后零延迟主峰应接近 1
    assert(abs(Rb(zeroIdxB) - 1) < 1e-10, ...
        'BPSK 自相关零延迟主峰不接近 1。');

    fprintf('通过：BPSK 自相关长度与零延迟主峰正确。\n\n');

    %% 4. BOC 自相关测试
    fprintf('【测试3】BOC 自相关长度与主峰测试...\n');
    [Rc, lagsc, lagTimec] = utils.computeCorrelation(sig_boc, [], cfg);

    assert(length(Rc) == expectedLen, ...
        'BOC 自相关输出长度不正确，应为 %d，实际为 %d。', expectedLen, length(Rc));
    assert(length(lagsc) == expectedLen, 'BOC lags 长度不正确。');
    assert(length(lagTimec) == expectedLen, 'BOC lagTime 长度不正确。');

    zeroIdxC = find(lagsc == 0, 1);
    assert(~isempty(zeroIdxC), 'BOC 自相关中未找到零延迟位置。');

    assert(abs(Rc(zeroIdxC) - 1) < 1e-10, ...
        'BOC 自相关零延迟主峰不接近 1。');

    fprintf('通过：BOC 自相关长度与零延迟主峰正确。\n\n');

    %% 5. 检查零延迟主峰是否为最大值之一
    fprintf('【测试4】零延迟主峰位置合理性测试...\n');

    maxRb = max(Rb);
    maxRc = max(Rc);

    assert(abs(Rb(zeroIdxB) - maxRb) < 1e-10, ...
        'BPSK 自相关零延迟不是最大峰值。');
    assert(abs(Rc(zeroIdxC) - maxRc) < 1e-10, ...
        'BOC 自相关零延迟不是最大峰值。');

    fprintf('通过：零延迟处为主峰。\n\n');

    %% 6. 检查 BPSK 与 BOC 是否存在差异
    fprintf('【测试5】BPSK 与 BOC 自相关差异测试...\n');

    assert(~isequal(Rb, Rc), 'BPSK 与 BOC 自相关结果完全相同，不符合预期。');

    diffCount = sum(abs(Rb - Rc) > 1e-12);
    assert(diffCount > 0, 'BPSK 与 BOC 自相关结果没有有效差异。');

    fprintf('通过：BPSK 与 BOC 自相关结果存在差异。\n');
    fprintf('差异点数：%d\n\n', diffCount);

    %% 7. 互相关调用测试
    fprintf('【测试6】互相关调用测试...\n');
    [Rxy, lagsxy, lagTimexy] = utils.computeCorrelation(sig_bpsk, sig_boc, cfg);

    assert(isvector(Rxy), '互相关输出 Rxy 不是向量。');
    assert(isvector(lagsxy), '互相关输出 lagsxy 不是向量。');
    assert(isvector(lagTimexy), '互相关输出 lagTimexy 不是向量。');
    assert(length(Rxy) == expectedLen, '互相关输出长度不正确。');
    assert(length(Rxy) == length(lagsxy), '互相关中 Rxy 与 lagsxy 长度不一致。');
    assert(length(Rxy) == length(lagTimexy), '互相关中 Rxy 与 lagTimexy 长度不一致。');

    fprintf('通过：互相关调用正常。\n\n');

    %% 8. 结果预览
    fprintf('【结果预览】\n');
    fprintf('BPSK 自相关长度: %d\n', length(Rb));
    fprintf('BOC  自相关长度: %d\n', length(Rc));
    fprintf('互相关长度: %d\n', length(Rxy));
    fprintf('BPSK 零延迟主峰值: %.6f\n', Rb(zeroIdxB));
    fprintf('BOC  零延迟主峰值: %.6f\n', Rc(zeroIdxC));

    fprintf('\n==============================\n');
    fprintf('test_correlation.m 全部测试通过！\n');
    fprintf('==============================\n');
end