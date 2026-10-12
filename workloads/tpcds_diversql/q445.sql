WITH intersect_items AS (
  SELECT cs_item_sk FROM catalog_sales
  INTERSECT
  SELECT ss_item_sk FROM store_sales
),
sampled_store_sales AS (
  SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)
),
filtered_catalog_sales AS (
  SELECT *
  FROM catalog_sales
  WHERE cs_ext_sales_price > 1000
    AND cs_order_number NOT IN (SELECT wr_order_number FROM web_returns)
),
base AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(fc.cs_ext_sales_price)          AS total_catalog_sales,
    COUNT(DISTINCT fc.cs_order_number)   AS distinct_catalog_orders,
    SUM(ss.ss_ext_sales_price)          AS total_store_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
    AVG(ss.ss_sales_price)              AS avg_store_sales_price,
    MIN(wr.wr_return_amt)               AS min_return_amount,
    MAX(p.p_cost)                       AS max_promo_cost
  FROM filtered_catalog_sales fc
  JOIN intersect_items it ON fc.cs_item_sk = it.cs_item_sk
  JOIN date_dim d ON fc.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON fc.cs_item_sk = i.i_item_sk
  JOIN promotion p ON fc.cs_promo_sk = p.p_promo_sk
  JOIN call_center cc ON fc.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON fc.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON fc.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c ON fc.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON fc.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON fc.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON fc.cs_bill_addr_sk = ca.ca_address_sk
  JOIN sampled_store_sales ss ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE cc.cc_state = 'TX'
    AND i.i_brand = 'BrandX'
    AND p.p_discount_active = 'Y'
    AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    AND s.s_state = 'CA'
  GROUP BY d.d_year, i.i_category
)
SELECT
  *,
  ROW_NUMBER() OVER (ORDER BY total_catalog_sales DESC) AS rn
FROM base
ORDER BY rn
LIMIT 100
