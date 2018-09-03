import os
import numpy as np
import argparse

from imageio import imread, imwrite

from tileutils import usemodel


def generate_embeddings(model_name, input_name, colors, reverse=True):
    data_root = os.path.join(os.path.abspath(os.path.dirname(__file__)), '../data')
    
    model_root = os.path.join(data_root, 'models', 'vaegan')
    

    dec_dir = os.path.join(model_root, model_name, 'saved_model_embed_in', '1')
    enc_dir = os.path.join(model_root, model_name, 'saved_model_image_in', '1')

    encoder = usemodel.Encoder(enc_dir)
    decoder = usemodel.Decoder(dec_dir)

    input_dir = os.path.join(data_root, 'tiles', input_name)

    embed_output_dir = os.path.join(data_root, 'embeds', model_name)
    reconstruction_output_dir = os.path.join(data_root, 'recons', model_name)

    try:
        os.makedirs(embed_output_dir)
    except OSError:
        pass
    
    try:
        os.makedirs(reconstruction_output_dir)
    except OSError:
        pass

    usemodel.use_model(encoder, decoder, input_dir, embed_output_dir, reconstruction_output_dir, colors, reverse )



if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('model_name')
    parser.add_argument('input_name')

    parser.add_argument('-c', '--colors', nargs='*', default=["0,0,1", "0,1,0", "1,1,1", "1,0,0"])
    parser.add_argument('-r', '--reverse', action='store_true', default=False)
    args = parser.parse_args()

    color_tuples = [tuple(int(x) for x in c.split(',')) for c in args.colors]

    generate_embeddings(args.model_name, args.input_name, color_tuples, args.reverse)