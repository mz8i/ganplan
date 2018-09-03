#!/bin/bash

tensorflow_model_server --port=8499 --rest_api_port=9499 --model_base_path=$(pwd)/saved_model_image_in/ --model_name=vaeenc