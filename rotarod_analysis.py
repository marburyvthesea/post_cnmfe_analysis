"""
helper functions for analysis of miniscope roatrod data
JJM jjm2128@gmail.com
5/11/2020
"""

import scipy.io as sio
import numpy as np
import pandas as pd
import python_utils_jjm as utils_jjm
from scipy import stats


def get_CNMFE_fluorescence(CNMFE_file):
	# get fluorescence manipulations for whole session
	cell_fluorescence = sio.loadmat(CNMFE_file)
	C_timedelta = utils_jjm.create_fluorescence_time_delta(cell_fluorescence['C'])
	C_normalized = C_timedelta.apply(utils_jjm.normalize).set_index(pd.to_timedelta(np.linspace(0, (len(C_timedelta)-1)*(1/20), len(C_timedelta)), unit='s'), drop=True)
	C_z_scored = C_timedelta.apply(stats.zscore).set_index(pd.to_timedelta(np.linspace(0, (len(C_timedelta)-1)*(1/20), len(C_timedelta)), unit='s'), drop=True)
	C_normalized_z_scored = C_normalized.apply(stats.zscore).set_index(pd.to_timedelta(np.linspace(0, (len(C_normalized)-1)*(1/20), len(C_normalized)), unit='s'), drop=True)
	com_df, spatial_components = utils_jjm.return_spatial_info(CNMFE_file, 0.6)
	cell_contours, for_dims = utils_jjm.create_contour_layouts(spatial_components)
	#filter out small cells for analysis
	C_normalized_z_scored_filtered = utils_jjm.filter_out_by_size(C_normalized_z_scored, cell_contours, 
		for_dims, 0.6, 100).drop(['msCamFrame'], axis=1)
	CNMFE_data = {'C': C_timedelta, 'C_z_scored': C_z_scored, 'C_normalized': C_normalized, 'C_normalized_z_scored': C_normalized_z_scored, 
				'com' : com_df, 'spatial_components' : spatial_components, 'cell_contours': cell_contours,  
				'for_dims' : for_dims}
	return(CNMFE_data)


def align_frames(CNMFE_file):
	"""
	create a data frame of recording session with aligned frames for rotarod CNMFE session
	"""
	CNMFE_results = sio.loadmat(CNMFE_file)
	# list of individual files making up batch analyzed file
	file_array = CNMFE_results['P'][0][0][13]
	session_names = []
	frames_indicies = []
	for session in range(len(file_array)):
		msCam_session = file_array[session][0][0].split('/')[8]
		frames = file_array[session][0][0].split('/')[10]
		frames_idx = frames.strip('frames_').split('_')
		session_names.append(msCam_session)
		frames_indicies.append(frames_idx)

	total_frames = np.sum(np.array([(1+int(frames_indicies[session_idx][1]))-int(frames_indicies[session_idx][0]) for session_idx in range(len(session_names))]))

	session_key = pd.DataFrame(frames_indicies, index=session_names)
	session_key['cumulative_frames'] = np.nan*np.ones(len(session_names))
	session_key = session_key.transpose()

	final_frames = pd.DataFrame({k:v for k,v in zip(np.unique(np.array(session_names)), 
					[session_key[session].loc[1].values[-1:] for session in np.unique(np.array(session_names))])}, 
					index=['final_frame']).transpose()

	final_frames['cumulative_frames'] = np.cumsum(np.array([int(frame) for frame in final_frames['final_frame'].values]))
	# pull out data by session
	frame_indicies = []
	for session in np.array(final_frames.index):
		session_idx = np.where(np.array(final_frames.index)==session)[0][0]
		frame_end = final_frames.iloc[session_idx]['cumulative_frames']
		if session_idx != 0:
			frame_start = final_frames.iloc[session_idx-1]['cumulative_frames']
		else:
			frame_start=0
		frames=(frame_start, frame_end)
		#start/stop indicies of session
		frame_indicies.append(frames)
	final_frames['frame_indicies'] = frame_indicies

	return(final_frames)


def trial_stats(final_frames, C_normalized_z_scored_filtered, event_thresold):
	by_trial = {}
	trial_stats = {}
	for session in np.array(final_frames.index):
		event_indicies, event_times, event_ISIs = utils_jjm.get_ISIs(C_normalized_z_scored_filtered.iloc[final_frames.loc[session]['frame_indicies'][0]:final_frames.loc[session]['frame_indicies'][1]], 20, .1, 
			np.array(C_normalized_z_scored_filtered.columns), event_thresold)
		by_trial[session] = {'event_indicies' : event_indicies, 'event_times': event_times, 'event_ISIs': event_ISIs}

		event_counts_by_cell = [len(by_trial[session]['event_indicies'][array]) for array in range(len(by_trial[session]['event_indicies']))]
		event_rates_by_cell = [count/((1/20)*float(final_frames.loc[session]['frame_indicies'][1]-final_frames.loc[session]['frame_indicies'][0])) for count in event_counts_by_cell]
		trial_stats[session] = {'event_counts_by_cell' : event_counts_by_cell , 'event_rates_by_cell' : event_rates_by_cell}

	return(by_trial, trial_stats)



