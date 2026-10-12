WITH
  filtered_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2000
      AND d_fy_quarter_seq = 4
      AND d_following_holiday = 'N'
  ),
  filtered_returns AS (
    SELECT sr_returned_date_sk,
           sr_hdemo_sk,
           sr_reason_sk,
           sr_return_amt
    FROM store_returns
    WHERE sr_return_amt > 50
  ),
  filtered_sales AS (
    SELECT ws_sold_date_sk,
           ws_web_page_sk,
           ws_bill_hdemo_sk,
           ws_net_profit,
           ws_quantity
    FROM web_sales
    WHERE ws_quantity > 2
  ),
  intersect_dates AS (
    SELECT sr_returned_date_sk AS dsk
    FROM filtered_returns
    INTERSECT
    SELECT d_date_sk
    FROM filtered_dates
  ),
  cc_date_full AS (
    SELECT
      cc.cc_call_center_id,
      cc.cc_name,
      d.d_date_sk,
      d.d_year
    FROM call_center cc
    FULL OUTER JOIN date_dim d
      ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE cc.cc_name IS NOT NULL
       OR d.d_year IS NOT NULL
  )
SELECT
  d.d_year,
  cc.cc_name,
  wp.wp_url,
  r.r_reason_desc,
  SUM(fr.sr_return_amt) AS total_return_amount,
  SUM(fs.ws_net_profit) AS total_net_profit,
  CASE
    WHEN SUM(fr.sr_return_amt) > 1000 THEN 'High'
    ELSE 'Low'
  END AS return_category,
  RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(fs.ws_net_profit) DESC) AS profit_rank
FROM intersect_dates id
JOIN filtered_returns fr
  ON fr.sr_returned_date_sk = id.dsk
JOIN filtered_sales fs
  ON fs.ws_sold_date_sk = id.dsk
JOIN date_dim d
  ON d.d_date_sk = id.dsk
JOIN household_demographics hd
  ON fr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN reason r
  ON fr.sr_reason_sk = r.r_reason_sk
JOIN web_page wp
  ON fs.ws_web_page_sk = wp.wp_web_page_sk
JOIN cc_date_full cc
  ON cc.d_date_sk = d.d_date_sk
GROUP BY
  d.d_year,
  cc.cc_name,
  wp.wp_url,
  r.r_reason_desc
ORDER BY
  d.d_year DESC,
  total_net_profit DESC
LIMIT 100
