%输入参数：距离d(km),速度speed(m/s),载波频率fc(MHz),IRS反射单元数目L_elements
%大尺度衰落：自由空间损耗模型：空间损耗=31.84+19*log10(fc)+21.5*log10(d)+shadowfading+fastfading;；fc为频率，单位：MHz；D为距离，单位：Km；
%链路计算公式：Pr=Pt+Gt-L+Gr，式中Pt是发射功率，Gt是发射天线增益，L是自由空间损耗，Gr是接收天线增益。
%小尺度衰落：抽头延迟线模型（CDL）

function SER = project(d,speed,fc,L_elements)
L_frame=5000000; 
% N_Packets=4000; % Number of frames/packet and Number of packets
NT=2; NR=1; b=2;M=4;
SNRdBs=[70:5:160];  
P_dBm = SNRdBs-83;
sq_NT=sqrt(NT); sq2=sqrt(2);
%d的单位是km，计算时单位需要是km
%fc的单位是MHz，1GHz=1000MHz
% PL_LOS_db = 31.84+21.5*log10(d)+19*log10(fc);
% PL_SL_db = 33+25.5*log10(d)+20*log10(fc);
% PL_DL_db = 18.6+35.7*log10(d)+20*log10(fc);
% if PL_LOS_db>PL_SL_db&&PL_LOS_db>PL_DL_db
%     PL_NLOS_db = PL_LOS_db;
% elseif PL_SL_db>PL_LOS_db&&PL_SL_db>PL_DL_db
%     PL_NLOS_db = PL_SL_db;
% elseif PL_DL_db>PL_LOS_db&&PL_DL_db>PL_DL_db
%     PL_NLOS_db = PL_DL_db;
% end
shadowfading = normrnd(0,4.3);
switch speed
    case 5
        fastfading=6.0607224;
    case 10
        fastfading=5.4125104;
    case 15
        fastfading=6.1249886;
    case 20
        fastfading=3.0333443;
    otherwise
        fastfading=3.0706782;
end
PL_NLOS_db = 31.84+19*log10(fc)+21.5*log10(d)+shadowfading+fastfading;
PL_NLOS = 10^(-1*PL_NLOS_db/10);
%modulator = comm.PSKModulator;
for i_SNR=1:length(SNRdBs)
    SNRdB=SNRdBs(i_SNR);  sigma=sqrt(0.5/(10^(SNRdB/10)));

