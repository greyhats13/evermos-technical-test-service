FROM python:3.4-alpine
RUN apk add --no-cache bash
COPY . /app
WORKDIR /app
RUN pip3 install -r requirements.txt
EXPOSE 5000
# RUN chmod +x docker-entrypoint.sh
# ENTRYPOINT ["./docker-entrypoint.sh"]
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0"]