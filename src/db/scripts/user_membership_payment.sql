--Queries
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

--Queries
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


--Trigger
--This trigger is one of the busness logic inside the system , one member address just can have one default address
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



