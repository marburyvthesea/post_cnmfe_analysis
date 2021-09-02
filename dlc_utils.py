import pandas as pd
import numpy as np
import math
from tqdm import tqdm
#import statsmodels.formula.api as smf

def get_nearest_Cdf_td_tuples(bounds_tuple, index):
    movement_boundary_Cdf = (dlc_utils.nearest(index, bounds_tuple[0]), dlc_utils.nearest(index, bounds_tuple[1]))
    return(movement_boundary_Cdf)

def pull_out_fluorescence_from_velocity_parallel(velocity_trace_boundaries, velocity_trace, fluorescence_trace):
    """velocity trace and fluorescence trace are indexed by timedeltas
        e.g velocity_trace=grouped_raw_data[session]['velocity_data']
        fluorescence_trace=C_norm_df[session]
    """
    #convert indicies to timedelta and exclude those outside period of fluorescence recording
    movement_boundaries_time_delta = [(velocity_trace.iloc[movement_bounds[0]].name, velocity_trace.iloc[movement_bounds[1]].name) for movement_bounds in velocity_trace_boundaries if velocity_trace.iloc[movement_bounds[0]].name<C_norm_df[session].iloc[-1].name]
    #parallel this 
    p=Pool(7)
    movement_boundaries_Cdf = p.map(functools.partial(get_nearest_Cdf_td_tuples, fluorescence_trace.index), movement_boundaries_time_delta)
    p.close 
    fluorescence_during_movement = pd.concat([fluorescence_trace.loc[movement_bound_Cdf[0]:movement_bound_Cdf[1]] for movement_bound_Cdf in movement_boundaries_Cdf], axis=1, keys=movement_boundaries_Cdf)
    return(fluorescence_during_movement)

def get_resting_period_boundaries(trace_mask):
	"""input a numpy array of true/false values"""
	rest_onset = []
	rest_offset = []
	sample = 0
	while sample<len(trace_mask):
		if trace_mask[sample]==False:
			sample += 1
		elif trace_mask[sample]==True:
			rest_onset.append(sample)
			sample += 1
			while sample < len(trace_mask) and trace_mask[sample]==True:
				sample+=1
			
			rest_offset.append(sample) 

	resting_boundaries_indicies = list(zip(rest_onset, rest_offset))
	return(resting_boundaries_indicies)

def get_movement_offset_points(movement_onset_points, activity_threshold, session_data):
	rest_crossing_thresholds = []
	for movement_onset_point in movement_onset_points:
		i = movement_onset_point
		comp = lambda x : x>activity_threshold
		while i <= len(session_data) and comp(session_data.iloc[i])==True:
			i+=1
			if i>=len(session_data):
				rest_crossing_thresholds.append(i-1)
				break
			elif comp(session_data.iloc[i])==False:
				rest_crossing_thresholds.append(i)
				break
	return(rest_crossing_thresholds)
	
def nearest(items, to_compare):
    return min(items, key=lambda x: abs(x-to_compare))

def get_behavCam_avi_index(frame_number):
	#works for 30fps behavior cam frame rate, 1000 frames / file
	behavCam_video = int(frame_number/1000)+1
	frames_within_video =frame_number%1000
	return(behavCam_video, frames_within_video)

def get_matched_threshold_crossings(input_array, threshold):
	crossing_points = []
	negative_crossings = []
	for point in range(len(input_array)):
		#look for where acceleration crosses threshold
		if input_array[point]>threshold:
			crossing_points.append(point)
			#find point where acceleration crosses negative threshold again
			i = point
			crossed_neg_threshold=False
			while i < (len(input_array)) and crossed_neg_threshold==False:
				if input_array[i]<(threshold*-1):
					negative_crossings.append(i+1)
					crossed_neg_threshold=True
				i+=1
	indicies_to_cut = list(zip(crossing_points, negative_crossings))
	return(indicies_to_cut)

