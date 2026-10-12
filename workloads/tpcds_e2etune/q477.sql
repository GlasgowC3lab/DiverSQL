WITH promo_demo_sales AS (
    SELECT
        p.p_promo_name,
        cd.cd_gender,
        cd.cd_credit_rating,
        COUNT(*) AS sales_cnt,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_net_paid) AS avg_net_paid,
        SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND cd.cd_gender IN ('M', 'F')
      AND cd.cd_purchase_estimate >= 1500
      AND cd.cd_dep_employed_count >= 1
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY p.p_promo_name, cd.cd_gender, cd.cd_credit_rating
    HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
    pds.p_promo_name,
    pds.cd_gender,
    pds.cd_credit_rating,
    pds.sales_cnt,
    pds.total_profit,
    pds.avg_net_paid,
    pds.total_qty,
    RANK() OVER (PARTITION BY pds.cd_gender ORDER BY pds.total_profit DESC) AS profit_rank_by_gender
FROM promo_demo_sales pds
ORDER BY pds.total_profit DESC
LIMIT 100
