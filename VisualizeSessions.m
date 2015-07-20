% VISUALIZESESSIONS: This script plots the motion data stream and 
% color-codes the signals corresponding to each labelled gesture. It 
% will display all axes, unless otherwise

%% -------- GLOBAL VARIABLES -------- %%

    %file name
    DIRECTORY = 'motion-data';
    
    %file extension
    EXTENSION = '*.csv';
    
    %indicates whether to display all axes or the given axis (X, Y, or Z)
    DISPLAY_AXES = AxesConstants.ALL;
    
    %color which is reserved for signals with no labelled gestures
    NO_ACTIVITY_COLOR = [0.5 0.5 0.5];
    
    %% -------- LOAD DATA -------- %%
    
    %data directory
    dataDir = fullfile('..',DIRECTORY);
    
    [accelData, gyroData] = loadSensorData(dataDir, EXTENSION, 4);
    
    %% -------- GET SESSION LABELS -------- %%
    
    [sessionStart, sessionEnd, labels] = loadSessionLabels(dataDir, EXTENSION, 4);
    
    %% -------- SHIFT TIMESTAMPS -------- %%
    
    SHIFT = min(accelData(1,1), gyroData(1,1)); %starting time (min time b/w gyro/accel data files)
    accelData(:,1) = accelData(:,1) - SHIFT;
    gyroData(:,1) = gyroData(:,1) - SHIFT;
    sessionStart = sessionStart - SHIFT;
    sessionEnd = sessionEnd - SHIFT;
    
    %% -------- PRE-PROCESSING -------- %
    disp('Preprocessing data...');
    tic
    accelInterval = 20*10^6;
    resampledAccelData = linearInterpolate(accelData, accelInterval);
    preprocessedAccelData = EWMA(resampledAccelData, 0.05);
    
    gyroInterval = 12*10^6;
    resampledGyroData = linearInterpolate(gyroData, gyroInterval);
    preprocessedGyroData = EWMA(resampledGyroData, 0.05);
    toc
    
    %% -------- PLOT SESSION-LABELLED DATA -------- %%
    
    disp('Plotting session-labelled accelerometer data...');
    tic
    plotSessionData(preprocessedAccelData, sessionStart, sessionEnd, labels, NO_ACTIVITY_COLOR, DISPLAY_AXES, 'SameScale', 'Accelerometer');
    toc
    
    disp('Plotting session-labelled gyroscope data...');
    tic
    plotSessionData(preprocessedGyroData, sessionStart, sessionEnd, labels, NO_ACTIVITY_COLOR, DISPLAY_AXES, 'SameScale', 'Gyroscope');
    toc