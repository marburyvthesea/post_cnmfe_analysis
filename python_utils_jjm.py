#!/usr/bin/env python3.5
# -*- coding: utf-8 -*-
"""
Helper functions to support 'run_cnmfe_matlab.py'

Please see that file for more details.

Created on Nov 1 2017

@author: tamachado@stanford.edu
@author: john-marshall@northwestern.edu
"""

from past.utils import old_div
from matplotlib import pyplot as plt
from scipy import stats
import scipy.sparse as sparse
import numpy as np
import miniscope_analysis as ma
from tqdm import tqdm
import scipy.io as sio
import pandas as pd
import scipy.spatial.distance as dist
import itertools
import statsmodels.formula.api as smf
import math
import dlc_utils

def return_list_of_level_indicies_in_session(event_regions_in_session_df, event_level_idx):
    """eg event_level_idx=0, start idx, 1 stop idx """
    indicies = list(set([event_regions_in_session_df.index[idx][event_level_idx] for idx in range(len(event_regions_in_session_df.index))]))
    indicies.sort()
    return(indicies)

def calculate_event_probability(baseline_regions, to_compare, z_score_event_threshold):
  #event probability by cell, comparison regions
  cell_event_probability_comparison = pd.DataFrame({cell:np.count_nonzero(to_compare[cell].values>z_score_event_threshold)/len(to_compare) 
                                                for cell in list(to_compare.columns)}, index=['event probability'])
  #event probability by cell, baseline regions 
  cell_event_probability_baseline = pd.DataFrame({cell:np.count_nonzero(baseline_regions[cell].values>z_score_event_threshold)/len(baseline_regions) 
                                            for cell in list(baseline_regions.columns)}, index=['event probability'])
  return(cell_event_probability_comparison, cell_event_probability_baseline)


def z_score_movement_by_rest(session_binned):
  """session binned shoud contain 'resting_fluorescence' and 'movement_fluorescence' data frames"""
  resting_fluorescence_mean = session_binned['resting_fluorescence'].mean()
  resting_fluorescence_std = session_binned['resting_fluorescence'].std()
  #indicies of movment onset and offset
  movement_onsets = return_list_of_level_indicies_in_session(session_binned['movement_fluorescence'], 0)
  movement_offsets = return_list_of_level_indicies_in_session(session_binned['movement_fluorescence'], 1)
  rest_onsets = return_list_of_level_indicies_in_session(session_binned['resting_fluorescence'], 0)
  rest_offsets = return_list_of_level_indicies_in_session(session_binned['resting_fluorescence'], 1)
  #use the resting mean and standard deviation values to z score 
  #z score movement regions
  z_scored_movement_regions = pd.concat([(session_binned['movement_fluorescence'].loc[movement_onset].loc[movement_offset]-resting_fluorescence_mean)/resting_fluorescence_std
                                       for movement_onset, movement_offset in zip(movement_onsets, movement_offsets)], keys=list(zip(movement_onsets, movement_offsets)))
  #z score rest regions
  z_scored_rest_regions = pd.concat([(session_binned['resting_fluorescence'].loc[rest_onset].loc[rest_offset]-resting_fluorescence_mean)/resting_fluorescence_std
                                       for rest_onset, rest_offset in zip(rest_onsets, rest_offsets)], keys=list(zip(rest_onsets, rest_offsets)))
  return({'z_scored_movement_regions':z_scored_movement_regions , 'z_scored_rest_regions': z_scored_rest_regions})

def pull_out_fluorescence_from_velocity_bounds(velocity_trace_boundaries, velocity_trace, fluorescence_trace):
  """velocity trace and fluorescence trace are indexed by timedeltas
        e.g velocity_trace=grouped_raw_data[session]['velocity_data']
        fluorescence_trace=C_norm_df[session]
  """ 
  #convert indicies to timedelta and exclude those outside period of fluorescence recording
  movement_boundaries_time_delta = [(velocity_trace.iloc[movement_bounds[0]].name, velocity_trace.iloc[movement_bounds[1]].name) for movement_bounds in velocity_trace_boundaries if velocity_trace.iloc[movement_bounds[0]].name<fluorescence_trace.iloc[-1].name]
  #parallelizing this could improve speed
  movement_boundaries_Cdf = [(dlc_utils.nearest(fluorescence_trace.index, movement_bound[0]), dlc_utils.nearest(fluorescence_trace.index, movement_bound[1])) for movement_bound in tqdm(movement_boundaries_time_delta)]
  #return concactenated fluorescence from these periods
  fluorescence_during_periods = pd.concat([fluorescence_trace.loc[movement_bound_Cdf[0]:movement_bound_Cdf[1]].reset_index(drop=True) for movement_bound_Cdf in movement_boundaries_Cdf], axis=0, keys=movement_boundaries_Cdf)
  return(fluorescence_during_periods)

