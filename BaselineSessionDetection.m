% BASELINESESSIONDETECTION: Baseline eating detection algorithm.

%% -------- GLOBAL VARIABLES -------- %%

    %file name
    DIRECTORY = 'motion-data-indiv';
    
    %file extension
    EXTENSION = '*.csv';
    
    %indicates whether to display all axes or the given axis (X, Y, or Z)
    DISPLAY_AXES = AxesConstants.X;
    
    %color which is reserved for signals with no labelled gestures
    NO_ACTIVITY_COLOR = [0.5 0.5 0.5];
    
    %% -------- LOAD DATA -------- %%
    
    dataDir = fullfile('..',DIRECTORY);
    
    [accelData, gyroData] = loadSensorData(dataDir, EXTENSION, []);
    
    %% -------- GET SESSION LABELS -------- %%
    
    [sessionStart, sessionEnd, sessionLabels] = loadSessionLabels(dataDir, EXTENSION, []);
    uniqueLabels = unique(sessionLabels); %should be in alphabetical order
    
    %% -------- SHIFT TIMESTAMPS -------- %%
    
    SHIFT = min(accelData(1,1), gyroData(1,1)); %starting time (min time b/w gyro/accel data files)
    accelData(:,1) = accelData(:,1) - SHIFT;
    gyroData(:,1) = gyroData(:,1) - SHIFT;
    sessionStart = sessionStart - SHIFT;
    sessionEnd = sessionEnd - SHIFT;
    
    %% -------- GET GESTURE LABELS -------- %%
    
    VIDEO_START = 1436747631000;
    SENSOR_START = 1436747582500;
    
    [S, E] = loadGestureLabels(dataDir, 'labels.txt');
    S = (S + VIDEO_START - SENSOR_START)*10^6;
    E = (E + VIDEO_START - SENSOR_START)*10^6;
    
    nGestures = length(S);
    gestureLabels = cell(nGestures, 1);
    labels = zeros(nGestures,1); %values corresponding to the labels
    
    %http://www.mathworks.com/matlabcentral/answers/2015-find-index-of-cells-containing-my-string
    cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
    
    for i=1:nGestures,
        %find closest matching start time
        diffS = S(i)-sessionStart;
        diffS(diffS < 0) = nan; %exclude any start times following startT
        [~, minIdx] = nanmin(diffS); %index of closest matching start time < startT
        gestureLabels{i} = sessionLabels{minIdx};
        labels(i) = find(cellfun(cellfind(gestureLabels{i}),uniqueLabels));
    end
    %after this point, uniqueLabels(Y) should give gestureLabels
    
    %% -------- PRE-PROCESSING -------- %%
    
    disp('Pre-processing data...');
    
    tic
    
    accelInterval = 20*10^6;
    resampledAccelData = linearInterpolate(accelData, accelInterval);
    preprocessedAccelData = EWMA(resampledAccelData, 0.05);
    
    gyroInterval = 12*10^6;
    resampledGyroData = linearInterpolate(gyroData, gyroInterval);
    preprocessedGyroData = EWMA(resampledGyroData, 0.05);
    
    toc
    
    %% -------- EXTRACT FEATURES OVER WINDOWS -------- %%

    startTime = 0;
    duration = 5*10^9; %5 sec (in nanoseconds)
    endTime = startTime + duration;
    upperBound = min(preprocessedAccelData(end,1), preprocessedGyroData(end,1));
    step = 1*10^9; %1 sec (in ns)
    
    OVERLAP_THRESHOLD = 0.65;
    
    nFeatures = 12; %3 axis mean/std dev for both sensors
    nWindows = ceil((upperBound - duration)/step);
    x = zeros(nFeatures, nWindows);
    y = zeros(nWindows, 1);
    
    windowIndex = 1;
    
    while endTime < upperBound,
        
        accelWindow = preprocessedAccelData(preprocessedAccelData(:,1) >= startTime ... 
            & preprocessedAccelData(:,1) <= endTime, 2:4);
        
        gyroWindow = preprocessedGyroData(preprocessedGyroData(:,1) >= startTime ... 
            & preprocessedGyroData(:,1) <= endTime, 2:4);
        
        %extract basic features to start:
        
        accelMean = mean(accelWindow,1);
        gyroMean = mean(gyroWindow,1);
        
        accelStd = std(accelWindow,1);
        gyroStd = std(gyroWindow,1);
        
        x(:,windowIndex) = [accelMean'; gyroMean'; accelStd'; gyroStd'];
        
        %find closest matching start time
        diffS = abs(S-startTime);
        [~, minIdx] = min(diffS);
         
        %label window if it contains most of the gesture
        labelStart = S(minIdx);
        labelEnd = E(minIdx);
        overlap = (min(labelEnd, endTime) - max(labelStart, startTime)) / (labelEnd - labelStart);
        if overlap < 0, overlap = 0; end
        if overlap >= OVERLAP_THRESHOLD && labels(minIdx) == 2
            y(windowIndex) = 1;
        else
            y(windowIndex) = -1; %no labelled gesture
        end
        
        %update window:
        startTime = startTime + step;
        endTime = startTime + duration;
        windowIndex = windowIndex + 1;
    end
    
    disp('Training SVM classifier...');
    tic
    lambda = 0.1;
    [w, b, ~] = vl_svmtrain(x, y, lambda, 'MaxNumIterations', 100000);
    toc
    
    %% -------- TEST ON OTHER DATA -------- %%
    
    %file name
    DIRECTORY = 'motion-data';
    
    %file extension
    EXTENSION = '*.csv';
    
    %% -------- LOAD DATA -------- %%
    
    dataDir = fullfile('..',DIRECTORY);
    
    [accelData, gyroData] = loadSensorData(dataDir, EXTENSION, 3);
    
    %% -------- GET SESSION LABELS -------- %%
    
    [sessionStart, sessionEnd, sessionLabels] = loadSessionLabels(dataDir, EXTENSION, 2);
    uniqueLabels = unique(sessionLabels); %should be in alphabetical order
    nSessionLabels = length(uniqueLabels);
    
    %% -------- SHIFT TIMESTAMPS -------- %%
    
    SHIFT = min(accelData(1,1), gyroData(1,1)); %starting time (min time b/w gyro/accel data files)
    accelData(:,1) = accelData(:,1) - SHIFT;
    gyroData(:,1) = gyroData(:,1) - SHIFT;
    sessionStart = sessionStart - SHIFT;
    sessionEnd = sessionEnd - SHIFT;
    
    %% -------- PRE-PROCESSING -------- %%
    
    disp('Pre-processing test data...');
    
    tic
    
    resampledAccelData = linearInterpolate(accelData, accelInterval);
    preprocessedAccelData = EWMA(resampledAccelData, 0.05);
    
    resampledGyroData = linearInterpolate(gyroData, gyroInterval);
    preprocessedGyroData = EWMA(resampledGyroData, 0.05);
    
    toc
    
    %% -------- EXTRACT FEATURES OVER WINDOWS -------- %%

    startTime = 0;
    endTime = startTime + duration;
    upperBound = min(preprocessedAccelData(end,1), preprocessedGyroData(end,1));
    
    nWindows = ceil((upperBound - duration)/step);
    x = zeros(nFeatures, nWindows);
    
    windowIndex = 1;
    
    disp('Extracting features on sliding window...');
    tic
    while endTime < upperBound,
        
        accelWindow = preprocessedAccelData(preprocessedAccelData(:,1) >= startTime ... 
            & preprocessedAccelData(:,1) <= endTime, 2:4);
        
        gyroWindow = preprocessedGyroData(preprocessedGyroData(:,1) >= startTime ... 
            & preprocessedGyroData(:,1) <= endTime, 2:4);
        
        %extract basic features to start:
        
        accelMean = mean(accelWindow,1);
        gyroMean = mean(gyroWindow,1);
        
        accelStd = std(accelWindow,1);
        gyroStd = std(gyroWindow,1);
        
        x(:,windowIndex) = [accelMean'; gyroMean'; accelStd'; gyroStd'];
        
        %update window:
        startTime = startTime + step;
        endTime = startTime + duration;
        windowIndex = windowIndex + 1;
    end
    toc %takes about 4.5 min on session 1 (~5.5 hours of data)
    
    disp('Evaluating classifier...');
    ypred = w'*x+b;
    yval = ypred > 0;
    gestures = find(yval);
    
    plotSessionData(preprocessedAccelData, S, E, cellstr(gestureLabels), NO_ACTIVITY_COLOR, DISPLAY_AXES, 'SameScale', 'Pre-processed Accelerometer Signal');
    [f, xi] = ksdensity(gestures);
    hold on
    %plot(xi*10^9,(f.^2)*10^6); %multiple xi by #nanoseconds (because it's in #secs)
    plot(gestures*10^9, 0, '*');
    