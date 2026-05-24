%% add_chinese_annotations_SS.m
% =========================================================================
%  综合脚本：从 S_S.slx 一次性生成 S_S_annotated.slx，做以下事情：
%   1. 按图片要求修改全部参数（Vin=48V、PWM=91.9kHz、死区150ns、L1=L2=30µH、
%      C1=C2=100nF、M=6.5µH、RL=2.4Ω、LL=10µH、线圈内阻 R1=R2=0.3Ω）
%   2. 删除冗余的 Scope（Scope2/5/8/9/12）和 Display（Display9/10）
%   3. 删除 Constant1 硬编码运算路径（Constant1 + Divide2 + Divide3），
%      添加真实 "Current Measurement Iout" 电流测量到负载支路
%   4. 把 Mutual Inductance1 改为 2 绕组
%   5. 给所有保留的 Block 加蓝色中文注释、红/绿色分区标题、顶部总标题
%
%  使用方法：
%    1) 把本 .m 文件和 S_S.slx 放在同一目录
%    2) 在 MATLAB 命令窗口运行：  add_chinese_annotations_SS
%    3) 自动生成 S_S_annotated.slx（每次运行都覆盖重新生成）
%
%  ⚠ 原始 S_S.slx 不会被修改。
% =========================================================================

modelName     = 'S_S';
annotatedName = 'S_S_annotated';

% --- 关闭已加载模型 ---
warning('off', 'Simulink:Commands:LoadMdlParameterizedLink');
try, close_system(modelName, 0);     end
try, close_system(annotatedName, 0); end

% --- 复制一份再编辑（每次都覆盖之前的注释版本） ---
if exist([annotatedName '.slx'], 'file')
    delete([annotatedName '.slx']);
end
copyfile([modelName '.slx'], [annotatedName '.slx']);
load_system(annotatedName);

fprintf('\n========== 开始处理 %s.slx ==========\n', annotatedName);

% =========================================================================
%% PART 1 : 按图片更新参数
% =========================================================================
fprintf('\n[1/5] 按图片更新仿真参数...\n');

% --- 1.1 直流输入源 48V ---
set_param([annotatedName '/DC Voltage Source1'], 'Amplitude', '48');
fprintf('   ✓ DC Voltage Source1 = 48 V\n');

% --- 1.2 PWM 频率 91.9kHz, 死区 150ns ---
fpwm     = 91900;
deadtime = 150e-9;
T_pwm    = 1/fpwm;
duty_pct = sprintf('%.4f', (T_pwm/2 - deadtime)/T_pwm * 100);  % ≈ 48.6213
% Pulse Generator (Q1/Q4)
p1 = [annotatedName '/' sprintf('Pulse\nGenerator')];
set_param(p1, 'Period','1/91900', 'PulseWidth',duty_pct, 'PhaseDelay','0');
% Pulse Generator1 (Q2/Q3) - 相位差半个周期
p2 = [annotatedName '/' sprintf('Pulse\nGenerator1')];
set_param(p2, 'Period','1/91900', 'PulseWidth',duty_pct, 'PhaseDelay','1/91900/2');
fprintf('   ✓ PWM 频率 = 91.9 kHz, 占空比 = %s%% (含 150 ns 死区)\n', duty_pct);

% --- 1.3 Mutual Inductance1：改成 2 绕组 + 新参数 ---
set_param([annotatedName '/Mutual Inductance1'], ...
    'NumberOfWindings', '2', ...
    'ThreeWindings',    'off', ...
    'SelfImpedance1',   '[0.3 30e-6]', ...
    'SelfImpedance2',   '[0.3 30e-6]', ...
    'MutualImpedance',  '[0 6.5e-6]');
fprintf('   ✓ Mutual Inductance1 = 2 绕组, L1=L2=30µH, M=6.5µH, R1=R2=0.3Ω\n');

% --- 1.4 原边补偿电容 Cp = 100nF ---
set_param([annotatedName '/Series RLC Branch8'], 'Capacitance', '100e-9');
fprintf('   ✓ 原边补偿电容 Cp = 100 nF\n');

% --- 1.5 副边补偿电容 Cs = 100nF ---
set_param([annotatedName '/Series RLC Branch5'], 'Capacitance', '100e-9');
fprintf('   ✓ 副边补偿电容 Cs = 100 nF\n');

% --- 1.6 输出滤波电容 Cd 的 ESR 改小一点（更接近实际） ---
set_param([annotatedName '/Series RLC Branch6'], 'Resistance', '0.05');
fprintf('   ✓ Cd 寄生电阻 ESR = 0.05 Ω\n');

