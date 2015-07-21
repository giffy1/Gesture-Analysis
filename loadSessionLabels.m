function [ S, E, labels ] = loadSessionLabels( dataDir, ext, filter )
%LOADSESSIONLABELS Loads the session labels of the gesture stream
%
%   dataDir: specifies in which directory the data files are located
%   ext: indicates the extension of the files. The extension must be
%   a valid Excel file extension (works with xlsread()).
%
%   filter: an array that indicates which files are of interest,
%   identifying these files by an index. If empty, then all files will 
%   be examined.
%
%   The file must start with "REPORT" and should be followed by an index. 
%   The first column must contain the timestamps and the second column must 
%   contain the label. The third column should contain  "before" or "after"; 
%   however, this is not necessary since the third column is simply ignored 
%   for now (though it could later be used as a validation for sound label 
%   sequences).
%
%   The function returns the start and end times, S and E respectively, and
%   the labels of each session. S and E are vectors of order M and labels 
%   is a cell array of length M.
%
%   See also LOADGESTURELABELS, LOADSENSORDATA

    regex = fullfile(dataDir, ext);
    
    files = dir(regex); %get file identifiers
    nFiles = length(files); %number of files
    filenames = {files.name}; %get list of file names
    
    %% -------- INIT -------- %%
    
    timeData = zeros(0, 1); %timestamps corresponding to the labels
    labelData = zeros(0, 2); %the labels
    
    %% -------- LOAD DATA FROM MULTIPLE FILES -------- %%

    for i=1:nFiles,
       file = filenames{i};
       filename = file(1:strfind(file, '.')-1);
       if strncmpi(filename, 'REPORT', 6),
           index = str2double(filename(7:end));
           if isempty(filter) || ~isempty(find(filter==index, 1)), 
               disp(['Reading session labels from ' filename '...']);
               tic
               [times, label] = xlsread(fullfile(dataDir, file));
               timeData = [timeData; times];
               labelData = [labelData; label];
               toc
           end
       elseif strncmpi(filename, 'ACCEL', 5),
           %do nothing, this is just so it won't display found additional
           %file
       elseif strncmpi(filename, 'GYRO', 4),
           %do nothing, this is just so it won't display found additional
           %file
       else
           disp(['Found additional file: ' filename]);
       end
    end

    %assumes that every start has corresponding end label
    S = timeData(1:2:end);
    E = timeData(2:2:end);
    
    labels = labelData(1:2:end, 1);
end

