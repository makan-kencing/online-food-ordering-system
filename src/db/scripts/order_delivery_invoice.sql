--Query 1 
-- View all active othat shows the summarized delivery history for each order
CREATE OR REPLACE VIEW vw_delivery_history AS
SELECT
    o.id AS order_id,
    m.username AS cust_name,
    o.ordered_at,
    d.id AS delivery_id,
    dv.name AS vendor_name,
    d.estimated_arrive_at
FROM orders o
         INNER JOIN member m ON o.member_id = m.id
         INNER JOIN delivery d ON o.id = d.order_id
         INNER JOIN delivery_vendor dv ON d.vendor_id = dv.id
         LEFT JOIN invoice i ON o.id = i.order_id
WHERE o.order_type = 1
  AND d.estimated_arrive_at <= CURRENT_TIMESTAMP;




SELECT * FROM vw_delivery_history
WHERE cust_name = 'ocox6'
ORDER BY estimated_arrive_at DESC;

--Query 2
--View the summary for all orders,combining the order, restaurant, invoice and dispatch method
CREATE OR REPLACE VIEW vw_full_order_overview AS
SELECT

    o.id AS order_id,
    o.ordered_at,
    m.username AS cust_name,
    r.name AS restaurant_name,

    (SELECT COALESCE(SUM(quantity), 0) FROM order_item WHERE order_id = o.id) AS total_items_ordered,

    CASE
        WHEN i.id IS NOT NULL THEN 'PAID'
        ELSE 'UNPAID'
        END AS payment_status,
    COALESCE(i.amount, 0) AS total_amount,

    o.order_type,
    CASE
        WHEN o.order_type = 2 THEN 'Customer Pickup'
        WHEN o.order_type = 1 THEN 'Delivered by ' || dv.name
        ELSE 'Pending Dispatch'
        END AS dispatch_method

FROM orders o
         INNER JOIN member m ON o.member_id = m.id
         INNER JOIN restaurant r ON o.restaurant_id = r.id
         LEFT JOIN invoice i ON o.id = i.order_id
         LEFT JOIN delivery d ON o.id = d.order_id
         LEFT JOIN delivery_vendor dv ON d.vendor_id = dv.id;

SELECT * FROM vw_full_order_overview
WHERE total_amount < 500;

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
    v_item_subtotal NUMBER;

BEGIN
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

--PROCEDURE 1 TESTING
-- 1. Create the Order record
-- DECLARE
--     v_order_id   orders.id%TYPE;
--     v_payment_id payment.id%TYPE;
-- BEGIN
--     -- 1. Create the Order and capture the ID
--     -- NOTE: Use 'DELIVERY' instead of 1 to satisfy the procedure's internal check
--     INSERT INTO orders (member_id, order_type, restaurant_id, ordered_at)
--     VALUES (2, 'DELIVERY', 1, CURRENT_TIMESTAMP)
--     RETURNING id INTO v_order_id;
-- 
--     -- 2. Add Items to the Order using the variable
--     -- (2x Margherita Pizza)
--     INSERT INTO order_item (order_id, product_id, quantity, unit_price)
--     VALUES (v_order_id, 1, 2, 25.00);
-- 
--     -- (1x Pepperoni Pizza)
--     INSERT INTO order_item (order_id, product_id, quantity, unit_price)
--     VALUES (v_order_id, 2, 1, 15.00);
-- 
--     -- 3. Create Payment (Using Method 2 - Card)
--     -- Total amount: (2 * 25) + 15 = 65.00
--     INSERT INTO payment (payment_method_id, amount, payment_method_data)
--     VALUES (2, 65.00, '{"description": "Test Case Dispatch"}')
--     RETURNING id INTO v_payment_id;
-- 
--     -- 4. Create Invoice (The procedure will fail if this is missing)
--     INSERT INTO invoice (order_id, payment_id, amount)
--     VALUES (v_order_id, v_payment_id, 65.00);
-- 
--     -- 5. Execute the Dispatch Procedure
--     -- Parameters: New Order ID, Address ID (1), Vendor ID (1 - Grab)
--     proc_dispatch_order(
--             p_order_id   => v_order_id,
--             p_address_id => 1,
--             p_vendor_id  => 1
--     );
-- 
--     
--     -- Commit all changes
--     COMMIT;
-- 
-- END;
-- /

