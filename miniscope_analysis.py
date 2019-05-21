

import scipy.io as sio
import pandas as pandas

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


	def align_to_eztrackoutput(path_to_eztrackfile, miniscope_time_stamp_file, location_files, max):
		dfs = []
		
		for file in location_files:
			dfs.append(pd.read_csv(file, usecols=[1,9,10,11]))

		tracking_concactenated = pd.concat(dfs)
		self.aligned_to_behavior = align_tracking.align_and_return_ezTrack(tracking_concacted, miniscope_time_stamp_file, 26000)
		return()


