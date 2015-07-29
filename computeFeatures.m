function [ features ] = computeFeatures( window )
%COMPUTEFEATURES Computes features over the window, intended for
%classifying eating/drinking gestures primarily.
%
%   Unlike computeStatisticalFeatures(), this method assumes that the
%   window contains 3-axis accelerometer data in the first three columns
%   and 3-axis gyroscope data in the remaining columns.
%
%   For both sensors, it integrates the raw readings to compute the linear
%   position and angular rotation approximations relative to the first 
%   sample in the window. Features over this stream include the number of
%   peaks and troughs, the maximum linear position/angular rotation, the
%   average, max and median of the raw data up to that maximum and the
%   minimum relative position/rotation.

        deltaT = .2; %TODO pass this in... is it even needed??
        %ACCELEROMETER FEATURES
        linearAcceleration = window(:,1:3); %accel values
        %linearVelocity = cumsum(linearAcceleration,1);
        %linearPosition = cumsum(linearVelocity,1);
        linearPosition = cumsum(1/2.*linearAcceleration.*deltaT.*deltaT);
        nPositionPeaks = zeros(3,1);    
        [maxPosition, maxIndex] = max(linearPosition);
        [minPosition, ~] = min(linearPosition);
        avgAccelerationToMax = zeros(3,1);
        maxAccelerationToMax = zeros(3,1);
        medianAccelerationToMax = zeros(3,1);
        for i=1:3,
            nPositionPeaks(i) = length(findpeaks(linearPosition(:,i),'MinPeakDistance',20)) ...
                + length(findpeaks(-linearPosition(:,i), 'MinPeakDistance',20));
            
            avgAccelerationToMax(i) = mean(linearAcceleration(1:maxIndex(i),i));
            maxAccelerationToMax(i) = max(linearAcceleration(1:maxIndex(i),i));
            medianAccelerationToMax(i) = median(linearAcceleration(1:maxIndex(i),i));
        end

        %GYROSCOPE FEATURES
        angularVelocity = window(:,4:end); %gyroscope rate
        angularRotation = cumsum(angularVelocity,1);
        %angularRotation = angularRotation - mean(angularRotation);
        nPeaks = zeros(3,1);    
        [maxAngularRotation, maxIndex] = max(angularRotation);
        [minAngularRotation, ~] = min(angularRotation);
        avgAngularVelocityToMax = zeros(3,1);
        maxAngularVelocityToMax = zeros(3,1);
        medianAngularVelocityToMax = zeros(3,1);
        for i=1:3,
            nPeaks(i) = length(findpeaks(angularRotation(:,i),'MinPeakDistance',20)) ...
                + length(findpeaks(-angularRotation(:,i), 'MinPeakDistance',20));
            
            avgAngularVelocityToMax(i) = mean(angularVelocity(1:maxIndex(i),i));
            maxAngularVelocityToMax(i) = max(angularVelocity(1:maxIndex(i),i));
            medianAngularVelocityToMax(i) = median(angularVelocity(1:maxIndex(i),i));
        end

        features = [...
            maxPosition'; minPosition'; avgAccelerationToMax; ...
            maxAccelerationToMax; medianAccelerationToMax; nPositionPeaks; ...
            maxAngularRotation'; minAngularRotation'; avgAngularVelocityToMax; ...
            maxAngularVelocityToMax; medianAngularVelocityToMax; nPeaks];
end

