function [ ] = writeARFF(featureDir, filename, X, Y, featureNames)
%WRITEARFF Write an .arrf file for use in Weka
%  
%   featureDir: the directory where the .arff file should be saved
%   filename: the name of the .arff file (excluding the extension)
%
%   X: MxN matrix containing N vectors of M features
%   Y: vector of N classes
%   
%   featureNames: optional cell array of names describing each feature.
%   This parameter can be omitted by passing in an empty array or cell
%   array, in which case the features will be called 'f1', 'f2', etc. If
%   fewer than M feature names are specified then the remaining features
%   will be named by that convention and if more than M are provided, only
%   the first M will be registered.
%   
%   See also GENERATEARFF, <a href="http://www.cs.waikato.ac.nz/ml/weka/">Weka</a>

    arff = generateARFF(featureNames, X, Y);
    fid = fopen(fullfile(featureDir, filename), 'w');
    fprintf(fid,'%s\r\n',arff);
    fclose(fid);

end

