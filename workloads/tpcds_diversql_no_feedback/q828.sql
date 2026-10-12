WITH sales_summary AS (
    SELECT
        cs_item_sk,
        cs_sold_date_sk,
        cs_call_center_sk,
        MIN(cs_order_number)       AS any_order_number,
        MIN(cs_bill_cdemo_sk)      AS any_cdemo_sk,
        SUM(cs_net_paid)           AS total_net_paid,
        SUM(cs_quantity)           AS total_quantity
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450815 AND 2451074
      AND cs_quantity > 0
      AND cs_net_paid > 0
    GROUP BY cs_item_sk, cs_sold_date_sk, cs_call_center_sk
),

date_filtered AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1200 AND 1250
),

time_filtered AS (
    SELECT *
    FROM time_dim
    WHERE t_sub_shift IN ('morning', 'afternoon')
      AND t_hour BETWEEN 8 AND 12
),

reason_filtered AS (
    SELECT *
    FROM reason
    WHERE r_reason_id = 'AAAAAAAGAAAAAAA'
),

cross_set AS (
    SELECT 1 AS dummy UNION ALL SELECT 2 UNION ALL SELECT 3
),

joined_data AS (
    SELECT
        d.d_date,
        c.cc_name,
        cd.cd_gender,
        r.r_reason_desc,
        s.total_quantity,
        s.total_net_paid,
        i.inv_quantity_on_hand,
        t.t_hour,
        cr.cr_return_amount,
        wr.wr_return_amt,
        cs.dummy,
        c.cc_state,
        s.total_net_paid AS net_paid
    FROM sales_summary s
    JOIN date_filtered d
        ON s.cs_sold_date_sk = d.d_date_sk
    JOIN call_center c
        ON s.cs_call_center_sk = c.cc_call_center_sk
    JOIN customer_demographics cd
        ON s.any_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory i
        ON i.inv_item_sk = s.cs_item_sk
       AND i.inv_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = s.cs_item_sk
       AND cr.cr_order_number = s.any_order_number
    LEFT JOIN reason_filtered r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN time_filtered t
        ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = s.cs_item_sk
       AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason_filtered r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    CROSS JOIN cross_set cs
    WHERE c.cc_state = 'CA'
      AND cd.cd_gender = 'M'
      AND i.inv_quantity_on_hand > 100
      AND s.total_net_paid > 1000
      AND t.t_hour BETWEEN 9 AND 11
      AND cs.dummy = 1
)
SELECT
    cc_name,
    AVG(net_paid)          AS avg_net_paid,
    SUM(total_quantity)    AS sum_quantity,
    COUNT(*)               AS row_count
FROM joined_data
GROUP BY cc_name
HAVING SUM(total_quantity) > 10
ORDER BY avg_net_paid DESC
LIMIT 100
