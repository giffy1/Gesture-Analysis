function [ features ] = computeStatisticalFeatures( window )
%COMPUTESTATISTICALFEATURES Computes statistical features over a window of data
%   The feature vector is a 5*K dimensional vector containing the mean,
%   standard deviation, skewness, kurtosis and root mean square for each of
%   the K axes.

        windowMean = mean(window,1);
        windowStd = std(window,1);
        windowSkew = skewness(window,1);
        windowKurtosis = kurtosis(window);
        windowRMS = rms(window,1);
        ZCR=mean(abs(diff(sign(window))));

        features = [windowMean'; windowStd'; windowSkew'; windowKurtosis'; windowRMS'; ZCR'];
end

