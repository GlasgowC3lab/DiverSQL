SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_returned.d_year AS return_year,
    d_returned.d_month_seq AS return_month,
    d_returned.d_weekend AS return_weekend,
    cd_returning.cd_gender AS returning_gender,
    cd_returning.cd_marital_status AS returning_marital_status,
    cd_refunded.cd_education_status AS refunded_education,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_link_count,
    d_page_creation.d_year AS page_creation_year,
    d_page_access.d_year AS page_access_year,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_tax,
    SUM(wr.wr_account_credit) AS total_account_credit,
    SUM(wr.wr_return_ship_cost) AS total_ship_cost,
    SUM(wr.wr_fee + wr.wr_return_tax) AS total_fees_and_tax,
    CASE WHEN d_returned.d_weekend = 'Y' THEN 1 ELSE 0 END AS is_weekend_return,
    SUM(CASE WHEN d_returned.d_weekend = 'Y' THEN 1 ELSE 0 END) OVER (PARTITION BY s.s_store_id) AS weekend_return_count_per_store
FROM web_returns wr
JOIN date_dim d_returned
    ON wr.wr_returned_date_sk = d_returned.d_date_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN store s
    ON s.s_closed_date_sk = d_returned.d_date_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
WHERE d_returned.d_year = 2022
  AND cd_returning.cd_gender = 'F'
  AND wp.wp_type = 'product'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_returned.d_year,
    d_returned.d_month_seq,
    d_returned.d_weekend,
    cd_returning.cd_gender,
    cd_returning.cd_marital_status,
    cd_refunded.cd_education_status,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_link_count,
    d_page_creation.d_year,
    d_page_access.d_year
HAVING SUM(wr.wr_return_amt) > 500
ORDER BY total_net_loss DESC
LIMIT 50
