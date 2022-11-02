FROM python:3.8-slim-buster
COPY src/* /app/
WORKDIR /app
RUN pip3 install oracledb 
RUN pip3 install Flask
RUN pip3 install -U flask-cors
RUN pip3 install flask-mysql
ENTRYPOINT ["python3","rest.py"]
