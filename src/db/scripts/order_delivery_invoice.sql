--Query 1 
-- Views the summarized delivery history for each order
CREATE OR REPLACE VIEW vw_order_overview AS
SELECT
    o.id AS order_id,
    m.username AS cust_name,
    TO_CHAR(o.ordered_at, 'DD-MON-YYYY') AS order_date,
    TO_CHAR(o.ordered_at, ' HH:MI AM') AS order_time,
    CASE
        WHEN i.id IS NOT NULL THEN 'PAID'
        ELSE 'UNPAID'
        END AS status,
    COALESCE(i.amount, 0) AS revenue,
    CASE
        WHEN o.order_type = 2 THEN 'Self-Pickup'
        WHEN o.order_type = 1 THEN 'Delivery'
        ELSE 'Pending Dispatch'
        END AS order_type
FROM orders o
         INNER JOIN member m ON o.member_id = m.id      
         LEFT JOIN invoice i ON o.id = i.order_id;
-- SET LINESIZE 120
-- SET PAGESIZE 120
--     COLUMN order_time FORMAT A12;
-- COLUMN status FORMAT A8;
-- COLUMN order_type FORMAT A15;
-- COLUMN revenue FORMAT 999,990.00;
SELECT * FROM vw_order_overview
WHERE cust_name = 'ocox6';


--Query 2
--View the summary for all orders,combining the order, restaurant, invoice and dispatch method
CREATE OR REPLACE VIEW vw_city_order AS
SELECT
    a.city,
    a.state,
    COUNT(DISTINCT o.id) AS total_orders,
    COALESCE(SUM(i.amount), 0) AS total_revenue,
    ROUND(COALESCE(SUM(i.amount), 0) / COUNT(DISTINCT o.id), 2) AS avg_order_value
FROM orders o
         JOIN (
    SELECT member_id, address_id,
           ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY address_id) as rn
    FROM member_address
) ma ON o.member_id = ma.member_id AND ma.rn = 1
         JOIN address a ON ma.address_id = a.id
         LEFT JOIN invoice i ON o.id = i.order_id
WHERE a.state IS NOT NULL
GROUP BY a.state, a.city;

-- SET LINESIZE 120;
-- SET PAGESIZE 120;
-- COLUMN state FORMAT A10;
-- COLUMN city FORMAT A30;
-- COLUMN total_orders FORMAT 99,999 HEADING 'TOTAL ORDERS';
-- COLUMN total_revenue FORMAT 999,990.00 HEADING 'TOTAL REVENUE (RM)';
-- COLUMN avg_order_value FORMAT 999,990.00 HEADING 'AVG ORDER VALUE (RM)';
SELECT * FROM vw_city_order WHERE UPPER(TRIM(state)) = 'WA'
ORDER BY city ASC;



--PROCEDURE 1
--To create order and generate receipt
CREATE OR REPLACE PROCEDURE proc_finalize_payment (
    p_order_id            IN orders.id%TYPE,
    p_payment_method_id   IN payment.payment_method_id%TYPE,
    p_amount              IN payment.amount%TYPE,
    p_description         IN VARCHAR2 
) AS
    v_payment_id    payment.id%TYPE;
    v_ref_no        payment.ref_no%TYPE;
    v_current_time  TIMESTAMP := CURRENT_TIMESTAMP;
    v_order_type    orders.order_type%TYPE;
    v_restaurant_id orders.restaurant_id%TYPE;
    v_rest_name     restaurant.name%TYPE;
    v_item_count    INT;
    v_item_subtotal NUMBER;

