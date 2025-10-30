# Social WiFi user fetcher

Script de ejemplo para consultar la API de Social WiFi y descargar los datos de usuarios de una cuenta utilizando el flujo documentado en [Getting user data](https://developer.socialwifi.com/api/getting-user-data/).

## Requisitos

- `curl`
- `jq`
- Token de API válido (`SOCIALWIFI_TOKEN`)
- Identificador del proyecto (`SOCIALWIFI_PROJECT_ID`)

## Uso

```bash
# Usando variables de entorno
export SOCIALWIFI_TOKEN="tu_token"
export SOCIALWIFI_ACCOUNT_ID="tu_account_uuid"
./fetch_users.sh

# Pasando argumentos y personalizando la consulta
./fetch_users.sh \
  --token "tu_token" \
  --account-id "tu_account_uuid" \
  --venue-id "tu_venue_uuid" \
  --page-size 200 \
  --filter "project=tu_project_uuid" \
  --output usuarios.json
```

El script se basa en el endpoint documentado `GET /api/accounts/{account_uuid}/users/` y agrega los parámetros `limit`, `venue` (por defecto `c713c145-79c7-46f5-ac8d-b4ff8b17d046`) y los filtros opcionales proporcionados. Por defecto se incluye el encabezado `Authorization: Token ...`, tal como indica la guía oficial, pero se puede cambiar el esquema con `--auth-scheme` si tu token requiere `Bearer`.
Durante la ejecución se sigue la paginación leyendo el enlace `next` que devuelve la API hasta que no haya más resultados. El contenido se muestra en JSON o se guarda en un archivo si se usa `--output`.
