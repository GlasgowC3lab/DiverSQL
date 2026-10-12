WITH sales_with_month AS (
    SELECT
        ss.*, 
        s.s_store_sk,
        s.s_store_name,
        CAST(FLOOR(ss.ss_sold_date_sk / 10000) AS VARCHAR) || '-' ||
        LPAD(CAST(FLOOR(ss.ss_sold_date_sk / 100) % 100 AS VARCHAR), 2, '0') AS year_month,
        p.p_discount_active
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
),
monthly_store_profit AS (
    SELECT
        s_store_sk,
        s_store_name,
        year_month,
        SUM(ss_net_profit) AS monthly_net_profit,
        SUM(CASE WHEN p_discount_active = 'Y' THEN ss_ext_sales_price ELSE 0 END) AS promo_sales,
        SUM(ss_ext_sales_price) AS total_sales
    FROM sales_with_month
    GROUP BY s_store_sk, s_store_name, year_month
)
SELECT
    s_store_sk,
    s_store_name,
    year_month,
    monthly_net_profit,
    moving_avg_3_months,
    CASE WHEN moving_avg_3_months > 5000 THEN 'Above Threshold' ELSE 'Normal' END AS profit_trend_flag,
    promo_sales,
    total_sales,
    promo_sales / NULLIF(total_sales, 0) AS promo_sales_ratio
FROM (
    SELECT
        s_store_sk,
        s_store_name,
        year_month,
        monthly_net_profit,
        promo_sales,
        total_sales,
        AVG(monthly_net_profit) OVER (PARTITION BY s_store_sk ORDER BY year_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_months
    FROM monthly_store_profit
) t
ORDER BY s_store_sk, year_month
