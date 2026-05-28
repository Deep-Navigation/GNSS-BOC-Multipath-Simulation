function cfg = config_default()
%CONFIG_DEFAULT 默认参数配置文件
%   用于 GNSS_Simulator 的统一参数管理。
%
%   设计原则：
%       1. 保持当前已验证链路不被破坏
%       2. 固定项目根目录，不再依赖 pwd
%       3. 明确核心参数真源，便于后续 GUI 接入
%       4. 保持与现有脚本尽量兼容，不做激进重构
%
%   输出:
%       cfg - 配置结构体，包含信号生成、调制、信道、多径、噪声、
%             分析、绘图与结果路径等默认参数

    %% =========================
    %  1. 基本工程信息
    %  =========================
    cfg.project.name        = 'GNSS_Simulator';
    cfg.project.author      = 'Nathan';
    cfg.project.version     = '1.1';
    cfg.project.description = '基于BOC调制的GNSS信号多路径效应抑制方法及仿真分析平台默认配置';

    %% =========================
    %  2. 全局控制参数
    %  =========================
    cfg.general.randomSeed  = 2026;      % 随机种子，保证结果可复现
    cfg.general.verbose     = true;      % 是否输出运行信息
    cfg.general.saveFigures = false;     % 是否自动保存图像
    cfg.general.saveData    = false;     % 是否自动保存数据

    %% =========================
    %  3. 项目根目录与路径配置
    %  =========================
    % 说明：
    %   不再使用 pwd 作为项目根目录，避免结果输出到项目外部。
    %   默认以 config_default.m 所在目录作为项目根目录。
    thisFileFullPath = mfilename('fullpath');
    cfg.path.root    = fileparts(thisFileFullPath);

    cfg.path.data      = fullfile(cfg.path.root, 'data');
    cfg.path.results   = fullfile(cfg.path.root, 'results');
    cfg.path.figures   = fullfile(cfg.path.results, 'figures');
    cfg.path.tables    = fullfile(cfg.path.results, 'tables');
    cfg.path.summaries = fullfile(cfg.path.results, 'summaries');
    cfg.path.paper     = fullfile(cfg.path.results, 'paper_figures');

    % 按实验类型组织结果目录（保留当前项目已有风格）
    cfg.path.exp.multipathAmplitude = fullfile(cfg.path.results, 'multipath_amplitude_scan');
    cfg.path.exp.multipathDelayPoint = fullfile(cfg.path.results, 'multipath_delay_point_scan');
    cfg.path.exp.multipathPhasePoint = fullfile(cfg.path.results, 'multipath_phase_point_scan');
    cfg.path.exp.spacingStability3D  = fullfile(cfg.path.results, 'spacing_stability_3d_scan');

    %% =========================
    %  4. 时间与采样参数
    %  =========================
    cfg.time.fs             = 10.23e6;   % 采样率(Hz)
    cfg.time.simDuration    = 1e-3;      % 仿真时长(s)，默认1 ms
    cfg.time.t0             = 0;         % 起始时间(s)

    % 自动计算采样点数
    cfg.time.numSamples     = round(cfg.time.fs * cfg.time.simDuration);

    %% =========================
    %  5. 伪码参数
    %  =========================
    cfg.prn.codeType        = 'mseq';    % 'mseq' 或 'gold'
    cfg.prn.codeLength      = 1023;      % 伪码长度
    cfg.prn.prnId           = 1;         % 卫星PRN编号
    cfg.prn.initState       = [1 1 1 1 1 1 1 1 1 1];
    cfg.prn.outputFormat    = 'bipolar'; % 'bipolar' => ±1, 'binary' => 0/1

    %% =========================
    %  6. 码片参数
    %  =========================
    % 说明：
    %   code.chipRate 作为码率真源。
    %   signal.chipRate 保留为兼容字段，并在后面同步。
    cfg.code.chipRate       = 1.023e6;   % 码率(Hz)
    cfg.code.samplesPerChip = round(cfg.time.fs / cfg.code.chipRate);

    %% =========================
    %  7. 信号调制参数
    %  =========================
    cfg.signal.modType      = 'BOC';     % 'BPSK' 或 'BOC'

    % BOC 参数，表示 BOC(m,n)
    cfg.signal.boc.m        = 1;
    cfg.signal.boc.n        = 1;
    cfg.signal.boc.type     = 'sin';     % 'sin' 或 'cos'

    % 是否对基带信号归一化
    cfg.signal.normalize    = true;

    % 兼容字段：与 cfg.code.chipRate 同步
    cfg.signal.chipRate     = cfg.code.chipRate;

    %% =========================
    %  8. 载波参数
    %  =========================
    cfg.carrier.enable      = true;      % 是否进行载波调制
    cfg.carrier.type        = 'IF';      % 'IF' 或 'RF'
    cfg.carrier.freq        = 4.1304e6;  % 中频/载波频率(Hz)
    cfg.carrier.phase       = 0;         % 初始相位(rad)
    cfg.carrier.amplitude   = 1.0;       % 载波幅度

    %% =========================
    %  9. 码跟踪/鉴别器参数
    %  =========================
    % 说明：
    %   tracking.earlyLateSpacing 作为主真源。
    %   scurve.earlyLateSpacing 作为兼容字段，后面同步。
    cfg.tracking.earlyLateSpacing = 0.04;   % 单位：chip
    cfg.tracking.discriminator    = 'NELP'; % Non-coherent Early-Late Power
    cfg.tracking.maxOffsetChips   = 2;      % S曲线横轴范围（码片）
    cfg.tracking.numOffsetPoints  = 201;    % S曲线采样点数
    cfg.tracking.interpMethod     = 'linear'; % linear / spline / pchip
    cfg.tracking.normalizeSCurve  = true;   % 是否归一化

    %% =========================
    %  10. 多径参数
    %  =========================
    cfg.multipath.enable    = true;      % 是否加入多径

    % 主路径参数
    cfg.multipath.main.amplitude = 1.0;
    cfg.multipath.main.delay     = 0;    % 主路径延迟(s)
    cfg.multipath.main.phase     = 0;    % 主路径相位(rad)

    % 多径条数
    cfg.multipath.numPaths  = 1;         % 默认1条附加多径

    % 附加多径参数（结构体数组）
    cfg.multipath.paths(1).amplitude = 0.5;    % 多径幅度衰减系数
    cfg.multipath.paths(1).delay     = 0.2e-6; % 多径延迟(s)
    cfg.multipath.paths(1).phase     = pi / 3; % 多径相位(rad)

    % 延迟实现方式
    %   'integer' : 按整数采样点延迟
    %   'fractional' : 按小数延迟（后续插值扩展）
    cfg.multipath.delayMode = 'integer';

    %% =========================
    %  11. 多径误差扫描参数
    %  =========================
    cfg.multipathScan.maxDelayChips = 1.5;
    cfg.multipathScan.numDelayPoints = 101;

    %% =========================
    %  12. 多径误差包络参数
    %  =========================
    cfg.multipathEnvelope.maxDelayChips = 1.5;
    cfg.multipathEnvelope.numDelayPoints = 101;
    cfg.multipathEnvelope.numPhasePoints = 73;   % 建议奇数，含 0 和 2pi 两端
    cfg.multipathEnvelope.phaseRange     = [0, 2*pi];

    %% =========================
    %  13. 噪声参数
    %  =========================
    cfg.noise.enable        = true;      % 是否加噪
    cfg.noise.type          = 'AWGN';
    cfg.noise.SNR_dB        = 20;        % 信噪比(dB)

    %% =========================
    %  14. 相关分析参数
    %  =========================
    cfg.corr.enable         = true;
    cfg.corr.type           = 'auto';    % 'auto' 或 'cross'
    cfg.corr.maxLagSamples  = 500;       % 最大延迟点数
    cfg.corr.normalize      = true;      % 是否归一化相关结果

    %% =========================
    %  15. S曲线分析参数
    %  =========================
    cfg.scurve.enable           = true;
    cfg.scurve.earlyLateSpacing = cfg.tracking.earlyLateSpacing; % 与 tracking 真源同步
    cfg.scurve.scanRangeChips   = 2.0;
    cfg.scurve.numScanPoints    = 401;
    cfg.scurve.discriminator    = 'NELP';

    %% =========================
    %  16. 绘图参数
    %  =========================
    cfg.plot.showTimeDomain     = true;
    cfg.plot.showSpectrum       = true;
    cfg.plot.showCorrelation    = true;
    cfg.plot.showSCurve         = true;

    cfg.plot.timeDomainSamples  = min(1000, cfg.time.numSamples);
    cfg.plot.spectrumNFFT       = 4096;
    cfg.plot.spectrumCenter     = false;
    cfg.plot.lineWidth          = 1.5;
    cfg.plot.fontSize           = 11;

    %% =========================
    %  17. 实验对照参数
    %  =========================
    cfg.experiment.compareSignals = {'BPSK', 'BOC(1,1)', 'BOC(5,2)'};

    % 多径延迟扫描范围(s)
    cfg.experiment.delaySweep = [0.05e-6, 0.1e-6, 0.2e-6, 0.3e-6, 0.5e-6];

    % 多径衰减扫描
    cfg.experiment.attenuationSweep = [0.2, 0.4, 0.6, 0.8];

    % SNR扫描(dB)
    cfg.experiment.snSweep = [0, 5, 10, 15, 20, 25, 30];

    %% =========================
    %  18. GUI 预留参数
    %  =========================
    % 说明：
    %   当前阶段先预留 GUI 默认入口，不立即引入 App 设计。
    cfg.gui.defaultSignalType = 'BOC';
    cfg.gui.defaultScanType   = 'multipath_amplitude';
    cfg.gui.enableExportAfterRun = false;

    %% =========================
    %  19. 运行期初始化
    %  =========================
    rng(cfg.general.randomSeed);

    % 可选：确保基础结果目录存在
    ensureDir(cfg.path.results);
    ensureDir(cfg.path.figures);
    ensureDir(cfg.path.tables);
    ensureDir(cfg.path.summaries);
    ensureDir(cfg.path.paper);
end

%% ========================= Local Function =========================
function ensureDir(folderPath)
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
end