WITH
    cs_sample AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (5)
    ),
    excluded_orders AS (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_quantity > 5
    ),
    inventory_agg AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory
        GROUP BY inv_item_sk
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY combined.total_net_profit DESC) AS rn,
    combined.order_number,
    combined.year,
    combined.customer_name,
    combined.department,
    combined.store_name,
    combined.reason_desc,
    combined.total_on_hand,
    combined.total_net_profit
FROM (
    SELECT
        cs.cs_order_number                         AS order_number,
        d_sold.d_year                              AS year,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cp.cp_department                           AS department,
        s.s_store_name                             AS store_name,
        r.r_reason_desc                            AS reason_desc,
        inv.total_on_hand                          AS total_on_hand,
        cs.cs_net_profit                           AS total_net_profit
    FROM cs_sample cs
    LEFT JOIN date_dim d_sold      ON cs.cs_sold_date_sk  = d_sold.d_date_sk
    LEFT JOIN date_dim d_ship      ON cs.cs_ship_date_sk  = d_ship.d_date_sk
    LEFT JOIN customer c          ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_page cp     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN inventory_agg inv   ON cs.cs_item_sk = inv.inv_item_sk
    LEFT JOIN store_returns sr    ON sr.sr_customer_sk = c.c_customer_sk
    FULL OUTER JOIN store s       ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r           ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cs.cs_order_number NOT IN (SELECT cs_order_number FROM excluded_orders)

    UNION DISTINCT

    SELECT
        ws.ws_order_number                         AS order_number,
        d_sold.d_year                              AS year,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        NULL                                       AS department,
        NULL                                       AS store_name,
        NULL                                       AS reason_desc,
        NULL                                       AS total_on_hand,
        ws.ws_net_profit                           AS total_net_profit
    FROM web_sales ws
    LEFT JOIN date_dim d_sold      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_ship      ON ws.ws_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN customer c          ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_site w          ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_order_number NOT IN (SELECT cs_order_number FROM excluded_orders)
) combined
WHERE combined.order_number NOT IN (
    SELECT order_number FROM (
        SELECT cs_order_number AS order_number FROM catalog_sales
        EXCEPT
        SELECT ws_order_number AS order_number FROM web_sales
    )
)
ORDER BY combined.total_net_profit DESC
LIMIT 20
