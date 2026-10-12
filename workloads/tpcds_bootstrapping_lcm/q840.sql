SELECT
    d.d_year,
    d.d_current_month,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    CASE 
        WHEN s.s_number_employees >= 200 THEN 'Large'
        WHEN s.s_number_employees >= 100 THEN 'Medium'
        ELSE 'Small'
    END AS store_size_category,
    r.r_reason_desc,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    CASE 
        WHEN SUM(wr.wr_return_quantity) = 0 THEN NULL
        ELSE SUM(i.inv_quantity_on_hand) / SUM(wr.wr_return_quantity)
    END AS inventory_to_return_ratio,
    GROUPING(d.d_year) AS g_year,
    GROUPING(s.s_store_id) AS g_store,
    GROUPING(r.r_reason_desc) AS g_reason
FROM
    date_dim d
JOIN
    web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN
    reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN
    inventory i ON i.inv_date_sk = d.d_date_sk
JOIN
    store s ON s.s_closed_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2020 AND 2022
    AND s.s_state IN ('CA', 'NY')
GROUP BY
    ROLLUP (d.d_year, s.s_store_id, r.r_reason_desc),
    d.d_current_month,
    s.s_store_name,
    s.s_state,
    CASE 
        WHEN s.s_number_employees >= 200 THEN 'Large'
        WHEN s.s_number_employees >= 100 THEN 'Medium'
        ELSE 'Small'
    END
HAVING
    SUM(wr.wr_return_amt) > 10000 OR GROUPING(d.d_year) = 1
ORDER BY
    d.d_year DESC,
    total_return_amount DESC
LIMIT 100
