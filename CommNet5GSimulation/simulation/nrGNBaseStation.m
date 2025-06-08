classdef nrGNBaseStation < handle
    properties
        id
        name
        position
        radius
        noiseFigure
        numTransmitAntennas
        transmitPower
        carrierFrequency
        channelBandwidth
        subcarrierSpacing
        numResourceBlocks
        connectedUEs

        useSliceMapping    % 使用切片映射，Map<sliceType, sliceObj>

        % 仿真属性
        allocationRBNums    
        allocationPower

        % 配置属性
        Carrier
    end
    
    methods
        function obj = nrGNBaseStation(varargin)
            if nargin ~= 12
                error('Exactly 12 input arguments are required.');
            end
            
            obj.id = varargin{1};
            obj.name = varargin{2};
            obj.position = varargin{3};
            obj.radius = varargin{4};
            obj.noiseFigure = varargin{5};
            obj.numTransmitAntennas = varargin{6};
            obj.transmitPower = varargin{7};
            obj.carrierFrequency = varargin{8};
            obj.channelBandwidth = varargin{9};
            obj.subcarrierSpacing = varargin{10};
            obj.numResourceBlocks = double(varargin{11});  % 强制转换为双精度

            obj.useSliceMapping = varargin{12};
            
            obj.connectedUEs = {};

            % 初始化，每次仿真都需要重新初始化
            obj.allocationRBNums = obj.numResourceBlocks;
            obj.allocationPower = obj.transmitPower;

            obj.Carrier = nrCarrierConfig;
            obj.Carrier.NSizeGrid = obj.numResourceBlocks;
            obj.Carrier.SubcarrierSpacing = obj.subcarrierSpacing / 1000;
            obj.Carrier.CyclicPrefix = 'Normal';  % 写死
        end

        function res = displayConnectedUE(obj, UEsMapping) %#ok<INUSD>
            % 显示当前基站连接的UE
            % 输入参数：
            %   obj：基站对象
            %   UEsMapping：UE与资源块的映射关系，Map<UEID, resourceBlockNum>
            % 输出参数：
            %   res：字符串，当前基站连接的UE信息
            res = '';
            for i = 1:length(obj.connectedUEs)
                res = [res sprintf('终端ID：%d  ', obj.connectedUEs{i})];
            end
            res = [res sprintf('总数：%d', length(obj.connectedUEs))];
        end

        function res = calculateConsumeRBNums(obj, bandwidth)
            % 计算基站消耗的RB数
            % 输入参数：
            %   obj：基站对象
            %   bandwidth：基站带宽
            % 输出参数：
            %   res：基站消耗的RB数
            res = ceil(bandwidth / (12 * obj.subcarrierSpacing));
        end

        function res = toString(obj)
            res = sprintf('Base Station %d (%s) at (%f, %f, %f)', obj.id, obj.name, obj.position(1), obj.position(2), obj.position(3));
        end

        % 判断当前基站是否与目标基站形成干扰
        function isInterfering = isInterferingWith(obj, targetBS)
            % 检查输入是否为有效基站对象
            if ~isa(targetBS, 'nrGNBaseStation')
                error('输入必须是nrGNBaseStation对象');
            end
            
            % 使用容差比较浮点数（解决浮点精度问题）
            tolerance = 1e-6;
            sameCarrierFreq = abs(obj.carrierFrequency - targetBS.carrierFrequency) < tolerance;
            sameBandwidth = abs(obj.channelBandwidth - targetBS.channelBandwidth) < tolerance;
            sameSCS = abs(obj.subcarrierSpacing - targetBS.subcarrierSpacing) < tolerance;
            
            % 当所有参数匹配时返回true
            isInterfering = sameCarrierFreq && sameBandwidth && sameSCS;
        end

        function res = isInConverage(position)
            % 判断当前位置是否在覆盖范围内
            % 输入参数：
            %   position：当前位置
            % 输出参数：
            %   res：布尔值，当前位置是否在覆盖范围内
            distance = tools.calculateHaversineDistance(position, obj.position);
            res = distance <= obj.radius;
        end
    end
    
    methods (Static)
        % 根据干扰条件对基站进行分组
        function interferenceGroups = groupByInterference(bsCellArray)
            % 验证输入是否为元胞数组
            if ~iscell(bsCellArray)
                error('输入必须是元胞数组');
            end
            
            % 验证所有元素都是nrGNBaseStation对象
            if ~all(cellfun(@(x) isa(x, 'nrGNBaseStation'), bsCellArray))
                error('元胞数组中所有元素必须是nrGNBaseStation对象');
            end
            
            n = numel(bsCellArray);
            groupID = zeros(1, n);  % 记录每个基站所属的组ID
            currentGroup = 0;       % 当前组ID计数器
            
            % 遍历所有基站
            for i = 1:n
                % 如果基站尚未分组
                if groupID(i) == 0
                    currentGroup = currentGroup + 1;  % 创建新组
                    groupID(i) = currentGroup;
                    
                    % 查找与当前基站有干扰关系的所有基站
                    for j = (i+1):n
                        if groupID(j) == 0 && bsCellArray{i}.isInterferingWith(bsCellArray{j})
                            groupID(j) = currentGroup;
                        end
                    end
                end
            end
            
            % 根据组ID创建分组
            interferenceGroups = cell(1, currentGroup);
            for k = 1:currentGroup
                interferenceGroups{k} = bsCellArray(groupID == k);
            end
        end
    end
end