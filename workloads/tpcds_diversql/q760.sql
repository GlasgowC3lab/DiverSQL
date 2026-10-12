WITH high_refund AS (
        SELECT DISTINCT sr_ticket_number
        FROM store_returns
        WHERE sr_refunded_cash > 100
    ),
    high_ship AS (
        SELECT DISTINCT sr_ticket_number
        FROM store_returns
        WHERE sr_return_ship_cost > 200
    ),
    common_tickets AS (
        SELECT sr_ticket_number FROM high_refund
        INTERSECT
        SELECT sr_ticket_number FROM high_ship
    )
SELECT
    r.r_reason_desc,
    COUNT(DISTINCT sr.sr_ticket_number) AS ticket_cnt,
    SUM(sr.sr_net_loss) AS total_net_loss,
    REGEXP_EXTRACT(r.r_reason_desc, '(\\w+) purchase') AS extracted_word,
    CONCAT('Reason: ', r.r_reason_id) AS reason_label
FROM store_returns sr
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr.sr_ticket_number IN (SELECT sr_ticket_number FROM common_tickets)
  AND REGEXP_LIKE(r.r_reason_desc, 'damaged|unauthoized')
  AND r.r_reason_desc LIKE '%product%'
GROUP BY
    r.r_reason_desc,
    r.r_reason_id,
    REGEXP_EXTRACT(r.r_reason_desc, '(\\w+) purchase'),
    CONCAT('Reason: ', r.r_reason_id)
HAVING COUNT(DISTINCT sr.sr_ticket_number) > 5
ORDER BY total_net_loss DESC
LIMIT 100