%         msg_symbol=randint(L_frame*b,NT);
     msg_symbol=randsrc(L_frame,NT,[0:3]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SISO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %SISO方案
     x1=pskmod(msg_symbol,4,pi/4); %编码
     n=sigma*(randn(L_frame,NT)+j*randn(L_frame,NT));%噪声
     h=(randn(L_frame,NT)+j*randn(L_frame,NT))/sqrt(2);%瑞利信道
     h=sqrt(PL_NLOS).*h;%瑞利衰落信道+室内工厂InF路径损耗模型
     y1=x1+n./h;%接收端信号
     x2=pskdemod(y1,M,pi/4);%解码
     [t,ber3(i_SNR)]=biterr(msg_symbol,x2,log2(M));%SISO方案的误码率

%%%%%%%%%%%%%%%%%%%%%%2×1STBC with IRS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     tx_bits=msg_symbol.';%转置
     tmp=[];   tmp1=[];
     for i=1:NT
         tmp1 = pskmod(tx_bits(i,:),M,pi/4);
         tmp=[tmp; tmp1];%tmp是两根天线的编码后的符号
     end
     X=tmp.'; X1=X; X2=[-conj(X(:,2)) conj(X(:,1))];%X(:,1)是第一根天线
%IRS反射单元数目设置为50
     HH=zeros(L_frame,NT);
     for n=1:NT
        for m=1:L_elements
            HH = HH+(randn(L_frame,NT)+j*randn(L_frame,NT)).*(randn(L_frame,NT)+j*randn(L_frame,NT));
            Hr(n,:,:)=sqrt(PL_NLOS).*HH/sq2;
            H=reshape(Hr(n,:,:),L_frame,NT);  
            Habs(:,n)=sum(abs(H).^2,2);
        end
     end
     R1 = sum(H.*X1,2)/sq_NT + sigma*(randn(L_frame,1)+j*randn(L_frame,1));
     R2 = sum(H.*X2,2)/sq_NT + sigma*(randn(L_frame,1)+j*randn(L_frame,1));
     R = [R1;R2];
     Z1 = R1.*conj(H(:,1)) + conj(R2).*H(:,2);
     Z2 = R1.*conj(H(:,2)) - conj(R2).*H(:,1);
     Z11 = Z1./(abs(H(:,1)).^2+abs(H(:,2)).^2);
     Z22 = Z2./(abs(H(:,1)).^2+abs(H(:,2)).^2);
        
     R11 = pskdemod(Z11,M,pi/4);
     R22 = pskdemod(Z22,M,pi/4);
     R_decode = [R11;R22];
        
     symbol_TX = reshape(msg_symbol,[2*L_frame,1]);
        
     [t,ber(i_SNR)]=biterr(symbol_TX,R_decode,log2(M));%2×1Alamouti编码方案with IRS的误码率

     SER = ber;

%%%%%%%%%%%%%%%%%%%%2×1STBC without IRS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %tx_bits=msg_symbol.';%转置
     tmp_withoutIRS=[];   tmp1_withoutIRS=[];
     for i=1:NT
         tmp1_withoutIRS = pskmod(tx_bits(i,:),M,pi/4);
         tmp_withoutIRS=[tmp_withoutIRS; tmp1_withoutIRS];%tmp是两根天线的编码后的符号
     end
     X_withoutIRS=tmp_withoutIRS.'; X1_withoutIRS=X_withoutIRS; X2_withoutIRS=[-conj(X_withoutIRS(:,2)) conj(X_withoutIRS(:,1))];%X_withoutIRS(:,1)是第一根天线
     for n=1:NT
         Hr_withoutIRS(n,:,:)=sqrt(PL_NLOS).*(randn(L_frame,NT)+j*randn(L_frame,NT))/sq2;
         H_withoutIRS=reshape(Hr_withoutIRS(n,:,:),L_frame,NT);  
         Habs_withoutIRS(:,n)=sum(abs(H_withoutIRS).^2,2);
     end
     R1_withoutIRS = sum(H_withoutIRS.*X1_withoutIRS,2)/sq_NT + sigma*(randn(L_frame,1)+j*randn(L_frame,1));
     R2_withoutIRS = sum(H_withoutIRS.*X2_withoutIRS,2)/sq_NT + sigma*(randn(L_frame,1)+j*randn(L_frame,1));
     R_withoutIRS = [R1_withoutIRS;R2_withoutIRS];
     Z1_withoutIRS = R1_withoutIRS.*conj(H_withoutIRS(:,1)) + conj(R2_withoutIRS).*H_withoutIRS(:,2);
     Z2_withoutIRS = R1_withoutIRS.*conj(H_withoutIRS(:,2)) - conj(R2_withoutIRS).*H_withoutIRS(:,1);
     Z11_withoutIRS = Z1_withoutIRS./(abs(H_withoutIRS(:,1)).^2+abs(H_withoutIRS(:,2)).^2);
     Z22_withoutIRS = Z2_withoutIRS./(abs(H_withoutIRS(:,1)).^2+abs(H_withoutIRS(:,2)).^2);
        
     R11_withoutIRS = pskdemod(Z11_withoutIRS,M,pi/4);
     R22_withoutIRS = pskdemod(Z22_withoutIRS,M,pi/4);
     R_decode_withoutIRS = [R11_withoutIRS;R22_withoutIRS];
        
     symbol_TX_withoutIRS = reshape(msg_symbol,[2*L_frame,1]);
        
     [t_withoutIRS,ber2(i_SNR)]=biterr(symbol_TX_withoutIRS,R_decode_withoutIRS,log2(M));%2×1Alamouti编码方案误码率

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end    % End of FOR loop for i_SNR

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%绘制BER vs SNR图%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xxx = -19:200;
yyy = 1e-6 * ones(1,220);
semilogy(P_dBm,ber3,'-k*',P_dBm,ber2,'-ko',P_dBm,ber,'-kd',xxx,yyy,'r'),axis([P_dBm([1 end]) 1e-7 1e0]);
grid on
legend('SISO方案','2×1STBC without IRS','2×1STBC with IRS','6个9可靠性标准线')
xlabel('发射功率(dBm)')
ylabel('误比特率(BER)')
hold on 
end