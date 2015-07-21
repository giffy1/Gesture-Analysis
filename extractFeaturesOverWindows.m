function [ x, y ] = extractFeaturesOverWindows(timeSeriesData, windowDuration, windowStep, featureFunction, nFeatures, overlap_threshold, S, E, labels, otherLabel)
%EXTRACTFEATURES Extract features over a sliding window over time-series data
%
%   timeSeriesData: dataset where the first column specifies some temporal
%   markers (timestamps) and the remaining columns are data readings (i.e.
%   accelerometer, gyroscope)
%
%   windowDuration: the size of the sliding window in nanoseconds
%   windowStep: the shift of the window in nanoseconds
%
%   featureFunction: a handle to a function that computes features over a
%   window of the specified time-series data
%   nFeatures: the size of the feature vector returned by the feature
%   function
%
%   OPTIONAL:
%
%   overlap_threshold: the minimum percentage of overlap, between 0 and 1,
%   of the window and the ground truth gesture, for the window to be given
%   the label corresponding to that gesture.
%
%   S: the start times of the gestures
%   E: the end times of the gestures
%   labels: the textual labels corresponding to the gestures
%   other_label: a string reserved for windows where no labelled gesture is
%   present, usually 'other'
%
%   The function returns the feature matrix X and the label vector Y, which
%   can be used for training a classifier. Alternatively, if the optional
%   parameters regarding ground-truth labels are omitted, then ONLY X will
%   be computed, which will allow the user to make predictions using an
%   existing trained classifier.
%
%   See also COMPUTEFEATURES, COMPUTESTATISTICALFEATURES, 
%   COMPUTECOMBINEDFEATURES

    disp('Extracting features over windows...');
    tic

    startTime = 0;
    endTime = startTime + windowDuration;
    upperBound = timeSeriesData(end,1);
    
    nWindows = ceil((upperBound - windowDuration)/windowStep);
    x = zeros(nFeatures, nWindows);
    y = cell(nWindows, 1);
    
    windowIndex = 1;
    
    while endTime < upperBound,
        
        window = timeSeriesData(timeSeriesData(:,1) >= startTime ... 
            & timeSeriesData(:,1) <= endTime, 2:end);
        
        %extract basic features to start:
        
        x(:,windowIndex) = featureFunction(window);
        
        if nargin == 10,
            %find closest matching start time
            diffS = abs(S-startTime);
            [~, minIdx] = min(diffS);

            %label window if it contains most of the gesture
            labelStart = S(minIdx);
            labelEnd = E(minIdx);
            overlap = (min(labelEnd, endTime) - max(labelStart, startTime)) / (labelEnd - labelStart);
            if overlap < 0, overlap = 0; end
            if overlap >= overlap_threshold
                y{windowIndex} = labels{minIdx};
            else
                y{windowIndex} = otherLabel;
            end
        end
        
        %update window:
        startTime = startTime + windowStep;
        endTime = startTime + windowDuration;
        windowIndex = windowIndex + 1;
    end

    toc
end

