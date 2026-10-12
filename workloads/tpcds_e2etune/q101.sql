WITH sales_returns AS (
    SELECT cs.cs_promo_sk AS promo_sk,
           cs.cs_ship_date_sk AS ship_date_sk,
           SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
           SUM(cs.cs_net_profit) AS total_profit,
           SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount,
           SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
           (SUM(cs.cs_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0))) AS net_profit_after_returns,
           COUNT(DISTINCT cs.cs_order_number) AS num_orders,
           COUNT(DISTINCT CASE WHEN wr.wr_order_number IS NOT NULL THEN cs.cs_order_number END) AS num_orders_with_returns
    FROM catalog_sales cs
    LEFT JOIN web_returns wr
      ON cs.cs_order_number = wr.wr_order_number
     AND cs.cs_item_sk = wr.wr_item_sk
    WHERE cs.cs_ship_date_sk IN (2450871, 2450869, 2450908)
      AND cs.cs_ext_ship_cost BETWEEN 500 AND 1500
      AND cs.cs_promo_sk IN (1023, 1057, 1374)
    GROUP BY cs.cs_promo_sk, cs.cs_ship_date_sk
    HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 10000
)
SELECT promo_sk,
       ship_date_sk,
       total_sales,
       total_profit,
       total_return_amount,
       total_return_loss,
       net_profit_after_returns,
       num_orders,
       num_orders_with_returns,
       RANK() OVER (PARTITION BY ship_date_sk ORDER BY net_profit_after_returns DESC) AS profit_rank_by_ship_date
FROM sales_returns
ORDER BY net_profit_after_returns DESC
LIMIT 20
