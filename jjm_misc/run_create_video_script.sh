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
INPUT_savedir=$2

#run script
python create_save_event_videos_script.py $INPUT_session $INPUT_savedir
