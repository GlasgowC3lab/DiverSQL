WITH store_metrics AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        s.s_state AS state,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, s.s_state
),
catalog_metrics AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        cc.cc_state AS state,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state
),
web_metrics AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        w.w_state AS state,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, w.w_state
),
combined AS (
    SELECT * FROM store_metrics
    UNION ALL
    SELECT * FROM catalog_metrics
    UNION ALL
    SELECT * FROM web_metrics
),
aggregated AS (
    SELECT
        year,
        month,
        state,
        SUM(total_sales) AS total_sales,
        SUM(total_profit) AS total_profit,
        SUM(total_discount) AS total_discount,
        SUM(total_return_loss) AS total_return_loss,
        SUM(total_sales) - SUM(total_return_loss) AS net_sales_after_returns,
        ROUND((SUM(total_discount) / NULLIF(SUM(total_sales), 0)) * 100, 2) AS discount_pct
    FROM combined
    GROUP BY year, month, state
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY year, month ORDER BY total_sales DESC) AS sales_rank
    FROM aggregated
)
SELECT
    year,
    month,
    state,
    total_sales,
    total_profit,
    total_discount,
    total_return_loss,
    net_sales_after_returns,
    discount_pct,
    sales_rank,
    ROUND(total_sales / SUM(total_sales) OVER (PARTITION BY year, month) * 100, 2) AS sales_share_pct
FROM ranked
WHERE sales_rank <= 10
ORDER BY year, month, sales_rank
LIMIT 200
