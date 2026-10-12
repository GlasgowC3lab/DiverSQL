WITH sales AS (
  SELECT
    d.d_year AS d_year,
    ca.ca_state AS ca_state,
    i.i_category AS i_category,
    cs.cs_ext_sales_price AS sales_amount,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_discount_amt AS discount_amt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  UNION ALL
  SELECT
    d.d_year,
    ca.ca_state,
    i.i_category,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    ss.ss_ext_discount_amt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  UNION ALL
  SELECT
    d.d_year,
    ca.ca_state,
    i.i_category,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
)
SELECT
  d_year,
  ca_state,
  i_category,
  SUM(sales_amount) AS total_sales,
  SUM(net_profit) AS total_profit,
  SUM(discount_amt) AS total_discount
FROM sales
GROUP BY d_year, ca_state, i_category
ORDER BY total_sales DESC
LIMIT 100
