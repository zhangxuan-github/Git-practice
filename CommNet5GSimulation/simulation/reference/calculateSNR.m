% Configure the carrier.(基站)
simParameters.Carrier = nrCarrierConfig;
simParameters.Carrier.NSizeGrid = 51;            % Bandwidth in number of resource blocks (51 RBs at 30 kHz SCS for 20 MHz BW)
simParameters.Carrier.SubcarrierSpacing = 30;    % 15, 30, 60, 120, 240 (kHz)
simParameters.Carrier.CyclicPrefix = 'Normal';   % 'Normal' or 'Extended' (Extended CP is relevant for 60 kHz SCS only)

% Configure the carrier frequency, transmitter (BS),  (UE), and
% distance between the BS and UE. Specify this distance as a vector for
% multiple SNR points.
simParameters.CarrierFrequency = 3.5e9;   % Carrier frequency (Hz)
simParameters.TxHeight = 25;              % Height of the BS antenna (m)
simParameters.TxPower = 40;               % Power delivered to all antennas of the BS on a fully allocated grid (dBm)
simParameters.RxHeight = 1.5;             % Height of UE antenna (m)
simParameters.RxNoiseFigure = 6;          % Noise figure of the UE (dB)
simParameters.RxAntTemperature = 290;     % Antenna temperature of the UE (K)
simParameters.TxRxDistance = [5e2 9e2];   % Distance between the BS and UE (m)

simParameters.PathLossModel = '5G-NR';        % '5G-NR' or 'fspl'
simParameters.PathLoss = nrPathLossConfig;
simParameters.PathLoss.Scenario = 'UMa';      % Urban macrocell，路径损失的配置，方案？
simParameters.PathLoss.EnvironmentHeight = 1; % Average height of the environment in UMa/UMi，平均环境高度？

simParameters.DelayProfile = 'TDL-A'; % A, B, and C profiles are NLOS channels. D and E profiles are LOS channels. 信道的延迟配置类型

% 获取信道的kFactor，用来计算SNR
if contains(simParameters.DelayProfile,'CDL','IgnoreCase',true)   % CDL
    channel = nrCDLChannel;
    channel.DelayProfile = simParameters.DelayProfile;
    chInfo = info(channel);
    kFactor = chInfo.KFactorFirstCluster; % dB
else % TDL
    channel = nrTDLChannel;
    channel.DelayProfile = simParameters.DelayProfile;
    chInfo = info(channel);
    kFactor = chInfo.KFactorFirstTap; % dB
end

% Determine LOS between Tx and Rx based on Rician factor K.
% If K is negative, then LOS is false.
% If K is positive, then LOS is true.
% 也就是判断是不是LOS
simParameters.LOS = kFactor>-Inf;

% Determine the sample rate and FFT size that are required for this carrier.
% The sample rate and FFT size are determined based on the bandwidth,
waveformInfo = nrOFDMInfo(simParameters.Carrier);

% Get the maximum delay of the fading channel.
% 获取衰落信道的最大延迟
chInfo = info(channel);
maxChDelay = chInfo.MaximumChannelDelay;
disp(maxChDelay);
disp('sa');


% Calculate the path loss.
% 计算路径损失
if contains(simParameters.PathLossModel,'5G','IgnoreCase',true)
    txPosition = [0;0; simParameters.TxHeight];
    dtr = simParameters.TxRxDistance;
    rxPosition = [dtr; zeros(size(dtr)); simParameters.RxHeight*ones(size(dtr))];
    disp(txPosition);
    disp(rxPosition);
    pathLoss = nrPathLoss(simParameters.PathLoss,simParameters.CarrierFrequency,simParameters.LOS,txPosition,rxPosition);
else % Free-space path loss
    lambda = physconst('LightSpeed')/simParameters.CarrierFrequency;
    pathLoss = fspl(simParameters.TxRxDistance,lambda);
end

% disp(pathLoss);

kBoltz = physconst('Boltzmann');
NF = 10^(simParameters.RxNoiseFigure/10);
Teq = simParameters.RxAntTemperature + 290*(NF-1); % K
N0 = sqrt(kBoltz*waveformInfo.SampleRate*Teq/2.0);
fftOccupancy = 12*simParameters.Carrier.NSizeGrid/waveformInfo.Nfft;
simParameters.SNRIn = (simParameters.TxPower-30) - pathLoss - 10*log10(fftOccupancy) - 10*log10(2*N0^2);
disp(simParameters.SNRIn)

SNRInc = mat2cell(simParameters.SNRIn(:),length(pathLoss),1);
tSNRIn = table(simParameters.TxRxDistance(:),SNRInc{:},'VariableNames',{'Distance Tx-Rx (m)','SNR (dB)'});
disp(tSNRIn)



disp("******************");
% 计算信号功率S (P_RE^S)
% S = (P_Tr / L) × (N_FFT^2 / (12 × N_grid^s))
P_Tr = 10^((simParameters.TxPower-30)/10); % 将dBm转换为瓦特
L = 10.^(pathLoss/10); % 将路径损耗从dB转换为线性值
N_FFT = waveformInfo.Nfft;
N_grid_s = simParameters.Carrier.NSizeGrid;
% 计算每个RE的信号功率S
S = (P_Tr ./ L) .* (N_FFT^2 ./ (12 * N_grid_s));

% 计算噪声功率N (P_RE^N)
% N = 2 × N_0^2 × N_FFT
N = 2 * (N0^2) * N_FFT;

% 计算SNR (线性值和dB值)
SNR_linear = S ./ N; % 线性SNR (S/N)
SNR_dB = 10*log10(SNR_linear); % 转换为dB

% 显示结果
disp('信号功率S (W):');
disp(S);
disp('噪声功率N (W):');
disp(N);
disp('SNR (dB):');
disp(SNR_dB);

% 创建结果表格
SNRInc = mat2cell(SNR_dB(:),length(pathLoss),1);
tSNRIn = table(simParameters.TxRxDistance(:),SNRInc{:},'VariableNames',{'Distance Tx-Rx (m)','SNR (dB)'});
disp(tSNRIn);
% 分开计算信号功率（S）和噪声功率（N）
% S = (simParameters.TxPower - pathLoss)/10; % 将dBm转换为线性单位（W）
% s = (simParameters.TxPower ./ pathLoss )*(waveformInfo.Nfft / (12 * simParameters.Carrier.NSizeGrid));
% n = 2 * N0^2;
% % N = 2*N0^2 * (12*simParameters.Carrier.NSizeGrid); % 噪声功率计算

% simParameters.SNRIn = 10*log10(s/n); % 计算SNR（dB）

% disp(simParameters.SNRIn)


a = physconst('LightSpeed');
disp(a);
