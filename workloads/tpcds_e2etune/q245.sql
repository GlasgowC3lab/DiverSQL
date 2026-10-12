WITH cs_agg AS (
    SELECT i.i_brand AS brand,
           SUM(cs.cs_net_profit) AS total_profit,
           COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 60000 AND 85000
      AND cd.cd_credit_rating = 'A'
      AND cd.cd_marital_status = 'M'
    GROUP BY i.i_brand
    HAVING COUNT(*) >= 100
),
sr_agg AS (
    SELECT i.i_brand AS brand,
           SUM(sr.sr_net_loss) AS total_loss,
           COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 60000 AND 85000
      AND cd.cd_credit_rating = 'A'
      AND cd.cd_marital_status = 'M'
    GROUP BY i.i_brand
    HAVING COUNT(*) >= 10
)
SELECT cs.brand,
       cs.sales_cnt,
       cs.total_profit,
       COALESCE(sr.total_loss, 0) AS total_loss,
       cs.total_profit - COALESCE(sr.total_loss, 0) AS net_contribution,
       ROUND((cs.total_profit - COALESCE(sr.total_loss, 0)) / NULLIF(cs.sales_cnt, 0), 2) AS avg_net_profit_per_sale,
       RANK() OVER (ORDER BY (cs.total_profit - COALESCE(sr.total_loss, 0)) DESC) AS brand_rank
FROM cs_agg cs
LEFT JOIN sr_agg sr ON cs.brand = sr.brand
WHERE (cs.total_profit - COALESCE(sr.total_loss, 0)) > 0
ORDER BY net_contribution DESC
LIMIT 10
