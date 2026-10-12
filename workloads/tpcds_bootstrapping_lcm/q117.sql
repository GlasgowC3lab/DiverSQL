SELECT
    s_store_id,
    s_store_name,
    s_city,
    closed_date,
    num_returns,
    total_return_amount,
    total_net_loss,
    avg_returning_income_band,
    avg_refunded_income_band,
    distinct_returning_addresses,
    distinct_refunded_addresses,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d.d_date AS closed_date,
        COUNT(DISTINCT w.wr_order_number) AS num_returns,
        SUM(w.wr_return_amt) AS total_return_amount,
        SUM(w.wr_net_loss) AS total_net_loss,
        AVG(hd_returning.hd_income_band_sk) AS avg_returning_income_band,
        AVG(hd_refunded.hd_income_band_sk) AS avg_refunded_income_band,
        COUNT(DISTINCT ca_returning.ca_address_sk) AS distinct_returning_addresses,
        COUNT(DISTINCT ca_refunded.ca_address_sk) AS distinct_refunded_addresses
    FROM web_returns w
    INNER JOIN date_dim d
        ON w.wr_returned_date_sk = d.d_date_sk
    INNER JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    INNER JOIN household_demographics hd_returning
        ON w.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    INNER JOIN household_demographics hd_refunded
        ON w.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    INNER JOIN customer_address ca_returning
        ON w.wr_returning_addr_sk = ca_returning.ca_address_sk
    INNER JOIN customer_address ca_refunded
        ON w.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    WHERE s.s_country = 'United States'
      AND d.d_year = 2022
    GROUP BY s.s_store_id, s.s_store_name, s.s_city, d.d_date
) t
ORDER BY net_loss_rank
LIMIT 10
