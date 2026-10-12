SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    s.s_store_name,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    CASE
        WHEN SUM(i.inv_quantity_on_hand) = 0 THEN NULL
        ELSE CAST(SUM(wr.wr_return_quantity) AS DOUBLE) / SUM(i.inv_quantity_on_hand)
    END AS return_to_inventory_ratio
FROM web_returns AS wr
JOIN date_dim AS d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason AS r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN inventory AS i
    ON i.inv_date_sk = d.d_date_sk
JOIN store AS s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2021
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    s.s_store_name
ORDER BY
    d.d_date,
    total_return_amount DESC
