
CNMFE_path = 'F:\JJM\miniscope_analysis\mGluR5_NAM\clustering_analysis\' ; 
cd(CNMFE_path)

sessions =  {'Vehicle_DIO_r2.7_15_20_30', 'Vehicle_DIO_r2.7_15_51_07', ...
              'Vehicle_DIO_r2.8_16_45_11', 'Vehicle_DIO_r2.8_17_16_03', ...
              'Vehicle_DIO_r2.14_17_25_26', 'Vehicle_DIO_r2.14_17_40_46', 'Vehicle_DIO_r2.14_18_11_01', ...
              'Vehicle_DIO_r2.19_13_45_01', 'Vehicle_DIO_r2.19_14_15_20', ...
              'Fenobam_DIO_r2.7_17_00_12', 'Fenobam_DIO_r2.7_17_30_50', ...
              'Fenobam_DIO_r2.8_16_00_28', 'Fenobam_DIO_r2.8_16_30_39', ...
              'Fenobam_DIO_r2.14_14_00_13', 'Fenobam_DIO_r2.14_14_30_28', ...
              'Fenobam_DIO_r2.19_16_04_27', 'Fenobam_DIO_r2.19_16_34_31'
              } ; 


regExp= '_velocityBin*' ; 

%framesDir= 'F:\JJM\miniscope_analysis\mGluR5_NAM\clustering_analysis\frames_subset_Fri_24_Feb_2023_13_21_14' ;
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


