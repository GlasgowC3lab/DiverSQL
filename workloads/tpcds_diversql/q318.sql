WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
stores_without_price_returns AS (
    SELECT s.s_store_sk
    FROM store s
    EXCEPT
    SELECT sr.sr_store_sk
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%price%'
),
promo_filtered AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           regexp_extract(p.p_promo_id, '[A-Z]+$', 0) AS promo_suffix
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '^Summer.*')
)
SELECT
    s.s_store_name,
    pf.p_promo_name,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS txn_count,
    pf.promo_suffix
FROM sampled_sales ss
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promo_filtered pf ON ss.ss_promo_sk = pf.p_promo_sk
WHERE s.s_store_sk IN (SELECT s_store_sk FROM stores_without_price_returns)
  AND ca.ca_city LIKE 'A%'
GROUP BY GROUPING SETS (
    (s.s_store_name, pf.p_promo_name, ca.ca_city, ca.ca_state, pf.promo_suffix),
    (s.s_store_name, pf.p_promo_name, pf.promo_suffix),
    (s.s_store_name)
)
ORDER BY total_net_profit DESC
LIMIT 100
