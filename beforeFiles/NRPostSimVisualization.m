% Post-simulation visualization of logs using MAT files containing
% parameters used for simulation run and the logs of simulation. You can
% visualize logs of cell of intereset and also metrics of the UEs of interest
% in a cell

% Copyright 2020-2021 The MathWorks, Inc.

% Configuration
% parametersFile = 'simPara.mat'; 
parametersFile = 'simParameters.mat'; % Simulation parameters file name
simulationLogFile = 'simulationLogs.mat'; % Simulation logs file name
cellId = 1; % Cell id
% Flag to indicate the type of visualization
% For DL only (visualizationFlag = 0), UL only (visualizationFlag = 1), and
% both UL and DL (visualizationFlag = 2)
visualizationFlag = []; % Value as [] indicates that the visualization type is dynamically detected from the log file
% Set this flag to true for replay of simulation logs. Set this flag to
% false, to analyze the details of a particular frame or a particular slot
% of a frame. In the 'Resource Grid Allocation' window, input the frame
% number to visualize the scheduling assignment for the entire frame. The
% frame number entered here controls the frame number for 'Channel Quality
% Visualization' figure too.
isLogReplay = false;

% Validate the inputs
if ~isfile(parametersFile) % Check presence of simulation parameters file
    error('nr5g:NRPostSimVisualization:couldNotReadFile', 'Unable to read file %s . No such file or directory.', parametersFile);
end

if ~isfile(simulationLogFile) % Check presence of simulation log file
    error('nr5g:NRPostSimVisualization:couldNotReadFile', 'Unable to read file %s . No such file or directory.', simulationLogFile);
end

% Validate cell id
validateattributes(cellId, {'numeric'}, {'nonempty', 'integer', 'scalar', '>=', 0, '<=', 1007}, 'cellId');

% Read simulation parameters
simParameters = load(parametersFile).simParameters;

% Flag to enable or disable channel quality information (CQI) visualization
simParameters.CQIVisualization = true;
% Flag to enable or disable visualization of resource block (RB)
% assignment. If enabled, then for slot based scheduling it shows RB
% allocation to the UEs for different slots of the frame. For symbol
% based scheduling, it shows RB allocation to the UEs over different
% symbols of the slot.
simParameters.RBVisualization = true;

if isfield(simParameters, 'NCellIDList')
    numCells = numel(simParameters.NCellIDList);
    if ~ismember(cellId, simParameters.NCellIDList)
        error('nr5g:NRPostSimVisualization:InvalidCellId', 'Invalid cell id (%d).', cellId);
    end
    cellId = simParameters.CellOfInterest;
else
    numCells = 1;
    if isfield(simParameters, 'NCellID')
        if cellId ~= simParameters.NCellID
            error('nr5g:NRPostSimVisualization:InvalidCellId', 'Invalid cell id (%d).', cellId);
        end
    end
end

simParameters.CellOfInterest = cellId;
simParameters.NCellID = cellId;

count = 0;

% Read simulation log of cell of interest
simulationLogsInfo = load(simulationLogFile).simulationLogs;
for cellIdx = 1:numCells
    if isfield(simulationLogsInfo{cellIdx}, 'NCellID') && simulationLogsInfo{cellIdx}.NCellID == cellId
        break;
    end
end

logInfo = simulationLogsInfo{cellIdx};
if isempty(visualizationFlag)
    if isfield(logInfo, 'TimeStepLogs') || (isfield(logInfo, 'DLTimeStepLogs') && isfield(logInfo, 'ULTimeStepLogs'))
        visualizationFlag = 2; % Both UL & DL
    elseif isfield(logInfo, 'DLTimeStepLogs')
        visualizationFlag = 0; % Only DL
    else
        visualizationFlag = 1; % Only UL
    end
else
    % Validate visualization flag
    validateattributes(visualizationFlag, {'numeric'}, {'integer', 'scalar', '>=', 0, '<=', 2}, 'visualizationFlag');
end

% Check the visualization flag for TDD
if isfield(simParameters, 'DuplexMode') && simParameters.DuplexMode && visualizationFlag ~= 2
    error('nr5g:NRPostSimVisualization:InvalidFlag', 'Flag value must be 2 for TDD');
end

% Create metrics visualization object 
metricsVisualizer = hNRMetricsVisualizer(simParameters, 'VisualizationFlag', visualizationFlag, 'CellOfInterest', simParameters.CellOfInterest);

