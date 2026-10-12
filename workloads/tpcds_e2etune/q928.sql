SELECT
    cc.cc_name AS call_center_name,
    d_ret.d_quarter_seq AS quarter,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(DISTINCT wr.wr_returning_customer_sk) AS distinct_customers,
    AVG(ca.ca_gmt_offset) AS avg_returning_addr_gmt_offset
FROM
    call_center cc
JOIN
    date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN
    date_dim d_close ON cc.cc_closed_date_sk = d_close.d_date_sk
JOIN
    date_dim d_ret ON d_ret.d_date BETWEEN d_open.d_date AND d_close.d_date
JOIN
    web_returns wr ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN
    item i ON wr.wr_item_sk = i.i_item_sk
JOIN
    customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
JOIN
    web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    d_ret.d_year = 2022
    AND cc.cc_state = 'GA'
    AND i.i_category = 'Electronics'
    AND wp.wp_type = 'Product'
GROUP BY
    cc.cc_name,
    d_ret.d_quarter_seq
HAVING
    COUNT(*) > 10
ORDER BY
    total_return_amount DESC
LIMIT 20
