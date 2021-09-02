     %20191121 %Author: Jones Parker

     
function [speedTrace, Behavior_distance_raw, Behavior_distance_filter] = motion_tracking(data, Fs_in, Fs_out); 


    
    %load the data
    Behavior = csvread(data,1); %exclude row1 (headers)


    %col 8 = x-coords (cm)
    %col 9 = y-coords (cm)
    %col 1 = area (largest area = mouse)
    %col 7 = 'slice' (ID'd ROIs in the frame)
    
    %clean up the vehicle behavior trace by finding the indices of the max
    %area per slice
    
       thisSession = Behavior;
        minSlice = min(thisSession(:,7));
        maxSlice = max(thisSession(:,7));
        Slices = minSlice:1:maxSlice;
        
        Indices = nan(length(Slices),1);%pre-allocate
        for idx = 1:length(Slices)
            theseIndices = find(thisSession(:,7) == Slices(idx));
            if ~isempty(theseIndices)
            subIndex = find(thisSession(theseIndices,1) == max(thisSession(theseIndices,1)));
            Indices(idx, 1) = theseIndices(subIndex(end));
            else
            Indices(idx, 1) = NaN;
            end
        end

    
    %compute the distances traveled from X Y locations in the vehicle and
    %drug movies. 
    
    %pre-allocate
    Behavior_distance = nan(size(Indices, 1)-1,1);

    
    %Behavior_distance
    for idx1 = 2:size(Indices, 1);
        if isnan(Indices(idx1)) || isnan(Indices(idx1-1))
            Behavior_distance(idx1-1,1) = NaN;
        else                      
            Behavior_distance(idx1-1,1) = sqrt((Behavior(Indices(idx1), 8) - Behavior(Indices(idx1-1), 8)).^2 + (Behavior(Indices(idx1), 9) - Behavior(Indices(idx1-1), 9)).^2);
        end
    end
    

    %now compute the frame rates of the movies (first session is 25 min
    %second is 55min). Compute here as frames per second (should be close
    %to 24)
    
    Behavior_frameRate = Fs_in;

    
    %compute the filter factor for 1-s medianFilter (must be round number)
    Behavior_filterFactor = round(Behavior_frameRate);

    


 
    %% Here we will split the data into three types: 1) raw 20 Hz, 2) 1-s median-filtered 20 Hz, and 3) 1-s median-filtered 5 Hz. 
    
    %1)
    Behavior_distance_raw = Behavior_distance;

    
    %2) Now filter using 1-s median filter
    Behavior_distance_filter = medfilt1(Behavior_distance_raw, Behavior_filterFactor,'omitnan','truncate');

    
    %3)Now downsample to 5Hz    
    Behavior_speed_filter = Behavior_distance_filter*Fs_in;
    
    %compute downsample factors for the two movies (to make them 5 Hz)
    downsampledRate = Fs_out;%define the target downsample rate
    Behavior_downsampleFactor = round(Behavior_frameRate/downsampledRate);
    
    if Behavior_downsampleFactor > 1
    
    Behavior_speed_filter = nanmean(reshape([Behavior_speed_filter(:); nan(mod(-numel(Behavior_speed_filter),Behavior_downsampleFactor),1)],Behavior_downsampleFactor,[]));
    
    end
%   Behavior_distance_filter20 = nansum(reshape([Behavior_distance_filter(:); nan(mod(-numel(Behavior_distance_filter),Behavior_downsampleFactor),1)],Behavior_downsampleFactor,[]));
%   Behavior_distance_filter20 = Behavior_distance_filter20';%transpose the distance traces
%   speedTrace = Behavior_distance_filter20*Fs_out;
    speedTrace = Behavior_speed_filter';
    
end
    
