# Getting Started

* Download [Java 17.0.12](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) for your OS and follow the installation wizard.
* Install [Gradle 8.14.2](https://gradle.org/next-steps/?version=8.14.2&format=bin) and follow the installation instructions [here](https://gradle.org/install/#manually).
* Set your JAVA_HOME env var to your Java 17 path (if you don't know how to do this, it's worth looking up and learning to do on your own).
* In VS Code, install the following extensions: `Extension Pack for Java` and `Spring Boot Extension Pack`
* Install [Docker](https://docs.docker.com/get-started/get-docker/) for your OS and follow the installation instructions on the associated page. It's been a while since I did this but Docker is insanely mainstream so you'll find an answer to any questions. For Windows users, I think I went the WSL 2 backend option.

## To run the app

* (Java) In your CLI, change your directory to the `docker_resources/java_dockerfile` folder. From there, run `docker build -t java-compiler-runner .`.
This builds the image from the Dockerfile for java. This is strictly for the Java code compiler feature. Please update the README to reflect changes once the additional languages have been supported. You can confirm the image has been built correctly by running `docker images` or checking the Docker Desktop images tab.

* (JavaScript) In your CLI, change directory to `docker_resources/js_dockerfile` folder (do `cd ..` to get back to `docker_resources` directory if you are in `java_dockerfile`). From there, run `docker build -t js-compiler-runner .` This builds the image from the Dockerfile for javascript.

* (Python) In your CLI, change directory to `docker_resources/python_dockerfile`. From there, run `docker build -t python-compiler-runner .` This builds the image from the Dockerfile for Python.

* I just use the Spring Boot Dashboard on the side to start the backend. Once you see the startup logs in your terminal and a log for Tomcat and the port 8080, you should be set.
* To test the backend, make a free Postman account and download [Postman](https://www.postman.com/downloads/) for your OS and download the [Postman Desktop Agent](https://www.postman.com/downloads/postman-agent/). The Agent is required to overcome the CORS issue while testing.

## These are generated docs that just supply helpful links. Follow them if you want.

### Reference Documentation
For further reference, please consider the following sections:

* [Official Gradle documentation](https://docs.gradle.org)
* [Spring Boot Gradle Plugin Reference Guide](https://docs.spring.io/spring-boot/3.5.0/gradle-plugin)
* [Create an OCI image](https://docs.spring.io/spring-boot/3.5.0/gradle-plugin/packaging-oci-image.html)
* [Spring Web](https://docs.spring.io/spring-boot/3.5.0/reference/web/servlet.html)
* [Spring Boot DevTools](https://docs.spring.io/spring-boot/3.5.0/reference/using/devtools.html)

### Guides
The following guides illustrate how to use some features concretely:

* [Building a RESTful Web Service](https://spring.io/guides/gs/rest-service/)
* [Serving Web Content with Spring MVC](https://spring.io/guides/gs/serving-web-content/)
* [Building REST services with Spring](https://spring.io/guides/tutorials/rest/)

### Additional Links
These additional references should also help you:

* [Gradle Build Scans – insights for your project's build](https://scans.gradle.com#gradle)

