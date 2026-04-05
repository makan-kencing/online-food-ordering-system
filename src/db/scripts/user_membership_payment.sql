-- Queries -1
-- Check the membership for the register member is active or expired
CREATE  VIEW membership_status_list AS
SELECT
    m.id AS Member_ID,
    m.username,
    MAX(sub.thru_date) AS Latest_Expiry,
    CASE
        WHEN MAX(sub.thru_date) < SYSDATE THEN 'Expired'
        ELSE 'Active'
    END AS Subscription_Status
FROM member m
JOIN monthly_subscription sub ON m.id = sub.member_id
GROUP BY m.id, m.username;

SELECT Member_ID, username, Latest_Expiry, Subscription_Status
FROM membership_status_list
ORDER BY Subscription_Status ASC, Latest_Expiry DESC;


-- Queries -2
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

SELECT
    username,
    email,
    TO_CHAR(thru_date, 'YYYY-MM-DD') AS expiry_date
FROM VW_UPCOMING_EXPIRATIONS
UNION ALL
SELECT
    'No upcoming expirations' AS username,
    'N/A' AS email,
    'N/A' AS expiry_date
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM VW_UPCOMING_EXPIRATIONS);

SELECT username, email, TO_CHAR(thru_date, 'YYYY-MM-DD') AS expiry_date
FROM VW_UPCOMING_EXPIRATIONS
ORDER BY thru_date ASC;

--PROCEDURE -1 : proc_subscribe_member
CREATE OR REPLACE PROCEDURE proc_subscribe_member (
    p_member_id      IN member.id%TYPE,
    p_membership_id  IN membership.id%TYPE,
    p_amount         IN NUMBER,
    p_pay_method_id  IN NUMBER
) AS
    v_unit_price      NUMBER;
    v_months_to_add   NUMBER;
    v_payment_id      NUMBER;
    v_sub_id          NUMBER;
    v_generated_ref   VARCHAR2(30);
    v_start_date      DATE := SYSDATE;
BEGIN
    BEGIN
        SELECT price INTO v_unit_price
        FROM membership
        WHERE id = p_membership_id;

        IF p_amount <= 0 OR MOD(p_amount, v_unit_price) != 0 THEN
             RAISE_APPLICATION_ERROR(-20001, 'Invalid amount. Must be ' || v_unit_price || ' or multiple of ' || v_unit_price);
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Membership ID not found.');
    END;

    v_months_to_add := p_amount / v_unit_price;

    FOR i IN 1..v_months_to_add LOOP

        INSERT INTO payment (
            amount,
            paid_at,
            payment_method_id,
            REF_NO,
            PAYMENT_METHOD_DATA
        ) VALUES (
            v_unit_price,
            CURRENT_TIMESTAMP,
            p_pay_method_id,
            'TEMP',
            '{"status": "AUTO_SPLIT", "month_index": ' || i || '}'
        )
        RETURNING id, ref_no INTO v_payment_id, v_generated_ref;

        INSERT INTO monthly_subscription (
            membership_id,
            member_id,
            from_date,
            thru_date
        ) VALUES (
            p_membership_id,
            p_member_id,
            ADD_MONTHS(v_start_date, i - 1),
            ADD_MONTHS(v_start_date, i)
        )
        RETURNING id INTO v_sub_id;

        INSERT INTO subscription_payment (
            monthly_subscription_id,
            payment_id
        ) VALUES (
            v_sub_id,
            v_payment_id
        );

        DBMS_OUTPUT.PUT_LINE('Processed Month ' || i || ': Sub_ID ' || v_sub_id || ', Pay_ID ' || v_payment_id);
    END LOOP;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('-----------------------------------');
    DBMS_OUTPUT.PUT_LINE('Successfully linked via subscription_payment');
    DBMS_OUTPUT.PUT_LINE('Total months processed: ' || v_months_to_add);
    DBMS_OUTPUT.PUT_LINE('-----------------------------------');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

--EXEC proc_subscribe_member(40,2, 98.00, 1);

--PROCEDURE -2 :proc_upgrade_membership
CREATE OR REPLACE PROCEDURE proc_upgrade_membership (
    p_member_id      IN member.id%TYPE,
    p_new_membership IN NUMBER,
    p_pay_amount     IN NUMBER,
    p_pay_method_id  IN NUMBER
) AS
    v_old_sub_id      NUMBER;
    v_old_expiry      DATE;
    v_payment_id      NUMBER;
