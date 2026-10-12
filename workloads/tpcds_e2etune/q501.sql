WITH store_agg AS (
    SELECT
        c.c_customer_id,
        s.s_store_id,
        s.s_state,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(*) AS store_txn_cnt,
        SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
      AND c.c_birth_country = 'MEXICO'
    GROUP BY c.c_customer_id, s.s_store_id, s.s_state
),
web_agg AS (
    SELECT
        c.c_customer_id,
        wp.wp_web_page_id,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(*) AS web_txn_cnt,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND wp.wp_type = 'product'
      AND c.c_birth_country = 'MEXICO'
    GROUP BY c.c_customer_id, wp.wp_web_page_id
)
SELECT
    ca.c_customer_id,
    COALESCE(sa.store_net_paid, 0) AS store_net_paid,
    COALESCE(wa.web_net_paid, 0) AS web_net_paid,
    (COALESCE(sa.store_net_paid, 0) + COALESCE(wa.web_net_paid, 0)) AS total_net_paid,
    COALESCE(sa.store_profit, 0) AS store_profit,
    COALESCE(wa.web_profit, 0) AS web_profit,
    (COALESCE(sa.store_profit, 0) + COALESCE(wa.web_profit, 0)) AS total_profit,
    (COALESCE(sa.store_txn_cnt, 0) + COALESCE(wa.web_txn_cnt, 0)) AS total_txn_cnt,
    RANK() OVER (ORDER BY (COALESCE(sa.store_net_paid, 0) + COALESCE(wa.web_net_paid, 0)) DESC) AS revenue_rank
FROM (
    SELECT DISTINCT c.c_customer_id
    FROM customer c
    WHERE c.c_birth_country = 'MEXICO'
) ca
LEFT JOIN store_agg sa ON ca.c_customer_id = sa.c_customer_id
LEFT JOIN web_agg wa ON ca.c_customer_id = wa.c_customer_id
WHERE (COALESCE(sa.store_net_paid, 0) + COALESCE(wa.web_net_paid, 0)) > 1000
ORDER BY total_net_paid DESC
LIMIT 10
