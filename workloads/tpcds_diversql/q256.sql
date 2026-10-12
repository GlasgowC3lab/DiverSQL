WITH first_part AS (
  SELECT
    cp.cp_department AS department,
    w.w_state AS state,
    p.p_channel_dmail AS dmail_channel,
    cs.cs_sold_date_sk AS sold_date_sk,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_count
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2451080 AND 2451090
    AND cs.cs_quantity >= 2
    AND p.p_channel_dmail = 'Y'
    AND cp.cp_department IN ('Books', 'Electronics')
    AND i.inv_quantity_on_hand > 500
  GROUP BY cp.cp_department, w.w_state, p.p_channel_dmail, cs.cs_sold_date_sk
),
second_part AS (
  SELECT
    cp.cp_department AS department,
    w.w_state AS state,
    p.p_channel_dmail AS dmail_channel,
    cs.cs_sold_date_sk AS sold_date_sk,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_count
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2451091 AND 2451100
    AND cs.cs_quantity BETWEEN 1 AND 5
    AND p.p_channel_dmail = 'N'
    AND cp.cp_department = 'Sports'
    AND i.inv_quantity_on_hand BETWEEN 200 AND 800
  GROUP BY cp.cp_department, w.w_state, p.p_channel_dmail, cs.cs_sold_date_sk
)
SELECT
  department,
  state,
  dmail_channel,
  sold_date_sk,
  total_sales,
  total_profit,
  sales_count,
  ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num
FROM (
  SELECT * FROM first_part
  UNION DISTINCT
  SELECT * FROM second_part
) AS combined
ORDER BY total_sales DESC
LIMIT 100
