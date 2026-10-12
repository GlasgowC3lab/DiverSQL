WITH sales AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_call_center_sk AS channel_sk,
           'catalog' AS channel,
           cs_quantity AS quantity,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit,
           cs_order_number AS order_number
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_store_sk AS channel_sk,
           'store' AS channel,
           ss_quantity AS quantity,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit,
           ss_ticket_number AS order_number
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk AS date_sk,
           ws_item_sk AS item_sk,
           ws_web_page_sk AS channel_sk,
           'web' AS channel,
           ws_quantity AS quantity,
           ws_net_paid AS net_paid,
           ws_net_profit AS net_profit,
           ws_order_number AS order_number
    FROM web_sales
),
returns AS (
    SELECT cr_returned_date_sk AS date_sk,
           cr_item_sk AS item_sk,
           cr_call_center_sk AS channel_sk,
           'catalog' AS channel,
           cr_return_quantity AS quantity,
           cr_return_amount AS amount,
           cr_net_loss AS net_loss,
           cr_order_number AS order_number
    FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk AS date_sk,
           sr_item_sk AS item_sk,
           sr_store_sk AS channel_sk,
           'store' AS channel,
           sr_return_quantity AS quantity,
           sr_return_amt AS amount,
           sr_net_loss AS net_loss,
           sr_ticket_number AS order_number
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk AS date_sk,
           wr_item_sk AS item_sk,
           wr_web_page_sk AS channel_sk,
           'web' AS channel,
           wr_return_quantity AS quantity,
           wr_return_amt AS amount,
           wr_net_loss AS net_loss,
           wr_order_number AS order_number
    FROM web_returns
),
sales_with_date AS (
    SELECT s.*,
           d.d_year,
           d.d_month_seq,
           d.d_day_name,
           d.d_quarter_name
    FROM sales s
    LEFT JOIN date_dim d
           ON s.date_sk = d.d_date_sk
),
returns_with_date AS (
    SELECT r.*,
           d.d_year,
           d.d_month_seq,
           d.d_day_name,
           d.d_quarter_name
    FROM returns r
    LEFT JOIN date_dim d
           ON r.date_sk = d.d_date_sk
),
combined AS (
    SELECT s.channel,
           s.channel_sk,
           s.item_sk,
           i.i_category,
           i.i_category_id,
           i.i_brand,
           i.i_brand_id,
           s.d_year,
           s.d_month_seq,
           s.d_day_name,
           s.d_quarter_name,
           s.quantity AS sold_quantity,
           s.net_paid AS sold_amount,
           s.net_profit AS sold_profit,
           COALESCE(r.quantity, 0) AS returned_quantity,
           COALESCE(r.amount, 0) AS returned_amount,
           COALESCE(r.net_loss, 0) AS returned_loss,
           s.net_paid - COALESCE(r.amount, 0) AS net_revenue,
           s.net_profit - COALESCE(r.net_loss, 0) AS net_profit_adj,
           s.order_number
    FROM sales_with_date s
    LEFT JOIN returns_with_date r
           ON s.order_number = r.order_number
          AND s.item_sk = r.item_sk
          AND s.channel = r.channel
          AND s.channel_sk = r.channel_sk
    LEFT JOIN item i
           ON s.item_sk = i.i_item_sk
),
ranked_items AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY d_year, i_category
                              ORDER BY net_profit_adj DESC) AS rank_in_category
    FROM combined
)
SELECT d_year,
       i_category,
       i_category_id,
       i_brand,
       i_brand_id,
       channel,
       channel_sk,
       SUM(sold_quantity) AS total_sold_quantity,
       SUM(returned_quantity) AS total_returned_quantity,
       SUM(sold_amount) AS total_sold_amount,
       SUM(returned_amount) AS total_returned_amount,
       SUM(net_revenue) AS total_net_revenue,
       SUM(sold_profit) AS total_gross_profit,
       SUM(returned_loss) AS total_returned_loss,
       SUM(net_profit_adj) AS total_net_profit,
       COUNT(DISTINCT IF(rank_in_category = 1, order_number, NULL)) AS top_item_orders
FROM ranked_items
WHERE d_year BETWEEN 1999 AND 2002
GROUP BY d_year,
         i_category,
         i_category_id,
         i_brand,
         i_brand_id,
         channel,
         channel_sk
HAVING SUM(net_revenue) > 1000000
ORDER BY d_year,
         i_category,
         total_net_revenue DESC
LIMIT 100
