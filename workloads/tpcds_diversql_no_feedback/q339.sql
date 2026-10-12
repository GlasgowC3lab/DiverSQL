WITH
    store_data AS (
        SELECT
            td1.t_hour AS hour,
            c1.c_birth_year AS birth_year,
            ss.ss_net_profit AS store_net_profit
        FROM store_sales ss
        JOIN time_dim td1 ON ss.ss_sold_time_sk = td1.t_time_sk
        JOIN customer c1 ON ss.ss_customer_sk = c1.c_customer_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN time_dim td2 ON sr.sr_return_time_sk = td2.t_time_sk
        JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
        WHERE ss.ss_ext_tax > 10
    ),
    catalog_data AS (
        SELECT
            td3.t_hour AS hour,
            c3.c_birth_year AS birth_year,
            cs.cs_net_profit AS catalog_net_profit
        FROM catalog_sales cs
        JOIN time_dim td3 ON cs.cs_sold_time_sk = td3.t_time_sk
        JOIN customer c3 ON cs.cs_bill_customer_sk = c3.c_customer_sk
        JOIN customer c4 ON cs.cs_ship_customer_sk = c4.c_customer_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
        JOIN time_dim td4 ON cr.cr_returned_time_sk = td4.t_time_sk
        JOIN customer c5 ON cr.cr_refunded_customer_sk = c5.c_customer_sk
        JOIN customer c6 ON cr.cr_returning_customer_sk = c6.c_customer_sk
        WHERE cs.cs_item_sk IN (
            SELECT cr2.cr_item_sk FROM catalog_returns cr2 WHERE cr2.cr_return_amount > 20
        )
    ),
    combined AS (
        SELECT hour, birth_year, store_net_profit AS profit FROM store_data
        UNION DISTINCT
        SELECT hour, birth_year, catalog_net_profit AS profit FROM catalog_data
    ),
    aggregated AS (
        SELECT
            hour,
            birth_year,
            SUM(profit) AS total_profit
        FROM combined
        GROUP BY hour, birth_year
    ),
    ranked AS (
        SELECT
            hour,
            birth_year,
            total_profit,
            row_number() OVER (PARTITION BY hour ORDER BY total_profit DESC) AS rn
        FROM aggregated
    )
SELECT
    hour,
    birth_year,
    total_profit
FROM ranked
WHERE rn <= 5
ORDER BY hour, total_profit DESC
LIMIT 100
