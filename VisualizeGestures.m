% VISUALIZEGESTURES: This script plots the labelled motion data stream, 
% such that each labelled gesture is given a unique distinguishable color.
% The data is loaded from the ACCEL.csv and GYRO.csv files and the session
% labels are loaded from the REPORT.csv file, located in the motion-data
% directory. The gesture labels are loaded from a labels.txt file, located
% in the same directory. The data is resampled and processed using an 
% exponentially weighted moving average.
%
% See also VISUALIZESESSIONS, PLOTDATA, DISTINGUISHABLE_COLORS,
% LOADSENSORDATA, LOADSESSIONLABELS, PREPROCESSDATA

%% -------- GLOBAL VARIABLES -------- %%

    %file name
    DIRECTORY = 'motion-data-train';
    
    %file extension
    EXTENSION = '*.csv';
    
    %indicates whether to display all axes or the given axis (X, Y, or Z)
    DISPLAY_AXES = AxesConstants.ALL;
    
    %color which is reserved for signals with no labelled gestures
    NO_ACTIVITY_COLOR = [0.5 0.5 0.5];
    
    %indicates which data set we are interested in
    DATA_INDEX = 5;
    
    interval = 15*10^6;
    
    %% -------- LOAD FILES -------- %%
    
    %data directory
    dataDir = fullfile('..',DIRECTORY);
    
    [accelData, gyroData] = loadSensorData(dataDir, EXTENSION, DATA_INDEX);
    
    %% -------- GET SESSION LABELS -------- %%
    
    [sessionStart, sessionEnd, sessionLabels] = loadSessionLabels(dataDir, EXTENSION, DATA_INDEX);
    
    %% -------- SHIFT TIMESTAMPS -------- %%
    
    %gesture labels assume that sensor data starts at 0 and is in
    %nanoseconds, so shift the sensor data so that it starts at 0
    SHIFT = min(accelData(1,1), gyroData(1,1)); %starting time (min time b/w gyro/accel data files)
    accelData(:,1) = accelData(:,1) - SHIFT;
    gyroData(:,1) = gyroData(:,1) - SHIFT;
    sessionStart = sessionStart - SHIFT;
    sessionEnd = sessionEnd - SHIFT;
    
    %% -------- GET GESTURE LABELS -------- %%
    
    [S, E] = loadGestureLabels(dataDir, ['labels' num2str(DATA_INDEX) '.txt']);
    nGestures = length(S);
    gestureLabels = cell(nGestures, 1);
    
    %use session to get nominal label of gesture
    for i=1:nGestures,
        %find closest matching start time
        diffS = S(i)-sessionStart;
        diffS(diffS < 0) = nan; %exclude any start times following startT
        [~, minIdx] = nanmin(diffS); %index of closest matching start time < startT
        gestureLabels{i} = sessionLabels{minIdx};
    end
    
    %% -------- PRE-PROCESSING -------- %%
    
    preprocessedData = preprocessData(accelData, gyroData, interval, 0.05);
    
    %% -------- PLOT DATA -------- %%
    
    plotData(preprocessedData(:,1:4), S, E, cellstr(gestureLabels), NO_ACTIVITY_COLOR, DISPLAY_AXES, 'SameScale', 'Pre-processed Accelerometer Signal');
    plotData(preprocessedData(:,[1,5:end]), S, E, cellstr(gestureLabels), NO_ACTIVITY_COLOR, DISPLAY_AXES, 'SameScale', 'Pre-processed Gyroscope Signal');