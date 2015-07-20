function [ preprocessedData ] = preprocessData( accelData, gyroData, interval, EWMA_alpha)
%PREPROCESSDATA Summary of this function goes here
%   Detailed explanation goes here

    disp('Pre-processing data...');
    
    tic
    
    resampledAccelData = linearInterpolate(accelData, interval);
    resampledGyroData = linearInterpolate(gyroData, interval);
    
    n = min(size(resampledAccelData, 1), size(resampledGyroData, 1));
    combined_data = [resampledAccelData(1:n, :) resampledGyroData(1:n, 2:end)];
    
    preprocessedData = EWMA(combined_data, EWMA_alpha);
    
    toc

end

