WITH intersect_customers AS (
    SELECT ss_customer_sk AS cust_sk FROM store_sales
    INTERSECT
    SELECT cr_returning_customer_sk FROM catalog_returns
),
base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_coupon_amt,
        ss.ss_ext_discount_amt,
        i.i_brand,
        i.i_category,
        d.d_year,
        t.t_hour,
        cd.cd_gender,
        cc.cc_state,
        cp.cp_catalog_number,
        cr.cr_return_amount,
        cr.cr_return_tax,
        w.w_state,
        ARRAY[ss.ss_coupon_amt, ss.ss_ext_discount_amt] AS amt_array
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND cc.cc_state = 'TX'
      AND cp.cp_catalog_number IN (5, 7, 15)
      AND t.t_hour BETWEEN 9 AND 17
      AND w.w_state = 'CA'
      AND EXISTS (
          SELECT 1 FROM customer c2
          WHERE c2.c_customer_sk = ss.ss_customer_sk
            AND c2.c_birth_year < 1950
      )
      AND ss.ss_customer_sk IN (SELECT cust_sk FROM intersect_customers)
),
unnested AS (
    SELECT
        b.d_year,
        b.i_brand,
        b.cc_state,
        b.cp_catalog_number,
        b.ss_ticket_number,
        b.ss_net_paid,
        b.cr_return_amount,
        b.ss_sales_price,
        b.ss_quantity,
        b.cd_gender,
        amt
    FROM base b
    CROSS JOIN UNNEST(b.amt_array) AS u(amt)
)
SELECT
    d_year,
    i_brand,
    cc_state,
    cp_catalog_number,
    COUNT(DISTINCT ss_ticket_number) AS order_count,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(cr_return_amount) AS avg_return_amount,
    MIN(ss_sales_price) AS min_sales_price,
    MAX(ss_sales_price) AS max_sales_price,
    SUM(CASE WHEN cd_gender = 'M' THEN ss_quantity ELSE 0 END) AS male_quantity,
    SUM(CASE WHEN cd_gender = 'F' THEN ss_quantity ELSE 0 END) AS female_quantity,
    amt AS amount_value,
    COUNT(*) AS amount_rows
FROM unnested
GROUP BY
    d_year,
    i_brand,
    cc_state,
    cp_catalog_number,
    amt
ORDER BY total_net_paid DESC
LIMIT 100
