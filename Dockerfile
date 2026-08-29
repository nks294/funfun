FROM node:20-bookworm-slim AS frontend-build

WORKDIR /frontend

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

RUN npm run build


FROM gradle:8-jdk17 AS backend-build

WORKDIR /backend

COPY backend ./

RUN gradle \
    --no-daemon \
    -Dorg.gradle.java.home="$JAVA_HOME" \
    clean bootJar


FROM eclipse-temurin:17-jre-jammy

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        supervisor && \
    rm -rf /var/lib/apt/lists/*

RUN rm -rf /usr/share/nginx/html/*

COPY --from=frontend-build \
    /frontend/build \
    /usr/share/nginx/html/funfun

COPY --from=backend-build \
    /backend/build/libs/backend.jar \
    /app/backend.jar

COPY docker/nginx.conf \
    /etc/nginx/sites-available/default

COPY docker/supervisord.conf \
    /etc/supervisor/conf.d/funfun.conf

EXPOSE 80

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
