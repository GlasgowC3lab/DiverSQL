WITH
date_filter AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2001
),
catalog_sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cc.cc_state AS state,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        MAX(cs.cs_call_center_sk) AS join_key
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_filter d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY cs.cs_sold_date_sk, cc.cc_state
),
store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        st.s_state AS state,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        MAX(ss.ss_store_sk) AS join_key
    FROM store_sales ss
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN date_filter d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY ss.ss_sold_date_sk, st.s_state
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws_site.web_state AS state,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        MAX(ws.ws_web_site_sk) AS join_key
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_filter d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY ws.ws_sold_date_sk, ws_site.web_state
),
channel_sales AS (
    SELECT 'CATALOG' AS channel, *
    FROM catalog_sales_agg
    UNION ALL
    SELECT 'STORE' AS channel, *
    FROM store_sales_agg
    UNION ALL
    SELECT 'WEB' AS channel, *
    FROM web_sales_agg
),
sales_with_returns AS (
    SELECT
        cs.channel,
        cs.date_sk,
        d.d_date AS sale_date,
        cs.state,
        cs.total_net_paid,
        cs.total_net_profit,
        cs.total_quantity,
        cs.distinct_customers,
        cs.join_key,
        CASE
            WHEN cs.total_net_paid = 0 THEN NULL
            ELSE cs.total_net_profit / cs.total_net_paid
        END AS profit_margin,
        CONCAT(cs.channel, ' - ', COALESCE(cs.state, 'UNKNOWN')) AS description,
        (
            SELECT SUM(ret.ret_quantity)
            FROM (
                SELECT cr.cr_return_quantity AS ret_quantity,
                       cr.cr_returned_date_sk AS ret_date_sk,
                       cc.cc_state AS ret_state
                FROM catalog_returns cr
                JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
                UNION ALL
                SELECT sr.sr_return_quantity,
                       sr.sr_returned_date_sk,
                       st.s_state
                FROM store_returns sr
                JOIN store st ON sr.sr_store_sk = st.s_store_sk
            ) ret
            WHERE ret.ret_date_sk = cs.date_sk
              AND ret.ret_state = cs.state
        ) AS total_return_qty,
        ROW_NUMBER() OVER (PARTITION BY cs.state ORDER BY cs.total_net_profit DESC) AS profit_rank_state,
        DENSE_RANK() OVER (PARTITION BY cs.channel, cs.date_sk ORDER BY cs.total_net_paid DESC) AS sales_rank_date
    FROM channel_sales cs
    JOIN date_dim d ON cs.date_sk = d.d_date_sk
)
SELECT
    swr.channel,
    swr.sale_date,
    swr.state,
    swr.total_net_paid,
    swr.total_net_profit,
    swr.total_quantity,
    swr.distinct_customers,
    swr.profit_margin,
    swr.total_return_qty,
    swr.description,
    swr.profit_rank_state,
    swr.sales_rank_date
FROM sales_with_returns swr
WHERE
    (swr.profit_margin > 0.05 OR swr.total_return_qty > 100)
    AND COALESCE(swr.state, '') <> ''
ORDER BY swr.channel, swr.state, swr.profit_rank_state
LIMIT 100
