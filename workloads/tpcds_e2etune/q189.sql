WITH returns_agg AS (
    SELECT wr.wr_item_sk,
           wr.wr_order_number,
           SUM(wr.wr_net_loss) AS total_return_loss,
           SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    GROUP BY wr.wr_item_sk, wr.wr_order_number
)
SELECT i.i_category,
       cs.cs_ship_mode_sk,
       SUM(cs.cs_net_profit) AS gross_profit,
       COALESCE(SUM(r.total_return_loss), 0) AS return_loss,
       SUM(cs.cs_net_profit) - COALESCE(SUM(r.total_return_loss), 0) AS net_profit_adj,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
       AVG(cs.cs_sales_price) AS avg_sales_price
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN returns_agg r
       ON r.wr_item_sk = cs.cs_item_sk
      AND r.wr_order_number = cs.cs_order_number
WHERE cs.cs_ship_hdemo_sk IN (2606, 6696)
  AND cs.cs_sales_price > 50
  AND cs.cs_promo_sk = 1023
  AND cs.cs_sold_date_sk BETWEEN 2450820 AND 2450826
GROUP BY i.i_category, cs.cs_ship_mode_sk
HAVING SUM(cs.cs_net_profit) > 1000
ORDER BY net_profit_adj DESC
LIMIT 100
