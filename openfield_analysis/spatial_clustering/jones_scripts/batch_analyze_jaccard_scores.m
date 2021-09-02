

%path to cell key 

%cell_key = readtable('/Volumes/My_Passport/cnmfe_analysis_files/batch_output_files/cnmfe_key.csv', 'ReadVariableNames', true); 

%base data dir

%dataDirectory = '/projects/p30771/miniscope/analysis/OpenFieldAnalysis/spatial_clusters/jones_script_analysis/data/ko/' ; 

%WT_sessions = {'GRIN013_H13_M33_S54'; 'GRIN026_H16_M35_S34'; 'GRIN027_H13_M29_S44'; 'GRIN032_H16_M49_S22'; 'GRIN032_H17_M30_S22'; 'GRIN033_H13_M42_S33'; ...
%			'GRIN033_H14_M34_S32'; 'GRIN034_H15_M28_S2'; 'GRIN034_H16_M13_S22'; 'GRIN034_H19_M0_S18'; 'GRIN035_H13_M31_S20'; 'GRIN035_H13_M50_S58'; 'GRIN035_H14_M40_S34'} ; 

%KO_sessions = {'GRIN009_H13_M59_S14'; 'GRIN011_H10_M19_S59'; 'GRIN012_H16_M57_S23'; 'GRIN012_H17_M32_S17'; ...
%			 'GRIN018_H16_M13_S53'; 'GRIN018_H17_M41_S43'} ;
%input sessions
%create variable for sdThreshold beforehand
%loop over sessions
size_array = size(sessions);
%save array with pixel scales for each indiv session
%maybe save a tuple with session name and pixel scale values

%structure to store data
batchData = cell(size_array(1,1), 1);

for session = 1:size_array(1,1);
	disp('loading');
	disp(sessions{session, :});
	% inputs = (dataDir, session, regExp,  sdThreshold, pixelScale, maxDist, binSize)
	% regExp e.g. = 'movement_regions_C_traces_filtered.csv', 'rest_regions_C_traces_filtered.csv'
	sessionOutput = jaccard_compute_fn_jjm(dataDirectory, sessions{session, :}, regExp, sdThreshold, 1, 500, 20);
	batchData{session, 1} = sessionOutput ;
end

disp('done') ; 
