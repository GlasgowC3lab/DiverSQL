WITH base AS (
   SELECT
     wr.wr_returned_date_sk,
     d.d_year,
     cd_refund.cd_gender AS refund_gender,
     cd_return.cd_gender AS return_gender,
     hd_refund.hd_income_band_sk AS refund_income_band_sk,
     ib_refund.ib_lower_bound AS refund_income_low,
     ib_refund.ib_upper_bound AS refund_income_high,
     hd_return.hd_income_band_sk AS return_income_band_sk,
     ib_return.ib_lower_bound AS return_income_low,
     ib_return.ib_upper_bound AS return_income_high,
     wp.wp_char_count,
     wp.wp_max_ad_count,
     i.inv_quantity_on_hand,
     wr.wr_return_amt,
     wr.wr_refunded_cash,
     ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY wr.wr_return_amt DESC) AS rn_year,
     l_refund.total_refunded_by_cdemo
   FROM web_returns wr
   JOIN date_dim d
     ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN customer_demographics cd_refund
     ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
   JOIN customer_demographics cd_return
     ON wr.wr_returning_cdemo_sk = cd_return.cd_demo_sk
   JOIN household_demographics hd_refund
     ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
   JOIN household_demographics hd_return
     ON wr.wr_returning_hdemo_sk = hd_return.hd_demo_sk
   JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN inventory i
     ON i.inv_date_sk = d.d_date_sk
   JOIN income_band ib_refund
     ON hd_refund.hd_income_band_sk = ib_refund.ib_income_band_sk
   JOIN income_band ib_return
     ON hd_return.hd_income_band_sk = ib_return.ib_income_band_sk
   FULL OUTER JOIN date_dim d2
     ON i.inv_date_sk = d2.d_date_sk
   CROSS JOIN LATERAL (
       SELECT SUM(wr2.wr_return_amt) AS total_refunded_by_cdemo
       FROM web_returns wr2
       WHERE wr2.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
   ) AS l_refund
   WHERE NOT EXISTS (
       SELECT 1
       FROM web_returns wr3
       WHERE wr3.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
         AND wr3.wr_returned_date_sk = d.d_date_sk
         AND wr3.wr_order_number <> wr.wr_order_number
   )
)
SELECT *
FROM (
   SELECT
     d_year,
     refund_gender,
     SUM(wr_return_amt) AS total_return_amt,
     SUM(wr_refunded_cash) AS total_refunded_cash,
     COUNT(*) AS return_cnt,
     MAX(rn_year) AS max_rank
   FROM base
   GROUP BY ROLLUP (d_year, refund_gender)

   UNION DISTINCT

   SELECT
     d_year,
     refund_gender,
     SUM(wr_return_amt) AS total_return_amt,
     SUM(wr_refunded_cash) AS total_refunded_cash,
     COUNT(*) AS return_cnt,
     MAX(rn_year) AS max_rank
   FROM base
   WHERE wp_max_ad_count > 1
   GROUP BY ROLLUP (d_year, refund_gender)
) AS unified
ORDER BY d_year ASC NULLS LAST,
         refund_gender ASC NULLS LAST,
         total_return_amt DESC
OFFSET 0
LIMIT 100
