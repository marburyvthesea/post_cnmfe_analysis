


from tkinter import filedialog
from tkinter import *
from tkinter import ttk
from tkinter import Menu
import cv2
import scipy.io as sio
from matplotlib import pyplot as plt
import numpy as np
import time


## add tkinter module for selecting matlab output file

# check if file has a filed with link to demixed videos, if not create demixed videos

# after file selected


## add tkinter module for selecting video file



def loadFileDialog(display_promt, file_type_tuple):
    """
    :param display_promt: e.g. "select matlab output file"
    :param file_type_tuple: e.g. ("ouput file", "*.mat")
    :return: file path to pass to other functions
    """
    filename =  filedialog.askopenfilename(initialdir = "/",title = display_promt,filetypes = (file_type_tuple,("all files","*.*")))
    print(filename)
    return(filename)

def displayImageStackWindow(image_stack, window_name):
    """this works on image_stacks loaded with imreadmulti"""
    frame_count = len(image_stack)

    def onChange(trackbarValue):
        cv2.imshow(window_name, image_stack[trackbarValue])
        pass

    cv2.namedWindow(window_name)
    cv2.createTrackbar('frame', window_name, 0, frame_count, onChange)

    onChange(0)
    cv2.waitKey()

    return()

def loadCNMFEfile():
    cnmfe_file = loadFileDialog("select video file", ("select _out.mat file", "*.mat"))
    cnmfe_results = sio.loadmat(cnmfe_file)
    populatetable(cnmfe_file)
    return(cnmfe_results)

def populatetable(cnmfe_file):
    tree = ttk.Treeview(root)
    tree["columns"] = ()
    #tree.column("one", width=150)
    #tree.column("two", width=100)
    #tree.heading("one", text="column A")
    #tree.heading("two", text="column B")
    tree.insert("", 0, text=cnmfe_file.split('/')[0])
    tree.pack()
    load_menu.add_command(label='display neurons')
    return()


root = Tk()
root.title("NeuronViewer")
menu = Menu(root)
load_menu = Menu(menu)
load_menu.add_command(label='load output', command=loadCNMFEfile)
menu.add_cascade(label='File',menu=load_menu)
root.config(menu=menu)


root.mainloop()

#processed_video_file = loadFileDialog("select video file", ("select tiff stack", "*.tiff"))
#success, images = cv2.imreadmulti(processed_video_file)


#displayImageStackWindow(images, 'demixed_video')
#displayImageStackWindow(images, 'window_2')









