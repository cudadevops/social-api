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
export SOCIALWIFI_PROJECT_ID="tu_project_id"
./fetch_users.sh

# Pasando argumentos y personalizando la consulta
./fetch_users.sh \
  --token "tu_token" \
  --project-id "tu_project_id" \
  --page-size 200 \
  --sort -created \
  --filter "filter[last_visit_on][gte]=2023-01-01" \
  --output usuarios.json
```

El script utiliza el endpoint `/users/project-user-data/` con el encabezado `Authorization: Bearer ...` descrito en la documentación y construye la consulta:

```
https://api.socialwifi.com/users/project-user-data/?filter[project]=PROJECT_ID&page[number]=1&page[size]=PAGE_SIZE&sort=-last_visit_on
```

y recorre las páginas incrementando `page[number]` hasta que la API no devuelve más resultados. El contenido se muestra en JSON o se guarda en un archivo si se usa `--output`.
