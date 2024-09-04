
CNMFE_path = 'F:\JJM\miniscope_analysis\JZL\clustering_analysis\' ; 
cd(CNMFE_path)

%'DIO_r2.21_JZL_15_03_44', 'DIO_r2.21_JZL_15_33_55'

sessions =  {'DIO_r2.14_JZL_13_32_52', 'DIO_r2.14_JZL_14_03_16', ...
            'DIO_r2.14_Vehicle_15_04_07', 'DIO_r2.14_Vehicle_15_34_28',  ...
            'DIO_r2.19_JZL_15_19_41', 'DIO_r2.19_Vehicle_14_24_19', ...
            'DIO_r2.19_Vehicle_14_54_58', 'DIO_r2.20_JZL_13_40_12', ...
            'DIO_r2.20_JZL_13_55_35', 'DIO_r2.20_vehicle_16_19_25', ...
            'DIO_r2.20_vehicle_16_50_02', 'DIO_r2.21_JNJ_13_26_34', ...
            'DIO_r2.21_vehicle__15_31_38', 'DIO_r2.21_vehicle__16_05_56', 'DIO_r2.21_vehicle__16_36_18', ...
            'DIO_r2.25_JZL_16_36_20', 'DIO_r2.25_JZL_17_06_28', ...
            'DIO_r2.25_Vehicle_12_23_38', 'DIO_r2.25_Vehicle_12_56_10', ...
            'DIO_r2.26_JZL_12_11_14', 'DIO_r2.26_JZL_12_41_25', ...
            'DIO_r2.26_vehicle__14_35_41', 'DIO_r2.26_vehicle__15_06_16', ...
            'DIO_r2.8_JZL_12_59_48', 'DIO_r2.8_JZL_13_31_03', ...
            'DIO_r2.8_Vehicle_15_04_07', 'DIO_r2.8_Vehicle_15_34_28', 'DIO_r2.8_Vehicle_16_24_15', 'DIO_r2.8_Vehicle_16_55_40' ...
             } ; 


%regExp= '_velocityBin*' ; 
regExp= '' ; 

%framesDir= 'F:\JJM\miniscope_analysis\PAM\clustering_analysis\frames_subset_Fri_18_Aug_2023_16_30_56' ;
framesDir = 'all_frames';

sizeSessions = size(sessions);

    if  strcmp(framesDir, 'all_frames')
        dirName = strcat('all_frames_', string(datetime('now', 'format', 'y_M_d_HH_mm-ss'), "yyyy-MM-dd-HH-mm-ss"), '_analysisOutput');
        mkdir(dirName);
        dirInput = dirName ;
    else
        dirInput = framesDir ;
    end

for i=1:sizeSessions(1,2)
    session=sessions{1,i} ;
    analyzeJaccardsForSessionFn(session, dirInput, regExp, CNMFE_path) ; 

end


