classdef NetSimuEnv < handle
    % NetSimuEnv 网络仿真管理类
    % 用于管理整个网络仿真过程，包括用户连接、资源分配、移动和切换等
    
    properties
        verbose         % 是否显示调试信息
        area

        simulationTime            % 仿真时间
        allocationStrategy        % 资源分配策略

        gNBs
        gNBsMapping
        UEs
        UEsMapping

        distanceMapping
        interferenceGroup

        channelInfo
        pathLossModel
        pathLoss
        LOS

        lightSpeed   % 物理常数，光速

        transmitGlobalConfig     % 全局传输配置
    end
    
    methods
        function obj = NetSimuEnv(netSimuEnvConfig)
            obj.verbose = true;
            % 构造函数  
            obj.area = netSimuEnvConfig.area;
            obj.simulationTime = netSimuEnvConfig.simulationTime;
            obj.allocationStrategy = netSimuEnvConfig.allocationStrategy;

            obj.gNBs = netSimuEnvConfig.gNBs;
            obj.gNBsMapping = netSimuEnvConfig.gNBsMapping;
            obj.UEs = netSimuEnvConfig.UEs;
            obj.UEsMapping = netSimuEnvConfig.UEsMapping;

            obj.distanceMapping = netSimuEnvConfig.distanceMapping;
            obj.interferenceGroup = nrGNBaseStation.groupByInterference(obj.gNBs);

            obj.channelInfo = info(netSimuEnvConfig.channel);
            obj.pathLossModel = netSimuEnvConfig.pathLossModel;
            obj.pathLoss = netSimuEnvConfig.pathLoss;
            obj.LOS = netSimuEnvConfig.LOS;

            obj.lightSpeed = physconst('LightSpeed');

            obj.transmitGlobalConfig = struct();

            obj.setTransmitGlobalConfig(netSimuEnvConfig);
        end

        function setTransmitGlobalConfig(obj, netSimuEnvConfig)
            obj.transmitGlobalConfig.NFrames = netSimuEnvConfig.NFrames;
            obj.transmitGlobalConfig.DisplaySimulationInformation = netSimuEnvConfig.DisplaySimulationInformation;
            obj.transmitGlobalConfig.NumLayers = netSimuEnvConfig.NumLayers;
            obj.transmitGlobalConfig.NumHARQProcesses = netSimuEnvConfig.NumHARQProcesses;
            obj.transmitGlobalConfig.EnableHARQ = netSimuEnvConfig.EnableHARQ;
            obj.transmitGlobalConfig.LDPCDecodingAlgorithm = netSimuEnvConfig.LDPCDecodingAlgorithm;
            obj.transmitGlobalConfig.MaximumLDPCIterationCount = netSimuEnvConfig.MaximumLDPCIterationCount;
            obj.transmitGlobalConfig.DataType = netSimuEnvConfig.DataType;
            channelExtension = struct();
            channelExtension.DelayProfile = netSimuEnvConfig.channelExtension.DelayProfile;
            channelExtension.DelaySpread = netSimuEnvConfig.channelExtension.DelaySpread;
            channelExtension.MaximumDopplerShift = netSimuEnvConfig.channelExtension.MaximumDopplerShift;
            channelExtension.ChannelResponseOutput = netSimuEnvConfig.channelExtension.ChannelResponseOutput;
            obj.transmitGlobalConfig.channel = channelExtension;

        end

        function run(obj)
            fprintf('开始仿真...\n');
            % 运行仿真
            % totalTime: 总仿真时间

            % obj.openParallelPool();
            % tools.plotNetwork(obj.gNBs, obj.UEs);

            for t = 1:obj.simulationTime
                fprintf('当前仿真时间: %.2f\n', t);
                
                % 阶段1: 用户连接基站
                obj.lockResources();

                % 阶段2: 分配资源
                obj.allocationResources();
                
                % 阶段3: 统计数据，数据传输
                obj.statisticAndCalculatePerformance();

                % 阶段4: 用户移动
                obj.ueMobility();

            end

            % obj.closeParallelPool();

        end

        %% 进行数据传输



        function openParallelPool(obj)
            % 检查并启动并行池
            fprintf('正在检查或启动并行池...\n');
            currentPool = gcp('nocreate'); % 获取当前并行池对象，如果不存在则返回空
            if isempty(currentPool)
                parpool(4); % 启动默认数量的并行工作者
                fprintf('并行池已启动。\n');
            else
                fprintf('并行池已存在并活跃。\n');
            end
        end

        function closeParallelPool(obj)
            % 关闭并行池
            fprintf('正在关闭并行池...\n');
            delete(gcp('nocreate')); % 关闭当前活跃的并行池
            fprintf('并行池已关闭。\n');
        end


        %% 阶段4：用户移动
        function ueMobility(obj)

            for i = 1:length(obj.UEs)
                ueInfo = obj.UEs{i};
                ueInfo.move();

                % 进行移动之后，用户需要判断是否在这个小区的覆盖范围内
                if ~isnan(ueInfo.gnbNodeId)
                    gnbInfo = obj.gNBsMapping(ueInfo.gnbNodeId);
                    if ~gnbInfo.isInCoverage(ueInfo.position)
                        % 表示移动后没有在覆盖范围内，需要重新分配基站，分配在第一阶段
                        targetId = ueInfo.gnbNodeId;
                        for j = 1:length(gnbInfo.connectedUEs)
                            if gnbInfo.connectedUEs{j} == targetId
                                deleteIndex = j;
                            end
                        end
                        gnbInfo.connectedUEs(deleteIndex) = [];
                        ueInfo.gnbNodeId = NaN;
                        
                        fprintf('  用户%d移动后不在原基站%d覆盖范围内，需要重新分配\n', ueInfo.id, gnbInfo.id);
                    end
                end
                obj.updateDistanceMapping(ueInfo);
            end
        end

        function updateDistanceMapping(obj, ueInfo)
            % 更新距离映射

            ueId = ueInfo.id;
            
            % 获取内层Map
            innerMapping = obj.distanceMapping(ueId);

            % 遍历所有基站，计算距离
            for i = 1:length(obj.gNBs)
                gnbInfo = obj.gNBs{i};
                gnbId = gnbInfo.id;
                % 判断是否在基站的覆盖范围内
                if gnbInfo.isInCoverage(ueInfo.position)
                    % 计算距离
                    innerMapping(gnbId) = tools.calculateHaversineDistance(gnbInfo.position, ueInfo.position);
                else
                    % 基站不在覆盖范围内，距离设置为NaN
                    innerMapping(gnbId) = inf;
                end
            end

            % 更新外层Map
            obj.distanceMapping(ueId) = innerMapping;
        end

        %% 阶段3：统计数据，计算性能指标
        function statisticAndCalculatePerformance(obj)
            % 统计数据，需要获取基站的信息（载波），信道，路径损失，OFDM编码，距离，传播时延等
            % 干扰是指别的用户的信号造成的，所以首先遍历每一个用户，计算用户信号，并存储下来
            % 然后遍历所有基站，找到所有的干扰基站，计算里面所有基站的干扰，
            % 也就是说，基站发送的功率作为干扰的功率，然后别的路径损失等是按照目标用户的来计算

            % 计算每一个用户的相关指标
            % 包括干扰（存储），SINR，速率（香农公式）
            calculateUEPerformance(obj);

            % 数据传输 单位·bits
            [thoughputArray, maxThroughputArray, transmitSizeArray] = nrDownlinkTransmit(obj.gNBs, obj.UEs, obj.transmitGlobalConfig, obj.gNBsMapping);
            % 计算时延
            for i = 1:length(obj.UEs)
                ueInfo = obj.UEs{i};
                ueInfo.transmitBits = transmitSizeArray(i);
                ueInfo.throughput = thoughputArray(i);
                ueInfo.maxThroughput = maxThroughputArray(i);
                if ~isnan(ueInfo.gnbNodeId)
                    gnbInfo = obj.gNBsMapping(ueInfo.gnbNodeId);
                    % 计算时延
                    ueInfo.delay = obj.calculateUEDelay(ueInfo, gnbInfo);
                else
                    ueInfo.delay = 0;
                end
            end
            
            if obj.verbose == true
                for i = 1:length(obj.UEs)
                    obj.UEs{i}.displayPerformanceInfo();
                end
            end
        sa
        end

        function calculateUEPerformance(obj)
            % 计算每一个用户的信号，干扰，噪声
            for i = 1:length(obj.UEs)
                ueInfo = obj.UEs{i};
                if ~isnan(ueInfo.gnbNodeId)
                    gnbInfo = obj.gNBsMapping(ueInfo.gnbNodeId);
                    % 计算干扰
                    ueInfo.interference = obj.calculateUEInterference(ueInfo);
                    % 计算SINR
                    ueInfo.sinr = obj.calculateUESINR(ueInfo, gnbInfo, ueInfo.interference);
                    % 计算速率
                    ueInfo.rate = obj.calculateUERate(ueInfo, gnbInfo);
                else
                    ueInfo.interference = 0;
                    % 计算SINR
                    ueInfo.sinr = 0;
                    % 计算速率
                    ueInfo.rate = 0;
                end
            end
        end

        function delay = calculateUEDelay(obj, ueInfo, gnbInfo)
            % TODO 需要补充时延计算
            delay = 0;
            % 光传播的传播时延
            delay = delay + tools.calculateHaversineDistance(gnbInfo.position, ...
                            ueInfo.position) / obj.lightSpeed;
            % 传输时延
            delay = delay + double(ueInfo.transmitBits) / (ueInfo.rate);
            % 解码调制时延

            % 排队时延


        end

        function rate = calculateUERate(obj, ueInfo, gnbInfo)
            ueBandwidth = ueInfo.allocationRBNums * 12 * gnbInfo.subcarrierSpacing;

            epsilon = 1;  % 香农公式计算得到的是理论值，实际上可能需要乘一个系数
            sinr_linear = ueInfo.sinr;
            rate = double(epsilon * ueBandwidth * log2(1 + sinr_linear));  % 单位: bps

        end

        function sinr = calculateUESINR(obj, ueInfo, gnbInfo, interference)

            % 计算信号
            S = obj.calculateGNBTransmitSingal(gnbInfo, ueInfo);

            % 计算噪声
            waveformInfo = nrOFDMInfo(gnbInfo.Carrier);

            N_FFT = waveformInfo.Nfft;
            kBoltz = physconst('Boltzmann');    
            NF = 10^(ueInfo.noiseFigure/10);   
            Teq = double(ueInfo.RxAntTemperature + 290*(NF-1)); % K  
            N0 = sqrt(kBoltz*waveformInfo.SampleRate*Teq/2.0);

            N = 2 * (N0^2) * N_FFT;

            % 计算SINR
            sinr = 10 * log10(S / (N + interference));
        end

        function inteference = calculateUEInterference(obj, ueInfo)
            % 计算干扰
            % 遍历interferenceGroup，找到哪一组有干扰
            % 然后计算干扰
            inteference = 0;
            connectedGNB = obj.gNBsMapping(ueInfo.gnbNodeId);
            for i = 1:length(obj.interferenceGroup)
                group = obj.interferenceGroup{i};
                if tools.isMemberCell(connectedGNB, group)
                    % 计算组内其他用户的干扰
                    for j = 1:length(group)
                        if group{j} ~= connectedGNB
                            inteference = inteference + obj.calculateGNBTransmitSingal(group{j}, ueInfo);
                        end
                    end
                    break;
                end
            end
        end

        function pathLossDB = calculatePathLoss(obj, gnbInfo, ueInfo)
            % 计算路径损失，根据基站和用户
            if contains(obj.pathLossModel,'5G','IgnoreCase',true)
                % txPosition = [0;0; gnbInfo.position(3)];  % 这里需要基站的高度
                % % dtr = tools.calculateHaversineDistance(gnbInfo.position, ueInfo.position);          % 计算两者的距离
                % rxPosition = [dtr; zeros(size(dtr)); simParameters.RxHeight*ones(size(dtr))];
                [xGNBMeter, yGNBMeter] = tools.relativePositionInRectangle(obj.area.latitudeTopLeft, obj.area.longitudeTopLeft, ...
                            obj.area.latitudeBottomRight, obj.area.longitudeBottomRight, ...
                            gnbInfo.position(1), gnbInfo.position(2));
                gnbPosition = [xGNBMeter; yGNBMeter; gnbInfo.position(3)];
                [xUEMeter, yUEMeter] = tools.relativePositionInRectangle(obj.area.latitudeTopLeft, obj.area.longitudeTopLeft, ...
                            obj.area.latitudeBottomRight, obj.area.longitudeBottomRight, ...
                            ueInfo.position(1), ueInfo.position(2));
                uePosition = [xUEMeter; yUEMeter; ueInfo.position(3)];
                pathLossDB = nrPathLoss(obj.pathLoss, gnbInfo.carrierFrequency,...
                            obj.LOS, gnbPosition, uePosition);
            else % Free-space path loss
                lambda = physconst('LightSpeed')/gnbInfo.carrierFrequency;
                dtr = tools.calculateHaversineDistance(gnbInfo.position, ueInfo.position);
                pathLossDB = fspl(dtr,lambda);
            end
        end

        function S = calculateGNBTransmitSingal(obj, gnbInfo, ueInfo)
            % 根据基站和UE，返回发射的信号强度

            % 获取OFDM信息
            waveformInfo = nrOFDMInfo(gnbInfo.Carrier);
            pathLossDB = obj.calculatePathLoss(gnbInfo, ueInfo);

            P_Tr = double(10 ^ ((gnbInfo.transmitPower - 30) / 10));  % 将dBm转换为watt
            L = double(10 ^ (pathLossDB / 10));  % 将dB转换为watt
            N_FFT = double(waveformInfo.Nfft);
            N_grid_s = double(gnbInfo.numResourceBlocks);
            % 计算S
            S = (P_Tr / L) .* (N_FFT^2 / (12 * N_grid_s));
        end



        %% 阶段2：消耗释放资源
        function allocationResources(obj)
            % 在第一阶段，有分配带宽和功率，具体分配的多少是根据基站的allocationRBNums和allocationPower
            % 这两个分配都是按照最小的，我们需要将资源尽可能地使用，所以根据分配策略，来决定如何分配
            % 对于RR，也就是公平分配，RB就平均分配，功率也平均分配
            % 对于Priority，也就是优先级分配，RB和功率按照优先级分配，同时也要照顾低优先级的，所以按照优先级进行分配
            switch obj.allocationStrategy
                case 'RR'
                    % 公平分配
                    % 遍历所有基站，分配资源
                    roundRobinAllocation(obj);
                case 'Priority'
                    % 优先级分配
                    priorityAllocation(obj);
                
                otherwise
                    % 默认按照公平分配
                    roundRobinAllocation(obj);
            end
            if obj.verbose == true
                for i = 1:length(obj.UEs)
                    obj.UEs{i}.displayAllocationInfo();
                end
            end
        end



        function priorityAllocation(obj)
            % 优先级分配
            % 首先遍历所有基站，统计每个终端的优先级，然后把优先级作为权重，进行分配
            % 对于RB和Power，都会将优先级作为权重，返回两个Map（priority：RBs/Power）
            % 然后给每一个用户进行分配
            for i = 1:length(obj.gNBs)
                gNBInfo = obj.gNBs{i};
                obj.calculateAndAllocationResourceByPriority(gNBInfo);
            end
        end

        function ueSlicemapping = connectedUEGroupBySlices(obj, gNBInfo)
            % 根据用户的切片类型，把用户分组
            % 输入:
            %   gNBInfo - 包含基站信息
            %
            % 输出:
            %   ueSlicemapping - 包含sliceType:connectedUEId的映射

            % 初始化映射
            ueSlicemapping = containers.Map('KeyType', 'char', 'ValueType', 'any');

            for i = 1:length(gNBInfo.connectedUEs)
                ueId = gNBInfo.connectedUEs{i};
                ueInfo = obj.UEsMapping(ueId);
                if ~ueSlicemapping.isKey(ueInfo.sliceType)
                    ueSlicemapping(ueInfo.sliceType) = {ueId};
                else
                    ueSlicemapping(ueInfo.sliceType) = {ueSlicemapping(ueInfo.sliceType) ueId};
                end
            end

        end

        function [rBsMapping, powerMapping] = allocationResourceByPriority(obj, ueList, slice)
            % 根据用户的优先级为每个用户分配RBs和功率
            % 提取用户优先级
            numUsers = length(ueList);
            priorities = zeros(numUsers, 1);
            for i = 1:numUsers
                priorities(i) = obj.UEsMapping(ueList{i}).priority;
            end

            % 验证所有优先级是否为0
            if all(priorities == 0)
                % 如果所有优先级都为0，均匀分配RBs和功率
                rbWeights = ones(numUsers, 1) / numUsers;
                powerWeights = ones(numUsers, 1) / numUsers;
            else
                % 否则按优先级分配权重
                rbWeights = priorities / sum(priorities);
                powerWeights = priorities / sum(priorities);
            end

            % 分配资源
            for i = 1:numUsers
                user = obj.UEsMapping(ueList{i});
                priority = user.priority;
                allocatedRbs = round(slice.numResourceBlocks * rbWeights(i));
                allocatedPower = slice.power * powerWeights(i);

                % 如果当前优先级已存在于资源映射中，累加资源
                if rBsMapping.isKey(priority)
                    currentRbs = rBsMapping(priority);
                    rBsMapping(priority) = currentRbs + allocatedRbs;
                else
                    rBsMapping(priority) = allocatedRbs;
                end

                if powerMapping.isKey(priority)
                    currentPower = powerMapping(priority);
                    powerMapping(priority) = currentPower + allocatedPower;
                else
                    powerMapping(priority) = allocatedPower;
                end
            end
        end

        function calculateAndAllocationResourceByPriority(obj, gNBInfo)
            % allocateResourcesByPriority 根据用户的优先级为每个用户分配RBs和功率
            % 基站有切片，每一个切片都有分配的RBs和功率，也就是numResourceBlocks和power
            % 每一个用户连接了不同的切片，所以需要把每一个切片的用户统计起来，然后根据这些用户的优先级，来分配
            % 所以首先遍历基站，创建一个Map，sliceType：connectedUEId
            % 然后遍历基站的每一个切片，把所有的用户的优先级提取，然后进行分配
            % 最后返回一个优先级到资源分配的映射
            %
            % 输入:
            %   gNBInfo - 包含基站信息
            %
            % 输出:
            %   rBsMapping - 包含priority:RBS的映射
            %   powerMapping - 包含priority:Power的映射

            % 初始化资源映射
            rBsMapping = containers.Map('KeyType', 'double', 'ValueType', 'any');
            powerMapping = containers.Map('KeyType', 'double', 'ValueType', 'any');

            % 提取基站信息
            ueSliceMapping = obj.connectedUEGroupBySlices(gNBInfo);

            % 遍历切片列表
            sliceInfo = gNBInfo.useSliceMapping.values;
            for i = 1:length(sliceInfo)
                slice = sliceInfo{i};
                ueList = ueSliceMapping(slice.sliceType);
                % 根据切片和连接的用户，返回每一个用户应该分配多少资源
                [rBsMapping, powerMapping] = obj.allocationResourceByPriority(ueList, slice);
                % 对每一个用户进行分配
                for j = 1:length(ueList)
                    ueInfo = obj.UEsMapping(ueList{j});
                    ueInfo.allocationRBNums = rBsMapping(ueInfo.priority);
                    ueInfo.allocationPower = powerMapping(ueInfo.priority);
                end
            end
        end

        function roundRobinAllocation(obj)
            % 公平分配
            % 首先遍历所有基站，在每一个基站中，得到剩余的RBs，也就是NumRBs-allocationRBNums
            % 然后除以连接的用户数，取下值，给每一个用户分配
            % 然后会剩余几个RBs，数量小区用户数，所以随机分配给某个用户
            % 对于功率比较简单，得到剩余功率，也就是power-allocationPower
            % 然后除以连接的用户数，给每一个用户分配
            % gNBs = obj.gNBs;
            for i = 1:length(obj.gNBs)
                gNBInfo = obj.gNBs{i};
                roundRobinAllocationResource(obj, gNBInfo);
                % roundRobinAllocationRBs(obj, gNBInfo);
                % roundRobinAllocationPower(obj, gNBInfo);
            end
        end

        function roundRobinAllocationPower(obj, gNBInfo)
            % 公平分配功率

            allocationRemainingPower = gNBInfo.transmitPower - gNBInfo.allocationPower;
            % disp(gNBInfo.transmitPower);
            % disp(gNBInfo.allocationPower);
            % disp(allocationRemainingPower);
            % sa
            perUEPower = tools.floorToDecimal(allocationRemainingPower / length(gNBInfo.connectedUEs), 6);
            % 为每一个用户平均分配
            for i = 1:length(gNBInfo.connectedUEs)
                ueId = gNBInfo.connectedUEs{i};
                ueInfo = obj.UEsMapping(ueId);
                targetSlice = gNBInfo.useSliceMapping(ueInfo.sliceType);
                ueInfo.allocationPower = perUEPower + targetSlice.minPowerGuarantee;
            end
        end

        function roundRobinAllocationResource(obj, gNBInfo)
            % 公平分配RBs
            % 基站中的切片有连接的用户总数，有资源块的总数，所以只需要使用资源块数/用户数，向下取整就可以
            % 首先遍历基站的所有切片，然后创建一个Map，sliceType: RBs
            % 然后遍历基站的连接的用户，得到基站对象，然后设置分配的资源块数，allocationRBNums
            % 这里资源块的数据包括带宽和功率，带宽设置好了，就使用资源块来设置，功率使用资源块来均分
            % 基站中的切片也有power，表示分配的功率，所以也可以使用power/用户数
            % 所以创建两个Map
            rBsMapping = containers.Map('KeyType', 'char', 'ValueType', 'any');
            powerMapping = containers.Map('KeyType', 'char', 'ValueType', 'any');
            % 遍历切片列表
            sliceInfo = gNBInfo.useSliceMapping.values;
            for i = 1:length(sliceInfo)
                slice = sliceInfo{i};
                rBsMapping(slice.sliceType) = floor(slice.numResourceBlocks / slice.connectedUEsCount);
                powerMapping(slice.sliceType) = floor(slice.power / slice.connectedUEsCount);
            end
            % 遍历连接的用户，设置分配的资源块数
            for i = 1:length(gNBInfo.connectedUEs)
                ueId = gNBInfo.connectedUEs{i};
                ueInfo = obj.UEsMapping(ueId);
                ueInfo.allocationRBNums = rBsMapping(ueInfo.sliceType);
                ueInfo.allocationPower = powerMapping(ueInfo.sliceType);
            end
        end


        %% 阶段1: 用户连接基站，并分配资源
        function lockResources(obj)
            % 阶段1: 用户尝试连接基站
            % 遍历所有用户，判断是否可以连接到基站
            
            fprintf('执行阶段1: 用户连接基站\n');
            % 获取所有用户
            ues = obj.UEs;
            % 遍历所有用户
            for i = 1:length(ues)
                ue = ues{i};
                ueId = ue.id;
                % 判断该终端是否有业务需求
                if ~ue.checkRemainBusiness()
                    % 表示该用户没有剩余业务，则产生新的业务
                    ue.generateNewBusiness();
                    fprintf('  用户%d产生新业务， 业务量为%d\n', ueId, ue.remainingBusinessVolume);
                else
                    fprintf('  用户%d剩余业务量为%d\n', ueId, ue.remainingBusinessVolume);
                end

                % 从distanceMapping中，获取所有与该终端的基站距离，并且按照距离远近进行排序
                gNBsList = tools.getCoveredGnbsForUe(ueId, obj.distanceMapping, obj.gNBs);
                % 判断该终端是否有连接到基站
                if ~isnan(ue.gnbNodeId)
                    % 尝试连接到基站
                    gNBInfo = obj.gNBsMapping(ue.gnbNodeId);
                    access = obj.attemptGNBConnection(ue, gNBInfo);
                    if ~access
                        % 表示该用户无法连接到，尝试连接别的基站
                        access = obj.findAndConnectToGNB(ue, gNBsList, {gNBInfo.id});
                    end
                else
                    % 尝试连接别的基站
                    access = obj.findAndConnectToGNB(ue, gNBsList, {});
                end

                if ~access
                    fprintf('用户 %d 无法找到合适的基站连接\n', ue.id);
                else
                    fprintf('用户 %d 成功连接到基站 %d\n', ue.id, ue.gnbNodeId);
                end
            end

            if obj.verbose == true
                for i = 1:length(obj.gNBs)
                    gNBInfo = obj.gNBs{i};
                    fprintf('基站 %d 连接的用户: %s\n', gNBInfo.id, gNBInfo.displayConnectedUE());
                    sliceInfo = gNBInfo.useSliceMapping.values;
                    for j = 1:length(sliceInfo)
                        slice = sliceInfo{j};
                        fprintf("%s", slice.toString());
                    end
                end
                fprintf('\n');
            end
            
        end


        function access = findAndConnectToGNB(obj, ue, gNBsList, excludedGNBs)
            % 为用户寻找并连接到合适的小区
            % Input:
            %   ue: 用户对象
            %   gNBsList: 基站列表，元胞数组
            %   excludedGNBs: 连接过的基站id列表，元胞数组
            % Output:
            %   access: 是否成功连接到小区
            access = false;
            %TODO 切换次数+1
            

            for i = 1:length(gNBsList)
                gNBInfo = gNBsList{i};
                
                % 判断该基站是否已经尝试连接过了
                if ismember(cell2mat(excludedGNBs), gNBInfo.id)
                    continue;
                end

                % 尝试连接到这个基站
                if obj.attemptGNBConnection(ue, gNBInfo)
                    access = true;
                    break;
                else
                    excludedGNBs{end+1} = gNBInfo.id; %#ok<AGROW>
                end
            end
        end



        function access = checkBandwidthAvailability(obj, ue, gNBInfo, targetSlice)
            % 判断带宽是否可用
            % 每一个基站的切片都会有分配的资源块，以及连接的用户最大数，所以，只需要判断一下是否超过连接的最大数就可以connectedUEsCount
            % 如果大于这个切片的可连接最大数，maxConnectedUEsCount，则表示该切片的资源不足，不能接入
            % 否则，则表示该切片的资源足够，可以接入
            % Input:
            %   ue: 用户对象
            %   gNBInfo: 基站信息
            %   targetSlice: 目标切片
            % Output:
            %   access: 是否可用
            % 判断带宽能否接入
            access = true;
            if targetSlice.connectedUEsCount >= targetSlice.maxConnectedUEsCount
                % 表示该切片的资源不足，不能接入
                access = false;
            end
        end

        function access = checkPowerAvailability(obj, ue, gNBInfo, targetSlice)
            % 判断功率是否可用
            % Input:
            %   ue: 用户对象
            %   gNBInfo: 基站信息
            %   targetSlice: 目标切片
            % Output:
            %   access: 是否可用
            % 判断功率能否接入
            access = false;

            % 计算该用户的最小功率保证
            minPowerGuarantee = targetSlice.minPowerGuarantee;
            % 判断剩余功率能否满足分配
            if gNBInfo.allocationPower >= minPowerGuarantee
                % 表示功率可以分配
                access = true;
            end
        end

        function access = checkAndConsumeResources(obj, ue, gNBInfo, targetSlice, accessRBs, accessPower)
            % 检查资源是否可用并消耗
            % 如果带宽满足的话，则UE，基站和目标切片都需要记录，UE需要记录gnbNodeId，基站需要记录connectedUEs，切片需要记录connectedUEsCount
            % 具体的分配时等到第二个阶段进行分配
            % Input:
            %   ue: 用户对象
            %   gNBInfo: 基站信息
            %   targetSlice: 目标切片
            %   accessRBs: 是否有资源块可用
            %   accessPower: 是否有功率可用
            % Output:
            %   access: 是否成功接入
            % 尝试分配资源
            access = false;

            if accessRBs && accessPower
                % 更新终端与基站的连接信息
                ue.gnbNodeId = gNBInfo.id;
                gNBInfo.connectedUEs{end+1} = ue.id;
                targetSlice.connectedUEsCount = targetSlice.connectedUEsCount + 1;
                access = true;

                if obj.verbose == true
                    fprintf('  用户 %d 尝试连接到基站 %d，分配资源\n', ue.id, gNBInfo.id);
                end
            end
        end
        
        function access = attemptGNBConnection(obj, ue, gNBInfo)
            % 尝试将用户连接到指定基站，返回能否连接到基站
            % Input:
            %   ue: 用户对象
            %   gNBInfo: 基站信息
            % Output:
            %   access: 是否成功连接到基站
            
            % TODO 尝试连接次数+1

            % 判断该小区是否支持该切片
            if ~isKey(gNBInfo.useSliceMapping, ue.sliceType)
                % 表示该小区不支持这种切片，需要重写寻找小区连接
                access = false;
                return;
            end

            targetSlice = gNBInfo.useSliceMapping(ue.sliceType);
            
            % 判断该基站的带宽能否接入
            accessRBs = obj.checkBandwidthAvailability(ue, gNBInfo, targetSlice);

            % 判断该基站的功率能否接入
            % accessPower = obj.checkPowerAvailability(ue, gNBInfo, targetSlice);
            accessPower = true;

            % 根据判断结果，判断是否需要接入，以及消耗接入的资源
            access = obj.checkAndConsumeResources(ue, gNBInfo, targetSlice, accessRBs, accessPower);
        end
    end
end