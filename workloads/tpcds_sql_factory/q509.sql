WITH cust_sales AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           c.c_birth_country,
           SUM(ss.ss_net_profit) AS store_net_profit,
           SUM(ss.ss_ext_discount_amt) AS store_discount,
           SUM(ss.ss_net_paid_inc_tax) AS store_net_paid,
           COUNT(*) AS store_txn_cnt
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, c.c_birth_country
),
 cust_web AS (
    SELECT c.c_customer_sk,
           SUM(ws.ws_net_profit) AS web_net_profit,
           SUM(ws.ws_ext_discount_amt) AS web_discount,
           SUM(ws.ws_net_paid_inc_tax) AS web_net_paid,
           COUNT(*) AS web_txn_cnt
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
 promo_cost_store AS (
    SELECT ss.ss_customer_sk AS c_customer_sk,
           SUM(p.p_cost) AS promo_cost_store
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY ss.ss_customer_sk
),
 promo_cost_web AS (
    SELECT ws.ws_bill_customer_sk AS c_customer_sk,
           SUM(p.p_cost) AS promo_cost_web
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY ws.ws_bill_customer_sk
),
 cust_promo_cost AS (
    SELECT COALESCE(s.c_customer_sk, w.c_customer_sk) AS c_customer_sk,
           COALESCE(s.promo_cost_store, 0) + COALESCE(w.promo_cost_web, 0) AS total_promo_cost
    FROM promo_cost_store s
    FULL OUTER JOIN promo_cost_web w ON s.c_customer_sk = w.c_customer_sk
),
 combined AS (
    SELECT
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.c_birth_country,
        cs.store_net_profit + cw.web_net_profit AS total_net_profit,
        cs.store_discount + cw.web_discount AS total_discount,
        cs.store_net_paid + cw.web_net_paid AS total_net_paid,
        cs.store_txn_cnt + cw.web_txn_cnt AS total_txn_cnt,
        cp.total_promo_cost,
        (cs.store_net_profit + cw.web_net_profit) - cp.total_promo_cost AS adjusted_profit,
        CASE WHEN (cs.store_discount + cw.web_discount) > 0 THEN 'Discounted' ELSE 'No Discount' END AS discount_flag,
        CASE WHEN (cs.store_discount + cw.web_discount) / NULLIF(cs.store_net_paid + cw.web_net_paid, 0) > 0.05 THEN 'Effective' ELSE 'Ineffective' END AS promo_effectiveness,
        ROW_NUMBER() OVER (PARTITION BY cs.c_birth_country ORDER BY (cs.store_net_profit + cw.web_net_profit) - cp.total_promo_cost DESC) AS country_rank
    FROM cust_sales cs
    JOIN cust_web cw ON cs.c_customer_sk = cw.c_customer_sk
    LEFT JOIN cust_promo_cost cp ON cs.c_customer_sk = cp.c_customer_sk
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_birth_country,
    total_net_profit,
    total_discount,
    total_net_paid,
    total_promo_cost,
    adjusted_profit,
    discount_flag,
    promo_effectiveness,
    country_rank
FROM combined
WHERE country_rank <= 5
ORDER BY c_birth_country, country_rank
