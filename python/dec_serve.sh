#!/bin/bash

tensorflow_model_server --port=8500 --rest_api_port=9500 --model_base_path=$(pwd)/saved_model_embed_in/ --model_name=vaedec