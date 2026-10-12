WITH catalog_agg AS (
    SELECT r.r_reason_id AS reason_id,
           d.d_date AS return_date,
           CAST(NULL AS integer) AS hour,
           SUM(cr.cr_net_loss) AS total_net_loss,
           'catalog' AS source
    FROM catalog_returns cr
    RIGHT OUTER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE (d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31' OR d.d_date IS NULL)
    GROUP BY r.r_reason_id, d.d_date
),
web_agg AS (
    SELECT r.r_reason_id AS reason_id,
           d.d_date AS return_date,
           CAST(NULL AS integer) AS hour,
           SUM(wr.wr_net_loss) AS total_net_loss,
           'web' AS source
    FROM web_returns wr
    RIGHT OUTER JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE (d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31' OR d.d_date IS NULL)
    GROUP BY r.r_reason_id, d.d_date
),
time_reason AS (
    SELECT r.r_reason_id AS reason_id,
           CAST(NULL AS date) AS return_date,
           t.t_hour AS hour,
           CAST(NULL AS decimal(7,2)) AS total_net_loss,
           'time_reason' AS source
    FROM (SELECT r_reason_id, r_reason_sk FROM reason WHERE r_reason_desc LIKE '%size%') r
    CROSS JOIN (SELECT t_time_sk, t_hour FROM time_dim WHERE t_hour BETWEEN 9 AND 10) t
)
SELECT reason_id, return_date, hour, total_net_loss, source
FROM catalog_agg
UNION ALL
SELECT reason_id, return_date, hour, total_net_loss, source
FROM web_agg
UNION ALL
SELECT reason_id, return_date, hour, total_net_loss, source
FROM time_reason
ORDER BY source, reason_id, return_date, hour
LIMIT 100