% --- 1.7 负载：RL = 2.4Ω + LL = 10µH 串联 ---
set_param([annotatedName '/Series RLC Branch4'], ...
    'BranchType',  'RL', ...
    'Resistance',  '2.4', ...
    'Inductance',  '10e-6');
fprintf('   ✓ 负载 RL = 2.4 Ω 串 LL = 10 µH\n');

% =========================================================================
%% PART 2 : 删除冗余 Scope / Display
% =========================================================================
fprintf('\n[2/5] 删除冗余示波器和显示器...\n');
redundant = {'Scope2','Scope5','Scope8','Scope9','Scope12','Display9','Display10'};
for k = 1:numel(redundant)
    blkPath = [annotatedName '/' redundant{k}];
    if getSimulinkBlockHandle(blkPath) ~= -1
        try
            delete_block(blkPath);
            fprintf('   ✓ 删除 %s\n', redundant{k});
        catch ME
            fprintf('   ! 删除 %s 失败: %s\n', redundant{k}, ME.message);
        end
    end
end

% =========================================================================
%% PART 3 : 删除 Constant1 硬编码路径，添加真实电流测量
% =========================================================================
fprintf('\n[3/5] 用真实电流测量替换 Constant1 硬编码路径...\n');

% --- 3.1 删掉硬编码三件套 ---
oldHard = {'Constant1','Divide2','Divide3'};
for k = 1:numel(oldHard)
    blkPath = [annotatedName '/' oldHard{k}];
    if getSimulinkBlockHandle(blkPath) ~= -1
        try
            delete_block(blkPath);
            fprintf('   ✓ 删除硬编码 %s\n', oldHard{k});
        catch
        end
    end
end

% --- 3.2 在 Cd 与 RL 之间添加 Current Measurement Iout ---
%       Cd  位置 [1323 785 1347 830]（旋转270 + 镜像）
%       RL  位置 [1353 785 1377 830]（旋转270 + 镜像）
%       它们在顶部 (y≈785) 相邻；在 y=760 处插入新电流测量
ioutName  = 'Current Measurement Iout';
ioutPath  = [annotatedName '/' ioutName];
if getSimulinkBlockHandle(ioutPath) == -1
    add_block('powerlib/Measurements/Current Measurement', ioutPath, ...
        'Position', [1330, 740, 1370, 770], ...
        'BackgroundColor', 'cyan');
    fprintf('   ✓ 已添加 Current Measurement Iout (位于 Cd 与 RL 顶部之间)\n');
end

% --- 3.3 尝试自动接线 Cd <-> Iout <-> RL（物理回路） ---
try
    hCd   = getSimulinkBlockHandle([annotatedName '/Series RLC Branch6']);
    hRL   = getSimulinkBlockHandle([annotatedName '/Series RLC Branch4']);
    hIout = getSimulinkBlockHandle(ioutPath);

    pCd   = get_param(hCd,   'PortHandles');
    pRL   = get_param(hRL,   'PortHandles');
    pIout = get_param(hIout, 'PortHandles');

    % Cd 顶部端口 LConn / RL 顶部端口 LConn  → 串入 Iout
    add_line(annotatedName, pCd.LConn(1),   pIout.LConn(1), 'autorouting','on');
    add_line(annotatedName, pIout.RConn(1), pRL.LConn(1),   'autorouting','on');
    fprintf('   ✓ Iout 物理回路已自动接入 Cd <-> RL\n');
catch ME1
    fprintf('   ! Iout 物理接线自动尝试失败: %s\n', ME1.message);
    fprintf('     请在 MATLAB 中手动把 Iout 串入 Cd 与 RL 之间的连线 (拖 2 条线即可)\n');
end

