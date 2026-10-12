WITH returns_detail AS (
    SELECT
        c.c_birth_month,
        c.c_birth_country,
        hd.hd_buy_potential,
        sr.sr_ticket_number,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss,
        rd.d_date AS return_date,
        fd.d_date AS first_sales_date
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim rd
        ON sr.sr_returned_date_sk = rd.d_date_sk
    JOIN date_dim fd
        ON c.c_first_sales_date_sk = fd.d_date_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
), aggregated_returns AS (
    SELECT
        c_birth_month AS birth_month,
        c_birth_country AS birth_country,
        hd_buy_potential,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_net_loss) AS avg_net_loss,
        AVG(DATE_DIFF('day', first_sales_date, return_date)) AS avg_days_to_return,
        CASE
            WHEN SUM(sr_return_amt_inc_tax) > 50000 THEN 'High'
            WHEN SUM(sr_return_amt_inc_tax) BETWEEN 20000 AND 50000 THEN 'Medium'
            ELSE 'Low'
        END AS return_volume_category
    FROM returns_detail
    GROUP BY c_birth_month, c_birth_country, hd_buy_potential
    HAVING COUNT(sr_ticket_number) >= 10
)
SELECT
    birth_month,
    birth_country,
    hd_buy_potential,
    total_returns,
    total_return_amount,
    avg_net_loss,
    return_volume_category,
    RANK() OVER (ORDER BY total_return_amount DESC) AS country_return_rank,
    avg_days_to_return
FROM aggregated_returns
ORDER BY country_return_rank
