WITH cr_daily AS (
       SELECT cr_returned_date_sk,
              cr_returned_time_sk,
              SUM(cr_return_amount) AS sum_cr_amount,
              COUNT(*) AS cnt_cr
       FROM catalog_returns
       GROUP BY cr_returned_date_sk, cr_returned_time_sk
     ),
     wr_daily AS (
       SELECT wr_returned_date_sk,
              wr_returned_time_sk,
              SUM(wr_return_amt) AS sum_wr_amount,
              COUNT(*) AS cnt_wr
       FROM web_returns
       GROUP BY wr_returned_date_sk, wr_returned_time_sk
     ),
     combined AS (
       SELECT d.d_year,
              d.d_quarter_name,
              t.t_sub_shift,
              ca.sum_cr_amount                AS amount,
              ca.cnt_cr                       AS qty,
              CASE WHEN ca.sum_cr_amount > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_category,
              u.metric
       FROM cr_daily ca
       JOIN date_dim d
         ON ca.cr_returned_date_sk = d.d_date_sk
       JOIN time_dim t
         ON ca.cr_returned_time_sk = t.t_time_sk
       JOIN catalog_returns cr
         ON ca.cr_returned_date_sk = cr.cr_returned_date_sk
        AND ca.cr_returned_time_sk = cr.cr_returned_time_sk
       JOIN customer cust_refunded
         ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
       JOIN customer cust_returning
         ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
       JOIN household_demographics hd_refunded
         ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
       JOIN household_demographics hd_returning
         ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
       JOIN income_band ib
         ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
       JOIN ship_mode sm
         ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
       JOIN warehouse w
         ON cr.cr_warehouse_sk = w.w_warehouse_sk
       JOIN store s
         ON s.s_closed_date_sk = d.d_date_sk
       CROSS JOIN UNNEST(ARRAY[CAST(ca.sum_cr_amount AS double), CAST(ca.cnt_cr AS double)]) AS u(metric)
       UNION DISTINCT
       SELECT d.d_year,
              d.d_quarter_name,
              t.t_sub_shift,
              wd.sum_wr_amount               AS amount,
              wd.cnt_wr                      AS qty,
              CASE WHEN wd.sum_wr_amount > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_category,
              u2.metric
       FROM wr_daily wd
       JOIN date_dim d
         ON wd.wr_returned_date_sk = d.d_date_sk
       JOIN time_dim t
         ON wd.wr_returned_time_sk = t.t_time_sk
       JOIN web_returns wr
         ON wd.wr_returned_date_sk = wr.wr_returned_date_sk
        AND wd.wr_returned_time_sk = wr.wr_returned_time_sk
       JOIN customer cust_refunded_w
         ON wr.wr_refunded_customer_sk = cust_refunded_w.c_customer_sk
       JOIN customer cust_returning_w
         ON wr.wr_returning_customer_sk = cust_returning_w.c_customer_sk
       JOIN household_demographics hd_refunded_w
         ON wr.wr_refunded_hdemo_sk = hd_refunded_w.hd_demo_sk
       JOIN household_demographics hd_returning_w
         ON wr.wr_returning_hdemo_sk = hd_returning_w.hd_demo_sk
       JOIN income_band ib_w
         ON hd_refunded_w.hd_income_band_sk = ib_w.ib_income_band_sk
       CROSS JOIN UNNEST(ARRAY[CAST(wd.sum_wr_amount AS double), CAST(wd.cnt_wr AS double)]) AS u2(metric)
     ),
     low_amount AS (
       SELECT *
       FROM combined
       WHERE amount_category = 'LOW'
     )
SELECT *
FROM combined
EXCEPT
SELECT *
FROM low_amount
LIMIT 100
