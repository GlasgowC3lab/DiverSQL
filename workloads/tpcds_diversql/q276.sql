WITH orders_meeting_criteria AS (
    SELECT cs_order_number
    FROM (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE regexp_like(i.i_item_desc, '.*[A-Z]{2,}.*')
          AND i.i_product_name LIKE '%Premium%'
        INTERSECT
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
          AND substring(c.c_last_name, 1, 1) = 'S'
    )
),
sales_aggregated AS (
    SELECT d.d_year,
           SUM(cs.cs_net_profit) AS total_net_profit,
           COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
           SUM(l.item_id_num) AS sum_item_id_num
    FROM catalog_sales cs
    JOIN orders_meeting_criteria omc ON cs.cs_order_number = omc.cs_order_number
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN LATERAL (
        SELECT TRY_CAST(regexp_extract(i.i_item_id, '\\d+') AS integer) AS item_id_num
    ) l ON true
    GROUP BY d.d_year
)
SELECT d_year,
       total_net_profit,
       order_cnt,
       sum_item_id_num
FROM sales_aggregated
ORDER BY total_net_profit DESC
