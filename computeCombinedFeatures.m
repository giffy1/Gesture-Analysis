function [ features ] = computeCombinedFeatures( window )
%COMPUTEFEATURES Summary of this function goes here
%   Detailed explanation goes here

        features = [computeFeatures(window); computeStatisticalFeatures(window)];
end

