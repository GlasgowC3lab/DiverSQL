WITH base AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_cdemo_sk,
        sr.sr_addr_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating,
        ca.ca_location_type,
        ws.web_county,
        ws.web_rec_start_date
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND ws.web_county = 'Williamson County'
      AND ca.ca_location_type = 'apartment'
)
SELECT
    b.c_first_name,
    b.c_last_name,
    b.cd_gender,
    b.cd_credit_rating,
    b.web_county,
    SUM(b.sr_return_amt) AS total_return_amount,
    AVG(b.sr_return_amt) AS avg_return_amount,
    COUNT(*) AS return_cnt,
    MAX(b.sr_net_loss) AS max_net_loss,
    ct.cust_total_return
FROM base b
CROSS JOIN LATERAL (
    SELECT SUM(sr2.sr_return_amt) AS cust_total_return
    FROM store_returns sr2
    WHERE sr2.sr_customer_sk = b.sr_customer_sk
) ct
GROUP BY
    b.c_first_name,
    b.c_last_name,
    b.cd_gender,
    b.cd_credit_rating,
    b.web_county,
    ct.cust_total_return
ORDER BY total_return_amount DESC
LIMIT 100
