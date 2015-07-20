function [ x, y ] = extractFeaturesOverWindows(timeSeriesData, windowDuration, windowStep, featureFunction, nFeatures, overlap_threshold, S, E, labels, otherLabel)
%EXTRACTFEATURES Extract features over a sliding window over the
%time-series data
%   The data provided must be time-series data, where the first column
%   represents the timestamp and the remaining columns represent the data
%   values. It is good practice to first interpolate the data so that the
%   timestamps are equally spaced. The sliding window is defined by the
%   windowDuration and windowStep parameters. The windowDuration is length
%   of the window in nanoseconds. This means the number of samples may
%   vary. The windowStep parameter defines how much the window slides, and
%   is also given in nanoseconds. The featureFunction defines how features
%   will be computed. This is a handle to another function. The number of
%   features must also be specified, but if this is not known, it can be
%   set to 0. The remaining features are optional: They may be provided if
%   the user wishes to train a classifier and therefore must label these
%   labels accordingly. The S and E parameters define the start and end
%   times in nanoseconds of the gestures/activities of interest and the
%   labels parameter is a cell array providing the nominal classes
%   corresponding to these intervals. Any window that contains at least
%   overlap_threshold percentage of the ground truth activity will be
%   labelled with that activity; otherwise, it will be labelled as 'other'
%   or 'none, etc.' (whatever is specified by the otherLabel parameter). If
%   the user decides not to provide these parameters, then y will be full
%   of zeros and should not be used! Leaving out ANY parameter will
%   indicate that the windows are not used for training.

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

