%% customize_LCC_S_to_robot.m
%  把已有的 LCC_S_2018b.slx 改造成"值守型光伏清洁机器人无线充电系统"
%  方法：拷贝一份原模型，用 set_param 批量改写电路参数
%        （连线、布局、测量、PWM 信号都保留，绝对不断线）
%
%  使用：
%    1) 把 init_WPT_robot.m / LCC_S_2018b.slx / 本脚本 放在同一文件夹
%    2) 在 MATLAB 命令窗口输入：>> customize_LCC_S_to_robot
%    3) 自动生成并打开 WPT_robot.slx，可直接 Run

clear; clc;

%% 1. 载入参数
init_WPT_robot;

%% 2. 复制源模型
srcModel = 'LCC_S_2018b';
dstModel = 'WPT_robot';

if bdIsLoaded(srcModel),  close_system(srcModel, 0);  end
if bdIsLoaded(dstModel),  close_system(dstModel, 0);  end
if exist([dstModel '.slx'], 'file'), delete([dstModel '.slx']); end

assert(exist([srcModel '.slx'],'file')==2, ...
    '找不到 %s.slx，请把源模型放到当前文件夹后再运行。', srcModel);

copyfile([srcModel '.slx'], [dstModel '.slx']);
load_system(dstModel);
fprintf('✓ 已复制 %s.slx → %s.slx\n', srcModel, dstModel);

%% 3. 批量改参数（块名来自 LCC_S_中文标注说明.md）
% ---- 直流输入电压 ----
trySet([dstModel '/DC Voltage Source1'], 'Amplitude',   num2str(Vin));

% ---- 原边 LCC 补偿 ----
trySet([dstModel '/Series RLC Branch3'], 'Inductance',  num2str(Lf));   % Lf
trySet([dstModel '/Series RLC Branch8'], 'Capacitance', num2str(Cf));   % Cf
trySet([dstModel '/Series RLC Branch10'],'Capacitance', num2str(C1));   % C1 (Cp)

% ---- 副边 S 补偿 ----
trySet([dstModel '/Series RLC Branch5'], 'Capacitance', num2str(C2));   % C2 (Cs)

% ---- 输出滤波 + 负载 ----
trySet([dstModel '/Series RLC Branch6'], 'Capacitance', num2str(Co));   % Co
trySet([dstModel '/Series RLC Branch4'], 'Resistance',  num2str(RL));   % RL

% ---- 互感耦合线圈：Mutual Inductance 参数名在不同版本里有差异，
%      这里把所有可能的写法都尝试一遍，哪个生效用哪个 ----
muBlk = [dstModel '/Mutual Inductance1'];

% 写法 A：旧式 [R L] 复合参数（R2015b–R2018b 常见）
ok = trySet(muBlk, 'Z1', sprintf('[%g %g]', R1, L1));
ok = trySet(muBlk, 'Z2', sprintf('[%g %g]', R2, L2)) || ok;
ok = trySet(muBlk, 'Zm', sprintf('[0 %g]',  M))      || ok;

% 写法 B：分立参数（R2019a 之后常用）
trySet(muBlk, 'L1', num2str(L1));
trySet(muBlk, 'L2', num2str(L2));
trySet(muBlk, 'R1', num2str(R1));
trySet(muBlk, 'R2', num2str(R2));
trySet(muBlk, 'M',  num2str(M));

% 写法 C：Self impedance 命名（少数版本）
trySet(muBlk, 'SelfImpedanceL1', sprintf('[%g %g]', R1, L1));
trySet(muBlk, 'SelfImpedanceL2', sprintf('[%g %g]', R2, L2));
trySet(muBlk, 'MutualImpedance', sprintf('[0 %g]',  M));

% ---- PWM 驱动频率（85 kHz） ----
% 两路 PWM 都改：周期=Tpwm，宽度=50%，相位差=Tpwm/2
trySet([dstModel '/Pulse Generator'],  'Period',     num2str(Tpwm));
trySet([dstModel '/Pulse Generator'],  'PulseWidth', '50');
trySet([dstModel '/Pulse Generator'],  'PhaseDelay', num2str(phase1));

trySet([dstModel '/Pulse Generator1'], 'Period',     num2str(Tpwm));
trySet([dstModel '/Pulse Generator1'], 'PulseWidth', '50');
trySet([dstModel '/Pulse Generator1'], 'PhaseDelay', num2str(phase2));

%% 4. 仿真配置
set_param(dstModel, ...
    'StopTime',  '0.005', ...                 % 5 ms
    'Solver',    'ode23tb', ...
    'MaxStep',   num2str(Ts*5));

%% 5. 保存并打开
save_system(dstModel);
open_system(dstModel);

fprintf('\n========================================\n');
fprintf('  已生成: %s.slx\n', dstModel);
fprintf('  Vin = %g V, f0 = %g kHz, k = %.2f, M = %.2f μH\n', Vin, f0/1e3, k, M*1e6);
fprintf('  Lf=%gμH  Cf=%gnF  C1=%gnF  C2=%gnF\n', ...
        Lf*1e6, Cf*1e9, C1*1e9, C2*1e9);
fprintf('  在 Simulink 中点 ▶ Run 即可仿真\n');
fprintf('========================================\n');

%% ===== 内嵌小工具：尝试 set_param，失败不报错 =====
function ok = trySet(blkPath, paramName, paramValue)
    ok = false;
    try
        % 先确认 block 存在，再确认参数名存在
        if getSimulinkBlockHandle(blkPath) == -1
            return
        end
        % 检查参数是否在该 block 的对话框里
        dlgParams = get_param(blkPath, 'DialogParameters');
        if isstruct(dlgParams) && isfield(dlgParams, paramName)
            set_param(blkPath, paramName, paramValue);
            ok = true;
            fprintf('   set %-40s %s = %s\n', blkPath, paramName, paramValue);
        end
    catch ME
        fprintf('   ⚠ %s.%s 设置失败: %s\n', blkPath, paramName, ME.message);
    end
end
