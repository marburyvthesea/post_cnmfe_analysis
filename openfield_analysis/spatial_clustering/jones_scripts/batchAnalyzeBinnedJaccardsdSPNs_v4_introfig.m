
CNMFE_path = 'F:\JJM\miniscope_analysis\introfigure\cnmfe_wt_openfield\' ; 
cd(CNMFE_path)

sessions =  {'DIO_r2_19_Day_3_13_54_25', 'DIO_r2_19_Day_1_14_20_58', 'DIO_r2_19_Day_1_14_36_06', ... 
              'DIO_r2_19_Day_2_14_52_25', 'DIO_r2_19_Day_3_13_35_03', ...
              'DIO_r2_1_Day2_17_19_33', 'DIO_r2_1_Day3_17_20_31', 'DIO_r2_1_Day1_18_05_16', ...
              'DIO_r2.20_Day_1_16_02_16', 'DIO_r2.20_Day_3_15_22_34', ...
              'DIO_r2.24_Day_1_12_07_18', 'DIO_r2.24_Day_2_12_49_12', ... 
              'DIO_r2.25_Day_1_10_58_59', 'DIO_r2.25_Day_1_11_16_28', 'DIO_r2.25_Day_2_11_19_38', 'DIO_r2.25_Day_2_11_28_12', ...
              'DIO_r2.26_Day_2_12_58_49', 'DIO_r2.26_Day_3_12_26_37', ...
              'DIO_r2_7_Day1_16_28_11', 'DIO_r2_7_Day2_14_04_48', 'DIO_r2_7_Day3_13_34_12'
             } ; 

inputPeakThreshold = 2.5 ; 
inputMicronsPerPixel = 1.85 ; % micronsPerPixel 2.5 = microns (inscopix), 1 (v3), 1.85 (v4)
inputMaxDist = 500 ; 
inputBinSize = 50 ; 
inputBStart = 50 ;
inputNumBins = 9; %9 for 50um Size
%inputBinVector = inputBStart:inputBinSize:inputMaxDist;
%%
regExp= '_velocityBin*' ; 

%framesDir= 'F:\\JJM\\miniscope_analysis\\dSPNs\\clustering_analysis\\frames_subset_Fri_06_Oct_2023_05_59_53\\' ;
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


