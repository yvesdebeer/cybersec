from flask import Flask, request, render_template_string
from datetime import datetime, timedelta
from threading import Lock

app = Flask(__name__)
status_data = {}
data_lock = Lock()

# HTML-template met live-status overzicht
template = """
<!doctype html>
<html>
<head>
  <meta http-equiv="refresh" content="5">
  <title>Cyberresilience Status Tracker</title>
  <style>
    table { width: 60%; border-collapse: collapse; margin: 20px auto; font-family: sans-serif; }
    th, td { border: 1px solid #ccc; padding: 10px; text-align: center; }
    th { background: #333; color: #fff; }
    .online { background: #c8f7c5; }
    .vulnerable { background: #f7c5c5; }
    .timeout { background: #eee; color: #aaa; }
  </style>
</head>
<body>
  <h2 style="text-align:center">Live Student Cyberstatus</h2>
  <table>
    <tr><th>Student</th><th>IP</th><th>Status</th><th>Last Update</th></tr>
    {% for student, info in status_data.items() %}
      {% set ago = now - info['last_seen'] %}
      {% if ago > timeout %}
        <tr class="timeout">
          <td>{{ student }}</td><td>{{ info['ip'] }}</td><td>⏳ Geen update</td><td>{{ info['last_seen'] }}</td>
        </tr>
      {% elif info['status'] == 'secure' %}
        <tr class="online">
          <td>{{ student }}</td><td>{{ info['ip'] }}</td><td>✅ Secure</td><td>{{ info['last_seen'] }}</td>
        </tr>
      {% else %}
        <tr class="vulnerable">
          <td>{{ student }}</td><td>{{ info['ip'] }}</td><td>❌ Kwetsbaar</td><td>{{ info['last_seen'] }}</td>
        </tr>
      {% endif %}
    {% endfor %}
  </table>
</body>
</html>
"""

@app.route('/')
def index():
    with data_lock:
        now = datetime.now()
        return render_template_string(template,
                                      status_data=status_data,
                                      now=now,
                                      timeout=timedelta(minutes=3))

@app.route('/update', methods=['POST'])
def update():
    name = request.form.get('student')
    ip = request.remote_addr
    status = request.form.get('status')

    if name and status:
        with data_lock:
            status_data[name] = {
                'ip': ip,
                'status': status,
                'last_seen': datetime.now()
            }
        return 'OK'
    return 'Bad Request', 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)

