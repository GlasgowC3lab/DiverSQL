WITH cs_agg AS (
    SELECT cs.cs_bill_cdemo_sk AS demo_sk,
           SUM(cs.cs_net_profit) AS total_profit,
           SUM(cs.cs_ext_discount_amt) AS total_discount,
           COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_coupon_amt > 100
      AND cs.cs_net_paid_inc_ship > 0
    GROUP BY cs.cs_bill_cdemo_sk
),
wr_agg AS (
    SELECT wr.wr_refunded_cdemo_sk AS demo_sk,
           SUM(wr.wr_net_loss) AS total_loss,
           SUM(wr.wr_return_quantity) AS total_return_qty,
           COUNT(*) AS returns_cnt
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0
    GROUP BY wr.wr_refunded_cdemo_sk
)
SELECT *
FROM (
    SELECT cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           COALESCE(cs.total_profit, 0) AS total_profit,
           COALESCE(wr.total_loss, 0) AS total_loss,
           COALESCE(cs.total_profit, 0) - COALESCE(wr.total_loss, 0) AS net_profit,
           COALESCE(cs.sales_cnt, 0) AS sales_transactions,
           COALESCE(wr.returns_cnt, 0) AS return_transactions,
           CASE 
               WHEN COALESCE(wr.total_loss, 0) = 0 THEN NULL
               ELSE COALESCE(cs.total_profit, 0) / COALESCE(wr.total_loss, 0)
           END AS profit_to_loss_ratio
    FROM customer_demographics cd
    LEFT JOIN cs_agg cs ON cs.demo_sk = cd.cd_demo_sk
    LEFT JOIN wr_agg wr ON wr.demo_sk = cd.cd_demo_sk
) t
WHERE t.net_profit > 5000
ORDER BY t.net_profit DESC
LIMIT 50
