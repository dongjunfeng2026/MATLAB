%% add_chinese_annotations.m
% -------------------------------------------------------------------------
%  作用：自动给 LCC_S_2018b.slx 仿真模型添加中文注释（Annotation 文字框）
%        与彩色分组框（区域划分），不会改变原有电路连接。
%
%  使用方法：
%    1) 把本 .m 文件和 LCC_S_2018b.slx 放在同一目录；
%    2) 在 MATLAB 命令窗口里运行：  add_chinese_annotations
%    3) 运行结束后会自动另存为 LCC_S_2018b_annotated.slx
%
%  说明：脚本通过 add_block('built-in/Note', ...) 与
%        Simulink.Annotation 句柄属性写入，不影响仿真。
% -------------------------------------------------------------------------

modelName     = 'LCC_S_2018b';
annotatedName = 'LCC_S_2018b_annotated';

% 关闭可能已加载的同名模型
if bdIsLoaded(modelName);     close_system(modelName, 0);     end
if bdIsLoaded(annotatedName); close_system(annotatedName, 0); end

% 复制一份再编辑，避免改坏原始模型
copyfile([modelName '.slx'], [annotatedName '.slx']);
load_system(annotatedName);

%% --------- 1. 给已有 Block 加中文显示名（在原英文名下方追加中文） ---------
labelMap = {
    % 原英文 Block 名                 追加的中文名
    'DC Voltage Source1',            '直流输入电源 Uin (15V)'
    'Mosfet4',                       '逆变开关管 Q1 (左桥上)'
    'Mosfet5',                       '逆变开关管 Q2 (右桥上)'
    'Mosfet6',                       '逆变开关管 Q3 (左桥下)'
    'Mosfet7',                       '逆变开关管 Q4 (右桥下)'
    'Pulse Generator',               'PWM 驱动 Q1/Q4'
    'Pulse Generator1',              'PWM 驱动 Q2/Q3'
    'Series RLC Branch3',            '原边谐振电感 Lf (LCC-L)'
    'Series RLC Branch8',            '原边并联补偿电容 Cf (LCC-C1)'
    'Series RLC Branch10',           '原边串联补偿电容 Cp (LCC-C2)'
    'Mutual Inductance1',            '耦合线圈 Lp - Ls (磁耦合)'
    'Series RLC Branch5',            '副边串联补偿电容 Cs (S 补偿)'
    'Universal Bridge1',             '副边全桥整流器'
    'Series RLC Branch6',            '输出滤波电容 Cd'
    'Series RLC Branch4',            '负载电阻 RL'
    'Current Measurement4',          '输入电流测量 Iin'
    'Current Measurement1',          '桥臂中点电流测量'
    'Current Measurement5',          '原边谐振电流 ILp'
    'Current Measurement6',          '副边谐振电流 ILs'
    'Voltage Measurement15',         '输入电压测量 Uin'
    'Voltage Measurement1',          '逆变输出电压 UAB'
    'Voltage Measurement16',         '原边补偿电容电压 UCp'
    'Voltage Measurement14',         '副边补偿电容电压 UCs'
    'Voltage Measurement8',          '输出电压 Uo'
    'Voltage Measurement12',         '功率运算电压采样1'
    'Voltage Measurement13',         '功率运算电压采样2'
    'Product2',                      '瞬时功率 Pin = Uin*Iin'
    'Product3',                      '瞬时功率 Pout = Uo*Io'
    'Divide2',                       '效率 η = Pout / Pin'
    'Divide3',                       '比值运算'
    'Display13',                     '输入功率 Pin 显示'
    'Display14',                     '输出功率 Pout 显示'
    'powergui',                      '电力系统配置块'
    'ILp',                           '示波器: 原边电流 ILp'
    'ILs1',                          '示波器: 副边电流 ILs'
    'UC',                            '示波器: 原边电容电压 UCp'
    'UCs',                           '示波器: 副边电容电压 UCs'
    'Us1',                           '示波器: 输出电压 Uo'
    'Zvsp',                          '示波器: ZVS 判断'
};

for k = 1:size(labelMap,1)
    blkOrigName = labelMap{k,1};
    cnName      = labelMap{k,2};
    blkPath     = [annotatedName '/' blkOrigName];
    if getSimulinkBlockHandle(blkPath) ~= -1
        % 在原名后追加换行 + 中文，不改 SID
        try
            % 用 Description 字段也写一份，方便鼠标悬停看
            set_param(blkPath, 'Description', cnName);
        catch
        end
        % 在 Block 旁边添加一个独立的 Note（注释）
        pos   = get_param(blkPath, 'Position');   % [x1 y1 x2 y2]
        noteX = pos(1);
        noteY = pos(4) + 8;                       % 紧贴 Block 下方
        Simulink.Annotation([annotatedName '/CN_' num2str(k)], ...
            'Text',          cnName, ...
            'Position',      [noteX, noteY], ...
            'FontName',      'Microsoft YaHei', ...
            'FontSize',      10, ...
            'ForegroundColor','blue');
    else
        warning('找不到 Block: %s, 已跳过。', blkOrigName);
    end
end

%% --------- 2. 添加六大功能区"分区标题" ---------
zoneTitles = {
    % 文本                             位置 [x y]   颜色
    '【1】直流输入电源 Vin',            [380, 600],  'red'
    '【2】高频全桥逆变 Q1~Q4',          [520, 600],  'red'
    '【3】原边 LCC 补偿网络 Lf/Cf/Cp',  [720, 600],  'red'
    '【4】磁耦合线圈 Lp~Ls (无线传能)', [950, 600],  'magenta'
    '【5】副边 S 补偿 + 全桥整流',      [1180, 600], 'red'
    '【6】输出滤波 Cd 与负载 RL',       [1380, 600], 'red'
    '【7】PWM 驱动信号发生区',          [380, 1180], 'darkGreen'
    '【8】功率与效率运算区',            [700, 1180], 'darkGreen'
};
for k = 1:size(zoneTitles,1)
    Simulink.Annotation([annotatedName '/ZONE_' num2str(k)], ...
        'Text',          zoneTitles{k,1}, ...
        'Position',      zoneTitles{k,2}, ...
        'FontName',      'Microsoft YaHei', ...
        'FontSize',      14, ...
        'FontWeight',    'bold', ...
        'ForegroundColor', zoneTitles{k,3});
end

%% --------- 3. 顶部加一个总标题 ---------
Simulink.Annotation([annotatedName '/TITLE'], ...
    'Text',           'LCC-S 型无线电能传输 (WPT) 仿真模型 —— 中文标注版', ...
    'Position',       [600, 540], ...
    'FontName',       'Microsoft YaHei', ...
    'FontSize',       18, ...
    'FontWeight',     'bold', ...
    'ForegroundColor','black');

%% --------- 4. 保存 ---------
save_system(annotatedName);
fprintf('\n已生成中文标注模型: %s.slx\n', annotatedName);
fprintf('在 MATLAB 中输入   open_system(''%s'')   即可查看。\n', annotatedName);
