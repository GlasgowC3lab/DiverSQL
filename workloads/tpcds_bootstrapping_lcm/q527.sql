SELECT
    s_store_id,
    s_store_name,
    d_year,
    hd_income_band_sk,
    returning_income_band,
    closed_year,
    store_net_loss,
    web_net_loss,
    total_net_loss,
    store_return_tickets,
    web_return_orders,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank_yearly,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS loss_rank_global
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        hd.hd_income_band_sk,
        hd_returning.hd_income_band_sk AS returning_income_band,
        d_closed.d_year AS closed_year,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN household_demographics hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        hd.hd_income_band_sk,
        hd_returning.hd_income_band_sk,
        d_closed.d_year
) t
ORDER BY total_net_loss DESC
LIMIT 100
