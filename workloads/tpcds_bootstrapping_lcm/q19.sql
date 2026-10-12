SELECT
    d.d_year,
    d.d_month_seq,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(CASE WHEN d.d_month_seq % 2 = 0 THEN cr.cr_return_amount ELSE 0 END) AS even_month_catalog_return_amount,
    SUM(CASE WHEN d.d_month_seq % 2 = 1 THEN wr.wr_return_amt ELSE 0 END) AS odd_month_web_return_amount,
    AVG(CASE WHEN s.s_state IS NOT NULL THEN s.s_tax_percentage END) AS avg_store_tax_pct
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'CA'
GROUP BY d.d_year, d.d_month_seq
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY d.d_year, d.d_month_seq
LIMIT 100
