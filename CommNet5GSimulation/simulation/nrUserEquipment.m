classdef nrUserEquipment < handle
    properties
        id
        name
        % UE Position (latitude, longitude)
        position
        noiseFigure
        numTransmitAntennas
        transmitPower
        % Connection State (Idle(0)/Connected(1))
        connectionState
        gnbNodeId
        businessType
        priority
        sliceType
        mobilityModel
        RxAntTemperature

        modulation
        targetCodeRate

        % 仿真属性
        remainingBusinessVolume
        allocationRBNums                          % 某个时隙的分配的资源块
        allocationPower                           % 某个时隙的分配的功率
        transmitBits                              % 传输的比特数
        interference                              % 干扰
        sinr                                      % sinr，dB单位
        rate                                      % 速率
        delay
        throughput                                % 吞吐量(Mbps)
        maxThroughput                             % 最大吞吐量(%)
    end
    
    methods
        function obj = nrUserEquipment(varargin)
            % Constructor to initialize nrUserEquipment object using varargin
            % Syntax: obj = nrUserEquipment(id, name, position, noiseFigure, numTransmitAntennas, transmitPower, connectionState, gnbNodeId, businessType, priority, sliceType, mobilityModel)
            
            % Check if the number of input arguments is exactly 12
            if nargin ~= 14
                error('Exactly 14 input arguments are required.');
            end
            
            % Initialize properties based on input arguments
            obj.id = varargin{1};
            obj.name = varargin{2};
            obj.position = varargin{3};
            obj.noiseFigure = varargin{4};
            obj.numTransmitAntennas = varargin{5};
            obj.transmitPower = varargin{6};
            obj.connectionState = varargin{7};
            obj.gnbNodeId = varargin{8};
            obj.businessType = varargin{9};
            obj.priority = varargin{10};
            obj.sliceType = varargin{11};
            obj.mobilityModel = varargin{12};
            obj.modulation = varargin{13};
            obj.targetCodeRate = varargin{14};

            obj.RxAntTemperature = 290;  % UE的天线温度

            obj.remainingBusinessVolume = 0;
        end

        function res = checkRemainBusiness(obj)
            % 检查用户是否有剩余的业务未处理
            res = (obj.remainingBusinessVolume > 0);
        end

        function move(obj, dt)
            % 移动用户
            % Input：
            %   dt：时间间隔（单位s）

            % 移动用户
            [d_lat, d_lon] = obj.mobilityModel.calculateDisplacement(dt, obj.position{1});
            obj.position(1) = obj.position(1) + d_lat;
            obj.position(2) = obj.position(2) + d_lon;
        end


        function generateNewBusiness(obj)
            %TODO 这里会产生新的业务，后续可能是选择某个文件，得到该文件的大小，然后进行传输，这里暂时使用随机数代替
            obj.remainingBusinessVolume = randi([1000, 10000]);
        end

        function displaySimulationProperties(obj)
            fprintf('--- UE Simulation Properties for ID: %d (%s) ---\n', obj.id, obj.name);
            fprintf('  Remaining Business Volume: %.2f\n', obj.remainingBusinessVolume);
            fprintf('  Allocated Resource Blocks: %d\n', obj.allocationRBNums);
            fprintf('  Allocated Power: %.2f W\n', obj.allocationPower);
            fprintf('  Transmitted Bits: %d\n', obj.transmitBits);
            fprintf('  Interference: %.4e W\n', obj.interference); % 科学计数法显示干扰
            fprintf('  SINR: %.2f dB\n', obj.sinr);
            fprintf('  Rate: %.2f bps\n', obj.rate);
            fprintf('  Delay: %.4f s\n', obj.delay);
            fprintf('---------------------------------------------------\n');
        end

        function displayPerformanceInfo(obj)
            fprintf('--- UE%d (%s) 性能信息 ---\n', obj.id, obj.name);
            fprintf('  速率: %.2f bps\n', obj.rate);
            fprintf('  传输功率: %.2f W\n', obj.transmitPower);
            fprintf('  干扰: %.4e W\n', obj.interference); % 科学计数法显示干扰
            fprintf('  SINR: %.2f dB\n', obj.sinr);
            fprintf('  延迟: %.8f ms\n', obj.delay * 1000);
        end

        function displayAllocationInfo(obj)
            fprintf('--- UE%d (%s) 分配情况 ---\n', obj.id, obj.name);
            fprintf('  资源块数量: %d\n', obj.allocationRBNums);
            fprintf('  功率: %.2f W\n', obj.allocationPower);
        end


        function res = toString(obj)
            res = sprintf('UE %d (%s) at (%f, %f, %f)', obj.id, obj.name, obj.position(1), obj.position(2), obj.position(3));
        end


    end
end