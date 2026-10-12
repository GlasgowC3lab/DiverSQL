WITH
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_state AS state,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS quantity,
        SUM(cs.cs_ext_discount_amt) AS discount_amt,
        SUM(COALESCE(cr.cr_refunded_cash, 0) + COALESCE(cr.cr_reversed_charge, 0) + COALESCE(cr.cr_store_credit, 0)) AS return_amount,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS return_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state
),
store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state AS state,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS quantity,
        SUM(ss.ss_ext_discount_amt) AS discount_amt,
        SUM(COALESCE(sr.sr_refunded_cash, 0) + COALESCE(sr.sr_reversed_charge, 0) + COALESCE(sr.sr_store_credit, 0)) AS return_amount,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS return_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_state
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        we.web_state AS state,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS quantity,
        SUM(ws.ws_ext_discount_amt) AS discount_amt,
        SUM(COALESCE(wr.wr_refunded_cash, 0) + COALESCE(wr.wr_reversed_charge, 0) + COALESCE(wr.wr_account_credit, 0)) AS return_amount,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS return_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    GROUP BY d.d_year, d.d_month_seq, we.web_state
),
combined AS (
    SELECT
        'catalog' AS channel,
        d_year,
        d_month_seq,
        state,
        net_paid,
        net_profit,
        quantity,
        discount_amt,
        return_amount,
        return_loss
    FROM catalog_sales_agg
    UNION ALL
    SELECT
        'store' AS channel,
        d_year,
        d_month_seq,
        state,
        net_paid,
        net_profit,
        quantity,
        discount_amt,
        return_amount,
        return_loss
    FROM store_sales_agg
    UNION ALL
    SELECT
        'web' AS channel,
        d_year,
        d_month_seq,
        state,
        net_paid,
        net_profit,
        quantity,
        discount_amt,
        return_amount,
        return_loss
    FROM web_sales_agg
),
final AS (
    SELECT
        channel,
        d_year,
        d_month_seq,
        state,
        net_paid,
        net_profit,
        quantity,
        discount_amt,
        return_amount,
        return_loss,
        net_paid - return_amount AS net_sales_after_returns,
        ROUND((net_profit / NULLIF(net_paid, 0)) * 100, 2) AS profit_margin_percent,
        RANK() OVER (PARTITION BY d_year, channel ORDER BY net_profit DESC) AS profit_rank
    FROM combined
    WHERE net_paid > 0
)
SELECT
    channel,
    d_year,
    d_month_seq,
    state,
    net_sales_after_returns,
    profit_margin_percent,
    profit_rank,
    net_sales_after_returns - LAG(net_sales_after_returns) OVER (PARTITION BY channel, state ORDER BY d_year, d_month_seq) AS delta_vs_prev_month,
    ((net_sales_after_returns - LAG(net_sales_after_returns) OVER (PARTITION BY channel, state ORDER BY d_year, d_month_seq))
        / NULLIF(LAG(net_sales_after_returns) OVER (PARTITION BY channel, state ORDER BY d_year, d_month_seq), 0)) * 100
        AS pct_change_vs_prev_month
FROM final
ORDER BY d_year, d_month_seq, channel, state
LIMIT 200