def return_movement_and_rest_for_session(moving_periods_by_session, resting_boundaries_by_session, grouped_raw_data,
  C_norm_df, resting_period_threshold, session):
  movement_boundaries = list(moving_periods_by_session[session].columns)
  pre_movement_boundaries = [(movement_bound[0]-80, movement_bound[0]) for movement_bound in movement_boundaries]
  #filter out short "resting" periods
  resting_boundaries_long = [(boundary[0], boundary[1]) for boundary in resting_boundaries_by_session[session] if (boundary[1]-boundary[0]>resting_period_threshold)]
  if len(movement_boundaries)>0:
    movement_fluorescence = pull_out_fluorescence_from_velocity_bounds(movement_boundaries, grouped_raw_data[session]['velocity_data'], C_norm_df[session])
    pre_movement_fluorescence = pull_out_fluorescence_from_velocity_bounds(pre_movement_boundaries, grouped_raw_data[session]['velocity_data'], C_norm_df[session])
  else:
    movement_fluorescence = []
    pre_movement_fluorescence = []
  if len(resting_boundaries_long)>0:
        resting_fluorescence = pull_out_fluorescence_from_velocity_bounds(resting_boundaries_long[:-1], grouped_raw_data[session]['velocity_data'], C_norm_df[session])
  else:
        resting_fluorescence = []
  return({'movement_fluorescence':movement_fluorescence, 'pre_movement_fluorescence':pre_movement_fluorescence, 'resting_fluorescence':resting_fluorescence})

def z_score_CNMFE(CNMFE_results):
    C_Z_scored = []
    for cell in range(len(CNMFE_results)):
      Z_scored_cell = stats.zscore(CNMFE_results[cell])
      C_Z_scored.append(Z_scored_cell)
    C_Z_scored = np.array(C_Z_scored)
    return(C_Z_scored)


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

def get_ISIs(signal, framerate, min_bout_len, cells_list, event_threshold):
    event_times = []
    event_ISIs = []
    event_indicies = []
    for cell in cells_list:
        event_indicies_by_cell = ma.count_events_in_array(signal[cell].values, framerate, min_bout_len, threshold=event_threshold, up=True)[1]
        event_times_by_cell = ([(1/framerate)*x for x in event_indicies_by_cell])
        event_times.append(np.array(event_times_by_cell))
        cell_ISIs = [(event_times_by_cell[event]-event_times_by_cell[event-1]) for event in range(1, len(event_times_by_cell))]
        event_ISIs.append(np.array(cell_ISIs))
        event_indicies.append(np.array(event_indicies_by_cell))
    return(np.array(event_indicies), np.array(event_times), np.array(event_ISIs))

def get_ISIs_binned_data(signal, framerate, num_cells, event_threshold):
    event_times = []
    event_ISIs = []
    for cell in range(num_cells):
        event_indicies_by_cell = ma.count_events_in_array(signal[cell], framerate, .1, threshold=event_threshold, up=True)[1]
        event_times_by_cell = ([(1/framerate)*x for x in event_indicies_by_cell])
        event_times.append(event_times_by_cell)
        cell_ISIs = [(event_times_by_cell[event]-event_times_by_cell[event-1]) for event in range(1, len(event_times_by_cell))]
        event_ISIs.append(cell_ISIs)
    return(event_times, event_ISIs)  

