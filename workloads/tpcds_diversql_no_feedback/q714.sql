WITH base AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_promo_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ship_date_sk,
        d_sold.d_year,
        d_sold.d_current_month,
        p.p_promo_name,
        p.p_channel_event,
        p.p_cost,
        cp.cp_department,
        cp.cp_catalog_page_number
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN catalog_page cp
        ON cp.cp_end_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_current_month = 'Y'
      AND p.p_channel_event = 'N'
      AND cp.cp_department = 'Sports'
),
union_data AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        d_year,
        p_cost,
        cp_department
    FROM base
    WHERE ws_quantity > 1
    UNION
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        d_year,
        p_cost,
        cp_department
    FROM base
    WHERE ws_quantity = 1 AND p_cost > 10
)
SELECT
    d_year,
    cp_department,
    SUM(ws_net_paid) AS total_sales,
    AVG(ws_quantity) AS avg_quantity,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    COUNT(DISTINCT ws_item_sk) AS distinct_items,
    MIN(p_cost) AS min_promo_cost,
    MAX(p_cost) AS max_promo_cost,
    ROW_NUMBER() OVER (ORDER BY SUM(ws_net_paid) DESC) AS row_num
FROM union_data
GROUP BY d_year, cp_department
ORDER BY total_sales DESC
LIMIT 100
