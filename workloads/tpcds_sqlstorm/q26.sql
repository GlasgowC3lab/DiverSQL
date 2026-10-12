WITH unified_sales AS (
  SELECT
    ss.ss_sold_date_sk AS sold_date_sk,
    ca.ca_state AS state,
    'store' AS channel,
    ss.ss_net_profit AS net_profit,
    ss.ss_net_paid AS net_paid,
    ss.ss_ext_discount_amt AS discount_amt,
    ss.ss_quantity AS quantity,
    ss.ss_item_sk AS item_sk,
    ss.ss_customer_sk AS customer_sk
  FROM store_sales ss
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  UNION ALL
  SELECT
    cs.cs_sold_date_sk,
    ca.ca_state,
    'catalog',
    cs.cs_net_profit,
    cs.cs_net_paid,
    cs.cs_ext_discount_amt,
    cs.cs_quantity,
    cs.cs_item_sk,
    cs.cs_bill_customer_sk
  FROM catalog_sales cs
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  UNION ALL
  SELECT
    ws.ws_sold_date_sk,
    ca.ca_state,
    'web',
    ws.ws_net_profit,
    ws.ws_net_paid,
    ws.ws_ext_discount_amt,
    ws.ws_quantity,
    ws.ws_item_sk,
    ws.ws_bill_customer_sk
  FROM web_sales ws
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
),
sales_with_date AS (
  SELECT
    us.*,
    d.d_year AS year
  FROM unified_sales us
  JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
),
aggregated AS (
  SELECT
    year,
    state,
    channel,
    sum(net_profit) AS total_net_profit,
    sum(net_paid) AS total_net_paid,
    sum(discount_amt) AS total_discount,
    count(DISTINCT customer_sk) AS distinct_customers,
    sum(quantity) AS total_quantity
  FROM sales_with_date
  GROUP BY year, state, channel
),
top_items AS (
  SELECT
    swd.year,
    swd.state,
    i.i_product_name AS product_name,
    sum(swd.net_profit) AS item_profit,
    row_number() OVER (PARTITION BY swd.year, swd.state ORDER BY sum(swd.net_profit) DESC) AS rn
  FROM sales_with_date swd
  JOIN item i ON swd.item_sk = i.i_item_sk
  GROUP BY swd.year, swd.state, i.i_product_name
)
SELECT
  a.year,
  a.state,
  a.channel,
  a.total_net_profit,
  a.total_net_paid,
  a.total_discount,
  a.distinct_customers,
  a.total_quantity,
  ti.product_name AS top_product,
  ti.item_profit AS top_product_profit
FROM aggregated a
LEFT JOIN (
  SELECT year, state, product_name, item_profit
  FROM top_items
  WHERE rn = 1
) ti ON a.year = ti.year AND a.state = ti.state
ORDER BY a.year DESC, a.state, a.channel
