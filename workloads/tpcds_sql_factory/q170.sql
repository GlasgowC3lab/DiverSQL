WITH promo_quarter AS (
    SELECT
        cs.cs_promo_sk,
        d.d_year,
        d.d_quarter_seq,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        MAX(w.web_tax_percentage) AS tax_percentage
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    GROUP BY cs.cs_promo_sk, d.d_year, d.d_quarter_seq
),
promo_with_tax AS (
    SELECT
        cs_promo_sk,
        d_year,
        d_quarter_seq,
        total_net_profit,
        total_discount,
        total_orders,
        avg_sales_price,
        tax_percentage,
        total_net_profit * (1 - COALESCE(tax_percentage, 0) / 100) AS net_profit_after_tax,
        CASE
            WHEN total_net_profit > 100000 THEN 'High'
            WHEN total_net_profit BETWEEN 50000 AND 100000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM promo_quarter
),
ranked_promos AS (
    SELECT
        cs_promo_sk,
        d_year,
        d_quarter_seq,
        total_orders,
        total_net_profit,
        net_profit_after_tax,
        total_discount,
        avg_sales_price,
        profit_category,
        DENSE_RANK() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY net_profit_after_tax DESC) AS promo_rank
    FROM promo_with_tax
)
SELECT
    d_year,
    d_quarter_seq,
    cs_promo_sk,
    total_orders,
    ROUND(total_net_profit, 2) AS total_net_profit,
    ROUND(net_profit_after_tax, 2) AS net_profit_after_tax,
    ROUND(total_discount, 2) AS total_discount,
    ROUND(avg_sales_price, 2) AS avg_sales_price,
    profit_category,
    promo_rank
FROM ranked_promos
WHERE promo_rank <= 5
ORDER BY d_year, d_quarter_seq, promo_rank
