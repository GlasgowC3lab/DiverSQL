WITH merged_sales AS (
    SELECT date_sk, item_sk,
           SUM(qty) AS total_qty,
           SUM(net_paid) AS total_net_paid,
           SUM(net_profit) AS total_net_profit
    FROM (
        SELECT ss_sold_date_sk AS date_sk,
               ss_item_sk AS item_sk,
               ss_quantity AS qty,
               ss_net_paid AS net_paid,
               ss_net_profit AS net_profit
        FROM store_sales
        UNION ALL
        SELECT cs_sold_date_sk,
               cs_item_sk,
               cs_quantity,
               cs_net_paid,
               cs_net_profit
        FROM catalog_sales
        UNION ALL
        SELECT ws_sold_date_sk,
               ws_item_sk,
               ws_quantity,
               ws_net_paid,
               ws_net_profit
        FROM web_sales
    ) s
    GROUP BY date_sk, item_sk
),
merged_returns AS (
    SELECT date_sk, item_sk,
           SUM(ret_qty) AS total_ret_qty,
           SUM(net_loss) AS total_net_loss
    FROM (
        SELECT sr_returned_date_sk AS date_sk,
               sr_item_sk AS item_sk,
               sr_return_quantity AS ret_qty,
               sr_net_loss AS net_loss
        FROM store_returns
        UNION ALL
        SELECT cr_returned_date_sk,
               cr_item_sk,
               cr_return_quantity,
               cr_net_loss
        FROM catalog_returns
        UNION ALL
        SELECT wr_returned_date_sk,
               wr_item_sk,
               wr_return_quantity,
               wr_net_loss
        FROM web_returns
    ) r
    GROUP BY date_sk, item_sk
),
sales_with_date AS (
    SELECT d.d_year,
           d.d_month_seq,
           s.item_sk,
           s.total_qty,
           s.total_net_paid,
           s.total_net_profit,
           COALESCE(r.total_ret_qty, 0) AS total_ret_qty,
           COALESCE(r.total_net_loss, 0) AS total_net_loss
    FROM merged_sales s
    LEFT JOIN merged_returns r
           ON r.date_sk = s.date_sk AND r.item_sk = s.item_sk
    JOIN date_dim d
           ON d.d_date_sk = s.date_sk
),
final_agg AS (
    SELECT
        d_year,
        d_month_seq,
        i.i_category,
        i.i_brand,
        i.i_item_id,
        i.i_product_name,
        SUM(total_qty) AS sum_qty,
        SUM(total_ret_qty) AS sum_ret_qty,
        SUM(total_net_paid) AS sum_revenue,
        SUM(total_net_profit) - SUM(total_net_loss) AS profit_after_returns,
        CASE WHEN SUM(total_qty) = 0 THEN 0 ELSE SUM(total_ret_qty) * 1.0 / SUM(total_qty) END AS return_rate,
        AVG(CASE WHEN total_qty > 0 THEN total_net_paid / total_qty END) AS avg_price,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(total_net_profit) - SUM(total_net_loss) DESC) AS profit_rank
    FROM sales_with_date swd
    JOIN item i ON i.i_item_sk = swd.item_sk
    GROUP BY d_year, d_month_seq, i.i_category, i.i_brand, i.i_item_id, i.i_product_name
)
SELECT *
FROM final_agg
WHERE profit_rank <= 10
ORDER BY d_year, profit_rank, profit_after_returns DESC
LIMIT 100
