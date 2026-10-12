WITH returned_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity AS sold_quantity,
        cs.cs_net_profit,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_sold_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_returned_time_sk,
        cr.cr_return_ship_cost,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_addr_sk
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE cr.cr_returned_time_sk IN (45816, 74710, 71104)
      AND cr.cr_return_ship_cost > 100.00
)
SELECT
    ca.ca_state AS state,
    COUNT(DISTINCT rs.cs_order_number) AS num_orders,
    SUM(rs.cs_net_profit) AS total_net_profit,
    AVG(rs.cr_return_amount) AS avg_return_amount,
    SUM(rs.cr_return_quantity) / NULLIF(SUM(rs.sold_quantity), 0) AS return_qty_ratio,
    RANK() OVER (ORDER BY SUM(rs.cs_net_profit) DESC) AS profit_rank
FROM returned_sales rs
JOIN customer_address ca
    ON rs.cs_bill_addr_sk = ca.ca_address_sk
WHERE ca.ca_country = 'United States'
GROUP BY ca.ca_state
HAVING COUNT(DISTINCT rs.cs_order_number) >= 10
ORDER BY profit_rank
LIMIT 20
