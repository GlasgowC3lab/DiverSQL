WITH
cs_join AS (
  SELECT
    c.c_customer_id,
    d_sold.d_date AS sold_date,
    i.i_item_sk,
    i.i_product_name,
    cs.cs_ext_sales_price AS sales_price,
    cs.cs_net_profit AS profit,
    cp.cp_department AS extra_info
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE cs.cs_quantity > 1
    AND cs.cs_ext_sales_price > 100
    AND cs.cs_net_profit > 0
    AND d_sold.d_year BETWEEN 2000 AND 2002
    AND c.c_preferred_cust_flag = 'Y'
    AND hd.hd_vehicle_count >= 2
    AND cp.cp_department = 'Books'
),
ws_join AS (
  SELECT
    c.c_customer_id,
    d.d_date AS sold_date,
    i.i_item_sk,
    i.i_product_name,
    ws.ws_ext_sales_price AS sales_price,
    ws.ws_net_profit AS profit,
    wp.wp_type AS extra_info
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
  WHERE ws.ws_quantity > 1
    AND ws.ws_ext_sales_price > 150
    AND ws.ws_net_profit > 0
    AND d.d_year BETWEEN 2000 AND 2002
    AND c.c_preferred_cust_flag = 'Y'
    AND hd.hd_vehicle_count >= 2
    AND wp.wp_type = 'content'
    AND we.web_country = 'United States'
),
store_join AS (
  SELECT
    c.c_customer_id,
    d.d_date AS sold_date,
    i.i_item_sk,
    i.i_product_name,
    ss.ss_ext_sales_price AS sales_price,
    ss.ss_net_profit AS profit,
    CAST(ib.ib_upper_bound AS varchar) AS extra_info
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ss.ss_quantity > 1
    AND ss.ss_ext_sales_price > 120
    AND ss.ss_net_profit > 0
    AND d.d_year BETWEEN 2000 AND 2002
    AND c.c_preferred_cust_flag = 'Y'
    AND ib.ib_upper_bound >= 50000
),
unioned AS (
  SELECT c_customer_id, sold_date, i_item_sk, i_product_name, sales_price, profit, extra_info FROM cs_join
  UNION
  SELECT c_customer_id, sold_date, i_item_sk, i_product_name, sales_price, profit, extra_info FROM ws_join
  UNION
  SELECT c_customer_id, sold_date, i_item_sk, i_product_name, sales_price, profit, extra_info FROM store_join
),
intersected AS (
  SELECT c_customer_id, sold_date, i_item_sk, profit FROM unioned
  INTERSECT
  SELECT c_customer_id, sold_date, i_item_sk, profit FROM unioned WHERE profit > 500
),
ranked AS (
  SELECT
    c_customer_id,
    sold_date,
    i_item_sk,
    profit,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY profit DESC) AS profit_rank
  FROM intersected
)
SELECT
  c_customer_id,
  sold_date,
  i_item_sk,
  profit,
  profit_rank,
  CASE WHEN profit_rank <= 5 THEN 'Top5' ELSE 'Other' END AS rank_group
FROM ranked
ORDER BY profit DESC
LIMIT 100