BEGIN
    SELECT COUNT(*) INTO v_item_count
    FROM order_item
    WHERE order_id = p_order_id;

    IF v_item_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20402, 'Cannot process payment. Order ' || p_order_id || ' contains no items.');
    END IF;
    
    SELECT o.order_type, o.restaurant_id, r.name
    INTO v_order_type, v_restaurant_id, v_rest_name
    FROM orders o
             JOIN restaurant r ON o.restaurant_id = r.id
    WHERE o.id = p_order_id;
    
    INSERT INTO payment (payment_method_id, paid_at, amount, payment_method_data) VALUES (
                 p_payment_method_id,
                 v_current_time,
                 p_amount,
                 JSON_OBJECT('description' VALUE p_description)
             )
    RETURNING id, ref_no INTO v_payment_id, v_ref_no;

    INSERT INTO invoice (order_id,payment_id,invoiced_at,amount) VALUES (
                 p_order_id,
                 v_payment_id,
                 v_current_time,
                 p_amount
             );

    -- Receipt Display
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('           SHOPGRAB OFFICIAL              ');
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('ORDER ID    : ' || p_order_id);
    DBMS_OUTPUT.PUT_LINE('INVOICE NO  : ' || v_payment_id);
    DBMS_OUTPUT.PUT_LINE('DATE/TIME   : ' || TO_CHAR(v_current_time, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('RESTAURANT  : ' || v_rest_name);
    DBMS_OUTPUT.PUT_LINE('ORDER TYPE  : ' || v_order_type);
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('ITEMS', 30) || 'SUBTOTAL');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');

    --Loop through and display all order items inside this order
    FOR item IN (
        SELECT p.name, oi.quantity, oi.unit_price
        FROM order_item oi
                 JOIN product p ON oi.product_id = p.id
        WHERE oi.order_id = p_order_id
        ) LOOP
            v_item_subtotal := item.quantity * item.unit_price;
            DBMS_OUTPUT.PUT_LINE(
                    RPAD(item.quantity || 'x ' || SUBSTR(item.name, 1, 25), 30) ||
                    'RM ' || LPAD(TO_CHAR(v_item_subtotal, 'FM990.00'), 8)
            );
        END LOOP;
    -- Display the payment reference and amount
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('PAYMENT REF:', 20) || v_ref_no);
    DBMS_OUTPUT.PUT_LINE(RPAD('TOTAL PAID :', 20) || 'RM ' || TO_CHAR(p_amount, 'FM999,990.00'));
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('       TRANSACTION SUCCESSFUL             ');

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Order ID ' || p_order_id || ' not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Process failed. ' || SQLERRM);
END;
/


