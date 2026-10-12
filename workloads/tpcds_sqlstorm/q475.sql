WITH store_sales_agg AS (
    SELECT
        s.s_state AS state,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_net_paid) AS store_net_paid,
        COUNT(*) AS store_txn_count,
        SUM(CASE WHEN p.p_promo_id IS NOT NULL THEN ss.ss_net_profit ELSE 0 END) AS promo_store_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year IN (2001, 2002)
    GROUP BY s.s_state, d.d_year
),
web_sales_agg AS (
    SELECT
        w.web_state AS state,
        d.d_year AS year,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_net_paid) AS web_net_paid,
        COUNT(*) AS web_txn_count,
        SUM(CASE WHEN p.p_promo_id IS NOT NULL THEN ws.ws_net_profit ELSE 0 END) AS promo_web_net_profit
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year IN (2001, 2002)
    GROUP BY w.web_state, d.d_year
),
combined AS (
    SELECT
        COALESCE(sa.state, wa.state) AS state,
        COALESCE(sa.year, wa.year) AS year,
        COALESCE(sa.store_net_profit, 0) AS store_net_profit,
        COALESCE(wa.web_net_profit, 0) AS web_net_profit,
        COALESCE(sa.store_net_paid, 0) AS store_net_paid,
        COALESCE(wa.web_net_paid, 0) AS web_net_paid,
        COALESCE(sa.store_txn_count, 0) AS store_txn_count,
        COALESCE(wa.web_txn_count, 0) AS web_txn_count,
        COALESCE(sa.promo_store_net_profit, 0) AS promo_store_net_profit,
        COALESCE(wa.promo_web_net_profit, 0) AS promo_web_net_profit,
        (COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) AS total_net_profit,
        (COALESCE(sa.store_net_paid, 0) + COALESCE(wa.web_net_paid, 0)) AS total_net_paid
    FROM store_sales_agg sa
    FULL OUTER JOIN web_sales_agg wa
        ON sa.state = wa.state AND sa.year = wa.year
),
yoy AS (
    SELECT
        state,
        year,
        total_net_profit,
        total_net_paid,
        total_net_profit / NULLIF(total_net_paid, 0) AS profit_margin,
        store_net_profit,
        web_net_profit,
        promo_store_net_profit,
        promo_web_net_profit,
        total_net_profit - LAG(total_net_profit) OVER (PARTITION BY state ORDER BY year) AS yoy_profit_change,
        (total_net_profit - LAG(total_net_profit) OVER (PARTITION BY state ORDER BY year)) /
            NULLIF(LAG(total_net_profit) OVER (PARTITION BY state ORDER BY year), 0) * 100.0 AS yoy_profit_percent_change
    FROM combined
),
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY yoy_profit_percent_change DESC) AS profit_change_rank
    FROM yoy
    WHERE year = 2002
)
SELECT
    state,
    year,
    total_net_profit,
    total_net_paid,
    profit_margin,
    store_net_profit,
    web_net_profit,
    promo_store_net_profit,
    promo_web_net_profit,
    yoy_profit_change,
    yoy_profit_percent_change,
    profit_change_rank
FROM ranked
ORDER BY profit_change_rank
LIMIT 10
