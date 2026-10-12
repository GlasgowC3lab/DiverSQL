WITH sampled_catalog AS (
  SELECT *
  FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_item_sk,
    cs.cs_bill_addr_sk,
    cs.cs_ext_sales_price,
    cs.cs_net_paid_inc_ship_tax,
    i.i_category,
    i.i_brand,
    ca.ca_state,
    t.t_hour
  FROM sampled_catalog cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE cs.cs_ext_sales_price > 100
    AND cs.cs_net_paid_inc_ship_tax BETWEEN 500 AND 7000
    AND i.i_category = 'Books'
    AND ca.ca_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
    AND t.t_meal_time = 'Lunch'
),
ss_base AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_sold_time_sk,
    ss.ss_item_sk,
    ss.ss_ext_sales_price,
    ss.ss_net_paid,
    i2.i_brand AS ss_brand,
    ca2.ca_state AS ss_state,
    t2.t_hour AS ss_hour
  FROM store_sales ss
  JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
  JOIN customer_address ca2 ON ss.ss_addr_sk = ca2.ca_address_sk
  JOIN time_dim t2 ON ss.ss_sold_time_sk = t2.t_time_sk
  WHERE ss.ss_ext_sales_price > 50
    AND ss.ss_net_paid > 0
    AND i2.i_brand = 'BrandX'
    AND ca2.ca_state = 'NY'
    AND t2.t_hour BETWEEN 8 AND 20
    AND t2.t_meal_time = 'Dinner'
),
sr_base AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_return_time_sk,
    sr.sr_item_sk,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    i3.i_category AS sr_category,
    ca3.ca_state AS sr_state,
    t3.t_hour AS sr_hour
  FROM store_returns sr
  JOIN item i3 ON sr.sr_item_sk = i3.i_item_sk
  JOIN customer_address ca3 ON sr.sr_addr_sk = ca3.ca_address_sk
  JOIN time_dim t3 ON sr.sr_return_time_sk = t3.t_time_sk
  WHERE sr.sr_return_amt > 0
    AND sr.sr_return_quantity >= 1
    AND i3.i_category = 'Books'
    AND ca3.ca_state = 'CA'
    AND t3.t_hour BETWEEN 9 AND 17
    AND t3.t_meal_time = 'Lunch'
),
ss_sr AS (
  SELECT
    COALESCE(ss.ss_ticket_number, sr.sr_ticket_number) AS ticket_number,
    ss.ss_ext_sales_price,
    sr.sr_return_amt,
    ss.ss_net_paid,
    sr.sr_return_quantity,
    ss.ss_brand,
    sr.sr_category,
    ss.ss_state,
    sr.sr_state,
    ss.ss_sold_time_sk,
    sr.sr_return_time_sk
  FROM ss_base ss
  FULL OUTER JOIN sr_base sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
),
joined_all AS (
  SELECT
    b.cs_sold_date_sk,
    b.cs_sold_time_sk,
    b.cs_ext_sales_price,
    b.cs_net_paid_inc_ship_tax,
    ssr.ss_ext_sales_price,
    ssr.sr_return_amt,
    (b.cs_ext_sales_price + COALESCE(ssr.ss_ext_sales_price, 0)) AS total_price,
    CASE
      WHEN b.cs_net_paid_inc_ship_tax > 1000 THEN 'High'
      ELSE 'Low'
    END AS profit_level
  FROM base b
  LEFT JOIN ss_sr ssr
    ON b.cs_sold_time_sk = ssr.ss_sold_time_sk
  WHERE b.cs_sold_date_sk IS NOT NULL
    AND ssr.ticket_number IS NOT NULL
)
SELECT
  profit_level,
  AVG(price_val) AS avg_price,
  SUM(total_price) AS sum_total_price,
  COUNT(*) AS txn_cnt
FROM joined_all
CROSS JOIN LATERAL (
  SELECT ARRAY[
    cs_ext_sales_price,
    COALESCE(ss_ext_sales_price, 0),
    COALESCE(sr_return_amt, 0)
  ] AS price_array
) AS l
CROSS JOIN UNNEST(l.price_array) AS u(price_val)
GROUP BY profit_level
HAVING AVG(price_val) > 200
ORDER BY sum_total_price DESC
LIMIT 100
