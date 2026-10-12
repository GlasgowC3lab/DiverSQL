WITH aggregated AS (
    SELECT
        cp.cp_department,
        d_end.d_current_month,
        i.i_brand,
        i.i_category,
        s.s_store_name,
        s.s_state,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
    JOIN web_returns wr   ON wr.wr_returned_date_sk = d_end.d_date_sk
    JOIN item i           ON i.i_item_sk = wr.wr_item_sk
    JOIN store s          ON s.s_closed_date_sk = d_end.d_date_sk
    WHERE cp.cp_type = 'Online' AND s.s_state = 'CA'
    GROUP BY cp.cp_department, d_end.d_current_month, i.i_brand, i.i_category, s.s_store_name, s.s_state
)
SELECT
    cp_department,
    d_current_month,
    i_brand,
    i_category,
    s_store_name,
    s_state,
    total_return_qty,
    total_net_loss,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
