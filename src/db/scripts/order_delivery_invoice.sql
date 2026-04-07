--Query 1 
-- View all active orders, that shows the deliveries that have not yet reached the estimated time of arrival 
CREATE OR REPLACE VIEW active_delivery AS
SELECT
    o.id AS order_id,
    o.member_id,
    TO_CHAR(o.ordered_at, 'YYYY-MM-DD HH24:MI:SS') AS order_placed_time,
    d.id AS delivery_id,
    dv.name AS vendor_name,
    d.address_id AS delivery_address_id,
    TO_CHAR(d.estimated_arrive_at, 'YYYY-MM-DD HH24:MI:SS') AS estimated_arrive_at
FROM
    orders o
        INNER JOIN
    delivery d ON o.id = d.order_id
        LEFT JOIN
    delivery_vendor dv ON d.vendor_id = dv.id
WHERE
    d.estimated_arrive_at > CURRENT_TIMESTAMP;
SELECT *
FROM active_delivery
ORDER BY estimated_arrive_at ASC;

--Query 2
--View all items sold with detailed sales information, can be used for sales analysis, such as identifying top-selling products and calculating total revenue generated.
CREATE OR REPLACE VIEW all_items_sold AS
SELECT
    oi.id AS order_item_id,
    o.id AS order_id,
    i.id AS invoice_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS total,
    i.invoiced_at AS sale_date
FROM
    order_item oi
        INNER JOIN
    orders o ON oi.order_id = o.id
        INNER JOIN
    invoice i ON o.id = i.order_id;

SELECT * FROM all_items_sold;


--Procedure 1
--To create orders in delivery table
CREATE OR REPLACE PROCEDURE proc_dispatch_order (
    p_order_id            IN orders.id%TYPE,
    p_address_id          IN delivery.address_id%TYPE,
    p_vendor_id           IN delivery.vendor_id%TYPE
) AS
    v_order_exists        NUMBER;
    v_delivery_id         NUMBER;
    v_dispatch_time       TIMESTAMP := CURRENT_TIMESTAMP;
    v_estimated_arrive_at TIMESTAMP := v_dispatch_time + INTERVAL '30' MINUTE;
