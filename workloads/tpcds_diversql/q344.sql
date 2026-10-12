WITH
  returns_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      cr.cr_refunded_hdemo_sk,
      SUM(cr.cr_return_quantity) AS total_return_qty,
      SUM(cr.cr_return_amount) AS total_return_amt,
      AVG(cr.cr_return_tax) AS avg_return_tax
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND d.d_month_seq BETWEEN 1200 AND 1205
      AND cr.cr_return_tax > 20
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk, cr.cr_refunded_hdemo_sk
  ),
  sales_agg AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_sold_date_sk,
      ws.ws_bill_hdemo_sk,
      SUM(ws.ws_quantity) AS total_sales_qty,
      SUM(ws.ws_ext_sales_price) AS total_sales_amt,
      AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND ws.ws_sales_price > 50
      AND ws.ws_ext_sales_price > 0
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk, ws.ws_bill_hdemo_sk
  ),
  common_items AS (
    SELECT cr_item_sk FROM returns_agg
    INTERSECT
    SELECT ws_item_sk FROM sales_agg
  ),
  full_join AS (
    SELECT
      r.cr_item_sk,
      r.cr_returned_date_sk,
      r.cr_refunded_hdemo_sk,
      r.total_return_qty,
      r.total_return_amt,
      r.avg_return_tax,
      s.ws_item_sk,
      s.ws_sold_date_sk,
      s.ws_bill_hdemo_sk,
      s.total_sales_qty,
      s.total_sales_amt,
      s.avg_sales_price
    FROM returns_agg r
    FULL OUTER JOIN sales_agg s
      ON r.cr_item_sk = s.ws_item_sk
      AND r.cr_returned_date_sk = s.ws_sold_date_sk
  )
SELECT
  d.d_date,
  i.i_item_id,
  i.i_product_name,
  f.total_return_qty,
  f.total_return_amt,
  f.avg_return_tax,
  f.total_sales_qty,
  f.total_sales_amt,
  f.avg_sales_price,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  s.s_store_name,
  s.s_floor_space,
  (
    SELECT AVG(cr_return_amount)
    FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = i.i_item_sk
  ) AS avg_return_amount_overall
FROM full_join f
JOIN item i
  ON COALESCE(f.cr_item_sk, f.ws_item_sk) = i.i_item_sk
JOIN date_dim d
  ON COALESCE(f.cr_returned_date_sk, f.ws_sold_date_sk) = d.d_date_sk
JOIN household_demographics hd
  ON COALESCE(f.cr_refunded_hdemo_sk, f.ws_bill_hdemo_sk) = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
  ON d.d_date_sk = s.s_closed_date_sk
JOIN common_items ci
  ON ci.cr_item_sk = COALESCE(f.cr_item_sk, f.ws_item_sk)
WHERE ib.ib_lower_bound >= 50000
  AND s.s_floor_space > 6000000
  AND i.i_current_price BETWEEN 20 AND 100
  AND d.d_month_seq = 1202
  AND d.d_dow = 2
GROUP BY
  d.d_date,
  i.i_item_id,
  i.i_product_name,
  f.total_return_qty,
  f.total_return_amt,
  f.avg_return_tax,
  f.total_sales_qty,
  f.total_sales_amt,
  f.avg_sales_price,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  s.s_store_name,
  s.s_floor_space,
  i.i_item_sk
ORDER BY d.d_date DESC, f.total_return_qty DESC
LIMIT 100
