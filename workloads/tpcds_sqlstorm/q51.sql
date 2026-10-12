WITH
date_filter AS (
    SELECT d_date_sk, d_year, d_month_seq, d_quarter_seq
    FROM date_dim
    WHERE d_year BETWEEN 2001 AND 2002
),
store_sales_agg AS (
    SELECT
        s.s_state AS state,
        i.i_category AS category,
        'store' AS channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        approx_distinct(ss.ss_ticket_number) AS order_cnt,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_returns_loss
    FROM store_sales ss
    JOIN date_filter d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    GROUP BY s.s_state, i.i_category
),
catalog_sales_agg AS (
    SELECT
        cc.cc_state AS state,
        i.i_category AS category,
        'catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        approx_distinct(cs.cs_order_number) AS order_cnt,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_returns_loss
    FROM catalog_sales cs
    JOIN date_filter d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    GROUP BY cc.cc_state, i.i_category
),
web_sales_agg AS (
    SELECT
        w.web_state AS state,
        i.i_category AS category,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        approx_distinct(ws.ws_order_number) AS order_cnt,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_returns_loss
    FROM web_sales ws
    JOIN date_filter d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    GROUP BY w.web_state, i.i_category
),
combined AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
)
SELECT
    state,
    category,
    channel,
    total_sales,
    total_profit,
    total_discount,
    order_cnt,
    total_returns_loss,
    (total_profit - total_returns_loss) AS net_profit_after_returns,
    ROUND((total_profit - total_returns_loss) / NULLIF(total_sales, 0) * 100, 2) AS profit_margin_pct,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY (total_profit - total_returns_loss) DESC) AS profit_rank_state
FROM combined
WHERE total_sales > 0
ORDER BY state, profit_rank_state
LIMIT 100
