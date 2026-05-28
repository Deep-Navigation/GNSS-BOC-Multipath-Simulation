function test_prn()
%TEST_PRN 测试 PRN 伪码生成函数
%   用于验证 core.generatePRN() 的基本功能是否正常。
%
%   测试内容：
%       1. 是否能正常生成伪码
%       2. 伪码长度是否正确
%       3. bipolar 输出是否只包含 -1 和 +1
%       4. binary 输出是否只包含 0 和 1
%       5. 同一配置重复生成是否一致
%
%   运行方式：
%       test_prn
%   或
%       tests.test_prn   % 如果你后续把 tests 也做成 package 再这样用

    clc;
    fprintf('==============================\n');
    fprintf('开始测试 core.generatePRN()\n');
    fprintf('==============================\n\n');

    %% 1. 读取默认配置
    cfg = config_default();

    %% 2. 测试 bipolar 输出
    fprintf('【测试1】bipolar 输出测试...\n');
    cfg.prn.outputFormat = 'bipolar';

    prn1 = core.generatePRN(cfg);

    assert(isvector(prn1), 'PRN 输出不是向量。');
    assert(length(prn1) == cfg.prn.codeLength, 'PRN 长度不正确。');

    uniqueVals1 = unique(prn1);
    assert(all(ismember(uniqueVals1, [-1, 1])), ...
        'bipolar 输出不只包含 -1 和 +1。');

    fprintf('通过：bipolar 输出长度和取值范围正确。\n\n');

    %% 3. 测试 binary 输出
    fprintf('【测试2】binary 输出测试...\n');
    cfg.prn.outputFormat = 'binary';

    prn2 = core.generatePRN(cfg);

    assert(isvector(prn2), 'PRN 输出不是向量。');
    assert(length(prn2) == cfg.prn.codeLength, 'PRN 长度不正确。');

    uniqueVals2 = unique(prn2);
    assert(all(ismember(uniqueVals2, [0, 1])), ...
        'binary 输出不只包含 0 和 1。');

    fprintf('通过：binary 输出长度和取值范围正确。\n\n');

    %% 4. 测试重复生成一致性
    fprintf('【测试3】重复生成一致性测试...\n');
    cfg.prn.outputFormat = 'bipolar';

    prn3 = core.generatePRN(cfg);
    prn4 = core.generatePRN(cfg);

    assert(isequal(prn3, prn4), '同一配置下重复生成结果不一致。');

    fprintf('通过：同一配置下重复生成结果一致。\n\n');

    %% 5. 测试默认调用方式
    fprintf('【测试4】无输入参数默认调用测试...\n');
    prn5 = core.generatePRN();

    assert(isvector(prn5), '默认调用输出不是向量。');
    assert(~isempty(prn5), '默认调用输出为空。');

    fprintf('通过：core.generatePRN() 默认调用正常。\n\n');

    %% 6. 显示部分结果
    fprintf('【结果预览】前20个码元如下：\n');
    disp(prn3(1:20));

    fprintf('==============================\n');
    fprintf('test_prn.m 全部测试通过！\n');
    fprintf('==============================\n');
end