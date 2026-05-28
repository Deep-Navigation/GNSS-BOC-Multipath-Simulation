function test_noise()
%TEST_NOISE 测试加噪模块
%   用于验证 core.addNoise() 的基本功能是否正常。
%
%   测试内容：
%       1. 默认调用是否正常
%       2. BPSK 加噪输出长度是否正确
%       3. 噪声长度与功率是否合理
%       4. 加噪结果是否与原始信号不同
%       5. 关闭噪声时是否直通
%       6. 复信号输入时是否正常
%
%   运行方式：
%       test_noise

    clc;
    fprintf('==============================\n');
    fprintf('开始测试 core.addNoise()\n');
    fprintf('==============================\n\n');

    %% 1. 默认调用测试
    fprintf('【测试1】默认调用测试...\n');
    [sig0, noise0, np0] = core.addNoise();

    assert(isvector(sig0), '默认调用输出 sig0 不是向量。');
    assert(isvector(noise0), '默认调用输出 noise0 不是向量。');
    assert(length(sig0) == length(noise0), ...
        '默认调用下 sig0 与 noise0 长度不一致。');
    assert(isscalar(np0), '默认调用输出 noisePower 不是标量。');
    assert(np0 >= 0, '默认调用输出 noisePower 不能为负。');

    fprintf('通过：默认调用正常。\n\n');

    %% 2. 构造测试信号
    cfg = config_default();
    prn = core.generatePRN(cfg);
    [sig_bpsk, ~] = core.bpskModulate(prn, cfg);

    expectedLen = round(cfg.time.fs * cfg.time.simDuration);

    %% 3. BPSK 加噪测试
    fprintf('【测试2】BPSK 加噪输出长度与功率测试...\n');
    [sig_noisy, noise, noisePower] = core.addNoise(sig_bpsk, cfg);

    assert(length(sig_noisy) == expectedLen, ...
        '加噪输出长度错误，应为 %d，实际为 %d。', expectedLen, length(sig_noisy));
    assert(length(noise) == expectedLen, ...
        '噪声长度错误，应为 %d，实际为 %d。', expectedLen, length(noise));
    assert(isscalar(noisePower), 'noisePower 必须为标量。');
    assert(noisePower > 0, '启用噪声时 noisePower 应大于 0。');

    fprintf('通过：加噪输出长度与噪声功率正确。\n\n');

    %% 4. 加噪结果差异测试
    fprintf('【测试3】加噪结果差异测试...\n');

    assert(~isequal(sig_noisy, sig_bpsk), ...
        '加噪后结果与原始信号完全相同，不符合预期。');

    diffCount = sum(abs(sig_noisy - sig_bpsk) > 1e-12);
    assert(diffCount > 0, '加噪后结果与原始信号没有有效差异。');

    fprintf('通过：加噪结果与原始信号存在差异。\n');
    fprintf('差异点数：%d\n\n', diffCount);

    %% 5. 关闭噪声直通测试
    fprintf('【测试4】关闭噪声直通测试...\n');

    cfg_no_noise = cfg;
    cfg_no_noise.noise.enable = false;

    [sig_direct, noise_direct, np_direct] = core.addNoise(sig_bpsk, cfg_no_noise);

    assert(isequal(sig_direct, sig_bpsk), ...
        '关闭噪声时，输出信号未保持与输入一致。');
    assert(all(noise_direct == 0), ...
        '关闭噪声时，noise 应为全零。');
    assert(np_direct == 0, ...
        '关闭噪声时，noisePower 应为 0。');

    fprintf('通过：关闭噪声时可正确直通输出。\n\n');

    %% 6. 复信号输入测试
    fprintf('【测试5】复信号输入测试...\n');

    cfg_complex = cfg;
    cfg_complex.carrier.type = 'complex';

    [sig_c, ~, ~] = core.addCarrier(sig_bpsk, cfg_complex);
    [sig_noisy_c, noise_c, np_c] = core.addNoise(sig_c, cfg_complex);

    assert(~isreal(sig_c), '复载波信号应为复信号。');
    assert(~isreal(sig_noisy_c), '复信号加噪后应保持复数形式。');
    assert(~isreal(noise_c), '复信号噪声应为复数形式。');
    assert(length(sig_noisy_c) == expectedLen, '复信号加噪输出长度错误。');
    assert(length(noise_c) == expectedLen, '复信号噪声长度错误。');
    assert(np_c > 0, '复信号加噪时 noisePower 应大于 0。');

    fprintf('通过：复信号输入时加噪正常。\n\n');

    %% 7. 结果预览
    fprintf('【结果预览】\n');
    fprintf('加噪输出长度: %d\n', length(sig_noisy));
    fprintf('噪声长度: %d\n', length(noise));
    fprintf('噪声功率: %.6f\n', noisePower);
    fprintf('原始信号与加噪结果差异点数: %d\n', diffCount);

    fprintf('\n==============================\n');
    fprintf('test_noise.m 全部测试通过！\n');
    fprintf('==============================\n');
end