BEGIN
    SELECT id, thru_date
    INTO v_old_sub_id, v_old_expiry
    FROM monthly_subscription
    WHERE member_id = p_member_id
      AND thru_date > CURRENT_TIMESTAMP
      AND ROWNUM = 1;

    INSERT INTO payment (
        amount, paid_at, payment_method_id, ref_no, payment_method_data
    ) VALUES (
        p_pay_amount, CURRENT_TIMESTAMP, p_pay_method_id, 'UPGRADE',
        '{"action": "UPGRADE", "from_member_id": ' || p_member_id || '}'
    )
    RETURNING id INTO v_payment_id;

    UPDATE monthly_subscription
    SET thru_date = CURRENT_TIMESTAMP
    WHERE id = v_old_sub_id;

    INSERT INTO monthly_subscription (
        membership_id,
        member_id,
        from_date,
        thru_date,
        payment_id
    ) VALUES (
        p_new_membership,
        p_member_id,
        CURRENT_TIMESTAMP,
        ADD_MONTHS(v_old_expiry, 1),
        v_payment_id
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('--- Upgrade & Record Saved ---');
    DBMS_OUTPUT.PUT_LINE('Old sub terminated at: ' || TO_CHAR(CURRENT_TIMESTAMP, 'HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('New sub expires at: ' || TO_CHAR(ADD_MONTHS(v_old_expiry, 1), 'YYYY-MM-DD'));

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20030, 'Error: No active subscription to upgrade.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
--EXEC proc_upgrade_membership(5, 2, 5.00, 1);

-- Trigger -1
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

--Trigger -2 : trg_check_sub_overlap
CREATE OR REPLACE TRIGGER trg_check_sub_overlap
BEFORE INSERT ON monthly_subscription
FOR EACH ROW
DECLARE
    v_current_expiry DATE;
    v_months_bought  NUMBER;
BEGIN
    SELECT MAX(thru_date)
    INTO v_current_expiry
    FROM monthly_subscription
    WHERE member_id = :NEW.member_id;

    IF v_current_expiry IS NOT NULL AND v_current_expiry > :NEW.from_date THEN
        v_months_bought := ROUND(MONTHS_BETWEEN(:NEW.thru_date, :NEW.from_date));
        :NEW.from_date := v_current_expiry;
        :NEW.thru_date := ADD_MONTHS(v_current_expiry, v_months_bought);

    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;
END;

-- SQL> SET LINESIZE 150;
-- SQL> SET PAGESIZE 400;
--SET SERVEROUTPUT ON
--REPORT -1 ： proc_new_member_conversion_analysis
CREATE OR REPLACE PROCEDURE proc_new_member_conversion_analysis (p_report_year IN NUMBER) IS
    v_curr_year         NUMBER := EXTRACT(YEAR FROM SYSDATE);
    v_year              NUMBER := p_report_year;
    v_m_conversion      NUMBER;
    v_grand_new_join    NUMBER := 0;
    v_grand_new_sub     NUMBER := 0;
    v_grand_total_rev   NUMBER := 0;
    v_line_width        CONSTANT NUMBER := 145;
    v_month_id          NUMBER;

    v_prepaid_count     NUMBER;
    v_prepaid_rev       NUMBER;
    v_remark            VARCHAR2(100);

    CURSOR cur_months IS
        SELECT LEVEL as month_num FROM DUAL CONNECT BY LEVEL <= 12;

    CURSOR cur_monthly_stats (p_y NUMBER, p_m NUMBER) IS
        SELECT
            (SELECT COUNT(*) FROM member
             WHERE EXTRACT(YEAR FROM created_at) = p_y
               AND EXTRACT(MONTH FROM created_at) = p_m) as new_join,

            (SELECT COUNT(DISTINCT s.member_id)
             FROM monthly_subscription s
             JOIN member m ON s.member_id = m.id
             WHERE EXTRACT(YEAR FROM s.from_date) = p_y
               AND EXTRACT(MONTH FROM s.from_date) = p_m
               AND EXTRACT(YEAR FROM m.created_at) = p_y
               AND EXTRACT(MONTH FROM m.created_at) = p_m) as new_subs,

            (SELECT NVL(SUM(daily_first_val), 0)
             FROM (
                 SELECT MAX(p.amount) as daily_first_val
                 FROM payment p
                 JOIN subscription_payment sp ON p.id = sp.payment_id
                 JOIN monthly_subscription s  ON sp.monthly_subscription_id = s.id
                 JOIN member m               ON s.member_id = m.id
                 WHERE EXTRACT(YEAR FROM s.from_date) = p_y
                   AND EXTRACT(MONTH FROM s.from_date) = p_m
                   AND EXTRACT(YEAR FROM m.created_at) = p_y
                 GROUP BY m.id, TRUNC(s.from_date)
             )) as subtotal
        FROM DUAL;

    rec_stats cur_monthly_stats%ROWTYPE;

BEGIN
    IF v_year > v_curr_year THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: Future year not allowed.');
    END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE('|' || LPAD('ANNUAL NEW MEMBER CONVERSION REPORT: ' || v_year, 85) || LPAD('|', 59));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));

    DBMS_OUTPUT.PUT_LINE(
        RPAD('MONTH', 15) ||
        RPAD('NEW JOIN (FREE)', 20) ||
        RPAD('NEW SUBS (PAID)', 20) ||
        RPAD('NEW MEMBER REV', 20) ||
        RPAD('REMARK (PREPAID SOURCE)', 35) ||
        'CONVERSION'
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));

    OPEN cur_months;
    LOOP
        FETCH cur_months INTO v_month_id;
        EXIT WHEN cur_months%NOTFOUND;

        OPEN cur_monthly_stats(v_year, v_month_id);
        FETCH cur_monthly_stats INTO rec_stats;
        CLOSE cur_monthly_stats;

        SELECT
            COUNT(DISTINCT mid),
            NVL(SUM(amt), 0)
        INTO v_prepaid_count, v_prepaid_rev
        FROM (
            SELECT m.id as mid, MAX(p.amount) as amt
            FROM payment p
            JOIN subscription_payment sp ON p.id = sp.payment_id
            JOIN monthly_subscription s  ON sp.monthly_subscription_id = s.id
            JOIN member m                ON s.member_id = m.id
            WHERE EXTRACT(YEAR FROM s.from_date) = v_year
              AND EXTRACT(MONTH FROM s.from_date) = v_month_id
              AND EXTRACT(YEAR FROM m.created_at) = v_year
              AND EXTRACT(MONTH FROM m.created_at) < v_month_id
            GROUP BY m.id, TRUNC(s.from_date)
        );

       IF v_prepaid_rev > 0 THEN
            v_remark := TO_CHAR(v_prepaid_rev, '9,990.00');
        ELSE
            v_remark := LPAD('-', 9);
        END IF;

        IF rec_stats.new_join > 0 THEN
            v_m_conversion := (rec_stats.new_subs / rec_stats.new_join) * 100;
        ELSE
            v_m_conversion := 0;
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(TO_CHAR(TO_DATE(v_month_id, 'MM'), 'Month'), 15) ||
            RPAD(rec_stats.new_join, 18) ||
            RPAD(rec_stats.new_subs, 18) ||
            RPAD(LPAD(TO_CHAR(rec_stats.subtotal, '9,990.00'), 10), 20) ||
            RPAD(v_remark, 25) ||
            LPAD(TO_CHAR(v_m_conversion, '990.99'), 8) || '%'
        );

        v_grand_new_join  := v_grand_new_join + rec_stats.new_join;
        v_grand_new_sub   := v_grand_new_sub + rec_stats.new_subs;
        v_grand_total_rev := v_grand_total_rev + rec_stats.subtotal;
    END LOOP;
    CLOSE cur_months;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE('YEARLY GRAND SUMMARY (' || v_year || '):');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));
    DBMS_OUTPUT.PUT_LINE(RPAD('1. Total New Members (Free Join)', 55) || ': ' || LPAD(v_grand_new_join, 20));
    DBMS_OUTPUT.PUT_LINE(RPAD('2. Total New Subscriptions (Paid)', 55) || ': ' || LPAD(v_grand_new_sub, 20));
    DBMS_OUTPUT.PUT_LINE(RPAD('3. Grand Total Revenue from New Mems', 55) || ': ' || LPAD('RM ' || TO_CHAR(v_grand_total_rev, '999,990.00'), 20));

    IF v_grand_new_join > 0 THEN
        DBMS_OUTPUT.PUT_LINE(RPAD('4. Overall Conversion Rate', 55) || ': ' || LPAD(TO_CHAR((v_grand_new_sub / v_grand_new_join) * 100, '990.99') || '%', 20));
    ELSE
        DBMS_OUTPUT.PUT_LINE(RPAD('4. Overall Conversion Rate', 55) || ': ' || LPAD('0.00%', 20));
    END IF;
    DBMS_OUTPUT.PUT_LINE(RPAD('=', v_line_width, '='));
