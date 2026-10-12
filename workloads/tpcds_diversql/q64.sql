WITH intersect_customers AS (
    SELECT ss_customer_sk AS c_customer_sk
    FROM store_sales
    WHERE ss_ext_sales_price > 2000
    INTERSECT
    SELECT wp_customer_sk
    FROM web_page
    WHERE wp_autogen_flag = 'N'
      AND wp_rec_end_date > DATE '2000-01-01'
),
joined_data AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ss.ss_ext_sales_price,
        ss.ss_list_price,
        wp.wp_url,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ss.ss_ext_sales_price DESC) AS rn_sales,
        RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_estimate_rank
    FROM intersect_customers ic
    JOIN customer c ON ic.c_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cd.cd_dep_count >= 2
      AND ss.ss_list_price BETWEEN 15 AND 50
      AND cd.cd_purchase_estimate >= 3000
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    cd_gender,
    cd_purchase_estimate,
    ss_ext_sales_price,
    ss_list_price,
    wp_url,
    rn_sales,
    purchase_estimate_rank
FROM joined_data
ORDER BY purchase_estimate_rank, rn_sales
LIMIT 100
