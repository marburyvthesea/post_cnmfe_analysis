



from tkinter import *
import cv2
import numpy as np
import time


## add tkinter module for selecting matlab output file

# check if file has a filed with link to demixed videos, if not create demixed videos

# after file selected


## add tkinter module for selecting video file



## opencv display to scroll through video


processed_video_file = '/Volumes/My_Passport/cnmfe_analysis_files/GRIN034/H21_M22_S45/H21_M22_S45msCam1.tif'
#processed_vid_cap = cv2.VideoCapture(processed_video_file)

success, images = cv2.imreadmulti(processed_video_file)
cv2.namedWindow('demixed video')

print(len(images[1]))

#cv2.imshow('demixed video', images[2])
#cv2.waitKey(0)
#cv2.destroyAllWindows()

frame_count = len(images)
i = 0
while i<frame_count:
  #  err, img = processed_vid_cap.read()

    cv2.imshow("demixed video", images[i])
    cv2.waitKey(1)
    #time.sleep(1)
    print(i)
    i+=1
 #  k = cv2.waitKey(10) & 0xff

 #   if k==27:
 #       break