def binning_function_uncrop(z_scored_cell_column, bin_increment_samples, z_score_threshold):
    z_scored_cell = z_scored_cell_column.values
    bin_start = 0
    bin_end = bin_increment_samples
    binned = np.zeros(len(z_scored_cell))
    #time_index = []
    while bin_end < len(z_scored_cell):
        if np.any(z_scored_cell[bin_start:bin_end]>z_score_threshold):
            binned[bin_start:bin_end] = np.ones(bin_increment_samples)
        else:
            binned[bin_start:bin_end] = np.zeros(bin_increment_samples)
        #time_index.append(bin_start)
        bin_start += bin_increment_samples
        bin_end += bin_increment_samples
    return(np.array(binned))

def binning_function_uncrop_array(z_scored_cell, bin_increment_samples, z_score_threshold):
    bin_start = 0
    bin_end = bin_increment_samples
    binned = np.zeros(len(z_scored_cell))
    #time_index = []
    while bin_end < len(z_scored_cell):
        if np.any(z_scored_cell[bin_start:bin_end]>z_score_threshold):
            binned[bin_start:bin_end] = np.ones(bin_increment_samples)
        else:
            binned[bin_start:bin_end] = np.zeros(bin_increment_samples)
        #time_index.append(bin_start)
        bin_start += bin_increment_samples
        bin_end += bin_increment_samples
    return(np.array(binned))


def binning_function(bin_increment_samples, z_scored_cell, z_score_threshold):
    bin_start = 0
    bin_end = bin_increment_samples
    binned = []
    #time_index = []
    while bin_end < len(z_scored_cell):
        if np.any(z_scored_cell[bin_start:bin_end]>z_score_threshold):
            binned.append(1)
        else:
            binned.append(0)
        #time_index.append(bin_start)
        bin_start += bin_increment_samples
        bin_end += bin_increment_samples
    return(np.array(binned))


def normalize(trace, percentile=True):
    """ Normalize a fluorescence trace by its max or its 99th percentile. """
    trace = trace - np.min(trace)
    if np.percentile(trace, 99) > 0:
        if percentile:
            trace = trace / np.percentile(trace, 99)
        else:
            trace = trace / np.max(trace)
    return trace


def com(A, d1, d2):
    """Calculation of the center of mass for spatial components

       From Caiman: https://github.com/flatironinstitute/CaImAn
       @author: agiovann

     Inputs:
     ------
     A:   np.ndarray
          matrix of spatial components (d x K)

     d1:  int
          number of pixels in x-direction

     d2:  int
          number of pixels in y-direction

     Output:
     -------
     cm:  np.ndarray
          center of mass for spatial components (K x 2)
    """
    nr = np.shape(A)[-1]
    Coor = dict()
    Coor['x'] = np.kron(np.ones((d2, 1)), np.expand_dims(list(range(d1)),
                        axis=1))
    Coor['y'] = np.kron(np.expand_dims(list(range(d2)), axis=1),
                        np.ones((d1, 1)))
    cm = np.zeros((nr, 2))        # vector for center of mass
    cm[:, 0] = old_div(np.dot(Coor['x'].T, A), A.sum(axis=0))
    cm[:, 1] = old_div(np.dot(Coor['y'].T, A), A.sum(axis=0))

    return cm


