-- =========================================================
-- MULUNGUSHI UNIVERSITY
-- COURSE: ICT371 - PostgreSQL Assignment
-- STUDENT NUMBER: 202402226
-- SCENARIO: SCENERIO 2
-- =========================================================



-- Step 1: Create tables and insert sample data
DROP TABLE IF EXISTS reservations CASCADE;
DROP TABLE IF EXISTS lab_sessions CASCADE;

CREATE TABLE lab_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(100) NOT NULL,
    available_workstations INT NOT NULL CHECK (available_workstations >= 0)
);

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    session_id INT REFERENCES lab_sessions(session_id),
    lecturer VARCHAR(100) NOT NULL,
    num_workstations INT NOT NULL CHECK (num_workstations > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'RESERVED'
);

INSERT INTO lab_sessions (session_name, available_workstations) VALUES
('Networking Lab', 30),
('Cyber Security Lab', 5),
('AI Lab', 0);

-- Step 2: IF ELSIF ELSE report on session status
DO $$
DECLARE
    v_workstations INT;
    v_session VARCHAR(100) := 'Networking Lab';
BEGIN
    SELECT available_workstations INTO v_workstations FROM lab_sessions WHERE session_name = v_session;

    IF v_workstations = 0 THEN
        RAISE NOTICE 'Session "%" is full.', v_session;
    ELSIF v_workstations < 10 THEN
        RAISE NOTICE 'Session "%" is nearly full (% workstations left).', v_session, v_workstations;
    ELSE
        RAISE NOTICE 'Session "%" has enough workstations (% workstations left).', v_session, v_workstations;
    END IF;
END $$;

-- Step 3: WHILE loop & numeric FOR loop
DO $$
DECLARE
    i INT := 1;
BEGIN
    WHILE i <= 3 LOOP
        RAISE NOTICE 'Session Preparation Reminder #%', i;
        i := i + 1;
    END LOOP;

    FOR j IN 1..3 LOOP
        RAISE NOTICE 'Workstation Check #%', j;
    END LOOP;
END $$;

-- Step 4: Create reserve_workstations procedure
CREATE OR REPLACE PROCEDURE reserve_workstations(
    p_session_id INT,
    p_lecturer VARCHAR,
    p_num_workstations INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INT;
BEGIN
    IF p_num_workstations <= 0 THEN
        RAISE EXCEPTION 'Invalid quantity: %. Must request at least 1 workstation.', p_num_workstations;
    END IF;

    SELECT available_workstations INTO v_available 
    FROM lab_sessions 
    WHERE session_id = p_session_id 
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE NOTICE 'Session ID % not found.', p_session_id;
        RETURN;
    END IF;

    IF v_available >= p_num_workstations THEN
        UPDATE lab_sessions 
        SET available_workstations = available_workstations - p_num_workstations 
        WHERE session_id = p_session_id;

        INSERT INTO reservations (session_id, lecturer, num_workstations, status)
        VALUES (p_session_id, p_lecturer, p_num_workstations, 'RESERVED');

        RAISE NOTICE 'Reserved % workstation(s) for Lecturer %.', p_num_workstations, p_lecturer;
    ELSE
        RAISE NOTICE 'Reservation failed: Requested %, but only % available.', p_num_workstations, v_available;
    END IF;
END;
$$;

-- Step 5: Call reserve_workstations and query
CALL reserve_workstations(1, 'Dr. Banda', 10);
CALL reserve_workstations(2, 'Prof. Phiri', 3);
CALL reserve_workstations(3, 'Dr. Mulenga', 5);

SELECT * FROM lab_sessions;
SELECT * FROM reservations;

-- Step 6: Create cancel_reservation procedure
CREATE OR REPLACE PROCEDURE cancel_reservation(
    p_reservation_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_session_id INT;
    v_num INT;
BEGIN
    SELECT status, session_id, num_workstations INTO v_status, v_session_id, v_num
    FROM reservations
    WHERE reservation_id = p_reservation_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE NOTICE 'Reservation ID % not found.', p_reservation_id;
        RETURN;
    END IF;

    IF v_status = 'CANCELLED' THEN
        RAISE NOTICE 'Reservation ID % is already cancelled. Workstations will NOT be released again.', p_reservation_id;
    ELSE
        UPDATE reservations
        SET status = 'CANCELLED'
        WHERE reservation_id = p_reservation_id;

        UPDATE lab_sessions
        SET available_workstations = available_workstations + v_num
        WHERE session_id = v_session_id;

        RAISE NOTICE 'Reservation ID % cancelled. Released % workstations.', p_reservation_id, v_num;
    END IF;
END;
$$;

CALL cancel_reservation(1);
CALL cancel_reservation(1); -- Second call check

-- Step 7: Explicit cursor for sessions with few workstations
DO $$
DECLARE
    rec RECORD;
    cur_low_capacity CURSOR FOR 
        SELECT session_id, session_name, available_workstations 
        FROM lab_sessions 
        WHERE available_workstations <= 5;
BEGIN
    OPEN cur_low_capacity;
    LOOP
        FETCH cur_low_capacity INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'LIMITED CAPACITY -> Session ID: %, Name: %, Available: %', rec.session_id, rec.session_name, rec.available_workstations;
    END LOOP;
    CLOSE cur_low_capacity;
END $$;

-- Step 8: Handle zero request with EXCEPTION block
DO $$
BEGIN
    CALL reserve_workstations(1, 'Dr. Tembo', 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'CAUGHT EXCEPTION: %', SQLERRM;
END $$;

-- Step 9: Query final state
SELECT * FROM lab_sessions;
SELECT * FROM reservations;