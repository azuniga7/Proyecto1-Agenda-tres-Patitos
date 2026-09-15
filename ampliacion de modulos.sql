-- ============================================
-- SCRIPT DE AMPLIACIÓN
-- Proyecto 1 - Agenda Digital Tres Patitos
-- Módulos: Ubicaciones, Tareas, Disponibilidad
-- Se ejecuta DESPUÉS del script base.sql
-- ============================================

SET search_path TO prototipo, public;

-- ============================================
-- MÓDULO 1: GESTIÓN DE UBICACIONES (RF-08, RF-09, RF-10)
-- ============================================

CREATE TABLE ubicaciones (
    id_ubicacion SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    capacidad INT NOT NULL
);

ALTER TABLE eventos
ADD COLUMN id_ubicacion INT REFERENCES ubicaciones(id_ubicacion);

CREATE VIEW vista_ranking_ubicaciones AS
SELECT
    u.id_ubicacion, u.nombre, u.ciudad,
    COUNT(e.id_evento) AS total_eventos
FROM ubicaciones u
LEFT JOIN eventos e ON e.id_ubicacion = u.id_ubicacion
GROUP BY u.id_ubicacion, u.nombre, u.ciudad
ORDER BY total_eventos DESC;

CREATE VIEW vista_traslapes_ubicaciones AS
SELECT
    e1.id_ubicacion,
    ub.nombre AS ubicacion,
    e1.id_evento AS evento_1,
    e2.id_evento AS evento_2,
    e1.titulo AS titulo_1,
    e2.titulo AS titulo_2,
    e1.fecha_inicio AS inicio_1,
    e1.fecha_fin AS fin_1,
    e2.fecha_inicio AS inicio_2,
    e2.fecha_fin AS fin_2
FROM eventos e1
JOIN eventos e2
    ON e1.id_ubicacion = e2.id_ubicacion
    AND e1.id_evento < e2.id_evento
    AND e1.fecha_inicio < e2.fecha_fin
    AND e2.fecha_inicio < e1.fecha_fin
JOIN ubicaciones ub ON ub.id_ubicacion = e1.id_ubicacion
WHERE e1.id_ubicacion IS NOT NULL;

-- ============================================
-- MÓDULO 2: TAREAS ASOCIADAS A EVENTOS (RF-15, RF-16, RF-17)
-- ============================================

CREATE TABLE tareas (
    id_tarea SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255),
    prioridad VARCHAR(20) NOT NULL,
    fecha_limite DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente'
        CHECK (estado IN ('Pendiente', 'En progreso', 'Completada', 'Cancelada')),
    id_evento INT NOT NULL REFERENCES eventos(id_evento),
    id_usuario_responsable INT NOT NULL REFERENCES usuarios(id_usuario)
);

CREATE VIEW vista_carga_trabajo_usuarios AS
SELECT
    u.id_usuario, u.nombre, u.apellido,
    COUNT(*) FILTER (WHERE t.estado IN ('Pendiente', 'En progreso')) AS tareas_pendientes,
    COUNT(*) FILTER (WHERE t.estado IN ('Pendiente', 'En progreso') AND t.fecha_limite < CURRENT_DATE) AS tareas_vencidas
FROM usuarios u
JOIN tareas t ON t.id_usuario_responsable = u.id_usuario
GROUP BY u.id_usuario, u.nombre, u.apellido;

CREATE VIEW vista_reporte_tareas_activas AS
SELECT
    t.id_tarea, u.nombre, u.apellido, t.titulo, t.estado, t.fecha_limite,
    (t.fecha_limite < CURRENT_DATE) AS esta_vencida
FROM tareas t
JOIN usuarios u ON u.id_usuario = t.id_usuario_responsable
WHERE t.estado IN ('Pendiente', 'En progreso');

-- ============================================
-- MÓDULO 3: DISPONIBILIDAD DE USUARIOS Y GESTIÓN DE TIEMPOS (RF-11, RF-12)
-- ============================================

CREATE TABLE tipos_disponibilidad (
    id_tipo SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

INSERT INTO tipos_disponibilidad (nombre) VALUES
('Disponible'), ('Ocupado'), ('No disponible');

CREATE TABLE disponibilidades (
    id_disponibilidad SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    id_usuario INT NOT NULL REFERENCES usuarios(id_usuario),
    id_tipo INT NOT NULL REFERENCES tipos_disponibilidad(id_tipo),
    CONSTRAINT check_horas_disp CHECK (hora_fin > hora_inicio)
);

CREATE VIEW vista_traslapes_disponibilidad AS
SELECT
    d1.id_usuario, d1.id_disponibilidad AS disponibilidad_1, d2.id_disponibilidad AS disponibilidad_2,
    d1.fecha, d1.hora_inicio AS inicio_1, d1.hora_fin AS fin_1,
    d2.hora_inicio AS inicio_2, d2.hora_fin AS fin_2
FROM disponibilidades d1
JOIN disponibilidades d2
    ON d1.id_usuario = d2.id_usuario
    AND d1.fecha = d2.fecha
    AND d1.id_disponibilidad < d2.id_disponibilidad
    AND d1.hora_inicio < d2.hora_fin
    AND d2.hora_inicio < d1.hora_fin;