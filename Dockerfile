FROM discourse/base:release
RUN apt-get install -y expect
USER 1000
EXPOSE 8080
WORKDIR /var/www/discourse
