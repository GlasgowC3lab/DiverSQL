WITH store_ret AS (
    SELECT
        d.d_date AS return_date,
        CASE WHEN sr.sr_net_loss > 50 THEN 'High' ELSE 'Low' END AS loss_category,
        sr.sr_return_amt AS amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM promotion p
          JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
          JOIN date_dim d_end   ON p.p_end_date_sk = d_end.d_date_sk
          WHERE d_start.d_date_sk <= sr.sr_returned_date_sk
            AND d_end.d_date_sk   >= sr.sr_returned_date_sk
      )
),
catalog_ret AS (
    SELECT
        d.d_date AS return_date,
        CASE WHEN cr.cr_net_loss > 50 THEN 'High' ELSE 'Low' END AS loss_category,
        cr.cr_return_amt_inc_tax AS amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM promotion p
          JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
          JOIN date_dim d_end   ON p.p_end_date_sk = d_end.d_date_sk
          WHERE d_start.d_date_sk <= cr.cr_returned_date_sk
            AND d_end.d_date_sk   >= cr.cr_returned_date_sk
      )
)
SELECT *
FROM store_ret
INTERSECT
SELECT *
FROM catalog_ret
ORDER BY return_date DESC, amount DESC
