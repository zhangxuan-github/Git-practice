function [nUEs, nUEsMapping] = createNRUE(gUEConfig)
    % Create nrUserEquipment based on the given configuration
    
    fprintf('Creating new nrUEs object...\n');
    nUEs = cell(1, length(gUEConfig));
    nUEsMapping = containers.Map("KeyType", "double", "ValueType", "any");
    for i = 1:length(gUEConfig)
        ueInfo = gUEConfig{i};
        mobilityModel = nrMobilityModel(ueInfo.mobilityModel.speed, ueInfo.mobilityModel.direction);
        nUEs{i} = nrUserEquipment(ueInfo.id, ueInfo.name, [ueInfo.position.latitude, ueInfo.position.longitude, ueInfo.position.height], ueInfo.noiseFigure, ueInfo.numTransmitAntennas, ...
                        ueInfo.transmitPower, 0, NaN, ueInfo.businessType, ueInfo.priority, ...
                        ueInfo.sliceType, mobilityModel, "QPSK", 490/1024);
        nUEsMapping(ueInfo.id) = nUEs{i};
    end

end