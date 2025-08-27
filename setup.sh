docker exec -t sxpr_db pg_dumpall -U postgres > backup.sql


# from the project root
docker compose up -d db
# watch health until healthy
docker compose ps

# restore everything from backup.sql into the running db container
cat backup.sql | docker exec -i sxpr_db psql -U postgres

docker compose up -d --build

# DB reachable?
docker exec -it sxpr_db psql -U postgres -c "\l"

# API health?
curl -sf http://localhost:8000/health && echo "API OK"

# Frontend reachable? (open in browser)
# http://localhost:8081
# Then try: http://localhost:8081/api/lessons  (proxied to FastAPI)