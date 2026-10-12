WITH page_dates AS (
    SELECT cp.cp_catalog_page_sk,
           cp.cp_department,
           cp.cp_type,
           cp.cp_catalog_number,
           start_dt.d_date AS start_date,
           end_dt.d_date AS end_date
    FROM catalog_page cp
    JOIN date_dim start_dt ON cp.cp_start_date_sk = start_dt.d_date_sk
    JOIN date_dim end_dt ON cp.cp_end_date_sk = end_dt.d_date_sk
    WHERE cp.cp_type = 'monthly'
),
returns_agg AS (
    SELECT pd.cp_department,
           r.r_reason_desc,
           DATE_TRUNC('month', rd.d_date) AS return_month,
           COUNT(*) AS return_cnt,
           SUM(cr.cr_net_loss) AS total_net_loss,
           SUM(cr.cr_return_amount) AS total_return_amount,
           AVG(cr.cr_return_quantity) AS avg_return_qty
    FROM catalog_returns cr
    JOIN page_dates pd ON cr.cr_catalog_page_sk = pd.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim rd ON cr.cr_returned_date_sk = rd.d_date_sk
    WHERE rd.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND cr.cr_return_amount > 0
    GROUP BY pd.cp_department, r.r_reason_desc, DATE_TRUNC('month', rd.d_date)
)
SELECT ra.cp_department,
       ra.r_reason_desc,
       ra.return_month,
       ra.return_cnt,
       ra.total_net_loss,
       ra.total_return_amount,
       ra.avg_return_qty,
       RANK() OVER (PARTITION BY ra.cp_department ORDER BY ra.total_net_loss DESC) AS loss_rank
FROM returns_agg ra
ORDER BY ra.cp_department, ra.total_net_loss DESC, ra.return_month
