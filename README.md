# 🌍 GCP Local Workspace Template (Event-Driven Architecture)

Este repositorio define un **workspace local** para desarrollar sistemas basados en eventos (event-driven) inspirados en GCP, utilizando emuladores y servicios locales.

La idea principal es tener un **template limpio, desacoplado y extensible** que permita iniciar nuevos proyectos sin fricción, simulando una arquitectura productiva desde el día 1.

---

## 🧠 Concepto

Este workspace sigue una arquitectura basada en eventos utilizando **NATS JetStream** como Event Bus.

Los servicios no se comunican directamente entre sí; publican y consumen eventos a través de JetStream.

La arquitectura se compone de cuatro conceptos principales:

```
Backend
    │
    ▼
 Subject (Evento)
    │
    ▼
 Stream (Persistencia)
    │
    ▼
 Durable Consumer
    │
    ▼
 Worker
```

### Componentes

#### 🧱 Stream

Es el contenedor donde JetStream almacena uno o varios eventos (Subjects).

Ejemplo:

```
example_stream
```

Un mismo Stream puede contener múltiples eventos relacionados.

---

#### 📨 Subject

Representa un evento específico del sistema.

Ejemplos:

```
example.created
files.uploaded
vehicle.created
vehicle.images.process
```

El backend únicamente publica mensajes sobre un Subject.

---

#### 👷 Durable Consumer

Es el consumidor persistente encargado de leer los mensajes de un Subject.

Cada worker posee normalmente su propio Durable Consumer.

Ejemplo:

```
example-worker
image-worker
ocr-worker
```

Si un worker se reinicia, JetStream recuerda qué mensajes ya procesó.

---

#### ⚙️ Worker

Los workers contienen la lógica de negocio.

Se encargan de:

- consumir eventos
- procesar información
- interactuar con Storage
- guardar resultados en Base de Datos
- confirmar (ACK) únicamente cuando el procesamiento fue exitoso

---

### Beneficios

- Arquitectura desacoplada
- Persistencia de eventos
- Reintentos automáticos
- Escalabilidad horizontal
- Procesamiento asíncrono
- Trazabilidad completa

---

## 🧱 Estructura del Workspace

```bash
.
├── backend/         # API (FastAPI)
├── frontend/         # Frontend ssr (Remix(react+vite))
├── workers/         # Workers desacoplados (event-driven)
├── docker-compose.yml
├── env.example
```

### 🔹 Backend

Encargado de:

- Exponer endpoints (REST/WebSocket)
- Publicar eventos en Pub/Sub
- Orquestar lógica de entrada

> ⚠️ Su documentación vive en su propio README

---

### 🔹 Workers

Encargados de:

- Escuchar eventos desde Pub/Sub
- Procesar tareas específicas
- Ejecutar jobs desacoplados

Cada worker debe ser:

- Independiente
- Escalable
- Reemplazable

---

## 🚀 Infraestructura Local

El workspace levanta los siguientes servicios:

### 🐇 NATS JetStream

Event Bus utilizado para la comunicación entre servicios.

Puerto:

```
4222
```

Permite:

- publicar eventos
- persistir mensajes
- crear Durable Consumers
- realizar procesamiento asíncrono

### 🪣 MinIO (S3 local)

- Storage compatible con S3
- API: `http://localhost:9000`
- Console: `http://localhost:9001`

Credenciales por defecto:

```
user: admin
password: password123
```

---

### 🗄️ PostgreSQL

- Base de datos principal
- Puerto: `5432`

Credenciales:

```
user: admin
password: password
db: app_db
```

---

### 🚀 Backend API

- FastAPI
- Puerto: `8080`

---

### ⚙️ Workers

- Consumidores de eventos
- Ejemplo incluido: `worker-example`

---

## ⚙️ Configuración Inicial

### 1. Clonar el repositorio

```bash
git clone https://github.com/hector4like6gorillaz/workspace-event-driven-architecture-gpc
cd workspace-event-driven-architecture-gpc
```

---

### 2. Crear archivo de entorno

```bash
cp env.example .env.localdev
```

> ⚠️ Completa las variables según tu necesidad

---

### 3. Levantar todo el workspace

## 🛠️ Makefile Commands Guide

Este proyecto incluye un `Makefile` para facilitar la configuración y ejecución del entorno.

---

## 🧠 Setup (Mac / Linux)

    make setup

