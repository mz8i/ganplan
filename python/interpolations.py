import numpy as np
import os

from imageio import imread, imwrite
from PIL import Image

from tileutils import usemodel, wrangle

def lerp(a, b, t):
    return a * (1 - t) + b * t

def interp(a, b, k):
    """Returns the borders of intervals for [a,b] divided into k equal intervals"""
    return [lerp(a, b, i*1.0/k) for i in range(k+1)]
    
def shift(a, d, s, k):
    mvt = np.zeros(100)
    mvt[d]=s
    return a + mvt * k

def get_model(model_name):
    model_dir = os.path.join('..','data','models','vaegan', model_name)
    enc_dir = os.path.join(model_dir, 'saved_model_image_in','1')
    dec_dir = os.path.join(model_dir, 'saved_model_embed_in','1')

    encoder = usemodel.Encoder(enc_dir)
    decoder = usemodel.Decoder(dec_dir)
    
    return encoder, decoder
    
def get_encoding(encoder, input_name, name):
    input_dir = os.path.join('..','data','tiles', input_name)
    img = usemodel.read_img_bytes(os.path.join(input_dir, name+'.png'))
    enc = encoder.encode(img)
    return enc
    
    
colors_lookup = {
    'roads': ((1,1,1),),
    'buildings': ((1,0,0),),
    'rbw': ((1,0,0), (1,1,1), (0,0,1))
}
    
def decode_list(decoder, encodings, colors, reverse=False):
    images = [wrangle.cat_to_display(decoder.decode(enc), colors, reverse) for enc in encodings]
    return images
    
def show(images, _):
    res = np.hstack(images)
    im = Image.fromarray(res)
    im.show()
    
    
def save(images, output_folder):
    output_dir = os.path.join('../data/analysis/latent', output_folder)
    try:
        os.makedirs(output_dir)
    except OSError:
        pass
    for i, img in enumerate(images):
        path = os.path.join(output_dir, str(i+1)+'.png')
        imwrite(path, img)
    
    
def interp_files(encoder, decoder, input_name, output_dir, name1, name2, entity_type, n=10):
    enc1 = get_encoding(encoder, input_name, name1)
    enc2 = get_encoding(encoder, input_name, name2)
    interpolations = interp(enc1, enc2, n)
    images = decode_list(decoder, interpolations, colors_lookup[entity_type])
    return images
    
    
def move_vector(encoder, decoder, input_name, output_dir, name1, dimension, step, entity_type):
    enc1 = get_encoding(encoder, input_name, name1)
    movements = [shift(enc1, dimension, step, i) for i in range(11)]
    images = decode_list(decoder, movements, colors_lookup[entity_type])
    return images
    
    
def randomize_vector(encoder, decoder, input_name, output_dir, name1, entity_type, mult=1):
    enc1 = get_encoding(encoder, input_name, name1)
    movements = [enc1 + mult* np.random.randn() for i in range(11)]
    images = decode_list(decoder, movements, colors_lookup[entity_type])
    return images


rbw_enc, rbw_dec = get_model('france_15_rbw_128_full')
r_enc, r_dec = get_model('france_15_roads_128_full')
b_enc, b_dec = get_model('france_15_buildings_128_full')

show(interp_files(rbw_enc, rbw_dec, 'france-ghs-15-rbw-cat', '', '15_16620_11260', '15_16591_11274','rbw'))
show(interp_files(rbw_enc, rbw_dec, 'france-ghs-15-rbw-cat', '', '15_16618_11261', '15_16610_11261','rbw'))

show(interp_files(r_enc, r_dec, 'france-ghs-15-roads-cat', '', '15_16620_11260', '15_16591_11274', 'roads'))
show(move_vector(r_enc, r_dec, 'france-ghs-15-roads-cat', '', '15_16620_11260', 3, 10, 'roads'))
show(randomize_vector(r_enc, r_dec, 'france-ghs-15-roads-cat', '', '15_16620_11261', 'roads', 2))

# final interpolations

save(interp_files(r_enc, r_dec, 'france-ghs-15-roads-cat', '', '15_16566_11265', '15_16583_11295', 'roads'), 'interp_roads__15_16566_11265__15_16583_11295')

save(interp_files(rbw_enc, rbw_dec, 'france-ghs-15-rbw-cat', '', '15_16620_11260', '15_16591_11274', 'rbw'), 'interp_rbw__15_16620_11260__15_16591_11274')

#15_17031_11962