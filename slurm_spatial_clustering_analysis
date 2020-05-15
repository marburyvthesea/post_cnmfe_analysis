#!/bin/bash
#SBATCH -A p30771
#SBATCH -p short
#SBATCH -t 4:00:00
#SBATCH -o ./logfiles/slurm.%x-%j.out # STDOUT
#SBATCH --job-name="spatial clustering analysis"
#SBATCH -N 1
#SBATCH -n 12
#SBATCH --mem=70G

module purge all

cd ~

#add project directory to PATH
export PATH=$PATH/projects/p30771/

#load modules to use
module load python/anaconda3.6 

#need to cd to load conda environment

cd pythonenvs
cd CaImAn
source activate caiman

#need to cd to module directory

cd /home/jma819/post_cmfe_analysis

#run clustering analysis

INPUT_cnmfe_file_path = $1
INPUT_Z_score_threshold = $2
INPUT_num_procs = $3
INPUT_dir_path = $4
INPUT_file_name = $5


echo "loading file: $INPUT_cnmfe_file_path"

echo "getting coactivity matrix"

# inputs are folder path, regular expression in file names(e.g. msCam), start and end files to correct, number of processors to run
python get_clustering_info_script.py $INPUT_cnmfe_file_path $INPUT_Z_score_threshold $INPUT_num_procs $INPUT_dir_path $INPUT_file_name

echo "finished, saving as: $INPUT_dir_path"
echo "$INPUT_file_name"
