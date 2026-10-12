WITH sales AS (
  SELECT i.i_brand AS brand,
         cd.cd_gender AS gender,
         SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
         SUM(cs.cs_net_profit) AS total_profit
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cs.cs_net_paid_inc_ship_tax > 500
    AND cs.cs_bill_hdemo_sk IN (5775, 6189)
  GROUP BY i.i_brand, cd.cd_gender
  HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 1000
),
returns AS (
  SELECT i.i_brand AS brand,
         cd.cd_gender AS gender,
         SUM(sr.sr_return_amt_inc_tax) AS total_returns,
         SUM(sr.sr_net_loss) AS total_loss
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE sr.sr_return_amt_inc_tax > 100
  GROUP BY i.i_brand, cd.cd_gender
)
SELECT s.brand,
       s.gender,
       s.total_sales,
       s.total_profit,
       COALESCE(r.total_returns, 0) AS total_returns,
       COALESCE(r.total_loss, 0) AS total_loss,
       (s.total_profit - COALESCE(r.total_loss, 0)) AS net_profit_after_returns,
       RANK() OVER (ORDER BY (s.total_profit - COALESCE(r.total_loss, 0)) DESC) AS profit_rank
FROM sales s
LEFT JOIN returns r
  ON s.brand = r.brand AND s.gender = r.gender
ORDER BY net_profit_after_returns DESC
LIMIT 50
