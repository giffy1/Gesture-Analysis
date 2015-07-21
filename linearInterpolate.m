function [resampled_data] = linearInterpolate(data, interval)
%LINEARINTERPOLATE linearly interpolates the provided data matrix along its
%rows, contingent on the first column (assuemd to be time-series)
%   data: Nx(D+1) matrix where D is the dimension of the data and the
%   first column defines a sequential ordering of the data (i.e.
%   time-domain). The data will be resampled based on the first column.
%
%   interval: specifies the new sampling rate. The method returns a Mx(D+1)
%   matrix where M is the number of samples after re-sampling.
%
%   NOTE: This assumes that the time-series data starts at t=0. If this is
%   not the case, shift the data prior to interpolating.

[n,d] = size(data);

%maximum time value
maxT = data(end,1);

%initialize
Tf = (0:interval:maxT)';
nIntervals = length(Tf);
resampled_data = zeros(nIntervals,d);
resampled_data(:,1) = Tf;

k = 2; %index into T
for i=1:nIntervals,
    deltaT = data(k,1) - data(k-1,1);
    s_i = interval*i;
    
    if deltaT == 0,
        resampled_data(i,2) = data(k,2);
        resampled_data(i,3) = data(k,3);
        resampled_data(i,4) = data(k,4);
    else
        %interpolation factors: how close is s_i to T_k-1 and to T_k
        f1 = (s_i - data(k-1,1))/deltaT;
        f2 = (data(k,1) - s_i)/deltaT;

        %weighted sum of X_k and X_k-1, where weights are f1, f2
        resampled_data(i,2) = data(k-1,2)*f1 + data(k,2)*f2;
        resampled_data(i,3) = data(k-1,3)*f1 + data(k,3)*f2;
        resampled_data(i,4) = data(k-1,4)*f1 + data(k,4)*f2;
    end
    
    %make sure s_i falls between T_k-1 and T_k
    while (s_i >= data(k,1) && k < n)
        k=k+1;
    end
end

end

