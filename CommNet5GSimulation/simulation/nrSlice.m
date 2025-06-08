classdef nrSlice < handle
    properties
        % properties
        sliceType
        qosLevel
        bandwidthWeight
        maxConnectedUEsCount
        minUERBs                  % 分配的最小的资源块数
        % 仿真属性
        connectedUEsCount         % 已连接的用户数
        numResourceBlocks         % 资源块数
        power
    end
    
    methods
        function obj = nrSlice(varargin)
            if nargin ~= 6
                error('Exactly 6 input arguments are required.');
            end
            
            obj.sliceType = varargin{1};
            obj.qosLevel = varargin{2};
            obj.bandwidthWeight = varargin{3};
            obj.minUERBs = varargin{4};

            obj.maxConnectedUEsCount = varargin{5} / obj.minUERBs;
            obj.connectedUEsCount = 0;
            obj.numResourceBlocks =  varargin{5};
            obj.power = varargin{6};
        end

        function str = toString(obj)
            str = sprintf('切片类型: %s，QoS 等级: %d，带宽权重: %.2f，最小资源块数: %d，最大连接用户数: %d, 已连接用户数: %d\n', ...
                obj.sliceType, obj.qosLevel, obj.bandwidthWeight, obj.minUERBs, obj.maxConnectedUEsCount * obj.minUERBs, obj.connectedUEsCount);
        end
    end
end