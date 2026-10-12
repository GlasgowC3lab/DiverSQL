WITH joined_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        ss.ss_net_profit,
        sr.sr_net_loss,
        wr.wr_net_loss,
        i.i_category,
        p.p_promo_name,
        r.r_reason_desc,
        t.t_meal_time,
        c.c_customer_id,
        ca.ca_state,
        cd.cd_education_status,
        i.i_current_price,
        p.p_discount_active
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
       AND ss.ss_sold_time_sk = t.t_time_sk
       AND ss.ss_customer_sk = c.c_customer_sk
       AND ss.ss_cdemo_sk = cd.cd_demo_sk
       AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = i.i_item_sk
       AND sr.sr_return_time_sk = t.t_time_sk
       AND sr.sr_customer_sk = c.c_customer_sk
       AND sr.sr_cdemo_sk = cd.cd_demo_sk
       AND sr.sr_addr_sk = ca.ca_address_sk
       AND sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_time_sk = t.t_time_sk
       AND wr.wr_refunded_customer_sk = c.c_customer_sk
       AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
       AND wr.wr_refunded_addr_sk = ca.ca_address_sk
       AND wr.wr_reason_sk = r.r_reason_sk
    WHERE
        i.i_current_price > 20
        AND ca.ca_state IN ('CA', 'TX')
        AND cd.cd_education_status = 'College'
        AND t.t_meal_time = 'lunch'
        AND p.p_discount_active = 'Y'
        AND r.r_reason_desc LIKE '%size%'
),
agg_by_reason AS (
    SELECT
        r_reason_desc,
        i_category,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_net_loss) AS avg_return_net_loss,
        SUM(sr_net_loss) AS total_store_return_loss,
        SUM(wr_net_loss) AS total_web_return_loss,
        SUM(ss_net_profit) AS total_store_profit
    FROM joined_data
    GROUP BY r_reason_desc, i_category
    HAVING SUM(cr_return_amount) > 1000
)
SELECT
    r_reason_desc,
    i_category,
    distinct_customers,
    total_return_amount,
    avg_return_net_loss,
    total_store_return_loss,
    total_web_return_loss,
    total_store_profit,
    ROUND(AVG(total_return_amount) OVER (), 2) AS avg_total_return_amount_all_groups
FROM agg_by_reason
ORDER BY total_return_amount DESC
LIMIT 100
