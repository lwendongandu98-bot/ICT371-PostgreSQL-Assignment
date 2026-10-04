-- =========================================================
-- MULUNGUSHI UNIVERSITY
-- COURSE: ICT371 - PostgreSQL Assignment
-- STUDENT NUMBER: 202402226
-- SCENARIO: SCENERIO 1
-- =========================================================

-- Step 1: Create tables and insert sample data
DROP TABLE IF EXISTS book_loans CASCADE;
DROP TABLE IF EXISTS books CASCADE;

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    available_copies INT NOT NULL CHECK (available_copies >= 0)
);

CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    book_id INT REFERENCES books(book_id),
    student_number VARCHAR(20) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    loan_status VARCHAR(20) NOT NULL DEFAULT 'ISSUED'
);

INSERT INTO books (title, available_copies) VALUES
('Database Systems', 5),
('Data Structures', 1),
('Operating Systems', 0);

-- Step 2: Use IF ELSIF ELSE to check book stock status
DO $$
DECLARE
    v_copies INT;
    v_title VARCHAR(100) := 'Database Systems';
BEGIN
    SELECT available_copies INTO v_copies FROM books WHERE title = v_title;
    
    IF v_copies = 0 THEN
        RAISE NOTICE 'Book "%" is unavailable.', v_title;
    ELSIF v_copies < 3 THEN
        RAISE NOTICE 'Book "%" is low on copies (Copies left: %).', v_title, v_copies;
    ELSE
        RAISE NOTICE 'Book "%" is sufficiently stocked (Copies left: %).', v_title, v_copies;
    END IF;
END $$;

-- Step 3: Use WHILE loop for overdue reminders & numeric FOR loop for shelf numbers
DO $$
DECLARE
    i INT := 1;
BEGIN
    WHILE i <= 3 LOOP
        RAISE NOTICE 'Overdue Reminder #%', i;
        i := i + 1;
    END LOOP;

    FOR j IN 1..3 LOOP
        RAISE NOTICE 'Library Shelf Number: %', j;
    END LOOP;
END $$;

-- Step 4: Create borrow_book procedure
CREATE OR REPLACE PROCEDURE borrow_book(
    p_book_id INT,
    p_student_number VARCHAR,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INT;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Invalid quantity: %. Loan quantity must be greater than zero.', p_quantity;
    END IF;

    SELECT available_copies INTO v_available 
    FROM books 
    WHERE book_id = p_book_id 
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE NOTICE 'Book ID % does not exist.', p_book_id;
        RETURN;
    END IF;

    IF v_available >= p_quantity THEN
        UPDATE books 
        SET available_copies = available_copies - p_quantity 
        WHERE book_id = p_book_id;

        INSERT INTO book_loans (book_id, student_number, quantity, loan_status)
        VALUES (p_book_id, p_student_number, p_quantity, 'ISSUED');

        RAISE NOTICE 'Successfully borrowed % copy/copies of Book ID % for Student %.', p_quantity, p_book_id, p_student_number;
    ELSE
        RAISE NOTICE 'Loan failed: Requested % copies, but only % available for Book ID %.', p_quantity, v_available, p_book_id;
    END IF;
END;
$$;

-- Step 5: Call borrow_book for 2 valid loans and 1 exceeding capacity
CALL borrow_book(1, 'STD001', 2);
CALL borrow_book(2, 'STD002', 1);
CALL borrow_book(3, 'STD003', 2);

SELECT * FROM books;
SELECT * FROM book_loans;

-- Step 6: Create return_book procedure
CREATE OR REPLACE PROCEDURE return_book(
    p_loan_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_book_id INT;
    v_quantity INT;
BEGIN
    SELECT loan_status, book_id, quantity INTO v_status, v_book_id, v_quantity
    FROM book_loans
    WHERE loan_id = p_loan_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE NOTICE 'Loan ID % not found.', p_loan_id;
        RETURN;
    END IF;

    IF v_status = 'RETURNED' THEN
        RAISE NOTICE 'Loan ID % was already returned. Copies will NOT be restored again.', p_loan_id;
    ELSE
        UPDATE book_loans
        SET loan_status = 'RETURNED'
        WHERE loan_id = p_loan_id;

        UPDATE books
        SET available_copies = available_copies + v_quantity
        WHERE book_id = v_book_id;

        RAISE NOTICE 'Loan ID % successfully returned. Restored % copy/copies.', p_loan_id, v_quantity;
    END IF;
END;
$$;

CALL return_book(1);
CALL return_book(1); -- Second call does not restore copies again

-- Step 7: Explicit cursor to display books with few copies remaining
DO $$
DECLARE
    rec RECORD;
    cur_low_stock CURSOR FOR 
        SELECT book_id, title, available_copies 
        FROM books 
        WHERE available_copies <= 2;
BEGIN
    OPEN cur_low_stock;
    LOOP
        FETCH cur_low_stock INTO rec;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'LOW STOCK ALERT -> Book ID: %, Title: %, Available: %', rec.book_id, rec.title, rec.available_copies;
    END LOOP;
    CLOSE cur_low_stock;
END $$;

-- Step 8: Try to borrow zero copies and handle with EXCEPTION block
DO $$
BEGIN
    CALL borrow_book(1, 'STD004', 0);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'CAUGHT EXCEPTION: %', SQLERRM;
END $$;

-- Step 9: Query final quantities and loan statuses
SELECT * FROM books;
SELECT * FROM book_loans;