# Observatorio Ciudadano de Legalidad y Transparencia

Versión 2.0 — plataforma ciudadana para vigilancia de actuaciones institucionales en Colombia con cobertura **nacional, departamental, distrital, municipal y regional/supraterritorial**.

El sistema conserva la metodología original: una actuación concreta se contrasta con una norma citada, se verifica con fuente primaria, se garantiza réplica y solo después se publica. También registra actuaciones conformes a derecho.

## Funciones

- Tablero nacional y territorial.
- Registro filtrable por ámbito, región y departamento.
- Formulario ciudadano con ubicación territorial.
- Curaduría humana antes de publicar.
- Clasificación: defecto jurídico, riesgo de integridad o conforme a derecho.
- Sellos: documentado, en verificación y sin verificar.
- Derecho de réplica y registro de traslado/radicado.
- Boletín semanal país, nacional o territorial.

## Desarrollo

```bash
npm install
npm run dev
```

## Producción

```bash
npm run build
```

El repositorio incluye un workflow para GitHub Pages. En **Settings → Pages → Build and deployment**, seleccione **GitHub Actions**.

## Advertencia de infraestructura

La demo usa `localStorage`; por tanto, los datos quedan en cada navegador y no constituyen una base compartida. Antes de abrir el sistema a reportes reales de todo el país debe conectarse un backend con autenticación, roles territoriales, auditoría y protección de datos. Véase `docs/arquitectura-produccion.md`.
