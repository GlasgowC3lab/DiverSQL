/* goal: Summarize sales and profit by year and a composite promotion channel string, using regular‑expression filters and string manipulation on promotion attributes. */
WITH filtered_sales AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        p.p_channel_event,
        p.p_channel_catalog,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_number,
        concat(p.p_channel_event, '_', p.p_channel_catalog) AS channel_concat,
        substring(p.p_promo_name, 1, 5) AS promo_name_prefix
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '^PROMO')
      AND p.p_channel_event LIKE 'N%'
)
SELECT
    d_year,
    channel_concat,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit)      AS total_profit,
    COUNT(*)                AS transaction_cnt
FROM filtered_sales
GROUP BY ROLLUP (d_year, channel_concat)
ORDER BY d_year NULLS LAST, channel_concat
LIMIT 100