END;
/

--exec proc_new_member_conversion_analysis(2026)

--REPORT -2 ：monthly_payment_method_using_summary_report
 CREATE OR REPLACE PROCEDURE monthly_payment_method_summary_report (
        p_year  IN NUMBER,
        p_month IN NUMBER) IS

    v_curr_year       NUMBER := EXTRACT(YEAR FROM SYSDATE);
    v_curr_month      NUMBER := EXTRACT(MONTH FROM SYSDATE);

    v_target_year     NUMBER :=  p_year;
    v_target_month    NUMBER := p_month;
    v_pay_method_id   PAYMENT_METHOD.ID%TYPE;
    v_pay_method_name PAYMENT_METHOD.NAME%TYPE;

    v_subtotal_qty    NUMBER;
    v_subtotal_rev    NUMBER;
    v_grand_total_qty NUMBER := 0;
    v_grand_total_rev NUMBER := 0;

    v_max_qty         NUMBER := -1;
    v_best_method     VARCHAR2(100) := 'N/A';

    v_line_width      CONSTANT NUMBER := 70;

    CURSOR payMetTypeCursor IS
        SELECT ID, NAME FROM PAYMENT_METHOD ORDER BY ID;

    CURSOR payDetailCursor IS
        SELECT ID, REF_NO, PAID_AT, AMOUNT
        FROM PAYMENT
        WHERE PAYMENT_METHOD_ID = v_pay_method_id
          AND EXTRACT(YEAR FROM PAID_AT) = v_target_year
          AND EXTRACT(MONTH FROM PAID_AT) = v_target_month
        ORDER BY PAID_AT;

    payRec payDetailCursor%ROWTYPE;

