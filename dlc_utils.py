import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import math
from tqdm import tqdm

def calculate_centroid(dlc_output_df):
	#df column names
	df_columns = list(dlc_output_df.columns)
	#calculate centroid coordiantes 
	x_centroids = np.zeros(1000)
	y_centroids = np.zeros(1000)
	for frame in range(len(dlc_output_df)):
		x_coordinates = [dlc_output_df[df_columns[0][0]][body_part]['x'].loc[frame] for body_part in list(set([df_columns[item][1] for item in range(len(df_columns))]))]
		x_centroid = sum(x_coordinates)/len(x_coordinates)
		y_coordinates = [dlc_output_df[df_columns[0][0]][body_part]['y'].loc[frame] for body_part in list(set([df_columns[item][1] for item in range(len(df_columns))]))]
		y_centroid = sum(y_coordinates)/len(y_coordinates)
		x_centroids[frame] = x_centroid 
		y_centroids[frame] = y_centroid 
	output_df_with_centroid = pd.concat([dlc_output_df, pd.DataFrame({(df_columns[0][0], 'centroid', 'x') : x_centroids, (df_columns[0][0], 'centroid', 'y') : y_centroids})], axis=1)
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

def align_behavior_data(msCam_timestamps, behavCam_timestamps):
	"""returns msCam Df with aligned timestamps
	"""
	#lists of ms cam and behavcam time stamps from time_stamps_df 
	behavCam_frames = []
	sys_clock_behavCam = []
	for msCam_frame in tqdm(range(0+1, len(msCam_timestamps)+1)):
		#get sys clock time of each miniscope recorded frame
		#sys_clock_msCam = time_stamps['sysClock'].loc[msCam_frame]
		#find behav cam frame closest to sys clock time of ms frame
		behavCam_frame = list(behavCam_timestamps.iloc[(behavCam_timestamps['sysClock']-msCam_timestamps['sysClock'].loc[msCam_frame]).abs().argsort()[:1]].index)[0]
		behavCam_frames.append(behavCam_frame)
		sys_clock_behavCam.append(behavCam_timestamps.loc[behavCam_frame]['sysClock'])

	msCam_timestamps['behavCam_frames'] = behavCam_frames
	msCam_timestamps['sys_clock_behavCam'] = sys_clock_behavCam

	return(msCam_timestamps)

def downsample_dlc_to_behavior(dlc_tracking_path, timestamps_file):
	dlc_analysis = pd.read_hdf(dlc_tracking_path)
	dlc_full = dlc_analysis.droplevel(0)
	dlc_full = dlc_full.reset_index()
	frame_clock_df = pd.read_table(timestamps_file)
	# load time stamps 
	msCam_timestamps = frame_clock_df[frame_clock_df['camNum'] == 0].set_index('frameNum')
	behavCam_timestamps = frame_clock_df[frame_clock_df['camNum'] == 1].set_index('frameNum')
	# reset initial clock value to 0 
	msCam_timestamps['sysClock'][1] = 0
	behavCam_timestamps['sysClock'][1] = 0
	#find beahviorcam frames closest to mscam frames
	msCam_timestamps = align_behavior_data(msCam_timestamps, behavCam_timestamps)
	msCam_timestamps.reset_index(inplace=True)
	#select only the behaviorcam frames closely matching msCam frames 
	ms_aligned = dlc_full.iloc[[row for row in msCam_timestamps['behavCam_frames'].values if row<len(dlc_full)],:]
	return(ms_aligned)

def downsample_and_interpolate(original_df, original_sf, downsampled_sf, interpolation_method):
	downsampled = original_df.resample(downsampled_sf).mean()
	upsampled = downsampled.resample(original_sf)
	interpolated = upsampled.interpolate(method=interpolation_method)
	return(interpolated)

def bin_by_activity_threshold(df_column, resting_time_threshold, active_time_threshold, resting_threshold, activity_threshold):
	moving_bins = np.zeros(len(df_column))
	for point in range(resting_time_threshold, len(df_column)):
		if df_column[point] < activity_threshold and not(any(df_column.values[point-resting_time_threshold:point] > resting_threshold)):
			moving_bins[point] = 0
		elif df_column[point] > 0.5 and all(df_column.values[point+1:point+active_time_threshold] > activity_threshold):
			moving_bins[point] = 1
	return(moving_bins)

def extended_bin_by_activity_threshold(rdf_column, resting_time_threshold, active_time_threshold, resting_threshold, activity_threshold):
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
























