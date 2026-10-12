WITH base AS (
  SELECT
    d.d_year AS d_year,
    i.i_category AS i_category,
    w.w_state AS w_state,
    SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                         AND cr.cr_item_sk = cs.cs_item_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
                     AND ss.ss_sold_date_sk = d.d_date_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                    AND ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
    AND w.w_state = 'CA'
    AND r.r_reason_desc LIKE '%price%'
    AND cs.cs_quantity > 5
    AND cs.cs_net_paid_inc_tax > 1000
    AND ws.ws_quantity > 3
  GROUP BY d.d_year, i.i_category, w.w_state
  HAVING SUM(cs.cs_net_paid_inc_tax) > 5000
)
SELECT
  d_year,
  i_category,
  w_state,
  total_catalog_sales,
  total_returns,
  total_store_sales,
  total_web_sales,
  order_cnt,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS sales_rank
FROM base
ORDER BY d_year, sales_rank
LIMIT 100
