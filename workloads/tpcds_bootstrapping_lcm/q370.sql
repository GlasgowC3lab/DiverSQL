SELECT
    cc.cc_market_manager,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    wp.wp_url,
    d.d_date,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_return_tax
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wp.wp_creation_date_sk = d.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2022
GROUP BY
    cc.cc_market_manager,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    wp.wp_url,
    d.d_date
ORDER BY total_return_amount DESC
LIMIT 100
