WITH base AS (
    SELECT
        ws.ws_order_number               AS ws_order_number,
        ws.ws_net_profit                 AS ws_net_profit,
        ws.ws_ext_discount_amt           AS ws_ext_discount_amt,
        ws.ws_ext_sales_price            AS ws_ext_sales_price,
        d.d_year                         AS d_year,
        p.p_promo_name                   AS p_promo_name,
        cp.cp_department                 AS cp_department,
        cp.cp_catalog_number             AS cp_catalog_number,
        i.i_current_price                AS i_current_price,
        wp.wp_type                       AS wp_type,
        p.p_channel_tv                   AS p_channel_tv
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price BETWEEN 1000 AND 3000
      AND p.p_channel_tv = 'Y'
      AND wp.wp_type = 'Content'
      AND cp.cp_catalog_number = 5
      AND NOT EXISTS (
            SELECT 1
            FROM tpcds.web_returns wr2
            WHERE wr2.wr_order_number = ws.ws_order_number
              AND wr2.wr_return_quantity > 0
        )
),
agg AS (
    SELECT
        p_promo_name,
        d_year,
        cp_department,
        SUM(ws_net_profit)               AS total_net_profit,
        COUNT(DISTINCT ws_order_number)  AS distinct_orders,
        AVG(ws_ext_discount_amt)         AS avg_discount,
        MAX(ws_ext_sales_price)          AS max_sales_price
    FROM base
    GROUP BY p_promo_name, d_year, cp_department
    HAVING SUM(ws_net_profit) > 0
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY p_promo_name ORDER BY total_net_profit DESC) AS rnk
    FROM agg
)
SELECT
    p_promo_name,
    d_year,
    cp_department,
    total_net_profit,
    distinct_orders,
    avg_discount,
    max_sales_price
FROM ranked
WHERE rnk <= 5
ORDER BY total_net_profit DESC
LIMIT 100
