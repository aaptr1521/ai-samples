from flask import Flask
import os


def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'hfjekweiurueoitoekokfoek45345hjhjer'
    IMAGE_FOLDER = os.path.join('static', 'images')
    app.config['UPLOAD_FOLDER'] = IMAGE_FOLDER

    return app