-- PROCEDURE 1 TEST CASE                 
DECLARE
    -- We only need a variable to catch the new order ID
    v_test_order_id orders.id%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TEST 1: SUCCESSFUL PAYMENT ---');

    -- 1. Create a quick dummy order
    INSERT INTO orders (member_id, order_type, restaurant_id, ordered_at)
    VALUES (2, 1, 1, CURRENT_TIMESTAMP)
    RETURNING id INTO v_test_order_id;

    -- 2. Add an item (e.g., 2x Product #4 at RM 25.00)
    INSERT INTO order_item (order_id, product_id, quantity, unit_price)
    VALUES (v_test_order_id, 4, 2, 25.00);

    -- 3. Call your procedure
    -- Passing the new Order ID, Payment Method 2 (Card), and RM 50.00 Total
    proc_finalize_payment(
            p_order_id          => v_test_order_id,
            p_payment_method_id => 2,
            p_amount            => 50.00,
            p_description       => 'Test Case 1 - Standard Payment'
    );
END;
/

    
    


--PROCEDURE 2
--To create orders in delivery table
CREATE OR REPLACE PROCEDURE proc_dispatch_order (
    p_order_id            IN orders.id%TYPE,
    p_address_id          IN delivery.address_id%TYPE,
    p_vendor_id           IN delivery.vendor_id%TYPE
) AS
    v_order_type          orders.order_type%TYPE;
    v_delivery_id         delivery.id%TYPE;
    v_invoice_exists      NUMBER;
    v_dispatch_time       TIMESTAMP := CURRENT_TIMESTAMP;
    v_estimated_arrive_at TIMESTAMP := v_dispatch_time + INTERVAL '45' MINUTE;
    v_already_dispatched  NUMBER;
BEGIN
    --Check whether the Order exists
    BEGIN
        SELECT order_type INTO v_order_type
        FROM orders
        WHERE id = p_order_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Order ID ' || p_order_id || ' not found.');
    END;

    IF v_order_type != 1 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cannot dispatch: This is a PICKUP order.');
    END IF;
    
    SELECT COUNT(*) INTO v_invoice_exists
    FROM invoice
    WHERE order_id = p_order_id;

    IF v_invoice_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cannot dispatch: Order ' || p_order_id || ' has not been invoiced/paid.');
    END IF;

    SELECT COUNT(*) INTO v_already_dispatched
    FROM delivery
    WHERE order_id = p_order_id;

    IF v_already_dispatched > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Order ' || p_order_id || ' has already been dispatched.');
    END IF;

    INSERT INTO delivery (order_id,address_id,vendor_id,ordered_at,estimated_arrive_at) VALUES (
                 p_order_id,
                 p_address_id,
                 p_vendor_id,
                 v_dispatch_time,
                 v_estimated_arrive_at
             )
    RETURNING id INTO v_delivery_id;

    COMMIT;
    --Display successful dispatch message
    DBMS_OUTPUT.PUT_LINE('DISPATCH SUCCESSFUL - Invoice Verified');
    DBMS_OUTPUT.PUT_LINE('Delivery ID : ' || v_delivery_id);
    DBMS_OUTPUT.PUT_LINE('Order ID    : ' || p_order_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

--PROCEDURE 2 TESTING
-- 1. Create the Order record
DECLARE
    v_order_id   orders.id%TYPE;
    v_payment_id payment.id%TYPE;
BEGIN
    -- 1. Create the Order and capture the ID
    INSERT INTO orders (member_id, order_type, restaurant_id, ordered_at)
    VALUES (2, 1, 1, CURRENT_TIMESTAMP)
    RETURNING id INTO v_order_id;

    -- 2. Add Items to the Order using the variable
    -- 2x Classic Cheeseburger
    -- Crispy Chicken Burger
    INSERT INTO order_item (order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, 4, 2, 25.00);

    -- 1x Crispy Chicken Burger
    INSERT INTO order_item (order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, 5, 1, 15.00);

    -- 3. Create Payment (Using Method 2 - Card)
    -- Total amount: (2 * 25) + 15 = 65.00
    INSERT INTO payment (payment_method_id, amount, payment_method_data)
    VALUES (2, 65.00, '{"description": "Test Case Dispatch"}')
    RETURNING id INTO v_payment_id;

    -- 4. Create Invoice 
    INSERT INTO invoice (order_id, payment_id, amount)
    VALUES (v_order_id, v_payment_id, 65.00);

    -- 5. Execute the Dispatch Procedure
    -- Parameters: New Order ID, Address ID (1), Vendor ID (1 - Grab)

    BEGIN
        proc_dispatch_order(
                p_order_id   => v_order_id,
                p_address_id => 1,
                p_vendor_id  => 1
        );
    end;
    
    COMMIT;


END;
/

CREATE OR REPLACE PROCEDURE calculate_order_total (
    p_order_id IN INT,
    p_total_price OUT DECIMAL
) AS
    v_item_total       DECIMAL(10, 2) := 0;
    v_feature_total    DECIMAL(10, 2) := 0;
    v_item_adj_total   DECIMAL(10, 2) := 0;
    v_order_adj_total  DECIMAL(10, 2) := 0;
BEGIN
    --Calculate Base Items(unit_price * quantity)
    SELECT NVL(SUM(unit_price * quantity), 0)
    INTO v_item_total
    FROM order_item
    WHERE order_id = p_order_id;

    --Calculate Product Features(unit_price * quantity) 
    SELECT NVL(SUM(oif.unit_price * oif.quantity), 0)
    INTO v_feature_total
    FROM order_item_feature oif
             JOIN order_item oi ON oif.order_item_id = oi.id
    WHERE oi.order_id = p_order_id;

    -- Calculate Item-Level Adjustments
    SELECT NVL(SUM(
       CASE
           WHEN adjustment_type = 1 THEN 
               -(COALESCE(amount, (SELECT (unit_price * quantity) FROM order_item WHERE id = order_item_id) * percentage))
           ELSE
               COALESCE(amount, (SELECT (unit_price * quantity) FROM order_item WHERE id = order_item_id) * percentage)
           END
               ), 0)
    INTO v_item_adj_total
    FROM order_item_adjustment
    WHERE order_id = p_order_id
      AND order_item_id IS NOT NULL;

    --Calculate Order-Level Adjustments
    SELECT NVL(SUM(
       CASE
           WHEN adjustment_type = 1 THEN
               -(COALESCE(amount, (v_item_total + v_feature_total) * percentage))
           ELSE
               COALESCE(amount, (v_item_total + v_feature_total) * percentage)
           END
               ), 0)
    INTO v_order_adj_total
    FROM order_item_adjustment
    WHERE order_id = p_order_id
      AND order_item_id IS NULL;

    -- Final Summation
    p_total_price := v_item_total + v_feature_total + v_item_adj_total + v_order_adj_total;
    DBMS_OUTPUT.PUT_LINE('Total amount for Order ID ' || p_order_id || ' is RM' || p_total_price);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error calculating total for Order ID: ' || p_order_id);
        RAISE;
END;
/

SELECT id
FROM orders
ORDER BY id DESC
    FETCH FIRST 1 ROW ONLY;


-- PROCEDURE 3 TEST
DECLARE
    v_order_id     orders.id%TYPE;
    v_item_1_id    order_item.id%TYPE;
    v_item_2_id    order_item.id%TYPE;
    v_calculated   DECIMAL(10,2);
BEGIN

    -- 1. Create the Order
    INSERT INTO orders (member_id, order_type, restaurant_id, ordered_at)
    VALUES (2, 1, 1, CURRENT_TIMESTAMP)
    RETURNING id INTO v_order_id;

    -- 2. Add Items to the Order and get order_item id
    -- Item 1: 2x Classic Cheeseburger @ RM 25.00 = RM 50.00
    INSERT INTO order_item (order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, 4, 2, 25.00)
    RETURNING id INTO v_item_1_id;

    -- Item 2: 1x Crispy Chicken Burger @ RM 15.00 = RM 15.00
    INSERT INTO order_item (order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, 5, 1, 15.00)
    RETURNING id INTO v_item_2_id;

    -- Math Checkpoint: Base Order Total is RM 65.00

    -- 3. Apply an Item-Level Adjustment
    -- 10% Discount on the Classic Cheeseburgers (Applies ONLY to v_item_1_id)
    -- Calculation: 10% of RM 50.00 = -RM 5.00
    INSERT INTO order_item_adjustment (order_id, order_item_id, adjustment_type, percentage)
    VALUES (v_order_id, v_item_1_id, 1, 0.1000);

    -- Adjusted Total is RM 60.00

    -- 4. Apply an Order-Level Adjustment
    -- RM 5.00 Delivery Fee 
    -- Calculation: +RM 5.00
    INSERT INTO order_item_adjustment (order_id, adjustment_type, amount)
    VALUES (v_order_id, 5, 5.00);

    -- Final Math Checkpoint: Expected Total is RM 65.00 (60.00 + 5.00)

    -- 5. Execute the Calculation
    calculate_order_total(
            p_order_id    => v_order_id,
            p_total_price => v_calculated
    );

    proc_finalize_payment(
            p_order_id          => v_order_id,
            p_payment_method_id => 2,
            p_amount            => v_calculated,
            p_description       => 'Order Paid with Card Payments'
    );
    
END;
/
SELECT id
FROM orders
ORDER BY id DESC
    FETCH FIRST 1 ROW ONLY;


--TRIGGER 1
--Lock Orders once placed
CREATE OR REPLACE TRIGGER trg_order_item_lock
    BEFORE INSERT OR UPDATE OR DELETE ON order_item
    FOR EACH ROW
DECLARE
    v_is_paid NUMBER;
    v_order_id orders.id%TYPE;
BEGIN
    --Determine which Order ID to check (handle delete via :OLD)
   IF DELETING THEN
       v_order_id := :OLD.order_id;
   ELSE
       v_order_id := :NEW.order_id;
   end if;

    --Check if an invoice exists for this order
    SELECT COUNT(*) INTO v_is_paid
    FROM invoice
    WHERE order_id = v_order_id;

    IF v_is_paid > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Order #' || v_order_id || ' is already invoiced and cannot be modified.');
    END IF;
END;
/
-- --Test trigger 1
UPDATE order_item
SET quantity = 5
WHERE id = 343;


--TRIGGER 2
--Each order can have order_items from the same restaurant
CREATE OR REPLACE TRIGGER trg_order_item_shop
    BEFORE INSERT OR UPDATE ON order_item
    FOR EACH ROW
DECLARE
    v_order_restaurant_id orders.restaurant_id%TYPE;
    v_item_is_valid       NUMBER;
    v_product_name        product.NAME%type;
BEGIN
    SELECT restaurant_id INTO v_order_restaurant_id
    FROM orders
    WHERE id = :NEW.order_id;
    
    SELECT name INTO v_product_name
    FROM product
    WHERE id = :NEW.product_id;

    SELECT COUNT(*) INTO v_item_is_valid
    FROM menu_item
    WHERE product_id = :NEW.product_id
      AND restaurant_id = v_order_restaurant_id;

    --If no match is found, block the transaction
    IF v_item_is_valid = 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
                                'Order Item' || v_product_name || ' is not on the menu for the selected restaurant.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Order ID or Product ID does not exist.');
END;
/


-- Test trigger 2
UPDATE order_item
SET product_id = 1
WHERE order_id = 2 AND product_id = 4;


-- REPORT 1
-- Vendors performance summary report by comparing each vendor 
-- by their total orders and revenue made in that year
CREATE OR REPLACE PROCEDURE proc_vendors_report (p_year IN NUMBER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE))AS

    v_order_count      NUMBER;
    v_total_revenue    NUMBER;
    v_top_vol_name     delivery_vendor.name%TYPE := 'N/A';
    v_top_vol_count    NUMBER := -1;
    v_top_rev_name     delivery_vendor.name%TYPE := 'N/A';
    v_top_rev_amount   NUMBER := -1;

    --Get all vendors
    CURSOR cur_vendors IS
        SELECT id, name
        FROM delivery_vendor
        ORDER BY name;

    --Get deliveries and invoice amounts
    CURSOR cur_deliveries(p_vendor_id NUMBER) IS
        SELECT d.order_id, i.amount
        FROM delivery d
                 LEFT JOIN invoice i ON d.order_id = i.order_id
        WHERE d.vendor_id = p_vendor_id
          AND EXTRACT(YEAR FROM d.ordered_at) = p_year;

