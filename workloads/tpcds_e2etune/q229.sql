SELECT
    ret_demo.cd_gender AS returning_gender,
    ret_demo.cd_marital_status AS returning_marital_status,
    CASE
        WHEN ret_c.c_birth_year BETWEEN 1960 AND 1969 THEN '1960s'
        WHEN ret_c.c_birth_year BETWEEN 1970 AND 1979 THEN '1970s'
        WHEN ret_c.c_birth_year BETWEEN 1980 AND 1989 THEN '1980s'
        WHEN ret_c.c_birth_year BETWEEN 1990 AND 1999 THEN '1990s'
        ELSE 'Other'
    END AS returning_birth_decade,
    COUNT(*) AS total_returns,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    RANK() OVER (ORDER BY SUM(wr.wr_net_loss) DESC) AS net_loss_rank
FROM web_returns wr
JOIN customer ret_c ON wr.wr_returning_customer_sk = ret_c.c_customer_sk
JOIN customer_demographics ret_demo ON wr.wr_returning_cdemo_sk = ret_demo.cd_demo_sk
JOIN customer ref_c ON wr.wr_refunded_customer_sk = ref_c.c_customer_sk
JOIN customer_demographics ref_demo ON wr.wr_refunded_cdemo_sk = ref_demo.cd_demo_sk
WHERE wr.wr_return_amt > 0
  AND ret_demo.cd_gender IN ('M', 'F')
  AND ref_demo.cd_credit_rating = 'Excellent'
GROUP BY
    ret_demo.cd_gender,
    ret_demo.cd_marital_status,
    CASE
        WHEN ret_c.c_birth_year BETWEEN 1960 AND 1969 THEN '1960s'
        WHEN ret_c.c_birth_year BETWEEN 1970 AND 1979 THEN '1970s'
        WHEN ret_c.c_birth_year BETWEEN 1980 AND 1989 THEN '1980s'
        WHEN ret_c.c_birth_year BETWEEN 1990 AND 1999 THEN '1990s'
        ELSE 'Other'
    END
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
