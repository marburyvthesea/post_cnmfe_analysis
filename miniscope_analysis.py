

import scipy.io as sio
import pandas as pd

import sys
sys.path.append('/Users/johnmarshall/caiman_data/post_cnmfe_analysis')
import align_msCam_tobehavior as align_tracking


class miniscope_session(object):
	"""
	class to store results of miniscope recording session analyzed with matlab CNMFE
	"""
	def __init__(self, results_filename):
		
		# output of MATLAB cnmfe analysis package
		self.cnmfe_results = sio.loadmat(results_filename)

		# dictionary with information about mouse
		self.session_info = {}

		# attribute for stroting behavior info
		self.aligned_to_behavior = None 


	def align_to_eztrackoutput(self, miniscope_time_stamp_file, location_files, frame_range):

		dfs = []
		
		for file in location_files:
			dfs.append(pd.read_csv(file, usecols=[1,9,10,11]))

		tracking_concacted = pd.concat(dfs)

		self.aligned_to_behavior = align_tracking.align_and_return_ezTrack(tracking_concacted, miniscope_time_stamp_file, frame_range)
		
		return()

## misc useful functions 
def count_events_in_array(trace, Fs, time_to_wait, threshold=0, up=True):
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
	samples_to_skip = int(time_to_wait*Fs)
	selection = trace
	# algorithm to detect events
	EventCounter,i = 0,0 # set counter and index to zero
	# list of sample points
	sample_points = []
	# choose comparator according to direction:
	if up:
		comp = lambda a, b: a > b
	else:
		comp = lambda a, b: a < b
	# run the loop
	while i<len(selection):

		if comp(float(selection[i]),float(threshold)):
			EventCounter +=1
			sample_points.append(i)

			i += 1 #skip set number of samples from threshold crossing
			
			while i<len(selection) and comp(selection[i],threshold):
				i+=1 # skip values if index in bounds AND until the value is below/above threshold again
		else:
			i+=1

	return (EventCounter, sample_points)


