# Modelo de consenso y priorización

## Objetivo

La plataforma debe ayudar a identificar prioridades compartidas sin fabricar una apariencia de consenso. La legitimidad depende del método, participación, inclusión, deliberación y amplitud territorial, no solamente del porcentaje final.

## 1. Tipos de resultado

La interfaz utilizará etiquetas descriptivas:

- `aporte_emergente`: existe una idea con participación inicial;
- `apoyo_relevante`: supera el umbral de apoyo definido para avanzar de fase;
- `prioridad_participativa`: supera los criterios de priorización del proceso;
- `prioridad_territorial_amplia`: además presenta respaldo en el número de territorios exigido;
- `consenso_amplio`: cumple todos los umbrales previamente publicados de apoyo, participación, cobertura territorial, deliberación y ausencia de incidencias críticas;
- `decision_formal`: solo cuando una autoridad competente integra el proceso a un mecanismo jurídicamente reconocido con efectos definidos.

No se utilizará `consenso_nacional` sin reglas previas y evidencia suficiente.

## 2. Dimensiones obligatorias

Cada proceso puede definir umbrales distintos, pero debe publicar estas dimensiones:

### Apoyo
Porcentaje o puntuación que obtiene la alternativa según el método de votación.

### Participación
Número absoluto de personas y, cuando exista universo habilitado, tasa de participación.

### Amplitud territorial
Número de departamentos, municipios, regiones o circunscripciones representadas y, si fue definido previamente, porcentaje mínimo de apoyo dentro de cada territorio contado para el umbral.

### Calidad deliberativa
Existencia de periodo de deliberación, argumentos contrapuestos, evidencia, respuesta a objeciones y versiones consolidadas.

### Inclusión
Cobertura de los grupos afectados y reporte de brechas de participación. Los datos sensibles se usan únicamente de forma agregada y cuando exista base jurídica para hacerlo.

### Integridad
Incidencias abiertas, anomalías detectadas, auditorías, disponibilidad del registro y estado de certificación.

## 3. Regla nacional recomendada para pilotos

Para pilotos nacionales no vinculantes, una configuración inicial puede exigir, a modo de regla de proceso y no como constante universal:

- umbral de apoyo explícito;
- participación mínima absoluta;
- presencia de participantes en un número mínimo de departamentos más Bogotá D.C.;
- respaldo territorial mínimo en una fracción de esos territorios;
- deliberación previa cerrada correctamente;
- evaluación técnica publicada;
- cero incidencia crítica de integridad sin resolver.

Los valores numéricos deben ser definidos y publicados antes de cada proceso; la plataforma no los cambia después de conocer los resultados.

## 4. Métodos de priorización

### Aprobación
Cada persona puede apoyar varias propuestas. Útil cuando se busca identificar un conjunto de alternativas aceptables.

### Ranking
Cada persona ordena alternativas. Útil cuando el orden relativo importa.

### 100 puntos
Cada persona distribuye un presupuesto abstracto de puntos. Útil para expresar intensidad relativa de prioridades, pero debe explicarse que no equivale a presupuesto público real.

### Presupuesto participativo
Cada propuesta tiene costo y las selecciones deben respetar un techo presupuestal. Requiere validación de costos antes de abrir la votación.

### Sí/No
Adecuado para una alternativa madura y claramente definida, no para comparar múltiples estrategias complejas.

## 5. Regla de no manipulación por algoritmo

El orden visual de propuestas antes de votar puede alterar el comportamiento. Por ello:

- se documenta el criterio de ordenamiento;
- se permite orden aleatorio cuando sea apropiado;
- no se usa popularidad oculta para favorecer opciones;
- los rankings personalizados no cambian resultados;
- las recomendaciones de IA se identifican como tales.

## 6. Territorialidad sin desigualdad del voto

La plataforma puede exigir amplitud territorial para declarar un consenso sin dar mayor peso a una persona por vivir en un territorio determinado.

Se calculan dos capas:

1. resultado nacional agregado, donde cada persona vale lo mismo;
2. prueba de amplitud territorial, que verifica si la propuesta también supera el umbral territorial previamente fijado.

Esto evita que una concentración masiva en un solo territorio sea presentada como consenso nacional y, al mismo tiempo, evita ponderaciones arbitrarias de ciudadanos.

## 7. Resultado reproducible

Cada cierre debe publicar un paquete verificable con:

- reglas congeladas;
- opciones congeladas;
- método;
- conteos agregados;
- métricas de participación y territorialidad;
- incidencias;
- algoritmo/fórmula de tabulación;
- commit del software;
- hashes de integridad;
- dictamen de auditoría cuando exista.

Un tercero debe poder reproducir el resultado a partir de los datos públicos agregados o del paquete de auditoría autorizado, sin acceder a identidades ni votos secretos individuales.
