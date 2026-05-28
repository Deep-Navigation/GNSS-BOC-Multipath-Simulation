function test_bpsk()
%TEST_BPSK 测试 BPSK 基带调制函数
%   用于验证 core.bpskModulate() 的基本功能是否正常。
%
%   测试内容：
%       1. 使用默认配置时能否正常生成信号
%       2. 输出信号与时间轴长度是否一致
%       3. 输出长度是否等于 round(fs * simDuration)
%       4. 信号取值是否为双极性矩形码片形式
%       5. 同一配置重复生成结果是否一致
%       6. 无输入参数调用是否正常
%
%   运行方式：
%       test_bpsk

    clc;
    fprintf('==============================\n');
    fprintf('开始测试 core.bpskModulate()\n');
    fprintf('==============================\n\n');

    %% 1. 默认配置
    cfg = config_default();

    %% 2. 先生成 PRN
    prn = core.generatePRN(cfg);

    %% 3. 测试正常调用
    fprintf('【测试1】正常输入下的 BPSK 生成测试...\n');
    [sig, t] = core.bpskModulate(prn, cfg);

    assert(isvector(sig), '输出信号 sig 不是向量。');
    assert(isvector(t), '输出时间轴 t 不是向量。');
    assert(length(sig) == length(t), 'sig 与 t 长度不一致。');

    expectedLen = round(cfg.time.fs * cfg.time.simDuration);
    assert(length(sig) == expectedLen, ...
        '输出信号长度不正确，应为 %d，实际为 %d。', expectedLen, length(sig));

    fprintf('通过：输出信号与时间轴长度正确。\n\n');

    %% 4. 测试信号取值是否合理
    fprintf('【测试2】信号取值范围测试...\n');

    uniqueVals = unique(sig);

    % 因为当前默认 normalize=true，BPSK 输出应只包含 -1 和 +1
    assert(all(ismember(uniqueVals, [-1, 1])), ...
        'BPSK 信号取值异常，当前应只包含 -1 和 +1。');

    fprintf('通过：信号取值范围正确。\n\n');

    %% 5. 测试重复生成一致性
    fprintf('【测试3】重复生成一致性测试...\n');

    [sig2, t2] = core.bpskModulate(prn, cfg);

    assert(isequal(sig, sig2), '同一配置下重复生成的信号不一致。');
    assert(isequal(t, t2), '同一配置下重复生成的时间轴不一致。');

    fprintf('通过：同一配置下重复生成结果一致。\n\n');

    %% 6. 测试无输入参数调用
    fprintf('【测试4】无输入参数默认调用测试...\n');

    [sig3, t3] = core.bpskModulate();

    assert(isvector(sig3), '默认调用输出 sig3 不是向量。');
    assert(isvector(t3), '默认调用输出 t3 不是向量。');
    assert(~isempty(sig3), '默认调用输出信号为空。');
    assert(length(sig3) == length(t3), '默认调用下 sig3 与 t3 长度不一致。');

    fprintf('通过：core.bpskModulate() 默认调用正常。\n\n');

    %% 7. 测试每码片采样点展开是否合理
    fprintf('【测试5】每码片采样点展开测试...\n');

    samplesPerChip = cfg.code.samplesPerChip;

    if length(sig) >= samplesPerChip
        firstChipSegment = sig(1:samplesPerChip);
        assert(all(firstChipSegment == firstChipSegment(1)), ...
            '第一个码片展开后，其采样点不一致，不符合矩形码片特征。');
    else
        error('test_bpsk:SignalTooShort', '信号长度小于每码片采样点数，测试无法进行。');
    end

    fprintf('通过：码片展开特性正确。\n\n');

    %% 8. 显示部分结果
    fprintf('【结果预览】\n');
    fprintf('信号长度: %d\n', length(sig));
    fprintf('时间轴长度: %d\n', length(t));
    fprintf('前20个采样点:\n');
    disp(sig(1:20));

    fprintf('==============================\n');
    fprintf('test_bpsk.m 全部测试通过！\n');
    fprintf('==============================\n');
end