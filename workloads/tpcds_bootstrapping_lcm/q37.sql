SELECT
    d.d_year AS year,
    d.d_month_seq AS month,
    s.s_state AS state,
    CASE
        WHEN (cs.cs_ship_date_sk - cs.cs_sold_date_sk) <= 0 THEN 'SameDayOrEarlier'
        WHEN (cs.cs_ship_date_sk - cs.cs_sold_date_sk) <= 7 THEN 'WithinWeek'
        ELSE 'LongDelay'
    END AS ship_delay_bucket,
    COUNT(*) AS transaction_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(wr.wr_net_loss) AS total_return_loss,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    CASE
        WHEN SUM(cs.cs_net_paid) > 0 THEN SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid)
        ELSE NULL
    END AS profit_margin,
    CASE
        WHEN SUM(cs.cs_net_paid) > 0 THEN SUM(wr.wr_net_loss) / SUM(cs.cs_net_paid)
        ELSE NULL
    END AS loss_to_sales_ratio
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year >= 2000
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_state,
    CASE
        WHEN (cs.cs_ship_date_sk - cs.cs_sold_date_sk) <= 0 THEN 'SameDayOrEarlier'
        WHEN (cs.cs_ship_date_sk - cs.cs_sold_date_sk) <= 7 THEN 'WithinWeek'
        ELSE 'LongDelay'
    END
ORDER BY d.d_year, d.d_month_seq, s.s_state, ship_delay_bucket
LIMIT 100
