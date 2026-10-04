-- =========================================================
-- MULUNGUSHI UNIVERSITY
-- COURSE: ICT371 - PostgreSQL Assignment
-- STUDENT NUMBER: 202402226
-- SCENARIO: SCENERIO 4
-- =========================================================


-- Step 1: Create tables and insert sample data
DROP TABLE IF EXISTS dispensing_records CASCADE;
DROP TABLE IF EXISTS medicines CASCADE;

CREATE TABLE medicines (
    medicine_id SERIAL PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL,
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE dispensing_records (
    dispense_id SERIAL PRIMARY KEY,
    medicine_id INT REFERENCES medicines(medicine_id),
    student_number VARCHAR(20) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'DISPENSED'
);

INSERT INTO medicines (medicine_name, stock_quantity) VALUES
('Paracetamol', 100),
('Amoxicillin', 8),
('Ibuprofen', 0);

-- Step 2: IF ELSIF ELSE report on medicine stock
DO $$
DECLARE
    v_stock INT;
    v_name VARCHAR(100) := 'Amoxicillin';
BEGIN
    SELECT stock_quantity INTO v_stock FROM medicines WHERE medicine_name = v_name;

    IF v_stock = 0 THEN
        RAISE NOTICE 'Medicine "%" is out of stock.', v_name;
    ELSIF v_stock < 20 THEN
        RAISE NOTICE 'Medicine "%" is low on stock (Quantity: %).', v_name, v_stock;
    ELSE
        RAISE NOTICE 'Medicine "%" is sufficiently stocked (Quantity: %).', v_name, v_stock;
    END IF;
END $$;

-- Step 3: WHILE loop & numeric FOR loop
DO $$
DECLARE
    i INT := 1;
BEGIN
    WHILE i <= 3 LOOP
        RAISE NOTICE 'Stock Review Day #%', i;
        i := i + 1;
    END LOOP;

    FOR j IN 1..3 LOOP
        RAISE NOTICE 'Clinic Shelf Inspection #%', j;
    END LOOP;
END $$;

-- Step 4: Create dispense_medicine procedure
CREATE OR REPLACE PROCEDURE dispense_medicine(
    p_medicine_id INT,
    p_student_number VARCHAR,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock INT;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Invalid quantity: %. Dispensing quantity must be positive.', p_quantity;
    END IF;

    SELECT stock_quantity INTO v_stock 
    FROM medicines 
    WHERE medicine_id = p_medicine_id 
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE NOTICE 'Medicine ID % not found.', p_medicine_id;
        RETURN;
    END IF;

    IF v_stock >= p_quantity THEN
        UPDATE medicines 
        SET stock_quantity = stock_quantity - p_quantity 
        WHERE medicine_id = p_medicine_id;

        INSERT INTO dispensing_records (medicine_id, student_number, quantity, status)
        VALUES (p_medicine_id, p_student_number, p_quantity, 'DISPENSED');

        RAISE NOTICE 'Dispensed % units of Medicine ID % to Student %.', p_quantity, p_medicine_id, p_student_number;
    ELSE
        RAISE NOTICE 'Dispensing failed: Requested %, but stock is only %.', p_quantity, v_stock;
    END IF;
END;
$$;

-- Step 5: Call dispense_medicine and query
CALL dispense_medicine(1, '20231001', 10);
CALL dispense_medicine(2, '20231002', 5);
CALL dispense_medicine(3, '20231003', 2);

SELECT * FROM medicines;
SELECT * FROM dispensing_records;

-- Step 6: Create reverse_dispensing procedure
CREATE OR REPLACE PROCEDURE reverse_dispensing(
    p_dispense_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_medicine_id INT;
    v_quantity INT;
BEGIN
    SELECT status, medicine_id, quantity INTO v_status, v_medicine_id, v_quantity
    FROM dispensing_records
    WHERE dispense_id = p_dispense_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE NOTICE 'Dispense Record ID % not found.', p_dispense_id;
        RETURN;
    END IF;

    IF v_status = 'REVERSED' THEN
        RAISE NOTICE 'Dispense Record ID % was already reversed. Stock will NOT be added again.', p_dispense_id;
    ELSE
        UPDATE dispensing_records
        SET status = 'REVERSED'
        WHERE dispense_id = p_dispense_id;

        UPDATE medicines
        SET stock_quantity = stock_quantity + v_quantity
        WHERE medicine_id = v_medicine_id;

        RAISE NOTICE 'Dispense Record ID % reversed. Restored % units to stock.', p_dispense_id, v_quantity;
    END IF;
END;
$$;

CALL reverse_dispensing(1);
CALL reverse_dispensing(1); -- Second call check

-- Step 7: Explicit cursor for medicines below low-stock threshold
DO $$
DECLARE
    rec RECORD;
    cur_low_stock CURSOR FOR 
        SELECT medicine_id, medicine_name, stock_quantity 
        FROM medicines 
        WHERE stock_quantity < 15;
BEGIN
    OPEN cur_low_stock;
    LOOP
        FETCH cur_low_stock INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'LOW STOCK MEDICINE -> ID: %, Name: %, Stock Left: %', rec.medicine_id, rec.medicine_name, rec.stock_quantity;
    END LOOP;
    CLOSE cur_low_stock;
END $$;

-- Step 8: Handle negative dispensing quantity with EXCEPTION block
DO $$
BEGIN
    CALL dispense_medicine(1, '20231004', -5);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'CAUGHT EXCEPTION: %', SQLERRM;
END $$;

-- Step 9: Query final state
SELECT * FROM medicines;
SELECT * FROM dispensing_records;