WITH store_sales_events AS (
    SELECT 
        ss.ss_sold_date_sk AS date_sk,
        s.s_store_name AS location,
        i.i_category AS category,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
store_returns_events AS (
    SELECT 
        sr.sr_returned_date_sk AS date_sk,
        s.s_store_name AS location,
        i.i_category AS category,
        -sr.sr_return_quantity AS quantity,
        -sr.sr_refunded_cash AS net_paid,
        -sr.sr_net_loss AS net_profit
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
),
catalog_sales_events AS (
    SELECT 
        cs.cs_sold_date_sk AS date_sk,
        cc.cc_name AS location,
        i.i_category AS category,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
catalog_returns_events AS (
    SELECT 
        cr.cr_returned_date_sk AS date_sk,
        cc.cc_name AS location,
        i.i_category AS category,
        -cr.cr_return_quantity AS quantity,
        -cr.cr_refunded_cash AS net_paid,
        -cr.cr_net_loss AS net_profit
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
),
web_sales_events AS (
    SELECT 
        ws.ws_sold_date_sk AS date_sk,
        site.web_name AS location,
        i.i_category AS category,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
web_returns_events AS (
    SELECT 
        wr.wr_returned_date_sk AS date_sk,
        'Web Return' AS location,
        i.i_category AS category,
        -wr.wr_return_quantity AS quantity,
        -wr.wr_refunded_cash AS net_paid,
        -wr.wr_net_loss AS net_profit
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
combined_events AS (
    SELECT * FROM store_sales_events
    UNION ALL
    SELECT * FROM store_returns_events
    UNION ALL
    SELECT * FROM catalog_sales_events
    UNION ALL
    SELECT * FROM catalog_returns_events
    UNION ALL
    SELECT * FROM web_sales_events
    UNION ALL
    SELECT * FROM web_returns_events
),
aggregated AS (
    SELECT 
        d.d_year,
        ce.location,
        ce.category,
        SUM(ce.net_paid) AS total_net_paid,
        SUM(ce.net_profit) AS total_net_profit,
        SUM(ce.quantity) AS net_quantity
    FROM combined_events ce
    JOIN date_dim d ON ce.date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, ce.location, ce.category
)
SELECT 
    a.d_year,
    a.location,
    a.category,
    a.total_net_paid,
    a.total_net_profit,
    a.net_quantity,
    AVG(a.total_net_paid) OVER (PARTITION BY a.location ORDER BY a.d_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3yr_net_paid
FROM aggregated a
ORDER BY a.d_year, a.total_net_paid DESC
LIMIT 100
