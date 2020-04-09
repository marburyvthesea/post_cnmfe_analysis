



from tkinter import *
import cv2
import numpy as np


## add tkinter module for selecting matlab output file

# check if file has a filed with link to demixed videos, if not create demixed videos

# after file selected


## add tkinter module for selecting video file



## opencv display to scroll through video


processed_video_file = '/Volumes/My_Passport/cnmfe_analysis_files/GRIN034/H21_M22_S45/H21_M22_S45msCam1.tif'
processed_vid_cap = cv2.VideoCapture(processed_video_file)

cv2.namedWindow('demixed video')

while processed_vid_cap.isOpened():
    err, img = processed_vid_cap.read()

    cv2.imshow("demixed video", img)

    k = cv2.waitKey(10) & 0xff

    if k==27:
        break