BEGIN

    IF v_target_year > v_curr_year THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: The year ' || v_target_year || ' is in the future. Please enter a valid year.');
    END IF;


    IF v_target_month < 1 OR v_target_month > 12 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error: Month must be between 1 and 12.');
    END IF;

    IF v_target_year = v_curr_year AND v_target_month > v_curr_month THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error: Data for ' || v_target_year || '-' || v_target_month || ' does not exist yet.');
    END IF;
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE('|' || LPAD(' ', 12) || 'MONTHLY PAYMENT METHOD SUMMARY: ' || v_target_year || '-' || LPAD(v_target_month, 2, '0') || LPAD(' ', 12) || '|');
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));

    OPEN payMetTypeCursor;
    LOOP
        FETCH payMetTypeCursor INTO v_pay_method_id, v_pay_method_name;
        EXIT WHEN payMetTypeCursor%NOTFOUND;

        v_subtotal_qty := 0;
        v_subtotal_rev := 0;

        DBMS_OUTPUT.PUT_LINE('METHOD: ' || v_pay_method_name);
        DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));
        DBMS_OUTPUT.PUT_LINE(RPAD('PAY_ID', 10) || RPAD('REF_NO', 20) || RPAD('PAID_AT', 20) || LPAD('AMOUNT', 20));
        DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));

        OPEN payDetailCursor;
        LOOP
            FETCH payDetailCursor INTO payRec;
            EXIT WHEN payDetailCursor%NOTFOUND;

            DBMS_OUTPUT.PUT_LINE(
                RPAD(payRec.ID, 10) ||
                RPAD(payRec.REF_NO, 20) ||
                RPAD(TO_CHAR(payRec.PAID_AT, 'YYYY-MM-DD'), 20) ||
                LPAD(TO_CHAR(payRec.AMOUNT, '$99,990.00'), 20)
            );

            v_subtotal_qty := v_subtotal_qty + 1;
            v_subtotal_rev := v_subtotal_rev + payRec.AMOUNT;
        END LOOP;

        IF v_subtotal_qty > v_max_qty THEN
            v_max_qty := v_subtotal_qty;
            v_best_method := v_pay_method_name;
        END IF;

        IF payDetailCursor%ROWCOUNT > 0 THEN
            DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));
            DBMS_OUTPUT.PUT_LINE(RPAD('SUB TOTAL (' || v_pay_method_name || ')', 30) ||
                                 'COUNT: ' || RPAD(v_subtotal_qty, 13) ||
                                 LPAD(TO_CHAR(v_subtotal_rev, '$99,990.00'), 20));
        ELSE
            DBMS_OUTPUT.PUT_LINE('** NO TRANSACTIONS THIS MONTH **');
        END IF;
        DBMS_OUTPUT.PUT_LINE(CHR(5));
        v_grand_total_qty := v_grand_total_qty + v_subtotal_qty;
        v_grand_total_rev := v_grand_total_rev + v_subtotal_rev;
        DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));
        CLOSE payDetailCursor;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));

    DBMS_OUTPUT.PUT_LINE(RPAD('MOST USED METHOD', 45) || ' : ' || LPAD(v_best_method || ' ' || v_max_qty || ' times', 22));
    DBMS_OUTPUT.PUT_LINE(RPAD('-', v_line_width, '-'));

    DBMS_OUTPUT.PUT_LINE(RPAD('GRAND TOTAL TRANSACTIONS', 45) || ' : ' || LPAD(v_grand_total_qty, 22));
    DBMS_OUTPUT.PUT_LINE(RPAD('GRAND TOTAL REVENUE', 45) || ' : ' || LPAD(TO_CHAR(v_grand_total_rev, '$99,990.00'), 22));
    DBMS_OUTPUT.PUT_LINE(LPAD('=', v_line_width, '='));
    DBMS_OUTPUT.PUT_LINE(LPAD(' ', 50) || '*** END OF REPORT ***');

    CLOSE payMetTypeCursor;
END;

--EXEC monthly_payment_method_summary_report(2029, 1);
