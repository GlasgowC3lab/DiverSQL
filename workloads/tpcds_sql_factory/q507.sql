WITH store_promo_agg AS (
    SELECT ss_promo_sk,
           SUM(ss_ext_discount_amt) AS store_total_discount,
           SUM(ss_net_profit) AS store_total_net_profit,
           COUNT(*) AS store_txn_cnt
    FROM store_sales
    GROUP BY ss_promo_sk
),
web_promo_agg AS (
    SELECT ws_promo_sk,
           SUM(ws_ext_discount_amt) AS web_total_discount,
           SUM(ws_net_profit) AS web_total_net_profit,
           COUNT(*) AS web_txn_cnt
    FROM web_sales
    GROUP BY ws_promo_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.p_cost,
    CASE WHEN p.p_cost > 1000 THEN 'High Cost' ELSE 'Low Cost' END AS cost_category,
    COALESCE(spa.store_total_discount, 0) + COALESCE(wpa.web_total_discount, 0) AS total_discount,
    COALESCE(spa.store_total_net_profit, 0) + COALESCE(wpa.web_total_net_profit, 0) AS total_net_profit,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS discount_status,
    DENSE_RANK() OVER (ORDER BY COALESCE(spa.store_total_net_profit, 0) + COALESCE(wpa.web_total_net_profit, 0) DESC) AS profit_dense_rank,
    RANK() OVER (ORDER BY COALESCE(spa.store_total_discount, 0) + COALESCE(wpa.web_total_discount, 0) DESC) AS discount_rank
FROM promotion p
LEFT JOIN store_promo_agg spa ON p.p_promo_sk = spa.ss_promo_sk
LEFT JOIN web_promo_agg wpa ON p.p_promo_sk = wpa.ws_promo_sk
WHERE p.p_promo_id IS NOT NULL
ORDER BY profit_dense_rank
LIMIT 100
