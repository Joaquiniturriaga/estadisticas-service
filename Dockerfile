# ── STAGE 1: builder ──────────────────────────────────────────────
# Imagen base liviana de Python 3.12 para construir dependencias
FROM python:3.12-slim AS builder

# Directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiamos solo el archivo de dependencias primero (aprovecha caché de Docker)
COPY requirements.txt .

# Actualizamos pip e instalamos dependencias en /install (no en el sistema)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── STAGE 2: runtime ──────────────────────────────────────────────
# Nueva imagen limpia, sin residuos del build
FROM python:3.12-slim

# Directorio de trabajo en la imagen final
WORKDIR /app

# Creamos usuario sin privilegios (uid 1000) para no correr como root
RUN useradd -m -u 1000 appuser

# Copiamos las dependencias instaladas desde el stage builder
COPY --from=builder /install /usr/local

# Copiamos el código fuente de la aplicación
COPY app ./app

# Damos pertenencia de los archivos al usuario no root
RUN chown -R appuser:appuser /app

# Cambiamos al usuario sin privilegios
USER appuser


EXPOSE 8006

# Comando de arranque con uvicorn (cámbia el puerto según el servicio)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8006"]