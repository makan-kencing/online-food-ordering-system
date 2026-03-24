--Queries
-- Check the membership for the register member is active or expired
CREATE VIEW membership_status_list AS
SELECT
    ms.id AS Membership_ID,
    m.id AS Member_ID,
    ms.name AS Membership_Type,
    sub.thru_date,
    CASE
        WHEN sub.thru_date < CURRENT_DATE THEN 'Expired'
        ELSE 'Active'
    END AS Subscription_Status
FROM monthly_subscription sub
JOIN member m ON sub.member_id = m.id
JOIN membership ms ON sub.membership_id = ms.id;

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

