WITH agg AS (
    SELECT
        d_sold.d_current_quarter AS quarter,
        d_sold.d_year AS year,
        s.s_division_name AS division,
        wp.wp_type AS page_type,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
        MIN(d_creation.d_date) AS earliest_page_creation_date,
        MAX(d_access.d_date) AS latest_page_access_date,
        SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS profit_margin
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN date_dim d_store
        ON s.s_closed_date_sk = d_store.d_date_sk
    WHERE d_sold.d_year BETWEEN 2020 AND 2022
      AND s.s_state IN ('CA', 'TX', 'NY')
      AND wp.wp_type IS NOT NULL
    GROUP BY
        d_sold.d_current_quarter,
        d_sold.d_year,
        s.s_division_name,
        wp.wp_type
    HAVING SUM(ws.ws_quantity) > 10
)
SELECT
    quarter,
    year,
    division,
    page_type,
    num_orders,
    total_quantity,
    total_sales,
    total_net_profit,
    avg_inventory_on_hand,
    distinct_web_pages,
    earliest_page_creation_date,
    latest_page_access_date,
    profit_margin,
    RANK() OVER (PARTITION BY quarter ORDER BY total_net_profit DESC) AS division_profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 50
