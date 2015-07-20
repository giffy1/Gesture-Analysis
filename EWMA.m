function [ smoothed_data ] = EWMA( data, alpha )
%EWMA Smooth dataset with exponentially-weighted moving average
%   data is that need be smoothed and alpha is the parameter which
%   defines how much weight is given to previous samples.

[n,d] = size(data);

%see Marquardt process for determining 'optimal' value of alpha
smoothed_data = zeros(size(data));
smoothed_data(:,1) = data(:,1); %copy first column
for i = 2:d %ignore first column
    smoothed_data(1,i) = data(1,i);
    for j = 2:n
        smoothed_data(j,i) = alpha * smoothed_data(j-1,i) + (1-alpha) * data(j,i);
    end
end


end

