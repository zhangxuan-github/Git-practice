
generateAPPConfig(1000);
generateUEConfig('NRFDDAPPConfigFile.xlsx', 'NRFDDRLCChannelConfig.xlsx');

function generateAPPConfig(NumUE)
    % 参数定义
    DataRates = [8000, 3000, 1500]; % 业务到达率
    PacketSize = 32; % 固定的包大小
    LCIDRange = [5, 20]; % LCID 范围
    HostDeviceRange = [0, 1]; % HostDevice 可能值

    % 初始化空表格
    ConfigData = table([], [], [], [], [], ...
        'VariableNames', {'DataRate', 'PacketSize', 'HostDevice', 'RNTI', 'LCID'});

    % 按行生成数据
    for i = 1:NumUE
        % 随机选择业务到达率
        dataRate = DataRates(randi(length(DataRates)));
        % 随机生成其他列数据
        packetSize = PacketSize;
        hostDevice = randi(HostDeviceRange);
        rnti = i; % RNTI 为当前行号
        lcid = randi(LCIDRange(2) - LCIDRange(1) + 1) - 1; % LCID 范围 0 到 20
        if lcid<1
            lcid=1;
        end

        % 添加到表格
        newRow = table(dataRate, packetSize, hostDevice, rnti, lcid, ...
            'VariableNames', {'DataRate', 'PacketSize', 'HostDevice', 'RNTI', 'LCID'});
        ConfigData = [ConfigData; newRow]; %#ok<AGROW> 
    end
     % 清空文件内容
    filename = 'NRFDDAPPConfigFile.xlsx';
    if exist(filename, 'file')
        delete(filename); % 删除现有文件
    end

    % 保存为 xlsx 文件
    writetable(ConfigData, filename);
    fprintf('配置文件已生成并保存为 %s\n', filename);
end

function generateUEConfig(configFilePath, outputFilePath)
    % 读取已有的配置文件
    ConfigData = readtable(configFilePath);

    % 参数定义
    LCGIDOptions = [1, 3, 5];
    SeqNumFieldLengthOptions = [6, 12];
    MaxTxBufferSDUsOptions = [2, 3, 5, 7];
    ReassemblyTimerOptions = [5, 10, 15];
    EntityTypeOptions = [0, 1, 2];
    PriorityMap = [3, 2, 1]; % 对应 DataRates [8000, 3000, 1500]
    PBROptions = [8, 16];
    BSDOptions = [5, 10, 20];

    % 初始化输出表格
    NumUE = height(ConfigData); % 从 ConfigFile 中获取行数
    UEConfigData = table([], [], [], [], [], [], [], [], [], [], ...
        'VariableNames', {'RNTI', 'LogicalChannelID', 'LCGID', 'SeqNumFieldLength', ...
                          'MaxTxBufferSDUs', 'ReassemblyTimer', 'EntityType', ...
                          'Priority', 'PBR', 'BSD'});

    for i = 1:NumUE
        % 提取 RNTI 和 LogicalChannelID
        RNTI = ConfigData.RNTI(i);
        LogicalChannelID = ConfigData.LCID(i);

        % 随机生成其他列数据
        LCGID = LCGIDOptions(randi(length(LCGIDOptions)));
        SeqNumFieldLength = SeqNumFieldLengthOptions(randi(length(SeqNumFieldLengthOptions)));
        MaxTxBufferSDUs = MaxTxBufferSDUsOptions(randi(length(MaxTxBufferSDUsOptions)));
        ReassemblyTimer = ReassemblyTimerOptions(randi(length(ReassemblyTimerOptions)));
        EntityType = EntityTypeOptions(randi(length(EntityTypeOptions)));

        % Priority 根据 DataRate 映射
        DataRate = ConfigData.DataRate(i);
        if DataRate == 8000
            Priority = PriorityMap(1);
        elseif DataRate == 3000
            Priority = PriorityMap(2);
        else
            Priority = PriorityMap(3);
        end

        % 随机生成 PBR 和 BSD
        PBR = PBROptions(randi(length(PBROptions)));
        BSD = BSDOptions(randi(length(BSDOptions)));

        % 添加到表格
        newRow = table(RNTI, LogicalChannelID, LCGID, SeqNumFieldLength, ...
                       MaxTxBufferSDUs, ReassemblyTimer, EntityType, ...
                       Priority, PBR, BSD);
        UEConfigData = [UEConfigData; newRow]; %#ok<AGROW>
    end

    % 清空文件内容
    if exist(outputFilePath, 'file')
        delete(outputFilePath); % 删除现有文件
    end

    % 保存生成的配置表为文件
    writetable(UEConfigData, outputFilePath);
    % 保存生成的配置表为文件
    writetable(UEConfigData, outputFilePath);
    fprintf('用户设备配置文件已生成并保存为 %s\n', outputFilePath);
end

