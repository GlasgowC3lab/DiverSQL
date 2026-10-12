WITH store_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        s.s_state AS state,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_state
),
store_returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        s.s_state AS state,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_state
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        cc.cc_state AS state,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state
),
catalog_returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        cc.cc_state AS state,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        wsit.web_state AS state,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    GROUP BY d.d_year, d.d_month_seq, wsit.web_state
),
web_returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        wsit.web_state AS state,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    GROUP BY d.d_year, d.d_month_seq, wsit.web_state
),
combined AS (
    SELECT
        'store' AS channel,
        ss.year,
        ss.month,
        ss.state,
        ss.total_sales,
        ss.total_profit,
        ss.total_discount,
        ss.total_quantity,
        COALESCE(sr.total_return_amount, 0) AS total_return_amount,
        COALESCE(sr.total_return_qty, 0) AS total_return_qty,
        COALESCE(sr.total_return_loss, 0) AS total_return_loss
    FROM store_sales_agg ss
    LEFT JOIN store_returns_agg sr
        ON ss.year = sr.year AND ss.month = sr.month AND ss.state = sr.state

    UNION ALL

    SELECT
        'catalog' AS channel,
        cs.year,
        cs.month,
        cs.state,
        cs.total_sales,
        cs.total_profit,
        cs.total_discount,
        cs.total_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_qty, 0) AS total_return_qty,
        COALESCE(cr.total_return_loss, 0) AS total_return_loss
    FROM catalog_sales_agg cs
    LEFT JOIN catalog_returns_agg cr
        ON cs.year = cr.year AND cs.month = cr.month AND cs.state = cr.state

    UNION ALL

    SELECT
        'web' AS channel,
        ws.year,
        ws.month,
        ws.state,
        ws.total_sales,
        ws.total_profit,
        ws.total_discount,
        ws.total_quantity,
        COALESCE(wr.total_return_amount, 0) AS total_return_amount,
        COALESCE(wr.total_return_qty, 0) AS total_return_qty,
        COALESCE(wr.total_return_loss, 0) AS total_return_loss
    FROM web_sales_agg ws
    LEFT JOIN web_returns_agg wr
        ON ws.year = wr.year AND ws.month = wr.month AND ws.state = wr.state
),
final AS (
    SELECT
        channel,
        year,
        month,
        state,
        total_sales,
        total_profit,
        total_discount,
        total_quantity,
        total_return_amount,
        total_return_qty,
        total_return_loss,
        (total_profit - total_return_loss) AS net_profit_after_returns,
        (total_return_qty * 1.0 / NULLIF(total_quantity, 0)) AS return_rate,
        RANK() OVER (PARTITION BY year, month ORDER BY total_profit DESC) AS profit_state_rank
    FROM combined
    WHERE year IN (2000, 2001)
)
SELECT *
FROM final
ORDER BY year, month, profit_state_rank
LIMIT 100
