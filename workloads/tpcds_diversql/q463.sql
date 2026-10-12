WITH
  cr_agg AS (
    SELECT
      cr_returning_hdemo_sk AS hd_demo_sk,
      SUM(cr_return_amount)           AS total_return_amount,
      COUNT(*)                        AS cnt_returns
    FROM catalog_returns
    WHERE cr_return_amount > 100.00
      AND cr_return_quantity >= 1
      AND cr_fee IS NOT NULL
      AND cr_store_credit >= 0
      AND cr_return_tax >= 0
      AND cr_return_ship_cost > 0
    GROUP BY cr_returning_hdemo_sk
  ),

  ws_agg AS (
    SELECT
      ws_bill_hdemo_sk AS hd_demo_sk,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_coupon_amt)      AS total_coupon,
      COUNT(*)                AS cnt_sales
    FROM web_sales
    WHERE ws_ext_sales_price > 0
      AND ws_coupon_amt >= 0
      AND ws_ship_mode_sk IN (1, 4, 10)
      AND ws_ship_hdemo_sk IS NOT NULL
      AND ws_warehouse_sk BETWEEN 1 AND 5
      AND ws_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY ws_bill_hdemo_sk
  ),

  household_keys_intersect AS (
    SELECT hd_demo_sk FROM cr_agg
    INTERSECT
    SELECT hd_demo_sk FROM ws_agg
  ),

  union_sales_returns AS (
    SELECT
      h.hd_demo_sk,
      ib.ib_income_band_sk,
      cr.total_return_amount,
      ws.total_sales,
      cr.cnt_returns,
      ws.cnt_sales
    FROM household_keys_intersect h
    JOIN household_demographics hd ON hd.hd_demo_sk = h.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN cr_agg cr ON cr.hd_demo_sk = h.hd_demo_sk
    LEFT JOIN ws_agg ws ON ws.hd_demo_sk = h.hd_demo_sk
    WHERE ib.ib_upper_bound <= 80000
      AND ib.ib_lower_bound >= 40000
    UNION DISTINCT
    SELECT
      h.hd_demo_sk,
      ib.ib_income_band_sk,
      cr.total_return_amount,
      ws.total_sales,
      cr.cnt_returns,
      ws.cnt_sales
    FROM household_keys_intersect h
    JOIN household_demographics hd ON hd.hd_demo_sk = h.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN cr_agg cr ON cr.hd_demo_sk = h.hd_demo_sk
    LEFT JOIN ws_agg ws ON ws.hd_demo_sk = h.hd_demo_sk
    WHERE ib.ib_upper_bound >= 10000
      AND ib.ib_lower_bound <= 200000
      AND cr.total_return_amount IS NOT NULL
  ),

  final_agg AS (
    SELECT
      hd_demo_sk,
      ib_income_band_sk,
      SUM(total_return_amount) AS sum_return,
      SUM(total_sales)          AS sum_sales,
      SUM(cnt_returns)          AS sum_cnt_returns,
      SUM(cnt_sales)            AS sum_cnt_sales
    FROM union_sales_returns
    GROUP BY GROUPING SETS ((hd_demo_sk, ib_income_band_sk), (hd_demo_sk), ())
    HAVING SUM(total_sales) > 1000
  )

SELECT
  hd_demo_sk,
  ib_income_band_sk,
  sum_return,
  sum_sales,
  sum_cnt_returns,
  sum_cnt_sales
FROM final_agg
ORDER BY sum_sales DESC
LIMIT 100
