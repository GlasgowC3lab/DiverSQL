WITH store_monthly AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq
),
promo_channels AS (
    SELECT
        p.p_promo_sk,
        channel
    FROM promotion p
    CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel)
    WHERE p.p_channel_details IS NOT NULL
),
combined AS (
    SELECT
        profit,
        d_year,
        d_month_seq,
        'store' AS source_type
    FROM store_monthly
    WHERE profit > 1000
    UNION ALL
    SELECT
        cs.cs_net_profit AS profit,
        d.d_year,
        d.d_month_seq,
        'catalog' AS source_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_net_profit > 1000
)
SELECT
    c.source_type,
    c.d_year,
    c.d_month_seq,
    c.profit,
    yr.d_year AS filter_year,
    (SELECT COUNT(*) FROM promo_channels) AS total_promo_channels
FROM combined c
CROSS JOIN (
    SELECT DISTINCT d_year FROM date_dim WHERE d_year IN (2001, 2002)
) yr
ORDER BY c.d_year, c.d_month_seq DESC, c.source_type
