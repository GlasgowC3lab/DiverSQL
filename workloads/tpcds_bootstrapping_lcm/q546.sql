SELECT
    cc.cc_market_manager,
    cc.cc_call_center_id,
    s.s_store_id,
    s.s_store_name,
    d_common.d_year AS year_of_event,
    d_cr.d_year AS return_year,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    SUM(cr.cr_net_loss) AS total_returns_net_loss,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(cr.cr_return_quantity) AS total_quantity_returned,
    (SUM(ss.ss_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) AS net_profit_after_returns,
    AVG(ss.ss_ext_discount_amt) AS avg_sales_discount,
    AVG(cr.cr_return_amt_inc_tax) AS avg_return_amount_inc_tax
FROM
    call_center cc
JOIN catalog_returns cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN date_dim d_common
    ON cc.cc_closed_date_sk = d_common.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_common.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
WHERE
    d_common.d_year = 2020
GROUP BY
    cc.cc_market_manager,
    cc.cc_call_center_id,
    s.s_store_id,
    s.s_store_name,
    d_common.d_year,
    d_cr.d_year
ORDER BY
    net_profit_after_returns DESC
LIMIT 100
