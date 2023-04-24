import socket
import ssl

host = 'localhost'
context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
context.load_verify_locations("server.crt")

with socket.create_connection((host, 1965)) as sock:
    with context.wrap_socket(sock, server_hostname=host) as ssock:
        print("Connected with: ", ssock.version())
        ssock.send("gemini://localhost/test".encode())
        data = ssock.recv(1024)
        print(data.decode())