BEGIN
    -- Check if the order actually exists AND is a delivery order
    BEGIN
        SELECT 1 INTO v_order_exists
        FROM orders
        WHERE id = p_order_id AND order_type = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Cannot dispatch: Order ID ' || p_order_id || ' does not exist or is not a DELIVERY order.');
    END;

    INSERT INTO delivery (
        order_id,
        address_id,
        vendor_id,
        ordered_at,
        estimated_arrive_at
    ) VALUES (
                 p_order_id,
                 p_address_id,
                 p_vendor_id,
                 v_dispatch_time,
                 v_estimated_arrive_at
             )
    RETURNING id INTO v_delivery_id;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('-----------------------------------');
    DBMS_OUTPUT.PUT_LINE('Successfully dispatched order.');
    DBMS_OUTPUT.PUT_LINE('Order ID          : ' || p_order_id);
    DBMS_OUTPUT.PUT_LINE('Created Delivery ID: ' || v_delivery_id);
    DBMS_OUTPUT.PUT_LINE('Ordered At        : ' || TO_CHAR(v_dispatch_time, 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Estimated Arrival : ' || TO_CHAR(v_estimated_arrive_at, 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('-----------------------------------');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/


--PROCEDURE 2
--To create order and generate receipt
CREATE OR REPLACE PROCEDURE proc_finalize_payment (
    p_order_id            IN orders.id%TYPE,
    p_payment_method_id   IN payment.payment_method_id%TYPE,
    p_amount              IN payment.amount%TYPE,
    p_ref_no              IN payment.ref_no%TYPE,
    p_description         IN VARCHAR2
) AS
    v_payment_id    payment.id%TYPE;
    v_current_time  TIMESTAMP := CURRENT_TIMESTAMP;
    v_order_type    orders.order_type%TYPE;
    v_restaurant_name restaurant.name%type;
    v_item_subtotal NUMBER;
        
BEGIN
    SELECT order_type
    INTO v_order_type
    FROM orders
    WHERE id = p_order_id;

    BEGIN
        SELECT r.name
        INTO v_restaurant_name
        FROM order_item oi
                 JOIN menu_item m ON oi.product_id = m.product_id
                 JOIN restaurant r ON m.restaurant_id = r.id
        WHERE oi.order_id = p_order_id
            FETCH FIRST 1 ROW ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_restaurant_name := 'Unknown Restaurant';
    END;
    
    INSERT INTO payment (payment_method_id, paid_at, ref_no, amount)
    VALUES (p_payment_method_id, v_current_time, p_ref_no, p_amount)
    RETURNING id INTO v_payment_id;

    INSERT INTO invoice (order_id, payment_id, invoiced_at, amount)
    VALUES (p_order_id, v_payment_id, v_current_time, p_amount);

    --Receipt Display
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('           SHOPGRAB OFFICIAL              ');
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('ORDER ID   : ' || p_order_id);
    DBMS_OUTPUT.PUT_LINE('DATE/TIME  : ' || TO_CHAR(v_current_time, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('RESTAURANT  : ' || v_restaurant_name);
    DBMS_OUTPUT.PUT_LINE('ORDER TYPE : ' || TO_CHAR(v_order_type));
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('ITEMS', 30) || 'SUBTOTAL');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');

    
    FOR item IN (
        SELECT p.name, oi.quantity, oi.unit_price
        FROM order_item oi
                 JOIN product p ON oi.product_id = p.id
        WHERE oi.order_id = p_order_id
        ) LOOP
            v_item_subtotal := item.quantity * item.unit_price;
            DBMS_OUTPUT.PUT_LINE(
                    RPAD(item.quantity || 'x ' || item.name, 30) ||
                    'RM ' || LPAD(TO_CHAR(v_item_subtotal, 'FM990.00'), 8)
            );
        END LOOP;

    DBMS_OUTPUT.PUT_LINE('------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('DESCRIPTION:', 25) || p_description);
    DBMS_OUTPUT.PUT_LINE(RPAD('PAYMENT REF:', 25) || p_ref_no);
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('TOTAL PAID:', 25) || 'RM ' || TO_CHAR(p_amount, 'FM999,990.00'));
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('       TRANSACTION SUCCESSFUL             ');

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Order ID ' || p_order_id || ' does not exist.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Payment failed. ' || SQLERRM);
END;
/

--TRIGGER 1
--Lock Orders once placed
CREATE OR REPLACE TRIGGER trg_order_item_lock
    BEFORE INSERT OR UPDATE OR DELETE ON order_item
    FOR EACH ROW
DECLARE
    v_locked NUMBER;
    v_id order_item.order_id%TYPE;
BEGIN
    --Get the Order ID 
    v_id := NVL(:NEW.order_id, :OLD.order_id);

    --Check if an invoice exists for this order
    SELECT COUNT(*) INTO v_locked
    FROM invoice
    WHERE order_id = v_id;

    IF v_locked > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Order cannot be modified once placed');
    END IF;
END;
/

--TRIGGER 2
--Each order can have order_items from the same restaurant
CREATE OR REPLACE TRIGGER trg_order_item_shop
    FOR INSERT OR UPDATE ON order_item
    COMPOUND TRIGGER

    TYPE t_order_set IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
    v_orders t_order_set;

BEFORE EACH ROW IS
BEGIN
    IF :NEW.order_id IS NOT NULL THEN
        v_orders(:NEW.order_id) := TRUE;
    END IF;
END BEFORE EACH ROW;

    AFTER STATEMENT IS
        v_valid_shops NUMBER;
        v_id PLS_INTEGER;
    BEGIN
        v_id := v_orders.FIRST;

        WHILE v_id IS NOT NULL LOOP
                --Check if there is a restaurant that sells ALL products currently in the order
                SELECT COUNT(*) INTO v_valid_shops
                FROM (
                         SELECT m.restaurant_id
                         FROM order_item o
                                  JOIN menu_item m ON o.product_id = m.product_id
                         WHERE o.order_id = v_id
                         GROUP BY m.restaurant_id
                         --Ensure this restaurant covers every order item in the cart
                         HAVING COUNT(DISTINCT o.product_id) = (
                             SELECT COUNT(DISTINCT product_id)
                             FROM order_item
                             WHERE order_id = v_id
                         )
                     );
                IF v_valid_shops = 0 THEN
                    RAISE_APPLICATION_ERROR(-20002, 'All order items must be from the same shop.');
                END IF;

                v_id := v_orders.NEXT(v_id);
            END LOOP;

        v_orders.DELETE;
    END AFTER STATEMENT;

    END trg_order_item_shop;
/



-- REPORT 1
-- Restaurant performance summary report
CREATE OR REPLACE PROCEDURE delivery_audit_report (
    p_month IN NUMBER DEFAULT NULL, 
    p_year  IN NUMBER DEFAULT NULL  
) AS

    v_item_count        NUMBER;
    v_total_orders      NUMBER := 0;
    v_vendor_order_count  NUMBER := 0;
    v_top_vendor_name    delivery_vendor.name%TYPE := 'N/A';
    v_top_vendor_orders  NUMBER := 0;
    v_active_vendors     NUMBER := 0;

    
    v_restaurant_name   restaurant.name%TYPE;
    v_state             address.state%TYPE;
    v_country           address.country%TYPE;
        
    v_start_date        DATE := NULL;
    v_end_date          DATE := NULL;
    v_report_date_title VARCHAR2(50) := 'ALL-TIME';



    CURSOR cur_vendors IS
        SELECT id, name FROM delivery_vendor ORDER BY id;

    CURSOR cur_vendor_deliveries (p_vendor_id NUMBER, p_start DATE, p_end DATE) IS
        SELECT o.id AS order_id,
               TO_CHAR(o.ordered_at, 'DD-MON-YYYY HH:MI AM') AS formatted_date
        FROM orders o
                 JOIN delivery d ON o.id = d.order_id
        WHERE d.vendor_id = p_vendor_id
          AND o.order_type = 1
          AND (p_start IS NULL OR o.ordered_at >= p_start)
          AND (p_end IS NULL OR o.ordered_at < p_end)
        ORDER BY o.ordered_at DESC;

    
    CURSOR cur_order_items (p_order_id NUMBER) IS
        SELECT oi.product_id, p.name AS product_name, oi.quantity
        FROM order_item oi
                 JOIN product p ON oi.product_id = p.id
        WHERE oi.order_id = p_order_id;

BEGIN
    IF p_year IS NOT NULL AND p_month IS NOT NULL THEN
        v_start_date := TO_DATE(p_year || '-' || LPAD(p_month, 2, '0') || '-01', 'YYYY-MM-DD');
        v_end_date := ADD_MONTHS(v_start_date, 1);
        v_report_date_title := TO_CHAR(v_start_date, 'MONTH YYYY');
    END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('SHOPGRAB DELIVERY AUDIT REPORT', 68));
    DBMS_OUTPUT.PUT_LINE(LPAD('Report Period: ' || TRIM(v_report_date_title), 62));
    DBMS_OUTPUT.PUT_LINE(LPAD('Date & Time: ' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI'), 62));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));

    
    FOR rec_vendor IN cur_vendors LOOP

            v_vendor_order_count := 0;
            DBMS_OUTPUT.PUT_LINE(CHR(10));
            DBMS_OUTPUT.PUT_LINE(RPAD('+', 100, '+'));
            DBMS_OUTPUT.PUT_LINE(' DELIVERY PARTNER: ' || UPPER(rec_vendor.name));
            DBMS_OUTPUT.PUT_LINE(RPAD('+', 100, '+'));

            
            FOR rec_order IN cur_vendor_deliveries(rec_vendor.id, v_start_date, v_end_date) LOOP

                    SELECT COUNT(*) INTO v_item_count
                    FROM order_item
                    WHERE order_id = rec_order.order_id;

                    IF v_item_count > 0 THEN
                        v_total_orders := v_total_orders + 1;
                        v_vendor_order_count := v_vendor_order_count + 1;

                        --Get restaurant and location
                        BEGIN
                            SELECT r.name, a.state, a.country
                            INTO v_restaurant_name, v_state, v_country
                            FROM order_item oi
                                     JOIN menu_item m ON oi.product_id = m.product_id
                                     JOIN restaurant r ON r.id = m.restaurant_id
                                     JOIN address a ON r.address_id = a.id
                            WHERE oi.order_id = rec_order.order_id
                                FETCH FIRST 1 ROW ONLY;
                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                                v_restaurant_name := 'N/A';
                                v_state := 'N/A';
                                v_country := 'N/A';
                        END;

                        DBMS_OUTPUT.PUT_LINE(CHR(10) || ' [ORDER #' || RPAD(rec_order.order_id, 6) || '] | DATE: ' || rec_order.formatted_date);
                        DBMS_OUTPUT.PUT_LINE(' Restaurant : ' || v_restaurant_name);
                        DBMS_OUTPUT.PUT_LINE(' Location   : ' || v_state || ', ' || v_country);
                        DBMS_OUTPUT.PUT_LINE(' Total Items: ' || v_item_count);
                        DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));
                        DBMS_OUTPUT.PUT_LINE('    ' || RPAD('PRODUCT', 40) || ' | ' || LPAD('QTY', 5));
                        DBMS_OUTPUT.PUT_LINE('    ' || RPAD('-', 50, '-'));

                        -- ITEMS 
                        FOR rec_item IN cur_order_items(rec_order.order_id) LOOP
                                DBMS_OUTPUT.PUT_LINE('    ' || RPAD(rec_item.product_id || '. ' || rec_item.product_name, 40) || ' | ' || LPAD(rec_item.quantity, 5));
                            END LOOP;

                        DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));
                    END IF;
                END LOOP;

            
            IF v_vendor_order_count = 0 THEN
                DBMS_OUTPUT.PUT_LINE(CHR(10) || '    -> No active deliveries logged for this partner in this period.');
            END IF;

            -- Track active vendors
            IF v_vendor_order_count > 0 THEN
                v_active_vendors := v_active_vendors + 1;
            END IF;

            -- Track top performer
            IF v_vendor_order_count > v_top_vendor_orders THEN
                v_top_vendor_orders := v_vendor_order_count;
                v_top_vendor_name := rec_vendor.name;
            END IF;

            -- Vendor Summary
            DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));
            DBMS_OUTPUT.PUT_LINE(' TOTAL DELIVERY ORDERS FOR ' || UPPER(rec_vendor.name) || ': ' || v_vendor_order_count);
            DBMS_OUTPUT.PUT_LINE(RPAD('-', 100, '-'));

        END LOOP;

    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || RPAD('=', 100, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('REPORT SUMMARY', 57));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));
    DBMS_OUTPUT.PUT_LINE(' TOTAL DELIVERY ORDERS FOUND : ' || v_total_orders);
    DBMS_OUTPUT.PUT_LINE(' ACTIVE DELIVERY VENDORS   : ' || v_active_vendors);
    DBMS_OUTPUT.PUT_LINE(' TOP PERFORMING VENDOR     : ' || UPPER(v_top_vendor_name));
    DBMS_OUTPUT.PUT_LINE(' ORDERS COMPLETED           : ' || v_top_vendor_orders);
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('*** END OF REPORT ***', 60));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/


