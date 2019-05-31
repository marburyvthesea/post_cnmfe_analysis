import numpy as np
import pandas as pd
from tqdm import tqdm
from matplotlib import pyplot as plt

def import_test():
	print ('imported!')
	return()

def return_triggered_events(trace_to_align, trigger_points, sample_window):
	"""
	Inputs:
	sample_window is tuple (samples before, samples after)
	"""
	traces_out = {}
	for point in trigger_points:
		traces_out[point] = trace_to_align[point-sample_window[0]:point+sample_window[1]]
	traces_out_df = pd.DataFrame(traces_out)

	return(traces_out_df)


def count_events_in_array_threshold(selection, Fs, time_to_wait, threshold=0, up=True):
	""" Counts the number of events (e.g action potentials (AP)) in the current trace.
	Arguments:
	trace -- 1d numpy array
	dt -- sampling interval
	threshold -- (optional) detection threshold (default = 0).
	up -- (optional) True (default) will look for upward events, False downwards.
	Returns:
	An integer with the number of events.
	Examples:
	count_events(500,1000) returns the number of events found between t=500 ms and t=1500 ms
	above 0 in the current trace and shows a stf marker.
	count_events(500,1000,0,False,-10,i) returns the number of events found below -10 in the 
	trace 
	"""
	# add in a minimum bout length?
	time_threshold_samples = int(time_to_wait*Fs)
	# algorithm to detect events
	EventCounter,i = 0,0 # set counter and index to zero
	# list of sample points
	sample_points = []
	# choose comparator according to direction:
	if up:
		comp = lambda a, b: a > b
	else:
		comp = lambda a, b: a < b
	# loop over array
	while i<len(selection):

		if comp(float(selection[i]),float(threshold)):

			to_add = i
			bout_start = i

			while i<len(selection) and comp(selection[i],threshold):
				i+=1 # skip values if index in bounds AND until the value is below/above threshold again

			bout_end = i 
			if time_threshold_samples < (bout_end - bout_start):
				EventCounter +=1
				sample_points.append(bout_start)   

		else:
			i+=1

	return (EventCounter, sample_points)

def align_and_return_ezTrack(tracking_df, timestamps_df_path, CNMFE_frame_range):

	timestamps_df = pd.read_table(timestamps_df_path)

	# timestamps of msCam and behavCam
	msCam_timestamps = timestamps_df[timestamps_df['camNum'] == 0].set_index('frameNum')[CNMFE_frame_range[0]-1:CNMFE_frame_range[1]]
	behavCam_timestamps = timestamps_df[timestamps_df['camNum'] == 1].set_index('frameNum')

	# length to align is length of tracking df
	behav_trimmed = behavCam_timestamps.loc[:len(tracking_df)]

	# this produces a data frame with frame by frame tracking info from ezTrack 
	behav_trimmed['Distance'] = np.array(tracking_df['Distance'])

	#first and last frame to align from CNMFE data
	first_frame = CNMFE_frame_range[0]
	final_frame = CNMFE_frame_range[1]
	
	# reset initial clock value to 0 
	msCam_timestamps['sysClock'][1] = 0
	behav_trimmed['sysClock'][1] = 0
	
	print(msCam_timestamps.head())
	print(msCam_timestamps['sysClock'].loc[CNMFE_frame_range[0]])

	# add following parameters to msCam data frame
	sys_clocks_behavCam = []
	behavCam_frames = []
	msCam_frames = []
	dist_btw_frames = []
	velocity = []

	# need to check alignemnt of new series here
	for msCam_frame in range(first_frame, final_frame+1):
		#get sys clock time of each miniscope recorded frame
		#find closest behav cam frame by sys clock time, 
		print(msCam_frame)
		sys_clock_msCam = msCam_timestamps['sysClock'].loc[msCam_frame]
		print(sys_clock_msCam)
		msCam_frames.append(list(msCam_timestamps.loc[msCam_timestamps['sysClock'] == sys_clock_msCam].index)[0])
		behavCam_frame = list(behav_trimmed.iloc[(behav_trimmed['sysClock']-sys_clock_msCam).abs().argsort()[:1]].index)[0]
		behavCam_frames.append(behavCam_frame)
		sys_clocks_behavCam.append(behav_trimmed.loc[behavCam_frame]['sysClock'])
		delta_d = behav_trimmed.loc[behavCam_frame]['Distance']
		dist_btw_frames.append(delta_d)
		#velocity is the difference in the distance between frames divived by the sysClcok difference
		if behavCam_frame-1 == 0:
			# use average framerate of 33msec to calculate initial velcoity 
			delta_t=33
		else:
			delta_t = behav_trimmed.loc[behavCam_frame]['sysClock']-behav_trimmed.loc[behavCam_frame-1]['sysClock']
		velocity.append(delta_d/(delta_t/1000))

	# add final values to df
	msCam_timestamps['velocity'] = velocity
	msCam_timestamps['Distance'] = dist_btw_frames
	msCam_timestamps['behavCam_frames'] = behavCam_frames
	msCam_timestamps['msCam_frames'] = msCam_frames
	msCam_timestamps['sys_clocks_behavCam'] = sys_clocks_behavCam

	return(msCam_timestamps)


