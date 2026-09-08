# Arquitectura recomendada para operación pública nacional

## Objetivo

GitHub debe usarse para versionar el código, documentar cambios y desplegar el frontend. Para una vigilancia ciudadana con múltiples usuarios y nodos regionales se necesita además un backend compartido.

## Frontend

React + Vite. Puede desplegarse en GitHub Pages, Vercel, Netlify o Cloudflare Pages.

## Backend recomendado

Supabase/PostgreSQL por su base relacional, autenticación, almacenamiento de archivos y Row Level Security.

### Tablas mínimas

- `fichas`
- `reportes`
- `fuentes`
- `replicas`
- `traslados`
- `usuarios`
- `roles_regionales`
- `historial_cambios`

### Roles

- **Público:** consulta fichas publicadas y envía reportes.
- **Curador regional:** revisa reportes de su territorio.
- **Curador nacional:** revisa y publica.
- **Administrador:** gestiona catálogos, permisos y auditoría.

## Seguridad

- Nunca exponer claves administrativas en el frontend.
- Habilitar Row Level Security.
- Separar datos de contacto de las vistas públicas.
- Conservar historial de cambios y correcciones.
- No prometer anonimato técnico mediante el formulario común.
- Usar un canal separado para fuentes sensibles.

## Fases

1. **Repositorio y demo:** código público + GitHub Pages en modo local.
2. **Backend:** Supabase, autenticación y esquema de permisos.
3. **Nodos regionales:** roles por región/departamento y flujo de aprobación.
4. **Automatización de fuentes:** ingestión de fuentes oficiales legalmente reutilizables, manteniendo revisión humana antes de clasificar y publicar.

## Principio operativo

La automatización puede identificar actos, fechas, entidades y documentos; la clasificación jurídica, el sello DOCUMENTADO y la publicación deben permanecer bajo revisión humana.
