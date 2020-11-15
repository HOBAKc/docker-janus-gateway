# Docker Janus-gateway
Janus WebRTC server Docker Image


### 소개
Ubuntu 18.04 + Janus gateway

#### * 사용 PORT
* 8880: expose janus documentation and admin/monitoring website
* 7088: expose Admin/monitor server
* 8088: expose Janus server
* 8188: expose Websocket server
* 10000-10200/udp: Used during session establishment

### 사용법
Docker와 Docker Compose은 설치 되어 있어야 합니다.

* Build the image
```
$ docker build -t hobakc/docker-janus-gateway .
```

* Run the container
```
$ DOCKER_IP=<YOUR DOCKER IP> docker-compose up

or 

$ DOCKER_IP=<YOUR DOCKER IP> docker run -p 80:80 -p 7088:7088 -p 8088:8088 -p 8188:8188 -p 10000-10200:10000-10200/udp hobakc/docker-janus-gateway
```
YOUR DOCKER IP에는 Public IP Address를 입력합니다.