def calculate_centroid(dlc_output_df):
	#df column names
	df_columns = list(dlc_output_df.columns)
	#calculate centroid coordiantes 
	x_centroids = np.zeros(len(dlc_output_df))
	y_centroids = np.zeros(len(dlc_output_df))
	likelihoods = np.zeros(len(dlc_output_df))
	for frame in range(len(dlc_output_df)):
		x_coordinates = [dlc_output_df[df_columns[0][0]][body_part]['x'].loc[frame] for body_part in list(set([df_columns[item][1] for item in range(len(df_columns))]))]
		x_centroid = sum(x_coordinates)/len(x_coordinates)
		y_coordinates = [dlc_output_df[df_columns[0][0]][body_part]['y'].loc[frame] for body_part in list(set([df_columns[item][1] for item in range(len(df_columns))]))]
		y_centroid = sum(y_coordinates)/len(y_coordinates)
		x_centroids[frame] = x_centroid 
		y_centroids[frame] = y_centroid
		# add in an average of likelihoods for the centroid calculation here (weighted average?)
		likelihood = np.mean([dlc_output_df[df_columns[0][0]][body_part]['likelihood'].loc[frame] for body_part in list(set([df_columns[item][1] for item in range(len(df_columns))]))])
		likelihoods[frame] = likelihood 
	output_df_with_centroid = pd.concat([dlc_output_df, pd.DataFrame({(df_columns[0][0], 'centroid', 'x') : x_centroids, (df_columns[0][0], 'centroid', 'y') : y_centroids, 
		(df_columns[0][0], 'centroid', 'likelihood') : likelihoods})], axis=1)
	return(output_df_with_centroid)


def difference_df(dlc_output_df):
	df_columns = list(dlc_output_df.columns)
	coordinates_delta_df = pd.concat([dlc_output_df[df_columns[0][0]][body_part][['x', 'y']] for body_part in list(set([df_columns[item][1] for item in range(len(df_columns))]))], 
		keys=list(set([df_columns[item][1] for item in range(len(df_columns))])), axis=1).diff()
	return(coordinates_delta_df)

#calculate velocity from body part coordinates
def velocity(x_diff, y_diff):
	v_t = math.sqrt(x_diff**2+y_diff**2)
	return(v_t)

#this one not working
def return_velocity_dataframe(df_input):
	coordinates_delta_df = difference_df(df_input)
	df_columns = list(coordinates_delta_df.columns)
	velocity_df = pd.DataFrame(np.transpose(np.array([np.array([velocity(coordinates_delta_df[body_part]['x'].values[frame],coordinates_delta_df[body_part]['y'].values[frame]) for frame in range(len(coordinates_delta_df))]) for body_part in list(set([df_columns[item][1] for item in range(len(df_columns))]))])), columns=list(set([df_columns[item][1] for item in range(len(df_columns))]))) 
	return(velocity_df)

def velocity_df_from_difference_df(difference_df):
	df_columns = list(difference_df.columns)
	velocity_df = pd.DataFrame(np.transpose(np.array([np.array([velocity(difference_df[body_part]['x'].values[frame],difference_df[body_part]['y'].values[frame]) 
								for frame in range(len(difference_df))]) for body_part in list(set([df_columns[item][0] 
								for item in range(len(df_columns))]))])), columns=list(set([df_columns[item][0] for item in range(len(df_columns))]))) 
	return(velocity_df)


def align_behavior_data(msCam_timestamps, behavCam_timestamps):
	"""returns msCam Df with aligned timestamps
	"""
	#lists of ms cam and behavcam time stamps from time_stamps_df 
	behavCam_frames = []
	sys_clock_behavCam = []
	for msCam_frame in tqdm(list(msCam_timestamps.index)):
		#get sys clock time of each miniscope recorded frame
		#sys_clock_msCam = time_stamps['sysClock'].loc[msCam_frame]
		#find behav cam frame closest to sys clock time of ms frame
		behavCam_frame = list(behavCam_timestamps.iloc[(behavCam_timestamps['sysClock']-msCam_timestamps['sysClock'].loc[msCam_frame]).abs().argsort()[:1]].index)[0]
		behavCam_frames.append(behavCam_frame)
		sys_clock_behavCam.append(behavCam_timestamps.loc[behavCam_frame]['sysClock'])

	msCam_timestamps['behavCam_frames'] = behavCam_frames
	msCam_timestamps['sys_clock_behavCam'] = sys_clock_behavCam

	return(msCam_timestamps)

