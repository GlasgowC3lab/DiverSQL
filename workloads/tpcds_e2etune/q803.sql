WITH sales_agg AS (
  SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    SUM(cs.cs_net_profit) AS order_item_profit,
    SUM(cs.cs_net_paid) AS order_item_paid,
    SUM(cs.cs_wholesale_cost * cs.cs_quantity) AS total_wholesale_cost
  FROM catalog_sales cs
  WHERE cs.cs_wholesale_cost > 50.00
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
  GROUP BY cs.cs_order_number, cs.cs_item_sk
)
SELECT
  cr.cr_returning_hdemo_sk AS returning_hdemo,
  COUNT(*) AS return_count,
  SUM(cr.cr_return_quantity) AS total_return_qty,
  SUM(cr.cr_net_loss) AS total_net_loss,
  SUM(sa.order_item_profit) AS total_sales_profit,
  CASE WHEN SUM(sa.order_item_profit) = 0 THEN NULL
       ELSE SUM(cr.cr_net_loss) / SUM(sa.order_item_profit)
  END AS loss_to_profit_ratio
FROM catalog_returns cr
JOIN sales_agg sa
  ON cr.cr_order_number = sa.cs_order_number
  AND cr.cr_item_sk = sa.cs_item_sk
WHERE cr.cr_refunded_customer_sk IN (8743536, 6212854, 9240699)
  AND cr.cr_return_quantity > 0
GROUP BY cr.cr_returning_hdemo_sk
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY loss_to_profit_ratio DESC NULLS LAST
LIMIT 20
