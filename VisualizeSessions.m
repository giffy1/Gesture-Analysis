% VISUALIZESESSIONS: This script plots the labelled motion data stream, 
% such that each labelled session is given a unique distinguishable color.
% The data is loaded from the ACCEL.csv and GYRO.csv files and the session
% labels are loaded from the REPORT.csv file, located in the motion-data 
% directory. The data is resampled and processed using an exponentially 
% weighted moving average.
%
% See also VISUALIZEGESTURES, PLOTDATA, DISTINGUISHABLE_COLORS,
% LOADSENSORDATA, LOADSESSIONLABELS, PREPROCESSDATA

%% -------- GLOBAL VARIABLES -------- %%

    %file name
    DIRECTORY = 'motion-data-test';
    
    %file extension
    EXTENSION = '*.csv';
    
    %indicates whether to display all axes or the given axis (X, Y, or Z)
    DISPLAY_AXES = AxesConstants.ALL;
    
    %color which is reserved for signals with no labelled gestures
    NO_ACTIVITY_COLOR = [0.5 0.5 0.5];
    
    interval = 20*10^6;
    
    %% -------- LOAD DATA -------- %%
    
    %data directory
    dataDir = fullfile('..',DIRECTORY);
    
    [accelData, gyroData] = loadSensorData(dataDir, EXTENSION, 1);
    
    %% -------- GET SESSION LABELS -------- %%
    
    [sessionStart, sessionEnd, labels] = loadSessionLabels(dataDir, EXTENSION, 1);
    
    %% -------- SHIFT TIMESTAMPS -------- %%
    
    SHIFT = min(accelData(1,1), gyroData(1,1)); %starting time (min time b/w gyro/accel data files)
    accelData(:,1) = accelData(:,1) - SHIFT;
    gyroData(:,1) = gyroData(:,1) - SHIFT;
    sessionStart = sessionStart - SHIFT;
    sessionEnd = sessionEnd - SHIFT;
    
    %% -------- PRE-PROCESSING -------- %
    
    preprocessedData = preprocessData(accelData, gyroData, interval, 0.05);
    
    %% -------- PLOT SESSION-LABELLED DATA -------- %%
    
    disp('Plotting session-labelled accelerometer data...');
    tic
    plotData(preprocessedData(:,1:4), sessionStart, sessionEnd, labels, NO_ACTIVITY_COLOR, DISPLAY_AXES, 'SameScale', 'Accelerometer');
    toc
    
    disp('Plotting session-labelled gyroscope data...');
    tic
    plotData(preprocessedData(:,[1,5:end]), sessionStart, sessionEnd, labels, NO_ACTIVITY_COLOR, DISPLAY_AXES, 'SameScale', 'Gyroscope');
    toc