WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450800
),
item_promo_full AS (
    SELECT i.i_item_sk,
           i.i_item_desc,
           i.i_current_price,
           i.i_category,
           p.p_promo_sk,
           p.p_response_target,
           p.p_end_date_sk
    FROM item i
    FULL OUTER JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
),
sales_enriched AS (
    SELECT ss.ss_ticket_number,
           ss.ss_net_paid,
           ss.ss_item_sk,
           ss.ss_cdemo_sk,
           ss.ss_promo_sk,
           ip.i_item_desc,
           ip.i_current_price,
           ip.i_category,
           cd.cd_gender,
           p.p_response_target,
           p.p_end_date_sk
    FROM sampled_sales ss
    LEFT JOIN item_promo_full ip
        ON ip.i_item_sk = ss.ss_item_sk
    LEFT JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ip.i_current_price > 50
      AND cd.cd_gender = 'M'
      AND p.p_response_target = 1
      AND p.p_end_date_sk BETWEEN 2450300 AND 2450600
      AND ip.i_category IS NOT NULL
),
union_set AS (
    SELECT ss_ticket_number, ss_net_paid, i_category
    FROM sales_enriched
    WHERE i_category = 'Books'
    UNION
    SELECT ss_ticket_number, ss_net_paid, i_category
    FROM sales_enriched
    WHERE i_category = 'Electronics'
),
except_set AS (
    SELECT ss_ticket_number
    FROM union_set
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
    WHERE sr_reversed_charge > 100
)
SELECT
    u.ss_ticket_number,
    u.ss_net_paid,
    se.i_category,
    ROW_NUMBER() OVER (PARTITION BY se.i_category ORDER BY u.ss_net_paid DESC) AS category_rank,
    CASE WHEN u.ss_ticket_number IN (SELECT ss_ticket_number FROM except_set) THEN 'Unique' ELSE 'Returned' END AS ticket_status
FROM union_set u
JOIN sales_enriched se
    ON u.ss_ticket_number = se.ss_ticket_number
ORDER BY u.ss_net_paid DESC
LIMIT 100
