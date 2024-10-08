# SSL-TLS Reverse Proxy Server

# 개요

SSL-TLS Reverse Proxy Server는 Let's Encrypt의 인증서를 사용하여 HTTPS 연결을 제공하는 서버입니다. 이 서버는 `certbot`을 통해 인증서를 발급하고 자동으로 갱신합니다.

# 설명

이 프로젝트는 Reverse Proxy Server를 구성하여 외부 클라이언트와 내부 서버 간의 안전한 통신을 보장합니다. (그러기 위해서는 외부 포트만 노출시켜야합니다. 예를들어 nginx.conf의 listen는 외부망 노출, proxy_pass는 내부망에서만 접속, 이렇게 구성해야합니다.) `certbot`을 사용해 Let's Encrypt 인증서를 발급하고 자동 갱신을 설정할 수 있습니다. 또한, Nginx를 Reverse Proxy로 설정하여 SSL/TLS 통신을 처리합니다.

nginx:alpine, certbot/certbot 도커 이미지를 이용하여 구축하였습니다. 2024.10.03 기준 최신 이미지로 프로젝트는 문제 없이 동작합니다.

# 프로젝트 중요 파일

- `docker-compose.yml` : 서버를 자동으로 구축하기 위한 docker-compose입니다.
- `init_cert.sh`: 초기에 인증서 발급 및 설정을 위한 스크립트입니다.
- `ssl_tls_reverse_proxy_server/certbot`: 발급된 인증서가 저장되는 경로입니다.
- `ssl_tls_reverse_proxy_server/nginx/nginx.conf.template`: Nginx 설정 템플릿 파일입니다.

## 프로젝트 구성 방법

[1. 초기 인증서 발급 방법](#초기-인증서-발급-방법)

[2. nginx conf 설정](#nginx-conf-설정)

[3. docker-compose yml 수정](#docker-compose-yml-수정)

[4. 구성 완료 및 서버 시작](#구성-완료-및-서버-시작)

### 초기 인증서 발급 방법

`init_cert.sh` 파일을 참고하여 Let's Encrypt 인증서를 발급받습니다. 발급된 인증서는 `ssl_tls_reverse_proxy_server/certbot` 경로에 저장됩니다.

### nginx conf 설정

`ssl_tls_reverse_proxy_server/nginx/nginx.conf.template`를 복사하여 `ssl_tls_reverse_proxy_server/nginx/nginx.conf`를 만들고 수정합니다.

${DOMAIN_NAME}에 서버 도메인을 넣고 외부망에 노출할 PORT(https 통신)를 지정합니다. ${PROXY_PASS_URL}에 실제 연결할 URL과 PROXY_PORT를 지정합니다. PROXY_PORT(http 통신)는 외부망에 노출되지 않아야 합니다.

```nginx
    # ${DOMAIN_NAME}:${PORT} -> ${PROXY_PASS_URL}:${PROXY_PORT}
    server {
        listen ${PORT} ssl;
        server_name ${DOMAIN_NAME};

        ssl_certificate_key /etc/nginx/ssl/${DOMAIN_NAME}/privkey.pem;
        ssl_certificate /etc/nginx/ssl/${DOMAIN_NAME}/fullchain.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        location / {
            proxy_pass ${PROXY_PASS_URL}:${PROXY_PORT};
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
```

### docker-compose yml 수정

`ssl-tls-reverse-proxy` 서비스의 `ports`를 적절히 변경합니다.

```docker-compose
services:
  ssl-tls-reverse-proxy:
    image: ssl-tls-reverse-proxy
    container_name: ssl-tls-reverse-proxy
    build:
      context: ./ssl_tls_reverse_proxy_server
      dockerfile: Dockerfile
    ports:
      - "80:80" # Example HTTP for certbot's webroot certification port
      - "5000:5000" # Example HTTPS Port ( HTTPS Port -> Proxy Port )
```

여기에서 `"80:80" # Example HTTP for certbot's webroot certification port` 이부분은 80:80으로 설정해도 됩니다.
http 기본 포트 80으로 접근하는 certbot's webroot를 허용하기 위해서 호스트 80에서 컨테이너 80로 연결합니다.

외부망에 노출할 port를 5000(https 통신)으로 설정했다면 호스트 5000에서 컨테이너 5000로 연결합니다.

호스트 포트와 컨테이너 포트를 같게 안해도 됩니다.

### 구성 완료 및 서버 시작

이미지 관련 에러가 뜨면, 아래와 같이 프로젝트 도커 이미지를 빌드를 해주세요

```bash
docker-compose build
```

시작할때는 아래와 같이 시작하고

```bash
docker-compose up -d
```

아래와 같이 종료하면 됩니다.

```bash
docker-compose down
```

종료 및 컨테이너 이미지를 깔끔하게 제거합니다.

```bash
docker-compose down --rmi all
```
