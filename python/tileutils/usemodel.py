import os

import tensorflow as tf
from tensorflow.python.saved_model import tag_constants
import numpy as np
import base64
from PIL import Image
from imageio import imread, imwrite
from io import BytesIO

from .wrangle import cat_to_rgba, add_black_bg, cat_to_display

def read_img_bytes(path):
    with open(path, 'rb') as f:
        return f.read()

def get_img_from_base64(b64):
    b64 = b64.replace(b'_', b'/').replace(b'-', b'+')

    missing_base64_padding = len(b64) % 4
    if missing_base64_padding != 0:
        b64 += (b'=' * (4 - missing_base64_padding))
    decoded = base64.b64decode(b64)

    return Image.open(BytesIO(decoded))


def get_model(model_path):
    g = tf.Graph()
    sess = tf.Session(graph=g)
    tf.saved_model.loader.load(sess, [tag_constants.SERVING], model_path)
    return g, sess


class Encoder:

    def __init__(self, model_path):
        self.g, self.sess = get_model(model_path)

    def encode(self, img):
        with self.g.as_default():
            tf.set_random_seed(1337)
            image = self.g.get_tensor_by_name("input:0")
            model = self.g.get_tensor_by_name('add:0')
            res = self.sess.run(model, {
                image: (img,)
            })
            return res


class Decoder:

    def __init__(self, model_path):
        self.g, self.sess = get_model(model_path)

    def decode(self, emb):
        with self.g.as_default():
            tf.set_random_seed(1337)
            embeddings = self.g.get_tensor_by_name("input:0")
            model = self.g.get_tensor_by_name('EncodeBase64:0')
            res = self.sess.run(model, {
                embeddings: emb
            })
            return get_img_from_base64(res)


def use_model(encoder, decoder, input_dir, embed_output_dir, reconstruction_output_dir, result_colors, reverse=False):

    filenames = [filename for filename in os.listdir(input_dir) if filename.endswith('.png')]

    for filename in filenames:
        img = read_img_bytes(os.path.join(input_dir, filename))
        res = encoder.encode(img)
        vec_filename = filename[:-4] + '.npy'
        np.save(os.path.join(embed_output_dir, vec_filename), res)
        im = decoder.decode(res)
        imwrite(os.path.join(reconstruction_output_dir, filename), cat_to_display(im, result_colors, reverse))



if __name__ == '__main__':
    
    np.random.seed(1234)

    dec_dir = '../../data/models/vaegan/france_15_rgba/saved_model_embed_in/1'
    enc_dir = '../../data/models/vaegan/france_15_rgba/saved_model_image_in/1'

    encoder = Encoder(enc_dir)
    decoder = Decoder(dec_dir)

    with open('../test.png', 'rb') as f:
        img = f.read()

    for a in range(10):
        res = encoder.encode(img)
        np.save('../test{}.npy'.format(a), res)
        im = decoder.decode(res)
        
        imwrite('../test_save{}.png'.format(a),add_black_bg(cat_to_rgba(np.array(im), ((0, 0, 1), (0, 1, 0), (1, 1, 1), (1, 0, 0)))))