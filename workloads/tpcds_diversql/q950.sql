WITH sr_agg AS (
    SELECT sr_returned_date_sk,
           COUNT(*) AS cnt_returns,
           SUM(sr_return_amt) AS total_return_amt,
           AVG(sr_fee) AS avg_fee,
           SUM(CASE WHEN sr_reversed_charge > 0 THEN sr_reversed_charge ELSE 0 END) AS total_rev_charge
    FROM store_returns
    WHERE sr_fee > 5.00
      AND sr_reversed_charge < 500
      AND sr_return_quantity >= 1
      AND sr_return_amt > 10.00
      AND sr_return_tax >= 0
    GROUP BY sr_returned_date_sk
),
date_filtered AS (
    SELECT d_date_sk,
           d_year,
           d_fy_week_seq,
           d_fy_quarter_seq,
           d_weekend
    FROM date_dim
    WHERE d_year = 2001
      AND d_fy_quarter_seq = 5
      AND d_fy_week_seq BETWEEN 6 AND 10
      AND d_weekend = 'N'
      AND d_holiday = 'N'
),
web_filtered AS (
    SELECT web_site_sk,
           web_name,
           web_class,
           web_manager,
           web_open_date_sk,
           web_close_date_sk,
           web_gmt_offset
    FROM web_site
    WHERE web_class = 'Unknown'
      AND web_manager IN ('Dwight Aaron','Jason Silva')
      AND web_gmt_offset BETWEEN -5.00 AND 0.00
      AND web_tax_percentage < 5.00
),
union_keys AS (
    SELECT d_date_sk AS key FROM date_filtered
    UNION
    SELECT web_open_date_sk AS key FROM web_filtered
),
date_not_in_web AS (
    SELECT d_date_sk FROM date_filtered
    EXCEPT
    SELECT web_open_date_sk FROM web_filtered
),
full_join AS (
    SELECT
        COALESCE(sr.sr_returned_date_sk, ws.d_date_sk) AS date_key,
        sr.cnt_returns,
        sr.total_return_amt,
        sr.avg_fee,
        sr.total_rev_charge,
        ws.web_name,
        ws.web_class,
        ws.web_manager
    FROM sr_agg sr
    FULL OUTER JOIN (
        SELECT w.web_name,
               w.web_class,
               w.web_manager,
               d.d_date_sk
        FROM web_filtered w
        JOIN date_filtered d ON w.web_open_date_sk = d.d_date_sk
    ) ws
    ON sr.sr_returned_date_sk = ws.d_date_sk
)
SELECT
    COALESCE(fj.web_class, 'NoWeb') AS web_class,
    COALESCE(fj.web_manager, 'NoManager') AS web_manager,
    SUM(COALESCE(fj.cnt_returns,0)) AS total_returns,
    SUM(COALESCE(fj.total_return_amt,0)) AS sum_return_amount,
    AVG(COALESCE(fj.avg_fee,0)) AS avg_fee,
    COUNT(DISTINCT fj.date_key) AS distinct_date_cnt,
    MIN(fj.total_rev_charge) AS min_rev_charge,
    MAX(fj.total_rev_charge) AS max_rev_charge,
    (SELECT COUNT(*) FROM date_not_in_web) AS missing_date_count
FROM full_join fj
WHERE fj.date_key IN (SELECT key FROM union_keys)
  AND EXISTS (
        SELECT 1 FROM date_dim d
        WHERE d.d_date_sk = fj.date_key
          AND d.d_dow = 2  -- Monday
    )
GROUP BY
    COALESCE(fj.web_class, 'NoWeb'),
    COALESCE(fj.web_manager, 'NoManager')
ORDER BY sum_return_amount DESC
LIMIT 100