-- SELECT id
-- FROM orders
-- ORDER BY id DESC
--     FETCH FIRST 1 ROW ONLY;
-- 
-- -- TEST CASE VALID
-- BEGIN
--     -- Parameters: Order ID 20, Payment Method 3, Total RM 65.00
--     proc_finalize_payment(
--             p_order_id          => 1,
--             p_payment_method_id => 3,
--             p_amount            => 65.00,
--             p_description       => 'Dinner payment via TnG'
--     );
-- END;
-- /
-- -- TEST CASE INVALID
-- BEGIN
--     proc_finalize_payment(
--             p_order_id          => 9999,
--             p_payment_method_id => 2,
--             p_amount            => 10.00,
--             p_description       => 'Testing invalid order'
--     );
-- END;
-- /


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

    --Ensure it is a DELIVERY type
    IF v_order_type != 1 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cannot dispatch: This is a PICKUP order.');
    END IF;
    
    --Ensure it is a invoice exists to ensure the order is paid
    SELECT COUNT(*) INTO v_invoice_exists
    FROM invoice
    WHERE order_id = p_order_id;

    IF v_invoice_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cannot dispatch: Order ' || p_order_id || ' has not been invoiced/paid.');
    END IF;

    --Check whether the delivery for this order is already existing
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
    --Display Message for successful dispatch
    DBMS_OUTPUT.PUT_LINE('DISPATCH SUCCESSFUL - Invoice Verified');
    DBMS_OUTPUT.PUT_LINE('Delivery ID : ' || v_delivery_id);
    DBMS_OUTPUT.PUT_LINE('Order ID    : ' || p_order_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- --PROCEDURE 2 TESTING (RESTAURANT 1 - PIZZA PALACE DOWNTOWN)
-- DECLARE
--     v_order_id   INT;
--     v_payment_id INT;
--     -- Prices for calculation
--     v_price_margherita CONSTANT NUMBER := 25.00;
--     v_price_cheeseburger CONSTANT NUMBER := 15.00;
--     v_price_supreme      CONSTANT NUMBER := 35.00;
--     v_total_amount       NUMBER;
-- BEGIN
--     -- 1. Create the Order (Member 2 at Restaurant 1)
--     -- Using 'DELIVERY' string to ensure it passes the procedure's type check
--     INSERT INTO orders (member_id, order_type, restaurant_id, ORDERED_AT)
--     VALUES (2, 'DELIVERY', 1, CURRENT_TIMESTAMP)
--     RETURNING id INTO v_order_id;
-- 
--     -- 2. Add Order Items based on verified menu for Restaurant 1
-- 
--     -- Adding 2x Margherita Pizza (Product ID 1)
--     INSERT INTO order_item (order_id, product_id, quantity, unit_price)
--     VALUES (v_order_id, 1, 2, v_price_margherita);
-- 
--     -- Adding 1x Classic Cheeseburger (Product ID 4) 
--     INSERT INTO order_item (order_id, product_id, quantity, unit_price)
--     VALUES (v_order_id, 4, 1, v_price_cheeseburger);
-- 
--     -- Adding 1x Supreme Pizza (Product ID 13)
--     INSERT INTO order_item (order_id, product_id, quantity, unit_price)
--     VALUES (v_order_id, 13, 1, v_price_supreme);
-- 
--     -- Calculate total: (2 * 25) + 15 + 35 = 100.00
--     v_total_amount := (2 * v_price_margherita) + v_price_cheeseburger + v_price_supreme;
-- 
--     -- 3. Process Payment (Method 2: Card)
--     INSERT INTO payment (payment_method_id, amount, payment_method_data)
--     VALUES (2, v_total_amount, '{"card": "Visa", "tx": "IMG_VERIFIED_TEST"}')
--     RETURNING id INTO v_payment_id;
-- 
--     -- 4. Generate the Invoice (The "Green Light" for dispatch)
--     INSERT INTO invoice (order_id, payment_id, amount)
--     VALUES (v_order_id, v_payment_id, v_total_amount);
-- 
--     COMMIT;
-- END;
-- /
-- SELECT id
-- FROM orders
-- ORDER BY id DESC
--     FETCH FIRST 1 ROW ONLY;
-- 
-- BEGIN
--     proc_dispatch_order(
--             p_order_id   => 2,
--             p_address_id => 15,
--             p_vendor_id  => 1
--     );
-- end;

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
-- UPDATE order_item
-- SET quantity = 5
-- WHERE id = 343;


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
    --Identify which restaurant this order is officially tied to
    SELECT restaurant_id INTO v_order_restaurant_id
    FROM orders
    WHERE id = :NEW.order_id;
    
    SELECT name INTO v_product_name
    FROM product
    WHERE id = :NEW.product_id;

    --Check if the order_item being added is actually sold by that restaurant
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
--TRIGGER 2 TEST
-- -- Create Order #1 at Pizza Palace (Restaurant ID 1)
-- INSERT INTO orders (member_id, order_type, restaurant_id)
-- VALUES (2, 1, 1);
-- 
-- -- Create Order #2 at Burger King Express (Restaurant ID 2)
-- INSERT INTO orders (member_id, order_type, restaurant_id)
-- VALUES (3, 2, 2);
-- 
-- -- Adding Margherita Pizza to the Pizza Palace order
-- INSERT INTO order_item (order_id, product_id, quantity, unit_price)
-- VALUES (1, 1, 1, 25.00);
-- 
-- -- Verify the success
-- SELECT * FROM order_item WHERE order_id = 1;
-- 
-- 
-- -- "Order Item Classic Cheeseburger is not on the menu for the selected restaurant."
-- INSERT INTO order_item (order_id, product_id, quantity, unit_price)
-- VALUES (1, 4, 1, 12.00);
-- 
-- -- First, add a valid burger to the Burger King order
-- INSERT INTO order_item (order_id, product_id, quantity, unit_price)
-- VALUES (2, 4, 1, 15.00);
-- 
-- -- Now, try to update that item to a Pizza (Product 1)
-- UPDATE order_item
-- SET product_id = 1
-- WHERE order_id = 2 AND product_id = 4;


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
    --Header
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('DELIVERY VENDOR YEARLY PERFORMANCE REPORT: ' || p_year, 50));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 70, '='));

    FOR rec_vendor IN cur_vendors LOOP

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

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- --REPORT 1 PROMPT
-- BEGIN
--     proc_compare_vendors(2026);
-- end;


