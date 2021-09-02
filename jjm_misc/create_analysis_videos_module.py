import pandas as pd 
import numpy as np
import h5py
import sys
sys.path.append('/home/jma819/post_cmfe_analysis')
import python_utils_jjm as utils_jjm
import dlc_utils
import matplotlib.pyplot as plt
from matplotlib import animation, rc
import av
from tqdm import tqdm
import multiprocessing as mp
from itertools import product

def create_compiled_event_videos_for_session(z_scored_events_by_session, velocity_data, spatial_contours, session, events_to_plot, cells_to_plot, save_dir, in_vmin=0, in_vmax=255):    
    """--create flags for selecting all cells/events or subset
        events_to_plot is tuple (event_start, event_end)
    """
    #loop over events here, loop over cells in function
    for event_bound in tqdm(events_to_plot):
        video_out, behav_cam_clip, cells_recombined, single_cell_response = create_event_video(event_bound[0], event_bound[1], velocity_data.loc[session], 
                                                                                    z_scored_events_by_session[session], 
                                                                                    spatial_contours[session][:, :], 
                                                                                    session, cells_to_plot, save_dir, in_vmin, in_vmax)  
    return(True)


def create_event_video(event_start, event_end, velocity_data_for_session, session_to_load, spatial_contours_by_session, session_name, cells, save_dir, in_vmin, in_vmax):
    #create time delta for msCam trace 
    time_delta_for_msCam_resampled = list(pd.timedelta_range(start=event_start, end=event_end, freq='.2S'))
    #find the closest frames to these in the behacCam data
    times_in_velocity_trace = [dlc_utils.nearest(velocity_data_for_session.index, time_delta_msCam) for time_delta_msCam in time_delta_for_msCam_resampled]
    #get the behav cam frame indicies for the times in times in velocity trace 
    behav_cam_indicies = [int(velocity_data_for_session.loc[td]['behavCam_frames']%1000) for td in times_in_velocity_trace]
    #get num of behavCam video
    behavCam_video = int((velocity_data_for_session.loc[times_in_velocity_trace[0]]['behavCam_frames'])/1000)+1
    behavCam_video_2 = int((velocity_data_for_session.loc[times_in_velocity_trace[-1]]['behavCam_frames'])/1000)+1
    #call function to get behavCam clip
    behav_cam_clip = load_and_return_behavCam_video(behav_cam_indicies, behavCam_video, session_name)
    
    all_cell_contours = spatial_contours_by_session[:, :]
    event_trace = session_to_load.loc['z_scored_movement_regions'].loc[event_start].loc[event_end]
    
    #get event movie for all cells
    cells_recombined = generate_event_movie_for_all_cells(event_trace, all_cell_contours)
    #get event movie for single cells
    ## now just run generate_event_movie_for_all_cells but with single cell 
    # for cell in columns from z scored movement dataframe 
    
    for cell in cells:
        single_cell_response = generate_cell_trace(cell, all_cell_contours, event_trace, (0, len(event_trace)))    
        anim_movie = generate_animation_function(behav_cam_clip, {behavCam_video:behav_cam_indicies}, cells_recombined, 
                                                 single_cell_response, event_trace[cell], session_name, event_start, cell, save_dir, in_vmin, in_vmax)
    return(anim_movie, behav_cam_clip, cells_recombined, single_cell_response)
    

def load_and_return_behavCam_video(behavCam_indicies_in_video, behavCam_video_to_load, session_to_load): 
    video = av.open('/projects/b1118/behaviorvideos/042021_run/'+session_to_load+'/behavCam'+str(behavCam_video_to_load).zfill(2)+'DLC_resnet50_dlc_22_miniscope_openfield-JJM-2021-04-25Apr25shuffle1_300000_labeled.mp4')
    total_frames = video.streams.video[0].frames
    movie_images = {}
    for i, frame in enumerate(video.decode(video=0)):
        img = frame.to_image()  # PIL image
        movie_images[i] = img
        if i%1000==0:
            print("Frame: %d/%d ..." % (i, total_frames))
    video.close()
    movie_shape = np.shape(movie_images[1])
    frame_subset = [movie_images[i] for i in behavCam_indicies_in_video]
    return(frame_subset)


