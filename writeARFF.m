function [ output_args ] = writeARFF( arff, featureDir, filename )
%WRITEARFF Summary of this function goes here
%   Detailed explanation goes here

    %filename = 'FF_backhand.arff';
    fid = fopen(fullfile(featureDir, filename), 'w');
    fprintf(fid,'%s\r\n',arff);
    fclose(fid);

end

