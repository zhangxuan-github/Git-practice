function communication_mode_config()
    % 创建主界面窗口
    fig = figure('Position', [100, 100, 600, 450], 'Name', '通信模式配置', 'NumberTitle', 'off', 'Resize', 'off');

    % 通信模式单选框
    bg = uibuttongroup('Parent', fig, 'Title', '选择通信模式', 'FontSize', 12, ...
        'Position', [0.05, 0.7, 0.9, 0.2], 'SelectionChangedFcn', @update_mode_selection);
    uicontrol('Parent', bg, 'Style', 'radiobutton', 'String', '5G', ...
        'Position', [30, 30, 100, 30], 'Tag', '5G');
    uicontrol('Parent', bg, 'Style', 'radiobutton', 'String', 'HPLC', ...
        'Position', [180, 30, 100, 30], 'Tag', 'HPLC');
    uicontrol('Parent', bg, 'Style', 'radiobutton', 'String', 'HRF', ...
        'Position', [330, 30, 100, 30], 'Tag', 'HRF');

    % 信号频率选择
    uicontrol('Parent', fig, 'Style', 'text', 'String', '信号频率：', ...
        'Position', [30, 275, 80, 30], 'HorizontalAlignment', 'left');
    freqMenu = uicontrol('Parent', fig, 'Style', 'popupmenu', 'Position', [150, 280, 200, 25]);

    % 信道模型选择
    uicontrol('Parent', fig, 'Style', 'text', 'String', '信道模型：', ...
        'Position', [30, 225, 80, 30], 'HorizontalAlignment', 'left');
    channelMenu = uicontrol('Parent', fig, 'Style', 'popupmenu', 'Position', [150, 230, 200, 25]);

    % 配置参数：发射功率
    uicontrol('Parent', fig, 'Style', 'text', 'String', '发射功率 (dBm)：', ...
        'Position', [30, 175, 120, 30], 'HorizontalAlignment', 'left');
    powerInput = uicontrol('Parent', fig, 'Style', 'edit', 'Position', [150, 180, 200, 25], ...
        'String', '20');

    % 配置参数：带宽
    uicontrol('Parent', fig, 'Style', 'text', 'String', '带宽 (MHz)：', ...
        'Position', [30, 125, 120, 30], 'HorizontalAlignment', 'left');
    bandwidthMenu = uicontrol('Parent', fig, 'Style', 'popupmenu', ...
        'Position', [150, 130, 200, 25]);

    % 确定按钮
    okButton = uicontrol('Parent', fig, 'Style', 'pushbutton', 'String', '确定', ...
        'Position', [250, 20, 100, 40], 'FontSize', 12, ...
        'Callback', @submit_config);

    % 初始化选项
    update_mode_selection();

    % 更新通信模式对应的配置选项
    function update_mode_selection(~, event)
        if nargin < 2
            mode = '5G'; % 默认选择 5G
        else
            mode = event.NewValue.Tag;
        end

        % 信号频率、信道模型、发射功率、带宽配置项
        switch mode
            case '5G'
                freqMenu.String = {'Sub-6 GHz', 'mmWave', 'THz'};
                channelMenu.String = {'Urban Macro', 'Urban Micro', 'Indoor Office', 'Rural Macro'};
                powerInput.String = '20';
                bandwidthMenu.String = {'10', '20', '100', '400'};
            case 'HPLC'
                freqMenu.String = {'50-500 kHz', '2-30 MHz'};
                channelMenu.String = {'Multipath Reflection', 'Interference-Dominant', 'Frequency-Selective Fading'};
                powerInput.String = '10';
                bandwidthMenu.String = {'1', '2', '5'};
            case 'HRF'
                freqMenu.String = {'2.4 GHz', '5 GHz', '60 GHz'};
                channelMenu.String = {'Line-of-Sight (LoS)', 'Non-Line-of-Sight (NLoS)', 'Doppler Effect Model'};
                powerInput.String = '15';
                bandwidthMenu.String = {'20', '40', '80'};
        end
    end



    % 使用waitfor阻塞，直到用户点击“确定”
    waitfor(okButton, 'UserData', 1);  % 使用UserData作为信号

    % 确定配置并显示结果
    function submit_config(~, ~)
        mode = bg.SelectedObject.Tag;
        freq = freqMenu.String{freqMenu.Value};
        channel = channelMenu.String{channelMenu.Value};
        power = str2double(powerInput.String);
        bandwidth = bandwidthMenu.String{bandwidthMenu.Value};

        % fprintf('通信模式: %s\n', mode);
        % fprintf('信号频率: %s\n', freq);
        % fprintf('信道模型: %s\n', channel);
        % fprintf('发射功率: %.1f dBm\n', power);
        % fprintf('带宽: %s MHz\n', bandwidth);
        % 
        % msgbox(sprintf(['配置完成！\n通信模式: %s\n信号频率: %s\n信道模型: %s\n发射功率: %.1f dBm\n带宽: %s MHz'], ...
        %     mode, freq, channel, power, bandwidth), '配置完成');

        % 触发waitfor继续执行并关闭窗口
        okButton.UserData = 1;  % 设置UserData标志
        close(fig);  % 关闭窗口

    end


end

