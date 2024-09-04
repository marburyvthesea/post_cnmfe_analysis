
CNMFE_path = 'F:\JJM\miniscope_analysis\PAM\clustering_analysis\' ; 
cd(CNMFE_path)

% 'DIO_r2.20_JNJ_15_28_00',
% 'DIO_r2.24_vehicle_13_47_11'


sessions =  {'DIO_r2.20_Vehicle_13_54_56', 'DIO_r2.20_Vehicle_14_25_44', ...
             'DIO_r2.21_Vehicle_15_10_28', 'DIO_r2.21_Vehicle_15_42_52', ...
             'DIO_r2.25_Vehicle_11_18_34', 'DIO_r2.25_Vehicle_11_51_22', 'DIO_r2.25_Vehicle_12_22_45', ...
             'DIO_r2.24_vehicle_13_16_48', 'DIO_r2.24_vehicle_13_47_11', ...
             'DIO_r2.26_Vehicle_16_59_53','DIO_r2.26_Vehicle_17_23_12', ...
             'DIO_r2.20_JNJ_14_57_33', 'DIO_r2.20_JNJ_15_28_00', ...
             'DIO_r2.21_JNJ_12_56_18', 'DIO_r2.21_JNJ_13_26_34', ... 
             'DIO_r2.25_JNJ_15_59_18','DIO_r2.25_JNJ_16_24_23', 'DIO_r2.25_JNJ_16_55_40', ...
             'DIO_r2.26_JNJ_13_36_07','DIO_r2.26_JNJ_14_06_36', ... 
             'DIO_r2.24_JNJ_12_32_40', 'DIO_r2.24_JNJ_12_01_17',
             } ; 

inputPeakThreshold = 2.5 ; 
inputMicronsPerPixel = 1.85 ; % micronsPerPixel 2.5 = microns (inscopix), 1 (v3), 1.85 (v4)
inputMaxDist = 500 ; 
inputBinSize = 225 ; 
inputBStart = 50 ;
inputNumBins = 2; %9 for 50um Size
%inputBinVector = inputBStart:inputBinSize:inputMaxDist;
%%
regExp= '_velocityBin*' ; 

%framesDir= 'F:\JJM\miniscope_analysis\PAM\clustering_analysis\frames_subset_Wed_11_Oct_2023_16_57_14\' ;
framesDir = 'all_frames';

sizeSessions = size(sessions);

    if  strcmp(framesDir, 'all_frames')
        dirName = strcat('all_frames_', string(datetime('now', 'format', 'y_M_d_HH_mm-ss'), "yyyy-MM-dd-HH-mm-ss"), '_analysisOutput');
        mkdir(dirName);
        dirInput = dirName ;
    else
        dirInput = framesDir ;
    end
%%
for i=1:sizeSessions(1,2)
    session=sessions{1,i} ;
    analyzeJaccardsForSessionFn(session, dirInput, regExp, CNMFE_path, inputPeakThreshold, inputMicronsPerPixel, ...
        inputMaxDist, inputBinSize, inputBStart, inputNumBins) ; 

end