def plot_contours(A, Cn, list_to_plot=None, thr=None, thr_method='max', maxthr=0.2, nrgthr=0.9,
                  display_numbers=True, max_number=None,
                  cmap=None, swap_dim=False, colors='w', vmin=None,
                  vmax=None, **kwargs):
    """Plots contour of spatial components against a background image
       and returns their coordinates

       From Caiman: https://github.com/flatironinstitute/CaImAn
       @author: agiovann

     Parameters:
     -----------
     A:   np.ndarray or sparse matrix
               Matrix of Spatial components (d x K)

     Cn:  np.ndarray (2D)
               Background image (e.g. mean, correlation)

     list_to_plot: 
      optional input list of specific cells to plot

     thr_method: [optional] string
              Method of thresholding:
                  'max' sets to zero pixels that have value less
                  than a fraction of the max value
                  'nrg' keeps the pixels that contribute up to a
                  specified fraction of the energy

     maxthr: [optional] scalar
                Threshold of max value

     nrgthr: [optional] scalar
                Threshold of energy

     thr: scalar between 0 and 1
               Energy threshold for computing contours (default 0.9)
               Kept for backwards compatibility.
               If not None then thr_method = 'nrg', and nrgthr = thr

     display_number:     Boolean
               Display number of ROIs if checked (default True)

     max_number:    int
               Display the number for only the first max_number components
               (default None, display all numbers)

     cmap:     string
               User specifies the colormap (default None, default colormap)

     Returns:
     --------
     Coor: list of coordinates with center of mass,
        contour plot coordinates and bounding box for each component
    """
    if sparse.issparse(A):
        A = np.array(A.todense())
    else:
        A = np.array(A)

    if swap_dim:
        Cn = Cn.T
        print('Swapping dim')

    d1, d2 = np.shape(Cn)
    d, nr = np.shape(A)
    if max_number is None:
        max_number = nr

    if thr is not None:
        thr_method = 'nrg'
        nrgthr = thr
        warn("The way to call utilities.plot_contours has changed.")

    x, y = np.mgrid[0:d1:1, 0:d2:1]

    ax = plt.gca()
    if vmax is None and vmin is None:
        plt.imshow(Cn, interpolation=None, cmap=cmap,
                   vmin=np.percentile(Cn[~np.isnan(Cn)], 1),
                   vmax=np.percentile(Cn[~np.isnan(Cn)], 99))
    else:
        plt.imshow(Cn, interpolation=None, cmap=cmap,
                   vmin=vmin, vmax=vmax)

    coordinates = []
    cm = com(A, d1, d2)
    
    #switch to accomodate input list of cells to plot
    if list_to_plot:
      to_plot = list_to_plot
    else:
      to_plot = range(np.minimum(nr, max_number))

    for i in to_plot:
        pars = dict(kwargs)
        if thr_method == 'nrg':
            indx = np.argsort(A[:, i], axis=None)[::-1]
            cumEn = np.cumsum(A[:, i].flatten()[indx]**2)
            cumEn /= cumEn[-1]
            Bvec = np.zeros(d)
            Bvec[indx] = cumEn
            thr = nrgthr

        else:
            if thr_method != 'max':
                warn("Unknown threshold method. Choosing max")
            Bvec = A[:, i].flatten()
            Bvec /= np.max(Bvec)
            thr = maxthr

        if swap_dim:
            Bmat = np.reshape(Bvec, np.shape(Cn), order='C')
        else:
            Bmat = np.reshape(Bvec, np.shape(Cn), order='F')
        cs = plt.contour(y, x, Bmat, [thr], colors=colors)

        # this fix is necessary for having disjoint figures and borders
        p = cs.collections[0].get_paths()
        v = np.atleast_2d([np.nan, np.nan])
        for pths in p:
            vtx = pths.vertices
            num_close_coords = np.sum(np.isclose(vtx[0, :], vtx[-1, :]))
            if num_close_coords < 2:
                if num_close_coords == 0:
                    # case angle
                    newpt = np.round(old_div(vtx[-1, :], [d2, d1])) * [d2, d1]
                    vtx = np.concatenate((vtx, newpt[np.newaxis, :]), axis=0)

                else:
                    # case one is border
                    vtx = np.concatenate((vtx, vtx[0, np.newaxis]), axis=0)

            v = np.concatenate((v, vtx, np.atleast_2d([np.nan, np.nan])),
                               axis=0)

        pars['CoM'] = np.squeeze(cm[i, :])
        pars['coordinates'] = v
        pars['bbox'] = [np.floor(np.min(v[:, 1])), np.ceil(np.max(v[:, 1])),
                        np.floor(np.min(v[:, 0])), np.ceil(np.max(v[:, 0]))]
        pars['neuron_id'] = i + 1
        coordinates.append(pars)

    if display_numbers:
        for i in to_plot:
            if swap_dim:
                ax.text(cm[i, 0], cm[i, 1], str(i + 1), color=colors)
            else:
                ax.text(cm[i, 1], cm[i, 0], str(i + 1), color=colors)

    return coordinates

## for compiling spatial information about cells