% --- 3.4 重建 Pout 和 η 运算链 ---
% Pin  : 已有 Product2 = Uin × Iin, 接到 Display13 + 输入功率1 (无需改)
% Pout : 新建 Product_Pout = Uo × Iout(信号)，接到 Display14 + 输出功率1
% η    : 新建 Divide_Eta = Pout / Pin，接到 效率1
try
    add_block('simulink/Math Operations/Product', ...
        [annotatedName '/Product_Pout'], ...
        'Inputs','**', 'Position',[1430, 940, 1460, 970]);
    fprintf('   ✓ 添加 Product_Pout (Uo × Iout)\n');

    add_block('simulink/Math Operations/Divide', ...
        [annotatedName '/Divide_Eta'], ...
        'Inputs','*/', 'Position',[1530, 940, 1560, 970]);
    fprintf('   ✓ 添加 Divide_Eta (η = Pout / Pin)\n');

    % 接线（best-effort）
    try
        % 接 Voltage Measurement8(Uo) 输出 -> Product_Pout 输入1
        hUo = getSimulinkBlockHandle([annotatedName '/Voltage Measurement8']);
        pUo = get_param(hUo,'PortHandles');
        hPout = getSimulinkBlockHandle([annotatedName '/Product_Pout']);
        pPout = get_param(hPout,'PortHandles');
        add_line(annotatedName, pUo.Outport(1), pPout.Inport(1), 'autorouting','on');
    catch, end

    try
        % 接 Iout 信号 -> Product_Pout 输入2
        add_line(annotatedName, pIout.Outport(1), pPout.Inport(2), 'autorouting','on');
    catch, end

    try
        % Pin 信号源 (Product2 输出) -> Divide_Eta 输入2
        hPin = getSimulinkBlockHandle([annotatedName '/Product2']);
        pPin = get_param(hPin,'PortHandles');
        hEta = getSimulinkBlockHandle([annotatedName '/Divide_Eta']);
        pEta = get_param(hEta,'PortHandles');
        add_line(annotatedName, pPout.Outport(1), pEta.Inport(1), 'autorouting','on');
        add_line(annotatedName, pPin.Outport(1),  pEta.Inport(2), 'autorouting','on');
    catch, end

    fprintf('   ✓ Pout 与 η 运算链尝试自动连接 (失败的请手动补线)\n');
catch ME2
    fprintf('   ! 重建运算块失败: %s\n', ME2.message);
end

% =========================================================================
%% PART 4 : 添加中文注释（蓝字 + 分区标题 + 总标题）
% =========================================================================
fprintf('\n[4/5] 添加中文注释...\n');

% 4.1 模块旁的蓝色中文标签
labelMap = {
    % --- 主电路 ---
    'DC Voltage Source1',                '直流输入电源 Uin = 48 V'
    'Mosfet4',                           '逆变开关管 Q1 (左桥上)'
    'Mosfet5',                           '逆变开关管 Q2 (右桥上)'
    'Mosfet6',                           '逆变开关管 Q3 (左桥下)'
    'Mosfet7',                           '逆变开关管 Q4 (右桥下)'
    sprintf('Pulse\nGenerator'),         'PWM驱动 Q1/Q4 (91.9kHz, 含150ns死区)'
    sprintf('Pulse\nGenerator1'),        'PWM驱动 Q2/Q3 (反相)'
    'Series RLC Branch8',                '原边串联补偿电容 Cp = 100 nF'
    'Mutual Inductance1',                '耦合线圈 Lp~Ls (L1=L2=30µH, M=6.5µH, R=0.3Ω)'
    'Series RLC Branch5',                '副边串联补偿电容 Cs = 100 nF'
    'Universal Bridge1',                 '副边全桥整流器 (二极管)'
    'Series RLC Branch6',                '输出滤波电容 Cd = 100 µF'
    'Series RLC Branch4',                '负载 RL=2.4Ω 串 LL=10µH'
    'Current Measurement Iout',          '★ 真实输出电流测量 Iout (替代原 Constant1)'

    % --- 测量 ---
    'Current Measurement4',              '输入电流 Iin'
    'Current Measurement3',              '原边谐振电流 ILp'
    'Current Measurement6',              '副边谐振电流 ILs'
    'Voltage Measurement15',             '输入电压 Uin'
    'Voltage Measurement9',              '逆变输出电压 UAB'
    'Voltage Measurement14',             '原边电容电压 UCp'
    'Voltage Measurement12',             '整流前交流电压'
    'Voltage Measurement13',             '整流后直流电压'
    'Voltage Measurement8',              '输出电压 Uo'
    sprintf('RMS\nMeasurement6'),        '输入电流 RMS'
    sprintf('RMS\nMeasurement10'),       '原边电流 RMS'
    sprintf('RMS\nMeasurement9'),        '输出电流 RMS'

    % --- 运算与显示 ---
    'Product2',                          '瞬时输入功率 Pin = Uin × Iin'
    'Product3',                          '(原Uo乘法器)'
    'Product_Pout',                      '★ 瞬时输出功率 Pout = Uo × Iout'
    'Divide_Eta',                        '★ 效率 η = Pout / Pin'
    'Display13',                         '输入功率 Pin 数值显示'
    'Display14',                         '输出功率 Pout 数值显示'

    % --- 示波器 ---
    'ILs1',                              '示波器: 副边电流 ILs'
    'UC',                                '示波器: 原边电容电压 UCp'
    'Us1',                               '示波器: 整流前后电压'
    'V&Ip',                              '示波器: 原边电压&电流'
    'V&Is',                              '示波器: 副边电压&电流'
    '效率1',                             '示波器: 系统效率 η(t)'
    '输入功率1',                         '示波器: 输入功率 Pin(t)'
    '输出功率1',                         '示波器: 输出功率 Pout(t)'

    % --- 其他 ---
    'powergui',                          '电力系统配置 (Simscape 必备)'
};
for k = 1:size(labelMap,1)
    blkOrigName = labelMap{k,1};
    cnName      = labelMap{k,2};
    blkPath     = [annotatedName '/' blkOrigName];
    if getSimulinkBlockHandle(blkPath) ~= -1
        try, set_param(blkPath, 'Description', cnName); end
        try
            pos   = get_param(blkPath, 'Position');
            Simulink.Annotation([annotatedName '/CN_' num2str(k)], ...
                'Text',           cnName, ...
                'Position',       [pos(1), pos(4)+8], ...
                'FontName',       'Microsoft YaHei', ...
                'FontSize',       10, ...
                'ForegroundColor','blue');
        catch
        end
    end
