%% build_WPT_robot_model.m
%  自动创建"值守型光伏清洁机器人无线充电系统"Simulink 仿真模型
%  适配 MATLAB R2018b ~ R2022b（Simscape Specialized Power Systems）
%
%  使用：
%    1) 把 init_WPT_robot.m 和本脚本放在同一文件夹
%    2) 命令行：>> build_WPT_robot_model
%    3) 自动生成并打开 WPT_robot.slx，点 ▶ Run 即可
%
%  本版本改进：
%    - 用 get_param('PortHandles') 句柄连线，对 R2022b 物理端口可靠
%    - Mutual Inductance 在 2022b 用 Lm 参数名（旧版用 M），自动适配
%    - 每条连线都有明确的成功/失败提示

clear; clc;
init_WPT_robot;

m = 'WPT_robot';
if bdIsLoaded(m), close_system(m, 0); end
if exist([m '.slx'],'file'), delete([m '.slx']); end
new_system(m);
open_system(m);

%% ===================== 1. 放置所有 Block =====================
fprintf('\n[1/3] 正在放置模块...\n');

% --- 仿真配置块 ---
add_block('powerlib/powergui', [m '/powergui'], ...
    'Position',[20 20 110 60], ...
    'SimulationMode','Discrete', 'SampleTime',num2str(Ts));

% --- 直流源（垂直放置）---
add_block('powerlib/Electrical Sources/DC Voltage Source', [m '/Vdc'], ...
    'Position',[100 220 130 280], 'Amplitude',num2str(Vin), ...
    'Orientation','down');

% --- 输入电流测量（水平）---
add_block('powerlib/Measurements/Current Measurement', [m '/Iin'], ...
    'Position',[180 235 220 265]);

% --- 4 个 MOSFET（垂直放置，箭头朝下：drain 上, source 下）---
add_block('powerlib/Power Electronics/Mosfet', [m '/Q1'], ...
    'Position',[280 200 320 260], 'Orientation','down');
add_block('powerlib/Power Electronics/Mosfet', [m '/Q3'], ...
    'Position',[280 320 320 380], 'Orientation','down');
add_block('powerlib/Power Electronics/Mosfet', [m '/Q2'], ...
    'Position',[400 200 440 260], 'Orientation','down');
add_block('powerlib/Power Electronics/Mosfet', [m '/Q4'], ...
    'Position',[400 320 440 380], 'Orientation','down');

% --- PWM 信号 ---
add_block('simulink/Sources/Pulse Generator', [m '/PWM1'], ...
    'Position',[160 120 200 150], ...
    'Period',num2str(Tpwm), 'PulseWidth','50', ...
    'PhaseDelay',num2str(phase1), 'Amplitude','1');
add_block('simulink/Sources/Pulse Generator', [m '/PWM2'], ...
    'Position',[160 430 200 460], ...
    'Period',num2str(Tpwm), 'PulseWidth','50', ...
    'PhaseDelay',num2str(phase2), 'Amplitude','1');

% --- 原边 LCC 网络 ---
add_block('powerlib/Elements/Series RLC Branch', [m '/Lf'], ...
    'Position',[510 230 560 270], 'BranchType','L', ...
    'Inductance',num2str(Lf));
add_block('powerlib/Elements/Series RLC Branch', [m '/Cf'], ...
    'Position',[610 290 650 350], 'BranchType','C', ...
    'Capacitance',num2str(Cf), 'Orientation','down');
add_block('powerlib/Elements/Series RLC Branch', [m '/C1'], ...
    'Position',[680 230 730 270], 'BranchType','C', ...
    'Capacitance',num2str(C1));

% --- Mutual Inductance（关键模块，2022b 参数名 Lm）---
muBlk = [m '/Coil'];
add_block('powerlib/Elements/Mutual Inductance', muBlk, ...
    'Position',[800 200 870 320]);