def return_spatial_info(path_to_cnmfe, spatial_threshold, dims=(752, 480)):
  CNMFE_results = sio.loadmat(path_to_cnmfe)
  spatial_components=np.array(CNMFE_results['A'].todense())
  d1 = dims[0]
  d2 = dims[1]
  coms = com(spatial_components, d1, d2)
  com_df = pd.DataFrame(coms, columns=['y', 'x'], index=[int(index) for index in np.linspace(1, len(coms), len(coms))])
  return(com_df, spatial_components)

#analysis by group

def get_pairwise_distance_by_session(com_df):
  pairwise_euclidean_distance = {}
  for pair in itertools.combinations(list(com_df.index), 2):
    pairwise_euclidean_distance[pair] = dist.euclidean(com_df.loc[pair[0]], com_df.loc[pair[1]])
  pairwise_distance = pd.DataFrame(pairwise_euclidean_distance, index=['euclidean distance'])
  return(pairwise_distance)

def get_linear_pairwise_correlation_coefficients(C_data, com_df):
  pairwise_r_correlation = {}
  for pair in itertools.combinations(list(com_df.index), 2):
    pairwise_r_correlation[pair] = stats.pearsonr(C_data[pair[0]], C_data[pair[1]])[0]
  pairwise_pearson = pd.DataFrame(pairwise_r_correlation, index=['pairwise_pearson_r'])
  return(pairwise_pearson)

def store_regression_info_per_session(pairwise_pearson, pairwise_distance, degree):
  fit_data = pd.DataFrame(columns=['y', 'x'])
  fit_data['y'] = pairwise_pearson
  fit_data['x'] = pairwise_distance
  p1d = np.poly1d(np.polyfit(fit_data['x'].values, fit_data['y'].values, degree))
  model = np.poly1d(np.polyfit(fit_data['x'].values, fit_data['y'].values, degree))
  results = smf.ols(formula='y ~ model(x)', data=fit_data).fit()
  return({'p1d' : p1d, 'model' : model, 'statsmodel_results' : results, 'fit_df' : fit_data})

def create_contour_layouts(spatial_components, dims=(752, 480)):
  # return dict with info for plotting
  x, y = np.mgrid[0:dims[0]:1, 0:dims[1]:1]
  cell_contours = {}
  for_dims = {}
  to_plot = (0, np.shape(spatial_components)[1])
  for i in range(to_plot[0], to_plot[1]):
    Bvec = spatial_components[:, i].flatten()
    #normalize contours to 1
    Bvec /= np.max(Bvec)
    thr = 0.6
  # rehape to dimensions of image
    Bmat = np.reshape(Bvec, (dims), order='F')
    cell_contours[i+1] = Bmat
    for_dims[i+1] = Bvec
  return(cell_contours, for_dims)

# match behavior tracking file with cnmfe file

def find_behavior_tracking(cnmfe_file, cnmfe_file_dict, suffix):
  animal = cnmfe_file_dict[cnmfe_file][0]
  session = cnmfe_file_dict[cnmfe_file][1]
  path_to_tracking = animal +'_' + session + '/' + animal + '_' + session + '_dlc_tracking_foranalysis_' + suffix + '.csv'
  
  return(path_to_tracking)

## group binning analysis

def prepare_timedelta_dfs(path_to_interpolated_tracking_data):
    # load cnmfe_data
    # behavior results
    interpolated = pd.read_csv(path_to_interpolated_tracking_data)
    interpolated.set_index('Unnamed: 0', inplace=True)
    interpolated.index.rename('time(sec)', inplace=True)
    interpolated['msCam_index'] = np.linspace(0, len(interpolated)-1, len(interpolated))
    interpolated.drop('msCamFrame', axis=1, inplace=True)
    interpolated.drop('level_0', axis=1, inplace=True)
    interpolated = interpolated.set_index(pd.to_timedelta(np.linspace(0, (len(interpolated)-1)*(1/20), len(interpolated)), unit='s'), drop=False)

    return(interpolated)

def create_fluorescence_time_delta(fluoresence_data):
    fluorescence = pd.DataFrame(np.transpose(z_score_CNMFE(fluoresence_data)),
      columns=[int(cell_num) for cell_num in np.linspace(1, len(fluoresence_data), len(fluoresence_data))])
    fluorescence['msCamFrame'] = fluorescence.index.values
    fluorescence = fluorescence.set_index(pd.to_timedelta(np.linspace(0, (len(fluorescence)-1*(1/20)), len(fluorescence)), unit='s'), drop=False)
    return(fluorescence)

