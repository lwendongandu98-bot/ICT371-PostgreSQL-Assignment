-- =========================================================
-- MULUNGUSHI UNIVERSITY
-- COURSE: ICT371 - PostgreSQL Assignment
-- STUDENT NUMBER: 202402226
-- SCENARIO: SCENERIO 3
-- =========================================================


-- Step 1: Create tables and insert sample data
DROP TABLE IF EXISTS allocations CASCADE;
DROP TABLE IF EXISTS hostel_rooms CASCADE;

CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(20) NOT NULL UNIQUE,
    available_beds INT NOT NULL CHECK (available_beds >= 0)
);

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    room_id INT REFERENCES hostel_rooms(room_id),
    status VARCHAR(20) NOT NULL DEFAULT 'ALLOCATED'
);

INSERT INTO hostel_rooms (room_number, available_beds) VALUES
('Room A1', 4),
('Room B2', 1),
('Room C3', 0);

-- Step 2: IF ELSIF ELSE for room status
DO $$
DECLARE
    v_beds INT;
    v_room VARCHAR(20) := 'Room B2';
BEGIN
    SELECT available_beds INTO v_beds FROM hostel_rooms WHERE room_number = v_room;

    IF v_beds = 0 THEN
        RAISE NOTICE 'Room % is full.', v_room;
    ELSIF v_beds = 1 THEN
        RAISE NOTICE 'Room % has one space left.', v_room;
    ELSE
        RAISE NOTICE 'Room % has several spaces left (Spaces: %).', v_room, v_beds;
    END IF;
END $$;

-- Step 3: WHILE loop & numeric FOR loop
DO $$
DECLARE
    i INT := 1;
BEGIN
    WHILE i <= 3 LOOP
        RAISE NOTICE 'Hostel Inspection Day #%', i;
        i := i + 1;
    END LOOP;

    FOR j IN 1..3 LOOP
        RAISE NOTICE 'Room Check #%', j;
    END LOOP;
END $$;

-- Step 4: Create allocate_room procedure
CREATE OR REPLACE PROCEDURE allocate_room(
    p_student_number VARCHAR,
    p_room_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INT;
BEGIN
    IF p_student_number IS NULL OR TRIM(p_student_number) = '' THEN
        RAISE EXCEPTION 'Student number cannot be blank or empty.';
    END IF;

    SELECT available_beds INTO v_available 
    FROM hostel_rooms 
    WHERE room_id = p_room_id 
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE NOTICE 'Room ID % does not exist.', p_room_id;
        RETURN;
    END IF;

    IF v_available > 0 THEN
        UPDATE hostel_rooms 
        SET available_beds = available_beds - 1 
        WHERE room_id = p_room_id;

        INSERT INTO allocations (student_number, room_id, status)
        VALUES (p_student_number, p_room_id, 'ALLOCATED');

        RAISE NOTICE 'Allocated Student % to Room ID %.', p_student_number, p_room_id;
    ELSE
        RAISE NOTICE 'Allocation failed: Room ID % is full.', p_room_id;
    END IF;
END;
$$;

-- Step 5: Call allocate_room and query
CALL allocate_room('20230001', 1);
CALL allocate_room('20230002', 2);
CALL allocate_room('20230003', 3);

SELECT * FROM hostel_rooms;
SELECT * FROM allocations;

-- Step 6: Create check_out procedure
CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_room_id INT;
BEGIN
    SELECT status, room_id INTO v_status, v_room_id
    FROM allocations
    WHERE allocation_id = p_allocation_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE NOTICE 'Allocation ID % not found.', p_allocation_id;
        RETURN;
    END IF;

    IF v_status = 'COMPLETED' THEN
        RAISE NOTICE 'Allocation ID % is already marked COMPLETED. Bed space will NOT be freed again.', p_allocation_id;
    ELSE
        UPDATE allocations
        SET status = 'COMPLETED'
        WHERE allocation_id = p_allocation_id;

        UPDATE hostel_rooms
        SET available_beds = available_beds + 1
        WHERE room_id = v_room_id;

        RAISE NOTICE 'Student checked out successfully for Allocation ID %.', p_allocation_id;
    END IF;
END;
$$;

CALL check_out(1);
CALL check_out(1); -- Second call check

-- Step 7: Explicit cursor for full or nearly full rooms
DO $$
DECLARE
    rec RECORD;
    cur_full_rooms CURSOR FOR 
        SELECT room_id, room_number, available_beds 
        FROM hostel_rooms 
        WHERE available_beds <= 1;
BEGIN
    OPEN cur_full_rooms;
    LOOP
        FETCH cur_full_rooms INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'NEARLY FULL / FULL ROOM -> Room ID: %, Room No: %, Beds Available: %', rec.room_id, rec.room_number, rec.available_beds;
    END LOOP;
    CLOSE cur_full_rooms;
END $$;

-- Step 8: Handle blank student number with EXCEPTION block
DO $$
BEGIN
    CALL allocate_room('   ', 1);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'CAUGHT EXCEPTION: %', SQLERRM;
END $$;

-- Step 9: Query final state
SELECT * FROM hostel_rooms;
SELECT * FROM allocations;