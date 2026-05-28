function test_scurve()
%TEST_SCURVE 测试 S 曲线计算模块
%   用于验证 utils.computeSCurve() 的基本功能是否正常。
%
%   测试内容：
%       1. 默认调用是否正常
%       2. BPSK 理想 S 曲线长度与零点性质是否正确
%       3. BPSK 理想 S 曲线是否满足近似奇对称
%       4. BOC 理想 S 曲线长度与零点性质是否正确
%       5. BOC 理想 S 曲线是否满足近似奇对称
%       6. 多径存在时 S 曲线是否发生变化
%
%   运行方式：
%       test_scurve

    clc;
    fprintf('==============================\n');
    fprintf('开始测试 utils.computeSCurve()\n');
    fprintf('==============================\n\n');

    %% 1. 默认调用测试
    fprintf('【测试1】默认调用测试...\n');
    [S0, x0, E0, L0, P0] = utils.computeSCurve();

    assert(isvector(S0), '默认调用输出 S0 不是向量。');
    assert(isvector(x0), '默认调用输出 x0 不是向量。');
    assert(isvector(E0), '默认调用输出 E0 不是向量。');
    assert(isvector(L0), '默认调用输出 L0 不是向量。');
    assert(isvector(P0), '默认调用输出 P0 不是向量。');

    assert(length(S0) == length(x0), '默认调用下 S0 与 x0 长度不一致。');
    assert(length(S0) == length(E0), '默认调用下 S0 与 E0 长度不一致。');
    assert(length(S0) == length(L0), '默认调用下 S0 与 L0 长度不一致。');
    assert(length(S0) == length(P0), '默认调用下 S0 与 P0 长度不一致。');

    fprintf('通过：默认调用正常。\n\n');

    %% 公共参数
    expectedLen = 201;      % 默认 numOffsetPoints
    zeroTol = 1e-12;        % 零点容差
    symTol = 1e-10;         % 奇对称容差

    %% 2. BPSK 理想 S 曲线测试
    fprintf('【测试2】BPSK 理想 S 曲线测试...\n');

    cfg_bpsk = config_default();
    cfg_bpsk.signal.modType = 'BPSK';
    cfg_bpsk.multipath.enable = false;
    cfg_bpsk.noise.enable = false;
    cfg_bpsk.tracking.interpMethod = 'linear';

    [Sb, xb, Eb, Lb, Pb] = utils.computeSCurve([], [], cfg_bpsk);

    assert(length(Sb) == expectedLen, ...
        'BPSK S 曲线长度错误，应为 %d，实际为 %d。', expectedLen, length(Sb));
    assert(length(xb) == expectedLen, 'BPSK 偏移轴长度错误。');
    assert(length(Eb) == expectedLen, 'BPSK Early 输出长度错误。');
    assert(length(Lb) == expectedLen, 'BPSK Late 输出长度错误。');
    assert(length(Pb) == expectedLen, 'BPSK Prompt 输出长度错误。');

    % 检查 0 点附近
    [~, idx0_b] = min(abs(xb));
    assert(abs(xb(idx0_b)) < 1e-12, 'BPSK 偏移轴中心点不在 0 附近。');
    assert(abs(Sb(idx0_b)) < zeroTol, ...
        'BPSK 理想 S 曲线在 0 附近应接近 0，实际为 %.3e。', Sb(idx0_b));

    fprintf('通过：BPSK 理想 S 曲线长度与零点性质正确。\n\n');

    %% 3. BPSK 奇对称测试
    fprintf('【测试3】BPSK 奇对称测试...\n');

    symErrB = max(abs(Sb + fliplr(Sb)));
    assert(symErrB < symTol, ...
        'BPSK 理想 S 曲线不满足近似奇对称，误差为 %.3e。', symErrB);

    fprintf('通过：BPSK 理想 S 曲线满足近似奇对称。\n');
    fprintf('奇对称误差：%.3e\n\n', symErrB);

    %% 4. BOC 理想 S 曲线测试
    fprintf('【测试4】BOC 理想 S 曲线测试...\n');

    cfg_boc = config_default();
    cfg_boc.signal.modType = 'BOC';
    cfg_boc.multipath.enable = false;
    cfg_boc.noise.enable = false;
    cfg_boc.tracking.interpMethod = 'linear';

    [Sc, xc, Ec, Lc, Pc] = utils.computeSCurve([], [], cfg_boc);

    assert(length(Sc) == expectedLen, ...
        'BOC S 曲线长度错误，应为 %d，实际为 %d。', expectedLen, length(Sc));
    assert(length(xc) == expectedLen, 'BOC 偏移轴长度错误。');
    assert(length(Ec) == expectedLen, 'BOC Early 输出长度错误。');
    assert(length(Lc) == expectedLen, 'BOC Late 输出长度错误。');
    assert(length(Pc) == expectedLen, 'BOC Prompt 输出长度错误。');

    [~, idx0_c] = min(abs(xc));
    assert(abs(xc(idx0_c)) < 1e-12, 'BOC 偏移轴中心点不在 0 附近。');
    assert(abs(Sc(idx0_c)) < zeroTol, ...
        'BOC 理想 S 曲线在 0 附近应接近 0，实际为 %.3e。', Sc(idx0_c));

    fprintf('通过：BOC 理想 S 曲线长度与零点性质正确。\n\n');

    %% 5. BOC 奇对称测试
    fprintf('【测试5】BOC 奇对称测试...\n');

    symErrC = max(abs(Sc + fliplr(Sc)));
    assert(symErrC < symTol, ...
        'BOC 理想 S 曲线不满足近似奇对称，误差为 %.3e。', symErrC);

    fprintf('通过：BOC 理想 S 曲线满足近似奇对称。\n');
    fprintf('奇对称误差：%.3e\n\n', symErrC);

    %% 6. 多径影响测试
    fprintf('【测试6】多径影响测试...\n');

    cfg_mp = config_default();
    cfg_mp.signal.modType = 'BPSK';
    cfg_mp.noise.enable = false;
    cfg_mp.multipath.enable = true;
    cfg_mp.tracking.interpMethod = 'linear';

    [S_mp, x_mp] = utils.computeSCurve([], [], cfg_mp);

    assert(length(S_mp) == expectedLen, '多径条件下 S 曲线长度错误。');
    assert(length(x_mp) == expectedLen, '多径条件下偏移轴长度错误。');

    diffCount = sum(abs(S_mp - Sb) > 1e-10);
    assert(diffCount > 0, '加入多径后，S 曲线与理想 BPSK 曲线没有有效差异。');

    fprintf('通过：加入多径后 S 曲线发生变化。\n');
    fprintf('差异点数：%d\n\n', diffCount);

    %% 7. 结果预览
    fprintf('【结果预览】\n');
    fprintf('BPSK 奇对称误差: %.3e\n', symErrB);
    fprintf('BOC  奇对称误差: %.3e\n', symErrC);
    fprintf('多径与理想 BPSK 曲线差异点数: %d\n', diffCount);

    fprintf('\n==============================\n');
    fprintf('test_scurve.m 全部测试通过！\n');
    fprintf('==============================\n');
end