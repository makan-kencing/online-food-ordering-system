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
        WHERE id = p_order_id AND order_type = order_type.DELIVERY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Cannot dispatch: Order ID ' || p_order_id || ' does not exist or is a PICKUP order.');
    END;

    --Checks whether the invoice for this order exists 
    BEGIN
        SELECT 1 INTO v_invoice_exists
        FROM invoice
        WHERE order_id = p_order_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Cannot dispatch: Order ID ' || p_order_id || ' does not have an active invoice.');
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
    DBMS_OUTPUT.PUT_LINE('Order ID: ' || p_order_id || 'Created Delivery ID: ' || v_delivery_id);
    DBMS_OUTPUT.PUT_LINE('Created Delivery ID: ' || v_delivery_id);
    DBMS_OUTPUT.PUT_LINE('Ordered At: ' || TO_CHAR(v_dispatch_time, 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Estimated Arrival: ' || TO_CHAR(v_estimated_arrive_at, 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('-----------------------------------');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/


--PROCEDURE 2
--To create order and generate receipt
CREATE OR REPLACE PROCEDURE proc_place_order (
    p_member_id           IN orders.member_id%TYPE,
    p_order_type          IN orders.order_type%TYPE,
    p_payment_method_id   IN payment.payment_method_id%TYPE,
    p_amount              IN payment.amount%TYPE,
    p_ref_no              IN payment.ref_no%TYPE,
    p_payment_data        IN VARCHAR2,
    p_items               IN t_order_item_tab 
) AS
    v_order_id            orders.id%TYPE;
    v_payment_id          payment.id%TYPE;
    v_invoice_id          invoice.id%TYPE;
    v_order_item_id       order_item.id%TYPE;
    v_current_time        TIMESTAMP := CURRENT_TIMESTAMP;
    v_product_name        product.name%TYPE;
    v_feature_name        product_feature.name%TYPE;
    v_item_subtotal       NUMBER;
    v_feature_subtotal    NUMBER;
BEGIN
    -- Create Order
    INSERT INTO orders (member_id, ordered_at, order_type)
    VALUES (p_member_id, v_current_time, p_order_type)
    RETURNING id INTO v_order_id;

    --Add all OrderItems and the Features
    FOR i IN 1 .. p_items.COUNT LOOP
            INSERT INTO order_item (order_id, product_id, quantity, unit_price, remarks)
            VALUES (v_order_id, p_items(i).product_id, p_items(i).quantity, p_items(i).unit_price, p_items(i).remarks)
            RETURNING id INTO v_order_item_id;

            IF p_items(i).features IS NOT NULL THEN
                FOR j IN 1 .. p_items(i).features.COUNT LOOP
                        INSERT INTO order_item_feature (product_feature_id, order_item_id, quantity, unit_price, remarks)
                        VALUES (p_items(i).features(j).product_feature_id, v_order_item_id,
                                p_items(i).features(j).quantity, p_items(i).features(j).unit_price,
                                p_items(i).features(j).remarks);
                    END LOOP;
            END IF;
        END LOOP;

    -- Create Payment
    INSERT INTO payment (payment_method_id, paid_at, ref_no, amount, payment_method_data)
    VALUES (p_payment_method_id, v_current_time, p_ref_no, p_amount, p_payment_data)
    RETURNING id INTO v_payment_id;

    -- Create Invoice
    INSERT INTO invoice (order_id, payment_id, invoiced_at, amount)
    VALUES (v_order_id, v_payment_id, v_current_time, p_amount)
    RETURNING id INTO v_invoice_id;

    COMMIT;

    -- ========================================================
    -- DIGITAL RECEIPT
    -- ========================================================
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('          SHOPGRAB OFFICIAL RECEIPT       ');
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('ORDER ID : ' || v_order_id);
    DBMS_OUTPUT.PUT_LINE('DATE     : ' || TO_CHAR(v_current_time, 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');

    -- Show all order items that are added inside 
    FOR i IN 1 .. p_items.COUNT LOOP

            SELECT name INTO v_product_name FROM product WHERE id = p_items(i).product_id;

            
            v_item_subtotal := p_items(i).quantity * p_items(i).unit_price;

            DBMS_OUTPUT.PUT_LINE(RPAD(p_items(i).quantity || 'x ' || v_product_name, 32) || 'RM ' || TO_CHAR(v_item_subtotal, 'FM999,990.00'));

            
            IF p_items(i).features IS NOT NULL THEN
                FOR j IN 1 .. p_items(i).features.COUNT LOOP
                        SELECT name INTO v_feature_name FROM product_feature WHERE id = p_items(i).features(j).product_feature_id;
                        v_feature_subtotal := p_items(i).features(j).quantity * p_items(i).features(j).unit_price;
                        DBMS_OUTPUT.PUT_LINE('   + ' || RPAD(p_items(i).features(j).quantity || 'x ' || v_feature_name, 27) || 'RM ' || TO_CHAR(v_feature_subtotal, 'FM999,990.00'));
                    END LOOP;
            END IF;
        END LOOP;

    DBMS_OUTPUT.PUT_LINE('------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('TOTAL PAID:', 32) || 'RM ' || TO_CHAR(p_amount, 'FM999,990.00'));
    DBMS_OUTPUT.PUT_LINE('==========================================');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