def downsample_dlc_to_behavior(dlc_tracking_path, timestamps_file, msCam_camnum=0, behavCam_camnum=1):
	"""
	use the timestamps file to get the closest behavior cam frame to each miniscope cam frame
	typically the mcCam is cam "0" and the behavCam is cam "1" but can change 
	"""
	dlc_full = pd.read_hdf(dlc_tracking_path)
	#dlc_full = dlc_analysis.droplevel(0)
	#dlc_full = dlc_full.reset_index(drop=True)
	frame_clock_df = pd.read_table(timestamps_file)
	# load time stamps 
	msCam_timestamps = frame_clock_df[frame_clock_df['camNum'] == msCam_camnum].set_index('frameNum')
	behavCam_timestamps = frame_clock_df[frame_clock_df['camNum'] == behavCam_camnum].set_index('frameNum')
	# reset initial clock value to 0 
	msCam_timestamps['sysClock'][1] = 0
	behavCam_timestamps['sysClock'][1] = 0
	#find beahviorcam frames closest to mscam frames
	msCam_timestamps = align_behavior_data(msCam_timestamps, behavCam_timestamps)
	msCam_timestamps.reset_index(inplace=True)
	#select only the behaviorcam frames closely matching msCam frames 
	ms_aligned = dlc_full.iloc[[row-1 for row in msCam_timestamps['behavCam_frames'].values if row<len(dlc_full)],:]
	ms_aligned.reset_index(inplace=True, drop=True)
	aligned_out = pd.concat([ms_aligned, msCam_timestamps.reset_index().loc[:len(ms_aligned)-1]], axis=1)

	return(aligned_out)

def downsample_mmtracking(mm_tracking_nondownsampled, timestamps_file, msCam_camnum=0, behavCam_camnum=1):
	"""
	use the timestamps file to get the closest behavior cam frame to each miniscope cam frame
	typically the mcCam is cam "0" and the behavCam is cam "1" but can change 
	"""

	frame_clock_df = pd.read_table(timestamps_file)
	# load time stamps 
	msCam_timestamps = frame_clock_df[frame_clock_df['camNum'] == msCam_camnum].set_index('frameNum')
	behavCam_timestamps = frame_clock_df[frame_clock_df['camNum'] == behavCam_camnum].set_index('frameNum')
	# reset initial clock value to 0 
	msCam_timestamps['sysClock'][1] = 0
	behavCam_timestamps['sysClock'][1] = 0
	#find beahviorcam frames closest to mscam frames
	msCam_timestamps = align_behavior_data(msCam_timestamps, behavCam_timestamps)
	msCam_timestamps.reset_index(inplace=True)
	#select only the behaviorcam frames closely matching msCam frames 
	ms_aligned = mm_tracking_nondownsampled.iloc[[row-1 for row in msCam_timestamps['behavCam_frames'].values if row<len(mm_tracking_nondownsampled)],:]
	ms_aligned.reset_index(inplace=True, drop=True)
	aligned_out = pd.concat([ms_aligned, msCam_timestamps.reset_index().loc[:len(ms_aligned)-1]], axis=1)

	return(aligned_out)

def downsample_and_interpolate(original_df, original_sf, downsampled_sf, interpolation_method):
	downsampled = original_df.resample(downsampled_sf).mean()
	upsampled = downsampled.resample(original_sf)
	interpolated = upsampled.interpolate(method=interpolation_method)
	return(interpolated)

def bin_by_activity_threshold_return_column(df_column, resting_time_threshold, active_time_threshold, crossing_threshold, resting_threshold, activity_threshold):
	moving_bins = np.zeros(len(df_column))
	# test if each point in df column is above the activity threshold
	# start at sample point that is equivalent to the length of samples of the resting period
	for point in range(resting_time_threshold, len(df_column)):
		if df_column[point] < activity_threshold:
			moving_bins[point] = 0
		#test if the mean of values before the threshold is below a certain level, i.e. starts from rest
		elif df_column[point] > crossing_threshold and (np.mean(df_column.values[point-resting_time_threshold:(point-1)]) < resting_threshold):
			# test if the velocity remains above a given value for set period
			if not(any(df_column.values[point+1:point+active_time_threshold] < activity_threshold)):
				moving_bins[point] = 1
			else:
				moving_bins[point] = 0
	return(moving_bins)

