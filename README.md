# Wave Rider

Rails 8 기반 한국 주식 섹터/대장주 선별 대시보드입니다. 개인용으로 Tailscale/VPN 안에서 접속하는 전제를 둡니다.

## 구성

- Rails 8.1, PostgreSQL, Solid Queue
- Hotwire: ERB, Turbo, Stimulus
- 단일 관리자 로그인
- 키움증권 REST API 실전 도메인: `https://api.kiwoom.com`

## 환경 변수

`.env.example`을 기준으로 `.env`를 만들고 값을 채웁니다.

- `ADMIN_USERNAME`, `ADMIN_PASSWORD`
- `KIWOOM_APP_KEY`, `KIWOOM_SECRET_KEY`
- `KIWOOM_REQUEST_DELAY`

API 키와 시크릿은 DB에 저장하지 않습니다.

## Docker 실행

```sh
cp .env.example .env
docker compose build
docker compose up -d db
docker compose run --rm web ./bin/rails db:prepare
docker compose up -d web jobs
```

앱 접속:

```text
http://localhost:3000
```

## 화면 제공 정보

대시보드는 선택한 거래일과 스냅샷 기준으로 저장된 정보를 보여줍니다. 상단에서 거래일과 스냅샷(`14:30 장중`, `16:00 장마감 확정`)을 선택할 수 있고, 현재 수집 상태와 재수집 버튼을 함께 제공합니다.

### 글로벌자산

스냅샷 수집 시점에 함께 저장된 글로벌자산 정보를 화면 상단에 표시합니다. 카테고리는 지수, 원자재, 외환, 가상화폐 순서로 병렬 배치되며, 각 항목은 가격, 변동량, 변동률 순으로 표시됩니다.

- 지수: 나스닥, 다우존스, S&P500, 코스피, 코스피200 선물, 필라델피아 반도체
- 원자재: 금, 은, WTI, 천연가스, 구리, 미국 옥수수
- 외환: 원/달러, 유로/달러, 파운드/달러, 엔/달러
- 가상화폐: 비트코인, 이더리움, 리플, 솔라나

가격은 검은색으로 표시하고, 변동량과 변동률은 상승이면 빨간색, 하락이면 파란색, 보합이면 검은색으로 표시합니다. 해당 스냅샷에 저장된 글로벌자산 데이터가 없으면 카테고리별로 `저장된 데이터 없음`을 표시합니다.

### 섹터 프리뷰

글로벌자산 아래에는 선택한 스냅샷에 포함된 섹터만 요약해서 보여줍니다. 섹터 미지정은 프리뷰에서 제외하고, 총거래대금이 큰 섹터가 먼저 오도록 정렬합니다.

- 도넛 차트는 섹터별 총거래대금 비중으로 구성합니다.
- 차트 색상은 거래대금가중평균변동률을 5% 단위로 나눠 상승은 빨간 계열, 하락은 파란 계열로 표시합니다.
- 차트 중앙에는 프리뷰 대상 섹터들의 총거래대금 합산액을 표시합니다.
- 상위 3개 섹터는 차트 영역에 섹터명을 표시하고, 나머지는 `기타`로 묶어 표시합니다.
- 우측 섹터 목록에는 섹터명, 종목수, 총거래대금, 거래대금가중평균변동률을 표시합니다.

### 섹터별 상세

본문은 섹터 박스 단위로 구성됩니다. 각 섹터 박스는 종목수, 총거래대금, 거래대금가중평균변동률을 헤더에 표시하고, 내부 종목은 대장주가 먼저 오며 나머지는 거래대금 내림차순으로 정렬됩니다.

각 종목 카드에는 종목명, 종목코드, 거래대금, 변동률, 일봉 차트, 현재 섹터, 대장주 선택 토글을 표시합니다. 섹터는 카드 안에서 기존 섹터 선택 또는 새 섹터명 입력으로 수정할 수 있습니다.

