import pandas as pd 
import numpy as np
import h5py
import sys
sys.path.append('/home/jma819/post_cmfe_analysis')
sys.path.append('/Users/johnmarshall/Documents/Analysis/PythonAnalysisScripts/post_cmfe_analysis/jjm_misc')
import python_utils_jjm as utils_jjm
import dlc_utils
import matplotlib.pyplot as plt
from matplotlib import animation, rc
import av
from tqdm import tqdm
import multiprocessing as mp
from itertools import product
import create_analysis_videos_module as cvm 


#input session (and list of events/cells?) as command line arguments 
#session = 'GRIN035_H14_M40_S34'
session = sys.argv[1]
save_dir = sys.argv[2]
print('session to load is:')
print(session)
#need to get keys first from all session dataframes to read into pandas 
h5file=pd.HDFStore('/projects/b1118/miniscope/analysis/event_analysis/movement_regions_for_display_2.h5')
keys=h5file.keys()
h5file.close()
#load fluorescence in event regions
z_scored_events_by_session = {key_idx.strip('/'):pd.read_hdf('/projects/b1118/miniscope/analysis/event_analysis/movement_regions_for_display_2.h5', key=key_idx) for key_idx in keys}
#load spatial components 
spatial_h5file=h5py.File('/projects/b1118/miniscope/analysis/spatial_data/spatial_components_test.h5', 'r')
spatial_contours = {session:spatial_h5file[session][:] for session in list(spatial_h5file.keys())}
spatial_h5file.close()
#velocity data
velocity_data = pd.read_hdf('/projects/b1118/miniscope/analysis/event_analysis/compiled_velocity_all_sessions.h5')
#times from msCam trace 
event_start_indicies_in_session = utils_jjm.return_list_of_level_indicies_in_session(z_scored_events_by_session[session].loc['z_scored_movement_regions'], 0)
event_end_indicies_in_session = utils_jjm.return_list_of_level_indicies_in_session(z_scored_events_by_session[session].loc['z_scored_movement_regions'], 1)

event_bounds = [event_bound for event_bound in zip(event_start_indicies_in_session, event_end_indicies_in_session)]

cells_to_plot = list(z_scored_events_by_session[session].loc['z_scored_movement_regions'].columns)

cvm.create_compiled_event_videos_for_session(z_scored_events_by_session, velocity_data, spatial_contours, session, event_bounds, cells_to_plot, save_dir, in_vmin=0, in_vmax='norm_to_each_video')












































