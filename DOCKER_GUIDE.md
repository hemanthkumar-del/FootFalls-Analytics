# Docker Deployment Guide

## Local Development (Docker Compose)
To start the backend alongside a local MongoDB instance:
```bash
docker-compose up --build
```
The FastAPI backend will be available at `http://localhost:8000`.

## Production Build
The `backend/Dockerfile` is optimized for production. It uses a non-root `appuser` and multi-stage builds.
```bash
docker build -t footfalls-backend:latest ./backend
docker run -p 8000:8000 --env-file ./backend/.env footfalls-backend:latest
```
