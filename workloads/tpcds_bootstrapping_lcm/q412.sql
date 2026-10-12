SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(sr.sr_return_amt) AS store_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(cr.cr_net_loss + sr.sr_net_loss + wr.wr_net_loss) AS total_net_loss,
    ROUND(
        100.0 *
        (SUM(cr.cr_return_amount) + SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt)) /
        NULLIF(
            (
                SELECT
                    SUM(cr2.cr_return_amount) + SUM(sr2.sr_return_amt) + SUM(wr2.wr_return_amt)
                FROM catalog_returns cr2
                JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
                JOIN store_returns sr2 ON sr2.sr_returned_date_sk = d2.d_date_sk
                JOIN web_returns wr2 ON wr2.wr_returned_date_sk = d2.d_date_sk
                WHERE d2.d_year = d.d_year
            ), 0
        ), 2
    ) AS pct_of_yearly_returns
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_store_sk = s.s_store_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY s.s_store_id, s.s_city, s.s_state, d.d_year, d.d_month_seq
HAVING SUM(cr.cr_net_loss + sr.sr_net_loss + wr.wr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