def align_and_return(tracking_df_path, timestamps_df_path):
#input timestamp data from miniscope DAQ and behaviorsoft tracking data

	tracking_df = pd.read_table(tracking_df_path, header=None, names=['dist_btw_frames'])

	timestamps_df = pd.read_table(timestamps_df_path)

	# set tracking data frame index to frame numbers
	len(tracking_df)
	new_index = np.array([i for i in range(1, len(tracking_df)+1)])
	tracking_df['frameNum'] = pd.Series(new_index)
	tracking_df = tracking_df.set_index('frameNum')

	# timestamps of msCam and behavCam
	msCam_timestamps = timestamps_df[timestamps_df['camNum'] == 0]
	behavCam_timestamps = timestamps_df[timestamps_df['camNum'] == 1].set_index('frameNum')

	# length to align is length of tracking df
	behav_trimmed = behavCam_timestamps.loc[:len(tracking_df)]

	# this produces a data frame with frame by frame tracking info from behavior soft 
	behav_trimmed['dist_btw_frames'] = tracking_df['dist_btw_frames']

	msCam_timestamps = msCam_timestamps.set_index('frameNum')

	# add following parameters to msCam data frame
	sys_clocks_behavCam = [1]
	behavCam_frames = [1]
	dist_btw_frames = [0]
	velocity = [0]

	# need to check alignemnt of new series here
	for msCam_frame in tqdm(range(1, len(msCam_timestamps))):
		sys_clock_msCam = msCam_timestamps['sysClock'].loc[msCam_frame]
		behavCam_frame = list(behav_trimmed.iloc[(behav_trimmed['sysClock']-sys_clock_msCam).abs().argsort()[:1]].index)[0]
		behavCam_frames.append(behavCam_frame)
		sys_clocks_behavCam.append(behav_trimmed.loc[behavCam_frame]['sysClock'])
		delta_d = behav_trimmed.loc[behavCam_frame]['dist_btw_frames']
		dist_btw_frames.append(delta_d)
		#velocity is the difference in the distance between frames divived by the sysClcok difference
		delta_t = behav_trimmed.loc[behavCam_frame]['sysClock']-behav_trimmed.loc[behavCam_frame-1]['sysClock']
		velocity.append(delta_d/(delta_t/1000))

	# add final values to df
	msCam_timestamps['velocity'] = velocity
	msCam_timestamps['dist_btw_frames'] = dist_btw_frames
	msCam_timestamps['behavCam_frames'] = behavCam_frames
	msCam_timestamps['sys_clocks_behavCam'] = sys_clocks_behavCam

	return(msCam_timestamps)