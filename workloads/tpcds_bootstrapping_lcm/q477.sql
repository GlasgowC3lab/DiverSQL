SELECT
    D_ret.d_year AS return_year,
    D_ret.d_month_seq AS return_month,
    D_sold.d_year AS sale_year,
    S.s_state,
    WP.wp_type,
    COUNT(DISTINCT CS.cs_order_number) AS num_sales_orders,
    COUNT(DISTINCT CR.cr_order_number) AS num_return_orders,
    SUM(CS.cs_net_paid) AS total_sales_net_paid,
    SUM(CR.cr_net_loss) AS total_return_net_loss,
    SUM(CS.cs_net_profit) AS total_sales_net_profit,
    AVG(CS.cs_ext_discount_amt) AS avg_discount_amount,
    AVG(date_diff('day', D_sold.d_date, D_ship.d_date)) AS avg_shipping_delay_days,
    SUM(CR.cr_return_quantity) AS total_return_quantity,
    SUM(CS.cs_quantity) AS total_sales_quantity,
    SUM(CS.cs_ext_sales_price) - SUM(CR.cr_return_amount) AS net_sales_minus_returns
FROM catalog_returns CR
JOIN catalog_sales CS
    ON CR.cr_item_sk = CS.cs_item_sk
    AND CR.cr_order_number = CS.cs_order_number
JOIN date_dim D_ret
    ON CR.cr_returned_date_sk = D_ret.d_date_sk
JOIN store S
    ON S.s_closed_date_sk = D_ret.d_date_sk
JOIN web_page WP
    ON WP.wp_creation_date_sk = D_ret.d_date_sk
JOIN date_dim D_sold
    ON CS.cs_sold_date_sk = D_sold.d_date_sk
JOIN date_dim D_ship
    ON CS.cs_ship_date_sk = D_ship.d_date_sk
GROUP BY
    D_ret.d_year,
    D_ret.d_month_seq,
    D_sold.d_year,
    S.s_state,
    WP.wp_type
ORDER BY
    total_return_net_loss DESC
LIMIT 100
