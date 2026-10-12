WITH store_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        CONCAT(s.s_city, ', ', s.s_state) AS location,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        MIN(r.r_reason_desc) AS sample_reason_desc,
        s.s_city,
        s.s_state
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE s.s_city LIKE '%town%'
      AND REGEXP_LIKE(r.r_reason_desc, '(damage|lost)')
    GROUP BY s.s_store_sk, s.s_store_id, s.s_city, s.s_state
)
SELECT
    sa.s_store_id,
    sa.location,
    sa.return_cnt,
    sa.total_net_loss,
    REGEXP_EXTRACT(sa.sample_reason_desc, '(\\w+)', 1) AS reason_first_word,
    SUBSTRING(sa.location, 1, 10) AS short_location,
    CASE
        WHEN sa.total_net_loss > (SELECT AVG(sr_net_loss) FROM store_returns) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS loss_flag
FROM store_agg sa
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = sa.s_store_sk
      AND sr2.sr_return_quantity > 5
)
ORDER BY sa.total_net_loss DESC
LIMIT 100
