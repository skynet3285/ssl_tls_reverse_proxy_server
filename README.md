# SSL-TLS Reverse Proxy Server

# 개요

SSL-TLS Reverse Proxy Server는 Let's Encrypt의 인증서를 사용하여 HTTPS 연결을 제공하는 서버입니다. 이 서버는 `certbot`을 통해 인증서를 발급하고 자동으로 갱신합니다.

# 설명

이 프로젝트는 Reverse Proxy Server를 구성하여 외부 클라이언트와 내부 서버 간의 안전한 통신을 보장합니다. (그러기 위해서는 외부 포트만 노출시켜야합니다. 예를들어 nginx.conf의 listen는 외부망 노출, proxy_pass는 내부망에서만 접속, 이렇게 구성해야합니다.) `certbot`을 사용해 Let's Encrypt 인증서를 발급하고 자동 갱신을 설정할 수 있습니다. 또한, Nginx를 Reverse Proxy로 설정하여 SSL/TLS 통신을 처리합니다.

nginx:alpine 도커 이미지를 이용하여 구축하였습니다. 2024.11.13 기준 최신 이미지로 프로젝트는 문제 없이 동작합니다.

# 프로젝트 중요 파일

- `init_cert.sh copy`: 초기에 인증서 발급 및 설정을 위한 예시 스크립트입니다.
- `certbot`: certbot의 설정과 인증서가 저장되는 디렉토리입니다.
- `docker-compose.yml` : 서버를 자동으로 구축하기 위한 docker-compose입니다.
- `ssl_tls_reverse_proxy_server/nginx.conf.template`: Nginx 설정 템플릿 파일입니다.

## 프로젝트 구성 방법

[1. 초기 인증서 발급 방법](#초기-인증서-발급-방법)

[2. nginx conf 설정](#nginx-conf-설정)

[3. docker-compose yml 수정](#docker-compose-yml-수정)

[4. 구성 완료 및 서버 시작](#구성-완료-및-서버-시작)

### 초기 인증서 발급 방법

`ssl_tls_certbot_server/nginx copy.conf`를 복사하여 `ssl_tls_certbot_server/nginx.conf`를 만들고 ${DOMAIN_NAME}을 실제 도메인(ex, example.com)으로 수정합니다.

`init_cert.sh copy`을 참고하여 수정 후 해당 쉘을 실행합니다.

쉘이 실행되고 몇 가지 certbot의 초기 인증서 발급을 위한 실행 과정을 거치면 .well-known/acme-challenge 관한 설정 안내가 나옵니다.

이때, certbot 디렉토리가 생성되고, `certbot/var/.well-known/acme-challenge/certbot에서 안내한 파일 이름`를 생성하고, 파일 안에 `certbot에서 안내한 내용`을 넣습니다.

Let's Encrypt 인증서를 발급받습니다. 발급된 인증서는 `certbot/etc/letsencrypt` 경로에 저장됩니다.

### nginx conf 설정

`ssl_tls_reverse_proxy_server/nginx copy.conf`를 복사하여 `ssl_tls_reverse_proxy_server/nginx.conf`를 만들고 수정합니다.

${DOMAIN_NAME}에 서버 도메인을 넣고 외부망에 노출할 PORT(https 통신)를 지정합니다. ${PROXY_PASS_URL}:${PROXY_PORT}에 실제 연결할 URL과 PROXY_PORT를 지정합니다. PROXY_PORT(http 통신)는 외부망에 노출되지 않아야 합니다.

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
    container_name: ssl-tls-reverse-proxy
    build:
      context: ./ssl_tls_reverse_proxy_server
      dockerfile: Dockerfile
    ports:
      - "3000:3001" # React Service
```

외부망에 노출할 port를 3000(https 통신)으로 설정했다면 호스트 3000에서 컨테이너 3001로 연결합니다.

### 구성 완료 및 서버 시작

시작할때는 아래와 같이 시작하고

```bash
docker-compose up -d
```

아래와 같이 종료하면 됩니다.

```bash
docker-compose down
```

### 참고

이미지 관련 에러가 뜨면, 아래와 같이 프로젝트 도커 이미지를 빌드를 해주세요

```bash
docker-compose build
```

종료 및 컨테이너 이미지를 깔끔하게 제거합니다.

```bash
docker-compose down --rmi all
```