% 优先尝试 R2022b 的标准参数名（两绕组 + 互感 Lm）
mu_ok = false;
candidates = {
    {'R1',num2str(R1); 'L1',num2str(L1); 'R2',num2str(R2); ...
     'L2',num2str(L2); 'Lm',num2str(M)};                     % R2019a~R2022b
    {'R1',num2str(R1); 'L1',num2str(L1); 'R2',num2str(R2); ...
     'L2',num2str(L2); 'M',num2str(M)};                      % R2018b
    {'Z1',sprintf('[%g %g]',R1,L1); 'Z2',sprintf('[%g %g]',R2,L2); ...
     'Zm',sprintf('[0 %g]',M)};                              % 旧版
};
dlg = get_param(muBlk,'DialogParameters');
for c = 1:numel(candidates)
    set = candidates{c};
    if all(cellfun(@(p) isfield(dlg,p), set(:,1)))
        for r = 1:size(set,1)
            set_param(muBlk, set{r,1}, set{r,2});
        end
        mu_ok = true;
        fprintf('   ✓ Mutual Inductance 用第 %d 套参数名设置成功\n', c);
        break;
    end
end
if ~mu_ok
    fprintf(2,'   ⚠ Mutual Inductance 参数未自动设上，请双击该块手动填:\n');
    fprintf(2,'      L1=%gH, L2=%gH, R1=R2=%gΩ, M=Lm=%gH\n', L1, L2, R1, M);
end

% --- 副边 ---
add_block('powerlib/Elements/Series RLC Branch', [m '/C2'], ...
    'Position',[940 230 990 270], 'BranchType','C', ...
    'Capacitance',num2str(C2));

add_block('powerlib/Power Electronics/Universal Bridge', [m '/Rect'], ...
    'Position',[1060 200 1140 320], ...
    'Arms','2', 'PowerElectronicDevice','Diodes');

% --- 输出 ---
add_block('powerlib/Elements/Series RLC Branch', [m '/Co'], ...
    'Position',[1210 280 1250 340], 'BranchType','C', ...
    'Capacitance',num2str(Co), 'Orientation','down');
add_block('powerlib/Elements/Series RLC Branch', [m '/RL'], ...
    'Position',[1310 280 1350 340], 'BranchType','R', ...
    'Resistance',num2str(RL), 'Orientation','down');

% --- 输出电流/电压测量 ---
add_block('powerlib/Measurements/Current Measurement', [m '/Io'], ...
    'Position',[1170 215 1200 245]);
add_block('powerlib/Measurements/Voltage Measurement', [m '/Vo'], ...
    'Position',[1390 280 1420 340], 'Orientation','down');

% --- 示波器 ---
add_block('simulink/Sinks/Scope', [m '/Scope_Vo'], ...
    'Position',[1460 290 1500 330]);

fprintf('   ✓ 共放置 17 个模块\n');

%% ===================== 2. 用 PortHandles 连线 =====================
fprintf('\n[2/3] 正在连线（用 PortHandles 句柄方式）...\n');

% 获取所有 block 的端口句柄
ph = struct();
blkList = {'Vdc','Iin','Q1','Q2','Q3','Q4','PWM1','PWM2', ...
           'Lf','Cf','C1','Coil','C2','Rect','Co','RL','Io','Vo','Scope_Vo'};
for i = 1:numel(blkList)
    ph.(blkList{i}) = get_param([m '/' blkList{i}], 'PortHandles');
end

