WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
sales_tickets AS (
    SELECT ss.ss_ticket_number AS ticket
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
return_tickets AS (
    SELECT cr.cr_order_number AS ticket
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
intersect_tickets AS (
    SELECT ticket FROM sales_tickets
    INTERSECT
    SELECT ticket FROM return_tickets
),
customer_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        (
            SELECT SUM(inv.inv_quantity_on_hand)
            FROM inventory inv
            WHERE inv.inv_item_sk = ss.ss_item_sk
        ) AS total_inventory_on_hand
    FROM sampled_sales ss
    WHERE ss.ss_customer_sk NOT IN (
        SELECT cr.cr_refunded_customer_sk
        FROM catalog_returns cr
    )
)
SELECT ticket
FROM intersect_tickets
UNION ALL
SELECT cs.ss_ticket_number AS ticket
FROM customer_sales cs
LIMIT 100
