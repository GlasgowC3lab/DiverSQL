WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price)        AS total_ext_sales,
        SUM(ss.ss_net_paid)               AS total_net_paid,
        SUM(ss.ss_quantity)               AS total_quantity
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
    )
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
)
SELECT
    ca.ca_state,
    d.d_year,
    t.t_hour,
    ws.web_name,
    sa.total_ext_sales,
    sa.total_net_paid,
    r.sr_return_quantity,
    r.sr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY sa.total_net_paid DESC) AS rn_state,
    CASE WHEN r.sr_return_amt > (SELECT AVG(sr_return_amt) FROM store_returns) THEN 'HIGH' ELSE 'LOW' END AS return_amount_flag,
    (sa.total_net_paid - (SELECT AVG(ss_net_paid) FROM store_sales)) AS net_paid_vs_avg
FROM sales_agg sa
JOIN store_sales ss
    ON ss.ss_store_sk = sa.ss_store_sk
   AND ss.ss_sold_date_sk = sa.ss_sold_date_sk
JOIN store_returns r
    ON r.sr_ticket_number = ss.ss_ticket_number
   AND r.sr_item_sk = ss.ss_item_sk
JOIN date_dim d
    ON d.d_date_sk = sa.ss_sold_date_sk
JOIN time_dim t
    ON t.t_time_sk = ss.ss_sold_time_sk
JOIN customer_address ca
    ON ca.ca_address_sk = ss.ss_addr_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE
    ca.ca_state IN ('CA', 'NY', 'TX')
    AND t.t_hour BETWEEN 9 AND 17
    AND r.sr_return_quantity > 0
    AND d.d_holiday = 'N'
    AND ws.web_gmt_offset >= -5.00
    AND ss.ss_store_sk IN (
        SELECT ss_store_sk
        FROM store_sales
        WHERE ss_quantity > 10
    )
ORDER BY ca.ca_state, rn_state
LIMIT 100
