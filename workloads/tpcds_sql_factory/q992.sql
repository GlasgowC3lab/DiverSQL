WITH store_month_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_current_month,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS total_returns
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_current_month
),
store_month_ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY d_year, d_current_month ORDER BY total_net_loss DESC) AS net_loss_rank,
        CASE WHEN total_net_loss > 10000 THEN 'HIGH'
             WHEN total_net_loss > 5000 THEN 'MEDIUM'
             ELSE 'LOW' END AS loss_severity
    FROM store_month_agg
),
customer_store_month AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_current_month,
        c.c_customer_id,
        SUM(sr.sr_return_amt) AS cust_return_amt,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id, d.d_year, d.d_current_month ORDER BY SUM(sr.sr_return_amt) DESC) AS cust_rank
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY s.s_store_id, d.d_year, d.d_current_month, c.c_customer_id
)
SELECT
    smr.s_store_id,
    smr.s_store_name,
    smr.d_year,
    smr.d_current_month,
    smr.total_net_loss,
    smr.total_return_amt,
    smr.total_returns,
    smr.net_loss_rank,
    smr.loss_severity,
    csm.c_customer_id,
    csm.cust_return_amt,
    csm.cust_rank
FROM store_month_ranked smr
JOIN customer_store_month csm
  ON smr.s_store_id = csm.s_store_id
 AND smr.d_year = csm.d_year
 AND smr.d_current_month = csm.d_current_month
WHERE csm.cust_rank <= 3
ORDER BY smr.d_year, smr.d_current_month, smr.net_loss_rank, csm.cust_rank
