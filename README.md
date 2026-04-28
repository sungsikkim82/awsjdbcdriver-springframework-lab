# AWS JDBC Driver Wrapper + Spring Boot Lab

AWS Advanced JDBC Wrapper를 사용하여 Aurora PostgreSQL에 연결하는 Spring Boot 애플리케이션입니다.

## 아키텍처

```
[Spring Boot App]
    │
    ├── Writer DataSource (External HikariCP)
    │       │
    │       └── AWS JDBC Wrapper (SF_F0 + Internal Pool)
    │               └── Aurora Writer
    │
    └── Reader DataSource (External HikariCP)
            │
            └── AWS JDBC Wrapper (SF_F0 + Internal Pool)
                    │  leastConnections 전략으로 균등 분배
                    │
                    ├── Reader 1 (Internal Pool)
                    ├── Reader 2 (Internal Pool)
                    ├── Reader 3 (Internal Pool)
                    ├── Reader 4 (Internal Pool)
                    └── Reader 5 (Internal Pool)
```

## External Pool + Internal Pool 이중 구조

본 프로젝트는 External Pool(HikariCP)과 Internal Pool(Wrapper 자체 HikariCP)을 동시에 사용합니다.

### 왜 이중 구조인가?

| 구성 | Reader 균등 분배 | 기동 시 min pool 유지 |
|---|---|---|
| External Pool만 (G0 프리셋) | ❌ DNS 라운드로빈 의존, 한쪽 몰림 | ✅ |
| Internal Pool만 (E 프리셋) | ✅ 인스턴스별 분배 | ❌ 요청 시 생성 |
| **External + Internal (SF_F0 프리셋)** | **✅ 균등 분배** | **✅ 기동 시 유지** |

### 동작 원리

```
External HikariCP (reader-pool, minimum-idle: 100)
    │
    │  "커넥션 100개 채워야 함"
    │
    └── 매 커넥션 요청마다
            │
            └── AWS JDBC Wrapper (Internal Pool)
                    │
                    │  leastConnections: 커넥션 가장 적은 reader 선택
                    │
                    ├── 1번째 → Reader 1 (0개 → 1개)
                    ├── 2번째 → Reader 2 (0개 → 1개)
                    ├── 3번째 → Reader 3 (0개 → 1개)
                    ├── 4번째 → Reader 4 (0개 → 1개)
                    ├── 5번째 → Reader 5 (0개 → 1개)
                    ├── 6번째 → Reader 1 (1개 → 2개)
                    └── ... (100개까지 균등 분배)
```

External HikariCP가 `minimum-idle`을 채우기 위해 커넥션을 요청할 때마다, Internal Pool이 `leastConnections` 전략으로 가장 커넥션이 적은 reader를 선택합니다. 결과적으로 reader 5개에 각 20개씩 균등 분배됩니다.

## Reader 분배 전략 (readerHostSelectorStrategy)

| 전략 | 설명 | 조건 |
|---|---|---|
| `random` | 랜덤 선택 (기본값) | 없음 |
| `roundRobin` | 순차적으로 돌아가며 선택 | 없음 |
| `leastConnections` | **커넥션 수가 가장 적은 reader 선택** | Internal Pool 필수 |
| `fastestResponse` | 응답 시간이 가장 빠른 reader 선택 | 별도 플러그인 필요 |

본 프로젝트는 `leastConnections`를 사용합니다.

## Configuration Preset: SF_F0

| 접두사/코드 | 의미 |
|---|---|
| **SF_** | Spring Framework 최적화 — readWriteSplitting 플러그인 비활성 |
| **F** | Internal Connection Pool + failover + efm2 + replica load balancing |
| **0** | Normal 감도 — false positive과 감지 속도의 균형 |

### 프리셋 패밀리 비교

| 패밀리 | 커넥션 풀 | 대상 |
|---|---|---|
| A, B, C | 없음 | 커넥션 풀 미사용 환경 |
| D, E, F | Internal Pool | Wrapper 자체 풀 사용 |
| G, H, I | External Pool | HikariCP 등 외부 풀 사용 |
| SF_D, SF_E, SF_F | Internal Pool + Spring 최적화 | Spring Boot 애플리케이션 |

## 현재 설정 옵션

```yaml
datasource:
  writer:
    jdbc-url: jdbc:aws-wrapper:postgresql://<writer-cluster-endpoint>:5432/<database>
    driver-class-name: software.amazon.jdbc.Driver
    pool-name: writer-pool
    minimum-idle: 100          # 최소 유지 커넥션
    maximum-pool-size: 500     # 최대 커넥션
    data-source-properties:
      wrapperProfileName: SF_F0                        # Spring 최적화 프리셋
      readerHostSelectorStrategy: leastConnections     # 균등 분배 전략

  reader:
    jdbc-url: jdbc:aws-wrapper:postgresql://<reader-cluster-endpoint>:5432/<database>
    driver-class-name: software.amazon.jdbc.Driver
    pool-name: reader-pool
    minimum-idle: 100
    maximum-pool-size: 500
    data-source-properties:
      wrapperProfileName: SF_F0
      readerHostSelectorStrategy: leastConnections
```

## 시작하기

### 사전 조건
- Java 17
- Aurora PostgreSQL 클러스터
- EC2 인스턴스 (배포 시, 보안 그룹 8080 포트 오픈)

### 설정

1. 환경변수 파일 생성
```bash
mkdir -p ~/.env
cp .env.example ~/.env/awsjdbcdriver.env
```

2. `~/.env/awsjdbcdriver.env`에서 본인 환경에 맞게 값 수정
```bash
# EC2
export EC2_HOST="<ec2-public-dns>"
export EC2_USER="ec2-user"
export PEM_KEY="<path-to-pem-key>"

# Database
export DB_WRITER_ENDPOINT="<writer-cluster-endpoint>"
export DB_READER_ENDPOINT="<reader-cluster-endpoint>"
export DB_NAME="<database>"
export DB_USERNAME="<username>"
export DB_PASSWORD="<password>"
```

> 이 파일은 `.gitignore`에 포함되어 GitHub에 올라가지 않습니다.

### 실행
```bash
# 로컬 실행
source ~/.env/awsjdbcdriver.env
./gradlew bootRun

# EC2 배포 (빌드 + 업로드 + 재시작 자동화)
bash deploy.sh
```

`deploy.sh`는 다음을 자동으로 수행합니다:
1. `~/.env/awsjdbcdriver.env` 로드
2. Gradle 빌드
3. jar, env, start.sh를 EC2에 업로드
4. EC2에서 환경변수 로드 후 앱 시작

### 접속
- 메인 페이지: `http://<host>:8080`
- 쿼리 콘솔: `http://<host>:8080/query.html`
- Actuator 메트릭: `http://<host>:8080/actuator/metrics/hikaricp.connections.idle`