def generate_event_movie_for_all_cells(event_trace, all_cell_contours, d1 = 752, d2 = 480):
    frame_range = (0, len(event_trace))
    cells_reshaped = np.empty((np.shape(all_cell_contours)[1], frame_range[1], d2, d1))
    for cell in tqdm(list(event_trace.columns)):
        # "spatial components", or "A" as dense matrix, cells are 1 indexed, spatial array is 0 indexed  
        A_reshaped = np.reshape(all_cell_contours[:, cell-1], (d2, d1))
        #cell_frames = []
        #for frame in range(frame_range[0], frame_range[1]):
        #cell_frames.append(np.array([np.dot(A_reshaped, item) for item in [255, 128, 0, z_scored_regions_by_session[session][sample][cell][frame]]]))
        cells_reshaped[cell-1] = np.array([np.dot(A_reshaped, event_trace[cell][frame]) for frame in range(frame_range[0], frame_range[1])])
    cells_recombined = np.sum(cells_reshaped, axis=0)
    return(cells_recombined)


def generate_cell_trace(cell_idx, all_cell_contours, event_trace, frame_range, d1 = 752, d2 = 480):
    A_reshaped = np.reshape(all_cell_contours[:, cell_idx-1], (d2, d1))
    #cells_reshaped[cell-1] = np.array([np.dot(A_reshaped, event_trace[cell][frame]) for frame in range(frame_range[0], frame_range[1])])
    cell_reshaped = np.array([np.dot(A_reshaped, event_trace[cell_idx][frame]) for frame in range(frame_range[0], frame_range[1])]) 
    return(cell_reshaped)

def wrap_for_map(list_input):
    
    A_reshaped = np.reshape(list_input[1][:, list_input[0]-1], (list_input[3], list_input[4]))
    cell_reshaped = np.array([np.dot(A_reshaped, list_input[2][list_input[0]][frame]) for frame in range(list_input[5][0], list_input[5][1])]) 
    return(cell_reshaped)

def generate_animation_function(behav_cam_clip, behavcaminfo, cells_recombined, single_cell_response, cell_trace, session, event_idx, cell, save_dir, in_vmin, in_vmax):
    """pass behavCam info as dictionary {'behavcamname':[frames]}"""
    #set up figure
    fig, ((ax1, ax2),(ax3,ax4)) = plt.subplots(2,2)
    plt.subplots_adjust(wspace=0.9)
    #plot initial frames
    #options for contrast diplay range
    if in_vmax=='norm_to_video':
        in_vmax = np.max(cells_recombined)
        in2_vmax = in_vmax
    elif in_vmax=='norm_to_each_video':
        in_vmax = np.max(cells_recombined)
        in2_vmax = np.max(single_cell_response)
    else:
        in2_vmax=in_vmax
        
    im = ax1.imshow(cells_recombined[0,:,:], cmap='gray', vmin=in_vmin, vmax=in_vmax)
    im2 = ax2.imshow(single_cell_response[0,:,:], cmap='gray', vmin=in_vmin, vmax=in2_vmax)
    ax3.plot(cell_trace)
    im4 = ax4.imshow(behav_cam_clip[0])
    #animation functions 
    def init():
        fig.suptitle("cell:"+str(cell)+"  frame:"+str(0))
        im.set_data(cells_recombined[0,:,:])
        im2.set_data(single_cell_response[0,:,:])
        ax4.set_title("behavCam: "+str(list(behavcaminfo.keys())[0])+"  frame: "+str(list(behavcaminfo.values())[0][0]))
        im4.set_data(behav_cam_clip[0])
    
    def animate(i):
        fig.suptitle("cell:"+str(cell)+"  frame:"+str(i))
        im.set_data(cells_recombined[i,:,:])
        im2.set_data(single_cell_response[i,:,:])
        ax4.set_title("behavCam: "+str(list(behavcaminfo.keys())[0])+"  frame: "+str(list(behavcaminfo.values())[0][i]))
        im4.set_data(behav_cam_clip[i])
        return (im, im2, im4)
    
    anim = animation.FuncAnimation(fig, animate, init_func=init, frames=cells_recombined.shape[0], interval=50)
    rc('animation', html='jshtml')
    mywriter = animation.FFMpegWriter(fps=5)
    anim.save(save_dir+session+'_event_'+str(event_idx)+'_cell_'+str(cell)+'.mp4', 
              writer=mywriter)
    print('saved: '+save_dir+session+'_event_'+str(event_idx)+'_cell_'+str(cell)+'.mp4')
    return(anim)
