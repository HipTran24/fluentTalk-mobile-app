#!/bin/bash
set -e

# FluentTalk AI - One-Click Launcher Script

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
WEB_BUILD_DIR="$PROJECT_DIR/build/web"
JAVA_JDK="$HOME/.cache/english-speaking-ai/toolchains/jdk-27.0.1.jdk/Contents/Home"

echo "=================================================="
echo "🚀 Khởi động FluentTalk AI (Backend + Web)..."
echo "=================================================="

# 1. Kiểm tra & Khởi động PostgreSQL qua Docker
if ! docker info >/dev/null 2>&1; then
    echo "⚠️  Docker daemon chưa bật, đang mở Docker Desktop..."
    open -a Docker
    sleep 8
fi

echo "📦 Khởi động Database PostgreSQL (Docker)..."
docker compose -f "$PROJECT_DIR/infra/docker-compose.yml" up -d

# 2. Khởi động Backend (Spring Boot trên cổng 8080)
if lsof -i :8080 >/dev/null 2>&1; then
    echo "✅ Backend đã đang chạy ở cổng 8080."
else
    echo "⚙️  Đang khởi chạy Backend Spring Boot ở cổng 8080..."
    JAVA_HOME="$JAVA_JDK" nohup "$BACKEND_DIR/mvnw" -f "$BACKEND_DIR/pom.xml" spring-boot:run > "$PROJECT_DIR/backend.log" 2>&1 &
    echo "⏳ Đang đợi Backend sẵn sàng..."
    for i in {1..20}; do
        if curl -s http://localhost:8080/api/v1/health >/dev/null 2>&1; then
            echo "✅ Backend đã sẵn sàng tại http://localhost:8080"
            break
        fi
        sleep 1
    done
fi

# 3. Khởi động Web Server (cổng 3000)
if lsof -i :3000 >/dev/null 2>&1; then
    echo "✅ Web Server đã đang chạy ở cổng 3000."
else
    echo "🌐 Đang khởi động Web Server phục vụ ứng dụng tại cổng 3000..."
    nohup python3 "$PROJECT_DIR/tools/serve_web.py" "$WEB_BUILD_DIR" > "$PROJECT_DIR/web.log" 2>&1 &
    sleep 1
fi

echo "=================================================="
echo "🎉 Ứng dụng đã sẵn sàng!"
echo "👉 Mở trình duyệt tại: http://localhost:3000"
echo "=================================================="

# Mở trình duyệt
open http://localhost:3000
