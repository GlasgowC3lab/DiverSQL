WITH combined_returns AS (
  SELECT
    'store' AS channel,
    s.s_state AS region,
    cd.cd_education_status AS education_status,
    sr.sr_return_quantity AS return_qty,
    sr.sr_net_loss AS net_loss,
    sr.sr_return_amt AS return_amount
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
    AND cd.cd_education_status = 'College'
    AND s.s_state IN ('CA', 'TX', 'NY')
  UNION ALL
  SELECT
    'web' AS channel,
    wp.wp_type AS region,
    cd.cd_education_status AS education_status,
    wr.wr_return_quantity AS return_qty,
    wr.wr_net_loss AS net_loss,
    wr.wr_return_amt AS return_amount
  FROM web_returns wr
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
    AND cd.cd_education_status = 'College'
    AND wp.wp_type IN ('Home', 'Search', 'Product')
)
SELECT
  channel,
  region,
  education_status,
  SUM(return_qty) AS total_return_qty,
  SUM(net_loss) AS total_net_loss,
  AVG(return_amount) AS avg_return_amount,
  ROW_NUMBER() OVER (PARTITION BY channel ORDER BY SUM(net_loss) DESC) AS rank_within_channel
FROM combined_returns
GROUP BY channel, region, education_status
HAVING SUM(net_loss) > 0
ORDER BY channel, rank_within_channel
LIMIT 20
