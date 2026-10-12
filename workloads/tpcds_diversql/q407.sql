WITH sales_base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_item_id,
        i.i_category,
        i.i_class_id,
        i.i_units,
        i.i_current_price,
        i.i_wholesale_cost,
        t.t_hour,
        t.t_sub_shift,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
)
SELECT
    sb.ss_ticket_number,
    sb.c_first_name,
    sb.c_last_name,
    sb.c_birth_year,
    sb.i_item_id,
    sb.i_category,
    sb.i_class_id,
    sb.t_hour,
    sb.t_sub_shift,
    sb.ss_quantity,
    sb.ss_net_paid,
    sb.ss_net_profit,
    CASE
        WHEN rr.sr_return_quantity IS NOT NULL THEN sb.ss_net_profit - rr.sr_return_amt_inc_tax
        ELSE sb.ss_net_profit
    END AS adjusted_profit,
    RANK() OVER (
        PARTITION BY sb.i_category
        ORDER BY CASE
            WHEN rr.sr_return_quantity IS NOT NULL THEN sb.ss_net_profit - rr.sr_return_amt_inc_tax
            ELSE sb.ss_net_profit
        END DESC
    ) AS category_profit_rank,
    (pf.flag * sb.ss_quantity) AS flagged_quantity
FROM sales_base sb
LEFT JOIN store_returns rr
    ON rr.sr_ticket_number = sb.ss_ticket_number
LEFT JOIN reason r
    ON rr.sr_reason_sk = r.r_reason_sk
CROSS JOIN (VALUES (1), (2)) AS pf(flag)
WHERE sb.t_hour BETWEEN 8 AND 16
  AND sb.i_class_id IN (5, 12, 15)
  AND sb.c_birth_year <= 1950
  AND sb.ss_quantity > 1
  AND sb.i_units <> 'N/A'
  AND (rr.sr_return_quantity IS NULL OR rr.sr_return_quantity = 0)
LIMIT 100
