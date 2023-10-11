import urllib.request
import numpy as np
import cv2
import os


def save_img(url):
    image_download = urllib.request.urlopen(url)
    arr = np.asarray(bytearray(image_download.read()), dtype=np.uint8)
    image_read = cv2.imdecode(arr, cv2.IMREAD_UNCHANGED)
    height, width, _ = image_read.shape
    if width > 800 or height > 800:
        ratio = min(800/width, 800/height)
        image_read = cv2.resize(image_read, (int(width*ratio), int(height*ratio)))
    path = 'C:/Projects/ICSv2.5/app/static/images'
    cv2.imwrite(os.path.join(path, 'result.jpg'), image_read)
    cv2.waitKey(0)
