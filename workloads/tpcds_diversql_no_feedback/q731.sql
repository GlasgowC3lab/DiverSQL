WITH sales_agg AS (
  SELECT
    cs.cs_bill_customer_sk,
    d.d_year AS sales_year,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    MIN(cs.cs_item_sk) AS item_sk,
    MIN(cs.cs_promo_sk) AS promo_sk,
    MIN(cs.cs_warehouse_sk) AS warehouse_sk,
    MIN(cs.cs_call_center_sk) AS cc_sk,
    MIN(cs.cs_catalog_page_sk) AS cp_sk,
    MIN(cs.cs_order_number) AS sample_order_number
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_date >= DATE '2000-01-01'
    AND d.d_date <= DATE '2001-12-31'
  GROUP BY cs.cs_bill_customer_sk, d.d_year
),

returns_agg AS (
  SELECT
    cr.cr_order_number,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  GROUP BY cr.cr_order_number
)

SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  ca.ca_city,
  cd.cd_gender,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  i.i_item_id,
  i.i_category,
  p.p_promo_name,
  w.w_warehouse_name,
  cc.cc_name,
  cp.cp_department,
  s.sales_year,
  s.total_profit,
  s.total_sales,
  r.total_return_amount,
  CASE
    WHEN s.total_profit > 10000 THEN 'HIGH'
    WHEN s.total_profit BETWEEN 0 AND 10000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  RANK() OVER (PARTITION BY s.sales_year ORDER BY s.total_profit DESC) AS profit_rank
FROM sales_agg s
JOIN customer c
  ON s.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i
  ON s.item_sk = i.i_item_sk
JOIN promotion p
  ON s.promo_sk = p.p_promo_sk
JOIN warehouse w
  ON s.warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
  ON s.cc_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON s.cp_sk = cp.cp_catalog_page_sk
LEFT JOIN returns_agg r
  ON s.sample_order_number = r.cr_order_number
WHERE ca.ca_country = 'United States'
  AND i.i_class_id IN (2, 5)
  AND hd.hd_buy_potential = '5000-10000'
ORDER BY s.sales_year DESC, profit_rank
LIMIT 100
