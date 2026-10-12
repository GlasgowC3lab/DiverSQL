SELECT
    d.d_year,
    d.d_month_seq,
    d.d_quarter_name,
    s.s_store_id,
    s.s_store_name,
    s.s_division_name,
    wp.wp_type,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT wr.wr_item_sk) AS distinct_items_returned,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
    CASE WHEN d.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    (SUM(wr.wr_return_amt) / NULLIF(SUM(i.inv_quantity_on_hand), 0)) AS return_amount_per_inventory
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_current_year = '2022'
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_quarter_name,
    s.s_store_id,
    s.s_store_name,
    s.s_division_name,
    wp.wp_type,
    d.d_weekend
HAVING SUM(wr.wr_return_quantity) > 0
ORDER BY d.d_year DESC, d.d_month_seq, s.s_store_id
