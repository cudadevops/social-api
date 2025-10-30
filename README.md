# Social WiFi user fetcher

Script de ejemplo para consultar la API de Social WiFi y descargar los datos de usuarios de un proyecto.

## Requisitos

- `curl`
- `jq`
- Token de API válido (`SOCIALWIFI_TOKEN`)
- Identificador del proyecto (`SOCIALWIFI_PROJECT_ID`)

## Uso

```bash
# Usando variables de entorno
export SOCIALWIFI_TOKEN="tu_token"
export SOCIALWIFI_ACCOUNT_ID="tu_account_id"
./fetch_users.sh

# Pasando argumentos y filtrando resultados
./fetch_users.sh \
  --token "tu_token" \
  --account-id "tu_account_id" \
  --filter "email__icontains=gmail.com" \
  --limit 200 \
  --output usuarios.json
```

El script recorrerá automáticamente todas las páginas devueltas por la API utilizando el endpoint `/accounts/{account_id}/users/` y mostrará los usuarios en formato JSON (o los guardará en un archivo si se indica la opción `--output`). Puedes aprovechar los parámetros de filtrado documentados por Social WiFi (por ejemplo `first_name`, `last_name`, `email__icontains`, `gender`, etc.) pasando la opción `--filter`.
