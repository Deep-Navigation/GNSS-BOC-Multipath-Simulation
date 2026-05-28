# GNSS-BOC-Multipath-Simulation
Modern GNSS signals (GPS L1C, Galileo E1, BeiDou B1C) adopt Binary Offset Carrier (BOC) modulation to achieve sharper correlation peaks and better spectrum compatibility. However, BOC’s inherent multi‑peak autocorrelation makes it vulnerable to side‑peak false locking in multipath‑prone environments (e.g., urban canyons).
GNSS_BOC_Simulation 简要说明
1. 项目简介

这是一个基于 MATLAB 的 GNSS 仿真平台，用来分析 BPSK vs BOC 在多径环境下的：

S 曲线

跟踪误差

多径误差包络

不同参数（幅度 / 延迟 / 相位 / spacing）对性能影响

2. 快速开始（最重要）

进入目录：

cd '你的路径/GNSS_BOC_Simulation'

运行一个实验（推荐入口）：

results = run_experiment('amplitude');

其他可选：

run_experiment('delay_point')
run_experiment('phase_point')
run_experiment('spacing_stability_3d')
3. 四个核心实验
(1) 多径幅度扫描
run_experiment('amplitude')

看：多径强度变化 → 误差变化

(2) 多径延迟扫描
run_experiment('delay_point')

看：多径位置 → 误差

(3) 多径相位扫描
run_experiment('phase_point')

看：相位变化 → 误差

(4) spacing 三维稳定性（最重要）
run_experiment('spacing_stability_3d')

输出：

最优 Early-Late spacing

worst-case error

平均误差

👉 论文最有价值的结果基本在这里

4. 推荐论文图一键导出
export_paper_figures

输出目录：

results/paper_figures/

包含：

S 曲线对比

多径误差对比

多径误差包络

各类扫描图

5. GUI 使用（可选）
run_gui_app

支持输入：

[0.2 0.4 0.6]
0:0.1:1
linspace(0,pi,9)
6. 项目结构（极简理解）
+core      → 信号生成（BPSK/BOC/多径/噪声）
+utils     → 相关 / S曲线 / 误差计算
+analysis  → 各种扫描实验（核心）
+helpers   → 保存结果
root       → 用户入口（run_*）
7. 最常用流程（建议这样用）
cfg = config_default();
cfg.noise.enable = false;   % 论文建议关噪声

run_experiment('amplitude');
run_experiment('delay_point');
run_experiment('phase_point');
run_experiment('spacing_stability_3d');

export_paper_figures
8. 一句话理解架构
run_experiment
   ↓
run_* 主入口
   ↓
analysis（计算+画图）
   ↓
core / utils（底层算法）
   ↓
helpers（保存）
   ↓
results（输出）
