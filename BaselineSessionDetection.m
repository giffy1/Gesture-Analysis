% BASELINESESSIONDETECTION: Baseline eating detection algorithm using a
% sliding window approach and a Random Forest classifier to detect
% infividual eating/drinking gestures, and a clustering approach to
% make session-level predictions.
%
%   See also COMPUTEFEATURES, EXTRACTFEATURESOVERWINDOWS, PREPROCESSDATA

%TODO: The overlap threshold should not be in terms of how much of the
%ground truth is covered by the window, but how much of the window is
%covered by the ground truth. This will be helpful when adding gesture
%training data for confounding actions like brushing teeth and talking on
%the phone, where the gestures may just be the entire session itself. BUT
%the confounding part is the hand-to-mouth/face movement, so it mgiht still
%work as is...?

    %% -------- GLOBAL VARIABLES -------- %%

    TRAINING_DIRECTORY = 'motion-data-train';
    TEST_DIRECTORY = 'motion-data-train';
    
    TRAINING_FILE_INDEX = [5 2 3 4];
    TEST_FILE_INDEX = 1;
    
    %file extension
    EXTENSION = '*.csv';
    
    %indicates whether to display all axes or the given axis (X, Y, or Z)
    DISPLAY_AXES = AxesConstants.X;
    
    %color which is reserved for signals with no labelled gestures
    NO_ACTIVITY_COLOR = [0.5 0.5 0.5];
    
    interval = 20*10^6;
    
    %% -------- FEATURE EXTRACTION PARAMETERS -------- %%
    
    windowSize = 5.8*10^9;
    stepSize = 1*10^9;
    overlap_threshold = 0.75;
    featureFunction = @computeFeatures;
    nFeatures = 36;
    
    %% -------- LOAD DATA -------- %%
    
    dataDir = fullfile('..',TRAINING_DIRECTORY);
    
    %empty to start:
    X = zeros(36,0);
    Y = zeros(0,1);
    
    for i=TRAINING_FILE_INDEX, %TODO don't hardcode 3
        [accelData, gyroData] = loadSensorData(dataDir, EXTENSION, i);

        %% -------- GET SESSION LABELS -------- %%

        [sessionStart, ~, sessionLabels] = loadSessionLabels(dataDir, EXTENSION, i);
        uniqueLabels = unique(sessionLabels); %should be in alphabetical order

        %% -------- SHIFT TIMESTAMPS -------- %%

        SHIFT = min(accelData(1,1), gyroData(1,1)); %starting time (min time b/w gyro/accel data files)
        accelData(:,1) = accelData(:,1) - SHIFT;
        gyroData(:,1) = gyroData(:,1) - SHIFT;
        sessionStart = sessionStart - SHIFT;
        
        %% -------- GET GESTURE LABELS -------- %%

        [S, E] = loadGestureLabels(dataDir, ['labels' num2str(i) '.txt']);

        nGestures = length(S);
        gestureLabels = cell(nGestures, 1);
        labels = zeros(nGestures,1); %values corresponding to the labels

        %http://www.mathworks.com/matlabcentral/answers/2015-find-index-of-cells-containing-my-string
        cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));

        for j=1:nGestures,
            %find closest matching start time
            diffS = S(j)-sessionStart;
            diffS(diffS < 0) = nan; %exclude any start times following startT
            [~, minIdx] = nanmin(diffS); %index of closest matching start time < startT
            gestureLabels{j} = sessionLabels{minIdx};
            labels(j) = find(cellfun(cellfind(gestureLabels{j}),uniqueLabels));
        end

        %% -------- PRE-PROCESSING -------- %%

        preprocessedData = preprocessData(accelData, gyroData, interval, 0.05);

        %% -------- EXTRACT FEATURES OVER WINDOWS -------- %%

        [x, y] = extractFeaturesOverWindows(preprocessedData, windowSize, stepSize, ... 
            featureFunction, nFeatures, overlap_threshold, S, E, gestureLabels, 'other');
        
        X = [X x];
        Y = [Y; y];
    end
    
    %% -------- TRAIN CLASSIFIER -------- %%

    disp('Training Random Forest classifier...');
    tic
    costMatrix = [0 1 2;
                  1 0 1
                  1 3 0];
    nTrees = 100;
    %BEST RANDOM FOREST EXPLANATION EVER READ: 
    %http://stackoverflow.com/questions/18541923/what-is-out-of-bag-error-in-random-forests
    %in particular about the out-of-bag error
    B = TreeBagger(nTrees, X', Y, 'OOBPred', 'On'); %, 'Cost', costMatrix);
    disp('Plotting classification error...');
    oobErrorBaggedEnsemble = oobError(B);
    figure
    plot(oobErrorBaggedEnsemble);
    xlabel('Number of grown trees');
    ylabel('Out-of-bag classification error');
    toc
    
    %% -------- TEST ON OTHER DATA -------- %%
    
    %% -------- LOAD DATA -------- %%
    
    dataDir = fullfile('..',TEST_DIRECTORY);
    [accelData, gyroData] = loadSensorData(dataDir, EXTENSION, TEST_FILE_INDEX);
    
    %% -------- GET SESSION LABELS -------- %%
    
    [sessionStart, sessionEnd, sessionLabels] = loadSessionLabels(dataDir, EXTENSION, TEST_FILE_INDEX);
    uniqueSessionLabels = unique(sessionLabels);
    
    %% -------- SHIFT TIMESTAMPS -------- %%
    
    SHIFT = min(accelData(1,1), gyroData(1,1)); %starting time (min time b/w gyro/accel data files)
    accelData(:,1) = accelData(:,1) - SHIFT;
    gyroData(:,1) = gyroData(:,1) - SHIFT;
    sessionStart = sessionStart - SHIFT;
    sessionEnd = sessionEnd - SHIFT;
    
    %% -------- PRE-PROCESSING -------- %%
    
    preprocessedTestData = preprocessData(accelData, gyroData, interval, 0.05);
    
    %% -------- EXTRACT FEATURES OVER WINDOWS -------- %%

    [xTest, ~] = extractFeaturesOverWindows(preprocessedTestData, windowSize, stepSize, featureFunction, nFeatures);
    
    %% -------- PREDICT GESTURES -------- %%
    
    disp('Evaluating classifier...');
    ypred = predict(B, xTest');
    
    %% -------- CLUSTER GESTURES & PLOT RESULTS -------- %%
    
    [~, colorSet] = plotData(preprocessedTestData(:,5:end), sessionStart, sessionEnd, sessionLabels, NO_ACTIVITY_COLOR, AxesConstants.X, 'SameScale', 'Pre-processed Accelerometer Signal');
    hold on
    
    for i=1:length(uniqueLabels),
        gestures = find(cellfun(cellfind(uniqueLabels{i}),ypred));
        if ~isempty(gestures),
            colorIndex = find(cellfun(cellfind(uniqueLabels{i}),uniqueSessionLabels));
            ylimits=ylim;
            plot(gestures*10^9, ylimits(1), '*', 'Color', colorSet(colorIndex,:));
            hold on
            [f, xi] = ksdensity(gestures);
            density = (f.^2)/norm(f.^2);
            plot(xi*10^9,0.9*ylimits(2)*density/max(density), 'Color', colorSet(colorIndex,:), 'LineWidth', 4); %multiple xi by #nanoseconds (because it's in #secs)
            hold on
        end
    end
    hold off
    