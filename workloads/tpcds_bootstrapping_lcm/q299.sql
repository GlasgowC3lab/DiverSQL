SELECT
    d.d_year,
    d.d_month_seq,
    s.s_division_id,
    CASE 
        WHEN d.d_quarter_seq IN (1, 2) THEN 'H1'
        ELSE 'H2'
    END AS half_year,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_return_amt_inc_tax) AS catalog_return_total,
    SUM(sr.sr_return_amt_inc_tax) AS store_return_total,
    SUM(wr.wr_return_amt_inc_tax) AS web_return_total,
    SUM(cr.cr_net_loss + sr.sr_net_loss + wr.wr_net_loss) AS total_net_loss,
    AVG(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_quantity END) AS avg_catalog_quantity,
    AVG(sr.sr_return_quantity) AS avg_store_quantity,
    AVG(wr.wr_return_quantity) AS avg_web_quantity,
    SUM(cr.cr_fee + sr.sr_fee + wr.wr_fee) AS total_fee,
    SUM(CASE 
            WHEN (cr.cr_return_amt_inc_tax + sr.sr_return_amt_inc_tax + wr.wr_return_amt_inc_tax) > 1000 THEN 1 
            ELSE 0 
        END) AS high_value_return_count
FROM date_dim d
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
   AND s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'TX'
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_division_id,
    CASE 
        WHEN d.d_quarter_seq IN (1, 2) THEN 'H1'
        ELSE 'H2'
    END
HAVING COUNT(*) > 100
ORDER BY total_net_loss DESC
LIMIT 100
