WITH
  base AS (
    SELECT
      wp.wp_web_page_sk,
      wp.wp_url,
      wp.wp_type,
      wp.wp_char_count,
      wp.wp_max_ad_count,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_net_loss,
      wr.wr_refunded_hdemo_sk,
      wr.wr_returned_date_sk
    FROM web_page AS wp
    JOIN web_returns AS wr
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_max_ad_count > 0
      AND wp.wp_char_count BETWEEN 1000 AND 6000
      AND wr.wr_return_amt > 10
      AND wr.wr_return_quantity >= 1
      AND EXISTS (
        SELECT 1
        FROM web_returns AS wr2
        WHERE wr2.wr_returned_date_sk = wr.wr_returned_date_sk
          AND wr2.wr_return_amt > 100
      )
  ),
  agg AS (
    SELECT
      wp_type,
      wp_max_ad_count,
      SUM(wr_return_amt) AS total_return_amt,
      SUM(wr_net_loss) AS total_net_loss,
      COUNT(*) AS cnt_returns
    FROM base
    GROUP BY GROUPING SETS (
      (wp_type, wp_max_ad_count),
      (wp_type),
      ()
    )
  )
SELECT
  agg.wp_type,
  agg.wp_max_ad_count,
  agg.total_return_amt,
  agg.total_net_loss,
  agg.cnt_returns,
  (
    SELECT AVG(b3.wr_return_amt)
    FROM base b3
    WHERE b3.wp_type = agg.wp_type
  ) AS avg_return_amt_per_type,
  RANK() OVER (PARTITION BY agg.wp_type ORDER BY agg.total_return_amt DESC) AS type_rank,
  CASE
    WHEN agg.total_return_amt > (
      SELECT SUM(wr_return_amt)
      FROM base b4
      WHERE b4.wp_max_ad_count = agg.wp_max_ad_count
    ) THEN 'Above'
    ELSE 'Below'
  END AS compared_to_same_ad_count_total
FROM agg
WHERE (agg.total_return_amt > 500 OR agg.total_net_loss > 100)
  AND agg.wp_type IS NOT NULL
ORDER BY agg.total_return_amt DESC, agg.wp_type
LIMIT 100
