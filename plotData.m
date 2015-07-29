function [H, colorSet, fig] = plotData( dataStream, startLabels, endLabels, labels, no_activity_color, axisOptions, sameScale, window_title )
%PLOTDATA Plots raw multi-axis session-labelled (or gesture-labelled) 
%data (i.e. accel/gyro) 
%
%   dataStream: Nx(K+1) matrix where the first column corresponds to the
%   timestamps and the remaining columns represent the K-axis data stream.
%   For example, the 3-axis accelerometer data is an Nx4 matrix.
%
%   startLabels: M-dimensional vector of timestamps indicating the start 
%   times of the labelled sessions/gestures. 
%
%   endLabels: M-dimensional vector of timestamps indicating the end times
%   of the labelled sessions/gestures.
%
%   labels: M-dimensional cell array of the textual identifiers of each
%   label.
%
%   no_activity_color: 3-dimensional vector specifying the color the
%   graph should have where no label is present.
%
%   axisOptions: specifues how many/which axes will be displayed, as 
%   described in the AxesConstants class.
%
%   The plot will automatically ensure that panning/zooming in one 
%   subplot will do the same for all subplots. The function returns a
%   vector of handles to the subplots corresponding to each unique label in
%   the labels parameter; it also returns the color set generated for the
%   graph.
%
%   See also DISTINGUISHABLE_COLORS, AXESCONSTANTS

    uniqueLabels = unique(labels); %should be in alphabetical order
    nUniqueLabels = length(uniqueLabels);
    H = zeros(nUniqueLabels+1,1); %handles for each of unique labels, plus handle for no-label signal
    colorSet = distinguishable_colors(nUniqueLabels, [1 1 1; 0 0 0; no_activity_color]);

    nAxes = 1;
    axis1 = 1;
    if axisOptions == AxesConstants.ALL,
        nAxes = 3;
    elseif axisOptions == AxesConstants.X,
        axis1 = 1;
    elseif axisOptions == AxesConstants.Y,
        axis1 = 2;
    elseif axisOptions == AxesConstants.Z,
        axis1 = 3;
    end

%% -------- PLOT DATA -------- %%
    ax = zeros(3,1);
    fig=figure('name', window_title); 
    for i=axis1:axis1+nAxes-1, %for each axis
        ax(i)=subplot(nAxes,1,i-axis1+1);
        H(1) = plot(dataStream(:,1), dataStream(:,i+1), 'Color', no_activity_color);
        [~, axisNames] = enumeration('AxesConstants');
        title([axisNames{i} ' axis']);
        xlabel('time (nanoseconds)');
        hold on;
        for k=1:length(startLabels), %plot each label
            label = labels(k);
            
            %http://www.mathworks.com/matlabcentral/answers/2015-find-index-of-cells-containing-my-string
            cellfind = @(string)(@(cell_contents)(strcmp(string,cell_contents)));
            index = find(cellfun(cellfind(label),uniqueLabels));
            
            color = colorSet(index,:);
            
            session = dataStream(dataStream(:,1) >= startLabels(k) & dataStream(:,1) <= endLabels(k), :);
            if ~isempty(session),
                H(index+1) = plot(session(:,1), session(:,i+1), 'Color', color);
            end
        end
        hold off;
    end
    hold on;
    
    %set default zoom/pan options to horizontal only
    linkaxes(ax, 'x');
    h = zoom;
    set(h,'Motion','horizontal','Enable','on');
    h = pan;
    set(h,'Motion','horizontal','Enable','on');
    
    if strcmpi(sameScale, 'SameScale') && axisOptions == AxesConstants.ALL,
        allYLim = get(ax, {'YLim'});
        allYLim = cat(2, allYLim{:});
        set(ax, 'YLim', [min(allYLim), max(allYLim)]);
    end
    
    %legend(H, [{'none'}; uniqueLabels]); %ignore legend just for now (when
    %plotting misclassified windows, it causes an error I couldn't fix...)
    hold off;

end

