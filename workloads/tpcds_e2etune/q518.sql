WITH sales_agg AS (
  SELECT
    c.c_birth_year,
    c.c_birth_month,
    COUNT(DISTINCT ss.ss_customer_sk) AS num_customers,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
  FROM store_sales ss
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN inventory inv
    ON ss.ss_item_sk = inv.inv_item_sk
   AND ss.ss_sold_date_sk = inv.inv_date_sk
  WHERE c.c_birth_year IN (1960, 1967)
    AND c.c_last_name = 'Norman'
    AND inv.inv_quantity_on_hand > 0
  GROUP BY c.c_birth_year, c.c_birth_month
  HAVING SUM(ss.ss_net_profit) > 1000
)
SELECT
  s.c_birth_year,
  s.c_birth_month,
  s.num_customers,
  s.total_profit,
  s.avg_discount,
  s.total_inventory_qty,
  RANK() OVER (ORDER BY s.total_profit DESC) AS profit_rank
FROM sales_agg s
ORDER BY s.total_profit DESC
LIMIT 10
