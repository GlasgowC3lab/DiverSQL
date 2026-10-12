WITH
    unified_sales AS (
        SELECT
            ss.ss_sold_date_sk AS date_sk,
            ss.ss_store_sk AS dim_sk,
            ss.ss_net_paid_inc_tax AS sales_amount,
            ss.ss_net_profit AS sales_profit,
            ss.ss_promo_sk AS promo_sk,
            'store' AS channel
        FROM store_sales ss
        UNION ALL
        SELECT
            cs.cs_sold_date_sk AS date_sk,
            cs.cs_call_center_sk AS dim_sk,
            cs.cs_net_paid_inc_tax AS sales_amount,
            cs.cs_net_profit AS sales_profit,
            cs.cs_promo_sk AS promo_sk,
            'catalog' AS channel
        FROM catalog_sales cs
        UNION ALL
        SELECT
            ws.ws_sold_date_sk AS date_sk,
            ws.ws_web_site_sk AS dim_sk,
            ws.ws_net_paid_inc_tax AS sales_amount,
            ws.ws_net_profit AS sales_profit,
            ws.ws_promo_sk AS promo_sk,
            'web' AS channel
        FROM web_sales ws
    ),
    dim_state AS (
        SELECT s_store_sk AS sk, s_state AS state FROM store
        UNION ALL
        SELECT cc_call_center_sk AS sk, cc_state AS state FROM call_center
        UNION ALL
        SELECT web_site_sk AS sk, web_state AS state FROM web_site
        UNION ALL
        SELECT ca_address_sk AS sk, ca_state AS state FROM customer_address
    ),
    sales_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            us.channel,
            ds.state,
            SUM(us.sales_amount) AS total_sales_amount,
            SUM(us.sales_profit) AS total_sales_profit,
            SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost
        FROM unified_sales us
        JOIN date_dim d ON us.date_sk = d.d_date_sk
        LEFT JOIN dim_state ds ON us.dim_sk = ds.sk
        LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
        GROUP BY d.d_year, d.d_month_seq, us.channel, ds.state
    ),
    unified_returns AS (
        SELECT
            sr.sr_returned_date_sk AS date_sk,
            sr.sr_store_sk AS dim_sk,
            sr.sr_net_loss AS return_loss,
            'store' AS channel
        FROM store_returns sr
        UNION ALL
        SELECT
            cr.cr_returned_date_sk AS date_sk,
            cr.cr_call_center_sk AS dim_sk,
            cr.cr_net_loss AS return_loss,
            'catalog' AS channel
        FROM catalog_returns cr
        UNION ALL
        SELECT
            wr.wr_returned_date_sk AS date_sk,
            wr.wr_refunded_addr_sk AS dim_sk,
            wr.wr_net_loss AS return_loss,
            'web' AS channel
        FROM web_returns wr
    ),
    returns_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            ur.channel,
            ds.state,
            SUM(ur.return_loss) AS total_return_loss
        FROM unified_returns ur
        JOIN date_dim d ON ur.date_sk = d.d_date_sk
        LEFT JOIN dim_state ds ON ur.dim_sk = ds.sk
        GROUP BY d.d_year, d.d_month_seq, ur.channel, ds.state
    )
SELECT
    sa.d_year,
    sa.d_month_seq,
    sa.channel,
    sa.state,
    sa.total_sales_amount,
    sa.total_sales_profit,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    sa.total_promo_cost,
    (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0) - sa.total_promo_cost) AS net_profit,
    RANK() OVER (PARTITION BY sa.channel, sa.d_year ORDER BY (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0) - sa.total_promo_cost) DESC) AS profit_rank,
    ROUND(100.0 * (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0) - sa.total_promo_cost) / SUM(sa.total_sales_profit - COALESCE(ra.total_return_loss, 0) - sa.total_promo_cost) OVER (PARTITION BY sa.channel), 2) AS profit_pct_of_channel
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.d_year = ra.d_year
   AND sa.d_month_seq = ra.d_month_seq
   AND sa.channel = ra.channel
   AND ((sa.state = ra.state) OR (sa.state IS NULL AND ra.state IS NULL))
WHERE sa.d_year >= 1998
ORDER BY sa.d_year, sa.d_month_seq, sa.channel, profit_rank
LIMIT 200
