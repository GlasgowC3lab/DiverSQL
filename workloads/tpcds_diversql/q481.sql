WITH base AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    ss.ss_customer_sk,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    ss.ss_wholesale_cost,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    c.c_salutation,
    d.d_date,
    d.d_year
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN inventory i ON d.d_date_sk = i.inv_date_sk
)
SELECT DISTINCT
  b.ss_ticket_number,
  b.d_date,
  b.c_first_name,
  b.c_last_name,
  b.c_birth_country,
  CASE
    WHEN b.ss_net_profit > 1000 THEN 'High'
    WHEN b.ss_net_profit > 0 THEN 'Medium'
    ELSE 'Low'
  END AS profit_category,
  b.ss_net_profit,
  RANK() OVER (PARTITION BY b.d_year ORDER BY b.ss_net_profit DESC) AS profit_rank_year,
  (SELECT SUM(DISTINCT i2.inv_quantity_on_hand)
   FROM inventory i2
   WHERE i2.inv_date_sk = b.ss_sold_date_sk) AS total_inventory_on_date,
  u.metric_value,
  g.grp
FROM base b
CROSS JOIN (VALUES 'A', 'B', 'C') AS g(grp)
CROSS JOIN UNNEST(ARRAY[b.ss_quantity, b.ss_ext_sales_price]) AS u(metric_value)
WHERE b.d_year = 2001
  AND b.c_birth_country IN ('KOREA', 'PHILIPPINES')
  AND b.ss_wholesale_cost > 20
  AND b.ss_quantity BETWEEN 1 AND 10
  AND b.ss_ext_sales_price > 100
  AND b.ss_ticket_number NOT IN (
        SELECT ss_ticket_number
        FROM store_sales
        WHERE ss_quantity > 20
      )
ORDER BY profit_rank_year, g.grp
LIMIT 100
