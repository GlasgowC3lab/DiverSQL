WITH filtered_returns AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_returned_date_sk,
        sr.sr_reason_sk,
        sr.sr_net_loss,
        c.c_customer_id,
        c.c_email_address,
        r.r_reason_desc,
        d.d_year
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(r.r_reason_desc, 'color')
      AND d.d_year = 2001
      AND sr.sr_customer_sk IN (
          SELECT c2.c_customer_sk
          FROM customer c2
          WHERE c2.c_preferred_cust_flag = 'Y'
      )
)
SELECT
    fr.c_customer_id,
    substring(fr.c_email_address, strpos(fr.c_email_address, '@') + 1) AS email_domain,
    fr.r_reason_desc,
    sum(fr.sr_net_loss) AS total_net_loss,
    count(*) AS returns_count
FROM filtered_returns fr
GROUP BY
    fr.c_customer_id,
    substring(fr.c_email_address, strpos(fr.c_email_address, '@') + 1),
    fr.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
