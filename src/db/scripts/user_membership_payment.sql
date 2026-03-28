-- Queries
-- Check the membership for the register member is active or expired
CREATE VIEW membership_status_list AS
SELECT
    m.id AS Member_ID,
    m.username,
    MAX(sub.thru_date) AS Latest_Expiry,
    CASE
        WHEN MAX(sub.thru_date) < CURRENT_DATE THEN 'Expired'
        ELSE 'Active'
    END AS Subscription_Status
FROM member m
JOIN monthly_subscription sub ON m.id = sub.member_id
GROUP BY m.id, m.username;

-- Queries
-- check the nearby expired membership subscription of each member
-- (will check the subscription data that nearby the expired date one week)
CREATE VIEW VW_UPCOMING_EXPIRATIONS AS
SELECT
    m.username,
    m.email,
    sub.thru_date
FROM member m
JOIN monthly_subscription sub ON m.id = sub.member_id
WHERE sub.thru_date BETWEEN CURRENT_DATE  AND (CURRENT_DATE + INTERVAL '7' DAY);

--PROCEDURE
CREATE OR REPLACE PROCEDURE


-- Trigger
-- This trigger is one of the busness logic inside the system , one member address just can have one default address
-- Why using the compound trigger is bc Mutating-Table Error .
CREATE OR REPLACE TRIGGER TRG_SET_Default_Address
FOR INSERT OR UPDATE ON MEMBER_ADDRESS
COMPOUND TRIGGER

    TYPE t_m_ids IS TABLE OF MEMBER_ADDRESS.MEMBER_ID%TYPE;
    v_m_ids t_m_ids:= t_m_ids();
    TYPE t_a_ids IS TABLE OF MEMBER_ADDRESS.ADDRESS_ID%TYPE;
    v_a_ids t_a_ids := t_a_ids();

    AFTER EACH ROW IS
    BEGIN
        IF :NEW.IS_PRIMARY = TRUE THEN
            v_m_ids.EXTEND;
            v_a_ids.EXTEND;
            v_m_ids(v_m_ids.LAST) := :NEW.MEMBER_ID;
            v_a_ids(v_a_ids.LAST) := :NEW.ADDRESS_ID;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        IF v_m_ids.COUNT > 0 THEN
            FOR i IN 1 .. v_m_ids.COUNT LOOP
                UPDATE MEMBER_ADDRESS
                SET IS_PRIMARY = 0
                WHERE MEMBER_ID = v_m_ids(i)
                  AND ADDRESS_ID <> v_a_ids(i)
                  AND IS_PRIMARY = 1;
            END LOOP;
        END IF;

        v_m_ids.DELETE;
        v_a_ids.DELETE;
    END AFTER STATEMENT;

END;

--REPORT
CREATE OR REPLACE PROCEDURE yearly_membership_subscription_report (v_report_date IN DATE) IS
    v_target_year     NUMBER := EXTRACT(YEAR FROM v_report_date);
    v_membership_id   MEMBERSHIP.ID%TYPE;
    v_membership_name MEMBERSHIP.NAME%TYPE;
    v_subtotal_qty    NUMBER;
    v_subtotal_rev    NUMBER;
    v_grand_total_qty NUMBER := 0;
    v_grand_total_rev NUMBER := 0;
    v_line_width      CONSTANT NUMBER := 65;

    CURSOR memTypeCursor IS
        SELECT ID, NAME FROM MEMBERSHIP ORDER BY ID;
    CURSOR subCursor IS
        SELECT TO_CHAR(p.paid_at, 'MM') AS pay_month, COUNT(s.id) AS qty, SUM(p.amount) AS revenue
        FROM monthly_subscription s
        JOIN payment p ON s.payment_id = p.id
        WHERE s.membership_id = v_membership_id AND EXTRACT(YEAR FROM p.paid_at) = v_target_year
        GROUP BY TO_CHAR(p.paid_at, 'MM') ORDER BY pay_month;

    subRec subCursor%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE('|' || LPAD(' ', 11) || 'YEARLY MEMBERSHIP SUBSCRIPTION REPORT - ' || v_target_year || LPAD(' ', 8) || '|');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));

    OPEN memTypeCursor;
    LOOP
        FETCH memTypeCursor INTO v_membership_id, v_membership_name;
        EXIT WHEN memTypeCursor%NOTFOUND;

        v_subtotal_qty := 0;
        v_subtotal_rev := 0;

        DBMS_OUTPUT.PUT_LINE('MEMBERSHIP TYPE: ' || v_membership_name);
        DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));
        DBMS_OUTPUT.PUT_LINE(RPAD('MONTH', 20) || RPAD('QUANTITY', 20) || LPAD('REVENUE', 25));
        DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));

        OPEN subCursor;
        LOOP
            FETCH subCursor INTO subRec;
            EXIT WHEN subCursor%NOTFOUND;

            DBMS_OUTPUT.PUT_LINE(
                RPAD(subRec.pay_month, 20) ||
                RPAD(subRec.qty, 20) ||
                LPAD(TO_CHAR(subRec.revenue, '$99,990.00'), 25)
            );

            v_subtotal_qty := v_subtotal_qty + subRec.qty;
            v_subtotal_rev := v_subtotal_rev + subRec.revenue;
        END LOOP;

        IF subCursor%ROWCOUNT > 0 THEN
            DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));
            DBMS_OUTPUT.PUT_LINE(RPAD('SUB TOTAL (' || v_membership_name || ')', 20) ||
                                 RPAD(v_subtotal_qty, 20) ||
                                 LPAD(TO_CHAR(v_subtotal_rev, '$99,990.00'), 25));
        ELSE
            DBMS_OUTPUT.PUT_LINE('** NO DATA FOUND **');
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD('.', v_line_width, '.'));

        v_grand_total_qty := v_grand_total_qty + v_subtotal_qty;
        v_grand_total_rev := v_grand_total_rev + v_subtotal_rev;

        CLOSE subCursor;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(RPAD('GRAND TOTAL QUANTITY', 40) || ' : ' || LPAD(v_grand_total_qty, 20));
    DBMS_OUTPUT.PUT_LINE(RPAD('GRAND TOTAL REVENUE', 40) || ' : ' || LPAD(TO_CHAR(v_grand_total_rev, '$99,990.00'), 20));
    DBMS_OUTPUT.PUT_LINE(RPAD('TOTAL CATEGORIES', 40) || ' : ' || LPAD(memTypeCursor%ROWCOUNT, 20));
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', 23) || '*** END OF REPORT ***');
    CLOSE memTypeCursor;
END;





