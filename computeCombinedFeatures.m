function [ features ] = computeCombinedFeatures( window )
%COMPUTEFEATURES Computes a feature vector combining both the statistical
%features and the features computed by integrating the accelerometer and
%gyroscope streams.
%   See also COMPUTEFEATURES, COMPUTESTATISTICALFEATURES

        features = [computeFeatures(window); computeStatisticalFeatures(window)];
end

