

%path to cell key 

%cell_key = readtable('/Volumes/My_Passport/cnmfe_analysis_files/batch_output_files/cnmfe_key.csv', 'ReadVariableNames', true); 

%base data dir

dataDirectory = '/Volumes/My_Passport/cnmfe_analysis_files/OpenFieldAnalysis/2020/D1_mGluRKO_clustering/data/' ; 

WT_sessions = ['30-Mar_20_39_05', '28-Feb_16_10_05', '25-Mar_14_22_02', '30-Mar_20_45_16', '27-Feb_17_32_15', '25-Mar_14_22_44', ...
				'27-Feb_17_33_59', '28-Feb_16_21_21', '26-Mar_18_33_55', '22-Mar_22_52_02', '25-Mar_13_27_27', '27-Mar_00_26_12', '27-Mar_00_48_46'] ; 

KO_sessions = ['31-Mar_13_28_15', '29-Mar_21_42_20', '13-Apr_17_57_40', '29-Mar_14_27_55', '13-Apr_16_01_20', '13-Apr_16_11_27', '29-Mar_13_39_44'] ;

%structure to store data
batchData = struct();

%loop over sessions
size_array = size(WT_sessions);

for session = 1:size_array(1,1);
	disp(session);
	sessionOutput = jaccard_compute_fn_jjm(dataDirectory, session, 2.5, 2.5, 500, 20);
	batchData.session = sessionOutput ; 

disp('done') ; 