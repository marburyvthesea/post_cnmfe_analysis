
%% do jones's post processing steps on mm tracking output (imageJ plugin)

% add path to data

addpath(genpath(dataFolder)) ; 

%original frame rate (30 from behavCam videos)
orig_Fs = 30 ; 
%downsampled frame rate (Jones uses 5)
downsampled_Fs = 5 ; 

disp('processing')
disp(f_to_process)

[speedTrace, Behavior_distance_raw, Behavior_distance_filter] = motion_tracking(strcat(dataFolder, f_to_process), 30, downsampled_Fs);

% save output to individual csv files
f_name_split = strsplit(f_to_process, '_');
session_name = strcat(f_name_split{1, 1}, '_', f_name_split{1, 2}, '_', f_name_split{1, 3}, '_', f_name_split{1, 4}); 

disp('saving output')

csvwrite(strcat(dataFolder, session_name, '_speedtrace.csv'), speedTrace) ;
csvwrite(strcat(dataFolder, session_name, '_raw_trace.csv'), Behavior_distance_raw) ;
csvwrite(strcat(dataFolder, session_name, '_raw_trace_median_filter.csv'), Behavior_distance_filter) ;
