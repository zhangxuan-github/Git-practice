function [gNBs, gNBsMapping] = createNRGNB(gNBConfig)
    % Create a new nrGNBaseStation object with the given configuration.
    %
    %   gNBConfig - a structure containing the configuration parameters for the nrGNBaseStation object.
    %
    % Outputs:
    %   nrGNBaseStation - a new nrGNBaseStation object with the given configuration.
    %

    fprintf('Creating new nrGNBaseStation object...\n');
    gNBs = cell(1, length(gNBConfig));
    gNBsMapping = containers.Map('KeyType', 'double', 'ValueType', 'any');

    for i = 1:length(gNBConfig)
        gNBInfo = gNBConfig{i};
        sliceInfo = gNBInfo.slices;
        slices = containers.Map('KeyType', 'char', 'ValueType', 'any');
        for j = 1:length(sliceInfo)
            % TODO这里每一个用户最小的RB数为4，可以考虑是否修改
            slices(sliceInfo{j}.sliceType) = nrSlice(sliceInfo{j}.sliceType, sliceInfo{j}.qosLevel, sliceInfo{j}.resourceWeight, 4, ...
                            ceil(gNBInfo.numResourceBlocks * sliceInfo{j}.resourceWeight), tools.floorToDecimal(gNBInfo.transmitPower * sliceInfo{j}.resourceWeight, 4));
        end
        gNBs{i} = nrGNBaseStation(gNBInfo.id, gNBInfo.name, [gNBInfo.position.latitude, gNBInfo.position.longitude, gNBInfo.position.height], gNBInfo.radius, ...
                        gNBInfo.noiseFigure, gNBInfo.numTransmitAntennas, gNBInfo.transmitPower, gNBInfo.carrierFrequency, ...
                        gNBInfo.channelBandwidth, gNBInfo.subcarrierSpacing, gNBInfo.numResourceBlocks, slices);
        gNBsMapping(gNBInfo.id) = gNBs{i};
    end
    
end
