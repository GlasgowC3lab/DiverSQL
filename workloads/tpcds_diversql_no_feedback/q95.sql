WITH sales_subset AS (
    SELECT
        ss.ss_ticket_number AS ticket_number,
        ss.ss_sold_date_sk AS transaction_date_sk,
        i.i_item_id AS item_id,
        s.s_store_name AS associate_name,
        ss.ss_net_paid AS net_amount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE
        t.t_shift = 'first'
        AND s.s_country = 'United States'
        AND i.i_wholesale_cost > 10
),
returns_subset AS (
    SELECT
        cr.cr_order_number AS ticket_number,
        cr.cr_returned_date_sk AS transaction_date_sk,
        i.i_item_id AS item_id,
        c.c_first_name AS associate_name,
        cr.cr_net_loss AS net_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE
        t.t_shift = 'second'
        AND cr.cr_return_amount > 0
),
unioned AS (
    SELECT ticket_number, transaction_date_sk, item_id, associate_name, net_amount
    FROM sales_subset
    UNION
    SELECT ticket_number, transaction_date_sk, item_id, associate_name, net_amount
    FROM returns_subset
)
SELECT
    u.ticket_number,
    u.transaction_date_sk,
    u.item_id,
    u.associate_name,
    u.net_amount
FROM unioned u
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_order_number = u.ticket_number
)
ORDER BY u.net_amount DESC, u.transaction_date_sk ASC
