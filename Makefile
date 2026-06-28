.PHONY: setup git-clone setup-win git-clone-win up down reset logs api workers infra db check-pg-dump check-cloud-sql-proxy proxy-up dump-local dump-cloud restore-local

# =========================================================
# 🧠 SETUP (Mac / Linux)
# =========================================================

setup:
	@echo "⚙️ Running setup (Mac/Linux)..."
	@bash scripts/setup.sh

git-clone:
	@echo "📦 Cloning repositories (Mac/Linux)..."
	@bash scripts/git-clone.sh

# =========================================================
# 🪟 SETUP (Windows)
# =========================================================

setup-win:
	@echo "⚙️ Running setup (Windows)..."
	@powershell -ExecutionPolicy Bypass -File scripts/setup.ps1

git-clone-win:
	@echo "📦 Cloning repositories (Windows)..."
	@powershell -ExecutionPolicy Bypass -File scripts/git-clone.ps1

# =========================================================
# 🚀 FULL ENVIRONMENT
# =========================================================

up:
	@echo "🚀 Starting full environment..."
	@docker compose up -d --build
	@echo ""
	@echo "✅ Services running:"
	@echo "👉 API:    http://localhost:8080"
	@echo "👉 MinIO:  http://localhost:9001"
	@echo "👉 DB:     localhost:5432"
	@echo ""

down:
	@echo "🛑 Stopping environment..."
	@docker compose down

reset:
	@echo "💣 Resetting environment (removing volumes)..."
	@docker compose down -v

logs:
	@echo "📜 Tailing logs..."
	@docker compose logs -f

# =========================================================
# 🧱 INFRASTRUCTURE ONLY (rápido)
# =========================================================

infra:
	@echo "🧱 Starting infrastructure..."
	@docker compose up -d pubsub-emulator minio db

# =========================================================
# 🚀 SERVICES (DESACOPLADOS)
# =========================================================

front:
	@echo "🎨 Starting frontend..."
	@docker compose up -d --build front

api:
	@echo "🚀 Starting API..."
	@docker compose up -d --build api

workers:
	@echo "⚙️ Starting workers..."
	@docker compose up -d --build worker-example

# =========================================================
# 🗄️ DATABASE
# =========================================================

db:
	@echo "🗄️ Starting database..."
	@docker compose up -d db



# =====================================
# VARIABLES DUMP DB
# =====================================
include .env.localdev

DUMP_DIR=dumps
GCP_KEY_FILE=./backend/config/credentials/sgc-dev.json
DATE=$(shell date +%Y%m%d_%H%M%S)

check-pg-dump:
	@command -v pg_dump >/dev/null 2>&1 || ( \
		echo "❌ pg_dump no está instalado."; \
		echo "👉 Mac: brew install postgresql"; \
		echo "👉 Ubuntu: sudo apt install postgresql-client"; \
		echo "👉 Windows: instala PostgreSQL tools"; \
		exit 1 \
	)

check-cloud-sql-proxy:
	@command -v cloud-sql-proxy >/dev/null 2>&1 || ( \
		echo "❌ cloud-sql-proxy no está instalado."; \
		echo "👉 Mac: brew install cloud-sql-proxy"; \
		echo "👉 Linux: curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.11.0/cloud-sql-proxy.linux.amd64 && chmod +x cloud-sql-proxy && sudo mv cloud-sql-proxy /usr/local/bin/"; \
		echo "👉 Windows: Descarga y renombra el exe desde https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.11.0/cloud-sql-proxy.x64.exe"; \
		exit 1 \
	)

# =====================================
# CLOUD SQL PROXY
# =====================================
proxy-up: check-cloud-sql-proxy
	@echo "🔌 Iniciando Cloud SQL Proxy en el puerto 5433..."
	@echo "🔑 Usando archivo de credenciales: $(GCP_KEY_FILE)"
	@echo "⚠️  (Deja esta terminal abierta y abre otra para hacer el dump)"
	cloud-sql-proxy $(CLOUDSQL_INSTANCE_CONNECTION_NAME) --port 5433 --credentials-file="$(GCP_KEY_FILE)"

# =====================================
# LOCAL
# =====================================
dump-local: check-pg-dump
	pg_dump \
	-h localhost \
	-U admin \
	-d app_db \
	> $(DUMP_DIR)/local_$(DATE).sql

# =====================================
# CLOUD (via proxy comprimido)
# =====================================
dump-cloud: check-pg-dump
	@echo "☁️  Haciendo dump de la base de datos en GCP..."
	@mkdir -p $(DUMP_DIR)
	PGPASSWORD=$(CLOUDSQL_DB_PASS) pg_dump \
		-h 127.0.0.1 \
		-p 5433 \
		-U $(CLOUDSQL_DB_USER) \
		-d $(CLOUDSQL_DB_NAME) \
		--no-owner \
		--no-privileges \
		-Fc \
		> $(DUMP_DIR)/cloud_$(DATE).dump
	@echo "✅ Dump completado en $(DUMP_DIR)/cloud_$(DATE).sql"


# =====================================
# CLOUD (via proxy .sql no comprimido modo texto para checar version)
# =====================================
dump-see-cloud-version:
	@echo "🔍 Consultando versión real..."
	PGPASSWORD=$(CLOUDSQL_DB_PASS) psql \
		-h 127.0.0.1 \
		-p 5433 \
		-U $(CLOUDSQL_DB_USER) \
		-d $(CLOUDSQL_DB_NAME) \
		-c "SHOW server_version;"


# =========================
# RESET DB
# =========================
db-reset:
	@echo "🧹 Reiniciando base de datos..."
	docker exec -i infra-postgres-db psql -U admin -d postgres -c "DROP DATABASE IF EXISTS app_db;"
	docker exec -i infra-postgres-db psql -U admin -d postgres -c "CREATE DATABASE app_db;"
	@echo "✅ DB limpia"

# =========================
# RESTORE CLOUD DUMP
# =========================
restore-cloud:
	@if [ -z "$(FILE)" ]; then echo "❌ Debes pasar FILE=dumps/archivo.dump"; exit 1; fi

	make db-reset

	@echo "📦 Restaurando dump en Docker..."
	cat $(FILE) | docker exec -i infra-postgres-db \
	pg_restore \
		-U admin \
		-d app_db \
		--no-owner \
		--no-privileges \
		--role=admin

	@echo "✅ Restore completo"

# =========================
# RESTORE DUMP (PRO)
# =========================
restore-local-dump:
	@if [ -z "$(FILE)" ]; then echo "❌ Debes pasar FILE=dumps/archivo.dump"; exit 1; fi
	make db-reset
	docker exec -i infra-postgres-db \
	pg_restore -U admin -d app_db < $(FILE)