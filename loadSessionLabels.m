function [ sessions ] = loadSessionLabels( dataDir, identifier )
%LOADSESSIONLABELS Loads the session labels of the gesture stream
%
%   dataDir: specifies in which directory the data files are located
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
%   The function returns a structure containing the start and end times and
%   the corresponding labels.
%
%   See also LOADGESTURELABELS, LOADSENSORDATA

    ext = '.csv';
    filename = fullfile(dataDir, ['REPORT' num2str(identifier) ext]);
    disp(['Reading session labels from ' filename '...']);
    tic
    [times, labels] = xlsread(filename);

    %assumes that every start has corresponding end label
    S = times(1:2:end);
    E = times(2:2:end);
    
    sessions = struct('size', length(S), 'start', S, 'end', E, 'labels', {labels(1:2:end, 1)});
    toc
end