BEGIN
    OPEN cur_vendors;
    --Header
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('DELIVERY VENDOR YEARLY PERFORMANCE REPORT: ' || p_year, 50));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));

    FOR rec_vendor IN cur_vendors LOOP
            OPEN cur_deliveries;
            v_order_count   := 0;
            v_total_revenue := 0;

            FOR rec_del IN cur_deliveries(rec_vendor.id) LOOP
                    v_order_count := v_order_count + 1;
                    v_total_revenue := v_total_revenue + NVL(rec_del.amount, 0);
                END LOOP;

            DBMS_OUTPUT.PUT_LINE(
                    '  ▶ ' || RPAD(UPPER(rec_vendor.name), 20) ||
                    ' : ' || LPAD(v_order_count, 4) || ' Orders | ' ||
                    'Revenue: RM ' || TO_CHAR(v_total_revenue, 'FM999,990.00')
            );

            IF v_order_count > v_top_vol_count THEN
                v_top_vol_count := v_order_count;
                v_top_vol_name  := rec_vendor.name;
            END IF;

            IF v_total_revenue > v_top_rev_amount THEN
                v_top_rev_amount := v_total_revenue;
                v_top_rev_name   := rec_vendor.name;
            END IF;

        END LOOP;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || RPAD('=', 70, '='));

    --Footer
    IF v_top_vol_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('  TOP VOLUME (Most Orders)  : ' || UPPER(v_top_vol_name) || ' (' || v_top_vol_count || ' Orders)');
        DBMS_OUTPUT.PUT_LINE('  TOP VALUE  (Most Revenue) : ' || UPPER(v_top_rev_name) || ' (RM ' || TO_CHAR(v_top_rev_amount, 'FM999,990.00') || ')');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  No active deliveries made in : ' || p_year);
    END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));

