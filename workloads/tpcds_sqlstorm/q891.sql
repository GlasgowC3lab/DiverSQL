WITH
store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy AS month_num,
        i.i_category,
        s.s_state AS state,
        SUM(ss.ss_net_profit) AS profit,
        COUNT(*) AS trans_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY d.d_year, d.d_moy, i.i_category, s.s_state
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy AS month_num,
        i.i_category,
        cc.cc_state AS state,
        SUM(cs.cs_net_profit) AS profit,
        COUNT(*) AS trans_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY d.d_year, d.d_moy, i.i_category, cc.cc_state
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy AS month_num,
        i.i_category,
        w.w_state AS state,
        SUM(ws.ws_net_profit) AS profit,
        COUNT(*) AS trans_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY d.d_year, d.d_moy, i.i_category, w.w_state
),
combined AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
final_agg AS (
    SELECT
        d_year,
        month_num,
        i_category,
        state,
        SUM(profit) AS total_profit,
        SUM(trans_cnt) AS total_trans
    FROM combined
    GROUP BY d_year, month_num, i_category, state
)
SELECT
    d_year,
    month_num,
    i_category,
    state,
    total_profit,
    total_trans,
    total_profit / NULLIF(total_trans, 0) AS avg_profit,
    prior_month_profit,
    CASE
        WHEN prior_month_profit IS NULL OR prior_month_profit = 0 THEN NULL
        ELSE (total_profit - prior_month_profit) / prior_month_profit * 100
    END AS profit_mom_pct,
    profit_rank
FROM (
    SELECT
        d_year,
        month_num,
        i_category,
        state,
        total_profit,
        total_trans,
        LAG(total_profit) OVER (PARTITION BY i_category, state ORDER BY d_year, month_num) AS prior_month_profit,
        RANK() OVER (PARTITION BY d_year, month_num ORDER BY total_profit DESC) AS profit_rank
    FROM final_agg
) t
ORDER BY d_year, month_num, profit_rank
