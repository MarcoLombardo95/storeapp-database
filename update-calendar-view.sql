-- =====================================================
-- Script per aggiornare la view activity_calendar
-- =====================================================

-- Elimina la view esistente
DROP VIEW IF EXISTS activity_calendar CASCADE;

CREATE OR REPLACE VIEW activity_calendar AS
SELECT 
    a.id,
    a.group_id,
    a.name AS title,
    a.description,
    a.start_time,
    a.end_time,
    EXTRACT(ISODOW FROM a.start_date) AS day_of_week,
    a.start_date AS activity_date,
    COALESCE(
        a.event_location_name,
        CASE WHEN a.trip_origin_name IS NOT NULL AND a.trip_destination_name IS NOT NULL
             THEN a.trip_origin_name || ' → ' || a.trip_destination_name
             ELSE a.trip_origin_name
        END
    ) AS location_name,
    COALESCE(a.event_location_latitude,  a.trip_origin_latitude)  AS location_lat,
    COALESCE(a.event_location_longitude, a.trip_origin_longitude) AS location_lng,
    a.is_completed,
    CASE 
        WHEN a.is_completed THEN 'completed'
        WHEN COUNT(CASE WHEN ap.status = 'CONFIRMED' THEN 1 END) > 0 THEN 'confirmed'
        WHEN COUNT(CASE WHEN ap.status = 'DECLINED' THEN 1 END) = COUNT(ap.id) AND COUNT(ap.id) > 0 THEN 'declined'
        ELSE 'pending'
    END AS calendar_status,
    COALESCE(COUNT(CASE WHEN ap.status = 'CONFIRMED' THEN 1 END), 0) AS confirmed_count,
    COALESCE(COUNT(CASE WHEN ap.status = 'MAYBE'     THEN 1 END), 0) AS maybe_count,
    COALESCE(COUNT(CASE WHEN ap.status = 'DECLINED'  THEN 1 END), 0) AS declined_count,
    COALESCE(COUNT(ap.id), 0) AS total_members,
    u.name       AS creator_name,
    u.avatar_url AS creator_avatar
FROM activities a
LEFT JOIN activity_participants ap ON a.id = ap.activity_id
LEFT JOIN users u ON a.created_by = u.id
GROUP BY a.id, a.group_id, a.name, a.description, a.start_time, a.end_time,
         a.start_date, a.is_completed,
         a.event_location_name, a.event_location_latitude, a.event_location_longitude,
         a.trip_origin_name, a.trip_destination_name, a.trip_origin_latitude, a.trip_origin_longitude,
         u.name, u.avatar_url;

-- Verifica
SELECT 'View activity_calendar ricreata con successo!' AS status;
SELECT * FROM activity_calendar LIMIT 5;
