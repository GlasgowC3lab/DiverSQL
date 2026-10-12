WITH sales_agg AS (
    SELECT
        p.p_promo_name AS promo_name,
        cd.cd_education_status AS education_status,
        d.d_year AS sales_year,
        d.d_moy AS sales_month,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(COALESCE(sr.sr_net_loss, 0.0)) AS total_return_loss,
        SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0.0)) AS net_profit_after_returns,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    WHERE cd.cd_education_status IN ('College', '4 yr Degree')
      AND d.d_holiday IS NOT NULL
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_name, cd.cd_education_status, d.d_year, d.d_moy
    HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
    promo_name,
    education_status,
    sales_year,
    sales_month,
    total_sales_profit,
    total_return_loss,
    net_profit_after_returns,
    avg_discount_amount,
    RANK() OVER (PARTITION BY sales_year, sales_month ORDER BY net_profit_after_returns DESC) AS promo_monthly_rank
FROM sales_agg
ORDER BY sales_year, sales_month, promo_monthly_rank
LIMIT 200