--REPORT 2
--Report on the revenue and total orders for each states and their respective cities based on year, 
-- listing top 3 highest and lowest order to make sales decision accordingly
CREATE OR REPLACE PROCEDURE proc_state_order_summary(
    p_year IN NUMBER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)
) AS
    v_state_orders      NUMBER;
    v_state_revenue     NUMBER;
    v_aov               NUMBER;
    v_top_city_orders   VARCHAR2(50);
    v_max_city_orders   NUMBER;
    v_top_city_rev      VARCHAR2(50);
    v_max_city_revenue  NUMBER;

    -- States
    CURSOR cur_states IS
        SELECT DISTINCT state FROM (
                                       SELECT a.state, o.ordered_at
                                       FROM orders o
                                                JOIN (
                                           -- pick one address per member to avoid double-counting
                                           SELECT member_id, address_id,
                                                  ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY address_id) as rn
                                           FROM member_address
                                       ) ma ON o.member_id = ma.member_id AND ma.rn = 1
                                                JOIN address a ON ma.address_id = a.id
                                   )
        WHERE state IS NOT NULL
          AND EXTRACT(YEAR FROM ordered_at) = p_year
        ORDER BY state;

    -- City 
    CURSOR cur_cities (p_state VARCHAR2) IS
        SELECT city, COUNT(DISTINCT order_id) as city_orders, SUM(amount) as city_revenue
        FROM (
                 SELECT a.city, o.id as order_id, NVL(i.amount, 0) as amount
                 FROM orders o
                          JOIN (
                     SELECT member_id, address_id,
                            ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY address_id) as rn
                     FROM member_address
                 ) ma ON o.member_id = ma.member_id AND ma.rn = 1
                          JOIN address a ON ma.address_id = a.id
                          LEFT JOIN invoice i ON o.id = i.order_id
                 WHERE a.state = p_state
                   AND EXTRACT(YEAR FROM o.ordered_at) = p_year
             )
        GROUP BY city;