def bin_by_activity_threshold_2(df_column, resting_time_threshold, active_time_threshold, crossing_threshold, resting_threshold, activity_threshold):
	moving_bins = np.zeros(len(df_column))
	# test if each point in df column is above the activity threshold
	# start at sample point that is equivalent to the length of samples of the resting period
	for point in range(resting_time_threshold, len(df_column)):
		if df_column[point] < activity_threshold:
			moving_bins[point] = 0
		#test if the mean of values before the threshold is below a certain level, i.e. starts from rest
		elif df_column[point] > crossing_threshold and (np.mean(df_column.values[point-resting_time_threshold:(point-1)]) < resting_threshold):
			# test if the velocity remains above a given value for set period
			if not(any(df_column.values[point+1:point+active_time_threshold] < activity_threshold)):
				moving_bins[point] = 1
			else:
				moving_bins[point] = 0
	return(moving_bins)

def bin_by_activity_threshold(df_column, resting_time_threshold, active_time_threshold, crossing_threshold, resting_threshold, activity_threshold):
	moving_bins = np.zeros(len(df_column))
	# test if each point in df column is above the activity threshold
	# start at sample point that is equivalent to the length of samples of the resting period
	for point in range(resting_time_threshold, len(df_column)):
		if df_column[point] < activity_threshold:
			moving_bins[point] = 0
		# if the sample point is above the activity theshold, also check if the resting period is below threshold and the activity
		# lasts for the active time threshold
		elif df_column[point] > crossing_threshold and (np.mean(df_column.values[point+1:point+active_time_threshold] > activity_threshold)):
			if not(any(df_column.values[point-resting_time_threshold:(point-1)] > resting_threshold)):
				moving_bins[point] = 1
			else:
				moving_bins[point] = 0
	return(moving_bins)

def bin_by_resting_threshold(df_column, resting_time_threshold, active_time_threshold, crossing_threshold, resting_threshold, activity_threshold):
	moving_bins = np.zeros(len(df_column))
	for point in range(active_time_threshold, len(df_column)):
		if df_column[point] > activity_threshold:
			moving_bins[point] = 0
		elif df_column[point] < crossing_threshold and not(np.mean(df_column.values[point+1:point+resting_time_threshold] > resting_threshold)):
			if (any(df_column.values[point-active_time_threshold:(point-1)] > activity_threshold)):
				moving_bins[point] = 1
			else:
				moving_bins[point] = 0
	return(moving_bins)

def select_trigger_regions(binned_velocity, activity_threshold, resting_threshold, resting_baseline):
	transition_indicies = []
	for point in range(resting_baseline, len(binned_velocity)-resting_baseline):
		if binned_velocity[point]>activity_threshold and not any(binned_velocity[int(point-resting_baseline):point]>resting_threshold):
			transition_indicies.append(point)
	return(np.array(transition_indicies))

def extended_bin_by_activity_threshold(df_column, resting_time_threshold, active_time_threshold, resting_threshold, activity_threshold):
	moving_bins_extended = np.zeros(len(df_column))
	point = 0
	while point < len(df_column):
		if df_column[point] < activity_threshold and not(any(df_column.values[point-resting_time_threshold:point] > resting_threshold)):
			moving_bins_extended[point] = 0
			point = point + 1
		elif df_column[point] > 0.5 and all(df_column.values[point+1:point+active_time_threshold] > activity_threshold):
			moving_bins_extended[point] = 1
			point = point +20
		else:
			point = point+1 
	return(moving_bins_extended)

## binning fluorescence by velocity

