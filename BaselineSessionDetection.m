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
    
    TRAINING_FILE_INDEX = [1 2 3 4];
    TEST_FILE_INDEX = 5;
    
    %file extension
    EXTENSION = '*.csv';
    
    %indicates whether to display all axes or the given axis (X, Y, or Z)
    DISPLAY_AXES = AxesConstants.X;
    
    %color which is reserved for signals with no labelled gestures
    NO_ACTIVITY_COLOR = [0.5 0.5 0.5];
    
    interval = 20*10^6; %re-sampling rate = 50Hz
    alpha = 0.05;
    
    loadParam = LocalDataConstants.SAVE_ALL;
    fileIndex = 3;
    
    %% -------- FEATURE EXTRACTION PARAMETERS -------- %%
    
    if loadParam == LocalDataConstants.LOAD_WINDOWS,
        load('data\windows\params.mat');
    else
        windowSize = 10^9 .* [2, 4, 6]; %(1*10^9:2*10^9:5*10^9);
        stepSize = 4*10^9;
        overlap_threshold = 0.5;
        featureFunction = @computeCombinedFeatures;
        nFeatures = 72;
    end
    
    %% -------- LOAD DATA -------- %%
    
    dataDir = fullfile('..',TRAINING_DIRECTORY);
    
    %empty to start:
    X = zeros(nFeatures,0);
    Y = zeros(0,1);
    
    for i=TRAINING_FILE_INDEX,
        [accelData, gyroData] = loadSensorData(dataDir, EXTENSION, i);
        save(['data/raw/accel/' num2str(i) '.mat'], 'accelData');
        save(['data/raw/gyro/' num2str(i) '.mat'], 'gyroData');

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

        preprocessedData = preprocessData(accelData, gyroData, interval, alpha);
        
        save(['data/preprocessed/train' num2str(i) '.mat'], 'preprocessedData', 'interval', 'alpha');

        %% -------- EXTRACT FEATURES OVER WINDOWS -------- %%

        [x, y] = extractFeaturesOverMultiscaleWindows(preprocessedData, windowSize, stepSize, ... 
            featureFunction, nFeatures, overlap_threshold, S, E, gestureLabels, 'other');
        
        X = [X x];
        Y = [Y; y];
        
        save(['data/windows/window' num2str(i) '.mat'], 'x', 'y', 'windowSize', ...
            'stepSize', 'featureFunction', 'nFeatures', 'overlap_threshold', 'S', 'E', ...
            'gestureLabels');
    end
    
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
    
    %% -------- GET GESTURE LABELS -------- %%

    [S, E] = loadGestureLabels(dataDir, ['labels' num2str(TEST_FILE_INDEX) '.txt']);

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
    
    preprocessedTestData = preprocessData(accelData, gyroData, interval, alpha);
    
    %% -------- EXTRACT FEATURES OVER WINDOWS -------- %%

    [xTest, yTest] = extractFeaturesOverMultiscaleWindows(preprocessedTestData, windowSize, ... 
        stepSize, featureFunction, nFeatures, overlap_threshold, S, E, gestureLabels, 'other');
    
    %% -------- TRAIN CLASSIFIER -------- %%

    disp('Training Random Forest classifier...');
    tic
    costMatrix = [0 25 30;
                  1 0 15;
                  1 15 0];
    %costMatrix = [0 40 50;
    %              1 0 40;
    %              1 1 0];
    nTrees = 200;
    %BEST RANDOM FOREST EXPLANATION EVER READ: 
    %http://stackoverflow.com/questions/18541923/what-is-out-of-bag-error-in-random-forests
    %in particular about the out-of-bag error
    %B = TreeBagger(nTrees, X', Y, 'OOBPred', 'On', 'Cost', costMatrix);
    B=fitensemble(X',Y,'Bag',nTrees,'Tree','type','classification','cost',costMatrix);
%    disp('Plotting classification error...');
%    oobErrorBaggedEnsemble = oobError(B);
%    figure
%    plot(oobErrorBaggedEnsemble);
%    xlabel('Number of grown trees');
%    ylabel('Out-of-bag classification error');
    toc
    
    %% -------- PREDICT GESTURES -------- %%
    
    disp('Evaluating classifier...');
    ypred = predict(B, xTest');
    
    accuracy = mean(cellfun(@strcmp, yTest, ypred));
    conf = confusionmat(yTest, ypred);
    precision=diag(conf)./sum(conf,2);
    recall=diag(conf)./sum(conf,1)';
    fscore = 2*precision.*recall./(precision+recall);
    avg_fscore = 2*mean(precision)*mean(recall)/(mean(precision)+mean(recall));
    
    fig_conf=figure;
    imshow(conf./length(yTest), 'InitialMagnification',10000);
    colormap(jet);
    hold on;
    text(-0.1,1,{'precision: ',round(precision*100,2)})
    text(-0.1,2,{'recall: ',round(recall*100,2)})
    text(-0.1,3,{'F-score: ',round(fscore*100,2)})
    hold off;
    
    %% -------- CLUSTER GESTURES & PLOT RESULTS -------- %%
    
    [~, colorSet, fig_data] = plotData(preprocessedTestData(:,[1,5:end]), S, E, gestureLabels, NO_ACTIVITY_COLOR, AxesConstants.X, 'SameScale', 'Pre-processed Gyroscope Signal');
    hold on
    
    for i=1:length(uniqueLabels),
        gestures = find(cellfun(cellfind(uniqueLabels{i}),ypred));
        if ~isempty(gestures),
            colorIndex = find(cellfun(cellfind(uniqueLabels{i}),uniqueSessionLabels));
            ylimits=ylim;
            plot(gestures*stepSize, ylimits(1), '*', 'Color', colorSet(colorIndex,:));
            hold on
            [f, xi] = ksdensity(gestures);
            density = (f.^2)/norm(f.^2);
            plot(xi*stepSize,0.9*ylimits(2)*density/max(density), 'Color', colorSet(colorIndex,:), 'LineWidth', 4); %multiple xi by #nanoseconds (because it's in #secs)
            hold on
        end
    end
    hold off

    %% -------- SAVE EVALUATION -------- %%
    if saveEval,
        saveas(fig_conf,['eval/eval' num2str(save_index) '_conf'],'fig');
        saveas(fig_data,['eval/eval' num2str(save_index) '_pred'],'fig');
        save(['eval/eval' num2str(save_index) '.mat'], 'TRAINING_DIRECTORY', 'TEST_DIRECTORY', 'TRAINING_FILE_INDEX', 'TEST_FILE_INDEX', 'interval', 'alpha', 'windowSize', 'stepSize', 'overlap_threshold', 'featureFunction', 'nFeatures', 'X', 'Y', 'S', 'E', 'gestureLabels', 'labels', 'xTest', 'yTest', 'B', 'costMatrix', 'nTrees', 'precision', 'recall', 'fscore', 'accuracy', 'conf');
    end
    
    %% Visualize False Negatives (EATING)
    %windows as false negatives for eating (FN)
    eatingOccurred = ismember(yTest, 'eating');
    eatingPredicted = ismember(ypred, 'eating');
    FN = eatingOccurred & ~eatingPredicted;
    FN_window_index=find(FN);
    for i = 1:min(10,length(FN_window_index)),
        FN_index=ceil(length(FN_window_index)*rand);
        start=FN_window_index(FN_index)*stepSize;
        stop=start+windowSize(end); % use largest window
        plotData(preprocessedTestData(preprocessedTestData(:,1)>=start&preprocessedTestData(:,1)<=stop,[1,5:end]), S, E, gestureLabels, NO_ACTIVITY_COLOR, AxesConstants.ALL, 'SameScale', 'False Negative')
    end
    %close all;
    
    %% Visualize False Positives (EATING)
    %windows as false positives for eating (FP)
    eatingOccurred = ismember(yTest, 'eating');
    eatingPredicted = ismember(ypred, 'eating');
    FP = ~eatingOccurred & eatingPredicted;
    FP_window_index=find(FP);
    for i = 1:min(10,length(FP_window_index)),
        FP_index=ceil(length(FP_window_index)*rand);
        start=FP_window_index(FP_index)*stepSize;
        stop=start+windowSize(end); % use largest window
        plotData(preprocessedTestData(preprocessedTestData(:,1)>=start&preprocessedTestData(:,1)<=stop,[1,5:end]), S, E, gestureLabels, NO_ACTIVITY_COLOR, AxesConstants.ALL, 'SameScale', 'False Positive')
    end
    %close all;
    
    %% Visualize True Positives (EATING)
    %windows correctly classified as eating (TP):
    eatingOccurred = ismember(yTest, 'eating');
    eatingPredicted = ismember(ypred, 'eating');
    TP = eatingOccurred & eatingPredicted;
    TP_window_index=find(TP);
    for i = 1:min(10,length(TP_window_index)),
        TP_index=ceil(length(TP_window_index)*rand);
        start=TP_window_index(TP_index)*stepSize;
        stop=start+windowSize(end); % use largest window
        plotData(preprocessedTestData(preprocessedTestData(:,1)>=start&preprocessedTestData(:,1)<=stop,[1,5:end]), S, E, gestureLabels, NO_ACTIVITY_COLOR, AxesConstants.ALL, 'SameScale', 'True Positives')
    end
    %close all;
    
    %% Visualize True Negatives (EATING)
    %windows correctly classified as not eating (TN):
    eatingOccurred = ismember(yTest, 'eating');
    eatingPredicted = ismember(ypred, 'eating');
    TN = ~eatingOccurred & ~eatingPredicted;
    TN_window_index=find(TN);
    for i = 1:min(10,length(TN_window_index)),
        TN_index=ceil(length(TN_window_index)*rand);
        start=TN_window_index(TN_index)*stepSize;
        stop=start+windowSize(end); % use largest window
        plotData(preprocessedTestData(preprocessedTestData(:,1)>=start&preprocessedTestData(:,1)<=stop,[1,5:end]), S, E, gestureLabels, NO_ACTIVITY_COLOR, AxesConstants.ALL, 'SameScale', 'True Negatives')
    end
    %close all;