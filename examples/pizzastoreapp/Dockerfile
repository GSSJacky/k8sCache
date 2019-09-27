FROM maven:3.6.1-amazoncorretto-8 as BUILD
#ADD m2.tar.gz /root
COPY . /usr/src/app
RUN mvn -Dmaven.repo.local=/root/m2 --batch-mode -f /usr/src/app/pom.xml clean package

FROM openjdk:alpine
EXPOSE 8080
COPY --from=BUILD /usr/src/app/target /opt/target
WORKDIR /opt/target
ENV _JAVA_OPTIONS ''

#CMD ["java", "-jar", "pizzastore.jar"]
ENTRYPOINT  ["java", "-jar", "pizzastore.jar"]
