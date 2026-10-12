WITH filtered_items AS (
    SELECT i_item_sk,
           i_category,
           i_brand,
           i_current_price,
           i_wholesale_cost
    FROM   item
    WHERE  i_current_price > 100
      AND  i_category IN (
            SELECT DISTINCT cc_class
            FROM   call_center
            WHERE  cc_state = 'TN'
        )
)
SELECT f.i_category,
       f.i_brand,
       COUNT(DISTINCT wr.wr_order_number)               AS num_returns,
       SUM(wr.wr_return_quantity)                       AS total_return_qty,
       SUM(wr.wr_net_loss)                              AS total_net_loss,
       AVG(wr.wr_return_quantity)                       AS avg_return_qty,
       SUM(wr.wr_return_quantity * f.i_current_price)  AS revenue_lost,
       ROUND(AVG(wr.wr_return_quantity * f.i_current_price), 2) AS avg_loss_per_return,
       RANK() OVER (ORDER BY SUM(wr.wr_net_loss) DESC) AS loss_rank
FROM   web_returns wr
JOIN   filtered_items f
       ON wr.wr_item_sk = f.i_item_sk
WHERE  wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
  AND  wr.wr_return_amt > 0
GROUP BY f.i_category, f.i_brand
HAVING SUM(wr.wr_net_loss) > 10000
ORDER BY total_net_loss DESC
LIMIT 50
