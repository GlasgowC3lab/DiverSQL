WITH promo_keys AS (
    SELECT p_promo_sk FROM (
        SELECT DISTINCT p.p_promo_sk
        FROM catalog_sales cs
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND regexp_like(p.p_promo_name, '[0-9]{2}')
    )
    INTERSECT
    SELECT p_promo_sk FROM (
        SELECT DISTINCT p.p_promo_sk
        FROM web_sales ws
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND p.p_promo_name LIKE '%Sale%'
    )
)
SELECT
    p.p_promo_sk,
    p.p_promo_name,
    substring(p.p_promo_name, 1, 10) AS promo_name_prefix,
    concat('Promo_', cast(p.p_promo_sk AS varchar)) AS promo_key,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
FROM promo_keys pk
JOIN promotion p ON pk.p_promo_sk = p.p_promo_sk
LEFT JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN catalog_sales cs2 ON cr.cr_order_number = cs2.cs_order_number
    WHERE cs2.cs_promo_sk = p.p_promo_sk
)
  AND wsite.web_name IS NOT NULL
  AND regexp_like(wsite.web_name, '^.*Online.*$')
  AND wsite.web_name LIKE '%Shop%'
GROUP BY
    p.p_promo_sk,
    p.p_promo_name,
    substring(p.p_promo_name, 1, 10),
    concat('Promo_', cast(p.p_promo_sk AS varchar))
ORDER BY total_catalog_profit DESC
LIMIT 100
