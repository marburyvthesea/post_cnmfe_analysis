## misc functions for analyzing cnmfe output

import numpy as np










def F_F0(fluorescence_power, Fs, sliding_baselne_length):
	"""calculate F/F0 as a sliding baseline
		Inputs: sliding_baseline_length (in seconds)
	"""
	baseline_length_samples = int(Fs*sliding_baselne_length)
	F_F0_array = []
	for point in range(int(baseline_length_samples), len(fluorescence_power)):
		F0 = np.mean(fluorescence_power[int(point-baseline_length_samples):int(point)])
		F_F0 = (fluorescence_power[point]-F0)/F0
		print(F_F0)
		F_F0_array.append(F_F0)

	return(np.array(F_F0_array))