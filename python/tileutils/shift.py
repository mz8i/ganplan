import os
import argparse
from math import ceil

import numpy as np
from imageio import imread, imwrite
from PIL import Image


def get_shifted_image(arr, col_shift, row_shift, neighbors):
    
    raise NotImplementedError('get_shifted_image is not implemented')

    width, height, channels = arr.shape
    indices_for_shift = get_tile_indices_for_shift(col_shift, row_shift)
    # TODO finish
    # selected_neighbors = [[] for ]

    col_pixel_start = width if col_shift < 0 else 0
    row_pixel_start = height if row_shift < 0 else 0

    tiles_to_concat = []

    col_index_shift = np.sign(col_shift) * ceil(abs(col_shift))
    row_index_shift = np.sign(row_shift) * ceil(abs(row_shift))

    col_index_lower_bound = min()


sign = lambda x: (1, -1)[x < 0]

def symceil(x):
    """Symmetric ceiling - round positives up, negatives down"""
    return sign(x) * ceil(abs(x))

def inclusive_range(x, y):
    """Return a list containing x, y and all numbers in between. The sequence goes in the same order as x and y are passed in"""
    sgn = sign(y - x)
    return range(x, y + sgn, sgn)


def get_tile_indices_for_shift(col_shift, row_shift):

    col_index_shift = symceil(col_shift)
    row_index_shift = symceil(row_shift)

    return [[(col_i, row_i) for col_i in sorted(inclusive_range(0, col_index_shift))] for row_i in sorted(inclusive_range(0, row_index_shift))]
