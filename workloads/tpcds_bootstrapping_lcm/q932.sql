SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    d_web_open.d_year AS website_open_year,
    d_web_open.d_month_seq AS website_open_month,
    d_web_close.d_year AS website_close_year,
    d_web_close.d_month_seq AS website_close_month,
    ws.web_name,
    ws.web_state,
    cd_ret.cd_gender AS returning_gender,
    cd_ret.cd_education_status AS returning_education,
    cd_ref.cd_gender AS refunded_gender,
    cd_ref.cd_education_status AS refunded_education,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders_returned,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_return_ship_cost) AS total_ship_cost,
    CASE
        WHEN SUM(wr.wr_return_quantity) > 0
        THEN SUM(wr.wr_net_loss) / SUM(wr.wr_return_quantity)
        ELSE NULL
    END AS net_loss_per_item
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
    ON TRUE
JOIN date_dim d_web_open
    ON ws.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close
    ON ws.web_close_date_sk = d_web_close.d_date_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_web_open.d_year,
    d_web_open.d_month_seq,
    d_web_close.d_year,
    d_web_close.d_month_seq,
    ws.web_name,
    ws.web_state,
    cd_ret.cd_gender,
    cd_ret.cd_education_status,
    cd_ref.cd_gender,
    cd_ref.cd_education_status
ORDER BY total_net_loss DESC
LIMIT 100
