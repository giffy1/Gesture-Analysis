function [ preprocessedData ] = preprocessData( accelData, gyroData, interval, EWMA_alpha)
%PREPROCESSDATA pre-processes the raw accelerometer and gyroscope streams
%by first resampling using linear interpolation so the streams align, then
%applying an exponentially weighted moving average to smooth the data.
%
%   accelData: the stream of raw accelerometer data. The first column is
%   assumed to be the time-series data
%   gyroData: the stream of raw gyroscope data.
%   
%   interval: the resampling interval; that is, the period corresponding to
%   the adjusted sampling rate. Linear interpolation is used
%
%   EWMA_alpha: the alpha parameter that defines the behavoir of the
%   exponentially weighted moving average algorithm.
%
%   The function returns the pre-processed data as a single matrix where
%   the first column corresponds to the now uniformly spaced time data, the
%   next 3 columns correpond to the 3-axis accelerometer data and the
%   remaining columns correspond to the 3-axis gyroscope data.
%
%   See also EWMA, LINEARINTERPOLATE

    disp('Pre-processing data...');
    
    tic
    
    resampledAccelData = linearInterpolate(accelData, interval);
    resampledGyroData = linearInterpolate(gyroData, interval);
    
    n = min(size(resampledAccelData, 1), size(resampledGyroData, 1));
    combined_data = [resampledAccelData(1:n, :) resampledGyroData(1:n, 2:end)];
    
    preprocessedData = EWMA(combined_data, EWMA_alpha);
    
    toc

end