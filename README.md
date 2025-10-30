# Social WiFi user fetcher

Script de ejemplo para consultar la API de Social WiFi y descargar los datos de usuarios utilizando el flujo documentado en [Getting user data](https://developer.socialwifi.com/api/getting-user-data/).

## Requisitos

- `curl`
- `jq`
- Token de API válido (`SOCIALWIFI_TOKEN`)
- Identificador del venue (`SOCIALWIFI_VENUE_ID`, opcional si se usa el valor por defecto)

## Uso

```bash
# Usando variables de entorno
export SOCIALWIFI_TOKEN="tu_token"
./fetch_users.sh

# Pasando argumentos y personalizando la consulta
./fetch_users.sh \
  --token "tu_token" \
  --venue-id "tu_venue_uuid" \
  --page-size 200 \
  --sort "-last_visit_on" \
  --filter "filter[project]=tu_project_uuid" \
  --output usuarios.json
```

El script se basa en el endpoint documentado `GET /users/user-data/` y agrega los parámetros `filter[venue]` (por defecto `c713c145-79c7-46f5-ac8d-b4ff8b17d046`), `page[number]`, `page[size]`, `sort` y los filtros opcionales proporcionados (por ejemplo `filter[project]`). Por defecto se incluye el encabezado `Authorization: Bearer ...`, tal como se muestra en la guía oficial, pero se puede cambiar el esquema con `--auth-scheme`.

Durante la ejecución se sigue la paginación leyendo el enlace `links.next` que devuelve la API hasta que no haya más resultados. El contenido se muestra en JSON o se guarda en un archivo si se usa `--output`.
