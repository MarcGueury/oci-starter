FROM python:3.10-bullseye

RUN pip install --upgrade pip

RUN adduser -D myuser
USER myuser
WORKDIR /app
ENV PATH="/app/.local/bin:${PATH}"
COPY src/* /app/
COPY --chown=myuser:myuser src/* /app/
RUN pip3 install --user -r requirements.txt

ENTRYPOINT ["python3","rest.py"]

