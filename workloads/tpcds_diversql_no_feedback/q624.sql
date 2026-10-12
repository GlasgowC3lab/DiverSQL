WITH base AS (
    SELECT
        ws.ws_bill_addr_sk,
        ca_bill.ca_city,
        ca_bill.ca_state,
        sd.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM web_sales ws
    JOIN date_dim sd ON ws.ws_sold_date_sk = sd.d_date_sk
    JOIN date_dim shd ON ws.ws_ship_date_sk = shd.d_date_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    WHERE
        ws.ws_ext_discount_amt > 1000
        AND ws.ws_sales_price BETWEEN 20 AND 200
        AND ws.ws_quantity >= 2
        AND ca_bill.ca_street_type IN ('Circle', 'Boulevard', 'Wy', 'Way', 'Street')
        AND sd.d_year = 2001
        AND EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_bill_addr_sk = ws.ws_bill_addr_sk
              AND ws2.ws_ext_discount_amt > ws.ws_ext_discount_amt
        )
    GROUP BY
        ws.ws_bill_addr_sk,
        ca_bill.ca_city,
        ca_bill.ca_state,
        sd.d_year
    HAVING COUNT(*) > 5
)
SELECT
    b.ws_bill_addr_sk,
    b.ca_city,
    b.ca_state,
    b.d_year,
    b.total_profit,
    b.total_discount,
    b.sales_cnt,
    b.profit_category,
    RANK() OVER (PARTITION BY b.d_year ORDER BY b.total_profit DESC) AS profit_rank_year,
    ROW_NUMBER() OVER (ORDER BY b.total_profit DESC) AS overall_rank
FROM base b
ORDER BY b.total_profit DESC
LIMIT 100
