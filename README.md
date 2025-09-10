Since you are using the certs from certbot, you may have to manually gen the hash for the TLSA record

Step 1 # Note, dont use sudo

Save the certificate with proper permissions:

openssl s_client -connect mail.example.com:465 -showcerts < /dev/null | openssl x509 -outform DER > /tmp/server_cert.der

Step 2

Generate the TLSA hash:
openssl x509 -in /tmp/server_cert.der -inform DER -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256

You should see something that looks like:
(stdin)= a1b2c3d4e5f6... (64-character hash)

Take the hash and included it n a TLSA record in your domain like the following

Type: TLSA
Host: _25._tcp.mail
Value: 3 1 1 your_64_character_hash_here

#Note: When you click on the dns button, it make show this as timed out.  Ignore it as you are using the generate CA certs to create hash.

Also add reuse_key= True in the following 

sudo nano /data/assets/ssl/renewal/mail.putyourdomain.com.conf

#Add under the [renewalparams]
reuse_key = True
