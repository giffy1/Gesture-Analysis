function [ accelData, gyroData ] = loadSensorData( dataDir, ext, filter )
%LOADSENSORDATA Loads raw accel/gyro data stream
%   dataDir specifies in which directory the data files are located,
%   and ext indicates the extension of the files. Currently, the extension
%   must be ".csv" to work with csvread(). The accelerometer file must
%   begin with the word "ACCEL" and the gyroscope file must begin with the
%   word "GYRO". All text following these identifiers will be safely
%   ignored. The function returns two matrices with the requested data:
%   accelData is an Nx4 double-precision matrix containing the timestamps
%   and the x-,y-,z- accelerometer data. gyroData is also an Nx4 matrix
%   with analogous information. Also the filter parameter indicates
%   which file(s) are of interest, by the value which follows the 
%   identifier. This is a vector of arbitrary length. If empty, then all
%   files will be examined.

    regex = fullfile(dataDir, ext);
    
    files = dir(regex); %get file identifiers
    nFiles = length(files); %number of files
    filenames = {files.name}; %get list of file names
    
    %% -------- INIT -------- %%
    
    accelData = zeros(0, 4);
    gyroData = zeros(0, 4);
    accelIndex = 1;
    gyroIndex = 1;
    
    %% -------- LOAD DATA FROM MULTIPLE FILES -------- %%

    for i=1:nFiles,
       file = filenames{i};
       filename = file(1:strfind(file, '.')-1);
       if strncmpi(filename, 'ACCEL', 5),
           index = str2double(filename(6:end));
           if isempty(filter) || ~isempty(find(filter==index, 1)), 
               disp(['Reading accelerometer data from ' file '...']);
               tic
               data = csvread(fullfile(dataDir, file));
               T0 = data(1,1);
               Tf = data(end,1);
               disp(['Collected ' num2str((Tf - T0)/(60*10^9)) ' minutes of data']);
               accelData = [accelData; data];
               toc
           end
       elseif strncmpi(filename, 'GYRO', 4),
           index = str2double(filename(5:end));
           if isempty(filter) || ~isempty(find(filter==index, 1)),
               disp(['Reading gyroscope data from ' file '...']);
               tic
               data = csvread(fullfile(dataDir, file));
               T0 = data(1,1);
               Tf = data(end,1);
               disp(['Collected ' num2str((Tf - T0)/(60*10^9)) ' minutes of data']);
               gyroData = [gyroData; data];
               toc
           end
       elseif strncmpi(filename, 'REPORT', 6),
           %do nothing, this is just so it won't display found additional
           %file
       else
           disp(['Found additional file: ' file]);
       end
    end

end