def bin_C_by_V_bins(V_df, body_part, C_df, bin_numbers):
	# bin velocity of body part
	binned = pd.cut(V_df[body_part].values, bin_numbers)
	# integer values correspond to bins
	v_data_binned = binned.codes
	# actual values of velocity bin ends
	bin_intervals=binned.categories.values
	# group the fluorescence at each data point into the velocity bins
	num_cells = len(C_df.columns)
	cells_c_binned_by_v = {}
	for cell in range(1, num_cells):
		C_by_cell_grouped = []
		for point in range(len(C_df[cell].values)):
			C_by_cell_grouped.append((v_data_binned[point], C_df[cell].values[point]))
		# first item in tuple will be bin identity, next is fluorescence value
		cells_c_binned_by_v[cell] = (np.array([item[0] for item in C_by_cell_grouped]), np.array([item[1] for item in C_by_cell_grouped]))
	# create averages of binned data
	means_by_cell = {}
	for cell in range(1, num_cells):
		means_by_bin = []
		for bin_ in range(0, bin_numbers):
			means_by_bin.append((bin_, np.mean(np.array([cells_c_binned_by_v[cell][1][point] for point in np.where(cells_c_binned_by_v[cell][0]==bin_)]))))
		means_by_cell[cell] = means_by_bin
	return(cells_c_binned_by_v, means_by_cell, bin_intervals)

## downsampling and binning recordings session

def downsample_session_and_bin_C_by_V(downsampled_interval_seconds, number_of_bins, body_part, velocity_df, fluorescence_df):
	"""velocity and fluorescence dfs should have timedelta index"""
	new_sampling_interval = downsampled_interval_seconds
	interpolated = velocity_df.set_index(pd.to_timedelta(np.linspace(0, len(velocity_df)*(1/20), len(velocity_df)), 
		unit='s'), drop=True)
	interpolated_downsampled = interpolated.resample(str(new_sampling_interval)+'S').max()
	# downsample C trace to match 
	C_z_scored_downsampled = fluorescence_df.resample(str(new_sampling_interval)+'S').max()
	# binning C by V
	C_binned_by_V, means_by_cell, bin_intervals = bin_C_by_V_bins(interpolated_downsampled, body_part, C_z_scored_downsampled, 
		number_of_bins)
	# C binned by V df
	C_by_v_df = pd.concat([pd.DataFrame(value, index=['bin_id', 'C_df']) for key, value in C_binned_by_V.items()], axis=0, keys=C_binned_by_V.keys(), names=['cells']).transpose()
	# C binned by V means df 
	C_by_v_means_df = pd.concat([pd.DataFrame(value, index=bin_intervals, columns=['bin', 'C_df_mean']) for key, value in means_by_cell.items()], axis=1, keys=means_by_cell.keys(), names=['cells'])

	return(C_by_v_df, C_by_v_means_df)

#def create_regression_models_per_cell(cells_mean_C_binned_by_V, polynomial_degree):
#	cell_results = {}
#	num_bins = len(cells_mean_C_binned_by_V)
#	for cell in list(cells_mean_C_binned_by_V.columns):
#		#degree of polynomial model
#		deg = polynomial_degree
#		x_to_fit = np.linspace(1, num_bins, num_bins)
#		y_to_fit = cells_mean_C_binned_by_V[cell].values
#		#df for stats models
#		fit_data = pd.DataFrame(columns=['y', 'x'])
#		fit_data['y'] = y_to_fit
#		fit_data['x'] = x_to_fit
#		fit_data.dropna(inplace=True)

		# poly1d object for ease of plotting
#		p1d = np.poly1d(np.polyfit(fit_data['x'].values, fit_data['y'].values, deg))
#		model = np.poly1d(np.polyfit(fit_data['x'].values, fit_data['y'].values, deg))
#		results = smf.ols(formula='y ~ model(x)', data=fit_data).fit()
#		cell_results[cell] = {'p1d' : p1d, 'model' : model, 'statsmodel_results' : results, 'fit_df' : fit_data}

#	return(cell_results)

def plot_cell_regression(regression_results, cell, cells_mean_C_binned_by_V):

	num_bins = len(cells_mean_C_binned_by_V)
	p1d = regression_results[cell]['p1d']
	xp = np.linspace(0, num_bins, num_bins)

	return(xp, p1d)


























