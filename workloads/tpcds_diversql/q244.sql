WITH agg_returns AS (
    SELECT
        wr_web_page_sk,
        wr_returned_time_sk,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(CASE WHEN wr_return_amt > 100 THEN 1 ELSE 0 END) AS high_value_cnt
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2451170 AND 2451200           -- predicate 1
      AND wr_return_quantity > 0                                 -- predicate 2
      AND wr_fee >= 0                                            -- predicate 3
      AND wr_account_credit IS NOT NULL                         -- predicate 4
      AND wr_return_amt_inc_tax IS NOT NULL                     -- predicate 5
    GROUP BY wr_web_page_sk, wr_returned_time_sk
)
SELECT
    wp.wp_web_page_sk,
    wp.wp_url,
    wp.wp_type,
    td.t_hour,
    td.t_minute,
    ar.return_cnt,
    ar.total_return_amt,
    ar.high_value_cnt,
    CASE WHEN ar.total_return_amt > 500 THEN 'HIGH' ELSE 'LOW' END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY wp.wp_type ORDER BY ar.total_return_amt DESC) AS rn_by_type
FROM agg_returns AS ar
JOIN web_page AS wp
    ON ar.wr_web_page_sk = wp.wp_web_page_sk
JOIN time_dim AS td
    ON ar.wr_returned_time_sk = td.t_time_sk
WHERE wp.wp_max_ad_count >= 1                                 -- predicate 6
  AND wp.wp_link_count BETWEEN 5 AND 15                        -- predicate 7
  AND wp.wp_autogen_flag = 'Y'                                 -- predicate 8
  AND td.t_hour BETWEEN 8 AND 18                               -- predicate 9
  AND td.t_minute IN (4, 7, 9, 19)                             -- predicate 10
ORDER BY ar.total_return_amt DESC
LIMIT 100
