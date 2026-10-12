SELECT
    d_return.d_date AS return_date,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    cs.cs_item_sk AS item_sk,
    COUNT(DISTINCT s.s_store_sk) AS closed_store_count,
    SUM(s.s_floor_space) AS total_closed_floor_space,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
GROUP BY
    d_return.d_date,
    d_sold.d_date,
    d_ship.d_date,
    cs.cs_item_sk
ORDER BY total_net_loss DESC
LIMIT 100