END;
/

--REPORT 1 PROMPT
BEGIN
    proc_compare_vendors();
end;
/

--REPORT 2
--Report on the revenue and total orders for each states and their respective cities based on year, 
-- listing top 3 highest and lowest order to make sales decision accordingly
CREATE OR REPLACE PROCEDURE proc_state_order_summary (
    p_year  IN NUMBER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    p_month IN NUMBER DEFAULT EXTRACT(MONTH FROM CURRENT_DATE)
) AS

    v_period_title   VARCHAR2(50);
    v_aov            NUMBER;
    v_rank           NUMBER;
    v_curr_state     address.state%TYPE;
    v_state_orders   NUMBER;
    v_state_revenue  NUMBER;
    v_curr_city      address.city%TYPE;
    v_city_orders    NUMBER;
    v_city_revenue   NUMBER;

    --States for top and bottom based on orders
    CURSOR cur_states (p_sort_mult NUMBER) IS
        SELECT
            a.state,
            COUNT(DISTINCT o.id)      AS state_orders,
            NVL(SUM(i.amount), 0)     AS state_revenue
        FROM orders o
                 JOIN (
            SELECT
                member_id,
                address_id,
                ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY address_id) AS rn
            FROM member_address
        ) ma
              ON o.member_id = ma.member_id
                  AND ma.rn = 1
         JOIN address a
              ON ma.address_id = a.id
         LEFT JOIN invoice i
                   ON o.id = i.order_id
        WHERE a.state IS NOT NULL
          AND EXTRACT(YEAR  FROM o.ordered_at) = p_year
          AND EXTRACT(MONTH FROM o.ordered_at) = p_month
        GROUP BY a.state
        ORDER BY (COUNT(DISTINCT o.id) * p_sort_mult) DESC
            FETCH FIRST 3 ROWS ONLY;

   
    -- Cities
    CURSOR cur_cities (p_state_name VARCHAR2) IS
        SELECT
            a.city,
            COUNT(DISTINCT o.id)  AS city_orders,
            NVL(SUM(i.amount), 0) AS city_revenue
        FROM orders o
                 JOIN (
            SELECT
                member_id,
                address_id,
                ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY address_id) AS rn
            FROM member_address
        ) ma ON o.member_id = ma.member_id
              AND ma.rn = 1
         JOIN address a
              ON ma.address_id = a.id
         LEFT JOIN invoice i
      ON o.id = i.order_id
        WHERE a.state = p_state_name
          AND EXTRACT(YEAR  FROM o.ordered_at) = p_year
          AND EXTRACT(MONTH FROM o.ordered_at) = p_month
        GROUP BY a.city
        ORDER BY city_orders DESC;

