WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_net_profit,
        ca.ca_city,
        d.d_year,
        d.d_month_seq,
        p.p_channel_catalog
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
      AND ca.ca_city LIKE 'S%'
      AND regexp_like(ca.ca_city, '^.*view$')
),
monthly AS (
    SELECT
        d_year,
        d_month_seq,
        SUM(cs_net_profit) AS month_profit,
        MAX(regexp_extract(ca_city, '^([A-Za-z]+)', 1)) AS city_prefix_example
    FROM filtered_sales
    GROUP BY d_year, d_month_seq
)
SELECT
    d_year,
    d_month_seq,
    month_profit,
    city_prefix_example,
    LAG(month_profit) OVER (PARTITION BY d_year ORDER BY d_month_seq) AS prev_month_profit,
    SUM(month_profit) OVER (PARTITION BY d_year ORDER BY d_month_seq ROWS UNBOUNDED PRECEDING) AS running_year_profit,
    CASE
        WHEN month_profit > (SELECT AVG(cs_net_profit) FROM catalog_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg
FROM monthly
ORDER BY d_year, d_month_seq
