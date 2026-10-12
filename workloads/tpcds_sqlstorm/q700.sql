WITH store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state AS state,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_ext_sales_price) AS revenue,
        SUM(ss.ss_quantity) AS units_sold,
        SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit_adj
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_state
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        w.web_state AS state,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_ext_sales_price) AS revenue,
        SUM(ws.ws_quantity) AS units_sold,
        SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit_adj
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, w.web_state
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_state AS state,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_ext_sales_price) AS revenue,
        SUM(cs.cs_quantity) AS units_sold,
        SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit_adj
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state
)
SELECT
    d_year,
    d_month_seq,
    state,
    channel,
    net_profit_adj,
    revenue,
    units_sold,
    total_state_profit,
    net_profit_adj / total_state_profit AS profit_share,
    RANK() OVER (PARTITION BY d_year, d_month_seq, state ORDER BY net_profit_adj DESC) AS profit_rank
FROM (
    SELECT
        d_year,
        d_month_seq,
        state,
        channel,
        net_profit_adj,
        revenue,
        units_sold,
        SUM(net_profit_adj) OVER (PARTITION BY d_year, d_month_seq, state) AS total_state_profit
    FROM (
        SELECT * FROM store_sales_agg
        UNION ALL
        SELECT * FROM web_sales_agg
        UNION ALL
        SELECT * FROM catalog_sales_agg
    ) AS combined
) AS t
ORDER BY d_year, d_month_seq, state, profit_rank
