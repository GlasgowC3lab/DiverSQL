WITH sales_agg AS (
  SELECT
    p.p_promo_id,
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    cs.cs_warehouse_sk,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(*) AS order_cnt
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE
    cs.cs_quantity > 1
    AND cs.cs_wholesale_cost > 500
    AND cs.cs_ext_discount_amt < 2000
    AND cs.cs_ext_sales_price BETWEEN 1000 AND 50000
    AND p.p_response_target = 1
    AND p.p_channel_catalog = 'Y'
    AND p.p_discount_active = 'Y'
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
  GROUP BY p.p_promo_id, hd.hd_demo_sk, hd.hd_income_band_sk, cs.cs_warehouse_sk
),
store_ret_agg AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    sr.sr_hdemo_sk,
    SUM(sr.sr_return_amt) AS total_return_amt,
    COUNT(sr.sr_ticket_number) AS return_cnt
  FROM store s
  FULL OUTER JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
  GROUP BY s.s_store_sk, s.s_store_name, sr.sr_hdemo_sk
),
base AS (
  SELECT
    sa.p_promo_id,
    sra.s_store_name,
    w.w_warehouse_name,
    SUM(sa.total_sales) AS total_sales,
    SUM(sa.total_discount) AS total_discount,
    SUM(sa.order_cnt) AS total_orders,
    SUM(COALESCE(sra.total_return_amt, 0)) AS total_returns,
    SUM(COALESCE(sra.return_cnt, 0)) AS total_return_cnt
  FROM sales_agg sa
  JOIN store_ret_agg sra ON sra.sr_hdemo_sk = sa.hd_demo_sk
  JOIN warehouse w ON sa.cs_warehouse_sk = w.w_warehouse_sk
  WHERE
    w.w_state = 'CA'
    AND sa.total_discount > 100
    AND sa.order_cnt >= 5
    AND sra.return_cnt > 0
    AND w.w_city IS NOT NULL
    AND sa.total_sales BETWEEN 1000 AND 100000
  GROUP BY sa.p_promo_id, sra.s_store_name, w.w_warehouse_name
  HAVING SUM(sa.total_sales) > 20000
)
SELECT
  p_promo_id,
  s_store_name,
  w_warehouse_name,
  total_sales,
  total_discount,
  total_orders,
  total_returns,
  total_return_cnt,
  CASE WHEN total_sales > 50000 THEN 'BIG' ELSE 'SMALL' END AS sales_category
FROM base
ORDER BY total_sales DESC
OFFSET 10
LIMIT 100
