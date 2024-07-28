FROM openjdk:17
ADD target/ether-0.0.1-RELEASE.jar ether.jar
CMD ["java","-jar","ether.jar"]