Ejecuta el script de configuración inicial para Mac/Linux.

    make git-clone

Clona los repositorios necesarios en Mac/Linux.

---

## 🪟 Setup (Windows)

    make setup-win

Ejecuta el script de configuración en Windows usando PowerShell.

    make git-clone-win

Clona los repositorios necesarios en Windows.

---

## 🚀 Full Environment

    make up

Levanta todo el entorno completo con Docker:

- API: http://localhost:8080
- MinIO: http://localhost:9001
- DB: localhost:5432

  make down

Detiene todos los servicios.

    make reset

Reinicia el entorno eliminando contenedores y volúmenes (⚠️ borra datos).

    make logs

Muestra los logs en tiempo real.

---

## 🧱 Infrastructure Only (rápido)

    make infra

Levanta solo la infraestructura básica:

- Pub/Sub Emulator
- MinIO
- Base de datos

---

## 🚀 Servicios desacoplados

    make api

Levanta únicamente la API.

    make workers

Levanta los workers.

---

## 🗄️ Base de Datos

    make db

Levanta únicamente la base de datos.

---

## 🧪 Database Dumps & Restore (Local ↔ Cloud)

Este workspace incluye herramientas para:

- 📥 Hacer dump de base de datos local
- ☁️ Hacer dump de Cloud SQL (vía proxy)
- 🔍 Ver versión de la base de datos remota
- ♻️ Restaurar dumps en tu entorno local Docker

---

## 🔧 Requisitos

Asegúrate de tener instalado:

- `pg_dump`
- `psql`
- `cloud-sql-proxy` (para Cloud SQL)

---

## 🔌 Conexión a Cloud SQL (Proxy)

Antes de hacer dump de Cloud, debes levantar el proxy:

    make proxy-up

⚠️ Deja esta terminal abierta

---

## 📥 Dump de Base de Datos

### 🟢 Dump Local (no comprimido)

    make dump-local

Genera:

    dumps/local_<timestamp>.sql

---

### ☁️ Dump Cloud SQL (comprimido - recomendado)

    make dump-cloud

Genera:

    dumps/cloud_<timestamp>.dump

✔️ Más rápido  
✔️ Más eficiente  
✔️ Ideal para restaurar

---

## 🔍 Ver versión de la base de datos Cloud

    make dump-see-cloud-version

Salida esperada:

    server_version
    --------------
    17.7 <- version de ejemplo que podria aparecer

---

## ♻️ Restaurar dump en entorno local (Docker)

### 🟣 Restaurar dump de Cloud

    make restore-cloud FILE=dumps/cloud_<timestamp>.dump

✔️ Limpia la base de datos  
✔️ Restaura el dump automáticamente  
✔️ Ignora roles de Cloud (compatibilidad local)

---

## 🧹 Reset manual de base de datos

    make db-reset

---

## 🧠 Notas importantes

- Los dumps de Cloud usan formato `.dump` (binario comprimido)
- Los dumps locales usan `.sql` (texto plano)
- El restore usa `pg_restore` con:
  - `--no-owner`
  - `--no-privileges`
- Esto evita errores de roles como:
  - `cloudsqlsuperuser`
  - usuarios internos de GCP

---

## 🚀 Flujo recomendado

1.  Levantar proxy:

        make proxy-up

2.  En otra terminal:

        make dump-cloud

3.  Restaurar en local:

        make restore-cloud FILE=dumps/cloud_<timestamp>.dump

---

## 🔥 Servicios Disponibles

| Servicio      | URL / Puerto          |
| ------------- | --------------------- |
| Frontend      | http://localhost:5173 |
| Backend API   | http://localhost:8080 |
| MinIO API     | http://localhost:9000 |
| MinIO Console | http://localhost:9001 |
| Pub/Sub       | http://localhost:8085 |
| PostgreSQL    | localhost:5432        |

---

## 🧪 Flujo de Trabajo (Ejemplo)

## 🧪 Flujo de Trabajo (Ejemplo)

```
Frontend
    │
    ▼
Backend API
    │
    ▼
Sube archivos a Storage
    │
    ▼
Publica evento

Subject:
example.created

    │
    ▼
JetStream

Stream:
example_stream

    │
    ▼
Durable Consumer

example-worker

    │
    ▼
Worker

    │
    ├── descarga archivos
    ├── procesa información
    ├── guarda resultados
    └── ACK
```