--REPORT 2
--Top Selling Order Items to track restaurant revenue and the best selling item(how many sold and how much made)
CREATE OR REPLACE PROCEDURE restaurant_item_report (
    p_month IN NUMBER DEFAULT NULL, 
    p_year  IN NUMBER DEFAULT NULL  
) AS

    v_has_sales             NUMBER := 0;
    v_global_revenue        NUMBER := 0;
    v_global_qty            NUMBER := 0;
    v_active_restaurants    NUMBER := 0;

    v_best_restaurant       VARCHAR2(100);
    v_best_restaurant_revenue NUMBER := 0;

    v_best_product          VARCHAR2(100);
    v_best_product_qty      NUMBER := 0;

    v_total_qty             NUMBER;
    v_total_revenue         NUMBER;
    v_top_product           VARCHAR2(100);
    v_top_qty               NUMBER;

    v_start_date            DATE := NULL;
    v_end_date              DATE := NULL;
    v_report_title_date     VARCHAR2(50) := 'ALL-TIME';

BEGIN
    
    IF p_year IS NOT NULL AND p_month IS NOT NULL THEN
        v_start_date := TO_DATE(p_year || '-' || LPAD(p_month, 2, '0') || '-01', 'YYYY-MM-DD');
        v_end_date := ADD_MONTHS(v_start_date, 1);
        v_report_title_date := TO_CHAR(v_start_date, 'MONTH YYYY');
    END IF;

    
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 85, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('RESTAURANT REVENUE & TOP-ORDER ITEMS REPORT', 62));
    DBMS_OUTPUT.PUT_LINE(LPAD('Report Period: ' || TRIM(v_report_title_date), 62));
    DBMS_OUTPUT.PUT_LINE(LPAD('Run Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI'), 61));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 85, '='));

    
    FOR rec_vendor IN (
        SELECT id, name
        FROM restaurant
        ORDER BY name
        ) LOOP

            v_has_sales := 0;
            v_total_qty := 0;
            v_total_revenue := 0;
            v_top_product := 'None';
            v_top_qty := 0;

            -- VENDOR HEADER
            DBMS_OUTPUT.PUT_LINE(CHR(10) || RPAD('+', 85, '+'));
            DBMS_OUTPUT.PUT_LINE('| ' || RPAD('  RESTAURANT: ' || UPPER(rec_vendor.name), 81) || ' |');
            DBMS_OUTPUT.PUT_LINE(RPAD('+', 85, '+'));

            
            FOR rec_sum IN (
                SELECT
                    p.name,
                    SUM(oi.quantity) AS total_qty,
                    SUM(oi.quantity * oi.unit_price) AS total_revenue
                FROM order_item oi
                         JOIN orders o ON oi.order_id = o.id  
                         JOIN product p ON oi.product_id = p.id
                         JOIN menu_item m ON p.id = m.product_id
                WHERE m.restaurant_id = rec_vendor.id
                  AND (v_start_date IS NULL OR o.ordered_at >= v_start_date)
                  AND (v_end_date IS NULL OR o.ordered_at < v_end_date)
                GROUP BY p.name
                ) LOOP
                    v_total_qty := v_total_qty + rec_sum.total_qty;
                    v_total_revenue := v_total_revenue + rec_sum.total_revenue;

                    IF rec_sum.total_qty > v_top_qty THEN
                        v_top_qty := rec_sum.total_qty;
                        v_top_product := rec_sum.name;
                    END IF;

                    IF rec_sum.total_qty > v_best_product_qty THEN
                        v_best_product_qty := rec_sum.total_qty;
                        v_best_product := rec_sum.name;
                    END IF;

                    v_has_sales := 1;
                END LOOP;

            
            IF v_has_sales = 0 THEN
                DBMS_OUTPUT.PUT_LINE('    -> No sales data registered for this restaurant in this period.');
                CONTINUE;
            END IF;

            
            v_active_restaurants := v_active_restaurants + 1;

            
            DBMS_OUTPUT.PUT_LINE('  [ PERFORMANCE SUMMARY ]');
            DBMS_OUTPUT.PUT_LINE('    Total Items Sold : ' || v_total_qty || ' units');
            DBMS_OUTPUT.PUT_LINE('    Total Revenue    : RM ' || TO_CHAR(v_total_revenue, 'FM999,990.00'));
            DBMS_OUTPUT.PUT_LINE('    Top Product      : ' || v_top_product || ' (' || v_top_qty || ' sold)');
            DBMS_OUTPUT.PUT_LINE('  ' || RPAD('-', 81, '-'));
            DBMS_OUTPUT.PUT_LINE(
                    '    ' || RPAD('PRODUCT NAME', 40) ||
                    ' | ' || LPAD('QTY', 6) ||
                    ' | ' || LPAD('REVENUE', 12)
            );
            DBMS_OUTPUT.PUT_LINE('    ' || RPAD('-', 64, '-'));

            
            FOR rec_item IN (
                SELECT *
                FROM (
                         SELECT
                             p.name AS product_name,
                             SUM(oi.quantity) AS total_qty,
                             SUM(oi.quantity * oi.unit_price) AS total_revenue
                         FROM order_item oi
                                  JOIN orders o ON oi.order_id = o.id
                                  JOIN product p ON oi.product_id = p.id
                                  JOIN menu_item m ON p.id = m.product_id
                         WHERE m.restaurant_id = rec_vendor.id
                           AND (v_start_date IS NULL OR o.ordered_at >= v_start_date)
                           AND (v_end_date IS NULL OR o.ordered_at < v_end_date)
                         GROUP BY p.name
                         ORDER BY total_qty DESC, total_revenue DESC
                     )
                WHERE ROWNUM <= 5
                ) LOOP
                    
                    DBMS_OUTPUT.PUT_LINE(
                            '  ▶ ' || RPAD(rec_item.product_name, 40) ||
                            ' | ' || LPAD(rec_item.total_qty, 6) ||
                            ' | RM ' || LPAD(TO_CHAR(rec_item.total_revenue, 'FM999,990.00'), 9)
                    );
                END LOOP;

            v_global_qty := v_global_qty + v_total_qty;
            v_global_revenue := v_global_revenue + v_total_revenue;

            IF v_total_revenue > v_best_restaurant_revenue THEN
                v_best_restaurant_revenue := v_total_revenue;
                v_best_restaurant := rec_vendor.name;
            END IF;

        END LOOP;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || RPAD('=', 85, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('GLOBAL PERFORMANCE SUMMARY', 56));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 85, '='));

    -- Top Performers
    DBMS_OUTPUT.PUT_LINE('  Most Performant Restaurant : ' || NVL(v_best_restaurant, 'N/A'));
    DBMS_OUTPUT.PUT_LINE('  Revenue Generated          : RM ' || TO_CHAR(v_best_restaurant_revenue, 'FM999,990.00'));

    --Most Popular Order Item
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '  Most Bought Item           : ' || NVL(v_best_product, 'N/A'));
    DBMS_OUTPUT.PUT_LINE('  Total Quantity Sold        : ' || v_best_product_qty || ' units');

    -- Platform Metrics
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '  Platform Metrics:');
    DBMS_OUTPUT.PUT_LINE('     Total Items Sold        : ' || v_global_qty || ' units');
    DBMS_OUTPUT.PUT_LINE('     Total Gross Revenue     : RM ' || TO_CHAR(v_global_revenue, 'FM999,990.00'));

    
    IF v_active_restaurants > 0 THEN
        DBMS_OUTPUT.PUT_LINE('     Avg Revenue per Restaurant  : RM ' || TO_CHAR(v_global_revenue / v_active_restaurants, 'FM999,990.00'));
    ELSE
        DBMS_OUTPUT.PUT_LINE('     Avg Revenue per Restaurant  : RM 0.00');
    END IF;

    
    -- FOOTER
    DBMS_OUTPUT.PUT_LINE(CHR(10) || RPAD('=', 85, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD('*** END OF ANALYTICS REPORT ***', 58));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 85, '='));

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Critical Analytics Error: ' || SQLERRM);

END;
/


--The Order Queue Index
CREATE INDEX idx_order_queue
    ON orders (ordered_at DESC, order_type);


--The Cart Index
CREATE INDEX idx_order_cart
    ON order_item (order_id, product_id);