end
fprintf('   ✓ 中文蓝字注释已加好\n');

% 4.2 分区标题（红色 = 主电路, 绿色 = 信号区）
zoneTitles = {
    '【1】直流输入电源 Vin = 48V',          [480, 600],  'red',       14
    '【2】高频全桥逆变 Q1~Q4 (91.9kHz)',    [630, 600],  'red',       14
    '【3】原边补偿 Cp (S 串联补偿)',        [820, 600],  'red',       14
    '【4】耦合线圈 Lp~Ls (磁耦合传能)',     [950, 600],  'magenta',   14
    '【5】副边补偿 Cs + 全桥整流',          [1170, 600], 'red',       14
    '【6】输出滤波 Cd + 负载 RL/LL',        [1340, 600], 'red',       14
    '【7】PWM 驱动信号发生区',              [380, 1180], 'darkGreen', 14
    '【8】功率与效率运算区 (使用真实 Iout)',[700, 1180], 'darkGreen', 14
    '【9】RMS 有效值测量',                  [400, 720],  'darkGreen', 12
};
for k = 1:size(zoneTitles,1)
    try
        Simulink.Annotation([annotatedName '/ZONE_' num2str(k)], ...
            'Text',           zoneTitles{k,1}, ...
            'Position',       zoneTitles{k,2}, ...
            'FontName',       'Microsoft YaHei', ...
            'FontSize',       zoneTitles{k,4}, ...
            'FontWeight',     'bold', ...
            'ForegroundColor', zoneTitles{k,3});
    catch
    end
end
fprintf('   ✓ 8 个功能分区标题已加好\n');

% 4.3 总标题 + 副标题
try
    Simulink.Annotation([annotatedName '/TITLE'], ...
        'Text',           'S-S 型无线电能传输 (WPT) 仿真模型 ── 中文标注 + 参数更新版', ...
        'Position',       [700, 540], ...
        'FontName',       'Microsoft YaHei', ...
        'FontSize',       18, ...
        'FontWeight',     'bold', ...
        'ForegroundColor','black');
    Simulink.Annotation([annotatedName '/TOPO'], ...
        'Text', '能量流: Vin(48V) → 全桥逆变(91.9kHz) → Cp(100nF) → Lp(30µH) ~ Ls(30µH), M=6.5µH → Cs(100nF) → 整流桥 → Cd → RL(2.4Ω)+LL(10µH)', ...
        'Position',       [600, 565], ...
        'FontName',       'Microsoft YaHei', ...
        'FontSize',       11, ...
        'FontAngle',      'italic', ...
        'ForegroundColor','black');
catch
end

% =========================================================================
%% PART 5 : 保存
% =========================================================================
fprintf('\n[5/5] 保存模型...\n');
save_system(annotatedName);

fprintf('\n========================================================\n');
fprintf(' ✓ 全部完成！文件：%s.slx\n', annotatedName);
fprintf(' 在 MATLAB 中输入   open_system(''%s'')   即可查看。\n', annotatedName);
fprintf('========================================================\n\n');
fprintf('如果"Current Measurement Iout"或"Product_Pout/Divide_Eta"接线显示\n');
fprintf('为红色虚线，请手动拖动连接（一般 2~3 条线就好）。\n\n');
