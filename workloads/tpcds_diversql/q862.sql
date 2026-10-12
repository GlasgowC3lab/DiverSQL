WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),
intersect_orders AS (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_return_amount > 0
    INTERSECT
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_fee > 0
),
joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_net_loss,
        d.d_year,
        t.t_hour,
        i.i_brand,
        i.i_category,
        sm.sm_carrier,
        r.r_reason_desc,
        c_ref.c_customer_id AS refunded_customer_id,
        c_ret.c_customer_id AS returning_customer_id,
        cd_ref.cd_gender AS refunded_gender,
        cd_ret.cd_gender AS returning_gender,
        hd_ref.hd_income_band_sk AS refunded_income_band,
        hd_ret.hd_income_band_sk AS returning_income_band,
        ca_ref.ca_state AS refunded_state,
        ca_ret.ca_state AS returning_state,
        w.web_name,
        CASE WHEN cr.cr_return_amount > (
            SELECT avg(cr2.cr_return_amount)
            FROM sampled_returns cr2
            WHERE cr2.cr_item_sk = cr.cr_item_sk
        ) THEN 'High' ELSE 'Low' END AS amount_category,
        CASE WHEN cr.cr_order_number IN (SELECT cr_order_number FROM intersect_orders) THEN 1 ELSE 0 END AS intersect_flag
    FROM sampled_returns cr
    INNER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    INNER JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    INNER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN customer c_ref
        ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    LEFT JOIN customer c_ret
        ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    LEFT JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    LEFT JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    LEFT JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    LEFT JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    LEFT JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    LEFT JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    FULL OUTER JOIN web_site w
        ON inv.inv_date_sk = w.web_open_date_sk
)
SELECT
    d_year,
    i_brand,
    sm_carrier,
    amount_category,
    COUNT(*) AS total_returns,
    SUM(cr_return_amount) AS sum_return_amount,
    AVG(cr_return_quantity) AS avg_quantity,
    SUM(CASE WHEN intersect_flag = 1 THEN 1 ELSE 0 END) AS intersected_returns
FROM joined
GROUP BY
    d_year,
    i_brand,
    sm_carrier,
    amount_category
ORDER BY
    total_returns DESC
LIMIT 100
