function [ motionData ] = loadSensorData(dataDir, identifier)
%LOADSENSORDATA Loads raw accel/gyro data stream
%   
%   dataDir: specifies in which directory the data files are located
%
%   identifier: indicates which file is of interest
%   
%   The accelerometer file must begin with the word "ACCEL" and the 
%   gyroscope file must begin with the word "GYRO". Following this 
%   identifier should be an index to identify the dataset.
%   
%   The function returns two matrices with the requested data:
%   accelData is an Nx4 double-precision matrix containing the timestamps
%   and the x-,y-,z- accelerometer data.
%   gyroData is also an Nx4 matrix with analogous information.
%
%   See also LOADSESSIONLABELS, LOADGESTURELABELS
    
    %% -------- LOAD DATA FROM MULTIPLE FILES -------- %%

    ext = '.csv';
    
    file = ['ACCEL' num2str(identifier) ext];
    path = fullfile(dataDir, file);
    disp(['Reading accelerometer data from ' file '...']);
    tic
    accelData = csvread(path);
    T0 = accelData(1,1);
    Tf = accelData(end,1);
    disp(['Collected ' num2str((Tf - T0)/(60*10^9)) ' minutes of data']);
    toc
    
    file = ['GYRO' num2str(identifier) ext];
    path = fullfile(dataDir, file);
    disp(['Reading gyroscope data from ' file '...']);
    tic
    gyroData = csvread(path);
    T0 = gyroData(1,1);
    Tf = gyroData(end,1);
    disp(['Collected ' num2str((Tf - T0)/(60*10^9)) ' minutes of data']);
    toc
    
    motionData = struct('accelerometer', accelData, 'gyroscope', gyroData);

end

