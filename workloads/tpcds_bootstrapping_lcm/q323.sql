SELECT
    d.d_year,
    CASE
        WHEN d.d_month_seq IN (12, 1, 2) THEN 'Winter'
        WHEN d.d_month_seq IN (3, 4, 5) THEN 'Spring'
        WHEN d.d_month_seq IN (6, 7, 8) THEN 'Summer'
        WHEN d.d_month_seq IN (9, 10, 11) THEN 'Fall'
        ELSE 'Unknown'
    END AS season,
    COALESCE(i_inv.i_category, i_wr.i_category) AS category,
    COALESCE(i_inv.i_brand, i_wr.i_brand) AS brand,
    SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT COALESCE(i_inv.i_item_sk, i_wr.i_item_sk)) AS distinct_item_count,
    COUNT(DISTINCT s.s_store_sk) AS distinct_store_closed,
    AVG(i_inv.i_current_price) AS avg_current_price,
    AVG(i_inv.i_wholesale_cost) AS avg_wholesale_cost,
    SUM(CASE WHEN wr.wr_return_amt > 0 THEN 1 ELSE 0 END) AS positive_returns,
    SUM(CASE WHEN wr.wr_return_amt = 0 THEN 1 ELSE 0 END) AS zero_returns,
    SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_quantity), 0) AS net_loss_rate,
    SUM(CASE WHEN d.d_holiday = 'Y' THEN inv.inv_quantity_on_hand ELSE 0 END) AS holiday_inventory_qty
FROM
    date_dim d
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN item i_inv ON i_inv.i_item_sk = inv.inv_item_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN item i_wr ON i_wr.i_item_sk = wr.wr_item_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2000 AND 2005
    AND COALESCE(i_inv.i_category, i_wr.i_category) IS NOT NULL
GROUP BY
    d.d_year,
    CASE
        WHEN d.d_month_seq IN (12, 1, 2) THEN 'Winter'
        WHEN d.d_month_seq IN (3, 4, 5) THEN 'Spring'
        WHEN d.d_month_seq IN (6, 7, 8) THEN 'Summer'
        WHEN d.d_month_seq IN (9, 10, 11) THEN 'Fall'
        ELSE 'Unknown'
    END,
    COALESCE(i_inv.i_category, i_wr.i_category),
    COALESCE(i_inv.i_brand, i_wr.i_brand)
HAVING
    SUM(inv.inv_quantity_on_hand) > 0
ORDER BY
    d.d_year,
    season,
    category
