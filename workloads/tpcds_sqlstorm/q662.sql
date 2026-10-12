WITH store_sales_agg AS (
    SELECT
        d.d_year AS year,
        'store' AS channel,
        SUM(ss.ss_ext_sales_price) AS revenue,
        SUM(ss.ss_ext_discount_amt) AS discount,
        COUNT(*) AS orders,
        SUM(p.p_cost) AS promo_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, 'store'
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        'catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS revenue,
        SUM(cs.cs_ext_discount_amt) AS discount,
        COUNT(*) AS orders,
        SUM(p.p_cost) AS promo_cost
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, 'catalog'
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS revenue,
        SUM(ws.ws_ext_discount_amt) AS discount,
        COUNT(*) AS orders,
        SUM(p.p_cost) AS promo_cost
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, 'web'
),
combined AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
)
SELECT
    year,
    channel,
    revenue,
    discount,
    orders,
    promo_cost,
    RANK() OVER (PARTITION BY year ORDER BY revenue DESC) AS revenue_rank
FROM combined
ORDER BY year, revenue_rank
LIMIT 100
