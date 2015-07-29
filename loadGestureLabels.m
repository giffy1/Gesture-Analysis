function [ gestures ] = loadGestureLabels(dataDir, identifier)
%LOADGESTURELABELS Loads the session labels of the gesture stream
%
%   dataDir: specifies in which directory the data files are located
%
%   filename: the name of the file where the gesture labels are recorded
%
%   This function only returns the start and end times correponding to the
%   gestures. To determine the textual labels, there must be assosciated
%   sessions. Use the loadSessionLabels functions to load these labels and
%   assign labels to the gestures based on what session the gestures are
%   contained in.
%
%   The function also returns the number of labels N, which corresponds to
%   the length of start_times and end_times.
%
%   See also LOADSESSIONLABELS, LOADSENSORDATA
        
    ext = '.txt';
    file = ['labels' num2str(identifier) ext];
    fName = fullfile(dataDir, file);
    disp(['Reading gesture labels from ' file '...']);
    tic

    FID = fopen(fName);
    labelsContent = textscan(FID,'%s','Delimiter','\n');
    labelCell = labelsContent{1};
    video_start = str2double(labelCell{1});
    sensor_start = str2double(labelCell{2});
    labels = cell2mat(labelCell(3:end));
    M = size(labels, 1);
    N = M/2;
    start_times = zeros(N,1);
    end_times = zeros(N,1);

    count = 1;
    for i = 1:size(labels,1)/2
        C = strsplit(labels(2*i-1,:),',');
        start_times(count) = str2double(C{1});
        C = strsplit(labels(2*i,:),',');
        end_times(count) = str2double(C{1});
        count = count + 1;
    end
    fclose(FID);
    
    %correct times by video/sensor start values (assumes sensor timestamps
    %are in nanoseconds)
    start_times = (start_times + video_start - sensor_start)*10^6;
    end_times = (end_times + video_start - sensor_start)*10^6;
    
    gestures = struct('video_start', video_start, 'sensor_start', sensor_start, 'size', N, 'start', start_times, 'end', end_times);
    toc
end
