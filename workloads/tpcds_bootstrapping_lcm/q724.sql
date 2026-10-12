SELECT
    d.d_current_quarter,
    s.s_store_id,
    wp.wp_type,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    CASE
        WHEN SUM(i.inv_quantity_on_hand) = 0 THEN NULL
        ELSE SUM(wr.wr_return_amt) / SUM(i.inv_quantity_on_hand)
    END AS return_to_inventory_ratio,
    MIN(d.d_date) AS period_start,
    MAX(d.d_date) AS period_end,
    CASE
        WHEN d2.d_current_year = '2022' THEN '2022'
        ELSE 'Other'
    END AS creation_year_category
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN date_dim d2
    ON wp.wp_creation_date_sk = d2.d_date_sk
GROUP BY
    d.d_current_quarter,
    s.s_store_id,
    wp.wp_type,
    d2.d_current_year
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
