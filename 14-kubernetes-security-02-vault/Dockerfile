FROM fedora:latest
RUN dnf install -y python3-pip && dnf clean all
RUN pip3 install hvac flask flask_restful
COPY vault-client.py /
RUN chmod +x /vault-client.py
EXPOSE 8080
ENTRYPOINT ["/vault-client.py"]
