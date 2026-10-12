WITH
    time_filtered AS (
        SELECT *
        FROM time_dim
        WHERE t_time_id = 'AAAAAAAFAAAAAAA'
          AND t_second > 10
          AND t_minute BETWEEN 5 AND 20
    ),
    sales AS (
        SELECT ss.*
        FROM store_sales ss
        JOIN time_filtered td ON ss.ss_sold_time_sk = td.t_time_sk
        WHERE ss.ss_quantity > 1
    ),
    websales AS (
        SELECT ws.*
        FROM web_sales ws
        JOIN time_filtered td ON ws.ws_sold_time_sk = td.t_time_sk
        WHERE ws.ws_quantity > 1
    ),
    returns AS (
        SELECT wr.*
        FROM web_returns wr
        JOIN time_filtered td ON wr.wr_returned_time_sk = td.t_time_sk
        WHERE wr.wr_return_tax > 20
    ),
    order_intersect AS (
        SELECT ws_order_number AS order_number FROM websales
        INTERSECT
        SELECT wr_order_number FROM returns
    ),
    full_sales_returns AS (
        SELECT
            s.ss_sold_date_sk,
            s.ss_quantity AS sales_quantity,
            r.wr_return_quantity AS return_quantity,
            s.ss_net_paid,
            r.wr_return_amt,
            s.ss_item_sk
        FROM sales s
        FULL OUTER JOIN returns r
            ON s.ss_sold_time_sk = r.wr_returned_time_sk
               AND s.ss_item_sk = r.wr_item_sk
    )
SELECT
    td.t_time_id,
    sm.sm_ship_mode_id,
    SUM(COALESCE(fsr.sales_quantity, 0) * ss.ss_sales_price) AS total_sales_amount,
    SUM(COALESCE(fsr.return_quantity, 0) * r.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(r.wr_return_tax) AS avg_return_tax,
    ship_detail
FROM time_filtered td
LEFT JOIN sales ss ON ss.ss_sold_time_sk = td.t_time_sk
LEFT JOIN full_sales_returns fsr ON fsr.ss_sold_date_sk = td.t_time_sk
LEFT JOIN websales ws ON ws.ws_sold_time_sk = td.t_time_sk
LEFT JOIN returns r ON r.wr_returned_time_sk = td.t_time_sk
INNER JOIN order_intersect oi ON ws.ws_order_number = oi.order_number
INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN (
    SELECT sm_ship_mode_sk, ARRAY[sm_carrier, sm_code] AS arr
    FROM ship_mode
) sm_arr ON sm_arr.sm_ship_mode_sk = sm.sm_ship_mode_sk
CROSS JOIN UNNEST(sm_arr.arr) AS t(ship_detail)
GROUP BY
    td.t_time_id,
    sm.sm_ship_mode_id,
    ship_detail
ORDER BY total_sales_amount DESC
LIMIT 100
