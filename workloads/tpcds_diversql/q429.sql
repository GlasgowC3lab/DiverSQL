WITH
  store_data AS (
    SELECT
      i.i_item_id,
      ss.ss_quantity,
      ss.ss_net_paid,
      sr.sr_return_amt,
      cd.cd_gender,
      hd.hd_vehicle_count,
      ib.ib_upper_bound
    FROM (
      SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)
    ) ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
      AND ss.ss_item_sk = sr.sr_item_sk
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
      td.t_hour BETWEEN 9 AND 17
      AND i.i_current_price BETWEEN 20 AND 200
      AND hd.hd_vehicle_count >= 2
      AND cd.cd_gender = 'M'
      AND ib.ib_upper_bound <= 50000
      AND (sr.sr_return_quantity IS NULL OR sr.sr_return_quantity > 0)
  ),
  web_data AS (
    SELECT
      i.i_item_id,
      wr.wr_return_quantity AS qty,
      wr.wr_return_amt AS return_amt,
      cd.cd_gender,
      hd.hd_vehicle_count,
      ib.ib_upper_bound
    FROM web_returns wr
    JOIN time_dim td
      ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd
      ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
      ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
      td.t_hour BETWEEN 9 AND 17
      AND i.i_current_price BETWEEN 20 AND 200
      AND hd.hd_vehicle_count >= 2
      AND cd.cd_gender = 'M'
      AND ib.ib_upper_bound <= 50000
  ),
  combined AS (
    SELECT
      i_item_id,
      SUM(ss_quantity) AS sales_qty,
      SUM(ss_net_paid) AS sales_amount,
      SUM(COALESCE(sr_return_amt, 0)) AS return_amount
    FROM store_data
    GROUP BY i_item_id
    UNION DISTINCT
    SELECT
      i_item_id,
      SUM(qty) AS sales_qty,
      0.0 AS sales_amount,
      SUM(return_amt) AS return_amount
    FROM web_data
    GROUP BY i_item_id
  )
SELECT
  c.i_item_id,
  SUM(c.sales_qty) AS total_qty,
  SUM(c.sales_amount) AS total_sales_amount,
  SUM(c.return_amount) AS total_return_amount,
  COUNT(*) AS item_count
FROM combined c
WHERE c.i_item_id NOT IN (
  SELECT i_item_id FROM item WHERE i_current_price > 1000
)
GROUP BY c.i_item_id
ORDER BY total_sales_amount DESC
LIMIT 100
