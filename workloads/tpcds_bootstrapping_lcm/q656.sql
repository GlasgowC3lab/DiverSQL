SELECT
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_market_manager,
    s.s_store_sk,
    s.s_store_name,
    s.s_market_manager,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_fee + cr.cr_reversed_charge + cr.cr_return_tax) AS total_catalog_fees,
    SUM(wr.wr_fee + wr.wr_reversed_charge + wr.wr_return_tax) AS total_web_fees,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_percentage,
    AVG(s.s_tax_percentage) AS avg_store_tax_percentage,
    CASE
        WHEN SUM(cr.cr_return_amount) > SUM(wr.wr_return_amt) THEN 'Catalog Higher'
        WHEN SUM(cr.cr_return_amount) < SUM(wr.wr_return_amt) THEN 'Web Higher'
        ELSE 'Equal'
    END AS higher_return_source
FROM
    date_dim d
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2020 AND 2022
    AND cc.cc_state = s.s_state
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_market_manager,
    s.s_store_sk,
    s.s_store_name,
    s.s_market_manager
HAVING
    COUNT(*) > 10
ORDER BY
    total_catalog_return_amount DESC
LIMIT 100
