from flask import Flask, request, render_template_string
from datetime import datetime, timedelta
from threading import Lock

app = Flask(__name__)
status_data = {}
data_lock = Lock()

# HTML-template met leesbare sessieduur
template = """
<!doctype html>
<html>
<head>
  <meta http-equiv="refresh" content="5">
  <title>Cyberresilience Status Tracker</title>
  <style>
    table { width: 70%; border-collapse: collapse; margin: 20px auto; font-family: sans-serif; }
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
    <tr><th>Student</th><th>IP</th><th>Status</th><th>Laatste update</th><th>⏱ Duur sessie</th></tr>
    {% for student, info in status_data.items() %}
      {% set ago = now - info['last_seen'] %}
      {% set duur = now - info['start_time'] %}
      {% set total_seconds = duur.total_seconds() | int %}
      {% set hours = total_seconds // 3600 %}
      {% set minutes = (total_seconds % 3600) // 60 %}
      {% set seconds = total_seconds % 60 %}
      {% set formatted_dur = "{:02d}u {:02d}m {:02d}s".format(hours, minutes, seconds) %}

      {% if ago > timeout %}
        <tr class="timeout">
          <td>{{ student }}</td><td>{{ info['ip'] }}</td><td>⏳ Geen update</td><td>{{ info['last_seen'] }}</td><td>{{ formatted_dur }}</td>
        </tr>
      {% elif info['status'] == 'secure' %}
        <tr class="online">
          <td>{{ student }}</td><td>{{ info['ip'] }}</td><td>✅ Secure</td><td>{{ info['last_seen'] }}</td><td>{{ formatted_dur }}</td>
        </tr>
      {% else %}
        <tr class="vulnerable">
          <td>{{ student }}</td><td>{{ info['ip'] }}</td><td>❌ Kwetsbaar</td><td>{{ info['last_seen'] }}</td><td>{{ formatted_dur }}</td>
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
            if name not in status_data:
                # Eerste update → starttijd instellen
                status_data[name] = {
                    'ip': ip,
                    'status': status,
                    'last_seen': datetime.now(),
                    'start_time': datetime.now()
                }
            else:
                # Update bestaand record
                status_data[name]['ip'] = ip
                status_data[name]['status'] = status
                status_data[name]['last_seen'] = datetime.now()
        return 'OK'
    return 'Bad Request', 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
