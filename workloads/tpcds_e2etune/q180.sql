WITH early_sales AS (
  SELECT ss_store_sk,
         ss_item_sk,
         SUM(ss_net_profit) AS early_profit,
         SUM(ss_quantity) AS early_qty
  FROM store_sales
  WHERE ss_sold_time_sk <= 50000
    AND ss_ext_discount_amt > 0
    AND ss_ticket_number IN (317803, 317804)
    AND ss_item_sk IN (34793, 264463)
    AND ss_list_price > 50
  GROUP BY ss_store_sk, ss_item_sk
),
late_sales AS (
  SELECT ss_store_sk,
         ss_item_sk,
         SUM(ss_net_profit) AS late_profit,
         SUM(ss_quantity) AS late_qty
  FROM store_sales
  WHERE ss_sold_time_sk > 50000
    AND ss_ext_discount_amt > 0
    AND ss_ticket_number IN (317803, 317804)
    AND ss_item_sk IN (34793, 264463)
    AND ss_list_price > 50
  GROUP BY ss_store_sk, ss_item_sk
)
SELECT e.ss_store_sk,
       e.ss_item_sk,
       e.early_profit,
       l.late_profit,
       CASE WHEN e.early_profit = 0 THEN NULL
            ELSE (l.late_profit - e.early_profit) / e.early_profit * 100 END AS profit_pct_change,
       RANK() OVER (ORDER BY (l.late_profit - e.early_profit) DESC) AS profit_growth_rank
FROM early_sales e
JOIN late_sales l
  ON e.ss_store_sk = l.ss_store_sk
 AND e.ss_item_sk = l.ss_item_sk
WHERE e.early_profit > 0
ORDER BY profit_pct_change DESC
LIMIT 100
