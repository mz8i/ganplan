import numpy as np
from imageio import imread, imwrite
from PIL import Image


def channel_coverage(arr):
    width, height, channels = arr.shape

    maximum_layer_value = width * height * 255.0

    return np.sum(arr, axis=(0,1)) / maximum_layer_value

