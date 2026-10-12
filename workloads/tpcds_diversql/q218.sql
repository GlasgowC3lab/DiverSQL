WITH hour_store_all AS (
    SELECT s.s_store_sk,
           s.s_store_id,
           t.t_hour,
           t.t_time_sk
    FROM store s
    CROSS JOIN (
        SELECT DISTINCT t_hour, t_time_sk
        FROM time_dim
    ) t
),
promo_agg AS (
    SELECT p.p_promo_id,
           SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id
)

SELECT
    hs.s_store_id AS store_id,
    hs.t_hour AS hour,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS transaction_cnt,
    (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = hs.s_store_sk
    ) AS avg_store_profit
FROM hour_store_all hs
JOIN store_sales ss
    ON ss.ss_store_sk = hs.s_store_sk
   AND ss.ss_sold_time_sk = hs.t_time_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE hs.t_hour BETWEEN 9 AND 12
  AND hd.hd_buy_potential IN ('1001-5000', '>10000')
  AND EXISTS (
        SELECT 1 FROM promo_agg pa
        WHERE pa.p_promo_id = p.p_promo_id
          AND pa.total_discount > 500
    )
GROUP BY hs.s_store_id, hs.t_hour, hs.s_store_sk

UNION

SELECT
    hs.s_store_id AS store_id,
    hs.t_hour AS hour,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS transaction_cnt,
    (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = hs.s_store_sk
    ) AS avg_store_profit
FROM hour_store_all hs
JOIN store_sales ss
    ON ss.ss_store_sk = hs.s_store_sk
   AND ss.ss_sold_time_sk = hs.t_time_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE hs.t_hour BETWEEN 15 AND 18
  AND hd.hd_buy_potential IN ('0-500', '501-1000')
GROUP BY hs.s_store_id, hs.t_hour, hs.s_store_sk

ORDER BY total_net_profit DESC
LIMIT 100
