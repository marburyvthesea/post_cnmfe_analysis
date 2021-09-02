#!/bin/bash
#SBATCH -A p30771
#SBATCH -p short
#SBATCH -t 4:00:00
#SBATCH -o /home/jma819/post_cmfe_analysis/jjm_misc/outputfiles/create_event_videos_slurm.%x-%j.out # STDOUT
#SBATCH --job-name="slurm_create_event_videos"
#SBATCH -N 1
#SBATCH -n 24
#SBATCH --mem=96G

module purge all
export PATH=$PATH/projects/b1118/

#load modules to use
module load python/anaconda3.6
source activate caiman_with_tables

# cd to video directory
cd /home/jma819/post_cmfe_analysis/jjm_misc/

#input variable is session to run
INPUT_session=$1
#input list of cells as a string e.g. '1,2,4,6'
INPUT_list_of_cells=$2
#directory to save videos
INPUT_save_dir=$3

#run script
python create_save_event_videos_script_cell_subset.py $INPUT_session $INPUT_list_of_cells $INPUT_save_dir
