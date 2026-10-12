SELECT
    ca_bill.ca_city,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
    CASE
        WHEN SUM(ws.ws_net_profit) > 50000 THEN 'High Performer'
        WHEN SUM(ws.ws_net_profit) > 20000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS profit_category
FROM web_sales ws
INNER JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
GROUP BY ca_bill.ca_city
