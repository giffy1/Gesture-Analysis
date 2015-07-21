function [ smoothed_data ] = EWMA( data, alpha )
%EWMA Smooth time-series dataset with exponentially-weighted moving average
%
%   data: the data set to be smoothed. The first column of the data set is
%   assumed to be uniformly sampled time (or sequence) data
%
%   alpha: defines how much weight is given to previous smoothed samples.
%   
%   See also <a
%   href="https://en.wikipedia.org/wiki/Moving_average#Exponential_moving_average">Wikipedia</a>,   

[n,d] = size(data);

smoothed_data = zeros(size(data));
smoothed_data(:,1) = data(:,1); %copy first column
for i = 2:d %ignore first column
    smoothed_data(1,i) = data(1,i);
    for j = 2:n
        smoothed_data(j,i) = alpha * smoothed_data(j-1,i) + (1-alpha) * data(j,i);
    end
end


end

