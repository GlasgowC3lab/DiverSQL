WITH order_sales AS (
    SELECT
        ws.ws_order_number,
        c.c_customer_id,
        i.i_category,
        w.w_warehouse_name,
        d_sold.d_year,
        SUM(ws.ws_net_profit)               AS order_profit,
        SUM(ws.ws_quantity)                 AS order_quantity
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv ON inv.inv_date_sk = ws.ws_sold_date_sk
        AND inv.inv_item_sk = ws.ws_item_sk
        AND inv.inv_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d_sold.d_year = 2001
      AND w.w_state = 'CA'
      AND p.p_channel_demo = 'N'
      AND wp.wp_max_ad_count >= 2
      AND i.i_category = 'Electronics'
      AND NOT EXISTS (
          SELECT 1 FROM web_returns wr2
          WHERE wr2.wr_order_number = ws.ws_order_number
            AND wr2.wr_return_quantity > 0
      )
    GROUP BY ws.ws_order_number,
             c.c_customer_id,
             i.i_category,
             w.w_warehouse_name,
             d_sold.d_year
)
SELECT
    os.c_customer_id,
    os.d_year,
    AVG(os.order_profit)                                 AS avg_profit_per_order,
    SUM(os.order_quantity)                               AS total_quantity,
    ROW_NUMBER() OVER (PARTITION BY os.d_year ORDER BY AVG(os.order_profit) DESC) AS profit_rank_year,
    (SELECT AVG(ws3.ws_net_profit) FROM web_sales ws3) AS overall_avg_profit
FROM order_sales os
GROUP BY os.c_customer_id, os.d_year
HAVING AVG(os.order_profit) > 1000
ORDER BY os.d_year, avg_profit_per_order DESC
LIMIT 100
