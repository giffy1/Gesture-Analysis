function [ start_times, end_times, N] = loadGestureLabels(dataDir, filename)
    %LOADGESTURELABELS
    
    fName = fullfile(dataDir, filename);

    FID = fopen(fName);
    labelsContent = textscan(FID,'%s','Delimiter','\n');
    labelCell = labelsContent{1};
    video_start = str2num(labelCell{1});
    sensor_start = str2num(labelCell{2});
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
end
