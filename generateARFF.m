function arff = generateARFF(X, Y, featureNames)
%GENERATEARFF: generates the contents of an .arff file for use in Weka.
%   X: feature matrix of MxN values
%   Y: class vector of size N
%
%   featureNames: optional cell array of M feature names. If omitted, then
%   the features will be named 'f1', 'f2', etc. It may also be partially
%   omitted, in which case the first K < M features are named and the rest
%   follow the indexed 'f' naming convention. If too many feature names are
%   provided, only the first M are registered.
%   
%   See also WRITEARFF, <a href="http://www.cs.waikato.ac.nz/ml/weka/">Weka</a>

    [M, k] = size(X);
    nFeatureNames = length(featureNames);
    if nFeatureNames < M, %too few feature names provided
        for i=nFeatureNames+1:M,
            featureNames{i} = ['f' num2str(i)];
        end
        %if too many feature names are provided, the last ones will be
        %ignored
    end
    
    attributes = [X;Y'];
    arff = sprintf('%s\n', '@relation gesture');
    for i = 1:M
        header = featureNames(i);
        arff = sprintf('%s\n', [arff,'@attribute ', header{1}, ' NUMERIC']);
    end
    arff = sprintf('%s\n', [arff, '@attribute ', 'class', '{0,1,2}']); 
    %TODO: use unique(y) to determine {0,1,2,...}
    arff = sprintf('%s\n', [arff, '@data']);
    for i = 1:k
        attr = attributes(1:M, i);
        class = Y(i);
        s = strtrim(cellstr(num2str([attr;class]))');
        arff = sprintf('%s\n', [arff, strjoin(s, ',')]);
    end
end

