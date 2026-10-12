WITH store_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_date_sk,
        d.d_year,
        d.d_current_month,
        SUM(ss.ss_net_paid_inc_tax) AS store_net_paid_inc_tax,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_store_items
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        d.d_date_sk,
        d.d_year,
        d.d_current_month
),
web_agg AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_current_month,
        SUM(ws.ws_net_paid_inc_tax) AS web_net_paid_inc_tax,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_web_items
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_date_sk,
        d.d_year,
        d.d_current_month
)
SELECT
    cc.cc_name,
    cc.cc_company_name,
    s.s_store_name,
    sa.d_year,
    sa.d_current_month,
    sa.store_net_paid_inc_tax,
    wa.web_net_paid_inc_tax,
    (sa.store_net_paid_inc_tax + wa.web_net_paid_inc_tax) AS total_net_paid_inc_tax,
    (sa.store_net_profit + wa.web_net_profit) AS total_net_profit,
    CASE
        WHEN (sa.store_net_paid_inc_tax + wa.web_net_paid_inc_tax) = 0 THEN NULL
        ELSE (sa.store_net_profit + wa.web_net_profit) / (sa.store_net_paid_inc_tax + wa.web_net_paid_inc_tax)
    END AS profit_margin,
    sa.distinct_store_items,
    wa.distinct_web_items,
    RANK() OVER (ORDER BY (sa.store_net_profit + wa.web_net_profit) DESC) AS profit_rank
FROM store_agg sa
JOIN web_agg wa
    ON sa.d_date_sk = wa.d_date_sk
JOIN store s
    ON s.s_store_sk = sa.s_store_sk
JOIN date_dim d_cc
    ON s.s_closed_date_sk = d_cc.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_cc.d_date_sk
ORDER BY total_net_profit DESC
LIMIT 100
