import av
from PIL import Image
import matplotlib.pyplot as plt
import glob
from tqdm import tqdm 
import numpy as np
import sys

#session = 'GRIN012_H16_M57_S23'
session=str(sys.argv[1])
video_end=int(sys.argv[2])

videos = sorted(glob.glob('/projects/b1118/behaviorvideos/to_concat/'+session+'/*.avi'))[0:video_end]

v_0 = av.open(videos[0])
for packet in v_0.demux():
    for frame in packet.decode():
        shape = np.shape(frame.to_nd_array())

concactenated_length=1000*len(videos)
converted_array = np.empty([concactenated_length, shape[0], shape[1]])
for video, i in tqdm(zip(videos, range(len(videos))), total=len(videos)):
    v = av.open(video)
    for packet in v.demux():
        for frame in packet.decode():
            #if frame.type == 'video':
            img = frame.to_image()  
            arr = np.asarray(img)
            #split into r,g,b channels 
            r = arr[:, :, 0]
            g = arr[:, :, 1]
            b = arr[:, :, 2]
            #scale pixel values to gray
            gray_image = (r*0.299 + g*0.587 +b*0.114)
            converted_array[frame.index+int(i*1000)] = gray_image

print(session + '  loaded')

output = av.open('/projects/b1118/behaviorvideos/'+session+'/'+session+'_gray.avi', mode='w')
fps = 30
stream = output.add_stream('mpeg4', rate=fps)
stream.width = 472
stream.height = 473
#stream.pix_fmt = 'gray'
for frame_i in tqdm(range(np.shape(converted_array)[0])):
    new_im = converted_array[frame_i].astype(np.uint8)
    #new_im = Image.fromarray(converted_array[frame_i].astype(np.uint8))
    #new_frame = av.VideoFrame.from_image(new_im)
    new_frame = av.VideoFrame.from_ndarray(new_im, format='gray')
    for packet in stream.encode(new_frame):
        output.mux(packet)
# Flush stream
for packet in stream.encode():
    output.mux(packet)
# Close the file
output.close()

print('saved')
print('/projects/b1118/behaviorvideos/'+session+'/'+session+'_gray.avi')

print('each frame has shape:')
print('np.shape(av.VideoFrame.to_ndarray(new_frame)')


