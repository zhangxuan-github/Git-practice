function selected_mode = select_communication_mode()
options = {'随机通信模式选择', '基于业务需求的通信模式选择'};
[selected_idx, tf] = listdlg('PromptString', '选择通信模式:', ...
                             'SelectionMode', 'single', ...
                             'ListString', options);
if ~tf
    error('未选择通信模式！');
end
selected_mode = options{selected_idx};
end
