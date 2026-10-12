SELECT
    s.s_store_name,
    d_sold.d_year,
    CASE WHEN ca_bill.ca_state = 'CA' THEN 'CA' ELSE 'Other' END AS state_group,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    (SUM(cs.cs_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0))) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS net_profit_margin,
    CASE
        WHEN SUM(cs.cs_net_profit) > 0.2 * SUM(cs.cs_ext_sales_price) THEN 'High'
        ELSE 'Low'
    END AS profit_category
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    s.s_store_name,
    d_sold.d_year,
    CASE WHEN ca_bill.ca_state = 'CA' THEN 'CA' ELSE 'Other' END
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
