%% add_chinese_annotations_SS.m
% -------------------------------------------------------------------------
%  作用：自动给 S_S.slx 仿真模型添加中文注释（蓝字 Annotation）、
%        顶部总标题和功能分区红/绿色标题，不会改变原有电路连接。
%
%  使用方法：
%    1) 把本 .m 文件和 S_S.slx 放在同一目录；
%    2) 在 MATLAB 命令窗口里运行：  add_chinese_annotations_SS
%    3) 运行结束后会自动另存为 S_S_annotated.slx
%
%  说明：脚本通过 Simulink.Annotation 添加文字注释，不影响仿真。
%        原始 S_S.slx 不会被修改。
% -------------------------------------------------------------------------

modelName     = 'S_S';
annotatedName = 'S_S_annotated';

% 关闭可能已加载的同名模型
if bdIsLoaded(modelName);     close_system(modelName, 0);     end
if bdIsLoaded(annotatedName); close_system(annotatedName, 0); end

% 复制一份再编辑，避免改坏原始模型
copyfile([modelName '.slx'], [annotatedName '.slx']);
load_system(annotatedName);

%% --------- 1. 模块旁的中文蓝字注释 ---------
% 第1列：模型中 Block 名称
% 第2列：要在 Block 旁边显示的中文名（蓝色字）
labelMap = {
    % 电源 + 逆变
    'DC Voltage Source1',          '直流输入电源 Uin (15V)'
    'Mosfet4',                     '逆变开关管 Q1 (左桥上)'
    'Mosfet5',                     '逆变开关管 Q2 (右桥上)'
    'Mosfet6',                     '逆变开关管 Q3 (左桥下)'
    'Mosfet7',                     '逆变开关管 Q4 (右桥下)'
    sprintf('Pulse\nGenerator'),   'PWM驱动 Q1/Q4'
    sprintf('Pulse\nGenerator1'),  'PWM驱动 Q2/Q3'

    % S-S 补偿网络（关键！）
    'Series RLC Branch8',          '原边串联补偿电容 Cp (S补偿,84.52nF)'
    'Mutual Inductance1',          '耦合线圈 Lp~Ls (磁耦合,无线传能)'
    'Series RLC Branch5',          '副边串联补偿电容 Cs (S补偿,181.11nF)'

    % 副边整流 + 输出
    'Universal Bridge1',           '副边全桥整流器 (二极管)'
    'Series RLC Branch6',          '输出滤波电容 Cd (100uF)'
    'Series RLC Branch4',          '负载电阻 RL (10Ω)'

    % 测量
    'Current Measurement4',        '输入电流 Iin 测量'
    'Current Measurement3',        '原边谐振电流 ILp 测量'
    'Current Measurement6',        '副边谐振电流 ILs 测量'
    'Voltage Measurement15',       '输入电压 Uin 测量'
    'Voltage Measurement9',        '逆变输出电压 UAB 测量'
    'Voltage Measurement14',       '原边电容电压 UCp 测量'
    'Voltage Measurement12',       '副边电压 (整流前) 测量'
    'Voltage Measurement13',       '整流后电压测量'
    'Voltage Measurement8',        '输出电压 Uo 测量'
    sprintf('RMS\nMeasurement6'),  '输入电流有效值 Iin_rms'
    sprintf('RMS\nMeasurement10'), '原边电流有效值 ILp_rms'
    sprintf('RMS\nMeasurement9'),  '输出电流有效值 Io_rms'

    % 功率与效率运算
    'Product2',                    '瞬时功率 Pin = Uin × Iin'
    'Product3',                    '瞬时功率 Pout = Uo × Io'
    'Divide2',                     '效率 η = Pout / Pin'
    'Divide3',                     '比值运算'
    'Display13',                   '输入功率 Pin 显示'
    'Display14',                   '输出功率 Pout 显示'
    'Display10',                   '功率/电压数值显示'
    'Display9',                    '数值显示'

    % 示波器
    'ILs1',                        '示波器: 副边电流 ILs'
    'UC',                          '示波器: 原边电容电压 UCp'
    'Us1',                         '示波器: 整流输入/输出电压'
    'V&Ip',                        '示波器: 原边电压&电流 (V&Ip)'
    'V&Is',                        '示波器: 副边电压&电流 (V&Is)'
    'Scope2',                      '示波器: 综合波形2'
    'Scope5',                      '示波器: 综合波形5'
    'Scope8',                      '示波器: 综合波形8'
    'Scope9',                      '示波器: 综合波形9'
    'Scope12',                     '示波器: 综合波形12'
    '效率1',                       '示波器: 系统效率 η(t)'
    '输入功率1',                   '示波器: 输入功率 Pin(t)'
    '输出功率1',                   '示波器: 输出功率 Pout(t)'

    % 其他
    'powergui',                    '电力系统配置块 (必备)'
    'Constant1',                   '常数 (运算系数)'
};

