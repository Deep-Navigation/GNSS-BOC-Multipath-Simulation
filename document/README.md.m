% # GNSS_BOC_Simulation
% 
% ## 1. 项目简介
% 
% 本项目是一个基于 MATLAB 的 GNSS 仿真分析平台，面向 BPSK 与 BOC 信号在多径条件下的相关特性、S 曲线特性、码跟踪误差、多径误差包络以及参数稳定性分析。
% 
% 当前项目已经具备以下能力：
% 
% - PRN 码生成
% - BPSK / BOC 基带调制
% - 载波加载
% - 多径叠加
% - 加噪声
% - 相关函数分析
% - S 曲线分析
% - 多径跟踪误差分析
% - 多径误差包络分析
% - 多径幅度扫描
% - 多径延迟点扫描
% - 多径相位点扫描
% - Early-Late spacing 三维稳定性比较
% - 论文图统一导出
% 
% ---
% 
% ## 2. 当前项目状态（阶段一：结构止血后）
% 
% 当前项目已经完成第一阶段整理，目标是：
% 
% - 区分“当前有效脚本”和“历史 legacy 脚本”
% - 减少误用旧脚本的风险
% - 让项目结构更清晰
% - 为后续工程化重构、GUI 整合做准备
% 
% ### 当前有效主入口脚本
% 
% 以下脚本是当前推荐使用的主入口：
% 
% - `run_multipath_amplitude_scan.m`
% - `run_multipath_delay_point_scan.m`
% - `run_multipath_phase_point_scan.m`
% - `run_spacing_stability_3d_scan.m`
% - `export_paper_figures.m`
% 
% ### 当前保留但角色待确认的脚本
% 
% - `run_bpsk_boc_comparison.m`
% 
% 该脚本暂时保留在根目录，但目前不作为后续主实验链路的核心入口。
% 
% ### Legacy 脚本
% 
% 以下脚本已归档到 `legacy/`，不再作为当前主流程推荐入口：
% 
% - `export_multipath_amplitude_scan_results_legacy.m`
% - `run_paper_figures_legacy.m`
% - `run_spacing_scan_legacy.m`
% - `run_spacing_fine_scan_legacy.m`
% - `run_spacing_ultrafine_scan_legacy.m`
% - `run_spacing_local_refine_scan_legacy.m`
% 
% 这些脚本保留仅用于历史参考，不应再作为当前论文结果或后续开发的主要入口。
% 
% ---
% 
% ## 3. 当前默认推荐参数
% 
% 当前已经通过多轮扫描与三维稳定性比较，确认推荐的 Early-Late spacing 为：
% 
% ```matlab
% cfg.tracking.earlyLateSpacing = 0.04;
% cfg.scurve.earlyLateSpacing   = 0.04;
% 
% 
% 
% ### 当前保留的基础演示脚本
% 
% - `run_bpsk_boc_comparison.m`
% 
% 该脚本用于快速生成 BPSK 与 BOC 的三类基础对比图：
% 
% 1. 理想 S 曲线对比  
% 2. 多径跟踪误差对比  
% 3. 多径误差包络对比  
% 
% 该脚本适合快速演示、人工检查和基础结果对比，不作为当前论文图统一导出的主入口。当前正式导出入口为：
% 
% export_paper_figures.m`
% 
% 
% 
% 
% 
% 
% 
%% ## 2. 当前项目状态（阶段二进行中）
% 
% 当前项目已经完成：
% 
% - 阶段一：结构止血
% - 阶段二步骤1：统一配置真源
% - 阶段二步骤2：统一主扫描脚本返回值风格
% - 阶段二步骤3：统一 `results` 结构体格式
% 
% 当前项目已经不再只是“能跑的脚本集合”，而是开始建立统一接口规范，为后续公共函数抽象、GUI 整合和进一步工程化重构做准备。
% 
% ---
% 
% ## 3. 当前有效主入口脚本
% 
% 以下脚本是当前推荐使用的正式主入口：
% 
% - `run_multipath_amplitude_scan.m`
% - `run_multipath_delay_point_scan.m`
% - `run_multipath_phase_point_scan.m`
% - `run_spacing_stability_3d_scan.m`
% - `export_paper_figures.m`
% 
% ### 基础演示脚本
% - `run_bpsk_boc_comparison.m`
% 
% 该脚本用于快速生成 BPSK 与 BOC 的三类基础对比图：
% 
% 1. 理想 S 曲线对比  
% 2. 多径跟踪误差对比  
% 3. 多径误差包络对比  
% 
% 它适合快速演示、人工检查和基础结果对比，不作为当前论文图统一导出的主入口。
% 
% ---
% 
% ## 4. Legacy 脚本
% 
% 以下脚本已归档到 `legacy/`，不再作为当前主流程推荐入口：
% 
% - `export_multipath_amplitude_scan_results_legacy.m`
% - `run_paper_figures_legacy.m`
% - `run_spacing_scan_legacy.m`
% - `run_spacing_fine_scan_legacy.m`
% - `run_spacing_ultrafine_scan_legacy.m`
% - `run_spacing_local_refine_scan_legacy.m`
% 
% 这些脚本仅用于历史参考，不应再用于当前论文主结果和后续开发主流程。
% 
% ---
% 
% ## 5. 当前配置真源（阶段二统一规则）
% 
% 为了避免多个字段并行控制同一物理量，当前项目已经明确配置主字段（source of truth）。
% 
% ### 5.1 码率主字段
% 主字段：
% 
% ```matlab
% cfg.code.chipRate.
% ```
% ## 15. 工程结构说明
% 
% 当前项目已经不再只是若干独立脚本，而是逐步形成了“入口层 + 公共能力层 + 核心算法层 + 结果层”的工程结构。
% 
% ---
% 
% ### 15.1 根目录的角色
% 
% 根目录当前只保留：
% 
% - 默认配置入口
% - 当前正式主入口脚本
% - 统一导出脚本
% - README
% 
% 当前根目录主要文件如下：
% 
% - `config_default.m`
% - `README.md`
% - `export_paper_figures.m`
% - `run_multipath_amplitude_scan.m`
% - `run_multipath_delay_point_scan.m`
% - `run_multipath_phase_point_scan.m`
% - `run_spacing_stability_3d_scan.m`
% - `run_bpsk_boc_comparison.m`
% 
% 其中：
% 
% #### 正式主入口
% - `run_multipath_amplitude_scan.m`
% - `run_multipath_delay_point_scan.m`
% - `run_multipath_phase_point_scan.m`
% - `run_spacing_stability_3d_scan.m`
% - `export_paper_figures.m`
% 
% #### 基础演示脚本
% - `run_bpsk_boc_comparison.m`
% 
% 该脚本用于快速生成 BPSK / BOC 的基础对比图，适合作为演示或 sanity check，不作为当前论文图统一导出的正式入口。
% 
% ---
% 
% ### 15.2 `+core/`：核心信号生成与信道模块
% 
% `+core/` 目录负责项目最底层的基础信号链路构建，是整个仿真平台的核心底座。
% 
% 当前主要包括：
% 
% - `generatePRN.m`
% - `bpskModulate.m`
% - `bocModulate.m`
% - `addCarrier.m`
% - `addMultipath.m`
% - `addNoise.m`
% 
% 这一层的职责是：
% 
% - 生成 PRN 码
% - 完成 BPSK / BOC 调制
% - 加载载波
% - 构造多径信道
% - 加入噪声
% 
% 这一层不负责高层实验流程控制，也不负责论文导出。
% 
% ---
% 
% ### 15.3 `+utils/`：分析与绘图工具模块
% 
% `+utils/` 目录负责各类分析函数和基础绘图函数。
% 
% 当前主要包括：
% 
% - `plotSpectrum.m`
% - `computeCorrelation.m`
% - `computeSCurve.m`
% - `plotSCurve.m`
% - `computeMultipathError.m`
% - `plotMultipathError.m`
% - `computeMultipathEnvelope.m`
% - `plotMultipathEnvelope.m`
% 
% 这一层的职责是：
% 
% - 计算相关函数
% - 计算 S 曲线
% - 计算多径跟踪误差
% - 计算多径误差包络
% - 提供基础绘图支持
% 
% 说明：
% 
% - `utils.computeMultipathError` 属于误差曲线扫描器
% - `utils.computeMultipathEnvelope` 属于包络扫描器
% - 这两个函数不应再被误当作“单点条件评估器”
% 
% ---
% 
% ### 15.4 `+helpers/`：公共 helper 层
% 
% `+helpers/` 是阶段三新增的公共辅助层，用于承载“非算法型、可复用”的通用能力。
% 
% 当前包括：
% 
% - `ensureDir.m`
% - `safeSaveFigure.m`
% - `writeTextFile.m`
% 
% 这一层的职责是：
% 
% - 统一目录创建逻辑
% - 统一图像保存逻辑
% - 统一文本摘要写出逻辑
% 
% 设计目的：
% 
% - 减少多个脚本里重复出现相同 helper
% - 降低维护成本
% - 提高脚本一致性
% 
% 后续如有更多稳定、低耦合的工具函数，也应优先放入这一层。
% 
% ---
% 
% ### 15.5 `+analysis/`：公共分析层
% 
% `+analysis/` 是阶段三新增的公共分析能力层，用于承载“可被多个实验脚本共享的分析逻辑”。
% 
% 当前包括：
% 
% - `evaluateSingleTrackingError.m`
% - `buildBasebandSignal.m`
% - `evaluateMultipathEnvelope.m`
% 
% 这一层的职责是：
% 
% #### `evaluateSingleTrackingError.m`
% 公共单点评估器，用于在固定多径参数下直接计算一次码跟踪误差。
% 
% 当前已被以下脚本复用：
% 
% - `run_multipath_delay_point_scan.m`
% - `run_multipath_phase_point_scan.m`
% - `run_spacing_stability_3d_scan.m`
% 
% #### `buildBasebandSignal.m`
% 公共基带信号构造器，用于统一生成 BPSK / BOC 基带信号。
% 
% #### `evaluateMultipathEnvelope.m`
% 公共包络适配层，用于统一兼容 `utils.computeMultipathEnvelope` 的多种输出签名。
% 
% 设计目的：
% 
% - 避免多个脚本各自带一份相似分析逻辑
% - 把“实验流程”与“底层分析计算”解耦
% - 为后续 GUI 接入提供稳定底层接口
% 
% ---
% 
% ### 15.6 `legacy/`：历史脚本归档区
% 
% `legacy/` 目录用于存放历史脚本和不再推荐直接使用的旧入口。
% 
% 当前包括：
% 
% - `export_multipath_amplitude_scan_results_legacy.m`
% - `run_paper_figures_legacy.m`
% - `run_spacing_scan_legacy.m`
% - `run_spacing_fine_scan_legacy.m`
% - `run_spacing_ultrafine_scan_legacy.m`
% - `run_spacing_local_refine_scan_legacy.m`
% 
% 这一层的作用是：
% 
% - 保留历史演化痕迹
% - 防止当前主流程被旧脚本干扰
% - 降低误用风险
% 
% 原则上：
% 
% - `legacy/` 中脚本不应再作为当前论文主结果生成入口
% - 后续开发不应继续建立在 `legacy/` 脚本上
% 
% ---
% 
% ### 15.7 `results/`：结果输出层
% 
% `results/` 用于保存所有扫描结果、导出图表和论文版图像。
% 
% 当前典型子目录包括：
% 
% - `results/multipath_amplitude_scan/`
% - `results/multipath_delay_point_scan/`
% - `results/multipath_phase_point_scan/`
% - `results/spacing_stability_3d_scan/`
% - `results/paper_figures/`
% 
% 这一层的职责是：
% 
% - 保存主扫描脚本输出的 `.mat`
% - 保存扫描图像 `.fig / .png`
% - 保存导出摘要 `.txt / .csv / .mat`
% - 保存统一论文图
% 
% 说明：
% 
% - 当前 `config_default.m` 已将项目根目录固定为配置文件所在目录
% - 因此输出不会再漂移到 MATLAB 当前工作目录外部
% 
% ---
% 
% ### 15.8 `tests/`：测试层
% 
% `tests/` 目录用于保存功能测试脚本，验证基础功能链路与主要分析模块是否正常。
% 
% 当前包括：
% 
% - `test_prn.m`
% - `test_bpsk.m`
% - `test_correlation.m`
% - `test_carrier.m`
% - `test_multipath.m`
% - `test_noise.m`
% - `test_scurve.m`
% - `test_multipath_error.m`
% - `test_multipath_envelope.m`
% 
% 这一层的职责是：
% 
% - 验证基础信号模块
% - 验证分析模块
% - 在重构后做回归测试
% 
% 后续如果继续重构公共层，建议补充：
% 
% - `analysis` 层单元测试
% - `helpers` 层基础测试
% - 主入口脚本回归测试说明
% 
% ---
% 
% ### 15.9 `experiments/`：预留实验脚本层
% 
% 当前项目中已经建立 `experiments/` 目录，但尚未完全接管根目录实验脚本。
% 
% 该目录的未来用途是：
% 
% - 承载非主入口的专项实验脚本
% - 承载基础演示脚本
% - 逐步减轻根目录负担
% 
% 后续更合理的方向是：
% 
% - 将 `run_bpsk_boc_comparison.m` 迁入 `experiments/`
% - 将新的专项验证脚本优先放入 `experiments/`
% - 根目录只保留少数正式主入口
% 
% ---
% 
% ### 15.10 当前工程分层的理解方式
% 
% 当前项目可以按下面四层来理解：
% 
% #### 第 1 层：入口层
% 负责组织实验流程与导出流程
% 
% - `run_multipath_amplitude_scan.m`
% - `run_multipath_delay_point_scan.m`
% - `run_multipath_phase_point_scan.m`
% - `run_spacing_stability_3d_scan.m`
% - `export_paper_figures.m`
% 
% #### 第 2 层：公共能力层
% 负责封装多个入口共享的公共能力
% 
% - `+helpers/`
% - `+analysis/`
% 
% #### 第 3 层：核心算法层
% 负责信号生成、分析计算和底层绘图
% 
% - `+core/`
% - `+utils/`
% 
% #### 第 4 层：结果与测试层
% 负责结果落地与功能验证
% 
% - `results/`
% - `tests/`
% 
% ---
% 
% ### 15.11 当前工程结构的阶段性评价
% 
% 当前项目已经从“脚本集合”逐步演化为一个具备明确分层的 MATLAB 仿真工程：
% 
% - 根目录开始收敛
% - legacy 已隔离
% - 公共 helper 层已建立
% - 公共 analysis 层已建立
% - 主入口接口已统一
% - 结果输出路径已固定
% 
% 但当前仍未完全完成工程化，主要还缺：
% 
% - `experiments/` 目录正式接管部分实验脚本
% - 更多公共分析函数继续抽取
% - GUI 第一版
% - 更完整的测试体系
% - 更完整的开发文档
% 
% ---
% 
% ### 15.12 一句话理解当前结构
% 
% 当前工程结构可以概括为：
% 
% > 根目录负责主入口，`+helpers` 和 `+analysis` 负责公共能力，`+core` 和 `+utils` 负责底层算法，`results` 负责输出落地，`tests` 负责回归验证，`legacy` 负责历史归档。