BEGIN

    -- Header
    v_period_title := TRIM(TO_CHAR(TO_DATE(p_month, 'MM'), 'MONTH')) || ' ' || p_year;
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 85, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('STATE ORDERS SUMMARY : ' || v_period_title, 53));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 85, '='));
    DBMS_OUTPUT.PUT_LINE('');
    
    --Top States
    
    DBMS_OUTPUT.PUT_LINE(LPAD('TOP 3 STATES BY ORDERS', 53));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 85, '='));
    v_rank := 1;
    OPEN cur_states(1);
    LOOP
        FETCH cur_states
            INTO v_curr_state, v_state_orders, v_state_revenue;
        EXIT WHEN cur_states%NOTFOUND;
        
        v_aov := CASE
                 WHEN v_state_orders > 0
                     THEN v_state_revenue / v_state_orders
                 ELSE 0
            END;
        DBMS_OUTPUT.PUT_LINE(v_rank || '. State: ' || UPPER(v_curr_state));
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('Total Orders:', 25) || v_state_orders);
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('Total Revenue:', 25) ||
                             'RM ' || LPAD(TO_CHAR(v_state_revenue, 'FM999,990.00'), 10));
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('Avg Order Value:', 25) ||
                             'RM ' || LPAD(TO_CHAR(v_aov, 'FM999,990.00'), 10));

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('CITY NAME', 30) ||
                             RPAD('ORDERS', 15) || 'REVENUE');
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('-', 65, '-'));

        OPEN cur_cities(v_curr_state);
        LOOP
            FETCH cur_cities
                INTO v_curr_city, v_city_orders, v_city_revenue;
            EXIT WHEN cur_cities%NOTFOUND;

            DBMS_OUTPUT.PUT_LINE(
                    '   ' || RPAD(v_curr_city, 30) ||
                    RPAD(v_city_orders, 15) ||
                    'RM ' || LPAD(TO_CHAR(v_city_revenue, 'FM999,990.00'), 10)
            );
        END LOOP;
        CLOSE cur_cities;

        DBMS_OUTPUT.PUT_LINE(RPAD('=', 85, '='));
        v_rank := v_rank + 1;
    END LOOP;
    CLOSE cur_states;

    DBMS_OUTPUT.PUT_LINE('');


    -- Bottom States
    DBMS_OUTPUT.PUT_LINE(LPAD('BOTTOM 3 STATES BY ORDERS', 54));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 85, '='));

    v_rank := 1;

    OPEN cur_states(-1);
    LOOP
        FETCH cur_states
            INTO v_curr_state, v_state_orders, v_state_revenue;
        EXIT WHEN cur_states%NOTFOUND;

        v_aov := CASE
                     WHEN v_state_orders > 0
                         THEN v_state_revenue / v_state_orders
                     ELSE 0
            END;

        DBMS_OUTPUT.PUT_LINE(v_rank || '. State: ' || UPPER(v_curr_state));
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('Total Orders:', 25) || v_state_orders);
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('Total Revenue:', 25) ||
                             'RM ' || LPAD(TO_CHAR(v_state_revenue, 'FM999,990.00'), 10));
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('Avg Order Value:', 25) ||
                             'RM ' || LPAD(TO_CHAR(v_aov, 'FM999,990.00'), 10));

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('CITY NAME', 30) ||
                             RPAD('ORDERS', 15) || 'REVENUE');
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('-', 65, '-'));

        OPEN cur_cities(v_curr_state);
        LOOP
            FETCH cur_cities
                INTO v_curr_city, v_city_orders, v_city_revenue;
            EXIT WHEN cur_cities%NOTFOUND;

            DBMS_OUTPUT.PUT_LINE(
                '   ' || RPAD(v_curr_city, 30) ||
                RPAD(v_city_orders, 15) ||
                'RM ' || LPAD(TO_CHAR(v_city_revenue, 'FM999,990.00'), 10)
            );
        END LOOP;
        CLOSE cur_cities;

        DBMS_OUTPUT.PUT_LINE(RPAD('=', 85, '='));
        v_rank := v_rank + 1;
    END LOOP;
    CLOSE cur_states;

    DBMS_OUTPUT.PUT_LINE('END OF REPORT');
END;
/
--REPORT 2 prompt
BEGIN
    proc_state_order_summary(2026, 4);
end;
/









