function [ features ] = computeStatisticalFeatures( window )
%COMPUTEFEATURES Summary of this function goes here
%   Detailed explanation goes here

        windowMean = mean(window,1);
        windowStd = std(window,1);
        windowSkew = skewness(window,1);
        windowKurtosis = kurtosis(window);
        windowRMS = rms(window,1);

        features = [windowMean'; windowStd'; windowSkew'; windowKurtosis'; windowRMS'];
end