El backend únicamente publica eventos.

Los workers consumen dichos eventos de forma completamente desacoplada.
---

## ⚙️ Workers (Concepto)

Los workers viven en:

```bash
workers/src/worker_system/workers/
```

Cada worker representa un consumidor independiente de JetStream.

Ejemplo:

```
example-worker
```

Escucha el Subject:

```
example.created
```

mediante el Durable Consumer:

```
example-worker
```

Todos los workers reutilizan la infraestructura común:

- BaseWorker
- NATS Consumer
- Storage
- Database
- Logger

Por lo tanto únicamente necesitan implementar la lógica del Job.

### Cada worker debe

- Escuchar uno o varios Subjects.
- Procesar únicamente su responsabilidad.
- Hacer ACK únicamente cuando el Job terminó correctamente.
- Permitir que JetStream reprograme mensajes cuando ocurra un fallo.
- Ser completamente independiente del Backend.

---

## 📨 Streams, Subjects y Consumers

Una diferencia importante respecto a Pub/Sub es que un Stream puede contener múltiples eventos.

Ejemplo:

```
example_stream
│
├── example.created
├── example.updated
├── example.deleted
└── example.failed
```

Cada Subject representa un evento independiente.

Los workers consumen únicamente los Subjects que necesitan.

```
example-worker
    │
    └── example.created

audit-worker
    │
    ├── example.created
    └── example.deleted
```

Esto permite reutilizar un mismo Stream para múltiples procesos sin crear infraestructura adicional.

### 1. Crear estructura

```bash
workers/src/worker_system/workers/<nombre>/
```

Ejemplo:

```bash
workers/src/worker_system/workers/extractor/
```

---

### 2. Crear archivos base

```bash
main.py
job.py
```

---

### 3. Registrar en docker-compose

```yaml
worker-extractor:
  build:
    context: ./workers
  container_name: worker-extractor
  volumes:
    - ./workers:/app
  depends_on:
    - pubsub-emulator
    - db
    - minio
  env_file:
    - .env.localdev
  environment:
    PYTHONPATH: /app
  command: ["python", "src/worker_system/workers/extractor/main.py"]
```

---

## 🧠 Convención de Nombres

Para mantener consistencia en todos los proyectos se utiliza la siguiente convención.

### Streams

Representan un dominio funcional.

```
example_stream
vehicles_stream
users_stream
payments_stream
```

---

### Subjects

Representan eventos.

```
example.created
example.updated

vehicle.created
vehicle.images.uploaded

user.created

payment.completed
```

---

### Durable Consumers

Representan quién procesa los eventos.

```
example-worker
image-worker
ocr-worker
notification-worker
```

Esta convención permite escalar el sistema agregando nuevos eventos sin necesidad de crear nuevos Streams para cada uno.

---

## 🧩 Agregar Nuevos Servicios

Puedes extender el workspace agregando:

- Frontend (React, Next.js, etc.)
- Nuevos workers
- Nuevas APIs
- Servicios externos

---

## 🧪 Testing Local

El flujo completo puede probarse de la siguiente manera:

1. Crear el Stream desde el Backend.
2. Verificar que exista el Subject.
3. Subir archivos al Storage.
4. Publicar un evento.
5. Verificar que el Worker reciba el mensaje.
6. Confirmar que el Job se registre en Base de Datos.
7. Revisar que el ACK sea enviado únicamente después de finalizar el procesamiento.

Todo el flujo puede ejecutarse completamente en entorno local utilizando Docker Compose.
---

## 📦 Persistencia

Los datos persisten en:

- PostgreSQL → `db_data`
- MinIO → `minio_data`

---

## 🧼 Resetear entorno

```bash
docker compose down -v
```

---

## 🧭 Filosofía del Template

Este workspace está diseñado para:

- Ser **mínimo pero escalable**
- Favorecer **desacoplamiento**
- Simular arquitectura real de GCP
- Permitir iteración rápida en local

---

## 🚧 Próximas mejoras

- Health checks
- Observabilidad (logs centralizados)
- Métricas

---

## 💡 Nota Final

Este template **no está acoplado a ningún dominio específico**.

Es una base para construir sistemas donde:

> "Los eventos son la fuente de verdad, y los workers ejecutan la lógica."

---

## 👨‍💻 Autor

HB <3
Template diseñado para acelerar desarrollo backend basado en eventos.
