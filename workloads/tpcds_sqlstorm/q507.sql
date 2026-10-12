WITH store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state AS state,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    GROUP BY d.d_year, d.d_month_seq, s.s_state
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ca.ca_state AS state,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_quantity) AS total_quantity,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    GROUP BY d.d_year, d.d_month_seq, ca.ca_state
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_state AS state,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_quantity) AS total_quantity,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state
),
unioned AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
),
final AS (
    SELECT
        channel,
        d_year,
        d_month_seq,
        state,
        total_net_paid,
        total_net_profit - total_return_loss AS net_profit_after_returns,
        total_discount / NULLIF(total_quantity, 0) AS avg_discount_per_item,
        total_net_paid - LAG(total_net_paid) OVER (PARTITION BY channel, state ORDER BY d_year, d_month_seq) AS diff_net_paid,
        LAG(total_net_paid) OVER (PARTITION BY channel, state ORDER BY d_year, d_month_seq) AS prev_net_paid
    FROM unioned
)
SELECT
    channel,
    d_year,
    d_month_seq,
    state,
    total_net_paid,
    net_profit_after_returns,
    avg_discount_per_item,
    CASE
        WHEN prev_net_paid IS NOT NULL AND prev_net_paid <> 0 THEN diff_net_paid / prev_net_paid
        ELSE NULL
    END AS yoy_growth_net_paid
FROM final
WHERE prev_net_paid IS NOT NULL
ORDER BY channel, state, d_year, d_month_seq
LIMIT 200
