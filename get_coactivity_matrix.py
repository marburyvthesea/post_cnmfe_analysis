

import pandas as pd
import python_utils_jjm as utils_jjm 
import rotarod_analysis as ra
import numpy as np
import itertools
from multiprocessing import Pool
import functools
from scipy import sparse


def map_to_sparse_matrix(cell_pairs, orig_df_comparison, time_index):
	indicies_to_update = []
	if time_index%100==0:
		print(time_index)
	for pair, pair_idx in zip(cell_pairs, range(len(cell_pairs))):
		if (orig_df_comparison.loc[time_index][pair[0]] == 1) and (orig_df_comparison.loc[time_index][pair[1]] == 1):
			indicies_to_update.append((time_index, pair_idx))
		else:
			pass
	return(indicies_to_update)


def load_and_bin_fluorescence(CNMFE_file_path, Z_score_threshold):
	CNMFE_data = ra.get_CNMFE_fluorescence(CNMFE_file_path)
	CNMFE_data_filtered = utils_jjm.filter_out_by_size(CNMFE_data['C_normalized_z_scored'], CNMFE_data['cell_contours'],
		CNMFE_data['for_dims'], 0.6, 100).drop(['msCamFrame'], axis=1)
	com_filtered = utils_jjm.filter_out_by_size(CNMFE_data['com'].transpose(), CNMFE_data['cell_contours'], 
												CNMFE_data['for_dims'], 0.6, 100)
	binned_fluorescence = CNMFE_data_filtered.apply(utils_jjm.binning_function_uncrop, args=[1, int(Z_score_threshold)])

	return(binned_fluorescence, com_filtered)

def get_coactivity_matrix(input_binned_fluorescence, num_procs):

	reindexed = input_binned_fluorescence.set_index(int(x) for x in np.linspace(0, len(input_binned_fluorescence)-1, len(input_binned_fluorescence)))
	cell_pairs = np.array([pair for pair in itertools.combinations(list(reindexed.columns), 2)])
	#create dictionary of cell pairs, keys are index in the list of pair combinations
	pairs_dict = {pair_idx:pair for (pair_idx , pair) in zip(range(len(cell_pairs)), cell_pairs)}
	coactivity_in_session_p = sparse.dok_matrix((len(reindexed), len(cell_pairs)))

	# search for indicies with coactivity
	print('iterating over time points in parallel')
	p=Pool(num_procs)

	indicies = [cell_indicies for cell_indicies in list(p.map(functools.partial(map_to_sparse_matrix, cell_pairs, reindexed), range(len(reindexed)))) if len(cell_indicies)>0]
	indicies_flattened = [indx for sublist in indicies for indx in sublist]

	p.close

	# update the coactivity matrix 
	for dok_index in indicies_flattened:
		coactivity_in_session_p[dok_index[0], dok_index[1]] = 1

	return(coactivity_in_session_p, cell_pairs)

def save_coactivity_info(input_coactivity_in_session_p, input_cell_pairs, directory_path, filename):
	
	csr_matrix = input_coactivity_in_session_p.tocsc()
	sparse.save_npz(directory_path+filename+".npz", csr_matrix)
	pd.DataFrame(input_cell_pairs).to_csv(directory_path+filename+".csv")

	return(True)


