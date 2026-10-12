SELECT
    cp.cp_catalog_number,
    cp.cp_type,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amt_inc_tax,
    SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amt_inc_tax,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    CASE 
        WHEN SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) <> 0 
        THEN SUM(sr.sr_net_loss) / (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) 
        ELSE NULL 
    END AS store_net_loss_ratio,
    CASE 
        WHEN SUM(wr.wr_net_loss) <> 0 
        THEN SUM(sr.sr_return_quantity) * 1.0 / SUM(wr.wr_return_quantity) 
        ELSE NULL 
    END AS return_qty_ratio,
    CASE 
        WHEN SUM(sr.sr_return_amt_inc_tax) > SUM(wr.wr_return_amt_inc_tax) THEN 'Store Higher'
        ELSE 'Web Higher' 
    END AS higher_return_amount_source
FROM catalog_page cp
JOIN date_dim d
    ON cp.cp_end_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
GROUP BY
    cp.cp_catalog_number,
    cp.cp_type,
    s.s_store_name,
    d.d_year,
    d.d_month_seq
HAVING COUNT(DISTINCT sr.sr_ticket_number) > 0
ORDER BY total_store_net_loss DESC
LIMIT 100
