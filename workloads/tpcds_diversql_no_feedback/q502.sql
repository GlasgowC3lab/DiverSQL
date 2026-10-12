WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        ca.ca_city,
        p.p_promo_name,
        p.p_promo_id
    FROM tpcds.store_sales ss
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(ca.ca_city, '(?i)ville')
      AND regexp_like(p.p_promo_name, '^Summer')
)
SELECT
    s.s_store_name,
    fs.p_promo_name,
    regexp_extract(fs.p_promo_id, '\\d+', 0) AS promo_id_digits,
    SUM(fs.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count
FROM filtered_sales fs
JOIN tpcds.store s
    ON fs.ss_store_sk = s.s_store_sk
GROUP BY
    s.s_store_name,
    fs.p_promo_name,
    regexp_extract(fs.p_promo_id, '\\d+', 0)
ORDER BY total_net_profit DESC
OFFSET 0 LIMIT 100