## triggered averaging for session
def select_trigger_regions(binned_velocity, activity_threshold, resting_threshold, resting_baseline):
  transition_indicies = []
  for point in range(resting_baseline, len(binned_velocity)-resting_baseline):
    if binned_velocity[point]>activity_threshold and not any(binned_velocity[int(point-resting_baseline):point]>resting_threshold):
           transition_indicies.append(point)
  return(np.array(transition_indicies))

#select and average section
def average_triggered_regions(trace_region, transition_indicies, length_samples_to_plot):
  transition_activity = {}
  for index in transition_indicies:
    if index < len(trace_region):
      region = trace_region[index-length_samples_to_plot:index+length_samples_to_plot]
      if len(region) == length_samples_to_plot*2:
        transition_activity[index] = region
  return(pd.DataFrame(transition_activity))

#adjust baseline
def adjust_triggered_average_plots(binned_velocity, C_z_scored, threshold_activity_df):
  C_z_scored_for_averaging = C_z_scored.drop(['msCamFrame'], axis=1)
  resting_indicies = [index[0] for index in np.argwhere(binned_velocity[0:len(C_z_scored_for_averaging)]<0.5)]
  resting_value = abs(C_z_scored_for_averaging.iloc[resting_indicies].mean(axis=1).mean())
  rezeroed_activity_df = ((threshold_activity_df+resting_value)-resting_value)/(resting_value)
  return(rezeroed_activity_df)


#filter by spatial components 

def filter_out_by_size(cell_df_to_filter, cell_contours, cell_dims, contour_thresold, cell_size_filter_threshold):
  cells_to_drop = np.array([cell for cell in range(1, len(cell_contours)+1) if len(np.array(np.where(cell_dims[cell]>contour_thresold)[0]))<cell_size_filter_threshold])
  filtered = cell_df_to_filter.drop(cells_to_drop, axis=1)
  return(filtered)


## spatial coordination index

def create_coordination_index(more_result, less_result):
  if more_result is None and less_result is not None:
    if less_result.pvalue == 0:
        coord_index = 0
    else:
        coord_index = math.log(less_result.pvalue, 10)*-1 
  elif more_result is not None and less_result is not None:
    if less_result.pvalue > more_result.pvalue:
      coord_index = math.log(less_result.pvalue, 10)*-1
    else:
      coord_index = math.log(more_result.pvalue, 10)
  elif more_result is not None and less_result is None:
    coord_index = math.log(more_result.pvalue, 10)
  else:
    coord_index = 0
  return(coord_index)

# analyze spatial coordination by session

def spatial_coordination_by_session(reindexed):
  """
  binnums are distance bins for ks testing
  """

  coactivity_dfs = []
  cell_pairs = [pair for pair in itertools.combinations(list(reindexed.columns), 2)]
  for time_index in range(len(reindexed)):
    coactivity_by_time_point = {}
    for pair in cell_pairs:
      if (reindexed.loc[time_index][pair[0]] == 1) and (reindexed.loc[time_index][pair[1]] == 1):
        coactivity_by_time_point[pair] = 1
      else:
        coactivity_by_time_point[pair] = 0
    coactivity_df = pd.DataFrame(coactivity_by_time_point, index=['coactivity'])
    coactivity_dfs.append(coactivity_df)

  return(coactivity_dfs)

def create_coactivity_matrix(cell_pairs, orig_df_comparison, time_index):
  indicies_to_update = []
  if time_index%1000==0:
    print(time_index)
    try:
      for pair, pair_idx in zip(cell_pairs, range(len(cell_pairs))):
        if (orig_df_comparison.loc[time_index][pair[0]] == 1) and (orig_df_comparison.loc[time_index][pair[1]] == 1):
          indicies_to_update.append((time_index, pair_idx))
        else:
          pass
    except TypeError:
      print(pair)
      print(pair_idx)
    return(indicies_to_update)
    
















