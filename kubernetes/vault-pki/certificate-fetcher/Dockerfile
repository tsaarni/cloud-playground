FROM python:3-alpine

COPY requirements.txt /
RUN pip install --no-cache-dir -r requirements.txt

COPY certificate-fetcher.py /

CMD [ "python", "-u", "/certificate-fetcher.py" ]
