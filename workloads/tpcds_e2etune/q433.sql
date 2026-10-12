WITH brand_sales AS (
  SELECT i.i_category,
         i.i_brand,
         SUM(ss.ss_net_paid) AS total_net_paid,
         SUM(ss.ss_net_profit) AS total_net_profit,
         AVG(ss.ss_quantity) AS avg_quantity,
         COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE i.i_category IN ('Music', 'Women', 'Home')
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
    AND i.i_units = 'Tsp'
  GROUP BY i.i_category, i.i_brand
  HAVING SUM(ss.ss_net_profit) > 1000
)
SELECT bs.i_category,
       bs.i_brand,
       bs.total_net_paid,
       bs.total_net_profit,
       bs.avg_quantity,
       bs.num_tickets,
       RANK() OVER (PARTITION BY bs.i_category ORDER BY bs.total_net_profit DESC) AS profit_rank
FROM brand_sales bs
ORDER BY bs.i_category, profit_rank
LIMIT 100
