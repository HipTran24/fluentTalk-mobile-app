# english_mobile_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Backend Setup (Spring Boot 4.2 milestone / Java 27)

The backend is built as a modular monolith in `backend/` using Spring Boot 4.2.0-M2 and Java 27. The milestone runtime has not been accepted for production.

Read [the current setup guide](docs/THIET_LAP_DE_CHAY_APP_THUC_TE.md) and [the detailed remaining-stage plan](docs/KE_HOACH_CHI_TIET_GIAI_DOAN_4_DEN_8.md), both dated 22/10/2026. Adding credentials alone does not enable the unfinished AI/audio/coach integrations. The setup guide records current source findings separately from historical test results.

### Prerequisites

- **Java 27**: Installed toolchain at `/Users/ProM2/.cache/english-speaking-ai/toolchains/jdk-27.0.1.jdk/Contents/Home`
- **Maven 3.9+** (or use the provided `backend/mvnw` wrapper)
- **Docker & Docker Compose** (for local PostgreSQL infrastructure)

### Environment Configuration

Create a local environment file from the template:
```bash
cp .env.example .env
```
Never commit `.env` or production credentials to source control.

Creating `.env` alone does not inject configuration into Spring or Flutter. Configure the backend process environment in your IDE/host. Flutter reads Dart defines; use only public values in `config/mobile.public.example.json`, never the backend secret file.

### Local Infrastructure (PostgreSQL)

Start the local PostgreSQL container:
```bash
docker compose -f infra/docker-compose.yml up -d
```
To stop the database:
```bash
docker compose -f infra/docker-compose.yml down
```

### Build & Run Tests

Run the full backend test suite using Java 27:
```bash
cd backend
JAVA_HOME=/Users/ProM2/.cache/english-speaking-ai/toolchains/jdk-27.0.1.jdk/Contents/Home ./mvnw clean test
```

### Running the Application

Start the backend server on port 8080:
```bash
cd backend
JAVA_HOME=/Users/ProM2/.cache/english-speaking-ai/toolchains/jdk-27.0.1.jdk/Contents/Home ./mvnw spring-boot:run
```

Verify the sanitized public health endpoint:
```bash
curl -i http://localhost:8080/api/v1/health
```
Expected response:
```json
{
  "status": "UP"
}
```
Response header `X-Request-Id` contains the correlation UUID.

### Current delivery status

Read [the Vietnamese eight-stage plan](docs/KE_HOACH_8_GIAI_DOAN.md) and [the final status report](docs/FINAL_STATUS.md) before running this snapshot. The four-hour scope was not completed. Java 27 auth/profile/catalog works locally; production AI, audio, realtime, coaching and full privacy flows are unfinished. Spring Boot 4.2.0-M2 is a milestone, not a production stability claim.

Android builds require a separate compatible JDK (JDK 21 was used locally), Gradle 8.14.3, AGP 8.11.1 and Kotlin 2.2.20. Set the Android JDK in your own Flutter/IDE configuration; do not hardcode a machine path in `android/gradle.properties`. Backend remains Java 27. Toolchain bounds were checked against the installed Flutter SDK and [official AGP compatibility documentation](https://developer.android.com/build/releases/agp-8-11-0-release-notes).

For an explicitly simulated mobile preview:

```bash
flutter run --dart-define=DEMO_MODE=true
```

The app displays a DEMO banner. Normal builds keep unfinished learning routes unavailable for real identities. See the final report for actual test and Android packaging results; a debug preview is not a release build.
