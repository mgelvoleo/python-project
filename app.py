from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello from Jenkins CI/CD! TESTING 2"

app.run(host="0.0.0.0", port=8000)
