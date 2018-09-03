import os
import argparse
from functools import reduce

import numpy as np
from imageio import imread, imwrite
from PIL import Image

standard_cat_colors = ((0, 0, 1), (0, 1, 0), (1, 1, 1), (1, 0, 0))

def imgs_to_ndarr(*img_defs):
    img_channels = [arr[:, :, channel] for arr, channel in img_defs]
    return np.stack(img_channels, axis=2)


def split_to_cat(tile_name, root_path, channel_defs):
    img_defs = [(imread(os.path.join(root_path, type_name, tile_name)), channel) for type_name, channel in channel_defs]
    return imgs_to_ndarr(*img_defs)


def cat_to_rgba(arr, channel_defs, reverse=False):
    arr = arr.reshape((arr.shape[0], arr.shape[1], -1))
    channel_layers = np.dsplit(arr, arr.shape[2])
    zipped_data = zip(channel_layers, channel_defs)
    split_image_data = []
    for layer, color_mult in reversed(list(zipped_data)) if reverse else zipped_data:
        new_image_data = np.squeeze(np.stack([np.multiply(layer, mult) for mult in color_mult + (1,)], axis=2))
        split_image_data.append(new_image_data)
        
    split_images = [Image.fromarray(nparr, 'RGBA') for nparr in split_image_data]
    return np.array(reduce(lambda x,y: Image.alpha_composite(x,y), split_images))


def alpha_to_black(arr):
    if arr.shape[2] != 4:
        raise ValueError('Original image does not have an alpha channel, there\'s no way to flatten to RGB')

    return arr[:,:,0:3]


def add_black_bg(arr):
    if arr.shape[2] != 4:
        raise ValueError('Original image does not have an alpha channel, there\'s no way to add a background')
    img = Image.fromarray(arr, 'RGBA')
    bg = Image.new('RGBA', img.size, (0, 0, 0, 255))

    return np.array(Image.alpha_composite(bg, img))


def cat_to_display(arr, colors=standard_cat_colors, reverse=False):
    if isinstance(arr, Image.Image):
        arr = np.array(arr)
    
    return add_black_bg(cat_to_rgba(arr, colors, reverse))


def save_img(arr, path):
    if isisntance(arr, Image.Image):
        arr = np.array(arr)
    imwrite(path, arr)


def test():
    # tiles_path = 'D:\\maciej\\Studies\\OSM\\data\\tiles\\france-ghs-split\\15\\france-tiles-'
    # merged_np = split_to_cat('15_15972_11340.png', tiles_path, [('water', 2), ('greenery', 1), ('roads', 0), ('buildings', 0)])
    # imwrite('test.png', merged_np)
    cat_test = imread('res.png')
    converted = cat_to_rgba(cat_test, standard_cat_colors)
    print(converted)
    imwrite('test_res.png', converted)

    imwrite('test_res_black_alpha.png', add_black_bg(converted))
    imwrite('test_res_black.png', alpha_to_black(converted))


def main():

    parser = argparse.ArgumentParser()

    parser.add_argument('-i', '--input-directory')
    parser.add_argument('-o', '--output-directory')
    parser.add_argument('-t', '--types', nargs='*')
    parser.add_argument('-x', '--channels', type=int, nargs='*')
    parser.add_argument('-c', '--colors', nargs='*', default=["0,0,1", "0,1,0", "1,1,1", "1,0,0"])
    parser.add_argument('-m', '--mode', choices=['split-cat', 'cat-rgb'])
    

    args = parser.parse_args()

    if args.mode == 'split-cat' and len(args.types) != len(args.channels):
        raise ValueError('Need the same number of channel definitions as types')

    color_tuples = [int(x) for c in args.colors for x in c.split(',') ]

    directories = [os.path.join(args.input_directory, t) for t in args.types]

    try:
        os.makedirs(args.output_directory)
    except OSError:
        pass

    if args.mode == 'split-cat':
        # assume all type directories contain the same list of files
        filenames = os.listdir(directories[0])
    elif args.mode == 'cat-rgb':
        filenames = os.listdir(args.input_directory)
    n = len(filenames)

    print() # print an empty new line
    for i, filename in enumerate(filenames):
        print('\rProcessing tiles {} of {} ({}% complete)'.format(i, n, int(i * 100 / n)), end='')
        dest = os.path.join(args.output_directory, filename)

        if args.mode == 'cat-rgb':
            orig = os.path.join(args.input_directory, filename)
            arr = imread(orig)
            imwrite(dest, cat_to_display(arr, color_tuples))
            pass
        elif args.mode == 'split-cat':
            type_files = [os.path.join(d, filename) for d in directories]
            imwrite(dest, split_to_cat(filename, args.input_directory, zip(args.types, args.channels)))


if __name__ == '__main__':
    main()