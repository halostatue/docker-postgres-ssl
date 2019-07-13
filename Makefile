.PHONY: ca server_ssl client_ssl ssl up

OUTPUT_FOLDER=./run/ssl-files
OPENSSL_COMMAND=scripts/docker-ssl

$(OUTPUT_FOLDER):
	@mkdir -p $(OUTPUT_FOLDER)

ca: $(OUTPUT_FOLDER)/ca-key.pem
server_ssl: $(OUTPUT_FOLDER)/server-cert.pem
client_ssl: $(OUTPUT_FOLDER)/client-cert.pem

$(OUTPUT_FOLDER)/ca-key.pem: $(OUTPUT_FOLDER)
	@$(OPENSSL_COMMAND) $(OUTPUT_FOLDER) req -new -x509 -nodes \
		-newkey rsa -out ca.pem -keyout ca-key.pem \
		-set_serial 01 -batch -subj "/CN=ssl-server"
	@$(OPENSSL_COMMAND) $(OUTPUT_FOLDER) rsa -in ca-key.pem -out ca-key.pem

$(OUTPUT_FOLDER)/server-key.pem: ca
	@$(OPENSSL_COMMAND) $(OUTPUT_FOLDER) req -new -newkey rsa -keyout \
		server-key.pem -out server-req.pem -passout pass:abcd \
		-subj "/CN=postgres-ssl-server"
	@$(OPENSSL_COMMAND) $(OUTPUT_FOLDER) rsa -in server-key.pem \
		-out server-key.pem -passin pass:abcd

$(OUTPUT_FOLDER)/server-cert.pem: $(OUTPUT_FOLDER)/server-key.pem
	@$(OPENSSL_COMMAND) $(OUTPUT_FOLDER) x509 -req -in server-req.pem \
		-CA ca.pem -CAkey ca-key.pem -set_serial 02 \
		-out server-cert.pem

$(OUTPUT_FOLDER)/client-key.pem: ca
	@$(OPENSSL_COMMAND) $(OUTPUT_FOLDER) req -new -newkey rsa \
		-keyout client-key.pem -out client-req.pem -passout pass:abcd \
		-subj "/CN=postgres-ssl-server"
	@$(OPENSSL_COMMAND) $(OUTPUT_FOLDER) rsa -in client-key.pem \
		-out client-key.pem -passin pass:abcd

$(OUTPUT_FOLDER)/client-cert.pem: $(OUTPUT_FOLDER)/client-key.pem
	@$(OPENSSL_COMMAND) $(OUTPUT_FOLDER) x509 -req -in client-req.pem \
		-CA ca.pem -CAkey ca-key.pem -set_serial 03 \
		-out client-cert.pem

ssl: ca server_ssl client_ssl
	@chmod 0600 "$(OUTPUT_FOLDER)"/*

up: ssl
	@docker-compose up -d

down:
	@docker-compose down

restart: ssl
	@docker-compose restart
