#!/bin/bash
#SBATCH -A p30771
#SBATCH -p short 
#SBATCH -t 00:20:00
#SBATCH -o /home/jma819/post_cmfe_analysis/openfield_analysis/mmtracking/logfiles/%x-%j.out # STDOUT
#SBATCH --job-name="mm_postprocessing"
#SBATCH --mem=20G
#SBATCH -N 1
#SBATCH -n 5 


module purge all
cd ~

DIR_path=$1
INPUT_f_to_process=$2

module load matlab/r2018a

#cd to script directory
cd /home/jma819/post_cmfe_analysis/openfield_analysis/mmtracking

matlab -nosplash -nodesktop -r "dataFolder='$DIR_path';f_to_process='$INPUT_f_to_process';run('mm_post_processing_script.m'); exit;"