BEGIN
    -- Header
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 112, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('STATES ORDER REPORT FOR YEAR : ' || p_year, 80));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 112, '='));
    DBMS_OUTPUT.PUT_LINE(
            RPAD('STATE', 8) || ' | ' ||
            LPAD('ORDERS', 8) || ' | ' ||
            LPAD('REVENUE (RM)', 15) || ' | ' ||
            LPAD('AVERAGE ORDER VALUE (RM)', 25) || ' | ' ||
            RPAD('MOST ORDERS (CITY)', 20) || ' | ' ||
            RPAD('HIGHEST VALUE (CITY)', 20)
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 112, '-'));

    FOR rec_state IN cur_states LOOP
            v_state_orders := 0; v_state_revenue := 0;
            v_max_city_orders := -1; v_top_city_orders := 'N/A';
            v_max_city_revenue := -1; v_top_city_rev := 'N/A';

            FOR rec_city IN cur_cities(rec_state.state) LOOP
                    v_state_orders  := v_state_orders + rec_city.city_orders;
                    v_state_revenue := v_state_revenue + rec_city.city_revenue;

                    IF rec_city.city_orders > v_max_city_orders THEN
                        v_max_city_orders := rec_city.city_orders;
                        v_top_city_orders := rec_city.city;
                    END IF;

                    IF rec_city.city_revenue > v_max_city_revenue THEN
                        v_max_city_revenue := rec_city.city_revenue;
                        v_top_city_rev := rec_city.city;
                    END IF;
                END LOOP;

            IF v_state_orders > 0 THEN v_aov := v_state_revenue / v_state_orders; ELSE v_aov := 0; END IF;

            DBMS_OUTPUT.PUT_LINE(
                    RPAD(UPPER(rec_state.state), 8) || ' | ' ||
                    LPAD(v_state_orders, 8) || ' | ' ||
                    LPAD(TO_CHAR(v_state_revenue, 'FM999,990.00'), 15) || ' | ' ||
                    LPAD(TO_CHAR(v_aov, 'FM990.00'), 25) || ' | ' ||
                    RPAD(SUBSTR(v_top_city_orders, 1, 20), 20) || ' | ' ||
                    RPAD(SUBSTR(v_top_city_rev, 1, 20), 20)
            );
        END LOOP;

    -- Footer
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 112, '-'));
    DBMS_OUTPUT.PUT_LINE(CHR(10) || RPAD('=', 112, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('STATE DEMANDS SUMMARY REPORT : ' || p_year, 72));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 112, '='));

    -- Top 3 States
    FOR top_st IN (
        SELECT state, COUNT(order_id) as total_orders, SUM(amount) as total_revenue
        FROM (
                 SELECT a.state, o.id as order_id, NVL(i.amount, 0) as amount
                 FROM orders o
                          JOIN (SELECT member_id, address_id, ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY address_id) as rn FROM member_address) ma
                               ON o.member_id = ma.member_id AND ma.rn = 1
                          JOIN address a ON ma.address_id = a.id
                          LEFT JOIN invoice i ON o.id = i.order_id
                 WHERE EXTRACT(YEAR FROM o.ordered_at) = p_year
             ) GROUP BY state ORDER BY total_orders DESC FETCH FIRST 3 ROWS ONLY
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('     ' || RPAD(UPPER(top_st.state), 10) || RPAD(top_st.total_orders, 12) || 'RM ' || TO_CHAR(top_st.total_revenue, 'FM999,990.00'));
        END LOOP;

    DBMS_OUTPUT.PUT_LINE(' ');

    -- Bottom 3 States
    FOR bot_st IN (
        SELECT state, COUNT(order_id) as total_orders, SUM(amount) as total_revenue
        FROM (
                 SELECT a.state, o.id as order_id, NVL(i.amount, 0) as amount
                 FROM orders o
                          JOIN (SELECT member_id, address_id, ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY address_id) as rn FROM member_address) ma
                               ON o.member_id = ma.member_id AND ma.rn = 1
                          JOIN address a ON ma.address_id = a.id
                          LEFT JOIN invoice i ON o.id = i.order_id
                 WHERE EXTRACT(YEAR FROM o.ordered_at) = p_year
             ) GROUP BY state ORDER BY total_orders ASC FETCH FIRST 3 ROWS ONLY
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('     ' || RPAD(UPPER(bot_st.state), 10) || RPAD(bot_st.total_orders, 12) || 'RM ' || TO_CHAR(bot_st.total_revenue, 'FM999,990.00'));
        END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 112, '='));

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- --REPORT 2 prompt
-- BEGIN
--     proc_state_order_summary(2025);
-- end;






