FROM python:3.10

WORKDIR /report_manager

COPY ./requirements.txt .

RUN pip install --no-cache-dir --upgrade -r ./requirements.txt

COPY . .

EXPOSE 8001

CMD ["python", "./server.py"]