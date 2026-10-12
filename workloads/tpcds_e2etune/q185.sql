WITH sales_agg AS (
  SELECT
    d_sold.d_year,
    d_sold.d_quarter_name,
    i.i_category,
    w.w_state,
    ws.web_state AS website_state,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
  WHERE cs.cs_net_profit > 0
    AND cs.cs_ext_discount_amt > 0
    AND cd.cd_gender = 'F'
    AND cd.cd_credit_rating = 'Excellent'
    AND d_sold.d_year BETWEEN 2000 AND 2005
  GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    i.i_category,
    w.w_state,
    ws.web_state
)
SELECT
  d_year,
  d_quarter_name,
  i_category,
  w_state,
  website_state,
  total_net_profit,
  total_sales,
  avg_discount,
  distinct_customers,
  RANK() OVER (PARTITION BY d_year, d_quarter_name ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
