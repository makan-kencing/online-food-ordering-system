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