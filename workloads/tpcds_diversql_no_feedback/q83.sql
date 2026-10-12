WITH
    cat_agg AS (
        SELECT
            cs.cs_bill_customer_sk AS customer_sk,
            SUM(cs.cs_net_profit) AS total_profit,
            COUNT(DISTINCT cs.cs_order_number) AS order_cnt
        FROM catalog_sales cs
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
        WHERE cs.cs_quantity > 10
        GROUP BY cs.cs_bill_customer_sk
    ),
    web_agg AS (
        SELECT
            ws.ws_bill_customer_sk AS customer_sk,
            SUM(ws.ws_net_profit) AS total_profit,
            COUNT(DISTINCT ws.ws_order_number) AS order_cnt
        FROM web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN customer cu ON ws.ws_bill_customer_sk = cu.c_customer_sk
        WHERE ws.ws_quantity > 5
        GROUP BY ws.ws_bill_customer_sk
    ),
    union_agg AS (
        SELECT customer_sk, total_profit, order_cnt FROM cat_agg
        UNION
        SELECT customer_sk, total_profit, order_cnt FROM web_agg
    ),
    store_agg AS (
        SELECT
            ss.ss_customer_sk AS customer_sk,
            SUM(ss.ss_net_profit) AS store_profit,
            COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
        FROM store_sales ss
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        WHERE ss.ss_quantity > 8
        GROUP BY ss.ss_customer_sk
    ),
    intersect_customers AS (
        SELECT u.customer_sk
        FROM union_agg u
        INTERSECT
        SELECT s.customer_sk
        FROM store_agg s
    )
SELECT
    ic.customer_sk,
    cu.c_first_name,
    cu.c_last_name,
    ua.total_profit,
    ua.order_cnt
FROM intersect_customers ic
JOIN union_agg ua ON ic.customer_sk = ua.customer_sk
JOIN customer cu ON ic.customer_sk = cu.c_customer_sk
ORDER BY ua.total_profit DESC
LIMIT 100
