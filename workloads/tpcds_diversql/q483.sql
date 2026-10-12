WITH promotions_started AS (
    SELECT p.p_promo_sk,
           p.p_promo_id,
           p.p_start_date_sk,
           d.d_date
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_current_month = 'Y'
),
promotions_ended AS (
    SELECT p.p_promo_sk,
           p.p_promo_id,
           p.p_end_date_sk,
           d.d_date
    FROM promotion p
    JOIN date_dim d ON p.p_end_date_sk = d.d_date_sk
    WHERE d.d_current_month = 'Y'
),
started_without_end AS (
    SELECT p.p_promo_sk,
           p.p_promo_id,
           p.p_start_date_sk,
           p.d_date
    FROM promotions_started p
    EXCEPT
    SELECT e.p_promo_sk,
           e.p_promo_id,
           e.p_end_date_sk,
           e.d_date
    FROM promotions_ended e
),
returns_by_reason AS (
    SELECT r.r_reason_sk,
           r.r_reason_desc,
           wr.wr_returned_date_sk,
           d_ret.d_date
    FROM reason r
    JOIN web_returns wr ON r.r_reason_sk = wr.wr_reason_sk
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_current_month = 'Y'
)
SELECT
    COALESCE(s.p_promo_id, CAST('UNKNOWN' AS varchar)) AS promo_id,
    COALESCE(r.r_reason_desc, CAST('No Reason' AS varchar)) AS reason_desc,
    s.d_date AS promo_date,
    r.d_date AS return_date,
    (
        SELECT COUNT(*)
        FROM web_returns wr2
        WHERE wr2.wr_reason_sk = r.r_reason_sk
    ) AS total_returns_for_reason
FROM started_without_end s
FULL OUTER JOIN returns_by_reason r
    ON s.d_date = r.d_date
ORDER BY promo_id ASC NULLS LAST,
         reason_desc ASC
OFFSET 0
LIMIT 100