종목 카드의 `10영업일 지표`를 펼치면 일자별 기관, 연금, 외인, 개인 순매수와 체결강도를 확인할 수 있습니다.

## VPN 직접 접속

Mac mini와 접속할 기기에 Tailscale을 설치하고 같은 tailnet에 로그인하면, Mac mini의 Tailscale IP로 직접 접속할 수 있습니다.

Mac mini에서 Tailscale IPv4 주소를 확인합니다.

```sh
tailscale ip -4
```

`no current Tailscale IPs; state: Stopped`가 나오면 Tailscale이 꺼져 있는 상태입니다. macOS 메뉴 막대의 Tailscale 앱에서 `Turn On` 또는 `Log In`을 먼저 실행합니다. CLI로 시작할 수 있는 설치 환경이면 아래 명령을 사용합니다.

```sh
sudo tailscale up
```

상태 확인:

```sh
tailscale status
tailscale ip -4
```

Docker 서비스가 실행 중인지 확인합니다.

```sh
docker compose ps
```

다른 기기에서 Tailscale VPN을 켠 뒤 아래 주소로 접속합니다.

```text
http://<mac-mini-tailscale-ip>:3000
```

예:

```text
http://100.x.y.z:3000
```

현재 개발 환경 설정은 Tailscale IP 대역(`100.64.0.0/10`)을 Rails host로 허용합니다. Tailscale MagicDNS 이름으로 접속하려면 `.env`에 해당 호스트명을 추가하고 `web`을 재시작합니다.

```env
APP_HOSTS=mac-mini-name.tailnet-name.ts.net,mac-mini-name
```

```sh
docker compose restart web
```

주의:

- 이 방식은 `docker-compose.yml`의 `web` 포트가 `"3000:3000"`으로 열려 있어야 합니다.
- 공유기에서 3000번 포트를 포트포워딩하지 마세요.
- 앱 로그인 비밀번호는 긴 값으로 바꾸세요.
- PostgreSQL은 외부 접속이 필요 없으면 `db` 서비스의 `ports` 설정을 제거하는 편이 안전합니다.

## Docker 재빌드

코드 변경 후 이미지까지 새로 만들고 싶으면 실행 중인 컨테이너를 내리고, 기존 로컬 이미지를 삭제한 뒤 다시 빌드합니다.

```sh
docker compose down --rmi local --remove-orphans
docker compose build --no-cache
docker compose up -d db
docker compose run --rm web ./bin/rails db:prepare
docker compose up -d web jobs
```

PostgreSQL 데이터 볼륨까지 완전히 삭제해야 할 때만 아래 명령을 사용합니다. 저장된 스냅샷과 섹터 수정 내역도 함께 사라집니다.

```sh
docker compose down --volumes --rmi local --remove-orphans
```

## 수집 스케줄

Solid Queue recurring task가 아래 두 시각에 수집 잡을 넣습니다.

- 14:30 장중 스냅샷
- 16:00 장마감 확정 스냅샷

각 잡은 키움 API로 실제 거래일 여부를 확인하고, 비거래일이면 수집하지 않습니다.

Mac mini 절전, Docker 재시작, 일시적인 프로세스 중단 등으로 정각 스케줄을 놓친 경우에는 대시보드 접속 시 보정 트리거가 동작합니다. 현재 시간이 수집 시각 이후인데 오늘 해당 스냅샷이 없으면, 오늘 날짜의 스냅샷 row를 만들고 수집 잡을 한 번만 큐에 넣습니다.

개별 종목의 10영업일 지표가 부족한 경우에는 해당 종목만 경고 로그로 남기고 건너뜁니다. 키움 API 자체 실패나 수집 가능한 종목이 하나도 없는 경우에는 해당 스냅샷을 실패 처리합니다.

## 검증

```sh
docker compose run --rm web ./bin/rails test
docker compose run --rm web ./bin/rails zeitwerk:check
docker compose run --rm web bundle exec rubocop
```
