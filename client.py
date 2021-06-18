import socket
import json

HOST = "127.0.0.1"
PORT = 65432


with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.connect((HOST, PORT))
    s.setblocking(False)
    s.sendall(b'Hello, world')
    conn_file = s.makefile('r')
    while True:
        line = conn_file.readline().strip()
        if len(line) > 0:
            json_data = json.loads(line)
            print(json_data)
