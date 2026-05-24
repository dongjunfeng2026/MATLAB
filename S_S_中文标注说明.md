# S-S 型无线电能传输（WPT）仿真模型 —— 中文标注 + 参数更新版

> 文件：`S_S.slx`（原始） → `S_S_annotated.slx`（脚本生成）
> 拓扑：原边 **S**eries 串联补偿 + 副边 **S**eries 串联补偿
> 应用：磁耦合谐振式无线充电（IPT/WPT）

运行 `add_chinese_annotations_SS.m` 一次，自动生成 `S_S_annotated.slx`。

---

## 1. 本次脚本对模型做的全部改动

| 类别 | 改动内容 |
|---|---|
| **参数更新（按图片）** | Vin = **48V**；PWM = **91.9kHz**；死区 = **150ns**；L1 = L2 = **30µH**；C1 = C2 = **100nF**；M = **6.5µH**；RL = **2.4Ω**；LL = **10µH**；R1 = R2 = **0.3Ω**；Cd ESR 顺手改成 0.05Ω |
| **删除冗余示波器** | `Scope2`、`Scope5`、`Scope8`、`Scope9`、`Scope12` |
| **删除冗余显示器** | `Display9`、`Display10`（保留 `Display13`、`Display14`） |
| **删除硬编码运算路径** | `Constant1`（=10）、`Divide2`、`Divide3` |
| **新增真实电流测量** | `Current Measurement Iout` 串入 Cd 与 RL 之间 |
| **新增运算块** | `Product_Pout`（Uo × Iout）、`Divide_Eta`（η = Pout/Pin） |
| **互感模块改动** | `Mutual Inductance1`：3 绕组 → **2 绕组**；R1 = R2 = 0.3Ω；L1 = L2 = 30µH；M = 6.5µH |
| **加入中文注释** | 每个保留 Block 旁加蓝色中文小标签；顶部红/绿色 8 个分区标题；最顶端总标题 |

---

## 2. 更新后的关键参数一览

| 位置 | 参数名 | 数值 |
|---|---|---|
| 直流输入源 | `DC Voltage Source1`.Voltage | **48 V** |
| PWM 频率 | `Pulse Generator`.Period | **1/91900 s** |
| PWM 占空比 | `Pulse Generator`.PulseWidth | **48.6213 %**（即 50% − 死区比例） |
| 死区时间 | 相位差/占空比共同实现 | **150 ns** |
| 发射线圈 L1 | `Mutual Inductance1`.SelfImpedance1 | **[0.3 30e-6]** |
| 接收线圈 L2 | `Mutual Inductance1`.SelfImpedance2 | **[0.3 30e-6]** |
| 互感 M | `Mutual Inductance1`.MutualImpedance | **[0 6.5e-6]** |
| 原边补偿电容 Cp（C1） | `Series RLC Branch8`.Capacitance | **100 nF** |
| 副边补偿电容 Cs（C2） | `Series RLC Branch5`.Capacitance | **100 nF** |
| 负载电阻 RL | `Series RLC Branch4`.Resistance | **2.4 Ω** |
| 负载电感 LL | `Series RLC Branch4`.Inductance | **10 µH** |
| 负载支路类型 | `Series RLC Branch4`.BranchType | **RL** |
| 输出滤波电容 Cd | `Series RLC Branch6`.Capacitance | 100 µF（保留原值） |

---

## 3. 谐振频率验算

按更新后的参数：

| 项 | 公式 | 结果 |
|---|---|---|
| 原边谐振 fp | 1 / (2π·√(L1·C1)) = 1 / (2π·√(30µH × 100nF)) | **≈ 91.89 kHz** |
| 副边谐振 fs | 1 / (2π·√(L2·C2)) = 1 / (2π·√(30µH × 100nF)) | **≈ 91.89 kHz** |
| 工作频率 fpwm |  | **91.9 kHz** |

✅ **完美对齐**——91.9 kHz 工作频率正好命中原副边的 LC 谐振点，原边电流和原边电容相互抵消感抗，使整个网络在工作频率下呈纯阻性。这就是 S-S 拓扑的"黄金参数"。

---

## 4. 模型结构（精简后）

```
   [ 直流 48V ]
        │
   [ 全桥逆变 Q1~Q4 ]  ← 91.9 kHz, 50%-150ns 死区
        │  (UAB)
   [ Cp = 100nF ]
        │
   [ Lp = 30µH ]  ⇉ 磁耦合 M=6.5µH ⇉  [ Ls = 30µH ]
                                            │
                                       [ Cs = 100nF ]
                                            │
                                       [ 全桥整流 ]
                                            │
                                       [ Cd = 100µF ]
                                            │
                                       [ Iout 测量 ]  ★ 新增
                                            │
                                       [ RL=2.4Ω + LL=10µH ]
```

---

## 5. 运算与示波器接线

| 信号 | 数据来源 |
|---|---|
| **Pin（输入功率）** | `Product2` ：Voltage Measurement15 (Uin) × Current Measurement4 (Iin) |
| **Pout（输出功率）** ★ 新建 | `Product_Pout` ：Voltage Measurement8 (Uo) × Current Measurement Iout 信号输出 |
| **η（效率）** ★ 新建 | `Divide_Eta` = Pout / Pin |
| Display13 | Pin 数值显示 |
| Display14 | Pout 数值显示 |
| 示波器 输入功率1 | Pin 时域波形 |
| 示波器 输出功率1 | Pout 时域波形 |
| 示波器 效率1 | η 时域波形 |
| 示波器 V&Ip / V&Is / ILs1 / UC / Us1 | 各关键节点波形 |

---

## 6. 使用方法

1. 把 `S_S.slx` 和 `add_chinese_annotations_SS.m` 放在 **同一文件夹**；
2. 打开 MATLAB（≥ 2020b），用 `cd` 切到该文件夹；
3. 命令窗口运行：

```matlab
add_chinese_annotations_SS
open_system('S_S_annotated')
```

4. 命令窗口会逐步打印：
   ```
   [1/5] 按图片更新仿真参数...
   [2/5] 删除冗余示波器和显示器...
   [3/5] 用真实电流测量替换 Constant1 硬编码路径...
   [4/5] 添加中文注释...
   [5/5] 保存模型...
   ```

5. 打开后会看到一份**模块旁有蓝色中文注释 + 顶部红绿色分区标题 + 黑色总标题**的全新模型。

---

## 7. 接线提示（万一某条线没自动连上）

由于 Simscape 物理端口的自动布线偶尔会失败，运行后请检查以下三处，**如果是红色虚线就手动拖一下**：

| 位置 | 应连接 |
|---|---|
| `Current Measurement Iout` 的 LConn ⇄ RConn | 串入 Cd 和 RL 之间的连线（原 Cd 顶 → RL 顶 那条） |
| `Current Measurement Iout` 的信号输出（顶端三角口） | → `Product_Pout` 的第 2 个输入 |
| `Voltage Measurement8` 的输出 | → `Product_Pout` 的第 1 个输入 |
| `Product_Pout` 的输出 | → `Divide_Eta` 的第 1 个输入；同时分支接到 `Display14` 和 `输出功率1` 示波器 |
| `Product2` 的输出 | → `Divide_Eta` 的第 2 个输入 |
| `Divide_Eta` 的输出 | → `效率1` 示波器 |

一般只需补 1 ~ 2 条线即可。
