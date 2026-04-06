CREATE OR REPLACE PROCEDURE TRUNCATE_ALL_TABLES
AS
BEGIN
    for c1 in (select table_name, constraint_name from user_constraints) loop
        begin
            execute immediate ('alter table '||c1.table_name||' disable constraint '||c1.constraint_name);
        end;
    end loop;

    for t1 in (select table_name from user_tables) loop
        begin
            execute immediate ('truncate table '||t1.table_name);
        end;
    end loop;

    for c2 in (select table_name, constraint_name from user_constraints) loop
        begin
            execute immediate ('alter table '||c2.table_name||' enable constraint '||c2.constraint_name);
        end;
    end loop;
END;
/

EXEC TRUNCATE_ALL_TABLES;

INSERT INTO member (id, username, email)
VALUES (1, 'SYSTEM', 'system@example.com');

INSERT INTO DELIVERY_VENDOR (ID, NAME, DESCRIPTION)
VALUES (1, 'Grab', 'Grab delivery'),
        (2, 'Food Panda', 'FoodPanda delivery'),
        (3, 'Lalamove', 'Lalamove delivery'),
        (3, 'Shopee Food', 'Shopee food delivery');

INSERT INTO MEMBERSHIP (ID, NAME, DESCRIPTION, PRICE)
VALUES (1, 'VIP', 'VIP status', 10),
       (2, 'VVIP', 'VVIP status', 25);

INSERT INTO PAYMENT_METHOD (ID, NAME, DESCRIPTION)
VALUES (1, 'Bank', 'Bank payments'),
       (2, 'Card', 'Card payments'),
       (3, 'TnG E-wallet', 'Touch N Go E-wallet payments'),
       (4, 'DuitNow', 'DuitNow QR payment'),
       (5, 'GrabPay', 'GrabPay payments');

INSERT INTO PRICE_COMPONENT (VENDOR_ID, PRICE_TYPE, FROM_DATE, DESCRIPTION, PERCENTAGE, CREATED_BY_ID)
VALUES (1, PRICE_TYPE.SURCHARGE, TIMESTAMP '2026-01-01 0:0:0', 'Grab shipping', 0.05, 1),
       (2, PRICE_TYPE.SURCHARGE, TIMESTAMP '2026-01-01 0:0:0', 'Food panda shipping', 0.07, 1),
       (3, PRICE_TYPE.SURCHARGE, TIMESTAMP '2026-01-01 0:0:0', 'Lalamove shipping', 0.10, 1),
       (4, PRICE_TYPE.SURCHARGE, TIMESTAMP '2026-01-01 0:0:0', 'Shopee food shipping', 0.05, 1);

INSERT INTO PRICE_COMPONENT (MEMBERSHIP_ID, PRICE_TYPE, FROM_DATE, DESCRIPTION, PERCENTAGE, CREATED_BY_ID)
VALUES (1, PRICE_TYPE.DISCOUNT, TIMESTAMP '2026-01-01 0:0:0', 'VIP 5% discount', 0.05, 1),
       (2, PRICE_TYPE.DISCOUNT, TIMESTAMP '2026-01-01 0:0:0', 'VVIP 10% discount', 0.10, 1);