% 连线表：{src_block, src_port_type, src_idx, dst_block, dst_port_type, dst_idx, 描述}
% 注意：Orientation='down' 时，原本"左右"的物理端口变为"上下"，
%       具体由 LConn/RConn 数组顺序决定，下面已按布局调整
conn = {
    % --- 原边主回路 ---
    'Vdc',  'LConn',1, 'Iin', 'LConn',1, 'Vdc(+)→Iin in';
    'Iin',  'RConn',1, 'Q1',  'LConn',1, 'Iin out→Q1 drain';
    'Iin',  'RConn',1, 'Q2',  'LConn',1, 'Iin out→Q2 drain（并联）';
    'Q1',   'LConn',2, 'Q3',  'LConn',1, 'Q1 source→Q3 drain（桥臂A中点）';
    'Q2',   'LConn',2, 'Q4',  'LConn',1, 'Q2 source→Q4 drain（桥臂B中点）';
    'Q3',   'LConn',2, 'Vdc', 'RConn',1, 'Q3 source→Vdc(-)';
    'Q4',   'LConn',2, 'Vdc', 'RConn',1, 'Q4 source→Vdc(-)（并联）';

    % --- PWM 驱动 ---
    'PWM1', 'Outport',1, 'Q1', 'Inport',1, 'PWM1→Q1 gate';
    'PWM1', 'Outport',1, 'Q4', 'Inport',1, 'PWM1→Q4 gate';
    'PWM2', 'Outport',1, 'Q2', 'Inport',1, 'PWM2→Q2 gate';
    'PWM2', 'Outport',1, 'Q3', 'Inport',1, 'PWM2→Q3 gate';

    % --- 原边 LCC 网络 ---
    'Q1',   'LConn',2, 'Lf',  'LConn',1, '桥臂A→Lf';
    'Lf',   'RConn',1, 'C1',  'LConn',1, 'Lf→C1';
    'Lf',   'RConn',1, 'Cf',  'LConn',1, 'Lf→Cf top（节点 A''）';
    'Cf',   'RConn',1, 'Q2',  'LConn',2, 'Cf bottom→桥臂B';
    'C1',   'RConn',1, 'Coil','LConn',1, 'C1→Coil L1+';
    'Coil', 'RConn',1, 'Q2',  'LConn',2, 'Coil L1-→桥臂B（回流）';

    % --- 副边 ---
    'Coil', 'LConn',2, 'C2',  'LConn',1, 'Coil L2+→C2';
    'C2',   'RConn',1, 'Rect','LConn',1, 'C2→Rect AC1';
    'Coil', 'RConn',2, 'Rect','LConn',2, 'Coil L2-→Rect AC2';

    % --- 整流后 ---
    'Rect', 'RConn',1, 'Io',  'LConn',1, 'Rect DC+→Io in';
    'Io',   'RConn',1, 'Co',  'LConn',1, 'Io out→Co top';
    'Io',   'RConn',1, 'RL',  'LConn',1, 'Io out→RL top';
    'Co',   'RConn',1, 'Rect','RConn',2, 'Co bottom→Rect DC-';
    'RL',   'RConn',1, 'Rect','RConn',2, 'RL bottom→Rect DC-（并联）';
    'RL',   'LConn',1, 'Vo',  'LConn',1, 'RL top→Vo+';
    'RL',   'RConn',1, 'Vo',  'RConn',1, 'RL bottom→Vo-';
    'Vo',   'Outport',1,'Scope_Vo','Inport',1, 'Vo→Scope';
};

ok_cnt = 0; fail_cnt = 0; failed = {};
for i = 1:size(conn,1)
    sB=conn{i,1}; sT=conn{i,2}; sI=conn{i,3};
    dB=conn{i,4}; dT=conn{i,5}; dI=conn{i,6}; desc=conn{i,7};
    try
        sP = ph.(sB).(sT)(sI);
        dP = ph.(dB).(dT)(dI);
        add_line(m, sP, dP, 'autorouting','smart');
        ok_cnt = ok_cnt + 1;
        fprintf('   ✓ %s\n', desc);
    catch ME
        fail_cnt = fail_cnt + 1;
        failed{end+1} = sprintf('%s → %s (%s)', sB, dB, ME.message); %#ok<AGROW>
        fprintf(2,'   ✗ %s : %s\n', desc, ME.message);
    end
end

fprintf('\n   连线小结: %d 条成功 / %d 条失败\n', ok_cnt, fail_cnt);

%% ===================== 3. 仿真配置 + 保存 =====================
set_param(m, 'StopTime','0.005', 'Solver','ode23tb', ...
    'MaxStep',num2str(Ts*5));
save_system(m);

fprintf('\n[3/3] 完成！\n');
fprintf('========================================\n');
fprintf('  模型: %s.slx\n', m);
fprintf('  Vin=%gV, f0=%gkHz, k=%.2f, M=%.1fμH\n', Vin, f0/1e3, k, M*1e6);
fprintf('  Lf=%gμH  Cf=%gnF  C1=%gnF  C2=%gnF\n', Lf*1e6, Cf*1e9, C1*1e9, C2*1e9);
if fail_cnt == 0
    fprintf('  全部连线成功，可以直接点 ▶ Run\n');
else
    fprintf('  ⚠ 有 %d 条连线失败，请按提示手动连接，或先点 Run 看错误是否影响仿真\n', fail_cnt);
end
fprintf('========================================\n');
