from app import create_app
from flask import render_template, request, flash
from app.ICS_model import ics_model
from app.saveimg import save_img
import os


app = create_app()


@app.route('/home', methods=['GET', 'POST'])
def home():
    return render_template("home.html")


@app.route('/results', methods=['GET', 'POST'])
def results():
    url = request.form.get('url')
    if request.method == 'POST' and (len(url) == 0):
        flash('No URL detected, please enter image URL', category='error')
        return render_template("home.html")
    elif request.method == 'POST' and len(url) > 1:
        flash('URL entered! Result is rendered below.', category='success')
        save_img(url)
        full_filename = os.path.join(app.config['UPLOAD_FOLDER'], 'result.jpg')
        prediction = ics_model(url)
        return render_template("results.html", user_image=full_filename, prediction=prediction)
    return render_template("results.html")

if __name__ == '__main__':
    app.run(debug=True)