% ## 16. 开发约定说明
% 
% 为了避免项目后续继续退化为“脚本堆积”，当前开发需要遵守统一的命名、分层、配置和结果结构约定。
% 
% 这些约定从当前阶段开始生效，后续新增代码、重构代码和 GUI 整合都应尽量遵守。
% 
% ---
% 
% ### 16.1 总体原则
% 
% 当前项目开发遵循以下原则：
% 
% 1. **优先保证结果正确**
%    - 不允许通过降低数值精度来换速度
%    - 不允许为了少写代码而改变物理含义
% 
% 2. **优先保持配置单一真源**
%    - 同一物理量尽量只有一个主字段
%    - 兼容字段允许存在，但不允许再作为主控制入口
% 
% 3. **优先复用公共层**
%    - 相同 helper 不要在多个脚本中重复定义
%    - 相同分析逻辑不要在多个脚本中各自维护一份
% 
% 4. **优先保持主入口统一风格**
%    - 主扫描脚本都应支持：
%      - 直接运行
%      - 返回 `results`
% 
% 5. **优先可维护性**
%    - 新代码应优先考虑：
%      - 命名清晰
%      - 职责单一
%      - 易于回归测试
%      - 易于接入 GUI
% 
% ---
% 
% ### 16.2 目录分层约定
% 
% 新增代码应尽量放入合适层级，而不是默认堆在根目录。
% 
% #### 根目录
% 仅保留以下内容：
% 
% - 默认配置入口
% - 当前正式主入口脚本
% - 统一导出脚本
% - README
% - 少量基础演示脚本
% 
% 不应继续把大量专项实验脚本直接堆在根目录。
% 
% ---
% 
% #### `+core/`
% 适用于：
% 
% - PRN 生成
% - 调制
% - 信道构造
% - 噪声与载波处理
% 
% 特点：
% 
% - 偏底层
% - 偏信号链路
% - 不应夹带实验流程控制逻辑
% 
% ---
% 
% #### `+utils/`
% 适用于：
% 
% - 相关分析
% - S 曲线分析
% - 多径误差分析
% - 包络分析
% - 基础绘图
% 
% 特点：
% 
% - 偏分析和工具
% - 可以是底层算法函数
% - 不应承载高层实验流程编排
% 
% ---
% 
% #### `+helpers/`
% 适用于：
% 
% - 通用目录创建
% - 图像保存
% - 文本写出
% - 其他稳定、低耦合、非算法型工具
% 
% 特点：
% 
% - 轻量
% - 可重复使用
% - 不应依赖具体实验物理含义
% 
% ---
% 
% #### `+analysis/`
% 适用于：
% 
% - 多个主脚本共享的分析逻辑
% - 单点评估器
% - 统一适配层
% - 公共信号构造器
% 
% 特点：
% 
% - 偏“可被多个实验脚本复用的公共分析能力”
% - 比 `utils` 更靠近上层实验
% - 比根目录脚本更底层
% 
% ---
% 
% #### `experiments/`
% 适用于：
% 
% - 非正式主入口的专项实验脚本
% - 对比脚本
% - 临时验证脚本
% - 未来演示脚本迁移目标
% 
% 特点：
% 
% - 可以保留实验探索性质
% - 但不应进入 `legacy`
% - 也不应污染根目录
% 
% ---
% 
% #### `legacy/`
% 适用于：
% 
% - 已被替代的旧脚本
% - 历史扫描脚本
% - 旧版导出脚本
% 
% 原则：
% 
% - `legacy/` 中脚本只保留历史参考价值
% - 不应再用于当前论文主结果生成
% - 后续新功能不得继续建立在 `legacy/` 上
% 
% ---
% 
% ### 16.3 命名约定
% 
% #### 主运行脚本
% 统一命名为：
% 
% ```matlab
% run_<task>.m
% ```