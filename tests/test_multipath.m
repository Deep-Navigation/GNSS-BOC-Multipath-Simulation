function test_multipath()
%TEST_MULTIPATH 测试多径叠加模块
%   用于验证 core.addMultipath() 的基本功能是否正常。
%
%   测试内容：
%       1. 默认调用是否正常
%       2. BPSK 信号加多径后的输出长度是否正确
%       3. pathSignals 维度是否正确
%       4. 主路径与多径路径是否存在差异
%       5. 多径叠加结果是否与原始信号不同
%       6. 关闭多径时是否直通输出
%       7. 复信号输入时是否正常
%
%   运行方式：
%       test_multipath

    clc;
    fprintf('==============================\n');
    fprintf('开始测试 core.addMultipath()\n');
    fprintf('==============================\n\n');

    %% 1. 默认调用测试
    fprintf('【测试1】默认调用测试...\n');
    [sig0, t0, path0] = core.addMultipath();

    assert(isvector(sig0), '默认调用输出 sig0 不是向量。');
    assert(isvector(t0), '默认调用输出 t0 不是向量。');
    assert(~isempty(path0), '默认调用输出 pathSignals 为空。');
    assert(length(sig0) == length(t0), '默认调用下 sig0 与 t0 长度不一致。');
    assert(size(path0, 2) == length(sig0), '默认调用下 pathSignals 列数与 sig0 长度不一致。');

    fprintf('通过：默认调用正常。\n\n');

    %% 2. 构造测试信号
    cfg = config_default();
    prn = core.generatePRN(cfg);
    [sig_bpsk, ~] = core.bpskModulate(prn, cfg);

    expectedLen = round(cfg.time.fs * cfg.time.simDuration);
    expectedNumPaths = 1 + cfg.multipath.numPaths;

    %% 3. BPSK 多径输出长度与维度测试
    fprintf('【测试2】BPSK 多径输出长度与维度测试...\n');
    [sig_mp, t, pathSignals] = core.addMultipath(sig_bpsk, cfg);

    assert(length(sig_mp) == expectedLen, ...
        '多径输出长度错误，应为 %d，实际为 %d。', expectedLen, length(sig_mp));
    assert(length(t) == expectedLen, '时间轴长度错误。');
    assert(size(pathSignals, 1) == expectedNumPaths, ...
        'pathSignals 行数错误，应为 %d，实际为 %d。', expectedNumPaths, size(pathSignals,1));
    assert(size(pathSignals, 2) == expectedLen, ...
        'pathSignals 列数错误，应为 %d，实际为 %d。', expectedLen, size(pathSignals,2));

    fprintf('通过：多径输出长度与路径矩阵维度正确。\n\n');

    %% 4. 主路径与多径路径差异测试
    fprintf('【测试3】主路径与多径路径差异测试...\n');

    if cfg.multipath.numPaths > 0
        mainPath = pathSignals(1, :);
        extraPath = pathSignals(2, :);

        assert(~isequal(mainPath, extraPath), ...
            '主路径与第一条多径路径完全相同，不符合预期。');

        diffCount = sum(abs(mainPath - extraPath) > 1e-12);
        assert(diffCount > 0, ...
            '主路径与第一条多径路径没有有效差异。');

        fprintf('通过：主路径与多径路径存在差异。\n');
        fprintf('差异点数：%d\n\n', diffCount);
    else
        fprintf('跳过：当前 cfg.multipath.numPaths = 0，无附加多径路径。\n\n');
    end

    %% 5. 多径叠加结果是否与原始信号不同
    fprintf('【测试4】多径叠加结果差异测试...\n');

    assert(~isequal(sig_mp, sig_bpsk), ...
        '多径叠加结果与原始信号完全相同，不符合预期。');

    diffCount2 = sum(abs(sig_mp - sig_bpsk) > 1e-12);
    assert(diffCount2 > 0, '多径叠加结果与原始信号没有有效差异。');

    fprintf('通过：多径叠加结果与原始信号存在差异。\n');
    fprintf('差异点数：%d\n\n', diffCount2);

    %% 6. 关闭多径时直通测试
    fprintf('【测试5】关闭多径直通测试...\n');

    cfg_no_mp = cfg;
    cfg_no_mp.multipath.enable = false;

    [sig_direct, t_direct, path_direct] = core.addMultipath(sig_bpsk, cfg_no_mp);

    assert(isequal(sig_direct, sig_bpsk), ...
        '关闭多径时，输出信号未保持与输入一致。');
    assert(length(t_direct) == expectedLen, '关闭多径时时间轴长度错误。');
    assert(isvector(path_direct), '关闭多径时 pathSignals 应退化为单路径向量。');

    fprintf('通过：关闭多径时可正确直通输出。\n\n');

    %% 7. 复信号输入测试
    fprintf('【测试6】复信号输入测试...\n');

    cfg_complex = cfg;
    cfg_complex.carrier.type = 'complex';

    [sig_complex, ~, ~] = core.addCarrier(sig_bpsk, cfg_complex);
    [sig_complex_mp, t_complex, path_complex] = core.addMultipath(sig_complex, cfg_complex);

    assert(~isreal(sig_complex), '复载波信号应为复信号。');
    assert(~isreal(sig_complex_mp), '复信号加多径后应保持复数形式。');
    assert(length(sig_complex_mp) == expectedLen, '复信号多径输出长度错误。');
    assert(length(t_complex) == expectedLen, '复信号多径时间轴长度错误。');
    assert(size(path_complex, 1) == expectedNumPaths, '复信号 pathSignals 行数错误。');
    assert(size(path_complex, 2) == expectedLen, '复信号 pathSignals 列数错误。');

    fprintf('通过：复信号输入时多径处理正常。\n\n');

    %% 8. 结果预览
    fprintf('【结果预览】\n');
    fprintf('多径输出长度: %d\n', length(sig_mp));
    fprintf('路径分量矩阵大小: %d x %d\n', size(pathSignals,1), size(pathSignals,2));
    fprintf('原始信号与多径叠加结果差异点数: %d\n', diffCount2);

    fprintf('\n==============================\n');
    fprintf('test_multipath.m 全部测试通过！\n');
    fprintf('==============================\n');
end