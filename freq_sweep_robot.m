%% freq_sweep_robot.m —— 频率扫描分析（70–100 kHz）
%   方法：基波分析法（FHA）+ 三回路阻抗矩阵
%   输出：频率—输出功率、频率—传输效率 两条曲线（每条曲线 4 个 k 值）

init_WPT_robot;     % 装载参数

f_vec  = linspace(70e3, 100e3, 121);
k_list = [0.25, 0.22, 0.19, 0.15];

Pout_mat = zeros(numel(k_list), numel(f_vec));
eta_mat  = zeros(numel(k_list), numel(f_vec));

% 整流前的等效交流负载（FHA 一阶近似）
Req = (8/pi^2) * RL;          % ≈ 8.106 Ω

% 全桥方波基波有效值
Vinv_rms = (4/pi) * Vin / sqrt(2);

for ik = 1:numel(k_list)
    kk = k_list(ik);
    Mk = kk * sqrt(L1*L2);
    for jf = 1:numel(f_vec)
        w = 2*pi*f_vec(jf);
        ZLf = 1j*w*Lf;
        ZCf = 1/(1j*w*Cf);
        ZC1 = 1/(1j*w*C1);
        ZC2 = 1/(1j*w*C2);
        ZL1 = R1 + 1j*w*L1;
        ZL2 = R2 + 1j*w*L2;
        Zsec = ZL2 + ZC2 + Req;

        % 阻抗矩阵 [I_a; I_b; I_2]
        %   I_a：源回路电流（流过 Lf）
        %   I_b：原边谐振回路电流（流过 L1）
        %   I_2：副边电流
        Z = [ ZLf+ZCf,  -ZCf,        0;
              -ZCf,     ZCf+ZC1+ZL1, 1j*w*Mk;
              0,        1j*w*Mk,     Zsec ];
        V = [Vinv_rms; 0; 0];
        I = Z\V;

        Pin   = real(Vinv_rms * conj(I(1)));
        Po_ac = abs(I(3))^2 * Req;            % 等效交流输出功率（≈整流后直流功率）
        Pout_mat(ik,jf) = Po_ac;
        eta_mat (ik,jf) = Po_ac / max(Pin, eps);
    end
end

%% 画图：频率 - 输出功率
figure('Name','频率—输出功率','Color','w');
plot(f_vec/1e3, Pout_mat', 'LineWidth', 1.6); grid on;
xlabel('频率 f / kHz'); ylabel('输出功率 P_{out} / W');
title('频率—输出功率特性曲线');
legend(arrayfun(@(x) sprintf('k=%.2f', x), k_list, 'UniformOutput', false), 'Location','best');

%% 画图：频率 - 效率
figure('Name','频率—效率','Color','w');
plot(f_vec/1e3, eta_mat'*100, 'LineWidth', 1.6); grid on;
xlabel('频率 f / kHz'); ylabel('传输效率 \eta / %');
title('频率—传输效率特性曲线');
legend(arrayfun(@(x) sprintf('k=%.2f', x), k_list, 'UniformOutput', false), 'Location','best');
ylim([0 100]);

%% 在 85 kHz 点打印数值，方便填论文表格
[~,i85] = min(abs(f_vec-f0));
fprintf('\n---------- f0=85 kHz 处仿真数值 ----------\n');
for ik = 1:numel(k_list)
    fprintf('k=%.2f : Pout = %6.2f W,  eta = %5.2f %%\n', ...
        k_list(ik), Pout_mat(ik,i85), eta_mat(ik,i85)*100);
end
fprintf('-------------------------------------------\n');
