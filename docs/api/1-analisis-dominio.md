# Análisis del Dominio — Sistema de Reservas de Recursos

**Autor:** Nazar Omelianenko  
**Proyecto:** UD5 / UT7 — Diseño de API REST  
**SGBD:** MariaDB

---

## 1. Tablas de la base de datos que participan en el CRUD de reservas

La funcionalidad central de la API es gestionar reservas de recursos (salas, pistas, equipamiento). Para ello se necesitan tres tablas:

**RESERVA** (tabla principal)  
Contiene todos los datos de cada reserva: qué recurso se reserva, qué usuario la hace, en qué fecha y franja horaria, cuántas plazas ocupa y por qué motivo.

**RECURSO** (tabla relacionada por FK)  
Necesaria para validar que el recurso existe, conocer su capacidad máxima y obtener su nombre para incluirlo en las respuestas de la API sin que el cliente tenga que hacer una segunda petición.

**USUARIONORMAL** (tabla relacionada por FK)  
El campo `id_usuario` de RESERVA referencia a esta tabla. En una API con autenticación JWT, el `id_usuario` se extrae del token en el backend y nunca lo envía el cliente directamente.

Las tablas ADMINISTRADOR, HORARIO y DISPONIBLEEN no participan directamente en el CRUD de reservas: HORARIO y DISPONIBLEEN describen la disponibilidad general de cada recurso, pero la reserva concreta registra su propia franja horaria con `hora_inicio` y `hora_fin`.

---

## 2. Campos de la entidad RESERVA y su exposición en la API

| Campo | Tipo en BBDD | ¿Se expone en la API? | Razón |
|---|---|---|---|
| id_recurso | INT (FK, parte de PK) | Sí — en request y response | Identifica qué recurso se reserva |
| id_reserva_local | INT (parte de PK) | Sí — solo en response y en ruta | Identifica la reserva dentro de un recurso; lo genera la BBDD |
| id_usuario | INT (FK) | No en request / Sí en response | Lo extrae el backend del token JWT |
| fecha | DATE | Sí | Día de la reserva |
| hora_inicio | TIME | Sí | Inicio de la franja |
| hora_fin | TIME | Sí | Fin de la franja |
| coste | DECIMAL(10,2) | No en request / Sí en response | Lo calcula el backend según duración y tarifa del recurso |
| numero_plazas | INT | Sí | El cliente indica cuántas plazas necesita |
| motivo | VARCHAR(20) | Sí | Descripción breve del uso |
| observaciones | VARCHAR(20) | Sí, opcional | Información adicional opcional |

**Campos auto-generados por el backend:**

- `id_reserva_local`: autoincremental gestionado por la BBDD dentro de cada recurso.
- `id_usuario`: extraído del JWT; el cliente nunca lo envía.
- `coste`: calculado por la lógica de negocio a partir de la duración y las tarifas del recurso.

**Campo adicional enriquecido en las respuestas (JOIN):**

En las respuestas GET y POST incluiré `recurso_nombre`, obtenido con un JOIN sobre la tabla RECURSO. Así el cliente recibe "Sala de Reuniones A" en lugar de solo `id_recurso: 1`.

---

## 3. Validaciones y reglas de negocio

**Campos obligatorios en el request (POST / PATCH):**

- `id_recurso`, `fecha`, `hora_inicio`, `hora_fin`, `numero_plazas`

**Restricciones de valores:**

- `hora_inicio` debe ser anterior a `hora_fin`
- `fecha` debe ser igual o posterior a la fecha actual (no se permiten reservas en el pasado)
- `numero_plazas` debe ser mayor o igual a 1
- `numero_plazas` no puede superar la `capacidad` del recurso
- `motivo` tiene longitud máxima de 20 caracteres
- `observaciones` tiene longitud máxima de 20 caracteres

**Reglas de negocio específicas del dominio:**

- No puede existir solapamiento de horarios para el mismo recurso en la misma fecha: si el recurso 1 ya tiene una reserva de 08:00 a 10:00 el día 2025-03-10, no se puede crear otra reserva que se solape en ese mismo recurso y día.
- Un RECURSO o USUARIONORMAL con reservas asociadas no puede eliminarse directamente (ON DELETE RESTRICT en la BBDD); la API devolverá un error 409 Conflict en ese caso.

---

## 4. Ruta principal de la API

```
GET    /reservas              → Lista de reservas del usuario autenticado
POST   /reservas              → Crear una nueva reserva
GET    /reservas/{id}         → Detalle de una reserva por id_reserva_local
PATCH  /reservas/{id}         → Modificar una reserva existente
DELETE /reservas/{id}         → Eliminar una reserva
```

El parámetro `{id}` corresponde a `id_reserva_local`. Aunque en la BBDD la PK es compuesta (`id_recurso` + `id_reserva_local`), a nivel de API se usa `id_reserva_local` como identificador de ruta, ya que resulta más limpio y coherente con los principios REST. El `id_recurso` se incluye en el body cuando es necesario.
