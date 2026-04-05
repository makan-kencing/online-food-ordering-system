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
    p_order_type_input    IN VARCHAR2,              -- Accept as String (VARCHAR2)
    p_payment_method_id   IN payment.payment_method_id%TYPE,
    p_amount              IN payment.amount%TYPE,
    p_ref_no              IN payment.ref_no%TYPE,
    p_description         IN VARCHAR2
) AS
    v_order_id      orders.id%TYPE;
    v_payment_id    payment.id%TYPE;
    v_current_time  TIMESTAMP := CURRENT_TIMESTAMP;
    v_type_str      VARCHAR2(20) := UPPER(TRIM(p_order_type_input));
BEGIN
    --Create Order
    INSERT INTO orders (member_id, ordered_at, order_type)
    VALUES (p_member_id, v_current_time, v_type_str)
    RETURNING id INTO v_order_id;

    --Create the Payment
    INSERT INTO payment (payment_method_id, paid_at, ref_no, amount)
    VALUES (p_payment_method_id, v_current_time, p_ref_no, p_amount)
    RETURNING id INTO v_payment_id;

    --Create Invoice
    INSERT INTO invoice (order_id, payment_id, invoiced_at, amount)
    VALUES (v_order_id, v_payment_id, v_current_time, p_amount);

    -- 4. Generate the Receipt
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('           SHOPGRAB OFFICIAL              ');
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('ORDER ID   : ' || v_order_id);
    DBMS_OUTPUT.PUT_LINE('DATE/TIME  : ' || TO_CHAR(v_current_time, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('MEMBER ID  : ' || p_member_id);

    -- Use TO_CHAR here to ensure the Enum displays correctly as text on the receipt
    DBMS_OUTPUT.PUT_LINE('ORDER TYPE : ' || TO_CHAR(v_type_str));
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');

    DBMS_OUTPUT.PUT_LINE(RPAD('DESCRIPTION:', 25) || p_description);
    DBMS_OUTPUT.PUT_LINE(RPAD('PAYMENT REF:', 25) || p_ref_no);
    DBMS_OUTPUT.PUT_LINE('------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('TOTAL PAID:', 25) || 'RM ' || TO_CHAR(p_amount, 'FM999,990.00'));
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('       TRANSACTION SUCCESSFUL             ');

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Order failed. Check if Order Type is DELIVERY or PICKUP.');
        DBMS_OUTPUT.PUT_LINE('Detail: ' || SQLERRM);
END;
/
