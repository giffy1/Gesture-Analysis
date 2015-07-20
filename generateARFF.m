function arff = generateARFF( featureNames, x, y )
%GENERATEARFF
%Input:
%featureNames is a cell array of M features, where the last 
%feature is assumed to be 'class'
%x is a feature matrix of MxN values
%y is a class vector of size N

    [M, k] = size(x);
    nFeatureNames = length(featureNames);
    if nFeatureNames < M, %too few feature names provided
        for i=nFeatureNames+1:M,
            featureNames{i} = ['f' num2str(i)];
        end
        %if too many feature names are provided, the last ones will be
        %ignored
    end
    
    attributes = [x;y'];
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
        class = y(i);
        s = strtrim(cellstr(num2str([attr;class]))');
        arff = sprintf('%s\n', [arff, strjoin(s, ',')]);
    end
end

