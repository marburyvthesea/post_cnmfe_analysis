
import get_coactivity_matrix as coam
import sys


input_cnmfe_file_path = sys.argv[1]
input_Z_score_threshold = int(sys.argv[2])
input_num_procs = int(sys.argv[3])
input_dir_path = sys.argv[4]
input_file_name = sys.argv[5]

binned_fluorescence, com_filtered = coam.load_and_bin_fluorescence(input_cnmfe_file_path, input_Z_score_threshold)
coactivity_in_session_p, cell_pairs = coam.get_coactivity_matrix(binned_fluorescence, input_num_procs)
coam.save_coactivity_info(coactivity_in_session_p, cell_pairs, input_dir_path, input_file_name)

