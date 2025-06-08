function mode = multi_mode_algorithm(businessType, modes)
    % 根据业务类型选择通信模式
    switch businessType
        case 'PowerDataCollection'
            mode = modes.('Mode_5G');
        case 'DistributionAutomation'
            mode = modes.('Mode_HPLC');
        case 'RenewableControl'
            mode = modes.('Mode_HRF');
        otherwise
            error('UnknownServiceType');
    end
end