for k = 1:size(labelMap,1)
    blkOrigName = labelMap{k,1};
    cnName      = labelMap{k,2};
    blkPath     = [annotatedName '/' blkOrigName];
    if getSimulinkBlockHandle(blkPath) ~= -1
        % 在 Description 字段里写一份，鼠标悬停可见
        try
            set_param(blkPath, 'Description', cnName);
        catch
        end
        % 在 Block 下方添加独立的蓝字注释
        pos   = get_param(blkPath, 'Position');   % [x1 y1 x2 y2]
        noteX = pos(1);
        noteY = pos(4) + 8;                       % 紧贴 Block 下方
        try
            Simulink.Annotation([annotatedName '/CN_' num2str(k)], ...
                'Text',           cnName, ...
                'Position',       [noteX, noteY], ...
                'FontName',       'Microsoft YaHei', ...
                'FontSize',       10, ...
                'ForegroundColor','blue');
        catch ME
            warning('注释 %s 添加失败: %s', cnName, ME.message);
        end
    else
        warning('找不到 Block: %s, 已跳过。', blkOrigName);
    end
end

%% --------- 2. 顶部"分区标题"——红色标功率主电路区，绿色标信号运算区 ---------
zoneTitles = {
    % 文本                                位置 [x y]   颜色      字号
    '【1】直流输入电源 Vin',              [480, 600],  'red',     14
    '【2】高频全桥逆变 Q1~Q4',            [630, 600],  'red',     14
    '【3】原边补偿 Cp (S 串联补偿)',      [820, 600],  'red',     14
    '【4】耦合线圈 Lp~Ls (磁耦合传能)',   [950, 600],  'magenta', 14
    '【5】副边补偿 Cs + 全桥整流',        [1170, 600], 'red',     14
    '【6】输出滤波 Cd 与负载 RL',         [1340, 600], 'red',     14
    '【7】PWM 驱动信号发生区',            [380, 1180], 'darkGreen', 14
    '【8】功率与效率运算区',              [700, 1180], 'darkGreen', 14
    '【9】RMS 有效值测量区',              [400, 720],  'darkGreen', 12
};
for k = 1:size(zoneTitles,1)
    try
        Simulink.Annotation([annotatedName '/ZONE_' num2str(k)], ...
            'Text',          zoneTitles{k,1}, ...
            'Position',      zoneTitles{k,2}, ...
            'FontName',      'Microsoft YaHei', ...
            'FontSize',      zoneTitles{k,4}, ...
            'FontWeight',    'bold', ...
            'ForegroundColor', zoneTitles{k,3});
    catch ME
        warning('分区标题 %s 添加失败: %s', zoneTitles{k,1}, ME.message);
    end
end

%% --------- 3. 顶部总标题 ---------
try
    Simulink.Annotation([annotatedName '/TITLE'], ...
        'Text',           'S-S 型无线电能传输 (WPT) 仿真模型 —— 中文标注版', ...
        'Position',       [700, 540], ...
        'FontName',       'Microsoft YaHei', ...
        'FontSize',       18, ...
        'FontWeight',     'bold', ...
        'ForegroundColor','black');
catch ME
    warning('总标题添加失败: %s', ME.message);
end

%% --------- 4. 副标题：拓扑简图（用文字描述） ---------
try
    Simulink.Annotation([annotatedName '/TOPO'], ...
        'Text', '拓扑能量流: Vin → 全桥逆变 → Cp → Lp ~ Ls → Cs → 整流桥 → Cd → RL', ...
        'Position',       [700, 565], ...
        'FontName',       'Microsoft YaHei', ...
        'FontSize',       12, ...
        'FontAngle',      'italic', ...
        'ForegroundColor','black');
catch
end

%% --------- 5. 保存 ---------
save_system(annotatedName);
fprintf('\n========================================================\n');
fprintf(' 已生成中文标注模型: %s.slx\n', annotatedName);
fprintf(' 在 MATLAB 中输入   open_system(''%s'')   即可查看。\n', annotatedName);
fprintf('========================================================\n\n');
