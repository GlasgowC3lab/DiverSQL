WITH
  intersect_pages AS (
    SELECT wp_web_page_sk FROM web_page WHERE wp_autogen_flag = 'N'
    INTERSECT
    SELECT wr_web_page_sk FROM web_returns WHERE wr_return_quantity > 0
  ),
  agg_returns AS (
    SELECT
      wr_web_page_sk,
      SUM(wr_return_amt) AS sum_return_amt,
      COUNT(*) AS cnt_returns,
      CASE WHEN SUM(wr_return_amt) > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level
    FROM web_returns
    WHERE wr_returned_date_sk IN (
      SELECT d_date_sk FROM date_dim
      WHERE d_year = 2001
        AND d_month_seq BETWEEN 1 AND 12
    )
    GROUP BY wr_web_page_sk
  ),
  joined_data AS (
    SELECT
      ar.wr_web_page_sk,
      ar.sum_return_amt,
      ar.cnt_returns,
      ar.return_level,
      wp.wp_customer_sk,
      wp.wp_url,
      d.d_day_name,
      p.p_promo_name,
      (
        SELECT SUM(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_returning_customer_sk = wp.wp_customer_sk
      ) AS cust_total_return_amt
    FROM agg_returns ar
    JOIN web_page wp ON ar.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE EXISTS (
      SELECT 1 FROM intersect_pages ip
      WHERE ip.wp_web_page_sk = ar.wr_web_page_sk
    )
  )
SELECT
  jd.wr_web_page_sk,
  jd.wp_url,
  jd.sum_return_amt,
  jd.cnt_returns,
  jd.return_level,
  jd.cust_total_return_amt,
  jd.p_promo_name,
  jd.d_day_name
FROM joined_data jd
WHERE jd.sum_return_amt > 500
  AND jd.cnt_returns >= 2
  AND jd.p_promo_name IS NOT NULL
ORDER BY jd.sum_return_amt DESC, jd.wr_web_page_sk
OFFSET 0 LIMIT 100
