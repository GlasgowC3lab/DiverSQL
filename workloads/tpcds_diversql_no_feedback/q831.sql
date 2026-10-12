WITH agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
       AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_count BETWEEN 2 AND 5
      AND cd.cd_purchase_estimate >= 3000
      AND cs.cs_net_paid_inc_tax > 1000
      AND cr.cr_refunded_cash > 100
      AND ss.ss_net_profit > 0
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT
    cd_gender,
    cd_marital_status,
    total_net_paid,
    total_refunded_cash,
    total_store_profit,
    order_cnt,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS row_num
FROM agg
WHERE total_store_profit > 500
ORDER BY total_net_paid DESC
LIMIT 100
