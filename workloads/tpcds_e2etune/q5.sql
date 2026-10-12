WITH agg AS (
    SELECT
        c.cc_city,
        c.cc_state,
        w.w_warehouse_name,
        c.cc_manager,
        c.cc_employees,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN call_center c
        ON sr.sr_returned_date_sk = c.cc_open_date_sk
    JOIN warehouse w
        ON c.cc_state = w.w_state
       AND c.cc_city = w.w_city
    WHERE c.cc_manager = 'Bob Belcher'
      AND sr.sr_return_amt > 100
      AND w.w_warehouse_sq_ft > 50000
    GROUP BY
        c.cc_city,
        c.cc_state,
        w.w_warehouse_name,
        c.cc_manager,
        c.cc_employees
    HAVING SUM(sr.sr_return_amt) > 10000
)
SELECT
    agg.cc_city,
    agg.cc_state,
    agg.w_warehouse_name,
    agg.cc_manager,
    agg.return_transactions,
    agg.total_return_qty,
    agg.total_return_amt,
    agg.avg_return_tax,
    agg.total_net_loss,
    agg.total_return_amt / NULLIF(agg.cc_employees, 0) AS amt_per_employee,
    RANK() OVER (ORDER BY agg.total_return_amt DESC) AS revenue_rank
FROM agg
ORDER BY agg.total_return_amt DESC
LIMIT 20