% Time step logs
if any(isfield(logInfo, {'TimeStepLogs', 'DLTimeStepLogs', 'ULTimeStepLogs'}))
    schedulingLogger = hNRSchedulingLogger(simParameters, visualizationFlag, isLogReplay);
    % Create an object for CQI, resource block grid visualization
    gridVisualizer = hNRGridVisualizer(simParameters, 'CellOfInterest', simParameters.CellOfInterest, 'MACLogger', schedulingLogger, 'VisualizationFlag', visualizationFlag, 'IsLogReplay', isLogReplay);
    if schedulingLogger.DuplexMode % For TDD
        schedulingLogger.SchedulingLog{1} = logInfo.TimeStepLogs(2:end, :); % MAC scheduling log
    else
        if visualizationFlag ~= 1 % Read downlink logs
            schedulingLogger.SchedulingLog{1} = logInfo.DLTimeStepLogs(2:end, :); % MAC DL scheduling log
        end

        if visualizationFlag ~= 0 % Read uplink logs
            schedulingLogger.SchedulingLog{2} = logInfo.ULTimeStepLogs(2:end, :); % MAC UL scheduling log
        end
    end
    % Add MAC metrics visualization
    addMACVisualization(metricsVisualizer, schedulingLogger);
end


% Radio link control (RLC) logs
if isfield(logInfo, 'RLCLogs')
    % Construct information for RLC logger
    lchInfo = repmat(struct('RNTI', [], 'LCID', [], 'EntityDir', []), [simParameters.NumUEs 1]);

    simParameters.NumUEs
    for ueIdx = 1:simParameters.NumUEs
        % Find the RLC entity direction from the RLC entity type. The entity
        % direction values 0, 1, and 2 indicates downlink only, uplink only,
        % and both, respectively. The RLC UM entities uses the same values for
        % entity type. But, RLC AM uses value 3 to indicate entity type. So, it
        % needs to be altered to 2 to represent its direction
        if isfield(simParameters, 'LCHConfig')
            if isscalar(simParameters.LCHConfig.LCID)
                lchInfo(ueIdx).LCID = simParameters.LCHConfig.LCID;
                lchInfo(ueIdx).EntityDir = simParameters.RLCConfig.EntityType;
            else
                lchInfo(ueIdx).LCID = simParameters.LCHConfig.LCID(ueIdx, :);
                lchInfo(ueIdx).EntityDir = simParameters.RLCConfig.EntityType(ueIdx, :);
            end
        else
            lchInfo(ueIdx).LCID = simParameters.RLCChannelConfig.LogicalChannelID(simParameters.RLCChannelConfig.RNTI == ueIdx);
            lchInfo(ueIdx).EntityDir = simParameters.RLCChannelConfig.EntityType(simParameters.RLCChannelConfig.RNTI == ueIdx);
        end
        lchInfo(ueIdx).RNTI = ueIdx;
    end
    simRLCLogger = hNRRLCLogger(simParameters, lchInfo);
    simRLCLogger.RLCStatsLog = logInfo.RLCLogs(2:end,:); % RLC log
    metricsVisualizer.LCHInfo = lchInfo;
    % Add RLC metrics visualization
    addRLCVisualization(metricsVisualizer, simRLCLogger);
end

% Physical layer (Phy) logs
if isfield(logInfo, 'BLERLogs')
    simPhyLogger = hNRPhyLogger(simParameters);
    simPhyLogger.BLERStatsLog = logInfo.BLERLogs(2:end,:); % BLER statistics log
    % Add Phy metrics visualization
    addPhyVisualization(metricsVisualizer, simPhyLogger)
end

% Plot the first frame
if ~isLogReplay
    showFrame(gridVisualizer, 0);
end

numSlotsFrame = (10 * simParameters.SCS)/ 15; % Number of slots in a 10 ms frame
simDuration = simParameters.NumFramesSim * numSlotsFrame; % In terms of number of slots
for slotNum = 1:simDuration % For each frame of simulation log
%     if any(isfield(logInfo, {'TimeStepLogs', 'DLTimeStepLogs', 'ULTimeStepLogs'}))
%         if isLogReplay
%             if isfield(simParameters, 'SchedulingType') && simParameters.SchedulingType
%                 % Symbol based scheduling
%                 plotPostSimRBGrids(gridVisualizer, slotNum); % Plot RB-assignment grid and RB-CQI grid
%             else
%                 % Slot based scheduling
%                 if ~mod(slotNum, numSlotsFrame) % Last slot of the frame
%                     plotPostSimRBGrids(gridVisualizer, slotNum); % Plot RB-assignment grid and RB-CQI grid
%                 end
%             end
%         end
%     end
    if mod(slotNum, simParameters.MetricsStepSize) == 0
        plotMetrics(metricsVisualizer, slotNum); % Plot metrics
    end
end
