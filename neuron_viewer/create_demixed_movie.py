
##create demixed movie of neurons from matlab output file

import scipy.sparse as sparse
from tqdm import tqdm
import numpy as np
import h5py
from tqdm import tqdm
import imageio

def demixed_movie_from_output_file(results, frame_range):
    """

    :param results: output of sio.loadmat
    :param frame_range: tuple (frame_start, frame_end)
    :return:
    """
    d1, d2 = 480, 752
    results['A'].todense()
    cells = np.shape(results['C'])[0]
    cells_reshaped = np.empty((cells), frame_range[1], d1, d2)
    for cell in tqdm(range(cells)):
        A_reshaped = np.reshape(dense_A[:, cell], (d1, d2))
        cells_reshaped[cell] = np.array([np.dot(A_reshaped, results['C'][cell, frame]) for frame in range(frame_range[0], frame_range[1])])

    return(cells_reshaped)


results_file =

results = sio.loadmat(results_file)
hf = h5py.File(results_file[0:-4] + '_demixed_.h5', 'w')
hf.create_dataset('demixed_movie_array', data=cells)