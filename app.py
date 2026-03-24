import os
import subprocess
import logging
from flask import Flask, render_template, request, Response, send_from_directory
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)

app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1)

log = logging.getLogger('werkzeug')
class HealthCheckFilter(logging.Filter):
    def filter(self, record):
        return "/status" not in record.getMessage()

log.addFilter(HealthCheckFilter())

@app.route('/status')
def status():
    return "OK", 200
    
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/favicon.ico')
def favicon():
    # Fixed: Now uses os and send_from_directory correctly
    return send_from_directory(os.path.join(app.root_path, 'static'),
                               'favicon.ico', mimetype='image/vnd.microsoft.icon')

@app.route('/search', methods=['POST'])
def search():
    card_list = request.form.get('cards', '').splitlines()

    def run_scripts():
        for card in card_list:
            card = card.strip()
            if not card: continue

            process = subprocess.Popen(['bash', 'cprice.sh', card],
                                     stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT,
                                     text=True)

            for line in process.stdout:
                yield line
            process.wait()
            yield "\n" 

    # Fixed: Added the streaming headers back in
    response = Response(run_scripts(), mimetype='text/plain')
    response.headers['X-Accel-Buffering'] = 'no'
    response.headers['Cache-Control'] = 'no-cache'
    return response

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
