%% coupling_sweep_robot.m —— 耦合系数 k 扫描（额定 f0=85 kHz）
%   工况：k = 0.25 / 0.22 / 0.19 / 0.15
%   输出：每个工况的 Pin、Pout、η、Vo、Io，以及两条对比曲线

init_WPT_robot;

k_vec = [0.25, 0.22, 0.19, 0.15];
w     = 2*pi*f0;

% 整流前等效交流负载
Req      = (8/pi^2) * RL;
% 全桥方波基波有效值
Vinv_rms = (4/pi) * Vin / sqrt(2);

% 频率相关阻抗（k 不变，可复用）
ZLf = 1j*w*Lf;       ZCf = 1/(1j*w*Cf);
ZC1 = 1/(1j*w*C1);   ZC2 = 1/(1j*w*C2);
ZL1 = R1 + 1j*w*L1;  ZL2 = R2 + 1j*w*L2;
Zsec = ZL2 + ZC2 + Req;

Pin_v  = zeros(size(k_vec));
Pout_v = zeros(size(k_vec));
eta_v  = zeros(size(k_vec));
Vo_v   = zeros(size(k_vec));
Io_v   = zeros(size(k_vec));

for i = 1:numel(k_vec)
    Mk = k_vec(i)*sqrt(L1*L2);
    Z  = [ ZLf+ZCf,  -ZCf,        0;
           -ZCf,     ZCf+ZC1+ZL1, 1j*w*Mk;
           0,        1j*w*Mk,     Zsec ];
    I  = Z\[Vinv_rms;0;0];
    Pin_v(i)  = real(Vinv_rms*conj(I(1)));
    Pout_v(i) = abs(I(3))^2*Req;
    eta_v(i)  = Pout_v(i)/Pin_v(i);
    % 折算到整流后直流：Vo ≈ (pi/(2√2))·|I2|·Req, Io = Vo/RL
    Vo_v(i)   = (pi/(2*sqrt(2)))*abs(I(3))*Req;
    Io_v(i)   = Vo_v(i)/RL;
end

%% 输出表格
T = table(k_vec', Pin_v', Pout_v', eta_v'*100, Vo_v', Io_v', ...
    'VariableNames', {'k','Pin_W','Pout_W','eta_pct','Vo_V','Io_A'});
disp(T);

%% 画图：耦合系数 - 输出功率
figure('Name','耦合系数—输出功率','Color','w');
bar(k_vec, Pout_v, 0.6); grid on;
xlabel('耦合系数 k'); ylabel('输出功率 P_{out} / W');
title('耦合系数—输出功率（f_0 = 85 kHz）');
text(k_vec, Pout_v, compose(' %.1f W', Pout_v), ...
    'VerticalAlignment','bottom','HorizontalAlignment','center');

%% 画图：耦合系数 - 效率
figure('Name','耦合系数—效率','Color','w');
plot(k_vec, eta_v*100, '-o', 'LineWidth', 1.6, 'MarkerFaceColor','b'); grid on;
xlabel('耦合系数 k'); ylabel('传输效率 \eta / %');
title('耦合系数—传输效率（f_0 = 85 kHz）');
ylim([0 100]);
for i = 1:numel(k_vec)
    text(k_vec(i), eta_v(i)*100, sprintf(' %.2f%%', eta_v(i)*100), ...
        'VerticalAlignment','bottom');
end
