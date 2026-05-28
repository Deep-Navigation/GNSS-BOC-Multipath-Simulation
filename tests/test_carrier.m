function test_carrier()
%TEST_CARRIER 测试载波调制模块
%   用于验证 core.addCarrier() 的基本功能是否正常。
%
%   测试内容：
%       1. 默认调用是否正常
%       2. BPSK 载波调制输出长度是否正确
%       3. BOC 载波调制输出长度是否正确
%       4. 调制公式是否成立
%       5. 载波序列长度是否正确
%       6. 复载波调制调用是否正常
%
%   运行方式：
%       test_carrier

    clc;
    fprintf('==============================\n');
    fprintf('开始测试 core.addCarrier()\n');
    fprintf('==============================\n\n');

    %% 1. 默认调用测试
    fprintf('【测试1】默认调用测试...\n');
    [sig0, t0, c0] = core.addCarrier();

    assert(isvector(sig0), '默认调用输出 sig0 不是向量。');
    assert(isvector(t0), '默认调用输出 t0 不是向量。');
    assert(isvector(c0), '默认调用输出 c0 不是向量。');
    assert(length(sig0) == length(t0), '默认调用下 sig0 与 t0 长度不一致。');
    assert(length(sig0) == length(c0), '默认调用下 sig0 与 c0 长度不一致。');

    fprintf('通过：默认调用正常。\n\n');

    %% 2. 构造测试信号
    cfg = config_default();
    prn = core.generatePRN(cfg);

    %% 3. BPSK 载波调制测试
    fprintf('【测试2】BPSK 载波调制测试...\n');
    [sig_bpsk, t_bpsk] = core.bpskModulate(prn, cfg);
    [sig_if_bpsk, t1, carrier1] = core.addCarrier(sig_bpsk, cfg);

    expectedLen = round(cfg.time.fs * cfg.time.simDuration);

    assert(length(sig_if_bpsk) == expectedLen, ...
        'BPSK 载波调制输出长度错误，应为 %d，实际为 %d。', expectedLen, length(sig_if_bpsk));
    assert(length(t1) == expectedLen, 'BPSK 时间轴长度错误。');
    assert(length(carrier1) == expectedLen, 'BPSK 载波长度错误。');

    % 验证公式
    fc  = cfg.carrier.freq;
    phi = cfg.carrier.phase;
    A   = cfg.carrier.amplitude;
    carrier_manual = A * cos(2*pi*fc*t_bpsk + phi);
    sig_manual = sig_bpsk .* carrier_manual;

    maxErr1 = max(abs(sig_if_bpsk - sig_manual));
    assert(maxErr1 < 1e-12, 'BPSK 载波调制公式验证失败，最大误差为 %.3e。', maxErr1);

    fprintf('通过：BPSK 载波调制长度与公式正确。\n\n');

    %% 4. BOC 载波调制测试
    fprintf('【测试3】BOC 载波调制测试...\n');
    [sig_boc, t_boc, ~] = core.bocModulate(prn, cfg);
    [sig_if_boc, t2, carrier2] = core.addCarrier(sig_boc, cfg);

    assert(length(sig_if_boc) == expectedLen, ...
        'BOC 载波调制输出长度错误，应为 %d，实际为 %d。', expectedLen, length(sig_if_boc));
    assert(length(t2) == expectedLen, 'BOC 时间轴长度错误。');
    assert(length(carrier2) == expectedLen, 'BOC 载波长度错误。');

    carrier_manual = A * cos(2*pi*fc*t_boc + phi);
    sig_manual = sig_boc .* carrier_manual;

    maxErr2 = max(abs(sig_if_boc - sig_manual));
    assert(maxErr2 < 1e-12, 'BOC 载波调制公式验证失败，最大误差为 %.3e。', maxErr2);

    fprintf('通过：BOC 载波调制长度与公式正确。\n\n');

    %% 5. 检查 BPSK 与 BOC 载波调制结果是否有差异
    fprintf('【测试4】BPSK 与 BOC 载波调制差异测试...\n');

    assert(~isequal(sig_if_bpsk, sig_if_boc), ...
        'BPSK 与 BOC 载波调制结果完全相同，不符合预期。');

    diffCount = sum(abs(sig_if_bpsk - sig_if_boc) > 1e-12);
    assert(diffCount > 0, 'BPSK 与 BOC 载波调制结果没有有效差异。');

    fprintf('通过：BPSK 与 BOC 载波调制结果存在差异。\n');
    fprintf('差异点数：%d\n\n', diffCount);

    %% 6. 复载波调制测试
    fprintf('【测试5】复载波调制调用测试...\n');

    cfg_complex = cfg;
    cfg_complex.carrier.type = 'complex';

    [sig_complex, t3, carrier3] = core.addCarrier(sig_bpsk, cfg_complex);

    assert(isvector(sig_complex), '复载波输出 sig_complex 不是向量。');
    assert(isvector(t3), '复载波输出 t3 不是向量。');
    assert(isvector(carrier3), '复载波输出 carrier3 不是向量。');
    assert(length(sig_complex) == expectedLen, '复载波调制输出长度错误。');
    assert(length(sig_complex) == length(t3), '复载波 sig 与 t 长度不一致。');
    assert(length(sig_complex) == length(carrier3), '复载波 sig 与 carrier 长度不一致。');
    assert(~isreal(sig_complex), '复载波调制输出应为复信号。');

    fprintf('通过：复载波调制调用正常。\n\n');

    %% 7. 结果预览
    fprintf('【结果预览】\n');
    fprintf('BPSK 载波调制长度: %d\n', length(sig_if_bpsk));
    fprintf('BOC  载波调制长度: %d\n', length(sig_if_boc));
    fprintf('BPSK 调制公式最大误差: %.3e\n', maxErr1);
    fprintf('BOC  调制公式最大误差: %.3e\n', maxErr2);

    fprintf('\n==============================\n');
    fprintf('test_carrier.m 全部测试通过！\n');
    fprintf('==============================\n');
end