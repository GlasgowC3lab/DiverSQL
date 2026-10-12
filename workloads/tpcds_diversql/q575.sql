WITH store_data AS (
    SELECT
        sr.sr_returned_date_sk,
        d.d_date,
        sr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sr.sr_return_amt,
        sr.sr_net_loss,
        CASE WHEN sr.sr_net_loss > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS loss_category,
        LAG(sr.sr_return_amt) OVER (PARTITION BY sr.sr_customer_sk ORDER BY d.d_date) AS prev_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_returning_customer_sk = sr.sr_customer_sk
            AND cr.cr_returned_date_sk = sr.sr_returned_date_sk
      )
),
web_data AS (
    SELECT
        wr.wr_returned_date_sk,
        d.d_date,
        wr.wr_returning_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        wr.wr_return_amt,
        wr.wr_net_loss,
        CASE WHEN wr.wr_net_loss > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS loss_category,
        LAG(wr.wr_return_amt) OVER (PARTITION BY wr.wr_returning_customer_sk ORDER BY d.d_date) AS prev_return_amt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_refunded_customer_sk = wr.wr_returning_customer_sk
            AND cr.cr_returned_date_sk = wr.wr_returned_date_sk
      )
)
SELECT
    combined.d_date,
    combined.customer_sk,
    combined.c_first_name,
    combined.c_last_name,
    combined.return_amount,
    combined.net_loss,
    combined.loss_category,
    combined.prev_return_amt
FROM (
    SELECT
        sd.d_date,
        sd.sr_customer_sk AS customer_sk,
        sd.c_first_name,
        sd.c_last_name,
        sd.sr_return_amt AS return_amount,
        sd.sr_net_loss AS net_loss,
        sd.loss_category,
        sd.prev_return_amt
    FROM store_data sd
    UNION ALL
    SELECT
        wd.d_date,
        wd.customer_sk,
        wd.c_first_name,
        wd.c_last_name,
        wd.wr_return_amt AS return_amount,
        wd.wr_net_loss AS net_loss,
        wd.loss_category,
        wd.prev_return_amt
    FROM web_data wd
) combined
ORDER BY combined.d_date DESC, combined.net_loss DESC
LIMIT 100
