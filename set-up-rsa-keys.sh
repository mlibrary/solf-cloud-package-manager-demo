openssl genrsa -out demo.pem 512
openssl rsa -in demo.pem -pubout -outform DER -out demo_public.der

